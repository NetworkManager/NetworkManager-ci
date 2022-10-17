import os
import re
import shlex
import time
from behave import step  # pylint: disable=no-name-in-module

import nmci

def manage_veth_device(context, device):
    rule_file = f"/etc/udev/rules.d/88-veth-{device}.rules"
    if not os.path.isfile(rule_file):
        rule = 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="%s*", ENV{NM_UNMANAGED}="0"' %device
        nmci.util.file_set_content(rule_file, [rule])
        nmci.util.update_udevadm()
        nmci.cleanup.cleanup_add_udev_rule(rule_file)

@step('Create PBR files for profile "{profile}" and "{dev}" device in table "{table}"')
def create_policy_based_routing_files(context, profile, dev, table, timeout=5):
    xtimeout = nmci.util.start_timeout(timeout)
    while xtimeout.loop_sleep(0.1):
        s = context.process.nmcli(["connection", "sh", profile])
        try:
            m = re.search("^IP4\.ADDRESS\[1\]:\\s*(\\S+)\\s*$", s, re.MULTILINE)
            ip, _, plen = nmci.ip.ipaddr_plen_norm(m.group(1), addr_family="inet")

            m = re.search("^IP4\.GATEWAY:\\s*(\\S+)\\s*$", s, re.MULTILINE)
            gw, _ = nmci.ip.ipaddr_norm(m.group(1), addr_family="inet")
        except Exception as e:
            continue
        break
    if xtimeout.was_expired:
        raise Exception(
            f"Profile {profile} has no suitable IPv4 address. Output:\n\n{s})"
        )

    context.util.file_set_content(
        f"/etc/sysconfig/network-scripts/route-{profile}",
        [
            f"{ip}/{plen} dev {dev} table {table}",
            f"default via {gw} dev {dev} table {table}",
        ],
    )

    context.util.file_set_content(
        f"/etc/sysconfig/network-scripts/rule-{profile}",
        [
            f"prio 17201 iif {dev} table {table}",
            f"prio 17200 from {ip} table {table}",
        ],
    )


@step(u'Configure dhcp server for subnet "{subnet}" with lease time "{lease}"')
def config_dhcp(context, subnet, lease):
    config = []
    config.append('default-lease-time %d;' % int(lease))
    config.append('max-lease-time %d;' % (int(lease)*2))
    config.append('subnet %s.0 netmask 255.255.255.0 {' % subnet)
    config.append('range %s.128 %s.250;' % (subnet, subnet))
    config.append('option routers %s.1;' % subnet)
    config.append('option domain-name "nodhcp";')
    config.append('option domain-name-servers %s.1, 8.8.8.8;}' % subnet)

    f = open('/tmp/dhcpd.conf', 'w')
    for line in config:
        f.write(line+'\n')
    f.close()

