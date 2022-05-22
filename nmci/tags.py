# before/after scenario for tags
import os
import sys
import nmci
import subprocess
import time
import re
import shutil

import nmci.ip
import nmci.lib
import nmci.misc

TAG_FILE = "/tmp/nmci_tag_registry"
compiled_tags = False


class Tag:
    def __init__(self, tag_name, before_scenario=None, after_scenario=None, args={}):
        self.lineno = 0
        self.tag_name = tag_name
        self.args = args
        self._before_scenario = before_scenario
        self._after_scenario = after_scenario
        if self._before_scenario:
            self.lineno = self._before_scenario.__code__.co_firstlineno
        elif self._after_scenario:
            self.lineno = self._after_scenario.__code__.co_firstlineno

    def before_scenario(self, ctx, scen):
        if self._before_scenario is not None:
            self._before_scenario(ctx, scen, **self.args)

    def after_scenario(self, ctx, scen):
        if self._after_scenario is not None:
            self._after_scenario(ctx, scen, **self.args)


tag_registry = {}


def _register_tag(tag_name, before_scenario=None, after_scenario=None, args={}):
    assert tag_name not in tag_registry, "multiple definitions for tag '@%s'" % tag_name
    tag_registry[tag_name] = Tag(tag_name, before_scenario, after_scenario, args)


# tags that have efect outside this file
_register_tag("no_abrt")
_register_tag("xfail")
_register_tag("may_fail")
_register_tag("nmtui")


def temporary_skip_bs(ctx, scen):
    sys.exit(77)


_register_tag("temporary_skip", temporary_skip_bs)


def skip_restarts_bs(ctx, scen):
    if os.path.isfile("/tmp/nm_skip_restarts") or os.path.isfile("/tmp/nm_skip_STR"):
        print("skipping service restart tests as /tmp/nm_skip_restarts exists")
        sys.exit(77)


_register_tag("skip_str", skip_restarts_bs)


def long_bs(ctx, scen):
    if os.path.isfile("/tmp/nm_skip_long"):
        print("skipping long test case as /tmp/nm_skip_long exists")
        sys.exit(77)


_register_tag("long", long_bs)


def skip_in_centos_bs(ctx, scen):
    if "CentOS" in ctx.rh_release:
        print("skipping with centos")
        sys.exit(77)


_register_tag("skip_in_centos", skip_in_centos_bs)


def skip_in_kvm_bs(ctx, scen):
    if "kvm" in ctx.hypervisor:
        if ctx.arch != "x86_64":
            print("skipping on non x86_64 machine with kvm hypvervisor")
            sys.exit(77)


_register_tag("skip_in_kvm", skip_in_kvm_bs)


def arch_only_bs(ctx, scen, arch):
    if ctx.arch != arch:
        sys.exit(77)


def not_on_arch_bs(ctx, scen, arch):
    if ctx.arch == arch:
        sys.exit(77)


for arch in ["x86_64", "s390x", "ppc64", "ppc64le", "aarch64"]:
    _register_tag("not_on_" + arch, not_on_arch_bs, None, {"arch": arch})
    _register_tag(arch + "_only", arch_only_bs, None, {"arch": arch})


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
    ctx.pexpect_service("sudo prepare/gsm_sim.sh modemu")


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
    # get core pattern
    ctx.core_pattern = ctx.command_output("sysctl -n kernel.core_pattern")
    if "systemd-coredump" not in ctx.core_pattern:
        # search for core pattern it in sysctl.d, if not found use default
        if os.path.isfile("/usr/lib/sysctl.d/50-coredump.conf"):
            ctx.command_output("sysctl -p /usr/lib/sysctl.d/50-coredump.conf")
        else:
            systemd_core_pattern = (
                "|/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %e"
            )
            ctx.command_output(
                f"sysctl -w kernel.core_pattern='{systemd_core_pattern}'"
            )
    # unmask systemd-coredump.socket if needed
    out, _, rc = ctx.run("systemctl is-enabled systemd-coredump.socket")
    ctx.systemd_coredump_masked = rc != 0 and "masked" in out
    if ctx.systemd_coredump_masked:
        ctx.run("systemctl unmask systemd-coredump.socket")
        ctx.run("systemctl restart systemd-coredump.socket")
    # set core file size limit of Networkmanager (centos workaround)
    # ctx.run("prlimit --core=unlimited:unlimited --pid $(pidof NetworkManager)")


def crash_as(ctx, scen):
    assert nmci.lib.restart_NM_service(ctx)
    if "systemd-coredump" not in ctx.core_pattern:
        ctx.command_output(f"sysctl -w kernel.core_pattern='{ctx.core_pattern}'")
    if ctx.systemd_coredump_masked:
        ctx.run("systemctl stop systemd-coredump.socket")
        ctx.run("systemctl mask systemd-coredump.socket")


_register_tag("crash", crash_bs, crash_as)


def not_with_systemd_resolved_bs(ctx, scen):
    if ctx.command_code("systemctl is-active systemd-resolved") == 0:
        print("Skipping as systemd-resolved is running")
        sys.exit(77)


_register_tag("not_with_systemd_resolved", not_with_systemd_resolved_bs)


def not_under_internal_DHCP_bs(ctx, scen):
    if (
        "release 8" in ctx.rh_release
        and ctx.command_code("NetworkManager --print-config|grep dhclient") != 0
    ):
        sys.exit(77)
    if ctx.command_code("NetworkManager --print-config|grep internal") == 0:
        sys.exit(77)


_register_tag("not_under_internal_DHCP", not_under_internal_DHCP_bs)


def not_on_veth_bs(ctx, scen):
    if os.path.isfile("/tmp/nm_veth_configured"):
        sys.exit(77)


_register_tag("not_on_veth", not_on_veth_bs, None)


def regenerate_veth_as(ctx, scen):
    if os.path.isfile("/tmp/nm_veth_configured"):
        nmci.lib.check_vethsetup(ctx)
    else:
        print("up eth1-11 links")
        for link in range(1, 11):
            ctx.run("ip link set eth%d up" % link)


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


def _is_container():
    return os.path.isfile("/run/.containerenv")


def restart_if_needed_as(ctx, scen):
    if ctx.command_code("systemctl is-active NetworkManager") != 0:
        nmci.lib.restart_NM_service(ctx)
    if (
        not os.path.isfile("/tmp/nm_dcb_inf_wol_sriov_configured")
        and not _is_container()
    ):
        nmci.lib.wait_for_testeth0(ctx)


_register_tag("restart_if_needed", None, restart_if_needed_as)


def secret_key_reset_bs(ctx, scen):
    ctx.run(
        "mv /var/lib/NetworkManager/secret_key /var/lib/NetworkManager/secret_key_back"
    )


def secret_key_reset_as(ctx, scen):
    ctx.run(
        "mv /var/lib/NetworkManager/secret_key_back /var/lib/NetworkManager/secret_key"
    )


_register_tag("secret_key_reset", secret_key_reset_bs, secret_key_reset_as)


def tag1000_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("python -m pip install pyroute2 mitogen") != 0:
        print("installing pip and pyroute2")
        ctx.run(
            "yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/p/python2-pyroute2-0.4.13-1.el7.noarch.rpm"
        )


def tag1000_as(ctx, scen):
    ctx.run("ip link del bridge0")
    ctx.run("for i in $(seq 0 1000); do ip link del port$i ; done")


_register_tag("1000", tag1000_bs, tag1000_as)


def many_vlans_bs(ctx, scen):
    nmci.lib.manage_veths(ctx)
    ctx.run("sh prepare/vlans.sh clean")
    os.environ["N_VLANS"] = "500" if ctx.arch == "x86_64" else "200"
    # We need NM to sanitize itself a bit
    time.sleep(20)


def many_vlans_as(ctx, scen):
    ctx.run("sh prepare/vlans.sh clean")
    nmci.lib.unmanage_veths(ctx)


_register_tag("many_vlans", many_vlans_bs, many_vlans_as)


def remove_vlan_range(ctx, scen):
    vlan_range = getattr(ctx, "vlan_range", None)
    if vlan_range is None:
        return

    # remove vlans and bridgess
    ip_cleanup_cmd = "; ".join((f"ip link del {dev}" for dev in vlan_range))
    ctx.run(ip_cleanup_cmd)

    # remove ifcfg (if any)
    ifcfg_list = " ".join(
        (f"/etc/sysconfig/network-scripts/ifcfg-{dev}" for dev in vlan_range)
    )
    ctx.run("rm -rvf " + ifcfg_list)

    # remove keyfile (if any)
    keyfile_list = " ".join(
        (f"/etc/NetworkManager/system-connections/{dev}*" for dev in vlan_range)
    )
    ctx.run("rm -rvf " + keyfile_list)

    nmci.lib.restart_NM_service(ctx)


_register_tag("remove_vlan_range", None, remove_vlan_range)


def captive_portal_bs(ctx, scen):
    # do not capture output, let it log to the console, otherwise this hangs!
    ctx.pexpect_service("sudo prepare/captive_portal.sh")


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

    if not os.path.isfile("/tmp/usb_hub"):
        ctx.run("sh prepare/initialize_modem.sh")
        # OBSOLETE: 2021/08/05
        # import time
        # dir = "/mnt/scratch/"
        # timeout = 3600
        # initialized = False
        # freq = 30
        #
        # while(True):
        #     print("* looking for gsm lock in nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock")
        #     lock = nmci.lib.get_lock(dir)
        #     if not lock:
        #         if not initialized:
        #             initialized = nmci.lib.reinitialize_devices()
        #         if nmci.lib.create_lock(dir):
        #             break
        #         else:
        #             continue
        #     if lock:
        #         if nmci.lib.is_lock_old(lock):
        #             nmci.lib.delete_old_lock(dir, lock)
        #             continue
        #         else:
        #             timeout -= freq
        #             print(" ** still locked.. wating %s seconds before next try" % freq)
        #             if not initialized:
        #                 initialized = nmci.lib.reinitialize_devices()
        #             time.sleep(freq)
        #             if timeout == 0:
        #                 raise Exception("Timeout reached!")
        #             continue

    ctx.run("nmcli con down testeth0")


