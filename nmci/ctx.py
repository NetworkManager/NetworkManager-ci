import sys
import os
import fcntl
import time
import re
import nmci
import glob
import pexpect
import xml.etree.ElementTree as ET
import shutil

from . import misc
from . import nmutil
from . import process
from . import util


###############################################################################


class Embed:
    def __init__(self, fail_only=False):
        self.fail_only = fail_only

    def postpone(self):
        return self.fail_only

    def evalDoEmbedArgs(self):
        return (self._mime_type, self._data or "NO DATA", self._caption)


class EmbedData(Embed):
    def __init__(self, caption, data, mime_type="text/plain", fail_only=False):
        Embed.__init__(self, fail_only=fail_only)
        self._caption = caption
        self._data = data
        self._mime_type = mime_type


class EmbedLink(Embed):
    def __init__(self, caption, data, fail_only=False):
        # data must be a list of 2-tuples, where the first element
        # is the link target (href) and the second the text.
        Embed.__init__(self, fail_only=fail_only)

        new_data = []
        for d in data:
            (target, text) = d
            new_data.append((target, text))

        self._caption = caption
        self._data = new_data
        self._mime_type = "link"


class EmbedLater(Embed):
    def __init__(self, callback, fail_only=False):
        Embed.__init__(self, fail_only=fail_only)
        self._callback = callback

    def postpone(self):
        return True

    def evalDoEmbedArgs(self):
        mime_type, data, caption = self._callback()
        return (mime_type, data or "NO DATA", caption)


###############################################################################


class _CExt:
    def __init__(self, context):
        self.context = context

        # setup formatter embed and set_title
        if hasattr(context, "_runner"):
            for formatter in context._runner.formatters:
                if "html" not in formatter.name:
                    continue
                if hasattr(formatter, "set_title"):
                    self._set_title = formatter.set_title
                if hasattr(formatter, "embedding"):
                    self._to_embed = []
                    self._html_formatter = formatter
                    formatter.embedding = self._html_formatter_embedding

    def set_title(self, *a, **kw):
        if hasattr(self, "_set_title"):
            self._set_title(*a, *kw)

    def _embed_now(self, entry):
        (mime_type, data, caption) = entry.evalDoEmbedArgs()
        self._html_formatter._doEmbed(entry._html_el, mime_type, data, caption)
        if mime_type == "link":
            # list() on ElementTree returns children
            last_embed = list(entry._html_el)[-1]
            for a_tag in last_embed.findall("a"):
                if a_tag.get("href", "").startswith("data:"):
                    a_tag.set("download", a_tag.text)
        ET.SubElement(entry._html_el, "br")

    def _embed(self, entry):
        if not hasattr(self, "_html_formatter"):
            return

        entry._html_el = self._html_formatter.actual["act_step_embed_span"]

        if entry.postpone():
            self._to_embed.append(entry)
        else:
            self._embed_now(entry)

    def process_embeds(self, scenario_fail):
        if hasattr(self, "_html_formatter"):
            for entry in util.consume_list(self._to_embed):
                if scenario_fail or not entry.fail_only:
                    self._embed_now(entry)

    def _html_formatter_embedding(self, mime_type, data, caption=None):
        if mime_type == "link":
            self.embed_link(caption=caption, data=data)
        else:
            self.embed_data(caption=caption, data=data, mime_type=mime_type)

    def embed_data(self, *a, **kw):
        self._embed(EmbedData(*a, **kw))

    def embed_link(self, *a, **kw):
        self._embed(EmbedLink(*a, **kw))

    def embed_later(self, *a, **kw):
        self._embed(EmbedLater(*a, **kw))

    def embed_dump(self, caption, dump_id, *, data=None, links=None):
        print("Attaching %s, %s" % (caption, dump_id))
        assert (data is None) + (links is None) == 1
        if data is not None:
            self.embed_data(caption, data)
        else:
            self.embed_link(caption, links)
        self.context.crash_embeded = True
        with open("/tmp/reported_crashes", "a") as f:
            f.write(dump_id + "\n")

    def embed_run(self, argv, returncode, stdout, stderr, fail_only=True):
        if stdout is not None:
            try:
                stdout = util.bytes_to_str(stdout)
            except UnicodeDecodeError:
                pass
        if stderr is not None:
            try:
                stderr = util.bytes_to_str(stderr)
            except UnicodeDecodeError:
                pass

        message = f"{repr(argv)} returned {returncode}\n"
        if stdout:
            message += (
                f"STDOUT{'[binary]' if isinstance(stderr, bytes) else ''}:\n{stdout}\n"
            )
        if stderr:
            message += (
                f"STDERR{'[binary]' if isinstance(stderr, bytes) else ''}:\n{stderr}\n"
            )

        if isinstance(argv, bytes):
            title = argv.decode("utf-8", errors="replace")
        elif isinstance(argv, str):
            title = argv
        else:
            import shlex

            title = " ".join(
                shlex.quote(util.bytes_to_str(a, errors="replace")) for a in argv
            )
        if len(argv) < 30:
            title = f"Command `{title}`"
        else:
            title = f"Command `{title[:30]}...`"

        self.embed_data(title, message, fail_only=fail_only)

    def embed_service_log(
        self,
        descr,
        service=None,
        syslog_identifier=None,
        journal_args=None,
        cursor=None,
        fail_only=False,
        now=True,
    ):
        print("embedding " + descr + " logs")
        if cursor is None:
            cursor = self.context.log_cursor
        if now:
            self.embed_data(
                descr,
                misc.journal_show(
                    service=service,
                    syslog_identifier=syslog_identifier,
                    journal_args=journal_args,
                    cursor=cursor,
                ),
                fail_only=fail_only,
            )
        else:
            self.embed_later(
                lambda: (
                    "text/plain",
                    misc.journal_show(
                        service=service,
                        syslog_identifier=syslog_identifier,
                        journal_args=journal_args,
                        cursor=cursor,
                    ),
                    descr,
                ),
                fail_only=fail_only,
            )

    def embed_file_if_exists(
        self,
        caption,
        fname,
        as_base64=False,
        fail_only=False,
    ):
        if not os.path.isfile(fname):
            print("Warning: File " + repr(fname) + " not found")
            return

        if caption is None:
            caption = fname

        print("embeding " + caption + " log (" + fname + ")")

        if not as_base64:
            data = util.file_get_content_simple(fname)
            self.embed_data(caption, data, fail_only=fail_only)
            return

        import base64

        data = util.file_get_content_simple(fname, as_bytes=True)
        data_base64 = base64.b64encode(data)
        data_encoded = data_base64.decode("utf-8").replace("\n", "")
        data = "data:application/octet-stream;base64," + data_encoded

        self.embed_link(caption, [(data, fname)], fail_only=fail_only)


