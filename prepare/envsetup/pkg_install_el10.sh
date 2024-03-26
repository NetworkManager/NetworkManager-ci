install_el10_packages () {
    # Enable EPEL but on s390x
    #if ! uname -a |grep -q s390x; then
    #    [ -f /etc/yum.repos.d/epel.repo ] || rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    #fi

    # Enable fedora 40 repo with lower priority
    # TODO remove when epel-10 is live
    cat << EOF > /etc/yum.repos.d/fedora-40.repo
[fedora]
name=Fedora 40 - \$basearch
#baseurl=http://download.example/pub/fedora/linux/releases/40/Everything/\$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-40&arch=\$basearch
enabled=1
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=0
skip_if_unavailable=False
priority=100

[updates]
name=Fedora 40 - \$basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/40/Everything/\$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f40&arch=\$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=0
metadata_expire=6h
skip_if_unavailable=False
priority=100

EOF
    dnf makecache

    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL \
        ModemManager dhcp-client file initscripts perl-IO-Tty python3-libnmstate
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
        # OVS deps and GSM perl deps
        POLICY_VER=$(get_centos_pkg_release "$CBSC/openvswitch-selinux-extra-policy/1.0/")
        OVS_VER=$(get_centos_pkg_release "$CBSC/openvswitch2.17/2.17.0/")
        PERL_VER=$(get_centos_pkg_release "$KHUB/perl-IO-Tty/1.16/")
        PKGS_INSTALL="$PKGS_INSTALL \
            $CBSC/openvswitch2.17/2.17.0/$OVS_VER/$(arch)/openvswitch2.17-2.17.0-$OVS_VER.$(arch).rpm \
            $CBSC/openvswitch-selinux-extra-policy/1.0/$POLICY_VER/noarch/openvswitch-selinux-extra-policy-1.0-$POLICY_VER.noarch.rpm \
            $KHUB/perl-IO-Tty/1.16/$PERL_VER/$(arch)/perl-IO-Tty-1.16-$PERL_VER.$(arch).rpm"
    else
        cp -f  contrib/ovs/ovs-rhel9.repo /etc/yum.repos.d/ovs.repo
        PKGS_INSTALL="$PKGS_INSTALL openvswitch2.17*"
    fi

    # Install vpn dependencies
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm"

    # libreswan please remove when in compose 12012021
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $BREW/rhel-9/packages/NetworkManager-libreswan/1.2.14/1.el9/$(arch)/NetworkManager-libreswan-1.2.14-1.el9.$(arch).rpm"

    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/openvpn/2.5.6/1.el9/$(arch)/openvpn-2.5.6-1.el9.$(arch).rpm \
        $KOJI/pkcs11-helper/1.27.0/2.fc34/$(arch)/pkcs11-helper-1.27.0-2.fc34.$(arch).rpm \
        $KOJI/NetworkManager-openvpn/1.10.2/1.el9/$(arch)/NetworkManager-openvpn-1.10.2-1.el9.$(arch).rpm"

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

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL  \
        $KOJI/scsi-target-utils/1.0.79/3.fc34/$(arch)/scsi-target-utils-1.0.79-3.fc34.$(arch).rpm \
        $KOJI/perl-Config-General/2.63/14.fc34/noarch/perl-Config-General-2.63-14.fc34.noarch.rpm"

    # This uses PKGS_{INSTALL,UPGRADE,REMOVE} and performs install
    install_common_packages

    # Aditional PIP packages
    python -m pip install netaddr

    # Disable mac radnomization
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link
    sleep 0.5
    systemctl restart systemd-udevd
}
