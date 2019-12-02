#!/bin/bash

install_plugins_yum () {
    # Installing plugins if missing
    if ! rpm -q --quiet NetworkManager-wifi; then
        yum -y install NetworkManager-wifi
    fi
    if ! rpm -q --quiet NetworkManager-team; then
        yum -y install NetworkManager-team
    fi
    if ! rpm -q --quiet NetworkManager-tui; then
        yum -y install NetworkManager-tui
    fi
    if ! rpm -q --quiet NetworkManager-pptp; then
        yum -y install NetworkManager-pptp
    fi
    if ! rpm -q --quiet NetworkManager-ppp && ! rpm -q NetworkManager |grep -q '1.4'; then
        yum -y install NetworkManager-ppp
    fi
    if ! rpm -q --quiet NetworkManager-openvpn; then
        yum -y install NetworkManager-openvpn
    fi
}


install_plugins_dnf () {
    # Installing plugins if missing
    if ! rpm -q --quiet NetworkManager-wifi; then
        dnf -4 -y install NetworkManager-wifi
    fi
    if ! rpm -q --quiet NetworkManager-team; then
        dnf -4 -y install NetworkManager-team
    fi
    if ! rpm -q --quiet NetworkManager-tui; then
        dnf -4 -y install NetworkManager-tui
    fi
    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install NetworkManager-pptp
    fi
    if ! rpm -q --quiet NetworkManager-ppp && ! rpm -q NetworkManager |grep -q '1.4'; then
        dnf -4 -y install NetworkManager-ppp
    fi
    if ! rpm -q --quiet NetworkManager-openvpn; then
        dnf -4 -y install NetworkManager-openvpn
    fi
}

check_packages () {
    rpm -q iw ethtool wireshark-cli NetworkManager-openvpn NetworkManager-ppp NetworkManager-pptp NetworkManager-tui NetworkManager-team NetworkManager-wifi NetworkManager-vpnc NetworkManager-strongswan && ls /usr/bin/behave
    return $?
}


install_behave () {
  python -m pip install behave
  python -m pip install behave_html_formatter
  echo -e "[behave.formatters]\nhtml = behave_html_formatter:HTMLFormatter" > ~/.behaverc
  ln -s /usr/bin/behave-3 /usr/bin/behave
}

install_fedora_packages () {
    # Update sshd in Fedora 32 to avoid rhbz1771946
    dnf -y -4 update https://kojipkgs.fedoraproject.org//packages/openssh/8.1p1/2.fc32/x86_64/openssh-8.1p1-2.fc32.x86_64.rpm https://kojipkgs.fedoraproject.org//packages/openssh/8.1p1/2.fc32/x86_64/openssh-server-8.1p1-2.fc32.x86_64.rpm https://kojipkgs.fedoraproject.org//packages/openssh/8.1p1/2.fc32/x86_64/openssh-clients-8.1p1-2.fc32.x86_64.rpm
    # Enable rawhide sshd to root
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    systemctl restart sshd

    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # Pip down some deps
    dnf -4 -y install python3-pip

    # Doesn't work on the newest aarch64 RHEL8
    python -m pip install --upgrade pip
    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy

    # Needed for gsm_sim
    dnf -4 -y install perl-IO-Pty-Easy perl-IO-Tty
    dnf -4 -y upgrade https://vbenes.fedorapeople.org/NM/ModemManager-1.10.6-1.fc30.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-debuginfo-1.10.6-1.fc30.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-debugsource-1.10.6-1.fc30.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-devel-1.10.6-1.fc30.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-glib-1.10.6-1.fc30.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-glib-debuginfo-1.10.6-1.fc30.x86_64.rpm --allowerasing

    # Dnf more deps
    dnf -4 -y install git nmap-ncat hostapd tcpreplay python3-netaddr dhcp-relay iw net-tools psmisc firewalld dhcp-server ethtool python3-dbus python3-gobject dnsmasq tcpdump wireshark-cli

    install_behave

    # Install vpn dependencies
    dnf -4 -y install NetworkManager-openvpn openvpn ipsec-tools

    # Install various NM dependencies
    dnf -4 -y remove NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat
    dnf -4 -y install openvswitch2* NetworkManager-ovs

    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install NetworkManager-pptp
    fi

    if ! rpm -q --quiet NetworkManager-strongswan; then
        dnf -4 -y install NetworkManager-strongswan
    fi

    if ! rpm -q --quiet strongswan; then
        dnf -4 -y install strongswan strongswan-charon-nm
    fi

    if ! rpm -q --quiet NetworkManager-vpnc || ! rpm -q --quiet vpnc; then
        dnf -4 -y install NetworkManager-vpnc
    fi

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant

    # Update and install the latest dbus
    dnf -4 -y update dbus*
    systemctl restart messagebus

    # Make crypto policies a bit less strict
    update-crypto-policies --set LEGACY
    systemctl restart wpa_supplicant

    # Install kernel-modules for currently running kernel
    dnf -4 -y install kernel-modules-*-$(uname -r)

    install_plugins_dnf

    # Make device mac address policy behave like old one
    echo -e "[Match]\nOriginalName=*\n[Link]\nMACAddressPolicy=none" > /etc/systemd/network/00-NM.link

    # disable dhcpd dispatcher script: rhbz1758476
    [ -f /etc/NetworkManager/dispatcher.d/12-dhcpd ] && sudo chmod -x /etc/NetworkManager/dispatcher.d/12-dhcpd
}

