#!/bin/bash
getcmdline() {
    while read -r _line || [ -n "$_line" ]; do
        printf "%s" "$_line"
    done </proc/cmdline;
}

_dogetarg() {
    local _o _val _doecho
    unset _val
    unset _o
    unset _doecho
    CMDLINE=$(getcmdline)

    for _o in $CMDLINE; do
        if [ "${_o%%=*}" = "${1%%=*}" ]; then
            if [ -n "${1#*=}" -a "${1#*=*}" != "${1}" ]; then
                # if $1 has a "=<value>", we want the exact match
                if [ "$_o" = "$1" ]; then
                    _val="1";
                    unset _doecho
                fi
                continue
            fi

            if [ "${_o#*=}" = "$_o" ]; then
                # if cmdline argument has no "=<value>", we assume "=1"
                _val="1";
                unset _doecho
                continue
            fi

            _val="${_o#*=}"
            _doecho=1
        fi
    done
    if [ -n "$_val" ]; then
        [ "x$_doecho" != "x" ] && echo "$_val";
        return 0;
    fi
    return 1;
}

getarg() {
    local _deprecated _newoption
    while [ $# -gt 0 ]; do
        case $1 in
            -d) _deprecated=1; shift;;
            -y) if _dogetarg $2 >/dev/null; then
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$2' is deprecated, use '$_newoption' instead." || warn "Option '$2' is deprecated."
                    fi
                    echo 1
                    return 0
                fi
                _deprecated=0
                shift 2;;
            -n) if _dogetarg $2 >/dev/null; then
                    echo 0;
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$2' is deprecated, use '$_newoption=0' instead." || warn "Option '$2' is deprecated."
                    fi
                    return 1
                fi
                _deprecated=0
                shift 2;;
            *)  if [ -z "$_newoption" ]; then
                    _newoption="$1"
                fi
                if _dogetarg $1; then
                    if [ "$_deprecated" = "1" ]; then
                        [ -n "$_newoption" ] && warn "Kernel command line option '$1' is deprecated, use '$_newoption' instead." || warn "Option '$1' is deprecated."
                    fi
                    return 0;
                fi
                _deprecated=0
                shift;;
        esac
    done
    return 1
}

getargbool() {
    local _b
    unset _b
    local _default
    _default="$1"; shift
    _b=$(getarg "$@")
    [ $? -ne 0 -a -z "$_b" ] && _b="$_default"
    if [ -n "$_b" ]; then
        [ $_b = "0" ] && return 1
        [ $_b = "no" ] && return 1
        [ $_b = "off" ] && return 1
    fi
    return 0
}
export PATH=/sbin:/bin:/usr/sbin:/usr/bin
exec >/dev/console 2>&1
export TERM=linux
export PS1='initramfs-test:\w\$ '
CMDLINE=$(while read line || [ -n "$line" ]; do echo $line;done < /proc/cmdline)
strstr() { [ "${1##*"$2"*}" != "$1" ]; }

stty sane
if getargbool 0 rd.shell; then
    [ -c /dev/watchdog ] && printf 'V' > /dev/watchdog
	strstr "$(setsid --help)" "control" && CTTY="-c"
	setsid $CTTY sh -i
fi

visible() {
    patt=$1
    command=$2
    rm /tmp/stdout
    check_run "$command | tee /tmp/stdout | grep -q -e $patt"
    echo " * '$patt' is visible with command '$command' ... passed"
}

not_visible() {
    patt=$1
    command=$2
    rm /tmp/stdout
    check_run "$command | tee /tmp/stdout | grep -v -q -e $patt"
    echo " * '$patt' is not visible with command '$command' ... passed"
}

die() {
    msg=$1
    echo -e "FAIL: $msg" | dd oflag=direct,dsync of=/dev/sda
    poweroff -f
}

check_run() {
    eval $@
    rc=$?
    [[ "$rc" == 0 ]] || die "'$@' exited with code $rc and output:\n$(cat /tmp/stdout)"
}

gateway() {
    grep -q -v 'ip=' /proc/cmdline && return 0
    grep -q -e 'ip=auto' -e 'ip=dhcp' /proc/cmdline && return 0
    grep -q -e 'ip=[0-9.:]*192\.168\.5.\.1[^0]' /proc/cmdline && return 0
    return 1
}

manual_if_num() {
    grep -o 'ip=192\.168\.' /proc/cmdline | wc -l
}

echo "made it to the rootfs! Doing checks..."

echo "== nfs mounts =="
mount | grep nfs
echo "== ext3 mounts =="
mount | grep ext3

echo "== ls ifcfg =="
ls -la /etc/sysconfig/network-scripts/

for file in $(find /etc/sysconfig/network-scripts/ -type f); do
    echo "== $file =="
    cat $file
done

