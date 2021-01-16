#!/bin/bash
export PATH=/sbin:/bin:/usr/sbin:/usr/bin

UUID_STATE=a32d3ed2-225f-11eb-bf6a-525400c7ed04
UUID_CHECK=a467c808-225f-11eb-96df-525400c7ed04

DEV_STATE=/dev/disk/by-uuid/$UUID_STATE
DEV_CHECK=/dev/disk/by-uuid/$UUID_CHECK

# boot succeeded, so try to attach logs
echo BOOT | dd status=none oflag=direct,dsync of=${DEV_STATE}

/core_pattern_setup

# load check library
mkdir -p /check_lib
mount ${DEV_CHECK} /check_lib
for script in /check_lib/*.sh; do
  source "$script" || ( echo "$script failed to load"; poweroff -f )
done

mount_list

echo "== ls initrd ifcfg =="
ls -la /run/initramfs/state/etc/sysconfig/network-scripts

for file in $(find /run/initramfs/state/etc/sysconfig/network-scripts -type f); do
    echo "== $file =="
    cat $file
done

echo "== checking services =="
for service in import-state dbus NetworkManager systemd-hostnamed; do
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

echo "== ls ifcfg =="
ls -la /etc/sysconfig/network-scripts/

for file in $(find /etc/sysconfig/network-scripts/ -type f); do
    echo "== $file =="
    cat $file
done

nmcli_list

echo "== checks #1 =="
client_check || die "client_check did not exit with 0"
wait  # wait for ip_renew tests to finish
echo "== checks #2 =="
client_check || die "client_check did not exit with 0"

/check_core_dumps

# client_check should "die" if failed
echo PASS | dd status=none oflag=direct,dsync of=${DEV_STATE}

# cleanup after succes
clean_root

echo "PASS"

poweroff -f
