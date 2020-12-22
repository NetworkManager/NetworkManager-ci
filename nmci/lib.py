import sys
import os
import fcntl
import time
import re
import nmci
import glob


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
    smaps = open("/proc/%d/smaps" % nm_pid())
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

    return nmci.lib.utf_only_open_read("/tmp/journal-nm.log")


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        return open(file, mode).read().decode('utf-8', 'ignore').encode('utf-8')
    else:
        return open(file, mode, encoding='utf-8', errors='ignore').read()


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


def dump_status_nmtui(fd, when):
    fd.write("Network configuration %s scenario:\n----------------------------------\n" % when)
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
        fd.write("--- %s ---\n" % cmd)
        fd.flush()
        nmci.run(cmd, stdout=fd)
        fd.write("\n")


def dump_status_nmcli(context, when):
    context.log.write("\n\n\n" + ("="*80) + "\n")
    context.log.write("Network configuration %s:\n\n" % when)
    nm_running = nmci.command_code('systemctl status NetworkManager') == 0

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
        context.log.write("--- %s ---\n" % cmd)
        context.log.flush()
        nmci.run(cmd, stdout=context.log)
    if nm_running:
        if os.path.isfile('/tmp/nm_newveth_configured'):
            context.log.write("\nVeth setup network namespace and DHCP server state:\n")
            for cmd in ['ip netns exec vethsetup ip addr', 'ip netns exec vethsetup ip -4 route',
                        'ip netns exec vethsetup ip -6 route', 'ps aux | grep dnsmasq']:
                context.log.write("--- %s ---\n" % cmd)
                context.log.flush()
                nmci.run(cmd, stdout=context.log)
    context.log.write(("="*80) + "\n\n\n")


def check_dump_package(pkg_name):
    if pkg_name in ["NetworkManager", "ModemManager"]:
        return True
    return False


def is_dump_reported(dump_dir):
    return nmci.command_code('grep -q "%s" /tmp/reported_crashes' % (dump_dir)) == 0


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
            pid, dump_timestamp = int(dump_dir_split[4]), int(dump_dir_split[5])
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
        with open("%s/pkg_name" % (dump_dir), "r") as f:
            pkg = f.read()
        if not check_dump_package(pkg):
            continue
        with open("%s/last_occurrence" % (dump_dir), "r") as f:
            last_timestamp = f.read()
        # append last_timestamp, to check if last occurrence is reported
        if not is_dump_reported("%s-%s" % (dump_dir, last_timestamp)):
            reports = []
            if os.path.isfile("%s/reported_to" % (dump_dir)):
                with open("%s/reported_to" % (dump_dir), "r") as f:
                    reports = f.read().strip("\n").split("\n")
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
    if nmci.command_code('systemctl is-active ModemManager  > /dev/null') != 0:
        nmci.run('systemctl restart ModemManager')
        timer = 40
        while nmci.command_code("nmcli device |grep gsm > /dev/null") != 0:
            time.sleep(1)
            timer -= 1
            if timer == 0:
                break
    if nmci.command_code('nmcli d |grep gsm > /dev/null') != 0:
        print("---------------------------")
        print("reinitialize devices")
        nmci.lib.reset_usb_devices()
        nmci.run('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done')
        nmci.run('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done')
        nmci.run('systemctl restart ModemManager')
        timer = 80
        while nmci.command_code("nmcli device |grep gsm > /dev/null") != 0:
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


def setup_libreswan(mode, dh_group, phase1_al="aes", phase2_al=None):
    print("setting up libreswan")
    RC = nmci.command_code("MODE=%s sh prepare/libreswan.sh > /tmp/libreswan_setup.log" % (mode))
    if RC != 0:
        teardown_libreswan(None)
        assert False, "Libreswan setup failed"


def setup_openvpn(tags):
    print ("* writing openvpn config")
    path = "%s/contrib/openvpn" %os.getcwd()
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
    openvpn_log = open("/tmp/openvpn.log", "w")
    print ("* starting openvpn server")
    ovpn_proc = nmci.Popen("sudo openvpn /etc/openvpn/trest-server.conf",
                                   stdout=openvpn_log)

    time.sleep(1)
    counter = 1
    while nmci.command_code("grep 'Initialization Sequence Completed' /tmp/openvpn.log ") != 0:
        print (" ** waiting %ss", counter )
        time.sleep(1)
        counter += 1
        if counter == 5:
            break
    print (" ** Done" )
    return openvpn_log, ovpn_proc


