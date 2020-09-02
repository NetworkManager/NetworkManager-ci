#!/bin/sh
exec </dev/console >/dev/console 2>&1
set -x
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
export TERM=linux
export PS1='nfstest-server:\w\$ '
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
wait_for_if_link 52:54:00:12:34:60 ens4
wait_for_if_link 52:54:00:12:34:61 ens5
wait_for_if_link 52:54:00:12:34:62 ens6

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
#bond@ens4+ens5
modprobe --first-time bonding
ip link add bond0 type bond
ip link set bond0 type bond miimon 100 mode active-backup
ip link set ens4 down
ip link set ens4 master bond0
ip link set ens5 down
ip link set ens5 master bond0
ip link set bond0 up
ip addr add 192.168.53.1/24 dev bond0
#vlan47@ens6
modprobe ipvlan
modprobe macvlan
modprobe 8021q
ip link add link ens6 name ens6.47 type vlan id 47
ip link set dev ens6.47 up
ip addr add 192.168.54.1/24 dev ens6.47
#vlan48@bond0
ip link add link bond0 name bond0.48 type vlan id 48
ip link set dev bond0.48 up
ip addr add 192.168.55.1/24 dev bond0.48

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
