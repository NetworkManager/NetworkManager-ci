# pylint: disable=function-redefined
# type: ignore [no-redef]
import os
import re
import shlex
import time
from behave import step  # pylint: disable=no-name-in-module

import nmci


@step('Create PBR files for profile "{profile}" and "{dev}" device in table "{table}"')
def create_policy_based_routing_files(context, profile, dev, table, timeout=5):
    xtimeout = nmci.util.start_timeout(timeout)
    while xtimeout.loop_sleep(0.1):
        s = context.process.nmcli(["connection", "sh", profile])
        try:
            m = re.search(r"^IP4\.ADDRESS\[1\]:\s*(\S+)\s*$", s, re.MULTILINE)
            ip, _, plen = nmci.ip.ipaddr_plen_parse(m.group(1), addr_family="inet")

            m = re.search(r"^IP4\.GATEWAY:\s*(\S+)\s*$", s, re.MULTILINE)
            gw = nmci.ip.ipaddr_norm(m.group(1), addr_family="inet")
        except Exception as e:
            continue
        break
    if xtimeout.was_expired:
        raise Exception(
            f"Profile {profile} has no suitable IPv4 address. Output:\n\n{s})"
        )

    _ip = ip.rsplit(".", 1)[0]

    nmci.misc.keyfile_update(
        f"/etc/NetworkManager/system-connections/{profile}.nmconnection",
        f"""
        [ipv4]
        route1={_ip}.0/{plen},{ip}
        route1_options=table={table}
        route2={_ip}.0/0,{gw}
        route2_options=table={table}
        routing-rule1=priority 17201 from 0.0.0.0/0 iif {dev} table {table}
        routing-rule2=priority 17200 from {ip} table {table}   
        """,
    )
    nmci.nmutil.restart_NM_service(timeout=timeout)


@step('Configure dhcp server for subnet "{subnet}" with lease time "{lease}"')
def config_dhcp(context, subnet, lease):
    config = []
    config.append("default-lease-time %d;" % int(lease))
    config.append("max-lease-time %d;" % (int(lease) * 2))
    config.append("subnet %s.0 netmask 255.255.255.0 {" % subnet)
    config.append("range %s.128 %s.250;" % (subnet, subnet))
    config.append("option routers %s.1;" % subnet)
    config.append('option domain-name "nodhcp";')
    config.append("option domain-name-servers %s.1, 8.8.8.8;}" % subnet)

    f = open("/tmp/dhcpd.conf", "w")
    for line in config:
        f.write(line + "\n")
    f.close()


@step(
    'Configure dhcpv6 prefix delegation server with address configuration mode "{mode}"'
)
@step(
    'Configure dhcpv6 prefix delegation server with address configuration mode "{mode}" and lease time "{lease}" seconds'
)
def config_dhcpv6_pd(context, mode, lease=None):
    adv_managed = "off"
    adv_other = "off"
    adv_prefix = "# no prefix"
    dhcp_range = "# no range"
    dhcp_lease = "# no lease"

    if lease is not None:
        dhcp_lease = f"default-lease-time {int(lease)}; max-lease-time {int(lease)*2};"

    if mode == "link-local":
        pass
    elif mode == "slaac":
        adv_prefix = (
            "prefix fc01::/64 {AdvOnLink on; AdvAutonomous on; AdvRouterAddr off; };"
        )
    elif mode == "dhcp-stateless":
        adv_other = "on"
        adv_prefix = (
            "prefix fc01::/64 {AdvOnLink on; AdvAutonomous on; AdvRouterAddr off; };"
        )
        dhcp_range = "range6 fc01::1000 fc01::ffff;"
    elif mode == "dhcp-stateful":
        adv_managed = "on"
        dhcp_range = "range6 fc01::1000 fc01::ffff;"
    else:
        assert False, "unknown address configuration mode %s" % mode

    context.command_code("cp contrib/ipv6/radvd-pd.conf.in /tmp/radvd-pd.conf")
    context.command_code("cp contrib/ipv6/dhcpd-pd.conf.in /tmp/dhcpd-pd.conf")

    context.command_output_err(
        f"sed -i 's/@ADV_MANAGED@/{adv_managed}/' /tmp/radvd-pd.conf"
    )
    context.command_output_err(
        f"sed -i 's/@ADV_OTHER@/{adv_other}/'   /tmp/radvd-pd.conf"
    )
    context.command_output_err(
        f"sed -i 's%@ADV_PREFIX@%{adv_prefix}%'  /tmp/radvd-pd.conf"
    )
    context.command_output_err(
        f"sed -i 's/@DHCP_RANGE@/{dhcp_range}/'  /tmp/dhcpd-pd.conf"
    )
    context.command_output_err(
        f"sed -i 's/@DHCP_LEASE@/{dhcp_lease}/'  /tmp/dhcpd-pd.conf"
    )

    with open("/tmp/ip6leases.conf", "w") as f:
        pass

    context.pexpect_service(
        "ip netns exec testX6_ns radvd -n -C /tmp/radvd-pd.conf", shell=True
    )
    context.pexpect_service(
        "ip netns exec testX6_ns dhcpd -6 -d -cf /tmp/dhcpd-pd.conf -lf /tmp/ip6leases.conf",
        shell=True,
    )


