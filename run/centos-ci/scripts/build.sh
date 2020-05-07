#!/bin/bash

BUILD_DIR="${BUILD_DIR:-/root/nm-build}"
RPM_DIR="NetworkManager/contrib/fedora/rpm/latest/RPMS/"
BUILD_ID="$1"
BUILD_REPO="${BUILD_REPO-https://github.com/NetworkManager/NetworkManager.git}"
ARCH="${ARCH:-`arch`}"
WITH_DEBUG="${WITH_DEBUG:-yes}"
DO_INSTALL="${DO_INSTALL:-yes}"

if [ -z "$SUDO" ]; then
    unset SUDO
fi

# Workaround for not working repo
rm -rf /etc/yum.repos.d/CentOS-Media.repo

# Get a build script from NM repo
wget https://gitlab.freedesktop.org/NetworkManager/NetworkManager/raw/automation/contrib/rh-bkr/build-from-source.sh -O /root/nm-build-from-source.sh

# Build NM
BUILD_ID=$BUILD_ID bash /root/nm-build-from-source.sh; RC=$?

if [ $RC -eq 0 ]; then
    cp $BUILD_DIR/NetworkManager/examples/dispatcher/10-ifcfg-rh-routes.sh /etc/NetworkManager/dispatcher.d/
    cp $BUILD_DIR/NetworkManager/examples/dispatcher/10-ifcfg-rh-routes.sh /etc/NetworkManager/dispatcher.d/pre-up.d/
    $SUDO systemctl restart NetworkManager
    echo "BUILDING $BUILD_ID COMPLETED SUCCESSFULLY"
    exit 0
else
    echo "BUILDING $BUILD_ID FAILED"
    touch /tmp/nm_compilation_failed
    exit 1
fi
