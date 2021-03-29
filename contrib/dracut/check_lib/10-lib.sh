# general checks and functions

die() {
  die_cmd "$@" 1>&2
}


die_cmd() {
  echo "[FAIL] $@"
  echo FAIL | dd status=none oflag=direct,dsync of=${DEV_STATE}
  /check_core_dumps
  echo "== dump state after fail =="
  ip_list
  nmcli_list
  clean_root
  poweroff -f
}


arg() {
  shift $1
  echo $1
}


clean_root() {
  echo "== cleaning ifcfg =="
  rm -vrf /etc/sysconfig/network-scripts/ifcfg*
  echo "== cleaning /var/run/NetworkManager/ =="
  rm -vrf /var/run/NetworkManager/*
  echo "== cleaning check script =="
  rm -vf /check.sh
  echo "== cleaning resolv.conf =="
  rm -vf /etc/resolv.conf
  echo "== cleaning hostname =="
  echo > /etc/hostname
  echo "== cleaning (and dumping) journal =="
  copy_journal
  echo "== sync =="
  sync
  echo "done"
}

copy_journal() {
  mkdir -p /mnt/dumps
  mount $DEV_DUMPS /mnt/dumps
  mkdir -p /mnt/dumps/var/log
  du -sch /var/log/journal
  df -h
  cp -r /var/log/journal /mnt/dumps/var/log/
  df -h
  umount /mnt/dumps/
  rm -rvf /var/log/journal
}


mount_list() {
  echo "== nfs mounts =="
  mount | grep nfs
  echo "== ext3 mounts =="
  mount | grep ext3
}


NM_logs() {
  echo "== NM logs =="
  time journalctl -b -u NetworkManager --no-pager -o cat
}


nfs_server() {
    local nfs_mnt
    nfs_mnt=$(mount | grep "type nfs")
    nfs_mnt=$(arg 1 $nfs_mnt)
    nfs_mnt=${nfs_mnt%:*}
    [[ "$nfs_mnt" == "$1" ]] || die "NFS server is '$nfs_mnt', expected '$1'"
    echo "[OK] NFS server is '$nfs_mnt'"
}


mount_root_type() {
    local root_mnt
    root_mnt=$(mount | grep " / type ")
    root_mnt=$(arg 5 $root_mnt)
    [[ "$root_mnt" == "$1" ]] || die "fstype of / is '$root_mnt', expected '$1'"
}


no_ifcfg() {
  find /etc/sysconfig/network-scripts/ifcfg-* &> /dev/null && \
    die "ifcfg file exists: $(echo; find /etc/sysconfig/network-scripts/ifcfg-*)"
  echo "[OK] no ifcfg file exists"
}


hostname_check() {
  local hostname
  hostname=$(cat /proc/sys/kernel/hostname)
  [[ "$hostname" == "$1" ]] || die "hostname is not '$1', but '$hostname'"
  echo "[OK] hostname is '$hostname'"
}


dns_search() {
    local search
    search=$(grep "^search" /etc/resolv.conf | sed 's/^search\s\+//g')
    [[ "$search" == $1 ]] || die "DNS search is '$search', expected '$1'"
    echo "[OK] DNS search '$search' is '$1'"
}


ifname_mac() {
    local mac
    mac=$(ip l show "$1" | grep "link/ether" | sed 's@\s\+link/ether\s\+\(\([0-9a-f]\+:\)\+[0-9a-f]\+\).*@\1@')
    [[ "$mac" == "$2" ]] || die "'$1' MAC is '$mac', expected '$2'"
    echo "[OK] '$1' MAC is '$mac'"
}


dracut_crash_test() {
    # TODO: install crashing binary (eg. derefrence null) and let it crash
    echo "This is not dump file! It's purpose is to test crash detection." > /tmp/dumps/dump_dracut_crash_test
}


ifname_mtu() {
    local mtu
    mtu=$(ip -o l show "$1" | sed 's@.*mtu \([0-9]*\).*@\1@')
    [[ "$mtu" == "$2" ]] || die "'$1' MTU is '$mtu', expected '$2'"
    echo "[OK] '$1' MTU is '$mtu'"
}
