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
mkdir -p /var/www/html/results/
echo "PASS" > /var/www/html/results/RESULT

echo "WILL RUN:"
echo $@

# For all tests
for test in $@; do
    echo "RUNING $test"
    # Start watchdog. Default is 10m
    timer=$(grep -w $test testmapper.txt | awk 'BEGIN { FS = "," } ; {print $5}')
    if [ "$timer" == "" ]; then
        timer="10m"
    fi

    # Start test itself with timeout
    export TEST="NetworkManager_Test$counter"_"$test"
    timeout $timer $(grep $test testmapper.txt |awk '{print $3,$4}'); rc=$?

    if [ $rc -ne 0 ]; then
        # Overal result is FAIL
        echo "FAIL" > /var/www/html/results/RESULT
        # Move reports to /var/www/html/results/ and add FAIL prefix
        mv /tmp/report_NetworkManager_Test$counter"_"$test.html /var/www/html/results/FAIL-Test$counter"_"$test.html
        failures+=($test)
        systemctl restart NetworkManager
        nmcli con up id testeth0
    else
        # Move reports to /var/www/html/results/
        mv /tmp/report_NetworkManager_Test$counter"_"$test.html /var/www/html/results/Test$counter"_"$test.html
    fi

    # Restore selinux context of files to allow browsing
    restorecon /var/www/html/results/*
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
cd /var/www/html/results
tar -czf Test_results-$(NetworkManager --version).tar.gz  *

exit $rc
