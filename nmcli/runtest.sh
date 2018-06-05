#!/bin/bash
set -x

logger -t $0 "Running test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)

. $DIR/prepare/envsetup.sh
setup_configure_environment "$1"

# set TEST variable for version_control script
if [ -z "$TEST" ]; then
    logger "setting test name to NetworkManager_Test0_$1"
    NMTEST="NetworkManager-ci_Test0_$1"
elif ! [ $TEST == "sanity-tests" ]; then
    NMTEST="$TEST"
fi

if [ -z "$NMTEST" ]; then
    logger "cannot set NMTEST var"
    exit 128
fi

#check if NM version is correct for test
TAG="$(python $DIR/version_control.py $DIR/nmcli $NMTEST)"; vc=$?
if [ $vc -eq 1 ]; then
    logger "Skipping due to incorrect NM version for this test"
    # exit 0 doesn't affect overal result
    rhts-report-result $NMTEST "SKIP"
    exit 0

elif [ $vc -eq 0 ]; then
    if [ x$TAG != x"" ]; then
        logger "Running $TAG version of $NMTEST"
        behave $DIR/nmcli/features -t $1 -t $TAG -k -f html -o /tmp/report_$NMTEST.html -f plain; rc=$?
    else
        behave $DIR/nmcli/features -t $1 -k -f html -o /tmp/report_$NMTEST.html -f plain; rc=$?
    fi
fi

RESULT="FAIL"
if [ $rc -eq 0 ]; then
    RESULT="PASS"
fi
if [ $rc -eq 77 ]; then
    RESULT="SKIP"
fi

rhts-report-result $NMTEST $RESULT "/tmp/report_$NMTEST.html"
#rhts-submit-log -T $TEST -l "/tmp/log_$TEST.html"

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
