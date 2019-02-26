#!/bin/sh

# 1. make veth managed by changing /usr/lib/udev/rules.d/85-nm-unmanaged.rules
# 2. check that DHCP connections are generated by NM for veths (uninstall NM-config-server package)

i=0
while ((i<20)); do
    ip l add veth$i type veth peer name veth${i}p
    ip l set veth$i up
    ip l set veth${i}p up
    ((i++))
    sleep 0.2
done

sleep 5

i=0
while ((i<20)); do
    ip link del veth$i
    ((i++))
    nmcli con del "Wired connection $i"
done
