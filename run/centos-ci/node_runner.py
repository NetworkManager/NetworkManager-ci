#!/usr/bin/python3
import argparse
import logging
import subprocess
import sys
import urllib.request
import gzip
import os
import yaml
import json
import traceback
import base64


from multiprocessing import Process, Pipe
from cico_gitlab_trigger import GitlabTrigger

MACHINES_NUM = 2
MACHINES_MIN_THRESHOLD = 1000


class Machine:

    def __init__(self, id, release):
        self.release = release
        self.release_num = release.split("-")[0]
        self.id = str(id)

        self.machine_list = "../machines"
        self.results = f"../results_m{self.id}"
        self.rpms_dir = "../rpms/"
        self.results_internal = "/tmp/results/"
        self.build_dir = "/root/nm-build"
        self.copr_repo_file_internal = "/etc/yum.repos.d/nm-copr.repo"
        self.ssh_options = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

        cico_out = subprocess.check_output(
                f"cico --debug node get -f value -c hostname -c comment --release {release}")
        cico_out = cico_out.strip("\n").split(" ")
        self.name = cico_out[0].strip(" \t") + ".ci.centos.org"
        self.ssid = cico_out[1].strip(" \t")
        with open(self.machine_list, "a") as mf:
            mf.write(f"{self.id}:{self.name}:{self.ssid}\n")

        self._pipe = None
        self._proc = None
        self._last_cmd_ret = None

    def done(self):
        if self.cmd_is_active():
            self.cmd_terminate()
        subprocess.run(f"cico node done {self.ssid}", shell=True, check=True)
        with open(self.machine_list) as mf:
            machines = mf.readlines()
        with open(self.machine_list, "w") as mf:
            for machine in machines:
                if not machine.startswith(f"{self.id}:"):
                    self.write(machine)

    def _run(self, cmd, shell=True, check=True, capture_output=True, *a, **kw):
        return subprocess.run(cmd, *a, shell=shell, check=check, capture_output=capture_output, **kw)

    def ssh(self, cmd):
        return self._run(f"ssh {self.ssh_options} root@{self.name} {cmd}")

    def scp_to(self, what, where, check=True):
        return self._scp(what, f"root@{self.name}:{where}", check=check)

    def scp_from(self, what, where, check=True):
        return self._scp(f"root@{self.name}:{what}", where, check=check)

    def _scp(self, what, where, check=True):
        return self._run(f"scp {self.ssh_options} -r {what} {where}", check=check)

    def cmd_async(self, cmd, *args):
        self._last_cmd_ret = None
        ret, self._pipe = Pipe()
        self._proc = Process(target=self._cmd_wrap_async(cmd, *args), args=(ret))

    def _cmd_wrap_async(self, cmd, *args):
        def _run(ret):
            try:
                rc = cmd(*args)
                ret.send(rc)
            except Exception as e:
                ret.send(e)
        return _run

    def cmd_wait(self):
        if self._proc is not None:
            self._proc.wait()
            return self._cmd_wait_pipe()
            self._proc = None
            self._pipe = None
            return self._last_cmd_ret
        return None

    def cmd_terminate(self):
        if self._proc is not None:
            self._proc.terminate()
            self._proc = None
            self._pipe = None

    def _cmd_wait_pipe(self):
        if self._pipe is not None:
            rc = self._pipe.recv()
            if isinstance(rc, Exception):
                print(str(rc))
                traceback.print_tb(rc.__traceback__)
                self._last_cmd_ret = False
            elif isinstance(rc, subprocess.CompletedProcess):
                if rc.returncode != 0:
                    print(f"command '{rc.args}' failed with {rc.returncode}:\n")
                    if rc.stdout:
                        print(f"STDOUT:\n{rc.stdout}")
                    if rc.stderr:
                        print(f"STDERR:\n{rc.stderr}")
                    self._last_cmd_ret = False
                else:
                    self._last_cmd_ret = True
            else:
                self._last_cmd_ret = rc
            return self._last_cmd_ret
        return None

    def cmd_is_active(self):
        if self._pipe is None:
            return False
        if self._pipe.poll():
            self._cmd_wait_pipe()
            return False
        return True

    def cmd_is_failed(self):
        return self._last_cmd_status

    def prepare(self):
        # copy NetworkManager-ci repo (already checked out at correct commit)
        self.scp_to(".", ":")
        # execute envsetup - with stock NM package, will update later, should not matter
        self.ssh("cd NetworkManager-ci\\; bash prepare/envsetup.sh setup first_test_setup")
        return True

    def prepare_async(self):
        self.cmd_async(self.prepare)

    def build(self, refspec, mr="custom", repo=""):
        self._run("mkdir -p ../rpms/")
        # remove NM packages
        self.ssh("rpm -ea --nodeps $(rpm -qa | grep NetworkManager)")
        # workaround
        self.ssh("yum -y install https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-1.7-5.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-devel-1.7-5.el8.x86_64.rpm")
        self.ssh("yum -y install crda make")
        # Add some extra repos
        epel_url = "https://dl.fedoraproject.org/pub/epel/"
        rpm = f"epel-release-latest-{self.release_num}.noarch.rpm"
        self.ssh(f"dnf -y install {epel_url}{rpm}")
        # For some reason names can differ, so enable both powertools
        self.ssh("yum install -y 'dnf-command(config-manager)'")
        self.ssh("yum config-manager --set-enabled PowerTools")
        self.ssh("yum config-manager --set-enabled powertools")
        # Enable build deps for NM
        self.ssh("yum -y copr enable nmstate/nm-build-deps")
        self.ssh("yum -y install crda NetworkManager-team \
                        NetworkManager-ppp NetworkManager-wifi \
                        NetworkManager-adsl NetworkManager-ovs \
                        NetworkManager-tui NetworkManager-wwan \
                        NetworkManager-bluetooth NetworkManager-libnm-devel \
                        --skip-broken")

        logging.debug(f"Building from refspec id {refspec} of repo '{repo}'")
        ret = self.ssh(f"BUILD_REPO={repo} sh run/centos-ci/scripts/./build.sh {refspec} {mr}", check=False, capture_output=False)
        if ret.returncode != 0:
            logging.debug("Build failed, copy config.log!")
            self.scp_from(f"{self.build_dir}/NetworkManager/config.log", "..")
            return False
        else:
            logging.debug("tree of build dir:\n" + self.ssh(f"find {self.build_dir} | grep -F .rpm").stdout)
            # self.scp_from(f"{self.build_dir}/NetworkManager/*", self.rpms_dir)
        return True

    def build_async(self, refspec):
        self.cmd_async(self.build, refspec)

    def install_NM(self, source="copr"):
        if source == "copr":
            self.scp_to(self.copr_repo_file, self.copr_repo_file_internal)
            self.ssh("yum -y install --repo nm-copr-repo NetworkManager*")
        else:
            self.scp_to(self.rpms_dir, ".")
            self.ssh("yum -y install ./rpms/NetworkManager*.rpm")
        self.ssh("systemctl restart NetworkManager")
        return True

    def install_NM_async(self, source=None):
        self.cmd_async(self.install_NM, source)

    def runtests(self, tests):
        tests = " ".join(tests)
        # command after redirection operators ('|', '>', '&&') execute on jenkins machine,
        # unless escaped as "echo \\> file', so runtest.out and journal are saved to jenkins directly
        ret = self.ssh(f"cd NetworkManager-ci\\; MACHINE_ID={self.id} bash run/centos-ci/scripts/runtest.sh {tests} &> {self.results}/runtest.out", check=False)
        self.ssh(f"journalctl -b --no-pager -o short-monotonic --all \\| bzip2 --best > ../journal.m{self.id}.log.bz2")
        # copy artefacts
        self.scp_from(f"{self.results_internal}/*.*", self.results)
        return ret

    def runtests_async(self, tests):
        self.cmd_async(self.runtests, tests)


