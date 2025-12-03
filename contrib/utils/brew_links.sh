#!/bin/bash

# brew_links.sh - Generate download URLs for RPM packages from Brew/Koji repositories
#
# This script generates direct download links for RPM packages from:
# - Brew (Red Hat internal build system) for RHEL 7-10
# - Kojihub (CentOS Stream) for CentOS 7-15
# - Koji (Fedora) as fallback or for Fedora releases
#
# The script can operate in several modes:
# 1. Automatic mode: Fetches latest packages matching specified criteria
# 2. Interactive mode (-i): Presents menus for selecting versions/builds
# 3. NVR mode (-n): Parses Name-Version-Release format
# 4. URL mode: Extracts RPM links from a given base URL
#
# Output: Full URLs to RPM files, one per line
# Usage: See help text below or run with -h/--help

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


# AWK script to parse HTML directory listings from Brew/Koji servers
# Extracts href links from table rows, starting after Parent Directory entry
# and stopping at "Locations hidden" marker (if present)
AWK_SCR="
BEGIN { p=0; }
/a href/ { if (p) print \$0; }
/Parent Directory/ { p=1; }
/\.\./ { p=1; }
/Locations hidden/ { p=0; }
"

# Properly escaped string for matching quotes in sed expressions: '"
QUOT="'"'"'

# get_all() - Fetch all entries from a Brew/Koji directory URL
# Args:
#   $1: URL to fetch
# Returns: List of filenames/directories, one per line
get_all() {
    curl -L --insecure --max-redirs 5 --connect-timeout 5 -s "$1" |sed 's/<tr>/\n/g' | awk "$AWK_SCR" | sed "s/.*a href=[$QUOT]\([^$QUOT]*\)[$QUOT].*/\1/;s@/*\$@@"
}

# get_latest() - Get the latest version from a directory listing
# Args:
#   $1: URL to fetch
# Returns: Most recent version/build using version sort
get_latest() {
    get_all $1 | sort -V | tail -n 1
}

# has_arch() - Check if a string contains an architecture identifier
# Args:
#   $1: String to check (typically a build identifier)
# Returns: 0 if architecture found, 1 otherwise
has_arch() {
    echo $1 | grep -q -F -e "x86_64" -e "aarch64" -e "ppc64le" -e "s390x" -e "noarch"
}

# ============================================================================
# Detect OS release version
# ============================================================================
# Use RH_RELEASE environment variable if set, otherwise detect from /etc/redhat-release
# RH_RELEASE can be in format "X.Y" (e.g., "9.5"), release will be just major version (e.g., "9")
if [ -z "$RH_RELEASE" ]; then
    RH_RELEASE="$(grep -o 'release [0-9.]*' /etc/redhat-release | sed 's/release //g')"
    release="$(grep -o 'release [0-9]*' /etc/redhat-release | sed 's/release //g')"
else
    release=$(echo "$RH_RELEASE" | grep -o "^[0-9]*")
fi

# ============================================================================
# Determine which package repository to use based on script name and OS version
# ============================================================================
# If script is named/symlinked with "brew" in the name, use Red Hat Brew
# Otherwise, use Koji/Kojihub for Fedora/CentOS
if [[ $0 == *"brew"* ]]; then

    if (($release >= 7 && $release <= 10)); then
        # Brew repositories for RHEL 7-10
        url_base="http://download.devel.redhat.com/brewroot/vol/rhel-$release/packages"
        url_base_build="http://download.devel.redhat.com/brewroot/packages"
	provider=brew
    else
        echo "Unsupported distro: $(cat /etc/redhat-release)"
        exit 1
    fi
else
    if (($release >= 7 && $release <= 15)); then
        # CentOS Stream Kojihub for CentOS 7-15
        url_base="https://kojihub.stream.centos.org/kojifiles/packages"
	provider=kojihub
    else
        # Fedora Koji for other releases
        url_base="https://kojipkgs.fedoraproject.org/packages"
	provider=koji
    fi
fi

# ============================================================================
# Handle interactive mode flag
# ============================================================================
interactive=false
if [ "$1" == "-i"  -o "$1" == "--interactive" ]; then
    interactive=true
    echo Interactive mode
    echo
    shift 1
fi

