#!/bin/bash
set -x
logger -t $0 "Running test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)

. $DIR/prepare/devsetup.sh
setup_configure_environment "$1"

# install the pyte VT102 emulator
if [ ! -e /tmp/nmtui_pyte_installed ]; then
    easy_install pip
    pip install pyte

    touch /tmp/nmtui_pyte_installed
fi

# can't have the default 'dumb' for curses to "work" even if we redirect output
# for the internal pyte based terminal
export TERM=vt102

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
TAG="$(python $DIR/version_control.py $DIR/nmtui $NMTEST)"; vc=$?
if [ $vc -eq 1 ]; then
    logger "Skipping due to incorrect NM version for this test"
    # exit 0 doesn't affect overal result
    rstrnt-report-result $NMTEST "PASS"
    exit 0

elif [ $vc -eq 0 ]; then
    if [ x$TAG != x"" ]; then
        logger "Running $TAG version of $NMTEST"
        behave $DIR/nmtui/features --no-capture --no-capture-stderr -k -t $1 -t $TAG -f plain -o /tmp/report_$NMTEST.log; rc=$?
    else
        behave $DIR/nmtui/features --no-capture --no-capture-stderr -k -t $1 -f plain -o /tmp/report_$NMTEST.log; rc=$?
    fi
fi

RESULT="FAIL"
if [ $rc -eq 0 ]; then
    RESULT="PASS"
fi
if [ $rc -eq 77 ]; then
    RESULT="PASS"
    rc=0
fi

# only way to have screen snapshots for each step present in the individual logs
# the tui-screen log is created via environment.py
cat /tmp/tui-screen.log >> /tmp/report_$NMTEST.log

# this is to see the semi-useful output in the TESTOUT for failed tests too
echo "--------- /tmp/report_$NMTEST.log ---------"
cat /tmp/report_$NMTEST.log

rstrnt-report-result -o "/tmp/report_$NMTEST.log" $NMTEST $RESULT

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