class Mapper:
    def __init__(self, mapper_file="mapper.yaml", gitlab=None):
        try:
            self.mapper = yaml.safe_load(mapper_file)
        except Exception as e:
            print(f"Unable to process mapper file '{mapper_file}':{e}\n")
            # TODO maybe force exit here, as mapper is probably malformed in MR!
            self.mapper = None
        self.gitlab = gitlab
        self.default_exlude = ['dcb', 'wifi', 'infiniband', 'wol', 'sriov', 'gsm']
        self.m_num = MACHINES_NUM
        self.m_thresh = MACHINES_MIN_THRESHOLD

    def _parse_features_string(self, features):
        if 'best' in features:
            features = None
            if self.gitlab is not None:
                features = [f for f in self.gitlab.changed_features if f not in self.default_exlude]
            if features is None or features == []:
                features = ["all"]
            logging.debug("running best effort execution to shorten time: %s" % features)
            return features

        elif not features or 'all' in features:
            return ["all"]
        else:
            return [x.strip() for x in features.split(',')]

    def get_tests_for_machines(self, features):
        if not self.mapper:
            return ["pass"]

        features = self._parse_features_string(features)
        times, tests = self._get_tests_and_times_for_features(features)
        m_tests = []
        m_time = []

        total_time = sum(times.values())
        average_time = total_time / self.m_num

        for i in range(self.m_num):
            m_tests.append([])
            m_time.append(0)

        for f in sorted(times.keys()):
            for i in range(self.m_num):
                new_time = m_time[i] + times[f]
                if new_time < average_time or new_time < self.m_thresh or i+1 == self.m_num:
                    m_time[i] = new_time
                    m_tests.extend(tests[f])
                    break

        while [] in m_tests:
            m_tests.remove([])

        if len(m_tests) == 0:
            logging.debug("No tests to run, running just '@pass'")
            m_tests = ["pass"]

        return m_tests

    def _get_tests_and_times_for_features(self, features=["all"]):
        if not self.mapper:
            return None

        times = {}
        tests = {}
        for test in self.mapper['testmapper']['default']:
            for test_name in test:
                f = test[test_name]['feature']
                if f in self.default_exlude:
                    continue
                if f not in features and "all" not in features:
                    continue
                t = 10
                if 'timeout' in test[test_name]:
                    t = int(test[test_name]['timeout'][:-1])
                if f in times:
                    times[f] += t
                    tests[f].append(test_name)
                else:
                    times[f] = t
                    tests[f] = [test_name]
        return times, tests


