# -*- coding: UTF-8 -*-

import os
import pexpect
import sys
import traceback
import string
import fcntl
from subprocess import call, Popen, PIPE, check_output, CalledProcessError
from time import sleep, localtime, strftime
from glob import glob


TIMER = 0.5

# the order of these steps is as follows
# 1. before scenario
# 2. before tag
# 3. after scenario
# 4. after tag

def nm_pid():
    try:
        pid = int(check_output(['systemctl', 'show', '-pMainPID', 'NetworkManager.service']).split('=')[-1])
    except CalledProcessError, e:
        pid = None
    if not pid:
        try:
            pid = int(check_output(['pgrep', 'NetworkManager']))
        except CalledProcessError, e:
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

def dump_status(context, when):
    context.log.write("\n\n\n=================================================================================\n")
    context.log.write("Network configuration %s:\n\n" % when)
    f = open(os.devnull, 'w')
    if call('systemctl status NetworkManager', shell=True, stdout=f) != 0:
        for cmd in ['ip addr', 'ip -4 route', 'ip -6 route']:
            context.log.write("--- %s ---\n" % cmd)
            context.log.flush()
            call(cmd, shell=True, stdout=context.log)
    else:
        for cmd in ['ip addr', 'ip -4 route', 'ip -6 route',
            'nmcli g', 'nmcli c', 'nmcli d', 'nmcli -f IN-USE,SSID,CHAN,SIGNAL,SECURITY d w', 'hostnamectl']:
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

def reset_usb_devices():
    USBDEVFS_RESET= 21780
    def getfile(dirname, filename):
        f = open("%s/%s" % (dirname, filename), "r")
        contents = f.read()
        f.close()
        return contents

    USB_DEV_DIR = "/sys/bus/usb/devices"
    dirs = os.listdir(USB_DEV_DIR)
    for d in dirs:
        # Skip interfaces, we only care about devices
        if string.find(d, ":") >= 0:
            continue

        busnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "busnum"))
        devnum = int(getfile("%s/%s" % (USB_DEV_DIR, d), "devnum"))
        f = open("/dev/bus/usb/%03d/%03d"%(busnum, devnum), 'w', os.O_WRONLY)
        try:
            fcntl.ioctl(f, USBDEVFS_RESET, 0)
        except Exception, msg:
            print ("failed to reset device:", msg)
        f.close()

def setup_racoon(mode, dh_group, phase1_al="aes", phase2_al=None):
    print ("setting up racoon")
    arch = check_output("uname -p", shell=True).strip()
    wait_for_testeth0()
    if arch == "s390x" or arch == 'aarch64':
        call("[ -x /usr/sbin/racoon ] || yum -y install https://vbenes.fedorapeople.org/NM/ipsec-tools-0.8.2-1.el7.$(uname -p).rpm", shell=True)
    else:
        call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
        call("[ -x /usr/sbin/racoon ] || yum -y install ipsec-tools", shell=True)

    RC = call("sh prepare/racoon.sh %s %s %s" %(mode, dh_group, phase1_al), shell=True)
    if RC != 0:
        teardown_racoon()
        sys.exit(1)

def teardown_racoon():
    call("sh prepare/racoon.sh teardown", shell=True)

def reset_hwaddr(ifname):
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        hwaddr = check_output("ethtool -P %s" % ifname, shell=True).split()[2]
        call("ip link set %s address %s" % (ifname, hwaddr), shell=True)

def setup_hostapd():
    print ("setting up hostapd")
    wait_for_testeth0()
    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
    call("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)", shell=True)

    if call("sh prepare/hostapd_wired.sh tmp/8021x/certs", shell=True) != 0:
        call("sh prepare/hostapd_wired.sh teardown", shell=True)
        sys.exit(1)

def setup_hostapd_wireless(auth):
    print ("setting up hostapd wireless")
    wait_for_testeth0()
    call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
    call("[ -x /usr/sbin/hostapd ] || (yum -y install hostapd; sleep 10)", shell=True)

    if call("sh prepare/hostapd_wireless.sh tmp/8021x/certs {}".format(auth), shell=True) != 0:
        call("sh prepare/hostapd_wireless.sh teardown", shell=True)
        sys.exit(1)

def teardown_hostapd_wireless():
    call("sh prepare/hostapd_wireless.sh teardown", shell=True)

def teardown_hostapd():
    call("sh prepare/hostapd_wired.sh teardown", shell=True)

def get_lock(dir):
    locks = os.listdir(dir)
    if locks == []:
        return None
    else:
        return int(locks[0])

def delete_old_lock(dir, lock):
    print ("* deleting old gsm lock %s" %lock)
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
    if call("nmcli connection show testeth0 > /dev/null", shell=True)!= 0:
        restore_testeth0()

    counter=40
    while call("nmcli connection show testeth0 |grep IP4.ADDRESS > /dev/null", shell=True) != 0:
        sleep(1)
        counter-=1
        if counter == 20:
            restore_testeth0()
        if counter == 0:
            print ("Testeth0 cannot be upped..this is wrong")
            sys.exit(1)

