#!/bin/bash

start_logger() {
    # redirect stdout+stderr into stdout and logger (force line buffering)
    export PYTHONUNBUFFERED=1
    # make pipes, use $TAG as $NMTEST is not defined yet
    rm -rf .tmp/{logger,tee}_${TAG}_p
    mkfifo .tmp/logger_${TAG}_p
    mkfifo .tmp/tee_${TAG}_p
    # start logger and tee processes outside main program group
    #  - will not be killed by timeout (or harness)
    setsid -f -w logger -t "runtest" < .tmp/logger_${TAG}_p &!
    LOGGER_PID=$!
    setsid -f -w stdbuf -i0 -o0 -e0 tee .tmp/logger_${TAG}_p < .tmp/tee_${TAG}_p &!
    TEE_PID=$!
    # redirect output of this shell to tee pipe
    exec > .tmp/tee_${TAG}_p 2>&1
    set -x
}

# Helper function to increment test number in testsing farm,
# return "0" for manual testing to overwrite last test report.
test_num() {
    if env | grep -q "TMT_"; then
        num=$(cat /tmp/nmci_test_num 2> /dev/null)
        printf "%04d" $((num++))
        echo "$num" > /tmp/nmci_test_num
    else
        echo "0"
    fi
}

wait_for_process_finish() {
    # do not log this, continue logging before exit and return
    set +x
    local PID="$1"
    local INTERVAL="$2"
    local RETRIES="$3"
    for i in $(seq 1 "$RETRIES"); do
        if kill -0 "$PID" &> /dev/null; then
            sleep "$INTERVAL"
            continue
        fi
        echo "Process $PID finished"
        set -x
        return
    done
    echo "Killing $PID with SIGKILL"
    kill -9 "$PID"
    set -x
}

report_result() {
    echo "Report results"
    # If RESULT is unset, process was killed by watchdog (or CTRL-c)
    [ -z $RESULT ] && RESULT=FAIL
    # If we have running harness.py then upload logs
    if ps aux | grep -v grep | grep -q harness.py; then
        # check for empty file: -s means nonempty
        if [ -s "$NMTEST_REPORT" ]; then
            timeout 1m rstrnt-report-result -o "$NMTEST_REPORT" "$NMTEST" "$RESULT"
        else
            echo "removing empty report file"
            rm -f "$NMTEST_REPORT"
            timeout 1m rstrnt-report-result -o "" "$NMTEST" "$RESULT"
        fi
    fi
    # If we are in testing farm
    if env | grep -q TMT_; then
        mkdir -p $TMT_PLAN_DATA/reports
        timeout 1m rstrnt-report-result -o "" "$NMTEST" "$RESULT"
        # add FAIL_ prefix in case of fail
        dst="$NMTEST_REPORT_NAME_PASS"
        if [ "$RESULT" == FAIL ]; then
            dst="$NMTEST_REPORT_NAME_FAIL"
        fi
        if [ -s "$NMTEST_REPORT" ]; then
            cp "$NMTEST_REPORT" "$TMT_PLAN_DATA/reports/$dst"
            cp "$NMTEST_REPORT" "$TMT_TEST_DATA/$dst"
        fi
    fi
    cp -f "$NMTEST_REPORT" ./.tmp/last_report.html
    echo "Testsuite time elapsed: $(date -u -d "$TS seconds ago" +%H:%M:%S)"
    echo "------------ Test result: $RESULT ------------"
}

finish_runtest() {
    # do not execute again - EXIT is executed with SIGINT and SIGTERM
    trap - EXIT SIGINT SIGTERM
    # Executed on clean run as well as on watchdog kill (or CTRL-c)
    # Behave handles cleanups internally, we just have to wait for PID
    echo "Wait for behave to finish"
    wait_for_process_finish "$BEHAVE_PID" 0.1 100
    # When behave is finished, upload logs
    report_result
    # Cleanup logger
    echo "Stop logging processes and remove pipes"
    kill $LOGGER_PID $TEE_PID
    rm -rf .tmp/{logger,tee}"_${TAG}_p"
    exit $rc
}

