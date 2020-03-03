#!/bin/bash

DISTRO=""
VERSION=""
RPM_DIR="/root/nm-build/NetworkManager/contrib/fedora/rpm/latest/RPMS"
ARCH_DIR=""
RESULTS="/tmp/results/Test_results-*"
KEY=$1

if grep -q CentOS /etc/redhat-release ; then
    if grep -q 8.1 /etc/redhat-release; then
        DISTRO="centos-8-1"
    elif grep -q 8.2 /etc/redhat-release; then
        DISTRO="centos-8-2"
    elif grep -q 8.3 /etc/redhat-release; then
        DISTRO="centos-8-3"
    elif grep -q 8.4 /etc/redhat-release; then
        DISTRO="centos-8-4"
    elif grep -q 8.5 /etc/redhat-release; then
        DISTRO="centos-8-5"
    elif grep -q 8.6 /etc/redhat-release; then
        DISTRO="centos-8-6"
    elif grep -q 8.7 /etc/redhat-release; then
        DISTRO="centos-8-7"
    elif grep -q 8.8 /etc/redhat-release; then
        DISTRO="centos-8-8"
    elif grep -q 8.9 /etc/redhat-release; then
        DISTRO="centos-8-9"
    fi

    VERSION=$(rpm -q NetworkManager | awk -F '.el8' '{print $1}')
fi


ARCH_DIR="/tmp/nightly/$DISTRO/$VERSION"

mkdir -p $ARCH_DIR
cp $RPM_DIR/noarch/* $ARCH_DIR
cp $RPM_DIR/x86_64/* $ARCH_DIR
cp $RESULTS $ARCH_DIR

RSYNC_PASSWORD=$KEY rsync -av /tmp/nightly/ networkmanager@artifacts.ci.centos.org::networkmanager/nightly
