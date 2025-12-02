#!/bin/bash

if [ "$1" == "-h"  -o "$1" == "--help" ]; then
    cat << EOF

USAGE: $0 [PACKAGE [VERSION [BUILD [ARCH]]]     print links of RPM packages
       $0 {base url}                            print links of RPM packages from given url
       $0 -n NVR / --nvr NVR                    print links for given NVR
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
/\.\./ { p=1; }
/Locations hidden/ { p=0; }
"

# properly escaped string: '"
QUOT="'"'"'

get_all() {
    curl -L --insecure --max-redirs 5 --connect-timeout 5 -s "$1" |sed 's/<tr>/\n/g' | awk "$AWK_SCR" | sed "s/.*a href=[$QUOT]\([^$QUOT]*\)[$QUOT].*/\1/;s@/*\$@@"
}

get_latest() {
    get_all $1 | sort -V | tail -n 1
}

has_arch() {
    echo $1 | grep -q -F -e "x86_64" -e "aarch64" -e "ppc64le" -e "s390x" -e "noarch"
}

if [ -z "$RH_RELEASE" ]; then
    RH_RELEASE="$(grep -o 'release [0-9.]*' /etc/redhat-release | sed 's/release //g')"
    release="$(grep -o 'release [0-9]*' /etc/redhat-release | sed 's/release //g')"
else
    release=$(echo "$RH_RELEASE" | grep -o "^[0-9]*")
fi

if [[ $0 == *"brew"* ]]; then

    if (($release >= 7 && $release <= 10)); then
        url_base="http://download.devel.redhat.com/brewroot/vol/rhel-$release/packages"
        url_base_build="http://download.devel.redhat.com/brewroot/packages"
	provider=brew
    else
        echo "Unsupported distro: $(cat /etc/redhat-release)"
        exit 1
    fi
else
    if (($release >= 7 && $release <= 15)); then
        url_base="https://kojihub.stream.centos.org/kojifiles/packages"
	provider=kojihub
    else
        url_base="https://kojipkgs.fedoraproject.org/packages"
	provider=koji
    fi
fi

interactive=false
if [ "$1" == "-i"  -o "$1" == "--interactive" ]; then
    interactive=true
    echo Interactive mode
    echo
    shift 1
fi

if [ "$1" == "-n"  -o "$1" == "--nvr" ]; then
    shift 1
    NVR=$1
    shift 1
    R=${NVR##*-}
    NV=${NVR%-*}
    V=${NV##*-}
    N=${NV%-*}
    if has_arch $R; then
        A=${R##*.}
        R=${R%.*}
    fi
    set $N $V $R $A
fi

if [[ "$1" == "https://"* || "$1" == "http://"* ]]; then
    rpms=$(get_all $1 | grep -F .rpm | grep -v -F 'src.rpm')
    for rpm in $rpms; do
        echo $1/$rpm
    done
    exit 0
fi

package=$1
[ -z "$package" ] && package=NetworkManager
$interactive && echo "Selected package: $package" && echo
ver=$2
if [ -z "$ver" ]; then
    if $interactive; then
        choices=$(get_all $url_base/$package/ | sort -V -r)
        if [ -z "$choices" -a "$provider" == kojihub ]; then
            echo "Package not found in kojihub, trying koji."
            url_base="https://kojipkgs.fedoraproject.org/packages"
	    provider=koji
            choices=$(get_all $url_base/$package/ | sort -V -r)
        fi
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
        # try koji, when no version for package found
        if [ -z "$ver" ]; then
            url_base="https://kojipkgs.fedoraproject.org/packages"
            provider=koji
        fi
        ver=$(get_latest $url_base/$package/)
    fi
else
    # Switch brew link to all builds regardless rhel version (non-gated builds are not there yet)
    echo "$url_base" | grep -q brew && url_base="$url_base_build"
    ver2=$(get_all $url_base/$package/ | grep -F "$ver" | sort -V | tail -n 1)
    if [ -z "$ver2" ]; then
       url_base="https://kojipkgs.fedoraproject.org/packages"
       provider=koji
       ver2=$(get_all $url_base/$package/ | grep -F "$ver" | sort -V | tail -n 1)
    fi
    ver="$ver2"
fi

# Switch brew link to all builds regardless rhel version (non-gated builds are not there yet)
echo "$url_base" | grep -q brew && url_base="$url_base_build"

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
        if [ "$provider" == kojihub ]; then
            build=$(get_all $url_base/$package/$ver/ | grep -F ".el$release" | sort -V | tail -n 1)
        elif [ "$provider" == brew ]; then
            # match z-streams
            all_builds=$(get_all $url_base/$package/$ver/ | grep -F ".el$release")
            # convert RH_RELEASE=X.Y to .elX_Y
            rel=$(echo $RH_RELEASE | sed 's/[.]/_/')
            build=$(echo "$all_builds" | grep -F ".el$rel" | sort -V | tail -n 1)
            # if we have no matchin z-stream, match only non-z-stream builds
            if [ -z "$build" ]; then
                build=$(echo "$all_builds" | grep "el$release$" | sort -V | tail -n 1)
            fi
	fi
        # If build is empty so far, try koji with matching release
        if [ -z "$build" ]; then
            url_base="https://kojipkgs.fedoraproject.org/packages"
            provider=koji
            build=$(get_all $url_base/$package/$ver/ | grep -F -e ".fc$release" -e ".el$release" | sort -V | tail -n 1)
        fi
        # If no build matched release, provide latest
        if [ -z "$build" ]; then
            build=$(get_all $url_base/$package/$ver/ | sort -V | tail -n 1)
        fi
    fi
else
    build=$(get_all $url_base/$package/$ver | grep -F "$build" | sort -V | tail -n 1)
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

# fallback from kojihub to koji in non-intractive mode
if [ -z "$rpms" -a "$provider" == kojihub ]; then
    url_base="https://kojipkgs.fedoraproject.org/packages"
	provider=koji
	rpms=$(get_all $url_base/$package/$ver/$build/$arch/)
fi

for rpm in $rpms; do
    echo $url_base/$package/$ver/$build/$arch/$rpm
done
