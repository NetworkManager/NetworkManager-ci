# before/after scenario for tags
import os
import sys
import nmci
import subprocess
import time
import re
import inspect

import nmci.lib


class Tag:
    def __init__(self, tag_name, before_scenario=None, after_scenario=None):
        stack = inspect.stack()
        self.lineno = stack[2].lineno
        self.tag_name = tag_name
        self.before_scenario = before_scenario
        self.after_scenario = after_scenario


tag_registry = {}


def _register_tag(tag_name, before_scenario=None, after_scenario=None):
    assert tag_name not in tag_registry, \
        "multiple definitions for tag '@%s'" % tag_name
    tag_registry[tag_name] = Tag(tag_name, before_scenario, after_scenario)


# tags that have efect outside this file
_register_tag("no_abrt")
_register_tag("xfail")
_register_tag("may_fail")
_register_tag("nmtui")


def temporary_skip_bs(ctx, scen):
    sys.exit(77)


_register_tag("temporary_skip", temporary_skip_bs)


def skip_restarts_bs(ctx, scen):
    if os.path.isfile('/tmp/nm_skip_restarts') or os.path.isfile('/tmp/nm_skip_STR'):
        print("skipping service restart tests as /tmp/nm_skip_restarts exists")
        sys.exit(77)


_register_tag("skip_str", skip_restarts_bs)


def long_bs(ctx, scen):
    if os.path.isfile('/tmp/nm_skip_long'):
        print("skipping long test case as /tmp/nm_skip_long exists")
        sys.exit(77)


_register_tag("long", long_bs)


def skip_in_centos_bs(ctx, scen):
    if 'CentOS' in ctx.rh_release:
        print("skipping with centos")
        sys.exit(77)


_register_tag("skip_in_centos", skip_in_centos_bs)


def arch_only_bs(arch):
    def arch_check(ctx, scen):
        if ctx.arch != arch:
            sys.exit(77)
    return arch_check


def not_on_arch_bs(arch):
    def arch_check(ctx, scen):
        if ctx.arch == arch:
            sys.exit(77)
    return arch_check


for arch in ["x86_64", "s390x", "ppc64", "ppc64le", "aarch64"]:
    _register_tag("not_on_" + arch, not_on_arch_bs(arch))
    _register_tag(arch + "_only", arch_only_bs(arch))


def not_on_aarch64_but_pegas_bs(ctx, scen):
    ver = ctx.command_output("uname -r").strip()
    if ctx.arch == "aarch64":
        if "4.5" in ver:
            sys.exit(77)


_register_tag("not_on_aarch64_but_pegas", not_on_aarch64_but_pegas_bs)


def gsm_sim_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping on not intel arch")
        sys.exit(77)
    # script hangs if output is redirected, however script should not output anything
    ctx.run("sudo prepare/gsm_sim.sh modemu", stdout=None, stderr=None)


def gsm_sim_as(ctx, scen):
    ctx.run("nmcli con down id gsm")
    time.sleep(2)
    ctx.run("sudo prepare/gsm_sim.sh teardown")
    time.sleep(1)
    ctx.run("nmcli con del id gsm")
    ctx.embed("text/plain", nmci.lib.utf_only_open_read("/tmp/gsm_sim.log"), "GSM_SIM")
    os.remove("/tmp/gsm_sim.log")


_register_tag("gsm_sim", gsm_sim_bs, gsm_sim_as)


def crash_bs(ctx, scen):
    # backup NM binary (if not done already)
    if not os.path.isfile("/tmp/NetworkManager"):
        ctx.run("cp /sbin/NetworkManager /tmp/NetworkManager")
    # compile crashing binary
    src = "contrib/crash/crash.c"
    assert ctx.command_code(f"gcc -o /tmp/crash {src}") == 0, \
        f"Unable to compile crashing binary {src}"


def crash_as(ctx, scen):
    # copy NM binary back
    ctx.run("cp /tmp/NetworkManager /sbin/NetworkManager")
    ctx.run("systemctl restart NetworkManager")


_register_tag("crash", crash_bs, crash_as)


def not_with_systemd_resolved_bs(ctx, scen):
    if ctx.command_code("systemctl is-active systemd-resolved") == 0:
        print("Skipping as systemd-resolved is running")
        sys.exit(77)


_register_tag("not_with_systemd_resolved", not_with_systemd_resolved_bs)


def not_under_internal_DHCP_bs(ctx, scen):
    if "release 8" in ctx.rh_release and \
       ctx.command_code("NetworkManager --print-config|grep dhclient") != 0:
        sys.exit(77)
    if ctx.command_code("NetworkManager --print-config|grep internal") == 0:
        sys.exit(77)


_register_tag("not_under_internal_DHCP", not_under_internal_DHCP_bs)


def newveth_bs(ctx, scen):
    if os.path.isfile('/tmp/nm_newveth_configured'):
        sys.exit(77)


_register_tag("newveth", newveth_bs)
_register_tag("veth", newveth_bs)
_register_tag("not_on_veth", newveth_bs)


def regenerate_veth_as(ctx, scen):
    if os.path.isfile('/tmp/nm_newveth_configured'):
        print("regenerate veth setup")
        ctx.run('sh prepare/vethsetup.sh check')
    else:
        print("up eth1-11 links")
        for link in range(1, 11):
            ctx.run('ip link set eth%d up' % link)


_register_tag("regenerate_veth", None, regenerate_veth_as)


def logging_info_only_bs(ctx, scen):
    log = "/etc/NetworkManager/conf.d/99-xlogging.conf"
    ctx.run("echo '[logging]' > %s" % log)
    ctx.run("echo 'level=INFO' >> %s" % log)
    ctx.run("echo 'domains=ALL' >> %s" % log)
    time.sleep(0.5)
    nmci.lib.restart_NM_service(ctx)
    time.sleep(1)


def logging_info_only_as(ctx, scen):
    log = "/etc/NetworkManager/conf.d/99-xlogging.conf"
    ctx.run("rm -rf %s" % log)
    nmci.lib.restart_NM_service(ctx)
    time.sleep(1)


_register_tag("logging_info_only", logging_info_only_bs, logging_info_only_as)


def restart_if_needed_as(ctx, scen):
    if ctx.command_code("systemctl is-active NetworkManager") != 0:
        nmci.lib.restart_NM_service(ctx)
    if not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
        nmci.lib.wait_for_testeth0(ctx)


_register_tag("restart_if_needed", None, restart_if_needed_as)


def secret_key_reset_bs(ctx, scen):
    ctx.run("mv /var/lib/NetworkManager/secret_key /var/lib/NetworkManager/secret_key_back")


def secret_key_reset_as(ctx, scen):
    ctx.run("mv /var/lib/NetworkManager/secret_key_back /var/lib/NetworkManager/secret_key")


_register_tag("secret_key_reset", secret_key_reset_bs, secret_key_reset_as)


def tag1000_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("python -m pip install pyroute2 mitogen") != 0:
        print("installing pip and pyroute2")
        ctx.run("yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python2-pyroute2-0.4.13-1.el7.noarch.rpm")


def tag1000_as(ctx, scen):
    ctx.run("ip link del bridge0")
    ctx.run("for i in $(seq 0 1000); do ip link del port$i ; done")


_register_tag("1000", tag1000_bs, tag1000_as)


def tag500_vlans_bs(ctx, scen):
    nmci.lib.manage_veths(ctx)
    ctx.run("sh prepare/vlans.sh clean")
    # We need NM to sanitize itself a bit
    time.sleep(20)


def tag500_vlans_as(ctx, scen):
    ctx.run("sh prepare/vlans.sh clean")
    nmci.lib.unmanage_veths(ctx)


_register_tag("500_vlans", tag500_vlans_bs, tag500_vlans_as)


def captive_portal_bs(ctx, scen):
    # do not capture output, let it log to the console, otherwise this hangs!
    ctx.run("sudo prepare/captive_portal.sh", stdout=None, stderr=None)


def captive_portal_as(ctx, scen):
    ctx.run("sudo prepare/captive_portal.sh teardown")


_register_tag("captive_portal", captive_portal_bs, captive_portal_as)


def gsm_bs(ctx, scen):
    ctx.run("mmcli -G debug")
    ctx.run("nmcli general logging level DEBUG domains ALL")
    # Extract modem's identification and keep it in a global variable for further use.
    # Only 1 modem is expected per test.
    ctx.modem_str = nmci.lib.find_modem(ctx)
    ctx.set_title(" - " + ctx.modem_str, append=True)

    if not os.path.isfile('/tmp/usb_hub'):
        import time
        dir = "/mnt/scratch/"
        timeout = 3600
        initialized = False
        freq = 30

        while(True):
            print("* looking for gsm lock in nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock")
            lock = nmci.lib.get_lock(dir)
            if not lock:
                if not initialized:
                    initialized = nmci.lib.reinitialize_devices()
                if nmci.lib.create_lock(dir):
                    break
                else:
                    continue
            if lock:
                if nmci.lib.is_lock_old(lock):
                    nmci.lib.delete_old_lock(dir, lock)
                    continue
                else:
                    timeout -= freq
                    print(" ** still locked.. wating %s seconds before next try" % freq)
                    if not initialized:
                        initialized = nmci.lib.reinitialize_devices()
                    time.sleep(freq)
                    if timeout == 0:
                        raise Exception("Timeout reached!")
                    continue

    ctx.run('nmcli con down testeth0')

def gsm_as(ctx, scen):
    # You can debug here only with console connection to the testing machine.
    # SSH connection is interrupted.
    # import ipdb

    ctx.run('nmcli connection delete gsm')
    ctx.run('rm -rf /etc/NetworkManager/system-connections/gsm')
    ctx.run('nmcli con up testeth0')
    nmci.lib.wait_for_testeth0(ctx)
    if not os.path.isfile('/tmp/usb_hub'):
        ctx.run('mount -o remount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch')
        nmci.lib.delete_old_lock("/mnt/scratch/", nmci.lib.get_lock("/mnt/scratch"))
    # Attach journalctl logs
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ MM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log")
    ctx.run("sudo journalctl -u ModemManager --no-pager -o cat %s >> /tmp/journal-mm.log" % ctx.log_cursor)
    data = nmci.lib.utf_only_open_read("/tmp/journal-mm.log")
    if data:
        print("embed ModemManager log")
        ctx.embed('text/plain', data, caption="MM")
    # Extract modem model.
    # Example: 'USB ID 1c9e:9603 Zoom 4595' -> 'Zoom 4595'
    regex = r'USB ID (\w{4}:\w{4}) (.*)'
    mo = re.search(regex, ctx.modem_str)
    if mo:
        modem_model = mo.groups()[1]
        cap = modem_model
    else:
        cap = 'MODEM INFO'

    modem_info = nmci.lib.get_modem_info(ctx)
    if modem_info:
        print("embed modem_info")
        ctx.embed('text/plain', modem_info, caption=cap)


_register_tag("gsm", gsm_bs, gsm_as)


def unmanage_eth_bs(ctx, scen):
    links = nmci.lib.get_ethernet_devices(ctx)
    for link in links:
        ctx.run('nmcli dev set %s managed no' % link)


