# Exit immediately if compilation failed
if [ -e /tmp/nm_compilation_failed ]; then
    exit 1
fi

systemctl restart NetworkManager
sleep 5

cd NetworkManager-ci

# Add failures and test counter variables
counter=0
failures=()

# Overal result is PASS
# This can be used as a test result indicator
mkdir -p /tmp/results/
echo "PASS" > /tmp/results/RESULT

echo "WILL RUN:"
echo $@

# For all tests
for test in $@; do
    echo "RUNING $test"
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
        failures+=($test)
        systemctl restart NetworkManager
        nmcli con up id testeth0
    else
        mv /tmp/report_NetworkManager_Test$counter"_"$test.html /tmp/results/Test$counter"_"$test.html
    fi

    counter=$((counter+1))

done

rc=1
# Write out tests failures
if [ ${#failures[@]} -ne 0 ]; then
    echo "** $counter TESTS PASSED"
    echo "--------------------------------------------"
    echo "** ${#failures[@]} TESTS FAILED"
    echo "--------------------------------------------"
    for fail in "${failures[@]}"; do
        echo "$fail"
    done
else
    rc=0
    echo "** ALL $counter TESTS PASSED!"
fi

# Create archive with results
cd /tmp/results
tar -czf Test_results-$(NetworkManager --version).tar.gz  *

exit $rc
