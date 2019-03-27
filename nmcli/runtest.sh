#!/bin/bash
set -x

logger -t $0 "Running test $1"

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
DIR=$(pwd)

function test_modems_usb_hub() {
    local MODEM_COUNT=${1:?"Error: number of modems is not specified."}
    # Number of modems that are plugged into Acroname USB hub.
    local PORT_COUNT=${2:?"Error: number of USB ports on hub is not specified."}
    local RC=0

    if [ -z "$NMTEST" ]; then
        echo "Error: variable \"NMTEST\" is not initialized." >&2
        return 1
    fi

    if [ -z "$DIR" ]; then
        echo "Error: variable \"DIR\" for working directory is not specified." >&2
        return 1
    fi

    touch /tmp/usb_hub
    echo "USB_HUB" > /tmp/report_$NMTEST.html
    for m in $(seq 0 1 $((MODEM_COUNT-1)) ); do
        for p in $(seq 0 1 $((PORT_COUNT-1)) ); do
            $DIR/tmp/usb_hub/acroname.py --port $p --disable
        done
        sleep 1

        $DIR/tmp/usb_hub/acroname.py --port $m --enable

        # wait for device to appear in NM
        TIMER=60
        while [ $TIMER -gt 0 ]; do
            if nmcli d |grep -q gsm; then
                break
            else
                sleep 1
                ((TIMER--))
            fi
        done

        # Test a single modem connected to the USB hub.
        # Test 1 of 2.
        behave $DIR/nmcli/features -t gsm_create_default_connection -k -f html -o /tmp/report_1.html -f plain
        if [ $? -eq 1 ]; then
            RC=1
        fi

        # Test 2 of 2.
        behave $DIR/nmcli/features -t gsm_disconnect -k -f html -o /tmp/report_2.html -f plain
        if [ $? -eq 1 ]; then
            RC=1
        fi

        # Insert the modem's USB ID and model into the HTML report.
        # Put the modem's identification in the title.
        # Do not insert into file /tmp/report_$NMTEST.html !
        # All modems will appear in every section of the report.
        if [ -f /tmp/modem_id ]; then
            MODEM_ID=$(cat /tmp/modem_id)
            sed -i -e "s/Behave Test Report/Behave Test Report - $MODEM_ID/g" /tmp/report_1.html
            sed -i -e "s/Behave Test Report/Behave Test Report - $MODEM_ID/g" /tmp/report_2.html
            # Remove modem id for next test.
            rm -f /tmp/modem_id
        fi

        # Concatenate HTML reports from 2 tests into 1.
        cat /tmp/report_{1,2}.html >> /tmp/report_$NMTEST.html
    done
}  # test_modems_usb_hub


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
    rstrnt-report-result $NMTEST "SKIP"
    exit 0

# do we have tag to run tagged test?
elif [ $vc -eq 0 ]; then
    # if yes, run with -t $TAG
    if [ x$TAG != x"" ]; then
        logger "Running $TAG version of $NMTEST"
        behave $DIR/nmcli/features -t $1 -t $TAG -k -f html -o /tmp/report_$NMTEST.html -f plain; rc=$?

    # if not 
    else
        # check if we have gsm_hub use this
        if [ $1 == 'gsm_hub' ];then
            # Test 3 modems on USB hub with 8 ports.
            test_modems_usb_hub 3 8; rc=$?

        # if we do not have tag or gsm_hub
        else
            behave $DIR/nmcli/features -t $1 -k -f html -o /tmp/report_$NMTEST.html -f plain; rc=$?
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

rstrnt-report-result -o "/tmp/report_$NMTEST.html" $NMTEST $RESULT

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc

