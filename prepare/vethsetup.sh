#!/bin/bash
#set -x

# Note: This entire setup is available from NetworkManager 1.0.4 up

function setup_veth_env ()
{
    # Log state of net before the setup
    #ip a
    #nmcli con
    #nmcli dev
    #nmcli gen
    sleep 1

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
    # Enable udev rule to enable ignoring 'veth' devices eth*, keeping their pairs unmanaged
    echo 'ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="eth[0-9]|eth[0-9]*[0-9]", ENV{NM_UNMANAGED}="0"' >/etc/udev/rules.d/99-lr.rules
    udevadm control --reload-rules
    udevadm settle --timeout=5
    sleep 1
    #if ! grep no-auto-default /etc/NetworkManager/NetworkManager.conf; then
    #    echo "no-auto-default=*" >> /etc/NetworkManager/NetworkManager.conf
    #    echo "ignore-carrier=*" >> /etc/NetworkManager/NetworkManager.conf
    #    sleep 1
    #    systemctl restart NetworkManager; sleep 1
    #fi

    # Need 'config server' like setup
    if ! rpm -q NetworkManager-config-server; then
        yum -y install NetworkManager-config-server
    fi

    # If different than default connection is up after compilation bring it down and restart service
    for i in $(nmcli -t -f DEVICE connection); do
        nmcli device disconnect $i
        rm -rf /var/run/NetworkManager*
    done
    sleep 2
    systemctl restart NetworkManager; sleep 5

    # # log state of net after service restart
    # ip a
    # nmcli con
    # nmcli dev
    # nmcli gen

    # Get active device
    counter=0
    DEV=""
    while [ -z $DEV ]; do
        DEV=$(nmcli -f DEVICE,TYPE,STATE -t d | grep :ethernet | grep :connected | awk -F':' '{print $1}' | head -n 1)
        sleep 1
        ((counter++))
        if [ $counter -eq 20 ]; then
            # in case, there is single ethernet device, connect it and count to 40
            if [ $(nmcli -f DEVICE,TYPE,STATE -t d | grep :ethernet | wc -l) == 1 ]; then
                DEV=$(nmcli -f DEVICE,TYPE,STATE -t d | grep :ethernet | awk -F':' '{print $1}' | head -n 1)
                echo "Activating single ethernet device '$DEV'"
                nmcli device connect $DEV
            # fail otherwise
            else
                echo "All ethernet interfaces down, unable to determine gateway"
                nmcli dev
                exit 1
            fi
        elif [ $counter -eq 40 ]; then
            echo "Unable to get active device"
            exit 1
        fi
    done
    # Make sure the active ethernet device is eth0
    if ! [ "x$DEV" == "xeth0" ]; then
        sleep 1
        ip link set $DEV down
        ip link set $DEV name eth0
    fi
    UUID_NAME=$(nmcli -t -f UUID,NAME c show --active | head -n 1)
    NAME=${UUID_NAME#*:}
    UUID=${UUID_NAME%:*}
    # Overwrite the name in order to be sure to have all the NM keys (including UUID) in the ifcfg file
    nmcli con mod $UUID connection.id "$NAME"

    if ! test -f /tmp/nm_plugin_keyfiles; then
        # Backup original ifcfg
        nmcli device disconnect $DEV 2>&1 > /dev/null

        if [ ! -e /tmp/ifcfg-$DEV ]; then
            mv /etc/sysconfig/network-scripts/ifcfg-$DEV /tmp/
            sleep 0.5
            nmcli con reload
            sleep 0.5
        fi

        # Copy backup to /etc/sysconfig/network-scripts/ and reload
        yes 2>/dev/null | cp -rf /tmp/ifcfg-$DEV /etc/sysconfig/network-scripts/ifcfg-testeth0
        sleep 0.5
        nmcli con reload
        sleep 0.5

    else
        # Backup original nmconnection file
        nmcli device disconnect $DEV 2>&1 > /dev/null
        if [ ! -e /tmp/$DEV.nmconnection ]; then
            mv /etc/NetworkManager/system-connections/$DEV.nmconnection /tmp/
            sleep 0.5
            nmcli con reload
            sleep 0.5
        fi

        # Copy backup to /etc/sysconfig/network-scripts/ and reload
        yes 2>/dev/null | cp -rf /tmp/$DEV.nmconnection /etc/NetworkManager/system-connections/testeth0.nmconnection
        sleep 0.5
        nmcli con reload
        sleep 0.5
    fi

    # Bring up the device and prepare final profile testeth0
    ip link set eth0 up
    nmcli con mod $UUID connection.id testeth0
    nmcli con mod $UUID connection.interface-name eth0
    nmcli connection modify $UUID ipv6.method auto
    sleep 1

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

        # And set it unmanaged
        nmcli device disconnect orig-$DEV
        nmcli device set orig-$DEV managed off
    done

    # unmanage orig- devices
    echo -e "[keyfile]\nunmanaged-devices=interface-name:orig-*" > /etc/NetworkManager/conf.d/99-unmanage-orig.conf

    # Create a network namespace for veth setup
    ip netns add vethsetup

    # Create 'internal' veth devices and hide their peers inside namespace
    for X in $(seq 1 9); do
        ip link add eth${X} type veth peer name eth${X}p
        ip link set eth${X}p netns vethsetup
    done

    # Create bridge for the internal device peers inside the namespace
    ip netns exec vethsetup ip link add name inbr type bridge forward_delay 0 stp_state 1

    # Set best prirority to this bridge
    ip netns exec vethsetup ip link set inbr type bridge priority 0
    ip netns exec vethsetup ip link set inbr up

    # Add the internal devices peers into the internal bridge
    for X in $(seq 1 9); do
        ip netns exec vethsetup ip link set eth${X}p master inbr
        # 'worse' priority to ports coming to simulated ethernet devices
        ip netns exec vethsetup ip link set eth${X}p type bridge_slave priority 5
        ip netns exec vethsetup ip link set eth${X}p up
    done

    # We want to have an extra veth pair for the dnsmasq so we can give that
    # The top priority preventing looping when ethX devices bridged on the other side
    ip netns exec vethsetup ip link add masq type veth peer name masqp

    ip netns exec vethsetup ip link set masqp master inbr
    ip netns exec vethsetup ip link set masqp type bridge_slave priority 0

    ip netns exec vethsetup ip link set masqp up
    ip netns exec vethsetup ip link set masq up

    # Give bridge an internal format address in form used in tests
    ip netns exec vethsetup ip addr add 192.168.100.1/24 dev masq

    # Remove mapping to lo only (starting Fedora 33)
    sed -i 's/^interface=lo/# interface=lo/' /etc/dnsmasq.conf

    # Start up a DHCP server on the internal bridge for IPv4
    ip netns exec vethsetup dnsmasq --pid-file=/tmp/dhcp_inbr.pid --dhcp-leasefile=/tmp/dhcp_inbr.lease --listen-address=192.168.100.1 --dhcp-range=192.168.100.10,192.168.100.254,240 --interface=masq --bind-interfaces

    # Setup simulated 'outside' connectivity device eth10 with IPv6 auto support
    ip link add eth10 type veth peer name eth10p
    ip link set eth10p netns vethsetup
    ip netns exec vethsetup ip link set eth10p up

    # Create the 'simbr' - providing both 10.x ipv4 and 2620:52:0 ipv6 dhcp
    ip netns exec vethsetup ip link add name simbr type bridge forward_delay 0 stp_state 1
    ip netns exec vethsetup ip link set simbr up
    ip netns exec vethsetup ip addr add 10.16.1.1/24 dev simbr
    ip netns exec vethsetup ip -6 addr add 2620:52:0:1086::1/64 dev simbr

    # Add eth10 peer into the simbr
    ip netns exec vethsetup ip link set eth10p master simbr

    # Run joint DHCP4/DHCP6 server with router advertisement enabled in veth namespace
    ip netns exec vethsetup dnsmasq --pid-file=/tmp/dhcp_simbr.pid --dhcp-leasefile=/tmp/dhcp_simbr.lease --dhcp-range=10.16.1.10,10.16.1.254,240 --dhcp-range=2620:52:0:1086::10,2620:52:0:1086::1ff,slaac,64,240 --enable-ra --interface=simbr --bind-interfaces

    # Creating testeth* profiles for the internal device network
    for X in $(seq 1 9); do
        nmcli c add type ethernet con-name testeth${X} ifname eth${X} autoconnect no
    done

    # Creating testeth profile for the simulated external device
    nmcli c add type ethernet con-name testeth10 ifname eth10 autoconnect no

    systemctl restart NetworkManager; sleep 4

    nmcli c modify testeth0 ipv4.route-metric 99 ipv6.route-metric 99
    nmcli c u testeth0

    if ! test -f /tmp/nm_plugin_keyfiles; then
        if [ ! -e /tmp/testeth0 ] ; then
            # THIS NEED TO BE DONE HERE FOR RECREATION REASONS
            # Copy final connection to /tmp/testeth0 for later in test usage
            yes 2>/dev/null | cp -rf /etc/sysconfig/network-scripts/ifcfg-testeth0 /tmp/testeth0
        fi
    else
        if ! test -f /tmp/testeth0; then
            # THIS NEED TO BE DONE HERE FOR RECREATION REASONS
            # Copy final connection to /tmp/testeth0 for later in test usage
            yes 2>/dev/null | cp -rf /etc/NetworkManager/system-connections/testeth0.nmconnection /tmp/testeth0
        fi
    fi
    # On s390x sometimes this extra default profile gets created in addition to custom static original one
    # Let's get rid of that
    for i in $(nmcli -t -f NAME,UUID connection |grep -v testeth |grep -v orig |awk -F ':' ' {print $2}'); do nmcli con del $i; done

    touch /tmp/nm_newveth_configured

    # Log state of net after the setup
    # ip a
    # nmcli con
    # nmcli dev
    # nmcli gen
}


function check_veth_env ()
{
    # Check devices
    need_veth=0
    echo "* Checking devices"
    for X in $(seq 1 10); do
        if ! (nmcli -t -f DEVICE device | grep -q ^eth$X$ && ip a s eth$X |grep -q 'state UP'); then
            echo "Not OK!!"
            need_veth=1
            break
        fi
    done

    echo "* Checking profiles"
    if ! nmcli connection show testeth0 testeth1 testeth2 testeth3 testeth4 testeth5 testeth6 testeth7 testeth8 testeth9 testeth10 > /dev/null; then
        echo "Not OK!!"
        need_veth=1
    fi

    echo "* Checking up testeth0 and non activated testethX"
    if ! (nmcli connection show --active |grep testeth0 > /dev/null && ! nmcli connection show --active |grep testeth |grep -v testeth0); then
        echo "Not OK!!"
        need_veth=1
    fi

    # Check running dnsmasqs
    echo "* Checking dnsmasqs"
    inbr_pid=$(cat /tmp/dhcp_inbr.pid)
    simbr_pid=$(cat /tmp/dhcp_simbr.pid)
    if ! pidof dnsmasq |grep -q $inbr_pid && pidof dnsmasq | grep -q $simbr_pid; then
        echo "Not OK!!"
        need_veth=1
    fi

    # Check inbr slaves
    echo "* Checking inbr slaves"
    for X in $(seq 1 9); do
        if ! ip netns exec vethsetup ip link show master inbr |grep -q eth$Xp; then
            echo "Not OK!!"
            need_veth=1
            break
        fi
    done

    # Check simbr
    echo "* Checking simbr slave"
    if ! ip netns exec vethsetup ip link show master simbr |grep -q eth10p; then
        echo "Not OK!!"
        need_veth=1
    fi

    echo "* Checking simbr addresses"
    if ! ip netns exec vethsetup ip a s simbr |grep -q 10.16.1.1/24 && ip netns exec vethsetup ip a s simbr |grep -q 2620:52:0:1086::1/64; then
        echo "Not OK!!"
        need_veth=1
    fi

    # Check inbr masq slave
    echo "* Checking masq slave"
    if ! ip netns exec vethsetup ip link show master inbr |grep -q masq; then
        echo "Not OK!!"
        need_veth=1
    fi

    echo "* Checking masq addresses"
    if ! ip netns exec vethsetup ip a s  masq |grep -q 192.168.100.1/24; then
        echo "Not OK!!"
        need_veth=1
    fi

    if [ $need_veth -eq 0 ]; then
        exit 0
    else
        echo "Need to regenerate vethsetup!!"
        teardown_veth_env
        setup_veth_env
    fi

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
    ip netns exec vethsetup ip link del inbr

    ip netns exec vethsetup ip link set simbr down
    ip netns exec vethsetup ip link del simbr

    ip netns del vethsetup

    # Remove the udev ruling
    rm -rf /etc/udev/rules.d/99-lr.rules
    udevadm control --reload-rules
    udevadm settle --timeout=5
    sleep 1

    # Remove extra config-sever like setup
    if grep no-auto-default /etc/NetworkManager/NetworkManager.conf; then
        sed -i '/no-auto-default=\*/d' /etc/NetworkManager/NetworkManager.conf
        sed -i '/ignore-carrier=\*/d' /etc/NetworkManager/NetworkManager.conf
    fi

    # Delete all testethX connections
    for X in $(seq 1 10); do
        nmcli con del testeth${X}
    done

    if ! test /tmp/nm_plugin_keyfiles; then
        # Get ORIGDEV name to bring device back to and copy the profile back
        ORIGDEV=$(grep DEVICE /tmp/ifcfg-* | awk -F '=' '{print $2}' | tr -d '"')
        if [ "x$ORIGDEV" == "x" ]; then
            ORIGDEV=$(ls /tmp/ifcfg-* | awk -F '-' '{print $2}' |tr -d '"')
        fi
        # Disconnect eth0
        nmcli device disconnect eth0
        # Move all profiles
        rm /etc/sysconfig/network-scripts/ifcfg-testeth0*
        mv -f /tmp/ifcfg-$ORIGDEV /etc/sysconfig/network-scripts/ifcfg-$ORIGDEV
    else
        ORIGDEV=$(grep interface-name /tmp/*.nmconnection | awk -F '=' '{print $2}' | tr -d '"')
        # Disconnect eth0
        nmcli device disconnect eth0
        rm /etc/NetworkManager/system-connections/testeth0.nmconnection
        # Move all profiles
        mv -f /tmp/$ORIGDEV.nmconnection /etc/NetworkManager/system-connections/$ORIGDEV.nmconnection
    fi

    # and reload
    sleep 1
    nmcli con reload
    sleep 1

    # Rename the device back to ORIGNAME
    if [ "$ORIGDEV" != "eth0" ]; then
        ip link set dev eth0 down
        ip link set dev eth0 name $ORIGDEV
        ip link set dev $ORIGDEV up
    fi

    # Rename original devices back
    for DEV in $(nmcli -f DEVICE -t d | grep '^orig-' | sed 's/^orig-//'); do
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
    sleep 1
    # Restart and bring back ORIGDEV up
    systemctl restart NetworkManager; sleep 2

    rm -rf /tmp/nm_newveth_configured
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
elif [ "$1" == "check" ]; then
    check_veth_env
fi
