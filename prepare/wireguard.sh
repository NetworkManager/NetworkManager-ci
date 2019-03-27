#!/bin/bash
set -e

# test whether wireguard module and utility are already installed
if which wg > /dev/null && lsmod | grep -q wireguard ; then
    echo "wireguard already configured"
    exit 0
fi

# install tools required for build
sudo yum -y install libmnl-devel elfutils-libelf-devel kernel-devel-$(uname -r) pkg-config gcc git

cd tmp/

# cleanum and clone repo
rm -rf WireGuard
git clone https://git.zx2c4.com/WireGuard
cd WireGuard

# checkout version 0.0.20190227 (safer to use comit hash than version - thaller)
git checkout ab146d92c353cb111b31ea8b672d4849fcbe8397

# build
cd src
make
sudo make install

# check that everything works
if which wg > /dev/null ; then
    exit 0
else
    echo "wireguard utility 'wg' not found"
    exit 1
fi


if lsmod | grep -q wireguard ; then
    exit 0
else
    echo "module wireguard not loaded"
    exit 1
fi