@step("Prepare connection")
def prepare_connection(context):
    context.execute_steps(
        """
        * Execute "nmcli con modify dcb ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv6.method ignore"
    """
    )


@step('Prepare "{conf}" config for "{device}" device with "{vfs}" VFs')
def prepare_sriov_config(context, conf, device, vfs):
    conf_path = "/etc/NetworkManager/conf.d/" + conf
    context.command_code("echo '[device-%s]' > %s" % (device, conf_path))
    context.command_code(
        "echo 'match-device=interface-name:%s' >> %s" % (device, conf_path)
    )
    context.command_code("echo 'sriov-num-vfs=%d' >> %s" % (int(vfs), conf_path))
    time.sleep(0.2)
    context.command_code("systemctl reload NetworkManager")
    context.execute_steps(
        f"""
        * Cleanup execute "echo 0 > /sys/class/net/{device}/device/sriov_numvfs" with timeout "10" seconds and priority "50"
        * Cleanup execute "rm -rf /etc/NetworkManager/conf.d/{conf}" with priority "60"
        * Cleanup execute "echo 1 > /sys/class/net/{device}/device/sriov_drivers_autoprobe" with priority "65"
        * Cleanup execute "systemctl reload NetworkManager" with priority "70"
        """
    )


@step("Prepare PBR documentation procedure")
def pbr_doc_proc(context):
    context.execute_steps(
        """
        * Prepare simulated test "provA" device without DHCP
        * Execute "ip -n provA_ns address add 198.51.100.2/30 dev provAp"
        * Prepare simulated test "provB" device without DHCP
        * Execute "ip -n provB_ns address add 192.0.2.2/30 dev provBp"
        * Prepare simulated test "servers" device without DHCP
        * Execute "ip -n servers_ns address add 203.0.113.2/24 dev serversp"
        * Prepare simulated test "int_work" device without DHCP
        * Execute "ip -n int_work_ns address add 10.0.0.2/24 dev int_workp"
        * Create "veth" device named "defA" in namespace "provA_ns" with options "peer name defAp"
        * Execute "ip -n provA_ns link set dev defA up"
        * Create "veth" device named "defB" in namespace "provB_ns" with options "peer name defBp"
        * Execute "ip -n provB_ns link set dev defB up"
    """
    )
    context.command_code("ip -n provA_ns addr add 172.20.20.20/24 dev defA")
    context.command_code("ip -n provB_ns addr add 172.20.20.20/24 dev defB")


@step(
    'Prepare pppoe server for user "{user}" with "{passwd}" password and IP "{ip}" authenticated via "{auth}"'
)
def prepare_pppoe_server(context, user, passwd, ip, auth):
    context.command_code(
        "echo -e 'require-%s\nlogin\nlcp-echo-interval 10\nlcp-echo-failure 2\nms-dns 8.8.8.8\nms-dns 8.8.4.4\nnetmask 255.255.255.0\ndefaultroute\nnoipdefault\nusepeerdns' > /etc/ppp/pppoe-server-options"
        % auth
    )
    context.command_code(
        "echo '%s * %s %s' > /etc/ppp/%s-secrets" % (user, passwd, ip, auth)
    )
    context.command_code("echo '%s-253' > /etc/ppp/allip" % ip)


@step('Prepare veth pairs "{pairs_array}" bridged over "{bridge}"')
def prepare_veths(context, pairs_array, bridge):
    pairs = []
    for pair in pairs_array.split(","):
        pairs.append(pair.strip())

    context.execute_steps(f'* Create "bridge" device named "{bridge}"')
    context.command_code("ip link set dev %s up" % bridge)
    for pair in pairs:
        nmci.veth.manage_device(pair)
        context.execute_steps(
            f"""
            * Create "veth" device named "{pair}" with options "peer name {pair}p"
            * Cleanup device "{pair}p"
            * Cleanup connection "{pair}p"
            * Cleanup connection "{bridge}"
            """
        )
        context.command_code("ip link set %sp master %s" % (pair, bridge))
        context.command_code("ip link set dev %s up" % pair)
        context.command_code("ip link set dev %sp up" % pair)


@step('Start radvd server with config from "{location}"')
def start_radvd(context, location):
    context.command_code("rm -rf /etc/radvd.conf")
    context.command_code("cp %s /etc/radvd.conf" % location)
    context.command_code("systemctl restart radvd")
    time.sleep(2)


