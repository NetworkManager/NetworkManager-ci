install_el10_packages () {
    # Enable EPEL but on s390x - 10 not live yet, change 9->10 when rpm is released
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || rpm -i https://dl.fedoraproject.org/pub/epel/10/Everything/x86_64/Packages/e/epel-release-10-2.el10_0.noarch.rpm
    fi

    dnf makecache


    # TODO remove when the issue with resolv.conf symlink is fixed
    dnf -y install systemd-resolved
    systemctl disable systemd-resolved
    systemctl stop systemd-resolved
    rm /etc/resolv.conf
    sleep 1
    systemctl restart NetworkManager
    sleep 1
    [ -f /etc/resolv.conf ] || systemctl restart NetworkManager

    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL \
        ModemManager file initscripts perl-IO-Tty python3-libnmstate python3-pyyaml \
        rpm-build sos wireguard-tools systemd-resolved dbus-tools dbus-daemon"

    # Install non distro deps
    # TODO install from epel once epel-10 is live
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/tcpreplay/4.4.4/5.fc40/$(arch)/tcpreplay-4.4.4-5.fc40.$(arch).rpm \
        $KOJI/libdnet/1.17.0/3.fc40/$(arch)/libdnet-1.17.0-3.fc40.$(arch).rpm"

    # Non ditro deps - not even in epel
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/rp-pppoe/4.0/4.fc40/$(arch)/rp-pppoe-4.0-4.fc40.$(arch).rpm \
        $KOJI/dhcp/4.4.3/13.P1.fc40/$(arch)/dhcp-client-4.4.3-13.P1.fc40.$(arch).rpm \
        $KOJI/dhcp/4.4.3/13.P1.fc40/$(arch)/dhcp-server-4.4.3-13.P1.fc40.$(arch).rpm \
        $KOJI/dhcp/4.4.3/13.P1.fc40/noarch/dhcp-common-4.4.3-13.P1.fc40.noarch.rpm"

    # Install util-linux deps to avoid RHEL-32647
    PKGS_UPGRADE="$PKGS_UPGRADE $(contrib/utils/koji_links.sh util-linux 2.40)"
    PKGS_INSTALL="$PKGS_INSTALL openvswitch"

    # Install vpn dependencies - we need NM-openvpn-gnome for 2FA tests
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/openvpn/2.6.9/1.fc40/$(arch)/openvpn-2.6.9-1.fc40.$(arch).rpm \
        $KOJI/pkcs11-helper/1.30.0/1.fc40/$(arch)/pkcs11-helper-1.30.0-1.fc40.$(arch).rpm \
        $KOJI/NetworkManager-openvpn/1.12.0/1.fc40/$(arch)/NetworkManager-openvpn-1.12.0-1.fc40.$(arch).rpm \
        $KOJI/NetworkManager-openvpn/1.12.0/1.fc40/$(arch)/NetworkManager-openvpn-gnome-1.12.0-1.fc40.$(arch).rpm"

    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/trousers/0.3.15/10.fc40/$(arch)/trousers-lib-0.3.15-10.fc40.$(arch).rpm \
        $KOJI/NetworkManager-strongswan/1.6.0/6.fc40/$(arch)/NetworkManager-strongswan-1.6.0-6.fc40.$(arch).rpm \
        $KOJI/strongswan/5.9.11/3.fc40/$(arch)/strongswan-5.9.11-3.fc40.$(arch).rpm \
        $KOJI/strongswan/5.9.11/3.fc40/$(arch)/strongswan-charon-nm-5.9.11-3.fc40.$(arch).rpm"

    # Install kernel-modules-internal for mac80211_hwsim
    # in case we have more kernels take the first (as we do no reboot)
    VER=$(rpm -q --queryformat '[%{VERSION}\n]' kernel |tail -n1)
    REL=$(rpm -q --queryformat '[%{RELEASE}\n]' kernel |tail -n1)
    if grep Red /etc/redhat-release; then
        PKGS_INSTALL="$PKGS_INSTALL \
            $BREW/rhel-10/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $BREW/rhel-10/packages/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm"
    else
        PKGS_INSTALL="$PKGS_INSTALL \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm \
            $KHUB/kernel/$VER/$REL/$(arch)/kernel-devel-$VER-$REL.$(arch).rpm"
    fi

    # We still need pptp and pptpd in epel to be packaged
    # https://bugzilla.redhat.com/show_bug.cgi?id=1810542
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/NetworkManager-pptp/1.2.12/6.fc40/$(arch)/NetworkManager-pptp-1.2.12-6.fc40.$(arch).rpm \
        $KOJI/pptpd/1.4.0/36.fc40/$(arch)/pptpd-1.4.0-36.fc40.$(arch).rpm \
        $KOJI/pptp/1.10.0/20.fc40/$(arch)/pptp-1.10.0-20.fc40.$(arch).rpm "

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL  \
        $KOJI/scsi-target-utils/1.0.79/9.fc40/$(arch)/scsi-target-utils-1.0.79-9.fc40.$(arch).rpm \
        $KOJI/perl-Config-General/2.65/8.fc40/noarch/perl-Config-General-2.65-8.fc40.noarch.rpm"

    # Wireless (wpa_supplicant and hostapd)
    # force install older version (if not in repo)
    PKGS_INSTALL="$PKGS_INSTALL \
        $BREW/rhel-10/packages/wpa_supplicant/2.10/11.el10/x86_64/wpa_supplicant-2.10-11.el10.x86_64.rpm \
        $BREW/rhel-10/packages/hostapd/2.10/11.el10/$(arch)/hostapd-2.10-11.el10.$(arch).rpm"

    # upgrade (if newer pkg in repo)
    PKGS_UPGRADE="$PKGS_UPGRADE hostapd wpa_supplicant"

    # This uses PKGS_{INSTALL,UPGRADE,REMOVE} and performs install
    install_common_packages

    # Let's remove blacklist and load sch_netem for later usage
    rm -rf /etc/modprobe.d/sch_netem-blacklist.conf
    modprobe sch_netem

    # Aditional PIP packages
    python -m pip install netaddr

    # Disable mac radnomization
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link
    sleep 0.5
    systemctl restart systemd-udevd
}
