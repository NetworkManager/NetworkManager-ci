#! /usr/bin/python3
import argparse
import pickle
import sys
import traceback

import requests
import jenkinsapi
from jenkinsapi.jenkins import Jenkins

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


def eprint(*args, **kwargs):
    print("ERR: ", *args, file=sys.stderr, **kwargs)


def dprint(*args, **kwargs):
    print("   :", *args, **kwargs)


class BuildCreationError(Exception):

    def __init__(self, msg):
        self.msg = msg


class Job:
    """ Represents a Jenkins job, comprising several builds (runs).
    attributes:
        - server: connection to the jenkins server
        - name: relative link to the jenkins job main page
        - nick: job nickname that will be shown on output"""

    def __init__(self, server, name, nick):
        self.server = server
        self.name = name
        self.nick = nick
        self.connection = None
        self.builds = []
        self.failures = []

    def connect(self):
        try:
            self.connection = self.server.get_job(self.name)

        except jenkinsapi.custom_exceptions.UnknownJob:
            eprint("Job '%s' not found - skip" % self.name)
            return False
        except jenkinsapi.custom_exceptions.JenkinsAPIException:
            eprint("Cannot retrieve job '%s' - skip" % self.name)
            return False

        return True

    def get_builds(self):
        return self.builds

    def append_build(self, build):
        self.builds.append(build)

    def builds_retrieve(self, max_builds):
        i = 0
        for build_id in self.connection.get_build_ids():
            try:
                build = Build(build_id, self.connection)
            except BuildCreationError as error:
                dprint("Build #{:d} - {:s} - skipped".format(build_id, error.msg))
                continue
            except Exception as e:
                eprint("Build #{:d} - exception [{:s}] - skipped\n".format(build_id, str(type(e))))
                dprint("---- traceback ----")
                traceback.print_exc(file=sys.stderr)
                dprint("----   -----   ----")
                continue
            dprint("Build #{:d} - processed".format(build_id))

            self.append_build(build)
            if i == max_builds:
                break
            i += 1

        if len(self.builds) == 0:
            return False

        return True

    def __html_write_header__(self, fd, file_builds, file_failures):
        fd.write(
            "<!DOCTYPE html>\n"
            "   <html>\n"
            "       <head>\n"
            "%s"
            "       </head>\n"
            "       <body>\n"
            "           <h1>%s</h1>\n"
            "           <p style=\"font-weight:bold\">\n"
            "               [ <a href=%s style=\"color:red\">builds</a> ]\n"
            "               [ <a href=%s>failures</a> ]\n"
            "           </p>\n"
            % (HTML_STYLE, self.nick, file_builds, file_failures))

    def __html_write_buildstats__(self, fd):
        fd.write(
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Id</th>\n"
            "                   <th>Date</th>\n"
            "                   <th>Status</th>\n"
            "                   <th>Failures</th>\n"
            "               </tr>\n")

        for build in self.builds:
            if build.failed:
                l_build = '<td style="background:black;color:white;font-weight:bold">' \
                          '{:s}</td>'.format(build.status)
                l_failures = '<td>--</td>'
            else:
                if build.status in ('FAILURE', 'NOT_BUILT'):
                    l_build = '<td style="color:red;font-weight:bold">'
                elif build.status in 'SUCCESS':
                    l_build = '<td style="color:green;font-weight:bold">'
                else:
                    l_build = "<td>"
                l_build += '%s</td>' % build.status

                n_failures = len(build.failures)
                if n_failures > 9:
                    l_failures = '<td style="background:red">%d</td>' % n_failures
                elif n_failures > 2:
                    l_failures = '<td style="background:yellow">%d</td>' % n_failures
                else:
                    l_failures = '<td>%d</td>' % n_failures

            fd.write(
                '               <tr>'
                '<td><a href="%s">%s</a></td>'
                '<td>%s</td>'
                '%s%s</tr>\n' %
                (build.url, build.id,
                 build.timestamp.ctime(),
                 l_build, l_failures))
        fd.write(
            "           </table>\n")

    @staticmethod
    def __html_write_footer__(fd):
        fd.write(
            "       </body>\n"
            "    <html>\n")

    def print_html(self, file_name):
        file_builds = "{:s}_builds.html".format(file_name)
        file_failures = "{:s}_failures.html".format(file_name)

        fd = open(file_builds, "w")
        self.__html_write_header__(fd, file_builds, file_failures)
        self.__html_write_buildstats__(fd)
        self.__html_write_footer__(fd)


