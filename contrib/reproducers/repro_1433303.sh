#!/bin/bash
ip l add brX type bridge

add_ports() {
    for i in $(seq $1 $2); do
        ip l add veth$i type veth peer name vethp$i
        ip l set veth$i up
        ip a a dev veth$i 9.9.9.9
        ip l set veth$i master brX
        ip l del veth$i
    done
    return 0
}

add_ports 1 250 &
add_ports 251 500 &
add_ports 501 750 &
add_ports 751 1000 &
