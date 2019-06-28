#!/bin/bash
set +x

HOSTAPD_CFG="/etc/hostapd/wireless.conf"
EAP_USERS_FILE="/etc/hostapd/hostapd.eap_user"
HOSTAPD_KEYS_PATH="/etc/hostapd/ssl"
CLIENT_KEYS_PATH="/tmp/certs"

function start_dnsmasq ()
{
    echo "Start DHCP server (dnsmasq)"
    /usr/sbin/dnsmasq\
    --pid-file=/tmp/dnsmasq_wireless.pid\
    --port=63\
    --conf-file\
    --no-hosts\
    --interface=wlan1\
    --clear-on-reload\
    --strict-order\
    --listen-address=10.0.254.1\
    --dhcp-range=10.0.254.10,10.0.254.100,60m\
    --dhcp-option=option:router,10.0.254.1\
    --dhcp-lease-max=50

}

function write_hostapd_cfg_wpa2 ()
{
    echo "# Hostapd configuration for 802.1x client testing
interface=wlan1
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=wpa2-eap
country_code=EN
hw_mode=g
channel=7
auth_algs=3
wpa=3
ieee8021x=1
eapol_version=1
wpa_key_mgmt=WPA-EAP WPA-PSK
wpa_passphrase=secret123
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat" > $1

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
\"test_ttls\"      TTLS-PAP,TTLS-CHAP,TTLS-MSCHAP,TTLS-MSCHAPV2    \"password\"  [2]" > $2
}

function write_hostapd_cfg_open ()
{
    echo "# Hostapd configuration for 802.1x client testing
interface=wlan1
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=open
hw_mode=g
channel=6
auth_algs=1
wpa=0
country_code=EN" > $1
}

function copy_certificates ()
{
    CERTS_PATH=$1

    # Copy certificates to correct places
    [ -d $HOSTAPD_KEYS_PATH ] || mkdir -p $HOSTAPD_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/server/hostapd* $HOSTAPD_KEYS_PATH

    [ -d $CLIENT_KEYS_PATH ] || mkdir -p $CLIENT_KEYS_PATH
    /bin/cp -rf $CERTS_PATH/client/test_user.*.pem $CLIENT_KEYS_PATH

    /bin/cp -rf $CERTS_PATH/client/test_user.ca.pem /etc/pki/ca-trust/source/anchors
    chown -R test:test $CLIENT_KEYS_PATH
    update-ca-trust extract
}

function restart_services ()
{
    systemctl daemon-reload
    systemctl restart NetworkManager
    systemctl restart wpa_supplicant
}

function start_nm_hostapd ()
{
    systemd-run --unit nm-hostapd hostapd -ddd $HOSTAPD_CFG
    sleep 10
}

function wireless_hostapd_check ()
{
    need_setup=0

    # Check running dnsmasq
    echo "* Checking dnsmasqs"
    pid=$(cat /tmp/dnsmasq_wireless.pid)
    if ! pidof dnsmasq |grep -q $pid; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking nm-hostapd"
    if ! systemctl is-active nm-hostapd -q; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking wlan0"
    if ! nmcli device show wlan0 |grep -q connected; then
        echo "Not OK!!"
        need_setup=1
    fi
    if [ $need_setup -eq 1 ]; then
        rm -rf /tmp/nm_wpa_supp_configured
        # Teardown just in case something went wrong
        wireless_hostapd_teardown
        return 1
    fi

    return 0
}
function prepare_test_bed ()
{
    # Install haveged to increase entropy
    yum -y install haveged
    systemctl restart haveged

    # Disable mac randomization to avoid rhbz1490885
    echo -e "[device-wifi]\nwifi.scan-rand-mac-address=no" > /etc/NetworkManager/conf.d/99-wifi.conf
    echo -e "[connection-wifi]\nwifi.cloned-mac-address=preserve" >> /etc/NetworkManager/conf.d/99-wifi.conf

    modprobe mac80211_hwsim
    sleep 5
    if ! lsmod | grep -q -w mac80211_hwsim; then
        echo "Error. Cannot load module \"mac80211_hwsim\"." >&2
        return 1
    fi

    restart_services
    sleep 5
    if ! systemctl -q is-active wpa_supplicant; then
        echo "Error. Cannot start the service for WPA supplicant." >&2
        return 1
    fi

    nmcli device set wlan1 managed off
    ip add add 10.0.254.1/24 dev wlan1
    sleep 5

}

