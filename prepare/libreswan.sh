#!/bin/bash
set +x

LIBRESWAN_DIR="/opt/ipsec"


# Allow only users with root priviledge to run the script.
if [ $EUID -ne 0 ]; then
    echo "This script can be run with root priviledge only." >&2
    exit 1
fi

# Check for the correct # of arguments - TODO

is_pluto_running ()
{
    [ -f "$LIBRESWAN_DIR/pluto.pid" ] && \
    kill -0 $(cat "$LIBRESWAN_DIR/pluto.pid")
}

start_pluto ()
{
    is_pluto_running || \
    ip netns exec libreswan ipsec pluto \
              --secretsfile "$SECRETS_CFG" \
              --ipsecdir "$LIBRESWAN_DIR" \
              --nssdir "$NSS_DIR" \
              --rundir "$LIBRESWAN_DIR"
}

add_pluto_connection ()
{
    ipsec addconn --addall --config "$CONNECTION_CFG" --ctlsocket "$LIBRESWAN_DIR/pluto.ctl"
}

libreswan_gen_connection ()
{
    cat > "$CONNECTION_CFG" << EOF
conn roadwarrior_psk
    auto=add
    pfs=no
    rekey=no
    left=11.12.13.14
    leftsubnet=0.0.0.0/0
    rightaddresspool=172.29.100.2-172.29.100.10
    right=%any
    leftxauthserver=yes
    rightxauthclient=yes
    leftmodecfgserver=yes
    rightmodecfgclient=yes
    modecfgpull=yes
    modecfgdns1=8.8.8.8
    modecfgbanner=BUG_REPORT_URL
    ike-frag=yes
    cisco-unity=yes
    ikev2=$IKEv2
EOF
    if [ "$IKEv2" = "insist" ]; then
        cat >> "$CONNECTION_CFG" << EOF
    leftcert=LibreswanServer
    leftsendcert=always
    leftid=11.12.13.14
    leftrsasigkey=%cert
    rightca=%same
    rightid=%fromcert
    rightrsasigkey=%cert
EOF
    else
        cat >> "$CONNECTION_CFG" << EOF
    authby=secret
    xauthby=$AUTH
EOF
    fi
    if [ "$MODE" = "aggressive" ]; then
        cat >> "$CONNECTION_CFG" << EOF
    rightid=@yolo
    aggressive=yes
EOF
    fi
}

libreswan_gen_secrets ()
{
    echo ": PSK \"ipsecret\"" > "$SECRETS_CFG"
    chmod 600 "$SECRETS_CFG"

    echo 'budulinek:$2y$05$blZd./TWeA4mYn3cxL/JJOjHEbIectXvnMXbUCEZ5U6GUtsQ0b5Ke:roadwarrior_psk' > "$PASSWD_FILE"
}

import_certificates ()
{
    echo "import server certificates into libreswan namespace NSS (if not exist yet)..."
    ipsec checknss --nssdir "$NSS_DIR"
    # ipsec import command asks for pkcs12 password, so importing manually
    pk12util -W "" -i tmp/libreswan/server/libreswan_server.p12 -d sql:$NSS_DIR
    certutil -M -n RedHat -t "CT,," -d sql:$NSS_DIR

    echo "import client certificates into default NSS (if not exist yet)..."
    ipsec checknss --nssdir "$NSS_CLIENT_DIR"
    # ipsec import command asks for pkcs12 password, so importing manually
    pk12util -W "" -i tmp/libreswan/client/libreswan_client.p12 -d sql:$NSS_CLIENT_DIR
    certutil -M -n RedHat -t "CT,," -d sql:$NSS_CLIENT_DIR
}

