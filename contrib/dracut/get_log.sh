#!/bin/bash

usage() {
  cat << EOF
USGAE: $0 test_type output_file1 options1 [ output_file 2 options2 ...]

Get client's journal log from NFS/iSCSI server, clean journal afterwards.

  test_type: where to search for logs (nfs|iscsi_single|iscsi_raid)
  output_fileX: output file for gathered logs
  optionsX: journalctl options to filter the logs for output_fileX (e.g. "-u NetworkManager -o cat")

EOF
  exit 1
}

# redirect stderr to stdout
exec 2>&1

cd /tmp/dracut_test/

test_type="$1"
shift

dump_logs() {
  journalctl --root=mnt/ -b --no-pager $args &> "$ofile"
}

# mount client FS based on test type
if [[ "$test_type" == "nfs" ]]; then
  ln -s nfs/client/ mnt

elif [[ "$test_type" == "iscsi_single" ]]; then
  mkdir mnt
  mount root.ext3 mnt/

elif [[ "$test_type" == "iscsi_raid" ]]; then
  mkdir mnt
  iscsi_loop2="$(losetup -j ./iscsidisk2.img)"
  iscsi_loop2=${iscsi_loop2%%:*}
  iscsi_loop3="$(losetup -j ./iscsidisk3.img)"
  iscsi_loop3=${iscsi_loop3%%:*}
  mdadm --assemble /dev/md0 $iscsi_loop2 $iscsi_loop3
  vgchange -a y dracutNMtest
  mount /dev/dracutNMtest/root mnt/

else
  echo "Unrecognized type: $test_type"
  usage
fi

# loop through args
while [[ -n "$1" ]]; do
  ofile=$1
  args=$2
  shift 2
  dump_logs
done

echo "== before clean =="
ls -lh mnt/var/log/journal
df -h mnt/

# clean logs
rm -rf mnt/var/log/journal/*

echo "== after clean =="
ls -lh mnt/var/log/journal
df -h mnt/

# umount client
if [[ "$test_type" == "nfs" ]]; then
  rm -f mnt

elif [[ "$test_type" == "iscsi_single" ]]; then
  umount mnt
  rmdir mnt

elif [[ "$test_type" == "iscsi_raid" ]]; then
  umount mnt
  rmdir mnt
  lvchange -a n /dev/dracutNMtest/root
  mdadm --stop /dev/md0
  losetup -d $iscsi_loop2
  losetup -d $iscsi_loop3
fi
