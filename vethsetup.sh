#!/bin/bash
set -x

# Note: This entire setup is available from NetworkManager 1.0.4 up

function setup_veth_env ()
{
    # Log state of net before the setup
    ip a
    nmcli con
    nmcli dev
    nmcli gen

    need_veth=0
    for X in $(seq 0 10); do
        if ! nmcli -t -f DEVICE device | grep -q ^eth$X$; then
            need_veth=1
            break
        fi
    done

    if [ $need_veth -eq 0 ]; then
        exit 0
    fi
    # Enable udev rule to enable ignoring 'veth' devices eth*, keeping their pairs unmanagad
    echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/99-lr.rules
    udevadm control --reload-rules
    udevadm settle

    #if ! grep no-auto-default /etc/NetworkManager/NetworkManager.conf; then
    #    echo "no-auto-default=*" >> /etc/NetworkManager/NetworkManager.conf
    #    echo "ignore-carrier=*" >> /etc/NetworkManager/NetworkManager.conf
    #    sleep 1
    #    systemctl restart NetworkManager; sleep 1
    #fi

    # Need 'config server' like setup
    if ! rpm -q NetworkManager-config-server; then
        yum -y install NetworkManager-config-server
        cp /usr/lib/NetworkManager/conf.d/00-server.conf /etc/NetworkManager/conf.d/00-server.conf
    fi

    # If different than default connection is up after compilation bring it down and restart service
    for i in $(nmcli -t -f DEVICE connection); do
        nmcli device disconnect $i
    done
    sleep 0.5
    systemctl restart NetworkManager; sleep 2

    # # log state of net after service restart
    # ip a
    # nmcli con
    # nmcli dev
    # nmcli gen

    # Make sure the active ethernet device is eth0
    if [ ! "eth0" == $(nmcli -f TYPE,DEVICE -t c sh --active  | grep ethernet | awk '{split($0,a,":"); print a[2]}') ]; then
        DEV=$(nmcli -f TYPE,DEVICE -t c sh --active  | grep ethernet | awk '{split($0,a,":"); print a[2]}')
        UUID=$(nmcli -t -f UUID c show --active)
        sleep 0.5
        ip link set $DEV down
        ip link set $DEV name eth0
    # Make active device eth0 if not
    else
        UUID=$(nmcli -t -f UUID c show --active)
        DEV="eth0"
    fi

    # Backup original ifcfg
    if [ ! -e /tmp/ifcfg-$DEV ]; then
        mv /etc/sysconfig/network-scripts/ifcfg-$DEV /tmp/
    fi

    # Copy backup to /etc/sysconfig/network-scripts/ and reload
    nmcli device disconnect $DEV 2>&1 > /dev/null
    yes 2>/dev/null | cp -rf /tmp/ifcfg-$DEV /etc/sysconfig/network-scripts/ifcfg-testeth0
    sleep 0.5
    nmcli con reload

    # Bring up the device and prepare final profile testeth0
    ip link set eth0 up
    nmcli con mod $UUID connection.id testeth0
    nmcli con mod $UUID connection.interface-name eth0
    nmcli connection modify $UUID ipv6.method auto
    sleep 0.5

    # Copy final connection to /tmp/testeth0 for later in test usage
    yes 2>/dev/null | cp -rf /etc/sysconfig/network-scripts/ifcfg-testeth0 /tmp/testeth0
    nmcli c u testeth0

    # Rename additional devices
    for DEV in $(nmcli -f TYPE,DEVICE -t d | grep -v eth0 | grep ethernet | awk '{split($0,a,":"); print a[2]}'); do
        ip link set $DEV down
        ip link set $DEV name orig-$DEV
        # Rename their profiles
        if nmcli c show $DEV 2>&1 > /dev/null; then
            nmcli c show $DEV | grep connection.interface | grep $DEV ; rc=$?
            if [ $rc -eq 0 ]; then
                nmcli con mod $DEV connection.id orig-$DEV
                nmcli con mod orig-$DEV connection.interface-name orig-$DEV
            else
                nmcli con mod $DEV connection.id orig-$DEV
            fi
        fi
        # Bring devices up with new name
        ip link set orig-$DEV up
    done

    # Create a network namespace for veth setup
    ip netns add vethsetup

    # Create 'internal' veth devices and hide their peers inside namespace
    for X in $(seq 1 9); do
        ip link add eth${X} type veth peer name eth${X}p
        ip link set eth${X}p netns vethsetup
    done

    # Create bridge for the internal device peers inside the namespace
    ip netns exec vethsetup brctl addbr inbr
    ip netns exec vethsetup brctl setfd inbr 2
    ip netns exec vethsetup brctl stp inbr on

    # Set best prirority to this bridge
    ip netns exec vethsetup brctl setbridgeprio inbr 0
    ip netns exec vethsetup ip link set inbr up

    # Add the internal devices peers into the internal bridge
    for X in $(seq 1 9); do
        ip netns exec vethsetup brctl addif inbr eth${X}p
        # 'worse' priority to ports coming to simulated ethernet devices
        ip netns exec vethsetup brctl setportprio inbr eth${X}p 5
        ip netns exec vethsetup ip link set eth${X}p up
    done

    # We want to have an extra veth pair for the dnsmasq so we can give that
    # The top priority preventing looping when ethX devices bridged on the other side
    ip netns exec vethsetup ip link add masq type veth peer name masqp

    ip netns exec vethsetup brctl addif inbr masqp
    ip netns exec vethsetup brctl setportprio inbr masqp 0

    ip netns exec vethsetup ip link set masqp up
    ip netns exec vethsetup ip link set masq up

    # Give bridge an internal format address in form used in tests
    ip netns exec vethsetup ip addr add 192.168.100.1/24 dev masq

    # Start up a DHCP server on the internal bridge for IPv4
    ip netns exec vethsetup dnsmasq --pid-file=/tmp/dhcp_inbr.pid --dhcp-leasefile=/tmp/dhcp_inbr.lease --listen-address=192.168.100.1 --dhcp-range=192.168.100.10,192.168.100.254,240 --interface=masq --bind-interfaces

    # Setup simulated 'outside' connectivity device eth10 with IPv6 auto support
    ip link add eth10 type veth peer name eth10p
    ip link set eth10p netns vethsetup
    ip netns exec vethsetup ip link set eth10p up

    # Create the 'simbr' - providing both 10.x ipv4 and 2620:52:0 ipv6 dhcp
    ip netns exec vethsetup brctl addbr simbr
    ip netns exec vethsetup brctl stp simbr on
    ip netns exec vethsetup ip link set simbr up
    ip netns exec vethsetup ip addr add 10.16.1.1/24 dev simbr
    ip netns exec vethsetup ip -6 addr add 2620:52:0:1086::1/64 dev simbr

    # Add eth10 peer into the simbr
    ip netns exec vethsetup brctl addif simbr eth10p

    # Run joint DHCP4/DHCP6 server with router advertisement enabled in veth namespace
    ip netns exec vethsetup dnsmasq --pid-file=/tmp/dhcp_simbr.pid --dhcp-leasefile=/tmp/dhcp_simbr.lease --dhcp-range=10.16.1.10,10.16.1.254,240 --dhcp-range=2620:52:0:1086::10,2620:52:0:1086::1ff,slaac,64,240 --enable-ra --interface=simbr --bind-interfaces

    # Creating testeth* profiles for the internal device network
    for X in $(seq 1 9); do
        nmcli c add type ethernet con-name testeth${X} ifname eth${X} autoconnect no
    done

    # Creating testeth profile for the simulater external device
    nmcli c add type ethernet con-name testeth10 ifname eth10 autoconnect no

    systemctl restart NetworkManager; sleep 1

    nmcli con up testeth0

    # On s390x sometimes this extra default profile gets created in addition to custom static original one
    # Let's get rid of that
    for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |awk -F ':' ' {print $2}'); do nmcli con del $i; done

    # Log state of net after the setup
    ip a
    nmcli con
    nmcli dev
    nmcli gen
}


