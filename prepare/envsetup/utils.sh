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
    rm -f /usr/bin/python3l
    if [ -f /tmp/keep_old_behave ]; then
        ln -s $(which python3) /usr/bin/python3l
    else
        ln -s $(ls `which python3`* | grep '[0-9]$' | sort -V | tail -n1) /usr/bin/python3l
    fi
}


install_behave_pytest () {
  # this is for gitlab-ci.yml script to work
  shopt -s expand_aliases
  # stable release is old, let's use the lastest available tagged release
  if [ -f /tmp/keep_old_behave ]; then
    python3l -m pip install behave --prefix=/usr/
  else
    python3l -m pip install "git+https://github.com/behave/behave@v1.2.7.dev6#egg=behave" --prefix=/usr/
  fi
  python3l -m pip install behave_html_pretty_formatter

  python3l -m pip install behave_html_formatter
  echo -e "[behave.formatters]\nhtml = behave_html_formatter:HTMLFormatter" > ~/.behaverc

  which behave || ln -s `which behave-3` /usr/bin/behave
  # pytest is needed for NetworkManager-ci unit tests and nmstate test
  python3l -m pip install pytest
  # fix click version because of black bug
  # https://github.com/psf/black/issues/2964
  python3l -m pip install click==8.0.4
  # black is needed by unit tests to check code format
  # stick to fedora 33 version of black: 22.3.0
  python3l -m pip install --prefix /usr/ black==22.3.0
  # install sphinx to build nmci documentation
  python3l -m pip install --prefix /usr/ sphinx==7.2.6 || touch /tmp/nm_skip_nmci_doc
  python3l -m pip install sphinx-markdown-builder==0.6.5 || touch /tmp/nm_skip_nmci_doc
}


check_packages () {
    rpm -q iw ethtool wireshark-cli \
           NetworkManager-{openvpn,ppp,pptp,tui,team,wifi,strongswan} || \
        return 1
    which behave || return 1
    which python3l || return 1
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
                usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL.$(arch).rpm --skip-broken
        popd
    else
        yum -y install \
            usb_modeswitch usbutils NetworkManager-ppp-$VER-$REL \
            NetworkManager-wwan-$VER-$REL ModemManager --skip-broken
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
        python3l -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
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
            python3l -m pip install brainstem-2.7.1-py2.py3-none-any.whl; local rc=$?
        else
            # And with RHEL8
            tar -C /tmp/brainstem -xf brainstem_dev_kit_ubuntu_lts_18.04_no_qt_x86_64_1.tgz
            cd /tmp/brainstem/development/python/
            python3l -m pip install brainstem-2.7.0-py2.py3-none-any.whl; local rc=$?
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
            python3l -c "import nmci; nmci.crash.after_crash_reset()";
            continue;
        }
        (( i % 5 )) || {
            echo "Wait for testeth0";
            python3l -c "import nmci; nmci.veth.wait_for_testeth0()";
            continue;
        }
        sleep 1
    done
    return 1
}

