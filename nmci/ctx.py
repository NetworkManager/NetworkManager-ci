import fcntl
import glob
import os
import re
import shutil
import subprocess
import time

import nmci


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
    nmci.embed.embed_data(caption, "\n".join(screen))


def stripped(x):
    return "".join([i for i in x if 31 < ord(i) < 127])


def dump_status(context, when, fail_only=False):
    nm_running = (
        nmci.process.systemctl("status NetworkManager", do_embed=False).returncode == 0
    )

    cmds = [
        'date "+%Y%m%d-%H%M%S.%N"',
        "NetworkManager --version",
        "ip addr",
        "ip -4 route",
        "ip -6 route",
        "nft list ruleset",
    ]
    if nm_running:
        cmds += [
            nmci.process.WithShell("hostnamectl 2>&1"),
            "nmcli -f ALL g",
            "nmcli -f ALL c",
            "nmcli -f ALL d",
            "nmcli -f ALL d w l",
            "NetworkManager --print-config",
            "cat /etc/resolv.conf",
            # use '[d]hclient' to not match grep command itself.
            nmci.process.WithShell("ps aux | grep -w '[d]hclient'"),
        ]

    headings = {len(cmds): "\nVeth setup network namespace and DHCP server state:\n"}

    if nm_running and os.path.isfile("/tmp/nm_veth_configured"):
        cmds += [
            "ip -n vethsetup addr",
            "ip -n vethsetup -4 route",
            "ip -n vethsetup -6 route",
            nmci.process.WithShell("ps aux | grep -w '[d]nsmasq'"),
            "ip netns exec vethsetup nft list ruleset",
        ]

    named_nss = nmci.ip.netns_list()

    # vethsetup is handled separately
    named_nss = [n for n in named_nss if n != "vethsetup"]

    if len(named_nss) > 0:
        add_to_heading = "\nStatus of other named network namespaces:\n"
        for ns in sorted(named_nss):
            heading = f"{add_to_heading}\nnetwork namespace {ns}:"
            if len(add_to_heading) > 0:
                add_to_heading = ""
            headings[len(cmds)] = heading
            cmds += [
                f"ip -n {ns} a",
                f"ip -n {ns} -4 r",
                f"ip -n {ns} -6 r",
                f"ip netns exec {ns} nft list ruleset",
            ]

    procs = [nmci.process.Popen(c, stderr=subprocess.DEVNULL) for c in cmds]

    timeout = nmci.util.start_timeout(20)
    while timeout.loop_sleep(0.05):
        any_pending = False
        for proc in procs:
            if proc.read_and_poll() is None:
                if timeout.was_expired:
                    proc.terminate_and_wait(timeout_before_kill=3)
                else:
                    any_pending = True
        if not any_pending or timeout.was_expired:
            break

    msg = ""
    for i in range(len(procs)):
        proc = procs[i]
        if i in headings.keys():
            msg = f"{msg}\n{headings[i]}"
        msg += f"\n--- {proc.argv} ---\n"
        msg += proc.stdout.decode("utf-8", errors="replace")
    if timeout.was_expired:
        msg += "\n\nWARNING: timeout expired waiting for processes. Processes were terminated."

    nmci.embed.embed_data("Status " + when, msg, fail_only=fail_only)

    # Always include memory stats
    if context.nm_pid is not None:
        try:
            kb = nmci.nmutil.nm_size_kb()
        except nmci.util.ExpectedException as e:
            msg = f"Daemon memory consumption: unknown ({e})\n"
        else:
            msg = f"Daemon memory consumption: {kb} KiB\n"
        if (
            os.path.isfile("/etc/systemd/system/NetworkManager.service")
            and nmci.process.run_code(
                "grep -q valgrind /etc/systemd/system/NetworkManager.service",
                process_hook=None,
            )
            == 0
        ):
            result = nmci.process.run(
                "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                shell=True,
                process_hook=None,
            )
            msg += result.stdout
        nmci.embed.embed_data("Memory use " + when, msg)


def check_dump_package(pkg_name):
    if pkg_name in ["NetworkManager", "ModemManager"]:
        return True
    return False


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


