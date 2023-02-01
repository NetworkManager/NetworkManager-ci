#!/bin/bash

function modem_setup ()
{
    # deactivate physical devices
    for i in $(ls /sys/bus/usb/devices/usb*/authorized)
    do
        if [ -f "$i" ]; then
            echo 0 > $i
        fi
    done

    # get modemu script from NM repo
    #[ -f /tmp/gsm_sim.pl ] ||  wget -O /tmp/gsm_sim.pl https://raw.githubusercontent.com/NetworkManager/NetworkManager/main/contrib/test/modemu.pl

    perl contrib/gsm_sim/gsm_sim.pl $1 -- pppd dump debug 172.31.82.1:172.31.82.2 ms-dns 172.16.1.1 &
    # get pid of perl script
    echo $!> /tmp/gsm_sim.pid
    wait
}

function modem_teardown ()
{
    #nmcli con down id gsm
    #nmcli con del id gsm
    pkill -F /tmp/gsm_sim.pid
}

if [ "$1" != "teardown" ]; then
    modem_setup $1 >> /tmp/gsm_sim.log 2>&1
else
    modem_teardown
fi
