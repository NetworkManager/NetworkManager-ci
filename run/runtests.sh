# Exit immediately if compilation failed
if [ -e /tmp/nm_compilation_failed ]; then
    exit 1
fi

# restart is done after install
#systemctl restart NetworkManager
#sleep 5

# Add fail, skip, pass, and test counter variables
cnt=0
fail=()
skip=()
pass=()

#to make run/runtest.sh return 77 on skip
export CENTOS_CI=1

# Overal result is PASS
# This can be used as a test result indicator
mkdir -p /tmp/results/
echo "WILL RUN:"
echo $@
echo "Starting time:" $(date)

# For all tests
for test in $@; do
    echo "_______________________________"
    echo "RUNNING $test"
    counter=$(printf "%04d\n" $cnt)

    # Start watchdog. Default is 10m
    timer=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "timeout:" | awk -F: '{print $2}')
    if [ "$timer" == "" ]; then
        timer="10m"
    fi

    # Start test itself with timeout
    if [ -z "$MACHINE_ID" ]; then
      export TEST="NetworkManager-ci_Test${counter}_$test"
    else
      export TEST="NetworkManager-ci-M${MACHINE_ID}_Test${counter}_$test"
    fi
    cmd=$(sed -n "/- $test:/,/ - /p" mapper.yaml | grep -e "run:" | awk -F: '{print $2}')
    if [ "$cmd" == "" ] ; then
        cmd="run/./runtest.sh $test"
    fi
    timeout $timer $cmd; rc=$?
    echo "Finished at:" $(date)

    result="/tmp/results/"

    if [ $rc = 77 ]; then
        skip+=($test)
    elif [ $rc = 0 ]; then
        pass+=($test)
    else
        # Overal result is FAIL
        result=/tmp/results/FAIL-report_$TEST.html
        fail+=($test)
        # This should not be neeed, we do not have it in RHEL/Fedora testing
        #systemctl restart NetworkManager
        #nmcli con up id testeth0
    fi
    mv /tmp/report_$TEST.html $result
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
echo "${#pass[@]}" > /tmp/results/summary.txt
echo "${#fail[@]}" >> /tmp/results/summary.txt
echo "${#skip[@]}" >> /tmp/results/summary.txt
echo "${fail[@]}" >> /tmp/results/summary.txt
echo "${skip[@]}" >> /tmp/results/summary.txt
exit $rc