class Runner:
    def __init__(self):
        self.mapper = Mapper
        self.machines = []
        self.build_machine = None
        self.copr_repo_file = 'nm_copr_repo'
        self.phase = ""
        self.results_common = "../"

    def _abort(self, msg=""):
        if self.gitlab:
            self.gitlab.set_pipeline('canceled')
        if self.builder:
            self.builder.cmd_terminate()
        for m in self.machines:
            m.cmd_terminate()
        logging.debug("Aborting job (exitting with 2).")
        if msg:
            logging.debug(f"Reason: {msg}")
        sys.exit(2)

    def _get_gitlab(self, trigger_data, gl_token):
        if not trigger_data or gl_token:
            return None

        # hide it to /tmp, which is not visible in Workspace
        with open("/tmp/python-gitlab.cfg", "w") as cfg:
            cfg.write('[global]\n')
            cfg.write('default = gitlab.freedesktop.org\n')
            cfg.write('ssl_verify = false\n')
            cfg.write('timeout = 30\n')
            cfg.write('[gitlab.freedesktop.org]\n')
            cfg.write('url = https://gitlab.freedesktop.org\n')
            cfg.write('private_token = %s\n' % gl_token)
            cfg.write("\n")

        content = base64.b64decode(trigger_data).decode('utf-8').strip()
        data = json.loads(content)
        logging.debug(data)
        gitlab_trigger = GitlabTrigger(data, ["/tmp/python-gitlab.cfg"])
        return gitlab_trigger

    def _generate_gitlab_message(self):
        self.exit_code = 0
        machine_lines = []
        failed_tests = ""
        for m in self.machines:
            if not os.path.isfile(f"{m.results}/RESULT.txt"):
                self.exit_code = 1
                continue
            with open(f"{m.results}/RESULT.txt") as rf:
                machine_lines.append(f"Machine {m.id} failed, no result stats retrieved!")
                lines = rf.read().strip("\n").split("\n")
            if len(lines) != 4:
                machine_lines.append(f"Machine {m.id}: unexpected status file:" + " ".join(lines))
                self.exit_code = 1
                continue
            m_status = "passed"
            if lines[1] != "0" or (lines[0] == "0" and lines[2] == "0"):
                m_status = "failed"
                self.exit_code = 1
            machine_lines.append(f"Machine {m.id} {m_status}: Passed: {lines[0]}, Failed: {lines[1]}, Skipped: {lines[2]}.")
            failed_tests += " " + lines[3]
            failed_tests.strip(" ")

        status = "UNSTABLE: Some tests failed"
        if self.exit_code != 0:
            status = "STABLE: All tests passed!"

        self._gitlab_message = f"{self.build_url}\n\n" + \
            f"\n\nResult: {status}" + \
            "\n\n".join(machine_lines) + \
            f"\n\nExecuted on: CentOS {self.release}" + \
            f"\n\nFailed tests: {failed_tests}"

    def _post_results(self):
        if self.gitlab:
            if self.gitlab.repository == "NetworkManager-ci":
                try:
                    self.gitlab.play_commit_job()
                except Exception:
                    pass
            self.gitlab.post_commit_comment(self._gitlab_message)

    def _generate_junit(self, results_dir):
        logging.debug("Generate JUNIT")

        failed = []
        passed = []
        for f in os.listdir(results_dir):
            if not f.endswith(".html"):
                continue
            f = f.split('.html')[0]
            if f.startswith('FAIL-'):
                f = f.replace('FAIL-', '', 1)
                failed.append(f)
            else:
                passed.append(f)

        import xml.etree.ElementTree as ET
        root = ET.ElementTree()
        testsuite = ET.Element('testsuite', tests=str(len(passed) + len(failed)))
        for test in passed:
            name = test[test.find("_Test")+10:]
            testcase = ET.Element('testcase', classname="tests", name=name)
            system_out = ET.Element('system-out')
            system_out.text = f"LOG:\n{self.build_url}/artifact/{test}.html"
            testcase.append(system_out)
            testsuite.append(testcase)
        for test in failed:
            name = test[test.find("_Test")+10:]
            testcase = ET.Element('testcase', classname="tests", name=name)
            failure = ET.Element('failure')
            failure.text = f"Error\nLOG:\n{self.build_url}/artifact/FAIL-{test}.html"
            testcase.append(failure)
            testsuite.append(testcase)
        root._setroot(testsuite)
        root.write(f'{results_dir}/junit.xml')
        self.exit_code = 0
        if len(failed):
            self.exit_code = 1
        logging.debug("JUNIT Done")

    def parse_args(self):
        logging.basicConfig(level=logging.DEBUG)
        logging.debug("reading params")
        parser = argparse.ArgumentParser()
        parser.add_argument('-t', '--test_branch', default="master")
        parser.add_argument('-c', '--code_refspec', default=None)
        parser.add_argument('-f', '--features', default="all")
        parser.add_argument('-b', '--build_id')
        parser.add_argument('-g', '--gitlab_token')
        parser.add_argument('-d', '--trigger_data')
        parser.add_argument('-r', '--nm_repo',
                            default="https://gitlab.freedesktop.org/NetworkManager/NetworkManager/")
        parser.add_argument('-v', '--os_version', default="c8s")
        parser.add_argument('-D', '--do_not_touch_NM', action="store_true", default=False)

        args = parser.parse_args()

        self.test_branch = args.test_branch
        logging.debug(self.test_branch)
        self.refspec = args.code_refspec
        if args.do_not_touch_NM is True:
            self.refspec = None
        logging.debug(f"NM_REFSPEC: {self.refspec}")
        self.features = args.features
        logging.debug(f"FEATURES: {self.features}")
        if args.build_id:
            self.build_url = args.build_id
        self.repo = args.nm_repo
        self.release = args.os_version
        self.release_num = self.release.split("-")[0]

        self.gitlab = None
        self.mr = "custom"
        if args.gitlab_token:
            gl_token = args.gitlab_token
        if args.trigger_data:
            trigger_data = args.trigger_data
            self.gitlab = self._get_gitlab(trigger_data, gl_token)
        if self.gitlab is not None:
            if self.gitlab.repository == 'NetworkManager':
                self.mr = f"mr{self.gitlab.merge_request_id}"

        self._check_if_copr_possible()

    def _check_if_copr_possible(self):
        self.copr_repo = False
        if not self.nm_repo or self.nm_repo == "https://gitlab.freedesktop.org/NetworkManager/NetworkManager/":
            if self.refspec == "main":
                self.copr_repo = "NetworkManager-main-debug"
            elif self.refspec == "nm-1-36":
                self.copr_repo = "NetworkManager-1.36-debug"
            elif self.refspec == "nm-1-34":
                self.copr_repo = "NetworkManager-1.34-debug"
            elif self.refspec == "nm-1-32":
                self.copr_repo = "NetworkManager-1.32-debug"
            elif self.refspec == "nm-1-30":
                self.copr_repo = "NetworkManager-1.30-debug"
            elif self.refspec == "nm-1-28":
                self.copr_repo = "NetworkManager-CI-1.28-git"
            elif self.refspec == "nm-1-26":
                self.copr_repo = "NetworkManager-CI-1.26-git"

            if self.copr_repo:
                copr_host = "https://copr-be.cloud.fedoraproject.org"
                copr_dirs = "results/networkmanager"
                centos_dir = f"centos-stream-{self.release_num}-x86_64"
                self.copr_baseurl = f"{copr_host}/{copr_dirs}/{self.copr_repo}/{centos_dir}/"

    def check_last_copr_build(self):
        copr_log = "backend.log.gz"
        build_list_cmd = f"curl -s {self.copr_baseurl} \
                | grep -o \"<a href=[\\\"\\\'][0-9]*-NetworkManager\" \
                | sort -r | grep -o \"[0-9]*-NetworkManager\""

        out = subprocess.check_output(build_list_cmd, shell=True)
        build_list = out.decode('utf-8').strip(" \n").split("\n")
        if len(build_list) == 0:
            self._abort(f"No builds found in copr: {self.copr_repo}")

        failed = False
        for build in build_list[:2]:
            backend_url = f"{self.copr_baseurl}/{build}/{copr_log}"
            try:
                logging.debug(f"Opening {backend_url}")
                back = urllib.request.urlopen(backend_url)
            except Exception as e:
                logging.debug("Trying the last but one as current one probably running")
                if not failed:
                    failed = True
                    continue
                else:
                    self._abort(f"Unable to retrieve copr builds: {e}")

        with gzip.open(back, 'r') as f:
            readfile = f.read().decode('utf-8')
            if 'Worker failed build' in readfile:
                self._abort("Latests copr build failed!")

    def wait_for_machines(self, abort_on_fail=True):
        build_machine = []
        if self.build_machine is not None:
            build_machine.append(self.build_machine)
        for m in self.machines + build_machine:
            m.cmd_wait()
            if m.cmd_is_failed():
                self._abort(f"Failed {self.phase} on machine {m.id}.")

    def prepare_machines(self):
        self.phase = "prepare"
        if self.gitlab:
            self.gitlab.set_pipeline('running')

        self.tests = self.mapper.get_tests_for_machines(self.features)
        machines_num = len(self.tests)
        for i in range(machines_num):
            m = Machine(i, self.release)
            self.machines.append(m)
            m.prepare_async()

    def build(self):
        if self.copr_repo:
            self.check_last_copr_build()

            with open(self.copr_repo_file, "w") as cfg:
                cfg.write('[nm-copr-repo]\n')
                cfg.write('name=nm-copr-repo\n')
                cfg.write(f'baseurl={self.copr_baseurl}\n')
                cfg.write('enable=1\n')
                cfg.write('gpgcheck=0\n')
                cfg.write('skip_if_unavailable=0\n')
                cfg.write('sslverify=0\n')
                cfg.write("\n")
            cfg.close()

            # tell machines where to search for repo file
            for m in self.machines:
                m.copr_repo_file = self.copr_repo_file
        else:
            self.builder = Machine("builder", self.release)
            self.builder.build_async(self.refspec, self.mr, self.repo)

    def install_NM_on_machines(self):
        # if we are here, build_machine succeeded, no longer needed
        if self.build_machine is not None:
            self.build_machine.done()
        self.phase = "install NM"
        src = "rpms"
        if self.copr_repo:
            src = "copr"
        for m in self.machines:
            m.install_NM_async(src)

    def run_tests_on_machines(self):
        self.phase = "runtests"
        for m in self.machines:
            m.runtest_async(self.tests[m.id])

    def merge_machines_results(self):
        for m in self.machines:
            # m._run is short for subprocess.run()
            m._run(f"mv {m.results_dir}/*.html {self.results_common}")
        # this computes exit_code
        self._generate_gitlab_message()
        self._generate_junit()

        if self.gitlab:
            if self.exit_code == 0:
                self.gitlab.set_pipeline('success')
            if self.exit_code == 1:
                self.gitlab.set_pipeline('failed')
            # should not be needed, already exited in _abort()
            if self.exit_code == 2:
                self.gitlab.set_pipeline('canceled')
            self._post_results()

        logging.debug(f"All Done. Exit with {self.exit_code}")
        sys.exit(self.exit_code)


def main():
    runner = Runner()
    runner.parse_args()  # ?? do in __init__?
    runner.prepare_machines()
    runner.build()
    runner.wait_for_machines(abort_on_fail=True)
    runner.install_NM_on_machines()
    runner.wait_for_machines(abort_on_fail=True)
    runner.run_tests_on_machines()
    runner.wait_for_machines(abort_on_fail=False)
    runner.merge_machines_results()


if __name__ == "__main__":
    main()
