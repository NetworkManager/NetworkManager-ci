#!/bin/bash

if [ "$1" == "-h"  -o "$1" == "--help" ]; then
    cat << EOF

USAGE: $0 [PACKAGE [VERSION [BUILD [ARCH]]]     print links of RPM packages
       $0 -h / --help                           print this help

Examples:

* upgrade, specify all arguments, do not install debuginfo and devel RPMs
    dnf upgrade \$($0 NetworkManager 1.32.0 1.el8 x86_64| grep -v debuginfo | grep -v devel)
* downgrade, use some defaults: PACKAGE defaults to "Networkmanager", for VERSION and BUILD
  latest is retrieved, default ARCH is currently running (now: $(arch))
    dnf downgrade \$($0 "" 1.30.0)
* upgrade to the latest NetworkManager package: use all defaults
    dnf upgrade \$($0)

EOF
    exit
fi


AWK_SCR="
BEGIN { p=0; }
/a href/ { if (p) print \$0; }
/Parent Directory/ { p=1; }
/Locations hidden/ { p=0; }
"

get_all() {
    curl -s "$1" | awk "$AWK_SCR" | sed 's/.*a href="\([^"]*\)".*/\1/'
}

get_latest() {
    get_all $1 | sort -V | tail -n 1
}

if [[ $0 == *"brew"* ]]; then

    if grep -q 'release 7' /etc/redhat-release; then
        url_base="http://download.eng.bos.redhat.com/brewroot/vol/rhel-7/packages"
    elif grep -q 'release 8' /etc/redhat-release; then
        url_base="http://download.eng.bos.redhat.com/brewroot/vol/rhel-8/packages"
    elif grep -q 'release 9' /etc/redhat-release; then
        url_base="http://download.eng.bos.redhat.com/brewroot/vol/rhel-9/packages"
    else
        echo "Unsupported distro: $(cat /etc/redhat-release)"
        exit 1
    fi
else
    url_base="https://kojipkgs.fedoraproject.org/packages"
fi


package=$1
[ -z "$package" ] && package=NetworkManager
ver=$2
[ -z "$ver" ] && ver=$(get_latest $url_base/$package/)
build=$3
[ -z "$build" ] && build=$(get_latest $url_base/$package/$ver/)
arch=$4
[ -z "$arch" ] && arch=$(arch)

rpms=$(get_all $url_base/$package/$ver/$build/$arch/)

for rpm in $rpms; do
    echo $url_base/$package/$ver/$build/$arch/$rpm
done
