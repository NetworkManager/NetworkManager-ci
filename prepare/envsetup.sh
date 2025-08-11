#!/bin/bash

set +x
D=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
for f in $D/envsetup/*.sh; do source $f; done
set -x

configure_environment () {
    # Configure real basics and install packages
    if [ "$1" != "image_mode_setup" ] && ! get_online_state; then
        set +x
        echo "***************************************************"
        echo "SETUP ERROR:"
        echo "We do not have network available via nmcli command."
        echo "Please do up (or create) at least one IPv4 profile"
        echo "with connection to internet (and up it)."
        echo "***************************************************"
        exit 1
    fi

    [ "$1" == "nm-applet" ] && touch /tmp/keep_old_behave
    configure_basic_system
    install_packages
    [ "$1" == "first_test_setup" ] && return
    [ "$1" == "image_mode_setup" ] && return

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
            if [[ "$1" != *"gsm_sim"* ]]; then
                configure_nm_gsm
            fi
            ;;
    esac
}

if [ "$1" == "setup" ]; then
    if [ -n "$2" ]; then
        configure_environment "$2"
    fi
fi
