# Some URL shorteners
KOJI="https://kojipkgs.fedoraproject.org/packages"
BREW="http://download.eng.bos.redhat.com/brewroot/vol"
FEDP="https://vbenes.fedorapeople.org/NM"
CBSC="https://cbs.centos.org/kojifiles/packages"
KHUB="https://kojihub.stream.centos.org/kojifiles/packages"

install_behave_pytest () {
  python -m pip install behave
  python -m pip install behave_html_formatter
  echo -e "[behave.formatters]\nhtml = behave_html_formatter:HTMLFormatter" > ~/.behaverc
  ln -s /usr/bin/behave-3 /usr/bin/behave
  # pytest is needed for NetworkManager-ci unit tests and nmstate test
  python -m pip install pytest
  # black is needed by unit tests to check code format
  # stick to fedora 33 version of black: 19.10b0
  python -m pip install --prefix /usr/ black==19.10b0
}


check_packages () {
    rpm -q iw ethtool wireshark-cli NetworkManager-openvpn NetworkManager-ppp NetworkManager-pptp NetworkManager-tui NetworkManager-team NetworkManager-wifi NetworkManager-vpnc NetworkManager-strongswan && ls /usr/bin/behave
    return $?
}


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
    if ! rpm -q --quiet NetworkManager-ovs; then
        yum -y install NetworkManager-ovs
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
    if ! rpm -q --quiet NetworkManager-ovs; then
        dnf -4 -y install NetworkManager-ovs
    fi
    if ! rpm -q --quiet NetworkManager-ppp && ! rpm -q NetworkManager |grep -q '1.4'; then
        dnf -4 -y install NetworkManager-ppp
    fi
    if ! rpm -q --quiet NetworkManager-openvpn; then
        dnf -4 -y install NetworkManager-openvpn
    fi
}


