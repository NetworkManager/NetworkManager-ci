#! /bin/bash
set -x
#sudo sysctl net.ipv6.conf.all.disable_ipv6=1
#sudo sysctl net.ipv6.conf.all.disable_ipv6=0

#nmcli dev disconnect eth0
#nmcli con del testeth0
#sleep 1
#nmcli connection add type ethernet ifname eth0 con-name testeth0
#nmcli connection modify testeth0 ipv6.may-fail no
#nmcli con up id testeth0
#ip a s eth0
#ip -6 r

#sudo kill -9 $(ps aux|grep -v grep| grep beah-beaker-backend |awk '{print $2}')
#sudo /usr/bin/python /usr/bin/beah-beaker-backend --log-stderr &

nmcli dev disconnect eth0
nmcli con del testeth0
sleep 1
nmcli connection add type ethernet ifname eth0 con-name testeth0
nmcli connection modify testeth0 ipv6.may-fail no
nmcli con up id testeth0
ip a s eth0
ip -6 r
sleep 30

systemctl condreload beah-beaker-backend.service

sleep 30

exit 0
