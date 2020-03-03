#! /bin/bash

BRANCH="${1:-nm-1-22}"
CI_REPO="https://github.com/NetworkManager/NetworkManager-ci"
yum -y install git

git clone $CI_REPO

cd NetworkManager-ci

sh run/centos-ci/scripts/build.sh $BRANCH