@step(u'Configure dhcpv6 prefix delegation server with address configuration mode "{mode}"')
@step(u'Configure dhcpv6 prefix delegation server with address configuration mode "{mode}" and lease time "{lease}" seconds')
def config_dhcpv6_pd(context, mode, lease=None):
    adv_managed="off"
    adv_other="off"
    adv_prefix="# no prefix"
    dhcp_range="# no range"
    dhcp_lease ="# no lease"

    if lease is not None:
        dhcp_lease = f"default-lease-time {int(lease)}; max-lease-time {int(lease)*2};"

    if mode == 'link-local':
        pass
    elif mode == 'slaac':
        adv_prefix="prefix fc01::/64 {AdvOnLink on; AdvAutonomous on; AdvRouterAddr off; };"
    elif mode == 'dhcp-stateless':
        adv_other="on"
        adv_prefix="prefix fc01::/64 {AdvOnLink on; AdvAutonomous on; AdvRouterAddr off; };"
        dhcp_range="range6 fc01::1000 fc01::ffff;"
    elif mode == 'dhcp-stateful':
        adv_managed="on"
        dhcp_range="range6 fc01::1000 fc01::ffff;"
    else:
        assert False, ("unknown address configuration mode %s" % mode)

    context.command_code("cp contrib/ipv6/radvd-pd.conf.in /tmp/radvd-pd.conf")
    context.command_code("cp contrib/ipv6/dhcpd-pd.conf.in /tmp/dhcpd-pd.conf")

    context.command_output_err(f"sed -i 's/@ADV_MANAGED@/{adv_managed}/' /tmp/radvd-pd.conf")
    context.command_output_err(f"sed -i 's/@ADV_OTHER@/{adv_other}/'   /tmp/radvd-pd.conf")
    context.command_output_err(f"sed -i 's%@ADV_PREFIX@%{adv_prefix}%'  /tmp/radvd-pd.conf")
    context.command_output_err(f"sed -i 's/@DHCP_RANGE@/{dhcp_range}/'  /tmp/dhcpd-pd.conf")
    context.command_output_err(f"sed -i 's/@DHCP_LEASE@/{dhcp_lease}/'  /tmp/dhcpd-pd.conf")

    with open('/tmp/ip6leases.conf', 'w') as f:
        pass

    context.pexpect_service("ip netns exec testX6_ns radvd -n -C /tmp/radvd-pd.conf", shell=True)
    context.pexpect_service("ip netns exec testX6_ns dhcpd -6 -d -cf /tmp/dhcpd-pd.conf -lf /tmp/ip6leases.conf", shell=True)


@step(u'Prepare connection')
def prepare_connection(context):
    context.execute_steps(u"""
        * Execute "nmcli con modify dcb ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv6.method ignore"
    """)


@step(u'Prepare "{conf}" config for "{device}" device with "{vfs}" VFs')
def prepare_sriov_config(context, conf, device, vfs):
    conf_path = "/etc/NetworkManager/conf.d/"+conf
    context.command_code("echo '[device-%s]' > %s" % (device, conf_path))
    context.command_code("echo 'match-device=interface-name:%s' >> %s" % (device, conf_path))
    context.command_code("echo 'sriov-num-vfs=%d' >> %s" % (int(vfs), conf_path))
    time.sleep(0.2)
    context.command_code('systemctl reload NetworkManager')


@step(u'Prepare PBR documentation procedure')
def pbr_doc_proc(context):
    context.execute_steps('''
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
    ''')
    context.command_code("ip -n provA_ns addr add 172.20.20.20/24 dev defA")
    context.command_code("ip -n provB_ns addr add 172.20.20.20/24 dev defB")


@step(u'Prepare pppoe server for user "{user}" with "{passwd}" password and IP "{ip}" authenticated via "{auth}"')
def prepare_pppoe_server(context, user, passwd, ip, auth):
    context.command_code("echo -e 'require-%s\nlogin\nlcp-echo-interval 10\nlcp-echo-failure 2\nms-dns 8.8.8.8\nms-dns 8.8.4.4\nnetmask 255.255.255.0\ndefaultroute\nnoipdefault\nusepeerdns' > /etc/ppp/pppoe-server-options" % auth)
    context.command_code("echo '%s * %s %s' > /etc/ppp/%s-secrets" % (user, passwd, ip, auth))
    context.command_code("echo '%s-253' > /etc/ppp/allip" % ip)


@step(u'Prepare veth pairs "{pairs_array}" bridged over "{bridge}"')
def prepare_veths(context, pairs_array, bridge):
    pairs = []
    for pair in pairs_array.split(','):
        pairs.append(pair.strip())

    context.execute_steps(f'* Create "bridge" device named "{bridge}"')
    context.command_code("sudo ip link set dev %s up" % bridge)
    for pair in pairs:
        manage_veth_device(context, pair)
        context.execute_steps(
            f'''
            * Create "veth" device named "{pair}" with options "peer name {pair}p"
            * Cleanup device "{pair}p"
            ''')
        context.command_code("ip link set %sp master %s" % (pair, bridge))
        context.command_code("ip link set dev %s up" % pair)
        context.command_code("ip link set dev %sp up" % pair)


