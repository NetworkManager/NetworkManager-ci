#!/bin/bash

BUILD_DIR="${BUILD_DIR:-/root/nm-build}"
RPM_DIR="NetworkManager/contrib/fedora/rpm/latest/RPMS/"
BUILD_ID="$1"
BUILD_REPO="${BUILD_REPO:-https://github.com/NetworkManager/NetworkManager.git}"
BUILD_SNAPSHOT="$2"
ARCH="${ARCH:-`arch`}"
WITH_DEBUG="${WITH_DEBUG:-yes}"
DO_INSTALL="${DO_INSTALL:-yes}"

if [ -z "$SUDO" ]; then
    unset SUDO
fi

# Workaround for not working repo
rm -rf /etc/yum.repos.d/CentOS-Media.repo

RC=1
# Get a build script from NM repo
if wget ${BUILD_REPO%.git}/raw/automation/contrib/rh-bkr/build-from-source.sh -O /root/nm-build-from-source.sh; then
    # Build NM
    BUILD_REPO=$BUILD_REPO \
    WITH_DEBUG=$WITH_DEBUG \
    BUILD_ID=$BUILD_ID \
    BUILD_SNAPSHOT=$BUILD_SNAPSHOT \
    bash /root/nm-build-from-source.sh; RC=$?
fi

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
