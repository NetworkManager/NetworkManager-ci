# general checks and functions

die() {
  die_cmd "$@" 1>&2
}


die_cmd() {
  echo "[FAIL] $@"
  vm_state FAIL
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
  echo "== sync =="
  sync
  echo "done"
}


vm_state() {
  echo "== $1 =="
  ls -l /var/log/
  [ -f /var/log/vm_state ] || remount_var_log
  echo $1 > /var/log/vm_state
  sync
}

remount_var_log() {
  echo "Warning: remounting log, something bad happened!"
  umount /var/log || true
  mount $DEV_LOG /var/log
}

core_pattern_setup() {
  # mount to /var/log which is local FS (mounted disk) to prevent deadlock
  mkdir -p /var/log/dumps/
  mount $DEV_DUMPS /var/log/dumps/
  echo "Setting core_pattern to /var/log/dumps/dump_*"
  echo "/var/log/dumps/dump_%e-%P-%u-%g-%s-%t-%c-%h" > /proc/sys/kernel/core_pattern
}

check_core_dumps() {
  echo "Checking for coredumps, core_pattern:"
  cat /proc/sys/kernel/core_pattern

  for dump in /var/log/dumps/dump_* ; do
    if [ -f "$dump" ]; then
      echo -e "[FAIL] Found core dumps:\n$(ls -l /var/log/dumps/dump_*)"
      return
    fi
  done
  echo "[OK] No coredumps found"
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
    # check for file in /var/log - it gets cleared after the test
    [ -f /var/log/sleep_crashed ] && return
    echo > /var/log/sleep_crashed
    echo "Crashing sleep..."
    sleep 10 &
    sleep 1
    kill -SIGSEGV $!
}


ifname_mtu() {
    local mtu
    mtu=$(ip -o l show "$1" | sed 's@.*mtu \([0-9]*\).*@\1@')
    [[ "$mtu" == "$2" ]] || die "'$1' MTU is '$mtu', expected '$2'"
    echo "[OK] '$1' MTU is '$mtu'"
}


my_wait() {
    local jobs
    while true; do
        jobs=$(jobs | grep -v "Done")
        echo "  $jobs"
        [ -z "$jobs" ] && break
        sleep 1
    done
}
