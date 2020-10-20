#!/bin/bash
set +x

STRONGSWAN_DIR="/etc/netns/strongswan/"


# Allow only users with root priviledge to run the script.
if [ $EUID -ne 0 ]; then
    echo "This script can be run with root priviledge only." >&2
    exit 1
fi

# Check for the correct # of arguments - TODO

kill_dnsmasq() {
    if test -f /tmp/strongswan_dnsmasq.pid; then
        pkill -F /tmp/strongswan_dnsmasq.pid dnsmasq
        rm -f /tmp/strongswan_dnsmasq.pid
    fi
}

strongswan_gen_connection ()
{
        CONNECTION_CFG="$STRONGSWAN_DIR/strongswan/swanctl/swanctl.conf"
        STRONGSWAN_CFG="$STRONGSWAN_DIR/strongswan/strongswan.conf"
        IPSEC_CFG="$STRONGSWAN_DIR/strongswan/ipsec.conf"
        IPSEC_SECRETS="$STRONGSWAN_DIR/ipsec.secrets"

        mkdir -p "$(dirname $CONNECTION_CFG)"
        mkdir -p "$(dirname $STRONGSWAN_CFG)"
        mkdir -p "$(dirname $IPSEC_CFG)"
        mkdir -p "$(dirname $IPSEC_SECRETS)"

        cat << EOF > $CONNECTION_CFG
connections {

   rw {
      local_addrs  = 172.31.70.1

      local {
         auth = psk
      }
      remote {
         auth = psk
      }
      children {
         net {
            local_ts  = 172.27.0.1/24
            #updown = /usr/local/libexec/ipsec/_updown iptables
            esp_proposals = aes128-sha256-x25519
         }
      }
      version = 2
      proposals = aes128-sha256-x25519
      pools = strongswan_pool
   }
}

secrets {
    ike-budulinek {
        secret = 12345678901234567890
    }
    ppk-budulinek {
        secret = 12345678901234567890
    }
    ike-dubulinek {
        secret = 12345678901234567890
    }
    ppk-dubulinek {
        secret = 12345678901234567890
    }
}

pools {
    strongswan_pool {
        addrs = 172.29.100.0/24
        dns = 8.8.8.8
    }
}
EOF

    cat << EOF > $STRONGSWAN_CFG
swanctl {
  load = random openssl
}

charon {
  install_routes = no
  load = random nonce aes sha1 sha2 md5 hmac curve25519 kernel-netlink socket-default updown vici
 # reuse_ikesa=no
}
EOF

    echo "config setup" > $IPSEC_CFG

    #echo ":PSK 12345678901234567890" > $IPSEC_SECRETS

#    cat << EOF > $STRONGSWAN_DIR/strongswan/strongswan.d/charon/duplicheck.conf
#duplicheck {
#    load = no
#    socket = unix://\${piddir}/charon.dck
#}
#EOF


}

strongswan_gen_netconfig ()
{
        ip netns add strongswan
        # IPv6 on a veth confuses pluto. Sigh. (TODO: check id still true)
        # ERROR: bind() for 80/80 fe80::94bf:8cff:fe1b:7620:500 in process_raw_ifaces(). Errno 22: Invalid argument
        echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
        ip netns exec strongswan echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
        ip link add strongswan0 type veth peer name strongswan1
        ip link set strongswan0 netns strongswan

        ip netns exec strongswan ip link set lo up
        ip netns exec strongswan ip addr add dev strongswan0 172.31.70.1/24
        ip netns exec strongswan ip link set strongswan0 up
        ip netns exec strongswan ip link add strongswan2 type veth
        ip netns exec strongswan ip link set strongswan2 up
        ip netns exec strongswan ip addr add 172.27.0.1/24 dev strongswan2
        ip netns exec strongswan ip r add default via 172.27.0.1 dev strongswan2
        ip link set dev strongswan1 up

    #    ip netns exec strongswan dnsmasq --pid-file=/tmp/strongswan_dnsmasq.pid \
    #                                    --dhcp-range=172.31.70.2,172.31.70.40,2m \
    #                                    --interface=strongswan0 --bind-interfaces
    #    echo "PID of dnsmasq:"
    #    cat /tmp/strongswan_dnsmasq.pid
}

####

strongswan_setup ()
{
        # Quit immediatelly on any script error
        set -e

        rm -rf $STRONGSWAN_DIR
        mkdir $STRONGSWAN_DIR -p
        cp -r /etc/strongswan $STRONGSWAN_DIR
        # prepare /var/run
        VAR_RUN_DIR=/var/netns/strongswan
        rm -rf $VAR_RUN_DIR
        mkdir -p $VAR_RUN_DIR
        touch $VAR_RUN_DIR/dummy



        # selinux policy
        semodule -i tmp/selinux-policy/strongswan.pp

        echo "Configuring remote Strongswan peer"

        strongswan_gen_connection
        strongswan_gen_netconfig

        ### add default route connection that takes precedence over the system one
        nmcli connection add type ethernet con-name str1 ifname strongswan1 autoconnect no \
                ipv6.method ignore ipv4.method manual ipv4.route-metric 90 ip4 172.31.70.2/24 \
                ipv4.gateway 172.31.70.1 ipv4.dns 172.31.70.1
        # Warning: the next command interrupts any established SSH connection to the remote machine!
        nmcli connection up id str1

        set +e

        modprobe af_key

        # rebind /var/run
        ip netns exec strongswan mount -o bind,remount $VAR_RUN_DIR /var/run

        ip netns exec strongswan strongswan start
        sleep 1
        ip netns exec strongswan swanctl --load-conns
        ip netns exec strongswan swanctl --load-pools
        ip netns exec strongswan swanctl --load-creds

}

strongswan_teardown ()
{
        ip netns exec strongswan strongswan stop
        echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
        ip netns del strongswan
        ip link del strongswan1
        kill_dnsmasq
        nmcli connection del str1
        modprobe -r ip_vti
}

if [ "$1" != "teardown" ]; then
        strongswan_setup $1
else
        strongswan_teardown
fi