class _ContextProcess:
    def __init__(self, cext):
        self._cext = cext

    def context_hook(self, event, *a):
        if event == "result":
            (argv, returncode, stdout, stderr) = a
            self._cext.embed_run(
                argv,
                returncode,
                stdout,
                stderr,
            )

    def run(self, *a, **kw):
        return process.run(*a, context_hook=self.context_hook, **kw)

    def run_stdout(self, *a, **kw):
        return process.run_stdout(*a, context_hook=self.context_hook, **kw)

    def run_code(self, *a, **kw):
        return process.run_code(*a, context_hook=self.context_hook, **kw)

    def run_search_stdout(self, *a, **kw):
        return process.run_search_stdout(*a, context_hook=self.context_hook, **kw)

    def nmcli(self, *a, **kw):
        return process.nmcli(*a, context_hook=self.context_hook, **kw)

    def nmcli_force(self, *a, **kw):
        return process.nmcli_force(*a, context_hook=self.context_hook, **kw)

    def systemctl(self, *a, **kw):
        return process.systemctl(*a, context_hook=self.context_hook, **kw)


def setup(context):

    assert not hasattr(context, "embed")
    assert not hasattr(context, "cext")

    cext = _CExt(context)

    context.process = _ContextProcess(cext)
    context.cext = cext

    def _run(command, *a, **kw):
        out, err, code = nmci.run(command, *a, **kw)
        cext.embed_run(
            command,
            code,
            out,
            err,
        )
        return out, err, code

    def _command_output(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d" % (command, code)
        return out

    def _command_output_err(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d" % (command, code)
        return out, err

    def _command_code(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        return code

    def _pexpect_spawn(*a, encoding="utf-8", logfile=None, shell=False, **kw):
        if logfile is None:
            logfile = open("/tmp/expect.log." + str(context._log_index), "w")
            context._log_index += 1
        if shell:
            a = ["/bin/bash", ["-c", *a]]
        proc = pexpect.spawn(*a, **kw, logfile=logfile, encoding=encoding)
        context._expect_procs.append((proc, logfile))
        return proc

    def _pexpect_service(*a, encoding="utf-8", logfile=None, shell=False, **kw):
        if logfile is None:
            logfile = open("/tmp/expect_service.log." + str(context._log_index), "w")
            context._log_index += 1
        if shell:
            a = ["/bin/bash", ["-c", *a]]
        proc = pexpect.spawn(*a, **kw, logfile=logfile, encoding=encoding)
        context._expect_services.append((proc, logfile))
        return proc

    context.command_code = _command_code
    context.run = _run
    context.command_output = _command_output
    context.command_output_err = _command_output_err
    # pexpect_spawn commands are killed after step (if survives)
    context.pexpect_spawn = _pexpect_spawn
    # pexpect_spawn commands are killed at the end of the test
    context.pexpect_service = _pexpect_service
    context._expect_procs = []
    context._expect_services = []
    context._log_index = 0


def get_pexpect_logs(context, proc, logfile):
    status = 0
    if proc.status is None:
        proc.kill(15)
        if proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1:
            proc.kill(9)
    # this sets proc status if killed, if exception, something very wrong happened
    if proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=0.2) == 1:
        context.pexpect_failed = True
        context.cext.embed_data("DEBUG: ps aufx", nmci.process.run_stdout("ps aufx"))
    logfile.close()
    if not status:
        status = proc.status
    stdout = util.file_get_content_simple(logfile.name)
    os.remove(logfile.name)
    return ["pexpect:" + proc.name, status, stdout, None]


def embed_commands(command_calls, when):
    message = when + "\n"
    for cmd in command_calls:
        if cmd[0] == "call":
            command, code, stdout, stderr = cmd[1](*cmd[2])
        else:
            command, code, stdout, stderr = cmd
        message += f"{'-'*50}\n{repr(command)} returned {code}"
        if stdout:
            message += f"\nSTDOUT:\n{stdout}"
        if stderr:
            message += f"\nSTDERR:\n{stderr}"
        message += "\n"
    return ["text/plain", message, "Commands"]


def process_commands(context, when):
    context.pexpect_failed = False
    command_calls = []
    for proc, logfile in context._expect_procs:
        command_calls.append(get_pexpect_logs(context, proc, logfile))
    context._expect_procs = []
    for proc, logfile in context._expect_services:
        command_calls.append(("call", get_pexpect_logs, (context, proc, logfile)))
    context._expect_services = []
    assert getattr(context, "pexpect_failed", False) is False, "some pexpect has failed"

    if command_calls:
        context.cext.embed_later(
            lambda: embed_commands(command_calls, when),
            fail_only=True,
        )


def get_cursored_screen(screen):
    myscreen_display = [line for line in screen.display]
    lst = [item for item in myscreen_display[screen.cursor.y]]
    lst[screen.cursor.x] = "\u2588"
    myscreen_display[screen.cursor.y] = "".join(lst)
    return myscreen_display


def get_screen_string(screen):
    screen_string = "\n".join(screen.display)
    return screen_string


def print_screen(screen):
    cursored_screen = get_cursored_screen(screen)
    for i in range(len(cursored_screen)):
        print(cursored_screen[i])


def print_screen_wo_cursor(screen):
    for i in range(len(screen.display)):
        print(screen.display[i])


def log_tui_screen(context, screen, caption="TUI"):
    context.cext.embed_data(caption, "\n".join(screen))


def stripped(x):
    return "".join([i for i in x if 31 < ord(i) < 127])


def dump_status(context, when, fail_only=False):
    nm_running = nmci.process.systemctl("status NetworkManager").returncode == 0
    msg = ""
    cmds = ['date "+%Y%m%d-%H%M%S.%N"']
    if nm_running:
        cmds += ["NetworkManager --version"]
    cmds += ["ip addr", "ip -4 route", "ip -6 addr", "ip -6 route"]
    if nm_running:
        cmds += [
            "hostnamectl 2>&1",
            "nmcli -f ALL g",
            "nmcli -f ALL c",
            "nmcli -f ALL d",
            "nmcli -f ALL d w l",
            "NetworkManager --print-config",
            "cat /etc/resolv.conf",
            "ps aux | grep dhclient",
        ]

    for cmd in cmds:
        msg += "\n--- %s ---\n" % cmd
        result = nmci.process.run(cmd, shell=True, timeout=20)
        msg += result.stdout
    if nm_running:
        if os.path.isfile("/tmp/nm_veth_configured"):
            msg += "\nVeth setup network namespace and DHCP server state:\n"
            for cmd in [
                "ip netns exec vethsetup ip addr",
                "ip netns exec vethsetup ip -4 route",
                "ip netns exec vethsetup ip -6 addr",
                "ip netns exec vethsetup ip -6 route",
                "ps aux | grep dnsmasq",
            ]:
                msg += "\n--- %s ---\n" % cmd
                result = nmci.process.run(cmd, shell=True)
                msg += result.stdout

    context.cext.embed_data("Status " + when, msg, fail_only=fail_only)

    # Always include memory stats
    if context.nm_pid is not None:
        try:
            kb = nmutil.nm_size_kb()
        except util.ExpectedException as e:
            msg = f"Daemon memory consumption: unknown ({e})\n"
        else:
            msg = f"Daemon memory consumption: {kb} KiB\n"
        if (
            os.path.isfile("/etc/systemd/system/NetworkManager.service")
            and nmci.process.run_code(
                "grep -q valgrind /etc/systemd/system/NetworkManager.service"
            )
            == 0
        ):
            result = nmci.process.run(
                "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                shell=True,
            )
            msg += result.stdout
        context.cext.embed_data("Memory use " + when, msg)


def check_dump_package(pkg_name):
    if pkg_name in ["NetworkManager", "ModemManager"]:
        return True
    return False


def is_dump_reported(dump_dir):
    if not os.path.isfile("/tmp/reported_crashes"):
        return False
    with open("/tmp/reported_crashes") as reported_crashed_file:
        return dump_dir + "\n" in reported_crashed_file.readlines()


def check_crash(context, crashed_step):
    pid_refresh_count = getattr(context, "nm_pid_refresh_count", 0)
    if pid_refresh_count > 0:
        context.pid_refresh_count = pid_refresh_count - 1
        context.nm_pid = nmci.nmutil.nm_pid()
    elif not context.crashed_step:
        new_pid = nmci.nmutil.nm_pid()
        if new_pid != context.nm_pid:
            print(
                "NM Crashed as new PID %s is not old PID %s" % (new_pid, context.nm_pid)
            )
            context.crashed_step = crashed_step
            if not context.crashed_step:
                context.crashed_step = "crash during scenario (NM restarted)"


def list_dumps(dumps_search):
    ls = nmci.process.run(f"ls -d {dumps_search}", shell=True, ignore_stderr=True)
    if ls.returncode != 0:
        return []
    return ls.stdout.strip("\n").split("\n")


def check_coredump(context):
    coredump_search = "/var/lib/systemd/coredump/*"
    list_of_dumps = list_dumps(coredump_search)

    for dump_dir in list_of_dumps:
        if not dump_dir:
            continue
        print("Examing crash: " + dump_dir)
        dump_dir_split = dump_dir.split(".")
        if len(dump_dir_split) < 6:
            print("Some garbage in %s" % (dump_dir))
            continue
        if not check_dump_package(dump_dir_split[1]):
            continue
        try:
            pid, _ = int(dump_dir_split[4]), int(dump_dir_split[5])
        except Exception as e:
            print("Some garbage in %s: %s" % (dump_dir, str(e)))
            continue
        if not is_dump_reported(dump_dir):
            # 'coredumpctl debug' not available in RHEL7
            if "Maipo" in context.rh_release:
                dump = nmci.process.run_stdout(
                    f"echo backtrace | coredumpctl -q -batch gdb {pid}",
                    shell=True,
                    stderr=subprocess.STDOUT,
                )
            else:
                dump = nmci.process.run_stdout(
                    f"echo backtrace | coredumpctl debug {pid}",
                    shell=True,
                    stderr=subprocess.STDOUT,
                )
            context.cext.embed_dump("COREDUMP", dump_dir, data=dump)


def wait_faf_complete(context, dump_dir):
    NM_pkg = False
    last = False
    last_timestamp = 0
    backtrace = False
    reported_bordell = False
    for i in range(context.faf_countdown):
        if not os.path.isdir(dump_dir):
            # Seems like FAF found it to be a duplicate one
            context.abrt_dir_change = True
            print("* report dir went away, skipping.")
            return False

        if not NM_pkg and os.path.isfile(f"{dump_dir}/pkg_name"):
            pkg = util.file_get_content_simple(f"{dump_dir}/pkg_name")
            if not check_dump_package(pkg):
                print("* not NM related FAF")
                context.faf_countdown -= i
                context.faf_countdown = max(10, context.faf_countdown)
                return False
            else:
                NM_pkg = True

        last = last or os.path.isfile(f"{dump_dir}/last_occurrence")
        if last and not last_timestamp:
            last_timestamp = util.file_get_content_simple(f"{dump_dir}/last_occurrence")
            if is_dump_reported(f"{dump_dir}-{last_timestamp}"):
                print("* Already reported")
                context.faf_countdown -= i
                context.faf_countdown = max(5, context.faf_countdown)
                return False
            print("* not yet reported, new crash")

        backtrace = backtrace or os.path.isfile(f"{dump_dir}/backtrace")

        if not reported_bordell and os.path.isfile(f"{dump_dir}/reported_to"):
            # embed content of reported_to for debug purposes
            context.process.run_stdout(f"cat {dump_dir}/reported_to", shell=True)
            reported_bordell = "bordell" in util.file_get_content_simple(
                f"{dump_dir}/reported_to"
            )
            # if there is no sosreport.log file, crash is already reported in FAF server
            # give it 5s to be 100% sure it is not starting
            time.sleep(5)
            if not reported_bordell and not os.path.isfile(f"{dump_dir}/sosreport.log"):
                reported_bordell = True

        if NM_pkg and last and backtrace and reported_bordell:
            print(f"* all FAF files exist in {i} seconds, should be complete")
            context.faf_countdown -= i
            context.faf_countdown = max(5, context.faf_countdown)
            return True
        print(f"* report not complete yet, try #{i}")
        context.process.run(
            f"ls -l {dump_dir}/{{backtrace,coredump,last_occurrence,pkg_name,reported_to}}"
        )
        time.sleep(1)
    if backtrace:
        print("* inclomplete report, but we have backtrace")
        return True
    # give other FAF 5 seconds (already waited 300 seconds)
    context.faf_countdown = 5
    print(
        f"* incomplete FAF report in {context.faf_countdown}s, skipping in this test."
    )
    return False


def check_faf(context):
    abrt_search = "/var/spool/abrt/ccpp*"
    context.abrt_dir_change = True
    context.faf_countdown = 300
    while context.abrt_dir_change:
        context.abrt_dir_change = False
        list_of_dumps = list_dumps(abrt_search)
        for dump_dir in list_of_dumps:
            if not dump_dir:
                continue
            print("Entering crash dir: " + dump_dir)
            if not wait_faf_complete(context, dump_dir):
                if context.abrt_dir_change:
                    break
                continue
            reports = []
            if os.path.isfile("%s/reported_to" % (dump_dir)):
                reports = (
                    util.file_get_content_simple("%s/reported_to" % (dump_dir))
                    .strip("\n")
                    .split("\n")
                )
            urls = []
            for report in reports:
                if "URL=" in report:
                    label, url = report.replace("URL=", "", 1).split(":", 1)
                    urls.append([url.strip(), label.strip()])

            last_timestamp = util.file_get_content_simple(f"{dump_dir}/last_occurrence")
            dump_id = f"{dump_dir}-{last_timestamp}"
            if urls:
                context.cext.embed_dump("FAF", dump_id, links=urls)
            else:
                if os.path.isfile("%s/backtrace" % (dump_dir)):
                    data = "Report not yet uploaded, please check FAF portal.\n\nBacktrace:\n"
                    data += util.file_get_content_simple("%s/backtrace" % (dump_dir))
                    context.cext.embed_dump("FAF", dump_id, data=data)
                else:
                    context.cext.embed_dump(
                        "FAF",
                        dump_id,
                        data="Report not yet uploaded, no backtrace yet, please check FAF portal.",
                    )


def reset_usb_devices():
    USBDEVFS_RESET = 21780

    def getfile(dirname, filename):
        f = open("%s/%s" % (dirname, filename), "r")
        contents = f.read().encode("utf-8")
        f.close()
        return contents

    USB_DEV_DIR = "/sys/bus/usb/devices"
    dirs = os.listdir(USB_DEV_DIR)
    for d in dirs:
        # Skip interfaces, we only care about devices
        if d.count(":") >= 0:
            continue

        busnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "busnum"))
        devnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "devnum"))
        f = open("/dev/bus/usb/%03d/%03d" % (busnum, devnum), "w", os.O_WRONLY)
        try:
            fcntl.ioctl(f, USBDEVFS_RESET, 0)
        except Exception as msg:
            print(("failed to reset device:", msg))
        f.close()