class Build:
    """ Represents a job's run.

    Attributes:
        - build_id: build id
        - job: jenkins job to which the build belongs
        - build: jenkins build obj
        - status: jenkins' build status ('SUCCESS', 'UNSTABLE', 'FAILURE', 'NOT_BUILT', 'ABORTED')
        - timestamp
        - failures: list of the failures that happened in the build"""

    def __init__(self, build_id, job):

        self.id = build_id
        self.job = job
        self.build = job.get_build(build_id)
        self.url = self.build.baseurl
        self.status = self.build.get_status()
        self.failed = False
        self.timestamp = self.build.get_timestamp()
        self.failures = []

        if self.build.has_resultset():
            results = self.build.get_resultset()
        else:
            if not self.status:
                if self.build.is_running():
                    raise BuildCreationError("build is still running")
                else:
                    raise BuildCreationError("build has no status nor results")

            # no results but failure: check if we have at least the artifacts
            if self.status == 'FAILURE':
                for artifact in self.build.get_artifact_dict():
                    split_artifact = artifact.split("FAIL")
                    if len(split_artifact) < 2:
                        continue
                    # let's check that the failure name in the artifact is as expected or skip...
                    # something like "FAIL-Test252_ipv6_honor_ip_order.html" (We already stripped "FAIL")
                    split_artifact = split_artifact[1].split("_", 1)
                    if len(split_artifact) != 2:
                        # what happened??
                        eprint("Unexpected artifact '{:s}': skip...".format(artifact))
                        continue

                    split_artifact = split_artifact[1].split(".")
                    if len(split_artifact) != 2:
                        # no .html suffix?? not sure, skip...
                        eprint("No .html suffix in artifact '{:s}': skip...".format(artifact))
                        continue
                    failure = Failure.add_failure(split_artifact[0], self)
                    self.append_failure(failure)
                # we got the artifacts, so we are done
                if len(self.failures):
                    return

            if self.status == 'FAILURE' or self.status == 'NOT_BUILT' or self.status == 'ABORTED':
                self.failed = True
            return

        self.name = results.name

        for result in results.iteritems():
            # item states: 'PASSED', 'SKIPPED', 'REGRESSION', 'FAILED', ??
            if result[1].status == 'REGRESSION' or result[1].status == 'FAILED':
                failure = Failure.add_failure(result[1].name, self)
                self.append_failure(failure)

    def append_failure(self, failure):
        self.failures.append(failure)


def failure_number(failure):
    return len(failure.builds)


def failure_last(failure):
    return failure.last


