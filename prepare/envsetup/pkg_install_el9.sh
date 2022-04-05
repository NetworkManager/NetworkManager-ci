install_el9_packages () {
    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    fi

    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy

    # Dnf more deps
    dnf -4 -y install \
        git python3-netaddr dhcp-relay iw net-tools psmisc firewalld dhcp-server \
        ethtool python3-dbus python3-gobject dnsmasq tcpdump wireshark-cli file \
        iproute-tc openvpn perl-IO-Tty dhcp-client rpm-build gcc initscripts \
        wireguard-tools python3-pyyaml \
        --skip-broken

    # Install non distro deps
    dnf -4 -y install \
        $KOJI/tcpreplay/4.3.3/3.fc34/$(arch)/tcpreplay-4.3.3-3.fc34.$(arch).rpm \
        $KOJI/libdnet/1.14/1.fc34/$(arch)/libdnet-1.14-1.fc34.$(arch).rpm \
        $KOJI/iw/5.4/3.fc34/$(arch)/iw-5.4-3.fc34.$(arch).rpm \
        $BREW/rhel-9/packages/libsmi/0.4.8/27.el9.1/$(arch)/libsmi-0.4.8-27.el9.1.$(arch).rpm \
        $BREW/rhel-9/packages/wireshark/3.4.0/1.el9.1/$(arch)/wireshark-cli-3.4.0-1.el9.1.$(arch).rpm \
        $KOJI/rp-pppoe/3.15/1.fc35/$(arch)/rp-pppoe-3.15-1.fc35.$(arch).rpm \
        --skip-broken

    install_behave_pytest

    # Install centos deps
    if grep -q -e 'CentOS' /etc/redhat-release; then
        # OVS deps and GSM perl deps
        dnf -y install \
            $CBSC/openvswitch2.16/2.16.0/33.el9s/$(arch)/openvswitch2.16-2.16.0-33.el9s.$(arch).rpm \
            $CBSC/openvswitch-selinux-extra-policy/1.0/30.el9s/noarch/openvswitch-selinux-extra-policy-1.0-30.el9s.noarch.rpm \
            $KHUB/perl-IO-Tty/1.16/4.el9/$(arch)/perl-IO-Tty-1.16-4.el9.$(arch).rpm
    else
        cp -f  contrib/ovs/ovs-rhel9.repo /etc/yum.repos.d/ovs.repo
        yum -y install openvswitch2.16*
        systemctl restart openvswitch
    fi


    # Install vpn dependencies
    dnf -4 -y install \
        $KOJI/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm \
        $KOJI/pkcs11-helper/1.22/5.fc28/$(arch)/pkcs11-helper-1.22-5.fc28.$(arch).rpm

    # libreswan please remove when in compose 12012021
    if ! rpm -q --quiet NetworkManager-libreswan || ! rpm -q --quiet libreswan; then
        dnf -4 -y install \
            $BREW/rhel-9/packages/NetworkManager-libreswan/1.2.14/1.el9/$(arch)/NetworkManager-libreswan-1.2.14-1.el9.$(arch).rpm
    fi
    # openvpn, please remove once in epel 12012021
    if ! rpm -q --quiet NetworkManager-openvpn || ! rpm -q --quiet openvpn; then
        dnf -4 -y install \
            $KOJI/NetworkManager-openvpn/1.8.12/1.fc33.1/$(arch)/NetworkManager-openvpn-1.8.12-1.fc33.1.$(arch).rpm \
            $KOJI/openvpn/2.5.0/1.fc34/$(arch)/openvpn-2.5.0-1.fc34.$(arch).rpm \
            $KOJI/pkcs11-helper/1.27.0/2.fc34/$(arch)/pkcs11-helper-1.27.0-2.fc34.$(arch).rpm
    fi
    # strongswan remove once in epel 12012021
    if ! rpm -q --quiet NetworkManager-strongswan || ! rpm -q --quiet strongswan; then
        dnf -4 -y install \
            $KOJI/trousers/0.3.15/2.fc34/$(arch)/trousers-lib-0.3.15-2.fc34.$(arch).rpm \
            $KOJI/NetworkManager-strongswan/1.5.0/3.fc34/$(arch)/NetworkManager-strongswan-1.5.0-3.fc34.$(arch).rpm \
            $KOJI/strongswan/5.9.3/1.fc34/$(arch)/strongswan-5.9.3-1.fc34.$(arch).rpm \
            $KOJI/strongswan/5.9.3/1.fc34/$(arch)/strongswan-charon-nm-5.9.3-1.fc34.$(arch).rpm
    fi

    # Remove connectivity checks
    dnf -4 -y remove \
        NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat

    # Install kernel-modules-internal for mac80211_hwsim
    VER=$(rpm -q --queryformat '%{VERSION}' kernel)
    REL=$(rpm -q --queryformat '%{RELEASE}' kernel)
    if grep Red /etc/redhat-release; then
        dnf -4 -y install \
            $BREW/rhel-9/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm
    else
        dnf -4 -y install \
            https://kojihub.stream.centos.org/kojifiles/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm
    fi

    # We still need pptp and pptpd in epel to be packaged
    # https://bugzilla.redhat.com/show_bug.cgi?id=1810542
    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install \
            $KOJI/NetworkManager-pptp/1.2.8/2.fc34.1/$(arch)/NetworkManager-pptp-1.2.8-2.fc34.1.$(arch).rpm \
            $KOJI/pptpd/1.4.0/25.fc34/$(arch)/pptpd-1.4.0-25.fc34.$(arch).rpm \
            $KOJI/pptp/1.10.0/11.eln107/$(arch)/pptp-1.10.0-11.eln107.$(arch).rpm
    fi

    if ! rpm -q --quiet NetworkManager-ppp; then
        VER=$(rpm -q --queryformat '%{VERSION}' NetworkManager)
        REL=$(rpm -q --queryformat '%{RELEASE}' NetworkManager)
        dnf -y install \
            $BREW/rhel-9/packages/NetworkManager/$VER/$REL/$(arch)/NetworkManager-ppp-$VER-$REL.$(arch).rpm
    fi

    # install wpa_supp and hostapd with 2.10 capabilities
    dnf -4 -y install \
        hostapd wpa_supplicant{,-debuginfo,-debugsource} --skip-broken

    WS_VER=$(rpm -q --queryformat '%{VERSION}' wpa_supplicant |awk -F '.' '{print $2}')
    if [ $WS_VER -lt 10 ]; then
        dnf -4 -y install \
            $KHUB/wpa_supplicant/2.10/1.el9/$(arch)/wpa_supplicant-2.10-1.el9.$(arch).rpm \
            $KHUB/wpa_supplicant/2.10/1.el9/$(arch)/wpa_supplicant-debuginfo-2.10-1.el9.x86_64.rpm \
            $KHUB/wpa_supplicant/2.10/1.el9/$(arch)/wpa_supplicant-debugsource-2.10-1.el9.x86_64.rpm
    fi

    HAPD_VER=$(rpm -q --queryformat '%{VERSION}' hostapd |awk -F '.' '{print $2}')
    if ! rpm -q --quiet hostapd || [ $HAPD_VER -lt 10 ]; then
        dnf -4 -y install \
            $KHUB//hostapd/2.10/1.el9/$(arch)/hostapd-2.10-1.el9.$(arch).rpm \
            $KHUB//hostapd/2.10/1.el9/$(arch)/hostapd-debuginfo-2.10-1.el9.$(arch).rpm \
            $KHUB//hostapd/2.10/1.el9/$(arch)/hostapd-debugsource-2.10-1.el9.$(arch).rpm

    fi

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant
    # Enable TLS 1.0 for old cisco APs
    sed -i 's/TLS.MinProtocol = TLSv1.2/TLS.MinProtocol = TLSv1.0/' /etc/crypto-policies/back-ends/opensslcnf.config

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # dracut testing
    dnf -4 -y install \
        qemu-kvm lvm2 mdadm cryptsetup iscsi-initiator-utils nfs-utils radvd gdb dhcp-client \
        $KOJI/scsi-target-utils/1.0.79/3.fc34/$(arch)/scsi-target-utils-1.0.79-3.fc34.$(arch).rpm \
        $KOJI/perl-Config-General/2.63/14.fc34/noarch/perl-Config-General-2.63-14.fc34.noarch.rpm

    install_plugins_dnf

    # Disable mac radnomization
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link
    sleep 0.5
    systemctl restart systemd-udevd
    systemctl restart wpa_supplicant

}
