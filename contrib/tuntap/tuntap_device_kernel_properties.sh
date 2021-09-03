#!/bin/bash
#
# gathers tuntap device properties from kernel, dbus and nmcli an compares them
# USAGE: tmp/tuntap_device_kernel_properties.sh {device} {property} [expected value]
# supported properties:
#   owner:       numeric id of tuntap device owner, -1 if undefined
#   gourp:       numeric id of tuntap device group, -1 if undefined
#   mode:        tun or tap
#   nopi:        true or false
#   multi-queue: true or false
#   vnet-hder:   true or false
#
###############################################################################

FLAG_NOPI=0x1000
FLAG_MULTIQUEUE=0x100
FLAG_VNETHDR=0x4000

# test binary flag and convert it to boolean
apply_flag() {
    n1=$1
    n2=$2
    r=$((n1 & n2))
    if [ "x$r" == "x0" ]; then
        echo "false"
    else
        echo "true"
    fi
}

# get response from nm and unify results
parse_nm_line() {
    arg=$(echo "$@" | awk '{print $2}')
    if [ "x$arg" == "x--" ]; then
        arg=-1
    elif [ "x$arg" == "xno" ]; then
        arg=false
    elif [ "x$arg" == "xyes" ]; then
        arg=true
    fi
    echo $arg
}

negate() {
    if [ "x$1" == "xtrue" ]; then
        echo false
    else
        echo true
    fi
}

# send dbus query and unify result (ignore type - first column and delete quotes)
query_dbus() {
    busctl get-property org.freedesktop.NetworkManager "$DBUS_PATH" org.freedesktop.NetworkManager.Device.Tun $1 | awk '{print $2}' | sed 's/"//g' 
}

# read property from sysfs
get_sysfs() {
    if [ "x$prop" == "xowner" ]; then
        cat "${SYS_PATH}${prop}"
    elif [ "x$prop" == "xgroup" ]; then
        cat "${SYS_PATH}${prop}"
    elif [ "x$prop" == "xmode" ]; then
        t=$(cat "${SYS_PATH}type")
        if [ "x$t" == "x1" ]; then
            echo "tap"
        elif [ "x$t" == "x65534" ]; then
            echo "tun"
        else
            echo "error"
        fi
    elif [ "x$prop" == "xnopi" ]; then
        flags=$(cat "${SYS_PATH}tun_flags")
        apply_flag $flags $FLAG_NOPI
    elif [ "x$prop" == "xmulti-queue" ]; then
        flags=$(cat "${SYS_PATH}tun_flags")
        apply_flag $flags $FLAG_MULTIQUEUE
    elif [ "x$prop" == "xvnet-hdr" ]; then
        flags=$(cat "${SYS_PATH}tun_flags")
        apply_flag $flags $FLAG_VNETHDR
    fi
}

# read property from nmcli
get_nmcli() {
    if [ "x$prop" == "xowner" ]; then
        parse_nm_line $(nmcli -f tun.$prop con show $dev)
    elif [ "x$prop" == "xgroup" ]; then
        parse_nm_line $(nmcli -f tun.$prop con show $dev)
    elif [ "x$prop" == "xmode" ]; then
        t=$(parse_nm_line $(nmcli -f tun.$prop con show $dev))
        if [ "x$t" == "x2" ]; then
            echo "tap"
        elif [ "x$t" == "x1" ]; then
            echo "tun"
        else
            echo "error"
        fi
    elif [ "x$prop" == "xnopi" ]; then
        # nmcli has pi instead of nopi
        negate $(parse_nm_line $(nmcli -f tun.pi con show $dev))
    elif [ "x$prop" == "xmulti-queue" ]; then
        parse_nm_line $(nmcli -f tun.$prop con show $dev)
    elif [ "x$prop" == "xvnet-hdr" ]; then
        parse_nm_line $(nmcli -f tun.$prop con show $dev)
    fi
}

# read property from nmcli dbus
get_dbus() {
    if [ "x$prop" == "xowner" ]; then
        query_dbus Owner
    elif [ "x$prop" == "xgroup" ]; then
        query_dbus Group
    elif [ "x$prop" == "xmode" ]; then
        query_dbus Mode
    elif [ "x$prop" == "xnopi" ]; then
        query_dbus NoPi
    elif [ "x$prop" == "xmulti-queue" ]; then
        query_dbus MultiQueue
    elif [ "x$prop" == "xvnet-hdr" ]; then
        query_dbus VnetHdr
    fi
}


###################################################################

# set arguments
dev=$1
prop=$2
exp=$3

# set paths
DBUS_PATH="$(nmcli -f DEVICE,DBUS-PATH -t device | sed -n "s/^$dev://p")";
SYS_PATH=/sys/devices/virtual/net/$dev/

# get values
sys=$(get_sysfs)
nmcli=$(get_nmcli)
dbus=$(get_dbus)

# if no expected result provided, set it to $sys
if [ -z "$exp" ]; then
    exp=$sys
fi

# all equal
if [ "x$sys" != "x$nmcli" ] || [ "x$sys" != "x$dbus" ]; then
    >&2 echo "ERROR: not equal values"
    echo "sys: $sys nmcli: $nmcli dbus: $dbus expected: $exp"
    exit 1
# all empty means bad property specified
elif [ -z "$sys" ]; then
    >&2 echo "ERROR: empty response of all (wron property?)"
    exit 1
# compare to expected result, comparing $sys to $sys if no expectated result provided
elif [ "x$sys" != "x$exp" ]; then
    >&2 echo "ERROR: not expected value"
    echo "sys=nmcli=dbus: $sys expected: $exp"
    exit 1
else 
    echo OK
    exit 0
fi