class Failure:
    """ Represents test failures. New failures should be created calling the
    class method 'add_failure': in this way, the class will ensure to have
    just one instance per failure.
    Linkage of the builds back to the failure instance should be done by the
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
        builds - a list of the builds in which the failure is present
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
    def postprocess_failures(cls, all_sorted_builds):
        if not all_sorted_builds:
            return

        for failure in cls.failures:
            failure.post_process(all_sorted_builds)
        cls.failures.sort(key=failure_number, reverse=True)
        cls.failures.sort(key=failure_last)

    @classmethod
    def print_html(cls, file_name, job_nick):
        file_failures = "{:s}_failures.html".format(file_name)
        file_builds = "{:s}_builds.html".format(file_name)

        fd = open(file_failures, "w")
        fd.write(
            "<!DOCTYPE html>\n"
            "   <html>\n"
            "       <head>\n"
            "%s"
            "       </head>\n"
            "       <body>\n"
            "           <h1>%s</h1>\n"
            "           <p style=\"font-weight:bold\">\n"
            "               [ <a href=%s>builds</a> ]\n"
            "               [ <a href=%s style=\"color:red\">failures</a> ]\n"
            "           </p>\n"
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Failure</th>\n"
            "                   <th>Kind</th>\n"
            "                   <th>Last</th>\n"
            "                   <th>Num</th>\n"
            "                   <th>Score</th>\n"
            "                   <th>Bugzilla</th>\n"
            "               </tr>\n" % (HTML_STYLE, job_nick, file_builds, file_failures))

        for failure in cls.failures:
            if failure.permanent:
                l_perm = "Permanent"
            else:
                l_perm = "Sporadic"
            # if failure.bugzilla:
            #     if failure.bugzilla[0] == 'h':
            #         l_bugz = '<a href="%s">%s</a>' % (failure.bugzilla,
            #                                           failure.bugzilla.split('=')[-1])
            #     else:
            #         l_bugz = failure.bugzilla
            if failure.last:
                l_last = "<td>{:d}</td>".format(failure.last)
            else:
                l_last = '<td style="background:red">{:d}</td>'.format(failure.last)

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
                             len(failure.builds),
                             failure.score,
                             failure.bugzilla))

        fd.write(
            "           </table>\n")

        for failure in cls.failures:
            fd.write('           <hr>\n\t<h3 id="%s">%s</h3>\n' % (failure.name, failure.name))
            fd.write('           <p>\n')
            for build in failure.builds:
                fd.write('          <a target="_blank" href="%s">%d</a><br>\n' % (build.url, build.id))
            fd.write('           </p>\n')

        fd.close()

    def __init__(self, name, build=None):
        self.name = name
        self.permanent = True
        self.last = -1
        self.score = 0
        self.bugzilla = None
        # builds tracking will need some changes to support multiple jobs
        self.builds = []
        if build:
            self.builds.append(build)

    def append_job(self, job):
        self.builds.append(job)

    def post_process(self, build_list):
        if not self.builds:
            return

        self.last = build_list.index(self.builds[0])
        last_failed = self.last == 0
        last_failed_switches = 0

        # permanent/sporadic
        for build in build_list:
            if build in self.builds:
                if not last_failed:
                    last_failed = True
                    last_failed_switches += 1
            else:
                if last_failed:
                    last_failed = False
                    last_failed_switches += 1

        if last_failed_switches > 2 or len(self.builds) == 1 and self.last:
            self.permanent = False
        else:
            self.permanent = True

        # TODO: search bugzilla


def save(pname, dname, data):
    fname = "%s_%s.bk" % (pname, dname)
    fd = open(fname, "wb")
    pickle.dump(data, fd, protocol=0)
    fd.close()


def process_job(server, job_name, job_nick, max_builds=50):
    job = Job(server, job_name, job_nick)

    if not job.connect():
        return False
    dprint("Processing job {:s}".format(job_name))

    if not job.builds_retrieve(max_builds):
        return False

    # save(name, "project", p)
    # save(name, "failures", Failure.failures)

    Failure.postprocess_failures(job.get_builds())

    job.print_html(job_name)
    Failure.print_html(job_name, job_nick)


def main():
    parser = argparse.ArgumentParser(description='Summarize NetworkManager jenkins results.')
    parser.add_argument('url', help="Jenkins base url")
    parser.add_argument('job', help="Jenkins job")
    parser.add_argument('--name', help="Job nickname to use in results")
    parser.add_argument('--user', help="username to access Jenkins url")
    parser.add_argument('--password', help="password to access Jenkins url")
    parser.add_argument('--token', help="Jenkins API token to access Jenkins url (use instead of password)")
    parser.add_argument('--ca_cert', help="file path of private CA to be used for https validation or 'disabled'")
    parser.add_argument('--max_builds', help="maximum number of builds considered for the job")
    args = parser.parse_args()

    user = None
    password = None
    url = args.url

    # TODO: accept multiple jobs
    job_name = args.job

    if args.token or args.password:
        if not args.user:
            eprint("Missing user: quit.")
            sys.exit(1)
        user = args.user
        password = args.password

    try:
        server = Jenkins(args.url, user, password)
    except requests.exceptions.ConnectionError as e:
        eprint("Connection to {:s} failed:\n\t {:s}".format(url, str(e.args[0])))
        sys.exit(-1)
    except requests.exceptions.HTTPError as e:
        eprint("Connection to {:s} failed:\n\t {:s}".format(url, str(e.args[0])))
        sys.exit(-1)
    dprint("Connected to {:s}".format(args.url))

    if args.name:
        job_nick = args.name
    else:
        job_nick = job_name

    if args.max_builds:
        max_builds = args.max_builds
    else:
        max_builds = 50

    process_job(server, job_name, job_nick, max_builds)


if __name__ == '__main__':
    main()
