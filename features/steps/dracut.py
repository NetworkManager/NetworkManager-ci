# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import os
from behave import step

import nmci
from nmci import pexpect

REMOTE_ROOT_DIR = "/var/dracut_test/nfs/client/"
REMOTE_JOURNAL_DIR = "/var/dracut_test/client_log/"
REMOTE_JOURNAL = "--root=" + REMOTE_JOURNAL_DIR
REMOTE_CRASH_DIR = "/var/dracut_test/client_dumps/"

KVM_HW_ERROR = "KVM: entry failed, hardware error"


def handle_timeout(proc, timeout, boot_log_proc=None):
    t = nmci.util.start_timeout(timeout=timeout / 2)
    now_booted = False
    last_before = None
    first_half = False
    if boot_log_proc is None:
        first_half = True
        nmci.process.run_stdout("touch /tmp/dracut_boot.log")
        boot_log_proc = nmci.pexpect.pexpect_spawn(
            "tail -f /tmp/dracut_boot.log",
            timeout=timeout,
            logfile=nmci.pexpect.DEV_NULL,
        )
    while t.loop_sleep():
        res = proc.expect([pexpect.EOF, KVM_HW_ERROR, pexpect.TIMEOUT], timeout=0.1)
        if res == 0:
            return True
        if res == 1:
            nmci.cext.skip("KVM hardware error detected.")
        message = boot_log_proc.expect(
            ["== BOOT ==", "Power down", "== DEBUG SHELL ==", pexpect.TIMEOUT],
            timeout=20,
        )
        # debug shell, wait until machine gets down, ignore timeout
        if message == 2:
            print("debug shell detected, waiting for machine to finish, no timeout")
            boot_log_proc.expect(["Power down", pexpect.EOF], timeout=None)

        now_booted = message == 0
        if first_half and now_booted:
            print(f"VM boot detected in {t.elapsed_time():.3f}s")
            break
        if boot_log_proc.before == last_before:
            print("No output in console in last 20s, exitting...")
            return False
        last_before = boot_log_proc.before

    if first_half:
        if not now_booted:
            print(
                f"VM did not start the testsuite in half of the timeout ({timeout/2}s)"
            )
            return False
        return handle_timeout(proc, timeout, boot_log_proc)
    else:
        return False


def embed_dracut_logs(context):
    context.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_DUMPS $TESTDIR/client_dumps; "
        "mount $DEV_LOG $TESTDIR/client_log/var/log/; "
    )

    context.dracut_vm_state = nmci.process.run_stdout(
        "cd contrib/dracut; . ./setup.sh; cat $TESTDIR/client_log/var/log/vm_state",
        shell=True,
    )

    nmci.embed.embed_file_if_exists(
        "Dracut boot",
        "/tmp/dracut_boot.log",
    )
    if not context.dracut_vm_state.startswith("NO"):
        nmci.embed.embed_service_log(
            "Dracut Test",
            syslog_identifier="test-init",
            journal_args=REMOTE_JOURNAL,
            fail_only=False,
        )

    nmci.embed.embed_service_log(
        "Dracut Journal", journal_args=REMOTE_JOURNAL, fail_only=False
    )

    check_core_dumps(context)


def get_backtrace(context, filename):
    out, _, _ = context.run(
        f"gdb -quiet -batch -c {filename} -x contrib/dracut/conf/backtrace"
    )
    return out


def check_core_dumps(context):
    """
    return True if unexpected crash happened, False otherwise
    """

    backtraces = ""
    sleep_crash = False
    other_crash = False
    for filename in os.listdir(REMOTE_CRASH_DIR):
        if filename.startswith("dump_"):
            if "sleep" in filename:
                sleep_crash = True
            else:
                other_crash = True
            backtraces += (
                filename
                + ":\n"
                + get_backtrace(context, REMOTE_CRASH_DIR + filename)
                + "\n\n"
            )
            nmci.embed.embed_file_if_exists(
                "Dracut Crash Dump",
                REMOTE_CRASH_DIR + filename,
                as_base64=True,
            )

    if backtraces:
        nmci.embed.embed_data("Dracut Backtraces", backtraces)

    assert sleep_crash == getattr(
        context, "dracut_crash_test", False
    ), "Excpected sleep crash not detected in initrd"
    assert not other_crash, "Crash in inird detected"