def unmanage_eth_as(ctx, scen):
    links = nmci.lib.get_ethernet_devices(ctx)
    for link in links:
        ctx.run('nmcli dev set %s managed yes' % link)


_register_tag("unmanage_eth", unmanage_eth_bs, unmanage_eth_as)


def manage_eth8_as(ctx, scen):
    ctx.run('sudo nmcli device set eth8 managed true')


_register_tag("manage_eth8", None, manage_eth8_as)


def connectivity_bs(ctx, scen):
    ctx.run("echo '[connectivity]' > /etc/NetworkManager/conf.d/99-connectivity.conf")
    if 'captive_portal' in scen.tags:
        ctx.run("echo 'uri=http://static.redhat.com:8001/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    else:
        ctx.run("echo 'uri=http://static.redhat.com/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    ctx.run("echo 'response=OK' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    # Change in interval  would affect connectivity tests and captive portal tests too
    ctx.run("echo 'interval=10' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    nmci.lib.reload_NM_service(ctx)


def connectivity_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-connectivity.conf")
    ctx.run("rm -rf /var/lib/NetworkManager/NetworkManager-intern.conf")
    ctx.execute_steps(u'* Reset /etc/hosts')

    nmci.lib.reload_NM_service(ctx)


_register_tag("connectivity", connectivity_bs, connectivity_as)


def unload_kernel_modules_bs(ctx, scen):
    ctx.run("modprobe -r qmi_wwan")
    ctx.run("modprobe -r cdc-mbim")


_register_tag("unload_kernel_modules", unload_kernel_modules_bs)


def disp_bs(ctx, scen):
    ctx.run("> /tmp/dispatcher.txt")


def disp_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/dispatcher.d/*-disp")
    ctx.run("rm -rf /usr/lib/NetworkManager/dispatcher.d/*-disp")
    ctx.run("rm -rf /etc/NetworkManager/dispatcher.d/pre-up.d/98-disp")
    ctx.run("rm -rf /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp")
    #ctx.run("rm -rf /tmp/dispatcher.txt")
    ctx.run('nmcli con down testeth1')
    ctx.run('nmcli con down testeth2')
    nmci.lib.reload_NM_service(ctx)


_register_tag("disp", disp_bs, disp_as)


def eth0_bs(ctx, scen):
    skip_restarts_bs(ctx, scen)
    #if ctx.IS_NMTUI:
    #    ctx.run("nmcli connection down id testeth0")
    #    time.sleep(1)
    #    if ctx.command_code("nmcli -f NAME c sh -a |grep eth0") == 0:
    #        print("shutting down eth0 once more as it is not down")
    #        ctx.run("nmcli device disconnect eth0")
    #        time.sleep(2)
    ctx.run("nmcli con down testeth0")
    ctx.run('nmcli con down testeth1')
    ctx.run('nmcli con down testeth2')


def eth0_as(ctx, scen):
#    if not ctx.IS_NMTUI:
#        if 'restore_hostname' in scen.tags:
#            ctx.run('hostnamectl set-hostname --transien ""')
#            ctx.run('hostnamectl set-hostname --static %s' % ctx.original_hostname)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("eth0", eth0_bs, eth0_as)


def alias_bs(ctx, scen):
    ctx.run("nmcli connection up testeth7")
    ctx.run("nmcli connection delete eth7")


def alias_as(ctx, scen):
    ctx.run("nmcli connection delete eth7")
    ctx.run("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:0")
    ctx.run("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:1")
    ctx.run("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:2")
    ctx.run("sudo nmcli connection reload")
    ctx.run("nmcli connection down testeth7")
    #ctx.run('sudo nmcli con add type ethernet ifname eth7 con-name testeth7 autoconnect no')
    #sleep(TIMER)


_register_tag("alias", alias_bs, alias_as)


def netcat_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if not os.path.isfile('/usr/bin/nc'):
        print("installing netcat")
        ctx.run('sudo yum -y install nmap-ncat')


_register_tag("netcat", netcat_bs)


def scapy_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if not os.path.isfile('/usr/bin/scapy'):
        print("installing scapy and tcpdump")
        ctx.run('yum -y install tcpdump')
        ctx.run("python -m pip install scapy")


def scapy_as(ctx, scen):
    ctx.run("ip link delete test10")
    ctx.run("ip link delete test11")
    ctx.run("nmcli connection delete ethernet-test10 ethernet-test11")


_register_tag("scapy", scapy_bs, scapy_as)


def mock_bs(ctx, scen):
    if ctx.command_code('rpm -q --quiet dbus-x11') != 0:
        print("installing dbus-x11, pip, and python-dbusmock dataclasses")
        ctx.run('yum -y install dbus-x11')
    ctx.run("sudo python3 -m pip install python-dbusmock dataclasses")
    ctx.run('./tmp/patch-python-dbusmock.sh')


_register_tag("mock", mock_bs)


def IPy_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code('rpm -q --quiet dbus-x11') != 0:
        print("installing dbus-x11")
        ctx.run('yum -y install dbus-x11')
    if ctx.command_code('python -m pip list |grep IPy') != 0:
        print("installing IPy")
        ctx.run("sudo python -m pip install IPy")


_register_tag("IPy", IPy_bs)


def netaddr_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code('python -m pip list |grep netaddr') != 0:
        print("install netaddr")
        ctx.run("sudo python -m pip install netaddr")


_register_tag("netaddr", netaddr_bs)


def inf_bs(ctx, scen):
    ctx.run("nmcli device disconnect inf_ib0")
    ctx.run("nmcli device disconnect inf_ib0.8002")
    ctx.run("nmcli connection delete inf_ib0.8002")
    ctx.run("nmcli connection delete id infiniband-inf_ib0.8002 inf.8002 inf inf2 infiniband-inf_ib0 infiniband")


def inf_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id infiniband0 infiniband0-port")
    else:
        ctx.run("nmcli connection up id tg3_1")
        ctx.run("nmcli connection delete id inf inf2 infiniband inf.8002")
        ctx.run("nmcli device connect inf_ib0.8002")


_register_tag("inf", inf_bs, inf_as)


def dsl_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id dsl0")


_register_tag("dsl", None, dsl_as)


def dns_dnsmasq_bs(ctx, scen):
    if ctx.command_code("systemctl is-active systemd-resolved") == 0:
        print("stopping systemd-resolved")
        ctx.systemd_resolved = True
        ctx.run("systemctl stop systemd-resolved")
        ctx.run("rm -rf /etc/resolv.conf")
    else:
        ctx.systemd_resolved = False
    ctx.run("printf '# configured by beaker-test\n[main]\ndns=dnsmasq\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin = "dnsmasq"


def dns_dnsmasq_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dns.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin=""
    if ctx.systemd_resolved == True:
        print("starting systemd-resolved")
        ctx.run("systemctl restart systemd-resolved")


_register_tag("dns_dnsmasq", dns_dnsmasq_bs, dns_dnsmasq_as)


def dns_systemd_resolved_bs(ctx, scen):
    ctx.systemd_resolved = True
    if ctx.command_code("systemctl is-active systemd-resolved") != 0:
        ctx.systemd_resolved = False
        print("start systemd-resolved as it is OFF and requried")
        ctx.run("timeout 60 systemctl start systemd-resolved")
        if ctx.command_code("systemctl is-active systemd-resolved") != 0:
            print("ERROR: Cannot start systemd-resolved")
            sys.exit(77)
    ctx.run("printf '# configured by beaker-test\n[main]\ndns=systemd-resolved\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin = "systemd-resolved"


def dns_systemd_resolved_as(ctx, scen):
    if not ctx.systemd_resolved:
        print("stop systemd-resolved")
        ctx.run("systemctl stop systemd-resolved")
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dns.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin = ""


_register_tag("dns_systemd_resolved", dns_systemd_resolved_bs, dns_systemd_resolved_as)


def internal_DHCP_bs(ctx, scen):
    ctx.run("printf '# configured by beaker-test\n[main]\ndhcp=internal\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf")
    nmci.lib.restart_NM_service(ctx)


def internal_DHCP_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf")
    nmci.lib.restart_NM_service(ctx)


_register_tag("internal_DHCP", internal_DHCP_bs, internal_DHCP_as)


def dhclient_DHCP_bs(ctx, scen):
    ctx.run("printf '# configured by beaker-test\n[main]\ndhcp=dhclient\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf")
    nmci.lib.restart_NM_service(ctx)


def dhclient_DHCP_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf")
    nmci.lib.restart_NM_service(ctx)


_register_tag("dhclient_DHCP", dhclient_DHCP_bs, dhclient_DHCP_as)


def dummy_as(ctx, scen):
    ctx.run("nmcli con del dummy0 dummy1")
    ctx.run("ip link delete dummy0")
    ctx.run("ip link del br0")
    ctx.run("ip link del vlan")
    ctx.run("ip link del bond0")
    ctx.run("ip link del team0")


_register_tag("dummy", None, dummy_as)


def delete_testeth0_bs(ctx, scen):
    skip_restarts_bs(ctx, scen)
    ctx.run("nmcli device disconnect eth0")
    ctx.run("nmcli connection delete id testeth0")


def delete_testeth0_as(ctx, scen):
    ctx.run('sudo nmcli connection delete eth0')
    nmci.lib.restore_testeth0(ctx)


_register_tag("delete_testeth0", delete_testeth0_bs, delete_testeth0_as)


def ethernet_bs(ctx, scen):
    if ctx.command_code('nmcli con |grep testeth1') == 0 or ctx.run('nmcli con |grep testeth2') == 0:
        print("sanitizing eth1 and eth2")
        ctx.run('sudo nmcli con del testeth1 testeth2')
        ctx.run('sudo nmcli con add type ethernet ifname eth1 con-name testeth1 autoconnect no')
        ctx.run('sudo nmcli con add type ethernet ifname eth2 con-name testeth2 autoconnect no')


def ethernet_as(ctx, scen):
    ctx.run("sudo nmcli connection delete id eth1 eth2 ethernet ethernet1 ethernet2")

    if 'ipv4' not in scen.tags and 'ipv6' not in scen.tags:
        print("removing ethernet profiles")
        ctx.run("sudo nmcli connection delete id ethernet ethernet0 ethos")
        ctx.run('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ethernet*') #ideally should do nothing

    time.sleep(0.2)


_register_tag("ethernet", ethernet_bs, ethernet_as)
_register_tag("ipv4", None, ethernet_as)
_register_tag("ipv6", None, ethernet_as)


def ifcfg_rh_bs(ctx, scen):
    if ctx.command_code("NetworkManager --print-config |grep '^plugins=ifcfg-rh'") != 0:
        print("setting ifcfg-rh plugin")
        # VV Do not lower this as some devices can be still going down
        time.sleep(0.5)
        ctx.run("printf '# configured by beaker-test\n[main]\nplugins=ifcfg-rh\n' > /etc/NetworkManager/conf.d/99-xxcustom.conf")
        nmci.lib.restart_NM_service(ctx)
        if ctx.IS_NMTUI:
            # comment out wifi_rescan, as simwifi prepare not done yet
            # if "simwifi" in scen.tags:
            #     nmci.lib.wifi_rescan()
            # VV Do not lower this as nmtui can be behaving weirdly
            time.sleep(4)
        time.sleep(0.5)


def ifcfg_rh_as(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-xxcustom.conf"):
        print("resetting ifcfg plugin")
        ctx.run('sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf')
        nmci.lib.restart_NM_service(ctx)
        if ctx.IS_NMTUI:
            # if 'simwifi' in scen.tags:
            #     nmci.lib.wifi_rescan()
            time.sleep(4)
        time.sleep(0.5)


_register_tag("ifcfg-rh", ifcfg_rh_bs, ifcfg_rh_as)


def plugin_default_bs(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-test.conf"):
        print("remove 'plugins=*' from 99-test.conf")
        assert ctx.command_code("cp /etc/NetworkManager/conf.d/99-test.conf /tmp/99-test.conf") == 0, \
            "unable to backup 99-test.conf"
        assert ctx.command_code("sed -i 's/^plugins=/#plugins=/' /etc/NetworkManager/conf.d/99-test.conf") == 0, \
            "unable to modify '99-test.conf'"
        nmci.lib.restart_NM_service(ctx)


def plugin_default_as(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-test.conf"):
        print("restore 99-test.conf")
        assert ctx.command_code("mv /tmp/99-test.conf /etc/NetworkManager/conf.d/99-test.conf") == 0, \
            "unable to restore '99-test.conf'"
        nmci.lib.restart_NM_service(ctx)


_register_tag("plugin_default", plugin_default_bs, plugin_default_as)


def eth3_disconnect_bs(ctx, scen):
    ctx.run('sudo nmcli device disconnect eth3')
    ctx.run('sudo kill -9 $(cat /var/run/dhclient-eth3.pid)')


def eth3_disconnect_as(ctx, scen):
    ctx.run('sudo nmcli device disconnect eth3')
    # VVV Up/Down to preserve autoconnect feature
    ctx.run('sudo nmcli connection up testeth3')
    ctx.run('sudo nmcli connection down testeth3')


_register_tag("eth3_disconnect", eth3_disconnect_bs, eth3_disconnect_as)


def need_dispatcher_scripts_bs(ctx, scen):
    if os.path.isfile("/tmp/nm-builddir"):
        print("install dispatcher scripts")
        ctx.run('yum install -y $(cat /tmp/nm-builddir)/noarch/NetworkManager-dispatcher-routing-rules*')
    else:
        nmci.lib.wait_for_testeth0(ctx)
        print("install NetworkManager-config-routing-rules")
        ctx.run("yum -y install NetworkManager-config-routing-rules")
    nmci.lib.reload_NM_service(ctx)


def need_dispatcher_scripts_as(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    ctx.run("yum -y remove NetworkManager-config-routing-rules ")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/rule-con_general")
    ctx.run('rm -rf /etc/sysconfig/network-scripts/route-con_general')
    ctx.run('ip rule del table 1; ip rule del table 1')
    nmci.lib.reload_NM_service(ctx)


_register_tag("need_dispatcher_scripts", need_dispatcher_scripts_bs, need_dispatcher_scripts_as)


def logging_bs(ctx, scen):
    ctx.loggin_level = ctx.command_output('nmcli -t -f LEVEL general logging').strip()


def logging_as(ctx, scen):
    print("---------------------------")
    print("setting log level back")
    ctx.run('sudo nmcli g log level %s domains ALL' % ctx.loggin_level)


_register_tag("logging", logging_bs, logging_as)



def remove_custom_cfg_as(ctx, scen):
    ctx.run('sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf')
    nmci.lib.restart_NM_service(ctx)


_register_tag("remove_custom_cfg", None, remove_custom_cfg_as)


def netservice_bs(ctx, scen):
    ctx.run("sudo pkill -9 /sbin/dhclient")
    # Make orig- devices unmanaged as they may be unfunctional
    ctx.run("for dev in $(nmcli  -g DEVICE d |grep orig); do nmcli device set $dev managed off; done")
    nmci.lib.restart_NM_service(ctx)
    ctx.run("sudo systemctl restart network.service")
    ctx.run("nmcli connection up testeth0")
    time.sleep(1)


def netservice_as(ctx, scen):
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NETWORK SRV LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-netsrv.log")
    ctx.run("sudo journalctl -u network --no-pager -o cat %s >> /tmp/journal-netsrv.log" % ctx.log_cursor)

    data = nmci.lib.utf_only_open_read("/tmp/journal-netsrv.log")
    if data:
        print("Attaching network.service log")
        ctx.embed('text/plain', data, caption="NETSRV")


_register_tag("netservice", netservice_bs, netservice_as)


def tag8021x_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("install hostapd.el7 on s390x")
        ctx.run("[ -x /usr/sbin/hostapd ] || (yum -y install 'https://vbenes.fedorapeople.org/NM/hostapd-2.6-7.el7.s390x.rpm'; time.sleep 10)")
    nmci.lib.setup_hostapd(ctx)


def tag8021x_as(ctx, scen):
    nmci.lib.teardown_hostapd(ctx)


_register_tag("8021x", tag8021x_bs, tag8021x_as)


def simwifi_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)
    nmci.lib.setup_hostapd_wireless(ctx)


def simwifi_as(ctx, scen):
    if ctx.IS_NMTUI:
        print("deleting all wifi connections")
        ctx.run("nmcli con del uuid $(nmcli -t -f uuid,type con show | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//g' )")


_register_tag("simwifi", simwifi_bs, simwifi_as)


def simwifi_ap_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)
    ctx.run("modprobe -r mac80211_hwsim")
    ctx.run("modprobe mac80211_hwsim")
    ctx.run("systemctl restart wpa_supplicant")
    ctx.run("systemctl restart NetworkManager")


def simwifi_ap_as(ctx, scen):
    ctx.run("nmcli con del wifi-ap wifi-client br0 br0-slave1 br0-slave2")
    ctx.run("ip link delete br0")
    ctx.run("modprobe -r mac80211_hwsim")
    ctx.run("systemctl restart wpa_supplicant")
    ctx.run("systemctl restart NetworkManager")


_register_tag("simwifi_ap", simwifi_ap_bs, simwifi_ap_as)


def simwifi_p2p_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)

    if "release 8" in ctx.rh_release:
        ctx.run("dnf -4 -y install "
             "https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.7-2.2.bz1693684.el8.x86_64.rpm "
             "https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.7-2.2.bz1693684.el8.x86_64.rpm ")
        ctx.run("systemctl restart wpa_supplicant")

    if ctx.command_code("ls /tmp/nm_*_supp_configured") == 0:
        print(" ** need to remove previous setup")
        nmci.lib.teardown_hostapd_wireless(ctx)

    ctx.run('modprobe -r mac80211_hwsim')
    time.sleep(1)

    # This should be good as dynamic addresses are now used
    #ctx.run("echo -e '[device-wifi]\nwifi.scan-rand-mac-address=no' > /etc/NetworkManager/conf.d/99-wifi.conf")
    #ctx.run("echo -e '[connection-wifi]\nwifi.cloned-mac-address=preserve' >> /etc/NetworkManager/conf.d/99-wifi.conf")

    # This is workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1752780
    ctx.run("echo -e '[keyfile]\nunmanaged-devices=wlan1\n' > /etc/NetworkManager/conf.d/99-wifi.conf")
    nmci.lib.restart_NM_service(ctx)

    ctx.run('modprobe mac80211_hwsim')
    time.sleep(3)


def simwifi_p2p_as(ctx, scen):
    print("---------------------------")
    if "release 8" in ctx.rh_release:
        if ctx.arch == "x86_64":
            print("Install patched wpa_supplicant for x86_64")
            ctx.run("dnf -4 -y install https://vbenes.fedorapeople.org/NM/WPA3/wpa_supplicant{,-debuginfo,-debugsource}-2.9-8.el8.$(arch).rpm")
        else:
            print("Install patched wpa_supplicant")
            ctx.run("dnf -4 -y install https://vbenes.fedorapeople.org/NM/rhbz1888051/wpa_supplicant{,-debuginfo,-debugsource}-2.9-3.el8.$(arch).rpm")
        ctx.run("dnf -y update wpa_supplicant")
        ctx.run("systemctl restart wpa_supplicant")
    ctx.run('modprobe -r mac80211_hwsim')
    ctx.run('nmcli con del wifi-p2p')
    ctx.run("kill -9 $(ps aux|grep wpa_suppli |grep wlan1 |awk '{print $2}')")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-wifi.conf")

    nmci.lib.restart_NM_service(ctx)


_register_tag("simwifi_p2p", simwifi_p2p_bs, simwifi_p2p_as)


def simwifi_wpa2_as(ctx, scen):
    ctx.run("nmcli con del wpa2-eap wifi")


_register_tag("simwifi_wpa2", None, simwifi_wpa2_as)


def simwifi_wpa3_eap_bs(ctx, scen):
    if ctx.command_code("nmcli device wifi list --rescan auto |grep -q wpa3-eap") != 0:
        print("No wpa3 eap, skipping")
        sys.exit(77)


_register_tag("simwifi_wpa3_eap", simwifi_wpa3_eap_bs, None)


def simwifi_wpa3_as(ctx, scen):
    ctx.run("nmcli con del wpa3-psk wpa3-eap wifi")


_register_tag("simwifi_wpa3", None, simwifi_wpa3_as)


def simwifi_open_as(ctx, scen):
    ctx.run("nmcli con del open")


_register_tag("simwifi_open", None, simwifi_open_as)


def simwifi_pskwep_as(ctx, scen):
    ctx.run("nmcli con del wep")


_register_tag("simwifi_pskwep", None, simwifi_pskwep_as)


def simwifi_dynwep_as(ctx, scen):
    ctx.run("nmcli con del wifi")


_register_tag("simwifi_dynwep", None, simwifi_dynwep_as)


def simwifi_teardown_bs(ctx, scen):
    nmci.lib.teardown_hostapd_wireless(ctx)
    sys.exit(77)


_register_tag("simwifi_teardown", simwifi_teardown_bs)


def vpnc_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        sys.exit(77)
    # Install under RHEL7 only
    if "Maipo" in ctx.rh_release:
        print("install epel-release-7")
        ctx.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
    if ctx.command_code("rpm -q NetworkManager-vpnc") != 0:
        print("install NetworkManager-vpnc")
        ctx.run("sudo yum -y install NetworkManager-vpnc")
        nmci.lib.restart_NM_service(ctx)
    nmci.lib.setup_racoon(ctx, mode="aggressive", dh_group=2)


def vpnc_as(ctx, scen):
    ctx.run('nmcli connection delete vpnc')
    nmci.lib.teardown_racoon(ctx)


_register_tag("vpnc", vpnc_bs, vpnc_as)


def tcpreplay_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        sys.exit(77)
    nmci.lib.wait_for_testeth0(ctx)
    # Install under RHEL7 only
    if "Maipo" in ctx.rh_release:
        print("install epel-release-7")
        ctx.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
    if not os.path.isfile("/usr/bin/tcpreplay"):
        print("install tcpreplay")
        ctx.run("yum -y install tcpreplay")


_register_tag("tcpreplay", tcpreplay_bs)


def teardown_testveth_as(ctx, scen):
    nmci.lib.teardown_testveth(ctx)


_register_tag("teardown_testveth", None, teardown_testveth_as)


def libreswan_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("rpm -q NetworkManager-libreswan") != 0:
        ctx.run("sudo yum -y install NetworkManager-libreswan")
        nmci.lib.restart_NM_service(ctx)
    ctx.run("/usr/sbin/ipsec --checknss")
    mode = "aggressive"
    if "ikev2" in scen.tags:
        mode = "ikev2"
    if "main" in scen.tags:
        mode = "main"
    nmci.lib.setup_libreswan(ctx, mode, dh_group=14)


def libreswan_as(ctx, scen):
    ctx.run('nmcli connection down libreswan')
    ctx.run('nmcli connection delete libreswan')
    nmci.lib.teardown_libreswan(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("libreswan", libreswan_bs, libreswan_as)
_register_tag("ikev2")
_register_tag("main")


def openvpn_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        nmci.lib.wait_for_testeth0(ctx)
        sys.exit(77)
    ctx.ovpn_proc = nmci.lib.setup_openvpn(ctx, scen.tags)


def openvpn_as(ctx, scen):
    nmci.lib.restore_testeth0(ctx)
    ctx.run('nmcli connection delete openvpn')
    ctx.run('nmcli connection delete tun0')
    ctx.run("sudo kill $(pidof openvpn)")


_register_tag("openvpn", openvpn_bs, openvpn_as)
_register_tag("openvpn4")
_register_tag("openvpn6")


def strongswan_bs(ctx, scen):
    # Do not run on RHEL7 on s390x
    if "release 7" in ctx.rh_release:
        if ctx.arch == "s390x":
            print("Skipping on RHEL7 on s390x")
            sys.exit(77)
    nmci.lib.wait_for_testeth0(ctx)
    nmci.lib.setup_strongswan(ctx)


def strongswan_as(ctx, scen):
    # ctx.run("ip route del default via 172.31.70.1")
    ctx.run('nmcli connection down strongswan')
    ctx.run('nmcli connection delete strongswan')
    nmci.lib.teardown_strongswan(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("strongswan", strongswan_bs, strongswan_as)


def vpn_as(ctx, scen):
    ctx.run("nmcli connection delete vpn")


_register_tag("vpn", None, vpn_as)


def iptunnel_bs(ctx, scen):
    # Workaround for 1869538
    ctx.run("modprobe -r xfrm_interface")
    ctx.run('sh prepare/iptunnel.sh')


def iptunnel_as(ctx, scen):
    ctx.run('sh prepare/iptunnel.sh teardown')


_register_tag("iptunnel", iptunnel_bs, iptunnel_as)


def iptunnel_doc_as(ctx, scen):
    # this must be done before @teardown_testveth
    # (netB is hidden in iptunnel_B namespace)
    ctx.run("nmcli con delete gre1 tun0 bridge0 bridge0-port1 bridge0-port2")
    ctx.run("ip netns del iptunnelB")
    ctx.run("ip link del ipA")
    ctx.run("ip link del tunB")
    ctx.run("ip link del brB")
    ctx.run("ip link del bridge0")


_register_tag("iptunnel_doc", None, iptunnel_doc_as)


def wireguard_bs(ctx, scen):
    stdout, stderr, rc = ctx.run('sh prepare/wireguard.sh')
    if rc != 0:
        assert False, "wireguard setup failed with exitcode: %d\nOutput:\n\n%s" % (rc, stdout)


def wireguard_as(ctx, scen):
    ctx.run('nmcli con del wireguard')


_register_tag("wireguard", wireguard_bs, wireguard_as)


def dracut_bs(ctx, scen):
    rc = ctx.command_code(
        "cd contrib/dracut; . ./setup.sh ; "
        " { time test_setup ; } &> /tmp/dracut_setup.log", shell=True)
    if rc != 0:
        print("dracut setup failed, doing clean !!!")
        ctx.run(
            "cd contrib/dracut; . ./setup.sh ;"
            "{ time test_clean; } &> /tmp/dracut_teardown.log", shell=True)
        assert False, "dracut setup failed"


def dracut_as(ctx, scen):
    # do not embed DHCP directly, cache output for "no free leases" check
    # nmci.lib.embed_service_log(ctx, "dhcpd", "DHCP")
    dhcpd_log = nmci.lib.get_service_log("dhcpd", ctx.log_cursor)
    ctx.embed("text/plain", dhcpd_log, "DHCP")
    nmci.lib.embed_service_log(ctx, "radvd", "RA")
    nmci.lib.embed_service_log(ctx, "rpc.mountd", "NFS")
    ctx.run("cd contrib/dracut; . ./setup.sh; after_test")
    # assert when everything is embedded
    assert "no free leases" not in dhcpd_log, "DHCPD leases exhausted"


_register_tag("dracut", dracut_bs, dracut_as)


def prepare_patched_netdevsim_bs(ctx, scen):
    rc = ctx.command_code('sh prepare/netdevsim.sh setup')
    assert rc == 0, "netdevsim setup failed with exitcode: %d" % rc


def prepare_patched_netdevsim_as(ctx, scen):
    ctx.run('sh prepare/netdevsim.sh teardown')


_register_tag("prepare_patched_netdevsim", prepare_patched_netdevsim_bs, prepare_patched_netdevsim_as)


def load_netdevsim_bs(ctx, scen):
    ctx.run('modprobe -r netdevsim; modprobe netdevsim')
    ctx.run("echo 1 1 > /sys/bus/netdevsim/new_device ; sleep 1")


def load_netdevsim_as(ctx, scen):
    ctx.run('modprobe -r netdevsim; sleep 1')


_register_tag("load_netdevsim", load_netdevsim_bs, load_netdevsim_as)


def attach_hostapd_log_as(ctx, scen):
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ HOSTAPD LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-hostapd.log")
    ctx.run("sudo journalctl -u nm-hostapd --no-pager -o cat %s >> /tmp/journal-hostapd.log" % ctx.log_cursor)
    data = nmci.lib.utf_only_open_read("/tmp/journal-hostapd.log")
    if data:
        print("Attaching hostapd log")
        ctx.embed('text/plain', data, caption="HOSTAPD")


_register_tag("attach_hostapd_log", None, attach_hostapd_log_as)


def attach_wpa_supplicant_log_as(ctx, scen):
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ WPA_SUPPLICANT LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-wpa_supplicant.log")
    ctx.run("journalctl -u wpa_supplicant --no-pager -o cat %s >> /tmp/journal-wpa_supplicant.log" % ctx.log_cursor)
    data = nmci.lib.utf_only_open_read("/tmp/journal-wpa_supplicant.log")
    if data:
        print("Attaching wpa_supplicant log")
        ctx.embed('text/plain', data, caption="WPA_SUP")


_register_tag("attach_wpa_supplicant_log", None, attach_wpa_supplicant_log_as)


def performance_bs(ctx, scen):
    if ctx.command_code("hostname |grep -q gsm-r5") != 0:
        print("Skipping on gsm-r5*")
        sys.exit(77)
    # NM needs to go down


def performance_as(ctx, scen):
    ctx.nm_restarted = True
    # Settings device number to 0
    ctx.run("tmp/./setup.sh 0")
    # Deleting all connections
    cons = ""
    for i in range(1,101):cons=cons+('t-a%s ' %i)
    command = "nmcli con del %s" %cons
    ctx.run(command)
    # setup.sh masks dispatcher scripts
    ctx.run("systemctl unmask NetworkManager-dispatcher")


_register_tag("performance", performance_bs, performance_as)


def preserve_8021x_certs_bs(ctx, scen):
    assert ctx.command_code("mkdir -p /tmp/certs/") == 0, "unable to create /tmp/certs/ directory"
    assert ctx.command_code("cp -r tmp/8021x/certs/client/* /tmp/certs/") == 0, "unable to copy certificates"


_register_tag("preserve_8021x_certs", preserve_8021x_certs_bs)


def pptp_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        sys.exit(77)
    nmci.lib.wait_for_testeth0(ctx)
    # Install under RHEL7 only
    if "Maipo" in ctx.rh_release:
        print("install epel-release-7")
        ctx.run("[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm")
    ctx.run("[ -x /usr/sbin/pptpd ] || sudo yum -y install /usr/sbin/pptpd")
    ctx.run("rpm -q NetworkManager-pptp || sudo yum -y install NetworkManager-pptp")

    ctx.run("sudo rm -f /etc/ppp/ppp-secrets")
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

        ctx.run("sudo systemctl unmask pptpd")
        ctx.run("sudo systemctl restart pptpd")
        #context.execute_steps(u'* Add a connection named "pptp" for device "\*" to "pptp" VPN')
        #context.execute_steps(u'* Use user "budulinek" with password "passwd" and MPPE set to "yes" for gateway "127.0.0.1" on PPTP connection "pptp"')
        ctx.run("/sbin/pppd pty '/sbin/pptp 127.0.0.1' nodetach")
        #ctx.run("nmcli con up id pptp")
        #ctx.run("nmcli con del pptp")
        ctx.run("touch /tmp/nm_pptp_configured")
        time.sleep(1)


def pptp_as(ctx, scen):
    ctx.run('nmcli connection delete pptp')


_register_tag("pptp", pptp_bs, pptp_as)


def firewall_bs(ctx, scen):
    if ctx.command_code("rpm -q firewalld") != 0:
        print("install firewalld")
        nmci.lib.wait_for_testeth0(ctx)
        ctx.run("sudo yum -y install firewalld")
    ctx.run("sudo systemctl unmask firewalld")
    time.sleep(1)
    ctx.run("sudo systemctl stop firewalld")
    time.sleep(5)
    ctx.run("sudo systemctl start firewalld")
    ctx.run("sudo nmcli con modify testeth0 connection.zone public")
    # Add a sleep here to prevent firewalld to hang
    # (see https://bugzilla.redhat.com/show_bug.cgi?id=1495893)
    time.sleep(1)


def firewall_as(ctx, scen):
    ctx.run("sudo firewall-cmd --panic-off")
    ctx.run("sudo systemctl stop firewalld")


_register_tag("firewall", firewall_bs, firewall_as)


def restore_hostname_bs(ctx, scen):
    ctx.original_hostname = ctx.command_output('hostname').strip()


def restore_hostname_as(ctx, scen):
    ctx.run('systemctl unmask systemd-hostnamed.service')
    ctx.run('systemctl unmask dbus-org.freedesktop.hostname1.service')
    if ctx.IS_NMTUI:
        ctx.run('sudo echo "localhost.localdomain" > /etc/hostname')
    else:
        ctx.run('hostnamectl set-hostname --transient ""')
        ctx.run('hostnamectl set-hostname --static %s' % ctx.original_hostname)
    ctx.run('rm -rf /etc/NetworkManager/conf.d/90-hostname.conf')
    ctx.run('rm -rf /etc/dnsmasq.d/dnsmasq_custom.conf')
    nmci.lib.reload_NM_service(ctx)
    ctx.run("nmcli con up testeth0")


_register_tag("restore_hostname", restore_hostname_bs, restore_hostname_as)


def runonce_bs(ctx, scen):
    ctx.run("systemctl stop network")
    ctx.run("nmcli device disconnect eth0")
    ctx.run("pkill -9 dhclient")
    ctx.run("pkill -9 nm-iface-helper")
    ctx.run("sudo systemctl stop firewalld")


def runonce_as(ctx, scen):
    ctx.run("for i in $(pidof nm-iface-helper); do kill -9 $i; done")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/01-run-once.conf")
    time.sleep(1)
    nmci.lib.restart_NM_service(ctx)
    time.sleep(1)
    ctx.run("for i in $(pidof nm-iface-helper); do kill -9 $i; done")
    ctx.run("nmcli connection delete con_general")
    ctx.run("nmcli device disconnect eth10")
    ctx.run("nmcli connection up testeth0")


_register_tag("runonce", runonce_bs, runonce_as)


def slow_team_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skippin as not on x86_64")
        sys.exit(77)
    ctx.run("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done")
    ctx.run("yum -y install https://vbenes.fedorapeople.org/NM/slow_libteam-1.25-5.el7_4.1.1.x86_64.rpm https://vbenes.fedorapeople.org/NM/slow_teamd-1.25-5.el7_4.1.1.x86_64.rpm")
    if ctx.command_code("rpm --quiet -q teamd") != 0:
        print("Skipping as unable to install slow_team")
        # Restore teamd package if we don't have the slow ones
        ctx.run("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done")
        ctx.run("yum -y install teamd libteam")
        sys.exit(77)
    nmci.lib.reload_NM_service(ctx)


def slow_team_as(ctx, scen):
    ctx.run("for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done")
    ctx.run("yum -y install teamd libteam")
    nmci.lib.reload_NM_service(ctx)


_register_tag("slow_team", slow_team_bs, slow_team_as)


def openvswitch_bs(ctx, scen):
    if ctx.arch == "s390x" and "Ootpa" not in ctx.rh_release:
        print("Skipping as on s390x and not Ootpa")
        sys.exit(77)
    if ctx.command_code('rpm -q NetworkManager-ovs') != 0:
        print("install NetworkManager-ovs")
        ctx.run('yum -y install NetworkManager-ovs')
        ctx.run('systemctl daemon-reload')
        nmci.lib.restart_NM_service(ctx)
    if ctx.command_code('systemctl is-active openvswitch') != 0 or \
            ctx.command_code('systemctl status ovs-vswitchd.service |grep -q ERR') != 0:
        print("restart openvswitch")
        ctx.run('systemctl restart openvswitch')
        nmci.lib.restart_NM_service(ctx)


def openvswitch_as(ctx, scen):
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ OVSDB LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log")
    data1 = nmci.lib.utf_only_open_read("/var/log/openvswitch/ovsdb-server.log")
    if data1:
        print("Attaching OVSDB log")
        ctx.embed('text/plain', data1, caption="OVSDB")
    ctx.run("echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ OVSDemon LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log")
    data2 = nmci.lib.utf_only_open_read("/var/log/openvswitch/ovs-vswitchd.log")
    if data2:
        print("Attaching OVSDemon log")
        ctx.embed('text/plain', data2, caption="OVSDemon")

    ctx.run('sudo ifdown bond0')
    ctx.run('sudo ifdown eth1')
    ctx.run('sudo ifdown eth2')
    ctx.run('sudo ifdown ovsbridge0')
    ctx.run('sudo nmcli con del eth1 eth2 ovs-bond0 ovs-port0 ovs-patch0 ovs-patch1 ovs-bridge1 ovs-bridge0 ovs-port1 ovs-eth2 ovs-eth3 ovs-iface0 eth2 dpdk-sriov c-ovs-br0 c-ovs-port0 c-ovs-iface0 ovs-testX') # to be sure
    time.sleep(1)
    ctx.run('ovs-vsctl del-br ovsbr0')
    ctx.run('ovs-vsctl del-br ovsbridge0')
    ctx.run('ovs-vsctl del-br ovsbridge1')
    ctx.run('ovs-vsctl del-br i-ovs-br0')
    ctx.run('nmcli device delete bond0')
    ctx.run('nmcli device delete port0')
    ctx.run('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-eth1')
    ctx.run('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-bond0')
    ctx.run('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ovsbridge0')
    ctx.run('sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-intbr0')
    ctx.run('sudo ip link set dev eth1 up')
    ctx.run('sudo ip link set dev eth2 up')
    ctx.run('sudo nmcli con reload')
    ctx.run('nmcli con up testeth1')
    ctx.run('nmcli con down testeth1')
    ctx.run('nmcli con up testeth2')
    ctx.run('nmcli con down testeth2')


_register_tag("openvswitch", openvswitch_bs, openvswitch_as)


def sriov_bs(ctx, scen):
    ctx.run('nmcli con del p4p1')


def sriov_as(ctx, scen):
    ctx.run("nmcli con del sriov")
    ctx.run("nmcli con del sriov_2")

    ctx.run("echo 0 > /sys/class/net/p6p1/device/sriov_numvfs")
    ctx.run("echo 0 > /sys/class/net/p4p1/device/sriov_numvfs")

    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-sriov.conf")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/98-sriov.conf")

    ctx.run("echo 1 > /sys/class/net/p4p1/device/sriov_drivers_autoprobe")
    ctx.run("echo 1 > /sys/class/net/p6p1/device/sriov_drivers_autoprobe")

    ctx.run("modprobe -r ixgbevf")

    ctx.run("nmcli con del sriov_2")

    nmci.lib.reload_NM_service(ctx)


_register_tag("sriov", sriov_bs, sriov_as)


def sriov_bond_as(ctx, scen):
    ctx.run("nmcli con del sriov2")
    ctx.run("nmcli con del sriov_bond0")
    ctx.run("nmcli con del sriov_bond0.0")
    ctx.run("nmcli con del sriov_bond0.1")


_register_tag("sriov_bond", None, sriov_bond_as)


def dpdk_bs(ctx, scen):
    ctx.run("sysctl -w vm.nr_hugepages=10")

    ctx.run('yum -y install dpdk dpdk-tools')

    ctx.run('sed -i.bak s/openvswitch:hugetlbfs/root:root/g /etc/sysconfig/openvswitch')

    ctx.run('ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true')

    ctx.run('modprobe vfio-pci')

    ctx.run('echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode')

    ctx.run('nmcli  connection add type ethernet ifname p4p1 con-name dpdk-sriov sriov.total-vfs 2')
    ctx.run('nmcli  connection up dpdk-sriov')

    ctx.run('dpdk-devbind -b vfio-pci 0000:42:10.0')
    ctx.run('dpdk-devbind -b vfio-pci 0000:42:10.2')

    ctx.run('systemctl restart openvswitch')
    nmci.lib.restart_NM_service(ctx)


def dpdk_as(ctx, scen):
    ctx.run('systemctl stop ovsdb-server')
    ctx.run('systemctl stop openvswitch')
    time.sleep(5)
    ctx.run('nmcli con del dpdk-sriov ovs-iface1 && sleep 1')
    ctx.run('systemctl device disconnect p4p1')


_register_tag("dpdk", dpdk_bs, dpdk_as)


def wireless_certs_bs(ctx, scen):
    ctx.run('mkdir /tmp/certs')
    if not os.path.isfile('/tmp/certs/eaptest_ca_cert.pem'):
        ctx.run('wget http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem -O /tmp/certs/eaptest_ca_cert.pem')
    if not os.path.isfile('/tmp/certs/client.pem'):
        ctx.run('wget http://wlan-lab.eng.bos.redhat.com/certs/client.pem -O /tmp/certs/client.pem')


_register_tag("wireless_certs", wireless_certs_bs)


def selinux_allow_ifup_bs(ctx, scen):
    ctx.run("semodule -i tmp/selinux-policy/ifup_policy.pp")


_register_tag("selinux_allow_ifup", selinux_allow_ifup_bs)


def no_testeth10_bs(ctx, scen):
    ctx.run('sudo nmcli connection delete testeth10')


_register_tag("no_testeth10", no_testeth10_bs)


def pppoe_bs(ctx, scen):
    # selinux on aarch64: see https://bugzilla.redhat.com/show_bug.cgi?id=1643954
    if ctx.arch == "aarch64":
        print("enable pppd selinux policy on aarch64")
        ctx.run("semodule -i tmp/selinux-policy/pppd.pp")
    # This -x is to avoid upgrade of NetworkManager in older version testing
    ctx.run("rpm -q NetworkManager-ppp || yum -y install NetworkManager-ppp -x NetworkManager")
    ctx.run('rpm -q rp-pppoe || yum -y install rp-pppoe')
    ctx.run('[ -x //usr/sbin/pppoe-server ] || yum -y install https://kojipkgs.fedoraproject.org//packages/rp-pppoe/3.12/11.fc28/$(uname -p)/rp-pppoe-3.12-11.fc28.$(uname -p).rpm')
    ctx.run("mknod /dev/ppp c 108 0")
    nmci.lib.reload_NM_service(ctx)


def pppoe_as(ctx, scen):
    ctx.run('kill -9 $(pidof pppoe-server)')
    ctx.run('nmcli con del ppp ppp2')


_register_tag("pppoe", pppoe_bs, pppoe_as)


def del_test1112_veths_bs(ctx, scen):
    ctx.run('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test11|test12", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/99-veths.rules''')
    ctx.run("udevadm control --reload-rules")
    ctx.run("udevadm settle --timeout=5")
    time.sleep(1)


def del_test1112_veths_as(ctx, scen):
    ctx.run('ip link del test11')
    ctx.run('rm -f /etc/udev/rules.d/99-veths.rules')
    ctx.run('udevadm control --reload-rules')
    ctx.run('udevadm settle --timeout=5')
    time.sleep(1)


_register_tag("del_test1112_veths", del_test1112_veths_bs, del_test1112_veths_as)


def veth_remove_as(ctx, scen):
    ctx.run('nmcli con down con_veth2')
    ctx.run('nmcli con down con_veth1')
    ctx.run('nmcli con delete con_veth1')
    ctx.run('nmcli con delete con_veth2')
    ctx.run('ip link del veth11')


_register_tag("veth_remove", None, veth_remove_as)

def nmstate_bs(ctx, scen):
    ctx.run("yum -y remove nmstate nispor")
    ctx.run("yum -y install nmstate")

_register_tag("nmstate", nmstate_bs, None)


def nmstate_upstream_setup_bs(ctx, scen):
    # Skip on deployments where we do not have veths
    if not os.path.isfile('/tmp/nm_newveth_configured'):
        print("Skipping as no vethsetup")
        sys.exit(77)

    # Prepare nmstate and skip if unsuccesful
    if ctx.command_code("sh prepare/nmstate.sh") != 0:
        print("ERROR: Skipping as prepare failed")
        sys.exit(77)

    # Rename eth1/2 to ethX/Y as these are used by test
    ctx.run("ip link set dev eth1 down")
    ctx.run("ip link set name ethX eth1")
    ctx.run("ip link set dev eth2 down")
    ctx.run("ip link set name ethY eth2")

    # We need to have use_tempaddr set to 0 to avoid test_dhcp_on_bridge0 PASSED
    ctx.run("echo 0 > /proc/sys/net/ipv6/conf/default/use_tempaddr")

    # Clone default profile but just ipv4 only"
    ctx.run('nmcli connection clone "$(nmcli -g NAME con show -a)" nmstate')
    ctx.run("nmcli con modify nmstate ipv6.method disabled ipv6.addresses '' ipv6.gateway ''")
    ctx.run("nmcli con up nmstate")

    # Move orig config file to /tmp
    ctx.run('mv /etc/NetworkManager/conf.d/99-unmanage-orig.conf /tmp')

    # Remove connectivity packages if present
    ctx.run("dnf -y remove NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat")
    nmci.lib.manage_veths(ctx)

    if ctx.command_code('systemctl is-active openvswitch') != 0 or \
            ctx.command_code('systemctl status ovs-vswitchd.service |grep -q ERR') != 0:
        print("restarting OVS service")
        ctx.run('systemctl restart openvswitch')
        nmci.lib.restart_NM_service(ctx)


def nmstate_upstream_setup_as(ctx, scen):
    # nmstate restarts NM few times during tests
    ctx.nm_restarted = True

    ctx.run("nmcli con del linux-br0 dhcpcli dhcpsrv brtest0 bond99 eth1.101 eth1.102")
    ctx.run('nmcli con del eth0 eth1 eth2 eth3 eth4 eth5 eth6 eth7 eth8 eth9 eth10')

    ctx.run("nmcli device delete dhcpsrv")
    ctx.run("nmcli device delete dhcpcli")
    ctx.run("nmcli device delete bond99")

    ctx.run("ovs-vsctl del-br ovsbr0")

    # in case of fail we need to kill this
    ctx.run('systemctl stop dnsmasq')
    ctx.run("pkill -f 'dnsmasq.*/etc/dnsmasq.d/nmstate.conf'")
    ctx.run('rm -rf /etc/dnsmasq.d/nmstate.conf')

    # Rename devices back to eth1/eth2
    ctx.run("ip link del eth1")
    ctx.run("ip link set dev ethX down")
    ctx.run("ip link set name eth1 ethX")
    ctx.run("ip link set dev eth1 up")

    ctx.run("ip link del eth2")
    ctx.run("ip link set dev ethY down")
    ctx.run("ip link set name eth2 ethY")
    ctx.run("ip link set dev eth2 up")


    # remove profiles
    ctx.run("nmcli con del nmstate ethX ethY eth1peer eth2peer")

    # Move orig config file to back
    ctx.run('mv /tmp/99-unmanage-orig.conf /etc/NetworkManager/conf.d/')

    # restore testethX
    nmci.lib.restore_connections(ctx)
    nmci.lib.wait_for_testeth0(ctx)

    # check just in case something went wrong
    ctx.run("sh prepare/vethsetup.sh check")

    nmstate = nmci.lib.utf_only_open_read("/tmp/nmstate.txt")
    if nmstate:
        print("Attaching nmstate log")
        ctx.embed('text/plain', nmstate, caption="NMSTATE")


_register_tag("nmstate_upstream_setup", nmstate_upstream_setup_bs, nmstate_upstream_setup_as)


def backup_sysconfig_network_bs(ctx, scen):
    ctx.run('sudo cp -f /etc/sysconfig/network /tmp/sysnetwork.backup')


def backup_sysconfig_network_as(ctx, scen):
    ctx.run('sudo mv -f /tmp/sysnetwork.backup /etc/sysconfig/network')
    nmci.lib.reload_NM_connections(ctx)
    ctx.run('sudo nmcli connection down testeth9')


_register_tag("backup_sysconfig_network", backup_sysconfig_network_bs, backup_sysconfig_network_as)


def remove_fedora_connection_checker_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    ctx.run('yum -y remove NetworkManager-config-connectivity-fedora')
    nmci.lib.reload_NM_service(ctx)


_register_tag("remove_fedora_connection_checker", remove_fedora_connection_checker_bs)


def need_config_server_bs(ctx, scen):
    if ctx.command_code('rpm -q NetworkManager-config-server') == 0:
        ctx.remove_config_server = False
    else:
        print("Install NetworkManager-config-server")
        ctx.run('sudo yum -y install NetworkManager-config-server')
        nmci.lib.reload_NM_service(ctx)
        ctx.remove_config_server = True


def need_config_server_as(ctx, scen):
    if ctx.remove_config_server:
        print("removing NetworkManager-config-server")
        ctx.run('sudo yum -y remove NetworkManager-config-server')
        nmci.lib.reload_NM_service(ctx)


_register_tag("need_config_server", need_config_server_bs, need_config_server_as)


def no_config_server_bs(ctx, scen):
    if ctx.command_code('rpm -q NetworkManager-config-server') == 1:
        ctx.restore_config_server = False
    else:
        #ctx.run('sudo yum -y remove NetworkManager-config-server')
        config_files = ctx.command_output('rpm -ql NetworkManager-config-server').strip().split('\n')
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file):
                print("* disabling file: %s" % config_file)
                ctx.run('sudo mv -f %s %s.off' % (config_file, config_file))
        nmci.lib.reload_NM_service(ctx)
        ctx.restore_config_server = True


def no_config_server_as(ctx, scen):
    if ctx.restore_config_server:
        config_files = ctx.command_output('rpm -ql NetworkManager-config-server').strip().split('\n')
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file + '.off'):
                print("* enabling file: %s" % config_file)
                ctx.run('sudo mv -f %s.off %s' % (config_file, config_file))
        nmci.lib.reload_NM_service(ctx)
    ctx.run("for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |awk -F ':' ' {print $2}'); do nmcli con del $i; done")
    nmci.lib.restore_testeth0(ctx)


_register_tag("no_config_server", no_config_server_bs, no_config_server_as)


def permissive_bs(ctx, scen):
    ctx.enforcing = False
    if ctx.command_output('getenforce').strip() == 'Enforcing':
        print("WORKAROUND for permissive selinux")
        ctx.enforcing = True
        ctx.run('setenforce 0')


def permissive_as(ctx, scen):
    if ctx.enforcing:
        print("WORKAROUND for permissive selinux")
        ctx.run('setenforce 1')


_register_tag("permissive", permissive_bs, permissive_as)


def tcpdump_bs(ctx, scen):
    with open("/tmp/network-traffic.log", "w") as f:
        f.write("~~~~~~~~~~~~~~~~~~~~~~~~~~ TRAFFIC LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    ctx.pexpect_service("/bin/bash", ["-c", "sudo tcpdump -nne -i any >> /tmp/network-traffic.log"])


def tcpdump_as(ctx, scen):
    print("Attaching traffic log")
    ctx.run("sudo kill -1 $(pidof tcpdump)")
    if os.stat("/tmp/network-traffic.log").st_size < 20000000:
        traffic = nmci.lib.utf_only_open_read("/tmp/network-traffic.log")
    else:
        traffic = "WARNING: 20M size exceeded in /tmp/network-traffic.log, skipping"
    ctx.embed('text/plain', traffic, caption="TRAFFIC", fail_only=True)

    ctx.run("pkill -9 tcpdump")


_register_tag("tcpdump", tcpdump_bs, tcpdump_as)


def wifi_bs(ctx, scen):
    if ctx.IS_NMTUI:
        nmci.lib.wifi_rescan(ctx)


def wifi_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id wifi wifi1 qe-open qe-wpa1-psk qe-wpa2-psk qe-wep")
        # ctx.run("sudo service NetworkManager restart") # debug restart to overcome the nmcli d w l flickering
    else:
        # ctx.run('sudo nmcli device disconnect wlan0')
        ctx.run('sudo nmcli con del wifi qe-open qe-wep qe-wep-psk qe-wep-enterprise qe-wep-enterprise-cisco')
        ctx.run('sudo nmcli con del qe-wpa1-psk qe-wpa2-psk qe-wpa1-enterprise qe-wpa2-enterprise qe-hidden-wpa2-psk')
        ctx.run('sudo nmcli con del qe-adhoc qe-ap wifi-wlan0')
        if "novice" in scen.tags:
            ctx.prompt.close()
            time.sleep(1)
            ctx.run('sudo nmcli con del wifi-wlan0')


_register_tag("wifi", wifi_bs, wifi_as)
_register_tag("novice")


def rescan_as(ctx, scen):
    nmci.lib.wifi_rescan(ctx)


_register_tag("rescan", None, rescan_as)



def no_connections_bs(ctx, scen):
    ctx.command_code("rm -rf /etc/NetworkManager/system-connections/testeth*")
    ctx.command_code("rm -rf /etc/sysconfig/network-scripts/ifcfg-*")
    ctx.command_code("nmcli con reload")


def no_connections_as(ctx, scen):
    if ctx.IS_NMTUI:
        nmci.lib.restore_connections(ctx)
        nmci.lib.wait_for_testeth0(ctx)


_register_tag("no_connections", no_connections_bs, no_connections_as)


def bridge_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli con down bridge0")
        time.sleep(1)
        ctx.run("sudo nmcli connection delete id bridge0 bridge-slave-eth1 bridge-slave-eth2")
        time.sleep(1)

        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth1')
        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth2')
        ctx.run("sudo ip link del bridge0")
        if "many_slaves" in scen.tags:
            ctx.run(
                "sudo nmcli con delete id bridge-slave-eth3 bridge-slave-eth4 bridge-slave-eth5"
                " bridge-slave-eth6 bridge-slave-eth7 bridge-slave-eth8 bridge-slave-eth9")
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth3')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth4')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth5')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth6')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth7')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth8')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth9')
    else:
        if 'bridge_assumed' in scen.tags:
            ctx.run('ip link del bridge0')
            ctx.run('ip link del br0')

        ctx.run('sudo nmcli con del bridge4 bridge4.0 bridge4.1 nm-bridge eth4.80 eth4.90')
        ctx.run('sudo nmcli con del bridge-slave-eth4 bridge-nonslave-eth4 bridge-slave-eth4.80 eth4')
        ctx.run('sudo nmcli con del bridge0 bridge bridge.15 nm-bridge br88 br11 br12 br15 bridge-slave br15-slave br15-slave1 br15-slave2 br10 br10-slave')
        nmci.lib.reset_hwaddr_nmcli(ctx, 'eth4')


