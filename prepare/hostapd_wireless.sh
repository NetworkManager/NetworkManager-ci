#!/bin/bash
set +x

HOSTAPD_CFG="/etc/hostapd/wireless.conf"
EAP_USERS_FILE="/etc/hostapd/hostapd.eap_user"
HOSTAPD_KEYS_PATH="/etc/hostapd/ssl"
CLIENT_KEYS_PATH="/tmp/certs"

function get_phy() {
    ifname=$1
    phynum=$(iw dev $ifname info | grep "wiphy [0-9]\+" | awk '{print $2}')
    echo "phy$phynum"
}

function get_mac() {
    ifname=$1
    ip="ip "
    if $DO_NAMESPACE; then
      ip="ip -n wlan_ns "
    fi
    $ip link show $ifname | sed -n 's/.*link.ether \(\([0-9a-f][0-9a-f]:\?\)*\).*/\1/p'
}

function start_dnsmasq ()
{
    echo "Start DHCP server (dnsmasq)"
    local dnsmasq="/usr/sbin/dnsmasq"
    if $DO_NAMESPACE; then
        dnsmasq="ip netns exec wlan_ns $dnsmasq"
    fi

    $dnsmasq\
    --pid-file=/tmp/dnsmasq_wireless.pid\
    --port=63\
    --no-hosts\
    --interface=wlan*\
    --except-interface=wlan0\
    --dhcp-range=10.0.254.150,10.0.254.205,60m\
    --dhcp-option=option:router,10.0.254.1\
    --dhcp-leasefile=/var/lib/dnsmasq/hostapd.leases\
    --dhcp-lease-max=50
}

function ver_gte() {
    test "$1" = "`echo -e "$1\n$2" | sort -V | tail -n1`"
}

function hostapd_conf_header() {
  echo "interface=wlan$num_ap
driver=nl80211
ctrl_interface=/var/run/hostapd$num_ap
ctrl_interface_group=0
hw_mode=g
channel=1
country_code=EN
logger_syslog=0
# keep loglevel 3 (WARNING), when launched with -dd it subtratcs to 1 (DEBUG)
logger_syslog_level=3
logger_stdout=-1
logger_stdout_level=3
"
}

