#!/bin/bash

# We need test user for some tests and sudo for vagrant user
sudo useradd test
echo "networkmanager" | sudo passwd test --stdin
sudo echo "%vagrant ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
# Create directory for web based results
mkdir -p /tmp/results/

# Skip long tests
touch /tmp/nm_skip_long

# Add some extra repos
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# For some reason names can differ, so enable both powertools
yum config-manager --set-enabled PowerTools
yum config-manager --set-enabled powertools
curl https://copr.fedorainfracloud.org/coprs/nmstate/nm-build-deps/repo/epel-8/nmstate-nm-build-deps-epel-8.repo > /etc/yum.repos.d/nmstate-nm-build-deps-epel-8.repo

# Install dependencies
sudo dnf -y install \
        python3 \
        NetworkManager-team \
        NetworkManager-wifi \
        NetworkManager-config-server \
        NetworkManager-pptp \
        NetworkManager-openvpn \
        NetworkManager-libreswan \
        pptp \
        rp-pppoe \
        pptpd \
        radvd \
        polkit \
        python2-behave \
        ethtool \
        git \
        bridge-utils \
        wireshark-cli \
        wireshark \
        bash-completion \
        dnsmasq \
        gcc \
        make \
        rpm-build \
        radvd \
        rsync \
        bash-completion \
        radvd \
        dbus-x11 \
        --skip-broken \
        --nobest

# Install OVS
sudo dnf install -y https://cbs.centos.org/kojifiles/packages/openvswitch/2.12.0/1.el8/x86_64/openvswitch-2.12.0-1.el8.x86_64.rpm

# Install rp-pppoe for pppoe feature
sudo dnf install -y https://kojipkgs.fedoraproject.org//packages/rp-pppoe/3.12/11.fc28/$(arch)/rp-pppoe-3.12-11.fc28.$(arch).rpm

# some minor compatibility items
sudo dnf -y update firewalld dnsmasq --best
sudo yum -y install easy_install
sudo pip3 install pexpect
sudo yum -y install python-lxml

sudo systemctl restart NetworkManager.service && sleep 5

# FIXME: avoid debuginfo installation in low space semaphore
touch /tmp/nm_no_debug
