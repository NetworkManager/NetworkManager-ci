# get distro and version
DISTRO_ID="$(. /etc/os-release; echo "$ID")"
DISTRO_ID_LIKE="$(. /etc/os-release; echo "$ID_LIKE")"
DISTRO_VERSION_ID="$(. /etc/os-release; echo "$VERSION_ID")"
DISTRO_PRETTY_NAME="$(. /etc/os-release; echo "$PRETTY_NAME")"
IFS_BACKUP="$IFS"
IFS="."
DISTRO_V=($DISTRO_VERSION_ID)
IFS="$IFS_BACKUP"


ver_cmp () {
    local IFS="."
    local V1=($1)
    local OP="$2"
    local V2=($3)
    IFS="$IFS_BACKUP"
    local LEN1="${#V1[@]}"
    local LEN2="${#V2[@]}"
    local LEN="$((LEN1 < LEN2 ? LEN1 : LEN2))"
    if [[ "${OP:0:1}" = "=" || "${OP:1:1}" = "=" ]]; then
        [[ "${V1[@]::$LEN}" = "${V2[@]::$LEN}" ]] && return 0
    fi
    echo "${V1[@]}"
    echo "${V2[@]}"
    case "${OP}" in
        "==" | "=")
            return 4
            ;;
        "<" | "-" | "<=" | "-=")
            local CHOICE="head"
            ;;
        ">" | "+" | ">=" | "+=")
            local CHOICE="tail"
            ;;
        *)
            echo "OP must be '[=<+>-]=?', was: ${OP}" >&2
            return 8
    esac
    for ((i=0; i < LEN; i++)); do
        if [[ "${V1[i]}" = "${V2[i]}" ]]; then
            ((i < LEN-1)) && continue || return 5
        fi
        if [[ "${V1[i]}" = "$(printf "%s\n%s" "${V1[i]}" "${V2[i]}" | sort -n | "${CHOICE}" -n1)" ]]; then
            return 0
        else
            return 6
        fi
    done
}


distro_version () {
    # usage: distro_version (exact|like) CMP1 [CMP2, ...]:
    #   - use "exact" for fedora, use "like" to match both rhel+centos
    #   - gt, lt: "rhel < 9.5", "rhel - 9.5", "rhel > 9.5", "rhel + 9.5"
    #   - ge, le: "rhel <= 9.5", "rhel -= 9.5", "rhel >= 9.5", "rhel += 9.5"
    #   - eq "rhel = 9.5", "rhel == 9.5" (the same thing)
    cmp="$1"
    shift
    for i in "${@}"; do
        local ARG=($i)
        OS="${ARG[0]}"
        OP="${ARG[1]}"
        V="${ARG[2]}"
        case "$cmp" in
            exact) [[ "$OS" = "$DISTRO_ID" ]] || return 2
                ;;
            like) echo "$DISTRO_ID $DISTRO_ID_LIKE" | grep -q "$OS" || return 3
                ;;
        esac
        ver_cmp "$DISTRO_VERSION_ID" "$OP" "$V"
        res="$?"
        [[ "$res" -eq "0" ]] || return "$res"
    done
}


# Some URL shorteners
KOJI="https://kojipkgs.fedoraproject.org/packages"
BREW="http://download.eng.bos.redhat.com/brewroot/vol"
FEDP="https://vbenes.fedorapeople.org/NM"
CBSC="https://cbs.centos.org/kojifiles/packages"
KHUB="https://kojihub.stream.centos.org/kojifiles/packages"
MBOX="https://koji.mbox.centos.org/pkgs/packages"

fix_python3_link() {
    rm -f /usr/bin/python
    ln -s `which python3` /usr/bin/python
}


install_behave_pytest () {
  # stable release is old, let's use the lastest available tagged release
  #python -m pip install behave
  if [ -f /tmp/keep_old_behave ]; then
    python -m pip install behave --prefix=/usr/ --force-reinstall
  else
    python -m pip install "git+https://github.com/behave/behave@v1.2.7.dev4#egg=behave" --prefix=/usr/ --force-reinstall
  fi
  python -m pip install behave_html_pretty_formatter

  python -m pip install behave_html_formatter
  echo -e "[behave.formatters]\nhtml = behave_html_formatter:HTMLFormatter" > ~/.behaverc

  which behave || ln -s `which behave-3` /usr/bin/behave
  # pytest is needed for NetworkManager-ci unit tests and nmstate test
  python -m pip install pytest
  # fix click version because of black bug
  # https://github.com/psf/black/issues/2964
  python -m pip install click==8.0.4
  # black is needed by unit tests to check code format
  # stick to fedora 33 version of black: 22.3.0
  python -m pip install --prefix /usr/ black==22.3.0
  # install sphinx to build nmci documentation
  python -m pip install --prefix /usr/ sphinx==7.2.6 || touch /tmp/nm_skip_nmci_doc
  python -m pip install sphinx-markdown-builder==0.6.5 || touch /tmp/nm_skip_nmci_doc
}


