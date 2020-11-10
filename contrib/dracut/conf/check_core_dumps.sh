#!/bin/sh

UUID_DUMPS=a6673314-225f-11eb-a9a2-525400c7ed04
DEV_DUMPS=/dev/disk/by-uuid/$UUID_DUMPS


copy_dumps() {
    mkdir -p /mnt/dumps
    mount $DEV_DUMPS /mnt/dumps
    cp /tmp/dumps/dump_* /mnt/dumps/
    umount /mnt/dumps/
    poweroff -f
}

echo "Checking for coredumps, core_pattern:" 1>&2
cat /proc/sys/kernel/core_pattern 1>&2

for dump in /tmp/dumps/dump_* ; do
    [ -f "$dump" ] && copy_dumps
done

echo "No coredumps found" 1>&2
