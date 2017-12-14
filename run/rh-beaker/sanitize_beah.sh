#! /bin/bash
set -x
sudo sysctl net.ipv6.conf.all.disable_ipv6=1
sudo sysctl net.ipv6.conf.all.disable_ipv6=0

nmcli con del testeth0
ip addr flush dev eth0

sleep 1

nmcli connection add type ethernet ifname eth0 con-name testeth0
nmcli connection modify testeth0 ipv6.may-fail no
nmcli con up testeth0
nmcli con down testeth0

sleep 5

systemctl restart NetworkManager
sleep 30

ip a s eth0
ip -6 r

systemctl restart beah*
sleep 120

rhts-report-result $TEST "PASS" "/dev/null"

exit 0
