#!/bin/bash
ip l add br1 type bridge
for i in $(seq 1 1000); do
        echo $i;
        ip l add veth$i type veth peer name vethp$i
        ip l set veth$i up
        ip a a dev veth$i 9.9.9.9
        ip l set veth$i master br1
        ip l del veth$i
done

sleep 2
