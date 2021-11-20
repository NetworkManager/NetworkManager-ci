#! /usr/bin/python3
import argparse
import pickle
import sys
import os
import traceback
from subprocess import call
import jsonpickle
import math

import requests
import urllib
import jenkinsapi
from jenkinsapi.jenkins import Jenkins
#logging.basicConfig(level=logging.DEBUG)

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
    print("ERR: ", *args, file=sys.stderr, flush=True, **kwargs)


def dprint(*args, **kwargs):
    print("   :", *args, flush=True, **kwargs)


class BuildCreationError(Exception):

    def __init__(self, msg):
        self.msg = msg


class Job:
    """ Represents a Jenkins job, comprising several builds (runs).
    attributes:
        - server: connection to the jenkins server
        - name: relative link to the jenkins job main page
        - nick: job nickname that will be shown on output
        - builds: list of builds
        - failures: dictionary of failures (key is failure name)
        - cache_dir/cache_file: where to store the json dump if builds and failures"""

    def __init__(self, server, name, nick, cache_dir_prefix="./cache/"):
        self.server = server
        self.name = name
        self.nick = nick
        self.connection = None
        self.builds = []
        self.failures = {}
        self.tags = {}
        self.tests = {}
        self.state = {}
        self.cache_dir = cache_dir_prefix
        if not os.path.isdir(self.cache_dir):
            call("mkdir -p %s" % (self.cache_dir), shell=True)
        self.cache_file = self.cache_dir + self.name + ".json"

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
        return [build for build in self.builds if build.status != "RUNNING"]

    def get_failures(self):
        return list(self.failures.values())

    def add_build(self, build):
        self.builds.append(build)
        self.process_tests_and_tags(build)

    def add_failure(self, failure_name, build, artifact_url=None):
        if failure_name in self.failures:
            failure = self.failures[failure_name]
        else:
            failure = Failure(failure_name)
            self.failures[failure_name] = failure
        failure.add_build(build)
        if artifact_url:
            failure.add_artifact(build.id, artifact_url)
        build.add_failure(failure_name, failure)

    def process_tests_and_tags(self, build):
        tests, tags = self.process_taskout_log(build)

        build.tests_passed, build.tests_failed, build.tests_skipped = 0, 0, 0

        if len(tests) == 0:
            return

        statuses = []
        for test_name, test_stats in tests.items():
            if test_name in self.tests:
                self.tests[test_name]["builds"][build.id] = test_stats
            else:
                self.tests[test_name] = {"builds": {build.id: test_stats}}
            statuses.append(test_stats["status"])

        for tag_name, tag_stats in tags.items():
            if tag_name in self.tags:
                self.tags[tag_name]["builds"][build.id] = tag_stats
            else:
                self.tags[tag_name] = {"builds": {build.id: tag_stats}}

        build.tests_passed = statuses.count("PASS")
        build.tests_failed = statuses.count("FAIL")
        build.tests_skipped = statuses.count("SKIP")

    def process_taskout_log(self, build):
        log = self.get_taskout_log(build)
        tests = {}
        tags = {}
        when = "bs"
        test_time = 0
        bs_time = 0
        as_time = 0
        tags_as_time = 0
        tags_bs_time = 0
        test_name = ""
        for line in log.split("\n"):
            line = line.strip(" ")
            if "runtest.sh 'Running test " in line:
                test_name = line.split("runtest.sh 'Running test ")[1][:-1]
                when = "bs"
                test_time = 0
                bs_time = 0
                as_time = 0
                tags_as_time = 0
                tags_bs_time = 0
            if line.startswith("@") and " in " in line and line.endswith("s"):
                tag_name = line.split(" ")[0].lstrip("@")
                tag_time = str_to_time(line.split(" ")[-1])
                if tag_name in tags:
                    tags[tag_name].append({when: tag_time})
                else:
                    tags[tag_name] = [{when: tag_time}]
                if when == "bs":
                    tags_bs_time += tag_time
                else:
                    tags_as_time += tag_time
            if "before_scenario ... " in line and " in " in line and line.endswith("s"):
                bs_time = str_to_time(line.split(" ")[-1]) - tags_bs_time
                when = "as"
            if "after_scenario ... " in line and " in " in line and line.endswith("s"):
                as_time = str_to_time(line.split(" ")[-1]) - tags_as_time
            if line.startswith("Took "):
                test_time = str_to_time(line.split(" ")[-1])
            if "echo '------------ Test result: " in line:
                status = line.split("Test result: ")[1].split(" ")[0]
                tests[test_name] = {"time": test_time, "as": as_time, "bs": bs_time,
                                    "tags_as": tags_as_time, "tags_bs": tags_bs_time,
                                    "status": status}
        return tests, tags

    def get_taskout_log(self, build):
        log = ""
        for url in [
            "/artifact/artifacts/taskout.log",
            "/artifact/artifacts/runner.txt",
            "/consoleText",
        ]:
            req = urllib.request.Request(build.url + url)
            try:
                with urllib.request.urlopen(req) as rq:
                    log = rq.read().decode("utf-8", errors='ignore')
                break
            except urllib.error.URLError:
                log = ""
        return log

    def remove_build(self, build_id):
        self.builds = [build for build in self.builds if build.id != build_id]
        for failure in self.failures.values():
            failure.builds = [build for build in failure.builds if build.id != build_id]
            if build_id in failure.artifact_urls.keys():
                failure.artifact_urls.pop(build_id)
        for test in self.tests.values():
            if build_id in test["builds"]:
                test["builds"].pop(build_id)
        for tag in self.tags.values():
            if build_id in tag["builds"]:
                tag["builds"].pop(build_id)

    def load_cache(self, build_ids):
        if not os.path.isfile(self.cache_file):
            return
        with open(self.cache_file, "r") as fd:
            data_json = fd.read()
        data = jsonpickle.decode(data_json, keys=True)
        self.builds, self.failures, self.tests, self.tags, self.state = data

        for build in self.builds:
            if build.status == "RUNNING":
                self.remove_build(build.id)

        cached_build_ids = [build.id for build in self.builds]
        sorted(cached_build_ids, reverse=True)

        self.remove_build(cached_build_ids[0])

        for build_id in cached_build_ids:
            if build_id not in build_ids:
                self.remove_build(build_id)
        for failure_name in list(self.failures.keys()):
            if len(self.failures[failure_name].builds) == 0:
                self.failures.pop(failure_name)

    def save_cache(self):
        data = (self.builds, self.failures, self.tests, self.tags, self.stats)
        data_json = jsonpickle.encode(data, keys=True)
        with open(self.cache_file, "w") as fd:
            fd.write(data_json)

        # for faster JS site loading
        data = (self.builds, self.stats)
        data_json = jsonpickle.encode(data, keys=True)
        with open(self.cache_file.replace(".json", "-builds.json"), "w") as fd:
            fd.write(data_json)

        for _, test_stats in self.tests.items():
            test_stats.pop("builds")
        data = (self.tests, self.stats)
        data_json = jsonpickle.encode(data, keys=True)
        with open(self.cache_file.replace(".json", "-tests.json"), "w") as fd:
            fd.write(data_json)

        for _, tag_stats in self.tags.items():
            tag_stats.pop("builds")
        data = (self.tags, self.stats)
        data_json = jsonpickle.encode(data, keys=True)
        with open(self.cache_file.replace(".json", "-tags.json"), "w") as fd:
            fd.write(data_json)

    def builds_retrieve(self, max_builds):
        build_ids = self.connection.get_build_ids()
        build_ids = list(build_ids)[:max_builds]
        # do not cache the first build in list, because its status may change even when job not running
        self.load_cache(build_ids)
        cache_build_ids = [build.id for build in self.builds]
        for build_id in build_ids:
            if build_id in cache_build_ids:
                dprint("Build #{:d} - cached".format(build_id))
                continue
            try:
                build = Build(build_id, self)
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

            self.add_build(build)

        self.builds.sort(key=lambda build: build.id, reverse=True)

        if len(self.builds) == 0:
            return False

        for test_name, test_stats in self.tests.items():
            num = len(test_stats["builds"])
            if num == 0:
                continue
            builds_stats = list(test_stats["builds"].items())
            builds_stats.sort(key=lambda x: -x[0])
            builds_stats = [b[1] for b in builds_stats]
            test_stats["num"] = num
            test_stats["num_pass"] = len([t for t in builds_stats if t["status"] == "PASS"])
            test_stats["num_fail"] = len([t for t in builds_stats if t["status"] == "FAIL"])
            test_stats["num_skip"] = len([t for t in builds_stats if t["status"] == "SKIP"])
            test_stats["time_avg"] = sum([t["time"] for t in builds_stats])/num
            test_stats["time_last"] = builds_stats[0]["time"]
            test_stats["time_min"] = min([t["time"] for t in builds_stats])
            test_stats["time_max"] = max([t["time"] for t in builds_stats])
            test_stats["time_dev"] = math.sqrt(sum([t["time"]**2 for t in builds_stats])/num)
            test_stats["bs_avg"] = sum([t["bs"] for t in builds_stats])/num
            test_stats["bs_last"] = builds_stats[0]["bs"]
            test_stats["bs_min"] = min([t["bs"] for t in builds_stats])
            test_stats["bs_max"] = max([t["bs"] for t in builds_stats])
            test_stats["bs_dev"] = math.sqrt(sum([t["bs"]**2 for t in builds_stats])/num)
            test_stats["as_avg"] = sum([t["as"] for t in builds_stats])/num
            test_stats["as_last"] = builds_stats[0]["as"]
            test_stats["as_min"] = min([t["as"] for t in builds_stats])
            test_stats["as_max"] = max([t["as"] for t in builds_stats])
            test_stats["as_dev"] = math.sqrt(sum([t["as"]**2 for t in builds_stats])/num)
            test_stats["tags_bs_avg"] = sum([t["tags_bs"] for t in builds_stats])/num
            test_stats["tags_bs_last"] = builds_stats[0]["tags_bs"]
            test_stats["tags_bs_min"] = min([t["tags_bs"] for t in builds_stats])
            test_stats["tags_bs_max"] = max([t["tags_bs"] for t in builds_stats])
            test_stats["tags_bs_dev"] = math.sqrt(sum([t["tags_bs"]**2 for t in builds_stats])/num)
            test_stats["tags_as_avg"] = sum([t["tags_as"] for t in builds_stats])/num
            test_stats["tags_as_last"] = builds_stats[0]["tags_as"]
            test_stats["tags_as_min"] = min([t["tags_as"] for t in builds_stats])
            test_stats["tags_as_max"] = max([t["tags_as"] for t in builds_stats])
            test_stats["tags_as_dev"] = math.sqrt(sum([t["tags_as"]**2 for t in builds_stats])/num)

        for tag_name, tag_stats in self.tags.items():
            bs_times = [t["bs"] for tt in tag_stats["builds"].values()
                        for t in tt if "bs" in t]
            bs_num = len(bs_times)
            as_times = [t["as"] for tt in tag_stats["builds"].values()
                        for t in tt if "as" in t]
            as_num = len(as_times)
            if bs_num:
                tag_stats["bs_num"] = bs_num
                tag_stats["bs_avg"] = sum(bs_times)/bs_num
                tag_stats["bs_min"] = min(bs_times)
                tag_stats["bs_max"] = max(bs_times)
                tag_stats["bs_dev"] = math.sqrt(sum([t**2 for t in bs_times])/bs_num)
            if as_num:
                tag_stats["as_num"] = as_num
                tag_stats["as_avg"] = sum(as_times)/as_num
                tag_stats["as_min"] = min(as_times)
                tag_stats["as_max"] = max(as_times)
                tag_stats["as_dev"] = math.sqrt(sum([t**2 for t in as_times])/as_num)

        self.stats = {"last_pass": 0, "last_fail": 0, "last_skip": 0}
        self.stats["health"] = len(list(filter(lambda b: b.status == "SUCCESS", list(
            filter(lambda b: b.status != "RUNNING", self.builds))[0:5])))
        self.stats["running"] = len(list(filter(lambda b: b.status == "RUNNING", self.builds)))
        self.stats["last_status"] = "ABORTED"
        for b in self.builds:
            if b.status != "RUNNING":
                self.stats["last_status"] = b.status
                if getattr(b, "failed", False):
                    self.stats["last_status"] = "ABORTED"
                self.stats["last_pass"] = b.tests_passed
                self.stats["last_fail"] = b.tests_failed
                self.stats["last_skip"] = b.tests_skipped
                break

        return True

    def postprocess_failures(self, all_sorted_builds):
        if not all_sorted_builds:
            return

        failures = self.get_failures()

        for failure in failures:
            failure.post_process(all_sorted_builds)
        failures.sort(key=failure_number, reverse=True)
        failures.sort(key=failure_last)

        self.sorted_failures = failures

    def __html_write_header__(self, fd, file_builds, file_failures, failure=False):
        style_build = "color:red"
        style_failure = ""
        if failure:
            style_build, style_failure = style_failure, style_build

        fd.write(
            "<!DOCTYPE html>\n"
            "   <html>\n"
            "       <head>\n"
            "%s"
            "       </head>\n"
            "       <body>\n"
            "           <h1>%s</h1>\n"
            "           <p style=\"font-weight:bold\">\n"
            "               [ <a href=%s style=\"%s\">builds</a> ]\n"
            "               [ <a href=%s style=\"%s\">failures</a> ]\n"
            "           </p>\n"
            % (HTML_STYLE, self.nick, file_builds, style_build, file_failures, style_failure))

    def __html_write_buildstats__(self, fd):
        fd.write(
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Id</th>\n"
            "                   <th>Date</th>\n"
            "                   <th>Duration</th>\n"
            "                   <th>Status</th>\n"
            "                   <th>Failures</th>\n"
            "                   <th>Links</th>\n"
            "               </tr>\n")

        for build in self.builds:
            if build.failed:
                l_build = '<td style="background:black;color:white;font-weight:bold">' \
                          '{:s}</td>'.format(build.status)
                l_failures = '<td>--</td>'
            else:
                if build.status in ('FAILURE', 'NOT_BUILT'):
                    l_build = '<td style="color:red;font-weight:bold">'
                elif build.status == 'RUNNING':
                    l_build = '<td style="color:brown;font-weight:bold">'
                elif build.status == 'SUCCESS':
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
                '<td><a target="_blank" href="%s">%s</a></td>'
                '<td>%s</td>'
                '<td>%s</td>'
                '%s%s'
                '<td>%s</td>'
                '</tr>\n' %
                (artifacts_url(build), build.id,
                 build.timestamp.ctime(),
                 str(build.duration).split('.')[0],
                 l_build, l_failures,
                 build.description))
        fd.write(
            "           </table>\n")

    def __html_write_failurestats__(self, fd):
        fd.write(
            "           <table>\n"
            "               <tr>\n"
            "                   <th>Failure</th>\n"
            "                   <th>Kind</th>\n"
            "                   <th>Last</th>\n"
            "                   <th>Num</th>\n"
            "                   <th>Score</th>\n"
            "                   <th>Bugzilla</th>\n"
            "               </tr>\n")

        for failure in self.sorted_failures:
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

        for failure in self.sorted_failures:
            fd.write('           <hr>\n\t<h3 id="%s">%s</h3>\n' % (failure.name, failure.name))
            fd.write('           <p>\n')
            builds = failure.builds
            for build in builds:
                if build.id in failure.artifact_urls:
                    artifact_url = failure.artifact_urls[build.id]
                    fd.write('          <a target="_blank" href="%s">report</a> from <a href="%s">#%d</a><br>\n' %
                             (artifact_url, artifacts_url(build), build.id))
                else:
                    fd.write('          <a target="_blank" href="%s">#%d</a><br>\n' %
                             (artifacts_url(build), build.id))
            fd.write('           </p>\n')

    @staticmethod
    def __html_write_footer__(fd):
        fd.write(
            "       </body>\n"
            "    <html>\n")

    def print_html(self, file_name=None):
        if not file_name:
            file_name = self.name
        file_builds = "{:s}_builds.html".format(file_name)
        file_failures = "{:s}_failures.html".format(file_name)

        with open(file_builds, "w") as fd:
            self.__html_write_header__(fd, file_builds, file_failures)
            self.__html_write_buildstats__(fd)
            self.__html_write_footer__(fd)

        with open(file_failures, "w") as fd:
            self.__html_write_header__(fd, file_builds, file_failures)
            self.__html_write_failurestats__(fd)
            self.__html_write_footer__(fd)


