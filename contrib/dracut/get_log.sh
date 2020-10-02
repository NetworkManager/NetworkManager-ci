#!/bin/bash

# redirect stderr to stdout
exec 2>&1

cd /tmp/dracut_test/

log_type="$1"
shift

if [[ "$log_type" == "nfs" ]]; then
  mkdir mnt
  mount server.ext3 mnt/

  journalctl --root=mnt/nfs/client/ -b --no-pager $@

  umount mnt
  rmdir mnt
elif [[ "$log_type" == "iscsi_single" ]]; then
  mkdir mnt
  mount root.ext3 mnt/

  journalctl --root=mnt/ -b --no-pager $@

  umount mnt
  rmdir mnt
elif [[ "$log_type" == "iscsi_raid" ]]; then
  mkdir mnt
  losetup -f ./iscsidisk2.img
  iscsi_loop2="$(losetup -j ./iscsidisk2.img)"
  iscsi_loop2=${iscsi_loop2%%:*}
  losetup -f ./iscsidisk3.img
  iscsi_loop3="$(losetup -j ./iscsidisk3.img)"
  iscsi_loop3=${iscsi_loop3%%:*}
  mdadm --assemble /dev/md0 $iscsi_loop2 $iscsi_loop3
  vgchange -a y dracutNMtest
  mount /dev/dracutNMtest/root mnt/

  journalctl --root=mnt/ -b --no-pager $@

  umount mnt
  rmdir mnt
  lvchange -a n /dev/dracutNMtest/root
  mdadm --stop /dev/md0
  losetup -d $iscsi_loop2
  losetup -d $iscsi_loop3
else
  echo "Unrecognized type: $log_type"
fi
