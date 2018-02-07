#! /usr/bin/python3
import sys
import argparse
import requests
from requests_kerberos import HTTPKerberosAuth, OPTIONAL
from bs4 import BeautifulSoup
import operator
import pickle
import kerberos
import logging

# logging.basicConfig(level=logging.DEBUG)


HTML_STYLE = """
           <style>\n
               * { font-family:arial, sans-serif; }\n
               table, th, td { border: 1px solid #dddddd; }\n
               td { padding-left: 6px; padding-right: 6px; }\n
               td:nth-child(n+2) { text-align: right }\n
               tr:nth-child(even) { background-color: #dddddd }\n
               a:link { background-color: none; text-decoration: none; }\n
               a:hover { color: red; background-color: none; text-decoration: none; }\n
           </style>\n"""


def eprint (*args, **kwargs):
    print ("ERR: ", *args, file=sys.stderr, **kwargs)

### HTTP Connection
class HTTPConnectionError(Exception):
    """Exception raised when http connection reports a status error code.

    Attributes:
        status -- http status code
    """
    def __init__(self, status):
        self.status = status

def connect_to(url, timeout=10):
    print("Connecting to:\n  --> %s" % url)
    try:
        ca_cert = None
        if (hasattr(connect_to, "ca_cert")):
            ca_cert = connect_to.ca_cert

        # No auth
        if not (hasattr(connect_to, "auth_mode")):
            if ca_cert:
                req = requests.get (url, timeout=timeout, verify=ca_cert)
            else:
                req = requests.get (url, timeout=timeout)

            if (req.status_code == 401):
                connect_to.auth_mode = "kerb"

        # Authenticated access
        if (hasattr(connect_to, "auth_mode")):
            # Kerberos
            # NOTE: not working, will fallback to password --> TODO
            if (connect_to.auth_mode == "kerb"):
                kerberos_auth = HTTPKerberosAuth(mutual_authentication=OPTIONAL)
                if ca_cert:
                    req = requests.get (url, timeout=20, verify=ca_cert, auth=kerberos_auth)
                else:
                    req = requests.get (url, timeout=20, auth=kerberos_auth)

                if (req.status_code != 200):
                    connect_to.auth_mode = "pwd"

            # Username/Password
            if (connect_to.auth_mode == "pwd"):
                # TODO: retrieve password from input without showing it on-screen
                if not (hasattr(connect_to, "username") or hasattr(connect_to, "password")):
                    print ("Server at %s requires credential:" % url)
                    connect_to.username = input ("Username:")
                    connect_to.password = input ("Password:")

                if (connect_to.username and connect_to.password):
                    if (ca_cert):
                        req = requests.get (url, timeout=timeout, verify=ca_cert,
                                            auth=(connect_to.username, connect_to.password))
                    else:
                        req = requests.get (url, timeout=timeout,
                                            auth=(connect_to.username, connect_to.password))

        if (req.status_code != 200):
            raise HTTPConnectionError(req.status_code)

        print("  Connection successful")
        return req;

    except HTTPConnectionError as e:
        if (e.status == 401):
            err_msg = " (authentication failure)"
        else:
            err_msg = ""
        eprint ("  HTTP error: status code %d%s.\nSkipping %s." % (e.status, err_msg, url))
        return None;
    except requests.exceptions.ConnectionError:
        eprint ("  Connection error.\nSkipping %s." % url)
        return None;
    except Exception as e:
        eprint ("Unhandled error in connect_to(): (%s) [%s]" % (url, type(e)))
        raise