for file in $(find /run/NetworkManager/ -type f); do
    echo "== $file =="
    cat $file
done

echo "== starting services =="
echo "dbus"
check_run systemctl start dbus
echo > /dev/watchdog
echo "NetworkManager"
check_run systemctl start NetworkManager
echo > /dev/watchdog
echo "systemd-hostnamed"
check_run systemctl start systemd-hostnamed.service
echo > /dev/watchdog
echo "OK"

for file in $(find /etc/sysconfig/network-scripts/ -type f); do
    echo "== $file =="
    cat $file
done

for file in $(find /run/NetworkManager/ -type f); do
    echo "== $file =="
    cat $file
done

echo "== NetworkManager config =="
NetworkManager --print-config
echo > /dev/watchdog

# ifname detect
ifname=ens2
if grep -wq "net.ifnames=0" /proc/cmdline ; then
    ifname=eth0
fi

if grep -wq "bridge" /proc/cmdline ; then
    ifname=br0
fi

if grep -q "bridge=" /proc/cmdline ; then
    ifname=$(grep -o 'bridge=[^: ]*' /proc/cmdline)
    ifname=${ifname#bridge=}
fi

echo "== interface with IP address =="
echo "$ifname"

echo "== ip addr =="
ip addr
echo "== ip -4 route =="
ip -4 route
echo "== ip -6 route =="
ip -6 route

echo "== ip command checks =="
if ! grep -q -e "ip=auto6" -e "ip=dhcp6" /proc/cmdline; then
    visible "\"inet 192.168.5..\"" "ip addr show $ifname"
    not_visible "\"inet6 deaf:beef::1:\"" "ip addr show $ifname"
else
    visible "\"inet6 deaf:beef::1:\"" "ip addr show $ifname"
    not_visible "\"inet 192.168.5..\"" "ip addr show $ifname"
fi
echo "OK"
echo > /dev/watchdog

if ! grep -q -e "ip=auto6" -e "ip=dhcp6" /proc/cmdline; then
    # rhbz1710935
    echo "== IPv4 route duplicity check @rhbz1710935 =="
    if gateway; then
        visible "^1\$" "ip -4 r show dev $ifname | grep ^default | wc -l"
    fi
    visible "^1\$" "ip -4 r show dev $ifname | grep '^192\.168\.5.\.' | wc -l"
else
    echo "== IPv6 RA route check =="
    visible "\"^deaf:beef::/64 proto ra\"" "ip -6 r show dev $ifname"
fi
echo "OK"
echo > /dev/watchdog


echo "== nmcli device =="
nmcli device | cat
echo "== nmcli connection =="
nmcli con | cat

echo "== nmcli checks =="
visible "100" "nmcli -t -f GENERAL.STATE dev show $ifname"
if grep -q bridge /proc/cmdline; then
    visible "^2\$" "nmcli -t -f uuid con show | wc -l"
elif [ $(manual_if_num) != 0 ]; then
    visible "^$(manual_if_num)\$" "nmcli -t -f uuid con show | wc -l"
else
    visible "^1\$" "nmcli -t -f uuid con show | wc -l"
fi
echo "OK"
echo > /dev/watchdog

# rhbz1627820
echo "== lease renewal check @rhbz1627820 =="
if ip a | grep -q 52:54:00:12:34:08; then
    lease_time="$(ip -4 a show $ifname | grep valid_lft | awk '{print $2}' | grep -o '[0-9]*')"
    [ -n "$lease_time" ] || die "lease time for $ifname not found: $lease_time"
    (( $lease_time <= 120 )) || die "lease time is more than 120s: $lease_time"
    last_lease=$lease_time
    count=0
    while (( lease_time <= last_lease )); do
        sleep 1
        if (( cout++ > 120 )); then
            die "lease not renewed: $(ip -a a show $ifname)"
        fi
        last_lease=$lease_time
        lease_time="$(ip -4 a show $ifname | grep valid_lft | awk '{print $2}' | grep -o '[0-9]*')"
        echo > /dev/watchdog
    done
    echo "lease time change: $last_lease -> $lease_time"
    visible "\"inet 192.168.50.\"" "ip addr show $ifname"
    echo "OK"
else
    echo "SKIP"
fi
echo > /dev/watchdog

echo "== dump mount params =="
while read dev fs fstype opts rest || [ -n "$dev" ]; do
    if [ "$fstype" == "nfs" -o "$fstype" == "nfs4" ] ; then
        echo "nfs-OK $dev $fstype $opts" | dd oflag=direct,dsync of=/dev/sda
    elif [ "$fstype" == "ext3" ]; then
        echo "iscsi-OK $dev $fstype $opts" | dd oflag=direct,dsync of=/dev/sda
    else
        continue
    fi
    break
done < /proc/mounts
echo "OK"

echo > /dev/watchdog
poweroff -f