def gsm_as(ctx, scen):
    # You can debug here only with console connection to the testing machine.
    # SSH connection is interrupted.
    # import ipdb
    ctx.run("nmcli connection delete gsm")
    ctx.run("rm -rf /etc/NetworkManager/system-connections/gsm")
    nmci.lib.wait_for_testeth0(ctx)

    # OBSOLETE: 2021/08/05
    # if not os.path.isfile('/tmp/usb_hub'):
    #     ctx.run('mount -o remount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch')
    #     nmci.lib.delete_old_lock("/mnt/scratch/", nmci.lib.get_lock("/mnt/scratch"))

    # Attach journalctl logs
    ctx.run(
        "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ MM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log"
    )
    ctx.run(
        "sudo journalctl -u ModemManager --no-pager -o cat %s >> /tmp/journal-mm.log"
        % ctx.log_cursor
    )
    data = nmci.lib.utf_only_open_read("/tmp/journal-mm.log")
    if data:
        print("embed ModemManager log")
        ctx.embed("text/plain", data, caption="MM")
    # Extract modem model.
    # Example: 'USB ID 1c9e:9603 Zoom 4595' -> 'Zoom 4595'
    regex = r"USB ID (\w{4}:\w{4}) (.*)"
    mo = re.search(regex, ctx.modem_str)
    if mo:
        modem_model = mo.groups()[1]
        cap = modem_model
    else:
        cap = "MODEM INFO"

    modem_info = nmci.lib.get_modem_info(ctx)
    if modem_info:
        print("embed modem_info")
        ctx.embed("text/plain", modem_info, caption=cap)


_register_tag("gsm", gsm_bs, gsm_as)


def unmanage_eth_bs(ctx, scen):
    links = nmci.lib.get_ethernet_devices(ctx)
    for link in links:
        ctx.run("nmcli dev set %s managed no" % link)


def unmanage_eth_as(ctx, scen):
    links = nmci.lib.get_ethernet_devices(ctx)
    for link in links:
        ctx.run("nmcli dev set %s managed yes" % link)


_register_tag("unmanage_eth", unmanage_eth_bs, unmanage_eth_as)


def manage_eth8_as(ctx, scen):
    ctx.run("sudo nmcli device set eth8 managed true")


_register_tag("manage_eth8", None, manage_eth8_as)


