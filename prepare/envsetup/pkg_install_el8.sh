install_el8_packages () {
    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    fi

    # Add mptcpd repo
    cp install/mptcpd-el8/mptcpd-el8.repo /etc/yum.repos.d/

    # install python3.11
    PKGS_INSTALL="$PKGS_INSTALL python3.11 python3.11-pip python3.11-devel"

    # Needed for gsm_sim
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/perl-IO-Pty-Easy/0.10/5.fc28/noarch/perl-IO-Pty-Easy-0.10-5.fc28.noarch.rpm \
        $KOJI/perl-IO-Tty/1.12/11.fc28/$(arch)/perl-IO-Tty-1.12-11.fc28.$(arch).rpm \
        $KOJI/tcpreplay/4.2.5/4.fc28/$(arch)/tcpreplay-4.2.5-4.fc28.$(arch).rpm \
        $KOJI/rp-pppoe/3.15/1.fc35/$(arch)/rp-pppoe-3.15-1.fc35.$(arch).rpm"

    # Enable nmstate-2 from copr
    dnf copr enable -y nmstate/nmstate-git

    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL bzip2 coreutils-debuginfo file haveged openvpn python3.11-pyyaml \
        systemd-devel cairo-devel cairo-gobject-devel gobject-introspection-devel dbus-devel"

    # Install vpn dependencies
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm \
        $KOJI/pkcs11-helper/1.22/5.fc28/$(arch)/pkcs11-helper-1.22-5.fc28.$(arch).rpm"

    # openvpn not in s390x repo
    if [ $(arch) == s390x ] ; then
        PKGS_INSTALL="$PKGS_INSTALL $KOJI/openvpn/2.4.9/1.fc30/s390x/openvpn-2.4.9-1.fc30.s390x.rpm \
            $KOJI/NetworkManager-openvpn/1.8.10/1.el8.1/s390x/NetworkManager-openvpn-1.8.10-1.el8.1.s390x.rpm"
    fi

    # Install kernel-modules-internal for mac80211_hwsim
    # in case we have more kernels take the first (as we do no reboot)
    VER=$(rpm -q --queryformat '[%{VERSION}\n]' kernel |tail -n1)
    REL=$(rpm -q --queryformat '[%{RELEASE}\n]' kernel |tail -n1)
    if grep -q -e 'CentOS' /etc/redhat-release; then
        PKGS_INSTALL="$PKGS_INSTALL \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-devel-$VER-$REL.$(arch).rpm"
    else
        PKGS_INSTALL="$PKGS_INSTALL \
            $BREW/rhel-8/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $BREW/rhel-8/packages/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm"
    fi

    # Add OVS repo and install OVS
    if grep -q -e 'CentOS .* release 8' /etc/redhat-release; then
        POLICY_VER=$(get_centos_pkg_release "$CBSC/openvswitch-selinux-extra-policy/1.0/")
        OVS_VER=$(get_centos_pkg_release "$CBSC/openvswitch2.17/2.17.0/")
        PKGS_INSTALL="$PKGS_INSTALL \
            $CBSC/openvswitch2.17/2.17.0/$OVS_VER/$(arch)/openvswitch2.17-2.17.0-$OVS_VER.$(arch).rpm \
            $CBSC/openvswitch2.17/2.17.0/$OVS_VER/$(arch)/python3-openvswitch2.17-2.17.0-$OVS_VER.$(arch).rpm \
            $CBSC/openvswitch-selinux-extra-policy/1.0/$POLICY_VER/noarch/openvswitch-selinux-extra-policy-1.0-$POLICY_VER.noarch.rpm"
    else
        cp -f  contrib/ovs/ovs-rhel8.repo /etc/yum.repos.d/ovs.repo
        PKGS_INSTALL="$PKGS_INSTALL openvswitch2.17* openvswitch-selinux-extra-policy"
    fi

    # We still need pptp and pptpd in epel to be packaged
    # https://bugzilla.redhat.com/show_bug.cgi?id=1810542
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/NetworkManager-pptp/1.2.8/1.el8.3/$(arch)/NetworkManager-pptp-1.2.8-1.el8.3.$(arch).rpm \
        $KOJI/pptpd/1.4.0/18.fc28/$(arch)/pptpd-1.4.0-18.fc28.$(arch).rpm"

    #vpnc
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/vpnc/0.5.3/33.svn550.fc29/$(arch)/vpnc-0.5.3-33.svn550.fc29.$(arch).rpm \
        $KOJI/NetworkManager-vpnc/1.2.6/1.fc29/$(arch)/NetworkManager-vpnc-1.2.6-1.fc29.$(arch).rpm \
        $KOJI/vpnc-script/20171004/3.git6f87b0f.fc29/noarch/vpnc-script-20171004-3.git6f87b0f.fc29.noarch.rpm"

    # strongswan
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/NetworkManager-strongswan/1.4.4/1.fc29/$(arch)/NetworkManager-strongswan-1.4.4-1.fc29.$(arch).rpm \
        $KOJI/strongswan/5.7.2/1.fc29/$(arch)/strongswan-5.7.2-1.fc29.$(arch).rpm \
        $KOJI/strongswan/5.7.2/1.fc29/$(arch)/strongswan-charon-nm-5.7.2-1.fc29.$(arch).rpm"

    # install wpa_supp and hostapd with 2.10 capabilities
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $FEDP/wpa_supplicant-2.10/wpa_supplicant-2.10-1.el8.$(arch).rpm \
        $FEDP/wpa_supplicant-2.10/wpa_supplicant-debuginfo-2.10-1.el8.$(arch).rpm \
        $FEDP/wpa_supplicant-2.10/wpa_supplicant-debugsource-2.10-1.el8.$(arch).rpm"

    PKGS_UPGRADE="$PKGS_UPGRADE \
        $FEDP/hostapd-2.10/hostapd-2.10-1.el8.$(arch).rpm \
        $FEDP/hostapd-2.10/hostapd-debuginfo-2.10-1.el8.$(arch).rpm \
        $FEDP/hostapd-2.10/hostapd-debugsource-2.10-1.el8.$(arch).rpm"
        #$FEDP/hostapd-2.10/hostapd-logwatch-2.10-1.el8.$(arch).rpm

    # Install non crashing MM
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $FEDP/ModemManager-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-debuginfo-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-debugsource-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-devel-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-glib-1.10.6-1.el8.x86_64.rpm \
        $FEDP/ModemManager-glib-debuginfo-1.10.6-1.el8.x86_64.rpm"

    # Install non crashing teamd 1684389 (only z-stream RHEL8)
    if ! grep -q -e 'CentOS .* release 8' /etc/redhat-release; then
        PKGS_UPGRADE="$PKGS_UPGRADE\
            $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/libteam-1.31-2.el8.$(arch).rpm \
            $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/libteam-devel-1.31-2.el8.$(arch).rpm \
            $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/teamd-1.31-2.el8.$(arch).rpm \
            $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/teamd-devel-1.31-2.el8.$(arch).rpm \
            $BREW/rhel-8/packages/libteam/1.31/2.el8/$(arch)/python3-libteam-1.31-2.el8.$(arch).rpm"
    fi

    # dracut testing
    if [[ $(arch) = "s390x" ]]; then
        # perl-Config-Genral not installable on s390x and needed by scsi-target-utils
        PKGS_INSTALL="$PKGS_INSTALL \
            $BREW/rhel-8/packages/perl-Config-General/2.63/5.el8+7/noarch/perl-Config-General-2.63-5.el8+7.noarch.rpm"
    fi
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/scsi-target-utils/1.0.79/1.fc32/$(arch)/scsi-target-utils-1.0.79-1.fc32.$(arch).rpm"

    if [ "$(arch)" == "aarch64" ]; then
        dnf -y install iwl*-firmware
    fi

    # Update to non crashing libreswan as RHEL-13123
    PKGS_UPGRADE="$PKGS_UPGRADE \
        https://vbenes.fedorapeople.org/NM/NetworkManager-libreswan-1.2.10-4.1.rhel13123.1.el8.x86_64.rpm"

    # This uses PKGS_{INSTALL,UPGRADE,REMOVE} and performs install
    install_common_packages

    # Additional PIP packages
    python3l -m pip install netaddr==0.10.1
    python3l -m pip install pycairo==0.16.3
    python3l -m pip install pygobject==3.40.0
    python3l -m pip install systemd==0.17.1
    python3l -m pip install dbus-python==1.3.2

    # Make crypto policies a bit less strict
    update-crypto-policies --set LEGACY
    systemctl restart wpa_supplicant
    systemctl restart haveged
}
