#############
# j-dump.py #
#############

The j-dump.py script is used to collect and summarize in a convenient way
jenkins automated jobs running NetworkManager-ci.

j-dump collects and summarize the results from the last ran jobs, retrieved
from the rss feed of the project page.
It will output the results in html format, generating two files:
$PROJECTNAME_index.html
$PROJECTNAME_failures.html

$PROJECTNAME_index.html: lists the jobs found and processed, and reports for
each one:
- Job: link to the jenkins job
- Build [OK|Failed]: indicates if the setup process (NM build & machine setup)
  was succesful
- Failures [0-9999]: indicates the number of tests that failed in the job
- Timeouts [0-9999]: the number of test that were stopped as taking too much
  time

$PROJECTNAME_failures.html: is a summary of the failures collected from all the
jobs listed in PROJECTNAME_index.html. It shows each test that failed in at least
one of the considered jobs. The main table contains in each row:
- Failure: the name of the test that failed
- Kind [Permanent|Sporadic]: if the test failed in the past but it is not
  failing anymore it is considered "Sporadic", otherwise "Permanent"
- Last: indicates how many "jobs ago" the test failed for the last time. 0 means
  it failed in the last job run.
- Num: the number of jobs in which the test failed
- Score: the severity of the failure (not used yet, WiP)
- Bugzilla: link to the bugzilla tracking the issue if any (not used yet, WiP)

-- USAGE --
j-dump.py [--name NAME] [--user USER] [--password PASSWORD] [--ca-cert CA_CERT] URL

URL is the jenkins url of the project from which data should be collected.
Execute "j-dump.py" without options or passing "-h" to get the command line
help. 

Available options are:
--name NAME: the name of the project. It will be used also for the name of the
             generated html files. If not provided, the trailing part of the
             jenkins url will be used.

--user USER / --password PASSWORD: used if the jenkins URL needs authentication.
  If authentication is required but no user/password have been provided, j-dump
  will prompt for them.

--ca-cert CA_CERT: it will allow to check against a private trusted CA for https connections.
  If an invalid certificate is found, https would otherwise fail.
  Passing 'disabled' as --ca-cert argument will skip https check.
 
--max_jobs <int>: by default only the job reported in the RSS feed of the project are parsed
  (which defaults to 10 jobs). By specifying the "max_jobs" parameter, j-python will start
  from the RSS feed as usual, but will try then to retrieve more jobs till the max_jobs value
  is matched.