def connectivity_bs(ctx, scen):
    ctx.run("echo '[connectivity]' > /etc/NetworkManager/conf.d/99-connectivity.conf")
    if "captive_portal" in scen.tags:
        ctx.run(
            "echo 'uri=http://static.redhat.com:8001/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf"
        )
    else:
        ctx.run(
            "echo 'uri=http://static.redhat.com/test/rhel-networkmanager.txt' >> /etc/NetworkManager/conf.d/99-connectivity.conf"
        )
    ctx.run("echo 'response=OK' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    # Change in interval  would affect connectivity tests and captive portal tests too
    ctx.run("echo 'interval=10' >> /etc/NetworkManager/conf.d/99-connectivity.conf")
    nmci.lib.reload_NM_service(ctx)


def connectivity_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-connectivity.conf")
    ctx.run("rm -rf /var/lib/NetworkManager/NetworkManager-intern.conf")
    ctx.execute_steps("* Reset /etc/hosts")

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
    # ctx.run("rm -rf /tmp/dispatcher.txt")
    ctx.run("nmcli con down testeth1")
    ctx.run("nmcli con down testeth2")
    nmci.lib.reload_NM_service(ctx)


_register_tag("disp", disp_bs, disp_as)


def eth0_bs(ctx, scen):
    skip_restarts_bs(ctx, scen)
    # if ctx.IS_NMTUI:
    #    ctx.run("nmcli connection down id testeth0")
    #    time.sleep(1)
    #    if ctx.command_code("nmcli -f NAME c sh -a |grep eth0") == 0:
    #        print("shutting down eth0 once more as it is not down")
    #        ctx.run("nmcli device disconnect eth0")
    #        time.sleep(2)
    ctx.run("nmcli con down testeth0")
    ctx.run("nmcli con down testeth1")
    ctx.run("nmcli con down testeth2")


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
    # ctx.run('sudo nmcli con add type ethernet ifname eth7 con-name testeth7 autoconnect no')
    # sleep(TIMER)


_register_tag("alias", alias_bs, alias_as)


def netcat_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if not os.path.isfile("/usr/bin/nc"):
        print("installing netcat")
        ctx.run("sudo yum -y install nmap-ncat")


_register_tag("netcat", netcat_bs)


def scapy_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if not os.path.isfile("/usr/bin/scapy"):
        print("installing scapy and tcpdump")
        ctx.run("yum -y install tcpdump")
        ctx.run("python -m pip install scapy")


def scapy_as(ctx, scen):
    ctx.run("ip link delete test10")
    ctx.run("ip link delete test11")
    ctx.run("nmcli connection delete ethernet-test10 ethernet-test11")


_register_tag("scapy", scapy_bs, scapy_as)


def mock_bs(ctx, scen):
    if ctx.command_code("rpm -q --quiet dbus-x11") != 0:
        print("installing dbus-x11, pip, and python-dbusmock==0.26.1 dataclasses")
        ctx.run("yum -y install dbus-x11")
    ctx.run("sudo python3 -m pip install python-dbusmock==0.26.1 dataclasses")
    ctx.run("./contrib/dbusmock/patch-python-dbusmock.sh")


_register_tag("mock", mock_bs)


def IPy_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("rpm -q --quiet dbus-x11") != 0:
        print("installing dbus-x11")
        ctx.run("yum -y install dbus-x11")
    if ctx.command_code("python -m pip list |grep IPy") != 0:
        print("installing IPy")
        ctx.run("sudo python -m pip install IPy")


_register_tag("IPy", IPy_bs)


def netaddr_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("python -m pip list |grep netaddr") != 0:
        print("install netaddr")
        ctx.run("sudo python -m pip install netaddr")


_register_tag("netaddr", netaddr_bs)


def inf_bs(ctx, scen):
    ctx.run("nmcli device disconnect inf_ib0")
    ctx.run("nmcli device disconnect inf_ib0.8002")
    ctx.run("nmcli connection delete inf_ib0.8002")
    ctx.run(
        "nmcli connection delete id infiniband-inf_ib0.8002 inf.8002 inf inf2 infiniband-inf_ib0 infiniband"
    )


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
    ctx.run(
        "printf '# configured by beaker-test\n[main]\ndns=dnsmasq\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf"
    )
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin = "dnsmasq"


def dns_dnsmasq_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dns.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.dns_plugin = ""
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
    ctx.run(
        "printf '# configured by beaker-test\n[main]\ndns=systemd-resolved\n' > /etc/NetworkManager/conf.d/99-xtest-dns.conf"
    )
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
    ctx.run(
        "printf '# configured by beaker-test\n[main]\ndhcp=internal\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf"
    )
    nmci.lib.restart_NM_service(ctx)


def internal_DHCP_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-internal.conf")
    nmci.lib.restart_NM_service(ctx)


_register_tag("internal_DHCP", internal_DHCP_bs, internal_DHCP_as)


def dhclient_DHCP_bs(ctx, scen):
    ctx.run(
        "printf '# configured by beaker-test\n[main]\ndhcp=dhclient\n' > /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf"
    )
    nmci.lib.restart_NM_service(ctx)


def dhclient_DHCP_as(ctx, scen):
    ctx.run("rm -f /etc/NetworkManager/conf.d/99-xtest-dhcp-dhclient.conf")
    nmci.lib.restart_NM_service(ctx)


_register_tag("dhclient_DHCP", dhclient_DHCP_bs, dhclient_DHCP_as)


def delete_testeth0_bs(ctx, scen):
    skip_restarts_bs(ctx, scen)
    ctx.run("nmcli device disconnect eth0")
    ctx.run("nmcli connection delete id testeth0")


def delete_testeth0_as(ctx, scen):
    ctx.run("sudo nmcli connection delete eth0")
    nmci.lib.restore_testeth0(ctx)


_register_tag("delete_testeth0", delete_testeth0_bs, delete_testeth0_as)


def ethernet_bs(ctx, scen):
    if (
        ctx.command_code("nmcli con |grep testeth1") == 0
        or ctx.run("nmcli con |grep testeth2") == 0
    ):
        print("sanitizing eth1 and eth2")
        ctx.run("sudo nmcli con del testeth1 testeth2")
        ctx.run(
            "sudo nmcli con add type ethernet ifname eth1 con-name testeth1 autoconnect no"
        )
        ctx.run(
            "sudo nmcli con add type ethernet ifname eth2 con-name testeth2 autoconnect no"
        )


_register_tag("ethernet", ethernet_bs, None)


def ifcfg_rh_bs(ctx, scen):
    _, nm_ver = nmci.misc.nm_version_detect()
    if (
        nm_ver >= [1, 36]
        and ctx.command_code("rpm -q Networkmanager-initscripts-updown") != 0
    ):
        print("install NetworkManager-initscripts-updown")
        ctx.run("dnf install -y NetworkManager-initscripts-updown")
    if ctx.command_code("NetworkManager --print-config |grep '^plugins=ifcfg-rh'") != 0:
        print("setting ifcfg-rh plugin")
        # VV Do not lower this as some devices can be still going down
        time.sleep(0.5)
        ctx.run(
            "printf '# configured by beaker-test\n[main]\nplugins=ifcfg-rh\n' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
        )
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
        ctx.run("sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf")
        nmci.lib.restart_NM_service(ctx)
        if ctx.IS_NMTUI:
            # if 'simwifi' in scen.tags:
            #     nmci.lib.wifi_rescan()
            time.sleep(4)
        time.sleep(0.5)


_register_tag("ifcfg-rh", ifcfg_rh_bs, ifcfg_rh_as)


def keyfile_bs(ctx, scen):
    _, nm_ver = nmci.misc.nm_version_detect()
    if (
        nm_ver >= [1, 36]
        and ctx.command_code("rpm -q Networkmanager-initscripts-updown") != 0
    ):
        print("install NetworkManager-initscripts-updown")
        ctx.run("dnf install -y NetworkManager-initscripts-updown")
    if ctx.command_code("NetworkManager --print-config |grep '^plugins=keyfile'") != 0:
        print("setting keyfile plugin")
        # VV Do not lower this as some devices can be still going down
        time.sleep(0.5)
        ctx.run(
            "printf '# configured by beaker-test\n[main]\nplugins=ifcfg-rh\n' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
        )
        nmci.lib.restart_NM_service(ctx)
        if ctx.IS_NMTUI:
            # comment out wifi_rescan, as simwifi prepare not done yet
            # if "simwifi" in scen.tags:
            #     nmci.lib.wifi_rescan()
            # VV Do not lower this as nmtui can be behaving weirdly
            time.sleep(4)
        time.sleep(0.5)


def keyfile_as(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-xxcustom.conf"):
        print("resetting ifcfg plugin")
        ctx.run("sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf")
        nmci.lib.restart_NM_service(ctx)
        if ctx.IS_NMTUI:
            # if 'simwifi' in scen.tags:
            #     nmci.lib.wifi_rescan()
            time.sleep(4)
        time.sleep(0.5)


_register_tag("keyfile", keyfile_bs, keyfile_as)


def plugin_default_bs(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-test.conf"):
        print("remove 'plugins=*' from 99-test.conf")
        assert (
            ctx.command_code(
                "cp /etc/NetworkManager/conf.d/99-test.conf /tmp/99-test.conf"
            )
            == 0
        ), "unable to backup 99-test.conf"
        assert (
            ctx.command_code(
                "sed -i 's/^plugins=/#plugins=/' /etc/NetworkManager/conf.d/99-test.conf"
            )
            == 0
        ), "unable to modify '99-test.conf'"
        nmci.lib.restart_NM_service(ctx)


def plugin_default_as(ctx, scen):
    if os.path.isfile("/etc/NetworkManager/conf.d/99-test.conf"):
        print("restore 99-test.conf")
        assert (
            ctx.command_code(
                "mv /tmp/99-test.conf /etc/NetworkManager/conf.d/99-test.conf"
            )
            == 0
        ), "unable to restore '99-test.conf'"
        nmci.lib.restart_NM_service(ctx)


_register_tag("plugin_default", plugin_default_bs, plugin_default_as)


def eth3_disconnect_bs(ctx, scen):
    ctx.run("sudo nmcli device disconnect eth3")
    ctx.run("sudo kill -9 $(cat /var/run/dhclient-eth3.pid)")


def eth3_disconnect_as(ctx, scen):
    ctx.run("sudo nmcli device disconnect eth3")
    # VVV Up/Down to preserve autoconnect feature
    ctx.run("sudo nmcli connection up testeth3")
    ctx.run("sudo nmcli connection down testeth3")


_register_tag("eth3_disconnect", eth3_disconnect_bs, eth3_disconnect_as)


def need_dispatcher_scripts_bs(ctx, scen):
    if os.path.isfile("/tmp/nm-builddir"):
        print("install dispatcher scripts")
        ctx.run(
            "yum install -y $(cat /tmp/nm-builddir)/noarch/NetworkManager-dispatcher-routing-rules*"
        )
    else:
        nmci.lib.wait_for_testeth0(ctx)
        print("install NetworkManager-config-routing-rules")
        ctx.run("yum -y install NetworkManager-config-routing-rules")
    nmci.lib.reload_NM_service(ctx)


def need_dispatcher_scripts_as(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    ctx.run("yum -y remove NetworkManager-config-routing-rules ")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/rule-con_general")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/route-con_general")
    ctx.run("ip rule del table 1; ip rule del table 1")
    nmci.lib.reload_NM_service(ctx)


_register_tag(
    "need_dispatcher_scripts", need_dispatcher_scripts_bs, need_dispatcher_scripts_as
)


def need_legacy_crypto_bs(ctx, scen):
    # We have openssl3 in RHEL9 with a bunch of algs deprecated
    if "release 9" in ctx.rh_release:
        pass
        # hostapd and wpa_supplicant 2.10+ can enforce this w/o config
        # ctx.run("sed '-i.bak' s/'^##'/''/g /etc/pki/tls/openssl.cnf")
        # if '8021x' in scen.tags:
        #     ctx.run("systemctl restart wpa_supplicant")
        #     ctx.run("systemctl restart nm-hostapd")


def need_legacy_crypto_as(ctx, scen):
    if "release 9" in ctx.rh_release:
        pass
        # hostapd and wpa_supplicant 2.10+ can enforce this w/o config
        # ctx.run("mv -f /etc/pki/tls/openssl.cnf.bak /etc/pki/tls/openssl.cnf")
        # if '8021x' in scen.tags:
        #     ctx.run("systemctl restart wpa_supplicant")
        #     ctx.run("systemctl restart nm-hostapd")


_register_tag("need_legacy_crypto", need_legacy_crypto_bs, need_legacy_crypto_as)


def logging_bs(ctx, scen):
    ctx.loggin_level = ctx.command_output("nmcli -t -f LEVEL general logging").strip()


def logging_as(ctx, scen):
    print("---------------------------")
    print("setting log level back")
    ctx.run("sudo nmcli g log level %s domains ALL" % ctx.loggin_level)


_register_tag("logging", logging_bs, logging_as)


def remove_custom_cfg_as(ctx, scen):
    ctx.run("sudo rm -f /etc/NetworkManager/conf.d/99-xxcustom.conf")
    nmci.lib.restart_NM_service(ctx)


_register_tag("remove_custom_cfg", None, remove_custom_cfg_as)


def netservice_bs(ctx, scen):
    ctx.run("sudo pkill -9 /sbin/dhclient")
    # Make orig- devices unmanaged as they may be unfunctional
    ctx.run(
        "for dev in $(nmcli  -g DEVICE d |grep orig); do nmcli device set $dev managed off; done"
    )
    nmci.lib.restart_NM_service(ctx)
    ctx.run("sudo systemctl restart network.service")
    ctx.run("nmcli connection up testeth0")
    time.sleep(1)


def netservice_as(ctx, scen):
    ctx.run(
        "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ NETWORK SRV LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-netsrv.log"
    )
    ctx.run(
        "sudo journalctl -u network --no-pager -o cat %s >> /tmp/journal-netsrv.log"
        % ctx.log_cursor
    )

    data = nmci.lib.utf_only_open_read("/tmp/journal-netsrv.log")
    if data:
        print("Attaching network.service log")
        ctx.embed("text/plain", data, caption="NETSRV")


_register_tag("netservice", netservice_bs, netservice_as)


def tag8021x_bs(ctx, scen):
    if not os.path.isfile("/tmp/nm_8021x_configured"):
        if ctx.arch == "s390x":
            print("install hostapd.el7 on s390x")
            ctx.run(
                "[ -x /usr/sbin/hostapd ] || (yum -y install 'https://vbenes.fedorapeople.org/NM/hostapd-2.6-7.el7.s390x.rpm'; time.sleep 10)"
            )
        nmci.lib.setup_hostapd(ctx)


_register_tag("8021x", tag8021x_bs)


def tag8021x_as(ctx, scen):
    nmci.lib.teardown_hostapd(ctx)


_register_tag("8021x_teardown", None, tag8021x_as)


def pkcs11_bs(ctx, scen):
    nmci.lib.setup_pkcs11(ctx)
    ctx.command_output("p11-kit list-modules")
    ctx.command_output("softhsm2-util --show-slots")
    ctx.command_output(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so --token-label nmci -l --pin 1234 -O"
    )


_register_tag("pkcs11", pkcs11_bs)


def simwifi_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)
    args = ["namespace"]
    if "need_legacy_crypto" in scen.tags:
        args.append("legacy_crypto")
    nmci.lib.setup_hostapd_wireless(ctx, args)


def simwifi_as(ctx, scen):
    if ctx.IS_NMTUI:
        print("deleting all wifi connections")
        ctx.run(
            "nmcli con del uuid $(nmcli -t -f uuid,type con show | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//g' )"
        )
        nmci.lib.wait_for_testeth0(ctx)


_register_tag("simwifi", simwifi_bs, simwifi_as)


def simwifi_ap_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)

    ctx.run("modprobe -r mac80211_hwsim")
    ctx.run("modprobe mac80211_hwsim")
    ctx.run("systemctl restart wpa_supplicant")
    assert nmci.lib.restart_NM_service(ctx, reset=False), "NM stop failed"


def simwifi_ap_as(ctx, scen):
    ctx.run("modprobe -r mac80211_hwsim")
    ctx.run("systemctl restart wpa_supplicant")
    assert nmci.lib.restart_NM_service(ctx, reset=False), "NM stop failed"


_register_tag("simwifi_ap", simwifi_ap_bs, simwifi_ap_as)


def simwifi_p2p_bs(ctx, scen):
    if ctx.arch != "x86_64":
        print("Skipping as not on x86_64")
        sys.exit(77)

    if (
        ctx.rh_release_num >= 8
        and ctx.rh_release_num <= 8.4
        and "Stream" not in ctx.rh_release
    ):
        ctx.run(
            "dnf -4 -y install "
            "https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.7-2.2.bz1693684.el8.x86_64.rpm "
            "https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.7-2.2.bz1693684.el8.x86_64.rpm "
        )
        ctx.run("systemctl restart wpa_supplicant")

    if ctx.command_code("ls /tmp/nm_*_supp_configured") == 0:
        print(" ** need to remove previous setup")
        nmci.lib.teardown_hostapd_wireless(ctx)

    ctx.run("modprobe -r mac80211_hwsim")
    time.sleep(1)

    # This should be good as dynamic addresses are now used
    # ctx.run("echo -e '[device-wifi]\nwifi.scan-rand-mac-address=no' > /etc/NetworkManager/conf.d/99-wifi.conf")
    # ctx.run("echo -e '[connection-wifi]\nwifi.cloned-mac-address=preserve' >> /etc/NetworkManager/conf.d/99-wifi.conf")

    # this need to be done before NM restart, otherwise there is a race between NM and wpa_supp
    ctx.run("systemctl restart wpa_supplicant")
    # This is workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1752780
    ctx.run(
        "echo -e '[device]\nmatch-device=interface-name:wlan1\nmanaged=0' > /etc/NetworkManager/conf.d/99-wifi.conf"
    )
    nmci.lib.restart_NM_service(ctx)

    ctx.run("modprobe mac80211_hwsim")
    time.sleep(3)


def simwifi_p2p_as(ctx, scen):
    print("---------------------------")
    if (
        ctx.rh_release_num >= 8
        and ctx.rh_release_num <= 8.4
        and "Stream" not in ctx.rh_release
    ):
        if arch == "x86_64":
            print("Install patched wpa_supplicant for x86_64")
            ctx.run(
                "dnf -4 -y install https://vbenes.fedorapeople.org/NM/WPA3/wpa_supplicant{,-debuginfo,-debugsource}-2.9-8.el8.$(arch).rpm"
            )
        else:
            print("Install patched wpa_supplicant")
            ctx.run(
                "dnf -4 -y install https://vbenes.fedorapeople.org/NM/rhbz1888051/wpa_supplicant{,-debuginfo,-debugsource}-2.9-3.el8.$(arch).rpm"
            )
        ctx.run("dnf -y update wpa_supplicant")
        ctx.run("systemctl restart wpa_supplicant")
    ctx.run("modprobe -r mac80211_hwsim")
    ctx.run("kill -9 $(ps aux|grep wpa_suppli |grep wlan1 |awk '{print $2}')")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-wifi.conf")

    nmci.lib.restart_NM_service(ctx)


_register_tag("simwifi_p2p", simwifi_p2p_bs, simwifi_p2p_as)


def simwifi_teardown_bs(ctx, scen):
    nmci.lib.teardown_hostapd_wireless(ctx)
    nmci.lib.wait_for_testeth0(ctx)
    sys.exit(77)


_register_tag("simwifi_teardown", simwifi_teardown_bs)


def vpnc_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        sys.exit(77)
    # Install under RHEL7 only
    if "Maipo" in ctx.rh_release:
        print("install epel-release-7")
        ctx.run(
            "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
        )
    if ctx.command_code("rpm -q NetworkManager-vpnc") != 0:
        print("install NetworkManager-vpnc")
        ctx.run("sudo yum -y install NetworkManager-vpnc")
        nmci.lib.restart_NM_service(ctx)
    nmci.lib.setup_racoon(ctx, mode="aggressive", dh_group=2)


def vpnc_as(ctx, scen):
    ctx.run("nmcli connection delete vpnc")
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
        ctx.run(
            "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
        )
    if not os.path.isfile("/usr/bin/tcpreplay"):
        print("install tcpreplay")
        ctx.run("yum -y install tcpreplay")


_register_tag("tcpreplay", tcpreplay_bs)


def libreswan_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    if ctx.command_code("rpm -q NetworkManager-libreswan") != 0:
        ctx.run("sudo yum -y install NetworkManager-libreswan")
        nmci.lib.restart_NM_service(ctx)

    # We need libreswan at least of version 3.17, that contains
    # commit 453167 ("pluto: ignore tentative and failed IPv6 addresses),
    # otherwise pluto would get very very confused.
    # That is RHEL 7.4, RHEL 8.0 or newer.
    swan_ver = ctx.command_output("rpm -q --qf '%{version}' libreswan")
    if (
        ctx.command_code(
            """rpm --eval '%%{lua:
        if rpm.vercmp(\"%s\", \"3.17\") < 0 then
            error(\"Libreswan too old\");
        end }'"""
            % swan_ver
        )
        != 0
    ):
        print("Skipping with old Libreswan")
        sys.exit(77)

    ctx.run("/usr/sbin/ipsec --checknss")
    mode = "aggressive"
    if "ikev2" in scen.tags:
        mode = "ikev2"
    if "main" in scen.tags:
        mode = "main"
    nmci.lib.setup_libreswan(ctx, mode, dh_group=14)


def libreswan_as(ctx, scen):
    ctx.run("nmcli connection down libreswan")
    ctx.run("nmcli connection delete libreswan")
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
    ctx.run("nmcli connection delete openvpn")
    ctx.run("nmcli connection delete tun0")
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
    ctx.run("nmcli connection down strongswan")
    ctx.run("nmcli connection delete strongswan")
    nmci.lib.teardown_strongswan(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("strongswan", strongswan_bs, strongswan_as)


def vpn_as(ctx, scen):
    ctx.run("nmcli connection delete vpn")


_register_tag("vpn", None, vpn_as)


def iptunnel_bs(ctx, scen):
    # Workaround for 1869538
    ctx.run("modprobe -r xfrm_interface")
    ctx.run("sh prepare/iptunnel.sh")


def iptunnel_as(ctx, scen):
    ctx.run("sh prepare/iptunnel.sh teardown")


_register_tag("iptunnel", iptunnel_bs, iptunnel_as)


def wireguard_bs(ctx, scen):
    stdout, stderr, rc = ctx.run("sh prepare/wireguard.sh")
    if rc != 0:
        assert False, "wireguard setup failed with exitcode: %d\nOutput:\n\n%s" % (
            rc,
            stdout,
        )


_register_tag("wireguard", wireguard_bs, None)


def dracut_bs(ctx, scen):
    # log dracut version to "Commands"
    ctx.run("rpm -qa | grep dracut | sort")

    rc = ctx.command_code(
        "cd contrib/dracut; . ./setup.sh ; set -x; "
        " { time test_setup ; } &> /tmp/dracut_setup.log",
        shell=True,
    )
    nmci.lib.embed_file_if_exists(
        ctx, "/tmp/dracut_setup.log", caption="Dracut setup", fail_only=False
    )
    if rc != 0:
        print("dracut setup failed, doing clean !!!")
        ctx.run(
            "cd contrib/dracut; . ./setup.sh ;"
            "{ time test_clean; } &> /tmp/dracut_teardown.log",
            shell=True,
        )
        nmci.lib.embed_file_if_exists(
            ctx, "/tmp/dracut_teardown.log", caption="Dracut teardown", fail_only=False
        )
        assert False, "dracut setup failed"


def dracut_as(ctx, scen):
    # clean an umount client_dumps
    ctx.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "rm -rf $TESTDIR/client_dumps/*; "
        "umount $DEV_DUMPS; "
        "umount $DEV_LOG; "
    )
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


def dracut_remote_NFS_clean_as(ctx, scen):
    # keep nfs service stopped as it hangs rm commands for 90s
    ctx.run(
        ". contrib/dracut/setup.sh; "
        "systemctl stop nfs-server.service; "
        "rm -vrf $TESTDIR/nfs/client/etc/NetworkManager/system-connections/*; "
        "rm -vrf $TESTDIR/nfs/client/etc/NetworkManager/conf.d/50-*; "
        "rm -vrf $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-*; "
        "systemctl start nfs-server.service; "
    )


_register_tag("dracut_remote_NFS_clean", None, dracut_remote_NFS_clean_as)


def prepare_patched_netdevsim_bs(ctx, scen):
    rc = ctx.command_code("sh prepare/netdevsim.sh setup")
    assert rc == 0, "netdevsim setup failed with exitcode: %d" % rc
    nmci.ip.link_set(ifname="eth11", up=True, wait_for_device=1)
    nmci.ip.link_show(ifname="eth11", flags="LOWER_UP", timeout=1)


def prepare_patched_netdevsim_as(ctx, scen):
    ctx.run("sh prepare/netdevsim.sh teardown")


_register_tag(
    "prepare_patched_netdevsim",
    prepare_patched_netdevsim_bs,
    prepare_patched_netdevsim_as,
)


def load_netdevsim_bs(ctx, scen):
    ctx.run("modprobe -r netdevsim; modprobe netdevsim")
    ctx.run("echo 1 1 > /sys/bus/netdevsim/new_device ; sleep 1")


def load_netdevsim_as(ctx, scen):
    ctx.run("modprobe -r netdevsim; sleep 1")


_register_tag("load_netdevsim", load_netdevsim_bs, load_netdevsim_as)


def attach_hostapd_log_as(ctx, scen):
    if scen.status == "failed" or ctx.DEBUG:
        ctx.run(
            "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ HOSTAPD LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-hostapd.log"
        )
        confs, _, _ = ctx.run("ls /etc/hostapd/wire* | sort -V")
        services = []
        for conf in confs.strip("\n").split("\n"):
            ext = conf.split(".")[-1]
            if ext == "conf":
                services.append("nm-hostapd")
            elif len(ext):
                services.append("nm-hostapd-" + ext)
        if len(services) == 0:
            ctx.run(
                "echo 'did not find any nm-hostapd service!' >> /tmp/journal-hostapd.log"
            )
        for service in services:
            ctx.run("echo -e '\n\n~~~ %s ~~~' >> /tmp/journal-hostapd.log" % service)
            ctx.run(
                "journalctl -u %s --no-pager -o short-unix --no-hostname %s >> /tmp/journal-hostapd.log"
                % (service, ctx.log_cursor_before_tags)
            )
        data = nmci.lib.utf_only_open_read("/tmp/journal-hostapd.log")
        if data:
            print("Attaching hostapd log")
            ctx.embed("text/plain", data, caption="HOSTAPD")


_register_tag("attach_hostapd_log", None, attach_hostapd_log_as)


def attach_wpa_supplicant_log_as(ctx, scen):
    if scen.status == "failed" or ctx.DEBUG:
        ctx.run(
            "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ WPA_SUPPLICANT LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-wpa_supplicant.log"
        )
        ctx.run(
            "journalctl -u wpa_supplicant --no-pager -o short-unix --no-hostname %s >> /tmp/journal-wpa_supplicant.log"
            % ctx.log_cursor_before_tags
        )
        data = nmci.lib.utf_only_open_read("/tmp/journal-wpa_supplicant.log")
        if data:
            print("Attaching wpa_supplicant log")
            ctx.embed("text/plain", data, caption="WPA_SUP")


_register_tag("attach_wpa_supplicant_log", None, attach_wpa_supplicant_log_as)


def performance_bs(ctx, scen):
    # Set machine perf to max
    ctx.process.run("systemctl start tuned", ignore_stderr=True)
    ctx.process.run("tuned-adm profile throughput-performance", ignore_stderr=True)
    ctx.process.run("systemctl stop tuned", ignore_stderr=True)
    ctx.process.run("systemctl stop openvswitch", ignore_stderr=True)
    # Set some speed factor
    ctx.machine_speed_factor = 1
    hostname = ctx.command_output("hostname").strip()
    if "ci.centos" in hostname:
        print("CentOS: should be 2 times faster")
        ctx.machine_speed_factor = 0.5
    elif hostname.startswith("gsm-r5s"):
        print("gsm-r5s: keeping default")
    elif hostname.startswith("wlan-r6s"):
        print("wlan-r6s: keeping the default")
    elif hostname.startswith("gsm-r6s"):
        print("gsm-r6s: multiply factor by 1.5")
        ctx.machine_speed_factor = 1.5
    elif hostname.startswith("wsfd-netdev"):
        print("wsfd-netdev: we are unpredictable here, skipping")
        sys.exit(77)
    else:
        print(f"Unmatched: {hostname}: keeping default")
    if "fedora" in ctx.rh_release.lower():
        print("Fedora: multiply factor by 1.5")
        ctx.machine_speed_factor *= 1.5


def performance_as(ctx, scen):
    ctx.nm_restarted = True
    # Settings device number to 0
    ctx.run("contrib/gi/./setup.sh 0")
    ctx.nm_pid = nmci.lib.nm_pid()
    # Deleting all connections
    cons = ""
    for i in range(1, 101):
        cons = cons + ("t-a%s " % i)
    command = "nmcli con del %s" % cons
    ctx.process.run(command)
    # setup.sh masks dispatcher scripts
    ctx.process.run("systemctl unmask NetworkManager-dispatcher", ignore_stderr=True)
    # reset the performance profile
    ctx.process.run("systemctl start tuned", ignore_stderr=True)
    ctx.process.run("tuned-adm profile $(tuned-adm recommend)", ignore_stderr=True)
    ctx.process.run("systemctl start openvswitch", ignore_stderr=True)


_register_tag("performance", performance_bs, performance_as)


def preserve_8021x_certs_bs(ctx, scen):
    assert (
        ctx.command_code("mkdir -p /tmp/certs/") == 0
    ), "unable to create /tmp/certs/ directory"
    assert (
        ctx.command_code("cp -r contrib/8021x/certs/client/* /tmp/certs/") == 0
    ), "unable to copy certificates"


_register_tag("preserve_8021x_certs", preserve_8021x_certs_bs)


def pptp_bs(ctx, scen):
    if ctx.arch == "s390x":
        print("Skipping on s390x")
        sys.exit(77)
    nmci.lib.wait_for_testeth0(ctx)
    # Install under RHEL7 only
    if "Maipo" in ctx.rh_release:
        print("install epel-release-7")
        ctx.run(
            "[ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
        )
    ctx.run("[ -x /usr/sbin/pptpd ] || sudo yum -y install /usr/sbin/pptpd")
    ctx.run("rpm -q NetworkManager-pptp || sudo yum -y install NetworkManager-pptp")

    ctx.run("sudo rm -f /etc/ppp/ppp-secrets")
    psk = open("/etc/ppp/chap-secrets", "w")
    psk.write("budulinek pptpd passwd *\n")
    psk.close()

    if not os.path.isfile("/tmp/nm_pptp_configured"):
        cfg = open("/etc/pptpd.conf", "w")
        cfg.write("# pptpd configuration for client testing")
        cfg.write("\n" + "option /etc/ppp/options.pptpd")
        cfg.write("\n" + "logwtmp")
        cfg.write("\n" + "localip 172.31.66.6")
        cfg.write("\n" + "remoteip 172.31.66.60-69")
        cfg.write("\n" + "ms-dns 8.8.8.8")
        cfg.write("\n" + "ms-dns 8.8.4.4")
        cfg.write("\n")
        cfg.close()

        ctx.run("sudo systemctl unmask pptpd")
        ctx.run("sudo systemctl restart pptpd")
        # context.execute_steps(u'* Add a connection named "pptp" for device "\*" to "pptp" VPN')
        # context.execute_steps(u'* Use user "budulinek" with password "passwd" and MPPE set to "yes" for gateway "127.0.0.1" on PPTP connection "pptp"')
        ctx.run("/sbin/pppd pty '/sbin/pptp 127.0.0.1' nodetach")
        # ctx.run("nmcli con up id pptp")
        # ctx.run("nmcli con del pptp")
        ctx.run("touch /tmp/nm_pptp_configured")
        time.sleep(1)


def pptp_as(ctx, scen):
    ctx.run("nmcli connection delete pptp")


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
    ctx.run("sudo firewall-cmd --permanent --remove-port=51820/udp --zone=public")
    ctx.run("sudo firewall-cmd --permanent --zone=public --remove-masquerade")
    ctx.run("sudo systemctl stop firewalld")


_register_tag("firewall", firewall_bs, firewall_as)


def restore_hostname_bs(ctx, scen):
    ctx.original_hostname = ctx.command_output("hostname").strip()


def restore_hostname_as(ctx, scen):
    ctx.run("systemctl unmask systemd-hostnamed.service")
    ctx.run("systemctl unmask dbus-org.freedesktop.hostname1.service")
    if ctx.IS_NMTUI:
        ctx.run('sudo echo "localhost.localdomain" > /etc/hostname')
    else:
        ctx.run('hostnamectl set-hostname --transient ""')
        ctx.run("hostnamectl set-hostname --static %s" % ctx.original_hostname)
    ctx.run("rm -rf /etc/NetworkManager/conf.d/90-hostname.conf")
    ctx.run("rm -rf /etc/dnsmasq.d/dnsmasq_custom.conf")
    nmci.lib.reload_NM_service(ctx)
    ctx.run("nmcli con up testeth0")


_register_tag("restore_hostname", restore_hostname_bs, restore_hostname_as)


def runonce_bs(ctx, scen):
    ctx.run("systemctl stop network")
    ctx.run("nmcli device disconnect eth0")
    ctx.run("pkill -9 dhclient")
    ctx.run("pkill -9 nm-iface-helper")
    ctx.run("sudo systemctl stop firewalld")
    ctx.nm_pid_refresh_count = 1000


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
    ctx.run(
        "yum -y install https://vbenes.fedorapeople.org/NM/slow_libteam-1.25-5.el7_4.1.1.x86_64.rpm https://vbenes.fedorapeople.org/NM/slow_teamd-1.25-5.el7_4.1.1.x86_64.rpm"
    )
    if ctx.command_code("rpm --quiet -q teamd") != 0:
        print("Skipping as unable to install slow_team")
        # Restore teamd package if we don't have the slow ones
        ctx.run(
            "for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done"
        )
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
    if ctx.command_code("rpm -q NetworkManager-ovs") != 0:
        print("install NetworkManager-ovs")
        ctx.run("yum -y install NetworkManager-ovs")
        ctx.run("systemctl daemon-reload")
        nmci.lib.restart_NM_service(ctx)
    if (
        ctx.command_code("systemctl is-active openvswitch") != 0
        or ctx.command_code("systemctl status ovs-vswitchd.service |grep -q ERR") != 0
    ):
        print("restart openvswitch")
        ctx.run("systemctl restart openvswitch")
        nmci.lib.restart_NM_service(ctx)


def openvswitch_as(ctx, scen):
    ctx.run(
        "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ OVSDB LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log"
    )
    data1 = nmci.lib.utf_only_open_read("/var/log/openvswitch/ovsdb-server.log")
    if data1:
        print("Attaching OVSDB log")
        ctx.embed("text/plain", data1, caption="OVSDB")
    ctx.run(
        "echo '~~~~~~~~~~~~~~~~~~~~~~~~~~ OVSDemon LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~' > /tmp/journal-mm.log"
    )
    data2 = nmci.lib.utf_only_open_read("/var/log/openvswitch/ovs-vswitchd.log")
    if data2:
        print("Attaching OVSDemon log")
        ctx.embed("text/plain", data2, caption="OVSDemon")

    ctx.run("sudo ifdown bond0")
    ctx.run("sudo ifdown eth1")
    ctx.run("sudo ifdown eth2")
    ctx.run("sudo ifdown ovsbridge0")
    time.sleep(1)
    ctx.run("ovs-vsctl del-br ovsbr0")
    ctx.run("ovs-vsctl del-br ovs-br0")
    ctx.run("ovs-vsctl del-br ovsbridge0")
    ctx.run("ovs-vsctl del-br ovsbridge1")
    ctx.run("ovs-vsctl del-br i-ovs-br0")
    ctx.run("nmcli device delete bond0")
    ctx.run("nmcli device delete port0")
    ctx.run("sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-eth1")
    ctx.run("sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-bond0")
    ctx.run("sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ovsbridge0")
    ctx.run("sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-intbr0")
    ctx.run("sudo ip link set dev eth1 up")
    ctx.run("sudo ip link set dev eth2 up")
    ctx.run("sudo nmcli con reload")
    ctx.run("nmcli con up testeth1")
    ctx.run("nmcli con down testeth1")
    ctx.run("nmcli con up testeth2")
    ctx.run("nmcli con down testeth2")


_register_tag("openvswitch", openvswitch_bs, openvswitch_as)


def sriov_bs(ctx, scen):
    ctx.run("nmcli con del p4p1")


def sriov_as(ctx, scen):

    ctx.run("echo 0 > /sys/class/net/p6p1/device/sriov_numvfs")
    ctx.run("echo 0 > /sys/class/net/p4p1/device/sriov_numvfs")

    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-sriov.conf")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/98-sriov.conf")

    ctx.run("echo 1 > /sys/class/net/p4p1/device/sriov_drivers_autoprobe")
    ctx.run("echo 1 > /sys/class/net/p6p1/device/sriov_drivers_autoprobe")

    ctx.run("modprobe -r ixgbevf")

    nmci.lib.reload_NM_service(ctx)


