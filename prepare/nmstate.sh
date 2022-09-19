#! /bin/bash

if test -f /tmp/nmstate_setup.txt; then
    exit 0
else
    # Enable the newest nispor repo
    dnf copr -y enable nmstate/nispor
    dnf copr -y enable nmstate/nmstate-git

    rm -rf nmstate
    git clone https://github.com/nmstate/nmstate

    dnf remove -y nmstate python3-libnmstate
    dnf install -y nispor nmstate python3-libnmstate; RC=$?
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
