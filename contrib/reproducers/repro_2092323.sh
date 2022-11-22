#!/bin/bash

function setup_cons () {
    nmcli con add type team ifname nm-team con-name team0 config '{"runner": {"name": "lacp"}, "link_watch": {"name": "ethtool"}}' ipv4.method disable ipv6.method ignore;
    nmcli con add type	ethernet con-name  team-slave-eth5 ifname eth5;
    nmcli con up team-slave-eth5
}

function clean () {
    nmcli con del team0 team-slave-eth5;
    ERROR=$(nmcli con down testeth5 2>&1 >/dev/null)
    if [[ $ERROR == *"nm-CRITICAL"* ]]; then
        echo "$ERROR";
        exit 2;
    fi
}

function restart () {
    sleep 1
    systemctl restart NetworkManager
    sleep 1
}

function run () {
    setup_cons;
    restart;
    nmcli con up testeth5;
    clean;
}

[[ $1 == "run" ]] && run;