_register_tag("bridge", None, bridge_as)
_register_tag("many_slaves")
_register_tag("bridge_assumed")


def vlan_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id vlan eth1.99")
        ctx.run("sudo ip link del eth1.99")
        ctx.run("sudo ip link del eth2.88")
    else:
        ctx.run('sudo nmcli con del vlan vlan1 vlan2 eth7.99 eth7.99 eth7.299 eth7.399 eth7.65 eth7.165 eth7.265 eth7.499 eth7.80 eth7.90')
        ctx.run('sudo nmcli con del vlan_bridge7.15 vlan_bridge7 vlan_vlan7 vlan_bond7 vlan_bond7.7 vlan_team7 vlan_team7.1 vlan_team7.0')
        ctx.run('ip link del bridge7')
        ctx.run('ip link del eth7.99')
        ctx.run('ip link del eth7.80')
        ctx.run('ip link del eth7.90')
        ctx.run('ip link del vlan7')
        ctx.run('ip link del vlan0')
        ctx.run('nmcli con down testeth7')
        nmci.lib.reset_hwaddr_nmcli(ctx, 'eth7')


_register_tag("vlan", None, vlan_as)


def many_vlans_as(ctx, scen):
    ctx.run("for i in {1..255}; do ip link del vlan.$i;done")