class Build:
    """ Represents a job's run.

    Attributes:
        - build_id: build id
        - job: jenkins job to which the build belongs
        - url
        - status: jenkins' build status ('SUCCESS', 'UNSTABLE', 'FAILURE', 'NOT_BUILT', 'ABORTED')
        - description
        - failed: True if no test results
        - timestamp
        - failures: list of the failures that happened in the build"""

    def __init__(self, build_id, job):

        self.id = build_id
        build = job.connection.get_build(build_id)
        self.url = build.baseurl
        self.status = build.get_status()
        self.description = build.get_description() or "--"
        self.failed = False
        self.timestamp = build.get_timestamp()
        self.duration = build.get_duration()
        self.failures = {}

        if self.status == 'NOT_BUILT' or self.status == 'ABORTED':
            self.failed = True

        if build.has_resultset():
            results = build.get_resultset()
            for result in results.iteritems():
                # item states: 'PASSED', 'SKIPPED', 'REGRESSION', 'FAILED', ??
                result = result[1]
                if result.status == 'REGRESSION' or result.status == 'FAILED':
                    result_name = result.name
                    if result_name.startswith("Test"):
                        result_name = result_name.split("_", 1)[1]
                    job.add_failure(result_name, self)
            self.name = results.name
        else:
            if not self.status:
                if build.is_running():
                    self.status = "RUNNING"
                    return
                else:
                    raise BuildCreationError("build has no status nor results")

        if self.status != 'SUCCESS':
            artifacts = build.get_artifact_dict()
            # if trere is small number of artifatcs, the build failed
            if len(artifacts) < 10:
                self.failed = True
            artifacts_fails = [art for art in artifacts.keys() if "FAIL" in art]
            for artifact in artifacts_fails:
                split_artifact = artifact.split("FAIL")
                if len(split_artifact) < 2:
                    continue
                # let's check that the failure name in the artifact is as expected or skip...
                # something like "FAIL-Test252_ipv6_honor_ip_order.html" (We already stripped "FAIL")
                # or "FAIL_report_NetworkManager-ci_Test252_ipv6_honor_ip_order.html"
                split_artifact = split_artifact[1].replace(
                    r'report_NetworkManager-ci', '').strip("_-")
                if split_artifact.startswith('M'):
                    split_artifact = split_artifact[3:]
                split_artifact = split_artifact.split("_", 1)
                if len(split_artifact) != 2:
                    # what happened??
                    eprint("Unexpected artifact '{:s}': skip...".format(artifact))
                    continue

                split_artifact = split_artifact[1].split(".")
                if split_artifact[-1] != "html" and split_artifact[-1] != "log":
                    # no .html suffix?? not sure, skip...
                    eprint("No .html or .log suffix in artifact '{:s}': skip...".format(artifact))
                    continue
                failure_name = '.'.join(split_artifact[:-1])
                job.add_failure(failure_name, self, artifacts[artifact].url)

    def add_failure(self, failure_name, failure):
        self.failures[failure_name] = failure


