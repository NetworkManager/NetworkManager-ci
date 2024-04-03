install_common_packages () {
    # Dnf more deps
    PKGS_INSTALL="$PKGS_INSTALL \
        bind-utils dhcp-relay dhcp-server dnsmasq ethtool firewalld freeradius gcc git hostapd \
        iproute-tc iputils iw jq mptcpd net-tools nmap-ncat nmstate openssl-pkcs11 podman psmisc \
        python3-dbus python3-gobject python3-netaddr python3-systemd s390utils-base tcpdump tuned \
        valgrind wireshark-cli wpa_supplicant"

    # freeradius cleanup config
    rm -rf /etc/raddb
    PKGS_REMOVE="$PKGS_REMOVE freeradius"

    # Install various NM dependencies
    PKGS_REMOVE="$PKGS_REMOVE NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat"

    # Update fallback versions of vpn plugins to repo RPMs (if provided)
    PKGS_UPGRADE="$PKGS_UPGRADE pptpd pptp"
    PKGS_UPGRADE="$PKGS_UPGRADE vpnc vpnc-script"
    PKGS_UPGRADE="$PKGS_UPGRADE strongswan strongswan-charon-nm trousers-lib"
    PKGS_UPGRADE="$PKGS_UPGRADE openvpn pkcs11-helper"


    PKGS_UPGRADE="$PKGS_UPGRADE \
        hostapd wpa_supplicant wpa_supplicant-debuginfo wpa_supplicant-debugsource"

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL \
        qemu-kvm lvm2 mdadm cryptsetup iscsi-initiator-utils nfs-utils radvd gdb dhcp-client"

    # iwl firmware for aarch
    if [ "$(arch)" == "aarch64" ]; then
        PKGS_INSTALL="$PKGS_INSTALL iwl*-firmware"
    fi

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK -O /var/run/wpa_supplicant"!' /etc/sysconfig/wpa_supplicant

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    install_plugins_dnf

    # Execute
    echo "remove dnf packages..."
    test -n "$PKGS_REMOVE" && dnf -4 -y remove $PKGS_REMOVE
    echo "install dnf packages..."
    test -n "$PKGS_INSTALL" && dnf -4 -y install $PKGS_INSTALL --skip-broken --nobest
    echo "update dnf packages..."
    test -n "$PKGS_UPGRADE" && dnf -4 -y upgrade $PKGS_UPGRADE --skip-broken --allowerasing

    # backup freeradius conf
    rm -rf /tmp/nmci-raddb
    cp -ar /etc/raddb/ /tmp/nmci-raddb/

    # installing python3-* package causes removal of /usr/bin/python
    fix_python3_link
    install_behave_pytest

    # Install common pip packages
    python -m pip install --upgrade pip
    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install pyte
    python -m pip install IPy
}
