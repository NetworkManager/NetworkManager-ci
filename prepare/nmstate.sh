#! /bin/bash

if test -f /tmp/nmstate_setup.txt; then
    exit 0
else
    yum -y install python3-devel rpm-build python3-openvswitch2.13
    yum -y install python3-devel rpm-build python3-openvswitch

    rm -rf /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

    # remove nmstate bits
    rm -rf nmstate

    git clone https://github.com/nmstate/nmstate
    cd nmstate
    # We have some regressions now so let's use 0.3's HEAD
    git checkout nmstate-0.3
    # git checkout $(git tag |tail -1)
    LC_TIME=en_US-UTF-8 sh packaging/make_rpm.sh; rc=$?
    if test $rc -eq 0; then
        rm -rf nmstate-*.src.rpm
        yum remove -y nmstate python3-libnmstate
        yum -y localinstall python3-libnmstate* nmstate-*; RC=$?
        python -m pip install pytest
        if test $RC -eq 0; then
            touch /tmp/nmstate_setup.txt
        fi
    else
        printf "\n\n* COMPILATION FAILED!\n\n"
    fi
    exit $RC
fi
