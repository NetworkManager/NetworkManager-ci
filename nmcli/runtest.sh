#!/bin/bash
set -x

logger -t $0 "Running test $1"

. prepare/devsetup.sh
setup_configure_environment "$1"

# set TEST variable for version_control script
if [ -z "$TEST" ]; then
    TEST="NetworkManager_Test0_$1"
fi

#check if NM version is correct for test
TAG=$(python version_control.py nmcli $TEST); vc=$?
if [ $vc -eq 1 ]; then
    echo "Skipping due to incorrect NM version for this test"
    # exit 0 doesn't affect overal result
    exit 0

elif [ $vc -eq 0 ]; then
    if [ x$TAG != x"" ]; then
        echo "Running $TAG version of $TEST"
        behave nmcli/features -t $1 -t $TAG -k -f html -o /tmp/report_$TEST.html -f plain; rc=$?
    else
        behave nmcli/features -t $1 -k -f html -o /tmp/report_$TEST.html -f plain; rc=$?
    fi
fi

RESULT="FAIL"
if [ $rc -eq 0 ]; then
    RESULT="PASS"
fi

rhts-report-result $TEST $RESULT "/tmp/report_$TEST.html"
#rhts-submit-log -T $TEST -l "/tmp/log_$TEST.html"

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
