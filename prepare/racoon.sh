#!/bin/bash

# Allow only users with root priviledge to run the script.
if [ $EUID -ne 0 ]; then
    echo "This script can be run with root priviledge only." >&2
    exit 1
fi

# Check for the correct # of arguments:
USAGE_INFO="Usage: $0 mode dh_group phase1_algorithm | teardown"

if [ $# -lt 3 ] && [ "$1" != 'teardown' ]; then
    echo "Error. Not enough arguments (3 required)." >&2
    echo "$USAGE_INFO" >&2
    exit 1
elif [ $# -gt 3 ]; then
    echo "Error. Too many arguments (3 required).\n" >&2
    echo "$USAGE_INFO" >&2
    exit 1
else
    echo "Starting racoon.sh..."
fi


function racoon_setup ()
{
    # Quit immediatelly on any script error
    set -e
    MODE=$1
    DH_GROUP=$2
    PHASE1_AL=$3
    RACOON_DIR="/etc/racoon"
    RACOON_CFG="$RACOON_DIR/racoon.conf"
    echo "Configuring VPN server Racoon..."
    [ -d $RACOON_DIR ] || mkdir $RACOON_DIR
    [ -f $RACOON_CFG ] || touch $RACOON_CFG

    echo "# Racoon configuration for Libreswan client testing
    path include \"$RACOON_DIR\";
    path pre_shared_key \"$RACOON_DIR/psk.txt\";
    path certificate \"$RACOON_DIR/certs\";
    path script \"$RACOON_DIR/scripts\";

    sainfo anonymous {
            encryption_algorithm aes;
            authentication_algorithm hmac_sha1;
            compression_algorithm deflate;
    }

    remote anonymous {
            exchange_mode $MODE;
            proposal_check obey;
            mode_cfg on;

            generate_policy on;
            dpd_delay 20;
            nat_traversal force;
            proposal {
                    encryption_algorithm $PHASE1_AL;
                    hash_algorithm sha1;
                    authentication_method xauth_psk_server;
                    dh_group $DH_GROUP;

            }
    }

    mode_cfg {
            auth_source system;
            network4 172.31.60.2;
            netmask4 255.255.255.0;
            pool_size 40;
            dns4 8.8.8.8;
            default_domain \"trolofon\";
            split_network include 172.31.80.0/24;
            banner \"/etc/os-release\";
    }" > $RACOON_CFG

    echo 'Modify the file with preshared keys.'
    # Pre-Shared Keys (PSK) is the simplest authentication method. PSK's should consist of
    # random characters and have a length of at least 20 characters. Due to the dangers of
    # non-random and short PSKs, this method is not available when the system is running in
    # FIPS mode.
    echo "172.31.70.2 ipsecret" > $RACOON_DIR/psk.txt
    for i in {3..41}; do
        echo "172.31.70.$i ipsecret" >> $RACOON_DIR/psk.txt
    done

    if getent passwd budulinek > /dev/null; then
        userdel -r budulinek
    fi

    # Add user budulinek with encrypted password
    useradd -s /sbin/nologin -p yO9FLHPGuPUfg budulinek

    # Create a network namespace allowing the VPN client and the VPN serve to run in the
    # isolated areas on the same machine.
    ip netns add racoon

    # IPv6 on a veth confuses pluto. Sigh.
    # ERROR: bind() for 80/80 fe80::94bf:8cff:fe1b:7620:500 in process_raw_ifaces(). Errno 22: Invalid argument
    echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    ip netns exec racoon echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    ip link add racoon0 type veth peer name racoon1

    ip link set racoon0 netns racoon

    ip netns exec racoon ip link set lo up
    ip netns exec racoon ip addr add dev racoon0 172.31.70.1/24
    ip netns exec racoon ip link set racoon0 up
    ip link set dev racoon1 up

    ip netns exec racoon dnsmasq --dhcp-range=172.31.70.2,172.31.70.40,2m --interface=racoon0 --bind-interfaces
    sleep 5
    echo 'PID of dnsmasq:'
    pidof dnsmasq

    nmcli connection add type ethernet con-name rac1 ifname racoon1 autoconnect no
    sleep 1
    nmcli connection modify rac1 ipv6.method ignore ipv4.route-metric 90
    sleep 1
    # Warning: the next command interrupts any established SSH connection to the remote machine!
    nmcli connection up id rac1
    sleep 1

    # Sometime there is larger time needed to set everything up, sometimes not. Let's make the delay
    # to fit all situations.
    SECONDS=20
    while [ $SECONDS -ge 0 ]; do
        if ! ip -4 address show racoon1 | grep -q '172.31.70'; then
            sleep 1
            ((SECONDS--))
            if [ $SECONDS -eq 0 ]; then
                false
            fi
        else
            break
        fi
    done

    set +e
    # For some reason the peer needs to initiate the arp otherwise it won't respond
    # and we'll end up in a stale entry in a neighbor cache
    IP=$(ip -o -4 addr show primary dev racoon1 |awk '{print $4}' |awk -F '/' '{print $1}')
    ip netns exec racoon ping -c1 $IP

    ping -c1 172.31.70.1

    systemd-run --unit nm-racoon nsenter --net=/var/run/netns/racoon racoon -F

    # Initialize NSS database for ipsec. See solution in bug description 1308325, 1365454.
    ipsec initnss
    sleep 5
}

function racoon_teardown ()
{
    echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    kill -INT $(ps aux|grep dns|grep racoon|grep -v grep |awk {'print $2'})
    if systemctl --quiet is-active nm-racoon; then
        systemctl stop nm-racoon
        systemctl reset-failed nm-racoon
    fi
    ip netns del racoon
    ip link del racoon1
    nmcli connection del rac1
    modprobe -r ip_vti
}

if [ "$1" != "teardown" ]; then
    racoon_setup $1 $2 $3
else
    racoon_teardown
fi
