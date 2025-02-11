#!/bin/bash
nmstatectl apply contrib/reproducers/repro_77167.yaml

for i in {1..10}; do
    printf "\n############### iteration $i\n\n"
    systemctl restart NetworkManager
    sleep 2
    connected=0
    for t in {1..20}; do
        sleep .5
        if ! ip addr show br-ex 2>/dev/null | grep "192.0.2.1" >/dev/null; then
            continue
        fi

        if [ "$(nmcli -g GENERAL.STATE connection show patch-ex-to-phy-if)" != activated ]; then
            continue
        fi

        connected=1
        break
    done
    if [ "$connected" = 0 ]; then
        nmcli device
        printf "\n\n\n *** ERROR: not connected at iteration $i\n\n"
        exit 1
    fi
done
sleep 5