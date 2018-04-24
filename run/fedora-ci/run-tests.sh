RELEASE=$1

TESTS=$(cat run/fedora-ci/$RELEASE.tests)

# Add failures and test counter variables
COUNTER=0
FAILURES=()

# Overal result is PASS
# This can be used as a test result indicator
RESULTS_DIR=/tmp/artifacts
RESULTS=$RESULTS_DIR/RESULTS

echo "PASS" > $RESULTS

echo "WILL RUN:"
echo $TESTS

pwd

# For all tests
for T in $TESTS; do
    echo "RUNING $T"
    # Start watchdog. Default is 10m
    #timer=$(grep -w $test testmapper.txt | awk 'BEGIN { FS = "," } ; {print $5}')
    #if [ "$timer" == "" ]; then
    #    timer="10m"
    #fi

    # Start test itself with timeout
    #export TEST="NetworkManager_ci-Test$counter"_"$test"
    nmcli/./runtest.sh $T; rc=$?

    if [ $rc -ne 0 ]; then
        # Overal result is FAIL
        echo "FAIL" > $RESULTS
        # Move reports to /var/www/html/results/ and add FAIL prefix
        mv /tmp/report_Test$COUNTER"_"$T.html $RESULTS_DIR/FAIL-Test$COUNTER"_"$T.html
        FAILURES+=($T)
    else
        # Move reports to /var/www/html/results/
        mv /tmp/report_Test$COUNTER"_"$T.html $RESULTS_DIR/Test$COUNTER"_"$T.html
    fi

    COUNTER=$((COUNTER+1))

done

rc=1
# Write out tests failures
if [ ${#FAILURES[@]} -ne 0 ]; then
    echo "** $counter TESTS PASSED"
    echo "--------------------------------------------"
    echo "** ${#FAILURES[@]} TESTS FAILED"
    echo "--------------------------------------------"
    for FAIL in "${FAILURES[@]}"; do
        echo "$FAIL"
    done
else
    rc=0
    echo "** ALL $COUNTER TESTS PASSED!"
fi

# # Create archive with results
# cd /var/www/html/results
# tar -czf Test_results-$(NetworkManager --version).tar.gz  *

exit $rc
