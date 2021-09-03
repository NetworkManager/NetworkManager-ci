#!/bin/bash
set +x

HOSTAPD_CFG="/etc/hostapd/wired.conf"
EAP_USERS_FILE="/etc/hostapd/hostapd.eap_user"
HOSTAPD_KEYS_PATH="/etc/hostapd/ssl"
CLIENT_KEYS_PATH="/tmp/certs"

function start_dnsmasq ()
{
    echo "Start DHCP server (dnsmasq)"
    local dnsmasq="/usr/sbin/dnsmasq"

    echo "Start auth DHCP server (dnsmasq)"
    $dnsmasq\
    --pid-file=/tmp/dnsmasq_wired.pid\
    --conf-file\
    --no-hosts\
    --bind-interfaces\
    --except-interface=lo\
    --interface=test8Y\
    --clear-on-reload\
    --strict-order\
    --listen-address=10.0.253.1\
    --dhcp-range=10.0.253.10,10.0.253.200,10m\
    --dhcp-option=option:router,10.0.253.1\
    --dhcp-leasefile=/var/lib/dnsmasq/hostapd.leases \
    --dhcp-lease-max=190

    echo "Start noauth DHCP server (dnsmasq)"
    $dnsmasq\
    --pid-file=/tmp/dnsmasq_wired_noauth.pid\
    --conf-file\
    --no-hosts\
    --bind-interfaces\
    --except-interface=lo\
    --interface=test8Z\
    --clear-on-reload\
    --strict-order\
    --listen-address=10.0.254.1\
    --dhcp-range=10.0.254.10,10.0.254.200,2m\
    --dhcp-option=option:router,10.0.254.1\
    --dhcp-leasefile=/var/lib/dnsmasq/hostapd.leases \
    --dhcp-lease-max=190
}

function write_hostapd_cfg ()
{
    echo "# Hostapd configuration for 802.1x client testing
interface=test8Y
driver=wired
ieee8021x=1
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat" > $HOSTAPD_CFG

# Create a list of users for network authentication, authentication types, and corresponding credentials.
echo "# Create hostapd peap user file
# Phase 1 authentication
\"user\"   MD5     \"password\"
\"test\"   TLS,TTLS,PEAP
# this is for doc_procedures, not to require anonymous identity to be set
\"TESTERS\\test_mschapv2\"   TLS,TTLS,PEAP

# Phase 2 authentication (tunnelled within EAP-PEAP or EAP-TTLS)
\"TESTERS\\test_mschapv2\"   MSCHAPV2    \"password\"  [2]
\"test_md5\"       MD5         \"password\"  [2]
\"test_gtc\"       GTC         \"password\"  [2]
# Tunneled TLS and non-EAP authentication inside the tunnel.
\"test_ttls\"      TTLS-PAP,TTLS-CHAP,TTLS-MSCHAP,TTLS-MSCHAPV2    \"password\"  [2]" > $EAP_USERS_FILE

}

function copy_certificates ()
{
    # Copy certificates to correct places
    [ -d $HOSTAPD_KEYS_PATH ] || mkdir -p $HOSTAPD_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/server/hostapd* $HOSTAPD_KEYS_PATH

    [ -d $CLIENT_KEYS_PATH ] || mkdir -p $CLIENT_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/client/test_user.* $CLIENT_KEYS_PATH

    /bin/cp -rf $CERTS_PATH/client/test_user.ca.pem /etc/pki/ca-trust/source/anchors
    chown -R test:test $CLIENT_KEYS_PATH
    update-ca-trust extract
}

function release_between () {
    rel_min="release $1"
    rel_max="release $2"
    rel="$(grep -o 'release [0-9.]*' /etc/redhat-release)"
    vers="$(echo -e "$rel_min\n$rel_max\n$rel" | sort -V)"
    [ "$rel_min" == "$(echo "$vers" | head -n1)" ] || return 1
    [ "$rel_max" == "$(echo "$vers" | tail -n1)" ] || return 1
    return 0
}

function start_nm_hostapd ()
{

    if grep -q 'Stream release 8' /etc/redhat-release || release_between 8.4 8.999; then
        local policy_file="contrib/selinux-policy/hostapd_wired_8.pp"
        if ! [ -f "/tmp/hostapd_wired_selinux" ] ; then
            touch "/tmp/hostapd_wired_selinux"
            semodule -i $policy_file || echo "ERROR: unable to load selinux policy !!!"
        fi
    fi
    if release_between 9.0 9.999; then
        local policy_file="contrib/selinux-policy/hostapd_wired_9.pp"
        if ! [ -f "/tmp/hostapd_wired_selinux" ] ; then
            touch "/tmp/hostapd_wired_selinux"
            semodule -i $policy_file || echo "ERROR: unable to load selinux policy !!!"
        fi
    fi

    local hostapd="hostapd -ddd $HOSTAPD_CFG"
    systemd-run --unit nm-hostapd $hostapd
    sleep 5
}

