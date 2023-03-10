#!/bin/bash

systemctl stop nm-hostapd
pkill -F /tmp/dnsmasq_wireless.pid

yum -y install haveged hostapd wpa_supplicant NetworkManager dnsmasq --skip-broken

echo "
#wpa3-sae
interface=wlp2s0
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
hw_mode=g
channel=3
country_code=EN
logger_syslog=0
# keep loglevel 3 (WARNING), when launched with -dd it subtratcs to 1 (DEBUG)
logger_syslog_level=3
logger_stdout=-1
logger_stdout_level=3
ssid=qe-wpa3-psk
auth_algs=3
wpa=2
wpa_key_mgmt=SAE
sae_password=over the river and through the woods
#sae_pwe=2
rsn_pairwise=CCMP
ieee80211w=2" > /etc/hostapd/wireless.conf

systemctl daemon-reload

systemctl restart haveged
systemctl restart wpa_supplicant

nmcli  device set wlp2s0 managed no

ip add add 10.0.254.1/24 dev wlp2s0

hostapd="hostapd -dd "
systemd-run --unit nm-hostapd $hostapd /etc/hostapd/wireless.conf

/usr/sbin/dnsmasq --pid-file=/tmp/dnsmasq_wireless.pid \
                  --port=63 --no-hosts --interface=wlp2s0 \
                  --dhcp-range=10.0.254.150,10.0.254.205,60m \
                  --dhcp-option=option:router,10.0.254.1 \
                  --dhcp-leasefile=/var/lib/dnsmasq/hostapd.leases \
                  --dhcp-lease-max=50 &


