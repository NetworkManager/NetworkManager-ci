#!/bin/bash
set -e
PID1=$(pidof NetworkManager)

nmcli  connection add type veth con-name test11+ ifname test11 veth.peer test12 ip4 10.42.0.2
nmcli  connection add type veth con-name test12+ ifname test12 veth.peer test11 ip4 10.42.0.1

nmcli con up test12+
while ! nmcli -g GENERAL.STATE con show test11+ |grep activated; do :;sleep 1;done

nmcli con del test11+ test12+

PID2=$(pidof NetworkManager)

echo $PID1
echo $PID2

if [ $PID1 != $PID2 ]; then
    exit 1
else
    exit 0
fi

