#!/bin/bash

ip l del brX
sleep 0.5

ip l add brX type bridge

add_ports() {
    for i in $(seq $1 $2); do
        ip l add veth$i type veth peer name vethp$i
        ip l set veth$i up
        ip a a dev veth$i 9.9.9.9
        ip l set veth$i master brX
        sleep 0.05
        ip l del veth$i &
    done
    return 0
}

add_ports 1 500 &
add_ports 501 1000 &

sleep 3