@step(
    "Restart dhcp server on {device} device with {ipv4} ipv4 and {ipv6} ipv6 dhcp address prefix"
)
def restart_dhcp_server(context, device, ipv4, ipv6):
    context.command_code("kill $(cat /tmp/{device}_ns.pid)".format(device=device))
    context.command_code(
        "ip netns exec {device}_ns ip addr flush dev {device}_bridge".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(
            device=device, ip=ipv4
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(
            device=device, ip=ipv6
        )
    )
    context.command_code(
        "ip netns exec {device}_ns dnsmasq \
                                        --pid-file=/tmp/{device}_ns.pid \
                                        --dhcp-leasefile=/tmp/{device}_ns.lease \
                                        --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                        --dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,2m \
                                        --enable-ra --interface={device}_bridge \
                                        --bind-interfaces".format(
            device=device, ipv4=ipv4, ipv6=ipv6
        )
    )


@step('Prepare simulated test "{device}" device using dhcpd')
@step(
    'Prepare simulated test "{device}" device using dhcpd and server identifier "{server_id}"'
)
@step(
    'Prepare simulated test "{device}" device using dhcpd and server identifier "{server_id}" and ifindex "{ifindex}"'
)
def prepare_dhcpd_simdev(context, device, server_id="192.168.99.1", ifindex=None):
    nmci.veth.manage_device(device)

    ipv4 = "192.168.99"
    nmci.ip.netns_add(f"{device}_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" in namespace "{device}_ns" with ifindex "{ifindex}" and options "peer name {device}p"'
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device} netns {pid}".format(
            device=device, pid=os.getpid()
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set lo up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(
            device=device, ip=ipv4
        )
    )
    context.command_code(
        "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"
    )
    context.command_code(
        "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts"
    )
    context.command_code("echo '192.168.99.10 ip-192-168-99-10' >> /etc/hosts")
    context.command_code("echo '192.168.99.11 ip-192-168-99-11' >> /etc/hosts")
    context.command_code("echo '192.168.99.12 ip-192-168-99-12' >> /etc/hosts")
    context.command_code("echo '192.168.99.13 ip-192-168-99-13' >> /etc/hosts")
    context.command_code("echo '192.168.99.14 ip-192-168-99-14' >> /etc/hosts")
    context.command_code("echo '192.168.99.15 ip-192-168-99-15' >> /etc/hosts")

    config = []
    if server_id is not None:
        config.append("server-identifier {server_id};".format(server_id=server_id))
    config.append("max-lease-time 150;")
    config.append("default-lease-time 120;")
    config.append("subnet {ip}.0 netmask 255.255.255.0 {{".format(ip=ipv4))
    config.append("  range {ip}.10 {ip}.15;".format(ip=ipv4))
    config.append("}}".format(ip=ipv4))

    f = open("/tmp/dhcpd.conf", "w")
    for line in config:
        f.write(line + "\n")
    f.close()

    context.command_code(
        "ip netns exec {device}_ns dhcpd -4 -cf /tmp/dhcpd.conf -pf /tmp/{device}_ns.pid".format(
            device=device
        )
    )


