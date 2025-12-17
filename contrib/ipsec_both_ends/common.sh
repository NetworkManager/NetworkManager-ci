scriptdir="$(dirname "$(readlink -f "$0")")"

# Use default values if not set by calling script
: ${distro:=centos:stream10}
: ${rpm_dir:="/tmp/"}

c1=ipsec-host1
c2=ipsec-host2
cr=ipsec-router
