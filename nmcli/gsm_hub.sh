#!/bin/bash

function runtest () {
    local TEST_NAME=${1:?"Error: test name is missing."}
    local MODEM_INDEX=${2:?"Error: modem index is missing."}
    local RC=0

    if [ -z "$DIR" ]; then
        echo "Error: variable \"DIR\" for working directory is not specified." >&2
        return 1
    fi

    TAG="$(python $DIR/version_control.py $DIR/nmcli $TEST_NAME)"; vc=$?
    if [ $vc -eq 1 ]; then
        logger "Skipping due to incorrect NM version for this test"
        return 0
    fi

    if [ "x$TAG" != "x" ]; then
        behave $DIR/nmcli/features -t $TEST_NAME -t $TAG -k -f html -o /tmp/report.html -f plain || RC=1
    else
        behave $DIR/nmcli/features -t $TEST_NAME -k -f html -o /tmp/report.html -f plain || RC=1
    fi

    # Insert the modem's USB ID and model into the HTML report.
    if [ -f /tmp/modem_id ]; then
        MODEM_ID=$(cat /tmp/modem_id)
        sed -i -e "s/Behave Test Report/Behave Test Report - $MODEM_ID/g" /tmp/report.html
        # Create unique IDs of embedded sections in the HTML report.
        # Allow joining of two or more reports with collapsible sections.
        sed -i -e "s/embed_/${MODEM_INDEX}_${TEST_NAME}_embed_/g" /tmp/report.html
        # Remove modem id for next test.
        rm -f /tmp/modem_id
    fi

    return $RC
}

function test_modems_usb_hub() {
    # Number of modems that are plugged into Acroname USB hub.
    local MODEM_COUNT=6
    # Number of ports Acroname USB hub has.
    local PORT_COUNT=8
    # Return code
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
    for M in $(seq 0 1 $((MODEM_COUNT-1)) ); do
        for P in $(seq 0 1 $((PORT_COUNT-1)) ); do
            $DIR/tmp/usb_hub/acroname.py --port $P --disable
        done
        sleep 1

        $DIR/tmp/usb_hub/acroname.py --port $M --enable

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

        # Run just one test to be as quick as possible
        if [[ $NMTEST ==  *gsm_hub_simple ]]; then
            GSM_TESTS='gsm_create_default_connection'
        else
            # Run the full set of tests on the 1st modem.
            if [ $M == 0 ]; then
                GSM_TESTS_ALL='
                gsm_create_assisted_connection
                gsm_create_default_connection
                gsm_disconnect
                gsm_create_one_minute_ping
                gsm_mtu
                gsm_route_metric
                gsm_load_from_file
                gsm_connectivity_check
                '
                # gsm_up_up
                # gsm_up_down_up

                GSM_TESTS=$GSM_TESTS_ALL
            else
                GSM_TESTS='
                gsm_create_default_connection
                gsm_disconnect
                gsm_create_one_minute_ping
                gsm_mtu
                '
                # gsm_up_up
                # gsm_up_down_up

            fi
        fi

        for T in $GSM_TESTS; do
            runtest $T $M || RC=1
            cat /tmp/report.html >> /tmp/report_$NMTEST.html

            # Adding sleep 10 just to make tests more stable
            sleep 10
        done
    done

    return $RC
}  # test_modems_usb_hub
