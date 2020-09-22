#!/bin/bash
set +x

HOSTAPD_CFG="/etc/hostapd/wireless.conf"
EAP_USERS_FILE="/etc/hostapd/hostapd.eap_user"
HOSTAPD_KEYS_PATH="/etc/hostapd/ssl"
CLIENT_KEYS_PATH="/tmp/certs"

function start_dnsmasq ()
{
    echo "Start DHCP server (dnsmasq)"
    local dnsmasq="/usr/sbin/dnsmasq"
    local ip="ip"
    if $DO_NAMESPACE; then
        dnsmasq="ip netns exec wlan_ns $dnsmasq"
        ip="ip -n wlan_ns"
    fi

    # assign addreses to wlan1_* interfaces created by hostapd
    # wlan1 is already configured
    num=2
    for dev in $($ip l | grep -o 'wlan1_[^:]*'); do
      $ip add add 10.0.254.$((num++))/24 dev $dev
    done

    $dnsmasq\
    --pid-file=/tmp/dnsmasq_wireless.pid\
    --port=63\
    --conf-file\
    --no-hosts\
    --interface=wlan1*\
    --clear-on-reload\
    --strict-order\
    --listen-address=10.0.254.1\
    --dhcp-range=10.0.254.$((num)),10.0.254.100,60m\
    --dhcp-option=option:router,10.0.254.1\
    --dhcp-lease-max=50
}

function ver_gte() {
    test "$1" = "`echo -e "$1\n$2" | sort -V | tail -n1`"
}

