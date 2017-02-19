cd NetworkManager-ci

# Add failures and test counter variables
counter=0
failures=()

# Overal result is PASS
# This can be used as a test result indicator
echo "PASS" > /var/www/html/results/RESULT

# For all tests
for test in $@; do
    # Start watchdog. Default is 10m
    timer=$(grep -w $test testmapper.txt | awk 'BEGIN { FS = "," } ; {print $5}')
    if [ "$timer" == "" ]; then
        timer="10m"
    fi
    sleep $timer && kill -9 $(ps aux|grep -v grep |grep behave |awk '{print $2}') && systemctl restart NetworkManager && nmcli con up id testeth0 &

    # Start test itself.
    export TEST="NetworkManager_Test$counter"_"$test"
    $(grep $test testmapper.txt |awk '{print $3,$4}'); rc=$?

    # Kill watchdog if we have result
    kill -9 $(ps aux|grep -v grep |grep sleep |awk '{print $2}')

    if [ $rc -ne 0 ]; then
        # Overal result is FAIL
        echo "FAIL" > /var/www/html/results/RESULT
        # Move reports to /var/www/html/results/ and add FAIL prefix
        mv /tmp/report_NetworkManager_Test$counter"_"$test.html /var/www/html/results/FAIL-Test$counter"_"$test.html
        failures+=($test)

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
    echo "** FAILED TESTS"
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
tar -czf Archives-$(NetworkManager --version).tar.gz  *

echo "** RESULTS ARE AVAILABLE at http://localhost:8080/results/"
echo "** Archive available at http://localhost:8080/results/Archives-$(NetworkManager --version).tar.gz"
echo "** Run 'vagrant destroy' when you're done with results exploration."

exit $rc
