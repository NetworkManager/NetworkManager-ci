#!/bin/bash
set -x

function setup () {
    # If $1 is empty, $NUM defaults to "3"
    NUM="${1:-3}"
    MAJOR="$(uname -r |awk -F '-' '{print $1}')"
    MINOR="$(uname -r |awk -F '-' '{print $2}'| rev| cut -d. -f2-  |rev)"
    MINOR_NUM="$(uname -r |awk -F '-' '{print $2}'|  cut -d. -f1 )"
    LINUX=linux-$MAJOR-$MINOR
    # We need this patched netdevsim device to support ring/coal ethtool options and physical address
    PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-1.patch"
    # for newer kernels, only physical address patch must be applied
    # PATCH="0001-netdevsim-physical-address.patch"
    DRIVER="drivers/net/netdevsim"

    if grep Fedora /etc/redhat-release; then
        URL='https://kojipkgs.fedoraproject.org//packages/kernel'
        LINUX="$(echo $LINUX |awk -F '.' '{print $1 "." $2}')"
        PATCH="0001-netdevsim-physical-address.patch"
    elif grep "release 8" /etc/redhat-release; then
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/kernel"
        (( $MINOR_NUM >= 291 )) && PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-2.patch"
        (( $MINOR_NUM >= 306 )) && PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-3.patch"
    elif grep "release 9" /etc/redhat-release; then
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages/kernel"
        LINUX=linux-$MAJOR-${MINOR%.el9}
        PATCH="0001-netdevsim-physical-address.patch"
    fi

    # If we have all necessary things done
    if ! test -f /tmp/netdevsim_installed; then

        # Install build dependencies
        yum -y install \
               wget git kernel-headers kernel-devel gcc \
               patch elfutils-libelf-devel bc yasm

        # Install srpm (first try manualy cached file in /root)
        rpm -i /root/kernel-$MAJOR-$MINOR.src.rpm || \
        rpm -i $URL/$MAJOR/$MINOR/src/kernel-$MAJOR-$MINOR.src.rpm
        tar xf /root/rpmbuild/SOURCES/$LINUX.tar.xz -C /tmp
        cp tmp/$PATCH /tmp/$LINUX
        cd /tmp/$LINUX
        # Patch module
        patch -p1 < $PATCH || { echo "Unable to patch, please fix the patch"; exit 1; }

        cd $DRIVER
        # If we cannot build exit 1
        make -C /lib/modules/$(uname -r)/build M=$PWD || \
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
    cd /tmp/$LINUX/$DRIVER

    # If we are able to insert module create devices and exit 0
    echo "** installing the patched one"
    if modprobe netdevsim; then
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
