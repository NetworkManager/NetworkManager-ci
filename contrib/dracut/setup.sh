#!/bin/bash

# load variables, might be called from NetworkManager-ci, or contrib/dracut
. ./contrib/dracut/vars.sh || . ./vars.sh

test_setup() {
  # Exit if setup is already done
  [ -f /tmp/dracut_setup_done ] && network_check && return 0

  # if setup done but network is missing (after crash)
  # do not compile initrd again, just refresh network setup
  if [ -f /tmp/dracut_setup_done ] ; then
      kill_server
      network_clean
      network_setup
      if ! run_server; then
          echo "Failed to start server" 1>&2
          network_clean
          kill_server
          rm /tmp/dracut_setup_done
          return 1
      fi
      return 0
  fi

  network_setup

  [ -x /etc/qemu-ifdown ] || {
      echo '#!/bin/sh' > /etc/qemu-ifdown;
      chmod +x /etc/qemu-ifdown;
  }


  # patch dracut NM module
  DRACUT_NM_INITRD=/usr/lib/dracut/modules.d/35network-manager/nm-initrd.service
  if ! grep -F "After=dbus.service" $DRACUT_NM_INITRD; then
    sed -i 's/After=dracut-cmdline.service/After=dracut-cmdline.service\nAfter=dbus.service/' $DRACUT_NM_INITRD
  fi

  cp -fa conf/smart_sleep.py /usr/local/bin/smart_sleep
  chmod +x /usr/local/bin/smart_sleep


  basedir=/usr/lib/dracut/

  if ! command -v tgtd &>/dev/null || ! command -v tgtadm &>/dev/null; then
      echo "Need tgtd and tgtadm from scsi-target-utils"
      return 1
  fi

  export initdir=$TESTDIR/nfs/client
  mkdir $TESTDIR
  mkdir -p $initdir

  ./prepare_nfsroot_from_image.sh || exit 1

  # install the same repos
  . /etc/os-release
  rsync -a /etc/yum.repos.d/ $initdir/etc/yum.repos.d

  # update centos to latests rpms
  if [ "$ID" == "centos" ]; then
      dnf -y --installroot=$initdir --releasever=${VERSION_ID%.*} update
  fi

  cp -fa /etc/machine-id $initdir/etc/machine-id

  echo "/dev/nfs / nfs defaults 1 1" > $initdir/etc/fstab
  echo "$DEV_LOG /var/log/ ext4 x-initrd.mount,defaults 1 1" >> $initdir/etc/fstab

  cp -fa ./conf/check_core_dumps.sh $initdir/check_core_dumps
  cp -fa ./conf/core_pattern_setup.sh $initdir/core_pattern_setup

  for file in passwd shadow group; do
    cp -fa /etc/$file $initdir/etc/$file
  done


  rsync -a /etc/ssh/ $initdir/etc/ssh
  rsync -a /root/.ssh/ $initdir/root/.ssh

  # enable persistent journal
  cp -af /etc/systemd/journald.conf $initdir/etc/systemd/journald.conf
  # make persisten journal directory
  mkdir -p $initdir/var/log/journal

  # copy systemd limits to catch coredumps, add config to overwrite default
  cp -af /etc/systemd/system.conf $initdir/etc/systemd/system.conf
  cp -af /etc/security/limits.conf $initdir/etc/security/limits.conf
  mkdir -p $initdir/etc/security/limits.d
  echo "* - core unlimited" >  $initdir/etc/security/90-dracut_nmci.conf

  > $initdir/etc/environment
  # empty hostname
  > $initdir/etc/hostname

  # copy dracut variables
  cp -fa ./vars.sh $initdir/vars.sh

  # copy testsuite script
  cp -fa ./conf/client-init.sh $initdir/sbin/test-init

  # setup the testsuite service
  cat >$initdir/etc/systemd/system/testsuite.service <<EOF
[Unit]
Description=Testsuite service
After=network-online.target
Wants=import-state.service
Wants=NetworkManager.service
Wants=systemd-hostnamed.service

[Service]
ExecStart=/sbin/test-init
Type=oneshot
StandardOutput=journal+console
StandardError=journal+console

[Install]
RequiredBy=multi-user.target
EOF

  systemctl --root "$initdir" enable testsuite.service

  du -sch $initdir

  # install NetworkManager-* to the nfsroot

  rpm_list=""
  for rpm in $(rpm -qa | grep NetworkManager | grep -v gnome); do
    found=0
    for nm_build_path in "/"{root,tmp}"/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"{noarch,$(arch)}"/" "/root/rpms/"; do
      if [ -f "$nm_build_path$rpm.rpm" ]; then
        rpm_list="$rpm_list $nm_build_path$rpm.rpm"
        found=1
        break
      fi
    done
    [ "$found" == 1 ] || rpm_list="$rpm_list $rpm"
  done

  # Install running kernel to the image (missing modules)
  rpm_list="$rpm_list $(rpm -qa | grep ^kernel | grep -F "$(uname -r)" )"

  # dnf5 only args
  which dnf5 && skip_unavail="--skip-unavailable"
  # Override --releasever, as epel repofile does not work with --inistallroot
  dnf -y --installroot=$initdir --releasever=${VERSION_ID%.*} install $rpm_list --skip-broken $skip_unavail
  du -sch $initdir

  dnf --installroot=$initdir clean all
  du -sch $initdir

  # Check installed NM is the same
  nm_local="$(rpm -q NetworkManager)"
  nm_nfs="$(rpm --root=$initdir -q NetworkManager)"

  if ! [ "$nm_local" == "$nm_nfs" ]; then
    echo "Unable to install NetworkManager to nfsroot: got $nm_nfs, expected $nm_local"
    exit 1
  fi

  # Enable NM debug
  cp -fa /etc/NetworkManager/conf.d/95-nmci-test.conf $initdir/etc/NetworkManager/conf.d/95-nmci-test.conf

  # clean any NM connection that might be in the image
  rm -rf $initdir/etc/NetworkManager/system-connections/*
  rm -rf $initdir/etc/sysconfig/network-scripts/ifcfg-*

  systemctl --root "$initdir" enable import-state.service
  systemctl --root "$initdir" enable dbus.service
  systemctl --root "$initdir" enable NetworkManager.service
  systemctl --root "$initdir" enable systemd-hostnamed.service


  # creare iscsi images
  mkdir -p $TESTDIR/nfs/nfs3-5
  mkdir -p $TESTDIR/nfs/ip/192.168.50.101
  mkdir -p $TESTDIR/nfs/tftpboot/nfs4-5

  dd if=/dev/zero of=$TESTDIR/client_log.img bs=1M count=200
  dd if=/dev/zero of=$TESTDIR/client_check.img bs=1M count=20
  dd if=/dev/zero of=$TESTDIR/client_dumps.img bs=1M count=200
  mkfs.ext4 -U $UUID_LOG $TESTDIR/client_log.img
  mkfs.ext4 -U $UUID_CHECK $TESTDIR/client_check.img
  mkfs.ext4 -U $UUID_DUMPS $TESTDIR/client_dumps.img
  sync; sync; sync
  mkdir -p $TESTDIR/client_log/var/log/
  mkdir $TESTDIR/client_check
  mkdir $TESTDIR/client_dumps

  # Create the blank file to use as a root iSCSI filesystem
  dd if=/dev/zero of=$TESTDIR/root.ext4 bs=1M count=2800
  dd if=/dev/zero of=$TESTDIR/iscsidisk2.img bs=1M count=1400
  dd if=/dev/zero of=$TESTDIR/iscsidisk3.img bs=1M count=1400

  # copy client files to root filesystem
  mkfs.ext4 -j -L singleroot -F $TESTDIR/root.ext4
  losetup -f $TESTDIR/root.ext4
  iscsi_loop1="$(losetup -j $TESTDIR/root.ext4)"
  iscsi_loop1=${iscsi_loop1%%:*}
  mkdir $TESTDIR/mnt_root
  mount $iscsi_loop1 $TESTDIR/mnt_root
  rsync -a $TESTDIR/nfs/client/ $TESTDIR/mnt_root  || echo "WARNING! rsync to iSCSI failed!"
  umount $TESTDIR/mnt_root

  (
    losetup -f $TESTDIR/iscsidisk2.img
    iscsi_loop2="$(losetup -j $TESTDIR/iscsidisk2.img)"
    iscsi_loop2=${iscsi_loop2%%:*}
    losetup -f $TESTDIR/iscsidisk3.img
    iscsi_loop3="$(losetup -j $TESTDIR/iscsidisk3.img)"
    iscsi_loop3=${iscsi_loop3%%:*}
    mdadm --create /dev/md0 --run --auto=yes --level=stripe --raid-devices=2 $iscsi_loop2 $iscsi_loop3 || exit 1
    mdadm -W /dev/md0
    lvm pvcreate -ff  -y /dev/md0
    lvm vgcreate dracutNMtest /dev/md0
    lvm lvcreate -y -l 100%FREE -n root dracutNMtest
    lvm vgchange -ay
    mkfs.ext4 -j -L sysroot /dev/dracutNMtest/root
    mount /dev/dracutNMtest/root $TESTDIR/mnt_root
    rsync -a $TESTDIR/nfs/client/ $TESTDIR/mnt_root || echo "WARNING! rsync to iSCSI raid failed!"
  )

  umount $TESTDIR/mnt_root
  lvm lvchange -a n /dev/dracutNMtest/root
  mdadm --stop /dev/md0
  rmdir $TESTDIR/mnt_root

  KVERSION=${KVERSION-$(uname -r)}

  # client initramfs with NM module
  mkdir $TESTDIR/overlay-client
  (
     set +x
     export initdir=$TESTDIR/overlay-client
     . $basedir/dracut-init.sh
     inst /etc/machine-id
     inst_multiple poweroff shutdown mount umount mv mkdir
     inst_hook shutdown-emergency 000 ./conf/hard-off.sh
     inst_hook emergency 000 ./conf/hard-off.sh
     # set core_pattern at the very beginning
     inst_hook cmdline 00 ./conf/core_pattern_setup.sh
     # add check to every dracut hook
     inst_hook pre-udev 99 ./conf/check_core_dumps.sh
     inst_hook pre-trigger 99 ./conf/check_core_dumps.sh
     inst_hook initqueue/settled 99 ./conf/check_core_dumps.sh
     inst_hook initqueue/timeout 99 ./conf/check_core_dumps.sh
     inst_hook initqueue/online 99 ./conf/check_core_dumps.sh
     inst_hook initqueue/finished 99 ./conf/check_core_dumps.sh
     inst_hook pre-mount 99 ./conf/check_core_dumps.sh
     inst_hook mount 99 ./conf/check_core_dumps.sh
     inst_hook pre-pivot 99 ./conf/check_core_dumps.sh
     inst_hook cleanup 99 ./conf/check_core_dumps.sh
     inst_simple ./conf/99-default.link /etc/systemd/network/99-default.link
  ) || exit 1

  # Make NFS client's dracut image using NM module
  dracut -i $TESTDIR/overlay-client / \
         -o "plymouth dash dmraid network-legacy" \
         -a "debug network-manager ifcfg" \
         -d "8021q ipvlan macvlan bonding af_packet piix ext4 ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc" \
         --no-hostonly-cmdline -N --no-compress \
         -f $TESTDIR/initramfs.client.NM $KVERSION || exit 1

  # Make NFS client's dracut image using legacy network module
  if grep -q 'release 8' /etc/redhat-release; then
      dracut -i $TESTDIR/overlay-client / \
             -o "plymouth dash dmraid network-manager" \
             -a "debug network-legacy ifcfg" \
             -d "8021q ipvlan macvlan bonding af_packet piix ext4 ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc" \
             --no-hostonly-cmdline -N --no-compress \
             -f $TESTDIR/initramfs.client.legacy $KVERSION || exit 1
  fi

  rm -rf -- $TESTDIR/overlay-client

  if ! run_server; then
      echo "Failed to start server" 1>&2
      kill_server
      return 1
  fi

  touch /tmp/dracut_setup_done
}


test_clean() {
  stop_qemu
  kill_server
  umount $TESTDIR/client_log.img 2>&1
  umount $TESTDIR/client_check.img 2>&1
  umount $TESTDIR/client_dumps.img 2>&1
  for file in \
    $TESTDIR/client_log.img \
    $TESTDIR/client_check.img \
    $TESTDIR/client_dumps.img \
    $TESTDIR/root.ext4 \
    $TESTDIR/iscsidisk2.img \
    $TESTDIR/iscsidisk3.img
  do
    loop="$(losetup -j $file)"
    loop=${loop%%:*}
    losetup -d $loop
  done

  rm -rf -- "$TESTDIR"
  echo "dracut testdir $TESTDIR cleaned"
  network_clean
  echo "dracut network bridges cleaned"
  rm -f /tmp/dracut_setup_done
}

reset_images() {
    umount $TESTDIR/client_log.img
    umount $TESTDIR/client_check.img
    umount $TESTDIR/client_dumps.img
    mkfs.ext4 -U $UUID_LOG $TESTDIR/client_log.img
    mkfs.ext4 -U $UUID_CHECK $TESTDIR/client_check.img
    mkfs.ext4 -U $UUID_DUMPS $TESTDIR/client_dumps.img
    sync; sync; sync
}

after_test() {
    stop_dhcpd
    start_dhcpd
    reset_images 2>&1
}


start_nfs() {
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/nfs3-5
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/ip/192.168.50.101
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/tftpboot/nfs4-5
  cp conf/exports /etc/exports
  # set nlm grace period for NFS
  sed -i '/nlm_grace_period/ d' /etc/modprobe.d/lockd.conf
  echo "options lockd nlm_grace_period=10" >> /etc/modprobe.d/lockd.conf
  modprobe -r lockd
  # nfs-server must be stopped when setting grace/lease time
  # but had to be started before, otherwise proc dir is empty
  systemctl start nfs-server
  systemctl stop nfs-server
  proc_dir=/proc/fs/nfsd
  echo 10 > $proc_dir/nfsv4leasetime
  echo 10 > $proc_dir/nfsv4gracetime
  systemctl start nfs-server
  # Next boot can stuck if booted too quickly, wait the grace period
  sleep 10
}


stop_nfs() {
  echo stopping nfs
  systemctl stop nfs-server
  umount $TESTDIR/nfs/nfs3-5
  umount $TESTDIR/nfs/ip/192.168.50.101
  umount $TESTDIR/nfs/tftpboot/nfs4-5
}


start_iscsi() {
  iscsi_loop1="$(losetup -j $TESTDIR/root.ext4)"
  iscsi_loop1=${iscsi_loop1%%:*}
  iscsi_loop2="$(losetup -j $TESTDIR/iscsidisk2.img)"
  iscsi_loop2=${iscsi_loop2%%:*}
  iscsi_loop3="$(losetup -j $TESTDIR/iscsidisk3.img)"
  iscsi_loop3=${iscsi_loop3%%:*}
  tgtd -p $TESTDIR/tgtd.pid

  # retry the first command
  for i in {1..5}; do
    tgtadm --lld iscsi --mode target --op new --tid 1 --targetname iqn.2009-06.dracut:target0 && break
    sleep 2
    false
  done || return 1
  tgtadm --lld iscsi --mode target --op new --tid 2 --targetname iqn.2009-06.dracut:target1
  tgtadm --lld iscsi --mode target --op new --tid 3 --targetname iqn.2009-06.dracut:target2
  tgtadm --lld iscsi --mode logicalunit --op new --tid 1 --lun 1 -b $iscsi_loop1
  tgtadm --lld iscsi --mode logicalunit --op new --tid 2 --lun 2 -b $iscsi_loop2
  tgtadm --lld iscsi --mode logicalunit --op new --tid 3 --lun 3 -b $iscsi_loop3
  tgtadm --lld iscsi --mode target --op bind --tid 1 -I 192.168.51.101
  tgtadm --lld iscsi --mode target --op bind --tid 2 -I 192.168.52.101
  tgtadm --lld iscsi --mode target --op bind --tid 3 -I 192.168.51.101
}


stop_iscsi() {
  echo stopping iscsi
  pkill -9 -F $TESTDIR/tgtd.pid
}


start_dhcpd() {
  mkdir -p /var/lib/dhcpd
  > $TESTDIR/dhcpd.leases
  > $TESTDIR/dhcpd6.leases
  > $TESTDIR/dhcpd6slow.leases
  chmod 777 $TESTDIR/dhcpd.leases
  chmod 777 $TESTDIR/dhcpd6.leases
  chmod 777 $TESTDIR/dhcpd6slow.leases
  dhcpd -q -cf conf/dhcpd.conf -lf $TESTDIR/dhcpd.leases -pf $TESTDIR/dhcpd.pid
  dhcpd -6 -q -cf conf/dhcpd6.conf -lf $TESTDIR/dhcpd6.leases -pf $TESTDIR/dhcpd6.pid
  dhcpd -6 -q -cf conf/dhcpd6slow.conf -lf $TESTDIR/dhcpd6slow.leases -pf $TESTDIR/dhcpd6slow.pid
}


stop_dhcpd() {
  echo stopping dhcpd
  pkill -9 -F $TESTDIR/dhcpd.pid
  pkill -9 -F $TESTDIR/dhcpd6.pid
  pkill -9 -F $TESTDIR/dhcpd6slow.pid
  rm -f $TESTDIR/{dhcpd.pid,dhcpd6.pid,dhcpd6slow.pid,dhcpd.leases,dhcpd6.leases,dhcpd6slow.leases}
}


start_radvd() {
  mkdir -p /run/radvd
  chown radvd:radvd /run/radvd
  radvd -C conf/radvd.conf -p $TESTDIR/radvd.pid -u radvd -d 5
}


stop_radvd() {
  echo stopping radvd
  pkill -9 -F $TESTDIR/radvd.pid
}


kill_server() {
  stop_nfs
  stop_iscsi
  stop_dhcpd
  stop_radvd
}


run_server() {
  start_nfs && \
  start_iscsi && \
  start_dhcpd && \
  start_radvd
}

stop_qemu() {
  pkill -F  $TESTDIR/qemu.pid
}

network_check() {
  nmcli con show id slow6 nfs nfs_ip6 iscsi0 iscsi1 vlan vlan33_0 vlan33_1 bond0_0 bond0_1 bond1_0 bond1_1 &> /dev/null
}

network_setup() {
  # bridge devices to connect
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "slow6"    ifname "slow6"    ipv4.addresses "192.168.49.1/30" ipv6.addresses "feed:beef::1/64" ipv6.gateway "feed:beef::aa" ipv4.method "manual" ipv6.method "manual"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "nfs"      ifname "nfs"      ipv4.addresses "192.168.50.1/24,192.168.50.2/24" ipv6.addresses "deaf:beef::1/64" ipv6.gateway "deaf:beef::aa" ipv4.method "manual" ipv6.method "manual"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "nfs_ip6"  ifname "nfs_ip6"  ipv4.method "disabled" ipv6.addresses "deaf:beaf::1/64" ipv6.gateway "deaf:beaf::aa" ipv6.method "manual"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "iscsi0"   ifname "iscsi0"   ipv4.addresses "192.168.51.1/24" ipv4.method "manual" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "iscsi1"   ifname "iscsi1"   ipv4.addresses "192.168.52.1/24" ipv4.method "manual" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "vlan"     ifname "vlan"     ipv4.method "disabled" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "vlan33_0" ifname "vlan33_0" ipv4.addresses "192.168.55.21/30" ipv4.method "manual" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "vlan33_1" ifname "vlan33_1" ipv4.method "disabled" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "bond0_0"  ifname "bond0_0"  ipv4.method "disabled" ipv6.method "disabled" slave-type "bond" master "bond0"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "bond0_1"  ifname "bond0_1"  ipv4.method "disabled" ipv6.method "disabled" slave-type "bond" master "bond0"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "bond1_0"  ifname "bond1_0"  ipv4.method "disabled" ipv6.method "disabled" slave-type "bond" master "bond1"
  nmcli con add autoconnect "no" type "bridge" bridge.stp "no" ethernet.cloned-mac-address "random" con-name "bond1_1"  ifname "bond1_1"  ipv4.method "disabled" ipv6.method "disabled" slave-type "bond" master "bond1"
  # special devices over bridges
  nmcli con add autoconnect "no" type "bond"   con-name "bond0"    ifname "bond0"    ipv4.address "192.168.53.1/24" ipv4.method "manual" ipv6.method "disabled" bond.options "mode=balance-rr"
  nmcli con add autoconnect "no" type "bond"   con-name "bond1"    ifname "bond1"    ipv4.address "192.168.54.1/24" ipv4.method "manual" ipv6.method "disabled" bond.options "mode=balance-rr"
  nmcli con add autoconnect "no" type "vlan"   con-name "bond0.13" ifname "bond0.13" ipv4.addresses "192.168.55.13/30" ipv4.method "manual" ipv6.method "disabled" id "13" dev "bond0"
  nmcli con add autoconnect "no" type "vlan"   con-name "bond1.17" ifname "bond1.17" ipv4.addresses "192.168.55.17/30" ipv4.method "manual" ipv6.method "disabled" id "17" dev "bond1"
  nmcli con add autoconnect "no" type "vlan"   con-name "vlan.5"   ifname "vlan.5"   ipv4.addresses "192.168.55.5/30" ipv4.method "manual" ipv6.method "disabled" id "5" dev "vlan"
  nmcli con add autoconnect "no" type "vlan"   con-name "vlan.9"   ifname "vlan.9"   ipv4.addresses "192.168.55.9/30" ipv4.method "manual" ipv6.method "disabled" id "9" dev "vlan"
  nmcli con add autoconnect "no" type "vlan"   con-name "vlan33_0.33" ifname "vlan33_0.33" ipv4.addresses "192.168.55.33/29" ipv4.method "manual" ipv6.method "disabled" id "33" dev "vlan33_0"
  nmcli con add autoconnect "no" type "vlan"   con-name "vlan33_1.33" ifname "vlan33_1.33" ipv4.addresses "192.168.55.34/29" ipv4.method "manual" ipv6.method "disabled" id "33" dev "vlan33_1"

  # up all connections
  for conn in \
      slow6 \
      nfs \
      nfs_ip6 \
      iscsi0 \
      iscsi1 \
      bond0 \
      bond0.13 \
      bond1 \
      bond1.17 \
      bond0_0 \
      bond0_1 \
      bond1_0 \
      bond1_1 \
      vlan \
      vlan.5 \
      vlan.9 \
      vlan33_0 \
      vlan33_1 \
      vlan33_0.33 \
      vlan33_1.33
    do
      nmcli con up $conn
  done

  # there is packet loss (and NFS not working) if bond is not in promisc mode
  ip link set bond0 promisc on
  ip link set bond1 promisc on
}


network_clean() {
  nmcli con del \
     slow6 \
     nfs \
     nfs_ip6 \
     iscsi0 \
     iscsi1 \
     bond0.13 \
     bond0 \
     bond1.17 \
     bond1 \
     bond0_0 \
     bond0_1 \
     bond1_0 \
     bond1_1 \
     vlan.5 \
     vlan.9 \
     vlan \
     vlan33_0.33 \
     vlan33_1.33 \
     vlan33_0 \
     vlan33_1

  # delete bridges left by NM
  for bridge in \
      slow6 \
      nfs \
      nfs_ip6 \
      iscsi0 \
      iscsi1 \
      bond0 \
      bond0.13 \
      bond1 \
      bond1.17 \
      bond0_0 \
      bond0_1 \
      bond1_0 \
      bond1_1 \
      vlan \
      vlan.5 \
      vlan.9 \
      vlan33_0 \
      vlan33_1 \
      vlan33_0.33 \
      vlan33_1.33
    do
      ip link del $bridge
  done
}