function wired_hostapd_check ()
{
    need_setup=0
    echo "* Checking hostapd"
    if [ ! -e /tmp/nm_8021x_configured ]; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking auth dnsmasqs"
    pid=$(cat /tmp/dnsmasq_wired.pid)
    if ! pidof dnsmasq |grep -q $pid; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking noauth dnsmasqs"
    pid=$(cat /tmp/dnsmasq_wired_noauth.pid)
    if ! pidof dnsmasq |grep -q $pid; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking hostapd-wired"
    #pid=$(cat /tmp/hostapd_wired.pid)
    if ! systemctl is-active nm-hostapd; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking test8Y"
    if ! nmcli device show test8Y | grep -qw connected; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking test8Z"
    if ! nmcli device show test8Z | grep -qw connected; then
        echo "Not OK!!"
        need_setup=1
    fi
    if [ $need_setup -eq 1 ]; then
        rm -rf /tmp/nm_8021x_configured
        wired_hostapd_teardown
        return 1
    fi

    return 0
}

function prepare_test_bed ()
{
    # Create 2 Veth interface pairs and a bridge between their peers.
    ip link add test8Y type veth peer name test8Yp
    ip link add test8X type veth peer name test8Xp
    ip link add name test8X_bridge type bridge
    ip link set dev test8X_bridge up
    ip link set test8Xp master test8X_bridge
    ip link set test8Yp master test8X_bridge
    # Up everything
    ip link set dev test8X up
    ip link set dev test8Xp up
    ip link set dev test8Y up
    ip link set dev test8Yp up
    # Create additional default down non protected network
    ip link add test8Z type veth peer name test8Zp
    ip link set test8Zp master test8X_bridge
    ip link set dev test8Z up

    # Create a connections which (in cooperation with dnsmasq) provide DHCP functionlity
    # Auth one
    nmcli connection add type ethernet con-name DHCP_test8Y ifname test8Y ip4 10.0.253.1/24
    sleep 1
    nmcli connection up id DHCP_test8Y

    # Non auth one
    nmcli connection add type ethernet con-name DHCP_test8Z ifname test8Z ip4 10.0.254.1/24
    sleep 1
    nmcli connection up id DHCP_test8Z

    # Note: Adding an interface to a bridge will cause the interface to lose its existing IP address.
    # If you're connected remotely via the interface you intend to add to the bridge,
    # you will lose your connection. That's why eth0 is never used in a bridge.
    # Allow 802.1x packets to be forwarded through the bridge

    # Enable forwarding of EAP 802.1x messages through software bridge "test8X_bridge".
    # Note: without this capability the testing scenario fails.
    echo 8 > /sys/class/net/test8X_bridge/bridge/group_fwd_mask

}

function wired_hostapd_setup ()
{
    set +x

    echo "Configuring hostapd 802.1x server..."

    if  wired_hostapd_check; then
        echo "OK. Configuration has already been done."
        return 0
    fi

    prepare_test_bed
    write_hostapd_cfg
    copy_certificates

    set -e

    # Start 802.1x authentication and built-in RADIUS server.
    # Start hostapd as a service via systemd-run using 802.1x configuration
    start_dnsmasq
    start_nm_hostapd

    pid=$(cat /tmp/dnsmasq_wired.pid)
    if ! pidof dnsmasq | grep -q $pid; then
        echo "Error. Cannot start auth dnsmasq as DHCP server." >&2
        return 1
    fi

    pid=$(cat /tmp/dnsmasq_wired_noauth.pid)
    if ! pidof dnsmasq | grep -q $pid; then
        echo "Error. Cannot start noauth dnsmasq as DHCP server." >&2
        return 1
    fi

    #pid=$(cat /tmp/hostapd_wired.pid)
    if ! systemctl is-active nm-hostapd; then
        echo "Error. Cannot start hostapd." >&2
        return 1
    fi

    touch /tmp/nm_8021x_configured
}

function wired_hostapd_teardown ()
{
    set -x
    if systemctl --quiet is-failed nm-hostapd; then
        systemctl reset-failed nm-hostapd
    fi
    systemctl stop nm-hostapd
    kill $(cat /tmp/dnsmasq_wired.pid)
    kill $(cat /tmp/dnsmasq_wired_noauth.pid)
    #kill $(cat /tmp/hostapd_wired.pid)
    ip netns del 8021x_ns
    ip link del test8Yp
    ip link del test8Xp
    ip link del test8Zp
    ip link del test8X_bridge
    nmcli con del DHCP_test8Y DHCP_test8Z test8X_bridge
    rm -rf /tmp/nm_8021x_configured

}

if [ "$1" != "teardown" ]; then
    # If hostapd's config fails then restore initial state.
    echo "Configure and start hostapd..."

    CERTS_PATH=${1:?"Error. Path to certificates is not specified."}

    wired_hostapd_setup $1; RC=$?
    if [ $RC -eq 0 ]; then
        echo "hostapd started successfully."
    else
        echo "Error. Failed to start hostapd." >&2
        exit 1
    fi
else
    wired_hostapd_teardown
    echo "System's state returned prior to hostapd's config."
fi
