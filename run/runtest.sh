#!/bin/bash

set -x

die() {
    printf '%s' "$*"
    exit 1
}


dump_NM_journal() {
    echo -e "No report generated, dumping NM journal log\n\n" > $NMTEST_REPORT
    if [[ "$NMTEST_REPORT" == *".html" ]]; then echo "<pre>" >> $NMTEST_REPORT; fi
    journalctl -u NetworkManager --no-pager -o cat "$LOG_CURSOR" | sed 's/</\&lt;/g;s/>/\&gt;/g' >> $NMTEST_REPORT
    if [[ "$NMTEST_REPORT" == *".html" ]]; then echo "</pre>" >> $NMTEST_REPORT; fi
}

logger -t $0 "Running test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)

. $DIR/run/gsm_hub.sh
. $DIR/prepare/envsetup.sh
configure_environment "$1"
export_python_command

export COLUMNS=1024

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

LOG_CURSOR=$(journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print "--after-cursor="$NF; exit}')


FEATURE_FILE=$(grep "@$1\(\s\|\$\)" -l $DIR/features/scenarios/*.feature)
# if $FEATURE_FILE is empty or contains more than one line
if [ -z "$FEATURE_FILE" -o $( wc -l <<< "$FEATURE_FILE" ) != 1 ]; then
    logger "Resetting FEATURE_FILE, as it is: $FEATURE_FILE"
    FEATURE_FILE=$DIR/features
fi
# get tags specific to software versions (NM, fedora, rhel)
# see version_control.py for more details
TAG="$(python $DIR/version_control.py "$FEATURE_FILE" "$NMTEST")"; rc=$?
# if version control exited normally, run the test
if [ $rc -eq 0 ]; then
    if [[ $1 == gsm_hub* ]];then
      # Test all modems on USB hub with 8 ports.
      test_modems_usb_hub; rc=$?
    else
      # Test nmtui and nmcli
      logger "Running  $NMTEST  with tags '$TAG'"

      behave $FEATURE_FILE -t $1 $TAG -k -f html -o "$NMTEST_REPORT" -f plain ; rc=$?
    fi
fi

# xfail handling
if [[ $TAG = *"-t xfail "* ]]; then
    if [ "$rc" = 0 ]; then
      rc=1
    elif [ "$rc" != 77 ]; then
      rc=0
    fi
# may_fail
elif [[ $TAG = *"-t may_fail "* ]]; then
    if [ "$rc" != 77 ]; then
      rc=0
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

# If we FAILED and no report, dump journal to report
if [ "$RESULT" = FAIL -a ! -s "$NMTEST_REPORT" ]; then
    dump_NM_journal
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
