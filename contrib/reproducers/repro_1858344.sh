#!/bin/sh

printf "\n * Initial hostname: %s\n" $(hostname)

hostnamectl set-hostname ""
hostname localhost

ip link add veth0 type veth peer name veth1
ip netns add ns1
ip link set veth1 netns ns1
ip link set veth0 up
ip -n ns1 link set veth1 up
ip -n ns1 address add dev veth1 fd01::1/64

ip netns exec ns1 dnsmasq \
   --pid-file=/tmp/dnsmasq.pid \
   --bind-interfaces --interface veth1 --except-interface lo \
   --dhcp-range=fd01::100,fd01::200 --enable-ra \
   --dhcp-host 00:11:22:33:44:55,client1234 \
   --dhcp-option=option6:24,test.com &

nmcli connection add type ethernet ifname veth0 \
      con-name veth0+ ipv4.method disabled \
      ethernet.cloned-mac-address 00:11:22:33:44:55

cat <<'EOF' > /etc/NetworkManager/dispatcher.d/10-save-env.sh
#!/bin/sh

if [ "$1" != veth0 ] || [ "$2" != up ]; then
   exit 0
fi

env > /tmp/nm-dispatcher-env
EOF
chmod +x /etc/NetworkManager/dispatcher.d/10-save-env.sh
rm /tmp/nm-dispatcher-env

nmcli connection up veth0+

sleep 2

RC=0
if [ "$(hostname)" != client1234 ]; then
    echo "ERROR: wrong hostname $(hostname)"
    RC=1
fi

if ! grep DHCP6_FQDN_FQDN=client1234 /tmp/nm-dispatcher-env; then
    echo "ERROR: FQDN not present in /tmp/nm-dispatcher-env"
    RC=1
fi

#cleanup
ip link del veth0
nmcli connection delete veth0+
pkill -F /tmp/dnsmasq.pid
rm -rf /tmp/dnsmasq.pid
ip netns del ns1

if test $RC -eq 0; then
    echo 'OK'
    exit 0
else
    echo 'FAIL'
    exit 1
fi
