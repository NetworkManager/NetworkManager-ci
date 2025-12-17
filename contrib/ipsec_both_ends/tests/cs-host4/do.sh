#!/bin/sh

set -x

. /root/ipsec/tests/test-funcs.sh

h=$(hostname)
event="$1"

if [ "$event" = clean ]; then

    cleanup_connections

elif [ "$event" = post ]; then

    :

elif [ "$event" = check ]; then

    if [ "$h" = hosta.example.org ]; then
        ping_host 172.16.2.20
        check_xfrm_esp dir out src 172.16.1.10/32 dst 172.16.2.20/32
    elif [ "$h" = hostb.example.org ]; then
        ping_host 172.16.1.10
        check_xfrm_esp dir out src 172.16.2.20/32 dst 172.16.1.10/32
    fi

fi