function teardown_veth_env ()
{
    # Log state of net before the teardown
    ip a
    nmcli con
    nmcli dev
    nmcli gen

    # Stop DHCP for inbr and simbr
    kill $(cat /tmp/dhcp_inbr.pid)
    kill $(cat /tmp/dhcp_simbr.pid)

    for X in $(seq 1 10); do
        ip netns exec vethsetup ip link set eth${X}p down
        ip netns exec vethsetup ip link del eth${X}p
    done

    # Delete all namespaces and bridges
    ip netns exec vethsetup ip link del masqp

    ip netns exec vethsetup ip link set inbr down
    ip netns exec vethsetup brctl delbr inbr

    ip netns exec vethsetup ip link set simbr down
    ip netns exec vethsetup brctl delbr simbr

    ip netns del vethsetup

    # Remove the udev ruling
    rm -rf /etc/udev/rules.d/99-lr.rules
    udevadm control --reload-rules
    udevadm settle

    # Remove extra config-sever like setup
    if grep no-auto-default /etc/NetworkManager/NetworkManager.conf; then
        sed -i '/no-auto-default=\*/d' /etc/NetworkManager/NetworkManager.conf
        sed -i '/ignore-carrier=\*/d' /etc/NetworkManager/NetworkManager.conf
    fi

    # Delete all testethX connections
    for X in $(seq 1 10); do
        nmcli con del testeth${X}
    done

    # Get ORIGDEV name to bring device back to and copy the profile back
    ORIGDEV=$(grep DEVICE /tmp/ifcfg-* | awk -F '=' '{print $2}' | tr -d '"')

    # Disconnect eth0
    nmcli device disconnect eth0

    # Move all profiles and reload
    rm /etc/sysconfig/network-scripts/ifcfg-testeth0
    mv -f /tmp/ifcfg-$ORIGDEV /etc/sysconfig/network-scripts/ifcfg-$ORIGDEV
    sleep 0.5
    nmcli con reload
    rm /tmp/testeth0

    # Rename the device back to ORIGNAME
    if [ "$ORIGDEV" != "eth0" ]; then
        ip link set dev eth0 down
        ip link set dev eth0 name $ORIGDEV
        ip link set dev $ORIGDEV up
    fi

    # Rename original devices back
    for DEV in $(nmcli -f TYPE,DEVICE -t d | grep orig | awk '{split($0,a,":"); split(a[2],b,"-"); print b[2]}'); do
        ip link set orig-$DEV down
        ip link set orig-$DEV name $DEV
        # Rename their profiles if these exist
        if nmcli c show orig-$DEV 2>&1 > /dev/null; then
            nmcli c show orig-$DEV | grep connection.interface | grep orig-$DEV ; rc=$?
            if [ $rc -eq 0 ]; then
                nmcli con mod orig-$DEV connection.id $DEV
                nmcli con mod $DEV connection.interface-name $DEV
            else
                nmcli con mod orig-$DEV connection.id $DEV
            fi
        fi
        # Bring original devices back up
        ip link set $DEV up

    done

    nmcli con reload
    sleep 0.5
    # Restart and bring back ORIGDEV up
    systemctl restart NetworkManager; sleep 2

    # Log state of net after the teardown
    ip a
    nmcli con
    nmcli dev
    nmcli gen
}

if [ "$1" == "setup" ]; then
    setup_veth_env
elif [ "$1" == "teardown" ]; then
    teardown_veth_env
fi
