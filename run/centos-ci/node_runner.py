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
import base64
import time


from multiprocessing import Process, Pipe
from cico_gitlab_trigger import GitlabTrigger

# TODO convert this to argument
MACHINES_NUM = 2
MACHINES_MIN_THRESHOLD = 1000


class Machine:

    def __init__(self, id, release):
        self.release = release
        self.release_num = release.split("-")[0]
        self.id = id

        self.machine_list = "../machines"
        self.results = f"../results_m{self.id}/"
        self._run(f"mkdir -p {self.results}")
        self.rpms_dir = "../rpms/"
        self.results_internal = "/tmp/results/"
        self.build_dir = "/root/nm-build/"
        self.rpms_build_dir = f"{self.build_dir}/NetworkManager/contrib/fedora/rpm/*/RPMS/x86_64/"
        self.copr_repo_file_internal = "/etc/yum.repos.d/nm-copr.repo"
        self.ssh_options = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

        cico_out = self._run(
                f"cico --debug node get -f value -c hostname -c comment --release {release}").stdout
        cico_out = cico_out.strip("\n").split(" ")
        self.name = cico_out[0].strip(" \t") + ".ci.centos.org"
        self.ssid = cico_out[1].strip(" \t")
        with open(self.machine_list, "a") as mf:
            mf.write(f"{self.id}:{self.name}:{self.ssid}\n")

        self._pipe = None
        self._proc = None
        self._last_cmd_ret = None

        self.cmd_async(self._setup)

    def done(self):
        if self.cmd_is_active():
            self.cmd_terminate()
        self._run(f"cico node done {self.ssid}")
        with open(self.machine_list) as mf:
            machines = mf.readlines()
        with open(self.machine_list, "w") as mf:
            for machine in machines:
                if not machine.startswith(f"{self.id}:"):
                    mf.write(machine)

    def _run(self, cmd, shell=True, check=True, capture_output=True, encoding='utf-8', verbose=False, *a, **kw):
        if capture_output:
            kw["stdout"] = subprocess.PIPE
            kw["stderr"] = subprocess.PIPE
        rc = subprocess.run(cmd, *a, shell=shell, check=check, encoding=encoding, **kw)
        logging.debug(f"executed '{cmd}': returned {rc.returncode}")
        if verbose:
            if rc.stdout:
                logging.debug(f"STDOUT:\n'{rc.stdout}")
            if rc.stderr:
                logging.debug(f"STDERR:\n'{rc.stderr}")
        return rc

    def ssh(self, cmd, check=True, verbose=False):
        return self._run(f"ssh {self.ssh_options} root@{self.name} {cmd}", check=check, verbose=verbose)

    def scp_to(self, what, where, check=True):
        return self._scp(what, f"root@{self.name}:{where}", check=check)

    def scp_from(self, what, where, check=True):
        return self._scp(f"root@{self.name}:{what}", where, check=check)

    def _scp(self, what, where, check=True):
        return self._run(f"scp -v {self.ssh_options} -r {what} {where}", check=check)

    def cmd_async(self, cmd, *args):
        self._last_cmd_ret = None
        ret, self._pipe = Pipe()
        self._proc = Process(target=self._cmd_wrap_async(cmd, *args), args=(ret,))
        self._proc.start()

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
            self._proc.join()
            self._cmd_wait_pipe()
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
            self._pipe = None
            if isinstance(rc, Exception):
                print(str(rc))
                if getattr(rc, "stdout", None):
                    print(f"STDOUT:\n{rc.stdout}")
                if getattr(rc, "stderr", None):
                    print(f"STDERR:\n{rc.stderr}")
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
        if self._proc is not None:
            if self._proc.is_alive():
                return True
            else:
                self._cmd_wait_pipe()
                self._proc = None
                return False
        return False

    def cmd_is_failed(self):
        return not self._last_cmd_ret

    def _wait_for_machine(self):
        for _ in range(12):
            if self.ssh("true", check=False).returncode == 0:
                return
        self.ssh("true")

    def _setup(self):
        self._wait_for_machine()
        self.ssh(f"mkdir -p {self.results_internal}")
        # enable repos
        self.ssh(f"dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-{self.release_num}.noarch.rpm")
        # For some reason names can differ, so enable both powertools
        self.ssh("yum install -y \\'dnf-command\\(config-manager\\)\\'")
        self.ssh("yum config-manager --set-enabled PowerTools", check=False)
        self.ssh("yum config-manager --set-enabled powertools", check=False)
        # Enable build deps for NM
        self.ssh("yum -y copr enable nmstate/nm-build-deps")
        # install NM packages
        self.ssh("yum -y install crda NetworkManager-team \
                        NetworkManager-ppp NetworkManager-wifi \
                        NetworkManager-adsl NetworkManager-ovs \
                        NetworkManager-tui NetworkManager-wwan \
                        NetworkManager-bluetooth NetworkManager-libnm-devel \
                        --skip-broken")
        return True

    def prepare(self):
        logging.debug(f"Prepare machine {self.id}")
        # enable NM debug/trace logs
        self.scp_to("contrib/conf/99-test.conf", "/etc/NetworkManager/conf.d/99-test.conf")
        self.ssh("systemctl restart NetworkManager")
        # copy NetworkManager-ci repo (already checked out at correct commit)
        self.scp_to("../NetworkManager-ci/", "")
        # execute envsetup - with stock NM package, will update later, should not matter
        self.ssh(f"cd NetworkManager-ci\\; bash -x prepare/envsetup.sh setup first_test_setup > {self.results}/envsetup.log")
        self._run(f"cp {self.results}/envsetup.log ../envsetup.m{self.id}.log")
        return True

    def prepare_async(self):
        self.cmd_async(self.prepare)

    def build(self, refspec, mr="custom", repo=""):
        self._run("mkdir -p ../rpms/")

        # el8 workarounds
        if self.release_num.startswith("8"):
            self.ssh("yum -y install https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-1.7-5.el8.x86_64.rpm https://vbenes.fedorapeople.org/NM/libndp_rhbz1933041/libndp-devel-1.7-5.el8.x86_64.rpm")
            self.ssh("yum -y install crda make")

        # remove NM packages
        self.ssh("rpm -ea --nodeps \\$\\(rpm -qa \\| grep NetworkManager\\)")

        logging.debug(f"Building from refspec id {refspec} of repo '{repo}'")
        self.scp_to("run/centos-ci/scripts/build.sh", "build.sh")
        ret = self.ssh(f"BUILD_REPO={repo} sh ./build.sh {refspec} {mr} &> {self.results}/build.log", check=False)
        if ret.returncode != 0:
            logging.debug("Build failed, copy config.log!")
            self.scp_from(f"{self.build_dir}/NetworkManager/config.log", "../", check=False)
            self._run(f"mv {self.results}/build.log ../")
            return False
        else:
            logging.debug("rpms in build dir:\n" + self.ssh(f"find {self.build_dir} | grep -F .rpm").stdout)
            # do not copy connectivity and devel packaqes
            self.ssh(f"rm -rf {self.rpms_build_dir}/*-devel*.rpm {self.rpms_build_dir}/*-connectivity-*.rpm ")
            self.scp_from(f"{self.rpms_build_dir}/*.rpm", self.rpms_dir)
        return True

    def build_async(self, refspec, mr="custom", repo=""):
        self.cmd_async(self.build, refspec, mr, repo)

    def install_NM(self, source="copr"):
        # remove NM first
        NM_rpms = self.ssh("rpm -qa \\| grep NetworkManager", check=False).stdout or ""
        delete_rpms = ""
        for rpm in NM_rpms.split("\n"):
            if "strongswan" in rpm:
                continue
            elif "openvpn" in rpm:
                continue
            elif "vpnc" in rpm:
                continue
            delete_rpms += " " + rpm
        if delete_rpms.strip():
            self.ssh(f"rpm -ea --nodeps {delete_rpms}")

        excludes = '--exclude \\"*-connectivity-*\\" --exclude \\"*-devel*\\"'
        if source == "copr":
            self.scp_to(self.copr_repo_file, self.copr_repo_file_internal)
            self.ssh(f"yum -y install --repo nm-copr-repo \\'NetworkManager*\\' {excludes}", verbose=True)
        else:
            self.ssh("mkdir -p rpms")
            self.scp_to(f"{self.rpms_dir}/*.rpm", "rpms")
            # excludes not needed here, as the rpms should not be copied from build_machine
            self.ssh("yum -y install ./rpms/NetworkManager*.rpm")
        self.ssh("systemctl restart NetworkManager")
        return True

    def install_NM_async(self, source=None):
        self.cmd_async(self.install_NM, source)

    def runtests(self, tests):
        self.tests = tests
        self.tests_num = len(tests)
        tests = " ".join(tests)
        # command after redirection operators ('|', '>', '&&') execute on jenkins machine,
        # unless escaped as "echo \\> file', so runtest.log and journal are saved to jenkins directly
        ret = self.ssh(f"cd NetworkManager-ci\\; MACHINE_ID={self.id} bash run/centos-ci/scripts/runtest.sh {tests} &> {self.results}/runtest.log", check=False)
        self.ssh(f"journalctl -b --no-pager -o short-monotonic --all \\| bzip2 --best > ../journal.m{self.id}.log.bz2")
        # copy artefacts
        self.scp_from(f"{self.results_internal}/*.*", self.results)
        self._run(f"cp {self.results}/runtest.log ../runtest.m{self.id}.log")
        return ret

    def runtests_async(self, tests):

        # set properties also here, as _async sets properties on forked object
        self.tests = tests
        self.tests_num = len(tests)

        self.cmd_async(self.runtests, tests)