class Project:
    """ Representis a jenkins project, comprising several Jobs (runs).
    attributes:
        - name: job nickname that will be shown on output
        - url: link to the jenkins job main page
        - jobs: list of jobs retrieved for the current project"""

    def __init__(self, name, url, job=None):
        self.name = name
        self.url = url
        self.jobs = []
        if job:
            self.append_job(job)

    def append_job(self, job):
        self.jobs.append(job)

    def get_jobs(self):
        return self.jobs

    def retrieve_jobs(self):
        req = connect_to(self.url + "/rssAll")
        if (not req):
            eprint("Cannot retrieve the list of jobs from project %s." % self.name)
            return False

        soup = BeautifulSoup(req.text, "xml")
        for link in soup.find_all("link"):
            url = link.get("href")
            # quick check on the link to see if it's a composed url and ends with
            # a jenkins job number; this allows also to skip the initial link to
            # the main jenkins project.
            # TODO: make it a function and improve it
            url_split = url.split("/")
            if not url_split:
                continue
            while not url_split[-1]:
                url_split.pop()
            if not (url_split[-1].isdigit()):
                continue

            job = Job(url)
            self.append_job(job)

        ### TODO: check if we got at least one job
        return True


    def __html_write_header__(self, fd):
        fd.write(
            "<!DOCTYPE html>\n"
            "   <html>\n"
            "       <head>\n"
            "%s"
            "       </head>\n"
            "       <body>\n"
            "           <h1>%s</h1>\n"
            "           <p style=\"font-weight:bold\">\n"
            "               [ <a href=%s_index.html style=\"color:red\">jobs</a> ]\n"
            "               [ <a href=%s_failures.html>failures</a> ]\n"
            "           </p>\n"
            % (HTML_STYLE, self.name, self.name, self.name))

    def __html_write_jobstats__(self, fd):
        fd.write(
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Job</th>\n"
            "                   <th>Build</th>\n"
            "                   <th>Failures</th>\n"
            "                   <th>Timeouts</th>\n"
            "               </tr>\n")

        for job in self.jobs:
            if job.build_failed:
                l_build = '<td style="background:red">Failed</td>'
            else:
                l_build = "<td>Ok</td>"

            n_failures = len(job.failures)
            if n_failures > 9:
                l_failures = '<td style="background:red">%d</td>' % n_failures
            elif n_failures > 2:
                l_failures = '<td style="background:yellow">%d</td>' % n_failures
            else:
                l_failures = '<td>%d</td>' % n_failures

            fd.write(
            '               <tr><td><a href="%s">%s</a></td>%s%s<td>%d</td></tr>\n' %
                            (job.url, job.name, l_build, l_failures, job.undefined_timeouts))
        fd.write(
            "           </table>\n")

    def __html_write_footer__(self, fd):
        fd.write(
            "       </body>\n"
            "    <html>\n")

    def print_html (self, fname):
        fd = open(fname, "w")
        self.__html_write_header__(fd)
        self.__html_write_jobstats__(fd)
        self.__html_write_footer__(fd)


class Job:
    """ Represents a job run.

    Attributes:
        - name: job nickname (or the last part of the url if not specified)
        - url: url to the jenkins job
        - failures: list of the failures that happened in the job
        - build_failed: true if no results are available for the job
        - undefined_timeouts: number of the tests that failed due to timeout"""

    def __init__(self, url, name=None, failure=None):
        self.url = url
        if (name):
            self.name = name
        else:
            self.name = url[-20:]

        self.failures = []
        self.build_failed = False
        self.undefined_timeouts = 0

        if failure:
            self.append_failure(failure)

    def append_failure(self, failure):
        self.failures.append(failure)

    def retrieve_failures(self):
        req = connect_to(self.url + "testReport")
        if (not req):
            self.build_failed = True
            return

        ## TODO: check for artifacts (otherwise means the build failed)
        soup = BeautifulSoup(req.text, "lxml")

        for failure_div in soup.findAll("div", "failure-summary"):
            failure_div_split = failure_div.get("id").split("/")
            while not failure_div_split[-1]:
                failure_div_split.pop()
            test_name = failure_div_split[-1]

            # TODO: some checks/safer retrieval of the test name?
            # we need to sanitize the UNDEFINED_timeout one...
            if (test_name[:17] == "UNDEFINED_timeout"):
                self.undefined_timeouts += 1
                continue

            failure = Failure.add_failure(test_name, self)
            self.append_failure(failure)


def failure_number(failure):
    return len(failure.jobs)

def failure_last(failure):
    return failure.last