def restore_connections():
    print("* recreate all connections")
    for X in range(0, 11):
        nmci.run('nmcli con del testeth%s 2>&1 > /dev/null' % X)
        nmci.run('nmcli connection add type ethernet con-name testeth%s ifname eth%s autoconnect no' % (X,X))
    restore_testeth0()


def manage_veths():
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        nmci.run('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-veths.rules''')
        nmci.run("udevadm control --reload-rules")
        nmci.run("udevadm settle --timeout=5")
        time.sleep(1)


def unmanage_veths():
    nmci.run('rm -f /etc/udev/rules.d/88-veths.rules')
    nmci.run('udevadm control --reload-rules')
    nmci.run('udevadm settle --timeout=5')
    time.sleep(1)


def teardown_libreswan(context):
    nmci.run("echo '## TEARDOWN ##' >> /tmp/libreswan_setup.log")
    nmci.run("sh prepare/libreswan.sh teardown >> /tmp/libreswan_setup.log")
    if context is not None:
        print("Attach Libreswan logs")
        nmci.run("sudo journalctl -t pluto --no-pager -o cat %s > /tmp/journal-pluto.log" % context.log_cursor)
        journal_log = utf_only_open_read("/tmp/journal-pluto.log")
        setup_log = utf_only_open_read("/tmp/libreswan_setup.log")
        conf = utf_only_open_read("/opt/ipsec/connection.conf")
        context.embed("text/plain", setup_log, caption="Libreswan Setup")
        context.embed("text/plain", journal_log, caption="Libreswan Pluto Journal")
        context.embed("text/plain", conf, caption="Libreswan Config")
    else:
        os.system("cat /tmp/libreswan_setup.log")


def teardown_testveth(context):
    print("---------------------------")
    print("removing testveth device setup for all test devices")
    if hasattr(context, 'testvethns'):
        for ns in context.testvethns:
            print("Removing the setup in %s namespace" % ns)
            nmci.run('[ -f /tmp/%s.pid ] && ip netns exec %s kill -SIGCONT $(cat /tmp/%s.pid)' % (ns, ns, ns))
            nmci.run('[ -f /tmp/%s.pid ] && kill $(cat /tmp/%s.pid)' % (ns, ns))
            nmci.run('ip netns del %s' % ns)
            nmci.run('ip link del %s' % ns.split('_')[0])
            device = ns.split('_')[0]
            print(device)
            nmci.run('kill $(cat /var/run/dhclient-*%s.pid)' % device)
    unmanage_veths()
    reload_NM_service()


def get_ethernet_devices():
    devs = nmci.command_output("nmcli dev | grep ' ethernet' | awk '{print $1}'").strip()
    return devs.split('\n')


def setup_strongswan():
    print("setting up strongswan")
    RC = nmci.command_code("sh prepare/strongswan.sh")
    if RC != 0:
        teardown_strongswan()
        assert False, "Strongswan setup failed"


def teardown_strongswan():
    nmci.run("sh prepare/strongswan.sh teardown")


def setup_racoon(mode, dh_group, phase1_al="aes", phase2_al=None):
    print("setting up racoon")
    arch = nmci.command_output("uname -p").strip()
    wait_for_testeth0()
    if arch == "s390x":
        nmci.run("[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.$(uname -p).rpm")
    else:
        # Install under RHEL7 only
        if nmci.command_code("grep -q Maipo /etc/redhat-release") == 0:
            nmci.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        nmci.run("[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools")

    RC = nmci.command_code("sh prepare/racoon.sh %s %s %s" % (mode, dh_group, phase1_al))
    if RC != 0:
        teardown_racoon()
        assert False, "Racoon setup failed"


def teardown_racoon():
    nmci.run("sh prepare/racoon.sh teardown")


def reset_hwaddr_nmcli(ifname):
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        hwaddr = nmci.command_output("ethtool -P %s" % ifname).split()[2]
        nmci.run("ip link set %s address %s" % (ifname, hwaddr))
    nmci.run("ip link set %s up" % (ifname))


def setup_hostapd():
    print("setting up hostapd")
    wait_for_testeth0()
    arch = nmci.command_output("uname -p").strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if nmci.command_code("grep -q Maipo /etc/redhat-release") == 0:
            nmci.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        nmci.run("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)")
    if nmci.command_code("sh prepare/hostapd_wired.sh tmp/8021x/certs") != 0:
        nmci.run("sh prepare/hostapd_wired.sh teardown")
        assert False, "hostapd setup failed"


