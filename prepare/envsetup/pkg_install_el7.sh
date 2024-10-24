install_el7_packages () {
    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi


    # Download some deps
    yum -y install perl-IO-Pty-Easy wireshark
    yum -y install python3 python3-pip
    yum -y install gcc

    # installing python3-* package causes removal of /usr/bin/python
    ln -s $(ls `which python3`* | grep '[0-9]$' | sort -V | tail -n1) /usr/bin/python3l


    python3l -m pip install --upgrade pip
    python3l -m pip install setuptools --upgrade
    python3l -m pip install pexpect
    python3l -m pip install pyroute2
    python3l -m pip install netaddr
    python3l -m pip install IPy
    python3l -m pip install python-dbusmock==0.26.1
    python3l -m pip install pyte
    python3l -m pip install pyyaml
    python3l -m pip install systemd


    # install dbus-python3 for s390x via pip
    if uname -a |grep -q s390x; then
        yum -y install \
        python3-devel cairo-gobject-devel pygobject3-devel cairo-devel cairo pycairo
        python3l -m pip install dbus-python
        python3l -m pip install PyGObject
        python3l -m pip install scapy
    fi

    yum -y install \
        git iw net-tools wireshark psmisc bridge-utils firewalld dhcp ethtool \
        python36-dbus python36-gobject dnsmasq NetworkManager-vpnc iproute-tc \
        openvpn rp-pppoe s390utils-base valgrind ModemManager usb_modeswitch \
        usbutils jq httpd libselinux-python3l python-inotify \
        --skip-broken

    # freeradius
    rm -rf /etc/raddb
    yum -4 -y remove freeradius
    yum -4 -y install freeradius
    rm -rf /tmp/nmci-raddb
    cp -ar /etc/raddb/ /tmp/nmci-raddb/

    yum -y install \
        $KOJI/hostapd/2.8/1.el7/$(arch)/hostapd-2.8-1.el7.$(arch).rpm
    yum -y remove \
        NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat

    install_behave_pytest

    # Add OVS repo and install OVS
    mv -f  contrib/ovs/ovs-rhel7.repo /etc/yum.repos.d/ovs.repo
    yum -y install openvswitch

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # Tune wpa_supplicant to log into journal and enable debugging
    systemctl stop wpa_supplicant
    sed -i 's!ExecStart=/usr/sbin/wpa_supplicant -u -f /var/log/wpa_supplicant.log -c /etc/wpa_supplicant/wpa_supplicant.conf!ExecStart=/usr/sbin/wpa_supplicant -u -c /etc/wpa_supplicant/wpa_supplicant.conf!' /etc/systemd/system/wpa_supplicant.service
    sed -i 's!OTHER_ARGS="-P /var/run/wpa_supplicant.pid"!OTHER_ARGS="-P /var/run/wpa_supplicant.pid -dddK"!' /etc/sysconfig/wpa_supplicant
    systemctl restart wpa_supplicant

    if ! rpm -q --quiet NetworkManager-strongswan; then
        yum -y install NetworkManager-strongswan strongswan
    fi

    if ! rpm -q --quiet strongswan; then
        yum -y install strongswan strongswan-charon-nm
    fi

    install_plugins_yum
}