_register_tag("sriov", sriov_bs, sriov_as)


def dpdk_bs(ctx, scen):
    ctx.run("sysctl -w vm.nr_hugepages=10")
    ctx.run(
        "if ! rpm -q --quiet dpdk dpdk-tools; then yum -y install dpdk dpdk-tools; fi"
    )
    ctx.run("sed -i.bak s/openvswitch:hugetlbfs/root:root/g /etc/sysconfig/openvswitch")
    ctx.run("ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true")
    ctx.run("modprobe vfio-pci")
    ctx.run("echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode")
    ctx.run(
        "nmcli  connection add type ethernet ifname p4p1 con-name dpdk-sriov sriov.total-vfs 2"
    )
    ctx.run("nmcli  connection up dpdk-sriov")
    # In newer versions of dpdk-tools there are dpdk binaries with py in the end
    ctx.run(
        "dpdk-devbind -b vfio-pci 0000:42:10.0 || dpdk-devbind.py -b vfio-pci 0000:42:10.0"
    )
    ctx.run(
        "dpdk-devbind -b vfio-pci 0000:42:10.2 || dpdk-devbind.py -b vfio-pci 0000:42:10.2"
    )
    # No idea why we need to restrt OVS but we need to
    ctx.run("systemctl restart openvswitch")


