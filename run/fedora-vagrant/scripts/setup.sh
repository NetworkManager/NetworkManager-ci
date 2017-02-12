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
        httpd \
        polkit \
        python2-pexpect \
        python2-behave \
        ethtool \
        git \
        bridge-utils \
        wireshark-cli \
        dbus-python \
        python-gobject \
        dnsmasq

sudo dnf -y update firewalld dnsmasq --best

sudo systemctl restart NetworkManager.service && sleep 5

# We need test user for some tests and sudo for vagrant user
sudo useradd test
echo "networkmanager" | sudo passwd test --stdin
sudo echo "%vagrant ALL=(ALL)   NOPASSWD: ALL" >> /etc/sudoers
# Create directory for web based results
mkdir -p /var/www/html/results/
# Show wide lines
echo "IndexOptions NameWidth=*" >> /etc/httpd/conf.d/autoindex.conf
# Start HTTPD
systemctl restart httpd.service
