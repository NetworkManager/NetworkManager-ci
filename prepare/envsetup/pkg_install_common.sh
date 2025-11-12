install_common_packages () {
    # Set dnf to use ipv4 DNS only
    sed -i '/ip_resolve=/d' /etc/dnf/dnf.conf
    echo 'ip_resolve=4' >> /etc/dnf/dnf.conf
    # Set DNF not to install weak deps
    sed -i '/install_weak_deps=/d' /etc/dnf/dnf.conf
    echo 'install_weak_deps=0' >> /etc/dnf/dnf.conf

    # Dnf more deps

    # Add the libreswan-next repo to test upstream if we are with main NM packages
    if grep -r -q NetworkManager-main-debug /etc/yum.repos.d/ || \
       grep -q Rawhide /etc/redhat-release; then
        dnf -y copr enable networkmanager/NetworkManager-libreswan-next
        PKGS_UPGRADE="$PKGS_UPGRADE NetworkManager-libreswan"
    fi

    # If running kernel is found in installed kernels, use it
    if rpm -q kernel | grep -q -F $(uname -r); then
        K_VER=$(uname -r)
    else
    # If not, we are probably building image, so let's use the installed one
        K_VER=$(rpm -q kernel | head -n 1 | sed 's/kernel-//')
    fi
    K_MAJOR="$(echo $K_VER |awk -F '-' '{print $1}')"
    K_MINOR="$(echo $K_VER |awk -F '-' '{print $2}'| rev| cut -d. -f2-  |rev)"
    links_scr=koji_links.sh
    grep -q "Red Hat Enterprise Linux" /etc/redhat-release && links_scr=brew_links.sh
    K_DEVEL="$(contrib/utils/$links_scr kernel $K_MAJOR $K_MINOR | grep kernel-devel-$K_MAJOR)"
    PKGS_INSTALL="$PKGS_INSTALL \
        audit2allow bash-completion bc bind-utils dbus-x11 dhcp-relay dhcp-server dnsconfd dnsmasq elfutils-libelf-devel \
        ethtool firewalld freeradius gcc git hostapd httpd iperf3 iproute-tc iptables iputils iw jq kernel-headers $K_DEVEL \
        libreswan-debuginfo lshw lsof mptcpd net-tools nmap-ncat nmstate openssl-pkcs11 patch podman pptpd pptp psmisc python3-dbus \
        python3-gobject python3-inotify python3-libselinux python3-netaddr python3-pip python3-systemd \
        rsync s390utils-base tcpdump telnet traceroute tuned valgrind valgrind-gdb wget wireshark-cli wpa_supplicant yasm ipcalc"

    # freeradius cleanup config
    rm -rf /etc/raddb
    PKGS_REMOVE="$PKGS_REMOVE freeradius"

    # Install various NM dependencies
    PKGS_REMOVE="$PKGS_REMOVE NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat"

    # Prevent NM-dispatcher AVCs caused by this script
    PKGS_REMOVE="$PKGS_REMOVE console-login-helper-messages*"

    # Update fallback versions of vpn plugins to repo RPMs (if provided)
    PKGS_UPGRADE="$PKGS_UPGRADE pptpd pptp"
    PKGS_UPGRADE="$PKGS_UPGRADE vpnc vpnc-script"
    PKGS_UPGRADE="$PKGS_UPGRADE strongswan strongswan-charon-nm trousers-lib"
    PKGS_UPGRADE="$PKGS_UPGRADE openvpn pkcs11-helper"


    PKGS_UPGRADE="$PKGS_UPGRADE \
        hostapd wpa_supplicant wpa_supplicant-debuginfo wpa_supplicant-debugsource"

    # dracut testing
    PKGS_INSTALL="$PKGS_INSTALL \
        qemu-kvm qemu-img lvm2 mdadm cryptsetup iscsi-initiator-utils nfs-utils radvd gdb dhcp-client"

    # iwl firmware for aarch
    if [ "$(arch)" == "aarch64" ]; then
        PKGS_INSTALL="$PKGS_INSTALL iwl*-firmware"
    fi

    install_plugins_dnf

    # Execute
    echo "remove dnf packages..."
    test -n "$PKGS_REMOVE" && dnf -y remove $PKGS_REMOVE
    echo "install dnf packages..."

    disable_repo=""
    if dnf repolist | grep buildroot-brewtrigger-repo; then
        disable_repo="--disablerepo=buildroot-brewtrigger-repo"
    fi

    skip="--skip-broken"
    rpm -q dnf5 && skip="--skip-unavailable --no-gpgchecks"

    test -n "$PKGS_INSTALL" && $dnf -y install $PKGS_INSTALL $skip \
                                                               --nobest \
                                                               $disable_repo
    echo "update dnf packages..."
    test -n "$PKGS_UPGRADE" && $dnf -y upgrade $PKGS_UPGRADE $skip \
                                                               --allowerasing

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK -O /var/run/wpa_supplicant"!' /etc/sysconfig/wpa_supplicant

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # backup freeradius conf
    rm -rf /tmp/nmci-raddb
    cp -ar /etc/raddb/ /tmp/nmci-raddb/

    # Let's remove blacklist and load sch_netem for later usage
    rm -rf /etc/modprobe.d/sch_netem-blacklist.conf
    modprobe sch_netem

    # remount rw overlay, if in image mode
    grep -q ostree /proc/cmdline && ( bootc usr-overlay; sudo mount -o remount,rw lazy /usr )

    # Workaround: restart polkit to accept new dnsconfd rule possibly installed in transient mode
    grep -q ostree /proc/cmdline && ( systemctl restart polkit )


    # installing python3-* package causes removal of /usr/bin/python
    fix_python3_link

    # Install common pip packages
    python3l -m pip install --upgrade pip
    install_behave_pytest
    python3l -m pip install pyroute2
    python3l -m pip install pexpect
    python3l -m pip install pyte
    python3l -m pip install IPy
    python3l -m pip install python-dbusmock
    python3l -m pip install psutil
    python3l -m pip install scapy
    python3l -m pip install qemu.qmp
    which tmt || python3l -m pip install tmt

    # remount ro overlay, if in image mode
    grep -q ostree /proc/cmdline && sudo mount -o remount,ro lazy /usr

}