enable_abrt () {
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


configure_nm_dcb () {
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


configure_nm_inf () {
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


install_usb_hub_utility () {
    # Utility for Acroname USB hub has already been donwloaded.
    # git clone https://github.com/rcorreia/acroname-python-cli.git
    # Using a local copy of that utility.
    # Augment the default search path for Python modules.
    if [ -z "$PYTHONPATH" ]; then
        export PYTHONPATH=$(pwd)/contrib/usb_hub/acroname.py
    else
        export PYTHONPATH=$PYTHONPATH:$(pwd)/contrib/usb_hub/acroname.py
    fi
    [ -z "$PYTHONPATH" ] && return 1 || return 0
    # How to use PYTHONPATH?
    # See :https://docs.python.org/3/using/cmdline.html#envvar-PYTHONPATH
}


configure_nm_gsm () {
    local RC=1
    [ -e /tmp/gsm_configured ] && return

    mkdir /mnt/scratch
    mount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch

    VER=$(rpm -q --queryformat '%{VERSION}' NetworkManager)
    REL=$(rpm -q --queryformat '%{RELEASE}' NetworkManager)

    if [ -d /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/ ]; then
        pushd /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/$(arch)
            yum -y install \
                NetworkManager-wwan-$VER-$REL.$(arch).rpm ModemManager \
                usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL.$(arch).rpm
        popd
    else
        yum -y install \
            usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL \
            NetworkManager-wwan-$VER-$REL ModemManager
    fi

    # Reset USB devices
    for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 0 > $i; done
    for i in $(ls /sys/bus/usb/devices/usb*/authorized); do echo 1 > $i; done

    systemctl restart ModemManager
    sleep 5
    systemctl restart NetworkManager

    # Selinux policy for gsm_sim (ModemManager needs access to /dev/pts/*)
    semodule -i contrib/selinux-policy/ModemManager.pp

    # Prepare conditions for using Acroname USB hub.
    if grep -q -E 'Enterprise Linux .*release|CentOS.*release' /etc/redhat-release; then
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


install_usb_hub_driver_fc29 () {
    # Accomodate to Fedora 29.
    yum install -y libffi-devel python3-devel python-unversioned-command
    mkdir /tmp/brainstem
    pushd contrib/usb_hub
        # The module brainstem is already stored in project NetworkManager-ci.
        tar -C /tmp/brainstem -xf brainstem_dev_kit_ubuntu_lts_18.04_no_qt_x86_64_1.tgz
        cd /tmp/brainstem/development/python/
        python -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
    popd
    return $rc
}


install_usb_hub_driver_el () {
    # Works under RHEL 8.0.
    yum install -y libffi-devel python36-devel
    mkdir /tmp/brainstem
    pushd contrib/usb_hub
        # The module brainstem is already stored in project NetworkManager-ci.
        if grep -q -e 'Enterprise Linux .*release 7' -e 'CentOS Linux release 7' /etc/redhat-release; then
            # Compatible with RHEL7
            tar -C /tmp/brainstem -xf brainstem_dev_kit_ubuntu_lts_14.04_x86_64.tgz
            cd /tmp/brainstem/development/python/
            python -m pip install brainstem-2.7.1-py2.py3-none-any.whl; local rc=$?
        else
            # And with RHEL8
            tar -C /tmp/brainstem -xf brainstem_dev_kit_ubuntu_lts_18.04_no_qt_x86_64_1.tgz
            cd /tmp/brainstem/development/python/
            python -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
        fi
    popd
    return $rc
}

get_online_state() {
    echo -n > /tmp/nmcli_general
    for i in {1..20}; do
        nmcli general | tee --append - /tmp/nmcli_general | grep -q "^connected" && return 0
        echo "get online state #$i failed"
        sleep 1
    done
    return 1
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


deploy_ssh_keys () {
    if ! test -d /root/.ssh; then
        mkdir /root/.ssh/
    fi

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGO5ve3AN8ynbd6/0DfG0Vm9mVxBKvO0oVERpkqj+sfO thaller@redhat.com" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLEW8B8/uX4VpsKIwrtrqBc/dAq+EaL17iegWZGR1qFbhC4xt8X+BoGRH/A9DlZPKhdMENHz+ZZT2XHkhLGSoRq0ElDM/WB9ppGxaVDh6plhvJL9aV8W8QcvOUPatdggGR3/b0qqnbGMwWnbPLJgqu/XwVm+z92oBJHh0W65cRg5jw/jedVPzFHe0ZVwfpZT3eUL2p6H16NV3phZVoIAJbkMEf59vSfKgK2816nNtKWCjwtCIzSR/K9KzejAfpUKyJNlNfxjtkoFf2zorPrdTT+DXiPprkTcExS4YEQl3fPp2/jT6gpcXuR+q8OGMIZDO8NkFVLL9AXhjR7nY+6Vr vbenes@benjoband" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT5g6igQ5ug29wJakhGGMUm8ZeeP8iXGDFMGyn9c5JGBcKHp2YI8xx6tWZcTTORLmk47OG6W87LS7iXfhTeUUWZ2kXSIaoU7B+ZyJBYUR6J0qqUMrYgD2RLeiO74BsI6bI1Hz1S0Y6gDgsuBDI0QTtaJ+Z3ISDkBROfiRYG3LaPObvPdnFOpYqqd6jsKFHHgGrQPd45Qi/CJ7enXGMOGiqlN/XzdJni7V67jAbW0C2/7caYLCayWJvEt1ZuFFhFoFV6aCbfo3MaHPJXBbiIiT/bGeInFgsdDymryj/CW1CZUzk5jcnD8hj/ZCG9At/2+M8dVfjtXBHpaP6TBw4I+hCxiDFjzDSAhXMb7xtFRZMKW9PeshNJkmfVaOuD6XHCZr3TcYnh0fU4+mJ2Wg1em//885pLiCgpJ41kNjv9b8zRUlkfqn46lkm0vQ0ikvOO83UgV3d6Et9Us1P42AYSM4Ed0mISw5rB2/9LAS0P8OmddgDzWoSks2tTVE29I1/dKNBslnAFTtE+ILIN3bYY1pY7lrRFZkJ23bXaTXqqsWfk95h0gh8u7O1JqP3nrHqH9y9TTPTjWTXglu2ZIvgmexj14PvFyrXRBmHe3fHUiKnXMlt8Ro6BqC63F6PCTaI6T1dqlwfMgKBLm4CHJ/t3XnKsntSxgwjuHFHNoyrZjxr6Q== ben@tp" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAM+2WB7nD+BbrmLCDk3AzI82EceBD5vXioOvGkVAjVIKKITs+D+Q7i4QpG42S/IIkeojlkodwE5Ht5omCtdqMSa5WBSPXhZASJskJs2EH3dAU23U/Rff6hSP845EO+Gs/zpGTgs5LAVvNpS9oZMiUdWyd/xI2QJlyOpcGbCr9AO1lGN5+Ls/ZJtCYL9W4F/Zp5H9ApYS8Z/EReiFY/TH0zngGj8sX3/L/em99H1aaFpkef9J2ZMZX13ixHhVfElA877Fj4CmLIX+aYXa24JBDBZLOJCsEK9WdCBo4imEfVd42Wm9FexRgDknpzfSOTVnukLN9lrYwr5FvUcHOOKE1 fpokryvk@rh" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHKLPGOLAnqR5PnP5InIedERR3/MrfmqHjchkv7HVnyb acabral@fedora" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnMu9jib5rn5lewW6HihXO2xQKBcXS41SHUaBUcAqX9qXbjeLqlelR51Ny6NTbWTp7k1j1LONzwU7ON6vZW49JvB6S3gf9NuN3wa/0XhelW8Rt6k9Odr7MZCsM74HdkVJpDuzUPh0qquUnInbYulv61CumyM3GZy82oLrpuh/JbxlpsqA/ue7rY7avnxIGEs8luC+a80oGfDJHxMS61TbarqDqkHUfXDeFm5TsJvBxRnd29kEnl7BwzaVImeY33X29V1atYo7BWO1DAGS5jBKM2kUXBxLzxv65+j2VZXP6ybKGnWVLzoUGNgyM/qH78qitvH6A1IOgwC9DiL8aOVHHaF6pWStZj9NSRkCixsxb1514EAlwmz5FvonPtv2GK6J+GTcWNCOg4tp9Ul7uwuUjiBhrjXLohl6VYA1Pvu0PBt+UALY9As8oLwmmv1QdmTfuFZPtT1LtGE+iDg2oUDht2iM8W24RUgLdyoaDY/DYbXMHXU5sH+3m+W9bppkpp00= mberezny@mberezny.brq.csb" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8JdDCWm0s/AJOF0Rjo07iV8fr5ELb/eWdP22yzWJmrZXlZZOT4yZcK5UJFW025ZDkblJ2MM8XSxGFPlBoHXyoKR5lg1gfNwcvKlZqBCWyubB+0oIEeq8t5Qj2KVIqc23e0ggVH0aqdKkWodixy+CujbhVxkthV+50IpQjhl0Yu6rA7jImDMuLS7DpKi68VPnBs9/RYMcN/5pU82suarJthXD+/alRg0B0TOa+jRt/hfBnf1rjZmjtvC64Y6g2M6XKA/7gcRgWeYi6WAXpyLE0lX5xLXJiyno6beQNMF6Mh4hkqM8CA14b9+1T7kn9vx5V0MCmfxe4/Ijk49Mfnuo3 djasa@redhat.com" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINXo1HJIv0UugufvaHAog5xJWDQdU2i9rg2y7D5HmtKs lkundrak@bzdocha.local" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD0faK/BixbvynP370pYtQ/OZMBk7RnezVBa8nhWi7Txr7g8BZqZftm0uaGRaIXZmFO1QHlvPJJ59GrKTBvAg/YF8K/FoKnMavGlGeKUM9WYlGigTYx/IzvkReEFplq5AnpON+Waw2urhcqptYJ1xG5phVNmZUXNJU7Idfgyw7axppsFLMzq9QJQSm7yt1TqucyWaH8feAaG9RBAG4ci2tEHrQBCXiy9YyiaRhiZBoBAsW9RcZv0JdiML5MJNoIMDM0Ybax+Gcaqf97So3Tr7NEI1olBml96d3b72vAvQ+tn1C2DrwAwoqYvx4+W4q+qE4nmslCmySq0Gx4A26ZQ0WIhrQiGivVQ4talXVsBvr+uA6CAENWdvGUYhV+M662rRQEzbcCtsHh5bRwUUbz5rp5+NRm2I78ZY4Bjc5aWjJT1UMBbha/wrbGamjUX4J1zMSCJc7DGdgsANTTSKH8uQrFnV/C/kYVtg5dbQcr8Ng/cIZO4YKhx6yKAfWmQkUAWIU= wenliang@localhost.localdomain" >> /root/.ssh/authorized_keys
}
