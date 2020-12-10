import os
import pexpect
from behave import step

import nmci.lib
import nmci


REMOTE_JOURNAL_DIR = "/var/dracut_test/client_dumps/"
REMOTE_JOURNAL = "--root=" + REMOTE_JOURNAL_DIR


def embed_dracut_logs(context):
    nmci.lib.embed_file_if_exists(
        context, "/tmp/dracut_setup.log", caption="Dracut setup", fail_only=True
    )
    # nmci.lib.embed_file_if_exists(context, "/tmp/dracut_boot.log", caption="Dracut boot", fail_only=True)
    context.run(
        "cd contrib/dracut/; . ./setup.sh; " "mount $DEV_DUMPS $TESTDIR/client_dumps; "
    )

    if context.dracut_boot:
        nmci.lib.embed_service_log(
            context,
            "test-init",
            "Dracut Test",
            journal_arg=REMOTE_JOURNAL,
            fail_only=False,
        )
        nmci.lib.embed_service_log(
            context,
            "NetworkManager",
            "Dracut NM",
            journal_arg=REMOTE_JOURNAL,
            fail_only=True,
        )

    crash = check_core_dumps(context)

    context.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "rm -rf $TESTDIR/client_dumps/*; "
        "umount $DEV_DUMPS; "
    )

    nmci.lib.embed_file_if_exists(
        context, "/tmp/dracut_teardown.log", "Dracut teardown", fail_only=True
    )

    assert not crash, f"Unexpected crash in initrd (or expected crash did not happen)"


def get_backtrace(context, filename):
    gdb = context.pexpect_spawn("gdb -quiet", cwd="/var/dracut_test/client_dumps/")
    prompt = gdb.expect(["\\(gdb\\)", pexpect.TIMEOUT, pexpect.EOF], timeout=5)
    if prompt != 0:
        return "ERROR: gdb did not start"

    gdb.sendline("core-file " + filename)
    prompt = gdb.expect(["\\(gdb\\)", pexpect.TIMEOUT, pexpect.EOF], timeout=20)
    if prompt != 0:
        return "ERROR: corefile not loaded"

    gdb.sendline("backtrace")
    prompt = gdb.expect(["\\(gdb\\)", pexpect.TIMEOUT, pexpect.EOF], timeout=60)
    if prompt != 0:
        return "ERROR: backtrace did not finish"
    backtrace = gdb.before

    gdb.sendline("quit")
    prompt = gdb.expect([pexpect.TIMEOUT, pexpect.EOF], timeout=5)

    return backtrace


def check_core_dumps(context):
    """
    return True if unexpected crash happened, False otherwise
    """

    backtraces = ""
    crash_test = False
    other_crash = False
    for filename in os.listdir("/var/dracut_test/client_dumps/"):
        if filename.startswith("dump_"):
            if filename == "dump_dracut_crash_test":
                crash_test = True
            else:
                other_crash = True
            backtraces += filename + ":\n" + get_backtrace(context, filename) + "\n\n"
            nmci.lib.embed_file_if_exists(
                context,
                "/var/dracut_test/client_dumps/" + filename,
                mime_type="link",
                caption="Dracut Crash Dump",
            )

    if crash_test or other_crash:
        context.embed("text/plain", backtraces, caption="Dracut Backtraces")

    # return True (crash not OK) if the is crash other than dracut_crash_test,
    # or crash_test and context.dracut_crash_test differ
    return other_crash or (crash_test != getattr(context, "dracut_crash_test", False))


def prepare_checks(checks):
    nmci.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_CHECK $TESTDIR/client_check/; "
        "rm -rf $TESTDIR/client_check/*; "
        "cp ./check_lib/*.sh $TESTDIR/client_check/; "
    )
    with open("/var/dracut_test/client_check/client_check.sh", "w") as f:
        f.write("client_check() {\n" + checks + "}")
    nmci.run("cd contrib/dracut/; . ./setup.sh; umount $DEV_CHECK")


@step("Run dracut test")
def dracut_run(context):
    qemu_args = []
    kernel_args = (
        "rd.net.timeout.dhcp=10 panic=1 systemd.crash_reboot rd.shell=0 "
        "rd.debug loglevel=7 rd.retry=50 biosdevname=0 net.ifnames=0 noapic "
    )
    kernel_arch_args = {
        "x86_64": "console=ttyS0,115200n81 ",
    }
    arch = context.arch
    if arch in kernel_arch_args.keys():
        kernel_args += kernel_arch_args[arch]
    initrd = "initramfs.client.NM"
    checks = ""
    timeout = "8m"
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

    prepare_checks(checks)

    # replace env of child processes
    os.environ["RAM"] = ram
    os.environ["TIMEOUT"] = timeout

    if timeout.endswith("m"):
        p_timeout = int(timeout.strip("m")) * 60 + 10
    else:
        p_timeout = int(timeout) + 10

    proc = context.pexpect_spawn(
        os.getcwd() + "/contrib/dracut/run-qemu",
        [
            *qemu_args,
            "-append",
            kernel_args,
            "-initrd",
            "$TESTDIR/" + initrd,
        ],
        cwd="./contrib/dracut/",
        timeout=p_timeout,
    )
    res = proc.expect([pexpect.EOF, pexpect.TIMEOUT])
    proc.kill(9)
    rc = proc.exitstatus

    with open("/var/dracut_test/client_state.img", "br") as f:
        result = f.read(4).decode("utf-8")

    context.dracut_boot = not result.startswith("NO")

    embed_dracut_logs(context)

    assert res == 0, "pexpect.TIMEOUT should not happen! (raise offset?)"
    assert rc == 0, f"Test run FAILED, VM returncode: {rc}, VM result: {result}"
    assert "PASS" in result, f"Test FAILED, VM result: {result}"
