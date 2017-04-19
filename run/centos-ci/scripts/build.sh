#!/bin/bash

BUILD_DIR="${BUILD_DIR:-/root/nm-build}"
BUILD_ID="$1"
BUILD_REPO="${BUILD_REPO-https://github.com/NetworkManager/NetworkManager.git}"
ARCH="${ARCH:-`arch`}"
WITH_DEBUG="${WITH_DEBUG:no}"

if [ -z "$SUDO" ]; then
    unset SUDO
fi

$SUDO yum install \
    git \
    rpm-build \
    intltool \
    valgrind \
    dbus-devel \
    dbus-glib-devel \
    wireless-tools-devel \
    glib2-devel \
    gobject-introspection-devel \
    gettext-devel \
    pkgconfig \
    libnl3-devel \
    'perl(XML::Parser)' \
    'perl(YAML)' \
    automake \
    ppp-devel \
    nss-devel \
    dhclient \
    readline-devel \
    audit-libs-devel \
    gtk-doc \
    libudev-devel \
    libuuid-devel \
    libgudev1-devel \
    vala-tools \
    iptables \
    bluez-libs-devel \
    systemd \
    libsoup-devel \
    libndp-devel \
    ModemManager-glib-devel \
    newt-devel \
    /usr/bin/dbus-launch \
    pygobject3-base \
    dbus-python \
    libselinux-devel \
    polkit-devel \
    teamd-devel \
    jansson-devel \
    make \
    libcurl-devel \
    -y

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

rm -rf "./NetworkManager"
git clone "$BUILD_REPO"
cd "./NetworkManager/"
git checkout "$BUILD_ID"

A=()
if [[ "$WITH_DEBUG" == yes ]]; then
    A=("${A[@]}" --with debug)
fi
time ./contrib/fedora/rpm/build_clean.sh -c -g "${A[@]}"

pushd "./contrib/fedora/rpm/latest/RPMS/$ARCH/"
    for p in $(ls -1 ./*.rpm | sed 's#.*\(NetworkManager.*\)-1\.[0-9]\..*#\1#'); do
        $SUDO rpm -e --nodeps $p || true
    done
    $SUDO yum install -y ./*.rpm
popd

# ensure that the expected NM is installed.
COMMIT_ID="$(git rev-parse --verify HEAD | sed 's/^\(.\{10\}\).*/\1/')"
$SUDO yum list installed NetworkManager | grep -q -e "\.$COMMIT_ID\."
RC=$?

if [ $RC -eq 0 ]; then
    cp $BUILD_DIR/NetworkManager/examples/dispatcher/10-ifcfg-rh-routes.sh /etc/NetworkManager/dispatcher.d/
    cp $BUILD_DIR/NetworkManager/examples/dispatcher/10-ifcfg-rh-routes.sh /etc/NetworkManager/dispatcher.d/pre-up.d/
    $SUDO systemctl restart NetworkManager
    echo "BUILDING $BUILD_ID COMPLETED SUCCESSFULLY"
    exit 0
else
    echo "BUILDING $BUILD_ID FAILED"
    touch /tmp/nm_compilation_failed
    exit 1
fi
