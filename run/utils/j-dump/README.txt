#############
# j-dump.py #
#############

The j-dump.py script is used to collect and summarize in a convenient way
jenkins automated jobs running NetworkManager-ci.

j-dump collects and summarizes the results of a Jenkins job processing the last
completed builds. It retrieves the data using the jenkins APIs.
The summary is presented in two html files:
$JOBNAME_builds.html
$JOBNAME_failures.html

$JOBNAME_builds.html: lists the builds found and processed, reporting for each one:
- 'Id': build id with a link to the related jenkins build.
- 'Date': date when the job build was started on Jenkins.
- 'Status': status of the Jenkins build. If results cannot be collected, the status
  will be reported as "FAILURE" with a black background.
- 'Failures': indicates the number of tests that have failed in the build.

$JOBNAME_failures.html: is a summary of the failures collected from all the
builds listed in $JOBNAME_index.html. It shows each test that failed in at least
one of the considered builds. The main table contains in each row:
- 'Failure': the name of the test that failed.
- 'Kind' [Permanent|Sporadic]: if the test failed only in consecutive builds it is
  reported as "Permanent", otherwise is "Sporadic" (meaning that may not fail always).
- 'Last': indicates how many "jobs ago" the test failed for the last time. So, '0' means
  it failed in the last job run.
- 'Num': the number of builds that had the test failing.
- 'Score': the severity of the failure (not implemented yet).
- 'Bugzilla': link to the bugzilla tracking the issue if any (not implemented yet).

-- USAGE --
j-dump.py [--name NAME] [--user USER] [--password PASSWORD] [--ca-cert CA_CERT] URL JOB

URL is the jenkins url and JOB is the job to process.
Execute "j-dump.py" without options or passing "-h" to get the command line
help. 

Available options are:
--name NAME: the name of the project. It will be used also for the name of the
             generated html files. If not provided, the trailing part of the
             jenkins url will be used.

--user USER / --password PASSWORD: used if the jenkins URL needs authentication. You can also
                                   use Jenkins token API instead of the password.

--ca-cert CA_CERT: it will allow to check against a private trusted CA for https connections.
  If an invalid certificate is found, https would otherwise fail.
  Passing 'disabled' as --ca-cert argument will skip https check.
  Currently the option is ignored.
 
--max_builds <int>: the max number of builds to process from the specified job. The default value
                    is '50'. A value of '0' means to process all the available builds.