function write_hostapd_cfg ()
{
    rm -rf $HOSTAPD_CFG.*
    num_ap=1
    echo "#open
$(hostapd_conf_header)
ssid=open
auth_algs=1
wpa=0
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#open-hidden
$(hostapd_conf_header)
ssid=open-hidden
auth_algs=1
wpa=0
ignore_broadcast_ssid=1
" > $HOSTAPD_CFG.$num_ap


if ! grep -F 'release 9' /etc/redhat-release; then
  ((++num_ap))
  echo "#pskwep
$(hostapd_conf_header)
ssid=wep
auth_algs=3
ignore_broadcast_ssid=0
wpa=0
wep_default_key=0
wep_key0=\"abcde\"
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#pskwep_len13
$(hostapd_conf_header)
ssid=wep-2
auth_algs=3
ignore_broadcast_ssid=0
wep_default_key=0
wep_key0=\"testing123456\"
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#dynwep
$(hostapd_conf_header)
ssid=dynwep
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
" > $HOSTAPD_CFG.$num_ap

fi

  ((++num_ap))
  echo "#wpa2
$(hostapd_conf_header)
ssid=wpa2-eap
auth_algs=3
wpa=3
ieee8021x=1
eapol_version=1
wpa_key_mgmt=WPA-EAP WPA-PSK
rsn_pairwise=CCMP
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
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa2_pskonly
$(hostapd_conf_header)
ssid=wpa2-psk
auth_algs=3
wpa=3
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=secret123
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa1eap
$(hostapd_conf_header)
ssid=wpa1-eap
auth_algs=3
wpa=1
ieee8021x=1
eapol_version=1
wpa_key_mgmt=WPA-EAP
wpa_pairwise=CCMP
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa1_pskonly
$(hostapd_conf_header)
ssid=wpa1-psk
auth_algs=3
wpa=1
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_passphrase=secret123
" > $HOSTAPD_CFG.$num_ap

# wpa3 requires wpa_suuplicant >= 2.9
wpa_ver=$(rpm -q wpa_supplicant)
wpa_ver=${wpa_ver#wpa_supplicant-}

if ver_gte $wpa_ver 2.9; then
  ((++num_ap))
  echo "#wpa3-sae
$(hostapd_conf_header)
ssid=wpa3-psk
auth_algs=3
wpa=2
wpa_key_mgmt=SAE
sae_password=secret123
#sae_pwe=2
rsn_pairwise=CCMP
ieee80211w=2
" > $HOSTAPD_CFG.$num_ap

((++num_ap))
echo "#wpa3 H2E only
$(hostapd_conf_header)
ssid=wpa3-h2e
auth_algs=3
wpa=2
wpa_key_mgmt=SAE
sae_password=secret123
sae_pwe=1
rsn_pairwise=CCMP
ieee80211w=2
" > $HOSTAPD_CFG.$num_ap
fi

hostapd_ver=$(rpm -q hostapd)
hostapd_ver=${hostapd_ver#hostapd-}
# There is no wpa_supplicant support in Fedoras
if ver_gte $hostapd_ver 2.9-6 && grep -q -e 'release \(8\|9\)' /etc/redhat-release; then
  ((++num_ap))
  echo "#wpa3eap
$(hostapd_conf_header)
ssid=wpa3-eap
auth_algs=3
wpa=2
ieee8021x=1
eapol_version=1
ieee80211w=2
wpa_key_mgmt=WPA-EAP-SUITE-B-192
eap_reauth_period=3600
eap_server=1
use_pae_group_addr=1
eap_user_file=$EAP_USERS_FILE
ca_cert=$HOSTAPD_KEYS_PATH/hostapd.ca.pem
dh_file=$HOSTAPD_KEYS_PATH/hostapd.dh.pem
server_cert=$HOSTAPD_KEYS_PATH/hostapd.cert.pem
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.enc.pem
private_key_passwd=redhat
rsn_pairwise=GCMP-256
group_cipher=GCMP-256
group_mgmt_cipher=BIP-GMAC-256
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa3_owe
$(hostapd_conf_header)
ssid=wpa3-owe
ieee80211w=2
wpa=2
wpa_key_mgmt=OWE
rsn_pairwise=CCMP
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa3_owe_transit
$(hostapd_conf_header)
ssid=wpa3-owe-transition
owe_transition_bssid=MAC_wlan$((num_ap+1))
owe_transition_ssid=\"wpa3-owe-hidden\"
" > $HOSTAPD_CFG.$num_ap

  ((++num_ap))
  echo "#wpa3_oweh
$(hostapd_conf_header)
ssid=wpa3-owe-hidden
ieee80211w=2
wpa=2
wpa_key_mgmt=OWE
rsn_pairwise=CCMP
ignore_broadcast_ssid=1
owe_transition_bssid=MAC_wlan$((num_ap-1))
owe_transition_ssid=\"wpa3-owe-transition\"
" > $HOSTAPD_CFG.$num_ap
fi

if ((MANY_AP)); then
  while ((num_ap < MANY_AP)); do
    ((++num_ap))
    echo "#MANY_AP
$(hostapd_conf_header)
ssid=open_$num_ap
auth_algs=1
wpa=0
" > $HOSTAPD_CFG.$num_ap
  done
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
    chmod -R o= $CLIENT_KEYS_PATH
    update-ca-trust extract
}

function restart_services ()
{
    systemctl daemon-reload
    systemctl restart wpa_supplicant
}

function replace_MAC_in_cfg () {
    for file in $HOSTAPD_CFG.*; do
        if [ -f "$file" ] ; then
            dev=$(sed -n 's/.*\MAC_\(wlan[0-9]*\)/\1/p' "$file")
            if [ -n "$dev" ]; then
                mac=$(get_mac $dev)
                sed -i "s/MAC_$dev/$mac/" "$file"
            fi
        fi
    done
}

function start_nm_hostapd ()
{
    replace_MAC_in_cfg
    # launch with -dd causes wpa_debug_level=1 in hostapd (level 0 spams logs too much)
    local hostapd="hostapd -dd "
    if $DO_NAMESPACE; then
        hostapd="ip netns exec wlan_ns $hostapd"
    fi
    for file in $HOSTAPD_CFG.*; do
        i="${file##*.}"
        systemd-run --unit nm-hostapd-$i $hostapd $file
    done
}

function stop_nm_hostapd () {
    for file in $HOSTAPD_CFG.*; do
        i="${file##*.}"
        if systemctl --quiet is-failed nm-hostapd-$i; then
            systemctl reset-failed nm-hostapd-$i
        fi
        systemctl stop nm-hostapd-$i
    done
}

function check_nm_hostapd () {
    num_conf=$(ls $HOSTAPD_CFG.* | wc -l)
    services="$(systemctl list-units | grep -o 'nm-hostapd-[^.]*\.service')"
    num_serv="$(echo "$services" | grep . | wc -l)"
    if [ "$num_conf" != "$num_serv" -o "$num_conf" == 0 ]; then
        echo "Not OK!! ($num_conf AP configs, $num_serv services)"
        return 1
    fi

    # skip active service check
    return 0

    for serv in $services; do
        if ! systemctl --quiet is-active "$serv"; then
          echo "Not OK!! service $serv not running"
          return 1
        fi
    done
    return 0
}

function wireless_hostapd_check ()
{
    need_setup=0
    need_restart=0
    echo "* Checking hostapd"
    if [ ! -e /tmp/nm_wifi_supp_configured ]; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking dnsmasqs"
    if ! pkill -0 -F /tmp/dnsmasq_wireless.pid; then
        echo "Not OK!!"
        need_setup=1
    fi
    echo "* Checking nm-hostapd"
    if ! check_nm_hostapd; then
        # check_nm_hostapd outputs "Not OK!!" message
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

    echo "* Checking crypto"
    crypto="default"
    if [ -f /tmp/nm_wifi_supp_legacy_crypto ]; then
      crypto="legacy"
    fi
    if [ $crypto != $CRYPTO ]; then
        if grep -q "release 9" /etc/redhat-release; then
            echo "Not OK!! (restart suffices)"
            need_restart=1
        fi
    fi

    echo "* Checking 'many_ap'"
    many_ap=$(ls $HOSTAPD_CFG.* | wc -l)
    if [ -n "$MANY_AP" -a "$many_ap" != "$MANY_AP" ]; then
      echo "Not OK!! - need $MANY_AP, found $many_ap"
      need_setup=1
    fi
    if [ -z "$MANY_AP" ] && grep -q MANY_AP -r $HOSTAPD_CFG.* ; then
      echo "Not OK!! - need to destroy some APs"
      need_setup=1
    fi

    if [ $need_setup -eq 1 ]; then
        rm -rf /tmp/nm_wifi_supp_configured
        wireless_hostapd_teardown
        return 1
    fi

    if [ $need_restart -eq 1 ]; then
        if [ "$CRYPTO" == "default" ]; then
          rm -rf /tmp/nm_wifi_supp_legacy_crypto
        else
          touch /tmp/nm_wifi_supp_legacy_crypto
        fi
        restart_services
        stop_nm_hostapd
        start_nm_hostapd
        if ! check_nm_hostapd; then
          echo "Not OK!! - hostapd restart failed, doing teardown"
          rm -rf /tmp/nm_wifi_supp_configured
          wireless_hostapd_teardown
          return 1
        fi
    else
        touch /tmp/wireless_hostapd_check.txt
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
        local policy_file="contrib/selinux-policy/hostapd_wireless_$major_ver.pp"
        (semodule -l | grep -q hostapd_wireless) || semodule -i $policy_file || echo "ERROR: unable to load selinux policy !!!"
        ip netns add wlan_ns
        ip -n wlan_ns link set lo up
    fi

    if [ "$CRYPTO" == "legacy" ]; then
        touch /tmp/nm_wifi_supp_legacy_crypto
    else
        rm -rf /tmp/nm_wifi_supp_legacy_crypto
    fi

    # Disable mac randomization to avoid rhbz1490885
    echo -e "[device-wifi]\nwifi.scan-rand-mac-address=no" > /etc/NetworkManager/conf.d/99-wifi.conf
    echo -e "[connection-wifi]\nwifi.cloned-mac-address=preserve" >> /etc/NetworkManager/conf.d/99-wifi.conf
    echo -e "[device]\nmatch-device=interface-name:wlan1\nmanaged=0" >> /etc/NetworkManager/conf.d/99-wifi.conf

    if lsmod | grep -q -w mac80211_hwsim; then
        modprobe -r mac80211_hwsim
    fi
    modprobe mac80211_hwsim radios=$((num_ap+1))
    if ! lsmod | grep -q -w mac80211_hwsim; then
        echo "Error. Cannot load module \"mac80211_hwsim\"." >&2
        return 1
    fi

    restart_services
    if ! systemctl -q is-active wpa_supplicant; then
        echo "Error. Cannot start the service for WPA supplicant." >&2
        return 1
    fi

    if $DO_NAMESPACE; then
        i=1
        for ((i=1; i <= num_ap; i++)); do
          phy=$(get_phy wlan$i)
          iw phy $phy set netns name wlan_ns
          ip -n wlan_ns link set wlan$i up
          ip -n wlan_ns add add 10.0.254.$i/24 dev wlan$i
        done
    else
        for ((i=1; i <= num_ap; i++)); do
          ip link set wlan$i up
          ip add add 10.0.254.$i/24 dev wlan$i
          ((i++))
        done
    fi
}

function wireless_hostapd_setup ()
{
    set +x

    echo "Configuring hostapd 802.1x server..."

    rm -rf /tmp/wireless_hostapd_check.txt
    if  wireless_hostapd_check; then
        echo "OK. Configuration has already been done."
        return 0
    fi

    write_hostapd_cfg
    prepare_test_bed
    copy_certificates

    set -e

    start_ap || return 1

    touch /tmp/nm_wifi_supp_configured
}

function start_ap () {
    # Start 802.1x authentication and built-in RADIUS server.
    # Start hostapd as a service via systemd-run using configuration wifi adapters
    start_nm_hostapd

    start_dnsmasq
    if ! pkill -0 -F /tmp/dnsmasq_wireless.pid; then
        echo "Error. Cannot start dnsmasq as DHCP server." >&2
        return 1
    fi

    if ! check_nm_hostapd; then
        echo "unable to start hostapd"
        return 1
    fi
}

function wireless_hostapd_teardown ()
{
    set -x
    ip netns del wlan_ns
    pkill -F /tmp/dnsmasq_wireless.pid
    stop_nm_hostapd
    nmcli device set wlan1 managed on
    ip addr flush dev wlan1
    modprobe -r mac80211_hwsim
    [ -f /run/hostapd/wlan1 ] && rm -rf /run/hostapd/wlan1
    rm -rf /etc/NetworkManager/conf.d/99-wifi.conf
    systemctl reload NetworkManager
    rm -rf /tmp/nm_wifi_supp_configured
    rm -rf $HOSTAPD_CFG.*
}

if [ "$1" == "teardown" ]; then
    wireless_hostapd_teardown
    echo "System's state returned prior to hostapd's config."
else
    # If hostapd's config fails then restore initial state.
    echo "Configure and start hostapd..."
    # Set DO_NAMESPACE to true if "namespace" in arguments
    DO_NAMESPACE=false
    MANY_AP=
    CRYPTO="default"

    for arg in "$@"; do
      if [[ "$arg" == "namespace" ]]; then
          DO_NAMESPACE=true
      fi
      if [[ "$arg" == "legacy_crypto" ]]; then
        CRYPTO="legacy"
      fi
      if [[ "$arg" == "many_ap="* ]]; then
        MANY_AP=${arg#many_ap=}
      fi
    done

    CERTS_PATH=${1:?"Error. Path to certificates is not specified."}

    wireless_hostapd_setup $1; RC=$?
    if [ $RC -eq 0 ]; then
        echo "hostapd started successfully."
    else
        echo "Error. Failed to start hostapd." >&2
        exit 1
    fi
fi