def before_scenario(context, scenario):
    try:
        if not os.path.isfile('/tmp/nm_wifi_configured') and not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
            if call("nmcli device |grep testeth0 |grep ' connected'", shell=True) != 0:
                call("sudo nmcli connection modify testeth0 ipv4.may-fail no", shell=True)
                call("sudo nmcli connection up id testeth0", shell=True)
                for attempt in xrange(0, 10):
                    if call("nmcli device |grep testeth0 |grep ' connected'", shell=True) == 0:
                        break
                    sleep(1)

        os.environ['TERM'] = 'dumb'

        # dump status before the test preparation starts
        context.log = file('/tmp/log_%s.html' % scenario.name,'w')
        dump_status(context, 'before %s' % scenario.name)

        if 'long' in scenario.tags:
            print ("---------------------------")
            print ("skipping long test case if /tmp/nm_skip_long exists")
            if os.path.isfile('/tmp/nm_skip_long'):
                sys.exit(0)


        if '1000' in scenario.tags:
            print ("---------------------------")
            print ("installing pip and pyroute2")
            wait_for_testeth0()
            if not os.path.isfile('/usr/bin/pip'):
                call('sudo easy_install pip', shell=True)
            if call('pip install pyroute2', shell=True) != 0:
                call ('yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python2-pyroute2-0.4.13-1.el7.noarch.rpm', shell=True)

        if 'rhel7_only' in scenario.tags:
            if call('rpm -qi NetworkManager |grep -q build.*bos.redhat.co', shell=True) != 0 or \
            check_output("rpm --queryformat %{RELEASE} -q NetworkManager |awk -F .  '{ print ($1 < 200) }'", shell=True).strip() == '0':
                sys.exit(0)

        if 'not_in_rhel' in scenario.tags:
            if call('rpm -qi NetworkManager |grep -q build.*bos.redhat.com', shell=True) == 0 or \
            check_output("rpm --queryformat %{RELEASE} -q NetworkManager |awk -F .  '{ print ($1 < 200) }'", shell=True).strip() == '1':
                sys.exit(0)

        if 'not_on_s390x' in scenario.tags:
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x":
                sys.exit(0)

        if 'not_on_aarch64' in scenario.tags:
            arch = check_output("uname -p", shell=True).strip()
            if arch == "aarch64":
                sys.exit(0)

        if 'not_on_aarch64_but_pegas' in scenario.tags:
            arch = check_output("uname -p", shell=True).strip()
            ver = check_output("uname -r", shell=True).strip()
            if arch == "aarch64":
                if "4.5" in ver:
                    sys.exit(0)

        if 'gsm' in scenario.tags:
            import time
            dir = "/mnt/scratch/"
            timeout = 3600
            initialized = False
            freq = 30
            call("mmcli -G debug", shell=True)
            call("nmcli general logging level DEBUG domains ALL", shell=True)

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
                    print ("* creating new gsm lock %s" % lock)
                    os.mkdir("%s%s" % (dir, lock))
                    return True
                else:
                    return False

            def is_lock_old(lock):
                lock += 3600
                if lock < int(time.time()):
                    print ("* lock %s is older than an hour" % lock)
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
                        print ("** still locked.. wating %s seconds before next try" % freq)
                        if not initialized:
                            reinitialize_devices()
                        sleep(freq)
                        if timeout == 0:
                            raise Exception("Timeout reached!")
                        continue

        if 'connectivity' in scenario.tags:
            print ("---------------------------")
            print ("add connectivity checker")
            call("echo '[connectivity]' > /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
            call("echo 'uri=http://fedoraproject.org/static/hotspot.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
            call("echo 'response=OK' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
            call("echo 'interval=5' >> /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            sleep(3)
            call("systemctl restart NetworkManager", shell=True)
            sleep(3)

        if 'shutdown_service_any' in scenario.tags or 'bridge_manipulation_with_1000_slaves' in scenario.tags:
            call("modprobe -r qmi_wwan", shell=True)
            call("modprobe -r cdc-mbim", shell=True)

        if 'need_s390x' in scenario.tags:
            arch = check_output("uname -p", shell=True).strip()
            if arch != "s390x":
                sys.exit(0)

        if 'allow_veth_connections' in scenario.tags:
            if call("grep '^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"' /usr/lib/udev/rules.d/85-nm-unmanaged.rules", shell=True) == 0:
                call("sed -i 's/^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/#ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/' /usr/lib/udev/rules.d/85-nm-unmanaged.rules", shell=True)
                cfg = Popen("sudo sh -c 'cat > /etc/NetworkManager/conf.d/99-unmanaged.conf'", stdin=PIPE, shell=True).stdin
                cfg.write('[main]')
                cfg.write("\n" + 'no-auto-default=eth*')
                cfg.write("\n")
                cfg.close()
                call("pkill -HUP NetworkManager", shell=True)
                context.revert_unmanaged = True
            else:
                context.revert_unmanaged = False

        if 'not_under_internal_DHCP' in scenario.tags:
            if call("grep dhcp=internal /etc/NetworkManager/NetworkManager.conf", shell=True) == 0:
                sys.exit(0)

        if 'newveth' in scenario.tags or 'not_on_veth' in scenario.tags:
            if os.path.isfile('/tmp/nm_newveth_configured'):
                sys.exit(0)

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
            call("nmcli connection up testeth8", shell=True)
            call("nmcli connection delete eth8", shell=True)

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
            if not os.path.isfile('/usr/bin/pip'):
                call('sudo easy_install pip', shell=True)
            if not os.path.isfile('/usr/bin/scapy'):
                call('sudo yum -y install tcpdump', shell=True)
                call("sudo pip install http://www.secdev.org/projects/scapy/files/scapy-latest.tar.gz", shell=True)

        if 'mock' in scenario.tags:
            print ("---------------------------")
            print ("installing dbus-x11, pip, and python-dbusmock")
            if call('rpm -q --quiet dbus-x11', shell=True) != 0:
                call('yum -y install dbus-x11', shell=True)
            if not os.path.isfile('/usr/bin/pip'):
                call('sudo easy_install pip', shell=True)
            if call('pip list |grep python-dbusmock', shell=True) != 0:
                call("sudo pip install python-dbusmock", shell=True)

        if 'IPy' in scenario.tags:
            print ("---------------------------")
            print ("installing dbus-x11, pip, and IPy")
            wait_for_testeth0()
            if call('rpm -q --quiet dbus-x11', shell=True) != 0:
                call('yum -y install dbus-x11', shell=True)
            if not os.path.isfile('/usr/bin/pip'):
                call('sudo easy_install pip', shell=True)
            if call('pip list |grep IPy', shell=True) != 0:
                call("sudo pip install IPy", shell=True)

        if 'netaddr' in scenario.tags:
            print ("---------------------------")
            print ("install netaddr")
            wait_for_testeth0()
            if not os.path.isfile('/usr/bin/pip'):
                call('sudo easy_install pip', shell=True)
            if call('pip list |grep netaddr', shell=True) != 0:
                call("sudo pip install netaddr", shell=True)

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

        if 'internal_DHCP' in scenario.tags:
            print ("---------------------------")
            print ("set internal DHCP")
            call("printf '# configured by beaker-test\n[main]\ndhcp=internal\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf", shell=True)
            call('systemctl restart NetworkManager.service', shell=True)

        if 'dhcpd' in scenario.tags:
            print ("---------------------------")
            print ("installing dhcp")
            wait_for_testeth0()
            if call('rpm -q --quiet dhcp', shell=True) != 0:
                call('yum -y install dhcp', shell=True)

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

        if 'eth1_disconnect' in scenario.tags:
            print ("---------------------------")
            print ("disconnecting eth1 device")
            call('sudo nmcli device disconnect eth1', shell=True)

        if 'need_dispatcher_scripts' in scenario.tags:
            print ("---------------------------")
            print ("install dispatcher scripts")
            wait_for_testeth0()
            call("yum -y install NetworkManager-config-routing-rules", shell=True)
            sleep(2)

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

        if ('ethernet' in scenario.tags) or ('bridge' in scenario.tags) or ('vlan' in scenario.tags):
            print ("---------------------------")
            print ("sanitizing eth1 and eth2")
            if call('nmcli con |grep testeth1', shell=True) == 0 or call('nmcli con |grep testeth2', shell=True) == 0:
                call('sudo nmcli con del testeth1 testeth2', shell=True)
                call('sudo nmcli con add type ethernet ifname eth1 con-name testeth1 autoconnect no', shell=True)
                call('sudo nmcli con add type ethernet ifname eth2 con-name testeth2 autoconnect no', shell=True)

        if 'logging' in scenario.tags:
            context.loggin_level = check_output('nmcli -t -f LEVEL general logging', shell=True).strip()

        if 'nmcli_general_profile_pickup_doesnt_break_network' in scenario.tags:
            print("---------------------------")
            print("turning on network.service")
            context.nm_restarted = True
            call('sudo pkill -9 /sbin/dhclient', shell=True)
            # Make orig- devices unmanaged as they may be unfunctional
            call('for dev in $(nmcli  -g DEVICE d |grep orig); do nmcli device set $dev managed off; done', shell=True)
            call('sudo systemctl restart NetworkManager.service', shell=True)
            call('sudo systemctl restart network.service', shell=True)
            call("nmcli connection up testeth0", shell=True)
            sleep(1)

        if 'vlan' in scenario.tags or 'bridge' in scenario.tags:
            print ("---------------------------")
            print ("connecting eth1")
            call("nmcli connection up testeth1", shell=True)

        if '8021x' in scenario.tags:
            print ("---------------------------")
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x" or arch == 'aarch64':
                sys.exit(0)
            setup_hostapd()

        if 'simwifi_wpa2' in scenario.tags:
            print ("---------------------------")
            arch = check_output("uname -p", shell=True).strip()
            if arch != "x86_64":
                sys.exit(0)
            setup_hostapd_wireless('wpa2')

        if 'vpnc' in scenario.tags:
            print ("---------------------------")
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x" or arch == 'aarch64':
                sys.exit(0)
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
            call("rpm -q NetworkManager-vpnc || ( sudo yum -y install NetworkManager-vpnc && service NetworkManager restart )", shell=True)
            setup_racoon (mode="aggressive", dh_group=2)

        if 'lldp' in scenario.tags:
            print ("---------------------------")
            print ("install tcpreplay")
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x" or arch == 'aarch64':
                sys.exit(0)
            wait_for_testeth0()
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
            call("[ -x /usr/bin/tcpreplay ] || yum -y install tcpreplay", shell=True)

        if 'openvpn' in scenario.tags:
            print ("---------------------------")
            print ("setting up OpenVPN")
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x" or arch == 'aarch64':
                sys.exit(0)
            wait_for_testeth0()
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
            call("[ -x /usr/sbin/openvpn ] || sudo yum -y install openvpn NetworkManager-openvpn", shell=True)
            call("rpm -q NetworkManager-openvpn || ( sudo yum -y install NetworkManager-openvpn-1.0.8-1.el7.$(uname -p).rpm && service NetworkManager restart )", shell=True)

            # This is an internal RH workaround for secondary architecures that are not present in EPEL

            call("[ -x /usr/sbin/openvpn ] || sudo yum -y install https://vbenes.fedorapeople.org/NM/openvpn-2.3.8-1.el7.$(uname -p).rpm\
                                                                  https://vbenes.fedorapeople.org/NM/pkcs11-helper-1.11-3.el7.$(uname -p).rpm", shell=True)
            call("rpm -q NetworkManager-openvpn || sudo yum -y install https://vbenes.fedorapeople.org/NM/NetworkManager-openvpn-1.0.8-1.el7.$(uname -p).rpm", shell=True)
            call("service NetworkManager restart", shell=True)
            sleep(2)

            samples = glob(os.path.abspath('tmp/openvpn'))[0]
            cfg = Popen("sudo sh -c 'cat >/etc/openvpn/trest-server.conf'", stdin=PIPE, shell=True).stdin
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
            if not 'openvpn4' in scenario.tags:
                cfg.write("\n" + 'tun-ipv6')
                cfg.write("\n" + 'push tun-ipv6')
                cfg.write("\n" + 'ifconfig-ipv6 2001:db8:666:dead::1/64 2001:db8:666:dead::1')
                cfg.write("\n" + 'ifconfig-ipv6-pool 2001:db8:666:dead::/64')
                cfg.write("\n" + 'push "ifconfig-ipv6 2001:db8:666:dead::2/64 2001:db8:666:dead::1"')
                cfg.write("\n" + 'push "route-ipv6 2001:db8:666:dead::/64 2001:db8:666:dead::1"')
            cfg.write("\n")
            cfg.close()
            call("sudo systemctl restart openvpn@trest-server", shell=True)

        if 'libreswan' in scenario.tags:
            print ("---------------------------")
            wait_for_testeth0()
            call("rpm -q NetworkManager-libreswan || ( sudo yum -y install NetworkManager-libreswan && service NetworkManager restart )", shell=True)
            call("/usr/sbin/ipsec --checknss", shell=True)
            setup_racoon (mode="aggressive", dh_group=5)
            if 'libreswan_add_profile' in scenario.tags:
                # Workaround for failures first in libreswan setup
                teardown_racoon ()
                setup_racoon (mode="aggressive", dh_group=5)

            #call("ip route add default via 172.31.70.1", shell=True)

        if 'libreswan_main' in scenario.tags:
            print ("---------------------------")
            wait_for_testeth0()
            call("rpm -q NetworkManager-libreswan || sudo yum -y install NetworkManager-libreswan", shell=True)
            call("/usr/sbin/ipsec --checknss", shell=True)
            setup_racoon (mode="main", dh_group=5)

        if 'macsec' in scenario.tags:
            print("---------------------------")
            print("installing macsec stuff")
            install = "yum install -y https://vbenes.fedorapeople.org/NM/dnsmasq-debuginfo-2.76-2.el7.$(uname -p).rpm \
                                  https://vbenes.fedorapeople.org/NM/dnsmasq-2.76-2.el7.$(uname -p).rpm \
                                  https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.6-4.el7.$(uname -p).rpm \
                                  https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.6-4.el7.$(uname -p).rpm"
            call(install, shell=True)
            call("systemctl restart wpa_supplicant", shell=True)

        if 'preserve_8021x_certs' in scenario.tags:
            print ("---------------------------")
            call("curl -s https://raw.githubusercontent.com/NetworkManager/NetworkManager/master/libnm-core/tests/certs/test-key-and-cert.pem -o /tmp/test_key_and_cert.pem", shell=True)
            call("curl -s https://raw.githubusercontent.com/NetworkManager/NetworkManager/master/libnm-core/tests/certs/test2_ca_cert.pem -o /tmp/test2_ca_cert.pem", shell=True)

        if 'pptp' in scenario.tags:
            print ("---------------------------")
            print ("setting up pptpd")
            arch = check_output("uname -p", shell=True).strip()
            if arch == "s390x" or arch == 'aarch64':
                sys.exit(0)
            wait_for_testeth0()
            call("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm", shell=True)
            call("[ -x /usr/sbin/pptpd ] || sudo yum -y install /usr/sbin/pptpd", shell=True)
            call("rpm -q NetworkManager-pptp || sudo yum -y install NetworkManager-pptp", shell=True)

            call("sudo rm -f /etc/ppp/ppp-secrets", shell=True)
            psk = Popen("sudo sh -c 'cat >/etc/ppp/chap-secrets'", stdin=PIPE, shell=True).stdin
            psk.write("budulinek pptpd passwd *\n")
            psk.close()

            if not os.path.isfile('/tmp/nm_pptp_configured'):
                call("sudo systemctl restart NetworkManager", shell=True)
                cfg = Popen("sudo sh -c 'cat >/etc/pptpd.conf'", stdin=PIPE, shell=True).stdin
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

        #if 'restore_hostname' in scenario.tags:
        #    print ("---------------------------")
        #    print ("saving original hostname")
        #    context.original_hostname = check_output('nmcli gen hostname', shell=True).strip()

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
            arch = check_output("uname -p", shell=True).strip()
            if arch != "x86_64":
                sys.exit(0)
            print ("---------------------------")
            print ("remove all team packages except NM one and reinstall them with delayed version")
            call("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done", shell=True)
            call("yum -y install https://vbenes.fedorapeople.org/NM/slow_libteam-1.25-5.el7_4.1.1.x86_64.rpm https://vbenes.fedorapeople.org/NM/slow_teamd-1.25-5.el7_4.1.1.x86_64.rpm", shell=True)
            call("systemctl restart NetworkManager.service", shell=True)

        if 'openvswitch' in scenario.tags:
            print ("---------------------------")
            print ("starting openvswitch if not active")
            if call('rpm -q NetworkManager-ovs', shell=True) != 0:
                call('yum -y install NetworkManager-ovs', shell=True)
                call('systemctl daemon-reload', shell=True)
                call('systemctl restart NetworkManager', shell=True)
            if call('systemctl is-active openvswitch', shell=True) != 0:
                call('yum -y install openvswitch', shell=True)
                call('systemctl restart openvswitch', shell=True)
                call('systemctl restart NetworkManager', shell=True)

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
            call("semodule -i tmp/ifup_policy.pp", shell=True)

        if 'nmcli_general_ignore_specified_unamanaged_devices' in scenario.tags:
            print ("---------------------------")
            print ("backing up NetworkManager.conf")
            call('sudo cp -f /etc/NetworkManager/NetworkManager.conf /tmp/bckp_nm.conf', shell=True)

        if 'ipv6_keep_connectivity_on_assuming_connection_profile' in scenario.tags:
            print ("---------------------------")
            print ("removing testeth10 profile")
            call('sudo nmcli connection delete testeth10', shell=True)

        if 'pppoe' in scenario.tags:
            print ("---------------------------")
            print ("installing pppoe dependencies")
            # This -x is to avoid upgrade of NetworkManager in older version testing
            call("yum -y install NetworkManager-ppp -x NetworkManager", shell=True)
            call('yum -y install rp-pppoe', shell=True)

        if 'nmcli_general_dhcp_profiles_general_gateway' in scenario.tags:
            print("---------------------------")
            print("backup of /etc/sysconfig/network")
            call('sudo cp -f /etc/sysconfig/network /tmp/sysnetwork.backup', shell=True)

        if 'remove_fedora_connection_checker' in scenario.tags:
            print("---------------------------")
            print("Making sure NetworkManager-config-connectivity-fedora is not installed")
            wait_for_testeth0()
            call('yum -y remove NetworkManager-config-connectivity-fedora', shell=True)
            call('sudo systemctl restart NetworkManager.service', shell=True)
            sleep(5)

        if 'remove_custom_cfg' in scenario.tags:
            print("---------------------------")
            print("Removing custom cfg file in conf.d")
            call('sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf', shell=True)
            call('sudo systemctl restart NetworkManager.service', shell=True)

        if 'need_config_server' in scenario.tags:
            print("---------------------------")
            print("Making sure NetworkManager-config-server is installed")
            if call('rpm -q NetworkManager-config-server', shell=True) == 0:
                context.remove_config_server = False
            else:
                call('sudo yum -y install NetworkManager-config-server', shell=True)
                call('sudo cp /usr/lib/NetworkManager/conf.d/00-server.conf /etc/NetworkManager/conf.d/00-server.conf', shell=True)
                call('sudo systemctl restart NetworkManager.service', shell=True)
                context.remove_config_server = True

        if 'no_config_server' in scenario.tags:
            print("---------------------------")
            print("Making sure NetworkManager-config-server is not installed")
            if call('rpm -q NetworkManager-config-server', shell=True) == 1:
                context.restore_config_server = False
            else:
                wait_for_testeth0()
                call('sudo yum -y remove NetworkManager-config-server', shell=True)
                call('sudo rm -f /etc/NetworkManager/conf.d/00-server.conf', shell=True)
                call('sudo systemctl restart NetworkManager.service', shell=True)
                context.restore_config_server = True

        try:
            context.nm_pid = nm_pid()
        except CalledProcessError, e:
            context.nm_pid = None

        print("NetworkManager process id before: %s" % context.nm_pid)

        if context.nm_pid is not None:
            context.log.write("NetworkManager memory consumption before: %d KiB\n" % nm_size_kb())
            if call("[ -f /etc/systemd/system/NetworkManager.service ] && grep -q valgrind /etc/systemd/system/NetworkManager.service", shell=True) == 0:
                call("LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch", shell=True, stdout=context.log, stderr=context.log)

        context.log_cursor = check_output("journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print \"\\\"--after-cursor=\"$NF\"\\\"\"; exit}'", shell=True).strip()

        os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ TRAFFIC LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/network-traffic.log")
        Popen("sudo tcpdump -nne -i any >> /tmp/network-traffic.log", shell=True)

    except Exception as e:
        print("Error in before_scenario: %s" % e.message)
        traceback.print_exc(file=sys.stdout)

def after_step(context, step):
    """
    """
    sleep(0.1)
    if step.name == ('Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites' or \
       step.name == 'Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites') and \
       step.status == 'failed' and step.step_type == 'given':
        print("Omitting the test as device does not AP/ADHOC mode")
        sys.exit(0)
    # for nmcli_wifi_right_band_80211a - HW dependent 'passes'
    if step.name == 'Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is set in WirelessCapabilites' and \
       step.status == 'failed' and step.step_type == 'given':
        print("Omitting the test as device does not support 802.11a")
        sys.exit(0)
    # for testcase_306559
    if step.name == 'Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is not set in WirelessCapabilites' and \
       step.status == 'failed' and step.step_type == 'given':
        print("Omitting test as device supports 802.11a")
        sys.exit(0)


def after_scenario(context, scenario):
    """
    """
    nm_pid_after = None
    try:
        nm_pid_after = nm_pid()
        print("NetworkManager process id after: %s (was %s)" % (nm_pid_after, context.nm_pid))
    except Exception as e:
        print("nm_pid wasn't set. Probably crash in before_scenario: %s" % e.message)
        pass

    try:
        # Attach journalctl logs
        os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-nm.log")
        os.system("sudo journalctl -u NetworkManager --no-pager -o cat %s >> /tmp/journal-nm.log" % context.log_cursor)
        if os.stat("/tmp/journal-nm.log").st_size < 20000000:
            data = open("/tmp/journal-nm.log", 'r').read()
            if data:
                context.embed('text/plain', data)
        else:
            print("WARNING: 20M size exceeded in /tmp/journal-nm.log, skipping")

        #attach network traffic log
        call("sudo kill -1 $(pidof tcpdump)", shell=True)
        if os.stat("/tmp/network-traffic.log").st_size < 20000000:
            traffic = open("/tmp/network-traffic.log", 'r').read()
            if traffic:
                context.embed('text/plain', traffic)
        else:
            print("WARNING: 20M size exceeded in /tmp/network-traffic.log, skipping")

        if 'netservice' in scenario.tags:
            # Attach network.service journalctl logs
            os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NETWORK SRV LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-netsrv.log")
            os.system("sudo journalctl -u network --no-pager -o cat %s >> /tmp/journal-netsrv.log" % context.log_cursor)
            data = open("/tmp/journal-netsrv.log", 'r').read()
            if data:
                context.embed('text/plain', data)

        if 'runonce' in scenario.tags:
            print ("---------------------------")
            print ("delete profiles and start NM")
            call("for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True)
            call("rm -rf /etc/NetworkManager/conf.d/01-run-once.conf", shell=True)
            sleep (1)
            call("systemctl restart  NetworkManager", shell=True)
            sleep (1)
            call("for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True)
            call("nmcli connection delete ethie", shell=True)
            call("nmcli device disconnect eth10", shell=True)
            call("nmcli connection up testeth0", shell=True)

        if 'restart' in scenario.tags:
            print ("---------------------------")
            print ("restarting NM service")
            call('sudo service NetworkManager restart', shell=True)
            if not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
                wait_for_testeth0()
        dump_status(context, 'after %s' % scenario.name)

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
                call('sudo service NetworkManager restart', shell=True)
            call("nmcli con del 'Wired connection 1'", shell=True)
            call("nmcli con del 'Wired connection 2'", shell=True)
            call("for i in $(nmcli -t -f DEVICE c s -a |grep -v ^eth0$); do nmcli device disconnect $i; done", shell=True)

        if 'mac' in scenario.tags:
            print ("---------------------------")
            print ("delete mac config")
            call("rm -rf /etc/NetworkManager/conf.d/99-mac.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            reset_hwaddr('eth1')

        if 'ipv4' in scenario.tags:
            print ("---------------------------")
            print ("deleting connection ethie")
            call("nmcli connection delete id ethie", shell=True)
            #sleep(TIMER)

        if 'ipv4_2' in scenario.tags:
            print ("---------------------------")
            print ("deleting connections ethie and ethie2")

            call("nmcli connection delete id ethie2", shell=True)
            call("nmcli connection delete id ethie", shell=True)
            #sleep(TIMER)

        if 'alias' in scenario.tags:
            print ("---------------------------")
            print ("deleting alias connections")
            call("nmcli connection delete eth8", shell=True)
            call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth8:0", shell=True)
            call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth8:1", shell=True)
            call("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth8:2", shell=True)
            call("sudo nmcli connection reload", shell=True)
            #call('sudo nmcli con add type ethernet ifname eth7 con-name testeth7 autoconnect no', shell=True)
            #sleep(TIMER)

        if 'slaves' in scenario.tags:
            print ("---------------------------")
            print ("deleting slave profiles")
            call('nmcli connection delete id bond0.0 bond0.1 bond0.2 bond-slave-eth1', shell=True)
            reset_hwaddr('eth1')
            reset_hwaddr('eth2')
            reset_hwaddr('eth3')
            reset_hwaddr('eth10')
            #sleep(TIMER)

        if 'bond' in scenario.tags:
            print ("---------------------------")
            print ("deleting bond profile")
            call('nmcli connection delete id bond0 bond', shell=True)
            call('ip link del nm-bond', shell=True)
            call('ip link del bond0', shell=True)
            #sleep(TIMER)
            print (os.system('ls /proc/net/bonding'))

        if 'bond_order' in scenario.tags:
            print ("---------------------------")
            print ("reset bond order")
            call("rm -rf /etc/NetworkManager/conf.d/99-bond.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            sleep(2)

        if 'connectivity' in scenario.tags:
            print ("---------------------------")
            print ("remove connectivity checker")
            call("rm -rf /etc/NetworkManager/conf.d/99-connectivity.conf", shell=True)
            call("rm -rf /var/lib/NetworkManager/NetworkManager-intern.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            sleep(3)
            call("systemctl restart NetworkManager", shell=True)
            sleep(3)

        if 'con' in scenario.tags:
            print ("---------------------------")
            print ("deleting connie")
            call("nmcli connection delete id connie", shell=True)
            call("rm -rf /etc/sysconfig/network-scripts/ifcfg-connie*", shell=True)
            #sleep(TIMER)

        if 'BBB' in scenario.tags:
            print ("---------------------------")
            print ("deleting BBB")
            call("ip link delete BBB", shell=True)
            call("nmcli connection delete id BBB", shell=True)
            #sleep(TIMER)

        if 'disp' in scenario.tags:
            print ("---------------------------")
            print ("deleting dispatcher files")
            call("rm -rf /etc/NetworkManager/dispatcher.d/*-disp", shell=True)
            call("rm -rf /etc/NetworkManager/dispatcher.d/pre-up.d/98-disp", shell=True)
            call("rm -rf /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp", shell=True)
            #call("rm -rf /tmp/dispatcher.txt", shell=True)
            call('nmcli con down testeth1', shell=True)
            call('nmcli con down testeth2', shell=True)
            call('kill -1 $(pidof NetworkManager)', shell=True)

        if 'eth' in scenario.tags:
            print ("---------------------------")
            print ("deleting ethie")
            call("nmcli connection delete id ethie", shell=True)
            call("rm -rf /etc/sysconfig/network-scripts/ifcfg-ethie*", shell=True)

        if 'eth_down_and_delete' in scenario.tags:
            print ("---------------------------")
            print ("deleting ethie")
            call("nmcli connection down id ethie", shell=True)
            call("nmcli connection delete id ethie", shell=True)

        if 'firewall' in scenario.tags:
            print ("---------------------------")
            print ("stoppping firewall")
            call("sudo firewall-cmd --panic-off", shell=True)
            call("sudo service firewalld stop", shell=True)

        if 'flush_300' in scenario.tags:
            print ("---------------------------")
            print ("flush route table 300")
            call("ip route flush table 300", shell=True)

        if 'logging' in scenario.tags:
            print ("---------------------------")
            print ("setting log level back")
            call('sudo nmcli g log level %s domains ALL' % context.loggin_level, shell=True)

        if 'eth0' in scenario.tags:
            print ("---------------------------")
            print ("upping eth0")
            restore_testeth0()

        if 'time' in scenario.tags:
            print ("---------------------------")
            print ("time connection delete")
            call("nmcli connection delete id time", shell=True)
            #sleep(TIMER)

        if 'dcb' in scenario.tags:
            print ("---------------------------")
            print ("deleting connection dcb")
            call("nmcli connection down id dcb", shell=True)
            call("nmcli connection delete id dcb", shell=True)
            sleep(10*TIMER)

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
            call('rm -f /etc/udev/rules.d/88-lr.rules', shell=True)
            call('udevadm control --reload-rules', shell=True)
            call('udevadm settle', shell=True)
            sleep(1)

        if 'internal_DHCP' in scenario.tags:
            print ("---------------------------")
            print ("revert internal DHCP")
            call("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf", shell=True)
            call('systemctl restart NetworkManager.service', shell=True)

        if 'dhcpd' in scenario.tags:
            print ("---------------------------")
            print ("deleting veth devices")
            call("sudo service dhcpd stop", shell=True)

        if 'stop_radvd' in scenario.tags:
            print ("---------------------------")
            print ("deleting veth devices")
            call("sudo systemctl stop radvd", shell=True)
            call('rm -rf /etc/radvd.conf', shell=True)
        if 'mtu' in scenario.tags:
            print ("---------------------------")
            print ("deleting veth devices from mtu test")
            call("nmcli connection delete id tc1 tc2", shell=True)
            call("ip link delete test1", shell=True)
            call("ip link delete test2", shell=True)
            call("ip link delete test1", shell=True)
            call("ip link delete test2", shell=True)
            call("ip link set dev vethbr down", shell=True)
            call("brctl delbr vethbr", shell=True)
            call("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')", shell=True)
            call("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')", shell=True)

        if 'inf' in scenario.tags:
            print ("---------------------------")
            print ("deleting infiniband connections")
            call("nmcli connection up id tg3_1", shell=True)
            call("nmcli device connect inf_ib0.8002", shell=True)
            call("nmcli connection delete id inf", shell=True)
            call("nmcli connection delete id inf2", shell=True)

        if 'kill_dnsmasq' in scenario.tags:
            print ("---------------------------")
            print ("kill dnsmasq")
            call("kill $(cat /tmp/dnsmasq.pid)", shell=True)

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

        if 'privacy' in scenario.tags:
            print ("---------------------------")
            print ("setting privacy back to defaults ")
            call("nmcli connection delete id ethie", shell=True)
            call("rm -rf /etc/NetworkManager/conf.d/01-default-ip6-privacy.conf", shell=True)
            call("echo 0 > /proc/sys/net/ipv6/conf/default/use_tempaddr", shell=True)
            call("service NetworkManager restart", shell=True)
            #sleep(TIMER)

        if 'sriov' in scenario.tags:
            print ("---------------------------")
            print ("remove sriov configs")
            # call("sed -i 's/sriov-num-vfs=[0-9]\+/sriov-num-vfs=0/' /etc/NetworkManager/conf.d/99-sriov.conf", shell=True)
            # call("sed -i 's/sriov-num-vfs=[0-9]\+/sriov-num-vfs=0/' /etc/NetworkManager/conf.d/98-sriov.conf", shell=True)
            # call("systemctl restart NetworkManager", shell=True)
            # sleep(5)
            # call("rm -rf /etc/NetworkManager/conf.d/99-sriov.conf", shell=True)
            # call("rm -rf /etc/NetworkManager/conf.d/98-sriov.conf", shell=True)
            # call("systemctl restart NetworkManager", shell=True)
            # sleep(5)
            call("echo 0 > /sys/class/net/p6p1/device/sriov_numvfs", shell=True)
            call("echo 0 > /sys/class/net/p6p2/device/sriov_numvfs", shell=True)
            call("rm -rf /etc/NetworkManager/conf.d/99-sriov.conf", shell=True)
            call("rm -rf /etc/NetworkManager/conf.d/98-sriov.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            sleep(1)

        if 'ipv6' in scenario.tags or 'ipv6_2' in scenario.tags:
            print ("---------------------------")
            print ("deleting connections")
            if 'ipv6_2' in scenario.tags:
                call("nmcli connection delete id ethie2", shell=True)
            call("nmcli connection delete id ethie", shell=True)
            #sleep(TIMER)

        if 'team_slaves' in scenario.tags:
            print ("---------------------------")
            print ("deleting team slaves")
            call('nmcli connection delete id team0.0 team0.1 team-slave-eth2 team-slave-eth1 eth1 eth2', shell=True)
            reset_hwaddr('eth1')
            reset_hwaddr('eth2')
            #sleep(TIMER)

        if 'team' in scenario.tags:
            print ("---------------------------")
            print ("deleting team masters")
            call('nmcli connection delete id team0 team', shell=True)
            call('ip link del nm-team', shell=True)
            #sleep(TIMER)

        if 'teamd' in scenario.tags:
            call("systemctl stop teamd", shell=True)
            call("systemctl reset-failed teamd", shell=True)

        if 'slow_team' in scenario.tags:
            print ("---------------------------")
            print ("restore original team pakages")
            call("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done", shell=True)
            call("yum -y install teamd libteam", shell=True)
            call('systemctl restart NetworkManager.service', shell=True)

        if 'tshark' in scenario.tags:
            print ("---------------------------")
            print ("kill tshark and delet dhclinet-eth10")
            call("pkill -9 tshark", shell=True)
            call("rm -rf /etc/dhcp/dhclient-eth10.conf", shell=True)

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

        if "attach_hostapd_log" in scenario.tags:
            os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ HOSTAPD LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-hostapd.log")
            os.system("sudo journalctl -u nm-hostapd --no-pager -o cat %s >> /tmp/journal-hostapd.log" % context.log_cursor)
            data = open("/tmp/journal-hostapd.log", 'r').read()
            if data:
                context.embed('text/plain', data)

        if "attach_wpa_supplicant_log" in scenario.tags:
            os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ WPA_SUPPLICANT LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-wpa_supplicant.log")
            os.system("journalctl -u wpa_supplicant --no-pager -o cat %s >> /tmp/journal-wpa_supplicant.log" % context.log_cursor)
            data = open("/tmp/journal-wpa_supplicant.log", 'r').read()
            if data:
                context.embed('text/plain', data)

        if 'openvpn' in scenario.tags:
            print ("---------------------------")
            print ("deleting openvpn profile")
            call('nmcli connection delete openvpn', shell=True)
            call("sudo systemctl stop openvpn@trest-server", shell=True)

        if 'libreswan' in scenario.tags:
            print ("---------------------------")
            print ("deleting libreswan profile")
            #call("ip route del default via 172.31.70.1", shell=True)
            call('nmcli connection down libreswan', shell=True)
            call('nmcli connection delete libreswan', shell=True)
            teardown_racoon ()

        if 'pptp' in scenario.tags:
            print ("---------------------------")
            print ("deleting pptp profile")
            call('nmcli connection delete pptp', shell=True)

        if 'ethernet' in scenario.tags:
            print ("---------------------------")
            print ("removing ethernet profiles")
            call("sudo nmcli connection delete id ethernet ethernet0 ethos", shell=True)
            call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ethernet*', shell=True) #ideally should do nothing

        if ('vlan' in scenario.tags) or ('bridge' in scenario.tags):
            print ("---------------------------")
            print ("deleting all possible bridge residues")
            call('sudo nmcli con del vlan eth0.99 eth1.99 eth1.299 eth1.399 eth1.65 eth1.165 eth1.265 eth1.499 eth1.80 eth1.90 bridge-slave-eth1.80', shell=True)
            call('sudo nmcli con del bridge-slave-eth1 bridge-slave-eth2 bridge-slave-eth3', shell=True)
            call('sudo nmcli con del bridge0 bridge bridge.15 nm-bridge br88 br11 br12 br15 bridge-slave br15-slave br15-slave1 br15-slave2 br10 br10-slave', shell=True)
            call("nmcli connection down testeth1", shell=True)
            call('ip link del bridge0', shell=True)
            call('ip link del eth0.99', shell=True)
            call('ip link del eth1.80', shell=True)
            call('ip link del eth1.90', shell=True)
            call('ip link del vlan', shell=True)
            reset_hwaddr('eth1')
            reset_hwaddr('eth2')
            reset_hwaddr('eth3')


        if 'vpn' in scenario.tags:
            print ("---------------------------")
            print ("removing vpn profiles")
            call("nmcli connection delete vpn", shell=True)

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
            call("ip link del br0", shell=True)


        if 'wifi' in scenario.tags:
            print ("---------------------------")
            print ("removing all wifi residues")
            #call('sudo nmcli device disconnect wlan0', shell=True)
            call('sudo nmcli con del qe-open qe-wep qe-wep-psk qe-wep-enterprise qe-wep-enterprise-cisco', shell=True)
            call('sudo nmcli con del qe-wpa1-psk qe-wpa2-psk qe-wpa1-enterprise qe-wpa2-enterprise qe-hidden-wpa2-psk', shell=True)
            call('sudo nmcli con del qe-adhoc qe-ap wifi-wlan0', shell=True)
            if 'nmcli_wifi_add_connection_in_novice_nmcli_a_mode_with_bogus_ip' in scenario.tags:
                context.prompt.close()
                sleep(1)
                call('sudo nmcli con del wifi-wlan0', shell=True)

        if 'nmcli_wifi_ap' in scenario.tags:
            # workaround for bug 1267327, should be removed when fixed
            call("sudo service NetworkManager restart", shell=True)
            sleep(5)
            call("sudo nmcli device wifi rescan", shell=True)
            sleep(10)

        if 'ifcfg-rh' in scenario.tags:
            print ("---------------------------")
            print ("enabling ifcfg-plugin")
            call("sudo sh -c \"echo '[main]\nplugins=ifcfg-rh' > /etc/NetworkManager/NetworkManager.conf\" ", shell=True)

        if 'waitforip' in scenario.tags:
            print ("---------------------------")
            print ("waiting till original IP regained")
            while True:
                sleep(5)
                cfg = pexpect.spawn('ifconfig')
                if cfg.expect(['inet 10', pexpect.EOF]) == 0:
                    break

        if 'remove_dns_none' in scenario.tags:
            if call('grep dns /etc/NetworkManager/NetworkManager.conf', shell=True) == 0:
                call("sudo sed -i 's/dns=none//' /etc/NetworkManager/NetworkManager.conf", shell=True)
            call('sudo service NetworkManager restart', shell=True)
            sleep(5)

        if 'restore_resolvconf' in scenario.tags:
            print ("---------------------------")
            print ("restore /etc/resolv.conf")
            call('rm -rf /etc/resolv.conf', shell=True)
            call('rm -rf /tmp/resolv_orig.conf', shell=True)
            call('rm -rf /tmp/resolv.conf', shell=True)
            call("rm -rf /etc/NetworkManager/conf.d/99-resolv.conf", shell=True)
            call("systemctl restart NetworkManager", shell=True)
            call("nmcli con up testeth0", shell=True)

        if 'need_config_server' in scenario.tags:
            if context.remove_config_server:
                print ("---------------------------")
                print ("removing NetworkManager-config-server")
                call('sudo yum -y remove NetworkManager-config-server', shell=True)
                call('sudo rm -f /etc/NetworkManager/conf.d/00-server.conf', shell=True)

        if 'no_config_server' in scenario.tags:
            if context.restore_config_server:
                print ("---------------------------")
                print ("restoring NetworkManager-config-server")
                wait_for_testeth0()
                call('sudo yum -y install NetworkManager-config-server', shell=True)
                call('sudo cp /usr/lib/NetworkManager/conf.d/00-server.conf /etc/NetworkManager/conf.d/00-server.conf', shell=True)
                call('systemctl restart NetworkManager', shell=True)
                call("for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |awk -F ':' ' {print $2}'); do nmcli con del $i; done", shell=True)
                restore_testeth0()

        if 'openvswitch' in scenario.tags:
            print ("---------------------------")
            print ("remove openvswitch residuals")
            call('sudo ifdown bond0', shell=True)
            call('sudo ifdown eth1', shell=True)
            call('sudo ifdown eth2', shell=True)
            call('sudo ifdown ovsbridge0', shell=True)
            call('ovs-vsctl del-br ovsbr0', shell=True)
            call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-eth1', shell=True)
            call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-bond0', shell=True)
            call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ovsbridge0', shell=True)
            call('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-intbr0', shell=True)
            call('sudo nmcli con del eth1 ovs-bridge0 ovs-port0 ovs-port1 ovs-bond0 ovs-eth2 ovs-eth3 ovs-iface0', shell=True) # to be sure
            call('sudo nmcli con reload', shell=True)

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

        if 'ipv6_describe' in scenario.tags or 'ipv4_describe' in scenario.tags:
            if call("systemctl is-enabled beah-srv.service  |grep ^enabled", shell=True) == 0:
                call('run/rh-beaker/./sanitize_beah.sh', shell=True)

        if 'nmcli_general_correct_profile_activated_after_restart' in scenario.tags:
            print ("---------------------------")
            print ("deleting profiles")
            call('sudo nmcli connection delete aaa bbb eth10', shell=True)

        if 'device_connect_no_profile' in scenario.tags or 'device_connect' in scenario.tags:
            print ("---------------------------")
            print ("env sanitization")
            call('nmcli connection delete testeth2 eth2', shell=True)
            call('nmcli connection add type ethernet ifname eth2 con-name testeth2 autoconnect no', shell=True)

        if 'nmcli_general_ignore_specified_unamanaged_devices' in scenario.tags:
            print ("---------------------------")
            print ("restoring original NetworkManager.conf and deleting bond device")
            call('sudo cp -f /tmp/bckp_nm.conf /etc/NetworkManager/NetworkManager.conf', shell=True)
            call('sudo ip link del dnt', shell=True)
            call('sudo ip link del bond0', shell=True)

        if 'nmcli_general_keep_slave_device_unmanaged' in scenario.tags:
            print ("---------------------------")
            print ("restoring the testeth1 profile to managed state / removing slave")
            call('sudo ip link del eth1.100', shell=True)
            call('sudo rm -f /etc/sysconfig/network-scripts/ifcfg-testeth1', shell=True)
            call('sudo nmcli connection reload', shell=True)
            call('nmcli connection add type ethernet ifname eth1 con-name testeth1 autoconnect no', shell=True)

        if 'nmcli_general_multiword_autocompletion' in scenario.tags:
            print ("---------------------------")
            print ("deleting profile in case of test failure")
            call('nmcli connection delete "Bondy connection 1"', shell=True)

        if 'nmcli_general_dhcp_profiles_general_gateway' in scenario.tags:
            print("---------------------------")
            print("restore /etc/sysconfig/network")
            call('sudo mv -f /tmp/sysnetwork.backup /etc/sysconfig/network', shell=True)
            call('sudo nmcli connection reload', shell=True)
            call('sudo nmcli connection down testeth1', shell=True)
            call('sudo nmcli connection down testeth2', shell=True)
            call('sudo nmcli connection up testeth0', shell=True)

        if 'nmcli_general_profile_pickup_doesnt_break_network' in scenario.tags:
            print("---------------------------")
            print("Restoring configuration, turning off network.service")
            context.nm_restarted = True
            call('sudo nmcli connection delete ethernet0 ethernet1', shell=True)
            call('sudo systemctl stop network.service', shell=True)
            call('sudo systemctl stop NetworkManager.service', shell=True)
            call('sysctl net.ipv6.conf.all.accept_ra=1', shell=True)
            call('sysctl net.ipv6.conf.default.accept_ra=1', shell=True)
            call('sudo systemctl start NetworkManager.service', shell=True)
            call('sudo nmcli connection down testeth1 testeth2', shell=True)
            call('sudo nmcli connection up testeth0', shell=True)

        if 'vlan_update_mac_from_bond' in scenario.tags:
            print("---------------------------")
            print("Restoring configuration, removing all artifacts")
            # in case the test failed during when nm was down
            call('sudo systemctl start NetworkManager.service', shell=True)
            # remove all the setup profiles in correct order
            call('sudo nmcli con del bridge-br0 vlan-vlan10 bond-bond0 bond-slave-eth1 bond-slave-eth2', shell=True)
            reset_hwaddr('eth1')
            reset_hwaddr('eth2')
            sleep(1)
            if not call('ip a s br0 > /dev/null', shell=True):
                call('sudo ip link del br0', shell=True)
            if not call('ip a s bond0 > /dev/null', shell=True):
                call('sudo ip link del bond0', shell=True)
            if not call('ip a s vlan10 > /dev/null', shell=True):
                call('sudo ip link del vlan10', shell=True)

        if 'gsm' in scenario.tags:
            print ("---------------------------")
            print ("remove gsm profile and delete lock and dump logs")
            call('nmcli connection delete gsm', shell=True)
            call('rm -rf /etc/NetworkManager/system-connections/gsm', shell=True)
            call('nmcli con up testeth0', shell=True)
            wait_for_testeth0()
            call('mount -o remount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch', shell=True)
            delete_old_lock("/mnt/scratch/", get_lock("/mnt/scratch"))
            # Attach journalctl logs
            os.system("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ MM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log")
            os.system("sudo journalctl -u ModemManager --no-pager -o cat %s >> /tmp/journal-mm.log" % context.log_cursor)
            data = open("/tmp/journal-mm.log", 'r').read()
            if data:
                context.embed('text/plain', data)


        if 'add_testeth10' in scenario.tags:
            print ("---------------------------")
            print ("restoring testeth10 profile")
            call('sudo nmcli connection delete eth10 testeth10', shell=True)
            call('sudo nmcli connection add type ethernet con-name testeth10 ifname eth10 autoconnect no', shell=True)

        if 'add_testeth1' in scenario.tags:
            print ("---------------------------")
            print ("restoring testeth1 profile")
            call('sudo nmcli connection delete eth1 eth1 eth1', shell=True)
            call('sudo nmcli connection add type ethernet con-name testeth1 ifname eth1 autoconnect no', shell=True)

        if 'eth1_disconnect' in scenario.tags:
            print ("---------------------------")
            print ("disconnecting eth1 device")
            call('sudo nmcli device disconnect eth1', shell=True)
            # VVV Up/Down to preserve autoconnect feature
            call('sudo nmcli connection up testeth1', shell=True)
            call('sudo nmcli connection down testeth1', shell=True)

        if 'manage_eth1' in scenario.tags:
            print ("---------------------------")
            print ("manage eth1 device")
            call('sudo nmcli device set eth1 managed true', shell=True)

        if 'non_utf_device' in scenario.tags:
            print ("---------------------------")
            print ("remove non utf-8 device")
            call("ip link del $'d\xccf\\c'", shell=True)
            call('systemctl restart NetworkManager', shell=True)

        if 'shutdown' in scenario.tags:
            print ("---------------------------")
            print ("sanitizing env")
            call('ip addr  del 192.168.50.5/24 dev eth1', shell=True)
            call('route del default gw 192.168.50.1 eth1', shell=True)

        if 'connect_testeth0' in scenario.tags:
            print ("---------------------------")
            print ("upping testeth0")
            call("nmcli connection up id testeth0", shell=True)
            sleep(2)

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
            call("rm -rf /etc/sysconfig/network-scripts/rule-ethie", shell=True)
            call('rm -rf /etc/sysconfig/network-scripts/route-ethie', shell=True)
            call('ip rule del table 1; ip rule del table 1', shell=True)

        if 'pppoe' in scenario.tags:
            print ("---------------------------")
            print ("kill pppoe server and remove ppp connection")
            call('kill -9 $(pidof pppoe-server)', shell=True)
            call('nmcli con del ppp', shell=True)

        if 'del_test1112_veths' in scenario.tags:
            print ("---------------------------")
            print ("removing test11 device")
            call('ip link del test11', shell=True)

        if 'teardown_testveth' in scenario.tags:
            print("---------------------------")
            print("removing testveth device setup for all test devices")
            if hasattr(context, 'testvethns'):
                for ns in context.testvethns:
                    print("Removing the setup in %s namespace" % ns)
                    call('[ -f /tmp/%s.pid ] && ip netns exec %s kill -SIGCONT $(cat /tmp/%s.pid)' % (ns, ns, ns), shell=True)
                    call('[ -f /tmp/%s.pid ] && kill $(cat /tmp/%s.pid)' % (ns, ns) , shell=True)
                    call('ip netns del %s' % ns, shell=True)
                    call('ip link del %s' % ns.split('_')[0], shell=True)
            call('rm -f /etc/udev/rules.d/88-lr.rules', shell=True)
            call('udevadm control --reload-rules', shell=True)
            call('udevadm settle', shell=True)
            sleep(1)
            call('systemctl restart NetworkManager', shell=True)


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

        if 'regenerate_veth' in scenario.tags or 'restart' in scenario.tags:
            print ("---------------------------")
            print ("regenerate veth setup")
            if os.path.isfile('/tmp/nm_newveth_configured'):
                call('sh prepare/vethsetup.sh check', shell=True)
            else:
                for link in range(1,10):
                    call('ip link set eth%d up' % link, shell=True)

        if nm_pid_after is not None and context.nm_pid == nm_pid_after:
            context.log.write("NetworkManager memory consumption after: %d KiB\n" % nm_size_kb())
            if call("[ -f /etc/systemd/system/NetworkManager.service ] && grep -q valgrind /etc/systemd/system/NetworkManager.service", shell=True) == 0:
                sleep(3) # Wait for dispatcher to finish its business
                call("LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager -ex 'target remote | vgdb' -ex 'monitor leak_check full kinds all increased' -batch", shell=True, stdout=context.log, stderr=context.log)

        context.log.close ()
        context.embed('text/plain', open("/tmp/log_%s.html" % scenario.name, 'r').read())

        if getattr(context, 'nm_restarted', True) or \
               'restart' in scenario.tags:
               pass
        else:
            if nm_pid_after is None or nm_pid_after != context.nm_pid:
                sys.exit(1)

        #
        # assert nm_pid_after is not None or \
        #        'restart' in scenario.tags
        # assert context.nm_pid is not None
        # assert getattr(context, 'nm_restarted', False) or \
        #        'restart' in scenario.tags or \
        #        nm_pid_after == context.nm_pid

    except Exception as e:
        print("Error in after_scenario: %s" % e.message)
        traceback.print_exc(file=sys.stdout)


def after_all(context):
    pass
    #call('sudo kill $(ps aux|grep -v grep| grep /usr/bin/beah-beaker-backend |awk \'{print $2}\')', shell=True)
    #Popen('beah-beaker-backend -H $(hostname) &', shell=True)