check_packages () {
    rpm -q iw ethtool wireshark-cli \
           NetworkManager-{openvpn,ppp,pptp,tui,team,wifi,strongswan} || \
        return 1
    which behave || return 1
    which python || return 1
}


install_plugins_yum () {
    # Installing plugins if missing
    pkgs=" "
    if ! rpm -q --quiet NetworkManager-wifi; then
        pkgs+=" NetworkManager-wifi"
    fi
    if ! rpm -q --quiet NetworkManager-team; then
        pkgs+=" NetworkManager-team"
    fi
    if ! rpm -q --quiet NetworkManager-wwan; then
        pkgs+=" NetworkManager-wwan"
    fi
    if ! rpm -q --quiet NetworkManager-tui; then
        pkgs+=" NetworkManager-tui"
    fi
    if ! rpm -q --quiet NetworkManager-cloud-setup; then
        pkgs+=" NetworkManager-cloud-setup"
    fi
    if ! rpm -q --quiet NetworkManager-pptp; then
        pkgs+=" NetworkManager-pptp"
    fi
    if ! rpm -q --quiet NetworkManager-ovs; then
        pkgs+=" NetworkManager-ovs"
    fi
    if ! rpm -q --quiet NetworkManager-ppp; then
        pkgs+=" NetworkManager-ppp"
    fi
    if ! rpm -q --quiet NetworkManager-openvpn; then
        pkgs+=" NetworkManager-openvpn"
    fi
    if ! rpm -q --quiet NetworkManager-libreswan; then
        pkgs+=" NetworkManager-libreswan"
    fi
    test -n "$pkgs" && yum -y install $pkgs
}


install_plugins_dnf () {
    PKGS_INSTALL="$PKGS_INSTALL \
        NetworkManager-wifi \
        NetworkManager-wwan \
        NetworkManager-tui \
        NetworkManager-cloud-setup \
        NetworkManager-pptp \
        NetworkManager-ovs \
        NetworkManager-ppp \
        NetworkManager-openvpn \
        NetworkManager-strongswan \
        NetworkManager-libreswan"

    if ! grep -q -e 'release 10' /etc/redhat-release; then
        PKGS_INSTALL="$PKGS_INSTALL \
            NetworkManager-team"
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

    DEV_MASTER=$(nmcli -t -f DEVICE device  |grep -o .*ib0$ |head -n 1)
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

    # mkdir /mnt/scratch
    # mount -t nfs nest.test.redhat.com:/mnt/qa/desktop/broadband_lock /mnt/scratch

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
        nmcli general | tee --append /tmp/nmcli_general | grep -q "^connected" && return 0
        echo "get online state #$i failed"
        (( i % 10 )) || {
            echo "After crash reset:";
            python3 -c "import nmci; nmci.crash.after_crash_reset()";
            continue;
        }
        (( i % 5 )) || {
            echo "Wait for testeth0";
            python3 -c "import nmci; nmci.veth.wait_for_testeth0()";
            continue;
        }
        sleep 1
    done
    return 1
}

get_centos_pkg_release() {
    DISTRO="el$(awk -F ' ' '{print $NF}' /etc/redhat-release)"
    VER=$(curl -s $1/ | \
           grep $DISTRO | \
           grep 'a href' | \
           tail -n -1 | \
           awk -F 'href=\"' '{print $2}' | \
           awk -F '/' '{print $1}')
    echo $VER
}

