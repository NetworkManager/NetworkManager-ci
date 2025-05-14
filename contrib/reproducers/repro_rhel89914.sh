#!/bin/bash

cleanup()
{
    ip link del vrf0
    ip link del veth0
    ip link del veth1
    ip netns del ns1
    nmcli connection delete vrf0
}

cleanup 2> /dev/null

set -e

ip netns add ns1
ip link add veth0 type veth peer name veth1 netns ns1
ip link set veth0 up
ip -n ns1 link set veth1 up

sleep 1

for i in $(seq 1 10); do
    printf "\n ---- iteration $i\n"
    sleep .01
    logger -t NetworkManager "TEST ITERATION $i"
    sleep .01

    ip link add vrf0 type vrf table 10
    ip link set vrf0 up
    ip link set veth0 master vrf0

    # Wait up to 0.5s for device state to become 100
    for i in $(seq 1 5); do
        state=$(nmcli --terse -g general.state device show vrf0 | cut -f1 -d " ")
        if [ "$state" = 100 ]; then
            break
        fi
        sleep 0.1
    done

    if [ "$state" != 100 ]; then
        printf "\n*** ERROR: state is $state\n"
        nmcli device
        exit 1
    fi

    ip link del vrf0
    sleep .2
done

