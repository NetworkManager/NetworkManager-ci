#!/bin/sh

function teardown() {
    ip l del ipip1
    ip l del gre1
    ip l del ip6gre1
    ip l del veth0
    ip netns del iptunnel
    nmcli connection delete iptunnel-veth ipip1 gre1
    modprobe -r ip_gre
    modprobe -r ipip
    modprobe -r ip6_gre
    modprobe -r sit
    modprobe -r ip_tunnel
    modprobe -r ip6_tunnel
}

function setup() {
    # prepare namespace and veth pair
    ip netns add iptunnel
    ip -n iptunnel link set lo up
    ip link add veth0 type veth peer name veth1
    ip link set veth1 netns iptunnel
    ip -n iptunnel link set veth1 up
    ip -n iptunnel address add dev veth1 172.25.16.2/24
    ip -n iptunnel -6 address add dev veth1 fe80:feed::beef/64
    # prepare tunnels in namespace - ipip
    ip -n iptunnel tunnel add ipip2 mode ipip remote 172.25.16.1 local 172.25.16.2 dev veth1
    ip -n iptunnel link set ipip2 up
    ip -n iptunnel address add dev ipip2 172.25.30.2/24
    # prepare tunnels in namespace - gre
    ip -n iptunnel tunnel add gre2 mode gre remote 172.25.16.1 local 172.25.16.2 dev veth1
    ip -n iptunnel link set gre2 up
    ip -n iptunnel address add dev gre2 172.25.31.2/24
    ip -n iptunnel -6 address add dev gre2  fe80:dead::beef/64
    # prepare tunnels in namespace - ip6gre
    ip -n iptunnel tunnel add ip6gre2 mode ip6gre remote fe80:feed::b00f local fe80:feed::beef dev veth1
    ip -n iptunnel link set ip6gre2 up
    ip -n iptunnel -6 address add dev ip6gre2 fe80:deaf::beef/64

    # prepare nmcli
    nmcli connection add type ethernet ifname veth0 con-name iptunnel-veth ip4 172.25.16.1/24 ip6 fe80:feed::b00f/64
    nmcli connection up iptunnel-veth
}

if [ "$1" == "teardown" ] ; then
    teardown
else
    setup
fi
