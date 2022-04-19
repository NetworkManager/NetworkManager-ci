#!/bin/bash

set -x

die() {
    printf '%s' "$*"
    exit 1
}


dump_NM_journal() {
    echo -e "No report generated, dumping NM journal log\n\n"
    echo "<pre>"
    journalctl -u NetworkManager --no-pager -o cat "$LOG_CURSOR" | \
      sed 's/</\&lt;/g;s/>/\&gt;/g'T
    echo "</pre>"
}

# if $1 starts with @, cut it away
TAG="${1#@}"

logger -t $0 "Running test $TAG"

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
DIR=$(pwd)

# set TEST variable for version_control script
if [ -z "$TEST" ]; then
    logger "setting test name to NetworkManager_Test0_$TAG"
    NMTEST="NetworkManager-ci_Test0_$TAG"
elif ! [ "$TEST" == "sanity-tests" ]; then
    NMTEST="$TEST"
fi

if [ -z "$NMTEST" ]; then
    logger "cannot set NMTEST var"
    exit 128
fi

. $DIR/run/gsm_hub.sh
. $DIR/prepare/envsetup.sh
( configure_environment "$TAG" ) ; conf_rc=$?
if [ $conf_rc != 0 ]; then
    if ps aux|grep -v grep| grep -q harness.py; then
        rstrnt-report-result -o "" "$NMTEST" FAIL
    fi
    cat /tmp/nmcli_general
    exit $conf_rc
fi
export_python_command

export COLUMNS="1024"

NMTEST_REPORT="/tmp/report_$NMTEST.html"

LOG_CURSOR=$(journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print "--after-cursor="$NF; exit}')


FEATURE_FILE=$(grep "@$TAG\(\s\|\$\)" -l $DIR/features/scenarios/*.feature)
# if $FEATURE_FILE is empty or contains more than one line
if [ -z "$FEATURE_FILE" -o $( wc -l <<< "$FEATURE_FILE" ) != 1 ]; then
    logger "Resetting FEATURE_FILE, as it is: $FEATURE_FILE"
    FEATURE_FILE="$DIR/features/scenarios/*"
fi
# get tags specific to software versions (NM, fedora, rhel)
# see version_control.py for more details
ALL_TAGS=($(python $DIR/version_control.py "$FEATURE_FILE" "$NMTEST")); rc=$?
# if version control exited normally, run the test
if [ $rc -eq 0 ]; then
    if [[ "$TAG" == gsm_hub* ]];then
      # Test all modems on USB hub with 8 ports.
      test_modems_usb_hub; rc=$?
    else
      # Test nmtui and nmcli
      logger "Running  $NMTEST  with tags '${ALL_TAGS[@]}'"

      behave "$FEATURE_FILE" "${ALL_TAGS[@]}" -k -f html -o "$NMTEST_REPORT" -f plain ; rc=$?
    fi
fi

# xfail handling
if [[ "${ALL_TAGS[@]} " =~ "-t xfail " ]]; then
    if [ "$rc" = 0 ]; then
      rc=1
    elif [ "$rc" != 77 ]; then
      rc=0
    fi
# may_fail
elif [[ "${ALL_TAGS[@]} " =~ "-t may_fail " ]]; then
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
if [ "$RESULT" = "FAIL" -a ! -s "$NMTEST_REPORT" ]; then
    dump_NM_journal  > "$NMTEST_REPORT"
fi

# If we have running harness.py then upload logs
if ps aux | grep -v grep | grep -q harness.py; then
    # check for empty file: -s means nonempty
    if [ -s "$NMTEST_REPORT" ]; then
        rstrnt-report-result -o "$NMTEST_REPORT" "$NMTEST" "$RESULT"
    else
        echo "removing empty report file"
        rm -f "$NMTEST_REPORT"
        rstrnt-report-result -o "" "$NMTEST" "$RESULT"
    fi
fi

logger -t $0 "Test $TAG finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc
