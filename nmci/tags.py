# before/after scenario for tags
import os
import nmci
import glob
import time
import re
import shutil
import traceback


class Tag:
    def __init__(
        self,
        tag_name,
        before_scenario=None,
        after_scenario=None,
        args={},
        priority=nmci.Cleanup.PRIORITY_TAG,
    ):
        self.lineno = 0
        self.tag_name = tag_name
        self.args = args
        self.priority = priority
        self._before_scenario = before_scenario
        self._after_scenario = after_scenario
        if self._before_scenario:
            self.lineno = self._before_scenario.__code__.co_firstlineno
        elif self._after_scenario:
            self.lineno = self._after_scenario.__code__.co_firstlineno

    def before_scenario(self, context, scenario):
        if self._after_scenario is not None:
            nmci.cleanup.add_callback(
                callback=lambda: self.after_scenario(context, scenario),
                name=f"tag-{self.tag_name}",
                unique_tag=(self,),
                priority=self.priority,
            )
        if self._before_scenario is None:
            return

        # Printing this information is important for nm-ci-stats:
        # https://gitlab.freedesktop.org/NetworkManager/NetworkManager-ci/-/blob/0c08590a16fb4558fd6583734c260f34c276eb3b/run/utils/j-dump/j-dump.py#L150

        print(f"Executing @{self.tag_name}")
        t_start = time.monotonic()
        try:
            self._before_scenario(context, scenario, **self.args)
        except Exception:
            print(f"  @{self.tag_name} ... failed in {time.monotonic() - t_start:.3f}s")
            raise
        print(f"  @{self.tag_name} ... passed in {time.monotonic() - t_start:.3f}s")

    def after_scenario(self, context, scenario):
        if self._after_scenario is None:
            return

        print(f"Executing @{self.tag_name}")
        t_start = time.monotonic()
        try:
            self._after_scenario(context, scenario, **self.args)
        except Exception:
            print(f"  @{self.tag_name} ... failed in {time.monotonic() - t_start:.3f}s")
            raise
        print(f"  @{self.tag_name} ... passed in {time.monotonic() - t_start:.3f}s")


tag_registry = {}


def _register_tag(
    tag_name,
    before_scenario=None,
    after_scenario=None,
    args={},
    priority=nmci.Cleanup.PRIORITY_TAG,
):
    assert tag_name not in tag_registry, "multiple definitions for tag '@%s'" % tag_name
    tag_registry[tag_name] = Tag(
        tag_name, before_scenario, after_scenario, args, priority
    )


# tags that have efect outside this file
_register_tag("no_abrt")
_register_tag("xfail")
_register_tag("may_fail")
_register_tag("nmtui")


def temporary_skip_bs(context, scenario):
    context.cext.skip("Temporarily skipped")


_register_tag("temporary_skip", temporary_skip_bs)


def fail_bs(context, scenario):
    assert False


_register_tag("fail", fail_bs)


def skip_restarts_bs(context, scenario):
    if os.path.isfile("/tmp/nm_skip_restarts") or os.path.isfile("/tmp/nm_skip_STR"):
        context.cext.skip(
            "skipping service restart tests as /tmp/nm_skip_restarts exists"
        )


_register_tag("skip_str", skip_restarts_bs)


def long_bs(context, scenario):
    if os.path.isfile("/tmp/nm_skip_long"):
        context.cext.skip("skipping long test case as /tmp/nm_skip_long exists")


_register_tag("long", long_bs)


def skip_in_centos_bs(context, scenario):
    if "CentOS" in context.rh_release:
        context.cext.skip("skipping with centos")


_register_tag("skip_in_centos", skip_in_centos_bs)


def skip_in_kvm_bs(context, scenario):
    if "kvm" or "powervm" in context.hypervisor:
        if context.arch != "x86_64":
            context.cext.skip(
                "skipping on non x86_64 machine with kvm or powervm hypvervisors"
            )


_register_tag("skip_in_kvm", skip_in_kvm_bs)


def arch_only_bs(context, scenario, arch):
    if context.arch != arch:
        context.cext.skip(f"skiping on {context.arch} as not on {arch}")


def not_on_arch_bs(context, scenario, arch):
    if context.arch == arch:
        context.cext.skip(f"skiping on {context.arch}")


for arch in ["x86_64", "s390x", "ppc64", "ppc64le", "aarch64"]:
    _register_tag("not_on_" + arch, not_on_arch_bs, None, {"arch": arch})
    _register_tag(arch + "_only", arch_only_bs, None, {"arch": arch})


def not_on_aarch64_but_pegas_bs(context, scenario):
    ver = context.process.run_stdout("uname -r").strip()
    if context.arch == "aarch64":
        if "4.5" in ver:
            context.cext.skip("skipping on aarch64 v4.5")


_register_tag("not_on_aarch64_but_pegas", not_on_aarch64_but_pegas_bs)


def gsm_sim_bs(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping on not intel arch")

    if context.process.systemctl("is-active ModemManager").returncode != 0:
        context.process.run(
            "semodule -i contrib/selinux-policy/ModemManager.pp",
            timeout=120,
            ignore_stderr=True,
        )

        context.process.systemctl("restart ModemManager")

        nmci.nmutil.restart_NM_service()

    # Load ppp_generic to avoid first test failure
    context.process.run_code("modprobe ppp_generic", ignore_stderr=True, timeout=120)

    # run as service
    context.pexpect_service("prepare/gsm_sim.sh modemu")


def gsm_sim_as(context, scenario):
    context.process.nmcli_force("con down id gsm")
    time.sleep(2)
    context.process.run("prepare/gsm_sim.sh teardown", ignore_stderr=True)
    time.sleep(1)
    context.process.nmcli_force("con del id gsm")
    nmci.embed.embed_file_if_exists(
        "GSM_SIM",
        "/tmp/gsm_sim.log",
    )


_register_tag("gsm_sim", gsm_sim_bs, gsm_sim_as)


def crash_bs(context, scenario):
    context.crash_upload = False
    nmci.util.file_set_content("/tmp/disable-qe-abrt")


_register_tag("crash", crash_bs)


def not_with_systemd_resolved_bs(context, scenario):
    if context.process.systemctl("is-active systemd-resolved").returncode == 0:
        context.cext.skip("Skipping as systemd-resolved is running")


_register_tag("not_with_systemd_resolved", not_with_systemd_resolved_bs)


def not_under_internal_DHCP_bs(context, scenario):
    if "release 8" in context.rh_release and not context.process.run_search_stdout(
        "NetworkManager --print-config", "dhclient"
    ):
        context.cext.skip("skipping as on CentOS/RHEL 8, and no dhclient")
    if context.process.run_search_stdout("NetworkManager --print-config", "internal"):
        context.cext.skip("skipping on DHCP internal config")


_register_tag("not_under_internal_DHCP", not_under_internal_DHCP_bs)


def not_on_veth_bs(context, scenario):
    if os.path.isfile("/tmp/nm_veth_configured"):
        context.cext.skip("skipping on veth")


_register_tag("not_on_veth", not_on_veth_bs, None)


def not_when_no_veths_bs(context, scenario):
    if not os.path.isfile("/tmp/nm_veth_configured"):
        context.cext.skip("skipping on defaults")


_register_tag("not_when_no_veths", not_when_no_veths_bs, None)


def regenerate_veth_as(context, scenario):
    if os.path.isfile("/tmp/nm_veth_configured"):
        nmci.veth.check_vethsetup()
    else:
        print("up eth1-11 links")
        for link in range(1, 11):
            context.process.run_stdout(f"ip link set eth{link} up")


_register_tag("regenerate_veth", None, regenerate_veth_as)


def logging_info_only_bs(context, scenario):
    conf = "/etc/NetworkManager/conf.d/96-nmci-logging.conf"
    # Cleanups in the same priority are executed in reversed order...
    nmci.cleanup.add_NM_service(
        timeout=120,
        priority=nmci.Cleanup.PRIORITY_TAG,
    )
    nmci.cleanup.add_NM_config(
        conf,
        schedule_nm_restart=False,
        priority=nmci.Cleanup.PRIORITY_TAG,
    )
    nmci.util.file_set_content(conf, ["[logging]", "level=INFO", "domains=ALL"])
    nmci.nmutil.restart_NM_service()


_register_tag("logging_info_only", logging_info_only_bs, None)


def _is_container():
    return os.path.isfile("/run/.containerenv")


def restart_if_needed_as(context, scenario):
    if context.process.systemctl("is-active NetworkManager").returncode != 0:
        nmci.nmutil.restart_NM_service()
    if (
        not os.path.isfile("/tmp/nm_dcb_inf_wol_sriov_configured")
        and not _is_container()
    ):
        nmci.veth.wait_for_testeth0()


_register_tag("restart_if_needed", None, restart_if_needed_as)


def secret_key_reset_bs(context, scenario):
    context.process.run_stdout(
        "mv /var/lib/NetworkManager/secret_key /var/lib/NetworkManager/secret_key_back"
    )


def secret_key_reset_as(context, scenario):
    context.process.run_stdout(
        "mv /var/lib/NetworkManager/secret_key_back /var/lib/NetworkManager/secret_key"
    )


_register_tag("secret_key_reset", secret_key_reset_bs, secret_key_reset_as)


def tag1000_as(context, scenario):
    context.process.run("ip link del bridge0", ignore_stderr=True)
    context.process.run(
        "for i in $(seq 0 1000); do ip link del port$i ; done",
        shell=True,
        ignore_stderr=True,
        timeout=240,
    )


_register_tag("1000", None, tag1000_as)


def many_vlans_bs(context, scenario):
    nmci.veth.manage_veths()
    context.process.run_stdout(
        "sh prepare/vlans.sh clean", ignore_stderr=True, timeout=30
    )
    os.environ["N_VLANS"] = "500" if context.arch == "x86_64" else "200"
    # We need NM to sanitize itself a bit
    time.sleep(20)


def many_vlans_as(context, scenario):
    context.process.run_stdout(
        "sh prepare/vlans.sh clean", ignore_stderr=True, timeout=30
    )
    nmci.veth.unmanage_veths()


_register_tag("many_vlans", many_vlans_bs, many_vlans_as)


def captive_portal_bs(context, scenario):
    # run as service
    context.pexpect_service("bash prepare/captive_portal.sh")


def captive_portal_as(context, scenario):
    context.process.run_stdout("bash prepare/captive_portal.sh teardown")


_register_tag("captive_portal", captive_portal_bs, captive_portal_as)


def gsm_bs(context, scenario):
    context.process.run("mmcli -G debug")
    context.process.nmcli("general logging level DEBUG domains ALL")
    # Extract modem's identification and keep it in a global variable for further use.
    # Only 1 modem is expected per test.
    context.modem_str = nmci.gsm.find_modem()
    scenario.name += " - " + context.modem_str

    if not os.path.isfile("/tmp/usb_hub"):
        context.process.run_stdout("sh prepare/initialize_modem.sh", timeout=600)

    context.process.nmcli_force("con down testeth0")


def gsm_as(context, scenario):
    # You can debug here only with console connection to the testing machine.
    # SSH connection is interrupted.
    # import ipdb

    context.process.nmcli_force("connection delete gsm")
    context.process.run_stdout("rm -rf /etc/NetworkManager/system-connections/gsm")
    nmci.veth.wait_for_testeth0()

    print("embed ModemManager log")
    data = nmci.misc.journal_show(
        "ModemManager",
        cursor=context.log_cursor,
        prefix="~~~~~~~~~~~~~~~~~~~~~~~~~~ MM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        journal_args="-o cat",
    )
    nmci.embed.embed_data("MM", data)
    # Extract modem model.
    # Example: 'USB ID 1c9e:9603 Zoom 4595' -> 'Zoom 4595'
    regex = r"USB ID (\w{4}:\w{4}) (.*)"
    mo = re.search(regex, context.modem_str)
    if mo:
        modem_model = mo.groups()[1]
        cap = modem_model
    else:
        cap = "MODEM INFO"

    modem_info = nmci.gsm.get_modem_info(context)
    if modem_info:
        print("embed modem_info")
        nmci.embed.embed_data(cap, modem_info)


_register_tag("gsm", gsm_bs, gsm_as)


def unmanage_eth_bs(context, scenario):
    links = nmci.nmutil.get_ethernet_devices()
    for link in links:
        context.process.nmcli(f"dev set {link} managed no")


def unmanage_eth_as(context, scenario):
    links = nmci.nmutil.get_ethernet_devices()
    for link in links:
        context.process.nmcli(f"dev set {link} managed yes")


_register_tag("unmanage_eth", unmanage_eth_bs, unmanage_eth_as)


def manage_eth8_as(context, scenario):
    context.process.nmcli("device set eth8 managed true")


_register_tag("manage_eth8", None, manage_eth8_as)


def connectivity_bs(context, scenario):
    if "captive_portal" in scenario.tags:
        uri = "http://static.redhat.com:8001/test/rhel-networkmanager.txt"
    else:
        uri = "http://static.redhat.com/test/rhel-networkmanager.txt"
    conf = [
        "[connectivity]",
        f"uri={uri}",
        "response=OK",
        "interval=10",
    ]
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/95-nmci-connectivity.conf", conf
    )
    nmci.nmutil.reload_NM_service()


def connectivity_as(context, scenario):
    context.process.run_stdout(
        "rm -rf /etc/NetworkManager/conf.d/95-nmci-connectivity.conf"
    )
    context.process.run_stdout(
        "rm -rf /var/lib/NetworkManager/NetworkManager-intern.conf"
    )
    context.execute_steps("* Reset /etc/hosts")

    nmci.nmutil.reload_NM_service()
    print(context.process.run_stdout("NetworkManager --print-config"))


_register_tag("connectivity", connectivity_bs, connectivity_as)


def unload_kernel_modules_bs(context, scenario):
    if (
        context.process.run_code(
            "lsmod |grep -q qmi_wwan",
            shell=True,
        )
        == 0
    ):
        context.process.run_stdout("modprobe -r qmi_wwan")
    if (
        context.process.run_code(
            "lsmod |grep -q cdc-mbim",
            shell=True,
        )
        == 0
    ):
        context.process.run_stdout("modprobe -r cdc-mbim")


_register_tag("unload_kernel_modules", unload_kernel_modules_bs)


def disp_as(context, scenario):
    context.process.nmcli_force("con down testeth1")
    context.process.nmcli_force("con down testeth2")


_register_tag("disp", None, disp_as)


def eth0_bs(context, scenario):
    skip_restarts_bs(context, scenario)
    # if context.IS_NMTUI:
    #    context.process.run_stdout("nmcli connection down id testeth0")
    #    time.sleep(1)
    #    if context.process.run_code("nmcli -f NAME c sh -a |grep eth0") == 0:
    #        print("shutting down eth0 once more as it is not down")
    #        context.process.run_stdout("nmcli device disconnect eth0")
    #        time.sleep(2)
    context.process.nmcli("con modify testeth0 connection.autoconnect no")
    context.process.nmcli("con down testeth0")
    context.process.nmcli_force("con down testeth1")
    context.process.nmcli_force("con down testeth2")


def eth0_as(context, scenario):
    #    if not context.IS_NMTUI:
    #        if 'restore_hostname' in scenario.tags:
    #            context.process.run_stdout('hostnamectl set-hostname --transien ""')
    #            context.process.run_stdout(f'hostnamectl set-hostname --static {context.original_hostname}')
    context.process.nmcli("con modify testeth0 connection.autoconnect yes")
    nmci.veth.wait_for_testeth0()


_register_tag("eth0", eth0_bs, eth0_as)


def alias_bs(context, scenario):
    context.process.nmcli("connection up testeth7")
    context.process.nmcli_force("connection delete eth7")


def alias_as(context, scenario):
    context.process.nmcli_force("connection delete eth7")
    context.process.run_stdout("rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:0")
    context.process.run_stdout("rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:1")
    context.process.run_stdout("rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:2")
    context.process.nmcli("connection reload")
    context.process.nmcli_force("connection down testeth7")
    # context.process.run_stdout('nmcli con add type ethernet ifname eth7 con-name testeth7 autoconnect no')
    # sleep(TIMER)


_register_tag("alias", alias_bs, alias_as)


def netcat_bs(context, scenario):
    nmci.veth.wait_for_testeth0()


_register_tag("netcat", netcat_bs)


def scapy_bs(context, scenario):
    nmci.veth.wait_for_testeth0()
    # TODO move to envsetup
    if not os.path.isfile("/usr/bin/scapy"):
        print("installing scapy and tcpdump")
        context.process.run_stdout(
            "yum -y install tcpdump", timeout=120, ignore_stderr=True
        )
        context.process.run_stdout(
            "python -m pip install scapy", ignore_stderr=True, timeout=120
        )


def scapy_as(context, scenario):
    context.process.run("ip link delete test10", ignore_stderr=True)
    context.process.run("ip link delete test11", ignore_stderr=True)
    context.process.nmcli_force("connection delete ethernet-test10 ethernet-test11")


_register_tag("scapy", scapy_bs, scapy_as)


def mock_bs(context, scenario):
    # TODO move to envsetup
    if context.process.run_code("rpm -q --quiet dbus-x11") != 0:
        print("installing dbus-x11, pip, and python-dbusmock==0.26.1 dataclasses")
        context.process.run_stdout(
            "yum -y install dbus-x11", timeout=120, ignore_stderr=True
        )
    context.process.run_stdout(
        "python3 -m pip install python-dbusmock==0.26.1 dataclasses",
        ignore_stderr=True,
        timeout=120,
    )
    # TODO: check why patch does not apply
    context.process.run(
        "./contrib/dbusmock/patch-python-dbusmock.sh", ignore_stderr=True
    )


_register_tag("mock", mock_bs)


def IPy_bs(context, scenario):
    nmci.veth.wait_for_testeth0()
    # TODO move to envsetup
    if context.process.run_code("rpm -q --quiet dbus-x11") != 0:
        print("installing dbus-x11")
        context.process.run_stdout(
            "yum -y install dbus-x11", timeout=120, ignore_stderr=True
        )
    if not context.process.run_search_stdout(
        "python -m pip list", "IPy", timeout=10, ignore_stderr=True
    ):
        print("installing IPy")
        context.process.run_stdout(
            "python -m pip install IPy", ignore_stderr=True, timeout=120
        )


_register_tag("IPy", IPy_bs)


def netaddr_bs(context, scenario):
    nmci.veth.wait_for_testeth0()
    # TODO move to envsetup
    if not context.process.run_search_stdout(
        "python -m pip list", "netaddr", ignore_stderr=True
    ):
        print("install netaddr")
        context.process.run_stdout(
            "python -m pip install netaddr", ignore_stderr=True, timeout=120
        )


_register_tag("netaddr", netaddr_bs)


def inf_bs(context, scenario):
    context.process.nmcli_force("device disconnect inf_ib0")
    context.process.nmcli_force("device disconnect inf_ib0.8002")
    context.process.nmcli_force("connection delete inf_ib0.8002")
    context.process.nmcli_force(
        "connection delete id infiniband-inf_ib0.8002 inf.8002 inf inf2 infiniband-inf_ib0 infiniband"
    )


def inf_as(context, scenario):
    if context.IS_NMTUI:
        context.process.nmcli_force("connection delete id infiniband0 infiniband0-port")
    else:
        context.process.nmcli("connection up id lom_1")
        context.process.nmcli_force("connection delete id inf inf2 infiniband inf.8002")
        context.process.nmcli_force("nmcli device connect inf_ib0.8002")


_register_tag("inf", inf_bs, inf_as)


def dsl_as(context, scenario):
    if context.IS_NMTUI:
        context.process.nmcli_force("connection delete id dsl0")


_register_tag("dsl", None, dsl_as)


def dns_dnsmasq_bs(context, scenario):
    if context.process.systemctl("is-active systemd-resolved").returncode == 0:
        print("stopping systemd-resolved")
        context.systemd_resolved = True
        context.process.systemctl("stop systemd-resolved")
        context.process.run_stdout("rm -rf /etc/resolv.conf")
    else:
        context.systemd_resolved = False
    conf = ["# configured by beaker-test", "[main]", "dns=dnsmasq"]
    nmci.util.file_set_content("/etc/NetworkManager/conf.d/96-nmci-test-dns.conf", conf)
    nmci.nmutil.restart_NM_service()
    context.dns_plugin = "dnsmasq"


def dns_dnsmasq_as(context, scenario):
    context.process.run_stdout("rm -f /etc/NetworkManager/conf.d/96-nmci-test-dns.conf")
    nmci.nmutil.reload_NM_service()
    context.dns_plugin = ""
    if context.systemd_resolved is True:
        print("starting systemd-resolved")
        context.process.systemctl("restart systemd-resolved")


_register_tag("dns_dnsmasq", dns_dnsmasq_bs, dns_dnsmasq_as)


def dns_systemd_resolved_bs(context, scenario):
    context.systemd_resolved = True
    if context.process.systemctl("is-active systemd-resolved").returncode != 0:
        context.systemd_resolved = False
        print("start systemd-resolved as it is OFF and requried")
        context.process.systemctl("start systemd-resolved")
        if context.process.systemctl("is-active systemd-resolved").returncode != 0:
            context.cext.skip("Cannot start systemd-resolved")
    conf = ["# configured by beaker-test", "[main]", "dns=systemd-resolved"]

    # We need to enable mdns for tests
    context.process.run_stdout(
        "echo 'MulticastDNS=yes' >> /etc/systemd/resolved.conf",
        shell=True,
    )
    # And disable DNSSEC
    context.process.run_stdout(
        "echo 'DNSSEC=no' >> /etc/systemd/resolved.conf",
        shell=True,
    )

    context.process.systemctl("restart systemd-resolved")

    # On Fedora and RHEL9+, rc-manager is "auto" by default, which doesn't touch
    # resolv.conf when dns=systemd-resolved; we also want to test NM writing
    # 127.0.0.53 to resolv.conf if needed, so change the value of rc-manager.
    try:
        target = os.readlink("/etc/resolv.conf")
    except:
        target = None
    if target is None or "/run/systemd/resolve/" not in target:
        conf.append("rc-manager=symlink")

    nmci.util.file_set_content("/etc/NetworkManager/conf.d/96-nmci-test-dns.conf", conf)
    nmci.nmutil.restart_NM_service()
    context.dns_plugin = "systemd-resolved"


def dns_systemd_resolved_as(context, scenario):
    # Remove the last line enabling mdns
    context.process.run_stdout("sed -i '$d' /etc/systemd/resolved.conf")
    if not context.systemd_resolved:
        print("stop systemd-resolved")
        context.process.systemctl("stop systemd-resolved")
    else:
        print("restarting systemd-resolved")
        context.process.systemctl("restart systemd-resolved")
    context.process.run_stdout("rm -f /etc/NetworkManager/conf.d/96-nmci-test-dns.conf")
    nmci.nmutil.reload_NM_service()
    context.dns_plugin = ""


_register_tag("dns_systemd_resolved", dns_systemd_resolved_bs, dns_systemd_resolved_as)


def internal_DHCP_bs(context, scenario):
    nmci.cleanup.add_NM_config("96-nmci-dhcp-internal.conf")
    conf = ["# configured by beaker-test", "[main]", "dhcp=internal"]
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/96-nmci-dhcp-internal.conf", conf
    )
    nmci.nmutil.restart_NM_service()


_register_tag("internal_DHCP", internal_DHCP_bs)


def dhclient_DHCP_bs(context, scenario):
    conf = ["# configured by beaker-test", "[main]", "dhcp=dhclient"]
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/96-nmci-dhcp-dhclient.conf", conf
    )
    nmci.nmutil.restart_NM_service()


def dhclient_DHCP_as(context, scenario):
    context.process.run_stdout(
        "rm -f /etc/NetworkManager/conf.d/96-nmci-dhcp-dhclient.conf"
    )
    nmci.nmutil.restart_NM_service()


_register_tag("dhclient_DHCP", dhclient_DHCP_bs, dhclient_DHCP_as)


def delete_testeth0_bs(context, scenario):
    skip_restarts_bs(context, scenario)
    context.process.nmcli("device disconnect eth0")
    context.process.nmcli("connection delete id testeth0")


def delete_testeth0_as(context, scenario):
    context.process.nmcli_force("connection delete eth0")
    nmci.veth.restore_testeth0()


_register_tag("delete_testeth0", delete_testeth0_bs, delete_testeth0_as)


def ethernet_bs(context, scenario):
    cons = context.process.nmcli("con")
    if "testeth1" in cons or "testeth2" in cons:
        print("sanitizing eth1 and eth2")
        context.process.nmcli_force("con del testeth1 testeth2")
        context.process.nmcli(
            "con add type ethernet ifname eth1 con-name testeth1 autoconnect no"
        )
        context.process.nmcli(
            "con add type ethernet ifname eth2 con-name testeth2 autoconnect no"
        )


_register_tag("ethernet", ethernet_bs, None)


