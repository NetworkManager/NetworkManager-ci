install_el8_packages () {
    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    fi

    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy

    # Needed for gsm_sim
    dnf -4 -y install \
        $KOJI/perl-IO-Pty-Easy/0.10/5.fc28/noarch/perl-IO-Pty-Easy-0.10-5.fc28.noarch.rpm \
        $KOJI/perl-IO-Tty/1.12/11.fc28/$(arch)/perl-IO-Tty-1.12-11.fc28.$(arch).rpm \
        $KOJI/tcpreplay/4.2.5/4.fc28/$(arch)/tcpreplay-4.2.5-4.fc28.$(arch).rpm \
        $KOJI/rp-pppoe/3.15/1.fc35/$(arch)/rp-pppoe-3.15-1.fc35.$(arch).rpm


    # Dnf more deps
    dnf -4 -y install \
        git python3-netaddr dhcp-relay iw net-tools psmisc firewalld dhcp-server \
        ethtool python3-dbus python3-gobject dnsmasq tcpdump wireshark-cli file iputils \
        iproute-tc openvpn gcc coreutils-debuginfo python3-pyyaml tuned haveged \
        abrt-plugin-sosreport \
        --skip-broken

    install_behave_pytest

    # Install vpn dependencies
    dnf -4 -y install \
        $KOJI/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm \
        $KOJI/pkcs11-helper/1.22/5.fc28/$(arch)/pkcs11-helper-1.22-5.fc28.$(arch).rpm

    # openvpn not in s390x repo
    if [ $(arch) == s390x ] ; then
        dnf -4 -y install $KOJI/openvpn/2.4.9/1.fc30/s390x/openvpn-2.4.9-1.fc30.s390x.rpm
    fi

    # Install various NM dependencies
    dnf -4 -y remove \
        NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat

    # Install kernel-modules-internal for mac80211_hwsim
    VER=$(rpm -q --queryformat '%{VERSION}' kernel)
    REL=$(rpm -q --queryformat '%{RELEASE}' kernel)
    if ! grep -q -e 'CentOS .* release 8' /etc/redhat-release; then
        dnf -4 -y install \
            $BREW/rhel-8/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm
    else
        if ! wget https://koji.mbox.centos.org/pkgs/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm -O /tmp/kernel-modules-internal.rpm --no-check-certificate; then
            wget $FEDP/c8s/kernel-modules-internal-4.18.0-301.1.el8.x86_64.rpm -O /tmp/kernel-modules-internal.rpm
        fi
        dnf -y localinstall /tmp/kernel-modules-internal.rpm
    fi

    # Add OVS repo and install OVS
    if ! grep -q -e 'CentOS .* release 8' /etc/redhat-release; then
        cp -f  contrib/ovs/ovs-rhel8.repo /etc/yum.repos.d/ovs.repo
        yum -y install openvswitch2.17* openvswitch-selinux-extra-policy
        systemctl restart openvswitch
    else
        dnf -y install \
            $CBSC/openvswitch2.17/2.17.0/31.el8s/$(arch)/openvswitch2.17-2.17.0-31.el8s.$(arch).rpm \
            $CBSC/openvswitch2.17/2.17.0/31.el8s/$(arch)/python3-openvswitch2.17-2.17.0-31.el8s.$(arch).rpm \
            $CBSC/openvswitch-selinux-extra-policy/1.0/29.el8s/noarch/openvswitch-selinux-extra-policy-1.0-29.el8s.noarch.rpm
    fi

    # We still need pptp and pptpd in epel to be packaged
    # https://bugzilla.redhat.com/show_bug.cgi?id=1810542
    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install \
            $KOJI/NetworkManager-pptp/1.2.8/1.el8.3/$(arch)/NetworkManager-pptp-1.2.8-1.el8.3.$(arch).rpm \
            $KOJI/pptpd/1.4.0/18.fc28/$(arch)/pptpd-1.4.0-18.fc28.$(arch).rpm
    fi

    if ! rpm -q --quiet NetworkManager-vpnc || ! rpm -q --quiet vpnc; then
        dnf -4 -y install \
            $KOJI/vpnc/0.5.3/33.svn550.fc29/$(arch)/vpnc-0.5.3-33.svn550.fc29.$(arch).rpm \
            $KOJI/NetworkManager-vpnc/1.2.6/1.fc29/$(arch)/NetworkManager-vpnc-1.2.6-1.fc29.$(arch).rpm \
            $KOJI/vpnc-script/20171004/3.git6f87b0f.fc29/noarch/vpnc-script-20171004-3.git6f87b0f.fc29.noarch.rpm
    fi

    # strongswan
    if ! rpm -q --quiet NetworkManager-strongswan || ! rpm -q --quiet strongswan; then
        dnf -4 -y install \
            $KOJI/NetworkManager-strongswan/1.4.4/1.fc29/$(arch)/NetworkManager-strongswan-1.4.4-1.fc29.$(arch).rpm \
            $KOJI/strongswan/5.7.2/1.fc29/$(arch)/strongswan-5.7.2-1.fc29.$(arch).rpm \
            $KOJI/strongswan/5.7.2/1.fc29/$(arch)/strongswan-charon-nm-5.7.2-1.fc29.$(arch).rpm
    fi

    dnf -4 -y install \
        hostapd wpa_supplicant{,-debuginfo,-debugsource} --skip-broken

    # install wpa_supp and hostapd with 2.10 capabilities
    WS_VER=$(rpm -q --queryformat '%{VERSION}' wpa_supplicant |awk -F '.' '{print $2}')
    if [ $WS_VER -lt 10 ]; then
        dnf -4 -y install \
            $FEDP/wpa_supplicant-2.10/wpa_supplicant-2.10-1.el8.$(arch).rpm \
            $FEDP/wpa_supplicant-2.10/wpa_supplicant-debuginfo-2.10-1.el8.$(arch).rpm \
            $FEDP/wpa_supplicant-2.10/wpa_supplicant-debugsource-2.10-1.el8.$(arch).rpm
    fi

    HAPD_VER=$(rpm -q --queryformat '%{VERSION}' hostapd |awk -F '.' '{print $2}')
    if ! rpm -q --quiet hostapd || [ $HAPD_VER -lt 10 ]; then
        dnf -4 -y install \
            $FEDP/hostapd-2.10/hostapd-2.10-1.el8.$(arch).rpm \
            $FEDP/hostapd-2.10/hostapd-debuginfo-2.10-1.el8.$(arch).rpm \
            $FEDP/hostapd-2.10/hostapd-debugsource-2.10-1.el8.$(arch).rpm
            #$FEDP/hostapd-2.10/hostapd-logwatch-2.10-1.el8.$(arch).rpm
    fi

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant
    # Make crypto policies a bit less strict
    update-crypto-policies --set LEGACY
    systemctl restart wpa_supplicant
    systemctl restart haveged

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # Install non crashing MM
    dnf -4 -y upgrade \
        $FEDP/ModemManager-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-debuginfo-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-debugsource-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-devel-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-glib-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-glib-debuginfo-1.10.6-1.el8.x86_64.rpm --allowerasing

    # Install non crashing teamd 1684389
    dnf -y -4 update \
        $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/libteam-1.31-2.el8.$(arch).rpm \
        $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/libteam-devel-1.31-2.el8.$(arch).rpm \
        $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/teamd-1.31-2.el8.$(arch).rpm \
        $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/teamd-devel-1.31-2.el8.$(arch).rpm \
        $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/python3-libteam-1.31-2.el8.$(arch).rpm

    # dracut testing
    dnf -4 -y install \
        qemu-kvm lvm2 mdadm cryptsetup iscsi-initiator-utils nfs-utils radvd gdb dhcp-client
    if [[ $(uname -p) = "s390x" ]]; then
        # perl-Config-Genral not installable on s390x and needed by scsi-target-utils
        dnf -4 -y install \
            $BREW/rhel-8/packages/perl-Config-General/2.63/5.el8+7/noarch/perl-Config-General-2.63-5.el8+7.noarch.rpm
    fi
    dnf -4 -y install \
        $KOJI/scsi-target-utils/1.0.79/1.fc32/$(arch)/scsi-target-utils-1.0.79-1.fc32.$(arch).rpm

    install_plugins_dnf
}
