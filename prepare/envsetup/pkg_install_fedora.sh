install_fedora_packages () {
    # Update sshd in Fedora 32 to avoid rhbz1771946
    dnf -y -4 update \
        $KOJI/openssh/8.1p1/2.fc32/x86_64/openssh-8.1p1-2.fc32.x86_64.rpm \
        $KOJI/openssh/8.1p1/2.fc32/x86_64/openssh-server-8.1p1-2.fc32.x86_64.rpm \
        $KOJI/openssh/8.1p1/2.fc32/x86_64/openssh-clients-8.1p1-2.fc32.x86_64.rpm
    # Enable rawhide sshd to root
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    if grep -q Rawhide /etc/redhat-release || grep -q 33 /etc/redhat-release; then
        dnf -y install \
            $KOJI/ipsec-tools/0.8.2/17.fc32/$(arch)/ipsec-tools-0.8.2-17.fc32.$(arch).rpm
        dnf update -y
    fi
    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # Pip down some deps
    dnf -4 -y install python3-pip

    # Doesn't work on the newest aarch64 RHEL8
    python -m pip install --upgrade pip
    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy

    # Needed for gsm_sim
    dnf -4 -y install perl-IO-Pty-Easy perl-IO-Tty
    dnf -4 -y upgrade \
        $FEDP/ModemManager-1.10.6-1.fc30.x86_64.rpm \
        $FEDP/ModemManager-debuginfo-1.10.6-1.fc30.x86_64.rpm \
        $FEDP/ModemManager-debugsource-1.10.6-1.fc30.x86_64.rpm \
        $FEDP/ModemManager-devel-1.10.6-1.fc30.x86_64.rpm \
        $FEDP/ModemManager-glib-1.10.6-1.fc30.x86_64.rpm \
        $FEDP/ModemManager-glib-debuginfo-1.10.6-1.fc30.x86_64.rpm \
        --allowerasing

    # Dnf more deps
    dnf -4 -y install \
        git nmap-ncat hostapd tcpreplay python3-netaddr dhcp-relay iw net-tools \
        psmisc firewalld dhcp-server ethtool python3-dbus python3-gobject dnsmasq \
        tcpdump wireshark-cli iproute-tc gdb gcc wireguard-tools rp-pppoe \
        --skip-broken

    install_behave_pytest

    # Install vpn dependencies
    dnf -4 -y install NetworkManager-openvpn openvpn ipsec-tools
    PKG="NetworkManager-libreswan-1.2.12-1.fc34.3.x86_64.rpm"
    dnf -y install $FEDP/NM-libreswan_4compat/$PKG

    # Install various NM dependencies
    dnf -4 -y remove \
        NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat
    dnf -4 -y install \
        openvswitch2* NetworkManager-ovs

    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install NetworkManager-pptp
    fi

    if ! rpm -q --quiet NetworkManager-strongswan; then
        dnf -4 -y install NetworkManager-strongswan
    fi

    if ! rpm -q --quiet strongswan; then
        dnf -4 -y install strongswan strongswan-charon-nm
    fi

    if ! rpm -q --quiet NetworkManager-vpnc || ! rpm -q --quiet vpnc; then
        dnf -4 -y install NetworkManager-vpnc
    fi

    # dracut testing
    dnf -4 -y install \
        qemu-kvm lvm2 mdadm cryptsetup iscsi-initiator-utils \
        nfs-utils radvd gdb dracut-network scsi-target-utils dhcp-client

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant

    # Update and install the latest dbus
    dnf -4 -y update dbus*
    systemctl restart messagebus

    # Install kernel-modules for currently running kernel
    dnf -4 -y install kernel-modules-*-$(uname -r)

    install_plugins_dnf

    # Make device mac address policy behave like old one
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link

    # disable dhcpd dispatcher script: rhbz1758476
    [ -f /etc/NetworkManager/dispatcher.d/12-dhcpd ] && sudo chmod -x /etc/NetworkManager/dispatcher.d/12-dhcpd

}