def reinitialize_devices():
    if nmci.process.systemctl("is-active ModemManager").returncode != 0:
        nmci.process.systemctl("restart ModemManager")
        timer = 40
        while "gsm" not in nmci.process.nmcli("device"):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                break
    if "gsm" not in nmci.process.nmcli("device"):
        print("reinitialize devices")
        reset_usb_devices()
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done",
            shell=True,
        )
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done",
            shell=True,
        )
        nmci.process.systemctl("restart ModemManager")
        timer = 80
        while "gsm" not in nmci.process.nmcli("device"):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                assert False, "Cannot initialize modem"
        time.sleep(60)
    return True


def create_lock(dir):
    if os.listdir(dir) == []:
        lock = int(time.time())
        print(("* creating new gsm lock %s" % lock))
        os.mkdir("%s%s" % (dir, lock))
        return True
    else:
        return False


def is_lock_old(lock):
    lock += 3600
    if lock < int(time.time()):
        print("* lock %s is older than an hour" % lock)
        return True
    else:
        return False


def get_lock(dir):
    locks = os.listdir(dir)
    if locks == []:
        return None
    else:
        return int(locks[0])


def delete_old_lock(dir, lock):
    print("* deleting old gsm lock %s" % lock)
    os.rmdir("%s%s" % (dir, lock))


