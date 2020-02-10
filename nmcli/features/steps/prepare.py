# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob

from steps import command_output, command_code, additional_sleep



@step(u'Create PBR files for profile "{profile}" and "{dev}" device in table "{table}"')
def create_policy_based_routing_files(context, profile, dev, table):
    ips = command_output(context, "nmcli connection sh %s |grep IP4.ADDRESS |awk '{print $2}'" % profile)
    ip_slash_prefix = ips.split('\n')[0]
    ip = ip_slash_prefix.split('/')[0]
    gw = command_output(context, "nmcli connection sh %s |grep IP4.GATEWAY |awk '{print $2}'" % profile).strip()
    command_code(context, "echo '%s dev %s table %s' > /etc/sysconfig/network-scripts/route-%s" % (ip_slash_prefix, dev, table, profile))
    command_code(context, "echo 'default via %s dev %s table %s' >> /etc/sysconfig/network-scripts/route-%s" % (gw, dev, table, profile))

    command_code(context, "echo 'iif %s table %s' > /etc/sysconfig/network-scripts/rule-%s" % (dev, table, profile))
    command_code(context, "echo 'from %s table %s' >> /etc/sysconfig/network-scripts/rule-%s" % (ip, table, profile))
    sleep(3)


@step(u'Configure dhcp server for subnet "{subnet}" with lease time "{lease}"')
def config_dhcp(context, subnet, lease):
    config = []
    config.append('default-lease-time %d;' %int(lease))
    config.append('max-lease-time %d;' %(int(lease)*2))
    config.append('subnet %s.0 netmask 255.255.255.0 {' %subnet)
    config.append('range %s.128 %s.250;' %(subnet, subnet))
    config.append('option routers %s.1;' %subnet)
    config.append('option domain-name "nodhcp";')
    config.append('option domain-name-servers %s.1, 8.8.8.8;}' %subnet)

    f = open('/etc/dhcp/dhcpd.conf','w')
    for line in config:
        f.write(line+'\n')
    f.close()


@step(u'Prepare connection')
def prepare_connection(context):
    context.execute_steps(u"""
        * Execute "nmcli con modify dcb ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv6.method ignore"
    """)


@step(u'Prepare "{conf}" config for "{device}" device with "{vfs}" VFs')
def prepare_sriov_config(context, conf, device, vfs):
    conf_path = "/etc/NetworkManager/conf.d/"+conf
    command_code(context, "echo '[device-%s]' > %s" % (device, conf_path))
    command_code(context, "echo 'match-device=interface-name:%s' >> %s" % (device, conf_path))
    command_code(context, "echo 'sriov-num-vfs=%d' >> %s" % (int(vfs), conf_path))
    command_code(context, 'systemctl reload NetworkManager')


@step(u'Prepare PBR documentation procedure')
def pbr_doc_proc(context):
    context.execute_steps('''
        * Prepare simulated test "provA" device without DHCP
        * Finish "ip -n provA_ns address add 198.51.100.2/30 dev provAp"
        * Prepare simulated test "provB" device without DHCP
        * Finish "ip -n provB_ns address add 192.0.2.2/30 dev provBp"
        * Prepare simulated test "servers" device without DHCP
        * Finish "ip -n servers_ns address add 203.0.113.2/24 dev serversp"
        * Prepare simulated test "int_work" device without DHCP
        * Finish "ip -n int_work_ns address add 10.0.0.2/24 dev int_workp"
        * Create device "defA" in "provA_ns" with address "172.20.20.20/24"
        * Create device "defB" in "provB_ns" with address "172.20.20.20/24"
    ''')


@step(u'Prepare pppoe server for user "{user}" with "{passwd}" password and IP "{ip}" authenticated via "{auth}"')
def prepare_pppoe_server(context, user, passwd, ip, auth):
    command_code(context, "echo -e 'require-%s\nlogin\nlcp-echo-interval 10\nlcp-echo-failure 2\nms-dns 8.8.8.8\nms-dns 8.8.4.4\nnetmask 255.255.255.0\ndefaultroute\nnoipdefault\nusepeerdns' > /etc/ppp/pppoe-server-options" %auth)
    command_code(context, "echo '%s * %s %s' > /etc/ppp/%s-secrets" %(user, passwd, ip, auth))
    command_code(context, "echo '%s-253' > /etc/ppp/allip" % ip)