deploy_ssh_keys () {
    if ! test -d /root/.ssh; then
        mkdir /root/.ssh/
    fi

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLEW8B8/uX4VpsKIwrtrqBc/dAq+EaL17iegWZGR1qFbhC4xt8X+BoGRH/A9DlZPKhdMENHz+ZZT2XHkhLGSoRq0ElDM/WB9ppGxaVDh6plhvJL9aV8W8QcvOUPatdggGR3/b0qqnbGMwWnbPLJgqu/XwVm+z92oBJHh0W65cRg5jw/jedVPzFHe0ZVwfpZT3eUL2p6H16NV3phZVoIAJbkMEf59vSfKgK2816nNtKWCjwtCIzSR/K9KzejAfpUKyJNlNfxjtkoFf2zorPrdTT+DXiPprkTcExS4YEQl3fPp2/jT6gpcXuR+q8OGMIZDO8NkFVLL9AXhjR7nY+6Vr vbenes@benjoband" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT5g6igQ5ug29wJakhGGMUm8ZeeP8iXGDFMGyn9c5JGBcKHp2YI8xx6tWZcTTORLmk47OG6W87LS7iXfhTeUUWZ2kXSIaoU7B+ZyJBYUR6J0qqUMrYgD2RLeiO74BsI6bI1Hz1S0Y6gDgsuBDI0QTtaJ+Z3ISDkBROfiRYG3LaPObvPdnFOpYqqd6jsKFHHgGrQPd45Qi/CJ7enXGMOGiqlN/XzdJni7V67jAbW0C2/7caYLCayWJvEt1ZuFFhFoFV6aCbfo3MaHPJXBbiIiT/bGeInFgsdDymryj/CW1CZUzk5jcnD8hj/ZCG9At/2+M8dVfjtXBHpaP6TBw4I+hCxiDFjzDSAhXMb7xtFRZMKW9PeshNJkmfVaOuD6XHCZr3TcYnh0fU4+mJ2Wg1em//885pLiCgpJ41kNjv9b8zRUlkfqn46lkm0vQ0ikvOO83UgV3d6Et9Us1P42AYSM4Ed0mISw5rB2/9LAS0P8OmddgDzWoSks2tTVE29I1/dKNBslnAFTtE+ILIN3bYY1pY7lrRFZkJ23bXaTXqqsWfk95h0gh8u7O1JqP3nrHqH9y9TTPTjWTXglu2ZIvgmexj14PvFyrXRBmHe3fHUiKnXMlt8Ro6BqC63F6PCTaI6T1dqlwfMgKBLm4CHJ/t3XnKsntSxgwjuHFHNoyrZjxr6Q== ben@tp" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAM+2WB7nD+BbrmLCDk3AzI82EceBD5vXioOvGkVAjVIKKITs+D+Q7i4QpG42S/IIkeojlkodwE5Ht5omCtdqMSa5WBSPXhZASJskJs2EH3dAU23U/Rff6hSP845EO+Gs/zpGTgs5LAVvNpS9oZMiUdWyd/xI2QJlyOpcGbCr9AO1lGN5+Ls/ZJtCYL9W4F/Zp5H9ApYS8Z/EReiFY/TH0zngGj8sX3/L/em99H1aaFpkef9J2ZMZX13ixHhVfElA877Fj4CmLIX+aYXa24JBDBZLOJCsEK9WdCBo4imEfVd42Wm9FexRgDknpzfSOTVnukLN9lrYwr5FvUcHOOKE1 fpokryvk@rh" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCnMu9jib5rn5lewW6HihXO2xQKBcXS41SHUaBUcAqX9qXbjeLqlelR51Ny6NTbWTp7k1j1LONzwU7ON6vZW49JvB6S3gf9NuN3wa/0XhelW8Rt6k9Odr7MZCsM74HdkVJpDuzUPh0qquUnInbYulv61CumyM3GZy82oLrpuh/JbxlpsqA/ue7rY7avnxIGEs8luC+a80oGfDJHxMS61TbarqDqkHUfXDeFm5TsJvBxRnd29kEnl7BwzaVImeY33X29V1atYo7BWO1DAGS5jBKM2kUXBxLzxv65+j2VZXP6ybKGnWVLzoUGNgyM/qH78qitvH6A1IOgwC9DiL8aOVHHaF6pWStZj9NSRkCixsxb1514EAlwmz5FvonPtv2GK6J+GTcWNCOg4tp9Ul7uwuUjiBhrjXLohl6VYA1Pvu0PBt+UALY9As8oLwmmv1QdmTfuFZPtT1LtGE+iDg2oUDht2iM8W24RUgLdyoaDY/DYbXMHXU5sH+3m+W9bppkpp00= mberezny@mberezny.brq.csb" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8JdDCWm0s/AJOF0Rjo07iV8fr5ELb/eWdP22yzWJmrZXlZZOT4yZcK5UJFW025ZDkblJ2MM8XSxGFPlBoHXyoKR5lg1gfNwcvKlZqBCWyubB+0oIEeq8t5Qj2KVIqc23e0ggVH0aqdKkWodixy+CujbhVxkthV+50IpQjhl0Yu6rA7jImDMuLS7DpKi68VPnBs9/RYMcN/5pU82suarJthXD+/alRg0B0TOa+jRt/hfBnf1rjZmjtvC64Y6g2M6XKA/7gcRgWeYi6WAXpyLE0lX5xLXJiyno6beQNMF6Mh4hkqM8CA14b9+1T7kn9vx5V0MCmfxe4/Ijk49Mfnuo3 djasa@redhat.com" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPheKGxDfKPDBJD//mbd5tj2ebWDHg/8poQISJvMq9hwih447ok7t/mXLUpp3ObuJxdQot9aSOxTZF+UgpRLnwWxXinSDO9JNuMgGEQCHOiCkAoKhQ/CTX7WtSFSw+VPIQGiSiawVTBMDujOeMebZ1QJzJmfyspjfOm/uh3BYJKQNwHKRzjL/XmPOzlmQIHJKQq6iTauFz/pgTxLvhcO91sUKFKcDc51JWrxGPreUzPOsd5Qw9gVMC7f2FBH6VPCQlxMezfjstHUZoeYGe/FfAc2CrMmRxzNEGWd+TfBqPn0fYeL5lnK6mpDLNBT4XK2DGbEOjXMxb0ZKkBq/w/VSr lrintel:openpgp:0x8A5CAD03" >> /root/.ssh/authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo+rH7F47RPoXz/89hMoAiEofj/RG+JwI0otXaFrqXLnFeGRbTgD+bAU/Pz1rMLT3/9b41LdqEfEkSpQ3L7hP4Sl0YcbvQWX5WwnePWHmeSxajA66SfW2MSSwOxxaQoZpQWOgN5DQZyBhR9Q6Fd+0qrnLuvHr8EX7XAMGc1YXIQdteSIfnZHHX4fW4NhpufF5lN2fveDjARMp3bnJDKQyEzR56xUkt5MMMp46Mf1AAaZiRRElI+X5IudaUzJzZFiYUvuGwCZBCGvedbK0wgwrwJzb25Ux9JKZrZ3AfdbFFsCPdRGyrkI37NMkpUlUd8qpeqpIc5hKonmzX1lgCvOIF lrintel:openpgp:0xBC6BE460:yubi" >> /root/.ssh/authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCias4Sc1x+d2exaP94spAppuN9ICutG60DBfzpLfgxMj1FgfTl+uAMa4FWkug9I/3hJI3Ed+2/pqR3bvmH5P4KwfI2iRnqUHK5nprd3P48R5Ee5iS/18vRUATyspk6aBY/U9mJsveIu+mSQ9/9E/mmgNzzz/ehPCPMm0KgDlj3qDS+SqoOqJOyR9sB2qdfwbWWMx+VGbj+KU+ol4RQ6JTmpWLZ0hPOljF2oHGsLmavG6ejFRkqb+SJrwoVUx1Aedf2Dh94jXPKvKcsksqhKcIfAQmQGcbqvlCadvQij2kgim8EBP8oatT1Uuy/o73Fa2LMR5f8lykyS+L4Ad7DyA+p lrintel:openpgp:0x71A01118:alt" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD0faK/BixbvynP370pYtQ/OZMBk7RnezVBa8nhWi7Txr7g8BZqZftm0uaGRaIXZmFO1QHlvPJJ59GrKTBvAg/YF8K/FoKnMavGlGeKUM9WYlGigTYx/IzvkReEFplq5AnpON+Waw2urhcqptYJ1xG5phVNmZUXNJU7Idfgyw7axppsFLMzq9QJQSm7yt1TqucyWaH8feAaG9RBAG4ci2tEHrQBCXiy9YyiaRhiZBoBAsW9RcZv0JdiML5MJNoIMDM0Ybax+Gcaqf97So3Tr7NEI1olBml96d3b72vAvQ+tn1C2DrwAwoqYvx4+W4q+qE4nmslCmySq0Gx4A26ZQ0WIhrQiGivVQ4talXVsBvr+uA6CAENWdvGUYhV+M662rRQEzbcCtsHh5bRwUUbz5rp5+NRm2I78ZY4Bjc5aWjJT1UMBbha/wrbGamjUX4J1zMSCJc7DGdgsANTTSKH8uQrFnV/C/kYVtg5dbQcr8Ng/cIZO4YKhx6yKAfWmQkUAWIU= wenliang@localhost.localdomain" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYBZKypoJLLdh1+jn/pLSbnIuqctx5whR8aiao2zMKT ffmancera@riseup.net" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCoHDuTAa/gNH4votMsLZb3etOhY8yffFlddON6YRxm ihuguet@redhat.com" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvOC7JibKnGzTk5SanZTq9NoWwfURWVunh5bDkrQKuRQdlOXzUQ7KLeRr/CpPcyI9c6LYDufmDD1QdBy7vbxCfmAD81IqDewKhKYf3H5YcpylfdytAjLY/0cfMoNisufdiC9y8vF6nkEh/R26/STESmaIT3cjzcO8QqQP3zqS85ungh1gSxpTJwrYBMs3QbgE36lCfWALWHkzKHuEiObIpDC4fEZ4cEqOBN2NIpnWqioWjq0W1NApk+28hVmxrmZSqedTIcZgS/7Hghgmi95pc+lr/SrcVOadqw0JcAe8kP0+Il4r8Y/jkwvJBTkjILTeJQzudaM64D2ke7O26/TFn fge@Gris-Redhat" >> /root/.ssh/authorized_keys

}
