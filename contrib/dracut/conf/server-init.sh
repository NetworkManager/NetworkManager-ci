#!/bin/bash
set -x
exec &> >(/sbin/logger)
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
stty sane
echo "made it to the rootfs!"
echo server > /proc/sys/kernel/hostname


wait_for_if_link() {
    local cnt=0
    local li
    while [ $cnt -lt 600 ]; do
        li=$(ip -o link | grep "$1")
	      [ -n "$li" ] && rename_if_link $2 $li && return 0
        sleep 0.1
        cnt=$(($cnt+1))
    done
    poweroff -f
}

rename_if_link() {
    local new_name=$1
    local old_name=${3%:}
    if [[ "$new_name" != "$old_name" ]]; then
        ip link set $old_name down && \
        ip link set $old_name name $new_name
    fi
    ip link set $new_name up
}

ip a

wait_for_if_link 52:54:00:12:34:56 ens1
wait_for_if_link 52:54:00:12:34:57 ens2
wait_for_if_link 52:54:00:12:34:58 ens3
wait_for_if_link 52:54:00:12:34:61 ens4
wait_for_if_link 52:54:00:12:34:62 ens5
wait_for_if_link 52:54:00:12:34:63 ens6
wait_for_if_link 52:54:00:12:34:64 ens7
wait_for_if_link 52:54:00:12:34:65 ens8
wait_for_if_link 52:54:00:12:34:66 ens9
wait_for_if_link 52:54:00:12:34:67 ens10

ip a

#nfs
ip addr add 127.0.0.1/8 dev lo
ip link set lo up
ip addr add 192.168.50.1/24 dev ens1
ip addr add 192.168.50.2/24 dev ens1
ip addr add 192.168.50.3/24 dev ens1
ip -6 addr add deaf:beef::1/64 dev ens1
ip -6 route add default via deaf:beef::aa dev ens1
#iscsi
ip addr add 192.168.51.1/24 dev ens2
ip addr add 192.168.52.1/24 dev ens3
modprobe --first-time bonding
#bond@ens4+ens5
ip link add bond0 type bond
ip link set bond0 type bond mode balance-rr
ip link set ens4 down
ip link set ens4 master bond0
ip link set ens5 down
ip link set ens5 master bond0
ip link set bond0 up
ip addr add 192.168.53.1/24 dev bond0
#bond1@ens6+ens7
ip link add bond1 type bond
ip link set bond1 type bond mode balance-rr
ip link set ens6 down
ip link set ens6 master bond1
ip link set ens7 down
ip link set ens7 master bond1
ip link set bond1 up
ip addr add 192.168.54.1/24 dev bond1
modprobe ipvlan
modprobe macvlan
modprobe 8021q
#vlan5@ens10
ip link add link ens10 name ens10.5 type vlan id 5
ip link set dev ens10.5 up
ip addr add 192.168.55.5/30 dev ens10.5
#vlan9@ens10
ip link add link ens10 name ens10.9 type vlan id 9
ip link set dev ens10.9 up
ip addr add 192.168.55.9/30 dev ens10.9
#vlan13@bond0
ip link add link bond0 name bond0.13 type vlan id 13
ip link set dev bond0.13 up
ip addr add 192.168.55.13/30 dev bond0.13
#vlan17@bond1
ip link add link bond1 name bond1.17 type vlan id 17
ip link set dev bond1.17 up
ip addr add 192.168.55.17/30 dev bond1.17
#vlan33@ens8
ip link add link ens8 name ens8.33 type vlan id 33
ip link set dev ens8.33 up
ip addr add 192.168.55.33/29 dev ens8.33
#vlan33@ens9
ip link add link ens9 name ens9.33 type vlan id 33
ip link set dev ens9.33 up
ip addr add 192.168.55.34/29 dev ens9.33


ip a

#nfs
modprobe af_packet
mount --bind /nfs/client /nfs/nfs3-5
mount --bind /nfs/client /nfs/ip/192.168.50.101
mount --bind /nfs/client /nfs/tftpboot/nfs4-5
modprobe sunrpc
mount -t rpc_pipefs sunrpc /var/lib/nfs/rpc_pipefs
[ -x /sbin/portmap ] && portmap
mkdir -p /run/rpcbind
[ -x /sbin/rpcbind ] && rpcbind
modprobe nfsd
mount -t nfsd nfsd /proc/fs/nfsd
exportfs -r
rpc.nfsd
rpc.mountd
rpc.idmapd
exportfs -r
mkdir -p /var/lib/dhcpd
>/var/lib/dhcpd/dhcpd.leases
>/var/lib/dhcpd/dhcpd6.leases
chmod 777 /var/lib/dhcpd/dhcpd.leases
chmod 777 /var/lib/dhcpd/dhcpd6.leases
rm -f /var/run/dhcpd.pid
dhcpd -d -cf /etc/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases &
dhcpd -6 -d -cf /etc/dhcpd6.conf -lf /var/lib/dhcpd/dhcpd6.leases &
mkdir /run/radvd
chown radvd:radvd /run/radvd
radvd -u radvd -m stderr

#iscsi server
tgtd
tgtadm --lld iscsi --mode target --op new --tid 1 --targetname iqn.2009-06.dracut:target0
tgtadm --lld iscsi --mode target --op new --tid 2 --targetname iqn.2009-06.dracut:target1
tgtadm --lld iscsi --mode target --op new --tid 3 --targetname iqn.2009-06.dracut:target2
tgtadm --lld iscsi --mode logicalunit --op new --tid 1 --lun 1 -b /dev/sdb
tgtadm --lld iscsi --mode logicalunit --op new --tid 2 --lun 2 -b /dev/sdc
tgtadm --lld iscsi --mode logicalunit --op new --tid 3 --lun 3 -b /dev/sdd
tgtadm --lld iscsi --mode target --op bind --tid 1 -I 192.168.51.101
tgtadm --lld iscsi --mode target --op bind --tid 2 -I 192.168.52.101
tgtadm --lld iscsi --mode target --op bind --tid 3 -I 192.168.51.101

echo "Serving NFS and iSCSI mounts"

while :; do
	jobs -rp
	sleep 10
done
mount -n -o remount,ro /
poweroff -f
