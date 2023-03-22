install_el7_packages () {
    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi


    # Download some deps
    yum -y install perl-IO-Pty-Easy wireshark
    yum -y install python3 python3-pip
    yum -y install gcc

    echo python3 > /tmp/python_command
    export_python_command

    python -m pip install --upgrade pip
    python -m pip install setuptools --upgrade
    python -m pip install pexpect
    python -m pip install pyroute2
    python -m pip install netaddr
    python -m pip install IPy
    python -m pip install python-dbusmock==0.26.1
    python -m pip install pyte
    python -m pip install pyyaml


    # install dbus-python3 for s390x via pip
    if uname -a |grep -q s390x; then
        yum -y install \
        python3-devel cairo-gobject-devel pygobject3-devel cairo-devel cairo pycairo
        python3 -m pip install dbus-python
        python3 -m pip install PyGObject
        python3 -m pip install scapy
    fi

    yum -y install \
        git iw net-tools wireshark psmisc bridge-utils firewalld dhcp ethtool \
        python36-dbus python36-gobject dnsmasq NetworkManager-vpnc iproute-tc \
        openvpn rp-pppoe s390utils-base \
        --skip-broken

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
