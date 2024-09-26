# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import os
from behave import step

import nmci
from nmci import pexpect

REMOTE_ROOT_DIR = lambda: os.environ["TESTDIR"] + "/nfs/client/"
REMOTE_JOURNAL_DIR = lambda: os.environ["TESTDIR"] + "/client_log/"
REMOTE_JOURNAL = lambda: "--root=" + REMOTE_JOURNAL_DIR()
REMOTE_CRASH_DIR = lambda: os.environ["TESTDIR"] + "/client_dumps/"

KVM_HW_ERROR = "KVM: entry failed, hardware error"


def handle_timeout(context, proc, timeout, boot_log_proc, first_half=True):
    t = nmci.util.start_timeout(timeout=timeout / 2)
    now_booted = False
    last_before = None
    message_check_timeout = 30
    messages = [
        "== BOOT ==",
        "== PASS ==",
        "== FAIL ==",
        "== DEBUG SHELL ==",
        pexpect.TIMEOUT,
    ]
    while t.loop_sleep():
        res = proc.expect([pexpect.EOF, KVM_HW_ERROR, pexpect.TIMEOUT], timeout=0.1)
        if res == 0:
            return True
        if res == 1:
            nmci.cext.skip("KVM hardware error detected.")
        message = boot_log_proc.expect(
            messages,
            timeout=message_check_timeout,
        )
        print(f"Found machine message: {messages[message]} in {t.elapsed_time():.3f}s")
        if message == 0:
            now_booted = True
            context.dracut_vm_state = "BOOT"
        elif message == 1:
            context.dracut_vm_state = "PASS"
            # check every second if boot finished
            message_check_timeout = 1
        elif message == 2:
            context.dracut_vm_state = "FAIL"
            # check every second if boot finished
            message_check_timeout = 1
        elif message == 3:
            # debug shell, create pipefile for stdin, redirect by lines
            debug_shell(proc)
        if first_half and now_booted:
            print(f"VM boot detected in {t.elapsed_time():.3f}s")
            break
        if boot_log_proc.before == last_before:
            print("No output in console in last 30s, exitting...")
            return False
        last_before = boot_log_proc.before

    if first_half:
        if not now_booted:
            print(
                f"VM did not start the testsuite in half of the timeout ({timeout/2}s)"
            )
            return False
        return handle_timeout(context, proc, timeout, boot_log_proc, first_half=False)
    else:
        return False


def debug_shell(proc):
    nmci.process.run("rm -rf /tmp/dracut_input")
    nmci.process.run("mkfifo /tmp/dracut_input")
    print("debug shell detected, reading /tmp/dracut_input")
    running = True
    while running:
        with open("/tmp/dracut_input", "r") as dracut_in:
            line = True
            while line:
                line = dracut_in.readline()
                proc.send(line)
                if line and "poweroff" in line:
                    running = False
                    break


def embed_dracut_logs(context):
    nmci.process.run(
        "mount $TESTDIR/client_dumps.img -o loop,ro,noatime,norecovery $TESTDIR/client_dumps; "
        "mount $TESTDIR/client_log.img -o loop,ro,noatime,norecovery $TESTDIR/client_log/var/log/; ",
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
            journal_args=REMOTE_JOURNAL(),
            fail_only=False,
        )

    nmci.embed.embed_service_log(
    )

    nmci.embed.embed_file_if_exists(
        "Dracut Audit",
        REMOTE_JOURNAL_DIR() + "/var/log/audit/audit.log",
    )

    check_core_dumps(context)


def get_backtrace(filename):
    return nmci.process.run_stdout(
        f"gdb -quiet -batch -c {filename} -x contrib/dracut/conf/backtrace",
        ignore_stderr=True,
        ignore_returncode=True,
    )


def check_core_dumps(context):
    """
    return True if unexpected crash happened, False otherwise
    """

    backtraces = ""
    sleep_crash = False
    other_crash = False
    for filename in os.listdir(REMOTE_CRASH_DIR()):
        if filename.startswith("dump_"):
            if "sleep" in filename:
                sleep_crash = True
            else:
                other_crash = True
            backtraces += (
                filename + ":\n" + get_backtrace(REMOTE_CRASH_DIR() + filename) + "\n\n"
            )
            nmci.embed.embed_file_if_exists(
                "Dracut Crash Dump",
                REMOTE_CRASH_DIR() + filename,
                as_base64=True,
            )

    if backtraces:
        nmci.embed.embed_data("Dracut Backtraces", backtraces)

    assert sleep_crash == getattr(
        context, "dracut_crash_test", False
    ), "Excpected sleep crash not detected in initrd"
    assert not other_crash, "Crash in inird detected"


def prepare_dracut(context, checks):
    nmci.process.run(
        "mount $TESTDIR/client_check.img -o loop $TESTDIR/client_check/; "
        "mount $TESTDIR/client_log.img -o loop $TESTDIR/client_log/var/log/; "
        "mkdir -p $TESTDIR/client_log/var/log/audit; "
        "mkdir -p $TESTDIR/client_log/var/log/journal; "
        "rm -rf $TESTDIR/client_check/*; "
        "cp ./check_lib/*.sh $TESTDIR/client_check/; ",
        shell=True,
        cwd="contrib/dracut",
    )
    with open(os.environ["TESTDIR"] + "/client_check/client_check.sh", "w") as f:
        f.write("client_check() {\n")
        f.write("\n".join(checks))
        f.write("}\n")
    nmci.process.run(
        "sync; sync; sync; umount $TESTDIR/client_check.img; "
        "umount $TESTDIR/client_log.img; sync; sync; sync; ",
        shell=True,
    )


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
        "enforcing=0",
        "cloud-init=disabled",
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

    nmci.process.run_stdout("touch /tmp/dracut_boot.log")
    boot_log_proc = nmci.pexpect.pexpect_spawn(
        "tail -f -n 0 /tmp/dracut_boot.log",
        timeout=timeout,
        logfile=nmci.pexpect.DEV_NULL,
        codec_errors="ignore",
    )

    context.dracut_vm_state = "NOBOOT"
    proc = context.pexpect_spawn(
        os.getcwd() + "/contrib/dracut/run-qemu",
        [
            *qemu_args,
            "-append",
            " ".join(kernel_args),
            "-initrd",
            os.environ["TESTDIR"] + "/" + initrd,
        ],
        cwd="./contrib/dracut/",
        timeout=None,
    )

    if not handle_timeout(context, proc, p_timeout, boot_log_proc):
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
    remote_file_name = f"{REMOTE_ROOT_DIR()}{file_name}"
    assert os.path.isfile(remote_file_name), f"Remote file {file_name} not found"
    context.dracut_files_to_restore = getattr(context, "dracut_files_to_restore", [])
    context.dracut_files_to_restore.append(file_name)
    os.remove(remote_file_name)
