#!/bin/bash

# This file can be sourced by our other bash scripts.
# It defines some environment variables and helper functions.

if ! (return 0 2>/dev/null) ; then
    echo "This script must be sourced!"
    exit 1
fi

[ -n "$_NMCI_UTILS_SOURCED" ] && return
_NMCI_UTILS_SOURCED=1

###############################################################################

export NMCI_BASE_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../..")"
export NMCI_TMP_DIR="$NMCI_BASE_DIR/.tmp"
export PATH="$NMCI_TMP_DIR/bin:$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"

###############################################################################

die() {
    echo "FATAL: $@" >&2
    exit 1
}

array_contains() {
    local tag="$1"
    local a
    shift

    for a; do
        if [ "$tag" = "$a" ]; then
            return 0
        fi
    done
    return 1
}

nmci_tmp_dir_ensure() {
    mkdir -p "$NMCI_TMP_DIR/$1"
    echo "$NMCI_TMP_DIR/$1"
}

nmci_tmp_dir_has() {
    test -f "$NMCI_TMP_DIR/$1"
}

nmci_tmp_dir_touch() {
    touch "$(nmci_tmp_dir_ensure "$(dirname "$1")")/$(basename "$1")"
}

nmci_utils_override_python() {
    [ -n "$NMCI_TMP_DIR" ] || return 1

    rm -rf "$NMCI_TMP_DIR/bin/python"
    hash -d python 2>/dev/null

    if [ -n "$1" ]; then
        local p="$(command -v "$1")"
        mkdir -p "$NMCI_TMP_DIR/bin/"
        cat <<EOF > "$NMCI_TMP_DIR/bin/python"
#!/bin/bash
exec "$p" "\$@"
EOF
        chmod +x "$NMCI_TMP_DIR/bin/python"
    fi
}

distro_detect() {
    if [ -z "$_NMCI_UTILS_DISTRO_DETECT" ]; then
        local s
        local distro_flavor
        local distro_version

        distro_version="$(sed "s/.*release *//;s/ .*//;s/Beta//;s/Alpha//" /etc/redhat-release)"

        if [ -z "$distro_version" ]; then
            echo "failed to parse version from /etc/redhat-release" >&2
            return 1
        fi

        if grep -qi fedora /etc/redhat-release ; then
            distro_flavor='fedora'
        else
            distro_flavor='rhel'
            if [[ "$distro_version" != *.* ]]; then
                # CentOS stream only gives "CentOS Stream release 8". Hack a minor version
                # number
                distro_version="$distro_version.99"
            fi
        fi

        distro_version="${distro_version//./ }"

        s="$distro_flavor $distro_version"

        local reg='^(fedora|rhel)( [0-9]+)*$'
        if [[ "$s" =~ $reg ]]; then
            :
        else
            echo "unrecognized version \"$s\"" >&2
            return 1
        fi

        _NMCI_UTILS_DISTRO_DETECT="$distro_flavor $distro_version"
    fi

    echo "$_NMCI_UTILS_DISTRO_DETECT"
}
