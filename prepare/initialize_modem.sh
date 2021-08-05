#!/bin/bash
TIMER=30
while [ $TIMER -gt 0 ]; do
    if nmcli d |grep -q gsm; then
        mmcli -m $(mmcli -L |awk -F '/' '{print $6}')
        if mmcli -m $(mmcli -L |awk -F '/' '{print $6}' |awk '{print $1}') |grep 'state:\sregistered'; then
            exit 0
        fi
    fi
    if [ $TIMER -eq 20 ]; then
        echo "**********************************"
        echo "DOING RESTART THIS SHOULDNT HAPPEN"
        echo "**********************************"
        mmcli -m $(mmcli -L |awk -F '/' '{print $6}') -r
    fi
    if [ $TIMER -eq 10 ]; then
        echo "********************************************"
        echo "DOING RESTART ONCE MORE THIS SHOULDNT HAPPEN"
        echo "********************************************"
        mmcli -m $(mmcli -L |awk -F '/' '{print $6}') -r
    fi

    mmcli -L
    sleep 10
    ((TIMER--))
done

exit 1