install_el8_packages () {
    # Make python3 default if it's not
    rm -rf /usr/bin/python
    ln -s /usr/bin/python3 /usr/bin/python

    # The newest PIP seems to be broken on aarch64 under rhel8.1
    #dnf -4 -y install python3-pip
    #python -m pip install --upgrade pip

    python -m pip install pyroute2
    python -m pip install pexpect
    python -m pip install netaddr
    python -m pip install pyte
    python -m pip install IPy

    # Needed for gsm_sim
    dnf -4 -y install https://kojipkgs.fedoraproject.org//packages/perl-IO-Pty-Easy/0.10/5.fc28/noarch/perl-IO-Pty-Easy-0.10-5.fc28.noarch.rpm https://kojipkgs.fedoraproject.org//packages/perl-IO-Tty/1.12/11.fc28/$(arch)/perl-IO-Tty-1.12-11.fc28.$(arch).rpm

    # Dnf more deps
    dnf -4 -y install git python3-netaddr dhcp-relay iw net-tools psmisc firewalld dhcp-server ethtool python3-dbus python3-gobject dnsmasq tcpdump wireshark-cli --skip-broken

    dnf -4 -y install https://kojipkgs.fedoraproject.org//packages/tcpreplay/4.2.5/4.fc28/$(uname -p)/tcpreplay-4.2.5-4.fc28.$(uname -p).rpm
    install_behave

    # Install vpn dependencies
    dnf -4 -y install https://kojipkgs.fedoraproject.org//packages/NetworkManager-openvpn/1.8.4/1.fc28/$(arch)/NetworkManager-openvpn-1.8.4-1.fc28.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/openvpn/2.4.6/1.fc28/$(arch)/openvpn-2.4.6-1.fc28.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/ipsec-tools/0.8.2/10.fc28/$(arch)/ipsec-tools-0.8.2-10.fc28.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/pkcs11-helper/1.22/5.fc28/$(arch)/pkcs11-helper-1.22-5.fc28.$(arch).rpm

    # Install various NM dependencies
    dnf -4 -y remove NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat
    dnf -4 -y install http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/libmnl/1.0.4/6.el8/$(arch)/libmnl-devel-1.0.4-6.el8.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/hostapd/2.8/1.el7/$(arch)/hostapd-2.8-1.el7.$(arch).rpm

    # Install kernel-modules-internal for mac80211_hwsim
    VER=$(rpm -q --queryformat '%{VERSION}' kernel)
    REL=$(rpm -q --queryformat '%{RELEASE}' kernel)
    dnf -4 -y install http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages/kernel/$VER/$REL/$(arch)/kernel-modules-internal-$VER-$REL.$(arch).rpm

    # Install OVS
    mv -f  tmp/ovs-rhel8.repo /etc/yum.repos.d/ovs.repo
    yum -y install openvswitch2*

    dnf -4 -y install http://download.eng.bos.redhat.com/brewroot/packages/$(rpm -q --queryformat '%{NAME}/%{VERSION}/%{RELEASE}' NetworkManager)/$(uname -p)/NetworkManager-ovs-$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' NetworkManager).$(uname -p).rpm
    if ! rpm -q --quiet NetworkManager-pptp; then
        dnf -4 -y install http://download.eng.bos.redhat.com/brewroot/packages/NetworkManager-pptp/1.2.4/4.el8+5/$(uname -p)/NetworkManager-pptp-1.2.4-4.el8+5.$(uname -p).rpm https://kojipkgs.fedoraproject.org//packages/pptpd/1.4.0/18.fc28/$(uname -p)/pptpd-1.4.0-18.fc28.$(uname -p).rpm http://download.eng.bos.redhat.com/brewroot/packages/pptp/1.10.0/3.el8+7/$(uname -p)/pptp-1.10.0-3.el8+7.$(uname -p).rpm
    fi

    if ! rpm -q --quiet NetworkManager-vpnc || ! rpm -q --quiet vpnc; then
        dnf -4 -y install https://kojipkgs.fedoraproject.org//packages/vpnc/0.5.3/33.svn550.fc29/$(arch)/vpnc-0.5.3-33.svn550.fc29.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/NetworkManager-vpnc/1.2.6/1.fc29/$(arch)/NetworkManager-vpnc-1.2.6-1.fc29.$(arch).rpm https://kojipkgs.fedoraproject.org//packages/vpnc-script/20171004/3.git6f87b0f.fc29/noarch/vpnc-script-20171004-3.git6f87b0f.fc29.noarch.rpm
    fi

    # strongswan
    if ! rpm -q --quiet NetworkManager-strongswan || ! rpm -q --quiet strongswan; then
        dnf -4 -y install https://kojipkgs.fedoraproject.org//packages/NetworkManager-strongswan/1.4.4/1.fc29/$(uname -p)/NetworkManager-strongswan-1.4.4-1.fc29.$(uname -p).rpm https://kojipkgs.fedoraproject.org//packages/strongswan/5.7.2/1.fc29/$(uname -p)/strongswan-5.7.2-1.fc29.$(uname -p).rpm https://kojipkgs.fedoraproject.org//packages/strongswan/5.7.2/1.fc29/$(uname -p)/strongswan-charon-nm-5.7.2-1.fc29.$(uname -p).rpm
    fi

    # Enable debug logs for wpa_supplicant
    sed -i 's!OTHER_ARGS="-s"!OTHER_ARGS="-s -dddK"!' /etc/sysconfig/wpa_supplicant

    # Install wifi p2p wpa_supplicant
    dnf -4 -y install https://vbenes.fedorapeople.org/NM/wpa_supplicant-2.7-2.2.bz1693684.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/wpa_supplicant-debuginfo-2.7-2.2.bz1693684.el8.x86_64.rpm

    # Make crypto policies a bit less strict
    update-crypto-policies --set LEGACY
    systemctl restart wpa_supplicant

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # Install non crashing MM
    dnf -4 -y upgrade https://vbenes.fedorapeople.org/NM/ModemManager-1.10.6-1.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-debuginfo-1.10.6-1.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-debugsource-1.10.6-1.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-devel-1.10.6-1.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-glib-1.10.6-1.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/ModemManager-glib-debuginfo-1.10.6-1.el8.x86_64.rpm --allowerasing

    # Install non crashing teamd 1684389
    dnf -4 -y install https://vbenes.fedorapeople.org/NM/team_rhbz1684389/libteam-debugsource-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/libteam-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/python3-libteam-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/teamd-debuginfo-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/libteam-debuginfo-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/libteam-devel-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/teamd-1.29-1.el8_1.x86_64.rpm \
    https://vbenes.fedorapeople.org/NM/team_rhbz1684389/teamd-devel-1.29-1.el8_1.x86_64.rpm

    install_plugins_dnf
}