def setup_libreswan(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    RC = context.process.run_code(
        f"MODE={mode} sh prepare/libreswan.sh",
        shell=True,
        ignore_stderr=True,
        timeout=60,
    )
    if RC != 0:
        teardown_libreswan(context)
        assert False, "Libreswan setup failed"


def setup_openvpn(context, tags):
    context.process.run_stdout(
        "chcon -R system_u:object_r:usr_t:s0 contrib/openvpn/sample-keys/"
    )
    path = "%s/contrib/openvpn" % os.getcwd()
    samples = glob.glob(os.path.abspath(path))[0]
    conf = [
        "# OpenVPN configuration for client testing",
        "mode server",
        "tls-server",
        "port 1194",
        "proto udp",
        "dev tun",
        "persist-key",
        "persist-tun",
        f"ca {samples}/sample-keys/ca.crt",
        f"cert {samples}/sample-keys/server.crt",
        f"key {samples}/sample-keys/server.key",
        f"dh {samples}/sample-keys/dh2048.pem",
    ]
    if "openvpn6" not in tags:
        conf += [
            "server 172.31.70.0 255.255.255.0",
            'push "dhcp-option DNS 172.31.70.53"',
            'push "dhcp-option DOMAIN vpn.domain"',
        ]
    if "openvpn4" not in tags:
        conf += [
            "tun-ipv6",
            "push tun-ipv6",
            "ifconfig-ipv6 2001:db8:666:dead::1/64 2001:db8:666:dead::1",
            'push "ifconfig-ipv6 2001:db8:666:dead::2/64 2001:db8:666:dead::1"',
            # Not working for newer Fedoras (rhbz1909741)
            # 'ifconfig-ipv6-pool 2001:db8:666:dead::/64',
            'push "route-ipv6 2001:db8:666:dead::/64 2001:db8:666:dead::1"',
        ]
    nmci.util.file_set_content("/etc/openvpn/trest-server.conf", conf)
    time.sleep(1)
    ovpn_proc = context.pexpect_service("sudo openvpn /etc/openvpn/trest-server.conf")
    res = ovpn_proc.expect(
        ["Initialization Sequence Completed", pexpect.TIMEOUT, pexpect.EOF], timeout=20
    )
    assert res == 0, "OpenVPN Server did not come up in 20 seconds"
    return ovpn_proc


def restore_connections(context):
    print("* recreate all connections")
    conns = context.process.nmcli("-g NAME connection show").strip().split("\n")
    context.process.nmcli_force(["con", "del"] + conns)
    devs = [
        d
        for d in context.process.nmcli("-g DEVICE device").strip().split("\n")
        if not d.startswith("eth") and d != "lo" and not d.startswith("orig")
    ]
    for d in devs:
        context.process.nmcli_force(["dev", "del", d])
    for X in range(1, 11):
        context.process.nmcli(
            f"connection add type ethernet con-name testeth{X} ifname eth{X} autoconnect no"
        )
    restore_testeth0(context)


def manage_veths(context):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"'
        nmci.util.file_set_content("/etc/udev/rules.d/88-veths.rules", [rule])
        context.process.run_stdout("udevadm control --reload-rules")
        context.process.run_stdout("udevadm settle --timeout=5")
        time.sleep(1)


def unmanage_veths(context):
    context.process.run_stdout("rm -f /etc/udev/rules.d/88-veths.rules")
    context.process.run_stdout("udevadm control --reload-rules")
    context.process.run_stdout("udevadm settle --timeout=5")
    time.sleep(1)


def after_crash_reset(context):
    print("@after_crash_reset")

    print("Stop NM")
    stop_NM_service(context)

    print("Remove all links except eth*")
    allowed_links = [b"lo"] + [f"eth{i}".encode("utf-8") for i in range(0, 11)]
    for link in nmci.ip.link_show_all(binary=True):
        if link["ifname"] in allowed_links or link["ifname"].startswith(b"orig-"):
            continue
        context.process.run_stdout(
            "ip link delete $'"
            + link["ifname"].decode("utf-8", "backslashreplace")
            + "'",
            shell=True,
        )

    print("Remove all ifcfg files")
    dir = "/etc/sysconfig/network-scripts"
    ifcfg_files = glob.glob(dir + "/ifcfg-*")
    context.process.run_stdout("rm -vrf " + " ".join(ifcfg_files))

    print("Remove all keyfiles in /etc")
    dir = "/etc/NetworkManager/system-connections"
    key_files = glob.glob(dir + "/*")
    context.process.run_stdout("rm -vrf " + " ".join(key_files))

    print("Remove all config in /etc except 99-test.conf")
    dir = "/etc/NetworkManager/conf.d"
    conf_files = [
        f
        for f in glob.glob(dir + "/*")
        if not f.endswith("/99-test.conf") or not f.endswith("/99-unmanage-orig.conf")
    ]
    context.process.run_stdout(["rm", "-vrf", *conf_files])

    print("Remove /run/NetworkManager/")
    if os.path.isdir("/run/NetworkManager/"):
        context.process.run_stdout("rm -vrf /run/NetworkManager/*")
    elif os.path.isdir("/var/run/NetworkManager/"):
        context.process.run_stdout("rm -vrf /var/run/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager run directory")

    print("Remove /var/lib/NetworkManager/")
    if os.path.isdir("/var/lib/NetworkManager/"):
        context.process.run_stdout("rm -vrf /var/lib/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager in /var/lib directory")

    print("Flush eth0 IP")
    context.process.run_stdout("ip addr flush dev eth0")
    context.process.run_stdout("ip -6 addr flush dev eth0")

    print("Start NM")
    if not start_NM_service(context):
        print(
            "Unable to start NM! Something very bad happened, trying to `pkill NetworkManager`"
        )
        if context.process.run_code("pkill NetworkManager") == 0:
            if not start_NM_service(context):
                print("NM still not up!")

    print("Wait for testeth0")
    wait_for_testeth0(context)

    if os.path.isfile("/tmp/nm_veth_configured"):
        check_vethsetup(context)
    else:
        print("Up eth1-10 links")
        for link in range(1, 11):
            context.process.run_stdout(f"ip link set eth{link} up")
        print("Add testseth1-10 connections")
        for link in range(1, 11):
            context.process.nmcli(
                f"con add type ethernet ifname eth{link} con-name testeth{link} autoconnect no"
            )


def check_vethsetup(context):
    print("Regenerate veth setup")
    context.process.run_stdout(
        "sh prepare/vethsetup.sh check", ignore_stderr=True, timeout=60
    )
    context.nm_pid = nmci.nmutil.nm_pid()


def teardown_libreswan(context):
    context.process.run_stdout("sh prepare/libreswan.sh teardown")
    print("Attach Libreswan logs")
    journal_log = misc.journal_show(
        syslog_identifier="pluto",
        cursor=context.log_cursor,
        journal_args="-o cat",
    )
    context.cext.embed_data("Libreswan Pluto Journal", journal_log)

    conf = util.file_get_content_simple("/opt/ipsec/connection.conf")
    context.cext.embed_data("Libreswan Config", conf)


def teardown_testveth(context, ns):
    print(f"Removing the setup in {ns} namespace")
    if os.path.isfile(f"/tmp/{ns}.pid"):
        context.process.run_stdout(
            f"ip netns exec {ns} pkill -SIGCONT -F /tmp/{ns}.pid"
        )
        context.process.run_stdout(f"ip netns exec {ns} pkill -F /tmp/{ns}.pid")
    device = ns.split("_")[0]
    print(device)
    context.process.run(f"pkill -F /var/run/dhclient-{device}.pid", ignore_stderr=True)
    # We need to reset this too
    context.process.run_stdout("sysctl net.ipv6.conf.all.forwarding=0")

    unmanage_veths(context)
    reload_NM_service(context)


def get_ethernet_devices(context):
    devs = context.process.nmcli("-g DEVICE,TYPE dev").strip().split("\n")
    ETHERNET = ":ethernet"
    eths = [d.replace(ETHERNET, "") for d in devs if d.endswith(ETHERNET)]
    return eths


def setup_strongswan(context):
    RC = context.process.run_code(
        "sh prepare/strongswan.sh", ignore_stderr=True, timeout=60
    )
    if RC != 0:
        teardown_strongswan(context)
        assert False, "Strongswan setup failed"


def teardown_strongswan(context):
    context.process.run_stdout("sh prepare/strongswan.sh teardown", ignore_stderr=True)


def setup_racoon(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    wait_for_testeth0(context)
    if context.arch == "s390x":
        context.process.run_stdout(
            f"[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.{context.arch}.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    else:
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            context.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        context.process.run_stdout(
            "[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )

    RC = context.process.run_code(
        f"sh prepare/racoon.sh {mode} {dh_group} {phase1_al}",
        timeout=60,
        ignore_stderr=True,
    )
    if RC != 0:
        teardown_racoon(context)
        assert False, "Racoon setup failed"


def teardown_racoon(context):
    context.process.run_stdout("sh prepare/racoon.sh teardown")


def reset_hwaddr_nmcli(context, ifname):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        hwaddr = context.process.run_stdout(f"ethtool -P {ifname}").split()[2]
        context.process.run_stdout(f"ip link set {ifname} address {hwaddr}")
    context.process.run_stdout(f"ip link set {ifname} up")


def setup_hostapd(context):
    wait_for_testeth0(context)
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            context.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        context.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    if (
        context.process.run_code(
            "sh prepare/hostapd_wired.sh contrib/8021x/certs",
            timeout=60,
            ignore_stderr=True,
        )
        != 0
    ):
        context.process.run_stdout(
            "sh prepare/hostapd_wired.sh teardown", ignore_stderr=True
        )
        assert False, "hostapd setup failed"


def setup_pkcs11(context):
    """
    Don't touch token, key or cert if they're already present in order
    to avoid SoftHSM errors. No teardown for this reason, too.
    """
    install_packages = []
    if not shutil.which("softhsm2-util"):
        install_packages.append("softhsm")
    if not shutil.which("pkcs11-tool"):
        install_packages.append("opensc")
    if len(install_packages) > 0:
        context.process.run_stdout(
            f"yum -y install {' '.join(install_packages)}",
            timeout=120,
            ignore_stderr=True,
        )
    re_token = re.compile(r"(?m)Label:[\s]*nmci[\s]*$")
    re_nmclient = re.compile(r"(?m)label:[\s]*nmclient$")

    nmci.util.file_set_content(
        "/tmp/pkcs11_passwd-file",
        ["802-1x.identity:test", "802-1x.private-key-password:1234"],
    )
    if not context.process.run_search_stdout(
        "softhsm2-util --show-slots", re_token, pattern_flags=None
    ):
        context.process.run_stdout(
            "softhsm2-util --init-token --free --pin 1234 --so-pin 123456 --label 'nmci'"
        )
    if not context.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y privkey -O",
        re_nmclient,
        pattern_flags=None,
    ):
        context.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y privkey --write-object contrib/8021x/certs/client/test_user.key.pem"
        )
    if not context.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y cert -O",
        re_nmclient,
        pattern_flags=None,
    ):
        context.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y cert --write-object contrib/8021x/certs/client/test_user.cert.der"
        )


