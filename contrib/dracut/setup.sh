#!/bin/bash

test_setup() {
    # Exit if server is already running
    [[ -f $TESTDIR/server.pid ]] && pkill -0 -F $TESTDIR/server.pid && return 0

    if ! command -v tgtd &>/dev/null || ! command -v tgtadm &>/dev/null; then
        echo "Need tgtd and tgtadm from scsi-target-utils"
        return 1
    fi

    # Make server root
    dd if=/dev/zero of=$TESTDIR/server.ext3 bs=1M count=600
    mke2fs -j -F $TESTDIR/server.ext3
    mkdir $TESTDIR/mnt
    mount -o loop $TESTDIR/server.ext3 $TESTDIR/mnt


    export kernel=$KVERSION
    export srcmods="/lib/modules/$kernel/"
    # Detect lib paths

    (
        export initdir=$TESTDIR/mnt
        . $basedir/dracut-init.sh

        for _f in modules.builtin.bin modules.builtin; do
            [[ $srcmods/$_f ]] && break
        done || {
            dfatal "No modules.builtin.bin and modules.builtin found!"
            return 1
        }

        for _f in modules.builtin.bin modules.builtin modules.order; do
            [[ $srcmods/$_f ]] && inst_simple "$srcmods/$_f" "/lib/modules/$kernel/$_f"
        done

        inst_multiple sh ls shutdown poweroff stty cat ps ln ip grep sed \
                      dmesg mkdir cp ping exportfs find  \
                      modprobe rpc.nfsd rpc.mountd showmount tcpdump \
                      /etc/services sleep mount chmod chown rm setsid \
                      umount tgtd tgtadm
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        type -P portmap >/dev/null && inst_multiple portmap
        type -P rpcbind >/dev/null && inst_multiple rpcbind
        [ -f /etc/netconfig ] && inst_multiple /etc/netconfig
        type -P dhcpd >/dev/null && inst_multiple dhcpd
        type -P radvd >/dev/null && inst_multiple radvd
        type -P teamd >/dev/null && inst_multiple teamd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet bonding ipvlan macvlan 8021q
        inst ./conf/server-init.sh /sbin/init
        inst_simple /etc/os-release
        inst ./conf/hosts /etc/hosts
        inst ./conf/exports /etc/exports
        inst ./conf/dhcpd.conf /etc/dhcpd.conf
        inst ./conf/dhcpd6.conf /etc/dhcpd6.conf
        inst ./conf/radvd.conf /etc/radvd.conf
        inst_multiple /etc/nsswitch.conf /etc/rpc /etc/protocols
        inst_multiple rpc.idmapd /etc/idmapd.conf

        inst_libdir_file 'libnfsidmap_nsswitch.so*'
        inst_libdir_file 'libnfsidmap/*.so*'
        inst_libdir_file 'libnfsidmap*.so*'

        _nsslibs=$(sed -e '/^#/d' -e 's/^.*://' -e 's/\[NOTFOUND=return\]//' /etc/nsswitch.conf \
                       |  tr -s '[:space:]' '\n' | sort -u | tr -s '[:space:]' '|')
        _nsslibs=${_nsslibs#|}
        _nsslibs=${_nsslibs%|}

        inst_libdir_file -n "$_nsslibs" 'libnss_*.so*'

        (
            cd "$initdir";
            mkdir -p dev sys proc run etc var/run tmp var/lib/{dhcpd,rpcbind}
            mkdir -p var/lib/nfs/{v4recovery,rpc_pipefs}
            chmod 777 var/lib/rpcbind var/lib/nfs
        )
        inst /etc/nsswitch.conf /etc/nsswitch.conf

        inst /etc/passwd /etc/passwd
        inst /etc/group /etc/group

        cp -a /etc/ld.so.conf* $initdir/etc
        ldconfig -r "$initdir"
        dracut_kernel_post
    )


    # Make client root inside server root
    (
        export initdir=$TESTDIR/mnt/nfs/client
        . $basedir/dracut-init.sh

        inst_multiple sh shutdown poweroff stty cat ps ln ip dd mount dmesg \
                      mkdir cp ping grep wc awk setsid ls find less cat tee \
                      sync rm sed time
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        inst_simple /etc/os-release
        inst /etc/machine-id
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
    )

    # install systemd in client
    (
        export initdir=$TESTDIR/mnt/nfs/client
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
StandardInput=tty
StandardOutput=tty
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
        export initdir=$TESTDIR/mnt/nfs/client
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
            for _file in $(rpm -ql $_rpm); do
                if [ -d $_file ]; then
                    inst_dir $_file
                elif [ -L $_file ]; then
                    inst_symlink $_file
                elif [[ "$file" =  *".so"* ]]; then
                    inst_libdir_file $_file
                else
                    inst $_file
                fi
            done
        done
    )

    mkdir -p $TESTDIR/mnt/nfs/nfs3-5
    mkdir -p $TESTDIR/mnt/nfs/ip/192.168.50.101
    mkdir -p $TESTDIR/mnt/nfs/tftpboot/nfs4-5

    # Create the blank file to use as a root filesystem
    dd if=/dev/zero of=$TESTDIR/root.ext3 bs=1M count=600
    dd if=/dev/zero of=$TESTDIR/iscsidisk2.img bs=1M count=300
    dd if=/dev/zero of=$TESTDIR/iscsidisk3.img bs=1M count=300

    # copy client files to root filesystem
    mkfs.ext3 -j -L singleroot -F $TESTDIR/root.ext3
    mkdir $TESTDIR/mnt_root
    mount -o loop $TESTDIR/root.ext3 $TESTDIR/mnt_root
    cp -a -t $TESTDIR/mnt_root $TESTDIR/mnt/nfs/client/*
    umount $TESTDIR/mnt_root
    umount $TESTDIR/mnt
    rm -fr -- $TESTDIR/mnt

    # server initramfs
    (
      mkdir $TESTDIR/overlay-server
      (
          export initdir=$TESTDIR/overlay-server
          . $basedir/dracut-init.sh
          inst /etc/mke2fs.conf
          inst_multiple sfdisk mkfs.ext3 poweroff cp umount setsid dd lsblk
          inst_hook initqueue/finished 01 ./conf/create-root.sh
          inst_hook shutdown-emergency 000 ./conf/hard-off.sh
          inst_hook emergency 000 ./conf/hard-off.sh
          inst_simple ./conf/99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
          inst_simple ./conf/99-default.link /etc/systemd/network/99-default.link
      )

      # Make server's dracut image
      dracut -i $TESTDIR/overlay-server / \
             -m "bash crypt lvm mdraid udev-rules base rootfs-block fs-lib debug kernel-modules qemu" \
             -d "8021q ipvlan macvlan bonding af_packet piix ide-gd_mod ata_piix ext3 sd_mod e1000 drbg" \
             --no-hostonly-cmdline -N \
             -f $TESTDIR/initramfs.server $KVERSION
      rm -rf -- $TESTDIR/overlay-server
    ) &

    # client initramfs with NM module
    (
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
               --no-hostonly-cmdline -N \
               -f $TESTDIR/initramfs.client.NM $KVERSION
       rm -rf -- $TESTDIR/overlay-client-NM
     ) &

     # client initramfs with legacy module
     (
       mkdir $TESTDIR/overlay-client-legacy
       (
          export initdir=$TESTDIR/overlay-client-legacy
          . $basedir/dracut-init.sh
          inst /etc/machine-id
          inst_multiple poweroff shutdown
          inst_hook shutdown-emergency 000 ./conf/hard-off.sh
          inst_hook emergency 000 ./conf/hard-off.sh
          inst_simple ./conf/99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
          inst_simple ./conf/99-default.link /etc/systemd/network/99-default.link
       )

       # Make NFS client's dracut image using legacy network module
       dracut -i $TESTDIR/overlay-client-legacy / \
              -o "plymouth dash dmraid network-manager" \
              -a "debug network-legacy ifcfg" \
              -d "8021q ipvlan macvlan bonding af_packet piix ext3 ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc" \
              --no-hostonly-cmdline -N \
              -f $TESTDIR/initramfs.client.legacy $KVERSION
       rm -rf -- $TESTDIR/overlay-client-legacy
  ) &

  wait

  if ! run_server; then
      echo "Failed to start server" 1>&2
      kill_server
      return 1
  fi
}


test_clean() {
    kill_server
    rm -rf -- "$TESTDIR"
    rm /tmp/dracut_testdir
    echo "dracut testdir $TESTDIR cleaned"
}



kill_server() {
    if [[ -f $TESTDIR/server.pid ]]; then
        pkill -9 -F $TESTDIR/server.pid
        rm -f -- $TESTDIR/server.pid
    fi
    if [[ -f $TESTDIR/server.log ]]; then
        cp $TESTDIR/server.log /tmp/dracut_server.log
    fi
}


run_server() {
    # Start server first
    echo "NFS TEST SETUP: Starting DHCP/NFS server"

    fsck -a $TESTDIR/server.ext3 || return 1
    ./run-qemu \
        -drive format=raw,index=0,media=disk,file=$TESTDIR/server.ext3 \
        -drive format=raw,index=1,media=disk,file=$TESTDIR/root.ext3 \
        -drive format=raw,index=2,media=disk,file=$TESTDIR/iscsidisk2.img \
        -drive format=raw,index=3,media=disk,file=$TESTDIR/iscsidisk3.img \
        -netdev socket,id=n0,listen=127.0.0.1:12320 \
        -netdev hubport,hubid=1,id=h1,netdev=n0 \
        -netdev hubport,hubid=1,id=h2 -device e1000,mac=52:54:00:12:34:56,netdev=h2 \
        -netdev hubport,hubid=1,id=h3 -device e1000,mac=52:54:00:12:34:57,netdev=h3 \
        -netdev hubport,hubid=1,id=h4 -device e1000,mac=52:54:00:12:34:58,netdev=h4 \
        -netdev socket,id=n1,listen=127.0.0.1:12321 -device e1000,netdev=n1,mac=52:54:00:12:34:60 \
        -netdev socket,id=n2,listen=127.0.0.1:12322 -device e1000,netdev=n2,mac=52:54:00:12:34:61 \
        -netdev socket,id=n3,listen=127.0.0.1:12323 -device e1000,netdev=n3,mac=52:54:00:12:34:62 \
        ${SERIAL:+-serial "$SERIAL"} \
        ${SERIAL:--serial file:"$TESTDIR"/server.log} \
        -append "panic=1 quiet root=/dev/sda rootfstype=ext3 rw $SERVER_DEBUG console=ttyS0,115200n81 selinux=0 noapic" \
        -initrd $TESTDIR/initramfs.server \
        -pidfile $TESTDIR/server.pid -daemonize || return 1
    chmod 644 $TESTDIR/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        for _ in {1..100} ; do
            grep -q Serving "$TESTDIR"/server.log && return 0
            echo "Waiting for the server to startup"
            sleep 1
        done
        return 1
    else
        echo Sleeping 10 seconds to give the server a head start
        sleep 10
    fi

    cp $TESTDIR/iscsidisk2.img $TESTDIR/iscsidisk3.img /tmp/
}
