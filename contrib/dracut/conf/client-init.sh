#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin

# include vars
. /vars.sh

# load check library
mkdir -p /check_lib
mount -o ro,norecovery,noatime ${DEV_CHECK} /check_lib
for script in /check_lib/*.sh; do
  source "$script" || ( echo "$script failed to load"; poweroff)
done
# boot succeeded, log it
vm_state BOOT

core_pattern_setup

mount_list

echo "== checking services =="
for service in dbus NetworkManager; do
    for i in {1..15}; do
        systemctl is-active $service.service | grep -q ^active && \
            break
        sleep 1
    done

    systemctl is-active $service.service | grep -q ^active || \
        die "$service.service failed: $(echo; systemctl status $service.service)"
    echo "[OK] $service.service is active"
done

echo "== NetworkManager --version =="
NetworkManager --version

echo "== NetworkManager --print-config =="
NetworkManager --print-config

verbose_ls_dir /run/initramfs/state/etc/sysconfig/network-scripts
verbose_ls_dir /etc/sysconfig/network-scripts/
verbose_ls_dir /etc/NetworkManager/system-connections
verbose_ls_dir /run/NetworkManager/
verbose_ls_dir /usr/lib/NetworkManager/

nmcli_list

echo "== checks #1 =="
client_check || die "client_check did not exit with 0"
my_wait  # wait for ip_renew tests to finish
echo "== checks #2 =="
client_check || die "client_check did not exit with 0"

check_core_dumps

# client_check should "die" if failed
vm_state PASS

# cleanup after succes
clean_root

poweroff
