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
echo "PASS" > /tmp/results/RESULT

echo "WILL RUN:"
echo $@

# For all tests
for test in $@; do
    echo "RUNING $test"
    counter=$(printf "%03d\n" $cnt)

    # Start watchdog. Default is 10m
    timer=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "timeout:" | awk -F: '{print $2}')
    if [ "$timer" == "" ]; then
        timer="10m"
    fi

    # Start test itself with timeout
    export TEST="NetworkManager_Test$counter"_"$test"
    cmd=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "run:" | awk -F: '{print $2}')
    if [ "$cmd" == "" ] ; then
        cmd="nmcli/./runtest.sh $test"
    fi
    timeout $timer $cmd; rc=$?

    if [ $rc -ne 0 ]; then
        # Overal result is FAIL
        echo "FAIL" > /tmp/results/RESULT
        mv /tmp/report_NetworkManager_Test$counter"_"$test.html /tmp/results/FAIL-Test$counter"_"$test.html
        fail+=($test)
        systemctl restart NetworkManager
        nmcli con up id testeth0
    else
        # File has a non zero size (was no skipped)
        if [ -s /tmp/report_NetworkManager_Test$counter"_"$test.html ]; then
            mv /tmp/report_NetworkManager_Test$counter"_"$test.html /tmp/results/Test$counter"_"$test.html
            pass+=($test)
        else
            skip+=($test)
            rm -rf /tmp/report_NetworkManager_Test$counter"_"$test.html
        fi
    fi
    ((cnt++))

done

rc=1
echo "--------------------------------------------"
echo "** ${#pass[@]} TESTS PASSED"
if [ ${#pass[@]} -ne 0 ]; then
    rc=0
fi
if [ ${#fail[@]} -ne 0 ]; then
    echo "** ${#fail[@]} TESTS FAILED"
    echo "--------------------------------------------"
    for f in "${fail[@]}"; do
        echo "$f"
    done
fi
if [ ${#skip[@]} -ne 0 ]; then
    echo "** ${#skip[@]} TESTS FAILED"
    echo "--------------------------------------------"
    for s in "${skip[@]}"; do
        echo "$s"
    done
fi
echo "${#pass[@]}" > /tmp/summary.txt
echo "${#fail[@]}" >> /tmp/summary.txt
echo "${#skip[@]}" >> /tmp/summary.txt

exit $rc