def ifupdown_bs(context, scenario):
    _, nm_ver = nmci.misc.nm_version_detect()
    if (
        nm_ver >= [1, 36]
        and context.process.run_code("rpm -q NetworkManager-initscripts-updown") != 0
    ):
        print("install NetworkManager-initscripts-updown")
        context.process.run_stdout(
            "dnf install -y NetworkManager-initscripts-updown",
            ignore_stderr=True,
            timeout=120,
        )


_register_tag("ifupdown", ifupdown_bs, None)


def ifcfg_rh_bs(context, scenario):

    distro, version = nmci.misc.distro_detect()

    if distro == "fedora" and version[0] >= 39:
        context.cext.skip("skipping on fedora 39+")
    elif distro == "rhel" and version[0] > 9:
        context.cext.skip("skipping on rhel 10+")

    _, nm_ver = nmci.misc.nm_version_detect()
    if (
        nm_ver >= [1, 36]
        and context.process.run_code("rpm -q NetworkManager-initscripts-updown") != 0
    ):
        print("install NetworkManager-initscripts-updown")
        context.process.run_stdout(
            "dnf install -y NetworkManager-initscripts-updown",
            ignore_stderr=True,
            timeout=120,
        )
    if not context.process.run_search_stdout(
        "NetworkManager --print-config", "^plugins=ifcfg-rh", pattern_flags=re.MULTILINE
    ):
        print("setting ifcfg-rh plugin")
        # VV Do not lower this as some devices can be still going down
        time.sleep(0.5)
        conf = ["# configured by beaker-test", "[main]", "plugins=ifcfg-rh"]
        nmci.util.file_set_content(
            "/etc/NetworkManager/conf.d/96-nmci-custom.conf", conf
        )
        nmci.nmutil.restart_NM_service()
        if context.IS_NMTUI:
            # comment out wifi_rescan, as simwifi prepare not done yet
            # if "simwifi" in scenario.tags:
            #     nmci.ctx.wifi_rescan()
            # VV Do not lower this as nmtui can be behaving weirdly
            time.sleep(4)
        time.sleep(0.5)


def ifcfg_rh_as(context, scenario):
    if os.path.isfile("/etc/NetworkManager/conf.d/96-nmci-custom.conf"):
        print("resetting ifcfg plugin")
        context.process.run_stdout(
            "rm -f /etc/NetworkManager/conf.d/96-nmci-custom.conf"
        )
        nmci.nmutil.restart_NM_service()
        if context.IS_NMTUI:
            # if 'simwifi' in scenario.tags:
            #     nmci.ctx.wifi_rescan()
            time.sleep(4)
        time.sleep(0.5)


_register_tag("ifcfg-rh", ifcfg_rh_bs, ifcfg_rh_as)


def keyfile_bs(context, scenario):
    _, nm_ver = nmci.misc.nm_version_detect()
    if (
        nm_ver >= [1, 36]
        and context.process.run_code("rpm -q NetworkManager-initscripts-updown") != 0
    ):
        print("install NetworkManager-initscripts-updown")
        context.process.run_stdout(
            "dnf install -y NetworkManager-initscripts-updown", timeout=120
        )
    if not context.process.run_search_stdout(
        "NetworkManager --print-config", "^plugins=keyfile", pattern_flags=re.MULTILINE
    ):
        print("setting keyfile plugin")
        # VV Do not lower this as some devices can be still going down
        time.sleep(0.5)
        conf = ["# configured by beaker-test", "[main]", "plugins=keyfile"]
        nmci.util.file_set_content(
            "/etc/NetworkManager/conf.d/96-nmci-custom.conf", conf
        )
        nmci.nmutil.restart_NM_service()
        if context.IS_NMTUI:
            # comment out wifi_rescan, as simwifi prepare not done yet
            # if "simwifi" in scenario.tags:
            #     nmci.ctx.wifi_rescan()
            # VV Do not lower this as nmtui can be behaving weirdly
            time.sleep(4)
        time.sleep(0.5)


def keyfile_as(context, scenario):
    if os.path.isfile("/etc/NetworkManager/conf.d/96-nmci-custom.conf"):
        print("resetting ifcfg plugin")
        context.process.run_stdout(
            "rm -f /etc/NetworkManager/conf.d/96-nmci-custom.conf"
        )
        nmci.nmutil.restart_NM_service()
        if context.IS_NMTUI:
            # if 'simwifi' in scenario.tags:
            #     nmci.ctx.wifi_rescan()
            time.sleep(4)
        time.sleep(0.5)


_register_tag("keyfile", keyfile_bs, keyfile_as)


def plugin_default_bs(context, scenario):
    if os.path.isfile("/etc/NetworkManager/conf.d/95-nmci-test.conf"):
        print("remove 'plugins=*' from 95-nmci-test.conf")
        context.process.run_stdout(
            "cp /etc/NetworkManager/conf.d/95-nmci-test.conf /tmp/95-nmci-test.conf"
        )
        context.process.run_stdout(
            "sed -i 's/^plugins=/#plugins=/' /etc/NetworkManager/conf.d/95-nmci-test.conf"
        )
        nmci.nmutil.restart_NM_service()


def plugin_default_as(context, scenario):
    if os.path.isfile("/etc/NetworkManager/conf.d/95-nmci-test.conf"):
        print("restore 95-nmci-test.conf")
        context.process.run_stdout(
            "mv /tmp/95-nmci-test.conf /etc/NetworkManager/conf.d/95-nmci-test.conf"
        )
        nmci.nmutil.restart_NM_service()


_register_tag("plugin_default", plugin_default_bs, plugin_default_as)


def eth3_disconnect_bs(context, scenario):
    context.process.nmcli_force("device disconnect eth3")
    context.process.run("pkill -9 -F /var/run/dhclient-eth3.pid", ignore_stderr=True)


def eth3_disconnect_as(context, scenario):
    context.process.nmcli_force("device disconnect eth3")
    # VVV Up/Down to preserve autoconnect feature
    context.process.nmcli("connection up testeth3")
    context.process.nmcli("connection down testeth3")


_register_tag("eth3_disconnect", eth3_disconnect_bs, eth3_disconnect_as)