@step(
    'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix and "{lease_time}" leasetime and daemon options "{daemon_options}"'
)
@step(
    'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix and dhcp option "{option}"'
)
@step(
    'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix'
)
@step(
    'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and daemon options "{daemon_options}"'
)
@step('Prepare simulated test "{device}" device with "{lease_time}" leasetime')
@step('Prepare simulated test "{device}" device with dhcp option "{option}"')
@step('Prepare simulated test "{device}" device with ifindex "{ifindex}"')
@step('Prepare simulated test "{device}" device')
@step('Prepare simulated test "{device}" device with daemon options "{daemon_options}"')
def prepare_simdev(
    context,
    device,
    lease_time="2m",
    ipv4=None,
    ipv6=None,
    ifindex=None,
    option=None,
    daemon_options=None,
):
    ipv4addr = None
    if ipv4 is None:
        ipv4 = "192.168.99"
    elif ipv4.lower() == "none":
        ipv4 = None
    else:
        try:
            ipv4 = nmci.ip.ipaddr_norm(ipv4, addr_family="4")
        except Exception:
            pass
        else:
            # This is a complete IP address. This means me choose
            # the .1 address for the server, and the DHCP range only
            # contains this one IP address.
            m = re.search(r"^(.*)\.([^.])+$", ipv4)
            ipv4addr = ipv4
            ipv4 = m.group(1)
            assert ipv4addr != ipv4 + ".1"

    assert ipv4 is None or nmci.ip.ipaddr_parse(ipv4 + ".1", addr_family="4")

    ipv6addr = None
    if ipv6 is None:
        ipv6 = "2620:dead:beaf"
    elif ipv6.lower() == "none":
        ipv6 = None
    else:
        try:
            ipv6 = nmci.ip.ipaddr_norm(ipv6, addr_family="6")
        except Exception:
            pass
        else:
            # This is a complete IP address. This means me choose
            # the ::1 address for the server, and the DHCP range only
            # contains this one IP address.
            m = re.search("^(.*)::([^:])+$", ipv6)
            ipv6addr = ipv6
            ipv6 = m.group(1)
            assert ipv6addr != ipv6 + "::1"

    assert ipv6 is None or nmci.ip.ipaddr_parse(ipv6 + "::1", addr_family="6")

    if daemon_options is None:
        daemon_options = ""

    nmci.veth.manage_device(device)

    nmci.ip.netns_add(f"{device}_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" in namespace "{device}_ns" with ifindex "{ifindex}" and options "peer name {device}p"'
    )
    context.command_code(
        "ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.disable_ipv6=0".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.accept_ra=1".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.autoconf=1".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set lo up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p up".format(device=device)
    )
    if ipv4:
        context.command_code(
            "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(
                device=device, ip=ipv4
            )
        )
    if ipv6:
        context.command_code(
            "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}p".format(
                device=device, ip=ipv6
            )
        )
    context.command_code(
        "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"
    )
    context.command_code(
        "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts"
    )
    context.command_code("echo '192.168.99.10 ip-192-168-99-10' >> /etc/hosts")
    context.command_code("echo '192.168.99.11 ip-192-168-99-11' >> /etc/hosts")
    context.command_code("echo '192.168.99.12 ip-192-168-99-12' >> /etc/hosts")
    context.command_code("echo '192.168.99.13 ip-192-168-99-13' >> /etc/hosts")
    context.command_code("echo '192.168.99.14 ip-192-168-99-14' >> /etc/hosts")
    context.command_code("echo '192.168.99.15 ip-192-168-99-15' >> /etc/hosts")

    if option:
        option = "--dhcp-option-force=" + option
    else:
        option = ""

    pid_file = f"/tmp/{device}_ns.pid"
    lease_file = f"/tmp/{device}_ns.lease"

    nmci.cleanup.add_file(pid_file)
    nmci.cleanup.add_file(lease_file)

    dnsmasq_command = "ip netns exec {device}_ns dnsmasq \
                                --interface={device}p \
                                --bind-interfaces \
                                --pid-file={pid_file} \
                                --dhcp-leasefile={lease_file} \
                                {option} \
                                {daemon_options}".format(
        device=device,
        pid_file=pid_file,
        lease_file=lease_file,
        option=option,
        daemon_options=daemon_options,
    )
    if ipv4:
        if ipv4addr:
            dhcprange = f"{ipv4addr},{ipv4addr}"
        else:
            dhcprange = f"{ipv4}.10,{ipv4}.15"
        dnsmasq_command += " --dhcp-range={dhcprange},{lease_time} ".format(
            lease_time=lease_time, dhcprange=dhcprange
        )
    if ipv6 and lease_time != "infinite":
        if ipv6addr:
            dhcprange = f"{ipv6addr},{ipv6addr}"
        else:
            dhcprange = f"{ipv6}::100,{ipv6}::fff"
        dnsmasq_command += " --dhcp-range={dhcprange},slaac,64,{lease_time} \
                             --enable-ra".format(
            lease_time=lease_time, dhcprange=dhcprange
        )

    assert (
        context.command_code(dnsmasq_command) == 0
    ), "unable to start dnsmasq using command `{dnsmasq_command}`".format(
        dnsmasq_command=dnsmasq_command
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device} netns {pid}".format(
            device=device, pid=os.getpid()
        )
    )
    if (
        nmci.process.systemctl(
            "status NetworkManager", embed_combine_tag=nmci.embed.NO_EMBED
        ).returncode
        == 0
    ):
        timeout = nmci.util.start_timeout(10)
        while timeout.loop_sleep(0.1):
            if nmci.nmutil.device_status(name=device):
                break
        assert not timeout.expired(), f"Did not see created device '{device}' in 10s."


@step(
    'Prepare simulated test "{device}" device with DHCPv4 server on different network'
)
def prepare_simdev(context, device):
    nmci.veth.manage_device(device)

    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    # (DHCP   | 172.16.0.1  10.0.0.2  | |  10.0.0.1   |
    # client) |(dhcrelay + forwarding)| | (DHCP serv) |
    #         +-----------------------+ +-------------+
    nmci.ip.netns_add(f"{device}_ns")
    nmci.ip.netns_add(f"{device}2_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" with options "peer name {device}p"'
    )
    context.execute_steps(
        f'* Create "veth" device named "{device}2" with options "peer name {device}2p"'
    )
    context.command_code(
        "ip link set {device}p netns {device}_ns".format(device=device)
    )
    context.command_code(
        "ip link set {device}2 netns {device}_ns".format(device=device)
    )
    context.command_code(
        "ip link set {device}2p netns {device}2_ns".format(device=device)
    )
    # Bring up devices
    context.command_code(
        "ip netns exec {device}_ns ip link set lo up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}2 up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}2_ns ip link set {device}2p up".format(device=device)
    )
    # Set addresses
    context.command_code(
        "ip netns exec {device}_ns ip addr add dev {device}p 172.16.0.1/24".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip addr add dev {device}2 10.0.0.2/24".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}2_ns ip addr add dev {device}2p 10.0.0.1/24".format(
            device=device
        )
    )
    # Enable forwarding and DHCP relay in first namespace
    context.command_code(
        "ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns dhcrelay -4 10.0.0.1 -pf /tmp/dhcrelay.pid".format(
            device=device
        )
    )
    # Start DHCP server in second namespace
    # Push a default route and a route to reach the DHCP server
    context.command_code(
        "ip netns exec {device}2_ns dnsmasq \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}2p \
                                         --dhcp-range=172.16.0.100,172.16.0.200,255.255.255.0,1m \
                                         --dhcp-option=3,172.16.0.50 \
                                         --dhcp-option=121,10.0.0.0/24,172.16.0.1".format(
            device=device
        )
    )


