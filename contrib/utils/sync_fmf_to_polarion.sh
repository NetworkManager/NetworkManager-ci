#!/bin/bash
# Make sure ~/.pylero is having correct credentials
# install script in crontab:
# 0 * * * * cd ~/NetworkManager-ci; contrib/utils/sync_fmf_to_polarion.sh --since last
# 30 * * * * cd ~/NetworkManager-ci; contrib/utils/sync_fmf_to_polarion.sh --retry-failed

pwd | grep -q -e "NetworkManager-ci$" -e "NM-ci$" || { echo Not in NetworkManager-ci directory; exit 1; }

git pull >> .tmp/git_pull_log

if [ "$1" == "--since" ]; then
    since="$2"
fi

if [ "$since" == "last" ]; then
    since="$(cat .tmp/last_fmf_to_polarion_sync)"
    git rev-parse HEAD > .tmp/last_fmf_to_polarion_sync
fi

if [ "$1" == "--retry-failed" ]; then
    failed=1
fi

# Get list of tests to export - either from git changes or retry failed ones
if [ -n "$since" ]; then
    tests="$(git log -p $since.. -- tests.fmf | grep '^+' | grep -o '/.*:' | sed s/:// | sort | uniq)"
elif [ -n "$failed" ]; then
    tests="$(cat .tmp/polarion_failed_tests)"
    echo -n > .tmp/polarion_failed_tests
fi

# Loop through tests and export them
for test in $tests; do
    date >> .tmp/polarion_sync_log
    tmt test export --how polarion --project-id RHELNST --create --bugzilla --no-duplicate --ignore-git-validation /tests$test$ >> .tmp/polarion_sync_log || echo $test >> .tmp/polarion_failed_tests
done

# Check for missing links and commit changes
./update_tests_fmf.py

diff="$(git diff tests.fmf)"
if [ -n "$diff" ]; then
    git add tests.fmf
    git commit -m "fmf: update polarion links" --author "NetworkManager-ci <$USER+nmcibot@redhat.com>"
    # push, and reset in case of fail and try luck next time
    git push || git reset origin/main -- tests.fmf
fi