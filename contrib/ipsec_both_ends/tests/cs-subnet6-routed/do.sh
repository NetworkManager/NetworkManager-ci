#!/bin/sh

set -x

. /root/ipsec/tests/test-funcs.sh

h=$(hostname)
event="$1"

if [ "$event" = clean ]; then

    cleanup_connections

elif [ "$event" = post ]; then

    if [ "$h" = hosta.example.org ]; then
        nmcli connection add type dummy ifname dummy0 ip6 fd42::1/64
    elif [ "$h" = hostb.example.org ]; then
        nmcli connection add type dummy ifname dummy0 ip6 fd43::1/64
    fi

elif [ "$event" = check ]; then

    if [ "$h" = hosta.example.org ]; then
        ping_host fd43::1 fd42::1
        check_xfrm_esp dir out src fd42::/64 dst fd43::/64 if_id 9

        ip -6 route show dev ipsec9 | grep "fd43::/64 .*metric 50 " > /dev/null || exit 1
        
    elif [ "$h" = hostb.example.org ]; then
        ping_host fd42::1 fd43::1
        check_xfrm_esp dir out src fd43::/64 dst fd42::/64 if_id 9
    fi

fi

    
