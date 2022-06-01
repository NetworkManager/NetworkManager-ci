import os
import pexpect
from behave import step

import nmci.lib
import nmci


REMOTE_JOURNAL_DIR = "/var/dracut_test/client_log/"
REMOTE_JOURNAL = "--root=" + REMOTE_JOURNAL_DIR
REMOTE_CRASH_DIR = "/var/dracut_test/client_dumps/"


def get_dracut_vm_state(mount=True):
    cmd = "cd contrib/dracut/; . ./setup.sh; "
    if mount:
        cmd += "mount -o ro $DEV_LOG $TESTDIR/client_log/var/log/; "
    cmd += "cat $TESTDIR/client_log/var/log/vm_state; "
    if mount:
        cmd += "umount $DEV_LOG"
    return nmci.run(cmd)[0].strip("\n")


def handle_timeout(proc, timeout):
    res = proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=timeout/2)
    if res == 0:
        return True
    vm_state = get_dracut_vm_state()
    print("vmstate is " + vm_state)
    if vm_state == "NOBOOT":
        print(f"VM did not enter the switchroot phase in half of the timeout ({timeout/2})")
        return False
    res = proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=timeout/2)
    return res == 0


def embed_dracut_logs(context):
    context.run("cd contrib/dracut/; . ./setup.sh; "
                "mount $DEV_DUMPS $TESTDIR/client_dumps; "
                "mount $DEV_LOG $TESTDIR/client_log/var/log/; "
                )

    context.dracut_vm_state = get_dracut_vm_state(mount=False)

    nmci.lib.embed_file_if_exists(context, "/tmp/dracut_boot.log", caption="Dracut boot", fail_only=True)
    if not context.dracut_vm_state.startswith("NO"):
        nmci.lib.embed_service_log(context, "Dracut Test", syslog_identifier="test-init", journal_args=REMOTE_JOURNAL, fail_only=False)
        #nmci.lib.embed_service_log(context, "Dracut NM", service="NetworkManager", journal_args=REMOTE_JOURNAL, fail_only=True)
        nmci.lib.embed_service_log(context, "Dracut Journal", journal_args=REMOTE_JOURNAL, fail_only=False)

    check_core_dumps(context)

    context.run("cd contrib/dracut/; . ./setup.sh; umount $DEV_DUMPS; umount $DEV_LOG;")


def get_backtrace(context, filename):
    out, _, _ = context.run(f"gdb -quiet -batch -c {filename} -x contrib/dracut/conf/backtrace")
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
            backtraces += filename + ":\n" \
                + get_backtrace(context, REMOTE_CRASH_DIR + filename) + "\n\n"
            nmci.lib.embed_file_if_exists(
                context,
                REMOTE_CRASH_DIR + filename,
                mime_type="link",
                caption="Dracut Crash Dump"
            )

    if backtraces:
        context.embed("text/plain", backtraces, caption="Dracut Backtraces")

    assert sleep_crash == getattr(context, "dracut_crash_test", False), \
        "Excpected sleep crash not detected in initrd"
    assert not other_crash, "Crash in inird detected"


def prepare_dracut(context, checks):
    context.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_CHECK $TESTDIR/client_check/; "
        "rm -rf $TESTDIR/client_check/*; "
        "cp ./check_lib/*.sh $TESTDIR/client_check/; "
        "mount $DEV_LOG $TESTDIR/client_log/var/log/; "
        "rm -rf $TESTDIR/client_log/var/log/*; "
        "echo NOBOOT > $TESTDIR/client_log/var/log/vm_state; "
        "mkdir $TESTDIR/client_log/var/log/journal/; "
    )
    with open("/var/dracut_test/client_check/client_check.sh", "w") as f:
        f.write("client_check() {\n" + checks + "}")
    context.run("cd contrib/dracut/; . ./setup.sh; umount $DEV_CHECK; umount $DEV_LOG;")


@step(u'Run dracut test')
def dracut_run(context):
    qemu_args = []
    kernel_args = "panic=1 systemd.crash_reboot rd.shell=0 "\
                  "rd.debug loglevel=7 biosdevname=0 net.ifnames=0 noapic "
    kernel_arch_args = {
        "x86_64": "console=ttyS0,115200n81 ",
    }
    arch = context.arch
    if arch in kernel_arch_args.keys():
        kernel_args += kernel_arch_args[arch]
    initrd = "initramfs.client.NM"
    checks = ""
    timeout = "4m"
    ram = "1200"
    for row in context.table:
        if "qemu" in row[0].lower():
            qemu_args += row[1].split(" ")
        elif "kernel" in row[0].lower():
            kernel_args += " " + row[1]
        elif "initrd" in row[0].lower():
            initrd = row[1]
        elif "check" in row[0].lower():
            checks += row[1] + " || die '" + '"' + row[1] + '"' + " failed'\n"
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
            "-append", kernel_args,
            "-initrd", "$TESTDIR/"+initrd,
        ],
        cwd="./contrib/dracut/",
        timeout=p_timeout)
    if not handle_timeout(proc, p_timeout):
        proc.kill(15)
    res = proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=5)
    rc = proc.exitstatus

    embed_dracut_logs(context)

    assert res == 0, "pexpect.TIMEOUT should not happen! (raise offset?)"
    assert rc == 0, f"Test run FAILED, VM returncode: {rc}, VM result: {context.dracut_vm_state}"
    assert "PASS" in context.dracut_vm_state, f"Test FAILED, VM result: {context.dracut_vm_state}"
