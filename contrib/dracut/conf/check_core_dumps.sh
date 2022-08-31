#!/bin/sh

UUID_DUMPS=a6673314-225f-11eb-a9a2-525400c7ed04
DEV_DUMPS=/dev/disk/by-uuid/$UUID_DUMPS


move_dumps() {
    mkdir -p /mnt/dumps
    mount $DEV_DUMPS /mnt/dumps
    mv /run/dumps/dump_* /mnt/dumps/
    umount /mnt/dumps/
}

echo "Checking for coredumps, core_pattern:" 1>&2
cat /proc/sys/kernel/core_pattern 1>&2

for dump in /run/dumps/dump_* ; do
    [ -f "$dump" ] && move_dumps
    break
done

echo "No coredumps found" 1>&2