@step(u'Prepare veth pairs "{pairs_array}" bridged over "{bridge}"')
def prepare_veths(context, pairs_array, bridge):
    os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''')
    command_code(context, "udevadm control --reload-rules")
    command_code(context, "udevadm settle --timeout=5")
    command_code(context, "sleep 1")

    pairs = []
    for pair in pairs_array.split(','):
        pairs.append(pair.strip())

    command_code(context, "sudo ip link add name %s type bridge"% bridge)
    command_code(context, "sudo ip link set dev %s up"% bridge)
    for pair in pairs:
        command_code(context, "ip link add %s type veth peer name %sp" %(pair, pair))
        command_code(context, "ip link set %sp master %s" %(pair, bridge))
        command_code(context, "ip link set dev %s up" % pair)
        command_code(context, "ip link set dev %sp up" % pair)


@step(u'Start radvd server with config from "{location}"')
def start_radvd(context, location):
    command_code(context, "rm -rf /etc/radvd.conf")
    command_code(context, "cp %s /etc/radvd.conf" % location)
    command_code(context, "systemctl restart radvd")
    sleep(2)


@step(u'Restart dhcp server on {device} device with {ipv4} ipv4 and {ipv6} ipv6 dhcp address prefix')
def restart_dhcp_server(context, device, ipv4, ipv6):
    command_code(context, 'kill $(cat /tmp/{device}_ns.pid)'.format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr flush dev {device}_bridge".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(device=device, ip=ipv4))
    command_code(context, "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(device=device, ip=ipv6))
    command_code(context, "ip netns exec {device}_ns dnsmasq \
                                        --pid-file=/tmp/{device}_ns.pid \
                                        --dhcp-leasefile=/tmp/{device}_ns.lease \
                                        --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                        --dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,2m \
                                        --enable-ra --interface={device}_bridge \
                                        --bind-interfaces".format(device=device, ipv4=ipv4, ipv6=ipv6))


@step(u'Prepare simulated test "{device}" device using dhcpd')
@step(u'Prepare simulated test "{device}" device using dhcpd and server identifier "{server_id}"')
def prepare_dhcpd_simdev(context, device, server_id):
    ipv4 = "192.168.99"
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip link set {device}p netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(device=device, ip=ipv4))
    command_code(context, "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts")
    command_code(context, "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts")
    command_code(context, "echo '192.168.99.10 ip-192-168-99-10' >> /etc/hosts")
    command_code(context, "echo '192.168.99.11 ip-192-168-99-11' >> /etc/hosts")
    command_code(context, "echo '192.168.99.12 ip-192-168-99-12' >> /etc/hosts")
    command_code(context, "echo '192.168.99.13 ip-192-168-99-13' >> /etc/hosts")
    command_code(context, "echo '192.168.99.14 ip-192-168-99-14' >> /etc/hosts")
    command_code(context, "echo '192.168.99.15 ip-192-168-99-15' >> /etc/hosts")

    config = []
    if server_id is not None:
        config.append("server-identifier {server_id};".format(server_id=server_id))
    config.append("max-lease-time 120;")
    config.append("default-lease-time 120;")
    config.append("subnet {ip}.0 netmask 255.255.255.0 {{".format(ip=ipv4))
    config.append("  range {ip}.10 {ip}.15;".format(ip=ipv4))
    config.append("}}".format(ip=ipv4))

    f = open('/tmp/dhcpd.conf','w')
    for line in config:
        f.write(line + '\n')
    f.close()

    command_code(context, "ip netns exec {device}_ns dhcpd -4 -cf /tmp/dhcpd.conf -pf /tmp/{device}_ns.pid".format(device=device))
    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)

@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix and dhcp option "{option}"')
@step(u'Prepare simulated test "{device}" device with "{ipv4}" ipv4 and "{ipv6}" ipv6 dhcp address prefix')
@step(u'Prepare simulated test "{device}" device with "{lease_time}" leasetime')
@step(u'Prepare simulated test "{device}" device with dhcp option "{option}"')
@step(u'Prepare simulated test "{device}" device')
@step(u'Prepare simulated test "{device}" device with daemon options "{daemon_options}"')
def prepare_simdev(context, device, lease_time="2m", ipv4=None, ipv6=None, option=None, daemon_options=None):
    if ipv4 is None:
        ipv4 = "192.168.99"
    if ipv6 is None:
        ipv6 = "2620:dead:beaf"
    if daemon_options is None:
        daemon_options = ""
    if not hasattr(context, 'testvethns'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="%s*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''' % device)
        command_code(context, "udevadm control --reload-rules")
        command_code(context, "udevadm settle --timeout=5")
        command_code(context, "sleep 1")
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip link set {device}p netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}p".format(device=device, ip=ipv4))
    command_code(context, "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}p".format(device=device, ip=ipv6))
    command_code(context, "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts")
    command_code(context, "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts")
    command_code(context, "echo '192.168.99.10 ip-192-168-99-10' >> /etc/hosts")
    command_code(context, "echo '192.168.99.11 ip-192-168-99-11' >> /etc/hosts")
    command_code(context, "echo '192.168.99.12 ip-192-168-99-12' >> /etc/hosts")
    command_code(context, "echo '192.168.99.13 ip-192-168-99-13' >> /etc/hosts")
    command_code(context, "echo '192.168.99.14 ip-192-168-99-14' >> /etc/hosts")
    command_code(context, "echo '192.168.99.15 ip-192-168-99-15' >> /etc/hosts")
    sleep(2)
    if lease_time == 'infinite':
        command_code(context, "ip netns exec {device}_ns dnsmasq \
                                            --pid-file=/tmp/{device}_ns.pid \
                                            --dhcp-leasefile=/tmp/{device}_ns.lease \
                                            --dhcp-range={ipv4}.10,{ipv4}.15,{lease_time} \
                                            {daemon_options} \
                                            --interface={device}p --bind-interfaces".format(device=device, lease_time=lease_time, ipv4=ipv4, daemon_options=daemon_options))
    else:
        if option is None:
            command_code(context, "ip netns exec {device}_ns dnsmasq \
                                                --pid-file=/tmp/{device}_ns.pid \
                                                --dhcp-leasefile=/tmp/{device}_ns.lease \
                                                --dhcp-range={ipv4}.10,{ipv4}.15,{lease_time} \
                                                --dhcp-range={ipv6}::100,{ipv6}::fff,slaac,64,{lease_time} \
                                                --enable-ra --interface={device}p \
                                                {daemon_options} \
                                                --bind-interfaces".format(device=device, lease_time=lease_time, ipv4=ipv4, ipv6=ipv6, daemon_options=daemon_options))
        else:
            command_code(context, "ip netns exec {device}_ns dnsmasq \
                                                --pid-file=/tmp/{device}_ns.pid \
                                                --dhcp-leasefile=/tmp/{device}_ns.lease \
                                                --dhcp-range={ipv4}.10,{ipv4}.15,{lease_time} \
                                                --dhcp-range={ipv6}::100,{ipv6}::1ff,slaac,64,{lease_time} \
                                                --enable-ra --interface={device}p \
                                                --dhcp-option-force={option} \
                                                {daemon_options} \
                                                --bind-interfaces".format(device=device, lease_time=lease_time, ipv4=ipv4, ipv6=ipv6, option=option, daemon_options=daemon_options))

    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)


