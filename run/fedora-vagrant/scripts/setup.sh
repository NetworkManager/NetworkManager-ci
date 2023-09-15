#!/bin/bash

# Install dependencies
yum -y install \
        NetworkManager-team \
        NetworkManager-wifi \
        NetworkManager-config-server \
        NetworkManager-pptp \
        NetworkManager-openvpn \
        NetworkManager-libreswan \
        pptp \
        rp-pppoe \
        pptpd \
        httpd \
        polkit \
        python2-behave \
        ethtool \
        git \
        bridge-utils \
        wireshark-cli \
        dbus-python \
        python-gobject \
        wireshark \
        dnsmasq

# some minor compatibility items
dnf -y update firewalld dnsmasq --best
yum -y install python2-pexpect
yum -y install pexpect
yum -y install python-lxml

systemctl restart NetworkManager.service && sleep 5

# FIXME: avoid debuginfo installation in low space semaphore
touch /tmp/nm_no_debug

# We need test user for some tests and for vagrant user
useradd test
echo "networkmanager" | passwd test --stdin
echo "%vagrant ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
# Create directory for web based results
mkdir -p /var/www/html/results/
# Show wide lines
echo "IndexOptions NameWidth=*" >> /etc/httpd/conf.d/autoindex.conf
# Start HTTPD
systemctl restart httpd.service

# Skip long tests
touch /tmp/nm_skip_long