get_centos_pkg_release() {
    DISTRO="el$(grep -o 'release [0-9]*' /etc/redhat-release | grep -o '[0-9]*')"
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

    # Delete all lines possibly added by NM-ci
    sed -i '/# NM_CONTRIBUTORS_START/,/# NM_CONTRIBUTORS_END/ d' /root/.ssh/authorized_keys

    echo "# NM_CONTRIBUTORS_START" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLEW8B8/uX4VpsKIwrtrqBc/dAq+EaL17iegWZGR1qFbhC4xt8X+BoGRH/A9DlZPKhdMENHz+ZZT2XHkhLGSoRq0ElDM/WB9ppGxaVDh6plhvJL9aV8W8QcvOUPatdggGR3/b0qqnbGMwWnbPLJgqu/XwVm+z92oBJHh0W65cRg5jw/jedVPzFHe0ZVwfpZT3eUL2p6H16NV3phZVoIAJbkMEf59vSfKgK2816nNtKWCjwtCIzSR/K9KzejAfpUKyJNlNfxjtkoFf2zorPrdTT+DXiPprkTcExS4YEQl3fPp2/jT6gpcXuR+q8OGMIZDO8NkFVLL9AXhjR7nY+6Vr vbenes@benjoband" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDT5g6igQ5ug29wJakhGGMUm8ZeeP8iXGDFMGyn9c5JGBcKHp2YI8xx6tWZcTTORLmk47OG6W87LS7iXfhTeUUWZ2kXSIaoU7B+ZyJBYUR6J0qqUMrYgD2RLeiO74BsI6bI1Hz1S0Y6gDgsuBDI0QTtaJ+Z3ISDkBROfiRYG3LaPObvPdnFOpYqqd6jsKFHHgGrQPd45Qi/CJ7enXGMOGiqlN/XzdJni7V67jAbW0C2/7caYLCayWJvEt1ZuFFhFoFV6aCbfo3MaHPJXBbiIiT/bGeInFgsdDymryj/CW1CZUzk5jcnD8hj/ZCG9At/2+M8dVfjtXBHpaP6TBw4I+hCxiDFjzDSAhXMb7xtFRZMKW9PeshNJkmfVaOuD6XHCZr3TcYnh0fU4+mJ2Wg1em//885pLiCgpJ41kNjv9b8zRUlkfqn46lkm0vQ0ikvOO83UgV3d6Et9Us1P42AYSM4Ed0mISw5rB2/9LAS0P8OmddgDzWoSks2tTVE29I1/dKNBslnAFTtE+ILIN3bYY1pY7lrRFZkJ23bXaTXqqsWfk95h0gh8u7O1JqP3nrHqH9y9TTPTjWTXglu2ZIvgmexj14PvFyrXRBmHe3fHUiKnXMlt8Ro6BqC63F6PCTaI6T1dqlwfMgKBLm4CHJ/t3XnKsntSxgwjuHFHNoyrZjxr6Q== ben@tp" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAM+2WB7nD+BbrmLCDk3AzI82EceBD5vXioOvGkVAjVIKKITs+D+Q7i4QpG42S/IIkeojlkodwE5Ht5omCtdqMSa5WBSPXhZASJskJs2EH3dAU23U/Rff6hSP845EO+Gs/zpGTgs5LAVvNpS9oZMiUdWyd/xI2QJlyOpcGbCr9AO1lGN5+Ls/ZJtCYL9W4F/Zp5H9ApYS8Z/EReiFY/TH0zngGj8sX3/L/em99H1aaFpkef9J2ZMZX13ixHhVfElA877Fj4CmLIX+aYXa24JBDBZLOJCsEK9WdCBo4imEfVd42Wm9FexRgDknpzfSOTVnukLN9lrYwr5FvUcHOOKE1 fpokryvk@rh" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPheKGxDfKPDBJD//mbd5tj2ebWDHg/8poQISJvMq9hwih447ok7t/mXLUpp3ObuJxdQot9aSOxTZF+UgpRLnwWxXinSDO9JNuMgGEQCHOiCkAoKhQ/CTX7WtSFSw+VPIQGiSiawVTBMDujOeMebZ1QJzJmfyspjfOm/uh3BYJKQNwHKRzjL/XmPOzlmQIHJKQq6iTauFz/pgTxLvhcO91sUKFKcDc51JWrxGPreUzPOsd5Qw9gVMC7f2FBH6VPCQlxMezfjstHUZoeYGe/FfAc2CrMmRxzNEGWd+TfBqPn0fYeL5lnK6mpDLNBT4XK2DGbEOjXMxb0ZKkBq/w/VSr lrintel:openpgp:0x8A5CAD03" >> /root/.ssh/authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo+rH7F47RPoXz/89hMoAiEofj/RG+JwI0otXaFrqXLnFeGRbTgD+bAU/Pz1rMLT3/9b41LdqEfEkSpQ3L7hP4Sl0YcbvQWX5WwnePWHmeSxajA66SfW2MSSwOxxaQoZpQWOgN5DQZyBhR9Q6Fd+0qrnLuvHr8EX7XAMGc1YXIQdteSIfnZHHX4fW4NhpufF5lN2fveDjARMp3bnJDKQyEzR56xUkt5MMMp46Mf1AAaZiRRElI+X5IudaUzJzZFiYUvuGwCZBCGvedbK0wgwrwJzb25Ux9JKZrZ3AfdbFFsCPdRGyrkI37NMkpUlUd8qpeqpIc5hKonmzX1lgCvOIF lrintel:openpgp:0xBC6BE460:yubi" >> /root/.ssh/authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCias4Sc1x+d2exaP94spAppuN9ICutG60DBfzpLfgxMj1FgfTl+uAMa4FWkug9I/3hJI3Ed+2/pqR3bvmH5P4KwfI2iRnqUHK5nprd3P48R5Ee5iS/18vRUATyspk6aBY/U9mJsveIu+mSQ9/9E/mmgNzzz/ehPCPMm0KgDlj3qDS+SqoOqJOyR9sB2qdfwbWWMx+VGbj+KU+ol4RQ6JTmpWLZ0hPOljF2oHGsLmavG6ejFRkqb+SJrwoVUx1Aedf2Dh94jXPKvKcsksqhKcIfAQmQGcbqvlCadvQij2kgim8EBP8oatT1Uuy/o73Fa2LMR5f8lykyS+L4Ad7DyA+p lrintel:openpgp:0x71A01118:alt" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD0faK/BixbvynP370pYtQ/OZMBk7RnezVBa8nhWi7Txr7g8BZqZftm0uaGRaIXZmFO1QHlvPJJ59GrKTBvAg/YF8K/FoKnMavGlGeKUM9WYlGigTYx/IzvkReEFplq5AnpON+Waw2urhcqptYJ1xG5phVNmZUXNJU7Idfgyw7axppsFLMzq9QJQSm7yt1TqucyWaH8feAaG9RBAG4ci2tEHrQBCXiy9YyiaRhiZBoBAsW9RcZv0JdiML5MJNoIMDM0Ybax+Gcaqf97So3Tr7NEI1olBml96d3b72vAvQ+tn1C2DrwAwoqYvx4+W4q+qE4nmslCmySq0Gx4A26ZQ0WIhrQiGivVQ4talXVsBvr+uA6CAENWdvGUYhV+M662rRQEzbcCtsHh5bRwUUbz5rp5+NRm2I78ZY4Bjc5aWjJT1UMBbha/wrbGamjUX4J1zMSCJc7DGdgsANTTSKH8uQrFnV/C/kYVtg5dbQcr8Ng/cIZO4YKhx6yKAfWmQkUAWIU= wenliang@localhost.localdomain" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYBZKypoJLLdh1+jn/pLSbnIuqctx5whR8aiao2zMKT ffmancera@riseup.net" >> /root/.ssh/authorized_keys

    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOCoHDuTAa/gNH4votMsLZb3etOhY8yffFlddON6YRxm ihuguet@redhat.com" >> /root/.ssh/authorized_keys

    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvOC7JibKnGzTk5SanZTq9NoWwfURWVunh5bDkrQKuRQdlOXzUQ7KLeRr/CpPcyI9c6LYDufmDD1QdBy7vbxCfmAD81IqDewKhKYf3H5YcpylfdytAjLY/0cfMoNisufdiC9y8vF6nkEh/R26/STESmaIT3cjzcO8QqQP3zqS85ungh1gSxpTJwrYBMs3QbgE36lCfWALWHkzKHuEiObIpDC4fEZ4cEqOBN2NIpnWqioWjq0W1NApk+28hVmxrmZSqedTIcZgS/7Hghgmi95pc+lr/SrcVOadqw0JcAe8kP0+Il4r8Y/jkwvJBTkjILTeJQzudaM64D2ke7O26/TFn fge@Gris-Redhat" >> /root/.ssh/authorized_keys

    echo "# NM_CONTRIBUTORS_END" >> /root/.ssh/authorized_keys
}
