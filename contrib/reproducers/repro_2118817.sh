#!/bin/sh

set -xe

# Reproducer for https://bugzilla.redhat.com/show_bug.cgi?id=2118817
#
#  NS1
#              bond1 (DNS server)
#        ----------------
#       veth1         veth3
#        |              |
#  -----------------------------
#        |              |
#       veth0         veth2
#        ----------------
#              bond0
#
# veth0 and veth2 (and so, also bond0) don't have carrier
# initially. NM should be able to resolve the system hostname via DNS
# even if a device gets carrier later.


# Cleanup
pkill -laf '--host-record=client1234,172.25.1.101' 2>/dev/null || :
nmcli connection delete veth0+ veth2+ bond0+ 2>/dev/null || :
ip netns del ns1 2>/dev/null || :
ip link del veth0 2>/dev/null || :
ip link del veth1 2>/dev/null || :
ip link del veth2 2>/dev/null || :
ip link del veth3 2>/dev/null || :
hostnamectl set-hostname ""
systemctl stop systemd-hostnamed
hostname localhost
systemctl restart systemd-hostnamed
systemctl restart NetworkManager
sleep 4

# Bring down any other connection
nmcli -g uuid connection show --active | xargs nmcli connection down 2>/dev/null || :


printf "\n * Initial hostname: %s\n" $(hostname)

# Create topology
ip netns add ns1
ip link add veth0 type veth peer name veth1 netns ns1
ip link add veth2 type veth peer name veth3 netns ns1
ip link set veth0 up
ip link set veth2 up
ip -n ns1 link add bond1 type bond mode balance-rr
ip -n ns1 link set veth1 master bond1
ip -n ns1 link set veth3 master bond1
ip -n ns1 address add dev bond1 172.25.1.1/24
ip -n ns1 link set bond1 up
ip -n ns1 link set veth1 down
ip -n ns1 link set veth3 down

# Start DNS server in ns1
ip netns exec ns1 dnsmasq -h --interface bond1 --except-interface lo \
   --host-record=client1234,172.25.1.101 --log-queries --no-resolv \
   --server=8.8.8.8

# Add bond port connections
nmcli connection add type ethernet ifname veth0 \
      master bond0 slave-type bond con-name veth0+
nmcli connection add type ethernet ifname veth2 \
      master bond0 slave-type bond con-name veth2+

# The bond connection has a static IP, for which the DNS server has a
# static entry.
nmcli connection add type bond ifname bond0 \
      con-name bond0+ ipv6.method disabled \
      ipv4.method manual ipv4.address 172.25.1.101/24 \
      ipv4.gateway 172.25.1.1 ipv4.dns 172.25.1.1 \
      mode balance-rr connection.autoconnect-slaves yes

nmcli connection up bond0+

sleep 4

echo "* Hostname is: $(hostname)"

# Bring carrier up on veth0 and veth2
ip -n ns1 link set veth1 up
ip -n ns1 link set veth3 up

sleep 10

if [ "$(hostname)" != client1234 ]; then
    echo "ERROR: wrong hostname $(hostname)"
    exit 1
fi
