install_fedora_packages () {
    # Enable rawhide sshd to root
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # Pip down some deps
    dnf -y install python3-pip libyaml-devel

    # Doesn't work on the newest aarch64 RHEL8
    python -m pip install --upgrade pip
    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy
    python -m pip install --upgrade --force pyyaml

    # Needed for gsm_sim
    dnf -y install perl-IO-Pty-Easy perl-IO-Tty

    # Dnf more deps
    dnf -y install \
        git nmap-ncat hostapd tcpreplay python3-netaddr dhcp-relay iw net-tools \
        psmisc firewalld dhcp-server ethtool python3-dbus python3-gobject dnsmasq \
        tcpdump wireshark-cli iputils iproute-tc gdb gcc wireguard-tools rp-pppoe tuned \
        mptcpd wpa_supplicant NetworkManager-initscripts-ifcfg-rh s390utils-base \
        --skip-broken

    # freeradius
    rm -rf /etc/raddb
    dnf -y remove freeradius
    dnf -y install freeradius
    rm -rf /tmp/nmci-raddb
    cp -ar /etc/raddb/ /tmp/nmci-raddb/

    install_behave_pytest

    # Install vpn dependencies
    dnf -y install NetworkManager-libreswan NetworkManager-openvpn openvpn ipsec-tools

    # Remove connectivity packages
    dnf -y remove \
        NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat


    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -y install NetworkManager-pptp
    fi

    if ! rpm -q --quiet NetworkManager-strongswan; then
        dnf -y install NetworkManager-strongswan
    fi

    if ! rpm -q --quiet strongswan; then
        dnf -y install strongswan strongswan-charon-nm
    fi

    if ! rpm -q --quiet NetworkManager-vpnc || ! rpm -q --quiet vpnc; then
        dnf -y install NetworkManager-vpnc
    fi

    # dracut testing
    dnf -y install \
        qemu-kvm lvm2 mdadm cryptsetup iscsi-initiator-utils \
        nfs-utils radvd gdb dracut-network scsi-target-utils dhcp-client

    install_plugins_dnf

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant

    # Install kernel-modules for currently running kernel
    dnf -y install kernel-modules-*-$(uname -r)

    # Make device mac address policy behave like old one
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link

    # disable dhcpd dispatcher script: rhbz1758476
    [ -f /etc/NetworkManager/dispatcher.d/12-dhcpd ] && sudo chmod -x /etc/NetworkManager/dispatcher.d/12-dhcpd

}
