#!/bin/bash

USE_NETWORK="network-manager"
OMIT_NETWORK="network-legacy"

TEST_DESCRIPTION="root filesystem on NFS with $USE_NETWORK"

KVERSION=${KVERSION-$(uname -r)}

# Uncomment this to debug failures
DEBUGFAIL="loglevel=1"
#DEBUGFAIL="rd.shell rd.break rd.debug loglevel=7 "
#DEBUGFAIL="rd.debug loglevel=7 "
#SERVER_DEBUG="rd.debug loglevel=7"
#SERIAL="tcp:127.0.0.1:9999"

run_server() {
    # Start server first
    echo "NFS TEST SETUP: Starting DHCP/NFS server"

    fsck -a $TESTDIR/server.ext3 || return 1
    $testdir/run-qemu \
        -drive format=raw,index=0,media=disk,file=$TESTDIR/server.ext3 \
        -net socket,listen=127.0.0.1:12320 \
        -net nic,macaddr=52:54:00:12:34:56,model=e1000 \
        ${SERIAL:+-serial "$SERIAL"} \
        ${SERIAL:--serial file:"$TESTDIR"/server.log} \
        -watchdog i6300esb -watchdog-action poweroff \
        -append "panic=1 quiet root=/dev/sda rootfstype=ext3 rw console=ttyS0,115200n81 selinux=0 noapic" \
        -initrd $TESTDIR/initramfs.server \
        -pidfile $TESTDIR/server.pid -daemonize || return 1
    chmod 644 $TESTDIR/server.pid || return 1

    # Cleanup the terminal if we have one
    tty -s && stty sane

    if ! [[ $SERIAL ]]; then
        for _ in {1..60} ; do
            grep Serving "$TESTDIR"/server.log && return 0
            echo "Waiting for the server to startup"
            sleep 1
        done
        return 1
    else
        echo Sleeping 10 seconds to give the server a head start
        sleep 10
    fi
}

return_fail() {
    local cmdline="$1"
    if [[ "$cmdline" == *"failme"* ]]; then
        return 0
    else
        return 1
    fi
}

return_pass() {
    local cmdline="$1"
    if [[ "$cmdline" == *"failme"* ]]; then
        return 1
    else
        return 0
    fi
}

