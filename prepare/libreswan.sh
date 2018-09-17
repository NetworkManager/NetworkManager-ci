#!/bin/bash
set +x

LIBRESWAN_DIR="/opt/ipsec"


# Allow only users with root priviledge to run the script.
if [ $EUID -ne 0 ]; then
    echo "This script can be run with root priviledge only." >&2
    exit 1
fi

# Check for the correct # of arguments - TODO


libreswan_gen_connection ()
{
	CONNECTION_CFG="$1"
	MODE="$2"

	echo "conn roadwarrior_psk
	auto=add
	authby=secret
	pfs=no
	rekey=no
	left=172.31.70.1
	leftsubnet=0.0.0.0/0
	rightaddresspool=172.29.100.2-172.29.100.10
	right=%any
	cisco-unity=yes
	leftxauthserver=yes
	rightxauthclient=yes
	leftmodecfgserver=yes
	rightmodecfgclient=yes
	modecfgpull=yes
    modecfgbanner=BUG_REPORT_URL
	xauthby=alwaysok
	ike-frag=yes
	ikev2=never" > "$CONNECTION_CFG"
	if [ "$MODE" = "aggressive" ]; then
		echo \
"	rightid=@yolo
	aggressive=yes" >> "$CONNECTION_CFG"
	fi
}

libreswan_gen_secrets ()
{
	SECRETS_CFG="$1"

	echo ": PSK \"ipsecret\"" > "$SECRETS_CFG"
	chmod 600 "$SECRETS_CFG"
}

libreswan_gen_netconfig ()
{
	ip netns add libreswan

	# IPv6 on a veth confuses pluto. Sigh. (TODO: check id still true)
	# ERROR: bind() for 80/80 fe80::94bf:8cff:fe1b:7620:500 in process_raw_ifaces(). Errno 22: Invalid argument
	echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
	ip netns exec libreswan echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
	ip link add libreswan0 type veth peer name libreswan1
	ip link set libreswan0 netns libreswan

	ip netns exec libreswan ip link set lo up
	ip netns exec libreswan ip addr add dev libreswan0 172.31.70.1/24
	ip netns exec libreswan ip link set libreswan0 up
	ip link set dev libreswan1 up

	ip netns exec libreswan dnsmasq --pid-file=/tmp/libreswan_dnsmasq.pid \
	                                --dhcp-range=172.31.70.2,172.31.70.40,2m \
	                                --interface=libreswan0 --bind-interfaces
	sleep 5
	echo "PID of dnsmasq:"
	pidof dnsmasq
}

####

libreswan_setup ()
{
	# Quit immediatelly on any script error
	set -e
	MODE="$1"
	CONNECTION_CFG="$LIBRESWAN_DIR/connection.conf"
	SECRETS_CFG="$LIBRESWAN_DIR/ipsec.secrets"
	NSS_DIR="$LIBRESWAN_DIR/nss"

	echo "Configuring remote Libreswan peer"
	[ -d "$LIBRESWAN_DIR" ] || mkdir "$LIBRESWAN_DIR"
	[ -d "$NSS_DIR" ] || mkdir "$NSS_DIR"

	libreswan_gen_secrets "$SECRETS_CFG"
	libreswan_gen_connection "$CONNECTION_CFG" "$MODE"
	libreswan_gen_netconfig

	### add default route connection that takes precedence over the system one
	nmcli connection add type ethernet con-name lib1 ifname libreswan1 autoconnect no \
		ipv6.method ignore ipv4.route-metric 90
	sleep 1
	# Warning: the next command interrupts any established SSH connection to the remote machine!
	nmcli connection up id lib1
	sleep 1

	# Sometime there is larger time needed to set everything up, sometimes not. Let's make the delay
	# to fit all situations.
	SECS=20
	while ! ip -4 add show libreswan1 | grep -q '172.31.70'; do
		((SECS--))
		[ $SECONDS -eq 0 ] && false
		sleep 1
	done

	set +e

	modprobe af_key
	ipsec checknss --nssdir "$NSS_DIR"

    ip netns exec libreswan ipsec pluto \
				--secretsfile "$SECRETS_CFG" \
				--ipsecdir "$LIBRESWAN_DIR" \
				--nssdir "$NSS_DIR" \
				--rundir "$LIBRESWAN_DIR"
	ipsec addconn --addall --config "$CONNECTION_CFG" --ctlsocket "$LIBRESWAN_DIR/pluto.ctl"

    sleep 5
}

libreswan_teardown ()
{
	kill $(cat "$LIBRESWAN_DIR/pluto.pid")
	echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
	ip netns del libreswan
	ip link del libreswan1
	kill $(cat /tmp/libreswan_dnsmasq.pid)
	nmcli connection del lib1
	modprobe -r ip_vti
}

if [ "$1" != "teardown" ]; then
	libreswan_setup $1 $2 $3
else
	libreswan_teardown
fi
