install_packages () {
    if ! test -f /tmp/nm_packages_installed; then
        /usr/bin/python3 -V || yum -y install python3
        /usr/bin/python3 -m pip &> /dev/null || yum -y install python3-pip
        if ! [ -e /usr/bin/debuginfo-install ]; then
            yum -y install /usr/bin/debuginfo-install
        fi

        need_abrt="no"
        # We need to check what distro we are on
        # and if we need abrt
        if grep -q 'Fedora' /etc/redhat-release; then
            release="fedora"
        elif grep -q -e 'release 8' /etc/redhat-release; then
            release="el8"
            need_abrt="yes"
        elif grep -q -e 'release 9' /etc/redhat-release; then
            release="el9"
            need_abrt="yes"
        elif grep -q -e 'release 7' /etc/redhat-release; then
            release="el7"
        fi

        # We can install packages now
        # and give it possibly one more try
        install_"$release"_packages
        if ! check_packages; then
            sleep 20
            install_"$release"_packages
        fi

        if [ $need_abrt == "yes" ]; then
            enable_abrt
        fi
        touch /tmp/nm_packages_installed
    fi
}