def check_coredump(context):
    for dump_dir in nmci.misc.coredump_list_on_disk(
        nmci.misc.COREDUMP_TYPE_SYSTEMD_COREDUMP
    ):
        print("Examining crash: " + dump_dir)
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
        if not nmci.misc.coredump_is_reported(dump_dir):
            # 'coredumpctl debug' not available in RHEL7
            if "Maipo" in context.rh_release:
                timeout = nmci.util.start_timeout(60)
                while timeout.loop_sleep(5):
                    e = False
                    try:
                        dump = nmci.process.run_stdout(
                            f"echo backtrace | coredumpctl -q -batch gdb {pid}",
                            shell=True,
                            stderr=subprocess.STDOUT,
                            ignore_stderr=True,
                            timeout=120,
                            process_hook=None,
                        )
                    except Exception as ex:
                        e = ex
                    if not e:
                        break
                if e:
                    raise e
            else:
                timeout = nmci.util.start_timeout(60)
                while timeout.loop_sleep(5):
                    e = False
                    try:
                        dump = nmci.process.run_stdout(
                            f"echo backtrace | coredumpctl debug {pid}",
                            shell=True,
                            stderr=subprocess.STDOUT,
                            ignore_stderr=True,
                            timeout=120,
                            process_hook=None,
                        )
                    except Exception as ex:
                        e = ex
                    if not e:
                        break
                if e:
                    raise e

            nmci.embed.embed_dump("COREDUMP", dump_dir, data=dump)


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
            pkg = nmci.util.file_get_content_simple(f"{dump_dir}/pkg_name")
            if not check_dump_package(pkg):
                print("* not NM related FAF")
                context.faf_countdown -= i
                context.faf_countdown = max(10, context.faf_countdown)
                return False
            else:
                NM_pkg = True

        last = last or os.path.isfile(f"{dump_dir}/last_occurrence")
        if last and not last_timestamp:
            last_timestamp = nmci.util.file_get_content_simple(
                f"{dump_dir}/last_occurrence"
            )
            if nmci.misc.coredump_is_reported(f"{dump_dir}-{last_timestamp}"):
                print("* Already reported")
                context.faf_countdown -= i
                context.faf_countdown = max(5, context.faf_countdown)
                return False
            print("* not yet reported, new crash")

        backtrace = backtrace or os.path.isfile(f"{dump_dir}/backtrace")

        if not reported_bordell and os.path.isfile(f"{dump_dir}/reported_to"):
            # embed content of reported_to for debug purposes
            nmci.process.run_stdout(f"cat {dump_dir}/reported_to", shell=True)
            reported_bordell = "bordell" in nmci.util.file_get_content_simple(
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
        nmci.process.run(
            f"ls -l {dump_dir}/{{backtrace,coredump,last_occurrence,pkg_name,reported_to}}",
            ignore_stderr=True,
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
    context.abrt_dir_change = True
    context.faf_countdown = 300
    while context.abrt_dir_change:
        context.abrt_dir_change = False
        for dump_dir in nmci.misc.coredump_list_on_disk(nmci.misc.COREDUMP_TYPE_ABRT):
            print("Entering crash dir: " + dump_dir)
            if not wait_faf_complete(context, dump_dir):
                if context.abrt_dir_change:
                    break
                continue
            reports = []
            if os.path.isfile("%s/reported_to" % (dump_dir)):
                reports = (
                    nmci.util.file_get_content_simple("%s/reported_to" % (dump_dir))
                    .strip("\n")
                    .split("\n")
                )
            urls = []
            for report in reports:
                if "URL=" in report:
                    label, url = report.replace("URL=", "", 1).split(":", 1)
                    urls.append([url.strip(), label.strip()])

            last_timestamp = nmci.util.file_get_content_simple(
                f"{dump_dir}/last_occurrence"
            )
            dump_id = f"{dump_dir}-{last_timestamp}"
            if urls:
                nmci.embed.embed_dump("FAF", dump_id, links=urls)
            else:
                if os.path.isfile("%s/backtrace" % (dump_dir)):
                    data = "Report not yet uploaded, please check FAF portal.\n\nBacktrace:\n"
                    data += nmci.util.file_get_content_simple(
                        "%s/backtrace" % (dump_dir)
                    )
                    nmci.embed.embed_dump("FAF", dump_id, data=data)
                else:
                    nmci.embed.embed_dump(
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
    if nmci.process.systemctl("is-active ModemManager", do_embed=False).returncode != 0:
        nmci.process.systemctl("restart ModemManager", do_embed=False)
        timer = 40
        while "gsm" not in nmci.process.nmcli("device", do_embed=False):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                break
    if "gsm" not in nmci.process.nmcli("device", do_embed=False):
        print("reinitialize devices")
        reset_usb_devices()
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done",
            shell=True,
            process_hook=None,
        )
        nmci.process.run_stdout(
            "for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done",
            shell=True,
            process_hook=None,
        )
        nmci.process.systemctl("restart ModemManager", do_embed=False)
        timer = 80
        while "gsm" not in nmci.process.nmcli("device", do_embed=False):
            time.sleep(1)
            timer -= 1
            if timer == 0:
                assert False, "Cannot initialize modem"
        time.sleep(60)
    return True


def setup_libreswan(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    RC = nmci.process.run_code(
        f"MODE={mode} sh prepare/libreswan.sh",
        shell=True,
        ignore_stderr=True,
        timeout=60,
    )
    if RC != 0:
        teardown_libreswan(context)
        assert False, "Libreswan setup failed"


def setup_openvpn(context, tags):
    nmci.process.run_stdout(
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
        ["Initialization Sequence Completed", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF],
        timeout=20,
    )
    assert res == 0, "OpenVPN Server did not come up in 20 seconds"
    return ovpn_proc


def restore_connections(context):
    print("* recreate all connections")
    conns = nmci.process.nmcli("-g NAME connection show").strip().split("\n")
    nmci.process.nmcli_force(["con", "del"] + conns)
    devs = [
        d
        for d in nmci.process.nmcli("-g DEVICE device").strip().split("\n")
        if not d.startswith("eth") and d != "lo" and not d.startswith("orig")
    ]
    for d in devs:
        nmci.process.nmcli_force(["dev", "del", d])
    for X in range(1, 11):
        nmci.process.nmcli(
            f"connection add type ethernet con-name testeth{X} ifname eth{X} autoconnect no"
        )
    restore_testeth0(context)


def update_udevadm(context):
    # Just wait a bit to have all files correctly written
    time.sleep(0.2)
    nmci.process.run_stdout(
        "udevadm control --reload-rules",
        timeout=15,
        ignore_stderr=True,
    )
    nmci.process.run_stdout(
        "udevadm settle --timeout=5",
        timeout=15,
        ignore_stderr=True,
    )
    time.sleep(0.8)


def manage_veths(context):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"'
        nmci.util.file_set_content("/etc/udev/rules.d/88-veths-eth.rules", [rule])
        update_udevadm(context)


def unmanage_veths(context):
    nmci.process.run_stdout("rm -f /etc/udev/rules.d/88-veths-*.rules")
    update_udevadm(context)


def after_crash_reset(context):
    print("@after_crash_reset")

    print("Stop NM")
    nmci.nmutil.stop_NM_service()

    print("Remove all links except eth*")
    allowed_links = (
        [b"lo"] + [b"wwan0"] + [f"eth{i}".encode("utf-8") for i in range(0, 11)]
    )
    for link in nmci.ip.link_show_all(binary=True):
        if link["ifname"] in allowed_links or link["ifname"].startswith(b"orig-"):
            continue
        nmci.process.run_stdout(
            "ip link delete $'"
            + link["ifname"].decode("utf-8", "backslashreplace")
            + "'",
            shell=True,
        )

    print("Remove all ifcfg files")
    dir = "/etc/sysconfig/network-scripts"
    ifcfg_files = glob.glob(dir + "/ifcfg-*")
    nmci.process.run_stdout("rm -vrf " + " ".join(ifcfg_files))

    print("Remove all keyfiles in /etc")
    dir = "/etc/NetworkManager/system-connections"
    key_files = glob.glob(dir + "/*")
    nmci.process.run_stdout("rm -vrf " + " ".join(key_files))

    print("Remove all config in /etc except 99-test.conf")
    dir = "/etc/NetworkManager/conf.d"
    conf_files = [
        f
        for f in glob.glob(dir + "/*")
        if not f.endswith("/99-test.conf") or not f.endswith("/99-unmanage-orig.conf")
    ]
    nmci.process.run_stdout(["rm", "-vrf", *conf_files])

    print("Remove /run/NetworkManager/")
    if os.path.isdir("/run/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /run/NetworkManager/*")
    elif os.path.isdir("/var/run/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /var/run/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager run directory")

    print("Remove /var/lib/NetworkManager/")
    if os.path.isdir("/var/lib/NetworkManager/"):
        nmci.process.run_stdout("rm -vrf /var/lib/NetworkManager/*")
    else:
        print("Warning: could not find NetworkManager in /var/lib directory")

    print("Flush eth0 IP")
    nmci.process.run_stdout("ip addr flush dev eth0")
    nmci.process.run_stdout("ip -6 addr flush dev eth0")

    print("Start NM")
    if not nmci.nmutil.start_NM_service():
        print(
            "Unable to start NM! Something very bad happened, trying to `pkill NetworkManager`"
        )
        if nmci.process.run_code("pkill NetworkManager") == 0:
            if not nmci.nmutil.start_NM_service():
                print("NM still not up!")

    print("Wait for testeth0")
    wait_for_testeth0(context)

    if os.path.isfile("/tmp/nm_veth_configured"):
        check_vethsetup(context)
    else:
        print("Up eth1-10 links")
        for link in range(1, 11):
            nmci.process.run_stdout(f"ip link set eth{link} up")
        print("Add testseth1-10 connections")
        for link in range(1, 11):
            nmci.process.nmcli(
                f"con add type ethernet ifname eth{link} con-name testeth{link} autoconnect no"
            )


def check_vethsetup(context):
    print("Regenerate veth setup")
    nmci.process.run_stdout(
        "sh prepare/vethsetup.sh check", ignore_stderr=True, timeout=60
    )
    context.nm_pid = nmci.nmutil.nm_pid()


def teardown_libreswan(context):
    nmci.process.run_stdout("sh prepare/libreswan.sh teardown")
    print("Attach Libreswan logs")
    journal_log = nmci.misc.journal_show(
        syslog_identifier="pluto",
        cursor=context.log_cursor,
        journal_args="-o cat",
    )
    nmci.embed.embed_data("Libreswan Pluto Journal", journal_log)

    conf = nmci.util.file_get_content_simple("/opt/ipsec/connection.conf")
    nmci.embed.embed_data("Libreswan Config", conf)


def teardown_testveth(context, ns):
    print(f"Removing the setup in {ns} namespace")
    if os.path.isfile(f"/tmp/{ns}.pid"):
        nmci.process.run_stdout(f"ip netns exec {ns} pkill -SIGCONT -F /tmp/{ns}.pid")
        nmci.process.run_stdout(f"ip netns exec {ns} pkill -F /tmp/{ns}.pid")
    device = ns.split("_")[0]
    print(device)
    nmci.process.run(f"pkill -F /var/run/dhclient-{device}.pid", ignore_stderr=True)
    # We need to reset this too
    nmci.process.run_stdout("sysctl net.ipv6.conf.all.forwarding=0")

    unmanage_veths(context)
    nmci.nmutil.reload_NM_service()


def get_ethernet_devices(context):
    devs = nmci.process.nmcli("-g DEVICE,TYPE dev").strip().split("\n")
    ETHERNET = ":ethernet"
    eths = [d.replace(ETHERNET, "") for d in devs if d.endswith(ETHERNET)]
    return eths


def setup_strongswan(context):
    RC = nmci.process.run_code(
        "sh prepare/strongswan.sh", ignore_stderr=True, timeout=60
    )
    if RC != 0:
        teardown_strongswan(context)
        assert False, "Strongswan setup failed"


def teardown_strongswan(context):
    nmci.process.run_stdout("sh prepare/strongswan.sh teardown", ignore_stderr=True)


def setup_racoon(context, mode, dh_group, phase1_al="aes", phase2_al=None):
    wait_for_testeth0(context)
    if context.arch == "s390x":
        nmci.process.run_stdout(
            f"[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.{context.arch}.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    else:
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )

    RC = nmci.process.run_code(
        f"sh prepare/racoon.sh {mode} {dh_group} {phase1_al}",
        timeout=60,
        ignore_stderr=True,
    )
    if RC != 0:
        teardown_racoon(context)
        assert False, "Racoon setup failed"


def teardown_racoon(context):
    nmci.process.run_stdout("sh prepare/racoon.sh teardown")


def reset_hwaddr_nmcli(context, ifname):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        hwaddr = nmci.process.run_stdout(f"ethtool -P {ifname}").split()[2]
        nmci.process.run_stdout(f"ip link set {ifname} address {hwaddr}")
    nmci.process.run_stdout(f"ip link set {ifname} up")


def setup_hostapd(context):
    wait_for_testeth0(context)
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    if (
        nmci.process.run_code(
            "sh prepare/hostapd_wired.sh contrib/8021x/certs",
            timeout=60,
            ignore_stderr=True,
        )
        != 0
    ):
        nmci.process.run_stdout(
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
        nmci.process.run_stdout(
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
    if not nmci.process.run_search_stdout(
        "softhsm2-util --show-slots", re_token, pattern_flags=None
    ):
        nmci.process.run_stdout(
            "softhsm2-util --init-token --free --pin 1234 --so-pin 123456 --label 'nmci'"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y privkey -O",
        re_nmclient,
        pattern_flags=None,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y privkey --write-object contrib/8021x/certs/client/test_user.key.pem"
        )
    if not nmci.process.run_search_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci -y cert -O",
        re_nmclient,
        pattern_flags=None,
    ):
        nmci.process.run_stdout(
            "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so -l -p 1234 --token-label nmci --label nmclient -y cert --write-object contrib/8021x/certs/client/test_user.cert.der"
        )


def wifi_rescan(context):
    if "wpa2-psk" in nmci.process.nmcli_force("dev wifi list").stdout:
        return
    print("Commencing wireless network rescan")
    timeout = nmci.util.start_timeout(60)
    while timeout.loop_sleep(5):
        if (
            "wpa2-psk"
            not in nmci.process.nmcli_force("dev wifi list --rescan yes").stdout
        ):
            print("* still not seeing wpa2-psk")
        else:
            return
    assert False, "Not seeing wpa2-psk in 60 seconds"


def setup_hostapd_wireless(context, args=None):
    wait_for_testeth0(context)
    if context.arch != "s390x":
        # Install under RHEL7 only
        if "Maipo" in context.rh_release:
            nmci.process.run_stdout(
                "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.process.run_stdout(
            "[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    argv = ["sh", "prepare/hostapd_wireless.sh", "contrib/8021x/certs"]
    if args is not None:
        argv.extend(args)
    nmci.process.run_stdout(
        argv,
        ignore_stderr=True,
        timeout=180,
    )
    # "check" file is touched once first check is passed
    # so first setup calls rescan, later setups  calls touch "check" file
    wifi_rescan(context)


def teardown_hostapd_wireless(context):
    nmci.process.run_stdout(
        "sh prepare/hostapd_wireless.sh teardown",
        ignore_stderr=True,
        timeout=15,
    )
    context.NM_pid = nmci.nmutil.nm_pid()


def teardown_hostapd(context):
    nmci.process.run_stdout("sh prepare/hostapd_wired.sh teardown", ignore_stderr=True)
    wait_for_testeth0(context)


def restore_testeth0(context):
    print("* restoring testeth0")
    nmci.process.nmcli_force("con delete testeth0")

    if not os.path.isfile("/tmp/nm_plugin_keyfiles"):
        # defaults to ifcfg files (RHELs)
        nmci.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0",
            shell=True,
        )
    else:
        # defaults to keyfiles (F33+)
        nmci.process.run_stdout(
            "yes | cp -rf /tmp/testeth0 /etc/NetworkManager/system-connections/testeth0.nmconnection",
            shell=True,
        )

    time.sleep(1)
    nmci.process.nmcli("con reload")
    time.sleep(1)
    nmci.process.nmcli("con up testeth0")
    time.sleep(2)


def wait_for_testeth0(context):
    print("* waiting for testeth0 to connect")
    if "testeth0" not in nmci.process.nmcli("connection"):
        restore_testeth0(context)

    if "testeth0" not in nmci.process.nmcli("connection show -a"):
        print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
        if "(connected)" in nmci.process.nmcli("device show eth0"):
            profile = nmci.process.nmcli("-g GENERAL.DEVICE device show eth0").strip()
            print(
                f" ** device eth0 is connected to {profile}, let's disconnect it first"
            )
            nmci.process.nmcli_force("dev disconnect eth0")
        nmci.process.nmcli("con up testeth0")

    counter = 0
    # We need to check for all 3 items to have working connection out
    testeth0 = nmci.process.nmcli("con show testeth0")
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
        testeth0 = nmci.process.nmcli("con show testeth0")
    print(" ** we do have IPv4 complete")


def reset_hwaddr_nmtui(context, ifname):
    # This can fail in case we don't have device
    hwaddr = nmci.process.run_stdout(f"ethtool -P {ifname}").split()[2]
    nmci.process.run_stdout(f"ip link set {ifname} address {hwaddr}")


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

    output = nmci.process.run_stdout("lsusb")
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
    code, output, _ = nmci.process.run("mmcli -L")
    if code != 0:
        print("Cannot get modem info from ModemManager.")
        return None

    regex = r"/org/freedesktop/ModemManager1/Modem/(\d+)"
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        code, modem_info, _ = nmci.process.run(f"mmcli -m {modem_index}")
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
        code, sim_info, _ = nmci.process.run(f"mmcli --sim {sim_index}")
        if code != 0:
            print(f"Cannot get SIM card info at index {sim_index}.")

    if sim_info:
        return f"MODEM INFO\n{modem_info}\nSIM CARD INFO\n{sim_info}"
    else:
        return modem_info
