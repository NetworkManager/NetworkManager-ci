#!/bin/bash

if [ "$1" == "-h"  -o "$1" == "--help" ]; then
    cat << EOF

USAGE: $0 [PACKAGE [VERSION [BUILD [ARCH]]]     print links of RPM packages
       $0 -i / --interactive                    enter interactive mode
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
    curl -s "$1" | awk "$AWK_SCR" | sed 's/.*a href="\([^"]*\)".*/\1/;s@/*$@@'
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
    elif grep -q 'release 10' /etc/redhat-release; then
        url_base="http://download.eng.bos.redhat.com/brewroot/vol/rhel-10/packages"
    else
        echo "Unsupported distro: $(cat /etc/redhat-release)"
        exit 1
    fi
else
    url_base="https://kojipkgs.fedoraproject.org/packages"
fi

interactive=false
if [ "$1" == "-i"  -o "$1" == "--interactive" ]; then
    interactive=true
    echo Interactive mode
    echo
    shift 1
fi

package=$1
[ -z "$package" ] && package=NetworkManager
$interactive && echo "Selected package: $package" && echo
ver=$2
if [ -z "$ver" ]; then
    if $interactive; then
        choices=$(get_all $url_base/$package/ | sort -V -r)
        echo "$choices" | nl -s": "
        echo
        lines=$(echo "$choices" | wc -l)
        if [ $lines == 1 ]; then
            echo "Selected version: $choices"
            ver="$choices"
            echo
        else
            read -p "Enter number [1..$lines]: " v
            ver=$(echo "$choices" | head -n $v | tail -n 1)
        fi
    else
        ver=$(get_latest $url_base/$package/)
    fi
fi
build=$3
if [ -z "$build" ]; then
    if $interactive; then
        choices=$(get_all $url_base/$package/$ver/ | sort -V -r)
        echo "$choices" | nl -s": "
        echo
        lines=$(echo "$choices" | wc -l)
        if [ $lines == 1 ]; then
            echo "Selected build: $choices"
            build="$choices"
            echo
        else
            read -p "Enter number [1..$lines]: " v
            build=$(echo "$choices" | head -n $v | tail -n 1)
        fi
    else
        build=$(get_latest $url_base/$package/$ver/)
    fi
fi
arch=$4
if [ -z "$arch" ]; then
    if $interactive; then
        choices=$(get_all $url_base/$package/$ver/$build/)
        choices=$(echo -e "auto\n$choices")
        echo "$choices" | nl -s": "
        echo
        read -p "Enter number [1..$(echo "$choices" | wc -l)]: " v
        arch=$(echo "$choices" | head -n $v | tail -n 1)
        [ "$arch" == "auto" ] && arch=$(arch)
    else
        arch=$(arch)
    fi
fi

rpms=$(get_all $url_base/$package/$ver/$build/$arch/)

for rpm in $rpms; do
    echo $url_base/$package/$ver/$build/$arch/$rpm
done