def dpdk_as(ctx, scen):
    ctx.run("systemctl stop ovsdb-server")
    ctx.run("systemctl stop openvswitch")
    time.sleep(5)


_register_tag("dpdk", dpdk_bs, dpdk_as)


def wireless_certs_bs(ctx, scen):
    ctx.run("mkdir /tmp/certs")
    if not os.path.isfile("/tmp/certs/eaptest_ca_cert.pem"):
        ctx.run(
            "wget http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem -O /tmp/certs/eaptest_ca_cert.pem"
        )
    if not os.path.isfile("/tmp/certs/client.pem"):
        ctx.run(
            "wget http://wlan-lab.eng.bos.redhat.com/certs/client.pem -O /tmp/certs/client.pem"
        )


_register_tag("wireless_certs", wireless_certs_bs)


def selinux_allow_ifup_bs(ctx, scen):
    ctx.run("semodule -i contrib/selinux-policy/ifup_policy.pp")


_register_tag("selinux_allow_ifup", selinux_allow_ifup_bs)


def no_testeth10_bs(ctx, scen):
    ctx.run("sudo nmcli connection delete testeth10")


_register_tag("no_testeth10", no_testeth10_bs)


def pppoe_bs(ctx, scen):
    pass
    if ctx.arch == "aarch64":
        print("enable pppd selinux policy on aarch64")
        ctx.run("semodule -i contrib/selinux-policy/pppd.pp")
    ctx.run("mknod /dev/ppp c 108 0")


