# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals

import base64
import os
import signal
import subprocess
import sys
from behave import step


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        return open(file, mode).read().decode('utf-8', 'ignore').encode('utf-8')
    else:
        return open(file, mode, encoding='utf-8', errors='ignore').read()


def get_dhcpd_log(cursor):
    with open("/tmp/cursor", "w") as f:
        f.write(cursor)
    subprocess.call(
        "journalctl -all --no-pager %s | grep ' dhcpd\\[' > /tmp/journal-dhcpd.log" % cursor,
        shell=True)
    return utf_only_open_read("/tmp/journal-dhcpd.log")


def get_backtrace(filename):
    proc = subprocess.run(
        ["gdb", "-quiet"],
        cwd="/tmp/dracut_test/client_dumps/",
        stdout=subprocess.PIPE,
        check=False,
        encoding="utf-8",
        input="core-file " + filename + "\nbacktrace")
    return proc.stdout


def get_dump(filename):
    result = "data:application/octet-stream;base64,"
    data_base64 = base64.b64encode(
        open("/tmp/dracut_test/client_dumps/"+filename, "rb").read())
    data_encoded = data_base64.decode("utf-8").replace("\n", "")
    return result + data_encoded


def check_core_dumps(context):
    subprocess.call(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_DUMPS $TESTDIR/client_dumps; ",
        shell=True)

    backtraces = ""
    dumps = []

    for filename in os.listdir("/tmp/dracut_test/client_dumps/"):
        if filename.startswith("dump_"):
            backtraces += filename.replace("dump_", "", 1) + ":\n" \
                + get_backtrace(filename) + "\n\n"
            dumps.append((get_dump(filename), filename))

    subprocess.call(
        "cd contrib/dracut/; . ./setup.sh; "
        "rm -f $TESTDIR/client_dumps/dump_*; "
        "umount $DEV_DUMPS; ",
        shell=True)

    if backtraces:
        context.embed("text/plain", backtraces, caption="CRASH_IN_INITRD_BACKTRACE")
        context.embed("link", dumps, caption="CRASH_IN_INITRD_DUMP")
        return False
    else:
        return True


class QemuStopper:

    def __init__(self, proc):
        self.proc = proc
        signal.signal(signal.SIGTERM, self.stop_qemu)
        signal.signal(signal.SIGINT, self.stop_qemu)

    def stop_qemu(self, sig, frame):
        # first stop shell script to prevent qemu-kvm restart
        if self.proc.pid:
            os.killpg(self.proc.pid, signal.SIGTERM)
        # stop qemu-kvm
        subprocess.call("cd contrib/dracut/; . ./setup.sh; stop_qemu;", shell=True)
        assert False, "killed externally (timeout) - called stop_qemu hook"


@step(u'Run dracut test')
def dracut_run(context):
    qemu_args = []
    kernel_args = "rd.net.timeout.dhcp=10 panic=1 systemd.crash_reboot rd.shell=0 "\
                  "rd.debug loglevel=7 rd.retry=50 biosdevname=0 net.ifnames=0 noapic "
    kernel_arch_args = {
        "x86_64": "console=ttyS0,115200n81 ",
    }
    arch = subprocess.check_output(["uname", "-p"], encoding="utf-8").strip()
    if arch in kernel_arch_args.keys():
        kernel_args += kernel_arch_args[arch]
    initrd = "initramfs.client.NM"
    checks = ""
    timeout = "8m"
    ram = "768"
    log_contains = []
    log_not_contains = []
    test_type = "nfs"
    for row in context.table:
        if "qemu" in row[0].lower():
            qemu_args += row[1].split(" ")
        elif "kernel" in row[0].lower():
            kernel_args += " " + row[1]
        elif "initrd" in row[0].lower():
            initrd = row[1]
        elif "check" in row[0].lower():
            checks += row[1] + " || die '" + '"' + row[1] + '"' + " failed'\n"
        elif "log+" in row[0].lower():
            log_contains.append(row[1])
        elif "log-" in row[0].lower():
            log_not_contains.append(row[1])
        elif "type" in row[0].lower():
            test_type = row[1]
        elif "timeout" in row[0].lower():
            timeout = row[1]
        elif "ram" in row[0].lower():
            ram = row[1]

    subprocess.call(
        "cd contrib/dracut/; . ./setup.sh; "
        "mount $DEV_CHECK $TESTDIR/client_check/; "
        "rm -rf $TESTDIR/client_check/*; "
        "cp ./check_lib/*.sh $TESTDIR/client_check/; ",
        shell=True
    )
    with open("/tmp/dracut_test/client_check/client_check.sh", "w") as f:
        f.write("client_check() {\n" + checks + "}")
    subprocess.call("cd contrib/dracut/; . ./setup.sh; umount $DEV_CHECK", shell=True)

    env = dict(os.environ)
    env["RAM"] = ram
    env["TIMEOUT"] = timeout
    with open("/tmp/dracut_boot.log", "wb") as boot_log_f:
        proc = subprocess.Popen([
            "./run-qemu",
            *qemu_args,
            "-append", kernel_args,
            "-initrd", "$TESTDIR/"+initrd,
            ],
            env=env,
            cwd="./contrib/dracut/",
            stdout=boot_log_f,
            stderr=subprocess.STDOUT,
            preexec_fn=os.setsid)
        QemuStopper(proc)
        proc.wait()
        rc = proc.returncode

    with open("/tmp/dracut_test/client_state.img", "br") as f:
        result = f.read(4).decode("utf-8")

    if not result.startswith("NO"):
        logs = {}
        logs["DRACUT_TEST"] = "-u testsuite"
        if "PASS" not in result:
            logs["DRACUT_NM"] = "-u NetworkManager -o cat"
        log_cmd = " ".join(["/tmp/%s.log '%s'" % (x, logs[x]) for x in logs])
        log_cmd = "bash contrib/dracut/get_log.sh " + test_type + " " + log_cmd
        proc = subprocess.run(log_cmd, shell=True, stdout=subprocess.PIPE, encoding="utf-8")

        if proc.returncode != 0:
            msg = "Error during log collection\nretcode:%d\noutput:%s" \
                % (proc.returncode, str(proc.stdout))
            context.embed("text/plain", msg, "DRACUT_LOGS_ERROR")
        else:
            for log in logs:
                log_f = "/tmp/" + log + ".log"
                if os.path.isfile(log_f):
                    context.embed("text/plain", utf_only_open_read(log_f) + "\n", log)
                    subprocess.call("rm -rf " + log_f, shell=True)
                else:
                    msg = "Error: log file '" + log_f + "' was not created for some reason"
                    context.embed("text/plain", msg, log)
        if proc.stdout is not None:
            context.embed("text/plain", proc.stdout, "DRACUT_LOG_COLLECTOR")

    assert check_core_dumps(context), "Crash in initrd"

    assert rc == 0, f"Test run FAILED, VM returncode: {rc}, VM result: {result}"
    assert "PASS" in result, f"Test FAILED, VM result: {result}"

    assert "no free leases" not in get_dhcpd_log(context.log_cursor), "DHCPD leases exhausted"

    boot_log = utf_only_open_read("/tmp/dracut_boot.log")
    for log_line in log_contains:
        assert log_line in boot_log, "Fail: not visible in log:\n" + log_line
    for log_line in log_not_contains:
        assert log_line not in boot_log, "Fail: visible in log:\n" + log_line
