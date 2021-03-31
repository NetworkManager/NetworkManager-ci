#!/bin/sh

# 1. make veth managed by changing /usr/lib/udev/rules.d/85-nm-unmanaged.rules
# 2. check that DHCP connections are generated by NM for veths (uninstall NM-config-server package)

die() {
    cleanup_dev
    nmcli con del "Wired connection "{1..40}
    exit 1
}

cleanup_dev() {
    echo "Cleanup"
    for i in {1..20}; do
        ip link del veth$i
    done
}

wait_for_con() {
  for i in {1..20}; do
      nmcli -t c | grep -q "$1:" && return
      sleep 0.5
  done
  echo "Connection '$1' does not exist:"
  nmcli c | cat
  die
}

wait_for_con() {
  for i in {1..20}; do
      nmcli -t c | grep -q "$1:" && return 0
      sleep 0.5
  done
  echo "Connection '$1' does not exist:"
  nmcli c | cat
  die
}

wait_for_not_con() {
  for i in {1..20}; do
      nmcli -t c | grep -q "$1:" || return 0
      sleep 0.5
  done
  echo "Connection '$1' still exist:"
  nmcli c | cat
  die
}

echo "Create devices"
for i in {1..20}; do
    ip l add veth$i type veth peer name veth${i}p
    ip l set veth$i up
    ip l set veth${i}p up
    sleep 0.2
done

echo "Wait for connections"
time for i in {1..40}; do
    wait_for_con "Wired connection $i"
done

cleanup_dev

echo "Wait until connections disappears"
time for i in {1..40}; do
    wait_for_not_con "Wired connection $i"
done