@step('Prepare simulated test "{device}" device without DHCP')
def prepare_simdev_no_dhcp(context, device):
    nmci.veth.manage_device(device)

    nmci.ip.netns_add(f"{device}_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" in namespace "{device}_ns" with options "peer name {device}p"'
    )
    nmci.ip.link_set(ifname=device, namespace=f"{device}_ns", netns=str(os.getpid()))
    # Fix potential race with indices in "iptunnel" prepare
    # Wait until device appears in root namespace, so index is captured correctly
    nmci.ip.link_show(ifname=device, timeout=5)
    nmci.ip.link_set(ifname=f"{device}p", namespace=f"{device}_ns", up=True)


@step('Prepare simulated test "{device}" device for IPv6 PMTU discovery')
def prepare_simdev(context, device):
    nmci.veth.manage_device(device)

    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    #         |  fd01::1     fd02::1  | |   fd02::2   |
    # mtu 1500|   1500        1400    | |    1500     |
    #         +-----------------------+ +-------------+
    nmci.ip.netns_add(f"{device}_ns")
    nmci.ip.netns_add(f"{device}2_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" with options "peer name {device}p"'
    )
    context.execute_steps(
        f'* Create "veth" device named "{device}2" with options "peer name {device}2p"'
    )
    context.command_code(
        "ip link set {device}p netns {device}_ns".format(device=device)
    )
    context.command_code(
        "ip link set {device}2 netns {device}_ns".format(device=device)
    )
    context.command_code(
        "ip link set {device}2p netns {device}2_ns".format(device=device)
    )
    # Bring up devices
    context.command_code(
        "ip netns exec {device}_ns ip link set lo up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}2 up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}2_ns ip link set {device}2p up".format(device=device)
    )
    # Set addresses
    context.command_code(
        "ip netns exec {device}_ns ip addr add dev {device}p fd01::1/64".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip addr add dev {device}2 fd02::1/64".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}2_ns ip addr add dev {device}2p fd02::2/64".format(
            device=device
        )
    )
    # Set MTU
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p mtu 1500".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}2 mtu 1400".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}2_ns ip link set {device}2p mtu 1500".format(
            device=device
        )
    )
    # Set up router (testX_ns)
    context.command_code(
        "ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv6/conf/all/forwarding'".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns dnsmasq \
                                         --no-resolv \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}p \
                                         --enable-ra \
                                         --dhcp-range=::1,::400,constructor:{device}p,ra-only,64,15s".format(
            device=device
        )
    )
    # Add route
    context.command_code(
        "ip netns exec {device}2_ns ip route add fd01::/64 via fd02::1 dev {device}2p".format(
            device=device
        )
    )
    # Run netcat server to receive some data
    context.pexpect_service(
        "ip netns exec {device}2_ns nc -6 -l -p 9000 > /dev/null".format(device=device),
        shell=True,
    )


