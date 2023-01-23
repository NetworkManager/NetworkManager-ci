#!/bin/bash

SRPM_AUTOCONF=https://kojipkgs.fedoraproject.org//packages/autoconf-archive/2022.02.11/3.eln120/src/autoconf-archive-2022.02.11-3.eln120.src.rpm
SRPM_LIBELL=https://kojipkgs.fedoraproject.org//packages/libell/0.52/1.eln121/src/libell-0.52-1.eln121.src.rpm
SRPM_MPTCPD=https://kojipkgs.fedoraproject.org//packages/mptcpd/0.10/2.eln120/src/mptcpd-0.10-2.eln120.src.rpm

RES_DIR=built
ARCH=$(arch)
MOCK="mock -r mock-configs/rhel-8-${ARCH}-mod.cfg"

die() {
  echo $1
  exit 1
}

which mock || die "mock command not found!"

mkdir -p $RES_DIR

cp mock-configs/rhel-8-mod.tpl /etc/mock/templates/

$MOCK --rebuild $SRPM_AUTOCONF --resultdir $RES_DIR
$MOCK --rebuild $SRPM_LIBELL --resultdir $RES_DIR
$MOCK --init
$MOCK --install "$(find $RES_DIR -name autoconf-archive*noarch.rpm)"  --install "$(find $RES_DIR -name libell-[0-9]*.${ARCH}.rpm)" --install $(find $RES_DIR -name libell-devel*)
$MOCK --no-clean --rebuild $SRPM_MPTCPD --resultdir $RES_DIR
