#!/usr/bin/env python
# -*- coding: UTF-8 -*-

from __future__ import absolute_import, division, print_function, unicode_literals

import os
import pexpect
import sys
if sys.version_info < (3, 0):
    reload(sys)
    sys.setdefaultencoding('utf8')

import traceback
import string
import fcntl
from subprocess import call, Popen, PIPE, check_output, CalledProcessError
from time import sleep, localtime, strftime
from glob import glob
import re

TIMER = 0.5

IS_NMTUI = 'nmtui' in __file__

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

    output = check_output('lsusb', shell=True).decode('utf-8', 'ignore')
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
    try:
        output = check_output('mmcli -L', shell=True).decode('utf-8', 'ignore')
    except CalledProcessError:
        print('Cannot get modem info from ModemManager.'.format(modem_index))
        return None

    regex = r'/org/freedesktop/ModemManager1/Modem/(\d+)'
    mo = re.search(regex, output)
    if mo:
        modem_index = mo.groups()[0]
        cmd = 'mmcli -m {}'.format(modem_index)
        try:
            modem_info = check_output(cmd, shell=True).decode('utf-8', 'ignore')
        except CalledProcessError:
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
        try:
            sim_info = check_output(cmd, shell=True).decode('utf-8', 'ignore')
        except:
            print('Cannot get SIM card info at index {}.'.format(sim_index))

    if sim_info is None:
        return modem_info
    else:
        return 'MODEM INFO\n{}\nSIM CARD INFO\n{}'.format(modem_info, sim_info)

# the order of these steps is as follows
# 1. before scenario
# 2. before tag
# 3. after scenario
# 4. after tag

def nm_pid():
    try:
        pid = int(check_output(['systemctl', 'show', '-pMainPID', 'NetworkManager.service']).decode('utf-8', 'ignore').split('=')[-1])
    except CalledProcessError as e:
        pid = None
    if not pid:
        try:
            pid = int(check_output(['pgrep', 'NetworkManager']).decode('utf-8', 'ignore'))
        except CalledProcessError as e:
            pid = None
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
        print (cursored_screen[i])

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
    for cmd in ['ip link', 'ip addr', 'ip -4 route', 'ip -6 route',
        'nmcli g', 'nmcli c', 'nmcli d', 'nmcli d w l']:
             fd.write("--- %s ---\n" % cmd)
             fd.flush()
             call(cmd, shell=True, stdout=fd)
             fd.write("\n")

def dump_status_nmcli(context, when):
    context.log.write("\n\n\n=================================================================================\n")
    context.log.write("Network configuration %s:\n\n" % when)
    f = open(os.devnull, 'w')
    if call('systemctl status NetworkManager', shell=True, stdout=f) != 0:
        for cmd in ['ip addr', 'ip -4 route', 'ip -6 route']:
            context.log.write("--- %s ---\n" % cmd)
            context.log.flush()
            call(cmd, shell=True, stdout=context.log)
    else:
        for cmd in ['NetworkManager --version', 'ip addr', 'ip -4 route', 'ip -6 route',
            'nmcli g', 'nmcli c', 'nmcli d',
            'hostnamectl', 'NetworkManager --print-config', 'ps aux | grep dhclient']:
            #'nmcli con show testeth0',\
            #'sysctl -a|grep ra |grep ipv6 |grep "all\|default\|eth\|test"']:
            context.log.write("--- %s ---\n" % cmd)
            context.log.flush()
            call(cmd, shell=True, stdout=context.log)
        if os.path.isfile('/tmp/nm_newveth_configured'):
            context.log.write("\nVeth setup network namespace and DHCP server state:\n")
            for cmd in ['ip netns exec vethsetup ip addr', 'ip netns exec vethsetup ip -4 route',
                        'ip netns exec vethsetup ip -6 route', 'ps aux | grep dnsmasq']:
                context.log.write("--- %s ---\n" % cmd)
                context.log.flush()
                call(cmd, shell=True, stdout=context.log)
    context.log.write("==================================================================================\n\n\n")

def check_dump_package(pkg_name):
    if pkg_name in ["NetworkManager","ModemManager"]:
        return True
    return False

def is_dump_reported(dump_dir):
    return call('grep -q "%s" /tmp/reported_crashes' % (dump_dir), shell=True) == 0

def embed_dump(context, dump_dir, dump_output, caption, do_report):
    print("Attaching %s, %s" % (caption, dump_dir))
    context.embed('text/plain', dump_output, caption=caption)
    context.crash_embeded = True
    with open("/tmp/reported_crashes", "a") as f:
        f.write(dump_dir+"\n")
        f.close()
    if not context.crashed_step:
        if context.nm_restarted:
            if do_report:
                context.crashed_step = "crash during scenario (NM restarted, not sure where was the crash)"
        else:
            if do_report:
                context.crashed_step = "crash outside steps (envsetup, before / after scenario...)"

def list_dumps(dumps_search):
    p = Popen("ls -d %s" % (dumps_search), shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, bufsize=-1)
    list_of_dumps, _ = p.communicate()
    return list_of_dumps.decode('utf-8', 'ignore').strip('\n').split('\n')

def check_coredump(context, do_report=True):
    coredump_search = "/var/lib/systemd/coredump/*"
    list_of_dumps =list_dumps(coredump_search)

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
            p = Popen('echo backtrace | coredumpctl debug %d' % (pid), shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE, bufsize=-1)
            dump_output, _ = p.communicate()
            embed_dump(context, dump_dir, dump_output.decode('utf-8', 'ignore'), "COREDUMP", do_report)

def check_faf(context, do_report=True):
    abrt_search = "/var/spool/abrt/ccpp*"
    list_of_dumps =list_dumps(abrt_search)
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
            with open("%s/reported_to" % (dump_dir), "r") as f:
                reports = f.read().strip("\n").split("\n")
            url = ""
            for report in reports:
                if "URL=" in report:
                    url = report.replace("URL=","")
            print ("embedding dump with report=%s", do_report)
            embed_dump(context, "%s-%s" % (dump_dir ,last_timestamp), url, "FAF", do_report)

def reset_usb_devices():
    USBDEVFS_RESET= 21780
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
        f = open("/dev/bus/usb/%03d/%03d"%(busnum, devnum), 'w', os.O_WRONLY)
        try:
            fcntl.ioctl(f, USBDEVFS_RESET, 0)
        except Exception as msg:
            print(("failed to reset device:", msg))
        f.close()

def setup_libreswan(mode, dh_group, phase1_al="aes", phase2_al=None, ike="ikev1"):
    print ("setting up libreswan")

    RC = call("sh prepare/libreswan.sh %s %s %s %s" %(mode, dh_group, phase1_al, ike), shell=True)
    if RC != 0:
        teardown_libreswan()
        sys.exit(1)

def restore_connections ():
    print ("* recreate all connections")
    for X in range(0,11):
        call('nmcli con del testeth%s 2>&1 > /dev/null' % X, shell=True)
        call('nmcli connection add type ethernet con-name testeth%s ifname eth%s autoconnect no' % (X,X), shell=True)
    restore_testeth0 ()