def pppoe_as(ctx, scen):
    ctx.run("kill -9 $(pidof pppoe-server)")


_register_tag("pppoe", pppoe_bs, pppoe_as)


def del_test1112_veths_bs(ctx, scen):
    ctx.run(
        """echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test11|test12", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/99-veths.rules"""
    )
    ctx.run("udevadm control --reload-rules")
    ctx.run("udevadm settle --timeout=5")
    time.sleep(1)


def del_test1112_veths_as(ctx, scen):
    ctx.run("ip link del test11")
    ctx.run("rm -f /etc/udev/rules.d/99-veths.rules")
    ctx.run("udevadm control --reload-rules")
    ctx.run("udevadm settle --timeout=5")
    time.sleep(1)


_register_tag("del_test1112_veths", del_test1112_veths_bs, del_test1112_veths_as)


def nmstate_bs(ctx, scen):
    ctx.run("yum -y remove nmstate nispor")
    ctx.run("yum -y install nmstate")


def nmstate_as(ctx, scen):
    ctx.run("sh contrib/reproducers/repro_1923248.sh clean")
    # Workaround for RHBZ#1935026
    ctx.run("ovs-vsctl del-br ovs-br0")


_register_tag("nmstate", nmstate_bs, nmstate_as)


def nmstate_upstream_setup_bs(ctx, scen):
    # Skip on deployments where we do not have veths
    if not os.path.isfile("/tmp/nm_veth_configured"):
        print("Skipping as no vethsetup")
        sys.exit(77)

    # Prepare nmstate and skip if unsuccesful
    if ctx.command_code("sh prepare/nmstate.sh") != 0:
        print("ERROR: Skipping as prepare failed")
        sys.exit(77)

    # Rename eth1/2 to ethX/Y as these are used by test
    ctx.run("ip link set dev eth1 down")
    ctx.run("ip link set name eth01 eth1")
    ctx.run("ip link set dev eth2 down")
    ctx.run("ip link set name eth02 eth2")

    # We need to have use_tempaddr set to 0 to avoid test_dhcp_on_bridge0 PASSED
    ctx.run("echo 0 > /proc/sys/net/ipv6/conf/default/use_tempaddr")

    # Clone default profile but just ipv4 only"
    ctx.run('nmcli connection clone "$(nmcli -g NAME con show -a)" nmstate')
    ctx.run(
        "nmcli con modify nmstate ipv6.method disabled ipv6.addresses '' ipv6.gateway ''"
    )
    ctx.run("nmcli con up nmstate")

    # Move orig config file to /tmp
    ctx.run("mv /etc/NetworkManager/conf.d/99-unmanage-orig.conf /tmp")

    # Remove connectivity packages if present
    ctx.run(
        "dnf -y remove NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat"
    )
    nmci.lib.manage_veths(ctx)

    if (
        ctx.command_code("systemctl is-active openvswitch") != 0
        or ctx.command_code("systemctl status ovs-vswitchd.service |grep -q ERR") != 0
    ):
        print("restarting OVS service")
        ctx.run("systemctl restart openvswitch")
        nmci.lib.restart_NM_service(ctx)


def nmstate_upstream_setup_as(ctx, scen):
    # nmstate restarts NM few times during tests
    ctx.nm_restarted = True

    ctx.run("nmcli con del linux-br0 dhcpcli dhcpsrv brtest0 bond99 eth1.101 eth1.102")
    ctx.run("nmcli con del eth0 eth1 eth2 eth3 eth4 eth5 eth6 eth7 eth8 eth9 eth10")

    ctx.run("nmcli device delete dhcpsrv")
    ctx.run("nmcli device delete dhcpcli")
    ctx.run("nmcli device delete bond99")

    ctx.run("ovs-vsctl del-br ovsbr0")

    # in case of fail we need to kill this
    ctx.run("systemctl stop dnsmasq")
    ctx.run("pkill -f 'dnsmasq.*/etc/dnsmasq.d/nmstate.conf'")
    ctx.run("rm -rf /etc/dnsmasq.d/nmstate.conf")

    # Rename devices back to eth1/eth2
    ctx.run("ip link del eth1")
    ctx.run("ip link set dev eth01 down")
    ctx.run("ip link set name eth1 eth01")
    ctx.run("ip link set dev eth1 up")

    ctx.run("ip link del eth2")
    ctx.run("ip link set dev eth02 down")
    ctx.run("ip link set name eth2 eth02")
    ctx.run("ip link set dev eth2 up")

    # remove profiles
    ctx.run("nmcli con del nmstate eth01 eth02 eth1peer eth2peer")

    # Move orig config file to back
    ctx.run("mv /tmp/99-unmanage-orig.conf /etc/NetworkManager/conf.d/")

    # restore testethX
    nmci.lib.restore_connections(ctx)
    nmci.lib.wait_for_testeth0(ctx)

    # check just in case something went wrong
    nmci.lib.check_vethsetup(ctx)

    nmstate = nmci.lib.utf_only_open_read("/tmp/nmstate.txt")
    if nmstate:
        print("Attaching nmstate log")
        ctx.embed("text/plain", nmstate, caption="NMSTATE")


_register_tag(
    "nmstate_upstream_setup", nmstate_upstream_setup_bs, nmstate_upstream_setup_as
)


def backup_sysconfig_network_bs(ctx, scen):
    ctx.run("sudo cp -f /etc/sysconfig/network /tmp/sysnetwork.backup")


def backup_sysconfig_network_as(ctx, scen):
    ctx.run("sudo mv -f /tmp/sysnetwork.backup /etc/sysconfig/network")
    nmci.lib.reload_NM_connections(ctx)
    ctx.run("sudo nmcli connection down testeth9")


_register_tag(
    "backup_sysconfig_network", backup_sysconfig_network_bs, backup_sysconfig_network_as
)


def remove_fedora_connection_checker_bs(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)
    ctx.run("yum -y remove NetworkManager-config-connectivity-fedora")
    nmci.lib.reload_NM_service(ctx)


_register_tag("remove_fedora_connection_checker", remove_fedora_connection_checker_bs)


def need_config_server_bs(ctx, scen):
    if ctx.command_code("rpm -q NetworkManager-config-server") == 0:
        ctx.remove_config_server = False
    else:
        print("Install NetworkManager-config-server")
        ctx.run("sudo yum -y install NetworkManager-config-server")
        nmci.lib.reload_NM_service(ctx)
        ctx.remove_config_server = True


def need_config_server_as(ctx, scen):
    if ctx.remove_config_server:
        print("removing NetworkManager-config-server")
        ctx.run("sudo yum -y remove NetworkManager-config-server")
        nmci.lib.reload_NM_service(ctx)


_register_tag("need_config_server", need_config_server_bs, need_config_server_as)


def no_config_server_bs(ctx, scen):
    if ctx.command_code("rpm -q NetworkManager-config-server") == 1:
        ctx.restore_config_server = False
    else:
        # ctx.run('sudo yum -y remove NetworkManager-config-server')
        config_files = (
            ctx.command_output("rpm -ql NetworkManager-config-server")
            .strip()
            .split("\n")
        )
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file):
                print("* disabling file: %s" % config_file)
                ctx.run("sudo mv -f %s %s.off" % (config_file, config_file))
        nmci.lib.reload_NM_service(ctx)
        ctx.restore_config_server = True


def no_config_server_as(ctx, scen):
    if ctx.restore_config_server:
        config_files = (
            ctx.command_output("rpm -ql NetworkManager-config-server")
            .strip()
            .split("\n")
        )
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file + ".off"):
                print("* enabling file: %s" % config_file)
                ctx.run("sudo mv -f %s.off %s" % (config_file, config_file))
        nmci.lib.reload_NM_service(ctx)
    ctx.run(
        "for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |awk -F ':' ' {print $2}'); do nmcli con del $i; done"
    )
    nmci.lib.restore_testeth0(ctx)


_register_tag("no_config_server", no_config_server_bs, no_config_server_as)


def permissive_bs(ctx, scen):
    ctx.enforcing = False
    if ctx.command_output("getenforce").strip() == "Enforcing":
        print("WORKAROUND for permissive selinux")
        ctx.enforcing = True
        ctx.run("setenforce 0")


def permissive_as(ctx, scen):
    if ctx.enforcing:
        print("WORKAROUND for permissive selinux")
        ctx.run("setenforce 1")


_register_tag("permissive", permissive_bs, permissive_as)