class Failure:
    """ Reprents test failures. New failures should be created calling the
    class method 'add_failure': in this way, the class will ensure to have
    just one instance per failure.
    Linkage of the jobs back to the failure instance should be done by the
    client.

    Class attributes:
        failures -- list containing all the failures retrieved.

    Class methods:
        add_failure -- will return the failure from the failures list if
                       present: otherwise will create a new Failure object and
                       add it to the failures list before returning it.
    Instance Attributes:
        name - the name of the test
        permanent - true if the failure happens always, false if it is sporadic
        last - how many days passed from the last occurrence of the failure
        score - [0-100] indicates the severity of the failure (TODO - not filled yet)
        jobs - a list of the jobs in which the failure is present
    """

    failures = []

    @classmethod
    def add_failure(cls, name, job):
        for failure in cls.failures:
            if failure.name == name:
                failure.append_job(job)
                return failure
        failure = Failure(name, job)
        cls.failures.append(failure)
        return failure

    @classmethod
    def save_failures(cls, fname):
        fd = open(fname, "wb")
        pickle.dump(cls.failures, fd, protocol=3)
        fd.close()

    @classmethod
    def load_failures(cls, fname):
        fd = open(fname, "rb")
        cls.failures = pickle.load(fd)
        fd.close()

    @classmethod
    def postprocess_failures(cls, all_sorted_jobs):
        for failure in cls.failures:
            failure.postprocess(all_sorted_jobs)
        cls.failures.sort(key=failure_number, reverse=True)
        cls.failures.sort(key=failure_last)

    @classmethod
    def print_html(cls, fname, project_name):
        fd = open(fname, "w")
        fd.write(
            "<!DOCTYPE html>\n"
            "   <html>\n"
            "       <head>\n"
            "%s"
            "       </head>\n"
            "       <body>\n"
            "           <h1>%s</h1>\n"
            "           <p style=\"font-weight:bold\">\n"
            "               [ <a href=%s_index.html>jobs</a> ]\n"
            "               [ <a href=%s_failures.html style=\"color:red\">failures</a> ]\n"
            "           </p>\n"
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Failure</th>\n"
            "                   <th>Kind</th>\n"
            "                   <th>Last</th>\n"
            "                   <th>Num</th>\n"
            "                   <th>Score</th>\n"
            "                   <th>Bugzilla</th>\n"
            "               </tr>\n" % (HTML_STYLE, project_name, project_name, project_name))

        for failure in cls.failures:
            if failure.permanent:
                l_perm = "Permanent"
            else:
                l_perm = "Sporadic"
            if failure.bugzilla:
                if failure.bugzilla[0] == 'h':
                    l_bugz = '<a href="%s">%s</a>' % (failure.bugzilla,
                                                      failure.bugzilla.split('=')[-1])
                else:
                    l_bugz = failure.bugzilla
            if failure.last:
                l_last = "<td>%d</td>" % failure.last
            else:
                l_last = '<td style="background:red">%d</td>' % failure.last

            fd.write(
            '               <tr>'
                                '<td><a href="#%s">%s</a></td>'
                                '<td>%s</td>'
                                '%s'
                                '<td>%d</td>'
                                '<td>%d</td>'
                                '<td>%s</td>'
                            '</tr>\n' % (failure.name, failure.name,
                                         l_perm,
                                         l_last,
                                         len(failure.jobs),
                                         failure.score,
                                         failure.bugzilla))

        fd.write(
            "           </table>\n")

        for failure in cls.failures:
            fd.write('           <hr>\n\t<h3 id="%s">%s</h3>\n' % (failure.name, failure.name))
            fd.write('           <p>\n')
            for job in failure.jobs:
                fd.write('          <a href="%s">%s</a><br>\n' % (job.url, job.name))
            fd.write('           </p>\n')

        fd.close()
       

    def __init__(self, name, job=None):
        self.name = name
        self.permanent = True
        self.last = -1
        self.score = 0
        self.bugzilla = None
        self.jobs = []
        if job:
            self.append_job(job)

    def append_job(self, job):
        self.jobs.append(job)

    def postprocess(self, job_list):
        self.last = job_list.index(self.jobs[0])
        last_failed = self.last == 0
        last_failed_switches = 0

        # permanent/sporadic
        for job in job_list:
            if job.build_failed:
                continue
            if job in self.jobs:
                if not last_failed:
                    last_failed = True
                    last_failed_switches += 1
            else:
                if last_failed:
                    last_failed = False
                    last_failed_switches += 1

        if (   (last_failed_switches > 2)
            or (len(self.jobs) == 1 and self.last)):
            self.permanent = False
        else:
            self.permanent = True

        ### TODO: search bugzilla



def save(pname, dname, data):
    fname = "%s_%s.bk" % (pname, dname)
    fd = open(fname, "wb")
    pickle.dump(data, fd, protocol=0)
    fd.close()

def process_project(name, url):
    p = Project(name, url)

    if not p.retrieve_jobs():
        return False

    for job in p.get_jobs():
        job.retrieve_failures()

    #save(name, "project", p)
    #save(name, "failures", Failure.failures)

    Failure.postprocess_failures(p.get_jobs())

    p.print_html("%s_index.html" % name)
    Failure.print_html("%s_failures.html" % name, name)


def main():
    parser = argparse.ArgumentParser(description='Summarize NetworkManager jenkins results.')
    parser.add_argument('url', help="Jenkins project url")
    parser.add_argument('--name', help="Project nickname to use in results");
    parser.add_argument('--user', help="username to access Jenkins url")
    parser.add_argument('--password', help="password to access Jenkins url")
    parser.add_argument('--ca_cert', help="file path of private CA to be used for https validation")
    args = parser.parse_args()

    if (args.user):
        connect_to.auth_mode = "pwd"
        connect_to.username = args.user
    if (args.password):
        connect_to.password = args.password
    if (args.ca_cert):
        connect_to.ca_cert = args.ca_cert
    url = args.url

    if (args.name):
        project_name = args.name
    else:
        project_name = url.split("/")[-1]

    process_project(project_name, url)


if __name__ == '__main__':
    main()