class Mapper:
    def __init__(self, mapper_file="mapper.yaml", gitlab=None):
        try:
            with open(mapper_file) as mf:
                self.mapper = yaml.safe_load(mf)
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
        elif features.startswith("covering:"):
            features = features.split(":", 1)
            if len(features) != 2:
                logging.debug("Unexpected feature list, unable to parse 'covering' tests")
                return ["all"]
            # split by space here as it allows simple copy paste from failed tets list
            features[1] = features[1].split(" ")
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
                    m_tests[i].extend(tests[f])
                    break

        while [] in m_tests:
            m_tests.remove([])

        if len(m_tests) > self.m_num:
            logging.debug("Something unexpected happened with test processing: " + m_tests)
            return ["pass"]

        if len(m_tests) == 0:
            logging.debug("No tests to run, running just '@pass'")
            m_tests = ["pass"]

        return m_tests

    def _get_tests_and_times_for_features(self, features=["all"]):
        if not self.mapper:
            return None

        times = {}
        tests = {}
        all = "all" in features or "covering" in features
        for test in self.mapper['testmapper']['default']:
            for test_name in test:
                f = test[test_name]['feature']
                if f in self.default_exlude:
                    continue
                if f not in features and not all:
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
        if "covering" in features:
            # features are in form ["covering", ["test1","test2",...]]
            logging.debug("Looking-up features covering selected tests")
            times, tests = self._cover_tests(times, tests, features[1])

        return times, tests

    def _cover_tests(self, times, tests, to_cover):
        unmatched_features = list(tests.keys())
        for feature in tests:
            if len(unmatched_features) == 0:
                break
            # to_cover should be smaller than feature
            for test in to_cover:
                if test in tests[feature]:
                    to_cover.remove(test)
                    if feature in unmatched_features:
                        unmatched_features.remove(feature)

        for feature in unmatched_features:
            tests.pop(feature)
            times.pop(feature)
        logging.debug(f"Excluding: {unmatched_features}, running: {times.keys()}")
        return times, tests


