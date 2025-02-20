#/bin/bash
set -e
DIR="$(pwd)/contrib/dnsconfd"
DISTRO="centos-stream-9"

rm -rf /tmp/dnsconfd || true
git clone https://github.com/InfrastructureServices/dnsconfd.git /tmp/dnsconfd


if grep -q el10 /etc/os-release; then
    dnf -y install \
        https://kojipkgs.fedoraproject.org//packages/cdrkit/1.1.11/57.el10_0/$(arch)/genisoimage-1.1.11-57.el10_0.$(arch).rpm \
        https://kojipkgs.fedoraproject.org//packages/cdrkit/1.1.11/57.el10_0/$(arch)/libusal-1.1.11-57.el10_0.$(arch).rpm
    DISTRO="centos-stream-10"

elif grep -q el9 /etc/os-release; then
    dnf -y install genisoimage libusal
    DISTRO="centos-stream-9"

elif grep -q fedora /etc/os-release; then
    dnf -y install genisoimage libusal
    DISTRO="fedora"

fi


dnf -y install \
    libvirt python3-libvirt

python3l -m pip install tmt testcloud

systemctl restart libvirtd

sed -i "s/centos-stream-9/$DISTRO/" $DIR/nmci.fmf

\cp -f $DIR/build_ostree.sh /tmp/dnsconfd/tests
\cp -f $DIR/nmci.fmf /tmp/dnsconfd/plans
\cp -f $DIR/../utils/* /tmp/dnsconfd/tests

pushd /tmp/dnsconfd
tmt --feeling-safe --context distro=$DISTRO run plan --name plans/nmci  -vvvv

popd