_register_tag("many_vlans", None, many_vlans_as)


def bond_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id bond0 bond-slave-eth1 bond-slave-eth2")
        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth1')
        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth2')
        ctx.run("sudo ip link del bond0")
        if "many_slaves" in scen.tags:
            ctx.run(
                "sudo nmcli con delete bond-slave-eth3 bond-slave-eth4 bond-slave-eth5"
                " bond-slave-eth6 bond-slave-eth7 bond-slave-eth8 bond-slave-eth9")
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth3')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth4')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth5')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth6')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth7')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth8')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth9')
    else:
        ctx.run('nmcli connection delete id bond0 bond')
        ctx.run('ip link del nm-bond')
        ctx.run('ip link del bond0')
        #sleep(TIMER)
        ctx.command_output('ls /proc/net/bonding || true')


_register_tag("bond", None, bond_as)


def team_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run("sudo nmcli connection delete id team0 team-slave-eth1 team-slave-eth2")
        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth1')
        nmci.lib.reset_hwaddr_nmtui(ctx, 'eth2')
        ctx.run("sudo ip link del team0")
        if "many_slaves" in scen.tags:
            ctx.run(
                "sudo nmcli con delete team-slave-eth3 team-slave-eth4 team-slave-eth5"
                " team-slave-eth6 team-slave-eth7 team-slave-eth8 team-slave-eth9")
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth3')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth4')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth5')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth6')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth7')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth8')
            nmci.lib.reset_hwaddr_nmtui(ctx, 'eth9')
    else:
        ctx.run('nmcli connection down team0')
        ctx.run('nmcli connection delete id team0 team')
        if 'team_assumed' in scen.tags:
            ctx.run('ip link del nm-team' )
        #sleep(TIMER)
        ctx.run("if nmcli con |grep 'team0 '; then echo 'team0 present: %s' >> /tmp/residues; fi" %scen.tags)


