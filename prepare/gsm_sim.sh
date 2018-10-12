#!/bin/bash

function modem_setup ()
{
    # deactivate physical devices
    for i in $(ls /sys/bus/usb/devices/usb*/authorized)
    do
        echo 0 > $i
    done
    
    # get modemu script from NM repo
    [ -f /tmp/gsm_sim.pl ] ||  wget -O /tmp/gsm_sim.pl https://raw.githubusercontent.com/NetworkManager/NetworkManager/master/contrib/test/modemu.pl

    # create simulated gsm device using perl script
    (
        while true;
        do
            perl /tmp/gsm_sim.pl $1 &
            # get pid of perl script
            echo $!> /tmp/gsm_sim_perl.pid
            wait
        done
    ) &
    # get pid of while loop
    echo $! > /tmp/gsm_sim.pid
}

function modem_teardown ()
{
    nmcli con down id gsm
    nmcli con del id gsm
    # kill while loop, prevent spawning another perl
    kill $(cat /tmp/gsm_sim.pid)
    # now kill remaining perl (if not killed behave hangs)
    kill $(cat /tmp/gsm_sim_perl.pid)
}

if [ "$1" != "teardown" ]; then
    modem_setup $1
else
    modem_teardown
fi