@step(u'Start radvd server with config from "{location}"')
def start_radvd(context, location):
    context.command_code("rm -rf /etc/radvd.conf")
    context.command_code("cp %s /etc/radvd.conf" % location)
    context.command_code("systemctl restart radvd")
    time.sleep(2)


@step(u'Restart dhcp server on {device} device with {ipv4} ipv4 and {ipv6} ipv6 dhcp address prefix')
def restart_dhcp_server(context, device, ipv4, ipv6):
    context.command_code('kill $(cat /tmp/{device}_ns.pid)'.format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr flush dev {device}_bridge".format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(device=device, ip=ipv4))
    context.command_code("ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(device=device, ip=ipv6))
    context.command_code("ip netns exec {device}_ns dnsmasq \
                                        --pid-file=/tmp/{device}_ns.pid \
                                        --dhcp-leasefile=/tmp/{device}_ns.lease \
                                        --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                        --dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,2m \
                                        --enable-ra --interface={device}_bridge \
                                        --bind-interfaces".format(device=device, ipv4=ipv4, ipv6=ipv6))


@step(u'Prepare simulated test "{device}" device using dhcpd')
@step(u'Prepare simulated test "{device}" device using dhcpd and server identifier "{server_id}"')
def prepare_dhcpd_simdev(context, device, server_id):
    manage_veth_device(context, device)

    ipv4 = "192.168.99"
    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.execute_steps(f'* Create "veth" device named "{device}" with options "peer name {device}p"')
    context.command_code("ip link set {device}p netns {device}_ns".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set lo up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(device=device, ip=ipv4))
    context.command_code("echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts")
    context.command_code("echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts")
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

    f = open('/tmp/dhcpd.conf', 'w')
    for line in config:
        f.write(line + '\n')
    f.close()

    context.command_code("ip netns exec {device}_ns dhcpd -4 -cf /tmp/dhcpd.conf -pf /tmp/{device}_ns.pid".format(device=device))
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")


@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix and "{lease_time}" leasetime and daemon options "{daemon_options}"')
@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix and dhcp option "{option}"')
@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix')
@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and daemon options "{daemon_options}"')
@step(u'Prepare simulated test "{device}" device with "{lease_time}" leasetime')
@step(u'Prepare simulated test "{device}" device with dhcp option "{option}"')
@step(u'Prepare simulated test "{device}" device')
@step(u'Prepare simulated test "{device}" device with daemon options "{daemon_options}"')
def prepare_simdev(context, device, lease_time="2m", ipv4=None, ipv6=None, option=None, daemon_options=None):
    manage_veth_device(context, device)

    if ipv4 is None:
        ipv4 = "192.168.99"
    if ipv6 is None:
        ipv6 = "2620:dead:beaf"
    if daemon_options is None:
        daemon_options = ""

    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.execute_steps(f'* Create "veth" device named "{device}" in namespace "{device}_ns" with options "peer name {device}p"')
    context.command_code("ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.disable_ipv6=0".format(device=device))
    context.command_code("ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.accept_ra=1".format(device=device))
    context.command_code("ip netns exec {device}_ns sysctl net.ipv6.conf.{device}.autoconf=1".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set lo up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    if ipv4.lower() != "none":
        context.command_code("ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(device=device, ip=ipv4))
    if ipv6.lower() != "none":
        context.command_code("ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}p".format(device=device, ip=ipv6))
    context.command_code("echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts")
    context.command_code("echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts")
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

    dnsmasq_command = "ip netns exec {device}_ns dnsmasq \
                                --interface={device}p \
                                --bind-interfaces \
                                --pid-file=/tmp/{device}_ns.pid \
                                --dhcp-leasefile=/tmp/{device}_ns.lease \
                                {option} \
                                {daemon_options}".format(device=device, option=option, daemon_options=daemon_options)
    if ipv4.lower() != "none":
        dnsmasq_command += " --dhcp-range={ipv4}.10,{ipv4}.15,{lease_time} ".format(lease_time=lease_time, ipv4=ipv4)
    if ipv6.lower() != "none" and lease_time != 'infinite':
        dnsmasq_command += " --dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,{lease_time} \
                             --enable-ra".format(lease_time=lease_time, ipv6=ipv6)

    assert context.command_code(dnsmasq_command) == 0, "unable to start dnsmasq using command `{dnsmasq_command}`".format(dnsmasq_command=dnsmasq_command)
    context.command_code("ip netns exec {device}_ns ip link set {device} netns {pid}".format(device=device, pid=os.getpid()))
    if nmci.process.systemctl("status NetworkManager", do_embed=False).returncode == 0:
        context.execute_steps(f'Then "connected" is visible with command "nmcli device show {device}" in "10" seconds');
    else:
        time.sleep(2)
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")



@step(u'Prepare simulated test "{device}" device with DHCPv4 server on different network')
def prepare_simdev(context, device):
    manage_veth_device(context, device)

    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    # (DHCP   | 172.16.0.1  10.0.0.2  | |  10.0.0.1   |
    # client) |(dhcrelay + forwarding)| | (DHCP serv) |
    #         +-----------------------+ +-------------+
    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.execute_steps(f'* Add namespace "{device}2_ns"')
    context.execute_steps(f'* Create "veth" device named "{device}" with options "peer name {device}p"')
    context.execute_steps(f'* Create "veth" device named "{device}2" with options "peer name {device}2p"')
    context.command_code("ip link set {device}p netns {device}_ns".format(device=device))
    context.command_code("ip link set {device}2 netns {device}_ns".format(device=device))
    context.command_code("ip link set {device}2p netns {device}2_ns".format(device=device))
    # Bring up devices
    context.command_code("ip netns exec {device}_ns ip link set lo up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}2 up".format(device=device))
    context.command_code("ip netns exec {device}2_ns ip link set {device}2p up".format(device=device))
    # Set addresses
    context.command_code("ip netns exec {device}_ns ip addr add dev {device}p 172.16.0.1/24".format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr add dev {device}2 10.0.0.2/24".format(device=device))
    context.command_code("ip netns exec {device}2_ns ip addr add dev {device}2p 10.0.0.1/24".format(device=device))
    # Enable forwarding and DHCP relay in first namespace
    context.command_code("ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'".format(device=device))
    context.command_code("ip netns exec {device}_ns dhcrelay -4 10.0.0.1 -pf /tmp/dhcrelay.pid".format(device=device))
    # Start DHCP server in second namespace
    # Push a default route and a route to reach the DHCP server
    context.command_code("ip netns exec {device}2_ns dnsmasq \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}2p \
                                         --dhcp-range=172.16.0.100,172.16.0.200,255.255.255.0,1m \
                                         --dhcp-option=3,172.16.0.50 \
                                         --dhcp-option=121,10.0.0.0/24,172.16.0.1".format(device=device))
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns2")


@step(u'Prepare simulated test "{device}" device without DHCP')
def prepare_simdev_no_dhcp(context, device):
    manage_veth_device(context, device)

    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.execute_steps(f'* Create "veth" device named "{device}" in namespace "{device}_ns" with options "peer name {device}p"')
    context.command_code("ip netns exec {device}_ns ip link set {device} netns {pid}".format(device=device, pid=os.getpid()))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")


@step(u'Prepare simulated test "{device}" device for IPv6 PMTU discovery')
def prepare_simdev(context, device):
    manage_veth_device(context, device)

    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    #         |  fd01::1     fd02::1  | |   fd02::2   |
    # mtu 1500|   1500        1400    | |    1500     |
    #         +-----------------------+ +-------------+
    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.execute_steps(f'* Add namespace "{device}2_ns"')
    context.execute_steps(f'* Create "veth" device named "{device}" with options "peer name {device}p"')
    context.execute_steps(f'* Create "veth" device named "{device}2" with options "peer name {device}2p"')
    context.command_code("ip link set {device}p netns {device}_ns".format(device=device))
    context.command_code("ip link set {device}2 netns {device}_ns".format(device=device))
    context.command_code("ip link set {device}2p netns {device}2_ns".format(device=device))
    # Bring up devices
    context.command_code("ip netns exec {device}_ns ip link set lo up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}2 up".format(device=device))
    context.command_code("ip netns exec {device}2_ns ip link set {device}2p up".format(device=device))
    # Set addresses
    context.command_code("ip netns exec {device}_ns ip addr add dev {device}p fd01::1/64".format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr add dev {device}2 fd02::1/64".format(device=device))
    context.command_code("ip netns exec {device}2_ns ip addr add dev {device}2p fd02::2/64".format(device=device))
    # Set MTU
    context.command_code("ip netns exec {device}_ns ip link set {device}p mtu 1500".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}2 mtu 1400".format(device=device))
    context.command_code("ip netns exec {device}2_ns ip link set {device}2p mtu 1500".format(device=device))
    # Set up router (testX_ns)
    context.command_code("ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv6/conf/all/forwarding'".format(device=device))
    context.command_code("ip netns exec {device}_ns dnsmasq \
                                         --no-resolv \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}p \
                                         --enable-ra \
                                         --dhcp-range=::1,::400,constructor:{device}p,ra-only,64,15s".format(device=device))
    # Add route
    context.command_code("ip netns exec {device}2_ns ip route add fd01::/64 via fd02::1 dev {device}2p".format(device=device))
    # Run netcat server to receive some data
    context.pexpect_service("ip netns exec {device}2_ns nc -6 -l -p 9000 > /dev/null".format(device=device), shell=True)
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns2")


@step(u'Prepare simulated veth device "{device}" without carrier')
def prepare_simdev_no_carrier(context, device):
    manage_veth_device(context, device)

    ipv4 = "192.168.99"
    ipv6 = "2620:dead:beaf"
    context.execute_steps(f'* Add namespace "{device}_ns"')
    context.command_code("ip netns exec {device}_ns ip link add {device} type veth peer name {device}p".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set lo up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link add name {device}_bridge type bridge".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p master {device}_bridge".format(device=device))
    context.command_code("ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(device=device, ip=ipv4))
    context.command_code("ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(device=device, ip=ipv6))
    context.command_code("ip netns exec {device}_ns ip link set {device}_bridge up".format(device=device))
    context.command_code("ip netns exec {device}_ns ip link set {device}p down".format(device=device))
    context.command_code("ip netns exec {device}_ns dnsmasq \
                                            --pid-file=/tmp/{device}_ns.pid \
                                            --dhcp-leasefile=/tmp/{device}_ns.lease \
                                            --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                            --dhcp-range={ipv6}::100,{ipv6}::1ff,slaac,64,2m \
                                            --enable-ra --interface={device}_bridge \
                                            --bind-interfaces".format(device=device, ipv4=ipv4, ipv6=ipv6))
    context.command_code("ip netns exec {device}_ns ip link set {device} netns 1".format(device=device))
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")


@step('Prepare simulated test "{device}" device with a bridged peer')
@step('Prepare simulated test "{device}" device with a bridged peer with bridge options "{bropts}"')
@step('Prepare simulated test "{device}" device with a bridged peer and veths to namespaces "{namespaces}"')
@step('Prepare simulated test "{device}" device with a bridged peer with bridge options "{bropts}" and veths to namespaces "{namespaces}"')
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
    nmci.cleanup.cleanup_add_namespace(f"{device}_ns")
    nmci.process.run_stdout(f"ip netns add {device}_ns")
    nmci.process.run_stdout(f"ip l add {device} type veth peer name {device}p netns {device}_ns")
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
        ns
        nmci.cleanup.cleanup_add_namespace(ns)
        nmci.process.run_stdout(f"ip netns add {ns}")
        nmci.process.run_stdout(f"ip -n {ns} l add veth0 type veth peer name {ns} netns {device}_ns")
        nmci.process.run_stdout(f"ip -n {ns} l set veth0 up")
        nmci.process.run_stdout(f"ip -n {device}_ns l set {ns} master br0")
        nmci.process.run_stdout(f"ip -n {device}_ns l set {ns} up")


@step(u'Start pppoe server with "{name}" and IP "{ip}" on device "{dev}"')
def start_pppoe_server(context, name, ip, dev):
    context.command_code("ip link set dev %s up" % dev)
    context.pexpect_service("pppoe-server -S %s -C %s -L %s -p /etc/ppp/allip -I %s" % (name, name, ip, dev), shell=True)
    time.sleep(1)


@step(u'Start pppoe server with "{name}" and IP "{ip}" in namespace "{dev}"')
def start_pppoe_server(context, name, ip, dev):
    dev_p = dev + "p"
    context.execute_steps(u"""
            * Prepare simulated test "%s" device""" % dev)
    context.pexpect_service("ip netns exec %s_ns pppoe-server -S %s -C %s -L %s -p /etc/ppp/allip -I %s" %(dev, name, name, ip, dev_p), shell=True)
    time.sleep(1)


@step(u'Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}"')
def setup_macsec_psk(context, cak, ckn):
    context.command_code("modprobe macsec")
    context.execute_steps(f'* Add namespace "macsec_ns"')
    context.execute_steps(f'* Create "veth" device named "macsec_veth" with options "peer name macsec_vethp"')
    context.command_code("ip link set macsec_vethp netns macsec_ns")
    context.command_code("ip link set macsec_veth up")
    context.command_code("ip netns exec macsec_ns ip link set macsec_vethp up")
    context.command_code("echo 'eapol_version=3' > /tmp/wpa_supplicant.conf")
    context.command_code("echo 'ap_scan=0' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo 'network={' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  key_mgmt=NONE' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  eapol_flags=0' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  macsec_policy=1' >> /tmp/wpa_supplicant.conf")
    context.command_code("echo '  mka_cak={cak}' >> /tmp/wpa_supplicant.conf".format(cak=cak))
    context.command_code("echo '  mka_ckn={ckn}' >> /tmp/wpa_supplicant.conf".format(ckn=ckn))
    context.command_code("echo '}' >> /tmp/wpa_supplicant.conf")

    context.command_code("ip netns exec macsec_ns wpa_supplicant \
                                         -c /tmp/wpa_supplicant.conf \
                                         -i macsec_vethp \
                                         -B \
                                         -D macsec_linux \
                                         -P /tmp/wpa_supplicant_ms.pid")
    time.sleep(6)
    assert context.command_code("ip netns exec macsec_ns ip link show macsec0") == 0, "wpa_supplicant didn't create a MACsec interface"
    assert context.command_code("nmcli device set macsec_veth managed yes") == 0, "wpa_supplicant didn't create a MACsec interface"
    context.command_code("ip netns exec macsec_ns ip link set macsec0 up")
    context.command_code("ip netns exec macsec_ns ip addr add 172.16.10.1/24 dev macsec0")
    context.command_code("ip netns exec macsec_ns ip -6 addr add 2001:db8:1::fffe/32 dev macsec0")
    context.command_code("ip netns exec macsec_ns dnsmasq \
                                         --pid-file=/tmp/dnsmasq_ms.pid \
                                         --dhcp-range=172.16.10.10,172.16.10.254,60m  \
                                         --interface=macsec0 \
                                         --bind-interfaces")


@step(u'Set default DCB options')
def set_default_dcb(context):
    context.execute_steps(u"""
    * Execute "nmcli con modify dcb dcb.app-fcoe-flags 7 dcb.app-fcoe-priority 7 dcb.app-fcoe-mode vn2vn dcb.app-iscsi-flags 7 dcb.app-iscsi-priority 6 dcb.app-fip-flags 7 dcb.app-fip-priority 2  dcb.priority-flow-control-flags 7 dcb.priority-flow-control 1,0,0,1,1,0,1,0 dcb.priority-group-flags 7 dcb.priority-group-id 0,0,0,0,1,1,1,1 dcb.priority-group-bandwidth 13,13,13,13,12,12,12,12 dcb.priority-bandwidth 100,100,100,100,100,100,100,100 dcb.priority-traffic-class 7,6,5,4,3,2,1,0"
    """)


@step(u'Prepare "{mode}" iptunnel networks A and B')
def prepare_iptunnel_doc(context, mode):
    bridge = False
    if mode == "gretap":
        bridge = True

    # prepare Network A (range 192.0.2.1/2) and Network B in namespace (range 172.16.0.1/24)
    context.execute_steps('* Prepare simulated test "netA" device without DHCP')
    context.execute_steps('* Prepare simulated test "netB" device without DHCP')
    context.execute_steps('* Add namespace "iptunnelB"')
    context.command_code("ip link set netB netns iptunnelB")
    if bridge:
        # if bridge, add addresses to "computers" in local networks
        context.command_code("ip -n netA_ns addr add 192.0.2.3/24 dev netAp")
        context.command_code("ip -n netB_ns addr add 192.0.2.4/24 dev netBp")
    else:
        # only add local addresses if not bridge
        context.command_code("ip addr add 192.0.2.1/24 dev netA")
        context.command_code("ip -n iptunnelB address add 172.16.0.1/24 dev netB")

    # connect Network A (public IP 203.0.113.10) and Network B (public IP 198.51.100.5) via veth pair ipA and ipB
    context.execute_steps('* Create "veth" device named "ipA" with options "peer name ipB"')
    context.command_code("ip link set ipA up")
    context.command_code("ip addr add 203.0.113.10/32 dev ipA")
    context.command_code("ip route add 198.51.100.5/32 dev ipA")
    context.command_code("ip link set ipB netns iptunnelB")
    context.command_code("ip -n iptunnelB link set ipB up")
    context.command_code("ip -n iptunnelB address add 198.51.100.5/32 dev ipB")
    context.command_code("ip -n iptunnelB route add 203.0.113.10/32 dev ipB")
    assert context.command_code("ping -c 1 198.51.100.5") == 0, \
        "unable to ping public IP of B from A"
    assert context.command_code("ip netns exec iptunnelB ping -c 1 203.0.113.10") == 0, \
        "unable to ping public IP of A from B"

    # preapre Network B part of iptunnel (in iptunnelB namespace)
    context.command_code("ip -n iptunnelB link add name tunB type %s local 198.51.100.5 remote 203.0.113.10" % (mode))
    context.command_code("ip -n iptunnelB link set tunB up")
    if not bridge:
        context.command_code("ip -n iptunnelB addr add 10.0.1.2/30 dev tunB")
        context.command_code("ip -n iptunnelB route add 10.0.1.1 dev tunB")
        context.command_code("ip -n iptunnelB route add 192.0.2.0/24 dev tunB")
    else:
        context.command_code("ip -n iptunnelB link add brB type bridge")
        context.command_code("ip -n iptunnelB link set netB down")
        context.command_code("ip -n iptunnelB link set netB master brB")
        context.command_code("ip -n iptunnelB link set netB up")
        context.command_code("ip -n iptunnelB link set brB up")
        context.command_code("ip -n iptunnelB addr add 192.0.2.2/24 dev brB")
        context.command_code("ip -n iptunnelB link set tunB master brB")
