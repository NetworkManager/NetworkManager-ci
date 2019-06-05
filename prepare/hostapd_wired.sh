#!/bin/bash

function hostapd_setup ()
{
    # Quit immediately on any script error
    set -e

    HOSTAPD_KEYS_PATH="/etc/hostapd/ssl"
    CLIENT_KEYS_PATH="/tmp/certs"
    HOSTAPD_CFG="/etc/hostapd/wired.conf"
    EAP_USERS_FILE="/etc/hostapd/hostapd.eap_user"
    CERTS_PATH=$1

    echo "Configuring hostapd 8021x server..."

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

    # Create a connection which (in cooperation with dnsmasq) provides DHCP functionlity
    nmcli connection add type ethernet con-name DHCP_test8Y ifname test8Y ip4 10.0.253.1/24
    sleep 1
    nmcli connection up id DHCP_test8Y

    # Note: Adding an interface to a bridge will cause the interface to lose its existing IP address.
    # If you're connected remotely via the interface you intend to add to the bridge,
    # you will lose your connection. That's why eth0 is never used in a bridge.
    # Allow 802.1x packets to be forwarded through the bridge

    # Enable forwarding of EAP 802.1x messages through software bridge "test8X_bridge".
    # Note: without this capability the testing scenario fails.
    echo 8 > /sys/class/net/test8X_bridge/bridge/group_fwd_mask

    # Create configuration for hostapd to be used with Ethernet adapters.
    echo "# Hostapd configuration for 802.1x client testing
interface=test8Y
driver=wired
logger_stdout=-1
logger_stdout_level=1
debug=2
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

# Include these lines when the environment is prepared for EAP-FAST authentication.
# Configuration for EAP-FAST authentication
# pac_opaque_encr_key=e350ddd67135c2029ad25ce0d2886c4e
# eap_fast_a_id=c035cfc65e00352b84a64ea738bfa9af
# eap_fast_a_id_info=testsvr
# eap_fast_prov=3
# pac_key_lifetime=604800
# pac_key_refresh_time=86400

    # Copy certificates to correct places
    [ -d $HOSTAPD_KEYS_PATH ] || mkdir -p $HOSTAPD_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/server/hostapd* $HOSTAPD_KEYS_PATH

    [ -d $CLIENT_KEYS_PATH ] || mkdir -p $CLIENT_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/client/test_user.* $CLIENT_KEYS_PATH

    /bin/cp -rf $CERTS_PATH/client/test_user.ca.pem /etc/pki/ca-trust/source/anchors
    chown -R test:test $CLIENT_KEYS_PATH
    update-ca-trust extract


    # Create a list of users for network authentication, authentication types, and corresponding credentials.
    echo "# Create hostapd peap user file
# Phase 1 authentication
\"user\"   MD5     \"password\"
\"test\"   TLS,TTLS,PEAP
# Phase 2 authentication (tunnelled within EAP-PEAP or EAP-TTLS)
\"TESTERS\\test_mschapv2\"   MSCHAPV2    \"password\"  [2]
\"test_md5\"       MD5         \"password\"  [2]
\"test_gtc\"       GTC         \"password\"  [2]
# Tunneled TLS and non-EAP authentication inside the tunnel.
\"test_ttls\"      TTLS-PAP,TTLS-CHAP,TTLS-MSCHAP,TTLS-MSCHAPV2    \"password\"  [2]" > $EAP_USERS_FILE

    sleep 2

    echo "Start DHCP server (dnsmasq)"
    /usr/sbin/dnsmasq\
    --pid-file=/tmp/dnsmasq_wired.pid\
    --conf-file\
    --no-hosts\
    --bind-interfaces\
    --except-interface=lo\
    --clear-on-reload\
    --strict-order\
    --listen-address=10.0.253.1\
    --dhcp-range=10.0.253.10,10.0.253.200,10m\
    --dhcp-option=option:router,10.0.253.1\
    --dhcp-lease-max=190

    # Start 802.1x authentication and built-in RADIUS server.
    # Start hostapd on the background using configuration for Ethernet adapters.
    hostapd -P /tmp/hostapd.pid -B $HOSTAPD_CFG &
    sleep 5
}
function hostapd_teardown ()
{
    kill $(cat /tmp/dnsmasq_wired.pid)
    kill $(cat /tmp/hostapd.pid)
    ip link del test8Yp
    ip link del test8Xp
    ip link del test8X_bridge
    nmcli con del DHCP_test8Y
}

if [ "$1" != "teardown" ]; then
    hostapd_setup $1
else
    hostapd_teardown
fi

# Test network authentication via IEEE 802.1x by using hostapd and dnsmasq.
# Various authentication methods are tested, such as:
# MD5, TLS, Tunneled TLS, PEAP
# For one part of the tests username and password is enough.
# For another part, CA certificate, server certificate, and client certificate are required.
# Two pairs of Veth interfaces are created. Both are linked to a network bridge between the pairs.
# This is used to test network authentication on a single host.
# The authentication works on layer 2 of the OSI networking model.
# EAP messages are exchanged, and therefore the bridge is made to forward them.
# The network authenticator is hostapd. It implements IEEE 802.11 access point management,
# IEEE 802.1X/WPA/WPA2/EAP authenticators and RADIUS authentication server.
# For more info, see:
#   yum info hostapd
#   https://wiki.gentoo.org/wiki/Hostapd
#   https://wiki.gentoo.org/wiki/Hostapd#Capabilities_of_Hostapd
#
# See details on configuration:
#   http://w1.fi/hostapd/
#   http://w1.fi/cgit/hostap/plain/hostapd/hostapd.conf
#   Check the section: "IEEE 802.1X-2004 related configuration"
#
# For PEAP and TTLS configuration, see:
#   http://w1.fi/cgit/hostap/tree/hostapd/hostapd.eap_user
#
# To have communication, IP addresses must be available.
# In our case this is achieved by using dnsmasq.
# dnsmasq provides services as a DNS cacher and a DHCP server.
# For more info, see: https://wiki.archlinux.org/index.php/dnsmasq