@step('Prepare simulated veth device "{device}" without carrier')
def prepare_simdev_no_carrier(context, device):
    nmci.veth.manage_device(device)

    ipv4 = "192.168.99"
    ipv6 = "2620:dead:beaf"
    nmci.ip.netns_add(f"{device}_ns")
    context.command_code(
        "ip netns exec {device}_ns ip link add {device} type veth peer name {device}p".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set lo up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link add name {device}_bridge type bridge".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p master {device}_bridge".format(
            device=device
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(
            device=device, ip=ipv4
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(
            device=device, ip=ipv6
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}_bridge up".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device}p down".format(device=device)
    )
    context.command_code(
        "ip netns exec {device}_ns dnsmasq \
                                            --pid-file=/tmp/{device}_ns.pid \
                                            --dhcp-leasefile=/tmp/{device}_ns.lease \
                                            --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                            --dhcp-range={ipv6}::100,{ipv6}::1ff,slaac,64,2m \
                                            --enable-ra --interface={device}_bridge \
                                            --bind-interfaces".format(
            device=device, ipv4=ipv4, ipv6=ipv6
        )
    )
    context.command_code(
        "ip netns exec {device}_ns ip link set {device} netns 1".format(device=device)
    )


@step('Prepare simulated test "{device}" device with a bridged peer')
@step(
    'Prepare simulated test "{device}" device with a bridged peer with bridge options "{bropts}"'
)
@step(
    'Prepare simulated test "{device}" device with a bridged peer and veths to namespaces "{namespaces}"'
)
@step(
    'Prepare simulated test "{device}" device with a bridged peer with bridge options "{bropts}" and veths to namespaces "{namespaces}"'
)
def prepare_bridged(context, device, bropts="", namespaces=None):
    """
    `namespaces` expects comma-separated list of extra namespaces

    Topology created:

    No NS:      +- br0 in {device}_ns --+
                |                       |
    {device} ---- {device}p     {ns1} ----- veth0 in {ns1}
                |               {ns2} ----- veth0 in {ns2}
                |               ...   ----- ...
                |               {ns_n} ---- veth0 in {ns_n}
                |                       |
                +-----------------------+
    """
    nmci.ip.netns_add(f"{device}_ns")
    nmci.process.run_stdout(
        f"ip l add {device} type veth peer name {device}p netns {device}_ns"
    )
    nmci.process.run_stdout(f"ip l set {device} up")
    nmci.process.run_stdout(f"ip -n {device}_ns l add br0 type bridge {bropts}")
    nmci.process.run_stdout(f"ip -n {device}_ns l set {device}p master br0")
    nmci.process.run_stdout(f"ip -n {device}_ns l set {device}p up")
    nmci.process.run_stdout(f"ip -n {device}_ns l set br0 up")
    if not namespaces:
        # no more namespaces and veths to create
        return
    namespaces = [ns.strip() for ns in namespaces.split(",")]
    for ns in namespaces:
        nmci.ip.netns_add(ns)
        nmci.process.run_stdout(
            f"ip -n {ns} l add veth0 type veth peer name {ns} netns {device}_ns"
        )
        nmci.process.run_stdout(f"ip -n {ns} l set veth0 up")
        nmci.process.run_stdout(f"ip -n {device}_ns l set {ns} master br0")
        nmci.process.run_stdout(f"ip -n {device}_ns l set {ns} up")


@step('Start pppoe server with "{name}" and IP "{ip}" on device "{dev}"')
def start_pppoe_server(context, name, ip, dev):
    context.command_code("ip link set dev %s up" % dev)
    context.pexpect_service(
        "pppoe-server -S %s -C %s -L %s -p /etc/ppp/allip -I %s"
        % (name, name, ip, dev),
        shell=True,
    )
    time.sleep(1)


@step('Start pppoe server with "{name}" and IP "{ip}" in namespace "{dev}"')
def start_pppoe_server(context, name, ip, dev):
    dev_p = dev + "p"
    context.execute_steps(
        """
            * Prepare simulated test "%s" device"""
        % dev
    )
    context.pexpect_service(
        "ip netns exec %s_ns pppoe-server -S %s -C %s -L %s -p /etc/ppp/allip -I %s"
        % (dev, name, name, ip, dev_p),
        shell=True,
    )
    time.sleep(1)


@step('Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}"')
@step('Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}" on VLAN "{vid}"')
def setup_macsec_psk(context, cak, ckn, vid=None):
    nmci.veth.manage_device("macsec_veth")
    context.command_code("modprobe macsec")
    nmci.ip.netns_add(f"macsec_ns")
    context.execute_steps(
        f'* Create "veth" device named "macsec_veth" with options "peer name macsec_vethp"'
    )
    context.command_code("ip link set macsec_vethp netns macsec_ns")
    context.command_code("ip link set macsec_veth up")
    context.command_code("ip netns exec macsec_ns ip link set macsec_vethp up")
    if vid is not None:
        context.command_code(
            "ip -n macsec_ns link add link macsec_vethp vlan type vlan id {vid}".format(
                vid=vid
            )
        )
        context.command_code("ip -n macsec_ns link set vlan up")
    context.command_code("echo 'eapol_version=3' > /tmp/wpa_supplicant.conf")
    context.command_code("echo 'ap_scan=0' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo 'network={' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  key_mgmt=NONE' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  eapol_flags=0' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  macsec_policy=1' >> /tmp/wpa_supplicant.conf")
    context.command_code(
        "echo '  mka_cak={cak}' >> /tmp/wpa_supplicant.conf".format(cak=cak)
    )
    context.command_code(
        "echo '  mka_ckn={ckn}' >> /tmp/wpa_supplicant.conf".format(ckn=ckn)
    )
    context.command_code("echo '}' >> /tmp/wpa_supplicant.conf")

    base_interface = "vlan" if vid is not None else "macsec_vethp"
    context.command_code(
        "ip netns exec macsec_ns wpa_supplicant \
                                         -c /tmp/wpa_supplicant.conf \
                                         -i {base_interface} \
                                         -B \
                                         -D macsec_linux \
                                         -P /tmp/wpa_supplicant_ms.pid".format(
            base_interface=base_interface
        )
    )
    time.sleep(6)
    assert (
        context.command_code("ip netns exec macsec_ns ip link show macsec0") == 0
    ), "wpa_supplicant didn't create a MACsec interface"
    assert (
        context.command_code("nmcli device set macsec_veth managed yes") == 0
    ), "wpa_supplicant didn't create a MACsec interface"
    context.command_code("ip netns exec macsec_ns ip link set macsec0 up")
    context.command_code(
        "ip netns exec macsec_ns ip addr add 172.16.10.1/24 dev macsec0"
    )
    context.command_code(
        "ip netns exec macsec_ns ip -6 addr add 2001:db8:1::fffe/32 dev macsec0"
    )
    context.command_code(
        "ip netns exec macsec_ns dnsmasq \
                                         --pid-file=/tmp/dnsmasq_ms.pid \
                                         --dhcp-range=172.16.10.10,172.16.10.254,60m  \
                                         --interface=macsec0 \
                                         --bind-interfaces"
    )


@step("Set default DCB options")
def set_default_dcb(context):
    context.execute_steps(
        """
    * Execute "nmcli con modify dcb dcb.app-fcoe-flags 7 dcb.app-fcoe-priority 7 dcb.app-fcoe-mode vn2vn dcb.app-iscsi-flags 7 dcb.app-iscsi-priority 6 dcb.app-fip-flags 7 dcb.app-fip-priority 2  dcb.priority-flow-control-flags 7 dcb.priority-flow-control 1,0,0,1,1,0,1,0 dcb.priority-group-flags 7 dcb.priority-group-id 0,0,0,0,1,1,1,1 dcb.priority-group-bandwidth 13,13,13,13,12,12,12,12 dcb.priority-bandwidth 100,100,100,100,100,100,100,100 dcb.priority-traffic-class 7,6,5,4,3,2,1,0"
    """
    )


@step('Prepare "{mode}" iptunnel networks A and B')
def prepare_iptunnel_doc(context, mode):
    bridge = False
    if mode == "gretap":
        bridge = True

    # prepare Network A (range 192.0.2.1/2) and Network B in namespace (range 172.16.0.1/24)
    context.execute_steps('* Prepare simulated test "netA" device without DHCP')
    context.execute_steps('* Prepare simulated test "netB" device without DHCP')
    nmci.ip.netns_add("iptunnelB")
    nmci.ip.link_set(ifname="netB", netns="iptunnelB")
    if bridge:
        # if bridge, add addresses to "computers" in local networks
        nmci.ip.address_add("192.0.2.3/24", ifname="netAp", namespace="netA_ns")
        nmci.ip.address_add("192.0.2.4/24", ifname="netBp", namespace="netB_ns")
    else:
        # only add local addresses if not bridge
        nmci.ip.address_add(address="192.0.2.1/24", ifname="netA")
        nmci.ip.address_add(
            address="172.16.0.1/24", ifname="netB", namespace="iptunnelB"
        )

    # connect Network A (public IP 203.0.113.10) and Network B (public IP 198.51.100.5) via veth pair ipA and ipB
    context.execute_steps(
        '* Create "veth" device named "ipA" in namespace "iptunnelB" with options "peer name ipB"'
    )
    nmci.ip.link_set(ifname="ipA", up=False, namespace="iptunnelB")
    nmci.ip.link_set(ifname="ipA", netns=str(os.getpid()), namespace="iptunnelB")
    nmci.ip.link_set(ifname="ipA", up=True)
    nmci.ip.address_add(address="203.0.113.10/32", ifname="ipA")
    nmci.ip.route_add("198.51.100.5/32", ifname="ipA")
    nmci.ip.link_set(ifname="ipB", up=True, namespace="iptunnelB")
    nmci.ip.address_add(address="198.51.100.5/32", ifname="ipB", namespace="iptunnelB")
    nmci.ip.route_add("203.0.113.10/32", ifname="ipB", namespace="iptunnelB")
    nmci.process.run_stdout("ping -c 1 198.51.100.5")
    nmci.process.run_stdout("ping -c 1 203.0.113.10", namespace="iptunnelB")

    # preapre Network B part of iptunnel (in iptunnelB namespace)
    nmci.ip.link_add(
        ifname="tunB",
        link_type=mode,
        local="198.51.100.5",
        remote="203.0.113.10",
        namespace="iptunnelB",
    )
    nmci.ip.link_set(ifname="tunB", up=True, namespace="iptunnelB")
    if bridge:
        nmci.ip.link_add(ifname="brB", link_type="bridge", namespace="iptunnelB")
        nmci.ip.link_set(ifname="netB", up=False, namespace="iptunnelB")
        nmci.ip.link_set(ifname="netB", master="brB", namespace="iptunnelB")
        nmci.ip.link_set(ifname="netB", up=True, namespace="iptunnelB")
        nmci.ip.link_set(ifname="brB", up=True, namespace="iptunnelB")
        nmci.ip.address_add("192.0.2.2/24", ifname="brB", namespace="iptunnelB")
        nmci.ip.link_set(ifname="tunB", master="brB", namespace="iptunnelB")
    else:
        nmci.ip.address_add("10.0.1.2/30", ifname="tunB", namespace="iptunnelB")
        nmci.ip.route_add("10.0.1.1/32", ifname="tunB", namespace="iptunnelB")
        nmci.ip.route_add("192.0.2.0/24", ifname="tunB", namespace="iptunnelB")


@step('Prepare simulated MPTCP setup with "{num}" veths named "{veth}"')
@step(
    'Prepare simulated MPTCP setup with "{num}" veths named "{veth}" and MPTCP type "{typ}"'
)
def mptcp(context, num, veth, typ="subflow"):
    import nmci.pexpect

    ### workaround for systems with MPTCP enabled by default
    # NM currently doesn't remove MPTCP endpoints for an interface that goes
    # down (eth0 before MPTCP scenarios) which makes existing checks for MPTCP
    # endpoints wrong on systems that have MPTCP enabled by default (Fedora).
    #
    # A workaround is to disable MPTCP, restart NM and flush the endpoints
    # early in the Prepare so that the rest of scenario works exactly the same
    # as on systems with MPTCP disabled.
    nmci.cleanup.add_sysctls("net.mptcp.enabled")
    nmci.cleanup.add_NM_service("restart")
    nmci.process.run(["sysctl", "-w", "net.mptcp.enabled=0"])
    nmci.process.run(["ip", "mptcp", "endpoint", "flush"])
    nmci.nmutil.restart_NM_service()
    ### end workaround

    number = int(num)
    nsname = "mptcp"
    run_in_ns = ["ip", "netns", "exec", nsname]
    ip_in_ns = ["ip", "-n", nsname]

    nmci.ip.netns_add(nsname)

    nmci.cleanup.add_sysctls(r"\.rp_filter")
    nmci.cleanup.add_sysctls("net.mptcp.enabled")
    nmci.cleanup.add_mptcp_limits()
    nmci.cleanup.add_mptcp_endpoints()
    nmci.process.run_stdout([*ip_in_ns, "mptcp", "endpoint", "flush"])
    nmci.process.run_stdout(
        [
            *ip_in_ns,
            "mptcp",
            "limits",
            "set",
            "subflow",
            num,
            "add_addr_accepted",
            f"{number - 1}",
        ]
    )

    nmci.process.run([*run_in_ns, "sysctl", "-w", "net.mptcp.enabled=1"])
    for i in range(number):
        iface = f"{veth}{i}"
        iface_ns = f"{veth}{i}p"
        v4_start = 80 + i
        v6_start = hex(v4_start)[2:]
        ipv4 = f"192.168.{v4_start}.1"
        ipv6 = f"2620:dead:beaf:{v6_start}::1"
        nmci.cleanup.add_iface(iface)
        nmci.process.run(
            [
                "ip",
                "l",
                "add",
                iface,
                "type",
                "veth",
                "peer",
                "name",
                iface_ns,
                "netns",
                nsname,
            ]
        )
        nmci.process.run([*ip_in_ns, "l", "set", iface_ns, "up"])
        nmci.process.run([*ip_in_ns, "addr", "add", f"{ipv4}/24", "dev", f"{iface}p"])
        nmci.process.run([*ip_in_ns, "addr", "add", f"{ipv6}/64", "dev", f"{iface}p"])
        nmci.process.run(
            [*ip_in_ns, "mptcp", "endpoint", "add", ipv4, "dev", iface_ns, typ]
        )
        nmci.process.run(
            [*ip_in_ns, "mptcp", "endpoint", "add", ipv6, "dev", iface_ns, typ]
        )

    rp_filter_keys = nmci.process.run_stdout(
        [*run_in_ns, "sysctl", "-N", "-a", "--pattern", r"\.rp_filter"]
    ).strip()
    if len(rp_filter_keys) > 0:
        rp_filters = [f"{k} = 0" for k in rp_filter_keys.split("\n")]

        pexpect_cmd = " ".join([*run_in_ns, "sysctl", f"-p-"])
        sysctl_p = nmci.pexpect.pexpect_spawn(pexpect_cmd, check=True)
        for f in rp_filters:
            sysctl_p.sendline(f)
        sysctl_p.sendcontrol("d")
        sysctl_p.sendeof()

    for f in ["/tmp/nmci-mptcp-ncat-4", "/tmp/nmci-mptcp-ncat-6"]:
        try:
            os.remove(f)
        except FileNotFoundError:
            pass
    if nmci.util.is_verbose():
        redir = "| tee"
        nmci.process.run_stdout([*ip_in_ns, "addr"])
        nmci.process.run_stdout([*ip_in_ns, "-4", "route"])
        nmci.process.run_stdout([*ip_in_ns, "-6", "route"])
        nmci.process.run_stdout([*ip_in_ns, "mptcp", "limits"])
        nmci.process.run_stdout([*ip_in_ns, "mptcp", "endpoint"])
        nmci.process.run_stdout([*run_in_ns, "sysctl", "-a", "--pattern", "mptcp"])
        nmci.process.run_stdout(
            [*run_in_ns, "sysctl", "-a", "--pattern", r"\.rp_filter"]
        )
    else:
        redir = ">"
    nmci.pexpect.pexpect_service(
        f"ip netns exec {nsname} tcpdump -i any -Ulvnn --number 'tcp port 9006' {redir} /tmp/tcpdump.log",
        shell=True,
        label="child",
    )
    nmci.pexpect.pexpect_service(
        f"ip netns exec {nsname} mptcpize run ncat -k -l 9006 {redir} /tmp/nmci-mptcp-ncat.log ",
        shell=True,
        label="child",
    )


@step('Set ip mptcp limits to "{lim}"')
@step('Set ip mptcp limits to "{lim}" in "{ns}"')
def lims(context, lim, ns=None):
    nmci.cleanup.add_mptcp_limits(namespace=ns)
    if lim is not None:
        nmci.process.run(f"ip mptcp limits set {lim}", namespace=ns)
