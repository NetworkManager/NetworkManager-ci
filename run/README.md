# run directory

## runtest.sh

The main script, executes single test, ensures setup/connectivity and publishes result. `test_run.sh` symlinks to this.

## runtests.sh

Executes multiple tests passed as arguments, uses `run/runtest.sh`.

## runfeature.sh

Execute given feature, retrieves testlist from `mapper.yaml` and passes it to `run/runtests.sh`.

## centos-ci

Contains configuration and executables for CentOS.

## fedora-vagrant

Vagrant setup for Fedora, currently not used.

## osci

Test lists and helper scripts for OSCI.

## publish_behave_logs

HTTP server serving history of HTML reports. More info [in this section](../README.md#accessing-reports-over-http).

## rh-str

Some old test executors.

## utils

Currently, only j-dump (nm_ci_stats) lives here.