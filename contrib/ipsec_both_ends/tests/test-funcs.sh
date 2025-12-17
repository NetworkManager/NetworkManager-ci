#!/bin/bash

ping_host()
{
    local host="$1"
    local src="$2"

    ping -i 0.2 -c 4 -w 10 ${src:+-I "$src"} "$host" || exit 1
}

check_iface_addr()
{
    ip addr show dev $1 | grep -E "inet.? $2" > /dev/null ||
        exit 1
}

check_xfrm_esp()
{
    ip xfrm policy get $* | grep "proto esp" > /dev/null ||
        exit 1
}

check_dns_server()
{
    grep "^nameserver $1\$" /etc/resolv.conf > /dev/null ||
        exit 1
}

check_dns_domain()
{
    grep "^search.*$1" /etc/resolv.conf > /dev/null ||
        exit 1
}

cleanup_connections()
{
    for uuid in $(nmcli -g uuid connection show); do
        name=$(nmcli -g connection.id connection show $uuid)
        if [ "$name" != "eth0" ] && [ "$name" != "lo" ]; then
            nmcli connection delete "$uuid"
        fi
    done
}
