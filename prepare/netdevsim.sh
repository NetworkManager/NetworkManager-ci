#!/bin/bash
set -x

function setup () {
    # If $1 is empty, $NUM defaults to "3"
    NUM="${1:-3}"
    MAJOR="$(uname -r |awk -F '-' '{print $1}')"
    MINOR="$(uname -r |awk -F '-' '{print $2}'| rev| cut -d. -f2-  |rev)"
    LINUX=linux-$MAJOR-$MINOR
    # We need this patched netdevsim device to support ring/coal ethtool options and physical address
    PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-1.patch"
    # for newer kernels, only physical address patch must be applied
    # PATCH="0001-netdevsim-physical-address.patch"
    DRIVER="drivers/net/netdevsim"

    if grep Fedora /etc/redhat-release; then
        URL='https://kojipkgs.fedoraproject.org//packages/kernel'
        LINUX="$(echo $LINUX |awk -F '.' '{print $1 "." $2}')"
        PATCH="0001-netdevsim-physical-address-ring.patch"
    elif grep "release 8" /etc/redhat-release; then
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/kernel"
        if grep -E "release 8.[0,1,2,3]" /etc/redhat-release; then
            PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-1.patch"
        elif grep "release 8.4" /etc/redhat-release; then
            PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-2.patch"
        elif grep -E "release 8.[5,6,7,8,9]" /etc/redhat-release; then
            PATCH="0001-netdevsim-physical-address-ring.patch"
        elif grep -E "CentOS Stream" /etc/redhat-release; then
            URL="https://koji.mbox.centos.org/pkgs/packages/kernel/"
            PATCH="0001-netdevsim-physical-address-ring.patch"
        fi
    elif grep "release 9" /etc/redhat-release; then
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages/kernel"
        LINUX=linux-$MAJOR-${MINOR%.el9}
        PATCH="0001-netdevsim-physical-address-ring.patch"
    fi

    # If we have all necessary things done
    if ! test -f /tmp/netdevsim_installed; then

        # Install build dependencies with skipbroken as yasm not present on 9
        yum -y install \
               wget git kernel-headers gcc \
               patch elfutils-libelf-devel bc yasm --skip-broken
        yum -y install kernel-devel-$MAJOR-$MINOR

        # Install srpm (first try manualy cached file in /root)
        rpm -i /root/kernel-$MAJOR-$MINOR.src.rpm || \
        wget $URL/$MAJOR/$MINOR/src/kernel-$MAJOR-$MINOR.src.rpm \
            --no-check-certificate -O /root/kernel-$MAJOR-$MINOR.src.rpm && \
          rpm -i /root/kernel-$MAJOR-$MINOR.src.rpm
        [ -f /root/rpmbuild/SOURCES/$LINUX.tar.xz ] || \
          LINUX=$(ls /root/rpmbuild/SOURCES/linux-${MAJOR%.*}*.tar.xz | tail -n1 | \
            sed 's@/root/rpmbuild/SOURCES/@@;s@\.tar\.xz@@')
        mkdir -p /var/src/
        tar xf /root/rpmbuild/SOURCES/$LINUX.tar.xz -C /var/src
        cp contrib/netdevsim/$PATCH /var/src/$LINUX
        cd /var/src/$LINUX
        # Patch module
        patch -p1 < $PATCH || { echo "Unable to patch, please fix the patch"; exit 1; }

        ARCH="$(uname -p)"

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
        echo "0 $NUM" > /sys/bus/netdevsim/new_device
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