_register_tag("team", None, team_as)
_register_tag("team_assumed", None, None)


def team_slaves_as(ctx, scen):
    ctx.run('nmcli connection delete id team0.0 team0.1 team-slave-eth5 team-slave-eth6 eth5 eth6 team-slave')
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth5')
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth6')
    #sleep(TIMER)


_register_tag("team_slaves", None, team_slaves_as)


def teamd_as(ctx, scen):
    ctx.run("systemctl stop teamd")
    ctx.run("systemctl reset-failed teamd")


_register_tag("teamd", None, teamd_as)


def bond_bridge_as(ctx, scen):
    ctx.run('sudo nmcli con del bond_bridge0')
    ctx.run('sudo ip link del bond-bridge')


_register_tag("bond_bridge", None, bond_bridge_as)


def team_br_remove_as(ctx, scen):
    ctx.run('sudo nmcli con del team_br')
    ctx.run('ip link del brA')


_register_tag("team_br_remove", None, team_br_remove_as)


def gen_br_remove_as(ctx, scen):
    ctx.run('sudo nmcli con del gen_br')
    ctx.run('ip link del brX')


_register_tag("gen_br_remove", None, gen_br_remove_as)


def restore_eth1_mtu_as(ctx, scen):
    ctx.run("sudo ip link set eth1 mtu 1500")