def failure_number(failure):
    return len(failure.builds)


def failure_last(failure):
    return failure.last


class Failure:
    """ Represents test failures.

    Instance Attributes:
        name - the name of the test
        permanent - true if the failure happens always, false if it is sporadic
        last - how many days passed from the last occurrence of the failure
        score - [0-100] indicates the severity of the failure (TODO - not filled yet)
        builds - a list of the builds in which the failure is present
        artifacts_urls - url of artifact for builds
    """

    def __init__(self, name):
        self.name = name
        self.permanent = True
        self.last = -1
        self.score = 0
        self.bugzilla = None
        # builds tracking will need some changes to support multiple jobs
        self.builds = []
        self.artifact_urls = {}

    def add_build(self, build):
        if build not in self.builds:
            self.builds.append(build)

    def add_artifact(self, build_id, artifact_url):
        self.artifact_urls[build_id] = artifact_url

    def post_process(self, build_list):
        if not self.builds:
            return

        self.builds.sort(key=lambda build: build.id, reverse=True)

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


def artifacts_url(job):
    if job.status != 'RUNNING':
        if 'centos' in job.url:
            return job.url + "/artifact/"
        if 'desktopqe' in job.url:
            return job.url + "/artifact/artifacts/"
    return job.url


def process_job(server, job_name, job_nick, max_builds=50):
    job = Job(server, job_name, job_nick)

    if not job.connect():
        return False
    dprint("Processing job {:s}".format(job_name))

    if not job.builds_retrieve(max_builds):
        return False

    # save(name, "project", p)
    # save(name, "failures", Failure.failures)

    job.postprocess_failures(job.get_builds())

    job.save_cache()

    job.print_html()


def str_to_time(time_str):
    time_str = time_str.rstrip("s")
    time_split = time_str.split("m")
    if len(time_split) == 1:
        return float(time_split[0])
    else:
        return int(time_split[0])*60 + float(time_split[1])


def main():
    parser = argparse.ArgumentParser(description='Summarize NetworkManager jenkins results.')
    parser.add_argument('url', help="Jenkins base url")
    parser.add_argument('job', help="Jenkins job")
    parser.add_argument('--name', help="Job nickname to use in results")
    parser.add_argument('--user', help="username to access Jenkins url")
    parser.add_argument('--password', help="password to access Jenkins url")
    parser.add_argument(
        '--token', help="Jenkins API token to access Jenkins url (use instead of password)")
    parser.add_argument(
        '--ca_cert', help="file path of private CA to be used for https validation or 'disabled'")
    parser.add_argument('--max_builds', type=int,
                        help="maximum number of builds considered for the job")
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