libreswan_check_netconfig ()
{
    echo " * check namespace..."
    ip netns list | grep -q libreswan || return 1
    echo "   OK"
    echo " * check libreswan1 iface..."
    ip a show dev libreswan1 | grep -q 11.12.13.15/24 || return 1
    echo "   OK"
    echo " * check libreswan0 iface..."
    ip -n libreswan a show dev libreswan0 | grep -q 11.12.13.14/24 || return 1
    echo "   OK"
    echo " * check default route..."
    ip r show | head -n1 | grep -q 'default via 11.12.13.14' || return 1
    echo "   OK"
    echo " * check lib1 connection..."
    nmcli -f NAME c show --active | grep -q 'lib1' || return 1
    echo "   OK"
    return 0
}

libreswan_gen_netconfig ()
{
    if libreswan_check_netconfig; then
        return
    else
        echo "   FAIL"
        echo " * doing libreswan_teardown"
        set +e
        libreswan_teardown
        set -e
    fi
    echo " * configuring network..."

    ip netns add libreswan

    # IPv6 on a veth confuses pluto. Sigh. (TODO: check id still true)
    # ERROR: bind() for 80/80 fe80::94bf:8cff:fe1b:7620:500 in process_raw_ifaces(). Errno 22: Invalid argument
    echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    ip netns exec libreswan echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    ip link add libreswan0 type veth peer name libreswan1
    ip link set libreswan0 netns libreswan

    ip netns exec libreswan ip link set lo up
    ip netns exec libreswan ip addr add dev libreswan0 11.12.13.14/24
    ip netns exec libreswan ip link set libreswan0 up
    ip link set dev libreswan1 up

    ### add default route connection that takes precedence over the system one
    # dns-priority should be less than 100 but more that 50 (default for VPN connection)
    nmcli connection add \
        type ethernet con-name lib1 ifname libreswan1 autoconnect no ipv6.method ignore \
        ipv4.route-metric 90 ipv4.method static ipv4.addresses 11.12.13.15/24 \
        ipv4.gateway 11.12.13.14 ipv4.dns 11.12.13.14 ipv4.route-metric 90
    nmcli dev set libreswan1 managed yes

    # Warning: the next command interrupts any established SSH connection to the remote machine!
    nmcli connection up id lib1
    echo "   OK"
}

####

libreswan_setup ()
{
    # Quit immediatelly on any script error
    set -e
    CONNECTION_CFG="$LIBRESWAN_DIR/connection.conf"
    SECRETS_CFG="$LIBRESWAN_DIR/ipsec.secrets"
    PASSWD_FILE="$LIBRESWAN_DIR/passwd"
    NSS_DIR="$LIBRESWAN_DIR/nss"
    # this is NSS database for client (used by pluto started by NM in main namespace)
    NSS_CLIENT_DIR="/etc/ipsec.d/"
    if [ "$MODE" = "ikev2" ]; then
        IKEv2="insist"
    else
        IKEv2="never"
    fi

    echo "Configuring remote Libreswan peer"
    [ -d "$LIBRESWAN_DIR" ] || mkdir "$LIBRESWAN_DIR"
    [ -d "$NSS_DIR" ] || mkdir "$NSS_DIR"

    # password authentication does not work on RHEL7 for some reason
    if grep -qi "release 7" /etc/redhat-release; then
        AUTH="alwaysok"
    else
        AUTH="file"
    fi

    libreswan_gen_secrets
    libreswan_gen_connection
    libreswan_gen_netconfig

    set +e

    modprobe af_key

    set -e

    import_certificates

    start_pluto
    add_pluto_connection
}

libreswan_teardown ()
{
    [ -f "$LIBRESWAN_DIR/pluto.pid" ] && kill $(cat "$LIBRESWAN_DIR/pluto.pid")
    echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    ip netns list | grep -q libreswan && ip netns del libreswan
    ip link | grep -q libreswan1 && ip link del libreswan1
    nmcli -f NAME c show | grep -q 'lib1' && nmcli connection del lib1
    modprobe -r ip_vti
}

if [ "$1" != "teardown" ]; then
    test -z "$MODE" && { echo "MODE not set"; exit 1; }
    libreswan_setup
else
    libreswan_teardown
fi