def tcpdump_bs(ctx, scen):
    with open("/tmp/network-traffic.log", "w") as f:
        f.write("~~~~~~~~~~~~~~~~~~~~~~~~~~ TRAFFIC LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    ctx.pexpect_service(
        "sudo tcpdump -nne -i any >> /tmp/network-traffic.log", shell=True
    )


def tcpdump_as(ctx, scen):
    print("Attaching traffic log")
    ctx.run("sudo kill -1 $(pidof tcpdump)")
    if os.stat("/tmp/network-traffic.log").st_size < 20000000:
        traffic = nmci.lib.utf_only_open_read("/tmp/network-traffic.log")
    else:
        traffic = "WARNING: 20M size exceeded in /tmp/network-traffic.log, skipping"
    ctx.embed("text/plain", traffic, caption="TRAFFIC", fail_only=True)

    ctx.run("pkill -9 tcpdump")


_register_tag("tcpdump", tcpdump_bs, tcpdump_as)


def wifi_bs(ctx, scen):
    if ctx.IS_NMTUI:
        nmci.lib.wifi_rescan(ctx)


def wifi_as(ctx, scen):
    if ctx.IS_NMTUI:
        ctx.run(
            "sudo nmcli connection delete id wifi wifi1 qe-open qe-wpa1-psk qe-wpa2-psk qe-wep"
        )
        # ctx.run("sudo service NetworkManager restart") # debug restart to overcome the nmcli d w l flickering
    else:
        # ctx.run('sudo nmcli device disconnect wlan0')
        ctx.run(
            "sudo nmcli con del wifi qe-open qe-wep qe-wep-psk qe-wep-enterprise qe-wep-enterprise-cisco"
        )
        ctx.run(
            "sudo nmcli con del qe-wpa1-psk qe-wpa2-psk qe-wpa1-enterprise qe-wpa2-enterprise qe-hidden-wpa2-psk"
        )
        ctx.run("sudo nmcli con del qe-adhoc qe-ap wifi-wlan0")
        if "novice" in scen.tags:
            ctx.prompt.close()
            time.sleep(1)
            ctx.run("sudo nmcli con del wifi-wlan0")


_register_tag("wifi", wifi_bs, None)
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


def teamd_as(ctx, scen):
    ctx.run("systemctl stop teamd")
    ctx.run("systemctl reset-failed teamd")


_register_tag("teamd", None, teamd_as)


def restore_eth1_mtu_as(ctx, scen):
    ctx.run("sudo ip link set eth1 mtu 1500")


_register_tag("restore_eth1_mtu", None, restore_eth1_mtu_as)


def wifi_rescan_as(ctx, scen):
    if ctx.IS_NMTUI:
        nmci.lib.restart_NM_service(ctx)
        nmci.lib.wifi_rescan(ctx)


_register_tag("wifi_rescan", None, wifi_rescan_as)


def testeth7_disconnect_as(ctx, scen):
    if ctx.command_code("nmcli connection show -a |grep testeth7") == 0:
        print("bring down testeth7")
        ctx.run("nmcli con down testeth7")


_register_tag("testeth7_disconnect", None, testeth7_disconnect_as)


def checkpoint_remove_as(ctx, scen):
    # Not supported on 1-10
    import dbus

    bus = dbus.SystemBus()
    # Get a proxy for the base NetworkManager object
    proxy = bus.get_object(
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager"
    )
    # get NM object, to be able to call CheckpointDestroy
    manager = dbus.Interface(proxy, "org.freedesktop.NetworkManager")
    # dbus property getter
    prop_get = dbus.Interface(proxy, "org.freedesktop.DBus.Properties")
    # Unsupported prior version 1.12
    if (
        int(prop_get.Get("org.freedesktop.NetworkManager", "Version").split(".")[1])
        > 10
    ):
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
    time.sleep(0.5)
    ctx.run("pkill -F /tmp/dhclient_custom.pid")
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
    ctx.run(
        """echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="veth*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/99-veths.rules"""
    )
    ctx.run("udevadm control --reload-rules")
    ctx.run("udevadm settle --timeout=5")
    ctx.run("rm -rf /var/lib/NetworkManager/no-auto-default.state")
    with open("/etc/NetworkManager/conf.d/99-unmanaged.conf", "w") as cfg:
        cfg.write("[main]\n")
        cfg.write("no-auto-default=eth*\n")
    nmci.lib.reload_NM_service(ctx)


def allow_veth_connections_as(ctx, scen):
    ctx.run("sudo rm -rf /etc/udev/rules.d/99-veths.rules")
    ctx.run("sudo rm -rf /etc/NetworkManager/conf.d/99-unmanaged.conf")
    ctx.run("udevadm control --reload-rules")
    ctx.run("udevadm settle --timeout=5")
    nmci.lib.reload_NM_service(ctx)
    ctx.run(
        "for i in $(nmcli -t -f DEVICE c s -a |grep -v ^eth0$); do nmcli device disconnect $i; done"
    )


_register_tag(
    "allow_veth_connections", allow_veth_connections_bs, allow_veth_connections_as
)


def con_ipv6_ifcfg_remove_as(ctx, scen):
    # ctx.run("nmcli connection delete id con_ipv6 con_ipv62")
    ctx.run("rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv6")
    ctx.run("nmcli con reload")


_register_tag("con_ipv6_ifcfg_remove", None, con_ipv6_ifcfg_remove_as)


def tuntap_as(ctx, scen):
    ctx.run("ip link del tap0")


_register_tag("tuntap", None, tuntap_as)


def bond_order_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-bond.conf")
    nmci.lib.reload_NM_service(ctx)


_register_tag("bond_order", None, bond_order_as)


def remove_tombed_connections_as(ctx, scen):
    tombs = []
    for dir in [
        "/etc/NetworkManager/system-connections/*.nmmeta",
        "/var/run/NetworkManager/system-connections/*.nmmeta",
    ]:
        ls, _, _ = ctx.run("ls %s" % dir, stderr=subprocess.PIPE)
        if ls:
            tombs.extend(ls.split("\n"))
    cons = []
    for tomb in tombs:
        print(tomb)
        con_id = tomb.split("/")[-1]
        con_id = con_id.split(".")[0]
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
    ctx.run("rm -rf /etc/radvd.conf")


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
    ctx.run(
        "kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')"
    )
    ctx.run(
        "kill -9 $(ps aux|grep '/usr/sbin/dns' |grep 192.168 |grep -v grep |awk '{print $2}')"
    )


_register_tag("mtu", None, mtu_as)


