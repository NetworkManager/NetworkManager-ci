import sys
import os
import fcntl
import time
import re
import nmci
import glob
import pexpect
import base64
import xml.etree.ElementTree as ET


def nm_pid():
    pid = None
    out, _, code = nmci.run("systemctl show -pMainPID NetworkManager.service")
    if code == 0:
        pid = int(out.split('=')[-1])
    if not pid:
        out, _, code = nmci.run("pgrep NetworkManager")
        if code == 0:
            pid = int(out)
    return pid


def nm_size_kb():
    memsize = 0
    pid = nm_pid()
    if not pid:
        print("Warning: unable to get mem usage, NetworkManager is not running!")
        return 0
    out, _, rc = nmci.run("sudo cat /proc/%d/smaps" % pid)
    if rc != 0:
        print("Warning: unable to get mem usage, smaps file missing for NetworkManager process!")
        return 0
    smaps = out.strip("\n").split("\n")
    for line in smaps:
        fields = line.split()
        if not fields[0] in ('Private_Dirty:', 'Swap:'):
            continue
        memsize += int(fields[1])
    return memsize


def new_log_cursor():
    return '"--after-cursor=%s"' % nmci.command_output(
        "journalctl --lines=0 --quiet --show-cursor").replace("-- cursor: ", "").strip()


def NM_log(cursor):
    file_name = "/tmp/journal-nm.log"

    with open(file_name, "w") as f:
        nmci.command_output(
            "sudo journalctl -u NetworkManager --no-pager -o cat %s" % cursor,
            stdout=f)

    if os.stat(file_name).st_size > 20000000:
        msg = "WARNING: 20M size exceeded in /tmp/journal-nm.log, skipping"
        print(msg)
        return msg

    return utf_only_open_read("/tmp/journal-nm.log")


def get_service_log(service, journal_arg):
    return nmci.run("journalctl --all --no-pager %s | grep ' %s\\['" % (journal_arg, service))[0]


def set_up_embedding(context):
    # setup formatter embed and set_title
    for formatter in context._runner.formatters:
        if "html" in formatter.name:
            if getattr(formatter, "set_title", None) is not None:
                context.set_title = formatter.set_title
            if getattr(formatter, "embedding", None) is not None:
                def embed(formatter, context):
                    def fn(mime_type, data, caption, html_el=None, fail_only=False):
                        data = data or " "
                        if html_el is None:
                            html_el = formatter.actual["act_step_embed_span"]
                        if mime_type == "call" or fail_only:
                            context._to_embed.append({
                                "html_el": html_el,
                                "mime_type": mime_type,
                                "data": data,
                                "caption": caption,
                                "fail_only": fail_only,
                                })
                        else:
                            formatter._doEmbed(html_el, mime_type, data, caption)
                            if mime_type == "link":
                                # list() on ElementTree returns children
                                last_embed = list(html_el)[-1]
                                for a_tag in last_embed.findall("a"):
                                    if a_tag.get("href", "").startswith("data:"):
                                        a_tag.set("download", a_tag.text)
                            ET.SubElement(html_el, "br")
                    return fn
                embed_fn = embed(formatter, context)
                formatter.embedding = embed_fn
                context.embed = embed_fn
                context.html_formatter = formatter

    context._to_embed = []


