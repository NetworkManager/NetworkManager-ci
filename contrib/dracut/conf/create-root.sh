#!/bin/sh

finish() {
  mount
  lsblk
  umount /source
  umount /sysroot
  lvm lvchange -a n /dev/dracut/root
  mdadm --stop /dev/md0
  mount
  lsblk
}

die() {
  finish
  exit 1
}

set -x
echo "Creating iSCSI RAID0 root"
for x in 64-lvm.rules 70-mdadm.rules 99-mount-rules; do
    > "/etc/udev/rules.d/$x"
done
rm -f -- /etc/lvm/lvm.conf
udevadm control --reload
mkdir -p /source
mount /dev/sda /source
mkdir -p /sysroot
mdadm --create /dev/md0 --run --auto=yes --level=stripe --raid-devices=2 /dev/sdc /dev/sdd || die
mdadm -W /dev/md0
lvm pvcreate -ff  -y /dev/md0
lvm vgcreate dracut /dev/md0
lvm lvcreate -y -l 100%FREE -n root dracut
lvm vgchange -ay
mkfs.ext3 -j -L sysroot /dev/dracut/root
mount /dev/dracut/root /sysroot
cp -a -t /sysroot /source/nfs/client/* || die
finish
echo "iSCSI RAID0 root complete"