def mtu_wlan0_as(ctx, scen):
    ctx.run(
        "nmcli con add type wifi ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    )
    ctx.run("nmcli connection modify qe-open 802-11-wireless.mtu 1500")
    ctx.run("nmcli connection up id qe-open")
    ctx.run("nmcli connection del id qe-open")


_register_tag("mtu_wlan0", None, mtu_wlan0_as)


def macsec_as(ctx, scen):
    ctx.run("kill $(cat /tmp/wpa_supplicant_ms.pid)")
    ctx.run("kill $(cat /tmp/dnsmasq_ms.pid)")


_register_tag("macsec", None, macsec_as)


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
    # sleep(TIMER)


_register_tag("peers_ns", None, peers_ns_as)


def tshark_as(ctx, scen):
    ctx.run("pkill tshark")
    ctx.run("rm -rf /etc/dhcp/dhclient-eth*.conf")


_register_tag("tshark", None, tshark_as)


def mac_as(ctx, scen):
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-mac.conf")
    nmci.lib.reload_NM_service(ctx)
    nmci.lib.reset_hwaddr_nmcli(ctx, "eth1")


_register_tag("mac", None, mac_as)


def eth8_up_as(ctx, scen):
    nmci.lib.reset_hwaddr_nmcli(ctx, "eth8")


_register_tag("eth8_up", None, eth8_up_as)


def keyfile_cleanup_as(ctx, scen):
    ctx.run('sudo sh -c "rm /usr/lib/NetworkManager/system-connections/*" ')
    ctx.run('sudo sh -c "rm /etc/NetworkManager/system-connections/*" ')
    # restore testethX
    nmci.lib.restore_connections(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("keyfile_cleanup", None, keyfile_cleanup_as)


def remove_dns_clean_as(ctx, scen):
    if ctx.command_code("grep dns /etc/NetworkManager/NetworkManager.conf") == 0:
        ctx.run("sudo sed -i 's/dns=none//' /etc/NetworkManager/NetworkManager.conf")
    ctx.run("sudo rm -rf /etc/NetworkManager/conf.d/90-test-dns-none.conf; sleep 1")
    nmci.lib.reload_NM_service(ctx)


_register_tag("remove_dns_clean", None, remove_dns_clean_as)


def restore_resolvconf_as(ctx, scen):
    ctx.run("rm -rf /etc/resolv.conf")
    if ctx.command_code("systemctl is-active systemd-resolved") == 0:
        ctx.run("ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf")
    ctx.run("rm -rf /tmp/resolv_orig.conf")
    ctx.run("rm -rf /tmp/resolv.conf")
    ctx.run("rm -rf /etc/NetworkManager/conf.d/99-resolv.conf")
    nmci.lib.reload_NM_service(ctx)
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("restore_resolvconf", None, restore_resolvconf_as)


def device_connect_as(ctx, scen):
    ctx.run("nmcli connection delete testeth9 eth9")
    ctx.run(
        "nmcli connection add type ethernet ifname eth9 con-name testeth9 autoconnect no"
    )


_register_tag("device_connect", None, device_connect_as)
_register_tag("device_connect_no_profile", None, device_connect_as)


def restore_eth8_as(ctx, scen):
    ctx.run("sudo ip link del eth8.100")
    ctx.run("sudo rm -f /etc/sysconfig/network-scripts/ifcfg-testeth8")
    ctx.run("sudo nmcli connection reload")
    ctx.run(
        "nmcli connection add type ethernet ifname eth8 con-name testeth8 autoconnect no"
    )


_register_tag("restore_eth8", None, restore_eth8_as)


def restore_broken_network_as(ctx, scen):
    ctx.run("sudo systemctl stop network.service")
    nmci.lib.stop_NM_service(ctx)
    ctx.run("sysctl net.ipv6.conf.all.accept_ra=1")
    ctx.run("sysctl net.ipv6.conf.default.accept_ra=1")
    nmci.lib.restart_NM_service(ctx)
    ctx.run("sudo nmcli connection down testeth8 testeth9")


_register_tag("restore_broken_network", None, restore_broken_network_as)


def add_testeth_as(ctx, scen, num):
    ctx.run("sudo nmcli connection delete eth%d testeth%d" % (num, num))
    ctx.run(
        "sudo nmcli connection add type ethernet con-name testeth%d ifname eth%d autoconnect no"
        % (num, num)
    )


for i in [1, 5, 8, 10]:
    _register_tag("add_testeth%d" % i, None, add_testeth_as, {"num": i})


def eth_disconnect_as(ctx, scen, num):
    ctx.run("sudo nmcli device disconnect eth%d" % num)
    # VVV Up/Down to preserve autoconnect feature
    ctx.run("sudo nmcli connection up testeth%d" % num)
    ctx.run("sudo nmcli connection down testeth%d" % num)


for i in [1, 2, 4, 5, 6, 8, 10]:
    _register_tag("eth%d_disconnect" % i, None, eth_disconnect_as, {"num": i})


def non_utf_device_bs(ctx, scen):
    if os.path.isfile("/usr/lib/udev/rules.d/80-net-setup-link.rules"):
        ctx.run("ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules")
        ctx.run("udevadm control --reload-rules")
        ctx.run("udevadm settle --timeout=5")
    ctx.process.run_stdout(
        ["ip", "link", "add", "name", b"\xca[2Jnonutf\xccf\\c", "type", "dummy"]
    )


def non_utf_device_as(ctx, scen):
    ctx.process.run_stdout(["ip", "link", "del", b"\xca[2Jnonutf\xccf\\c"])
    if os.path.isfile("/usr/lib/udev/rules.d/80-net-setup-link.rules"):
        ctx.run("ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules")
        ctx.run("udevadm control --reload-rules")
        ctx.run("udevadm settle --timeout=5")


_register_tag("non_utf_device", non_utf_device_bs, non_utf_device_as)


def shutdown_as(ctx, scen):
    print("sanitizing env")
    ctx.run("ip addr del 192.168.50.5/24 dev eth8")
    ctx.run("route del default gw 192.168.50.1 eth8")


_register_tag("shutdown", None, shutdown_as)


def connect_testeth0_as(ctx, scen):
    nmci.lib.wait_for_testeth0(ctx)


_register_tag("connect_testeth0", None, connect_testeth0_as)


def kill_dbus_monitor_as(ctx, scen):
    ctx.run("pkill -9 dbus-monitor")


_register_tag("kill_dbus-monitor", None, kill_dbus_monitor_as)


def kill_children_as(ctx, scen):
    children = getattr(ctx, "children", [])
    if len(children):
        print("kill remaining children (%d)", len(children))
        for child in children:
            child.kill(9)


_register_tag("kill_children", None, kill_children_as)


def restore_rp_filters_as(ctx, scen):
    ctx.run("echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter")
    ctx.run("echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter")


_register_tag("restore_rp_filters", None, restore_rp_filters_as)


def remove_ctcdevice_bs(ctx, scen):
    ctx.run("cio_ignore -R")
    time.sleep(1)


def remove_ctcdevice_as(ctx, scen):
    ctx.run(
        """znetconf -r $(znetconf -c |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }') -n"""
    )
    time.sleep(1)


_register_tag("remove_ctcdevice", remove_ctcdevice_bs, remove_ctcdevice_as)


def filter_batch_bs(ctx, scen):

    file_path = "/tmp/filter_batch.txt"
    ctx.run(f"sudo touch {file_path}")
    count = 1
    with open(file_path, "a") as file:
        for a in range(64):
            for b in range(64):
                for c in range(64):
                    file.write(
                        f"filter add dev dummy0 protocol ip ingress prio 1 handle {count} "
                        + f"flower skip_hw src_mac 11:11:00:{a:02x}:{b:02x}:{c:02x} "
                        + f"dst_mac 12:34:00:{a:02x}:{b:02x}:{c:02x} action gact drop\n"
                    )
                    count += 1


def filter_batch_as(ctx, scen):
    ctx.run("sudo rm /tmp/filter_batch.txt")


_register_tag("filter_batch", filter_batch_bs, filter_batch_as)


def custom_ns_as(ctx, scen):
    if not hasattr(ctx, "cleanup_ns"):
        return
    cleaned = set()
    for ns in ctx.cleanup_ns:
        ctx.run(f"ip netns delete {ns}")
        cleaned.add(ns)
    ctx.cleanup_ns.difference_update(cleaned)


_register_tag("custom_ns", None, custom_ns_as)


def radius_bs(ctx, scen):
    if ctx.command_code("systemctl is-active radiusd.service") == 0:
        ctx.run("systemctl disable --now radiusd.service")
    if os.path.isdir("/tmp/nmci-raddb"):
        if ctx.command_code("radiusd -XC") != 0:
            ctx.run("rm -rf /etc/raddb ; cp -a /tmp/nmci-raddb")
    else:
        # set up radius from scratch, full install is required to get freeradius configuration to fresh state
        if ctx.command_code("rpm -q freeradius") == 0:
            ctx.run("yum -y remove freeradius")
        shutil.rmtree("/etc/raddb", ignore_errors=True)
        ctx.run("yum -y install freeradius", check=True)
        shutil.copy("contrib/8021x/certs/server/hostapd.dh.pem", "/etc/raddb/certs/dh")
        ctx.run("make all", cwd="/etc/raddb/certs")
        shutil.chown("/etc/raddb/certs/server.pem", None, "radiusd")
        with open("/etc/raddb/mods-enabled/eap", "r+") as f:
            eap = f.read()
            # external certs: change paths to cert+key and possibly passowrd
            eap = re.sub(
                r"(\n\s*eap {[^}]*default_eap_type = )[^\n]*(\n)",
                r"\g<1>ttls\g<2>",
                eap,
            )
            eap = re.sub(r"\n(\s*md5 {\n)(\s*})", r"\n#\g<1>#\g<2>", eap)
            f.seek(0)
            f.write(eap)
        with open("/etc/raddb/sites-enabled/default", "r+") as f:
            r_sites = f.read()
            r_sites = re.sub(
                r"\n(\s*Auth-Type[^\n]*)\n([^\n]*)\n(\s*})",
                r"\n#\g<1>\n#\g<2>\n#\g<3>",
                r_sites,
            )
            r_sites = re.sub(r"\n(\s*mschap\n)", r"\n#\g<1>", r_sites)
            r_sites = re.sub(r"\n(\s*digest\n)", r"\n#\g<1>", r_sites)
            f.seek(0)
            f.write(r_sites)
        # if necessary (e.g. when moved to namespace), add non-localhost client to /etc/raddb/clients.conf
        with open("/etc/raddb/clients.conf", "r+") as f:
            clients = f.read()
            clients = re.sub(
                r"(\n\s*client localhost {[^}]*\n\s*secret = )[^\n]*\n",
                r"\g<1>client_password\n",
                clients,
            )
            clients = re.sub(
                r"(\n\s*client localhost_v6 {[^}]*\n\s*secret = )[^\n]*\n",
                r"\g<1>client_password\n",
                clients,
            )
            f.seek(0)
            f.write(clients)
        with open("/etc/raddb/users", "r+") as f:
            users_new = (
                f'example_user        Cleartext-Password := "user_password"\n{f.read()}'
            )
            f.seek(0)
            f.write(users_new)
        ctx.run("radiusd -XC", check=True)
        ctx.run("cp -a /etc/raddb /tmp/nmci-raddb")
    ctx.run("chown -R radiusd.radiusd /var/run/radiusd")
    if ctx.command_code("systemctl is-active radiusd") == 0:
        ctx.run("systemctl stop radiusd")
    ctx.run(
        f"systemd-run --service-type forking --unit nm-radiusd.service /usr/sbin/radiusd -l stdout -x",
        check=True,
    )


def radius_as(ctx, scen):
    if scen.status == "failed" or ctx.DEBUG:
        nmci.lib.embed_service_log(ctx, "radiusd", "RADIUS")
    ctx.run("systemctl stop nm-radiusd.service")


_register_tag("radius", radius_bs, radius_as)


def tag8021x_doc_procedure_bs(ctx, scen):
    # must run after radius tag whose _bs() part creates source files
    shutil.copy("/etc/raddb/certs/client.key", "/etc/pki/tls/private/8021x.key")
    shutil.copy("/etc/raddb/certs/client.pem", "/etc/pki/tls/certs/8021x.pem")
    shutil.copy("/etc/raddb/certs/ca.pem", "/etc/pki/tls/certs/8021x-ca.pem")
    ctx.run(f"yum -y install hostapd wpa_supplicant", check=True)
    with open("/etc/sysconfig/hostapd", "r+") as f:
        content = f.read()
        f.seek(0)
        f.write(re.sub("(?m)^OTHER_ARGS=.*$", 'OTHER_ARGS="-d"', content))


def tag8021x_doc_procedure_as(ctx, scen):
    ctx.run("systemctl stop 802-1x-tr-mgmt hostapd")
    if scen.status == "failed" or ctx.DEBUG:
        nmci.lib.embed_service_log(ctx, "hostapd", "HOSTAPD")
        nmci.lib.embed_service_log(ctx, "802-1x-tr-mgmt", "802.1X access control")
        nmci.lib.embed_file_if_exists(
            ctx,
            "/tmp/nmci-wpa_supplicant-standalone",
            caption="WPA_SUP from access control test",
        )
    os.remove("/etc/hostapd/hostapd.conf")
    ctx.run("systemctl daemon-reload")
    nmci.lib.reset_hwaddr_nmcli(ctx, "eth4")


_register_tag(
    "8021x_doc_procedure", tag8021x_doc_procedure_bs, tag8021x_doc_procedure_as
)


def simwifi_hw_bs(ctx, scen):
    if not hasattr(ctx, "noted"):
        ctx.noted = {}
    if ctx.process.run_stdout("iw list").strip():
        ctx.noted["wifi-hw_real"] = "enabled"
    else:
        ctx.noted["wifi-hw_real"] = "missing"


def simwifi_hw_as(ctx, scen):
    ctx.process.run_stdout("nmcli radio wifi on")


_register_tag("simwifi_hw", simwifi_hw_bs, simwifi_hw_as)
