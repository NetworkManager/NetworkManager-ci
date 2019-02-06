#!/bin/bash

# Install dependencies
sudo yum -y install \
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
        dbus-python \
        python-gobject \
        wireshark \
        bash-completion \
        dnsmasq

# some minor compatibility items
sudo dnf -y update firewalld dnsmasq --best
sudo yum -y install easy_install
sudo pip install pexpect
sudo yum -y install python-lxml

sudo systemctl restart NetworkManager.service && sleep 5

# FIXME: avoid debuginfo installation in low space semaphore
touch /tmp/nm_no_debug

# We need test user for some tests and sudo for vagrant user
sudo useradd test
echo "networkmanager" | sudo passwd test --stdin
sudo echo "%vagrant ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
# Create directory for web based results
mkdir -p /tmp/results/

# Skip long tests
touch /tmp/nm_skip_long
