#/bin/bash

set -e -x

function skip_test_on_arch() {
    local file="$1" arch="${2:-s390x}"
    [[ -f "$file" ]] || { echo "File not found"; return 1; }
    # Do just an easy fmf file removal, this is enough for skipping the test
    rm -rf $file
}

SETUP_DIR="$(pwd)/contrib/dnsconfd"
DNSCONFD_DIR="/tmp/dnsconfd"
DNSCONFD_VER=$(rpm -q --qf '%{VERSION}' dnsconfd)

rm -rf $DNSCONFD_DIR || true
git clone https://github.com/InfrastructureServices/dnsconfd.git $DNSCONFD_DIR

pushd $DNSCONFD_DIR
    if [ "$DNSCONFD_VER" == "1.7.2" ]; then
        git checkout 823369e59ce1bdf29f1a3f75e54e61b049c2c79a
        skip_test_on_arch /tmp/dnsconfd/tests/dhcp/main.fmf s390x
    else
        if [ "$DNSCONFD_VER" == "1.7.3" ]; then
            skip_test_on_arch /tmp/dnsconfd/tests/dhcp/main.fmf s390x
	fi
        git checkout tags/$DNSCONFD_VER
    fi

    # Include a missing NM logs in Cleanup phase into all tests if not present
    for file in $DNSCONFD_DIR/tests/*/test.sh; do
        line='        rlRun "podman exec $dnsconfd_cid journalctl -u NetworkManager" 0 "Saving NM logs"'
        if ! grep -q "Saving NM logs" $file; then
	    echo "Adding NM logs to $file" && sed -i "/rlPhaseStartCleanup/a\\$line" $file
	fi
    done
popd

if [ -f /etc/os-release ]; then
    source /etc/os-release
    echo "ID: $ID"
    echo "VERSION_ID: $VERSION_ID"
else
    echo "Cannot determine the distribution!"
    exit 1
fi

# Create /tmp/rpms where we need installed rpms in
TARGET_DIR="/tmp/rpms"
rm -rf $TARGET_DIR
mkdir $TARGET_DIR
# Download packages to /tmp/rpms where nmci.fmf plan pulls them

# Do we have copr?
if dnf info NetworkManager --installed | grep -iE 'from repo' | grep copr; then
    dnf download --disablerepo=* --enablerepo=*copr* \
        NetworkManager NetworkManager-libnm \
        --destdir $TARGET_DIR \
        --arch=$(arch) # to avoid src.rpm downloading
fi

# Did we compiled NM?
RPM_DIRS=(
    "/root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"
    "/tmp/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"
    "/root/rpms/"
)
for RPM_DIR in "${RPM_DIRS[@]}"; do
    if [[ -d "$RPM_DIR" ]]; then
        if ls $RPM_DIR/$(arch) |grep -q NetworkManager; then
            cp $RPM_DIR/$(arch)/NetworkManager-[1-9]* $TARGET_DIR
            cp $RPM_DIR/$(arch)/NetworkManager-libnm-[1-9]* $TARGET_DIR
            break
        fi
    fi
done

# Do we still have empty /tmp/rpms? We are on stock packages
if [ -z "$(ls -A $TARGET_DIR)" ]; then
    dnf download NetworkManager NetworkManager-libnm \
        --destdir $TARGET_DIR
fi

# Let's move our changes to dnsconfd dir
\cp -f $SETUP_DIR/dnsconfd.Dockerfile $DNSCONFD_DIR/tests/
\cp -f $SETUP_DIR/nmci.fmf $DNSCONFD_DIR/plans/

pushd $DNSCONFD_DIR
# detect tmt - try harmless command
# 1) rpm install - tmt command should work
# 2) pip install - we install to latest python3l, but might get executed by older python3, execute with python3l then
TMT_BIN=tmt
tmt --version || TMT_BIN="python3l -m tmt"
$TMT_BIN --feeling-safe --context=distro=$ID-$VERSION_ID --context trigger=CI run -v -a plan --name plans/nmci provision --how local

popd
