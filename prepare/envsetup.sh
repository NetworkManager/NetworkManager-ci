#!/bin/bash

set +x
D=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
for f in $D/envsetup/*.sh; do source $f; done
set -x

configure_environment () {
    # Configure real basics and install packages
    if ! get_online_state; then
        set +x
        echo "***************************************************"
        echo "SETUP ERROR:"
        echo "We do not have network available via nmcli command."
        echo "Please do up (or create) at least one IPv4 profile"
        echo "with connection to internet (and up it)."
        echo "***************************************************"
        exit 1
    fi
    configure_basic_system
    install_packages
    [ "$1" == "first_test_setup" ] && return

    # Configure hw specific needs (veth, wifi, etc)
    configure_networking $1
    case "$1" in
        *dcb_*)
            configure_nm_dcb
            ;;
        *inf_*)
            configure_nm_inf
            ;;
        *gsm*)
            configure_nm_gsm
            ;;
    esac
}

if [ "$1" == "setup" ]; then
    if [ -n "$2" ]; then
        configure_environment "$2"
    fi
fi
