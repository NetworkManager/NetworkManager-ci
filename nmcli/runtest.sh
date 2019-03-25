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
            MODEM_COUNT=3
            PORT_COUNT=8
            rc=0
            touch /tmp/usb_hub
            echo "USB_HUB" > /tmp/report_$NMTEST.html
            # Number of modems that are plugged into Acroname USB hub.
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
                
                behave $DIR/nmcli/features -t gsm_create_default_connection -k -f html -o /tmp/report_1.html -f plain
                if [ $? -eq 1 ]; then
                    rc=1
                fi
                
                cat /tmp/report_1.html >> /tmp/report_$NMTEST.html

                behave $DIR/nmcli/features -t gsm_disconnect -k -f html -o /tmp/report_2.html -f plain
                if [ $? -eq 1 ]; then
                    rc=1
                fi
                
                cat /tmp/report_2.html >> /tmp/report_$NMTEST.html
            done

        # if we do not have tag or gsm_hub
        else
            behave $DIR/nmcli/features -t $1 -k -f html -o /tmp/report_$NMTEST.html -f plain; rc=$?
        fi
    fi
fi

RESULT="FAIL"
if [ $rc -eq 0 ]; then
    RESULT="PASS"
fi
if [ $rc -eq 77 ]; then
    RESULT="SKIP"
    rc=0
fi

rstrnt-report-result -o "/tmp/report_$NMTEST.html" $NMTEST $RESULT

logger -t $0 "Test $1 finished with result $RESULT: $rc"

echo "------------ Test result: $RESULT ------------"
exit $rc

