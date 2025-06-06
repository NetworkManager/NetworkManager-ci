install_el9_packages () {
    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    fi

    # install python3.11
    PKGS_INSTALL="$PKGS_INSTALL python3.11 python3.11-pip python3.11-devel"

    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL \
        python3.11-pyyaml systemd-devel cairo-devel cairo-gobject-devel gobject-introspection-devel
        dbus-devel ModemManager dhcp-client file initscripts perl-IO-Tty python3-libnmstate \
        python3-pyyaml rpm-build sos systemd-resolved wireguard-tools"


    # Install non distro deps
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/tcpreplay/4.3.3/3.fc34/$(arch)/tcpreplay-4.3.3-3.fc34.$(arch).rpm \
        $KOJI/libdnet/1.14/1.fc34/$(arch)/libdnet-1.14-1.fc34.$(arch).rpm \
        $KOJI/iw/5.4/3.fc34/$(arch)/iw-5.4-3.fc34.$(arch).rpm \
        $BREW/rhel-9/packages/libsmi/0.4.8/27.el9.1/$(arch)/libsmi-0.4.8-27.el9.1.$(arch).rpm \
        $BREW/rhel-9/packages/wireshark/3.4.0/1.el9.1/$(arch)/wireshark-cli-3.4.0-1.el9.1.$(arch).rpm \
        $KOJI/rp-pppoe/3.15/1.fc35/$(arch)/rp-pppoe-3.15-1.fc35.$(arch).rpm"

    # Install centos deps
    if grep -q -e 'CentOS' /etc/redhat-release; then
        # We need to install OVS repo
        dnf -y install centos-release-nfv-openvswitch.noarch
        # GSM perl deps
        PERL_VER=$(get_centos_pkg_release "$KHUB/perl-IO-Tty/1.16/")
        PKGS_INSTALL="$PKGS_INSTALL \
            openvswitch3.4* \
            $KHUB/perl-IO-Tty/1.16/$PERL_VER/$(arch)/perl-IO-Tty-1.16-$PERL_VER.$(arch).rpm"
    else
        cp -f  contrib/ovs/ovs-rhel9.repo /etc/yum.repos.d/ovs.repo
        PKGS_INSTALL="$PKGS_INSTALL openvswitch3.3*"
    fi

    # Install vpn dependencies
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm"

    # libreswan please remove when in compose 12012021
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $BREW/rhel-9/packages/NetworkManager-libreswan/1.2.14/1.el9/$(arch)/NetworkManager-libreswan-1.2.14-1.el9.$(arch).rpm"

    # OpenVPN dependencies - we install NM-openvpn-gnome for 2FA tests
    # Also, NM plugin 1.12.0 requires NM>=1.46.0, so we need to stick to 1.10 for now on RHEL<9.4
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/openvpn/2.5.9/2.el9/$(arch)/openvpn-2.5.9-2.el9.$(arch).rpm \
        $KOJI/pkcs11-helper/1.27.0/2.fc34/$(arch)/pkcs11-helper-1.27.0-2.fc34.$(arch).rpm"
    if rpm --eval "%{lua:print(rpm.vercmp('$(NetworkManager --version)', '1.46.0-11'))}" | grep -q '^1$'; then
        PKGS_INSTALL="$PKGS_INSTALL \
            $KOJI/NetworkManager-openvpn/1.12.0/2.el9/$(arch)/NetworkManager-openvpn-1.12.0-2.el9.$(arch).rpm \
            $KOJI/NetworkManager-openvpn/1.12.0/2.el9/$(arch)/NetworkManager-openvpn-gnome-1.12.0-2.el9.$(arch).rpm"
    else
        # We need older plugin for older NM
        PKGS_INSTALL="$PKGS_INSTALL \
            $KOJI/NetworkManager-openvpn/1.10.2/1.el9/$(arch)/NetworkManager-openvpn-1.10.2-1.el9.$(arch).rpm \
            $KOJI/NetworkManager-openvpn/1.10.2/1.el9/$(arch)/NetworkManager-openvpn-gnome-1.10.2-1.el9.$(arch).rpm"

    fi

    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/trousers/0.3.15/2.fc34/$(arch)/trousers-lib-0.3.15-2.fc34.$(arch).rpm \
        $KOJI/NetworkManager-strongswan/1.5.0/3.fc34/$(arch)/NetworkManager-strongswan-1.5.0-3.fc34.$(arch).rpm \
        $KOJI/strongswan/5.9.3/1.fc34/$(arch)/strongswan-5.9.3-1.fc34.$(arch).rpm \
        $KOJI/strongswan/5.9.3/1.fc34/$(arch)/strongswan-charon-nm-5.9.3-1.fc34.$(arch).rpm"

    # Install kernel-modules-internal for mac80211_hwsim
    # in case we have more kernels take the first (as we do no reboot)
    VER=$(rpm -q --queryformat '[%{VERSION}\n]' kernel |tail -n1)
    REL=$(rpm -q --queryformat '[%{RELEASE}\n]' kernel |tail -n1)
    if grep Red /etc/redhat-release; then
        PKGS_INSTALL="$PKGS_INSTALL \
            $BREW/rhel-9/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $BREW/rhel-9/packages/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm"
    else
        PKGS_INSTALL="$PKGS_INSTALL \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-devel-$VER-$REL.$(arch).rpm"
    fi

    # We still need pptp and pptpd in epel to be packaged
    # https://bugzilla.redhat.com/show_bug.cgi?id=1810542
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/NetworkManager-pptp/1.2.8/2.fc34.1/$(arch)/NetworkManager-pptp-1.2.8-2.fc34.1.$(arch).rpm \
        $KOJI/pptpd/1.4.0/25.fc34/$(arch)/pptpd-1.4.0-25.fc34.$(arch).rpm \
        $KOJI/pptp/1.10.0/11.eln107/$(arch)/pptp-1.10.0-11.eln107.$(arch).rpm"

    VER=$(rpm -q --queryformat '%{VERSION}' NetworkManager)
    REL=$(rpm -q --queryformat '%{RELEASE}' NetworkManager)
    PKGS_INSTALL="$PKGS_INSTALL  \
        $BREW/rhel-9/packages/NetworkManager/$VER/$REL/$(arch)/NetworkManager-ppp-$VER-$REL.$(arch).rpm"

    # install wpa_supp and hostapd with 2.10 capabilities
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $KHUB/wpa_supplicant/2.10/5.el9/$(arch)/wpa_supplicant-2.10-5.el9.$(arch).rpm \
        $KHUB/wpa_supplicant/2.10/5.el9/$(arch)/wpa_supplicant-debuginfo-2.10-5.el9.$(arch).rpm \
        $KHUB/wpa_supplicant/2.10/5.el9/$(arch)/wpa_supplicant-debugsource-2.10-5.el9.$(arch).rpm"

    PKGS_UPGRADE="$PKGS_UPGRADE \
        $KHUB/hostapd/2.10/1.el9/$(arch)/hostapd-2.10-1.el9.$(arch).rpm \
        $KHUB/hostapd/2.10/1.el9/$(arch)/hostapd-debuginfo-2.10-1.el9.$(arch).rpm \
        $KHUB/hostapd/2.10/1.el9/$(arch)/hostapd-debugsource-2.10-1.el9.$(arch).rpm"

    # upgrade freeradius from kojihub to match openssl version
    if rpm -q openssl | grep -q openssl-3.2; then
        PKGS_UPGRADE="$PKGS_UPGRADE \
            $KHUB/freeradius/3.0.21/41.el9/$(arch)/freeradius-3.0.21-41.el9.$(arch).rpm"
    fi

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL  \
        $KOJI/scsi-target-utils/1.0.79/3.fc34/$(arch)/scsi-target-utils-1.0.79-3.fc34.$(arch).rpm \
        $KOJI/perl-Config-General/2.63/14.fc34/noarch/perl-Config-General-2.63-14.fc34.noarch.rpm"

    ##############################################################################
    #####            _   _       _    __ _
    #####           | | | | ___ | |_ / _(_)_  _____  ___
    #####           | |_| |/ _ \| __| |_| \ \/ / _ \/ __|
    #####           |  _  | (_) | |_|  _| |>  <  __/\__ \
    #####           |_| |_|\___/ \__|_| |_/_/\_\___||___/
    #####
    #####

    # Install freeradius not in centos compose yet
    grep -q CentOS /etc/redhat-release && PKGS_UPGRADE="$PKGS_UPGRADE \
         $KHUB/freeradius/3.0.21/44.el9/$(arch)/freeradius-3.0.21-44.el9.$(arch).rpm"

    #####
    #####            _   _       _    __ _
    #####           | | | | ___ | |_ / _(_)_  _____  ___
    #####           | |_| |/ _ \| __| |_| \ \/ / _ \/ __|
    #####           |  _  | (_) | |_|  _| |>  <  __/\__ \
    #####           |_| |_|\___/ \__|_| |_/_/\_\___||___/
    #####
    ##############################################################################

    # This uses PKGS_{INSTALL,UPGRADE,REMOVE} and performs install
    install_common_packages

    # Copy libnmstate from python3.9 to python3.11
    cp -r /usr/lib/python3.9/site-packages/libnmstate /usr/lib/python3.11/site-packages/

    # Aditional PIP packages
    python3l -m pip install netaddr==0.10.1
    python3l -m pip install pycairo==1.16.3
    python3l -m pip install pygobject==3.40.0
    python3l -m pip install systemd==0.17.1
    python3l -m pip install dbus-python==1.3.2

    # Disable mac radnomization
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link
    sleep 0.5
    systemctl restart systemd-udevd
}
