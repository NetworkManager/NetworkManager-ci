# Exit immediately if compilation failed
if [ -e /tmp/nm_compilation_failed ]; then
    exit 1
fi

systemctl restart NetworkManager
sleep 5

cd NetworkManager-ci

# Add fail, skip, pass, and test counter variables
cnt=0
fail=()
skip=()
pass=()

# Overal result is PASS
# This can be used as a test result indicator
mkdir -p /tmp/results/
echo "WILL RUN:"
echo $@

# For all tests
for test in $@; do
    echo "RUNING $test"
    counter=$(printf "%04d\n" $cnt)

    # Start watchdog. Default is 10m
    timer=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "timeout:" | awk -F: '{print $2}')
    if [ "$timer" == "" ]; then
        timer="10m"
    fi

    # Start test itself with timeout
    export TEST="NetworkManager-ci_Test$counter"_"$test"
    cmd=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "run:" | awk -F: '{print $2}')
    if [ "$cmd" == "" ] ; then
        cmd="nmcli/./runtest.sh $test"
    fi
    timeout $timer $cmd; rc=$?

    if [ $rc -ne 0 ]; then
        # Overal result is FAIL
        mv /tmp/report_$TEST.html /tmp/results/FAIL-report_$TEST.html
        fail+=($test)
        systemctl restart NetworkManager
        nmcli con up id testeth0
    else
        # File has a non zero size (was no skipped)
        if [ -s /tmp/report_$TEST.html ]; then
            mv /tmp/report_$TEST.html /tmp/results/
            pass+=($test)
        else
            skip+=($test)
            rm -rf /tmp/report_$TEST.html
        fi
    fi
    ((cnt++))

done

rc=1
echo "--------------------------------------------"
echo "** ${#pass[@]} TESTS PASSED"
if [ ${#pass[@]} -ne 0 ]; then
    rc=0
    echo "PASS" > /tmp/results/RESULT.txt
fi
if [ ${#fail[@]} -ne 0 ]; then
    echo "--------------------------------------------"
    echo "** ${#fail[@]} TESTS FAILED"
    for f in "${fail[@]}"; do
        echo "$f"
    done
    rc=1
    echo "FAIL" > /tmp/results/RESULT.txt
fi
if [ ${#skip[@]} -ne 0 ]; then
    echo "--------------------------------------------"
    echo "** ${#skip[@]} TESTS SKIPPED"
    for s in "${skip[@]}"; do
        echo "$s"
    done
fi
echo "${#pass[@]}" > /tmp/summary.txt
echo "${#fail[@]}" >> /tmp/summary.txt
echo "${#skip[@]}" >> /tmp/summary.txt

exit $rc