client_test() {
    local test_name="$1"
    local mac=$2
    local cmdline="$3"
    local server="$4"
    local check_opt="$5"
    local nfsinfo opts found expected

    if [ -n "$TEST_TO_RUN" ] && [ "$test_name" != "$TEST_TO_RUN" ]; then
        return 0
    fi

    touch /tmp/dracut_test_match

    echo -e "\n\nCLIENT TEST START: $test_name"

    # Need this so kvm-qemu will boot (needs non-/dev/zero local disk)
    if ! dd if=/dev/zero of=$TESTDIR/client.img bs=1M count=1 &>/dev/null; then
        echo "Unable to make client sda image" 1>&2
        return 1
    fi

    $testdir/run-qemu \
        -drive format=raw,index=0,media=disk,file=$TESTDIR/client.img \
        -net nic,macaddr=$mac,model=e1000 \
        -net socket,connect=127.0.0.1:12320 \
        -watchdog i6300esb -watchdog-action poweroff \
        -append "rd.net.timeout.dhcp=3 panic=1 systemd.crash_reboot rd.shell=0 $cmdline $DEBUGFAIL rd.retry=10 quiet ro console=ttyS0,115200n81 selinux=0 noapic" \
        -initrd $TESTDIR/initramfs.testing

    if [[ $? -ne 0 ]] || ! grep -F -m 1 -q nfs-OK $TESTDIR/client.img; then
        echo "CLIENT MSG: $(cat $TESTDIR/client.img)"
        echo "CLIENT END: $test_name [FAILED - BAD EXIT]"
        return_fail "$cmdline"
        return $?
    fi

    # nfsinfo=( server:/path nfs{,4} options )
    nfsinfo=($(awk '{print $2, $3, $4; exit}' $TESTDIR/client.img))
    if [[ "${nfsinfo[0]%%:*}" != "$server" ]]; then
        echo "CLIENT INFO: got server: ${nfsinfo[0]%%:*}"
        echo "CLIENT INFO: expected server: $server"
        echo "CLIENT END: $test_name [FAILED - WRONG SERVER]"
        return_fail "$cmdline"
        return $?
    fi

    found=0
    expected=1
    if [[ ${check_opt:0:1} = '-' ]]; then
        expected=0
        check_opt=${check_opt:1}
    fi

    opts=${nfsinfo[2]},
    while [[ $opts ]]; do
        if [[ ${opts%%,*} = $check_opt ]]; then
            found=1
            break
        fi
        opts=${opts#*,}
    done

    if [[ $found -ne $expected ]]; then
        echo "CLIENT INFO: got options: ${nfsinfo[2]%%:*}"
        if [[ $expected -eq 0 ]]; then
            echo "CLIENT INFO: did not expect: $check_opt"
            echo "CLIENT END: $test_name [FAILED - UNEXPECTED OPTION]"
        else
            echo "CLIENT INFO: missing: $check_opt"
            echo "CLIENT END: $test_name [FAILED - MISSING OPTION]"
        fi
        return_fail "$cmdline"
        return $?
    fi

    echo "CLIENT END: $test_name [OK]"
    return_pass "$cmdline"
    return $?
}

test_nfsv3() {
    # MAC numbering scheme:
    # NFSv3: last octect starts at 0x00 and works up
    # NFSv4: last octect starts at 0x80 and works up

    client_test "NFSv3 root=dhcp DHCP path only" 52:54:00:12:34:00 \
                "root=dhcp" 192.168.50.1 -wsize=4096 || return 1

    #if [[ "$(systemctl --version)" != *"systemd 230"* ]] 2>/dev/null; then
        client_test "NFSv3 Legacy root=/dev/nfs nfsroot=IP:path" 52:54:00:12:34:01 \
                    "root=/dev/nfs nfsroot=192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

        client_test "NFSv3 Legacy root=/dev/nfs DHCP path only" 52:54:00:12:34:00 \
                    "root=/dev/nfs" 192.168.50.1 -wsize=4096 || return 1

        client_test "NFSv3 Legacy root=/dev/nfs DHCP IP:path" 52:54:00:12:34:01 \
                    "root=/dev/nfs" 192.168.50.2 -wsize=4096 || return 1
    #fi

    client_test "NFSv3 root=dhcp DHCP IP:path" 52:54:00:12:34:01 \
                "root=dhcp" 192.168.50.2 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:02 \
                "root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:03 \
                "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    client_test "NFSv3 root=nfs:..." 52:54:00:12:34:04 \
                "root=nfs:192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Bridge root=nfs:..." 52:54:00:12:34:04 \
                "root=nfs:192.168.50.1:/nfs/client bridge net.ifnames=0" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 Legacy root=IP:path" 52:54:00:12:34:04 \
                "root=192.168.50.1:/nfs/client" 192.168.50.1 -wsize=4096 || return 1

    # This test must fail: nfsroot= requires root=/dev/nfs
    client_test "NFSv3 Invalid root=dhcp nfsroot=/nfs/client" 52:54:00:12:34:04 \
                "root=dhcp nfsroot=/nfs/client failme rd.debug" 192.168.50.1 -wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP path,options" \
                52:54:00:12:34:05 "root=dhcp" 192.168.50.1 wsize=4096 || return 1

    client_test "NFSv3 Bridge Customized root=dhcp DHCP path,options" \
                52:54:00:12:34:05 "root=dhcp bridge=foobr0:ens2" 192.168.50.1 wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP IP:path,options" \
                52:54:00:12:34:06 "root=dhcp" 192.168.50.2 wsize=4096 || return 1

    client_test "NFSv3 root=dhcp DHCP proto:IP:path,options" \
                52:54:00:12:34:07 "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    # rhbz1627820
    client_test "NFSv3 root=dhcp DHCP lease renewal bridge" 52:54:00:12:34:08 \
                "root=dhcp bridge net.ifnames=0" 192.168.50.3 wsize=4096 || return 1

    # rhbz1710935
    client_test "NFSv3 root=dhcp rd.neednet=1" 52:54:00:12:34:00 \
                "root=dhcp rd.neednet=1" 192.168.50.1 -wsize=4096 || return 1

    return 0
}

test_nfsv4() {
    # There is a mandatory 90 second recovery when starting the NFSv4
    # server, so put these later in the list to avoid a pause when doing
    # switch_root

    client_test "NFSv4 root=dhcp DHCP proto:IP:path" 52:54:00:12:34:82 \
                "root=dhcp" 192.168.50.3 -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path:options" 52:54:00:12:34:83 \
                "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    client_test "NFSv4 root=nfs4:..." 52:54:00:12:34:84 \
                "root=nfs4:192.168.50.1:/client" 192.168.50.1 \
                -wsize=4096 || return 1

    client_test "NFSv4 root=dhcp DHCP proto:IP:path,options" \
                52:54:00:12:34:87 "root=dhcp" 192.168.50.3 wsize=4096 || return 1

    return 0
}

kill_server() {
    if [[ -s $TESTDIR/server.pid ]]; then
        kill -TERM $(cat $TESTDIR/server.pid)
        rm -f -- $TESTDIR/server.pid
        cp $TESTDIR/server.log /tmp/dracut_server.log
    fi
}

test_run() {
    rm /tmp/dracut_test_match

    test_nfsv3 && \
        test_nfsv4

    ret=$?

    if [ -n "$TEST_TO_RUN" ] && [ ! -f "/tmp/dracut_test_match" ]; then
        echo "Test not found: $TEST_TO_RUN"
        ret=1
    fi

    return $ret
}

test_setup() {
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

        inst_multiple sh ls shutdown poweroff stty cat ps ln ip \
                      dmesg mkdir cp ping exportfs \
                      modprobe rpc.nfsd rpc.mountd showmount tcpdump \
                      /etc/services sleep mount chmod rm
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        type -P portmap >/dev/null && inst_multiple portmap
        type -P rpcbind >/dev/null && inst_multiple rpcbind
        [ -f /etc/netconfig ] && inst_multiple /etc/netconfig
        type -P dhcpd >/dev/null && inst_multiple dhcpd
        [ -x /usr/sbin/dhcpd3 ] && inst /usr/sbin/dhcpd3 /usr/sbin/dhcpd
        instmods nfsd sunrpc ipv6 lockd af_packet
        inst ./server-init.sh /sbin/init
        inst_simple /etc/os-release
        inst ./hosts /etc/hosts
        inst ./exports /etc/exports
        inst ./dhcpd.conf /etc/dhcpd.conf
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

        inst_multiple sh shutdown poweroff stty cat ps ln ip dd \
                      mount dmesg mkdir cp ping grep wc awk setsid ls vi /etc/virc less cat
        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        #inst ./client-init.sh /sbin/init
        inst_simple /etc/os-release
        (
            cd "$initdir"
            mkdir -p dev sys proc etc run
            mkdir -p var/lib/nfs/rpc_pipefs
            mkdir -p root usr/bin usr/lib usr/lib64 usr/sbin
            for i in bin sbin lib lib64; do
                ln -sfnr usr/$i $i
            done
        )
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
                      mount dmesg mkdir cp ping dd \
                      umount strace less setsid tree systemctl reset

        for _terminfodir in /lib/terminfo /etc/terminfo /usr/share/terminfo; do
            [ -f ${_terminfodir}/l/linux ] && break
        done
        inst_multiple -o ${_terminfodir}/l/linux
        inst_multiple grep
        inst_simple ./fstab /etc/fstab
        rpm -ql systemd | xargs -r $DRACUT_INSTALL ${initdir:+-D "$initdir"} -o -a -l
        inst /lib/systemd/system/systemd-remount-fs.service
        inst /lib/systemd/systemd-remount-fs
        inst /lib/systemd/system/systemd-journal-flush.service
        inst /etc/sysconfig/init
        inst /lib/systemd/system/slices.target
        inst /lib/systemd/system/system.slice
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

        inst ./client-init.sh /sbin/test-init

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

    umount $TESTDIR/mnt
    rm -fr -- $TESTDIR/mnt

    # Make an overlay with needed tools for the test harness
    (
        export initdir=$TESTDIR/overlay
        . $basedir/dracut-init.sh
        mkdir $TESTDIR/overlay
        inst_multiple poweroff shutdown
        inst_hook shutdown-emergency 000 ./hard-off.sh
        inst_hook emergency 000 ./hard-off.sh
        inst_simple ./99-idesymlinks.rules /etc/udev/rules.d/99-idesymlinks.rules
        inst_simple ./99-default.link /etc/systemd/network/99-default.link
    )

    # Make server's dracut image
    dracut -l -i $TESTDIR/overlay / \
           -m "bash udev-rules base rootfs-block fs-lib debug kernel-modules watchdog qemu" \
           -d "af_packet piix ide-gd_mod ata_piix ext3 sd_mod e1000 i6300esb" \
           --no-hostonly-cmdline -N \
           -f $TESTDIR/initramfs.server $KVERSION || return 1

    # Make client's dracut image
    dracut -l -i $TESTDIR/overlay / \
           -o "plymouth dash dash ${OMIT_NETWORK}" \
           -a "debug watchdog ${USE_NETWORK}" \
           -d "af_packet piix ide-gd_mod ata_piix sd_mod e1000 nfs sunrpc i6300esb" \
           --no-hostonly-cmdline -N \
           -f $TESTDIR/initramfs.testing $KVERSION || return 1

     if ! run_server; then
         echo "Failed to start server" 1>&2
         kill_server
         return 1
     fi
}

test_cleanup() {
    kill_server
}

. $testdir/test-functions
