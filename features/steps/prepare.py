# pylint: disable=function-redefined,unused-argument,line-too-long
# type: ignore [no-redef]
import os
import re
import time
from behave import step  # pylint: disable=no-name-in-module

import nmci


@step('Create PBR files for profile "{profile}" and "{dev}" device in table "{table}"')
def create_policy_based_routing_files(context, profile, dev, table, timeout=5):
    xtimeout = nmci.util.start_timeout(timeout)
    while xtimeout.loop_sleep(0.1):
        s = nmci.process.nmcli(["connection", "sh", profile])
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
    config = [
        f"default-lease-time {int(lease)};",
        f"max-lease-time {int(lease) * 2};",
        f"subnet {subnet}.0 netmask 255.255.255.0 {{",
        f"range {subnet}.128 {subnet}.250;",
        f"option routers {subnet}.1;",
        'option domain-name "nodhcp";',
        f"option domain-name-servers {subnet}.1, 8.8.8.8;}}",
    ]

    nmci.util.file_set_content("/tmp/dhcpd.conf", config)


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

    nmci.process.run("cp contrib/ipv6/radvd-pd.conf.in /tmp/radvd-pd.conf")
    nmci.process.run("cp contrib/ipv6/dhcpd-pd.conf.in /tmp/dhcpd-pd.conf")

    sed_commands = [
        f"sed -i 's/@ADV_MANAGED@/{adv_managed}/' /tmp/radvd-pd.conf",
        f"sed -i 's/@ADV_OTHER@/{adv_other}/' /tmp/radvd-pd.conf",
        f"sed -i 's%@ADV_PREFIX@%{adv_prefix}%' /tmp/radvd-pd.conf",
        f"sed -i 's/@DHCP_RANGE@/{dhcp_range}/' /tmp/dhcpd-pd.conf",
        f"sed -i 's/@DHCP_LEASE@/{dhcp_lease}/' /tmp/dhcpd-pd.conf",
    ]

    for cmd in sed_commands:
        nmci.process.run(cmd, shell=True)

    nmci.util.file_set_content("/tmp/ip6leases.conf")

    nmci.pexpect.pexpect_service(
        "ip netns exec testX6_ns radvd -n -C /tmp/radvd-pd.conf", shell=True
    )
    nmci.pexpect.pexpect_service(
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
    conf_path = f"/etc/NetworkManager/conf.d/{conf}"

    config_lines = [
        f"[device-{device}]",
        f"match-device=interface-name:{device}",
        f"sriov-num-vfs={int(vfs)}",
    ]

    nmci.util.file_set_content(conf_path, config_lines)

    time.sleep(0.2)
    nmci.process.run("systemctl reload NetworkManager")
    cleanup_commands = [
        (f"echo 0 > /sys/class/net/{device}/device/sriov_numvfs", "50", "10"),
        (f"rm -rf /etc/NetworkManager/conf.d/{conf}", "60", None),
        (
            f"echo 1 > /sys/class/net/{device}/device/sriov_drivers_autoprobe",
            "65",
            None,
        ),
        ("systemctl reload NetworkManager", "70", None),
    ]

    for cmd, priority, timeout in cleanup_commands:
        if timeout:
            context.execute_steps(
                f'* Cleanup execute "{cmd}" with timeout "{timeout}" seconds and priority "{priority}"'
            )
        else:
            context.execute_steps(
                f'* Cleanup execute "{cmd}" with priority "{priority}"'
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
        * Add namespace "internet"
        * Create "veth" device named "defA" in namespace "provA_ns" with options "peer name defAp"
        * Execute "ip -n provA_ns link set dev defAp netns internet"
        * Create "veth" device named "defB" in namespace "provB_ns" with options "peer name defBp"
        * Execute "ip -n provB_ns link set dev defBp netns internet"
        * Create "bridge" device named "br0" in namespace "internet" with options "stp_state 0"
        """
    )

    # Configure bridge connections in internet namespace
    bridge_commands = [
        "ip -n internet link set dev defAp master br0",
        "ip -n internet link set dev defBp master br0",
        "ip -n internet link set dev br0 up",
        "ip -n internet link set dev defAp up",
        "ip -n internet link set dev defBp up",
    ]

    # Bring up veth devices in provider namespaces
    link_up_commands = [
        "ip -n provA_ns link set dev defA up",
        "ip -n provB_ns link set dev defB up",
    ]

    # Configure IP addresses
    address_commands = [
        ("provA_ns", "defA", "172.20.20.1/24"),
        ("provB_ns", "defB", "172.20.20.2/24"),
        ("internet", "br0", "172.20.20.20/24"),
    ]

    # Configure internet namespace routes
    internet_routes = [
        ("203.0.113.0/24", "172.20.20.1"),
        ("198.51.100.0/30", "172.20.20.1"),
        ("10.0.0.0/24", "172.20.20.2"),
        ("192.0.2.0/30", "172.20.20.2"),
    ]

    # Configure default routes for each namespace
    default_routes = [
        ("provB_ns", "192.0.2.1"),
        ("int_work_ns", "10.0.0.1"),
        ("servers_ns", "203.0.113.1"),
        ("provA_ns", "198.51.100.1"),
    ]

    # Execute all commands
    for cmd in bridge_commands + link_up_commands:
        nmci.process.run(cmd)

    for namespace, device, address in address_commands:
        nmci.process.run(f"ip -n {namespace} addr add {address} dev {device}")

    for network, via_addr in internet_routes:
        nmci.process.run(f"ip -n internet route add {network} via {via_addr} dev br0")

    for namespace, gateway in default_routes:
        nmci.process.run(f"ip -n {namespace} route add default via {gateway}")


@step(
    'Prepare pppoe server for user "{user}" with "{passwd}" password and IP "{ip}" authenticated via "{auth}"'
)
def prepare_pppoe_server(context, user, passwd, ip, auth):
    pppoe_options = [
        f"require-{auth}",
        "login",
        "lcp-echo-interval 10",
        "lcp-echo-failure 2",
        "ms-dns 8.8.8.8",
        "ms-dns 8.8.4.4",
        "netmask 255.255.255.0",
        "defaultroute",
        "noipdefault",
        "usepeerdns",
    ]

    nmci.util.file_set_content("/etc/ppp/pppoe-server-options", pppoe_options)
    nmci.util.file_set_content(f"/etc/ppp/{auth}-secrets", f"{user} * {passwd} {ip}\n")
    nmci.util.file_set_content("/etc/ppp/allip", f"{ip}-253\n")


@step('Prepare veth pairs "{pairs_array}" bridged over "{bridge}"')
def prepare_veths(context, pairs_array, bridge):
    pairs = []
    for pair in pairs_array.split(","):
        pairs.append(pair.strip())

    context.execute_steps(f'* Create "bridge" device named "{bridge}"')
    nmci.process.run(f"ip link set dev {bridge} up")
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
        veth_commands = [
            f"ip link set {pair}p master {bridge}",
            f"ip link set dev {pair} up",
            f"ip link set dev {pair}p up",
        ]

        for cmd in veth_commands:
            nmci.process.run(cmd)


@step('Start radvd server with config from "{location}"')
def start_radvd(context, location):
    nmci.process.run("rm -rf /etc/radvd.conf")
    nmci.process.run(f"cp {location} /etc/radvd.conf")
    nmci.process.run("systemctl restart radvd")
    time.sleep(2)


@step(
    "Restart dhcp server on {device} device with {ipv4} ipv4 and {ipv6} ipv6 dhcp address prefix"
)
def restart_dhcp_server(context, device, ipv4, ipv6):
    nmci.process.run(f"kill $(cat /tmp/{device}_ns.pid)", shell=True)
    nmci.process.run(f"ip netns exec {device}_ns ip addr flush dev {device}_bridge")
    nmci.process.run(
        f"ip netns exec {device}_ns ip addr add {ipv4}.1/24 dev {device}_bridge"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns ip -6 addr add {ipv6}::1/64 dev {device}_bridge"
    )

    dnsmasq_cmd = (
        f"ip netns exec {device}_ns dnsmasq "
        f"--pid-file=/tmp/{device}_ns.pid "
        f"--dhcp-leasefile=/tmp/{device}_ns.lease "
        f"--dhcp-range={ipv4}.10,{ipv4}.15,2m "
        f"--dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,2m "
        f"--enable-ra --interface={device}_bridge "
        f"--bind-interfaces"
    )
    nmci.process.run(dnsmasq_cmd)


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
    nmci.process.run(
        f"ip netns exec {device}_ns ip link set {device} netns {os.getpid()}"
    )
    nmci.process.run(f"ip netns exec {device}_ns ip link set lo up")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p up")
    nmci.process.run(f"ip netns exec {device}_ns ip addr add {ipv4}.1/24 dev {device}p")

    hosts_entries = [
        "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4",
        "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6",
        "192.168.99.10 ip-192-168-99-10",
        "192.168.99.11 ip-192-168-99-11",
        "192.168.99.12 ip-192-168-99-12",
        "192.168.99.13 ip-192-168-99-13",
        "192.168.99.14 ip-192-168-99-14",
        "192.168.99.15 ip-192-168-99-15",
    ]

    nmci.util.file_set_content("/etc/hosts", hosts_entries)

    config = []
    if server_id is not None:
        config.append(f"server-identifier {server_id};")
    config.extend(
        [
            "max-lease-time 150;",
            "default-lease-time 120;",
            f"subnet {ipv4}.0 netmask 255.255.255.0 {{",
            f"  range {ipv4}.10 {ipv4}.15;",
            "}",
        ]
    )

    nmci.util.file_set_content("/tmp/dhcpd.conf", config)

    nmci.process.run(
        f"ip netns exec {device}_ns dhcpd -4 -cf /tmp/dhcpd.conf -pf /tmp/{device}_ns.pid",
        ignore_stderr=True,
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
    'Prepare simulated test "{device}" device with MAC address "{address}" and "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix'
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
    address=None,
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
        f'* Create "veth" device named "{device}" in namespace "{device}_ns" with ifindex "{ifindex}" and MAC address "{address}" and options "peer name {device}p"'
    )
    sysctl_commands = [
        f"net.ipv6.conf.{device}.disable_ipv6=0",
        f"net.ipv6.conf.{device}.accept_ra=1",
        f"net.ipv6.conf.{device}.autoconf=1",
    ]

    for sysctl_cmd in sysctl_commands:
        nmci.process.run(f"ip netns exec {device}_ns sysctl {sysctl_cmd}")

    nmci.process.run(f"ip netns exec {device}_ns ip link set lo up")

    # This speeds up RA packets heavily
    ra_sysctl_commands = [
        f"net.ipv6.conf.{device}p.router_solicitation_interval=1000",
        f"net.ipv6.conf.{device}p.router_solicitations=1",
    ]

    for sysctl_cmd in ra_sysctl_commands:
        nmci.process.run(f"ip netns exec {device}_ns sysctl -w {sysctl_cmd}")

    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p up")
    if ipv4:
        nmci.process.run(
            f"ip netns exec {device}_ns ip addr add {ipv4}.1/24 dev {device}p"
        )
    if ipv6:
        nmci.process.run(
            f"ip netns exec {device}_ns ip -6 addr add {ipv6}::1/64 dev {device}p"
        )
    hosts_entries = [
        "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4",
        "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6",
        "192.168.99.10 ip-192-168-99-10",
        "192.168.99.11 ip-192-168-99-11",
        "192.168.99.12 ip-192-168-99-12",
        "192.168.99.13 ip-192-168-99-13",
        "192.168.99.14 ip-192-168-99-14",
        "192.168.99.15 ip-192-168-99-15",
    ]

    nmci.util.file_set_content("/etc/hosts", hosts_entries)

    if option:
        option = "--dhcp-option-force=" + option
    else:
        option = ""

    pid_file = f"/tmp/{device}_ns.pid"
    lease_file = f"/tmp/{device}_ns.lease"

    nmci.cleanup.add_file(pid_file)
    nmci.cleanup.add_file(lease_file)

    dnsmasq_command = (
        f"ip netns exec {device}_ns dnsmasq "
        f"--interface={device}p "
        f"--bind-interfaces "
        f"--pid-file={pid_file} "
        f"--dhcp-leasefile={lease_file} "
        f"{option} "
        f"{daemon_options}"
    )
    if ipv4:
        if ipv4addr:
            dhcprange = f"{ipv4addr},{ipv4addr}"
        else:
            dhcprange = f"{ipv4}.10,{ipv4}.15"
        dnsmasq_command += f" --dhcp-range={dhcprange},{lease_time} "

    if ipv6 and lease_time != "infinite":
        if ipv6addr:
            dhcprange = f"{ipv6addr},{ipv6addr}"
        else:
            dhcprange = f"{ipv6}::100,{ipv6}::fff"
        dnsmasq_command += (
            f" --dhcp-range={dhcprange},slaac,64,{lease_time} --enable-ra"
        )

    result = nmci.process.run(dnsmasq_command, shell=True)
    assert (
        result.returncode == 0
    ), f"unable to start dnsmasq using command `{dnsmasq_command}`"

    nmci.process.run(
        f"ip netns exec {device}_ns ip link set {device} netns {os.getpid()}"
    )
    if nmci.process.systemctl("status NetworkManager").returncode == 0:
        with nmci.util.start_timeout(10) as timeout:
            while timeout.loop_sleep(0.1):
                if nmci.nmutil.device_status(name=device):
                    break
            assert (
                not timeout.expired()
            ), f"Did not see created device '{device}' in 10s."


@step(
    'Prepare simulated test "{device}" device with DHCPv4 server on different network'
)
def prepare_simdev_different_network(context, device):
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

    link_set_commands = [
        (f"{device}p", f"{device}_ns"),
        (f"{device}2", f"{device}_ns"),
        (f"{device}2p", f"{device}2_ns"),
    ]

    for link, netns in link_set_commands:
        nmci.process.run(f"ip link set {link} netns {netns}")
    # Bring up devices
    link_up_commands = [
        (f"{device}_ns", "lo"),
        (f"{device}_ns", f"{device}p"),
        (f"{device}_ns", f"{device}2"),
        (f"{device}2_ns", f"{device}2p"),
    ]

    for netns, link in link_up_commands:
        nmci.process.run(f"ip netns exec {netns} ip link set {link} up")

    # Set addresses
    addr_commands = [
        (f"{device}_ns", f"{device}p", "172.16.0.1/24"),
        (f"{device}_ns", f"{device}2", "10.0.0.2/24"),
        (f"{device}2_ns", f"{device}2p", "10.0.0.1/24"),
    ]

    for netns, link, addr in addr_commands:
        nmci.process.run(f"ip netns exec {netns} ip addr add dev {link} {addr}")
    # Enable forwarding and DHCP relay in first namespace
    nmci.process.run(
        f"ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns dhcrelay -4 10.0.0.1 -pf /tmp/dhcrelay.pid",
        ignore_stderr=True,
    )

    # Start DHCP server in second namespace
    # Push a default route and a route to reach the DHCP server
    dnsmasq_cmd = (
        f"ip netns exec {device}2_ns dnsmasq "
        f"--pid-file=/tmp/{device}_ns.pid "
        f"--bind-interfaces -i {device}2p "
        f"--dhcp-range=172.16.0.100,172.16.0.200,255.255.255.0,1m "
        f"--dhcp-option=3,172.16.0.50 "
        f"--dhcp-option=121,10.0.0.0/24,172.16.0.1"
    )
    nmci.process.run(dnsmasq_cmd)


@step('Prepare simulated test "{device}" device without DHCP')
@step(
    'Prepare simulated test "{device}" device with MAC address "{address}" and without DHCP'
)
def prepare_simdev_no_dhcp(context, device, address=None):
    nmci.veth.manage_device(device)

    nmci.ip.netns_add(f"{device}_ns")
    context.execute_steps(
        f'* Create "veth" device named "{device}" in namespace "{device}_ns" with MAC address "{address}" and options "peer name {device}p"'
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
    nmci.process.run(f"ip link set {device}p netns {device}_ns")
    nmci.process.run(f"ip link set {device}2 netns {device}_ns")
    nmci.process.run(f"ip link set {device}2p netns {device}2_ns")
    # Bring up devices
    nmci.process.run(f"ip netns exec {device}_ns ip link set lo up")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p up")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}2 up")
    nmci.process.run(f"ip netns exec {device}2_ns ip link set {device}2p up")
    # Set addresses
    nmci.process.run(f"ip netns exec {device}_ns ip addr add dev {device}p fd01::1/64")
    nmci.process.run(f"ip netns exec {device}_ns ip addr add dev {device}2 fd02::1/64")
    nmci.process.run(
        f"ip netns exec {device}2_ns ip addr add dev {device}2p fd02::2/64"
    )
    # Set MTU
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p mtu 1500")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}2 mtu 1400")
    nmci.process.run(f"ip netns exec {device}2_ns ip link set {device}2p mtu 1500")
    # Set up router (testX_ns)
    nmci.process.run(
        f"ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv6/conf/all/forwarding'"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns dnsmasq \
                                         --no-resolv \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}p \
                                         --enable-ra \
                                         --dhcp-range=::1,::400,constructor:{device}p,ra-only,64,15s"
    )
    # Add route
    nmci.process.run(
        f"ip netns exec {device}2_ns ip route add fd01::/64 via fd02::1 dev {device}2p"
    )
    # Run netcat server to receive some data
    nmci.pexpect.pexpect_service(
        f"ip netns exec {device}2_ns nc -6 -l -p 9000 > /dev/null",
        shell=True,
    )


@step('Prepare simulated veth device "{device}" without carrier')
def prepare_simdev_no_carrier(context, device):
    nmci.veth.manage_device(device)

    ipv4 = "192.168.99"
    ipv6 = "2620:dead:beaf"
    nmci.ip.netns_add(f"{device}_ns")
    nmci.process.run(
        f"ip netns exec {device}_ns ip link add {device} type veth peer name {device}p"
    )
    nmci.process.run(f"ip netns exec {device}_ns ip link set lo up")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p up")
    nmci.process.run(
        f"ip netns exec {device}_ns ip link add name {device}_bridge type bridge"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns ip link set {device}p master {device}_bridge"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns ip addr add {ipv4}.1/24 dev {device}_bridge"
    )
    nmci.process.run(
        f"ip netns exec {device}_ns ip -6 addr add {ipv6}::1/64 dev {device}_bridge"
    )
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}_bridge up")
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device}p down")
    nmci.process.run(
        f"ip netns exec {device}_ns dnsmasq \
                                            --pid-file=/tmp/{device}_ns.pid \
                                            --dhcp-leasefile=/tmp/{device}_ns.lease \
                                            --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                            --dhcp-range={ipv6}::100,{ipv6}::1ff,slaac,64,2m \
                                            --enable-ra --interface={device}_bridge \
                                            --bind-interfaces"
    )
    nmci.process.run(f"ip netns exec {device}_ns ip link set {device} netns 1")


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
    nmci.process.run(f"ip link set dev {dev} up")
    nmci.pexpect.pexpect_service(
        f"pppoe-server -S {name} -C {name} -L {ip} -p /etc/ppp/allip -I {dev}",
        shell=True,
    )
    time.sleep(1)


@step('Start pppoe server with "{name}" and IP "{ip}" in namespace "{dev}"')
def start_pppoe_server_ns(context, name, ip, dev):
    dev_p = f"{dev}p"
    context.execute_steps(f'* Prepare simulated test "{dev}" device')
    nmci.pexpect.pexpect_service(
        f"ip netns exec {dev}_ns pppoe-server -S {name} -C {name} -L {ip} -p /etc/ppp/allip -I {dev_p}",
        shell=True,
    )
    time.sleep(1)


@step('Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}"')
@step('Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}" on VLAN "{vid}"')
def setup_macsec_psk(context, cak, ckn, vid=None):
    nmci.veth.manage_device("macsec_veth")
    nmci.process.run("modprobe macsec")
    nmci.ip.netns_add(f"macsec_ns")
    context.execute_steps(
        f'* Create "veth" device named "macsec_veth" with options "peer name macsec_vethp"'
    )
    nmci.ip.link_set("macsec_vethp", netns="macsec_ns")
    nmci.ip.link_set("macsec_veth", up=True)
    nmci.ip.link_set("macsec_vethp", namespace="macsec_ns", up=True)
    if vid is not None:
        # ifname, type, args
        nmci.ip.link_add(
            "vlan",
            link_type="vlan",
            id=vid,
            namespace="macsec_ns",
            parent_link="macsec_vethp",
        )
        nmci.ip.link_set("vlan", up=True, namespace="macsec_ns")
    conf = [
        "eapol_version=3",
        "ap_scan=0",
        "network={",
        "  key_mgmt=NONE",
        "  eapol_flags=0",
        "  macsec_policy=1",
        f"  mka_cak={cak}",
        f"  mka_ckn={ckn}",
        "}",
    ]
    nmci.util.file_set_content("/tmp/wpa_supplicant.conf", conf)

    base_interface = "vlan" if vid is not None else "macsec_vethp"
    nmci.process.run(
        f"ip netns exec macsec_ns wpa_supplicant \
                                         -c /tmp/wpa_supplicant.conf \
                                         -i {base_interface} \
                                         -B \
                                         -D macsec_linux \
                                         -P /tmp/wpa_supplicant_ms.pid"
    )
    nmci.ip.link_set("macsec0", up=True, namespace="macsec_ns", wait_for_device=6)
    nmci.process.nmcli("device set macsec_veth managed yes")
    nmci.ip.address_add(
        "172.16.10.1/24", "macsec0", addr_family="4", namespace="macsec_ns"
    )
    nmci.ip.address_add(
        "2001:db8:1::fffe/32", "macsec0", addr_family="6", namespace="macsec_ns"
    )
    nmci.process.run(
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
        f"ip netns exec {nsname} stdbuf -oL -eL tcpdump -i any -Ulvnn --number 'tcp port 9006' {redir} /tmp/tcpdump.log",
        shell=True,
        label="child",
    )
    # We need some sleep here to avoid s390x failures here and there
    time.sleep(0.5)
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


@step('Prepare nmstate libreswan server for "{ipsec_type}" environment')
def libreswan_ng_setup(context, ipsec_type):
    # ensure correct versions are installed
    nmci.veth.wait_for_testeth0()
    if context.rh_release_num <= [9, 1]:
        nmci.cext.skip("These libreswan tests require RHEL9.2+")

    if context.rh_release_num == [9, 2]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.14-4.el9_2"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el9"
            """
        )
    if context.rh_release_num == [9, 3]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.14-3.el9_3"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el9"
            """
        )
    if context.rh_release_num == [9, 4]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.18-4.el9_4"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el9"
            """
        )
    if context.rh_release_num == [9, 5]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.22-1.el9"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el9"
            """
        )
    if context.rh_release_num == [10, 0]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.22-1.el10"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el10"
            """
        )
    if context.rh_release_num == [9, 99]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.22-1.el9"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el9"
            """
        )
    if context.rh_release_num == [10, 99]:
        context.execute_steps(
            f"""
            * Ensure that version of "NetworkManager-libreswan" package is at least "1.2.22-1.el10"
            * Ensure that version of "nmstate" package is at least "2.2.31-1.el10"
            """
        )

    # This might take some time on secondaries if NM is restarted ^^
    nmci.process.run(
        "nmcli general logging level trace domains all,vpn_plugin:trace", timeout=10
    )

    # Clone nmstate project, if not already done
    base = "contrib/ipsec/nmstate"
    if not os.path.isfile("/tmp/nmstate_ipsec_updated"):
        nmci.process.run(f"rm -rf {base}")
        nmci.process.run(
            "git clone https://github.com/nmstate/nmstate.git",
            cwd="contrib/ipsec",
            ignore_stderr=True,
            timeout=40,
        )
        # Mark setup complete
        nmci.util.file_set_content("/tmp/nmstate_ipsec_updated")

    pluto_journal = nmci.pexpect.pexpect_spawn("journalctl -f -n 0 -t pluto")

    # We need to run this and expect "env ready" message
    context.ipsec_proc = nmci.pexpect.pexpect_service(
        f"python3l contrib/ipsec/ipsec_setup.py {ipsec_type}",
        shell=True,
    )

    # register cleanup
    def _libreswan_ng_teardown():
        try:
            context.ipsec_proc.send("\n")
        except:
            pass
        context.ipsec_proc.expect(nmci.pexpect.EOF)
        context.execute_steps('* "hosta_nic" is not visible with command "ip a s"')

    nmci.cleanup.add_callback(_libreswan_ng_teardown, "teardown-libreswan")

    # Wait until env is ready
    context.ipsec_proc.expect("env ready", timeout=60)

    # Secondaries might be slower in writing the config file where we read
    # the certificate info from - wait until pluto starts
    with nmci.util.start_timeout() as t:
        pluto_journal.expect("listening for IKE messages")
        print(f"pluto started in {t.elapsed_time():.3f}s")

    import yaml

    # Load data from YAML
    with open("/tmp/ipsec_config.yaml", "r") as f:
        data = yaml.safe_load(f) or {}  # Ensure data is a dictionary

    # Update os.environ with YAML variables
    for key, value in data.items():
        os.environ[key] = str(value)
        # And store them in noted dict as well
        print(f"Exporting {os.environ[key]} as {str(value)}")
        context.noted[key] = str(value)
