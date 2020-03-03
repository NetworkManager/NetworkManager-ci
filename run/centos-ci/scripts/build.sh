#!/bin/bash

BUILD_DIR="${BUILD_DIR:-/root/nm-build}"
RPM_DIR="NetworkManager/contrib/fedora/rpm/latest/RPMS/"
BUILD_ID="$1"
BUILD_REPO="${BUILD_REPO-https://github.com/NetworkManager/NetworkManager.git}"
ARCH="${ARCH:-`arch`}"
WITH_DEBUG="${WITH_DEBUG:no}"

if [ -z "$SUDO" ]; then
    unset SUDO
fi

# Workaround for not working repo
rm -rf /etc/yum.repos.d/CentOS-Media.repo

$SUDO dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
$SUDO yum config-manager --set-enabled PowerTools
$SUDO curl https://copr.fedorainfracloud.org/coprs/nmstate/nm-build-deps/repo/epel-8/nmstate-nm-build-deps-epel-8.repo > /etc/yum.repos.d/nmstate-nm-build-deps-epel-8.repo

$SUDO yum install \
    git \
    rpm-build \
    intltool \
    valgrind \
    strace \
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
    mobile-broadband-provider-info-devel \
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
    pygobject3-devel \
    dbus-python \
    libselinux-devel \
    polkit-devel \
    teamd-devel \
    jansson-devel \
    make \
    libcurl-devel \
    python3 \
    libasan \
    gnutls-devel \
    https://vbenes.fedorapeople.org/NM/openvswitch2.13-2.13.0-4.el8fdp.$(arch).rpm \
    https://vbenes.fedorapeople.org/NM/openvswitch-selinux-extra-policy-1.0-22.el8fdp.noarch.rpm \
    --skip-broken \
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

echo ">> Removing an old packages"
for p in $(rpm -qa |grep NetworkManager); do
    echo ">>> Removing $p"
    rpm -e --nodeps $p
done

echo ">> Installing the newly built packages"
$SUDO yum install -y $BUILD_DIR/$RPM_DIR/{$ARCH,noarch}/*.rpm


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
