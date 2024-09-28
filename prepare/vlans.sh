#!/bin/bash

ID_START=10

function setup {
    set -e
    ID_END=$(($NUM+9))

    ip netns add eth11_ns
    ip link add eth11 type veth peer name eth11p
    ip link set dev eth11 up
    ip link set dev eth11p netns eth11_ns
    ip -n eth11_ns link set dev eth11p up
    nmcli dev set eth11 managed yes
    ip netns exec eth11_ns sysctl -w net.ipv6.conf.all.disable_ipv6=1
    ip netns exec eth11_ns sysctl -w net.ipv6.conf.default.disable_ipv6=1
    for i in $(seq $ID_START $ID_END); do
            ip -n eth11_ns link add link eth11p name eth11p.$i type vlan id $i
            ip -n eth11_ns link set eth11p.$i up
            ip -n eth11_ns add add 11.1.$((i / 100)).$((i % 100))/8 dev eth11p.$i
    done

    ip netns exec eth11_ns dnsmasq \
            --conf-file=/dev/null \
            --dhcp-lease-max=2000 \
            --dhcp-range=11.2.0.1,11.2.10.250,20m \
            --no-ping \
            $(seq -f "--interface=eth11p.%g" $ID_START $ID_END) \
            --dhcp-leasefile=/var/lib/dnsmasq/vlans.leases \
            --pid-file=/tmp/dnsmasq_vlan.pid
    echo $NUM > /tmp/vlan_count.txt
    echo "*****************************************"
    echo "$NUM vlans inside namespace created!"
    echo "check via: 'ip netns exec eth11_ns ip a s'"
}

function delete_connection_files {
    echo "Deleting connection files, NM is unresponsive..."
    rm -f /etc/NetworkManager/system-connections/eth11.*
    rm -f /etc/sysconfig/network-scripts/ifcfg-eth11.*
    nmcli con reload || true
}

function delete_links {
    echo "Deleting link devices, NM is unresponsive..."
    # get active inetrafce names, parse the following line format:
    # 012: eth11.XY@eth11: <BROADCAST...
    links=$(ip link | grep -F eth11. | sed 's/^[^:]*://;s/:.*$//;s/@.*$//')
    for link in $links; do
        ip link del $link
    done

    # example format of busctl output, grep for array length (number separated by spaces):
    # ao 14 "/org/freedesktop/NetworkManager/Devices/1" "/org/freedesktop/NetworkManager/Devices/2"...
    dev=$(timeout 5 \
        busctl call org.freedesktop.NetworkManager \
            /org/freedesktop/NetworkManager \
            org.freedesktop.NetworkManager \
            GetAllDevices | \
        grep -o " [0-9]* ")
    (( dev > 0 && dev < 20 )) && return 0

    # If NM is unresponsive, stop it, it will start after scenario - PID check will not take effect here
    echo Stopping NM, found number of devices: $dev
    systemctl stop NetworkManager
}

function clean {
    set -x
    pkill -F /tmp/dnsmasq_vlan.pid || true
    NUM=$(cat /tmp/vlan_count.txt)
    rm -rf /tmp/vlan_count.txt
    rm -rf /var/lib/dnsmasq/vlans.leases
    rm -rf /etc/dnsmasq.d/vlan.conf

    if ! [[ $NUM =~ ^-?[0-9]+$ ]]; then
        echo "No /tmp/vlan_count.txt, cleaning up to 1000"
        NUM=1000
    fi
    echo "Cleaning $NUM vlans"
    ID_END=$(($NUM+9))

    cons=$(nmcli -f NAME c | grep -F eth11.)
    nmcli con del $cons || delete_connection_files

    # give NM some time to delete links
    for _ in {1..10}; do
        links=$(ip link | grep -F eth11. | wc -l)
        ((links == 0)) && break
        echo Found $links vlan devices, waiting...
        sleep 1
    done

    # delete them manually if not gone yet
    links=$(ip link | grep -F eth11. | wc -l)
    ((links > 0)) && delete_links

    ip netns del eth11_ns || true
    ip link del eth11 || true
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
