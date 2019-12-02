#!/bin/bash

set -x

die() {
    printf '%s' "$*"
    exit 1
}

RUNTEST_TYPE="$(readlink -f "$(dirname "$0")")"
RUNTEST_TYPE="${RUNTEST_TYPE##*/}"
case "$RUNTEST_TYPE" in
    nmcli) : ;;
    nmtui) : ;;
    *) die "invalid test type \"$RUNTEST_TYPE\". Failed to detect from script name \"$0\""
esac

logger -t $0 "Running $RUNTEST_TYPE test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)

test "$RUNTEST_TYPE" == nmtui || . $DIR/nmcli/gsm_hub.sh
. $DIR/prepare/envsetup.sh
setup_configure_environment "$1"
export_python_command

if [ "$RUNTEST_TYPE" == nmtui ]; then
    # install the pyte VT102 emulator
    if [ ! -e /tmp/nmtui_pyte_installed ]; then
        python -m pip install setuptools --upgrade
        python -m pip install pyte

        touch /tmp/nmtui_pyte_installed
    fi

    # can't have the default 'dumb' for curses to "work" even if we redirect output
    # for the internal pyte based terminal
    export TERM=vt102
fi

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

if [ "$RUNTEST_TYPE" == nmtui ]; then
    NMTEST_REPORT=/tmp/report_$NMTEST.log
else
    NMTEST_REPORT=/tmp/report_$NMTEST.html
fi

# get tags specific to software versions (NM, fedora, rhel)
# see version_control.py for more details
TAG="$(python $DIR/version_control.py $DIR/$RUNTEST_TYPE $NMTEST)"; vc=$?
if [ $vc -eq 1 ]; then
    logger "Skipping due to incorrect NM version for this test"
    rstrnt-report-result -o "" $NMTEST "SKIP"
    exit 0

# do we have tag to run tagged test?
elif [ $vc -eq 0 ]; then
    FEATURE_FILE=$(grep "@$1" -l $DIR/$RUNTEST_TYPE/features/*.feature)
    if [ -z $FEATURE_FILE ]; then
        FEATURE_FILE=$DIR/$RUNTEST_TYPE/features
    fi

    logger "Running $TAG version of $NMTEST"
    if [ "$RUNTEST_TYPE" == nmtui ]; then
        # Test nmtui
        behave $FEATURE_FILE --no-capture --no-capture-stderr -k -t $1 -t $TAG -f plain -o $NMTEST_REPORT; rc=$?
    elif [[ $1 == gsm_hub* ]];then
        # Test all modems on USB hub with 8 ports.
        test_modems_usb_hub; rc=$?
    else
        # Test nmcli
        behave $FEATURE_FILE -t $1 -t $TAG -k -f html -o "$NMTEST_REPORT" -f plain; rc=$?
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

if [ "$RUNTEST_TYPE" != nmtui ]; then
    # check for NM crash
    if grep -q CRASHED_STEP_NAME "$NMTEST_REPORT" ; then
        RESULT="FAIL"
        rc=1
    fi
fi

if [ "$RUNTEST_TYPE" == nmtui ]; then
    # only way to have screen snapshots for each step present in the individual logs
    # the tui-screen log is created via environment.py
    cat /tmp/tui-screen.log >> $NMTEST_REPORT

    # this is to see the semi-useful output in the TESTOUT for failed tests too
    echo "--------- $NMTEST_REPORT ---------"
    cat $NMTEST_REPORT

    if [ $RESULT == "FAIL" ]; then
        echo "Attaching journal log as well"
        cat /tmp/journal-session.log >> $NMTEST_REPORT
        sleep 1
    fi
fi

# If we have running harness.py then upload logs
if ps aux|grep -v grep| grep -q harness.py; then
    # check for empty file: -s means nonempty
    if [ -s "$NMTEST_REPORT" ]; then
        rstrnt-report-result -o "$NMTEST_REPORT" $NMTEST $RESULT
    else
        echo "removing empty report file"
        rm -f "$NMTEST_REPORT"
        rstrnt-report-result -o "" $NMTEST $RESULT
    fi
fi

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
