#! /bin/bash

BRANCH="${1:-master}"
CI_REPO="https://github.com/NetworkManager/NetworkManager-ci"
yum -y install git

git clone $CI_REPO

cd NetworkManager-ci

sh run/centos-ci/scripts/setup.sh
sh run/centos-ci/scripts/build.sh $BRANCH