def wifi_rescan():
    print("Commencing wireless network rescan")
    out = nmci.command_output("time sudo nmcli dev wifi list --rescan yes").strip()
    while 'wpa2-psk' not in out:
        time.sleep(5)
        print("* still not seeing wpa2-psk")
        out = nmci.command_output("time sudo nmcli dev wifi list --rescan yes").strip()
    print(out)


def setup_hostapd_wireless():
    print("setting up hostapd wireless")
    wait_for_testeth0()
    arch = nmci.command_output("uname -p").strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if nmci.command_code("grep -q Maipo /etc/redhat-release") == 0:
            nmci.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
        nmci.run("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)")
    if nmci.command_code("sh prepare/hostapd_wireless.sh tmp/8021x/certs namespace") != 0:
        nmci.run("sh prepare/hostapd_wireless.sh teardown")
        assert False, "hostapd_wireless setup failed"
    if not os.path.isfile('/tmp/wireless_hostapd_check.txt'):
        wifi_rescan()


def teardown_hostapd_wireless():
    nmci.run("sh prepare/hostapd_wireless.sh teardown")


def teardown_hostapd():
    nmci.run("sh prepare/hostapd_wired.sh teardown")
    wait_for_testeth0()


def restore_testeth0():
    print("* restoring testeth0")
    nmci.run("nmcli con delete testeth0 2>&1 > /dev/null")

    if not os.path.isfile('/tmp/nm_plugin_keyfiles'):
        # defaults to ifcfg files (RHELs)
        nmci.run("yes 2>/dev/null | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0")
    else:
        # defaults to keyfiles (F33+)
        nmci.run("yes 2>/dev/null | cp -rf /tmp/testeth0 /etc/NetworkManager/system-connections/testeth0.nmconnection")

    time.sleep(1)
    nmci.run("nmcli con reload")
    time.sleep(1)
    nmci.run("nmcli con up testeth0")
    time.sleep(2)


def wait_for_testeth0():
    print("* waiting for testeth0 to connect")
    if nmci.command_code("nmcli connection |grep -q testeth0") != 0:
        restore_testeth0()

    if nmci.command_code("nmcli con show -a |grep -q testeth0") != 0:
        print(" ** we don't have testeth0 activat{ing,ed}, let's do it now")
        if nmci.command_code("nmcli device show eth0 |grep -q '(connected)'") == 0:
            print(" ** device eth0 is connected, let's disconnect it first")
            nmci.run("nmcli dev disconnect eth0")
        nmci.run("nmcli con up testeth0")

    counter = 0
    # We need to check for all 3 items to have working connection out
    while nmci.command_code("nmcli connection show testeth0 |grep -qzE 'IP4.ADDRESS.*IP4.GATEWAY.*IP4.DNS'") != 0:
        time.sleep(1)
        print(" ** %s: we don't have IPv4 (address, default route or dns) complete" % counter)
        counter += 1
        if counter == 20:
            restore_testeth0()
        if counter == 40:
            assert False, "Testeth0 cannot be upped..this is wrong"
    print(" ** we do have IPv4 complete")


def reload_NM_service():
    time.sleep(0.5)
    nmci.run("pkill -HUP NetworkManager")
    time.sleep(1)


def restart_NM_service():
    nmci.run("systemctl reset-failed NetworkManager.service ; systemctl restart NetworkManager.service")


def reset_hwaddr_nmtui(ifname):
    try:
        # This can fail in case we don't have device
        hwaddr = nmci.check_output(None, "ethtool -P %s" % ifname).split()[2]
        nmci.run("ip link set %s address %s" % (ifname, hwaddr))
    except:
        pass


def find_modem():
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
        '1199:68c0': 'Sierra Wireless MC7304',
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

    output = nmci.command_output('lsusb')
    output = output.splitlines()

    if output:
        for line in output:
            for key, value in modem_dict.items():
                if line.find(str(key)) > 0:
                    return 'USB ID {} {}'.format(key, value)

    return 'USB ID 0000:0000 Modem Not in List'


def get_modem_info():
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
    output, _, code = nmci.run('mmcli -L')
    if code != 0:
        print('Cannot get modem info from ModemManager.'.format(modem_index))
        return None

    regex = r'/org/freedesktop/ModemManager1/Modem/(\d+)'
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        cmd = 'mmcli -m {}'.format(modem_index)
        modem_info, _, code = nmci.run(cmd)
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
        sim_info, _, code = nmci.run(cmd)
        if code != 0:
            print('Cannot get SIM card info at index {}.'.format(sim_index))

    if sim_info:
        return 'MODEM INFO\n{}\nSIM CARD INFO\n{}'.format(modem_info, sim_info)
    else:
        return modem_info
