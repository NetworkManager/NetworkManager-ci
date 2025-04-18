#!/bin/bash
set -x

function setup () {
    # If $1 is empty, $NUM defaults to "3"
    NUM="${1:-3}"
    MAJOR="$(uname -r |awk -F '-' '{print $1}')"
    MINOR="$(uname -r |awk -F '-' '{print $2}'| rev| cut -d. -f2-  |rev)"
    LINUX=linux-$MAJOR-$MINOR
    # We need this patched netdevsim device to support ring/coal ethtool options and physical address
    PATCH="0001-netdevsim-add-coal-ring-channels-8.3.patch"
    # for newer kernels, only physical address patch must be applied
    # PATCH="0001-netdevsim-physical-address.patch"
    DRIVER="drivers/net/netdevsim"

    if grep Fedora /etc/redhat-release; then
        URL='https://kojipkgs.fedoraproject.org//packages/kernel'
        LINUX="$(echo $LINUX |awk -F '.' '{print $1 "." $2}')"
        PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-fix-channels.patch"
    elif grep "release 8" /etc/redhat-release; then
        PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-fix-channels.patch"
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/kernel"
        if grep -F --regexp="release 8."{0..4}" " /etc/redhat-release; then
            PATCH="0001-netdevsim-add-coal-ring-channels.patch"
        elif grep -F --regexp="release 8."{5..6}" " /etc/redhat-release; then
            PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-add-channels.patch"
        elif grep -E "CentOS Stream" /etc/redhat-release; then
            URL="https://kojihub.stream.centos.org/kojifiles/packages/kernel/"
        fi
    elif grep -e "release 9" /etc/redhat-release; then
        PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-fix-channels.patch"
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages/kernel"
        if grep -F --regexp="release 9.0 " /etc/redhat-release; then
            PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-add-channels.patch"
        elif grep "CentOS" /etc/redhat-release; then
            URL="https://kojihub.stream.centos.org/kojifiles/packages/kernel/"
        fi
        LINUX=linux-$MAJOR-${MINOR%.el9}
    elif grep "release 10" /etc/redhat-release; then
        PATCH="0001-netdevsim-fix-ring.patch 0001-netdevsim-fix-channels.patch"
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-10/packages/kernel"
        if grep "CentOS" /etc/redhat-release; then
            URL="https://kojihub.stream.centos.org/kojifiles/packages/kernel/"
        fi
        LINUX=linux-$MAJOR-${MINOR%.el10}
    fi

    # If we have all necessary things done
    if ! test -f /tmp/netdevsim_installed; then
        # Install srpm (first try manualy cached file in /root)
        rpm -i /root/kernel-$MAJOR-$MINOR.src.rpm || \
        wget $URL/$MAJOR/$MINOR/src/kernel-$MAJOR-$MINOR.src.rpm \
            --no-check-certificate -O /root/kernel-$MAJOR-$MINOR.src.rpm && \
          rpm -i /root/kernel-$MAJOR-$MINOR.src.rpm
        [ -f /root/rpmbuild/SOURCES/$LINUX.tar.xz ] || \
          LINUX=$(ls /root/rpmbuild/SOURCES/linux-${MAJOR%%.*}*.tar.xz | tail -n1 | \
            sed 's@/root/rpmbuild/SOURCES/@@;s@\.tar\.xz@@')
        mkdir -p /var/src/
        tar xf /root/rpmbuild/SOURCES/$LINUX.tar.xz -C /var/src
        cd contrib/netdevsim
        cp -f *.patch /var/src/$LINUX
        cd /var/src/$LINUX
        # Patch critical features:
        #  - either add features for old kernels
        #  - or fix in new kernels
        cat $PATCH | patch -p1 --merge -t -l || { echo "Unable to patch, please fix the patch"; exit 1; }
        # Set permanent address - needed for GUI and cloud test
        cat "0001-netdevsim-physical-address.patch" | patch -p1 --merge -t -l || { echo "Unable to patch, please fix the patch"; exit 1; }

        ARCH="$(arch)"

        if [ $ARCH == "ppc64le" ] ;then
            ARCH="powerpc"
        elif [ $ARCH == "s390x" ] ;then
            ARCH="s390"
        elif [ $ARCH == "x86_64" ] ;then
            ARCH="x86"
        elif [ $ARCH == "aarch64" ] ;then
            ARCH="arm64"
        fi

        cd $DRIVER
        # If we cannot build exit 1
        make -C /lib/modules/$(uname -r)/build M=$PWD ARCH=$ARCH || \
          { echo "Unable to build module"; exit 1; }
        make -C /lib/modules/$(uname -r)/build M=$PWD modules_install || \
          { echo "Unable to install module"; exit 1; }

        # We are all OK installing deps
        touch /tmp/netdevsim_installed
    fi

    # Remove module in case netdevsim is loaded
    if lsmod |grep netdevsim > /dev/null; then
        echo "** removing previous kernel module"
        modprobe -r netdevsim
    fi

    # Change dir to the patched driver dir
    cd /var/src/$LINUX/$DRIVER

    # If we are able to insert module create devices and exit 0
    echo "** installing the patched one"
    if modprobe netdevsim; then
        # RHEL9 prefers signed module, use insmod instead
        if grep "release 9" /etc/redhat-release; then
            rmmod netdevsim
            insmod /lib/modules/$(uname -r)/extra/netdevsim.ko
        fi
        sleep 0.5
        echo "0 $NUM 128" > /sys/bus/netdevsim/new_device

        # Make sure the netdevsim devices based from eth11,
        # even if eth0-eth10 are not there yet.
        # prepare_patched_netdevsim_bs() expects this.
        n=11
        for i in $(ls -d /sys/devices/netdevsim*/net/eth* |sort); do
            O=$(basename $i)
            N=eth$n
            [ $N = $O ] && break
            ip link set $N name $O; n=$(( n+1 ))
        done

        touch /tmp/netdevsim
    else
        echo "** we fail to load - > exit 1"
        exit 1
    fi
    echo "** done"
    exit 0
}

function teardown () {
    modprobe -r netdevsim
    rm -rf /tmp/netdevsim
}

if [ "x$1" != "xteardown" ]; then
    setup $2
else
    teardown
fi
