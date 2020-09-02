die() {
    echo "[FAIL] $@"
    echo FAIL | dd oflag=direct,dsync of=/dev/sda
    clean_root
    poweroff -f
}

arg() {
    shift $1
    echo $1
}

clean_root() {
  rm -rf /etc/sysconfig/network-scripts/ifcg*
}

nfs_server() {
    local nfs_mnt
    nfs_mnt=$(mount | grep "type nfs")
    nfs_mnt=$(arg 1 $nfs_mnt)
    nfs_mnt=${nfs_mnt%:*}
    [[ $nfs_mnt == "$1" ]] || die "fstype of / is '$root_mnt', expected '$1'"
}

mount_root_type() {
    local root_mnt
    root_mnt=$(mount | grep " / type ")
    root_mnt=$(arg 5 $root_mnt)
    [[ $root_mnt == "$1" ]] || die "fstype of / is '$root_mnt', expected '$1'"
}