trap finish_runtest EXIT SIGINT SIGTERM

die() {
    printf '%s\n' "$*"
    exit 1
}


array_contains() {
    local tag="$1"
    shift

    for a; do
        if [ "$tag" = "$a" ]; then
            return 0
        fi
    done
    return 1
}

get_rhel_compose() {
    for file in /etc/yum.repos.d/repofile.repo /etc/yum.repos.d/beaker-BaseOS.repo; do
        if [ -f "$file" ]; then
            grep -F -e baseurl= -e BaseOS "$file" 2>/dev/null | grep -o "RHEL-[^/]*" | tail -n 1
            return
        fi
    done
    grep DISTRO= /etc/motd | grep -o "RHEL-[^/]*"
}

export -f get_rhel_compose

get_timestamp() {
    if [ -f /tmp/nm_tests_timestamp ]; then
      cat /tmp/nm_tests_timestamp
    else
      date +%s | tee /tmp/nm_tests_timestamp
    fi
}

running_NM_version_check() {
    local running_ver
    local dist_ver
    running_ver="$(busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager Version | tr -d 's "')"
    dist_ver="$(NetworkManager -V)"
    if [[ "$dist_ver" != "$running_ver"* ]]; then
        echo -e '\n\033[0;31mWARNING!!! Running NetworkManager version differs from installed package
Did you forgot to restart after install?\033[0m\n'
    fi
}

version_control() {
    local out
    local rc
    local A

    out="$("$DIR/nmci/helpers/version_control.py" "$1")"
    rc=$?
    if [ $rc -eq 0 ]; then
        local IFS=$'\n'
        A=( $out )
        FEATURE_FILE="${A[0]}"
        TEST_NAME="${A[1]}"
        ALL_TAGS=("${A[@]:2}")
        return 0
    elif [ $rc -eq 77 ]; then
        unset FEATURE_FILE
        unset TEST_NAME
        unset ALL_TAGS
        return 77
    else
        die "Invalid test name $1: $out"
    fi
}

call_behave() {
    local FEATURE_FILE="$1"
    shift
    local NMTEST_REPORT="$1"
    shift

    local a
    local TAGS
    TAGS=()
    for a; do
        TAGS+=("-t" "$a")
    done

    rc=1
    # start behave in background to remember PID
    python3l -m behave "$FEATURE_FILE" "${TAGS[@]}" --no-capture --no-skipped -f html-pretty -o "$NMTEST_REPORT" -f plain &
    BEHAVE_PID=$!
    wait $BEHAVE_PID
}

###############################################################################

function gsm_hub_runtest () {
    local TEST_NAME=${1:?"Error: test name is missing."}
    local MODEM_INDEX=${2:?"Error: modem index is missing."}
    local rc=0
    local VERSION_CONTROL
    local ALL_TAGS

    version_control "$TEST_NAME"
    rc=$?

    [ -n "$FEATURE_FILE" ] || return 0

    call_behave "$FEATURE_FILE" /tmp/report.html "${ALL_TAGS[@]}"
    rc=$?

    # Create unique IDs of embedded sections in the HTML report.
    # Allow joining of two or more reports with collapsible sections.
    sed -i -e "s/embed_\([0-9]\+\)/embed_${MODEM_INDEX}_${TEST_NAME}_\1/g" /tmp/report.html
    return $rc
}

function gsm_hub_test() {
    # Number of modems that are plugged into Acroname USB hub.
    local MODEM_COUNT=5
    # Number of ports Acroname USB hub has.
    local PORT_COUNT=8
    # Return code
    local rc=0

    touch /tmp/usb_hub
    echo "USB_HUB" > /tmp/report_$NMTEST.html
    for M in $(seq 1 1 $((MODEM_COUNT-1)) ); do

        for P in $(seq 0 1 $((PORT_COUNT-1)) ); do
            $DIR/prepare/acroname.py --port $P --disable
        done

        # systemctl stop ModemManager
        # modprobe -r qmi_wwan
        # modprobe qmi_wwan
        # sleep 2
        # systemctl restart ModemManager

        $DIR/prepare/acroname.py --port $M --enable

        # wait up to 300s for device to appear in NM
        sh $DIR/prepare/initialize_modem.sh


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
            gsm_hub_runtest $T $M || rc=1
            cat /tmp/report.html >> /tmp/report_$NMTEST.html

            # Adding sleep 10 just to make tests more stable
            sleep 10
        done
    done

    return $rc
}

###############################################################################

# if $1 starts with @, cut it away
TAG="${1#@}"

start_logger

echo "Running test $TAG"

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
DIR=$(pwd)

TS=$(get_timestamp)

# set TEST variable for version_control script
if [ -z "$TEST" ]; then
    echo "setting test name to NetworkManager_Test0_$TAG"
    NMTEST="NetworkManager-ci_Test$(test_num)_$TAG"
elif ! [ "$TEST" == "sanity-tests" ]; then
    NMTEST="$TEST"
fi

if [ -z "$NMTEST" ]; then
    echo "cannot set NMTEST var"
    exit 128
fi

rm -f "$DIR/.tmp/nmci-random-seed"

. $DIR/prepare/envsetup.sh
( configure_environment "$TAG" ) ; conf_rc=$?
if [ $conf_rc != 0 ]; then
    if ps aux|grep -v grep| grep -q harness.py; then
        timeout 2m rstrnt-report-result -o "" "$NMTEST" FAIL
    fi
    cat /tmp/nmcli_general
    exit $conf_rc
fi

export COLUMNS="1024"

NMTEST_REPORT="/tmp/report_$NMTEST.html"
# Used in testing-farm, shorten as much as possible to avoid ellipsis in http dir listing
NMTEST_REPORT_NAME_PASS="${NMTEST#NetworkManager-ci_Test}.html"
NMTEST_REPORT_NAME_FAIL="FAIL_${NMTEST_REPORT_NAME_PASS}"

LOG_CURSOR=$(journalctl --lines=0 --show-cursor |awk '/^-- cursor:/ {print "--after-cursor="$NF; exit}')

version_control "$NMTEST"
rc=$?
if [ -n "$FEATURE_FILE" ]; then
    if [[ "$TEST_NAME" == gsm_hub* ]];then
        # Test all modems on USB hub with 8 ports.
        gsm_hub_test
        rc=$?
    else
        # Test nmtui and nmcli
        echo "Running  $NMTEST  with tags '${ALL_TAGS[@]}'"
        call_behave "$FEATURE_FILE" "$NMTEST_REPORT" "${ALL_TAGS[@]}"
        rc=$?
    fi
    [ "$rc" = 0 -a -f /tmp/nmci_test_skipped ] && rc=77
    rm /tmp/nmci_test_skipped
    if array_contains xfail "${ALL_TAGS[@]}"; then
        if [ "$rc" = 0 ]; then
            rc=1
        elif [ "$rc" != 77 ]; then
            rc=0
        fi
    elif array_contains may_fail "${ALL_TAGS[@]}"; then
        if [ "$rc" != 77 ]; then
            rc=0
        fi
    fi
fi

if [ $rc -eq 0 ]; then
    RESULT="PASS"
elif [ $rc -eq 77 ]; then
    RESULT="SKIP"
    if [ "$CENTOS_CI" != 1 ]; then
      rc=0
    fi
else
    RESULT="FAIL"
fi

# If we FAILED and no report, dump journal to report
if [ "$RESULT" = "FAIL" -a ! -s "$NMTEST_REPORT" ]; then
    (
        echo -e "No report generated, dumping NM journal log\n\n"
        echo "<pre>"
        journalctl _SYSTEMD_UNIT=NetworkManager.service + \
                   SYSLOG_IDENTIFIER=runtest + \
                   SYSLOG_IDENTIFIER=nmci \
                   --no-pager -o cat "$LOG_CURSOR" | \
          sed 's/</\&lt;/g;s/>/\&gt;/g'
        echo "</pre>"
    ) > "$NMTEST_REPORT"
fi

running_NM_version_check