def wifi_rescan(context):
    print("Commencing wireless network rescan")
    while (
        "wpa2-psk"
        not in context.process.nmcli_force("dev wifi list --rescan yes").stdout
    ):
        time.sleep(1)
        print("* still not seeing wpa2-psk")


def setup_hostapd_wireless(context, args=None):
    wait_for_testeth0(context)
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            context.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        context.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    argv = ["sh", "prepare/hostapd_wireless.sh", "contrib/8021x/certs"]
    if args is not None:
        argv.extend(args)
    context.process.run_stdout(
        argv,
        ignore_stderr=True,
        timeout=180,
    )
    if not os.path.isfile("/tmp/wireless_hostapd_check.txt"):
        wifi_rescan(context)


def teardown_hostapd_wireless(context):
    context.process.run_stdout(
        "sh prepare/hostapd_wireless.sh teardown",
        ignore_stderr=True,
        timeout=15,
    )
    context.NM_pid = nmci.nmutil.nm_pid()


def teardown_hostapd(context):
    context.process.run_stdout(
        "sh prepare/hostapd_wired.sh teardown", ignore_stderr=True
    )
    wait_for_testeth0(context)


def restore_testeth0(context):
    print("* restoring testeth0")
    context.process.nmcli_force("con delete testeth0")

    if not os.path.isfile("/tmp/nm_plugin_keyfiles"):
        # defaults to ifcfg files (RHELs)
        context.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0",
            shell=True,
        )
    else:
        # defaults to keyfiles (F33+)
        context.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/NetworkManager/system-connections/testeth0.nmconnection",
            shell=True,
        )

    time.sleep(1)
    context.process.nmcli("con reload")
    time.sleep(1)
    context.process.nmcli("con up testeth0")
    time.sleep(2)


