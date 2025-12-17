#!/bin/sh

set -x

. /root/ipsec/tests/test-funcs.sh

h=$(hostname)
event="$1"

if [ "$event" = clean ]; then

    cleanup_connections

elif [ "$event" = post ]; then

    if [ "$h" = hosta.example.org ]; then
        nmcli connection add type dummy ifname dummy0 ip4 192.0.1.1/24
    elif [ "$h" = hostb.example.org ]; then
        nmcli connection add type dummy ifname dummy0 ip4 192.0.2.2/24
    fi

elif [ "$event" = check ]; then

    if [ "$h" = hosta.example.org ]; then
        ping_host 192.0.2.2 192.0.1.1
        check_xfrm_esp dir out src 192.0.1.0/24 dst 192.0.2.0/24
    elif [ "$h" = hostb.example.org ]; then
        ping_host 192.0.1.1 192.0.2.2
        check_xfrm_esp dir out src 192.0.2.0/24 dst 192.0.1.0/24
    fi

fi