function write_hostapd_cfg ()
{
    echo "# Hostapd configuration for 802.1x client testing

#open
interface=wlan1
bssid=$new_mac
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=open
hw_mode=g
channel=6
auth_algs=1
wpa=0
country_code=EN

#pskwep
bss=wlan1_pskwep
ssid=wep
channel=1
hw_mode=g
auth_algs=3
ignore_broadcast_ssid=0
wep_default_key=0
wep_key0=\"abcde\"
wep_key_len_broadcast=\"5\"
wep_key_len_unicast=\"5\"
wep_rekey_period=300

#pskwep_len13
bss=wlan1_13pskwep
ssid=wep-2
channel=1
hw_mode=g
auth_algs=3
ignore_broadcast_ssid=0
wep_default_key=0
wep_key0=\"testing123456\"
wep_key_len_broadcast=\"13\"
wep_key_len_unicast=\"13\"
wep_rekey_period=300

#dynwep
bss=wlan1_dynwep
ssid=dynwep
channel=1
hw_mode=g
auth_algs=3
ignore_broadcast_ssid=0
wep_default_key=0
wep_key0=\"abcde\"
wep_key_len_broadcast=5
wep_key_len_unicast=5
wep_rekey_period=300
ieee8021x=1
eapol_version=1
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat

#wpa2
bss=wlan1_wpa2eap
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
private_key_passwd=redhat

#wpa2_pskonly
bss=wlan1_wpa2psk
ssid=wpa2-psk
country_code=EN
hw_mode=g
channel=7
auth_algs=3
wpa=3
wpa_key_mgmt=WPA-PSK
wpa_passphrase=secret123

#wpa1eap
bss=wlan1_wpa1eap
ssid=wpa1-eap
country_code=EN
hw_mode=g
channel=7
auth_algs=3
wpa=1
ieee8021x=1
eapol_version=1
wpa_key_mgmt=WPA-EAP
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat

#wpa1_pskonly
bss=wlan1_wpa1psk
ssid=wpa1-psk
country_code=EN
hw_mode=g
channel=7
auth_algs=3
wpa=1
wpa_key_mgmt=WPA-PSK
wpa_passphrase=secret123
" > $HOSTAPD_CFG

# wpa3 requires wpa_suuplicant >= 2.9
wpa_ver=$(rpm -q wpa_supplicant)
wpa_ver=${wpa_ver#wpa_supplicant-}
if ver_gte $wpa_ver 2.9; then
echo "
#wpa3
bss=wlan1_wpa3
ssid=wpa3
country_code=EN
hw_mode=g
channel=7
auth_algs=3
wpa=2
wpa_key_mgmt=SAE
wpa_passphrase=secret123
" >> $HOSTAPD_CFG
fi

# Create a list of users for network authentication, authentication types, and corresponding credentials.
echo "# Create hostapd peap user file
# Phase 1 authentication
\"user\"   MD5     \"password\"
\"test\"   TLS,TTLS,PEAP
# this is for doc_procedures, not to require anonymous identity to be set
\"TESTERS\\test_mschapv2\"  TLS,TTLS,PEAP

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
    local hostapd="hostapd -ddd $HOSTAPD_CFG"
    if $DO_NAMESPACE; then
        hostapd="ip netns exec wlan_ns $hostapd"
    fi
    systemd-run --unit nm-hostapd $hostapd

    sleep 10
}

function wireless_hostapd_check ()
{
    need_setup=0
    echo "* Checking hostapd"
    if [ ! -e /tmp/nm_wifi_supp_configured ]; then
        echo "Not OK!!"
        need_setup=1
    fi
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
    echo "* Checking namespace"
    namespace=false
    if ip netns exec wlan_ns true; then
        namespace=true
    fi
    if [ $namespace != $DO_NAMESPACE ]; then
        echo "Not OK!!"
        need_setup=1
    fi
    if [ $need_setup -eq 1 ]; then
        rm -rf /tmp/nm_wifi_supp_configured
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

    if $DO_NAMESPACE; then
        local major_ver=$(cat /etc/redhat-release | grep -o "release [0-9]*" | sed 's/release //')
        local policy_file="tmp/selinux-policy/hostapd_wireless_$major_ver.pp"
        semodule -i $policy_file || echo "ERROR: unable to load selinux policy !!!"
        ip netns add wlan_ns
    fi

    # Disable mac randomization to avoid rhbz1490885
    echo -e "[device-wifi]\nwifi.scan-rand-mac-address=no" > /etc/NetworkManager/conf.d/99-wifi.conf
    echo -e "[connection-wifi]\nwifi.cloned-mac-address=preserve" >> /etc/NetworkManager/conf.d/99-wifi.conf
    echo -e "[keyfile]\nunmanaged-devices=interface-name:wlan1*" >> /etc/NetworkManager/conf.d/99-wifi.conf

    if ! lsmod | grep -q -w mac80211_hwsim; then
        modprobe mac80211_hwsim
        sleep 5
    fi
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

    # zero last two bits in wlan1 MAC address
    new_mac=$(ip link show dev wlan1 | grep -o 'link/ether [^ ]*' | sed 's/^.* //;s/:..$/:00/')
    ip link set dev wlan1 down
    ip link set dev wlan1 address "$new_mac"
    ip link set dev wlan1 up

    if $DO_NAMESPACE; then
        iw phy phy1 set netns name wlan_ns
        ip -n wlan_ns add add 10.0.254.1/24 dev wlan1
    else
        ip add add 10.0.254.1/24 dev wlan1
    fi
    sleep 5

}

function wireless_hostapd_setup ()
{
    set +x

    echo "Configuring hostapd 802.1x server..."

    rm -rf /tmp/wireless_hostapd_check.txt
    if  wireless_hostapd_check; then
        echo "OK. Configuration has already been done."
        touch /tmp/wireless_hostapd_check.txt
        return 0
    fi

    prepare_test_bed
    write_hostapd_cfg
    copy_certificates

    set -e

    # Start 802.1x authentication and built-in RADIUS server.
    # Start hostapd as a service via systemd-run using configuration wifi adapters
    start_nm_hostapd
    if ! systemctl -q is-active nm-hostapd; then
        echo "Error. Cannot start the service for hostapd." >&2
        return 1
    fi

    start_dnsmasq
    pid=$(cat /tmp/dnsmasq_wireless.pid)
    if ! pidof dnsmasq | grep -q $pid; then
        echo "Error. Cannot start dnsmasq as DHCP server." >&2
        return 1
    fi

    touch /tmp/nm_wifi_supp_configured
    # do not lower this as first test may fail then
    sleep 5
}

function wireless_hostapd_teardown ()
{
    set -x
    ip netns del wlan_ns
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
    rm -rf /tmp/nm_wifi_supp_configured

}

if [ "$1" != "teardown" ]; then
    # If hostapd's config fails then restore initial state.
    echo "Configure and start hostapd..."
    # Set DO_NAMESPACE to true if "namespace" in arguments
    DO_NAMESPACE=false
    if [[ " $@ " == *" namespace "* ]]; then
        DO_NAMESPACE=true
    fi

    CERTS_PATH=${1:?"Error. Path to certificates is not specified."}

    wireless_hostapd_setup $1; RC=$?
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
