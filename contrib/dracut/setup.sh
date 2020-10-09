#!/bin/bash

TESTDIR=/tmp/dracut_test

test_setup() {
  # Exit if setup is already done
  [ -f /tmp/dracut_setup_done ] && return 0

  touch /tmp/dracut_setup_done

  network_setup

  mkdir $TESTDIR

  basedir=/usr/lib/dracut/

  if ! command -v tgtd &>/dev/null || ! command -v tgtadm &>/dev/null; then
      echo "Need tgtd and tgtadm from scsi-target-utils"
      return 1
  fi

  mkdir -p $TESTDIR/nfs/client

  # Make client root
  (
      export initdir=$TESTDIR/nfs/client
      . $basedir/dracut-init.sh

      inst_multiple sh shutdown poweroff stty cat ps ln ip dd mount dmesg \
                    mkdir cp ping grep wc awk setsid ls find less tee \
                    sync rm sed time
      for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
          [ -f ${_terminfodir}/l/linux ] && break
      done
      inst_multiple -o ${_terminfodir}/l/linux
      inst_simple /etc/os-release
      inst_simple /etc/machine-id
      (
          cd "$initdir"
          mkdir -p dev sys proc etc run
          mkdir -p var/lib/nfs/rpc_pipefs
          mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
          for i in bin sbin lib lib64; do
              ln -sfnr usr/$i $i
          done
      )

      instmods nfsd sunrpc ipv6 lockd af_packet bonding ipvlan macvlan 8021q

      inst /etc/nsswitch.conf /etc/nsswitch.conf
      inst /etc/passwd /etc/passwd
      inst /etc/group /etc/group

      inst_libdir_file 'libnfsidmap_nsswitch.so*'
      inst_libdir_file 'libnfsidmap/*.so*'
      inst_libdir_file 'libnfsidmap*.so*'

      _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
                     |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
      _nsslibs=${_nsslibs#|}
      _nsslibs=${_nsslibs%|}

      inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

      cp -a /etc/ld.so.conf* $initdir/etc
      ldconfig -r "$initdir"
      echo "/dev/nfs / nfs defaults 1 1" > $initdir/etc/fstab


      rpm -ql libteam | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} -o -a -l
      rpm -ql teamd | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} -o -a -l
  )

  # install systemd in client
  (
      export initdir=$TESTDIR/nfs/client
      . $basedir/dracut-init.sh

      for d in usr/bin usr/sbin bin etc lib "$libdir" sbin tmp usr var var/log var/tmp dev proc sys sysroot root run; do
          if [ -L "/$d" ]; then
              inst_symlink "/$d"
          else
              inst_dir "/$d"
          fi
      done

      ln -sfn /run "$initdir/var/run"
      ln -sfn /run/lock "$initdir/var/lock"

      inst_multiple sh df free ls shutdown poweroff stty cat ps ln ip \
                    mount dmesg mkdir cp ping dd head tail grep \
                    umount strace less setsid tree systemctl reset

      for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
          [ -f ${_terminfodir}/l/linux ] && break
      done
      inst_multiple -o ${_terminfodir}/l/linux
      inst_simple ./fstab /etc/fstab
      rpm -ql systemd | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} -o -a -l
      inst /lib/systemd/system/systemd-remount-fs.service
      inst /lib/systemd/systemd-remount-fs
      inst /lib/systemd/system/systemd-journal-flush.service
      inst /etc/sysconfig/init
      inst /lib/systemd/system/slices.target
      inst /lib/systemd/system/system.slice
      inst /usr/lib/systemd/system/import-state.service
      inst_multiple -o /lib/systemd/system/dracut*

      # make a journal directory
      mkdir -p $initdir/var/log/journal

      # install some basic config files
      inst_multiple -o  \
                    /etc/machine-id \
                    /etc/adjtime \
                    /etc/passwd \
                    /etc/shadow \
                    /etc/group \
                    /etc/shells \
                    /etc/nsswitch.conf \
                    /etc/pam.conf \
                    /etc/securetty \
                    /etc/os-release \
                    /etc/localtime

      # we want an empty environment
      > $initdir/etc/environment

      # empty hostname
      > $initdir/etc/hostname

      # setup the testsuite target
      mkdir -p $initdir/etc/systemd/system
      cat >$initdir/etc/systemd/system/testsuite.target <<EOF