_register_tag("restore_eth1_mtu", None, restore_eth1_mtu_as)


def wifi_rescan_as(ctx, scen):
    if ctx.IS_NMTUI:
        nmci.lib.restart_NM_service(ctx)
        nmci.lib.wifi_rescan(ctx)


_register_tag("wifi_rescan", None, wifi_rescan_as)


def testeth7_disconnect_as(ctx, scen):
    if ctx.IS_NMTUI:
        if ctx.command_code("nmcli connection show -a |grep testeth7") == 0:
            print("bring down testeth7")
            ctx.run("nmcli con down testeth7")


_register_tag("testeth7_disconnect", None, testeth7_disconnect_as)


def checkpoint_remove_as(ctx, scen):
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
            print("destroying checkpoint with path %s" % checkpoint)
            manager.CheckpointDestroy(checkpoint)


_register_tag("checkpoint_remove", None, checkpoint_remove_as)


def clean_iptables_as(ctx, scen):
    ctx.run("iptables -D OUTPUT -p udp --dport 67 -j REJECT")


_register_tag("clean_iptables", None, clean_iptables_as)


def kill_dhclient_custom_as(ctx, scen):
    ctx.run("kill $(cat /tmp/dhclient_custom.pid)")
    ctx.run("rm -f /tmp/dhclient_custom.pid")


