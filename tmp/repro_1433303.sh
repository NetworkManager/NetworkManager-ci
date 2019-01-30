#!/bin/bash
ip l add brX type bridge
for i in $(seq 1 750); do
        echo $i;
        ip l add veth$i type veth peer name vethp$i
        ip l set veth$i up
        ip a a dev veth$i 9.9.9.9
        ip l set veth$i master brX
        ip l del veth$i
done

sleep 2
