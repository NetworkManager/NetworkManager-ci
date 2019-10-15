# -*- coding: UTF-8 -*-

from __future__ import absolute_import, division, print_function, unicode_literals
import os
import sys
if sys.version_info < (3, 0):
    reload(sys)
    sys.setdefaultencoding('utf8')

import traceback
from time import sleep, localtime, strftime
from subprocess import call, check_output

IS_NMTUI = True

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

def restore_testeth0_nmtui():
    print ("* restoring testeth0")
    call("nmcli con delete testeth0 2>&1 > /dev/null", shell=True)
    call("yes 2>/dev/null | cp -rf /tmp/testeth0 /etc/sysconfig/network-scripts/ifcfg-testeth0", shell=True)
    sleep(1)
    call("nmcli con reload", shell=True)
    sleep(1)
    call("nmcli con up testeth0", shell=True)
    sleep(2)

def wait_for_testeth0_nmtui():
    print ("* waiting for testeth0 to connect")
    if call("nmcli connection show testeth0 > /dev/null", shell=True)!= 0:
        restore_testeth0_nmtui()
    if call("nmcli con show testeth0 |grep -q IP4.ADDRESS", shell=True) != 0:
        call("nmcli con up testeth0", shell=True)
    counter=40
    while call("nmcli connection show testeth0 |grep IP4.ADDRESS > /dev/null", shell=True) != 0:
        sleep(1)
        counter-=1
        if counter == 20:
            restore_testeth0_nmtui()
        if counter == 0:
            print ("Testeth0 cannot be upped..this is wrong")
            sys.exit(1)

def reload_NM_service():
    sleep(0.5)
    call("pkill -HUP NetworkManager", shell=True)
    sleep(1)

def before_all(context):
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

def reset_hwaddr_nmtui(ifname):
    hwaddr = check_output("ethtool -P %s" % ifname, shell=True).decode('utf-8', 'ignore').split()[2]
    call("ip link set %s address %s" % (ifname, hwaddr), shell=True)

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

def after_step(context, step):
    if IS_NMTUI:
        """Teardown after each step.
        Here we make screenshot and embed it (if one of formatters supports it)
        """
        try:
            if os.path.isfile('/tmp/nmtui.out'):
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
                data = open("/tmp/journal-session.log", 'r').read()
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
                    wait_for_testeth0_nmtui()
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
                wait_for_testeth0_nmtui()

        except Exception:
            # Stupid behave simply crashes in case exception has occurred
            print("Error in after_scenario:")
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
