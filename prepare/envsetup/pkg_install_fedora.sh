install_fedora_packages () {
    # Enable rawhide sshd to root
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    # Pip down some deps
    PKGS_INSTALL="$PKGS_INSTALL python3-pip libyaml-devel"

    # Needed for gsm_sim
    PKGS_INSTALL="$PKGS_INSTALL perl-IO-Pty-Easy perl-IO-Tty"

    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL \
        ModemManager NetworkManager-initscripts-ifcfg-rh bzip2 gdb lshw python3-libnmstate \
        rp-pppoe tcpreplay usb_modeswitch usbutils wireguard-tools"

    # Install vpn dependencies
    PKGS_INSTALL="$PKGS_INSTALL \
        openvpn ipsec-tools strongswan strongswan-charon-nm"

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL dracut-network scsi-target-utils"

    # Install kernel-modules for currently running kernel
    # Install kernel-modules-internal for mac80211_hwsim
    # in case we have more kernels take the first (as we do no reboot)
    VER=$(rpm -q --queryformat '[%{VERSION}\n]' kernel-core |tail -n1)
    REL=$(rpm -q --queryformat '[%{RELEASE}\n]' kernel-core |tail -n1)
    PKGS_INSTALL="$PKGS_INSTALL \
        $KOJI/kernel/$VER/$REL/$(arch)/kernel-modules-$VER-$REL.$(arch).rpm \
        $KOJI/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm \
        $KOJI/kernel/$VER/$REL/$(arch)/kernel-modules-extra-$VER-$REL.$(arch).rpm"

    # Update to patched libreswan as for preF40
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $FEDP/NetworkManager-libreswan-1.2.18-3.5.fc40.x86_64.rpm"

    # Update to the newest nmstate just for F40
    PKGS_UPGRADE="$PKGS_UPGRADE \
        $FEDP/nmstate-2.27/F40/nmstate-2.2.27-0.alpha.20240313.c2ce615b.fc40.x86_64.rpm \
        $FEDP/nmstate-2.27/F40/nmstate-libs-2.2.27-0.alpha.20240313.c2ce615b.fc40.x86_64.rpm \
        $FEDP/nmstate-2.27/F40/python3-libnmstate-2.2.27-0.alpha.20240313.c2ce615b.fc40.x86_64.rpm \
    "
    # This uses PKGS_{INSTALL,UPGRADE,REMOVE} and performs install
    install_common_packages

    # Additional PIP packages
    python -m pip install netaddr
    python -m pip install --upgrade --force pyyaml

    # Make device mac address policy behave like old one
    test -d /etc/systemd/network/ || mkdir /etc/systemd/network/
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link

    # disable dhcpd dispatcher script: rhbz1758476
    [ -f /etc/NetworkManager/dispatcher.d/12-dhcpd ] && chmod -x /etc/NetworkManager/dispatcher.d/12-dhcpd
}