_register_tag("kill_dhclient_custom", None, kill_dhclient_custom_as)


def networking_on_as(ctx, scen):
    ctx.run("nmcli networking on")
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("networking_on", None, networking_on_as)


def adsl_as(ctx, scen):
    ctx.run("nmcli connection delete id adsl-test11 adsl")


_register_tag("adsl", None, adsl_as)


def allow_veth_connections_bs(ctx, scen):
    if ctx.command_code("grep '^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"' /usr/lib/udev/rules.d/85-nm-unmanaged.rules") == 0:
        ctx.run("sed -i 's/^ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/#ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/' /usr/lib/udev/rules.d/85-nm-unmanaged.rules")
        ctx.run('udevadm control --reload-rules')
        ctx.run('udevadm settle --timeout=5')
        ctx.run('rm -rf /var/lib/NetworkManager/no-auto-default.state')
        with open("/etc/NetworkManager/conf.d/99-unmanaged.conf", "w") as cfg:
            cfg.write('[main]\n')
            cfg.write('no-auto-default=eth*\n')
        nmci.lib.reload_NM_service(ctx)
        ctx.revert_unmanaged = True
    else:
        ctx.revert_unmanaged = False


def allow_veth_connections_as(ctx, scen):
    if ctx.revert_unmanaged:
        ctx.run("sed -i 's/^#ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/ENV{ID_NET_DRIVER}==\"veth\", ENV{NM_UNMANAGED}=\"1\"/' /usr/lib/udev/rules.d/85-nm-unmanaged.rules")
        ctx.run('sudo rm -rf /etc/NetworkManager/conf.d/99-unmanaged.conf')
        ctx.run('udevadm control --reload-rules')
        ctx.run('udevadm settle --timeout=5')
        nmci.lib.reload_NM_service(ctx)
    ctx.run("nmcli con del 'Wired connection 1'")
    ctx.run("nmcli con del 'Wired connection 2'")
    ctx.run("for i in $(nmcli -t -f DEVICE c s -a |grep -v ^eth0$); do nmcli device disconnect $i; done")


_register_tag("allow_veth_connections", allow_veth_connections_bs, allow_veth_connections_as)


def con_ipv4_remove_as(ctx, scen):
    ctx.run("nmcli connection delete id con_ipv4 con_ipv42")
    ctx.run("if nmcli con |grep con_ipv4; then echo 'con_ipv4 present: %s' >> /tmp/residues; fi" % scen.tags)


_register_tag("con_ipv4_remove", None, con_ipv4_remove_as)


def con_ipv6_remove_as(ctx, scen):
    ctx.run("nmcli connection down con_ipv6 ")
    ctx.run("nmcli connection down con_ipv62 ")
    ctx.run("nmcli connection delete id con_ipv6 con_ipv62")
    ctx.run("if nmcli con |grep con_ipv6; then echo 'con_ipv6 present: %s' >> /tmp/residues; fi" %scen.tags)


_register_tag("con_ipv6_remove", None, con_ipv6_remove_as)


def con_ipv6_ifcfg_remove_as(ctx, scen):
    #ctx.run("nmcli connection delete id con_ipv6 con_ipv62")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv6")
    ctx.run('nmcli con reload')


_register_tag("con_ipv6_ifcfg_remove", None, con_ipv6_ifcfg_remove_as)


def con_con_remove_as(ctx, scen):
    ctx.run("nmcli connection delete id con_con con_con2")


_register_tag("con_con_remove", None, con_con_remove_as)


def con_general_remove_as(ctx, scen):
    ctx.run("sudo nmcli connection delete id con_general con_general2")


_register_tag("con_general_remove", None, con_general_remove_as)


def con_tc_remove_as(ctx, scen):
    ctx.run("sudo nmcli connection delete id con_tc")


_register_tag("con_tc_remove", None, con_tc_remove_as)


def con_dns_remove_as(ctx, scen):
    ctx.run("nmcli connection delete id con_dns con_dns2")


_register_tag("con_dns_remove", None, con_dns_remove_as)


def con_ethernet_remove_as(ctx, scen):
    ctx.run("nmcli connection delete id con_ethernet")


_register_tag("con_ethernet_remove", None, con_ethernet_remove_as)


def con_vrf_remove_as(ctx, scen):
    ctx.run("nmcli connection delete id vrf.eth4 vrf.eth1 vrf0 vrf1")


_register_tag("con_vrf_remove", None, con_vrf_remove_as)


def con_PBR_remove_as(ctx, scen):
    ctx.run("sudo nmcli connection delete id Servers Internal-Workstations Provider-A Provider-B")


_register_tag("con_PBR_remove", None, con_PBR_remove_as)


def many_con_remove_as(ctx, scen):
    ctx.run('nmcli con del con-team con-bond con-wifi')


_register_tag("many_con_remove", None, many_con_remove_as)


def gen_bond_remove_as(ctx, scen):
    ctx.run('nmcli connection delete "Bondy connection 1"')
    ctx.run('nmcli connection delete id gen-bond0 gen-bond0.0 gen-bond0.1')
    ctx.run('ip link del gen-bond')
    ctx.run('ip link del gen-bond0')


_register_tag("gen-bond_remove", None, gen_bond_remove_as)


def general_vlan_as(ctx, scen):
    ctx.run("sudo nmcli connection delete id eth8.100")
    ctx.run("sudo ip link del eth8.100")


_register_tag("general_vlan", None, general_vlan_as)


def tuntap_as(ctx, scen):
    ctx.run("ip link del tap0")
    ctx.run("nmcli con delete tap0")
    ctx.run("ip link del brY")
    ctx.run("ip link del brX")


_register_tag("tuntap", None, tuntap_as)


def slaves_as(ctx, scen):
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth1')
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth4')
    ctx.run('nmcli connection delete id bond0.0 bond0.1 bond0.2 bond-slave-eth1 bond-slave')


_register_tag("slaves", None, slaves_as)


def bond_order_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-bond.conf")
    nmci.lib.reload_NM_service(ctx)


_register_tag("bond_order", None, bond_order_as)


def con_as(ctx, scen):
    print("---------------------------")
    print("deleting connie")
    ctx.run("nmcli connection delete id connie")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/ifcfg-connie*")


_register_tag("con", None, con_as)


def remove_tombed_connections_as(ctx, scen):
    tombs = []
    for dir in ["/etc/NetworkManager/system-connections/*.nmmeta", "/var/run/NetworkManager/system-connections/*.nmmeta"]:
        ls, _, _ = ctx.run('ls %s' % dir, stderr=subprocess.PIPE)
        if ls:
            tombs.extend(ls.split("\n"))
    cons = []
    for tomb in tombs:
        print(tomb)
        con_id = tomb.split("/")[-1]
        con_id = con_id.split('.')[0]
        cons.append(con_id)
        print("removing tomb file %s" % tomb)
        ctx.run("rm -f %s" % tomb)
    if len(cons):
        print("removing connections: " + " ".join(cons))
        ctx.run("nmcli con reload")
        ctx.run("nmcli con delete %s" % " ".join(cons))


_register_tag("remove_tombed_connections", None, remove_tombed_connections_as)


def flush_300_as(ctx, scen):
    ctx.run("ip route flush table 300")


_register_tag("flush_300", None, flush_300_as)


def stop_radvd_as(ctx, scen):
    ctx.run("sudo systemctl stop radvd")
    ctx.run('rm -rf /etc/radvd.conf')


_register_tag("stop_radvd", None, stop_radvd_as)


def dcb_as(ctx, scen):
    ctx.run("nmcli connection delete id dcb")


_register_tag("dcb", None, dcb_as)


def mtu_as(ctx, scen):
    ctx.run("nmcli connection modify testeth1 802-3-ethernet.mtu 1500")
    ctx.run("nmcli connection up id testeth1")
    ctx.run("nmcli connection modify testeth1 802-3-ethernet.mtu 0")
    ctx.run("nmcli connection down id testeth1")
    ctx.run("ip link set dev eth1 mtu 1500")
    ctx.run("ip link set dev eth2 mtu 1500")
    ctx.run("ip link set dev eth3 mtu 1500")

    ctx.run("nmcli connection delete id tc1 tc2 tc16 tc26")
    ctx.run("ip link delete test1")
    ctx.run("ip link delete test2")
    ctx.run("ip link delete test10")
    ctx.run("ip link delete test11")
    ctx.run("ip link del vethbr")
    ctx.run("ip link del vethbr6")
    ctx.run("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')")
    ctx.run("kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')")


_register_tag("mtu", None, mtu_as)


def mtu_wlan0_as(ctx, scen):
    ctx.run('nmcli con add type wifi ifname wlan0 con-name qe-open autoconnect off ssid qe-open')
    ctx.run("nmcli connection modify qe-open 802-11-wireless.mtu 1500")
    ctx.run("nmcli connection up id qe-open")
    ctx.run("nmcli connection del id qe-open")


_register_tag("mtu_wlan0", None, mtu_wlan0_as)


def macsec_as(ctx, scen):
    ctx.run('sudo nmcli connection delete test-macsec test-macsec-base')
    ctx.run('sudo ip netns delete macsec_ns')
    ctx.run('sudo ip link delete macsec_veth')
    ctx.run("kill $(cat /tmp/wpa_supplicant_ms.pid)")
    ctx.run("kill $(cat /tmp/dnsmasq_ms.pid)")


_register_tag("macsec", None, macsec_as)


def two_bridged_veths_as(ctx, scen):
    ctx.run("nmcli connection delete id tc1 tc2")
    ctx.run("ip link del test1")
    ctx.run("ip link del test2")
    ctx.run("ip link del vethbr")
    ctx.run("nmcli con del tc1 tc2 vethbr")
    nmci.lib.unmanage_veths(ctx)


_register_tag("two_bridged_veths", None, two_bridged_veths_as)


def two_bridged_veths6_as(ctx, scen):
    ctx.run("nmcli connection delete id tc16 tc26 test10 test11 vethbr6")
    ctx.run("ip link del test11")
    ctx.run("ip link del test10")
    ctx.run("ip link del vethbr6")
    nmci.lib.unmanage_veths(ctx)


_register_tag("two_bridged_veths6", None, two_bridged_veths6_as)


def two_bridged_veths_gen_as(ctx, scen):
    ctx.run("ip link del test1g")
    ctx.run("ip link del test2g")
    ctx.run("ip link del vethbrg")
    ctx.run("nmcli con del test1g test2g tc1g tc2g vethbrg")
    time.sleep(1)


_register_tag("two_bridged_veths_gen", None, two_bridged_veths_gen_as)


def dhcpd_as(ctx, scen):
    ctx.run("sudo systemctl stop dhcpd")


_register_tag("dhcpd", None, dhcpd_as)


def modprobe_cfg_remove_as(ctx, scen):
    ctx.run("rm -rf /etc/modprobe.d/99-test.conf")


_register_tag("modprobe_cfg_remove", None, modprobe_cfg_remove_as)


def kill_dnsmasq_vlan_as(ctx, scen):
    ctx.run("kill $(cat /tmp/dnsmasq_vlan.pid)")


_register_tag("kill_dnsmasq_vlan", None, kill_dnsmasq_vlan_as)


def kill_dnsmasq_ip4_as(ctx, scen):
    ctx.run("kill $(cat /tmp/dnsmasq_ip4.pid)")


_register_tag("kill_dnsmasq_ip4", None, kill_dnsmasq_ip4_as)


def kill_dnsmasq_ip6_as(ctx, scen):
    ctx.run("kill $(cat /tmp/dnsmasq_ip6.pid)")


_register_tag("kill_dnsmasq_ip6", None, kill_dnsmasq_ip6_as)


def kill_dhcrelay_as(ctx, scen):
    ctx.run("kill $(cat /tmp/dhcrelay.pid)")


_register_tag("kill_dhcrelay", None, kill_dhcrelay_as)


def profie_as(ctx, scen):
    ctx.run("nmcli connection delete id profie")


_register_tag("profie", None, profie_as)


def peers_ns_as(ctx, scen):
    ctx.run("ip netns del peers")
    #sleep(TIMER)


_register_tag("peers_ns", None, peers_ns_as)


def tshark_as(ctx, scen):
    ctx.run("pkill tshark")
    ctx.run("rm -rf /etc/dhcp/dhclient-eth*.conf")


_register_tag("tshark", None, tshark_as)


def mac_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-mac.conf")
    nmci.lib.reload_NM_service(ctx)
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth1')


_register_tag("mac", None, mac_as)


def eth8_up_as(ctx, scen):
    nmci.lib.reset_hwaddr_nmcli(ctx, 'eth8')


_register_tag("eth8_up", None, eth8_up_as)


def keyfile_cleanup_as(ctx, scen):
    ctx.run("sudo sh -c \"rm /usr/lib/NetworkManager/system-connections/*\" ")
    ctx.run("sudo sh -c \"rm /etc/NetworkManager/system-connections/*\" ")


_register_tag("keyfile_cleanup", None, keyfile_cleanup_as)


def remove_dns_clean_as(ctx, scen):
    if ctx.command_code('grep dns /etc/NetworkManager/NetworkManager.conf') == 0:
        ctx.run("sudo sed -i 's/dns=none//' /etc/NetworkManager/NetworkManager.conf")
    ctx.run("sudo rm -rf /etc/NetworkManager/conf.d/90-test-dns-none.conf; sleep 1")
    nmci.lib.reload_NM_service(ctx)


_register_tag("remove_dns_clean", None, remove_dns_clean_as)


def restore_resolvconf_as(ctx, scen):
    ctx.run('rm -rf /etc/resolv.conf')
    if ctx.command_code("systemctl is-active systemd-resolved") == 0:
        ctx.run("ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf")
    ctx.run('rm -rf /tmp/resolv_orig.conf')
    ctx.run('rm -rf /tmp/resolv.conf')
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-resolv.conf")
    nmci.lib.reload_NM_service(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("restore_resolvconf", None, restore_resolvconf_as)


def device_connect_as(ctx, scen):
    ctx.run('nmcli connection delete testeth9 eth9')
    ctx.run('nmcli connection add type ethernet ifname eth9 con-name testeth9 autoconnect no')


_register_tag("device_connect", None, device_connect_as)
_register_tag("device_connect_no_profile", None, device_connect_as)


def restore_eth8_as(ctx, scen):
    ctx.run('sudo ip link del eth8.100')
    ctx.run('sudo rm -f /etc/sysconfig/network-scripts/ifcfg-testeth8')
    ctx.run('sudo nmcli connection reload')
    ctx.run('nmcli connection add type ethernet ifname eth8 con-name testeth8 autoconnect no')


_register_tag("restore_eth8", None, restore_eth8_as)


def restore_broken_network_as(ctx, scen):
    ctx.run('sudo systemctl stop network.service')
    ctx.run('sudo systemctl stop NetworkManager.service')
    ctx.run('sysctl net.ipv6.conf.all.accept_ra=1')
    ctx.run('sysctl net.ipv6.conf.default.accept_ra=1')
    nmci.lib.restart_NM_service(ctx)
    ctx.run('sudo nmcli connection down testeth8 testeth9')


_register_tag("restore_broken_network", None, restore_broken_network_as)


def add_testeth_as(num):
    def _add_testeth_as(ctx, scen):
        ctx.run('sudo nmcli connection delete eth%d testeth%d' % (num, num))
        ctx.run('sudo nmcli connection add type ethernet con-name testeth%d ifname eth%d autoconnect no' % (num, num))
    return _add_testeth_as


for i in [1, 5, 8, 10]:
    _register_tag("add_testeth%d" % i, None, add_testeth_as(i))


def eth_disconnect_as(num):
    def _eth_disconnect_as(ctx, scen):
        ctx.run('sudo nmcli device disconnect eth%d' % num)
        # VVV Up/Down to preserve autoconnect feature
        ctx.run('sudo nmcli connection up testeth%d' % num)
        ctx.run('sudo nmcli connection down testeth%d' % num)
    return _eth_disconnect_as


for i in [1, 2, 4, 5, 6, 8, 10]:
    _register_tag("eth%d_disconnect" % i, None, eth_disconnect_as(i))


def non_utf_device_as(ctx, scen):
    print("remove non utf-8 device")
    if sys.version_info.major < 3:
        ctx.run("ip link del $'d\xccf\\c'")
    else:
        ctx.run("ip link del $'d\\xccf\\\\c'")


_register_tag("non_utf_device", None, non_utf_device_as)


def shutdown_as(ctx, scen):
    print("sanitizing env")
    ctx.run('ip addr del 192.168.50.5/24 dev eth8')
    ctx.run('route del default gw 192.168.50.1 eth8')


_register_tag("shutdown", None, shutdown_as)


def connect_testeth0_as(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("connect_testeth0", None, connect_testeth0_as)


def kill_dbus_monitor_as(ctx, scen):
    ctx.run('pkill -9 dbus-monitor')


_register_tag("kill_dbus-monitor", None, kill_dbus_monitor_as)


def kill_children_as(ctx, scen):
    children = getattr(ctx, "children", [])
    if len(children):
        print('kill remaining children (%d)', len(children))
        for child in children:
            child.kill(9)


_register_tag("kill_children", None, kill_children_as)


def restore_rp_filters_as(ctx, scen):
    ctx.run('echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter')
    ctx.run('echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter')


_register_tag("restore_rp_filters", None, restore_rp_filters_as)


def remove_ctcdevice_as(ctx, scen):
    ctx.run("""znetconf -r $(znetconf -c |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }') -n""")
    time.sleep(1)


_register_tag("remove_ctcdevice", None, remove_ctcdevice_as)