def prepare_dracut(context, checks):
    context.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_CHECK $TESTDIR/client_check/; "
        "rm -rf $TESTDIR/client_check/*; "
        "cp ./check_lib/*.sh $TESTDIR/client_check/; "
        "mount $DEV_LOG $TESTDIR/client_log/var/log/; "
        "echo NOBOOT > $TESTDIR/client_log/var/log/vm_state; "
        "mkdir $TESTDIR/client_log/var/log/journal/; "
    )
    with open("/var/dracut_test/client_check/client_check.sh", "w") as f:
        f.write("client_check() {\n")
        f.write("\n".join(checks))
        f.write("}\n")
    context.run("cd contrib/dracut/; . ./setup.sh; umount $DEV_CHECK; umount $DEV_LOG;")


@step("Run dracut test")
def dracut_run(context):
    qemu_args = []
    kernel_args = [
        "panic=1",
        "systemd.crash_reboot",
        "rd.shell=0",
        "biosdevname=0",
        "net.ifnames=0",
        "noapic",
        "loglevel=7",
        "rd.debug",
    ]
    kernel_arch_args = {
        "x86_64": ["console=ttyS0,115200n81,", "intel_iommu=on"],
    }
    arch = context.arch
    if arch in kernel_arch_args.keys():
        kernel_args += kernel_arch_args[arch]
    initrd = "initramfs.client.NM"
    checks = []
    timeout = "6m"
    ram = "1200"
    for row in context.table:
        if "qemu" in row[0].lower():
            qemu_args.extend(row[1].split(" "))
        elif "kernel" in row[0].lower():
            kernel_args.append(row[1])
            if "nm.debug" in row[1]:
                kernel_args.remove("rd.debug")
        elif "initrd" in row[0].lower():
            initrd = row[1]
        elif "check" in row[0].lower():
            checks.append(f"{row[1]} || die '\"{row[1]}\" failed'\n")
            if "dracut_crash_test" in row[1]:
                context.dracut_crash_test = True
        elif "timeout" in row[0].lower():
            timeout = row[1]
        elif "ram" in row[0].lower():
            ram = row[1]

    prepare_dracut(context, checks)

    # replace env of child processes
    os.environ["RAM"] = ram
    os.environ["TIMEOUT"] = timeout

    if timeout.endswith("m"):
        p_timeout = int(timeout.strip("m")) * 60
    else:
        p_timeout = int(timeout)

    proc = context.pexpect_spawn(
        os.getcwd() + "/contrib/dracut/run-qemu",
        [
            *qemu_args,
            "-append",
            " ".join(kernel_args),
            "-initrd",
            "$TESTDIR/" + initrd,
        ],
        cwd="./contrib/dracut/",
        timeout=None,
    )
    if not handle_timeout(proc, p_timeout):
        proc.kill(15)
    res = proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=5)
    rc = proc.exitstatus

    embed_dracut_logs(context)

    assert res == 0, "pexpect.TIMEOUT should not happen! (raise offset?)"
    ## Disable this check, if rc != 0, it is not NM fail
    # assert (
    #    rc == 0
    # ), f"Test run FAILED, VM returncode: {rc}, VM result: {context.dracut_vm_state}"
    assert (
        "PASS" in context.dracut_vm_state
    ), f"Test FAILED, VM result: {context.dracut_vm_state}"


@step('Remove "{file_name}" from dracut NFS root')
def remove_file_ns_root(context, file_name):
    assert os.path.isfile(file_name), f"Local file {file_name} not found"
    remote_file_name = f"{REMOTE_ROOT_DIR}{file_name}"
    assert os.path.isfile(remote_file_name), f"Remote file {file_name} not found"
    context.dracut_files_to_restore = getattr(context, "dracut_files_to_restore", [])
    context.dracut_files_to_restore.append(file_name)
    os.remove(remote_file_name)
