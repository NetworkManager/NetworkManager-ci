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

. /etc/os-release

if [ "$ID" == rhel ]; then
    link=$(dnf -v repolist --enabled | grep Repo-baseurl | grep BaseOS | grep /os | grep -v RCMTOOLS | head -n 1 | sed 's/.*: //g;s!/os!/images/!' )
    link="$link$(get_all "$link" | grep 'qcow2$')"
elif [ "$ID" == centos ]; then
    link=https://cloud.centos.org/centos/$VERSION_ID-stream/$(arch)/images/
    # grep out GenericCloud-x86_64-9-latest.x86_64.qcow2
    img="$(get_all "$link" | grep latest | grep "GenericCloud-$VERSION_ID" | grep 'qcow2$' )"
    if [ -z "$img" ]; then
        link=https://kojihub.stream.centos.org/kojifiles/vol/koji02/packages/CentOS-Stream-GenericCloud/$VERSION_ID/
        link="$link$(get_all "$link" | sort | tail -n 1)/images/"
        img="$(get_all "$link" | grep "GenericCloud-$VERSION_ID" | grep $(arch) | grep 'qcow2$' )"
    fi
    link="$link$img"
elif [ "$ID" == fedora ]; then
    VERSION_ID2="$VERSION_ID"
    [[ "$VERSION" == *"Rawhide"* ]] && VERSION_ID=rawhide && VERSION_ID2=Rawhide
    # get compose from repo
    COMP=$(grep baseurl -r /etc/yum.repos.d/ | grep -o Fedora-$VERSION_ID2-[^/]* | head -n1)
    link=https://kojipkgs.fedoraproject.org/compose/$VERSION_ID/$COMP/compose/Cloud/$(arch)/images/
    img="$(get_all "$link" | grep -e "Base-Generic" -e "Base-$VERSION_ID" | grep "qcow2" )"
    # or set to latest if not recognized
    if [ -z "$img" ]; then
        COMP="latest-Fedora-$VERSION_ID2"
        link=https://kojipkgs.fedoraproject.org/compose/$VERSION_ID/$COMP/compose/Cloud/$(arch)/images/
        img="$(get_all "$link" | grep -e "Base-Generic" -e "Base-$VERSION_ID" | grep "qcow2" )"
    fi
    # if we don't have img so far, probably rawhide is missing in os version
    if [ -z "$img" ]; then
        VERSION_ID=rawhide
        VERSION_ID2=Rawhide
        COMP="latest-Fedora-$VERSION_ID2"
        link=https://kojipkgs.fedoraproject.org/compose/$VERSION_ID/$COMP/compose/Cloud/$(arch)/images/
        img="$(get_all "$link" | grep -e "Base-Generic" -e "Base-$VERSION_ID" | grep "qcow2" )"
    fi
    if [ -z "$img" ]; then
        echo "Unable to find fedora image"
        exit 1
    fi

    # filter only relevant SHA to root.sha
    checksum="$link$(get_all "$link" | grep "CHECKSUM")"
    wget --tries=5 --retry-connrefused --retry-on-http-error=404,500,502 --waitretry=2 --no-verbose -O $TESTDIR/root.sha $checksum --no-check-certificate
    sed -n -i "/Base-Generic/ p;/Base-$VERSION_ID.*qcow2/ p" $TESTDIR/root.sha

    link="$link$img"
fi

if [ -z "$link" ]; then
    echo "Distribution not recognized, unable to download image"
    exit 1
fi

echo "ImageLink: $link"

wget --tries=5 --retry-connrefused --retry-on-http-error=404,500,502 --waitretry=2 --no-verbose -O $TESTDIR/root.sha $link.SHA256SUM --no-check-certificate
SHA=$(sed -n 's/.* = //p' < $TESTDIR/root.sha)

# Download image if checksum is not correct
if ! sha256sum $TESTDIR/root.qcow2 | grep -q "$SHA" ; then
    wget --tries=5 --retry-connrefused --retry-on-http-error=404,500,502 --waitretry=2 --no-verbose -O $TESTDIR/root.qcow2 $link --no-check-certificate
fi

# Exit if checksum is not correct
if ! sha256sum $TESTDIR/root.qcow2 | grep -q "$SHA" ; then
    echo "Downloaded image corrupted, checksum mismatch..."
    exit 1
fi

modprobe nbd max_part=8
# nbd0 sometimes refuses to work (c10s), use nbd1 then
nbd=/dev/nbd0
if ! qemu-nbd --read-only --connect=$nbd $TESTDIR/root.qcow2; then
    nbd=/dev/nbd1
    qemu-nbd --read-only --connect=$nbd $TESTDIR/root.qcow2
fi
sleep 0.1
fdisk $nbd -l || (sleep 1; fdisk $nbd -l; )
part=$(fdisk $nbd -l | grep "Linux \(filesystem\|root\)" | tail -n 1 | sed 's/ .*//')
[ -z "$part" ] && part=$(fdisk $nbd -l | grep "Linux" | tail -n 1 | sed 's/ .*//')

mkdir -p $TESTDIR/qcow
# mount with many options:
#  - ro - read only - we don't want to change the qcow2 disk (to preserve SHA)
#  - noatime - do not modify access times of the files
#  - norecovery - do not repair journaling FS
#  - nouuid - prevent mounting error, as image is probably running (OpenStack) - not availiable on btrfs
mount $part -o ro,noatime,norecovery,nouuid $TESTDIR/qcow || \
    mount $part -o ro,noatime,norecovery $TESTDIR/qcow

# Fedora Cloud image contains / in /root dir
root=""
[ -d $TESTDIR/qcow/root/etc ] && root=root/

[ -d $TESTDIR/qcow/${root}etc ] || { echo "Mount failed, etc/ directory not found" ; exit 1; }

mkdir -p $initdir
rsync -a $TESTDIR/qcow/$root $initdir || echo "WARNING! rsync to nfsroot failed!"

# Fedora Cloud image contains /var separately
[ -n "$root" ] && [ -d $TESTDIR/qcow/var ] && ( rsync -a $TESTDIR/qcow/var/ $initdir/var/ || echo "WARNING! rsync if /var to nfsroot failed!"; )

# umount twice, there might be also bind
umount $TESTDIR/qcow
umount $TESTDIR/qcow
qemu-nbd --disconnect $nbd

# remove qcow, if not enough space for 2 iSCSI images, +1000M safatey margin for installed NM and kernel later on
df=$(df -m --output=avail $TESTDIR | tail -n 1)
du=$(du -s -m $initdir | tail -n 1 | grep -o '^[0-9]*')
(( df > 2*du + 1000 )) || rm $TESTDIR/root.qcow2