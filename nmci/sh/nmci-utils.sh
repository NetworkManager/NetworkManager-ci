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
