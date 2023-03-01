#!/bin/bash

set -x

# redirect stdout+stderr into stdout and logger (force line buffering)
stdbuf -oL -eL exec &> >(tee - >(logger -t "runtest"))

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

    behave "$FEATURE_FILE" "${TAGS[@]}" --no-capture -k -f html-pretty -o "$NMTEST_REPORT" -f plain
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

logger -t $0 "Running test $TAG"

export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin"
DIR=$(pwd)

TS=$(get_timestamp)

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

. $DIR/prepare/envsetup.sh
( configure_environment "$TAG" ) ; conf_rc=$?
if [ $conf_rc != 0 ]; then
    if ps aux|grep -v grep| grep -q harness.py; then
        timeout 2m rstrnt-report-result -o "" "$NMTEST" FAIL
    fi
    cat /tmp/nmcli_general
    exit $conf_rc
fi
export_python_command

export COLUMNS="1024"

NMTEST_REPORT="/tmp/report_$NMTEST.html"

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
        logger "Running  $NMTEST  with tags '${ALL_TAGS[@]}'"
        call_behave "$FEATURE_FILE" "$NMTEST_REPORT" "${ALL_TAGS[@]}"
        rc=$?
    fi
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
    if [ "$CENTOS_CI" -ne 1 ]; then
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
        journalctl -u NetworkManager --no-pager -o cat "$LOG_CURSOR" | \
          sed 's/</\&lt;/g;s/>/\&gt;/g'
        echo "</pre>"
    ) > "$NMTEST_REPORT"
fi

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

running_NM_version_check

logger -t $0 "Test $TAG finished with result $RESULT: $rc"

cp -f "$NMTEST_REPORT" ./.tmp/last_report.html

echo "Testsuite time elapsed: $(date -u -d "$TS seconds ago" +%H:%M:%S)"
echo "------------ Test result: $RESULT ------------"
exit $rc
