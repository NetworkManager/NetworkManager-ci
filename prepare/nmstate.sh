#! /bin/bash

yum -y install python3-devel rpm-build
rm -rf /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

# remove nmstate bits
rm -rf nmstate

git clone https://github.com/ffmancera/nmstate
cd nmstate
git checkout not_available_connections
LC_TIME=en_US-UTF-8 sh packaging/make_rpm.sh; rc=$?
if test $rc -eq 0; then
    rm -rf nmstate-*.src.rpm
    yum remove -y nmstate python3-libnmstate
    yum -y localinstall python3-libnmstate* nmstate-*
    python -m pip install pytest
else
    printf "\n\n* COMPILATION FAILED!\n\n"
fi

exit $rc
