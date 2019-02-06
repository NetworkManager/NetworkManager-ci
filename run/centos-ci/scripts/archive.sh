#!/bin/bash

DISTRO=""
VERSION=""
RPM_DIR="/root/nm-build/NetworkManager/contrib/fedora/rpm/latest/RPMS"
ARCH_DIR=""
RESULTS="/tmp/results/Test_results-*"
KEY=$1

if grep -q CentOS /etc/redhat-release ; then
    if grep -q 7.3 /etc/redhat-release; then
        DISTRO="centos-7-3"
    elif grep -q 7.4 /etc/redhat-release; then
        DISTRO="centos-7-4"
    elif grep -q 7.5 /etc/redhat-release; then
        DISTRO="centos-7-5"
    elif grep -q 7.6 /etc/redhat-release; then
        DISTRO="centos-7-6"
    fi

    VERSION=$(rpm -q NetworkManager | awk -F '.el7' '{print $1}')
fi


ARCH_DIR="/tmp/nightly/$DISTRO/$VERSION"

mkdir -p $ARCH_DIR
cp $RPM_DIR/noarch/* $ARCH_DIR
cp $RPM_DIR/x86_64/* $ARCH_DIR
cp $RESULTS $ARCH_DIR

RSYNC_PASSWORD=$KEY rsync -av /tmp/nightly/ networkmanager@artifacts.ci.centos.org::networkmanager/nightly