def set_up_commands(context):
    def _run(command, *a, **kw):
        out, err, code = nmci.run(command, *a, **kw)
        context._command_calls.append((command, code, out, err))
        return out, err, code

    def _command_output(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d" \
            % (command, code)
        return out

    def _command_output_err(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d" \
            % (command, code)
        return out, err

    def _command_code(command, *a, **kw):
        out, err, code = _run(command, *a, **kw)
        return code

    def _pexpect_spawn(*a, encoding="utf-8", logfile=None, shell=False, **kw):
        if logfile is None:
            logfile = open("/tmp/expect.log."+str(context._log_index), "w")
            context._log_index += 1
        if shell:
            a = ["/bin/bash", ["-c", *a]]
        proc = pexpect.spawn(*a, **kw, logfile=logfile, encoding=encoding)
        context._expect_procs.append((proc, logfile))
        return proc

    def _pexpect_service(*a, encoding="utf-8", logfile=None, shell=False, **kw):
        if logfile is None:
            logfile = open("/tmp/expect_service.log."+str(context._log_index), "w")
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
    context._command_calls = []
    context._expect_procs = []
    context._expect_services = []
    context._log_index = 0


def process_embeds(context, scenario_fail=False):
    for kwargs in getattr(context, "_to_embed", []):
        # execute postponed "call"s
        if kwargs["mime_type"] == "call":
            # "data" is function, "caption" is args, function returns triple
            mime_type, data, caption = kwargs["data"](*kwargs["caption"])
            kwargs["mime_type"], kwargs["data"], kwargs["caption"] = mime_type, data, caption
        # skip "fail_only" when scenario passed
        if not scenario_fail and kwargs["fail_only"]:
            continue
        # reset "fail_only" to prevent loop
        kwargs["fail_only"] = False
        context.embed(**kwargs)


def embed_service_log(context, service, descr, journal_arg=None, fail_only=False, now=True):
    print("embedding " + descr + " logs")
    if journal_arg is None:
        journal_arg = context.log_cursor
    if now:
        context.embed("text/plain", get_service_log(service, journal_arg), descr, fail_only=fail_only)
    else:
        context.embed("call", lambda: ("text/plain", get_service_log(service, journal_arg), descr), [], fail_only=fail_only)


def embed_file_if_exists(context, fname, mime_type="text/plain", caption=None, fail_only=False, remove=True):
    if os.path.isfile(fname):
        if caption is None:
            caption = fname
        print("embeding " + caption + " log (" + fname + ")")
        if mime_type == "link":
            data = [(file_to_base64_url(fname), fname)]
        else:
            data = utf_only_open_read(fname)
        if remove:
            os.remove(fname)
        context.embed(mime_type, data, caption, fail_only=fail_only)
    else:
        print("Warning: File " + repr(fname) + " not found")


def file_to_base64_url(filename):
    result = "data:application/octet-stream;base64,"
    data_base64 = base64.b64encode(
        open(filename, "rb").read())
    data_encoded = data_base64.decode("utf-8").replace("\n", "")
    return result + data_encoded


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        with open(file, mode) as f:
            data = f.read().decode('utf-8', 'ignore').encode('utf-8')
        return data
    else:
        with open(file, mode, encoding='utf-8', errors='ignore') as f:
            data = f.read()
        return data


def get_pexpect_logs(proc, logfile):
    if proc.status is None:
        proc.kill(15)
    if proc.status is None and proc.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=3) != 1:
        proc.kill(9)
    logfile.close()
    stdout = utf_only_open_read(logfile.name)
    os.remove(logfile.name)
    return ["pexpect:"+proc.name, proc.status, stdout, None]


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


def expects_to_commands(context):
    for proc, logfile in context._expect_procs:
        context._command_calls.append(get_pexpect_logs(proc, logfile))
    context._expect_procs = []
    for proc, logfile in context._expect_services:
        context._command_calls.append(("call", get_pexpect_logs, (proc, logfile)))
    context._expect_services = []


def process_commands(context, when):
    expects_to_commands(context)
    if context._command_calls:
        context.embed(
            "call", embed_commands, (context._command_calls, when), fail_only=True)
    context._command_calls = []


def get_cursored_screen(screen):
    myscreen_display = screen.display
    lst = [item for item in myscreen_display[screen.cursor.y]]
    lst[screen.cursor.x] = u'\u2588'
    myscreen_display[screen.cursor.y] = u''.join(lst)
    return myscreen_display


def print_screen(screen):
    cursored_screen = get_cursored_screen(screen)
    for i in range(len(cursored_screen)):
        print(cursored_screen[i])


def log_screen(stepname, screen, path):
    cursored_screen = get_cursored_screen(screen)
    f = open(path, 'a+')
    f.write(stepname + '\n')
    for i in range(len(cursored_screen)):
        f.write(cursored_screen[i] + '\n')
    f.flush()
    f.close()


def stripped(x):
    return "".join([i for i in x if 31 < ord(i) < 127])


def dump_status_nmtui(context, when, fail_only=False):
    msg = ""
    cmds = ['date "+%Y%m%d-%H%M%S.%N"',
            'ip link',
            'ip addr',
            'ip -4 route',
            'ip -6 route',
            'nmcli g',
            'nmcli c',
            'nmcli d',
            'nmcli d w l']
    for cmd in cmds:
        msg += "\n--- %s ---\n" % cmd
        cmd_out, _, _ = nmci.run(cmd)
        msg += cmd_out
    context.embed("text/plain", msg, "Status " + when, fail_only=fail_only)


def dump_status_nmcli(context, when, fail_only=False):
    nm_running = nmci.command_code('systemctl status NetworkManager') == 0
    msg = ""
    cmds = ['date "+%Y%m%d-%H%M%S.%N"']
    if nm_running:
        cmds += ['NetworkManager --version']
    cmds += ['ip addr',
             'ip -4 route',
             'ip -6 route']
    if nm_running:
        cmds += ['nmcli g',
                 'nmcli c',
                 'nmcli d',
                 'hostnamectl',
                 'NetworkManager --print-config',
                 'cat /etc/resolv.conf',
                 'ps aux | grep dhclient']

    for cmd in cmds:
        msg += "\n--- %s ---\n" % cmd
        cmd_out, _, _ = nmci.run(cmd)
        msg += cmd_out
    if nm_running:
        if os.path.isfile('/tmp/nm_newveth_configured'):
            msg += "\nVeth setup network namespace and DHCP server state:\n"
            for cmd in ['ip netns exec vethsetup ip addr', 'ip netns exec vethsetup ip -4 route',
                        'ip netns exec vethsetup ip -6 route', 'ps aux | grep dnsmasq']:
                msg += "\n--- %s ---\n" % cmd
                cmd_out, _, _ = nmci.run(cmd)
                msg += cmd_out

    if context.nm_pid is not None:
        msg += "NetworkManager memory consumption before: %d KiB\n" % nm_size_kb()
        if os.path.isfile("/etc/systemd/system/NetworkManager.service") \
                and nmci.command_code(
                    "grep -q valgrind /etc/systemd/system/NetworkManager.service") == 0:
            cmd_out, _, _ = nmci.run(
                    "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                    " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch")
            msg += cmd_out

    context.embed("text/plain", msg, "Status " + when, fail_only=fail_only)


def check_dump_package(pkg_name):
    if pkg_name in ["NetworkManager", "ModemManager"]:
        return True
    return False


def is_dump_reported(dump_dir):
    if not os.path.isfile("/tmp/reported_crashes"):
        return False
    with open("/tmp/reported_crashes") as reported_crashed_file:
        return dump_dir + "\n" in reported_crashed_file.readlines()


def embed_dump(context, dump_id, dump_output, caption, do_report):
    print("Attaching %s, %s" % (caption, dump_id))
    if isinstance(dump_output, str):
        mime_type = "text/plain"
    else:
        mime_type = "link"
    context.embed(mime_type, dump_output, caption=caption)
    context.crash_embeded = True
    with open("/tmp/reported_crashes", "a") as f:
        f.write(dump_id+"\n")
    if not context.crashed_step:
        if context.nm_restarted:
            if do_report:
                context.crashed_step = "crash during scenario (NM restarted)"
        else:
            if do_report:
                context.crashed_step = "crash outside steps (envsetup, before / after scenario...)"


def list_dumps(dumps_search):
    out, err, code = nmci.run("ls -d %s" % (dumps_search))
    if code != 0:
        return []
    return out.strip('\n').split('\n')


def check_coredump(context, do_report=True):
    coredump_search = "/var/lib/systemd/coredump/*"
    list_of_dumps = list_dumps(coredump_search)

    for dump_dir in list_of_dumps:
        if not dump_dir:
            continue
        print("Examing crash: " + dump_dir)
        dump_dir_split = dump_dir.split('.')
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
            dump = nmci.command_output('echo backtrace | coredumpctl debug %d' % (pid))
            embed_dump(context, dump_dir, dump, "COREDUMP", do_report)


def check_faf(context, do_report=True):
    abrt_search = "/var/spool/abrt/ccpp*"
    list_of_dumps = list_dumps(abrt_search)
    for dump_dir in list_of_dumps:
        if not dump_dir:
            continue
        print("Examing crash: " + dump_dir)
        if not os.path.isfile("%s/pkg_name" % (dump_dir)) or \
                not os.path.isfile("%s/last_occurrence" % (dump_dir)):
            print("* incomplete report, skipping.")
            continue
        pkg = utf_only_open_read("%s/pkg_name" % (dump_dir))
        if not check_dump_package(pkg):
            continue
        last_timestamp = utf_only_open_read("%s/last_occurrence" % (dump_dir))
        # append last_timestamp, to check if last occurrence is reported
        if not is_dump_reported("%s-%s" % (dump_dir, last_timestamp)):
            reports = []
            if os.path.isfile("%s/reported_to" % (dump_dir)):
                reports = utf_only_open_read("%s/reported_to" % (dump_dir)).strip("\n").split("\n")
            urls = []
            for report in reports:
                if "URL=" in report:
                    report = report.replace("URL=", "", 1).split(":", 1)
                    urls.append([report[1].strip(), report[0].strip()])
            dump_id = "%s-%s" % (dump_dir, last_timestamp)
            if urls:
                embed_dump(context, dump_id, urls, "FAF", do_report)
            else:
                if os.path.isfile("%s/backtrace" % (dump_dir)):
                    data = "Report not yet uploaded, please check FAF portal.\n\nBacktrace:\n"
                    data += utf_only_open_read("%s/backtrace" % (dump_dir))
                    embed_dump(context, dump_id, data, "FAF", do_report)
                else:
                    msg = "Report not yet uploaded, no backtrace yet, please check FAF portal."
                    embed_dump(context, dump_id, msg, "FAF", do_report)


def reset_usb_devices():
    USBDEVFS_RESET = 21780

    def getfile(dirname, filename):
        f = open("%s/%s" % (dirname, filename), "r")
        contents = f.read().encode('utf-8')
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
        f = open("/dev/bus/usb/%03d/%03d" % (busnum, devnum), 'w', os.O_WRONLY)
        try:
            fcntl.ioctl(f, USBDEVFS_RESET, 0)
        except Exception as msg:
            print(("failed to reset device:", msg))
        f.close()


def reinitialize_devices():
    if nmci.command_code('systemctl is-active ModemManager') != 0:
        nmci.run('systemctl restart ModemManager')
        timer = 40
        while nmci.command_code("nmcli device |grep gsm") != 0:
            time.sleep(1)
            timer -= 1
            if timer == 0:
                break
    if nmci.command_code('nmcli d |grep gsm') != 0:
        print("reinitialize devices")
        reset_usb_devices()
        nmci.run('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done')
        nmci.run('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done')
        nmci.run('systemctl restart ModemManager')
        timer = 80
        while nmci.command_code("nmcli device |grep gsm") != 0:
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
    RC = context.command_code("MODE=%s sh prepare/libreswan.sh" % (mode))
    if RC != 0:
        teardown_libreswan(None)
        assert False, "Libreswan setup failed"


def setup_openvpn(context, tags):
    context.run("chcon -R system_u:object_r:usr_t:s0 contrib/openvpn/sample-keys/")
    path = "%s/contrib/openvpn" % os.getcwd()
    samples = glob.glob(os.path.abspath(path))[0]
    with open("/etc/openvpn/trest-server.conf", "w") as cfg:
        cfg.write('# OpenVPN configuration for client testing')
        cfg.write("\n" + 'mode server')
        cfg.write("\n" + 'tls-server')
        cfg.write("\n" + 'port 1194')
        cfg.write("\n" + 'proto udp')
        cfg.write("\n" + 'dev tun')
        cfg.write("\n" + 'persist-key')
        cfg.write("\n" + 'persist-tun')
        cfg.write("\n" + 'ca %s/sample-keys/ca.crt' % samples)
        cfg.write("\n" + 'cert %s/sample-keys/server.crt' % samples)
        cfg.write("\n" + 'key %s/sample-keys/server.key' % samples)
        cfg.write("\n" + 'dh %s/sample-keys/dh2048.pem' % samples)
        if 'openvpn6' not in tags:
            cfg.write("\n" + 'server 172.31.70.0 255.255.255.0')
            cfg.write("\n" + 'push "dhcp-option DNS 172.31.70.53"')
            cfg.write("\n" + 'push "dhcp-option DOMAIN vpn.domain"')
        if 'openvpn4' not in tags:
            cfg.write("\n" + 'tun-ipv6')
            cfg.write("\n" + 'push tun-ipv6')
            cfg.write("\n" + 'ifconfig-ipv6 2001:db8:666:dead::1/64 2001:db8:666:dead::1')
            # Not working for newer Fedoras (rhbz1909741)
            # cfg.write("\n" + 'ifconfig-ipv6-pool 2001:db8:666:dead::/64')
            cfg.write("\n" + 'push "ifconfig-ipv6 2001:db8:666:dead::2/64 2001:db8:666:dead::1"')
            cfg.write("\n" + 'push "route-ipv6 2001:db8:666:dead::/64 2001:db8:666:dead::1"')
        cfg.write("\n")
    time.sleep(1)
    ovpn_proc = context.pexpect_service("sudo openvpn /etc/openvpn/trest-server.conf")
    res = ovpn_proc.expect(["Initialization Sequence Completed", pexpect.TIMEOUT, pexpect.EOF], timeout=20)
    assert res == 0, "OpenVPN Server did not come up in 20 seconds"
    return ovpn_proc


def restore_connections(context):
    print("* recreate all connections")
    context.run('for i in $(nmcli -g NAME connection show); do nmcli con del $i 2>&1 > /dev/null; done')
    context.run('for i in $(nmcli -g DEVICE device |grep -v -e ^eth -e lo -e orig); do nmcli dev del $i 2>&1 > /dev/null; done')
    for X in range(1, 11):
        context.run('nmcli connection add type ethernet con-name testeth%s ifname eth%s autoconnect no' % (X,X))
    restore_testeth0(context)


def manage_veths(context):
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        context.run('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-veths.rules''')
        context.run("udevadm control --reload-rules")
        context.run("udevadm settle --timeout=5")
        time.sleep(1)


def unmanage_veths(context):
    context.run('rm -f /etc/udev/rules.d/88-veths.rules')
    context.run('udevadm control --reload-rules')
    context.run('udevadm settle --timeout=5')
    time.sleep(1)


def after_crash_reset(context):
    print('@after_crash_reset')

    print("Stop NM")
    context.run("systemctl stop NetworkManager")

    print("Remove all links except eth*")
    allowed_links = [b"lo"] + [f"eth{i}".encode("utf-8") for i in range(0, 11)]
    for link in nmci.ip._link_show_all_legacy_raw():
        if link["ifname"] in allowed_links or link["ifname"].startswith(b"orig-"):
            continue
        context.run("ip link delete $'" + link['ifname'].decode("utf-8", "backslashreplace") + "'")

    print("Remove all ifcfg files")
    dir = "/etc/sysconfig/network-scripts"
    ifcfg_files = glob.glob(dir + "/ifcfg-*")
    context.run("rm -vrf " + " ".join(ifcfg_files))

    print("Remove all keyfiles in /etc")
    dir = "/etc/NetworkManager/system-connections"
    key_files = glob.glob(dir + "/*")
    context.run("rm -vrf " + " ".join(key_files))

    print("Remove all config in /etc except 99-test.conf")
    dir = "/etc/NetworkManager/conf.d"
    conf_files = [f for f in glob.glob(dir + "/*") if not f.endswith("/99-test.conf")]
    context.run("rm -vrf " + " ".join(conf_files))

    print("Remove /run/NetworkManager/")
    if os.path.isdir("/run/NetworkManager/"):
        context.run("rm -vrf /run/NetworkManager/*")
    elif os.path.isdir("/var/run/NetworkManager/"):
        context.run("rm -vrf /var/run/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager run directory")

    print("Remove /var/lib/NetworkManager/")
    if os.path.isdir("/var/lib/NetworkManager/"):
        context.run("rm -vrf /var/lib/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager in /var/lib directory")

    print("Flush eth0 IP")
    context.run("ip addr flush dev eth0")
    context.run("ip -6 addr flush dev eth0")

    print("Start NM")
    rc = context.command_code("systemctl start NetworkManager")
    if rc != 0:
        print("Unable to start NM! Something very bad happened, trying to `pkill NetworkManager`")
        if context.command_code("pkill NetworkManager") == 0:
            if context.command_code("systemctl start NetworkManager") != 0:
                print("NM still not up!")

    print("Wait for testeth0")
    wait_for_testeth0(context)

    if os.path.isfile('/tmp/nm_newveth_configured'):
        print("Regenerate veth setup")
        context.run('sh prepare/vethsetup.sh check')
    else:
        print("Up eth1-10 links")
        for link in range(1, 11):
            context.run('ip link set eth%d up' % link)
        print("Add testseth1-10 connections")
        for link in range(1, 11):
            context.run('nmcli con add type ethernet ifname eth%d con-name testeth%d autoconnect no' % (link, link))


def teardown_libreswan(context):
    context.run("sh prepare/libreswan.sh teardown")
    print("Attach Libreswan logs")
    nmci.run("sudo journalctl -t pluto --no-pager -o cat %s > /tmp/journal-pluto.log" % context.log_cursor)
    journal_log = utf_only_open_read("/tmp/journal-pluto.log")
    conf = utf_only_open_read("/opt/ipsec/connection.conf")
    context.embed("text/plain", journal_log, caption="Libreswan Pluto Journal")
    context.embed("text/plain", conf, caption="Libreswan Config")


def teardown_testveth(context):
    if hasattr(context, 'testvethns'):
        for ns in context.testvethns:
            print("Removing the setup in %s namespace" % ns)
            context.run('[ -f /tmp/%s.pid ] && ip netns exec %s kill -SIGCONT $(cat /tmp/%s.pid)' % (ns, ns, ns))
            context.run('[ -f /tmp/%s.pid ] && kill $(cat /tmp/%s.pid)' % (ns, ns))
            context.run('ip netns del %s' % ns)
            context.run('ip link del %s' % ns.split('_')[0])
            device = ns.split('_')[0]
            print(device)
            context.run('kill $(cat /var/run/dhclient-*%s.pid)' % device)
    unmanage_veths(context)
    reload_NM_service(context)


def get_ethernet_devices(context):
    devs = context.command_output("nmcli dev | grep ' ethernet' | awk '{print $1}'").strip()
    return devs.split('\n')


def setup_strongswan(context):
    RC = context.command_code("sh prepare/strongswan.sh")
    if RC != 0:
        teardown_strongswan(context)
        assert False, "Strongswan setup failed"


def teardown_strongswan(context):
    context.run("sh prepare/strongswan.sh teardown")


def setup_racoon(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    arch = context.command_output("uname -p").strip()
    wait_for_testeth0(context)
    if arch == "s390x":
        context.run("[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.$(uname -p).rpm")
    else:
        # Install under RHEL7 only
        if context.command_code("grep -q Maipo /etc/redhat-release") == 0:
            context.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        context.run("[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools")

    RC = context.command_code("sh prepare/racoon.sh %s %s %s" % (mode, dh_group, phase1_al))
    if RC != 0:
        teardown_racoon(context)
        assert False, "Racoon setup failed"


def teardown_racoon(context):
    context.run("sh prepare/racoon.sh teardown")


def reset_hwaddr_nmcli(context, ifname):
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        hwaddr = context.command_output("ethtool -P %s" % ifname).split()[2]
        context.run("ip link set %s address %s" % (ifname, hwaddr))
    context.run("ip link set %s up" % (ifname))


def setup_hostapd(context):
    wait_for_testeth0(context)
    arch = nmci.command_output("uname -p").strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if nmci.command_code("grep -q Maipo /etc/redhat-release") == 0:
            nmci.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        nmci.run("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)")
    if nmci.command_code("sh prepare/hostapd_wired.sh tmp/8021x/certs") != 0:
        nmci.run("sh prepare/hostapd_wired.sh teardown")
        assert False, "hostapd setup failed"


def wifi_rescan(context):
    print("Commencing wireless network rescan")
    out = context.command_output("time sudo nmcli dev wifi list --rescan yes").strip()
    while 'wpa2-psk' not in out:
        time.sleep(5)
        print("* still not seeing wpa2-psk")
        out = context.command_output("time sudo nmcli dev wifi list --rescan yes").strip()


def setup_hostapd_wireless(context):
    wait_for_testeth0(context)
    arch = nmci.command_output("uname -p").strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            context.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        context.run("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)")
    if context.command_code("sh prepare/hostapd_wireless.sh tmp/8021x/certs namespace") != 0:
        context.run("sh prepare/hostapd_wireless.sh teardown")
        assert False, "hostapd_wireless setup failed"
    if not os.path.isfile('/tmp/wireless_hostapd_check.txt'):
        wifi_rescan(context)


def teardown_hostapd_wireless(context):
    context.run("sh prepare/hostapd_wireless.sh teardown")


def teardown_hostapd(context):
    context.run("sh prepare/hostapd_wired.sh teardown")
    wait_for_testeth0(context)


def restore_testeth0(context):
    print("* restoring testeth0")
    context.run("nmcli con delete testeth0 2>&1 > /dev/null")

    if not os.path.isfile('/tmp/nm_plugin_keyfiles'):
        # defaults to ifcfg files (RHELs)
        context.run("yes | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0")
    else:
        # defaults to keyfiles (F33+)
        context.run("yes | cp -rf /tmp/testeth0 /etc/NetworkManager/system-connections/testeth0.nmconnection")

    time.sleep(1)
    context.run("nmcli con reload")
    time.sleep(1)
    context.run("nmcli con up testeth0")
    time.sleep(2)


def wait_for_testeth0(context):
    print("* waiting for testeth0 to connect")
    if context.command_code("nmcli connection |grep -q testeth0") != 0:
        restore_testeth0(context)

    if context.command_code("nmcli con show -a |grep -q testeth0") != 0:
        print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
        if context.command_code("nmcli device show eth0 |grep -q '(connected)'") == 0:
            print(" ** device eth0 is connected, let's disconnect it first")
            context.run("nmcli dev disconnect eth0")
        context.run("nmcli con up testeth0")

    counter = 0
    # We need to check for all 3 items to have working connection out
    while context.command_code("nmcli connection show testeth0 |grep -qzE 'IP4.ADDRESS.*IP4.GATEWAY.*IP4.DNS'") != 0:
        time.sleep(1)
        print(" ** %s: we don't have IPv4 (address, default route or dns) complete" % counter)
        counter += 1
        if counter == 20:
            restore_testeth0(context)
        if counter == 40:
            assert False, "Testeth0 cannot be upped..this is wrong"
    print(" ** we do have IPv4 complete")


def reload_NM_connections(context):
    print("reload NM connections")
    out, err, rc = context.run("nmcli con reload")
    assert rc == 0, "`nmcli con reload` failed:\n\n%s\n%s" % (out, err)


def reload_NM_service(context):
    print("reload NM service")
    time.sleep(0.5)
    context.run("pkill -HUP NetworkManager")
    time.sleep(1)


def restart_NM_service(context):
    print("restart NM service")
    context.run("systemctl reset-failed NetworkManager.service ; systemctl restart NetworkManager.service")


def reset_hwaddr_nmtui(context, ifname):
    # This can fail in case we don't have device
    hwaddr, _, _ = context.run("ethtool -P %s" % ifname)
    hwaddr = hwaddr.split()[2]
    context.run("ip link set %s address %s" % (ifname, hwaddr))


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
        '413c:8118': 'Dell Wireless 5510',
        '413c:81b6': 'Dell Wireless EM7455',
        '0bdb:190d': 'Ericsson F5521 gw',
        '0bdb:1926': 'Ericsson H5321 gw',
        '0bdb:193e': 'Ericsson N5321',
        '05c6:6000': 'HSDPA USB Stick',
        '12d1:1001': 'Huawei E1550',
        '12d1:1436': 'Huawei E173',
        '12d1:1446': 'Huawei E173',
        '12d1:1003': 'Huawei E220',
        '12d1:1506': 'Huawei E3276',
        '12d1:1465': 'Huawei K3765',
        '0421:0637': 'Nokia 21M-02',
        '1410:b001': 'Novatel Ovation MC551',
        '0b3c:f000': 'Olicard 200',
        '0b3c:c005': 'Olivetti Techcenter',
        '0af0:d033': 'Option GlobeTrotter Icon322',
        '04e8:6601': 'Samsung SGH-Z810',
        '1199:9051': 'Sierra Wireless AirCard 340U',
        '1199:68c0': 'Sierra Wireless MC7608',
        '1199:a001': 'Sierra Wireless EM7345',
        '1199:9041': 'Sierra Wireless EM7355',
        '413c:81a4': 'Sierra Wireless EM8805',
        '1199:9071': 'Sierra Wireless MC7455',
        '1199:68a2': 'Sierra Wireless MC7710',
        '03f0:371d': 'Sierra Wireless MC8355',
        '1199:68a3': 'Sierra Wireless USB 306',
        '1c9e:9603': 'Zoom 4595',
        '19d2:0117': 'ZTE MF190',
        '19d2:2000': 'ZTE MF627'
    }

    output = context.command_output('lsusb')
    output = output.splitlines()

    if output:
        for line in output:
            for key, value in modem_dict.items():
                if line.find(str(key)) > 0:
                    return 'USB ID {} {}'.format(key, value)

    return 'USB ID 0000:0000 Modem Not in List'


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
    output, _, code = context.run('mmcli -L')
    if code != 0:
        print('Cannot get modem info from ModemManager.'.format(modem_index))
        return None

    regex = r'/org/freedesktop/ModemManager1/Modem/(\d+)'
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        cmd = 'mmcli -m {}'.format(modem_index)
        modem_info, _, code = context.run(cmd)
        if code != 0:
            print('Cannot get modem info at index {}.'.format(modem_index))
            return None
    else:
        return None

    # Get SIM card info from modem_info.
    regex = r'/org/freedesktop/ModemManager1/SIM/(\d+)'
    mo = re.search(regex, modem_info)
    if mo:
        # Get SIM card info from ModemManager.
        sim_index = mo.groups()[0]
        cmd = 'mmcli --sim {}'.format(sim_index)
        sim_info, _, code = context.run(cmd)
        if code != 0:
            print('Cannot get SIM card info at index {}.'.format(sim_index))

    if sim_info:
        return 'MODEM INFO\n{}\nSIM CARD INFO\n{}'.format(modem_info, sim_info)
    else:
        return modem_info