function wireless_hostapd_setup ()
{
    local CERTS_PATH=${1:?"Error. Path to certificates is not specified."}
    local AUTH_TYPE=${2:?"Error. Authentication type is not specified."}

    set +x

    #VV FIXME: this has to be checking auth version too
    echo "Configuring hostapd 802.1x server..."
    if  wireless_hostapd_check; then
        echo "OK. Configuration has already been done."
        return 0
    fi
    #^^ FIXME


    if [ "$AUTH_TYPE" == "open" ]; then
        echo "Auth type is Open"
        prepare_test_bed
        write_hostapd_cfg_open $HOSTAPD_CFG
        set -e
        start_dnsmasq
        pid=$(cat /tmp/dnsmasq_wireless.pid)
        if ! pidof dnsmasq | grep -q $pid; then
            echo "Error. Cannot start dnsmasq as DHCP server." >&2
            return 1
        fi

        # Start 802.1x authentication and built-in RADIUS server.
        # Start hostapd as a service via systemd-run using configuration wifi adapters
        start_nm_hostapd
        if ! systemctl -q is-active nm-hostapd; then
            echo "Error. Cannot start the service for hostapd." >&2
            return 1
        fi

        touch /tmp/nm_open_supp_configured
        # do not lower this as first test may fail then
        sleep 5

    elif [ "$AUTH_TYPE" == "wpa2" ]; then
        echo "Auth type is WPA"
        prepare_test_bed
        write_hostapd_cfg_wpa2 $HOSTAPD_CFG $EAP_USERS_FILE
        copy_certificates $CERTS_PATH

        set -e
        start_dnsmasq
        pid=$(cat /tmp/dnsmasq_wireless.pid)
        if ! pidof dnsmasq | grep -q $pid; then
            echo "Error. Cannot start dnsmasq as DHCP server." >&2
            return 1
        fi

        # Start 802.1x authentication and built-in RADIUS server.
        # Start hostapd as a service via systemd-run using configuration wifi adapters
        start_nm_hostapd
        if ! systemctl -q is-active nm-hostapd; then
            echo "Error. Cannot start the service for hostapd." >&2
            return 1
        fi

        touch /tmp/nm_wpa_supp_configured
        # do not lower this as first test may fail then
        sleep 5

    else
        echo "Unsupported authentication type: $AUTH_TYPE." >&2
        return 1
    fi
}

function wireless_hostapd_teardown ()
{
    set -x
    kill $(cat /tmp/dnsmasq_wireless.pid)
    if systemctl --quiet is-failed nm-hostapd; then
        systemctl reset-failed nm-hostapd
    fi
    systemctl stop nm-hostapd
    nmcli device set wlan1 managed on
    ip addr flush dev wlan1
    modprobe -r mac80211_hwsim
    [ -f /run/hostapd/wlan1 ] && rm -rf /run/hostapd/wlan1
    rm -rf /etc/NetworkManager/conf.d/99-wifi.conf
    systemctl reload NetworkManager
    rm -rf /tmp/nm_*_supp_configured

}

if [ "$1" != "teardown" ]; then
    # If hostapd's config fails then restore initial state.
    echo "Configure and start hostapd..."
    wireless_hostapd_setup $1 $2; RC=$?
    if [ $RC -eq 0 ]; then
        echo "hostapd started successfully."
    else
        echo "Error. Failed to start hostapd." >&2
        exit 1
    fi
else
    wireless_hostapd_teardown
    echo "System's state returned prior to hostapd's config."
fi