install_el7_packages () {
    # Enable EPEL but on s390x
    if ! uname -a |grep -q s390x; then
        [ -f /etc/yum.repos.d/epel.repo ] || sudo rpm -i http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi

    # Download some deps
    yum -y install perl-IO-Pty-Easy wireshark

    yum -y install python3 python3-pip

    echo python3 > /tmp/python_command
    export_python_command

    python -m pip install --upgrade pip
    python -m pip install pexpect
    python -m pip install pyroute2
    python -m pip install netaddr
    yum -y install git python36-netaddr iw net-tools wireshark psmisc bridge-utils firewalld dhcp ethtool python36-dbus python36-gobject dnsmasq NetworkManager-vpnc

    yum -y install https://kojipkgs.fedoraproject.org//packages/hostapd/2.8/1.el7/$(arch)/hostapd-2.8-1.el7.$(arch).rpm

    yum -y remove NetworkManager-config-connectivity-fedora NetworkManager-config-connectivity-redhat

    install_behave

    # Add OVS repo and install OVS
    if grep -q -e 'CentOS Linux release 7' /etc/redhat-release; then
        yum -y install https://cbs.centos.org/kojifiles/packages/openvswitch/2.11.0/4.el7/$(arch)/openvswitch-2.11.0-4.el7.$(arch).rpm
    else
        mv -f  tmp/ovs-rhel7.repo /etc/yum.repos.d/ovs.repo
        yum -y install openvswitch
    fi

    # Remove cloud-init dns
    rm -rf /etc/NetworkManager/conf.d/99-cloud-init.conf

    # Tune wpa_supplicat to log into journal and enable debugging
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

deploy_ssh_keys () {
    if ! test -d /root/.ssh; then
        mkdir /root/.ssh/
    fi

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxWHTPdT+b/4EPoVgR/a88K9Wpdta8MdcqXPYOc4uNO/IDhLvGbU6HjlFjA1cI48U/KU6fM6qACJxgyeE/3h0EyMOt11UbzBK8d6Ts03HwdaKiE1Jvvs8Ga7FqZHBr37k7rESGT9B5zA11Bb7xIaBoZp2Q+D6VIGI5D9k0jcFUEEFW/+Rs0hVG8CczMLYAIeECsFSgksHKzrkY28lLn+N4iFWJBY6PpBlxZKiw9POi3L1gekbF+tEpzkeOmqWelZmD/t8ttKpqAeLp43K9nFLYdYaeoAPsaPANo6l5NSi30UGOjKtyWee0LGYDl92c7ahnyLmCybf2YgatD4GQphLh thaller@rh.com" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLEW8B8/uX4VpsKIwrtrqBc/dAq+EaL17iegWZGR1qFbhC4xt8X+BoGRH/A9DlZPKhdMENHz+ZZT2XHkhLGSoRq0ElDM/WB9ppGxaVDh6plhvJL9aV8W8QcvOUPatdggGR3/b0qqnbGMwWnbPLJgqu/XwVm+z92oBJHh0W65cRg5jw/jedVPzFHe0ZVwfpZT3eUL2p6H16NV3phZVoIAJbkMEf59vSfKgK2816nNtKWCjwtCIzSR/K9KzejAfpUKyJNlNfxjtkoFf2zorPrdTT+DXiPprkTcExS4YEQl3fPp2/jT6gpcXuR+q8OGMIZDO8NkFVLL9AXhjR7nY+6Vr vbenes@benjoband" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT5g6igQ5ug29wJakhGGMUm8ZeeP8iXGDFMGyn9c5JGBcKHp2YI8xx6tWZcTTORLmk47OG6W87LS7iXfhTeUUWZ2kXSIaoU7B+ZyJBYUR6J0qqUMrYgD2RLeiO74BsI6bI1Hz1S0Y6gDgsuBDI0QTtaJ+Z3ISDkBROfiRYG3LaPObvPdnFOpYqqd6jsKFHHgGrQPd45Qi/CJ7enXGMOGiqlN/XzdJni7V67jAbW0C2/7caYLCayWJvEt1ZuFFhFoFV6aCbfo3MaHPJXBbiIiT/bGeInFgsdDymryj/CW1CZUzk5jcnD8hj/ZCG9At/2+M8dVfjtXBHpaP6TBw4I+hCxiDFjzDSAhXMb7xtFRZMKW9PeshNJkmfVaOuD6XHCZr3TcYnh0fU4+mJ2Wg1em//885pLiCgpJ41kNjv9b8zRUlkfqn46lkm0vQ0ikvOO83UgV3d6Et9Us1P42AYSM4Ed0mISw5rB2/9LAS0P8OmddgDzWoSks2tTVE29I1/dKNBslnAFTtE+ILIN3bYY1pY7lrRFZkJ23bXaTXqqsWfk95h0gh8u7O1JqP3nrHqH9y9TTPTjWTXglu2ZIvgmexj14PvFyrXRBmHe3fHUiKnXMlt8Ro6BqC63F6PCTaI6T1dqlwfMgKBLm4CHJ/t3XnKsntSxgwjuHFHNoyrZjxr6Q== ben@tp" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAM+2WB7nD+BbrmLCDk3AzI82EceBD5vXioOvGkVAjVIKKITs+D+Q7i4QpG42S/IIkeojlkodwE5Ht5omCtdqMSa5WBSPXhZASJskJs2EH3dAU23U/Rff6hSP845EO+Gs/zpGTgs5LAVvNpS9oZMiUdWyd/xI2QJlyOpcGbCr9AO1lGN5+Ls/ZJtCYL9W4F/Zp5H9ApYS8Z/EReiFY/TH0zngGj8sX3/L/em99H1aaFpkef9J2ZMZX13ixHhVfElA877Fj4CmLIX+aYXa24JBDBZLOJCsEK9WdCBo4imEfVd42Wm9FexRgDknpzfSOTVnukLN9lrYwr5FvUcHOOKE1 fpokryvk@rh" >> /root/.ssh/authorized_keys

}

export_python_command() {
    if [ -f /tmp/python_command ]; then
        PYTHON_COMMAND=$(cat /tmp/python_command)
        if [ -n "$PYTHON_COMMAND" ]; then
            python() {
            if [ -f /tmp/python_command ]; then
                PYTHON_COMMAND=$(cat /tmp/python_command)
                if [ -n "$PYTHON_COMMAND" ]; then
                    $PYTHON_COMMAND $@
                fi
            fi
            }
            export -f python
        fi
    fi
}

enable_abrt_el8 () {
    if which abrt-auto-reporting > /dev/null; then
        systemctl stop systemd-coredump.socket
        systemctl mask systemd-coredump.socket
        abrt-auto-reporting enabled
        systemctl restart abrt-journal-core.service
        systemctl restart abrt-ccpp.service
    else
        echo "ABRT probably not installed !!!"
    fi
}

local_setup_configure_nm_eth () {
    [ -e /tmp/nm_eth_configured ] && return

    # Set the root password to 'networkmanager' (for overcoming polkit easily)
    echo "Setting root password to 'networkmanager'"
    echo "networkmanager" | passwd root --stdin

    echo "Setting test's password to 'networkmanager'"
    userdel -r test
    sleep 1
    useradd -m test
    echo "networkmanager" | passwd test --stdin

    # Adding chronyd and syncing
    systemctl restart chronyd.service

    # Pull in debugging symbols
    if [ ! -e /tmp/nm_no_debug ]; then
        cat /proc/$(pidof NetworkManager)/maps | awk '/ ..x. / {print $NF}' |
            grep '^/' | xargs rpm -qf | grep -v 'not owned' | sort | uniq |
            xargs debuginfo-install -y
    fi

    # Restart with valgrind
    if [ -e /etc/systemd/system/NetworkManager-valgrind.service ]; then
        ln -s NetworkManager-valgrind.service /etc/systemd/system/NetworkManager.service
        systemctl daemon-reload
    elif [[      -e /etc/systemd/system/NetworkManager.service.d/override.conf-strace
            && ! -e /etc/systemd/system/NetworkManager.service.d/override.conf ]]; then
        ln -s override.conf-strace /etc/systemd/system/NetworkManager.service.d/override.conf
        systemctl daemon-reload
    fi

    # Removing rate limit for systemd journaling
    sed -i 's/^#\?\(RateLimitInterval *= *\).*/\10/' /etc/systemd/journald.conf
    sed -i 's/^#\?\(RateLimitBurst *= *\).*/\10/' /etc/systemd/journald.conf
    sed -i 's/^#\?\(SystemMaxUse *= *\).*/\115G/' /etc/systemd/journald.conf
    systemctl restart systemd-journald.service

    # Fake console
    echo "Faking a console session..."
    touch /run/console/test
    echo test > /run/console/console.lock

    # Passwordless sudo
    echo "enabling passwordless sudo"
    if [ -e /etc/sudoers.bak ]; then
    mv -f /etc/sudoers.bak /etc/sudoers
    fi
    cp -a /etc/sudoers /etc/sudoers.bak
    grep -v requiretty /etc/sudoers.bak > /etc/sudoers
    echo 'Defaults:test !env_reset' >> /etc/sudoers
    echo 'test ALL=(ALL)   NOPASSWD: ALL' >> /etc/sudoers

    # Setting ulimit to unlimited for test user
    echo "ulimit -c unlimited" >> /home/test/.bashrc

    # Give proper context to openvpn profiles
    chcon -R system_u:object_r:usr_t:s0 tmp/openvpn/sample-keys/

    # Deploy ssh-keys
    deploy_ssh_keys

    # Making sure all wifi devices are named wlanX
    NUM=0
    wlan=0
    for DEV in `nmcli device | grep wifi | awk {'print $1'}`; do
        wlan=1
        ip link set $DEV down
        ip link set $DEV name wlan$NUM
        ip link set wlan$NUM up
        NUM=$(($NUM+1))
    done

    # Install packages for various distributions
    if grep -q 'Fedora' /etc/redhat-release; then
        install_fedora_packages
        if ! check_packages; then
            sleep 20
            install_fedora_packages
        fi
    fi
    if grep -q -e 'Enterprise Linux .*release 8' -e 'CentOS Linux release 8' /etc/redhat-release; then
        install_el8_packages
        if ! check_packages; then
            sleep 20
            install_el8_packages
        fi
        enable_abrt_el8
    fi
    if grep -q -e 'Enterprise Linux .*release 7' -e 'CentOS Linux release 7' /etc/redhat-release; then
        install_el7_packages
        if ! check_packages; then
            sleep 20
            install_el7_packages
        fi
    fi

    # Do we have special HW needs?
    dcb_inf_wol_sriov=0
    if [[ $1 == *sriov_* ]]; then
        dcb_inf_wol_sriov=1
    fi
    if [[ $1 == *dcb_* ]]; then
        dcb_inf_wol_sriov=1
    fi
    if [[ $1 == *inf_* ]]; then
        dcb_inf_wol_sriov=1
    fi
    if [[ $1 == *wol_* ]]; then
        dcb_inf_wol_sriov=1
    fi
    if [[ $1 == *dpdk_* ]]; then
        dcb_inf_wol_sriov=1
    fi
    # We need this if yes
    if [ $dcb_inf_wol_sriov -eq 1 ]; then
        touch /tmp/nm_dcb_inf_wol_sriov_configured
    fi

    # Do we need virtual eth setup?
    veth=0
    if [ $wlan -eq 0 ]; then
        if [ $dcb_inf_wol_sriov -eq 0 ]; then
            for X in $(seq 0 10); do
                if ! nmcli -f DEVICE -t device |grep eth${X}$; then
                    veth=1
                    break
                else
                    # Setting ipv6 dad to 0 as parallel test on different machines
                    # there can be dad connected failures
                    sysctl net.ipv6.conf.eth$X.accept_dad=0
                fi
            done

        fi
    fi

    # Do veth setup if yes
    if [ $veth -eq 1 ]; then
        . prepare/vethsetup.sh setup

        # If we are on RHEL8 let's test nettools DHCP plugin too
        if grep -q -e 'Enterprise Linux .*release 8' /etc/redhat-release; then
            echo -e "[main]\ndhcp=nettools\n" >> /etc/NetworkManager/conf.d/99-test.conf
        fi

        # Copy this once more just to be sure it's there as it's really crucial
        yes 2>/dev/null | cp -rf /etc/sysconfig/network-scripts/ifcfg-testeth0 /tmp/testeth0
        cat /tmp/testeth0

        touch /tmp/nm_newveth_configured

    else
        # Profiles tuning
        if [ $wlan -eq 0 ]; then
            if [ $dcb_inf_wol_sriov -eq 0 ]; then
                nmcli connection add type ethernet ifname eth0 con-name testeth0
                nmcli connection delete eth0
                #nmcli connection modify testeth0 ipv6.method ignore
                nmcli connection up id testeth0
                nmcli con show -a
                for X in $(seq 1 10); do
                    nmcli connection add type ethernet con-name testeth$X ifname eth$X autoconnect no
                    nmcli connection delete eth$X
                done
                nmcli connection modify testeth10 ipv6.method auto
            fi

            # THIS NEEDS TO BE DONE HERE AS DONE SEPARATELY IN VETHSETUP FOR RECREATION REASONS
            nmcli c modify testeth0 ipv4.route-metric 99 ipv6.route-metric 99
            sleep 1
            # Copy final connection to /tmp/testeth0 for later in test usage
            yes 2>/dev/null | cp -rf /etc/sysconfig/network-scripts/ifcfg-testeth0 /tmp/testeth0

        fi

        if [ $wlan -eq 1 ]; then
            # obtain valid certificates
            mkdir /tmp/certs
            wget http://wlan-lab.eng.bos.redhat.com/certs/eaptest_ca_cert.pem -O /tmp/certs/eaptest_ca_cert.pem
            wget http://wlan-lab.eng.bos.redhat.com/certs/client.pem -O /tmp/certs/client.pem
            touch /tmp/nm_wifi_configured
        fi
    fi

    systemctl stop firewalld
    systemctl mask firewalld

    nmcli c u testeth0


    systemctl restart NetworkManager
    sleep 10
    nmcli con up testeth0; rc=$?
    if [ $rc -ne 0 ]; then
        sleep 20
        nmcli con up testeth0
    fi

    yum -y install NetworkManager-config-server
    touch /tmp/nm_eth_configured
}

local_setup_configure_nm_dcb () {
    [ -e /tmp/dcb_configured ] && return

    #start dcb modules
    yum -y install lldpad fcoe-utils
    systemctl enable fcoe
    systemctl start fcoe
    systemctl enable lldpad
    systemctl start lldpad

    modprobe -r ixgbe; modprobe ixgbe
    sleep 2
    dcbtool sc p6p2 dcb on

    touch /tmp/dcb_configured
}

local_setup_configure_nm_inf () {
    [ -e /tmp/inf_configured ] && return

    DEV_MASTER=$(nmcli -t -f DEVICE device  |grep -o .*ib0$)
    echo $DEV_MASTER
    for VLAN in $(nmcli -t -f DEVICE device  |grep ib0 | awk 'BEGIN {FS = "."} {print $2}'); do
        DEV="$DEV_MASTER.$VLAN"
        NEW_DEV="inf_ib0.$VLAN"
        ip link set $DEV down
        sleep 1
        ip link set $DEV name $NEW_DEV
        ip link set $NEW_DEV up
        nmcli con del $DEV
    done
    ip link set $DEV_MASTER down
    sleep 1
    ip link set $DEV_MASTER name inf_ib0
    ip link set inf_ib0 up
    nmcli con del $DEV_MASTER

    touch /tmp/inf_configured
}

install_usb_hub_driver_el () {
    # Works under RHEL 8.0.
    yum install -y libffi-devel python36-devel
    pushd tmp/usb_hub
        # The module brainstem is already stored in project NetworkManager-ci.
        tar xf brainstem_dev_kit_ubuntu_lts_18.04_no_qt_x86_64_1.tgz
        cd development/python/
        python -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
    popd
    return $rc
}

install_usb_hub_driver_fc29 () {
    # Accomodate to Fedora 29.
    yum install -y libffi-devel python3-devel python-unversioned-command
    pushd tmp/usb_hub
        # The module brainstem is already stored in project NetworkManager-ci.
        tar xf brainstem_dev_kit_ubuntu_lts_18.04_no_qt_x86_64_1.tgz
        cd development/python/
        python -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
        # bash: python: command not found...
        #Install package 'python-unversioned-command' to provide command 'python'? [N/y]
    popd
    return $rc
}

install_usb_hub_utility () {
    # Utility for Acroname USB hub has already been donwloaded.
    # git clone https://github.com/rcorreia/acroname-python-cli.git
    # Using a local copy of that utility.
    # Augment the default search path for Python modules.
    if [ -z "$PYTHONPATH" ]; then
        export PYTHONPATH=$(pwd)/tmp/usb_hub/acroname.py
    else
        export PYTHONPATH=$PYTHONPATH:$(pwd)/tmp/usb_hub/acroname.py
    fi
    [ -z "$PYTHONPATH" ] && return 1 || return 0
    # How to use PYTHONPATH?
    # See :https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPATH
}

local_setup_configure_nm_gsm () {
    local RC=1
    [ -e /tmp/gsm_configured ] && return

    mkdir /mnt/scratch
    mount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch

    VER=$(rpm -q --queryformat '%{VERSION}' NetworkManager)
    REL=$(rpm -q --queryformat '%{RELEASE}' NetworkManager)

    if [ -d /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/ ]; then
        pushd /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/$(arch)
            yum -y install NetworkManager-wwan-$VER-$REL.$(arch).rpm ModemManager usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL.$(arch).rpm
        popd
    else
        yum -y install NetworkManager-wwan-$VER-$REL ModemManager usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL
    fi

    systemctl restart ModemManager
    sleep 60
    systemctl restart NetworkManager
    sleep 120

    # Selinux policy for gsm_sim (ModemManager needs access to /dev/pts/*)
    semodule -i tmp/selinux-policy/ModemManager.pp

    # Prepare conditions for using Acroname USB hub.
    if grep -q -E 'Enterprise Linux .*release|CentOS Linux .*release' /etc/redhat-release; then
        install_usb_hub_driver_el; RC=$?
    elif grep -q -E 'Fedora .*release' /etc/redhat-release; then
        install_usb_hub_driver_fc29; RC=$?
    else
        echo "Unsupported OS by Brainstem module." >&2
        return 1
    fi

    if [ $RC -ne 0 ]; then
        echo "Error when installing USB hub driver.">&2
        return 1
    fi

    if ! install_usb_hub_utility; then
        echo "Error when installing USB hub utility.">&2
        return 1
    fi

    touch /tmp/gsm_configured
}

setup_configure_environment () {
    local_setup_configure_nm_eth "$1"
    case "$1" in
        *dcb_*)
            local_setup_configure_nm_dcb
            ;;
        *inf_*)
            local_setup_configure_nm_inf
            ;;
        *gsm*)
            local_setup_configure_nm_gsm
            ;;
    esac
}
