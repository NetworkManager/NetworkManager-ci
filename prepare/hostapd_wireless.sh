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

# function tune_wpa_supplicant ()
# {
#     # Tune wpa_supplicat to log into journal and enable debugging
#     systemctl stop wpa_supplicant
#     sed -i.bak s/^INTERFACES.*/INTERFACES=\"-iwlan1\"/ /etc/sysconfig/wpa_supplicant
#     cp -rf /usr/lib/systemd/system/wpa_supplicant.service /etc/systemd/system/wpa_supplicant.service
#     sed -i 's!ExecStart=/usr/sbin/wpa_supplicant -u -f /var/log/wpa_supplicant.log -c /etc/wpa_supplicant/wpa_supplicant.conf!ExecStart=/usr/sbin/wpa_supplicant -u -c /etc/wpa_supplicant/wpa_supplicant.conf!' /etc/systemd/system/wpa_supplicant.service
#     sed -i 's!OTHER_ARGS="-P /var/run/wpa_supplicant.pid"!OTHER_ARGS="-P /var/run/wpa_supplicant.pid -ddddK"!' /etc/sysconfig/wpa_supplicant
#
# }

function write_hostapd_cfg ()
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
private_key=$HOSTAPD_KEYS_PATH/hostapd.key.pem
private_key_passwd=redhat " > $1

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
    systemctl restart wpa_supplicant
    systemctl reload NetworkManager
}

function start_nm_hostapd ()
{
    systemd-run --unit nm-hostapd hostapd -ddd $HOSTAPD_CFG
    sleep 10
    if systemctl --quiet is-failed nm-hostapd; then
        exit 1
    fi
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
function wireless_hostapd_setup ()
{
    set +x
    CERTS_PATH=$1

    echo "Configuring hostapd 8021x server..."

    if [ "$2" == "wpa2" ]; then
        if  wireless_hostapd_check; then
            echo "Not needed, continuing"
            return
        else
            # Install haveged to increase entropy
            yum -y install haveged
            systemctl restart haveged

            # Disable mac randomization to avoid rhbz1490885
            echo -e "[device-wifi]\nwifi.scan-rand-mac-address=no" > /etc/NetworkManager/conf.d/99-wifi.conf
            echo -e "[connection-wifi]\nwifi.cloned-mac-address=preserve" >> /etc/NetworkManager/conf.d/99-wifi.conf

            modprobe mac80211_hwsim
            sleep 5
            #tune_wpa_supplicant
            restart_services
            sleep 10
            nmcli device set wlan1 managed off
            ip add add 10.0.254.1/24 dev wlan1
            sleep 5

            write_hostapd_cfg $HOSTAPD_CFG $EAP_USERS_FILE

            copy_certificates $CERTS_PATH

            set -e
            start_dnsmasq
            # Start 802.1x authentication and built-in RADIUS server.
            # Start hostapd as a service via systemd-run using configuration wifi adapters
            start_nm_hostapd

            touch /tmp/nm_wpa_supp_configured
        fi
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
    rm -rf /tmp/nm_wpa_supp_configured
    rm -rf /etc/NetworkManager/conf.d/99-wifi.conf
    systemctl reload NetworkManager

}

if [ "$1" != "teardown" ]; then
    wireless_hostapd_setup $1 $2
else
    wireless_hostapd_teardown
fi
