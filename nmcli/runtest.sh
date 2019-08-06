#!/bin/bash
set -x

logger -t $0 "Running test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)


. $DIR/nmcli/gsm_hub.sh
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

NMTEST_REPORT=/tmp/report_$NMTEST.html

#check if NM version is correct for test
TAG="$(python $DIR/version_control.py $DIR/nmcli $NMTEST)"; vc=$?
if [ $vc -eq 1 ]; then
    logger "Skipping due to incorrect NM version for this test"
    rstrnt-report-result -o "" $NMTEST "SKIP"
    exit 0

# do we have tag to run tagged test?
elif [ $vc -eq 0 ]; then
    # if yes, run with -t $TAG
    if [ x$TAG != x"" ]; then
        logger "Running $TAG version of $NMTEST"
        behave $DIR/nmcli/features -t $1 -t $TAG -k -f html -o "$NMTEST_REPORT" -f plain; rc=$?

    # if not
    else
        # check if we have gsm_hub use this
        if [[ $1 == gsm_hub* ]];then
            # Test 3 modems on USB hub with 8 ports.
            test_modems_usb_hub; rc=$?

        # if we do not have tag or gsm_hub
        else
            behave $DIR/nmcli/features -t $1 -k -f html -o "$NMTEST_REPORT" -f plain; rc=$?
        fi
    fi
fi


if [ $rc -eq 0 ]; then
    RESULT="PASS"
elif [ $rc -eq 77 ]; then
    RESULT="SKIP"
    rc=0
else
    RESULT="FAIL"
fi

# check for NM crash
if grep -q CRASHED_STEP_NAME "$NMTEST_REPORT" ; then
    RESULT="FAIL"
    rc=1
fi

rstrnt-report-result -o "$NMTEST_REPORT" $NMTEST $RESULT

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
