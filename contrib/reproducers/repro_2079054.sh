#!/bin/sh


set -e

for i in {1..100}
do
    ip link del testbr 2>&1 || :
    
    ip link add name testbr type bridge forward_delay 0
    
    nmcli d set testbr managed false
    
    
    ip link set testbr up
    ip addr add 192.0.2.1/24 dev testbr
    ip -6 addr add 2001:DB8::1/32 dev testbr
    
    if ! ip addr show testbr | grep -q "192.0.2.1"; then
        echo
        echo "*** Error - Missing configured IPv4 address"
        ip addr show testbr
        exit 1
    elif ! ip addr show testbr | grep -q "2001:db8::1"; then
        echo
        echo "*** Error - Missing configured IPv6 address"
        ip addr show testbr
        exit 1
    fi
    sleep 0.1
done

exit 0