class Runner:
    def __init__(self):
        self.mapper = Mapper()
        self.machines = []
        self.build_machine = None
        self.copr_repo_file = '../nm_copr_repo'
        self.phase = ""
        self.results_common = "../"
        self.exit_code = 0

    def _abort(self, msg=""):
        if self.gitlab:
            self.gitlab.set_pipeline('canceled')
            # if we have config.log, build failed
            if os.path.isfile("../build.log"):
                self._gitlab_message = f"{self.build_url}\n\nNetworkManager build from source failed!"
            else:
                self._gitlab_message = f"{self.build_url}\n\nJob unexpectedly aborted!"
            self._post_results()
        if self.build_machine:
            self.build_machine.cmd_terminate()
        for m in self.machines:
            m.cmd_terminate()
        logging.debug("Aborting job (exitting with 2).")
        if msg:
            logging.debug(f"Reason: {msg}")
        self.exit_code = 2
        sys.exit(2)

    def _set_gitlab(self, trigger_data, gl_token):
        if not trigger_data or not gl_token:
            self.gitlab = None
            logging.debug(f"trigger or token not set! token: {not not gl_token},"
                          f" data: {not not trigger_data}")
            return

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
        self.gitlab = gitlab_trigger
        if self.mapper:
            self.mapper.gitlab = gitlab_trigger

    def _generate_gitlab_message(self):
        # prevent pipeline cancel
        self.exit_code = 0
        machine_lines = []
        failed_tests = ""
        p = 0
        f = 0
        s = 0
        for m in self.machines:
            if not os.path.isfile(f"{m.results}/summary.txt"):
                machine_lines.append(f"Machine {m.id}: failed, no result stats retrieved!")
                self.exit_code = 1
                continue
            with open(f"{m.results}/summary.txt") as rf:
                lines = rf.read().strip("\n").split("\n")
            if len(lines) not in [3, 4]:
                machine_lines.append(f"Machine {m.id}: unexpected summary.txt file: {lines}")
                self.exit_code = 1
                continue
            m_status = "passed"
            if lines[1] != "0" or (lines[0] == "0" and lines[2] == "0"):
                m_status = "failed"
                self.exit_code = 1
            try:
                pm = int(lines[0])
                fm = int(lines[1])
                sm = int(lines[2])
            except Exception as e:
                machine_lines.append(f"Machine {m.id}: unexpected summary.txt file: {lines}, {e}")
                self.exit_code = 1
                continue
            p, f, s = p+pm, f+fm, s+sm
            undef = m.tests_num - (pm + fm + sm)
            if undef != 0:
                machine_lines.append(f"Machine {m.id} {m_status}: Passed: {pm}, Failed: {fm}, Skipped: {sm}, Undefined: {undef}")
                continue
            machine_lines.append(f"Machine {m.id} {m_status}: Passed: {pm}, Failed: {fm}, Skipped: {sm}")
            if len(lines) == 4:
                failed_tests += " " + lines[3]
                failed_tests.strip(" ")

        if len(self.machines) > 1:
            machine_lines.append(f"Totals: Passed: {p}, Failed {f}, Skipped {f}.")

        status = "UNSTABLE: Some tests failed"
        if self.exit_code == 0:
            status = "STABLE: All tests passed!"

        self._gitlab_message = f"{self.build_url}\n\n" + \
            f"Result: {status}\n\n" + \
            "\n\n".join(machine_lines) + \
            f"\n\nExecuted on: CentOS {self.release}"
        if failed_tests:
            self._gitlab_message += f"\n\nFailed tests: {failed_tests}"

        logging.debug("Gitlab Message:\n\n" + self._gitlab_message)

    def _post_results(self):
        if self.gitlab:
            if self.gitlab.repository == "NetworkManager-ci":
                try:
                    self.gitlab.play_commit_job()
                except Exception:
                    pass
            self.gitlab.post_commit_comment(self._gitlab_message)

    def _generate_junit(self):
        logging.debug("Generate JUNIT")

        failed = []
        passed = []
        for f in os.listdir(self.results_common):
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
        root.write(f'{self.results_common}/junit.xml')
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

        self.mr = "custom"
        self._set_gitlab(args.trigger_data, args.gitlab_token)
        if self.gitlab is not None:
            if self.gitlab.repository == 'NetworkManager':
                self.mr = f"mr{self.gitlab.merge_request_id}"

        self._check_if_copr_possible()

    def _check_if_copr_possible(self):
        self.copr_repo = False
        if not self.repo or self.repo == "https://gitlab.freedesktop.org/NetworkManager/NetworkManager/":
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
        logging.debug(f"Waiting for {self.phase} to finish...")
        build_machine = []
        if self.build_machine is not None:
            build_machine.append(self.build_machine)
        running_machines = list(self.machines) + build_machine
        while len(running_machines):
            for m in running_machines:
                if m.cmd_is_active():
                    continue
                # m is finished
                running_machines.remove(m)
                if m.cmd_is_failed():
                    if abort_on_fail:
                        self._abort(f"Failed {self.phase} on machine {m.id}.")
                    else:
                        logging.debug(f"Failed {self.phase} on machine {m.id}.")
            time.sleep(5)

    def create_machines(self):
        self.phase = "create"
        if self.gitlab:
            self.gitlab.set_pipeline('running')

        self.tests = self.mapper.get_tests_for_machines(self.features)
        logging.debug(f"tests distributed to {len(self.tests)} machines: {[len(x) for x in self.tests]}")
        machines_num = len(self.tests)
        for i in range(machines_num):
            m = Machine(i, self.release)
            self.machines.append(m)

        if not self.copr_repo:
            self.build_machine = Machine("builder", self.release)

    def prepare_machines(self):
        self.phase = "prepare"
        for m in self.machines:
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
            self.build_machine.build_async(self.refspec, self.mr, self.repo)

    def install_NM_on_machines(self):
        if self.exit_code != 0:
            sys.exit(1)
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
            tests = self.tests[m.id]
            logging.debug(f"Running {len(tests)} tests on machine {m.id}:\n" + "\n".join(tests))
            m.runtests_async(tests)

    def merge_machines_results(self):
        for m in self.machines:
            # m._run is short for subprocess.run()
            m._run(f"mv {m.results}/*.html {self.results_common}")

        # this also computes exit_code
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
    runner.parse_args()
    runner.create_machines()
    runner.wait_for_machines(abort_on_fail=True)
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
