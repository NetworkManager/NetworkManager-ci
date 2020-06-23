#!/bin/bash

function setup () {
    MAJOR="$(uname -r |awk -F '-' '{print $1}')"
    MINOR="$(uname -r |awk -F '-' '{print $2}'|awk -F '.' '{print  $1"."$2}')"
    LINUX=linux-$MAJOR-$MINOR
    # We need this patched netdevsim device to support ring/coal ethtool options
    PATCH="0001-netdevsim-add-mock-support-for-coalescing-and-ring-o-1.patch"
    DRIVER="drivers/net/netdevsim"

    # If we have all necessary things done
    if ! test -f /tmp/netdevsim_installed; then
        URL="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/kernel"
        # Install build dependencies
        yum -y install \
               wget git kernel-headers kernel-devel gcc \
               patch elfutils-libelf-devel bc yasm

        # Install srpm
        rpm -i $URL/$MAJOR/$MINOR/src/kernel-$MAJOR-$MINOR.src.rpm
        tar xf /root/rpmbuild/SOURCES/$LINUX.tar.xz -C /tmp
        cp tmp/$PATCH /tmp/$LINUX
        cd /tmp/$LINUX
        # Patch module
        patch -p1 < $PATCH

        cd $DRIVER
        # If we cannot build exit 1
        if ! make -C /lib/modules/$(uname -r)/build M=$PWD; then
            exit 1
        fi

        # We are all OK installing deps
        touch /tmp/netdevsim_installed
    fi

    # Remove module in case netdevsim is loaded
    if lsmod |grep netdevsim > /dev/null; then
        modprobe -r netdevsim
    fi

    # Change dir to the patched driver dir
    cd /tmp/$LINUX/$DRIVER

    # If we are able to insert module create devices and exit 0
    if insmod netdevsim.ko; then
        echo "0 3" > /sys/bus/netdevsim/new_device
        touch /tmp/netdevsim
    else
        # If we fail to load exit 1
        exit 1
    fi
    exit 0
}

function teardown () {
    modprobe -r netdevsim
    rm -rf /tmp/netdevsim
}
if [ "x$1" != "xteardown" ]; then
    setup
else
    teardown
fi
