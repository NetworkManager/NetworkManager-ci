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

ip_list

echo "== ls initrd ifcfg =="
ls -la /run/initramfs/state/etc/sysconfig/network-scripts

for file in $(find /run/initramfs/state/etc/sysconfig/network-scripts -type f); do
    echo "== $file =="
    cat $file
done

echo "== starting services =="
echo "start import-state (to copy ifcfg files)"
systemctl start import-state.service || die "import-state failed: $(echo; systemctl status import-state.service)"
echo "start dbus"
systemctl start dbus.service || die "dbus failed: $(echo; systemctl status dbus.service)"
echo "start NetworkManager"
systemctl start NetworkManager.service || die "NetworkManager failed: $(echo; systemctl status NetworkManager.service)"
echo "start systemd-hostnamed"
systemctl start systemd-hostnamed.service || die "systemd-hostnamed failed: $(echo; systemctl status systemd-hostnamed.service)"
echo "OK"

echo "== ls ifcfg =="
ls -la /etc/sysconfig/network-scripts/

for file in $(find /etc/sysconfig/network-scripts/ -type f); do
    echo "== $file =="
    cat $file
done

ip_list

nmcli_list

echo "== checks =="
client_check || die "client_check did not exit with 0"

/check_core_dumps

# client_check should "die" if failed
echo PASS | dd status=none oflag=direct,dsync of=${DEV_STATE}

# cleanup after succes
clean_root

echo "PASS"

poweroff -f
