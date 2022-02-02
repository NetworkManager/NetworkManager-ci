#!/bin/bash

ID_START=10

function setup {
    set -e
    ID_END=$(($NUM+10))

    echo "dhcp-lease-max=2000" > /etc/dnsmasq.d/vlan.conf

    ip netns add eth11_ns
    ip link add eth11 type veth peer name eth11p
    ip link set dev eth11 up
    ip link set dev eth11p netns eth11_ns
    ip -n eth11_ns link set dev eth11p up
    nmcli dev set eth11 managed yes
    ip netns exec eth11_ns sysctl -w net.ipv6.conf.all.disable_ipv6=1
    ip netns exec eth11_ns sysctl -w net.ipv6.conf.default.disable_ipv6=1
    for i in `seq $ID_START $ID_END`; do
            ip -n eth11_ns link add link eth11p name eth11p.$i type vlan id $i
            ip -n eth11_ns link set eth11p.$i up
            ip -n eth11_ns add add 11.1.$((i / 100)).$((i % 100))/8 dev eth11p.$i
    done
    ip netns exec eth11_ns dnsmasq \
            --dhcp-range=11.2.0.1,11.2.10.250,1h \
            --no-ping \
            --dhcp-leasefile=/var/lib/dnsmasq/vlans.leases \
            --pid-file=/tmp/dnsmasq_vlan.pid
    echo $NUM > /tmp/vlan_count.txt
    echo "*****************************************"
    echo "$NUM vlans inside namespace created!"
    echo "check via: 'ip netns exec eth11_ns ip a s'"


}

function clean {
    NUM=$(cat /tmp/vlan_count.txt)
    rm -rf /tmp/vlan_count.txt
    rm -rf /var/lib/dnsmasq/vlans.leases
    rm -rf /etc/dnsmasq.d/vlan.conf

    if ! [[ $NUM =~ ^-?[0-9]+$ ]]; then
        echo "No /tmp/vlan_count.txt, cleaning up to 1000"
        NUM=1000
    fi
    echo "Cleaning $NUM vlans"
    ID_END=$(($NUM+10))

    for i in $(seq $ID_START $ID_END); do
        ids="$ids eth11.$i"
    done
    nmcli con del $ids || true

    ip netns del eth11_ns || true
    ip link del eth11 || true
    pkill -F /tmp/dnsmasq_vlan.pid || true

}

if [ "$1" == "setup" ]; then
    NUM=$2
    if [[ $NUM =~ ^-?[0-9]+$ ]]; then
        if [ $NUM -gt 0 ] && [ $NUM -lt 1000 ]; then
            setup $NUM
        else
            echo "$NUM is not in (1, 1000) interval"
        fi

    else
        echo "$NUM is not an integer"
    fi

elif [ "$1" == "clean" ]; then
    clean
else
    echo "Usage:"
    echo "'$0 setup 500': to setup 500 vlans on top of eth11p veth"
    echo "'$0 clean': to clean previously created setup"

fi
