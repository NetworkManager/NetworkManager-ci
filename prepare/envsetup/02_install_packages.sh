install_packages () {
    if ! test -f /tmp/nm_packages_installed; then

        # We need to check what distro we are on
        if grep -q 'Fedora' /etc/redhat-release; then
            release="fedora"
        elif grep -q -e 'release 10' /etc/redhat-release; then
            release="el10"
        elif grep -q -e 'release 9' /etc/redhat-release; then
            release="el9"
        elif grep -q -e 'release 8' /etc/redhat-release; then
            release="el8"
        elif grep -q -e 'release 7' /etc/redhat-release; then
            release="el7"
        fi

        # We need PIP if not installed
        # We need special dance around python in RHEL8
        if [ "$release" = "el8" ]; then
            python_rpm=$(rpm -qa |grep 'python3.[0-9]*-3' | awk -F '-' '{print $1}'|head -1)
            rm -f /usr/bin/python
            rm -f /usr/bin/python3
            ln -s /usr/bin/$python_rpm /usr/bin/python
            ln -s /usr/bin/$python_rpm /usr/bin/python3
            /usr/bin/python3 -m pip &> /dev/null || \
                yum -y install $python_rpm-pip
            yum -y install $python_rpm-devel
            # There will always be something like python3.1[1-9]
            # So we can remove older python from RHEL8
            yum -y remove python3[0-9]*
        else
            /usr/bin/python3 -m pip &> /dev/null || yum -y install python3-pip
        fi

        if ! [ -e /usr/bin/debuginfo-install ]; then
            yum -y install /usr/bin/debuginfo-install
        fi

        # We can install packages now
        # and give it possibly one more try
        install_"$release"_packages
        if ! check_packages; then
            sleep 20
            install_"$release"_packages
        fi

        touch /tmp/nm_packages_installed
    fi
}