def need_dispatcher_scripts_bs(context, scenario):
    if os.path.isfile("/tmp/nm-builddir"):
        print("install dispatcher scripts")
        context.process.run_stdout(
            "yum install -y $(cat /tmp/nm-builddir)/noarch/NetworkManager-dispatcher-routing-rules*",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    else:
        nmci.veth.wait_for_testeth0()
        print("install NetworkManager-config-routing-rules")
        context.process.run_stdout(
            "yum -y install NetworkManager-config-routing-rules",
            timeout=120,
            ignore_stderr=True,
        )
    nmci.nmutil.reload_NM_service()


def need_dispatcher_scripts_as(context, scenario):
    nmci.veth.wait_for_testeth0()
    context.process.run_stdout(
        "yum -y remove NetworkManager-config-routing-rules",
        timeout=120,
        ignore_stderr=True,
    )
    context.process.run_stdout("rm -rf /etc/sysconfig/network-scripts/rule-con_general")
    context.process.run_stdout(
        "rm -rf /etc/sysconfig/network-scripts/route-con_general"
    )
    context.process.run("ip rule del table 1", ignore_stderr=True)
    context.process.run("ip rule del table 1", ignore_stderr=True)
    nmci.nmutil.reload_NM_service()


_register_tag(
    "need_dispatcher_scripts", need_dispatcher_scripts_bs, need_dispatcher_scripts_as
)


def logging_bs(context, scenario):
    context.loggin_level = context.process.nmcli("-t -f LEVEL general logging").strip()


def logging_as(context, scenario):
    print("---------------------------")
    print("setting log level back")
    context.process.nmcli(f"g log level {context.loggin_level} domains ALL")


_register_tag("logging", logging_bs, logging_as)


def netservice_bs(context, scenario):
    context.process.run_stdout("pkill -9 /sbin/dhclient")
    # Make orig- devices unmanaged as they may be unfunctional
    devs = context.process.nmcli("-g DEVICE device").strip().split("\n")
    for dev in devs:
        if dev.startswith("orig"):
            context.process.nmcli_force(f"device set {dev} managed off")
    nmci.nmutil.restart_NM_service()
    context.process.systemctl("restart network.service")
    nmci.veth.wait_for_testeth0()
    time.sleep(1)


def netservice_as(context, scenario):
    print("Attaching network.service log")
    data = nmci.misc.journal_show(
        "network",
        cursor=context.log_cursor,
        prefix="~~~~~~~~~~~~~~~~~~~~~~~~~~ NETWORK SRV LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        journal_args="-o cat",
    )
    nmci.embed.embed_data("NETSRV", data)


_register_tag("netservice", netservice_bs, netservice_as)


def tag8021x_bs(context, scenario):
    if not os.path.isfile("/tmp/nm_8021x_configured"):
        if context.arch == "s390x":
            # TODO move to envsetup
            print("install hostapd.el7 on s390x")
            context.process.run_stdout(
                "[ -x /usr/sbin/hostapd ] || (yum -y install 'https://vbenes.fedorapeople.org/NM/hostapd-2.6-7.el7.s390x.rpm'; time.sleep 10)",
                shell=True,
                timeout=120,
                ignore_stderr=True,
            )
        nmci.prepare.setup_hostapd(context)


_register_tag("8021x", tag8021x_bs)


def tag8021x_as(context, scenario):
    nmci.prepare.teardown_hostapd(context)


_register_tag("8021x_teardown", None, tag8021x_as)


def pkcs11_bs(context, scenario):
    nmci.prepare.setup_pkcs11(context)
    context.process.run_stdout("p11-kit list-modules")
    context.process.run_stdout("softhsm2-util --show-slots")
    context.process.run_stdout(
        "pkcs11-tool --module /usr/lib64/pkcs11/libsofthsm2.so --token-label nmci -l --pin 1234 -O"
    )


_register_tag("pkcs11", pkcs11_bs)


def simwifi_bs(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")
    args = ["namespace"]
    nmci.prepare.setup_hostapd_wireless(context, args)


def simwifi_as(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")

    if context.IS_NMTUI:
        print("deleting all wifi connections")
        conns = (
            nmci.process.nmcli(
                "-t -f UUID,TYPE con show", embed_combine_tag=nmci.embed.NO_EMBED
            )
            .strip()
            .split("\n")
        )
        WIRELESS = ":802-11-wireless"
        del_conns = [c.replace(WIRELESS, "") for c in conns if c.endswith(WIRELESS)]
        if del_conns:
            print(" * deleting UUIDs: " + " ".join(del_conns))
            context.process.nmcli(["con", "del", "uuid"] + del_conns)
        else:
            print(" * no wifi connectons found")
        nmci.veth.wait_for_testeth0()


_register_tag("simwifi", simwifi_bs, simwifi_as)


def simwifi_ap_bs(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")

    context.process.run_stdout("modprobe -r mac80211_hwsim")
    if not hasattr(context, "noted"):
        context.noted = {}
    if context.process.run_stdout("iw list").strip():
        context.noted["wifi-hw_real"] = "enabled"
    else:
        context.noted["wifi-hw_real"] = "missing"

    context.process.run_stdout("modprobe mac80211_hwsim")
    context.process.systemctl("restart wpa_supplicant")
    nmci.nmutil.restart_NM_service()


def simwifi_ap_as(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")

    context.process.nmcli("radio wifi on")
    context.process.run_stdout("modprobe -r mac80211_hwsim")
    context.process.systemctl("restart wpa_supplicant")
    nmci.nmutil.restart_NM_service()


_register_tag("simwifi_ap", simwifi_ap_bs, simwifi_ap_as)


def simwifi_p2p_bs(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")

    if (
        context.rh_release_num >= [8, 0]
        and context.rh_release_num <= [8, 4]
        # "Stream" is [8,99]
        # and "Stream" not in context.rh_release
    ):
        context.process.run_stdout(
            "dnf -4 -y install "
            "https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.7-2.2.bz1693684.el8.x86_64.rpm "
            "https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.7-2.2.bz1693684.el8.x86_64.rpm ",
            timeout=120,
        )
        context.process.systemctl("restart wpa_supplicant")

    if (
        context.process.run_code(
            "ls /tmp/nm_*_supp_configured", shell=True, ignore_stderr=True
        )
        == 0
    ):
        print(" ** need to remove previous setup")
        nmci.prepare.teardown_hostapd_wireless(context)

    context.process.run_stdout("modprobe -r mac80211_hwsim")
    time.sleep(1)

    # This should be good as dynamic addresses are now used
    # context.process.run_stdout("echo -e '[device-wifi]\nwifi.scan-rand-mac-address=no' > /etc/NetworkManager/conf.d/95-nmci-wifi.conf")
    # context.process.run_stdout("echo -e '[connection-wifi]\nwifi.cloned-mac-address=preserve' >> /etc/NetworkManager/conf.d/95-nmci-wifi.conf")

    # this need to be done before NM restart, otherwise there is a race between NM and wpa_supp
    context.process.systemctl("restart wpa_supplicant")
    # This is workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1752780
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/95-nmci-wifi.conf",
        ["[device]", "match-device=interface-name:wlan1", "managed=0"],
    )

    nmci.nmutil.restart_NM_service()

    context.process.run_stdout("modprobe mac80211_hwsim")
    time.sleep(3)


def simwifi_p2p_as(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skipping as not on x86_64")

    print("---------------------------")
    if (
        context.rh_release_num >= [8, 0]
        and context.rh_release_num <= [8, 4]
        # "Stream" is [8,99]
        # and "Stream" not in context.rh_release
    ):
        if arch == "x86_64":
            print("Install patched wpa_supplicant for x86_64")
            context.process.run_stdout(
                "dnf -4 -y install https://vbenes.fedorapeople.org/NM/WPA3/wpa_supplicant{,-debuginfo,-debugsource}-2.9-8.el8.$(arch).rpm",
                shell=True,
                timeout=120,
            )
        else:
            print("Install patched wpa_supplicant")
            context.process.run_stdout(
                "dnf -4 -y install https://vbenes.fedorapeople.org/NM/rhbz1888051/wpa_supplicant{,-debuginfo,-debugsource}-2.9-3.el8.$(arch).rpm",
                shell=True,
                timeout=120,
            )
        context.process.run_stdout("dnf -y update wpa_supplicant", timeout=120)
        context.process.systemctl("restart wpa_supplicant")
    context.process.run_stdout("modprobe -r mac80211_hwsim")
    context.process.run_stdout("pkill -9 -f wpa_supplicant.*wlan1", shell=True)
    context.process.run_stdout("rm -rf /etc/NetworkManager/conf.d/95-nmci-wifi.conf")

    nmci.nmutil.restart_NM_service()


_register_tag("simwifi_p2p", simwifi_p2p_bs, simwifi_p2p_as)


def simwifi_teardown_bs(context, scenario):
    nmci.prepare.teardown_hostapd_wireless(context)
    nmci.veth.wait_for_testeth0()
    # no need to skip teardown
    # context.cext.skip("simwifi teardown skip")


_register_tag("simwifi_teardown", simwifi_teardown_bs)


def vpnc_bs(context, scenario):
    if context.arch == "s390x":
        context.cext.skip("Skipping on s390x")
    # Install under RHEL7 only
    if "Maipo" in context.rh_release:
        print("install epel-release-7")
        context.process.run_stdout(
            "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    if context.process.run_code("rpm -q NetworkManager-vpnc") != 0:
        print("install NetworkManager-vpnc")
        context.process.run_stdout(
            "yum -y install NetworkManager-vpnc",
            timeout=120,
            ignore_stderr=True,
        )
        nmci.nmutil.restart_NM_service()
    nmci.prepare.setup_racoon(context, mode="aggressive", dh_group=2)


def vpnc_as(context, scenario):
    context.process.nmcli_force("connection delete vpnc")
    nmci.prepare.teardown_racoon(context)


_register_tag("vpnc", vpnc_bs, vpnc_as)


def tcpreplay_bs(context, scenario):
    if context.arch == "s390x":
        context.cext.skip("Skipping on s390x")
    nmci.veth.wait_for_testeth0()
    # Install under RHEL7 only
    if "Maipo" in context.rh_release:
        print("install epel-release-7")
        context.process.run_stdout(
            "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    if not os.path.isfile("/usr/bin/tcpreplay"):
        print("install tcpreplay")
        context.process.run_stdout(
            "yum -y install tcpreplay", timeout=120, ignore_stderr=True
        )


_register_tag("tcpreplay", tcpreplay_bs)


def libreswan_bs(context, scenario):
    nmci.veth.wait_for_testeth0()
    if context.process.run_code("rpm -q NetworkManager-libreswan") != 0:
        context.process.run_stdout(
            "yum -y install NetworkManager-libreswan",
            timeout=120,
            ignore_stderr=True,
        )
        nmci.nmutil.restart_NM_service()

    # We need libreswan at least of version 3.17, that contains
    # commit 453167 ("pluto: ignore tentative and failed IPv6 addresses),
    # otherwise pluto would get very very confused.
    # That is RHEL 7.4, RHEL 8.0 or newer.
    swan_ver = context.process.run_stdout("rpm -q --qf '%{version}' libreswan")
    if (
        context.process.run_code(
            f"""rpm --eval '%%{{lua:
            if rpm.vercmp(\"{swan_ver}\", \"3.17\") < 0 then
                error(\"Libreswan too old\");
            end }}'"""
        )
        != 0
    ):
        context.cext.skip("Skipping with old Libreswan")

    context.process.run_stdout("/usr/sbin/ipsec --checknss")
    mode = "aggressive"
    if "ikev2" in scenario.tags:
        mode = "ikev2"
    if "main" in scenario.tags:
        mode = "main"
    nmci.prepare.setup_libreswan(context, mode, dh_group=14)


def libreswan_as(context, scenario):
    context.process.nmcli_force("connection down libreswan")
    context.process.nmcli_force("connection delete libreswan")
    nmci.prepare.teardown_libreswan(context)
    nmci.veth.wait_for_testeth0()


_register_tag("libreswan", libreswan_bs, libreswan_as)
_register_tag("ikev2")
_register_tag("main")


def openvpn_bs(context, scenario):
    context.ovpn_proc = nmci.prepare.setup_openvpn(context, scenario.tags)


def openvpn_as(context, scenario):
    # commenting this seems to fix RHEL-5420
    # nmci.veth.restore_testeth0()
    # context.process.nmcli_force("connection delete tun0")

    context.process.run(
        "pkill -F /tmp/openvpn.pid",
        shell=True,
        ignore_stderr=True,
    )


_register_tag("openvpn", openvpn_bs, openvpn_as)
_register_tag("openvpn4")
_register_tag("openvpn6")


def strongswan_bs(context, scenario):
    # Do not run on RHEL7 on s390x
    if "release 7" in context.rh_release:
        if context.arch == "s390x":
            context.cext.skip("Skipping on RHEL7 on s390x")
    nmci.veth.wait_for_testeth0()
    nmci.prepare.setup_strongswan(context)


def strongswan_as(context, scenario):
    # context.process.run_stdout("ip route del default via 172.31.70.1")
    context.process.nmcli_force("connection down strongswan")
    context.process.nmcli_force("connection delete strongswan")
    nmci.prepare.teardown_strongswan(context)
    nmci.veth.wait_for_testeth0()


_register_tag("strongswan", strongswan_bs, strongswan_as)


def vpn_as(context, scenario):
    context.process.nmcli_force("connection delete vpn")


_register_tag("vpn", None, vpn_as)


def iptunnel_bs(context, scenario):
    # Workaround for 1869538
    context.process.run_stdout("modprobe -r xfrm_interface")
    context.process.run_stdout("sh prepare/iptunnel.sh")


def iptunnel_as(context, scenario):
    context.process.run_stdout("sh prepare/iptunnel.sh teardown", ignore_stderr=True)


_register_tag("iptunnel", iptunnel_bs, iptunnel_as)


def wireguard_bs(context, scenario):
    context.process.run_stdout(
        "sh prepare/wireguard.sh", timeout=150, ignore_stderr=True
    )


_register_tag("wireguard", wireguard_bs, None)


def dracut_bs(context, scenario):
    # log dracut version to "Commands"
    context.process.run_stdout("rpm -qa dracut*", timeout=15)

    rc = context.process.run_code(
        "cd contrib/dracut; . ./setup.sh ; set -x; "
        " { time test_setup ; } &> /tmp/dracut_setup.log",
        shell=True,
        timeout=600,
    )
    nmci.embed.embed_file_if_exists(
        "Dracut setup",
        "/tmp/dracut_setup.log",
    )
    if rc != 0:
        print("dracut setup failed, doing clean !!!")
        context.process.run_stdout(
            "cd contrib/dracut; . ./setup.sh ;"
            "{ time test_clean; } &> /tmp/dracut_teardown.log",
            shell=True,
        )
        nmci.embed.embed_file_if_exists(
            "Dracut teardown",
            "/tmp/dracut_teardown.log",
        )
        assert False, "dracut setup failed"


def dracut_as(context, scenario):
    # clean an umount client_dumps
    context.process.run(
        "cd contrib/dracut/; . ./setup.sh; "
        "rm -rf $TESTDIR/client_dumps/*; "
        "umount $DEV_DUMPS; "
        "umount $DEV_LOG; ",
        shell=True,
        ignore_stderr=True,
    )
    # do not embed DHCP directly, cache output for "no free leases" check
    # nmci.embed.embed_service_log("DHCP", syslog_identifier="dhcpd")
    dhcpd_log = nmci.misc.journal_show(
        syslog_identifier="dhcpd", cursor=context.log_cursor
    )
    nmci.embed.embed_data("DHCP", dhcpd_log)
    nmci.embed.embed_service_log("RA", syslog_identifier="radvd")
    nmci.embed.embed_service_log("NFS", syslog_identifier="rpc.mountd")
    context.process.run_stdout(
        "cd contrib/dracut; . ./setup.sh; after_test", shell=True, timeout=15
    )

    for file_name in getattr(context, "dracut_files_to_restore", []):
        remote_file_name = f"/var/dracut_test/nfs/client/{file_name}"
        try:
            shutil.copy2(file_name, remote_file_name)
        except Exception:
            nmci.embed.embed_data("Exception in dracut_bs", traceback.format_exc())
    # assert when everything is embedded
    assert "no free leases" not in dhcpd_log, "DHCPD leases exhausted"


_register_tag("dracut", dracut_bs, dracut_as)


def dracut_remote_NFS_clean_as(context, scenario):
    # keep nfs service stopped as it hangs rm commands for 90s
    context.process.systemctl("stop nfs-server.service")
    context.process.run_stdout(
        ". contrib/dracut/setup.sh; "
        "rm -vrf $TESTDIR/nfs/client/etc/NetworkManager/system-connections/*; "
        "rm -vrf $TESTDIR/nfs/client/etc/NetworkManager/conf.d/50-*; "
        "rm -vrf $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-*; ",
        shell=True,
    )
    context.process.systemctl("start nfs-server.service")


_register_tag("dracut_remote_NFS_clean", None, dracut_remote_NFS_clean_as)


def dump_status_verbose_bs(context, scenario):
    nmci.util.dump_status_verbose = True


_register_tag("dump_status_verbose", dump_status_verbose_bs)


def prepare_patched_netdevsim_bs(context, scenario):
    context.process.run_stdout(
        "sh prepare/netdevsim.sh setup", timeout=600, ignore_stderr=True
    )
    nmci.ip.link_set(ifname="eth11", up=True, wait_for_device=1)

    # Wait until NetworkManager notices the device
    timeout = nmci.util.start_timeout(10)
    while timeout.loop_sleep(0.1):
        if context.process.run_search_stdout(
            "nmcli -f GENERAL.STATE device show eth11",
            "disconnected",
            ignore_stderr=True,
            ignore_returncode=True,
        ):
            return
    assert False, "Timed out waiting for eth11 to be seen by NetworkManager"


def prepare_patched_netdevsim_as(context, scenario):
    context.process.run_stdout("sh prepare/netdevsim.sh teardown", ignore_stderr=True)


_register_tag(
    "prepare_patched_netdevsim",
    prepare_patched_netdevsim_bs,
    prepare_patched_netdevsim_as,
)


def load_netdevsim_bs(context, scenario):
    context.process.run("modprobe -r netdevsim", ignore_stderr=True)
    context.process.run_stdout("modprobe netdevsim")
    context.process.run_stdout("echo 1 1 > /sys/bus/netdevsim/new_device", shell=True)
    time.sleep(1)


def load_netdevsim_as(context, scenario):
    context.process.run_stdout("modprobe -r netdevsim")
    time.sleep(1)


_register_tag("load_netdevsim", load_netdevsim_bs, load_netdevsim_as)


def attach_hostapd_log_as(context, scenario):
    if nmci.util.is_verbose():
        print("Attaching hostapd log")

        confs = context.process.run_stdout(
            "ls /etc/hostapd/wire* | sort -V", ignore_stderr=True, shell=True
        )

        services = []
        for conf in confs.strip("\n").split("\n"):
            ext = conf.split(".")[-1]
            if ext == "conf":
                services.append("nm-hostapd")
            elif len(ext):
                services.append("nm-hostapd-" + ext)

        data = "~~~~~~~~~~~~~~~~~~~~~~~~~~ HOSTAPD LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        if services:
            for service in services:
                data += nmci.misc.journal_show(
                    services,
                    short=True,
                    cursor=context.log_cursor_before_tags,
                    prefix=f"\n~~~ {service} ~~~",
                )
        else:
            data += "\ndid not find any nm-hostapd service!"
        nmci.embed.embed_data("HOSTAPD", data)


_register_tag("attach_hostapd_log", None, attach_hostapd_log_as)


def attach_wpa_supplicant_log_as(context, scenario):
    if nmci.util.is_verbose():
        print("Attaching wpa_supplicant log")
        data = nmci.misc.journal_show(
            "wpa_supplicant",
            short=True,
            cursor=context.log_cursor_before_tags,
            prefix="~~~~~~~~~~~~~~~~~~~~~~~~~~ WPA_SUPPLICANT LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        )
        nmci.embed.embed_data("WPA_SUP", data)


_register_tag("attach_wpa_supplicant_log", None, attach_wpa_supplicant_log_as)


def performance_bs(context, scenario):
    # Set the speed factor
    context.machine_speed_factor = 1
    hostname = context.process.run_stdout("hostname").strip()
    if "ci.centos" in hostname:
        print("CentOS: should be much faster")
        context.machine_speed_factor = 0.6
    elif hostname.startswith("gsm-r5s"):
        print("gsm-r5s: keeping default")
    elif hostname.startswith("wlan-r6s"):
        print("wlan-r6s: keeping the default")
    elif hostname.startswith("gsm-r6s"):
        print("gsm-r6s: multiply factor by 1.5")
        context.machine_speed_factor = 1.5
    elif hostname.startswith("wsfd-netdev"):
        context.cext.skip("wsfd-netdev: we are unpredictable here, skipping")
        return
    else:
        print(f"Unmatched: {hostname}: keeping default")
    if "fedora" in context.rh_release.lower():
        print("Fedora: multiply factor by 1.5")
        context.machine_speed_factor *= 1.5
    # Set machine perf to max
    context.process.systemctl("start tuned")
    context.process.run("tuned-adm profile throughput-performance", ignore_stderr=True)
    context.process.systemctl("stop tuned")
    context.process.systemctl("stop openvswitch")
    nmci.nmutil.restart_NM_service()
    time.sleep(5)


def performance_as(context, scenario):
    nmci.nmutil.context_set_nm_restarted(context)
    # Settings device number to 0
    context.process.run_stdout("contrib/gi/./setup.sh 0", timeout=120)
    context.nm_pid = nmci.nmutil.nm_pid()
    # Deleting all connections t-a1..t-a100
    cons = " ".join([f"t-a{i}" for i in range(1, 101)])
    context.process.nmcli_force(f"con del {cons}")
    # reset the performance profile
    context.process.systemctl("start tuned")
    context.process.run("tuned-adm profile $(tuned-adm recommend)", ignore_stderr=True)


_register_tag("performance", performance_bs, performance_as)


def preserve_8021x_certs_bs(context, scenario):
    assert (
        context.process.run_code("mkdir -p /tmp/certs/") == 0
    ), "unable to create /tmp/certs/ directory"
    assert (
        context.process.run_code(
            "cp -r contrib/8021x/certs/client/* /tmp/certs/", shell=True
        )
        == 0
    ), "unable to copy certificates"


_register_tag("preserve_8021x_certs", preserve_8021x_certs_bs)


def pptp_bs(context, scenario):
    if context.arch == "s390x":
        context.cext.skip("Skipping on s390x")

    # Load ppp_generic to avoid first test failure
    context.process.run_code("modprobe ppp_generic", ignore_stderr=True, timeout=120)

    nmci.veth.wait_for_testeth0()
    # Install under RHEL7 only
    if "Maipo" in context.rh_release:
        print("install epel-release-7")
        context.process.run_stdout(
            "[ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
            shell=True,
            timeout=120,
            ignore_stderr=True,
        )
    context.process.run_stdout(
        "[ -x /usr/sbin/pptpd ] || yum -y install /usr/sbin/pptpd",
        shell=True,
        timeout=120,
        ignore_stderr=True,
    )
    context.process.run_stdout(
        "rpm -q NetworkManager-pptp || yum -y install NetworkManager-pptp",
        shell=True,
        timeout=120,
        ignore_stderr=True,
    )

    context.process.run_stdout("rm -f /etc/ppp/ppp-secrets")
    nmci.util.file_set_content("/etc/ppp/chap-secrets", ["budulinek pptpd passwd *"])

    if not os.path.isfile("/tmp/nm_pptp_configured"):
        nmci.util.file_set_content(
            "/etc/pptpd.conf",
            [
                "# pptpd configuration for client testing",
                "option /etc/ppp/options.pptpd",
                "logwtmp",
                "localip 172.31.66.6",
                "remoteip 172.31.66.60-69",
                "ms-dns 8.8.8.8",
                "ms-dns 8.8.4.4",
            ],
        )

        context.process.systemctl("unmask pptpd")
        context.process.systemctl("restart pptpd")
        context.process.run_stdout(
            "echo 'require-mppe-128' >> /etc/ppp/options.pptpd",
            shell=True,
        )

        time.sleep(0.5)

        context.pexpect_service("/sbin/pppd pty '/sbin/pptp 127.0.0.1' nodetach")
        nmci.util.file_set_content("/tmp/nm_pptp_configured", "")

        time.sleep(1)


def pptp_as(context, scenario):
    context.process.nmcli_force("connection delete pptp")


_register_tag("pptp", pptp_bs, pptp_as)


def firewall_bs(context, scenario):
    if context.process.run_code("rpm -q firewalld") != 0:
        print("install firewalld")
        nmci.veth.wait_for_testeth0()
        context.process.run_stdout(
            "yum -y install firewalld", timeout=120, ignore_stderr=True
        )
    # configure log verbosity
    log_level = "4"
    override_file = "/etc/systemd/system/firewalld.service.d/30-firewalld-debug.conf"
    override = f"[Service]\nEnvironment=FIREWALLD_ARGS=--debug={log_level}\n"
    service_cat = nmci.process.run_stdout("systemctl cat firewalld.service")
    if f"FIREWALLD_ARGS=--debug={log_level}" not in service_cat:
        os.makedirs(os.path.dirname(override_file), exist_ok=True)
        nmci.util.file_set_content(override_file, override)
        nmci.process.systemctl("daemon-reload")

    context.process.systemctl("unmask firewalld")
    time.sleep(1)
    context.process.systemctl("stop firewalld")
    time.sleep(5)
    context.process.systemctl("start firewalld")
    nmci.process.run("firewall-cmd --zone=public --add-port=80/tcp --add-port=8080/tcp")
    # can fail in @sriov_con_drv_add_VF_firewalld
    context.process.nmcli_force("con modify testeth0 connection.zone public")
    # Add a sleep here to prevent firewalld to hang
    # (see https://bugzilla.redhat.com/show_bug.cgi?id=1495893)
    time.sleep(1)


def firewall_as(context, scenario):
    context.process.run_stdout("firewall-cmd --panic-off", ignore_stderr=True)
    context.process.run_stdout(
        "firewall-cmd --permanent --remove-port=51820/udp --zone=public",
        ignore_stderr=True,
    )
    context.process.run_stdout(
        "firewall-cmd --permanent --zone=public --remove-masquerade",
        ignore_stderr=True,
    )
    context.process.systemctl("stop firewalld")
    nmci.embed.embed_service_log("firewalld", syslog_identifier="firewalld")


_register_tag("firewall", firewall_bs, firewall_as)


def restore_hostname_bs(context, scenario):
    context.original_hostname = context.process.run_stdout("hostname").strip()


def restore_hostname_as(context, scenario):
    context.process.systemctl("unmask systemd-hostnamed.service")
    context.process.systemctl("unmask dbus-org.freedesktop.hostname1.service")
    if context.IS_NMTUI:
        nmci.util.file_set_content("/etc/hostname", ["localhost.localdomain"])
    else:
        context.process.run_stdout(
            'hostnamectl set-hostname --transient ""', ignore_stderr=True
        )
        context.process.run_stdout(
            f"hostnamectl set-hostname --static {context.original_hostname}"
        )
    context.process.run_stdout(
        "rm -rf /etc/NetworkManager/conf.d/90-nmci-hostname.conf"
    )
    context.process.run_stdout("rm -rf /etc/dnsmasq.d/dnsmasq_custom.conf")
    nmci.nmutil.reload_NM_service()
    nmci.veth.wait_for_testeth0()


_register_tag("restore_hostname", restore_hostname_bs, restore_hostname_as)


def runonce_bs(context, scenario):
    context.process.systemctl("stop network")
    # TODO check: this should be done by @eth0
    context.process.nmcli_force("device disconnect eth0")
    context.process.run("pkill -9 dhclient", ignore_stderr=True)
    context.process.run("pkill -9 nm-iface-helper", ignore_stderr=True)
    context.process.systemctl("stop firewalld")
    context.nm_pid_refresh_count = 1000


def runonce_as(context, scenario):
    context.process.run_stdout(
        "for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True
    )
    context.process.run_stdout(
        "rm -rf /etc/NetworkManager/conf.d/01-nmci-run-once.conf"
    )
    time.sleep(1)
    nmci.nmutil.restart_NM_service()
    time.sleep(1)
    context.process.run_stdout(
        "for i in $(pidof nm-iface-helper); do kill -9 $i; done", shell=True
    )
    # TODO check: is this neccessary?
    context.process.nmcli_force("connection delete con_general")
    context.process.nmcli_force("device disconnect eth10")
    nmci.veth.wait_for_testeth0()


_register_tag(
    "runonce",
    runonce_bs,
    runonce_as,
    priority=nmci.Cleanup.PRIORITY_NM_SERVICE_START - 1,
)


def slow_team_bs(context, scenario):
    if context.arch != "x86_64":
        context.cext.skip("Skippin as not on x86_64")
    context.process.run_stdout(
        "for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done",
        shell=True,
    )
    context.process.run_stdout(
        "yum -y install https://vbenes.fedorapeople.org/NM/slow_libteam-1.25-5.el7_4.1.1.x86_64.rpm https://vbenes.fedorapeople.org/NM/slow_teamd-1.25-5.el7_4.1.1.x86_64.rpm",
        timeout=120,
        ignore_stderr=True,
    )
    if context.process.run_code("rpm --quiet -q teamd") != 0:
        # Restore teamd package if we don't have the slow ones
        context.process.run_stdout(
            "for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done",
            shell=True,
        )
        context.process.run_stdout(
            "yum -y install teamd libteam", timeout=120, ignore_stderr=True
        )
        context.cext.skip("Skipping as unable to install slow_team")
    nmci.nmutil.reload_NM_service()


def slow_team_as(context, scenario):
    context.process.run_stdout(
        "for i in $(rpm -qa |grep team|grep -v Netw); do rpm -e $i --nodeps; done",
        shell=True,
    )
    context.process.run_stdout(
        "yum -y install teamd libteam", timeout=120, ignore_stderr=True
    )
    nmci.nmutil.reload_NM_service()


_register_tag("slow_team", slow_team_bs, slow_team_as)


def openvswitch_bs(context, scenario):
    if context.arch == "s390x" and "Ootpa" not in context.rh_release:
        context.cext.skip("Skipping as on s390x and not Ootpa")
    if context.process.run_code("rpm -q NetworkManager-ovs") != 0:
        print("install NetworkManager-ovs")
        context.process.run_stdout(
            "yum -y install NetworkManager-ovs", timeout=120, ignore_stderr=True
        )
        context.process.systemctl("daemon-reload")
    print("Start openvswitch")
    context.process.systemctl("reset-failed openvswitch")
    context.process.systemctl("start openvswitch")
    nmci.nmutil.restart_NM_service()


def openvswitch_as(context, scenario):
    if not os.path.isfile("/tmp/nm_dcb_inf_wol_sriov_configured"):
        nmci.embed.embed_file_if_exists(
            "OVSDB Log",
            "/var/log/openvswitch/ovsdb-server.log",
        )
        nmci.embed.embed_file_if_exists(
            "OVSDaemon Log",
            "/var/log/openvswitch/ovs-vswitchd.log",
        )

        # Restart in case we have openvswitch stopped from the test
        if context.process.systemctl("is-active openvswitch").returncode != 0:
            context.process.systemctl("restart openvswitch")
        nmci.nmutil.stop_NM_service()

        context.process.run(
            "for br in $(ovs-vsctl list-br); do ovs-vsctl del-br $br; done",
            ignore_stderr=True,
            shell=True,
        )
        context.process.run(
            "ovs-vsctl list-br",
            ignore_stderr=True,
        )

        context.process.systemctl("stop openvswitch")
        time.sleep(1)
        nmci.nmutil.restart_NM_service()


_register_tag("openvswitch", openvswitch_bs, openvswitch_as)


def dpdk_bs(context, scenario):
    if not os.path.isfile("/tmp/nm_dpdk_configured"):
        context.process.run_stdout("sysctl -w vm.nr_hugepages=10")
        context.process.run_stdout(
            "if ! rpm -q --quiet dpdk dpdk-tools; then yum -y install dpdk dpdk-tools; fi",
            shell=True,
            timeout=120,
        )
        context.process.run_stdout(
            "sed -i.bak s/openvswitch:hugetlbfs/root:root/g /etc/sysconfig/openvswitch"
        )
        context.process.run_stdout(
            "ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true"
        )
        context.process.run_stdout("modprobe vfio-pci")
        context.process.run_stdout(
            "echo 1 > /sys/module/vfio/parameters/enable_unsafe_noiommu_mode",
            shell=True,
        )

        # Create two VFs from p4p1 device
        context.process.run_stdout(
            "echo 2 > /sys/class/net/p4p1/device/sriov_numvfs",
            shell=True,
            timeout=5,
        )

        # Wait for some time to settle things down
        time.sleep(2)

        # Moving those two VFs from ixgbevf to vfio-pci driver
        # In newer versions of dpdk-tools there are dpdk binaries with py in the end
        context.process.run_stdout(
            "dpdk-devbind -b vfio-pci 0000:42:10.0 || dpdk-devbind.py -b vfio-pci 0000:42:10.0",
            shell=True,
            ignore_stderr=True,
        )
        context.process.run_stdout(
            "dpdk-devbind -b vfio-pci 0000:42:10.2 || dpdk-devbind.py -b vfio-pci 0000:42:10.2",
            shell=True,
            ignore_stderr=True,
        )
        # We need to restart openvswitch as we changed configuration
        context.process.systemctl("restart openvswitch")
        nmci.util.file_set_content("/tmp/nm_dpdk_configured", "")


_register_tag("dpdk", dpdk_bs, None)


def dpdk_remove_as(context, scenario):
    if os.path.isfile("/tmp/nm_dpdk_configured"):
        # Return vfio-pci devices back to ixgbevf
        context.process.run_stdout(
            "dpdk-devbind -b vfio-pci 0000:42:10.0 || dpdk-devbind.py -b ixgbevf 0000:42:10.0",
            shell=True,
            ignore_stderr=True,
        )
        context.process.run_stdout(
            "dpdk-devbind -b vfio-pci 0000:42:10.2 || dpdk-devbind.py -b ixgbevf 0000:42:10.2",
            shell=True,
            ignore_stderr=True,
        )

        # Remove two VFs from p4p1 device
        context.process.run_stdout(
            "echo 0 > /sys/class/net/p4p1/device/sriov_numvfs",
            shell=True,
            timeout=5,
        )
        os.remove("/tmp/nm_dpdk_configured")


_register_tag("dpdk_remove", None, dpdk_remove_as)


def wireless_certs_bs(context, scenario):
    context.process.run_stdout("mkdir -p /tmp/certs")
    if not os.path.isfile("/tmp/certs/eaptest_ca_cert.pem"):
        context.process.run_stdout(
            "wget http://hpe-dl380pgen9-02.wlan.rhts.eng.bos.redhat.com/ca.pem -q -O /tmp/certs/eaptest_ca_cert.pem"
        )
    if not os.path.isfile("/tmp/certs/client.pem"):
        context.process.run_stdout(
            "wget http://hpe-dl380pgen9-02.wlan.rhts.eng.bos.redhat.com/client.pem -q -O /tmp/certs/client.pem"
        )


_register_tag("wireless_certs", wireless_certs_bs)


def selinux_allow_ifup_bs(context, scenario):
    if not context.process.run_search_stdout("semodule -l", "ifup_policy"):
        context.process.run_stdout(
            "semodule -i contrib/selinux-policy/ifup_policy.pp",
            timeout=40,
        )


_register_tag("selinux_allow_ifup", selinux_allow_ifup_bs)


def no_testeth10_bs(context, scenario):
    context.process.nmcli_force("connection delete testeth10")


_register_tag("no_testeth10", no_testeth10_bs)


def pppoe_bs(context, scenario):
    pass
    if context.arch == "aarch64":
        if not context.process.run_search_stdout("semodule -l", "pppd"):
            print("enable pppd selinux policy on aarch64")
            context.process.run_stdout(
                "semodule -i contrib/selinux-policy/pppd.pp",
                timeout=40,
            )
    if not os.path.isabs("/dev/ppp"):
        context.process.run("mknod /dev/ppp c 108 0")


def pppoe_as(context, scenario):
    context.process.run_stdout("kill $(pidof pppoe-server)", shell=True)
    # Give pppoe-server a bit time to clean after itslef when terminated
    time.sleep(1)


_register_tag("pppoe", pppoe_bs, pppoe_as)


def del_test1112_veths_bs(context, scenario):
    nmci.cleanup.add_iface("test11")
    nmci.cleanup.add_udev_rule("/etc/udev/rules.d/99-veths.rules")
    rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test11|test12", ENV{NM_UNMANAGED}="0"'
    nmci.util.file_set_content("/etc/udev/rules.d/99-veths.rules", [rule])
    nmci.util.update_udevadm()


_register_tag("del_test1112_veths", del_test1112_veths_bs)


def nmstate_bs(context, scenario):
    context.process.run("yum -y remove nmstate nispor", ignore_stderr=True, timeout=120)
    context.process.run_stdout("yum -y install nmstate", timeout=120)


def nmstate_as(context, scenario):
    context.process.run_stdout(
        "sh contrib/reproducers/repro_1923248.sh clean", ignore_stderr=True
    )
    # Workaround for RHBZ#1935026
    context.process.run("ovs-vsctl del-br ovs-br0", ignore_stderr=True)


_register_tag("nmstate", nmstate_bs, nmstate_as)


def nmstate_setup_as(context, scenario):
    # There might be some podman residuals, delete them.
    context.process.nmcli_force("con del cni-podman0")
    context.process.nmcli_force("dev del cni-podman0")
    # Embed NMSTATE logs.
    nmci.embed.embed_file_if_exists("NMSTATE", "/tmp/nmstate.txt", fail_only=True)


_register_tag("nmstate_setup", None, nmstate_setup_as)


def nmstate_libreswan_bs(context, scenario):
    if context.rh_release_num == [9, 2]:
        context.process.run_stdout(
            "dnf -4 -y update \
            $(contrib/utils/brew_links.sh nmstate 2.2.23 1.el9_2) \
            $(contrib/utils/brew_links.sh NetworkManager-libreswan 1.2.14 3.el9_2)",
            timeout=120,
            shell=True,
            ignore_stderr=True,
        )
    if context.rh_release_num == [9, 3]:
        context.process.run_stdout(
            "dnf -4 -y update \
            $(contrib/utils/brew_links.sh nmstate 2.2.23 1.el9_3) \
            $(contrib/utils/brew_links.sh NetworkManager-libreswan 1.2.14 3.el9_3)",
            timeout=120,
            shell=True,
            ignore_stderr=True,
        )
    if context.rh_release_num == [9, 4]:
        context.process.run_stdout(
            "dnf -4 -y update \
            $(contrib/utils/brew_links.sh nmstate 2.2.23 1.el9) \
            $(contrib/utils/brew_links.sh NetworkManager-libreswan 1.2.18 2.el9)",
            timeout=120,
            shell=True,
            ignore_stderr=True,
        )
    if context.rh_release_num == [9, 99]:
        kojihub = "https://kojihub.stream.centos.org/kojifiles/packages/"
        context.process.run_stdout(
            f"dnf -4 -y update \
            {kojihub}nmstate/2.2.23/1.el9/x86_64/nmstate-2.2.23-1.el9.x86_64.rpm \
            {kojihub}nmstate/2.2.23/1.el9/x86_64/nmstate-libs-2.2.23-1.el9.x86_64.rpm \
            {kojihub}nmstate/2.2.23/1.el9/x86_64/python3-libnmstate-2.2.23-1.el9.x86_64.rpm \
            {kojihub}NetworkManager-libreswan/1.2.18/2.el9/x86_64/NetworkManager-libreswan-1.2.18-2.el9.x86_64.rpm",
            timeout=120,
            shell=True,
            ignore_stderr=True,
        )

    nmci.nmutil.restart_NM_service()


def nmstate_libreswan_as(context, scenario):
    # Embed NMSTATE logs.
    nmci.embed.embed_file_if_exists("NMSTATE", "/tmp/nmstate.txt", fail_only=True)


_register_tag("nmstate_libreswan", nmstate_libreswan_bs, nmstate_libreswan_as)


def backup_sysconfig_network_bs(context, scenario):
    context.process.run_stdout("cp -f /etc/sysconfig/network /tmp/sysnetwork.backup")


def backup_sysconfig_network_as(context, scenario):
    context.process.run_stdout("mv -f /tmp/sysnetwork.backup /etc/sysconfig/network")
    nmci.nmutil.reload_NM_connections()
    context.process.nmcli_force("connection down testeth9")


_register_tag(
    "backup_sysconfig_network", backup_sysconfig_network_bs, backup_sysconfig_network_as
)


def remove_fedora_connection_checker_bs(context, scenario):
    nmci.veth.wait_for_testeth0()
    context.process.run(
        "yum -y remove NetworkManager-config-connectivity-fedora",
        ignore_stderr=True,
        timeout=120,
    )
    nmci.nmutil.reload_NM_service()


_register_tag("remove_fedora_connection_checker", remove_fedora_connection_checker_bs)


def need_config_server_bs(context, scenario):
    if context.process.run_code("rpm -q NetworkManager-config-server") == 0:
        context.remove_config_server = False
    else:
        print("Install NetworkManager-config-server")
        context.process.run_stdout(
            "yum -y install NetworkManager-config-server", timeout=120
        )
        nmci.nmutil.reload_NM_service()
        context.remove_config_server = True


def need_config_server_as(context, scenario):
    if context.remove_config_server:
        print("removing NetworkManager-config-server")
        context.process.run_stdout(
            "yum -y remove NetworkManager-config-server", timeout=120
        )
        nmci.cleanup.add_NM_service("restart")


_register_tag("need_config_server", need_config_server_bs, need_config_server_as)


def no_config_server_bs(context, scenario):
    if context.process.run_code("rpm -q NetworkManager-config-server") == 1:
        context.restore_config_server = False
    else:
        # context.process.run_stdout('yum -y remove NetworkManager-config-server')
        config_files = (
            context.process.run_stdout("rpm -ql NetworkManager-config-server")
            .strip()
            .split("\n")
        )
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file):
                print(f"* disabling file: {config_file}")
                context.process.run_stdout(f"mv -f {config_file} {config_file}.off")
        nmci.nmutil.reload_NM_service()
        context.restore_config_server = True


def no_config_server_as(context, scenario):
    if context.restore_config_server:
        config_files = (
            context.process.run_stdout("rpm -ql NetworkManager-config-server")
            .strip()
            .split("\n")
        )
        for config_file in config_files:
            config_file = config_file.strip()
            if os.path.isfile(config_file + ".off"):
                print(f"* enabling file: {config_file}")
                context.process.run_stdout(f"mv -f {config_file}.off {config_file}")
        nmci.cleanup.add_NM_service("restart")
    conns = (
        nmci.process.nmcli("-t -f UUID,NAME c", embed_combine_tag=nmci.embed.NO_EMBED)
        .strip()
        .split("\n")
    )
    # UUID has fixed length, 36 characters
    uuids = [c[:36] for c in conns if c and "testeth" not in c]
    if uuids:
        print("* delete connections with UUID in: " + " ".join(uuids))
        context.process.nmcli(["con", "del"] + uuids)


_register_tag("no_config_server", no_config_server_bs, no_config_server_as)


def permissive_bs(context, scenario):
    context.enforcing = False
    if context.process.run_search_stdout("getenforce", "Enforcing"):
        print("WORKAROUND for permissive selinux")
        context.enforcing = True
        context.process.run_stdout("setenforce 0")


def permissive_as(context, scenario):
    if context.enforcing:
        print("WORKAROUND for permissive selinux")
        context.process.run_stdout("setenforce 1")


_register_tag("permissive", permissive_bs, permissive_as)


def tcpdump_bs(context, scenario):
    nmci.util.file_set_content(
        "/tmp/network-traffic.log",
        ["~~~~~~~~~~~~~~~~~~~~~~~~~~ TRAFFIC LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"],
    )
    context.pexpect_service(
        "tcpdump -nne -i any >> /tmp/network-traffic.log", shell=True
    )


def tcpdump_as(context, scenario):
    print("Attaching traffic log")
    context.process.run("pkill -1 tcpdump")
    if os.stat("/tmp/network-traffic.log").st_size < 20000000:
        traffic = nmci.util.file_get_content_simple("/tmp/network-traffic.log")
    else:
        traffic = "WARNING: 20M size exceeded in /tmp/network-traffic.log, skipping"
    nmci.embed.embed_data("TRAFFIC", traffic, fail_only=True)

    context.process.run("pkill -9 tcpdump")


_register_tag("tcpdump", tcpdump_bs, tcpdump_as)


def wifi_as(context, scenario):
    if context.IS_NMTUI:
        context.process.nmcli_force(
            "connection delete id wifi wifi1 qe-open qe-wpa1-psk qe-wpa2-psk qe-wpa3-psk qe-wep"
        )
        # context.process.run_stdout("service NetworkManager restart") # debug restart to overcome the nmcli d w l flickering
    else:
        # context.process.run_stdout('nmcli device disconnect wlan0')
        context.process.nmcli_force(
            "con del wifi qe-open qe-wep qe-wep-psk qe-wep-enterprise qe-wep-enterprise-cisco"
        )
        context.process.nmcli_force(
            "con del qe-wpa1-psk qe-wpa2-psk qe-wpa3-psk qe-wpa1-enterprise qe-wpa2-enterprise qe-hidden-wpa2-psk"
        )
        context.process.nmcli_force("con del qe-adhoc qe-ap wifi-wlan0")
        if "novice" in scenario.tags:
            # context.prompt.close()
            time.sleep(1)
            context.process.nmcli_force("con del wifi-wlan0")


_register_tag("wifi", None, wifi_as)
_register_tag("novice")


def no_connections_bs(context, scenario):
    nmci.process.nmcli(
        ["con", "del", *[c["name"] for c in nmci.nmutil.connection_show()]]
    )


def no_connections_as(context, scenario):
    if context.IS_NMTUI:
        nmci.veth.restore_connections()
        nmci.veth.wait_for_testeth0()


_register_tag("no_connections", no_connections_bs, no_connections_as)


def teamd_as(context, scenario):
    context.process.systemctl("stop teamd")
    context.process.systemctl("reset-failed teamd")


_register_tag("teamd", None, teamd_as)


def restore_eth_mtu_as(context, scenario, num):
    nmci.ip.link_set(ifname=f"eth{num}", mtu="1500")


for i in [1, 7]:
    _register_tag(f"restore_eth{i}_mtu", None, restore_eth_mtu_as, {"num": i})


def wifi_rescan_as(context, scenario):
    if context.IS_NMTUI:
        nmci.nmutil.restart_NM_service()
        nmci.veth.wifi_rescan()


_register_tag("wifi_rescan", None, wifi_rescan_as)


def testeth7_disconnect_as(context, scenario):
    if "testeth7" in context.process.nmcli("connection show -a"):
        print("bring down testeth7")
        context.process.nmcli("con down testeth7")


_register_tag("testeth7_disconnect", None, testeth7_disconnect_as)


def checkpoint_remove_as(context, scenario):
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


def clean_iptables_as(context, scenario):
    context.process.run_stdout("iptables -D OUTPUT -p udp --dport 67 -j REJECT")


_register_tag("clean_iptables", None, clean_iptables_as)


def kill_dhclient_custom_as(context, scenario):
    time.sleep(0.5)
    context.process.run("pkill -F /tmp/dhclient_custom.pid")
    context.process.run_stdout("rm -f /tmp/dhclient_custom.pid")


_register_tag("kill_dhclient_custom", None, kill_dhclient_custom_as)


def networking_on_as(context, scenario):
    context.process.nmcli("networking on")
    nmci.veth.wait_for_testeth0()


_register_tag("networking_on", None, networking_on_as)


def adsl_as(context, scenario):
    context.process.nmcli_force("connection delete id adsl-test11 adsl")


_register_tag("adsl", None, adsl_as)


def allow_veth_connections_bs(context, scenario):
    rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="veth*", ENV{NM_UNMANAGED}="0"'
    nmci.util.file_set_content("/etc/udev/rules.d/99-veths.rules", [rule])
    nmci.util.update_udevadm()
    context.process.run_stdout("rm -rf /var/lib/NetworkManager/no-auto-default.state")
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/95-nmci-unmanaged.conf",
        ["[main]", "no-auto-default=eth*"],
    )
    nmci.nmutil.reload_NM_service()


def no_auto_default_bs(context, scenario):
    nmci.util.file_set_content(
        "/etc/NetworkManager/conf.d/95-nmci-no-auto-default.conf",
        ["[main]", "no-auto-default=*"],
    )
    nmci.nmutil.reload_NM_service()


def no_auto_default_as(context, scenario):
    c_file = "/etc/NetworkManager/conf.d/95-nmci-no-auto-default.conf"
    if os.path.isfile(c_file):
        os.remove(c_file)
        nmci.nmutil.reload_NM_service()


_register_tag("no_auto_default", no_auto_default_bs, no_auto_default_as)


def allow_veth_connections_as(context, scenario):
    context.process.run_stdout("rm -rf /etc/udev/rules.d/99-veths.rules")
    context.process.run_stdout(
        "rm -rf /etc/NetworkManager/conf.d/95-nmci-unmanaged.conf"
    )
    nmci.util.update_udevadm()
    nmci.nmutil.reload_NM_service()
    devs = nmci.process.nmcli(
        "-t -f DEVICE c s -a", embed_combine_tag=nmci.embed.NO_EMBED
    )
    for dev in devs.strip().split("\n"):
        if dev and dev != "eth0":
            context.process.nmcli(f"device disconnect {dev}")

    connections = nmci.process.nmcli(
        "-t -f NAME c s", embed_combine_tag=nmci.embed.NO_EMBED
    )
    for connection in connections.strip().split("\n"):
        if connection and "Wired" in connection:
            context.process.nmcli(f"connection delete '{connection}'")


_register_tag(
    "allow_veth_connections", allow_veth_connections_bs, allow_veth_connections_as
)


def con_ipv6_ifcfg_remove_as(context, scenario):
    # context.process.nmcli_force("connection delete id con_ipv6 con_ipv62")
    context.process.run_stdout("rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv6")
    context.process.nmcli("con reload")


_register_tag("con_ipv6_ifcfg_remove", None, con_ipv6_ifcfg_remove_as)


def tuntap_as(context, scenario):
    context.process.run_stdout("ip link del tap0")


_register_tag("tuntap", None, tuntap_as)


def remove_tombed_connections_as(context, scenario):
    tombs = []
    for dir in [
        "/etc/NetworkManager/system-connections/",
        "/var/run/NetworkManager/system-connections/",
    ]:
        tombs.extend(glob.glob(f"{dir}*.nmmeta"))
        cons = []
    for tomb in tombs:
        print(tomb)
        con_id = tomb.split("/")[-1]
        con_id = con_id.split(".")[0]
        cons.append(con_id)
        print(f"removing tomb file {tomb}")
        context.process.run_stdout(f"rm -f {tomb}")
    if cons:
        print("removing connections: " + " ".join(cons))
        context.process.nmcli("con reload")
        context.process.nmcli(["con", "delete"] + cons)


_register_tag("remove_tombed_connections", None, remove_tombed_connections_as)


def flush_300_as(context, scenario):
    context.process.run("ip route flush table 300", ignore_stderr=True)


_register_tag("flush_300", None, flush_300_as)


def stop_radvd_as(context, scenario):
    context.process.systemctl("stop radvd")
    context.process.run_stdout("rm -rf /etc/radvd.conf")


_register_tag("stop_radvd", None, stop_radvd_as)


def dcb_as(context, scenario):
    context.process.nmcli_force("connection delete id dcb")


_register_tag("dcb", None, dcb_as)


def mtu_as(context, scenario):
    context.process.nmcli("connection modify testeth1 802-3-ethernet.mtu 1500")
    context.process.nmcli("connection up id testeth1")
    context.process.nmcli("connection modify testeth1 802-3-ethernet.mtu 0")
    context.process.nmcli("connection down id testeth1")
    context.process.run_stdout("ip link set dev eth1 mtu 1500")
    context.process.run_stdout("ip link set dev eth2 mtu 1500")
    context.process.run_stdout("ip link set dev eth3 mtu 1500")

    context.process.nmcli_force("connection delete id tc1 tc2 tc16 tc26")
    context.process.run("ip link delete test1", ignore_stderr=True)
    context.process.run("ip link delete test2", ignore_stderr=True)
    context.process.run("ip link delete test10", ignore_stderr=True)
    context.process.run("ip link delete test11", ignore_stderr=True)
    context.process.run("ip link del vethbr", ignore_stderr=True)
    context.process.run("ip link del vethbr6", ignore_stderr=True)
    context.process.run("pkill -9 -f /usr/sbin/dns.*192.168")
    context.process.run("pkill -9 -f /usr/sbin/dns.*192.168")


_register_tag("mtu", None, mtu_as)


def macsec_as(context, scenario):
    context.process.run_stdout("pkill -F /tmp/wpa_supplicant_ms.pid")
    context.process.run_stdout("pkill -F /tmp/dnsmasq_ms.pid")


_register_tag("macsec", None, macsec_as)


def dhcpd_as(context, scenario):
    context.process.systemctl("stop dhcpd")


_register_tag("dhcpd", None, dhcpd_as)


def kill_dnsmasq_from_pid_file(pid_file):
    def finished(pid):
        try:
            os.kill(pid, 0)
        except OSError:
            # process with this PID doesn't exist (any more)
            return True
        return False

    def try_kill(pid, signal):
        try:
            os.kill(pid, signal)
        except ProcessLookupError:
            pass

    if os.path.isfile(pid_file):
        try:
            pid = int(nmci.util.file_get_content_simple(pid_file))
        except FileNotFoundError:
            return
        try_kill(pid, 15)
        time.sleep(0.2)
        for i in range(5):
            if finished(pid):
                return
            time.sleep(1)
        try_kill(pid, 9)


def kill_dnsmasq_vlan_as(context, scenario):
    log_file = "/tmp/dnsmasq_vlan.log"
    if nmci.embed.embed_file_if_exists("dnsmasq_vlan.log", log_file, fail_only=True):
        os.remove(log_file)
    kill_dnsmasq_from_pid_file("/tmp/dnsmasq_vlan.pid")


_register_tag("kill_dnsmasq_vlan", None, kill_dnsmasq_vlan_as)


def kill_dnsmasq_ip4_as(context, scenario):
    log_file = "/tmp/dnsmasq_ip4.log"
    if nmci.embed.embed_file_if_exists("dnsmasq_ip4.log", log_file, fail_only=True):
        os.remove(log_file)
    kill_dnsmasq_from_pid_file("/tmp/dnsmasq_ip4.pid")


_register_tag("kill_dnsmasq_ip4", None, kill_dnsmasq_ip4_as)


def kill_dnsmasq_ip6_as(context, scenario):
    log_file = "/tmp/dnsmasq_ip6.log"
    if nmci.embed.embed_file_if_exists("dnsmasq_ip6.log", log_file, fail_only=True):
        os.remove(log_file)
    kill_dnsmasq_from_pid_file("/tmp/dnsmasq_ip6.pid")


_register_tag("kill_dnsmasq_ip6", None, kill_dnsmasq_ip6_as)


def kill_dhcrelay_as(context, scenario):
    context.process.run_stdout("pkill -F /tmp/dhcrelay.pid")


_register_tag("kill_dhcrelay", None, kill_dhcrelay_as)


def profie_as(context, scenario):
    context.process.nmcli_force("connection delete id profie")


_register_tag("profie", None, profie_as)


def peers_ns_as(context, scenario):
    context.process.run_stdout("ip netns del peers")
    # sleep(TIMER)


_register_tag("peers_ns", None, peers_ns_as)


def tshark_as(context, scenario):
    log_file = "/tmp/tshark.log"
    if nmci.embed.embed_file_if_exists("tshark.log", log_file, fail_only=True):
        os.remove(log_file)
    context.process.run("pkill tshark", ignore_stderr=True)
    context.process.run_stdout("rm -rf /etc/dhcp/dhclient-eth*.conf", shell=True)


_register_tag("tshark", None, tshark_as)


def eth8_up_as(context, scenario):
    nmci.veth.reset_hwaddr_nmcli("eth8")


_register_tag("eth8_up", None, eth8_up_as)


def keyfile_cleanup_as(context, scenario):
    context.process.run_stdout(
        "rm -f /usr/lib/NetworkManager/system-connections/*", shell=True
    )
    context.process.run_stdout(
        "rm -f /etc/NetworkManager/system-connections/*", shell=True
    )
    # restore testethX
    nmci.veth.restore_connections()
    nmci.veth.wait_for_testeth0()


_register_tag("keyfile_cleanup", None, keyfile_cleanup_as)


def remove_dns_clean_as(context, scenario):
    if context.process.run_search_stdout(
        "cat /etc/NetworkManager/NetworkManager.conf", "dns"
    ):
        context.process.run_stdout(
            "sed -i 's/dns=none//' /etc/NetworkManager/NetworkManager.conf"
        )
    context.process.run_stdout(
        "rm -rf /etc/NetworkManager/conf.d/90-nmci-test-dns-none.conf"
    )
    time.sleep(1)
    nmci.nmutil.reload_NM_service()


_register_tag("remove_dns_clean", None, remove_dns_clean_as)


def restore_resolvconf_as(context, scenario):
    context.process.run_stdout("rm -rf /etc/resolv.conf")
    if context.process.systemctl("is-active systemd-resolved").returncode == 0:
        context.process.run_stdout(
            "ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf"
        )
    context.process.run_stdout("rm -rf /tmp/resolv_orig.conf")
    context.process.run_stdout("rm -rf /tmp/resolv.conf")
    context.process.run_stdout("rm -rf /etc/NetworkManager/conf.d/95-nmci-resolv.conf")
    nmci.nmutil.reload_NM_service()
    nmci.veth.wait_for_testeth0()


_register_tag("restore_resolvconf", None, restore_resolvconf_as)


def device_connect_as(context, scenario):
    context.process.nmcli_force("connection delete testeth9 eth9")
    context.process.nmcli(
        "connection add type ethernet ifname eth9 con-name testeth9 autoconnect no"
    )


_register_tag("device_connect", None, device_connect_as)
_register_tag("device_connect_no_profile", None, device_connect_as)


def remove_ifcfg_con_general_as(context, scenario):
    context.process.run_stdout("ip link del eth8.100")
    context.process.run_stdout(
        "rm -rf /etc/sysconfig/network-scripts/ifcfg-con_general",
    )
    context.process.nmcli("con reload")


_register_tag("remove_ifcfg_con_general", None, remove_ifcfg_con_general_as)


def restore_broken_network_as(context, scenario):
    context.process.systemctl("stop network.service")
    nmci.nmutil.stop_NM_service()
    context.process.run_stdout("sysctl net.ipv6.conf.all.accept_ra=1")
    context.process.run_stdout("sysctl net.ipv6.conf.default.accept_ra=1")
    nmci.nmutil.restart_NM_service()
    context.process.nmcli_force("connection down testeth8 testeth9")


_register_tag("restore_broken_network", None, restore_broken_network_as)


def add_testeth_as(context, scenario, num):
    context.process.nmcli_force(f"connection delete eth{num} testeth{num}")
    context.process.nmcli(
        f"connection add type ethernet con-name testeth{num} ifname eth{num} autoconnect no"
    )


for i in [1, 5, 8, 9, 10]:
    _register_tag(f"add_testeth{i}", None, add_testeth_as, {"num": i})


def eth_disconnect_as(context, scenario, num):
    context.process.nmcli_force(f"device disconnect eth{num}")
    # VVV Up/Down to preserve autoconnect feature
    context.process.nmcli(f"connection up testeth{num}")
    context.process.nmcli(f"connection down testeth{num}")


for i in [1, 2, 4, 5, 6, 8, 10]:
    _register_tag(f"eth{i}_disconnect", None, eth_disconnect_as, {"num": i})


def non_utf_device_bs(context, scenario):
    if os.path.isfile("/usr/lib/udev/rules.d/80-net-setup-link.rules"):
        context.process.run_stdout("rm -f /etc/udev/rules.d/80-net-setup-link.rules")
        context.process.run_stdout(
            "ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules"
        )
        nmci.util.update_udevadm()
    context.process.run_stdout(
        ["ip", "link", "add", "name", b"\xca[2Jnonutf\xccf\\c", "type", "dummy"]
    )


def non_utf_device_as(context, scenario):
    context.process.run_stdout(["ip", "link", "del", b"\xca[2Jnonutf\xccf\\c"])
    if os.path.isfile("/usr/lib/udev/rules.d/80-net-setup-link.rules"):
        context.process.run_stdout("rm -f /etc/udev/rules.d/80-net-setup-link.rules")
        nmci.util.update_udevadm()


_register_tag("non_utf_device", non_utf_device_bs, non_utf_device_as)


def shutdown_as(context, scenario):
    print("sanitizing env")
    context.process.run("ip addr del 192.168.50.5/24 dev eth8", ignore_stderr=True)
    context.process.run("route del default gw 192.168.50.1 eth8", ignore_stderr=True)


_register_tag("shutdown", None, shutdown_as)


def connect_testeth0_as(context, scenario):
    nmci.veth.wait_for_testeth0()


_register_tag("connect_testeth0", None, connect_testeth0_as)


def kill_dbus_monitor_as(context, scenario):
    context.process.run_stdout("pkill -9 dbus-monitor")


_register_tag("kill_dbus-monitor", None, kill_dbus_monitor_as)


def restore_rp_filters_as(context, scenario):
    context.process.run_stdout(
        "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter", shell=True
    )
    context.process.run_stdout(
        "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter", shell=True
    )


_register_tag("restore_rp_filters", None, restore_rp_filters_as)


def remove_ctcdevice_bs(context, scenario):
    context.process.run_stdout("cio_ignore -R")
    time.sleep(1)


def remove_ctcdevice_as(context, scenario):
    devs = context.process.run_stdout("znetconf -c")
    ctc_devs = ""
    for dev in devs.strip().split("\n"):
        if "CTC" in dev:
            ctc_devs += " " + dev.split(",")[0]
    context.process.run_stdout(f"znetconf -r {ctc_devs} -n")
    time.sleep(1)


_register_tag("remove_ctcdevice", remove_ctcdevice_bs, remove_ctcdevice_as)


def filter_batch_bs(context, scenario):
    file_path = "/tmp/filter_batch.txt"
    count = 1
    filter = []
    for a in range(64):
        for b in range(64):
            for c in range(64):
                filter.append(
                    f"filter add dev dummy0 protocol ip ingress prio 1 handle {count} "
                    + f"flower skip_hw src_mac 11:11:00:{a:02x}:{b:02x}:{c:02x} "
                    + f"dst_mac 12:34:00:{a:02x}:{b:02x}:{c:02x} action gact drop"
                )
                count += 1
    nmci.util.file_set_content(file_path, filter)


def filter_batch_as(context, scenario):
    context.process.run_stdout("rm /tmp/filter_batch.txt")


_register_tag("filter_batch", filter_batch_bs, filter_batch_as)


def custom_ns_as(context, scenario):
    if not hasattr(context, "cleanup_ns"):
        return
    cleaned = set()
    for ns in context.cleanup_ns:
        context.process.run_stdout(f"ip netns delete {ns}")
        cleaned.add(ns)
    context.cleanup_ns.difference_update(cleaned)


_register_tag("custom_ns", None, custom_ns_as)


def radius_bs(context, scenario):
    if context.process.systemctl("is-active radiusd.service").returncode == 0:
        context.process.systemctl("disable --now radiusd.service")
    if os.path.isfile("/tmp/nmci_raddb_configured"):
        if context.process.run_code("radiusd -XC") != 0:
            context.process.run_stdout("rm -rf /etc/raddb")
            context.process.run_stdout("cp -a /tmp/nmci-raddb /etc/raddb")
    else:
        context.process.run_stdout("rm -rf /etc/raddb")
        context.process.run_stdout("cp -a /tmp/nmci-raddb /etc/raddb")
        shutil.copy("contrib/8021x/certs/server/hostapd.dh.pem", "/etc/raddb/certs/dh")
        context.process.run_stdout(
            "cd /etc/raddb/certs; make all", shell=True, ignore_stderr=True
        )
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
        context.process.run_stdout("radiusd -XC")
        nmci.util.file_set_content("/tmp/nmci_raddb_configured")
    context.process.run_stdout("chown -R radiusd:radiusd /var/run/radiusd")
    if context.process.systemctl("is-active radiusd").returncode == 0:
        context.process.systemctl("stop radiusd")
    context.process.run_stdout(
        "systemd-run --service-type forking --unit nm-radiusd.service /usr/sbin/radiusd -l stdout -x",
        ignore_stderr=True,
    )


def radius_as(context, scenario):
    if nmci.util.is_verbose():
        nmci.embed.embed_service_log("RADIUS", syslog_identifier="radiusd")
    context.process.systemctl("stop nm-radiusd.service")


_register_tag("radius", radius_bs, radius_as)


def tag8021x_doc_procedure_bs(context, scenario):
    # must run after radius tag whose _bs() part creates source files
    shutil.copy("/etc/raddb/certs/client.key", "/etc/pki/tls/private/8021x.key")
    shutil.copy("/etc/raddb/certs/client.pem", "/etc/pki/tls/certs/8021x.pem")
    shutil.copy("/etc/raddb/certs/ca.pem", "/etc/pki/tls/certs/8021x-ca.pem")
    context.process.run_stdout(
        "yum -y install hostapd wpa_supplicant", ignore_stderr=True, timeout=120
    )
    with open("/etc/sysconfig/hostapd", "r+") as f:
        content = f.read()
        f.seek(0)
        f.write(re.sub("(?m)^OTHER_ARGS=.*$", 'OTHER_ARGS="-d"', content))


def tag8021x_doc_procedure_as(context, scenario):
    context.process.systemctl("stop 802-1x-tr-mgmt hostapd")
    if nmci.util.is_verbose():
        nmci.embed.embed_service_log("HOSTAPD", syslog_identifier="hostapd")
        nmci.embed.embed_service_log(
            "802.1X access control", syslog_identifier="802-1x-tr-mgmt"
        )
        nmci.embed.embed_file_if_exists(
            "WPA_SUP from access control test",
            "/tmp/nmci-wpa_supplicant-standalone",
        )
    if os.path.isfile("/etc/hostapd/hostapd.conf"):
        os.remove("/etc/hostapd/hostapd.conf")
    context.process.systemctl("daemon-reload")
    nmci.veth.reset_hwaddr_nmcli("eth4")


_register_tag(
    "8021x_doc_procedure", tag8021x_doc_procedure_bs, tag8021x_doc_procedure_as
)


def slow_dnsmasq_bs(context, scenario):
    dnsmasq_bin = context.process.run_stdout("which dnsmasq").strip("\n")
    if not os.path.isfile(f"{dnsmasq_bin}.orig"):
        # use copy2 to preserve selinux context
        shutil.copy2(dnsmasq_bin, f"{dnsmasq_bin}.orig")
    nmci.util.file_set_content(
        f"{dnsmasq_bin}.slow",
        [
            "#!/bin/bash",
            "sleep 3",
            f"exec {dnsmasq_bin}.orig $@",
        ],
    )
    context.process.run_stdout(f"chmod +x {dnsmasq_bin}.slow")


def slow_dnsmasq_as(context, scenario):
    dnsmasq_bin = context.process.run_stdout("which dnsmasq").strip("\n")
    os.rename(f"{dnsmasq_bin}.orig", dnsmasq_bin)
    if os.path.isfile(f"{dnsmasq_bin}.slow"):
        os.remove(f"{dnsmasq_bin}.slow")
    # this is to ensure `sleep 3` dnsmasq.slow finished in case of fail
    time.sleep(3)
    context.process.run("pkill dnsmasq.orig")


_register_tag("slow_dnsmasq", slow_dnsmasq_bs, slow_dnsmasq_as)


def cleanup_as(context, scenario):
    nmci.cleanup.process_cleanup()


_register_tag("cleanup", None, cleanup_as)


def copy_ifcfg_bs(context, scenario):
    dirpath = "contrib/profiles"
    for file in os.listdir(dirpath):
        if "ifcfg-migration" in file:
            filepath = f"{dirpath}/{file}"
            with open(filepath) as f:
                contents = f.read()
                device = re.search(r"(?<=DEVICE=)[a-zA-Z0-9_-]+", contents).group(0)
                name = re.search(r"(?<=NAME=)[a-zA-Z0-9_-]+", contents).group(0)
            context.execute_steps(
                f"""
             * Cleanup connection "{name}" and device "{device}"
             """
            )
            context.process.run_stdout(f"cp {filepath} /etc/sysconfig/network-scripts")


_register_tag("copy_ifcfg", copy_ifcfg_bs, None)
