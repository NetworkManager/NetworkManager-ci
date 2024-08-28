#!/bin/bash
set -x

# This is copied from contrib/utils/brew_links.sh - TODO, source it instead
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
    curl -L --insecure --max-redirs 5 -s "$1" |sed 's/<tr>/\n/g' | awk "$AWK_SCR" | sed "s/.*a href=[$QUOT]\([^$QUOT]*\)[$QUOT].*/\1/;s@/*\$@@"
}

link=

dnf -v repolist --enabled
if grep -q "Red Hat" /etc/redhat-release; then
    link=$(dnf -v repolist --enabled | grep Repo-baseurl | grep BaseOS | grep /os | sed 's/.*: //g;s!/os!/images/!' )
    link="$link$(get_all "$link" | grep 'qcow2$')"
elif grep -q "CentOS" /etc/redhat-release; then
    rel=$(grep -o 'release [0-9]*' /etc/redhat-release | grep -o '[0-9]*')
    link=https://cloud.centos.org/centos/$rel-stream/$(arch)/images/
    # grep out GenericCloud-x86_64-9-latest.x86_64.qcow2
    link="$link$(get_all "$link" | grep latest | grep "GenericCloud-$rel" | grep 'qcow2$' )"
elif grep -q "Fedora" /etc/redhat-release; then
    link=http://spiceqe.brq.redhat.com/
    . /etc/os-release
    img="$(get_all "$link" | grep "Fedora-$VERSION_ID-latest-Server-$(arch)" | head -n 1)"
    if [ -z "$img" ]; then
        img="$(get_all "$link" | grep "Fedora-Rawhide-latest-Server-$(arch)" | head -n 1)"
    fi

    if [ -z "$img" ]; then
        echo "Unable to find fedora image"
        exit 1
    fi

    link="$link$img"
fi

if [ -z "$link" ]; then
    echo "Distribution not recognized, unable to download image"
    exit 1
fi

echo "ImageLink: $link"

wget --no-verbose -O $TESTDIR/root.sha $link.SHA256SUM --no-check-certificate
SHA=$(sed -n 's/.* = //p' < $TESTDIR/root.sha)

# Download image if checksum is not correct
if ! sha256sum $TESTDIR/root.qcow2 | grep -q "$SHA" ; then
    wget --no-verbose -O $TESTDIR/root.qcow2 $link --no-check-certificate
fi

# Exit if checksum is not correct
if ! sha256sum $TESTDIR/root.qcow2 | grep -q "$SHA" ; then
    echo "Downloaded image corrupted, checksum mismatch..."
    exit 1
fi

modprobe nbd max_part=8
qemu-nbd --read-only --connect=/dev/nbd0 $TESTDIR/root.qcow2
sleep 0.1
fdisk /dev/nbd0 -l || (sleep 1; fdisk /dev/nbd0 -l; )
part=$(fdisk /dev/nbd0 -l | grep "Linux \(filesystem\|root\)" | sed 's/ .*//')
[ -z "$part" ] && part=$(fdisk /dev/nbd0 -l | grep "Linux" | tail -n 1 | sed 's/ .*//')

mkdir -p $TESTDIR/qcow
# mount with many options:
#  - ro - read only - we don't want to change the qcow2 disk (to preserve SHA)
#  - noatime - do not modify access times of the files
#  - norecovery - do not repair journaling FS
#  - nouuid - prevent mounting error, as image is probably running (OpenStack)
mount $part -o ro,noatime,norecovery,nouuid $TESTDIR/qcow

[ -d $TESTDIR/qcow/etc ] || { echo "Mount failed, etc/ directory not found" ; exit 1; }

mkdir -p $initdir
rsync -a $TESTDIR/qcow/ $initdir || echo "WARNING! rsync to nfsroot failed!"

umount $TESTDIR/qcow
qemu-nbd --disconnect /dev/nbd0

# remove qcow to save some space
rm $TESTDIR/root.qcow2