def wait_for_testeth0(context):
    print("* waiting for testeth0 to connect")
    if "testeth0" not in context.process.nmcli("connection"):
        restore_testeth0(context)

    if "testeth0" not in context.process.nmcli("connection show -a"):
        print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
        if "(connected)" in context.process.nmcli("device show eth0"):
            profile = context.process.nmcli(
                "-g GENERAL.DEVICE device show eth0"
            ).strip()
            print(
                f" ** device eth0 is connected to {profile}, let's disconnect it first"
            )
            context.process.nmcli_force("dev disconnect eth0")
        context.process.nmcli("con up testeth0")

    counter = 0
    # We need to check for all 3 items to have working connection out
    testeth0 = context.process.nmcli("con show testeth0")
    while (
        "IP4.ADDRESS" not in testeth0
        or "IP4.GATEWAY" not in testeth0
        or "IP4.DNS" not in testeth0
    ):
        time.sleep(1)
        print(
            f" ** {counter}: we don't have IPv4 (address, default route or dns) complete"
        )
        counter += 1
        if counter == 20:
            restore_testeth0(context)
        if counter == 60:
            assert False, "Testeth0 cannot be upped..this is wrong"
        testeth0 = context.process.nmcli("con show testeth0")
    print(" ** we do have IPv4 complete")