@step(u'Prepare simulated test "{device}" device with DHCPv4 server on different network')
def prepare_simdev(context, device):
    if not hasattr(context, 'testvethns'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''')
        command_code(context, "udevadm control --reload-rules")
        command_code(context, "udevadm settle --timeout=5")
        command_code(context, "sleep 1")
    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    # (DHCP   | 172.16.0.1  10.0.0.2  | |  10.0.0.1   |
    # client) |(dhcrelay + forwarding)| | (DHCP serv) |
    #         +-----------------------+ +-------------+
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip netns add {device}2_ns".format(device=device))
    command_code(context, "ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip link add {device}2 type veth peer name {device}2p".format(device=device))
    command_code(context, "ip link set {device}p netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device}2 netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device}2p netns {device}2_ns".format(device=device))
    # Bring up devices
    command_code(context, "ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}2 up".format(device=device))
    command_code(context, "ip netns exec {device}2_ns ip link set {device}2p up".format(device=device))
    # Set addresses
    command_code(context, "ip netns exec {device}_ns ip addr add dev {device}p 172.16.0.1/24".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add dev {device}2 10.0.0.2/24".format(device=device))
    command_code(context, "ip netns exec {device}2_ns ip addr add dev {device}2p 10.0.0.1/24".format(device=device))
    # Enable forwarding and DHCP relay in first namespace
    command_code(context, "ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'".format(device=device))
    command_code(context, "ip netns exec {device}_ns dhcrelay -4 10.0.0.1 -pf /tmp/dhcrelay.pid".format(device=device))
    # Start DHCP server in second namespace
    # Push a default route and a route to reach the DHCP server
    command_code(context, "ip netns exec {device}2_ns dnsmasq \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}2p \
                                         --dhcp-range=172.16.0.100,172.16.0.200,255.255.255.0,1m \
                                         --dhcp-option=3,172.16.0.50 \
                                         --dhcp-option=121,10.0.0.0/24,172.16.0.1".format(device=device))
    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)
    context.testvethns.append("%s2_ns" % device)


@step(u'Prepare simulated test "{device}" device without DHCP')
def prepare_simdev_no_dhcp(context, device):
    if not hasattr(context, 'testvethns'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''')
        command_code(context, "udevadm control --reload-rules")
        command_code(context, "udevadm settle --timeout=5")
        command_code(context, "sleep 1")
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip link set {device}p netns {device}_ns".format(device=device))
    # Bring up devices
    command_code(context, "ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)


@step(u'Prepare simulated test "{device}" device for IPv6 PMTU discovery')
def prepare_simdev(context, device):
    if not hasattr(context, 'testvethns'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''')
        command_code(context, "udevadm control --reload-rules")
        command_code(context, "udevadm settle --timeout=5")
        command_code(context, "sleep 1")
    #         +-------testX_ns--------+ +--testX2_ns--+
    # testX <-|-> testXp     testX2 <-|-|-> testX2p   |
    #         |  fd01::1     fd02::1  | |   fd02::2   |
    # mtu 1500|   1500        1400    | |    1500     |
    #         +-----------------------+ +-------------+
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip netns add {device}2_ns".format(device=device))
    command_code(context, "ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip link add {device}2 type veth peer name {device}2p".format(device=device))
    command_code(context, "ip link set {device}p netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device}2 netns {device}_ns".format(device=device))
    command_code(context, "ip link set {device}2p netns {device}2_ns".format(device=device))
    # Bring up devices
    command_code(context, "ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}2 up".format(device=device))
    command_code(context, "ip netns exec {device}2_ns ip link set {device}2p up".format(device=device))
    # Set addresses
    command_code(context, "ip netns exec {device}_ns ip addr add dev {device}p fd01::1/64".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add dev {device}2 fd02::1/64".format(device=device))
    command_code(context, "ip netns exec {device}2_ns ip addr add dev {device}2p fd02::2/64".format(device=device))
    # Set MTU
    command_code(context, "ip netns exec {device}_ns ip link set {device}p mtu 1500".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}2 mtu 1400".format(device=device))
    command_code(context, "ip netns exec {device}2_ns ip link set {device}2p mtu 1500".format(device=device))
    # Set up router (testX_ns)
    command_code(context, "ip netns exec {device}_ns sh -c 'echo 1 > /proc/sys/net/ipv6/conf/all/forwarding'".format(device=device))
    command_code(context, "ip netns exec {device}_ns dnsmasq \
                                         --no-resolv \
                                         --pid-file=/tmp/{device}_ns.pid \
                                         --bind-interfaces -i {device}p \
                                         --enable-ra \
                                         --dhcp-range=::1,::400,constructor:{device}p,ra-only,64,15s".format(device=device))
    # Add route
    command_code(context, "ip netns exec {device}2_ns ip route add fd01::/64 via fd02::1 dev {device}2p".format(device=device))
    # Run netcat server to receive some data
    Popen("ip netns exec {device}2_ns nc -6 -l -p 8080 > /dev/null".format(device=device) , shell=True)

    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)
    context.testvethns.append("%s2_ns" % device)


@step(u'Prepare simulated veth device "{device}" wihout carrier')
def prepare_simdev_no_carrier(context, device):
    ipv4 = "192.168.99"
    ipv6 = "2620:dead:beaf"
    if not hasattr(context, 'testvethns'):
        os.system('''echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="test*", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/88-lr.rules''')
        command_code(context, "udevadm control --reload-rules")
        command_code(context, "udevadm settle --timeout=5")
        command_code(context, "sleep 1")
    command_code(context, "ip netns add {device}_ns".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link add {device} type veth peer name {device}p".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device} up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link add name {device}_bridge type bridge".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p master {device}_bridge".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip addr add {ip}.1/24 dev {device}_bridge".format(device=device, ip=ipv4))
    command_code(context, "ip netns exec {device}_ns ip -6 addr add {ip}::1/64 dev {device}_bridge".format(device=device, ip=ipv6))
    command_code(context, "ip netns exec {device}_ns ip link set {device}_bridge up".format(device=device))
    command_code(context, "ip netns exec {device}_ns ip link set {device}p down".format(device=device))
    command_code(context, "ip netns exec {device}_ns dnsmasq \
                                            --pid-file=/tmp/{device}_ns.pid \
                                            --dhcp-leasefile=/tmp/{device}_ns.lease \
                                            --dhcp-range={ipv4}.10,{ipv4}.15,2m \
                                            --dhcp-range={ipv6}::100,{ipv6}::1ff,slaac,64,2m \
                                            --enable-ra --interface={device}_bridge \
                                            --bind-interfaces".format(device=device, ipv4=ipv4, ipv6=ipv6))
    command_code(context, "ip netns exec {device}_ns ip link set {device} netns 1".format(device=device))
    if not hasattr(context, 'testvethns'):
        context.testvethns = []
    context.testvethns.append("%s_ns" % device)


@step(u'Start pppoe server with "{name}" and IP "{ip}" on device "{dev}"')
def start_pppoe_server(context, name, ip, dev):
    command_code(context, "ip link set dev %s up" %dev)
    Popen("kill -9 $(pidof pppoe-server); pppoe-server -S %s -C %s -L %s -p /etc/ppp/allip -I %s" %(name, name, ip, dev), shell=True)
    sleep(0.5)


@step(u'Prepare MACsec PSK environment with CAK "{cak}" and CKN "{ckn}"')
def setup_macsec_psk(context, cak, ckn):
    command_code(context, "modprobe macsec")
    command_code(context, "ip netns add macsec_ns")
    command_code(context, "ip link add macsec_veth type veth peer name macsec_vethp")
    command_code(context, "ip link set macsec_vethp netns macsec_ns")
    command_code(context, "ip link set macsec_veth up")
    command_code(context, "ip netns exec macsec_ns ip link set macsec_vethp up")
    command_code(context, "echo 'eapol_version=3' > /tmp/wpa_supplicant.conf")
    command_code(context, "echo 'ap_scan=0' >> /tmp/wpa_supplicant.conf")
    command_code(context, "echo 'network={' >> /tmp/wpa_supplicant.conf")
    command_code(context, "echo '  key_mgmt=NONE' >> /tmp/wpa_supplicant.conf")
    command_code(context, "echo '  eapol_flags=0' >> /tmp/wpa_supplicant.conf")
    command_code(context, "echo '  macsec_policy=1' >> /tmp/wpa_supplicant.conf")
    command_code(context, "echo '  mka_cak={cak}' >> /tmp/wpa_supplicant.conf".format(cak=cak))
    command_code(context, "echo '  mka_ckn={ckn}' >> /tmp/wpa_supplicant.conf".format(ckn=ckn))
    command_code(context, "echo '}' >> /tmp/wpa_supplicant.conf")

    command_code(context, "ip netns exec macsec_ns wpa_supplicant \
                                         -c /tmp/wpa_supplicant.conf \
                                         -i macsec_vethp \
                                         -B \
                                         -D macsec_linux \
                                         -P /tmp/wpa_supplicant_ms.pid")
    sleep(6)
    assert command_code(context, "ip netns exec macsec_ns ip link show macsec0") == 0, "wpa_supplicant didn't create a MACsec interface"
    command_code(context, "ip netns exec macsec_ns ip link set macsec0 up")
    command_code(context, "ip netns exec macsec_ns ip addr add 172.16.10.1/24 dev macsec0")
    command_code(context, "ip netns exec macsec_ns dnsmasq \
                                         --pid-file=/tmp/dnsmasq_ms.pid \
                                         --dhcp-range=172.16.10.10,172.16.10.254,60m  \
                                         --interface=macsec0 \
                                         --bind-interfaces")


@step(u'Set default DCB options')
def set_default_dcb(context):
    context.execute_steps(u"""
    * Execute "nmcli con modify dcb dcb.app-fcoe-flags 7 dcb.app-fcoe-priority 7 dcb.app-fcoe-mode vn2vn dcb.app-iscsi-flags 7 dcb.app-iscsi-priority 6 dcb.app-fip-flags 7 dcb.app-fip-priority 2  dcb.priority-flow-control-flags 7 dcb.priority-flow-control 1,0,0,1,1,0,1,0 dcb.priority-group-flags 7 dcb.priority-group-id 0,0,0,0,1,1,1,1 dcb.priority-group-bandwidth 13,13,13,13,12,12,12,12 dcb.priority-bandwidth 100,100,100,100,100,100,100,100 dcb.priority-traffic-class 7,6,5,4,3,2,1,0"
    """)
