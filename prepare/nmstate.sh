#! /bin/bash

if test -f /tmp/nmstate_setup.txt; then
    exit 0
else
    # Enable the newest nispor repo
    dnf copr -y enable nmstate/nispor
    dnf copr -y enable nmstate/nmstate-git


    dnf remove -y \
            nmstate python3-libnmstate nmstate-libs nmstate-plugin-ovsdb
    if grep -q 'release 8' /etc/redhat-release; then
        dnf install -y \
            nispor nmstate-1* nmstate-libs-1* \
            python3-libnmstate nmstate-plugin-ovsdb
    elif grep -q 'release 9' /etc/redhat-release; then
        dnf install -y \
            nispor nmstate-2* nmstate-libs-2*
            python3-libnmstate
    fi

    rpm -q nmstate; RC=$?

    rm -rf nmstate
    git clone https://github.com/nmstate/nmstate
    pushd nmstate
        git checkout v$(rpm -q --queryformat '%{VERSION}' nmstate)
    popd

    if test $RC -eq 0; then
        touch /tmp/nmstate_setup.txt
    else
        printf "\n\n* INSTALLATION FAILED!\n\n"
    fi

    # Turn of the nispor repo again
    dnf copr -y disable nmstate/nispor
    dnf copr -y disable nmstate/nmstate-git
    exit $RC
fi