def reload_NM_connections(context):
    print("reload NM connections")
    context.process.nmcli("con reload")


def reload_NM_service(context):
    print("reload NM service")
    time.sleep(0.5)
    context.process.run_stdout("pkill -HUP NetworkManager")
    time.sleep(1)


def restart_NM_service(context, reset=True, timeout=10):
    print("restart NM service")
    if reset:
        context.process.systemctl("reset-failed NetworkManager.service")
    r = context.process.systemctl("restart NetworkManager.service", timeout=timeout)
    context.nm_pid = nmutil.wait_for_nm_pid(10)
    return r.returncode == 0


def start_NM_service(context, pid_wait=True, timeout=10):
    print("start NM service")
    r = context.process.systemctl("start NetworkManager.service", timeout=timeout)
    if pid_wait:
        context.nm_pid = nmutil.wait_for_nm_pid(10)
    return r.returncode == 0


def stop_NM_service(context):
    print("stop NM service")
    r = context.process.systemctl("stop NetworkManager.service")
    context.nm_pid = 0
    return r.returncode == 0


def reset_hwaddr_nmtui(context, ifname):
    # This can fail in case we don't have device
    hwaddr = context.process.run_stdout(f"ethtool -P {ifname}").split()[2]
    context.process.run_stdout(f"ip link set {ifname} address {hwaddr}")