[Unit]
Description=Testsuite target
Requires=network.target
After=network.target
Conflicts=rescue.target
AllowIsolate=yes
EOF

      inst ./conf/client-init.sh /sbin/test-init

      # setup the testsuite service
      cat >$initdir/etc/systemd/system/testsuite.service <<EOF
[Unit]
Description=Testsuite service
After=network.target

[Service]
ExecStart=/sbin/test-init
Type=oneshot
StandardOutput=journal+console
StandardError=journal+console
EOF
      mkdir -p $initdir/etc/systemd/system/testsuite.target.wants
      ln -fs ../testsuite.service $initdir/etc/systemd/system/testsuite.target.wants/testsuite.service

      # make the testsuite the default target
      ln -fs testsuite.target $initdir/etc/systemd/system/default.target

      #         mkdir -p $initdir/etc/rc.d
      #         cat >$initdir/etc/rc.d/rc.local <<EOF
      # #!/bin/bash
      # exit 0
      # EOF

      # install basic tools needed
      inst_multiple sh bash setsid loadkeys setfont \
                    login sushell sulogin gzip sleep echo mount umount
      inst_multiple modprobe

      # install libnss_files for login
      inst_libdir_file "libnss_files*"

      # install dbus and pam
      find \
          /etc/dbus-1 \
          /etc/pam.d \
          /etc/security \
          /lib64/security \
          /lib/security -xtype f \
          | while read file || [ -n "$file" ]; do
          inst_multiple -o $file
      done

      # install dbus socket and service file
      inst /usr/lib/systemd/system/dbus.socket
      inst /usr/lib/systemd/system/dbus.service
      inst /usr/lib/systemd/system/dbus-broker.service
      inst /usr/lib/systemd/system/dbus-daemon.service

      (
          echo "FONT=eurlatgr"
          echo "KEYMAP=us"
      ) >$initrd/etc/vconsole.conf

      # install basic keyboard maps and fonts
      for i in \
          /usr/lib/kbd/consolefonts/eurlatgr* \
              /usr/lib/kbd/keymaps/{legacy/,/}include/* \
              /usr/lib/kbd/keymaps/{legacy/,/}i386/include/* \
              /usr/lib/kbd/keymaps/{legacy/,/}i386/qwerty/us.*; do
          [[ -f $i ]] || continue
          inst $i
      done

      # some basic terminfo files
      for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
          [ -f ${_terminfodir}/l/linux ] && break
      done
      inst_multiple -o ${_terminfodir}/l/linux

      # softlink mtab
      ln -fs /proc/self/mounts $initdir/etc/mtab

      # install any Execs from the service files
      grep -Eho '^Exec[^ ]*=[^ ]+' $initdir/lib/systemd/system/*.service \
          | while read i || [ -n "$i" ]; do
          i=${i##Exec*=}; i=${i##-}
          inst_multiple -o $i
      done

      # some helper tools for debugging
      [[ $DEBUGTOOLS ]] && inst_multiple $DEBUGTOOLS

      # install ld.so.conf* and run ldconfig
      cp -a /etc/ld.so.conf* $initdir/etc
      ldconfig -r "$initdir"
      ddebug "Strip binaeries"
      find "$initdir" -perm /0111 -type f | xargs -r strip --strip-unneeded | ddebug

      # copy depmod files
      inst /lib/modules/$kernel/modules.order
      inst /lib/modules/$kernel/modules.builtin
      # generate module dependencies
      if [[ -d $initdir/lib/modules/$kernel ]] && \
             ! depmod -a -b "$initdir" $kernel; then
          dfatal "\"depmod -a $kernel\" failed."
          exit 1
      fi
      # disable some services
      systemctl --root "$initdir" mask systemd-update-utmp
      systemctl --root "$initdir" mask systemd-tmpfiles-setup
  )

  # install NetworkManager to client
  (
      export initdir=$TESTDIR/nfs/client
      . $basedir/dracut-init.sh

      inst_multiple \
              /usr/bin/dbus \
              /usr/bin/dbus-launch \
              /usr/share/dbus-1/system.conf

      inst_multiple \
          /usr/lib/systemd/system/dbus-broker.service \
          /usr/lib/systemd/system/dbus.socket \
          busctl

      # enable trace logs
      inst /etc/NetworkManager/conf.d/99-test.conf


      for _rpm in $(rpm -qa | grep -e ^NetworkManager -e ^systemd | sort); do
        rpm -ql $_rpm | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} -o -a -l
      done
  )

  mkdir -p $TESTDIR/nfs/nfs3-5
  mkdir -p $TESTDIR/nfs/ip/192.168.50.101
  mkdir -p $TESTDIR/nfs/tftpboot/nfs4-5

  # Create the blank file to use as a root filesystem
  dd if=/dev/zero of=$TESTDIR/root.ext3 bs=1M count=600
  dd if=/dev/zero of=$TESTDIR/iscsidisk2.img bs=1M count=300
  dd if=/dev/zero of=$TESTDIR/iscsidisk3.img bs=1M count=300

  # copy client files to root filesystem
  mkfs.ext3 -j -L singleroot -F $TESTDIR/root.ext3
  losetup -f $TESTDIR/root.ext3
  iscsi_loop1="$(losetup -j $TESTDIR/root.ext3)"
  iscsi_loop1=${iscsi_loop1%%:*}
  mkdir $TESTDIR/mnt_root
  mount $iscsi_loop1 $TESTDIR/mnt_root
  cp -a -t $TESTDIR/mnt_root $TESTDIR/nfs/client/*
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
    mkfs.ext3 -j -L sysroot /dev/dracutNMtest/root
    mount /dev/dracutNMtest/root $TESTDIR/mnt_root
    cp -a -t $TESTDIR/mnt_root/ $TESTDIR/nfs/client/*

  )

  umount $TESTDIR/mnt_root
  lvm lvchange -a n /dev/dracutNMtest/root
  mdadm --stop /dev/md0
  rmdir $TESTDIR/mnt_root

  KVERSION=${KVERSION-$(uname -r)}

  # client initramfs with NM module
  mkdir $TESTDIR/overlay-client-NM
  (
     export initdir=$TESTDIR/overlay-client-NM
     . $basedir/dracut-init.sh
     inst /etc/machine-id
     inst_multiple poweroff shutdown
     inst_hook shutdown-emergency 000 ./conf/hard-off.sh
     inst_hook emergency 000 ./conf/hard-off.sh
     inst_simple ./conf/99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
     inst_simple ./conf/99-default.link /etc/systemd/network/99-default.link
  )

  # Make NFS client's dracut image using NM module
  dracut -i $TESTDIR/overlay-client-NM / \
         -o "plymouth dash dmraid network-legacy" \
         -a "debug network-manager ifcfg" \
         -d "8021q ipvlan macvlan bonding af_packet piix ext3 ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc" \
         --no-hostonly-cmdline -N --no-compress \
         -f $TESTDIR/initramfs.client.NM $KVERSION

  # Make NFS client's dracut image using legacy network module
  dracut -i $TESTDIR/overlay-client-legacy / \
         -o "plymouth dash dmraid network-manager" \
         -a "debug network-legacy ifcfg" \
         -d "8021q ipvlan macvlan bonding af_packet piix ext3 ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc" \
         --no-hostonly-cmdline -N --no-compress \
         -f $TESTDIR/initramfs.client.legacy $KVERSION

  rm -rf -- $TESTDIR/overlay-client-NM

  if ! run_server; then
      echo "Failed to start server" 1>&2
      kill_server
      return 1
  fi
}


test_clean() {
  kill_server
  for file in $TESTDIR/root.ext3 $TESTDIR/iscsidisk2.img $TESTDIR/iscsidisk3.img; do
    loop="$(losetup -j $file)"
    loop=${loop%%:*}
    losetup -d $loop
  done

  umount $TESTDIR/nfs/nfs3-5
  umount $TESTDIR/nfs/ip/192.168.50.101
  umount $TESTDIR/nfs/tftpboot/nfs4-5

  rm -rf -- "$TESTDIR"
  echo "dracut testdir $TESTDIR cleaned"
  network_clean
  echo "dracut network bridges cleaned"
  rm -f /tmp/dracut_setup_done
}


start_nfs() {
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/nfs3-5
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/ip/192.168.50.101
  mount --bind $TESTDIR/nfs/client $TESTDIR/nfs/tftpboot/nfs4-5
  cp conf/exports /etc/exports
  systemctl start nfs-server
}


stop_nfs() {
  echo stopping nfs
  systemctl stop nfs-server
}


start_iscsi() {
  iscsi_loop1="$(losetup -j $TESTDIR/root.ext3)"
  iscsi_loop1=${iscsi_loop1%%:*}
  iscsi_loop2="$(losetup -j $TESTDIR/iscsidisk2.img)"
  iscsi_loop2=${iscsi_loop2%%:*}
  iscsi_loop3="$(losetup -j $TESTDIR/iscsidisk3.img)"
  iscsi_loop3=${iscsi_loop3%%:*}
  tgtd -p $TESTDIR/tgtd.pid
  tgtadm --lld iscsi --mode target --op new --tid 1 --targetname iqn.2009-06.dracut:target0
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


start_dhcp() {
  mkdir -p /var/lib/dhcpd
  >/var/lib/dhcpd/dhcpd.leases
  >/var/lib/dhcpd/dhcpd6.leases
  chmod 777 /var/lib/dhcpd/dhcpd.leases
  chmod 777 /var/lib/dhcpd/dhcpd6.leases
  dhcpd -q -cf conf/dhcpd.conf -lf /var/lib/dhcpd/dhcpd.leases -pf $TESTDIR/dhcpd.pid
  dhcpd -6 -q -cf conf/dhcpd6.conf -lf /var/lib/dhcpd/dhcpd6.leases -pf $TESTDIR/dhcpd6.pid
}


stop_dhcp() {
  echo stopping dhcp
  pkill -9 -F $TESTDIR/dhcpd.pid
  pkill -9 -F $TESTDIR/dhcpd6.pid
  rm -f $TESTDIR/dhcpd.pid
  rm -f $TESTDIR/dhcpd6.pid
}


start_radvd() {
  mkdir /run/radvd
  chown radvd:radvd /run/radvd
  radvd -C conf/radvd.conf -p $TESTDIR/radvd.pid -u radvd
}


stop_radvd() {
  echo stopping radvd
  pkill -9 -F $TESTDIR/radvd.pid
}


kill_server() {
  stop_nfs
  stop_iscsi
  stop_dhcp
  stop_radvd
}


run_server() {
  start_nfs
  start_iscsi
  start_dhcp
  start_radvd
}

network_setup() {
  nmcli con add autoconnect "no" type "bridge" con-name "nfs"      ifname "nfs"      ipv4.addresses "192.168.50.1/24,192.168.50.2/24" ipv6.addresses "deaf:beef::1/64" ipv6.gateway "deaf:beef::aa" ipv4.method "manual" ipv6.method "manual"
  nmcli con add autoconnect "no" type "bridge" con-name "iscsi0"   ifname "iscsi0"   ipv4.addresses "192.168.51.1/24" ipv4.method "manual" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bridge" con-name "iscsi1"   ifname "iscsi1"   ipv4.addresses "192.168.52.1/24" ipv4.method "manual" ipv6.method "disabled"
  nmcli con add autoconnect "no" type "bond"   con-name "bond0"    ifname "bond0"    ipv4.address "192.168.53.1/24" ipv4.method "manual" ipv6.method "disabled" bond.options "mode=balance-rr"
  nmcli con add autoconnect "no" type "bond"   con-name "bond1"    ifname "bond1"    ipv4.address "192.168.54.1/24" ipv4.method "manual" ipv6.method "disabled" bond.options "mode=balance-rr"
  nmcli con add autoconnect "no" type "vlan"   con-name "bond0.13" ifname "bond0.13" ipv4.addresses "192.168.55.13/30" ipv4.method "manual" ipv6.method "disabled" id "13" dev "bond0"
  nmcli con add autoconnect "no" type "vlan"   con-name "bond1.17" ifname "bond1.17" ipv4.addresses "192.168.55.17/30" ipv4.method "manual" ipv6.method "disabled" id "17" dev "bond1"

  nmcli con up id nfs
  nmcli con up id iscsi0
  nmcli con up id iscsi1
  nmcli con up id bond0
  nmcli con up id bond0.13
  nmcli con up id bond1
  nmcli con up id bond1.17
}


network_clean() {
  nmcli con del nfs iscsi{0,1} bond{0,1} bond0.13 bond1.17
}