def manage_veths ():
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-veths.rules''')
        call("udevadm control --reload-rules", shell=True)
        call("udevadm settle --timeout=5", shell=True)
        sleep(1)

def unmanage_veths ():
    call('rm -f /etc/udev/rules.d/88-veths.rules', shell=True)
    call('udevadm control --reload-rules', shell=True)
    call('udevadm settle --timeout=5', shell=True)
    sleep(1)

def teardown_libreswan():
    call("sh prepare/libreswan.sh teardown", shell=True)

def teardown_testveth (context):
    print("---------------------------")
    print("removing testveth device setup for all test devices")
    if hasattr(context, 'testvethns'):
        for ns in context.testvethns:
            print(("Removing the setup in %s namespace" % ns))
            call('[ -f /tmp/%s.pid ] && ip netns exec %s kill -SIGCONT $(cat /tmp/%s.pid)' % (ns, ns, ns), shell=True)
            call('[ -f /tmp/%s.pid ] && kill $(cat /tmp/%s.pid)' % (ns, ns) , shell=True)
            call('ip netns del %s' % ns, shell=True)
            call('ip link del %s' % ns.split('_')[0], shell=True)
            device=ns.split('_')[0]
            print (device)
            call('kill $(cat /var/run/dhclient-*%s.pid)' % device, shell=True)
    unmanage_veths ()
    reload_NM_service()

def get_ethernet_devices():
    devs = check_output("nmcli dev | grep ' ethernet' | awk '{print $1}'", shell=True).decode('utf-8', 'ignore').strip()
    return devs.split('\n')

def setup_strongswan():
    print ("setting up strongswan")

    RC = call("sh prepare/strongswan.sh" , shell=True)
    if RC != 0:
        teardown_strongswan()
        sys.exit(1)

def teardown_strongswan():
    call("sh prepare/strongswan.sh teardown", shell=True)

def setup_racoon(mode, dh_group, phase1_al="aes", phase2_al=None):
    print ("setting up racoon")
    arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
    wait_for_testeth0()
    if arch == "s390x":
        call("[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.$(uname -p).rpm", shell=True)
    else:
        # Install under RHEL7 only
        if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
        call("[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools", shell=True)

    RC = call("sh prepare/racoon.sh %s %s %s" %(mode, dh_group, phase1_al), shell=True)
    if RC != 0:
        teardown_racoon()
        sys.exit(1)

def teardown_racoon():
    call("sh prepare/racoon.sh teardown", shell=True)

def reset_hwaddr_nmcli(ifname):
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        hwaddr = check_output("ethtool -P %s" % ifname, shell=True).decode('utf-8', 'ignore').split()[2]
        call("ip link set %s address %s" % (ifname, hwaddr), shell=True)
    call("ip link set %s up" % (ifname), shell=True)

def setup_hostapd():
    print ("setting up hostapd")
    wait_for_testeth0()
    arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
        call("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)", shell=True)
    if call("sh prepare/hostapd_wired.sh tmp/8021x/certs", shell=True) != 0:
        call("sh prepare/hostapd_wired.sh teardown", shell=True)
        sys.exit(1)

def setup_hostapd_wireless(auth):
    print ("setting up hostapd wireless")
    wait_for_testeth0()
    arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
    if arch != "s390x":
        # Install under RHEL7 only
        if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
        call("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)", shell=True)
    if call("sh prepare/hostapd_wireless.sh tmp/8021x/certs {}".format(auth), shell=True) != 0:
        call("sh prepare/hostapd_wireless.sh teardown", shell=True)
        sys.exit(1)

def teardown_hostapd_wireless():
    call("sh prepare/hostapd_wireless.sh teardown", shell=True)

def teardown_hostapd():
    call("sh prepare/hostapd_wired.sh teardown", shell=True)
    wait_for_testeth0()

def get_lock(dir):
    locks = os.listdir(dir)
    if locks == []:
        return None
    else:
        return int(locks[0])

def delete_old_lock(dir, lock):
    print(("* deleting old gsm lock %s" %lock))
    os.rmdir("%s%s" %(dir, lock))

def restore_testeth0():
    print ("* restoring testeth0")
    call("nmcli con delete testeth0 2>&1 > /dev/null", shell=True)
    call("yes 2>/dev/null | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0", shell=True)
    sleep(1)
    call("nmcli con reload", shell=True)
    sleep(1)
    call("nmcli con up testeth0", shell=True)
    sleep(2)

def wait_for_testeth0():
    print ("* waiting for testeth0 to connect")
    if call("nmcli connection |grep -q testeth0", shell=True) != 0:
        restore_testeth0()

    if call("nmcli con show -a |grep -q testeth0", shell=True) != 0:
        print ("** we don't have testeth0 activat{ing,ed}, let's do it now")
        if call("nmcli device show eth0 |grep -q '(connected)'", shell=True) == 0:
            print ("** device eth0 is connected, let's disconnect it first")
            call("nmcli dev disconnect eth0", shell=True)
        call("nmcli con up testeth0", shell=True)

    counter=0
    while call("nmcli connection show testeth0 |grep -q IP4.ADDRESS", shell=True) != 0:
        sleep(1)
        print ("** %s: we don't have IPv4 complete" %counter)
        counter+=1
        if counter == 20:
            restore_testeth0()
        if counter == 40:
            print ("Testeth0 cannot be upped..this is wrong")
            sys.exit(1)
    print ("** we do have IPv4 complete")

def reload_NM_service():
    sleep(0.5)
    call("pkill -HUP NetworkManager", shell=True)
    sleep(1)

def restart_NM_service():
    call("sudo systemctl restart NetworkManager.service", shell=True)

def reset_hwaddr_nmtui(ifname):
    try:
        # This can fail in case we don't have device
        hwaddr = check_output("ethtool -P %s" % ifname, shell=True).decode('utf-8', 'ignore').split()[2]
        call("ip link set %s address %s" % (ifname, hwaddr), shell=True)
    except:
        pass

def before_all(context):
    def embed_data(mime_type, data, caption):
        embed_to = None
        for formatter in context._runner.formatters:
            if "html" in formatter.name:
                embed_to = formatter
        if embed_to is not None:
            embed_to.embedding(mime_type=mime_type, data=data, caption=caption)
        else:
            return None
    context.embed = embed_data

    if IS_NMTUI:
        """Setup gnome-weather stuff
        Being executed before all features
        """

        try:
            # Kill initial setup
            os.system("sudo pkill nmtui")

            # Store scenario start cursor for session logs
            context.log_cursor = check_output("journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print \"\\\"--after-cursor=\"$NF\"\\\"\"; exit}'", shell=True).decode('utf-8', 'ignore').strip()
        except Exception:
            print("Error in before_all:")
            traceback.print_exc(file=sys.stdout)

def before_scenario(context, scenario):
    if IS_NMTUI:
        try:
            os.environ['TERM'] = 'dumb'

            # Do the cleanup
            if os.path.isfile('/tmp/tui-screen.log'):
                os.remove('/tmp/tui-screen.log')
            fd = open('/tmp/tui-screen.log', 'a+')
            dump_status_nmtui(fd, 'before')
            fd.write('Screen recordings after each step:' + '\n----------------------------------\n')
            fd.flush()
            fd.close()
            context.log = None
            if 'newveth' in scenario.tags:
                if os.path.isfile('/tmp/nm_newveth_configured'):
                    if os.path.isfile('/tmp/tui-screen.log'):
                        os.remove('/tmp/tui-screen.log')
                    f = open('/tmp/tui-screen.log', 'a+')
                    f.write('INFO: VETH SETUP: this test has been disabled in VETH setup')
                    f.flush()
                    f.close()
                    sys.exit(77)
            if 'veth' in scenario.tags:
                if os.path.isfile('/tmp/nm_veth_configured'):
                    if os.path.isfile('/tmp/tui-screen.log'):
                        os.remove('/tmp/tui-screen.log')
                    f = open('/tmp/tui-screen.log', 'a+')
                    f.write('INFO: VETH mod: this test has been disabled in VETH setup')
                    f.flush()
                    f.close()
                    sys.exit(77)
            if 'eth0' in scenario.tags:
                print ("---------------------------")
                print ("eth0")# and eth10 disconnect"
                os.system("nmcli connection down id testeth0")
                sleep(1)
                if os.system("nmcli -f NAME c sh -a |grep eth0") == 0:
                    print ("shutting down eth0 once more as it is not down")
                    os.system("nmcli device disconnect eth0")
                    sleep(2)
                print ("---------------------------")
            if 'wifi' in scenario.tags:
                print("Commencing wireless network rescan")
                os.system("sudo nmcli device wifi rescan")
            if 'nmtui_general_activate_screen_no_connections' in scenario.tags:
                print ("Moving all connection profiles to temp dir")
                os.system("mkdir /tmp/backup_profiles")
                os.system("mv -f /etc/sysconfig/network-scripts/ifcfg-* /tmp/backup_profiles")
                os.system("nmcli con reload")
        except Exception:
            print("Error in before_scenario:")
            traceback.print_exc(file=sys.stdout)
    else:
        try:
            if not os.path.isfile('/tmp/nm_wifi_configured') and not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
                if call("nmcli device |grep testeth0 |grep ' connected'", shell=True) != 0:
                    call("sudo nmcli connection modify testeth0 ipv4.may-fail no", shell=True)
                    call("sudo nmcli connection up id testeth0", shell=True)
                    for attempt in range(0, 10):
                        if call("nmcli device |grep testeth0 |grep ' connected'", shell=True) == 0:
                            break
                        sleep(1)

            os.environ['TERM'] = 'dumb'

            # dump status before the test preparation starts
            context.log = open('/tmp/log_%s.html' % scenario.name,'w')
            dump_status_nmcli(context, 'before %s' % scenario.name)
            import time
            context.start_timestamp = int(time.time())

            if 'long' in scenario.tags:
                print ("---------------------------")
                print ("skipping long test case if /tmp/nm_skip_long exists")
                if os.path.isfile('/tmp/nm_skip_long'):
                    sys.exit(77)

            if 'eth0' in scenario.tags or 'delete_testeth0' in scenario.tags \
                                        or 'connect_testeth0' in scenario.tags \
                                        or 'restart' in scenario.tags \
                                        or 'dummy' in scenario.tags \
                                        or 'skip_str' in scenario.tags:
                print ("---------------------------")
                print ("skipping service restart tests if /tmp/nm_skip_restarts exists")
                if os.path.isfile('/tmp/nm_skip_restarts') or os.path.isfile('/tmp/nm_skip_STR'):
                    sys.exit(77)

            if 'secret_key_reset' in scenario.tags:
                call("mv /var/lib/NetworkManager/secret_key /var/lib/NetworkManager/secret_key_back", shell=True)

            if '1000' in scenario.tags:
                print ("---------------------------")
                print ("installing pip and pyroute2")
                wait_for_testeth0()
                if call('python -m pip install pyroute2', shell=True) != 0:
                    call ('yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python2-pyroute2-0.4.13-1.el7.noarch.rpm', shell=True)

            if 'not_on_s390x' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)

            if 'not_on_aarch64' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "aarch64":
                    sys.exit(77)

            if 'not_on_ppc64' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "ppc64":
                    sys.exit(77)

            if 'not_on_aarch64_but_pegas' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                ver = check_output("uname -r", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "aarch64":
                    if "4.5" in ver:
                        sys.exit(77)

            if 'captive_portal' in scenario.tags:
                call("sudo prepare/captive_portal.sh", shell=True)

            if 'gsm_sim' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    print ("---------------------------")
                    print ("Skipping on not intel arch")
                    sys.exit(77)
                call("sudo prepare/gsm_sim.sh modemu", shell=True)

            if 'gsm' in scenario.tags:
                call("mmcli -G debug", shell=True)
                call("nmcli general logging level DEBUG domains ALL", shell=True)
                # Extract modem's identification and keep it in a global variable for further use.
                # Only 1 modem is expected per test.
                context.modem_str = find_modem()
                if context.modem_str:
                    # Create a file containging modem identification. Use the file for HTML reports.
                    m_file = open('/tmp/modem_id', 'w')
                    m_file.write(context.modem_str)
                    m_file.close()

                if not os.path.isfile('/tmp/usb_hub'):
                    import time
                    dir = "/mnt/scratch/"
                    timeout = 3600
                    initialized = False
                    freq = 30

                    def reinitialize_devices():
                        if call('systemctl is-active ModemManager  > /dev/null', shell=True) != 0:
                            call('systemctl restart ModemManager', shell=True)
                            timer = 40
                            while call("nmcli device |grep gsm > /dev/null", shell=True) != 0:
                                sleep(1)
                                timer -= 1
                                if timer == 0:
                                    break
                        if call('nmcli d |grep gsm > /dev/null', shell=True) != 0:
                            print ("---------------------------")
                            print ("reinitialize devices")
                            reset_usb_devices()
                            call('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done', shell=True)
                            call('for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done', shell=True)
                            call('systemctl restart ModemManager', shell=True)
                            timer = 80
                            while call("nmcli device |grep gsm > /dev/null", shell=True) != 0:
                                sleep(1)
                                timer -= 1
                                if timer == 0:
                                    print ("Cannot initialize modem")
                                    sys.exit(1)
                            sleep(60)
                        global initialized
                        initialized = True

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
                            print(("* lock %s is older than an hour" % lock))
                            return True
                        else:
                            return False

                    print ("---------------------------")
                    while(True):
                        print ("* looking for gsm lock in nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock")
                        lock = get_lock(dir)
                        if not lock:
                            if not initialized:
                                reinitialize_devices()
                            if create_lock(dir):
                                break
                            else:
                                continue
                        if lock:
                            if is_lock_old(lock):
                                delete_old_lock(dir, lock)
                                continue
                            else:
                                timeout -= freq
                                print(("** still locked.. wating %s seconds before next try" % freq))
                                if not initialized:
                                    reinitialize_devices()
                                sleep(freq)
                                if timeout == 0:
                                    raise Exception("Timeout reached!")
                                continue

            if 'unmanage_eth' in scenario.tags:
                links = get_ethernet_devices()
                for link in links:
                    call('nmcli dev set %s managed no' % link, shell=True)

            if 'connectivity' in scenario.tags:
                print ("---------------------------")
                print ("add connectivity checker")
                call("echo '[connectivity]' > /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                if 'captive_portal' in scenario.tags:
                    call("echo 'uri=http://static.redhat.com:8001/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                else:
                    call("echo 'uri=http://static.redhat.com/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                call("echo 'response=OK' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                # Change in interval  would affect connectivity tests and captive portal tests too
                call("echo 'interval=30' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                reload_NM_service()

            if 'shutdown_service_any' in scenario.tags or 'bridge_manipulation_with_1000_slaves' in scenario.tags:
                call("modprobe -r qmi_wwan", shell=True)
                call("modprobe -r cdc-mbim", shell=True)

            if 'need_s390x' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "s390x":
                    sys.exit(77)

            if 'allow_veth_connections' in scenario.tags:
                if call("grep '^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"' /usr/lib/udev/rules.d/85-nm-unmanaged.rules", shell=True) == 0:
                    call("sed -i 's/^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/#ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/' /usr/lib/udev/rules.d/85-nm-unmanaged.rules", shell=True)
                    cfg = open("/etc/NetworkManager/conf.d/99-unmanaged.conf", "w")
                    cfg.write('[main]')
                    cfg.write("\n" + 'no-auto-default=eth*')
                    cfg.write("\n")
                    cfg.close()
                    reload_NM_service ()
                    context.revert_unmanaged = True
                else:
                    context.revert_unmanaged = False

            if 'not_under_internal_DHCP' in scenario.tags:
                if call("grep -q Ootpa /etc/redhat-release", shell=True) == 0 and \
                   call("NetworkManager --print-config|grep dhclient", shell=True) != 0:
                    sys.exit(77)
                if call("NetworkManager --print-config|grep internal", shell=True) == 0:
                    sys.exit(77)

            if 'newveth' in scenario.tags or 'not_on_veth' in scenario.tags:
                if os.path.isfile('/tmp/nm_newveth_configured'):
                    sys.exit(77)

            if 'disp' in scenario.tags:
                print ("---------------------------")
                print ("initialize dispatcher.txt")
                call("> /tmp/dispatcher.txt", shell=True)

            if 'eth0' in scenario.tags:
                print ("---------------------------")
                print ("eth0 disconnect")
                call("nmcli con down testeth0", shell=True)
                call('nmcli con down testeth1', shell=True)
                call('nmcli con down testeth2', shell=True)

            if 'alias' in scenario.tags:
                print ("---------------------------")
                print ("deleting eth7 connections")
                call("nmcli connection up testeth7", shell=True)
                call("nmcli connection delete eth7", shell=True)

            if 'netcat' in scenario.tags:
                print ("---------------------------")
                print ("installing netcat")
                wait_for_testeth0()
                if not os.path.isfile('/usr/bin/nc'):
                    call('sudo yum -y install nmap-ncat', shell=True)

            if 'scapy' in scenario.tags:
                print ("---------------------------")
                print ("installing scapy and tcpdump")
                wait_for_testeth0()
                if not os.path.isfile('/usr/bin/scapy'):
                    call('yum -y install tcpdump', shell=True)
                    call("python -m pip install scapy", shell=True)

            if 'mock' in scenario.tags:
                print ("---------------------------")
                print ("installing dbus-x11, pip, and python-dbusmock")
                if call('rpm -q --quiet dbus-x11', shell=True) != 0:
                    call('yum -y install dbus-x11', shell=True)
                if call('python -m pip list |grep python-dbusmock', shell=True) != 0:
                    call("sudo python -m pip install python-dbusmock", shell=True)
                call('./tmp/patch-python-dbusmock.sh')

            if 'IPy' in scenario.tags:
                print ("---------------------------")
                print ("installing dbus-x11, pip, and IPy")
                wait_for_testeth0()
                if call('rpm -q --quiet dbus-x11', shell=True) != 0:
                    call('yum -y install dbus-x11', shell=True)
                if call('python -m pip list |grep IPy', shell=True) != 0:
                    call("sudo python -m pip install IPy", shell=True)

            if 'netaddr' in scenario.tags:
                print ("---------------------------")
                print ("install netaddr")
                wait_for_testeth0()
                if call('python -m pip list |grep netaddr', shell=True) != 0:
                    call("sudo python -m pip install netaddr", shell=True)

            if 'inf' in scenario.tags:
                print ("---------------------------")
                print ("deleting infiniband connections")
                call("nmcli device disconnect inf_ib0", shell=True)
                call("nmcli device disconnect inf_ib0.8002", shell=True)
                call("nmcli connection delete inf_ib0.8002", shell=True)
                call("nmcli connection delete id inf", shell=True)
                call("nmcli connection delete id inf2", shell=True)
                call("nmcli connection delete id infiniband-inf_ib0", shell=True)
                call("nmcli connection delete id inf.8002", shell=True)
                call("nmcli connection delete id infiniband-inf_ib0.8002", shell=True)

            if 'dns_dnsmasq' in scenario.tags:
                print ("---------------------------")
                print ("set dns=dnsmasq")
                call("printf '# configured by beaker-test\n[main]\ndns=dnsmasq\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf", shell=True)
                reload_NM_service ()
                context.dns_script="dnsmasq.sh"

            if 'dns_systemd_resolved' in scenario.tags:
                print ("---------------------------")
                context.systemd_resolved= True
                print ("check systemd-resolved status:")
                if call("systemctl is-active systemd-resolved", shell=True) != 0:
                    context.systemd_resolved = False
                    print ("start systemd-resolved as it is OFF and requried, now it's:")
                    call("timeout 60 systemctl start systemd-resolved", shell=True)
                    if call("systemctl is-active systemd-resolved", shell=True) != 0:
                        print ("ERROR: Cannot start systemd-resolved")
                        sys.exit(77)
                print ("set dns=systemd-resolved")
                call("printf '# configured by beaker-test\n[main]\ndns=systemd-resolved\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf", shell=True)
                reload_NM_service ()
                context.dns_script="sd-resolved.py"

            if 'internal_DHCP' in scenario.tags:
                print ("---------------------------")
                print ("set internal DHCP")
                call("printf '# configured by beaker-test\n[main]\ndhcp=internal\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf", shell=True)
                restart_NM_service()

            if 'dhclient_DHCP' in scenario.tags:
                print ("---------------------------")
                print ("set dhclient DHCP")
                call("printf '# configured by beaker-test\n[main]\ndhcp=dhclient\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf", shell=True)
                restart_NM_service()

            if 'dummy' in scenario.tags:
                print ("---------------------------")
                print ("removing dummy devices")
                call("ip link add dummy0 type dummy", shell=True)
                call("ip link delete dummy0", shell=True)

            if 'delete_testeth0' in scenario.tags:
                print ("---------------------------")
                print ("delete testeth0")
                call("nmcli device disconnect eth0", shell=True)
                call("nmcli connection delete id testeth0", shell=True)

            if 'eth3_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth1 device")
                call('sudo nmcli device disconnect eth3', shell=True)
                call('sudo kill -9 $(cat /var/run/dhclient-eth3.pid)', shell=True)

            if 'need_dispatcher_scripts' in scenario.tags:
                print ("---------------------------")
                print ("install dispatcher scripts")
                wait_for_testeth0()
                call("yum -y install NetworkManager-config-routing-rules", shell=True)
                reload_NM_service()

            if 'firewall' in scenario.tags:
                print ("---------------------------")
                print ("starting firewall")
                if call("rpm -q firewalld", shell=True) != 0:
                    wait_for_testeth0()
                    call("sudo yum -y install firewalld", shell=True)
                call("sudo systemctl unmask firewalld", shell=True)
                call("sudo systemctl start firewalld", shell=True)
                call("sudo nmcli con modify testeth0 connection.zone public", shell=True)
                # Add a sleep here to prevent firewalld to hang
                # (see https://bugzilla.redhat.com/show_bug.cgi?id=1495893)
                call("sleep 1", shell=True)

            if 'ethernet' in scenario.tags:
                print ("---------------------------")
                print ("sanitizing eth1 and eth2")
                if call('nmcli con |grep testeth1', shell=True) == 0 or call('nmcli con |grep testeth2', shell=True) == 0:
                    call('sudo nmcli con del testeth1 testeth2', shell=True)
                    call('sudo nmcli con add type ethernet ifname eth1 con-name testeth1 autoconnect no', shell=True)
                    call('sudo nmcli con add type ethernet ifname eth2 con-name testeth2 autoconnect no', shell=True)

            if 'logging' in scenario.tags:
                context.loggin_level = check_output('nmcli -t -f LEVEL general logging', shell=True).decode('utf-8', 'ignore').strip()

            if 'logging_info_only' in scenario.tags:
                print ("---------------------------")
                print ("add info only logging")
                log = "/etc/NetworkManager/conf.d/99-xlogging.conf"
                call("echo '[logging]' > %s" %log,  shell=True)
                call("echo 'level=INFO' >> %s" %log, shell=True)
                call("echo 'domains=ALL' >> %s" %log, shell=True)
                sleep(0.5)
                restart_NM_service()
                context.nm_restarted = True
                sleep(1)

            if 'nmcli_general_profile_pickup_doesnt_break_network' in scenario.tags:
                print("---------------------------")
                print("turning on network.service")
                context.nm_restarted = True
                call('sudo pkill -9 /sbin/dhclient', shell=True)
                # Make orig- devices unmanaged as they may be unfunctional
                call('for dev in $(nmcli  -g DEVICE d |grep orig); do nmcli device set $dev managed off; done', shell=True)
                restart_NM_service()
                call('sudo systemctl restart network.service', shell=True)
                call("nmcli connection up testeth0", shell=True)
                sleep(1)

            if '8021x' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    call("[ -x /usr/sbin/hostapd ] || (yum -y install 'https://vbenes.fedorapeople.org/NM/hostapd-2.6-7.el7.s390x.rpm'; sleep 10)", shell=True)
                setup_hostapd()

            if 'simwifi_wpa2' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)
                setup_hostapd_wireless('wpa2')

            if 'simwifi_open' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)
                setup_hostapd_wireless('open')

            if 'simwifi_pskwep' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)
                setup_hostapd_wireless('pskwep')

            if 'simwifi_dynwep' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)
                setup_hostapd_wireless('dynwep')

            if 'simwifi_p2p' in scenario.tags:
                print ("---------------------------")
                print ("* setting p2p test bed")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)

                if call("ls /tmp/nm_*_supp_configured", shell=True) == 0:
                    print ("** need to remove previous setup")
                    teardown_hostapd_wireless()

                call('modprobe -r mac80211_hwsim', shell=True)
                sleep(1)

                # This should be good as dynamic addresses are now used
                #call("echo -e '[device-wifi]\nwifi.scan-rand-mac-address=no' > /etc/NetworkManager/conf.d/99-wifi.conf", shell=True)
                #call("echo -e '[connection-wifi]\nwifi.cloned-mac-address=preserve' >> /etc/NetworkManager/conf.d/99-wifi.conf", shell=True)

                # This is workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1752780
                call("echo -e '[keyfile]\nunmanaged-devices=wlan1\n' > /etc/NetworkManager/conf.d/99-wifi.conf", shell=True)
                restart_NM_service()

                call('modprobe mac80211_hwsim', shell=True)
                sleep(3)

            if 'vpnc' in scenario.tags:
                print ("---------------------------")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)
                # Install under RHEL7 only
                if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
                    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
                if call("rpm -q NetworkManager-vpnc", shell=True) != 0:
                    call("sudo yum -y install NetworkManager-vpnc", shell=True)
                    restart_NM_service()
                setup_racoon (mode="aggressive", dh_group=2)

            if 'tcpreplay' in scenario.tags:
                print ("---------------------------")
                print ("install tcpreplay")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)
                wait_for_testeth0()
                # Install under RHEL7 only
                if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
                    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
                call("[ -x /usr/bin/tcpreplay ] || yum -y install tcpreplay", shell=True)

            if 'openvpn' in scenario.tags:
                print ("---------------------------")
                print ("setting up OpenVPN")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)
                wait_for_testeth0()
                # Install under RHEL7 only
                if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
                    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
                call("[ -x /usr/sbin/openvpn ] || sudo yum -y install openvpn NetworkManager-openvpn", shell=True)
                if call("rpm -q NetworkManager-openvpn", shell=True) != 0:
                    call("sudo yum -y install NetworkManager-openvpn-1.0.8-1.el7.$(uname -p).rpm", shell=True)
                    restart_NM_service()

                # This is an internal RH workaround for secondary architecures that are not present in EPEL

                call("[ -x /usr/sbin/openvpn ] || sudo yum -y install https://vbenes.fedorapeople.org/NM/openvpn-2.3.8-1.el7.$(uname -p).rpm\
                                                                      https://vbenes.fedorapeople.org/NM/pkcs11-helper-1.11-3.el7.$(uname -p).rpm", shell=True)
                call("rpm -q NetworkManager-openvpn || sudo yum -y install https://vbenes.fedorapeople.org/NM/NetworkManager-openvpn-1.0.8-1.el7.$(uname -p).rpm", shell=True)
                reload_NM_service()

                samples = glob(os.path.abspath('tmp/openvpn'))[0]
                cfg = open("/etc/openvpn/trest-server.conf", "w")
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
                if not 'openvpn6' in scenario.tags:
                    cfg.write("\n" + 'server 172.31.70.0 255.255.255.0')
                    cfg.write("\n" + 'push "dhcp-option DNS 172.31.70.53"')
                    cfg.write("\n" + 'push "dhcp-option DOMAIN vpn.domain"')
                if not 'openvpn4' in scenario.tags:
                    cfg.write("\n" + 'tun-ipv6')
                    cfg.write("\n" + 'push tun-ipv6')
                    cfg.write("\n" + 'ifconfig-ipv6 2001:db8:666:dead::1/64 2001:db8:666:dead::1')
                    cfg.write("\n" + 'ifconfig-ipv6-pool 2001:db8:666:dead::/64')
                    cfg.write("\n" + 'push "ifconfig-ipv6 2001:db8:666:dead::2/64 2001:db8:666:dead::1"')
                    cfg.write("\n" + 'push "route-ipv6 2001:db8:666:dead::/64 2001:db8:666:dead::1"')
                cfg.write("\n")
                cfg.close()
                sleep(1)
                Popen("sudo openvpn /etc/openvpn/trest-server.conf", shell=True)
                sleep(6)
                #call("sudo systemctl restart openvpn@trest-server", shell=True)

            if 'libreswan' in scenario.tags:
                print ("---------------------------")
                wait_for_testeth0()
                if call("rpm -q NetworkManager-libreswan", shell=True) != 0:
                    call("sudo yum -y install NetworkManager-libreswan", shell=True)
                    restart_NM_service()
                call("/usr/sbin/ipsec --checknss", shell=True)
                ike="ikev1"
                if 'ikev2' in scenario.tags:
                    ike="ikev2"
                setup_libreswan (mode="aggressive", dh_group=5, ike=ike)

            if 'libreswan_main' in scenario.tags:
                print ("---------------------------")
                wait_for_testeth0()
                call("rpm -q NetworkManager-libreswan || sudo yum -y install NetworkManager-libreswan", shell=True)
                call("/usr/sbin/ipsec --checknss", shell=True)
                ike="ikev1"
                if 'ikev2' in scenario.tags:
                    ike="ikev2"
                setup_libreswan (mode="main", dh_group=5, ike=ike)

            if 'strongswan' in scenario.tags:
                # Do not run on RHEL7 on s390x
                if call("grep -q 'release 7' /etc/redhat-release", shell=True) == 0:
                    arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                    if arch == "s390x":
                        print("Skipping on RHEL7 on s390x")
                        sys.exit(77)

                print ("---------------------------")
                wait_for_testeth0()
                #call("/usr/sbin/ipsec --checknss", shell=True)
                setup_strongswan()


            if 'iptunnel' in scenario.tags:
                print("----------------------------")
                print("iptunnel setup")
                call('sh prepare/iptunnel.sh', shell=True)

            if 'wireguard' in scenario.tags:
                print("----------------------------")
                print("wireguard setup")
                rc = call('sh prepare/wireguard.sh', shell=True)
                if rc != 0:
                    print("wireguard setup failed with exitcode: %d" % rc)
                    sys.exit(rc)

            # if 'macsec' in scenario.tags:
            #     print("---------------------------")
            #     print("installing macsec stuff")
            #     install = "yum install -y https://vbenes.fedorapeople.org/NM/dnsmasq-debuginfo-2.76-2.el7.$(uname -p).rpm \
            #                           https://vbenes.fedorapeople.org/NM/dnsmasq-2.76-2.el7.$(uname -p).rpm \
            #                           https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.6-4.el7.$(uname -p).rpm \
            #                           https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.6-4.el7.$(uname -p).rpm"
            #     call(install, shell=True)
            #     call("systemctl restart wpa_supplicant", shell=True)

            if 'preserve_8021x_certs' in scenario.tags:
                print ("---------------------------")
                call("curl -s https://raw.githubusercontent.com/NetworkManager/NetworkManager/master/libnm-core/tests/certs/test-key-and-cert.pem -o /tmp/test_key_and_cert.pem", shell=True)
                call("curl -s https://raw.githubusercontent.com/NetworkManager/NetworkManager/master/libnm-core/tests/certs/test2_ca_cert.pem -o /tmp/test2_ca_cert.pem", shell=True)

            if 'pptp' in scenario.tags:
                print ("---------------------------")
                print ("setting up pptpd")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)
                wait_for_testeth0()
                # Install under RHEL7 only
                if call("grep -q Maipo /etc/redhat-release", shell=True) == 0:
                    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
                call("[ -x /usr/sbin/pptpd ] || sudo yum -y install /usr/sbin/pptpd", shell=True)
                call("rpm -q NetworkManager-pptp || sudo yum -y install NetworkManager-pptp", shell=True)

                call("sudo rm -f /etc/ppp/ppp-secrets", shell=True)
                psk = open("/etc/ppp/chap-secrets", "w")
                psk.write("budulinek pptpd passwd *\n")
                psk.close()

                if not os.path.isfile('/tmp/nm_pptp_configured'):
                    cfg = open("/etc/pptpd.conf", "w")
                    cfg.write('# pptpd configuration for client testing')
                    cfg.write("\n" + 'option /etc/ppp/options.pptpd')
                    cfg.write("\n" + 'logwtmp')
                    cfg.write("\n" + 'localip 172.31.66.6')
                    cfg.write("\n" + 'remoteip 172.31.66.60-69')
                    cfg.write("\n" + 'ms-dns 8.8.8.8')
                    cfg.write("\n" + 'ms-dns 8.8.4.4')
                    cfg.write("\n")
                    cfg.close()

                    call("sudo systemctl unmask pptpd", shell=True)
                    call("sudo systemctl restart pptpd", shell=True)
                    #context.execute_steps(u'* Add a connection named "pptp" for device "\*" to "pptp" VPN')
                    #context.execute_steps(u'* Use user "budulinek" with password "passwd" and MPPE set to "yes" for gateway "127.0.0.1" on PPTP connection "pptp"')
                    call("/sbin/pppd pty '/sbin/pptp 127.0.0.1' nodetach", shell=True)
                    #call("nmcli con up id pptp", shell=True)
                    #call("nmcli con del pptp", shell=True)
                    call("touch /tmp/nm_pptp_configured", shell=True)
                    sleep(1)

            if 'restore_hostname' in scenario.tags:
               print ("---------------------------")
               print ("saving original hostname")
               context.original_hostname = check_output('hostname', shell=True).decode('utf-8', 'ignore').strip()

            if 'runonce' in scenario.tags:
                print ("---------------------------")
                print ("stop all networking services and prepare configuration")
                call("systemctl stop network", shell=True)
                call("nmcli device disconnect eth0", shell=True)
                call("pkill -9 dhclient", shell=True)
                call("pkill -9 nm-iface-helper", shell=True)
                call("sudo systemctl stop firewalld", shell=True)

            if 'slow_team' in scenario.tags:
                print ("---------------------------")
                print ("run just on x86_64")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch != "x86_64":
                    sys.exit(77)
                print ("---------------------------")
                print ("remove all team packages except NM one and reinstall them with delayed version")
                call("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done", shell=True)
                call("yum -y install https://vbenes.fedorapeople.org/NM/slow_libteam-1.25-5.el7_4.1.1.x86_64.rpm https://vbenes.fedorapeople.org/NM/slow_teamd-1.25-5.el7_4.1.1.x86_64.rpm", shell=True)
                if call("rpm --quiet -q teamd", shell=True) != 0:
                    # Restore teamd package if we don't have the slow ones
                    call("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done", shell=True)
                    call("yum -y install teamd libteam", shell=True)
                    sys.exit(77)
                reload_NM_service()

            if 'openvswitch' in scenario.tags:
                print ("---------------------------")
                print ("starting openvswitch if not active")
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                if arch == "s390x":
                    sys.exit(77)
                if call('rpm -q NetworkManager-ovs', shell=True) != 0:
                    call('yum -y install NetworkManager-ovs', shell=True)
                    call('systemctl daemon-reload', shell=True)
                    restart_NM_service()
                if call('systemctl is-active openvswitch', shell=True) != 0:
                    call('systemctl restart openvswitch', shell=True)
                    restart_NM_service()

            if 'dpdk' in scenario.tags:
                print ("---------------------------")
                print ("Setting dpdk openvswitch")
                print (" * enable hugepages")
                call("sysctl -w vm.nr_hugepages=10", shell=True)

                print (" * install dpdk")
                call('yum -y install dpdk dpdk-tools', shell=True)

                print (" add root:root to run hugetlbfs in /etc/openvswitch")
                call('sed -i.bak s/openvswitch:hugetlbfs/root:root/g /etc/sysconfig/openvswitch', shell=True)

                print (" * enable dpdk in openvswitch")
                call('ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true', shell=True)

                print (" * modprobe vfio-pci to be used as dpdk NIC driver")
                call('modprobe vfio-pci', shell=True)

                print (" * enable unsafe_noiommu_mode")
                call('echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode', shell=True)

                print (" * enable two VFs")
                call('nmcli  connection add type ethernet ifname p4p1 con-name dpdk-sriov sriov.total-vfs 2', shell=True)
                call('nmcli  connection up dpdk-sriov', shell=True)

                print (" * add both VFs to DPDK")
                call('dpdk-devbind -b vfio-pci 0000:42:10.0', shell=True)
                call('dpdk-devbind -b vfio-pci 0000:42:10.2', shell=True)

                call('systemctl restart openvswitch', shell=True)
                restart_NM_service()

            if 'wireless_certs' in scenario.tags:
                print ("---------------------------")
                print ("download certs if needed")
                call('mkdir /tmp/certs', shell=True)
                if not os.path.isfile('/tmp/certs/eaptest_ca_cert.pem'):
                    call('wget http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem -O /tmp/certs/eaptest_ca_cert.pem', shell=True)
                if not os.path.isfile('/tmp/certs/client.pem'):
                    call('wget http://wlan-lab.eng.bos.redhat.com/certs/client.pem -O /tmp/certs/client.pem', shell=True)

            if 'selinux_allow_ifup' in scenario.tags:
                print ("---------------------------")
                print ("allow ifup in selinux")
                call("semodule -i tmp/selinux-policy/ifup_policy.pp", shell=True)

            if 'ipv6_keep_connectivity_on_assuming_connection_profile' in scenario.tags:
                print ("---------------------------")
                print ("removing testeth10 profile")
                call('sudo nmcli connection delete testeth10', shell=True)

            if 'pppoe' in scenario.tags:
                arch = check_output("uname -p", shell=True).decode('utf-8', 'ignore').strip()
                # selinux on aarch64: see https://bugzilla.redhat.com/show_bug.cgi?id=1643954
                if arch == "aarch64":
                    print ("---------------------------")
                    print ("enable pppd selinux policy")
                    call("semodule -i tmp/selinux-policy/pppd.pp", shell=True)
                print ("---------------------------")
                print ("installing pppoe dependencies")
                # This -x is to avoid upgrade of NetworkManager in older version testing
                call("yum -y install NetworkManager-ppp -x NetworkManager", shell=True)
                call('yum -y install rp-pppoe', shell=True)
                call('[ -x //usr/sbin/pppoe-server ] || yum -y install https://kojipkgs.fedoraproject.org//packages/rp-pppoe/3.12/11.fc28/$(uname -p)/rp-pppoe-3.12-11.fc28.$(uname -p).rpm', shell=True)
                call("mknod /dev/ppp c 108 0", shell=True)
                reload_NM_service()

            if 'nmstate_setup' in scenario.tags:
                # Skip on deployments where we do not have veths
                if not os.path.isfile('/tmp/nm_newveth_configured'):
                    sys.exit(77)

                # FIXME: workaround for rhbz1796838
                call("modprobe -r ip_gre ip6_gre ip6_tunnel ip_gre sit gre ipip", shell=True)

                call("sh prepare/vethsetup.sh teardown", shell=True)
                # Need to have the file to be able to regenerate
                call("touch /tmp/nm_newveth_configured", shell=True)
                context.nm_restarted = True

                manage_veths ()

                context.nm_pid = nm_pid()
                # prepare nmstate
                call("sh prepare/nmstate.sh", shell=True)

                if call('systemctl is-active openvswitch', shell=True) != 0:
                    call('systemctl restart openvswitch', shell=True)
                    restart_NM_service()

            if 'nmcli_general_dhcp_profiles_general_gateway' in scenario.tags:
                print("---------------------------")
                print("backup of /etc/sysconfig/network")
                call('sudo cp -f /etc/sysconfig/network /tmp/sysnetwork.backup', shell=True)

            if 'remove_fedora_connection_checker' in scenario.tags:
                print("---------------------------")
                print("Making sure NetworkManager-config-connectivity-fedora is not installed")
                wait_for_testeth0()
                call('yum -y remove NetworkManager-config-connectivity-fedora', shell=True)
                reload_NM_service()

            if 'need_config_server' in scenario.tags:
                print("---------------------------")
                print("Making sure NetworkManager-config-server is installed")
                if call('rpm -q NetworkManager-config-server', shell=True) == 0:
                    context.remove_config_server = False
                else:
                    call('sudo yum -y install NetworkManager-config-server', shell=True)
                    reload_NM_service()
                    context.remove_config_server = True

            if 'no_config_server' in scenario.tags:
                print("---------------------------")
                print("Making sure NetworkManager-config-server is not installed")
                if call('rpm -q NetworkManager-config-server', shell=True) == 1:
                    context.restore_config_server = False
                else:
                    #call('sudo yum -y remove NetworkManager-config-server', shell=True)
                    config_files = check_output('rpm -ql NetworkManager-config-server', shell=True).decode('utf-8', 'ignore').strip().split('\n')
                    for config_file in config_files:
                        config_file = config_file.strip()
                        if os.path.isfile(config_file):
                            print("* disabling file: %s" % config_file)
                            call('sudo mv -f %s %s.off' % (config_file, config_file), shell=True)
                    reload_NM_service()
                    context.restore_config_server = True

            if 'permissive' in scenario.tags:
                context.enforcing = False
                if check_output('getenforce', shell=True).decode('utf-8', 'ignore').strip() == 'Enforcing':
                    print("---------------------------")
                    print("WORKAROUND for permissive selinux")
                    context.enforcing = True
                    call('setenforce 0', shell=True)


            if 'tcpdump' in scenario.tags:
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ TRAFFIC LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/network-traffic.log")
                Popen("sudo tcpdump -nne -i any >> /tmp/network-traffic.log", shell=True)

            context.nm_pid = nm_pid()

            context.nm_restarted = False
            context.crashed_step = False

            print(("NetworkManager process id before: %s" % context.nm_pid))

            if context.nm_pid is not None:
                context.log.write("NetworkManager memory consumption before: %d KiB\n" % nm_size_kb())
                if call("[ -f /etc/systemd/system/NetworkManager.service ] && grep -q valgrind /etc/systemd/system/NetworkManager.service", shell=True) == 0:
                    call("LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch", shell=True, stdout=context.log, stderr=context.log)

            context.log_cursor = check_output("journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print \"\\\"--after-cursor=\"$NF\"\\\"\"; exit}'", shell=True).decode('utf-8', 'ignore').strip()

        except Exception as e:
            print(("Error in before_scenario"))
            traceback.print_exc(file=sys.stdout)

def after_step(context, step):
    if IS_NMTUI:
        """Teardown after each step.
        Here we make screenshot and embed it (if one of formatters supports it)
        """
        try:
            if os.path.isfile('/tmp/nmtui.out'):
                # This doesn't need utf_only_open_read as it's strictly utf-8
                context.stream.feed(open('/tmp/nmtui.out', 'r').read().encode('utf-8'))
            print_screen(context.screen)
            log_screen(step.name, context.screen, '/tmp/tui-screen.log')

            if (step.name == 'Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites' or \
               step.name == 'Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites') and \
               step.status == 'failed' and step.step_type == 'given':
                print("Omiting the test as device does not support AP/ADHOC mode")
                if os.path.isfile('/tmp/tui-screen.log'):
                    os.remove('/tmp/tui-screen.log')
                f = open('/tmp/tui-screen.log', 'a+')
                f.write('INFO: Skiped the test as device does not support AP/ADHOC mode')
                f.flush()
                f.close()
                sys.exit(77)

            if step.status == 'failed':
                # Test debugging - set DEBUG_ON_FAILURE to drop to ipdb on step failure
                if os.environ.get('DEBUG_ON_FAILURE'):
                    import ipdb; ipdb.set_trace()  # flake8: noqa

        except Exception:
            print("Error in after_step:")
            traceback.print_exc(file=sys.stdout)
    else:
        """
        """
        # This is for RedHat's STR purposes sleep
        if os.path.isfile('/tmp/nm_skip_restarts'):
            sleep(0.4)

        if step.name == ('Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites' or \
           step.name == 'Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites') and \
           step.status == 'failed' and step.step_type == 'given':
            print("Omitting the test as device does not AP/ADHOC mode")
            sys.exit(77)
        # for nmcli_wifi_right_band_80211a - HW dependent 'passes'
        if step.name == 'Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is set in WirelessCapabilites' and \
           step.status == 'failed' and step.step_type == 'given':
            print("Omitting the test as device does not support 802.11a")
            sys.exit(77)
        # for testcase_306559
        if step.name == 'Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is not set in WirelessCapabilites' and \
           step.status == 'failed' and step.step_type == 'given':
            print("Omitting test as device supports 802.11a")
            sys.exit(77)

        if not context.nm_restarted and not context.crashed_step:
            new_pid = nm_pid()
            if new_pid != context.nm_pid:
                print(('NM Crashed as new PID %s is not old PID %s' %(new_pid, context.nm_pid)))
                context.crashed_step = step.name

def after_scenario(context, scenario):
    if IS_NMTUI:
        """Teardown for each scenario
        Kill gnome-weather (in order to make this reliable we send sigkill)
        """
        try:
            # record the network status after the test
            if os.path.isfile('/tmp/tui-screen.log'):
                fd = open('/tmp/tui-screen.log', 'a+')
                dump_status_nmtui(fd, 'after')
                fd.flush()
                fd.close()
            # Stop TUI
            os.system("sudo killall nmtui &> /dev/null")
            os.remove('/tmp/nmtui.out')
            # Attach journalctl logs
            if hasattr(context, "embed"):
                os.system("sudo journalctl -u NetworkManager --no-pager -o cat %s > /tmp/journal-session.log" % context.log_cursor)
                data = utf_only_open_read("/tmp/journal-session.log", 'r')
                if data:
                    context.embed('text/plain', data, caption="NM")
            if 'bridge' in scenario.tags:
                os.system("sudo nmcli connection delete id bridge0 bridge-slave-eth1 bridge-slave-eth2")
                reset_hwaddr_nmtui('eth1')
                reset_hwaddr_nmtui('eth2')
                os.system("sudo ip link del bridge0")
            if 'vlan' in scenario.tags:
                os.system("sudo nmcli connection delete id vlan eth1.99")
                os.system("sudo ip link del eth1.99")
                os.system("sudo ip link del eth2.88")
            if 'bond' in scenario.tags:
                os.system("sudo nmcli connection delete id bond0 bond-slave-eth1 bond-slave-eth2")
                reset_hwaddr_nmtui('eth1')
                reset_hwaddr_nmtui('eth2')
                os.system("sudo ip link del bond0")
            if 'team' in scenario.tags:
                os.system("sudo nmcli connection delete id team0 team-slave-eth1 team-slave-eth2")
                reset_hwaddr_nmtui('eth1')
                reset_hwaddr_nmtui('eth2')
                os.system("sudo ip link del team0")
            if 'inf' in scenario.tags:
                os.system("sudo nmcli connection delete id infiniband0 infiniband0-port")
            if 'dsl' in scenario.tags:
                os.system("sudo nmcli connection delete id dsl0")
            if 'wifi' in scenario.tags:
                os.system("sudo nmcli connection delete id wifi wifi1 qe-open qe-wpa1-psk qe-wpa2-psk qe-wep")
                #os.system("sudo service NetworkManager restart") # debug restart to overcome the nmcli d w l flickering
            if 'restore_hostname' in scenario.tags:
                print ("---------------------------")
                print ("restoring original hostname")
                os.system('systemctl unmask systemd-hostnamed.service')
                os.system('systemctl unmask dbus-org.freedesktop.hostname1.service')
                #call('sudo echo %s > /etc/hostname' % context.original_hostname, shell=True)
                #call('sudo nmcli g hostname %s' % context.original_hostname, shell=True)
                call('sudo echo "localhost.localdomain" > /etc/hostname', shell=True)
                call('hostnamectl set-hostname localhost.localdomain', shell=True)
                call('rm -rf /etc/NetworkManager/conf.d/90-hostname.conf', shell=True)
                call('rm -rf /etc/dnsmasq.d/dnsmasq_custom.conf', shell=True)
                call('systemctl restart NetworkManager', shell=True)
                call("nmcli con up testeth0", shell=True)
            if 'restart' in scenario.tags:
                print ("---------------------------")
                print ("restarting NM service")
                if call("systemctl is-active NetworkManager", shell=True) != 0:
                    call('sudo systemctl restart NetworkManager', shell=True)
                if not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
                    wait_for_testeth0()
            if ('ethernet' in scenario.tags) or ('ipv4' in scenario.tags) or ('ipv6' in scenario.tags):
                os.system("sudo nmcli connection delete id ethernet ethernet1 ethernet2")
            if 'nmtui_ethernet_set_mtu' in scenario.tags:
                os.system("sudo ip link set eth1 mtu 1500")
            if 'nmtui_bridge_add_many_slaves' in scenario.tags:
                os.system("sudo nmcli con delete bridge-slave-eth3 bridge-slave-eth4 bridge-slave-eth5"+
                          " bridge-slave-eth6 bridge-slave-eth7 bridge-slave-eth8 bridge-slave-eth9")
                reset_hwaddr_nmtui('eth3')
                reset_hwaddr_nmtui('eth4')
                reset_hwaddr_nmtui('eth5')
                reset_hwaddr_nmtui('eth6')
                reset_hwaddr_nmtui('eth7')
                reset_hwaddr_nmtui('eth8')
                reset_hwaddr_nmtui('eth9')
            if 'nmtui_bond_add_many_slaves' in scenario.tags:
                os.system("sudo nmcli con delete bond-slave-eth3 bond-slave-eth4 bond-slave-eth5"+
                          " bond-slave-eth6 bond-slave-eth7 bond-slave-eth8 bond-slave-eth9")
                reset_hwaddr_nmtui('eth3')
                reset_hwaddr_nmtui('eth4')
                reset_hwaddr_nmtui('eth5')
                reset_hwaddr_nmtui('eth6')
                reset_hwaddr_nmtui('eth7')
                reset_hwaddr_nmtui('eth8')
                reset_hwaddr_nmtui('eth9')
            if 'nmtui_team_add_many_slaves' in scenario.tags:
                os.system("sudo nmcli con delete team-slave-eth3 team-slave-eth4 team-slave-eth5"+
                          " team-slave-eth6 team-slave-eth7 team-slave-eth8 team-slave-eth9")
                reset_hwaddr_nmtui('eth3')
                reset_hwaddr_nmtui('eth4')
                reset_hwaddr_nmtui('eth5')
                reset_hwaddr_nmtui('eth6')
                reset_hwaddr_nmtui('eth7')
                reset_hwaddr_nmtui('eth8')
                reset_hwaddr_nmtui('eth9')
            if 'nmtui_ethernet_set_mtu' in scenario.tags:
                os.system("ip link set mtu 1500 dev eth1")
            if 'nmtui_wifi_ap' in scenario.tags:
                os.system("sudo service NetworkManager restart")
                sleep(5)
                os.system("sudo nmcli device wifi rescan")
                sleep(10)
            if 'nmtui_general_activate_screen_no_connections' in scenario.tags:
                print ("Restoring all connection profiles from temp dir")
                os.system("cp -f /tmp/backup_profiles/* /etc/sysconfig/network-scripts/")
                os.system("rm -rf /tmp/backup_profiles")
                os.system("nmcli con reload")
            if 'nmtui_ethernet_activate_connection_specific_device' in scenario.tags:
                if os.system("nmcli connection show -a |grep testeth7") == 0:
                    print ("Disconnect testeth7")
                    os.system("nmcli con down testeth7")
            if "eth0" in scenario.tags:
                print ("---------------------------")
                print ("upping testeth0")
                wait_for_testeth0()

        except Exception:
            # Stupid behave simply crashes in case exception has occurred
            print("Error in after_scenario:")
            traceback.print_exc(file=sys.stdout)
    else:
        """
        """
        nm_pid_after = nm_pid()
        print(("NetworkManager process id after: %s (was %s)" % (nm_pid_after, context.nm_pid)))

        try:
            #attach network traffic log
            if 'tcpdump' in scenario.tags:
                print("Attaching traffic log")
                call("sudo kill -1 $(pidof tcpdump)", shell=True)
                if os.stat("/tmp/network-traffic.log").st_size < 20000000:
                    traffic = utf_only_open_read("/tmp/network-traffic.log")
                    if traffic:
                        context.embed('text/plain', traffic, caption="TRAFFIC")
                else:
                    print("WARNING: 20M size exceeded in /tmp/network-traffic.log, skipping")

            if 'netservice' in scenario.tags:
                # Attach network.service journalctl logs
                print("Attaching network.service log")
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NETWORK SRV LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-netsrv.log")
                os.system("sudo journalctl -u network --no-pager -o cat %s >> /tmp/journal-netsrv.log" % context.log_cursor)

                data = utf_only_open_read("/tmp/journal-netsrv.log")
                if data:
                    context.embed('text/plain', data, caption="NETSRV")

            if scenario.status == 'failed':
                dump_status_nmcli(context, 'after %s' % scenario.name)

            if 'checkpoint_remove' in scenario.tags:
                print ("--------------------------")
                print ("cleanup checkpoints")
                # Not supported on 1-10
                import dbus
                bus = dbus.SystemBus()
                # Get a proxy for the base NetworkManager object
                proxy = bus.get_object("org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager")
                # get NM object, to be able to call CheckpointDestroy
                manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
                # dbus property getter
                prop_get = dbus.Interface(proxy, "org.freedesktop.DBus.Properties")
                # Unsupported prior version 1.12
                if int(prop_get.Get("org.freedesktop.NetworkManager", "Version").split('.')[1]) > 10:
                    # get list of all checkpoints (property Checkpoints of org.freedesktop.NetworkManager)
                    checkpoints = prop_get.Get("org.freedesktop.NetworkManager", "Checkpoints")
                    for checkpoint in checkpoints:
                        print ("destroying checkpoint with path %s" % checkpoint)
                        manager.CheckpointDestroy(checkpoint)

            if 'clean_iptables' in scenario.tags:
                print ("---------------------------")
                print ("clean iptables")
                call("iptables -D OUTPUT -p udp --dport 67 -j REJECT", shell=True)

            if 'runonce' in scenario.tags:
                print ("---------------------------")
                print ("delete profiles and start NM")
                call("for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True)
                call("rm -rf /etc/NetworkManager/conf.d/01-run-once.conf", shell=True)
                sleep (1)
                restart_NM_service()
                sleep (1)
                call("for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True)
                call("nmcli connection delete con_general", shell=True)
                call("nmcli device disconnect eth10", shell=True)
                call("nmcli connection up testeth0", shell=True)

            if 'secret_key_reset' in scenario.tags:
                call("mv /var/lib/NetworkManager/secret_key_back /var/lib/NetworkManager/secret_key", shell=True)

            if 'kill_dhclient_eth8' in scenario.tags:
                call("kill $(cat /tmp/dhclient_eth8.pid)", shell=True)
                call("rm -f /tmp/dhclient_eth8.pid", shell=True)

            if 'restart' in scenario.tags:
                print ("---------------------------")
                print ("restarting NM service")
                if call("systemctl is-active NetworkManager", shell=True) != 0:
                    restart_NM_service()
                if not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
                    wait_for_testeth0()

            if 'networking_on' in scenario.tags:
                print ("---------------------------")
                print ("enabling NM networking")
                call("nmcli networking on", shell=True)
                wait_for_testeth0()

            if 'nmstate_setup' in scenario.tags:
                print ("---------------------------")
                print ("* remove nmstate setup")

                # nmstate restarts NM few times during tests
                context.nm_restarted = True

                call("ip link del eth1", shell=True)
                call("ip link del eth2", shell=True)

                call("nmcli con del eth1 eth2 linux-br0 dhcpcli dhcpsrv brtest0 bond99 eth1.101 eth1.102", shell=True)
                call("nmcli device delete dhcpsrv", shell=True)
                call("nmcli device delete dhcpcli", shell=True)
                call("nmcli device delete bond99", shell=True)

                call("ovs-vsctl del-br ovsbr0", shell=True)
                # in case of fail we need to kill this
                call('rm -rf /etc/dnsmasq.d/nmstate.conf', shell=True)
                call('systemctl stop dnsmasq', shell=True)

                wait_for_testeth0 ()

                print("* attaching nmstate log")
                nmstate = utf_only_open_read("/tmp/nmstate.txt")
                if nmstate:
                    context.embed('text/plain', nmstate, caption="NMSTATE")

            if 'restore_hostname' in scenario.tags:
                print ("---------------------------")
                print ("restoring original hostname")
                os.system('systemctl unmask systemd-hostnamed.service')
                os.system('systemctl unmask dbus-org.freedesktop.hostname1.service')
                call('hostnamectl set-hostname --transien ""', shell=True)
                call('hostnamectl set-hostname --static %s' % context.original_hostname, shell=True)
                call('rm -rf /etc/NetworkManager/conf.d/90-hostname.conf', shell=True)
                call('rm -rf /etc/dnsmasq.d/dnsmasq_custom.conf', shell=True)
                reload_NM_service()
                call("nmcli con up testeth0", shell=True)

            if '1000' in scenario.tags:
                print ("---------------------------")
                print ("deleting bridge0 and 1000 dummy devices")
                call("ip link del bridge0", shell=True)
                call("for i in $(seq 0 1000); do ip link del port$i ; done", shell=True)

            if 'adsl' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection adsl")
                call("nmcli connection delete id adsl-test11", shell=True)

            if 'allow_veth_connections' in scenario.tags:
                if context.revert_unmanaged == True:
                    call("sed -i 's/^#ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/' /usr/lib/udev/rules.d/85-nm-unmanaged.rules", shell=True)
                    call('sudo rm -rf /etc/NetworkManager/conf.d/99-unmanaged.conf', shell=True)
                    reload_NM_service()
                call("nmcli con del 'Wired connection 1'", shell=True)
                call("nmcli con del 'Wired connection 2'", shell=True)
                call("for i in $(nmcli -t -f DEVICE c s -a |grep -v ^eth0$); do nmcli device disconnect $i; done", shell=True)

            if 'con_ipv4_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_ipv4 and con_ipv42")
                call("nmcli connection delete id con_ipv4 con_ipv42", shell=True)
                call("if nmcli con |grep con_ipv4; then echo 'con_ipv4 present: %s' >> /tmp/residues; fi" %scenario.tags, shell=True)

            if 'con_ipv6_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_ipv6 con_ipv62")
                call("nmcli connection down con_ipv6 ", shell=True)
                call("nmcli connection down con_ipv62 ", shell=True)
                call("nmcli connection delete id con_ipv6 con_ipv62", shell=True)
                call("if nmcli con |grep con_ipv6; then echo 'con_ipv6 present: %s' >> /tmp/residues; fi" %scenario.tags, shell=True)

            if 'con_ipv6_ifcfg_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_ipv6_ifcfg")
                #call("nmcli connection delete id con_ipv6 con_ipv62", shell=True)
                call("rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv6", shell=True)
                call('nmcli con reload', shell=True)

            if 'con_con_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_con and con_con2")
                call("nmcli connection delete id con_con con_con2", shell=True)

            if 'con_dns_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_dns and con_dns2")
                call("nmcli connection delete id con_dns con_dns2", shell=True)

            if 'con_ethernet_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection con_ethernet")
                call("nmcli connection delete id con_ethernet", shell=True)

            if 'alias' in scenario.tags:
                print ("---------------------------")
                print ("deleting alias connections")
                call("nmcli connection delete eth7", shell=True)
                call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:0", shell=True)
                call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:1", shell=True)
                call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:2", shell=True)
                call("sudo nmcli connection reload", shell=True)
                call("nmcli connection down testeth7", shell=True)
                #call('sudo nmcli con add type ethernet ifname eth7 con-name testeth7 autoconnect no', shell=True)
                #sleep(TIMER)

            if 'gen-bond_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting gen-bond profile")
                call('nmcli connection delete id gen-bond0 gen-bond0.0 gen-bond0.1', shell=True)
                call('ip link del gen-bond', shell=True)
                call('ip link del gen-bond0', shell=True)

            if 'bond' in scenario.tags:
                print ("---------------------------")
                print ("deleting bond profile")
                call('nmcli connection delete id bond0 bond', shell=True)
                call('ip link del nm-bond', shell=True)
                call('ip link del bond0', shell=True)
                #sleep(TIMER)
                print((os.system('ls /proc/net/bonding')))

            if 'slaves' in scenario.tags:
                print ("---------------------------")
                print ("deleting slave profiles")
                reset_hwaddr_nmcli('eth1')
                reset_hwaddr_nmcli('eth4')
                call('nmcli connection delete id bond0.0 bond0.1 bond0.2 bond-slave-eth1 bond-slave', shell=True)

                #sleep(TIMER)

            if 'bond_order' in scenario.tags:
                print ("---------------------------")
                print ("reset bond order")
                call("rm -rf /etc/NetworkManager/conf.d/99-bond.conf", shell=True)
                reload_NM_service()

            if 'connectivity' in scenario.tags:
                print ("---------------------------")
                print ("remove connectivity checker")
                call("rm -rf /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
                call("rm -rf /var/lib/NetworkManager/NetworkManager-intern.conf", shell=True)
                context.execute_steps(u'* Reset /etc/hosts')

                reload_NM_service()

            if 'con' in scenario.tags:
                print ("---------------------------")
                print ("deleting connie")
                call("nmcli connection delete id connie", shell=True)
                call("rm -rf /etc/sysconfig/network-scripts/ifcfg-connie*", shell=True)
                #sleep(TIMER)

            if 'remove_tombed_connections' in scenario.tags:
                print ("---------------------------")
                print("removing tombed connections")
                tombs = []
                for dir in ["/etc/NetworkManager/system-connections/*.nmmeta", "/var/run/NetworkManager/system-connections/*.nmmeta"]:
                    try:
                        tombs.extend(check_output('ls %s' % dir, shell=True).decode('utf-8', 'ignore').split("\n"))
                    except:
                        pass
                cons = []
                for tomb in tombs:
                    print(tomb)
                    con_id = tomb.split("/")[-1]
                    con_id = con_id.split('.')[0]
                    cons.append(con_id)
                    call("rm -f %s" % tomb, shell=True)
                if len(cons):
                    call("nmcli con reload", shell=True)
                    call("nmcli con delete %s" % " ".join(cons), shell=True)

            if 'disp' in scenario.tags:
                print ("---------------------------")
                print ("deleting dispatcher files")
                call("rm -rf /etc/NetworkManager/dispatcher.d/*-disp", shell=True)
                call("rm -rf /usr/lib/NetworkManager/dispatcher.d/*-disp", shell=True)
                call("rm -rf /etc/NetworkManager/dispatcher.d/pre-up.d/98-disp", shell=True)
                call("rm -rf /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp", shell=True)
                #call("rm -rf /tmp/dispatcher.txt", shell=True)
                call('nmcli con down testeth1', shell=True)
                call('nmcli con down testeth2', shell=True)
                call('kill -1 $(pidof NetworkManager)', shell=True)

            if 'firewall' in scenario.tags:
                print ("---------------------------")
                print ("stoppping firewall")
                call("sudo firewall-cmd --panic-off", shell=True)
                call("sudo systemctl stop firewalld", shell=True)

            if 'flush_300' in scenario.tags:
                print ("---------------------------")
                print ("flush route table 300")
                call("ip route flush table 300", shell=True)

            if 'logging' in scenario.tags:
                print ("---------------------------")
                print ("setting log level back")
                call('sudo nmcli g log level %s domains ALL' % context.loggin_level, shell=True)

            if 'logging_info_only' in scenario.tags:
                print ("---------------------------")
                print ("remove info only logging")
                log = "/etc/NetworkManager/conf.d/99-xlogging.conf"
                call("rm -rf %s" %log,  shell=True)
                restart_NM_service()
                sleep(1)

            if 'stop_radvd' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices")
                call("sudo systemctl stop radvd", shell=True)
                call('rm -rf /etc/radvd.conf', shell=True)

            if 'eth0' in scenario.tags:
                print ("---------------------------")
                print ("upping eth0")
                if 'restore_hostname' in scenario.tags:
                    call('hostnamectl set-hostname --transien ""', shell=True)
                    call('hostnamectl set-hostname --static %s' % context.original_hostname, shell=True)
                wait_for_testeth0()

            if 'dcb' in scenario.tags:
                print ("---------------------------")
                print ("deleting connection dcb")
                call("nmcli connection delete id dcb", shell=True)

            if 'mtu' in scenario.tags:
                print ("---------------------------")
                print ("setting mtu back to 1500")
                call("nmcli connection modify testeth1 802-3-ethernet.mtu 1500", shell=True)
                call("nmcli connection up id testeth1", shell=True)
                call("nmcli connection modify testeth1 802-3-ethernet.mtu 0", shell=True)
                call("nmcli connection down id testeth1", shell=True)
                call("ip link set dev eth1 mtu 1500", shell=True)

            if 'mtu_wlan0' in scenario.tags:
                print ("---------------------------")
                print ("setting mtu back to 1500")
                call('nmcli con add type wifi ifname wlan0 con-name qe-open autoconnect off ssid qe-open', shell=True)
                call("nmcli connection modify qe-open 802-11-wireless.mtu 1500", shell=True)
                call("nmcli connection up id qe-open", shell=True)
                call("nmcli connection del id qe-open", shell=True)

            if 'macsec' in scenario.tags:
                print("---------------------------")
                call('sudo nmcli connection delete test-macsec test-macsec-base', shell=True)
                call('sudo ip netns delete macsec_ns', shell=True)
                call('sudo ip link delete macsec_veth', shell=True)
                print ("kill wpa_supplicant")
                call("kill $(cat /tmp/wpa_supplicant_ms.pid)", shell=True)
                print ("kill dnsmasq")
                call("kill $(cat /tmp/dnsmasq_ms.pid)", shell=True)

            if 'two_bridged_veths' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices")
                call("nmcli connection delete id tc1 tc2", shell=True)
                call("ip link del test1", shell=True)
                call("ip link del test2", shell=True)
                call("ip link del vethbr", shell=True)
                call("nmcli con del tc1 tc2 vethbr", shell=True)
                unmanage_veths ()

            if 'two_bridged_veths6' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices")
                call("nmcli connection delete id tc16 tc26 test10 test11 vethbr6", shell=True)
                call("ip link del test11", shell=True)
                call("ip link del test10", shell=True)
                call("ip link del vethbr6", shell=True)
                unmanage_veths ()

            if 'two_bridged_veths_gen' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices")
                call("ip link del test1g", shell=True)
                call("ip link del test2g", shell=True)
                call("ip link del vethbrg", shell=True)
                call("nmcli con del test1g test2g tc1g tc2g vethbrg", shell=True)
                sleep(1)

            if 'dns_systemd_resolved' in scenario.tags:
                print ("---------------------------")
                if context.systemd_resolved == False:
                    print ("stop systemd-resolved")
                    call("systemctl stop systemd-resolved", shell=True)
                print ("revert dns=default")
                call("rm -f /etc/NetworkManager/conf.d/99-xtest-dns.conf", shell=True)
                reload_NM_service ()
                context.dns_script=""

            if 'dns_dnsmasq' in scenario.tags:
                print ("---------------------------")
                print ("revert dns=default")
                call("rm -f /etc/NetworkManager/conf.d/99-xtest-dns.conf", shell=True)
                reload_NM_service ()
                context.dns_script=""

            if 'internal_DHCP' in scenario.tags:
                print ("---------------------------")
                print ("revert internal DHCP")
                call("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf", shell=True)
                restart_NM_service()

            if 'dhclient_DHCP' in scenario.tags:
                print ("---------------------------")
                print ("revert dhclient DHCP")
                call("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf", shell=True)
                restart_NM_service()

            if 'dhcpd' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices")
                call("sudo systemctl stop dhcpd", shell=True)

            if 'mtu' in scenario.tags:
                print ("---------------------------")
                print ("deleting veth devices from mtu test")
                call("nmcli connection delete id tc1 tc2 tc16 tc26", shell=True)
                call("ip link delete test1", shell=True)
                call("ip link delete test2", shell=True)
                call("ip link delete test10", shell=True)
                call("ip link delete test11", shell=True)
                call("ip link del vethbr", shell=True)
                call("ip link del vethbr6", shell=True)
                call("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')", shell=True)
                call("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')", shell=True)

            if 'modprobe_cfg_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting modprobe config")
                call("rm -rf /etc/modprobe.d/99-test.conf", shell=True)

            if 'inf' in scenario.tags:
                print ("---------------------------")
                print ("deleting infiniband connections")
                call("nmcli connection up id tg3_1", shell=True)
                call("nmcli connection delete id inf", shell=True)
                call("nmcli connection delete id inf2", shell=True)
                call("nmcli connection delete id inf.8002", shell=True)
                call("nmcli device connect inf_ib0.8002", shell=True)

            if 'kill_dnsmasq_vlan' in scenario.tags:
                print ("---------------------------")
                print ("kill dnsmasq")
                call("kill $(cat /tmp/dnsmasq_vlan.pid)", shell=True)

            if 'kill_dnsmasq_ip4' in scenario.tags:
                print ("---------------------------")
                print ("kill dnsmasq")
                call("kill $(cat /tmp/dnsmasq_ip4.pid)", shell=True)

            if 'kill_dnsmasq_ip6' in scenario.tags:
                print ("---------------------------")
                print ("kill dnsmasq")
                call("kill $(cat /tmp/dnsmasq_ip6.pid)", shell=True)

            if 'kill_dhcrelay' in scenario.tags:
                print ("---------------------------")
                print ("kill dhcrelay")
                call("kill $(cat /tmp/dhcrelay.pid)", shell=True)

            if 'profie' in scenario.tags:
                print ("---------------------------")
                print ("deleting profile profile")
                call("nmcli connection delete id profie", shell=True)
                #sleep(TIMER)

            if 'peers_ns' in scenario.tags:
                print ("---------------------------")
                print ("deleting peers namespace")
                call("ip netns del peers", shell=True)
                #sleep(TIMER)

            if 'sriov_bond' in scenario.tags:
                print ("---------------------------")
                print ("remove sriov bond profiles")
                call("nmcli con del sriov2", shell=True)
                call("nmcli con del sriov_bond0", shell=True)
                call("nmcli con del sriov_bond0.0", shell=True)
                call("nmcli con del sriov_bond0.1", shell=True)

            if 'sriov' in scenario.tags:
                print ("---------------------------")
                print ("remove sriov configs")

                print ("remove sriov")
                call("nmcli con del sriov", shell=True)

                print ("remove sriov_2")
                call("nmcli con del sriov_2", shell=True)

                print ("set 0 to /sys/class/net/*/device/sriov_numvfs")
                call("echo 0 > /sys/class/net/p6p1/device/sriov_numvfs", shell=True)
                call("echo 0 > /sys/class/net/p4p1/device/sriov_numvfs", shell=True)

                print ("remove /etc/NetworkManager/conf.d/9*-sriov.conf")
                call("rm -rf /etc/NetworkManager/conf.d/99-sriov.conf", shell=True)
                call("rm -rf /etc/NetworkManager/conf.d/98-sriov.conf", shell=True)

                call("set 1 to /sys/class/net/p4p1/device/sriov_drivers_autoprobe", shell=True)
                call("echo 1 > /sys/class/net/p4p1/device/sriov_drivers_autoprobe", shell=True)
                call("echo 1 > /sys/class/net/p6p1/device/sriov_drivers_autoprobe", shell=True)

                print ("remove ixgbevf driver")
                call("modprobe -r ixgbevf", shell=True)

                print ("remove sriov_2")
                call("nmcli con del sriov_2", shell=True)

                reload_NM_service()

            if 'team_slaves' in scenario.tags:
                print ("---------------------------")
                print ("deleting team slaves")
                call('nmcli connection delete id team0.0 team0.1 team-slave-eth5 team-slave-eth6 eth5 eth6 team-slave', shell=True)
                reset_hwaddr_nmcli('eth5')
                reset_hwaddr_nmcli('eth6')
                #sleep(TIMER)

            if 'team' in scenario.tags:
                print ("---------------------------")
                print ("deleting team masters")
                call('nmcli connection down team0', shell=True)
                call('nmcli connection delete id team0 team', shell=True)
                if 'team_assumed' in scenario.tags:
                    call('ip link del nm-team' , shell=True)
                #sleep(TIMER)
                call("if nmcli con |grep 'team0 '; then echo 'team0 present: %s' >> /tmp/residues; fi" %scenario.tags, shell=True)

            if 'bond-team_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting team masters")
                call('nmcli connection delete id bond-team0 bond-team', shell=True)
                call('ip link del bond-team', shell=True)


            if 'teamd' in scenario.tags:
                call("systemctl stop teamd", shell=True)
                call("systemctl reset-failed teamd", shell=True)

            if 'slow_team' in scenario.tags:
                print ("---------------------------")
                print ("restore original team pakages")
                call("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done", shell=True)
                call("yum -y install teamd libteam", shell=True)
                reload_NM_service()

            if 'tshark' in scenario.tags:
                print ("---------------------------")
                print ("kill tshark and delet dhclinet-eth10")
                call("pkill tshark", shell=True)
                call("rm -rf /etc/dhcp/dhclient-eth*.conf", shell=True)

            if 'tcpdump' in scenario.tags:
                print ("---------------------------")
                print ("kill tcpdump")
                call("pkill -9 tcpdump", shell=True)

            if 'vpnc' in scenario.tags:
                print ("---------------------------")
                print ("deleting vpnc profile")
                call('nmcli connection delete vpnc', shell=True)
                teardown_racoon ()

            if '8021x' in scenario.tags:
                print ("---------------------------")
                print ("deleting 8021x setup")
                teardown_hostapd()

            if 'simwifi_wpa2' in scenario.tags:
                print ("---------------------------")
                print ("deleting wifi connections")
                #teardown_hostapd_wireless()
                call("nmcli con del wpa2-eap wifi", shell=True)

            if 'simwifi_wpa2_teardown' in scenario.tags:
                print ("---------------------------")
                print ("bringing down hostapd setup")
                teardown_hostapd_wireless()

            if 'simwifi_open' in scenario.tags:
                print ("---------------------------")
                print ("deleting wifi connections")
                call("nmcli con del open", shell=True)

            if 'simwifi_pskwep' in scenario.tags:
                print ("---------------------------")
                print ("deleting wifi connections")
                call("nmcli con del wep", shell=True)

            if 'simwifi_dynwep' in scenario.tags:
                print ("---------------------------")
                print ("deleting wifi connections")
                call("nmcli con del wifi", shell=True)

            if 'simwifi_open_teardown' in scenario.tags:
                print ("---------------------------")
                print ("bringing down hostapd setup")
                teardown_hostapd_wireless()

            if 'simwifi_p2p' in scenario.tags:
                print ("---------------------------")
                call('modprobe -r mac80211_hwsim', shell=True)
                call('nmcli con del wifi-p2p', shell=True)
                call("kill -9 $(ps aux|grep wpa_suppli |grep wlan1 |awk '{print $2}')", shell=True)
                call("rm -rf /etc/NetworkManager/conf.d/99-wifi.conf", shell=True)

                restart_NM_service()

            if "attach_hostapd_log" in scenario.tags:
                print("Attaching hostapd log")
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ HOSTAPD LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-hostapd.log")
                os.system("sudo journalctl -u nm-hostapd --no-pager -o cat %s >> /tmp/journal-hostapd.log" % context.log_cursor)
                data = utf_only_open_read("/tmp/journal-hostapd.log")
                if data:
                    context.embed('text/plain', data, caption="HOSTAPD")

            if "attach_wpa_supplicant_log" in scenario.tags:
                print("Attaching wpa_supplicant log")
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ WPA_SUPPLICANT LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-wpa_supplicant.log")
                os.system("journalctl -u wpa_supplicant --no-pager -o cat %s >> /tmp/journal-wpa_supplicant.log" % context.log_cursor)
                data = utf_only_open_read("/tmp/journal-wpa_supplicant.log")
                if data:
                    context.embed('text/plain', data, caption="WPA_SUP")

            if 'openvpn' in scenario.tags:
                print ("---------------------------")
                print ("deleting openvpn profile")
                call('nmcli connection delete openvpn', shell=True)
                #call("sudo systemctl stop openvpn@trest-server", shell=True)
                call("sudo kill -9 $(pidof openvpn)", shell=True)

            if 'libreswan' in scenario.tags:
                print ("---------------------------")
                print ("deleting libreswan profile")
                call('nmcli connection down libreswan', shell=True)
                call('nmcli connection delete libreswan', shell=True)
                teardown_libreswan ()
                wait_for_testeth0()

            if 'libreswan_main' in scenario.tags:
                print ("---------------------------")
                print ("deleting libreswan profile")
                call('nmcli connection down libreswan', shell=True)
                call('nmcli connection delete libreswan', shell=True)
                teardown_libreswan ()
                wait_for_testeth0()

            if 'strongswan' in scenario.tags:
                print ("---------------------------")
                print ("deleting strongswan profile")
                #call("ip route del default via 172.31.70.1", shell=True)
                call('nmcli connection down strongswan', shell=True)
                call('nmcli connection delete strongswan', shell=True)
                teardown_strongswan ()
                wait_for_testeth0()

            if 'pptp' in scenario.tags:
                print ("---------------------------")
                print ("deleting pptp profile")
                call('nmcli connection delete pptp', shell=True)

            if 'ethernet' in scenario.tags:
                print ("---------------------------")
                print ("removing ethernet profiles")
                call("sudo nmcli connection delete id ethernet ethernet0 ethos", shell=True)
                call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ethernet*', shell=True) #ideally should do nothing

            if 'mac' in scenario.tags:
                print ("---------------------------")
                print ("delete mac config")
                call("rm -rf /etc/NetworkManager/conf.d/99-mac.conf", shell=True)
                reload_NM_service()
                reset_hwaddr_nmcli('eth1')

            if 'con_general_remove' in scenario.tags:
                print ("---------------------------")
                print ("removing ethernet profiles")
                call("sudo nmcli connection delete id con_general con_general2", shell=True)

            if 'con_PBR_remove' in scenario.tags:
                print ("---------------------------")
                print ("removing PBR procedure profiles")
                call("sudo nmcli connection delete id Servers Internal-Workstations Provider-A Provider-B", shell=True)

            if 'eth8_up' in scenario.tags:
                print ("---------------------------")
                print ("upping eth8 device")
                reset_hwaddr_nmcli('eth8')

            if 'con_tc_remove' in scenario.tags:
                print ("---------------------------")
                print ("removing con_tc profiles")
                call("sudo nmcli connection delete id con_tc", shell=True)

            if 'general_vlan' in scenario.tags:
                print ("---------------------------")
                print ("removing ethernet profiles")
                call("sudo nmcli connection delete id eth8.100", shell=True)
                call("sudo ip link del eth8.100", shell=True)

            if 'vlan' in scenario.tags:
                print ("---------------------------")
                print ("deleting all possible vlan residues")
                call('sudo nmcli con del vlan vlan1 vlan2 eth7.99 eth7.99 eth7.299 eth7.399 eth7.65 eth7.165 eth7.265 eth7.499 eth7.80 eth7.90', shell=True)
                call('sudo nmcli con del vlan_bridge7.15 vlan_bridge7 vlan_vlan7 vlan_bond7 vlan_bond7.7 vlan_team7 vlan_team7.1 vlan_team7.0', shell=True)
                call('ip link del bridge7', shell=True)
                call('ip link del eth7.99', shell=True)
                call('ip link del eth7.80', shell=True)
                call('ip link del eth7.90', shell=True)
                call('ip link del vlan7', shell=True)
                call('nmcli con down testeth7', shell=True)
                reset_hwaddr_nmcli('eth7')

            if 'bridge' in scenario.tags:
                print ("---------------------------")
                print ("deleting all possible bridge residues")

                if 'bridge_assumed' in scenario.tags:
                    call('ip link del bridge0', shell=True)
                    call('ip link del br0', shell=True)

                call('sudo nmcli con del bridge4 bridge4.0 bridge4.1 nm-bridge eth4.80 eth4.90', shell=True)
                call('sudo nmcli con del bridge-slave-eth4 bridge-nonslave-eth4 bridge-slave-eth4.80 eth4', shell=True)
                call('sudo nmcli con del bridge0 bridge bridge.15 nm-bridge br88 br11 br12 br15 bridge-slave br15-slave br15-slave1 br15-slave2 br10 br10-slave', shell=True)
                reset_hwaddr_nmcli('eth4')
            if 'bond_bridge' in scenario.tags:
                print ("---------------------------")
                print ("deleting all possible bond bridge")
                call('sudo nmcli con del bond_bridge0', shell=True)

            if 'team_br_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting all possible bridge residues")
                call('sudo nmcli con del team_br', shell=True)
                call('ip link del brA', shell=True)

            if 'gen_br_remove' in scenario.tags:
                print ("---------------------------")
                print ("deleting all possible bridge residues")
                call('sudo nmcli con del gen_br', shell=True)
                call('ip link del brX', shell=True)

            if 'vpn' in scenario.tags:
                print ("---------------------------")
                print ("removing vpn profiles")
                call("nmcli connection delete vpn", shell=True)

            if 'iptunnel' in scenario.tags:
                print("----------------------------")
                print("iptunnel teardown")
                call('sh prepare/iptunnel.sh teardown', shell=True)

            if 'wireguard' in scenario.tags:
                print("----------------------------")
                print("remove wireguard connection")
                call('nmcli con del wireguard', shell=True)

            if 'scapy' in scenario.tags:
                print ("---------------------------")
                print ("removing veth devices")
                call("ip link delete test10", shell=True)
                call("ip link delete test11", shell=True)
                call("nmcli connection delete ethernet-test10 ethernet-test11", shell=True)

            if 'dummy' in scenario.tags:
                print ("---------------------------")
                print ("removing dummy and bridge/bond/team devices")
                call("ip link delete dummy0", shell=True)
                call("ip link del br0", shell=True)
                call("ip link del vlan", shell=True)
                call("ip link del bond0", shell=True)
                call("ip link del team0", shell=True)


            if 'tuntap' in scenario.tags:
                print ("---------------------------")
                print ("removing tuntap devices")
                call("ip link del tap0", shell=True)
                call("nmcli con delete tap0", shell=True)
                call("ip link del brY", shell=True)
                call("ip link del brX", shell=True)


            if 'wifi' in scenario.tags:
                print ("---------------------------")
                print ("removing all wifi residues")
                #call('sudo nmcli device disconnect wlan0', shell=True)
                call('sudo nmcli con del wifi qe-open qe-wep qe-wep-psk qe-wep-enterprise qe-wep-enterprise-cisco', shell=True)
                call('sudo nmcli con del qe-wpa1-psk qe-wpa2-psk qe-wpa1-enterprise qe-wpa2-enterprise qe-hidden-wpa2-psk', shell=True)
                call('sudo nmcli con del qe-adhoc qe-ap wifi-wlan0', shell=True)
                if 'nmcli_wifi_add_connection_in_novice_nmcli_a_mode_with_bogus_ip' in scenario.tags:
                    context.prompt.close()
                    sleep(1)
                    call('sudo nmcli con del wifi-wlan0', shell=True)

            if 'nmcli_wifi_ap' in scenario.tags:
                call("sudo nmcli device wifi rescan", shell=True)
                sleep(10)

            if 'ifcfg-rh' in scenario.tags:
                print ("---------------------------")
                print ("enabling ifcfg-plugin")
                call("sudo sh -c \"echo '[main]\nplugins=ifcfg-rh' > /etc/NetworkManager/NetworkManager.conf\" ", shell=True)

            if 'keyfile_cleanup' in scenario.tags:
                print ("---------------------------")
                print ("removing residual files in /usr/lib/NetworkManager/system-connections")
                call("sudo sh -c \"rm /usr/lib/NetworkManager/system-connections/*\" ", shell=True)
                print ("removing residual files in /etc/NetworkManager/system-connections")
                call("sudo sh -c \"rm /etc/NetworkManager/system-connections/*\" ", shell=True)

            if 'waitforip' in scenario.tags:
                print ("---------------------------")
                print ("waiting till original IP regained")
                while True:
                    sleep(5)
                    cfg = pexpect.spawn('ifconfig')
                    if cfg.expect(['inet 10', pexpect.EOF]) == 0:
                        break

            if 'remove_dns_clean' in scenario.tags:
                if call('grep dns /etc/NetworkManager/NetworkManager.conf', shell=True) == 0:
                    call("sudo sed -i 's/dns=none//' /etc/NetworkManager/NetworkManager.conf", shell=True)
                call("sudo rm -rf /etc/NetworkManager/conf.d/90-test-dns-none.conf", shell=True)
                reload_NM_service()

            if 'restore_resolvconf' in scenario.tags:
                print ("---------------------------")
                print ("restore /etc/resolv.conf")
                call('rm -rf /etc/resolv.conf', shell=True)
                call('rm -rf /tmp/resolv_orig.conf', shell=True)
                call('rm -rf /tmp/resolv.conf', shell=True)
                call("rm -rf /etc/NetworkManager/conf.d/99-resolv.conf", shell=True)
                reload_NM_service()
                wait_for_testeth0 ()

            if 'need_config_server' in scenario.tags:
                if context.remove_config_server:
                    print ("---------------------------")
                    print ("removing NetworkManager-config-server")
                    call('sudo yum -y remove NetworkManager-config-server', shell=True)
                    reload_NM_service()

            if 'no_config_server' in scenario.tags:
                if context.restore_config_server:
                    print ("---------------------------")
                    print ("restoring NetworkManager-config-server")
                    config_files = check_output('rpm -ql NetworkManager-config-server', shell=True).decode('utf-8', 'ignore').strip().split('\n')
                    for config_file in config_files:
                        config_file = config_file.strip()
                        if os.path.isfile(config_file + '.off'):
                            print("* enabling file: %s" % config_file)
                            call('sudo mv -f %s.off %s' % (config_file, config_file), shell=True)
                    reload_NM_service()
                    call("for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |awk -F ':' ' {print $2}'); do nmcli con del $i; done", shell=True)
                    restore_testeth0()

            if 'openvswitch' in scenario.tags:
                print ("---------------------------")
                print ("remove openvswitch residuals")
                call('sudo ifdown bond0', shell=True)
                call('sudo ifdown eth1', shell=True)
                call('sudo ifdown eth2', shell=True)
                call('sudo ifdown ovsbridge0', shell=True)
                call('sudo nmcli con del eth1 eth2 ovs-bond0 ovs-port0 ovs-bridge0 ovs-port1 ovs-eth2 ovs-eth3 ovs-iface0 eth2 dpdk-sriov', shell=True) # to be sure
                sleep(1)
                call('ovs-vsctl del-br ovsbr0', shell=True)
                call('ovs-vsctl del-br ovsbridge0', shell=True)
                call('nmcli device delete bond0', shell=True)
                call('nmcli device delete port0', shell=True)
                call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-eth1', shell=True)
                call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-bond0', shell=True)
                call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ovsbridge0', shell=True)
                call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-intbr0', shell=True)
                call('sudo ip link set dev eth1 up', shell=True)
                call('sudo ip link set dev eth2 up', shell=True)
                call('sudo nmcli con reload', shell=True)
                call('nmcli con up testeth1', shell=True)
                call('nmcli con down testeth1', shell=True)
                call('nmcli con up testeth2', shell=True)
                call('nmcli con down testeth2', shell=True)

            if 'dpdk' in scenario.tags:
                print ("---------------------------")
                print ("remove dpdk residuals")
                call('systemctl stop ovsdb-server', shell=True)
                call('systemctl stop openvswitch', shell=True)
                sleep(5)
                call('nmcli con del dpdk-sriov ovs-iface1 && sleep 1', shell=True)
                call('systemctl device disconnect p4p1', shell=True)


            if 'remove_custom_cfg' in scenario.tags:
                print("---------------------------")
                print("Removing custom cfg file in conf.d")
                call('sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf', shell=True)
                reload_NM_service()

            if 'device_connect_no_profile' in scenario.tags or 'device_connect' in scenario.tags:
                print ("---------------------------")
                print ("env sanitization")
                call('nmcli connection delete testeth9 eth9', shell=True)
                call('nmcli connection add type ethernet ifname eth9 con-name testeth9 autoconnect no', shell=True)

            if 'nmcli_general_keep_slave_device_unmanaged' in scenario.tags:
                print ("---------------------------")
                print ("restoring the testeth8 profile to managed state / removing slave")
                call('sudo ip link del eth8.100', shell=True)
                call('sudo rm -f /etc/sysconfig/network-scripts/ifcfg-testeth8', shell=True)
                call('sudo nmcli connection reload', shell=True)
                call('nmcli connection add type ethernet ifname eth8 con-name testeth8 autoconnect no', shell=True)

            if 'nmcli_general_multiword_autocompletion' in scenario.tags:
                print ("---------------------------")
                print ("deleting profile in case of test failure")
                call('nmcli connection delete "Bondy connection 1"', shell=True)

            if 'nmcli_general_dhcp_profiles_general_gateway' in scenario.tags:
                print("---------------------------")
                print("restore /etc/sysconfig/network")
                call('sudo mv -f /tmp/sysnetwork.backup /etc/sysconfig/network', shell=True)
                call('sudo nmcli connection reload', shell=True)
                call('sudo nmcli connection down testeth9', shell=True)

            if 'nmcli_general_profile_pickup_doesnt_break_network' in scenario.tags:
                print("---------------------------")
                print("Restoring configuration, turning off network.service")
                context.nm_restarted = True
                call('sudo nmcli connection delete con_general con_general2', shell=True)
                call('sudo systemctl stop network.service', shell=True)
                call('sudo systemctl stop NetworkManager.service', shell=True)
                call('sysctl net.ipv6.conf.all.accept_ra=1', shell=True)
                call('sysctl net.ipv6.conf.default.accept_ra=1', shell=True)
                call('sudo systemctl start NetworkManager.service', shell=True)
                call('sudo nmcli connection down testeth8 testeth9', shell=True)
                call('sudo nmcli connection up testeth0', shell=True)

            if 'gsm' in scenario.tags:
                # You can debug here only with console connection to the testing machine.
                # SSH connection is interrupted.
                # import ipdb

                print ("---------------------------")
                print ("remove gsm profile and delete lock and dump logs")
                call('nmcli connection delete gsm', shell=True)
                call('rm -rf /etc/NetworkManager/system-connections/gsm', shell=True)
                call('nmcli con up testeth0', shell=True)
                wait_for_testeth0()
                if not os.path.isfile('/tmp/usb_hub'):
                    call('mount -o remount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch', shell=True)
                    delete_old_lock("/mnt/scratch/", get_lock("/mnt/scratch"))
                # Attach journalctl logs
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ MM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log")
                print("Attaching MM log")
                os.system("sudo journalctl -u ModemManager --no-pager -o cat %s >> /tmp/journal-mm.log" % context.log_cursor)
                data = utf_only_open_read("/tmp/journal-mm.log")
                if data:
                    context.embed('text/plain', data, caption="MM")
                # Extract modem model.
                # Example: 'USB ID 1c9e:9603 Zoom 4595' -> 'Zoom 4595'
                regex = r'USB ID (\w{4}:\w{4}) (.*)'
                mo = re.search(regex, context.modem_str)
                if mo:
                    modem_model = mo.groups()[1]
                    cap = modem_model
                else:
                    cap = 'MODEM INFO'

                modem_info = get_modem_info()
                if modem_info:
                    context.embed('text/plain', modem_info, caption=cap)

            if 'captive_portal' in scenario.tags:
                call("sudo prepare/captive_portal.sh teardown", shell=True)

            if 'gsm_sim' in scenario.tags:
                call("nmcli con down id gsm", shell=True)
                sleep(2)
                call("sudo prepare/gsm_sim.sh teardown", shell=True)
                sleep(1)
                call("nmcli con del id gsm", shell=True)

            if 'add_testeth10' in scenario.tags:
                print ("---------------------------")
                print ("restoring testeth10 profile")
                call('sudo nmcli connection delete eth10 testeth10', shell=True)
                call('sudo nmcli connection add type ethernet con-name testeth10 ifname eth10 autoconnect no', shell=True)

            if 'add_testeth1' in scenario.tags:
                print ("---------------------------")
                print ("restoring testeth1 profile")
                call('sudo nmcli connection delete eth1 eth1 eth1 testeth1', shell=True)
                call('sudo nmcli connection add type ethernet con-name testeth1 ifname eth1 autoconnect no', shell=True)

            if 'add_testeth5' in scenario.tags:
                print ("---------------------------")
                print ("restoring testeth1 profile")
                call('sudo nmcli connection delete eth5 eth5 eth5 testeth5', shell=True)
                call('sudo nmcli connection add type ethernet con-name testeth5 ifname eth5 autoconnect no', shell=True)

            if 'add_testeth8' in scenario.tags:
                print ("---------------------------")
                print ("restoring testeth1 profile")
                call('sudo nmcli connection delete eth8 eth8 eth8 testeth8', shell=True)
                call('sudo nmcli connection add type ethernet con-name testeth8 ifname eth8 autoconnect no', shell=True)

            if 'eth1_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth1 device")
                call('sudo nmcli device disconnect eth1', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth1', shell=True)
                call('sudo nmcli connection down testeth1', shell=True)

            if 'eth2_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth2 device")
                call('sudo nmcli device disconnect eth2', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth2', shell=True)
                call('sudo nmcli connection down testeth2', shell=True)

            if 'eth3_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth3 device")
                call('sudo nmcli device disconnect eth3', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth3', shell=True)
                call('sudo nmcli connection down testeth3', shell=True)

            if 'eth5_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth5 device")
                call('sudo nmcli device disconnect eth5', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth5', shell=True)
                call('sudo nmcli connection down testeth5', shell=True)

            if 'eth8_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth8 device")
                call('sudo nmcli device disconnect eth8', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth8', shell=True)
                call('sudo nmcli connection down testeth8', shell=True)

            if 'eth10_disconnect' in scenario.tags:
                print ("---------------------------")
                print ("disconnecting eth10 device")
                call('sudo nmcli device disconnect eth10', shell=True)
                # VVV Up/Down to preserve autoconnect feature
                call('sudo nmcli connection up testeth10', shell=True)
                call('sudo nmcli connection down testeth10', shell=True)

            if 'manage_eth8' in scenario.tags:
                print ("---------------------------")
                print ("manage eth1 device")
                call('sudo nmcli device set eth8 managed true', shell=True)

            if 'non_utf_device' in scenario.tags:
                print ("---------------------------")
                print ("remove non utf-8 device")
                if sys.version_info.major < 3:
                    call("ip link del $'d\xccf\\c'", shell=True)
                else:
                    call("ip link del $'d\\xccf\\\\c'", shell=True)

            if 'shutdown' in scenario.tags:
                print ("---------------------------")
                print ("sanitizing env")
                call('ip addr del 192.168.50.5/24 dev eth8', shell=True)
                call('route del default gw 192.168.50.1 eth8', shell=True)

            if 'connect_testeth0' in scenario.tags:
                print ("---------------------------")
                print ("upping testeth0")
                wait_for_testeth0 ()

            if 'vlan_create_many_vlans' in scenario.tags:
                print ("---------------------------")
                print ("delete all vlans")
                call("for i in {1..255}; do ip link del vlan.$i;done", shell=True)

            if 'delete_testeth0' in scenario.tags:
                print ("---------------------------")
                print ("restoring testeth0 profile")
                call('sudo nmcli connection delete eth0', shell=True)
                restore_testeth0()

            if 'kill_dbus-monitor' in scenario.tags:
                print ("---------------------------")
                print ("killing dbus-monitor")
                call('pkill -9 dbus-monitor', shell=True)

            if 'need_dispatcher_scripts' in scenario.tags:
                print ("---------------------------")
                print ("remove dispatcher scripts")
                wait_for_testeth0()
                call("yum -y remove NetworkManager-config-routing-rules ", shell=True)
                call("rm -rf /etc/sysconfig/network-scripts/rule-con_general", shell=True)
                call('rm -rf /etc/sysconfig/network-scripts/route-con_general', shell=True)
                call('ip rule del table 1; ip rule del table 1', shell=True)
                reload_NM_service()

            if 'pppoe' in scenario.tags:
                print ("---------------------------")
                print ("kill pppoe server and remove ppp connection")
                call('kill -9 $(pidof pppoe-server)', shell=True)
                call('nmcli con del ppp', shell=True)

            if 'display_allowed_values' in scenario.tags:
                print ("---------------------------")
                print ("delete various connections")
                call('nmcli con del con-team con-bond con-wifi', shell=True)

            if 'del_test1112_veths' in scenario.tags:
                print ("---------------------------")
                print ("removing test11 device")
                call('ip link del test11', shell=True)

            if 'teardown_testveth' in scenario.tags:
                teardown_testveth (context)

            if 'kill_children' in scenario.tags:
                children = getattr(context, "children", [])
                print('--------------------------')
                print('kill remaining children (%d)', len(children))
                for child in children:
                    child.kill()

            if '@restore_rp_filters' in scenario.tags:
                print ("---------------------------")
                print ("restore rp filters for eth2 and eth3")
                call('echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter', shell=True)
                call('echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter', shell=True)

            if 'remove_ctcdevice' in scenario.tags:
                print("---------------------------")
                print("removing ctc device")
                call("""znetconf -r $(znetconf -c |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }') -n""", shell=True)
                sleep(1)

            if 'permissive' in scenario.tags:
                if context.enforcing:
                    print("---------------------------")
                    print("WORKAROUND for permissive selinux")
                    call('setenforce 1', shell=True)

            if 'unmanage_eth' in scenario.tags:
                links = get_ethernet_devices()
                for link in links:
                    call('nmcli dev set %s managed yes' % link, shell=True)

            if 'regenerate_veth' in scenario.tags or 'restart' in scenario.tags:
                print ("---------------------------")
                print ("regenerate veth setup")
                if os.path.isfile('/tmp/nm_newveth_configured'):
                    call('sh prepare/vethsetup.sh check', shell=True)
                else:
                    for link in range(1,11):
                        call('ip link set eth%d up' % link, shell=True)


            # check for crash reports and embed them
            # sets crash_embeded and crashed_step, if crash found
            context.crash_embeded = False
            try:
                if 'no_abrt' in scenario.tags:
                    check_coredump(context, False)
                    check_faf(context, False)
                else:
                    check_coredump(context)
                    check_faf(context)

            except Exception as e:
                print("Exception during crash search!")
                traceback.print_exc(file=sys.stdout)


            if scenario.status == 'failed' or context.crashed_step:
                dump_status_nmcli(context, 'after cleanup %s' % scenario.name)

                # Attach journalctl logs
                print("Attaching NM log")
                os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-nm.log")
                os.system("sudo journalctl -all -u NetworkManager --no-pager -o cat %s >> /tmp/journal-nm.log" % context.log_cursor)
                if os.stat("/tmp/journal-nm.log").st_size < 20000000:
                    data = utf_only_open_read("/tmp/journal-nm.log")
                    if data:
                        context.embed('text/plain', data, caption="NM")
                else:
                    print("WARNING: 20M size exceeded in /tmp/journal-nm.log, skipping")


            if nm_pid_after is not None and context.nm_pid == nm_pid_after:
                context.log.write("NetworkManager memory consumption after: %d KiB\n" % nm_size_kb())
                if call("[ -f /etc/systemd/system/NetworkManager.service ] && grep -q valgrind /etc/systemd/system/NetworkManager.service", shell=True) == 0:
                    sleep(3) # Wait for dispatcher to finish its business
                    call("LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager -ex 'target remote | vgdb' -ex 'monitor leak_check full kinds all increased' -batch", shell=True, stdout=context.log, stderr=context.log)

            context.log.close ()
            print("Attaching MAIN log")
            context.embed('text/plain', utf_only_open_read("/tmp/log_%s.html" % scenario.name), caption="MAIN")

            if context.crashed_step:
                print ("\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                print ("!! NM CRASHED. NEEDS INSPECTION. FAILING THE TEST                      !!")
                print(("!! CRASHING STEP: %s" %(context.crashed_step)))
                print ("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n")
                context.embed('text/plain', context.crashed_step, caption="CRASHED_STEP_NAME")
                if not context.crash_embeded:
                    context.embed('text/plain', "!!! no crash report detected, but NM PID changed !!!", caption="NO_COREDUMP/NO_FAF")

        except Exception as e:
            print(("Error in after_scenario"))
            traceback.print_exc(file=sys.stdout)

def after_tag(context, tag):
    if IS_NMTUI:
        try:
            if tag in ('vlan','bridge','bond','team', 'inf'):
                if hasattr(context, 'is_virtual'):
                    context.is_virtual = False
        except Exception:
            # Stupid behave simply crashes in case exception has occurred
            print("Error in after_tag:")
            traceback.print_exc(file=sys.stdout)

def after_all(context):
    if not IS_NMTUI:
        print("ALL DONE")