def find_modem(context):
    """
    Find the 1st modem connected to a USB port or USB hub on a testing machine.
    :return: None/a string of detected modem specified in a dictionary.
    """
    # When to extract information about a modem?
    # - When the modem is initialized.
    # - When it is available in the output of 'mmcli -L'.
    # - When the device has type of 'gsm' in the output of 'nmcli dev'.

    modem_dict = {
        "413c:8118": "Dell Wireless 5510",
        "413c:81b6": "Dell Wireless EM7455",
        "0bdb:190d": "Ericsson F5521 gw",
        "0bdb:1926": "Ericsson H5321 gw",
        "0bdb:193e": "Ericsson N5321",
        "05c6:6000": "HSDPA USB Stick",
        "12d1:1001": "Huawei E1550",
        "12d1:1436": "Huawei E173",
        "12d1:1446": "Huawei E173",
        "12d1:1003": "Huawei E220",
        "12d1:1506": "Huawei E3276",
        "12d1:1465": "Huawei K3765",
        "0421:0637": "Nokia 21M-02",
        "1410:b001": "Novatel Ovation MC551",
        "0b3c:f000": "Olicard 200",
        "0b3c:c005": "Olivetti Techcenter",
        "0af0:d033": "Option GlobeTrotter Icon322",
        "04e8:6601": "Samsung SGH-Z810",
        "1199:9051": "Sierra Wireless AirCard 340U",
        "1199:68c0": "Sierra Wireless MC7608",
        "1199:a001": "Sierra Wireless EM7345",
        "1199:9041": "Sierra Wireless EM7355",
        "413c:81a4": "Sierra Wireless EM8805",
        "1199:9071": "Sierra Wireless MC7455",
        "1199:68a2": "Sierra Wireless MC7710",
        "03f0:371d": "Sierra Wireless MC8355",
        "1199:68a3": "Sierra Wireless USB 306",
        "1c9e:9603": "Zoom 4595",
        "19d2:0117": "ZTE MF190",
        "19d2:2000": "ZTE MF627",
    }

    output = context.process.run_stdout("lsusb")
    output = output.splitlines()

    if output:
        for line in output:
            for key, value in modem_dict.items():
                if line.find(str(key)) > 0:
                    return f"USB ID {key} {value}"

    return "USB ID 0000:0000 Modem Not in List"


def get_modem_info(context):
    """
    Get a list of connected modem via command 'mmcli -L'.
    Extract the index of the 1st modem.
    Get info about the modem via command 'mmcli -m $i'
    Find its SIM card. This optional for this function.
    Get info about the SIM card via command 'mmcli --sim $i'.
    :return: None/A string containing modem information.
    """
    output = modem_index = modem_info = sim_index = sim_info = None

    # Get a list of modems from ModemManager.
    code, output, _ = context.process.run("mmcli -L")
    if code != 0:
        print("Cannot get modem info from ModemManager.")
        return None

    regex = r"/org/freedesktop/ModemManager1/Modem/(\d+)"
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        code, modem_info, _ = context.process.run(f"mmcli -m {modem_index}")
        if code != 0:
            print(f"Cannot get modem info at index {modem_index}.")
            return None
    else:
        return None

    # Get SIM card info from modem_info.
    regex = r"/org/freedesktop/ModemManager1/SIM/(\d+)"
    mo = re.search(regex, modem_info)
    if mo:
        # Get SIM card info from ModemManager.
        sim_index = mo.groups()[0]
        code, sim_info, _ = context.process.run(f"mmcli --sim {sim_index}")
        if code != 0:
            print(f"Cannot get SIM card info at index {sim_index}.")

    if sim_info:
        return f"MODEM INFO\n{modem_info}\nSIM CARD INFO\n{sim_info}"
    else:
        return modem_info


def add_iface_to_cleanup(context, name):
    if re.match(r"^(eth[0-9]|eth10)$", name):
        context.cleanup["interfaces"]["reset"].add(name)
    else:
        context.cleanup["interfaces"]["delete"].add(name)


def cleanup(context):

    if context.cleanup["connections"]:
        context.process.nmcli_force(
            ["connection", "delete"] + list(context.cleanup["connections"]),
        )
    if context.cleanup["interfaces"]["delete"]:
        context.process.nmcli_force(
            ["device", "delete"] + list(context.cleanup["interfaces"]["delete"]),
        )
    for iface in context.cleanup["interfaces"]["reset"]:
        nmci.ctx.reset_hwaddr_nmcli(context, iface)
        if iface != "eth0":
            context.process.run(f"ip addr flush {iface}")

    for namespace, teardown in context.cleanup["namespaces"].items():
        if teardown:
            teardown_testveth(context, namespace)
        if context.process.run_search_stdout("ip netns list", namespace):
            context.process.run_stdout(f'ip netns del "{namespace}"')

    # reset cleanup, so it is safe to be called multiple times
    context.cleanup = {
        "connections": set(),
        "interfaces": {"reset": set(), "delete": set()},
        "namespaces": {},
    }
