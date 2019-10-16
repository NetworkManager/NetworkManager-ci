#!/usr/bin/bash

DUMMY=dummy0

function set_up {
    ip l add $DUMMY type dummy
    ip l set up dev $DUMMY
}

function tear_down {
    ip l del $DUMMY
}

function test_add_del_addr {
    tear_down
    set_up

    ip a add 192.168.212.212/24 dev $DUMMY
    ip a | grep -q '192.168.212.212/24' || { echo Error: missing ipv4 address after ipv4 add; exit 1; }

    ip a add 2002:99::1/64 dev $DUMMY
    ip a | grep -q '192.168.212.212/24' || { echo Error: missing ipv4 address after ipv6 add; exit 1; }
    ip a | grep -q '2002:99' || { echo Error: missing ipv6 address after ipv6 add; exit 1; }

    ip a del 2002:99::1/64 dev $DUMMY
    ip a | grep -q '192.168.212.212/24' || { echo Error: missing ipv4 address after ipv6 del; exit 1; }
    ip a | grep -q '2002:99' && { echo Error: found ipv6 address after ipv6 del; exit 1; }

    ip a del 192.168.212.212/24 dev $DUMMY
    ip a | grep -q '192.168.212.212/24' && { echo Error: found ipv4 address after ipv4 del; exit 1; }
    ip a | grep -q '2002:99' && { echo Error: found ipv6 address after ipv4 del; exit 1; }
}

for i in `seq 1 100` :; do
    test_add_del_addr
done

exit 0