# ============================================================================
# Handle NVR (Name-Version-Release) mode
# ============================================================================
# Parse NVR format like "NetworkManager-1.32.0-1.el9" into components
# Also handles NVRA format if architecture is included (e.g., "...-1.el9.x86_64")
if [ "$1" == "-n"  -o "$1" == "--nvr" ]; then
    shift 1
    NVR=$1
    shift 1
    # Parse NVR: NetworkManager-1.32.0-1.el9 -> N=NetworkManager, V=1.32.0, R=1.el9
    R=${NVR##*-}           # Release: everything after last dash
    NV=${NVR%-*}           # Name-Version: everything before last dash
    V=${NV##*-}            # Version: everything after last dash in NV
    N=${NV%-*}             # Name: everything before last dash in NV
    # Check if release contains architecture (e.g., "1.el9.x86_64")
    if has_arch $R; then
        A=${R##*.}         # Architecture: everything after last dot
        R=${R%.*}          # Release without arch: everything before last dot
    fi
    # Set positional parameters for standard processing
    set $N $V $R $A
fi

# ============================================================================
# Handle direct URL mode
# ============================================================================
# If a full URL is provided, fetch and list all binary RPMs from that location
if [[ "$1" == "https://"* || "$1" == "http://"* ]]; then
    rpms=$(get_all $1 | grep -F .rpm | grep -v -F 'src.rpm')
    for rpm in $rpms; do
        echo $1/$rpm
    done
    exit 0
fi

# ============================================================================
# Main package resolution logic
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Determine package name (defaults to NetworkManager)
# ----------------------------------------------------------------------------
package=$1
[ -z "$package" ] && package=NetworkManager
$interactive && echo "Selected package: $package" && echo

# ----------------------------------------------------------------------------
# 2. Determine version
# ----------------------------------------------------------------------------
ver=$2
if [ -z "$ver" ]; then
    # No version specified - fetch available versions
    if $interactive; then
        # Interactive: present menu of versions
        choices=$(get_all $url_base/$package/ | sort -V -r)
        if [ -z "$choices" -a "$provider" == kojihub ]; then
            # Fallback from kojihub to koji if package not found
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
        # Automatic: get latest version
        ver=$(get_latest $url_base/$package/)
        # Fallback to koji if package not found
        if [ -z "$ver" ]; then
            url_base="https://kojipkgs.fedoraproject.org/packages"
            provider=koji
        fi
        ver=$(get_latest $url_base/$package/)
    fi
else
    # Version was specified - find matching version in repository
    # For brew, switch to url_base_build to access all builds (not just gated ones)
    echo "$url_base" | grep -q brew && url_base="$url_base_build"
    ver2=$(get_all $url_base/$package/ | grep -F "$ver" | sort -V | tail -n 1)
    if [ -z "$ver2" ]; then
       # Fallback to koji if version not found
       url_base="https://kojipkgs.fedoraproject.org/packages"
       provider=koji
       ver2=$(get_all $url_base/$package/ | grep -F "$ver" | sort -V | tail -n 1)
    fi
    ver="$ver2"
fi

# For brew URLs, always use url_base_build for access to all builds
echo "$url_base" | grep -q brew && url_base="$url_base_build"

# ----------------------------------------------------------------------------
# 3. Determine build
# ----------------------------------------------------------------------------
build=$3
if [ -z "$build" ]; then
    # No build specified - fetch available builds
    if $interactive; then
        # Interactive: present menu of builds
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
        # Automatic: find best matching build for current release
        if [ "$provider" == kojihub ]; then
            # Kojihub: match builds for current EL release
            build=$(get_all $url_base/$package/$ver/ | grep -F ".el$release" | sort -V | tail -n 1)
        elif [ "$provider" == brew ]; then
            # Brew: prefer z-stream builds (e.g., .el9_5 over .el9)
            all_builds=$(get_all $url_base/$package/$ver/ | grep -F ".el$release")
            # Convert RH_RELEASE=9.5 to .el9_5 format for z-stream matching
            rel=$(echo $RH_RELEASE | sed 's/[.]/_/')
            build=$(echo "$all_builds" | grep -F ".el$rel" | sort -V | tail -n 1)
            # If no z-stream match, use base release build (e.g., .el9)
            if [ -z "$build" ]; then
                build=$(echo "$all_builds" | grep "el$release$" | sort -V | tail -n 1)
            fi
	fi
        # Fallback to koji if no build found
        if [ -z "$build" ]; then
            url_base="https://kojipkgs.fedoraproject.org/packages"
            provider=koji
            # Try both Fedora (.fc) and EL (.el) builds
            build=$(get_all $url_base/$package/$ver/ | grep -F -e ".fc$release" -e ".el$release" | sort -V | tail -n 1)
        fi
        # If still no match, use latest available build regardless of release
        if [ -z "$build" ]; then
            build=$(get_all $url_base/$package/$ver/ | sort -V | tail -n 1)
        fi
    fi
else
    # Build was specified - find matching build
    build=$(get_all $url_base/$package/$ver | grep -F "$build" | sort -V | tail -n 1)
fi

# ----------------------------------------------------------------------------
# 4. Determine architecture
# ----------------------------------------------------------------------------
arch=$4
if [ -z "$arch" ]; then
    # No architecture specified
    if $interactive; then
        # Interactive: present menu of architectures with "auto" option
        choices=$(get_all $url_base/$package/$ver/$build/)
        choices=$(echo -e "auto\n$choices")
        echo "$choices" | nl -s": "
        echo
        read -p "Enter number [1..$(echo "$choices" | wc -l)]: " v
        arch=$(echo "$choices" | head -n $v | tail -n 1)
        [ "$arch" == "auto" ] && arch=$(arch)
    else
        # Automatic: use current system architecture
        arch=$(arch)
    fi
fi

# ============================================================================
# Fetch and print RPM download URLs
# ============================================================================
rpms=$(get_all $url_base/$package/$ver/$build/$arch/)

# Final fallback from kojihub to koji if no RPMs found
if [ -z "$rpms" -a "$provider" == kojihub ]; then
    url_base="https://kojipkgs.fedoraproject.org/packages"
	provider=koji
	rpms=$(get_all $url_base/$package/$ver/$build/$arch/)
fi

# Output full URLs for each RPM file
for rpm in $rpms; do
    echo $url_base/$package/$ver/$build/$arch/$rpm
done
