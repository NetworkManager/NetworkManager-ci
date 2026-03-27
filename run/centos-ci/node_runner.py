#!/usr/bin/python3
import argparse
import glob as glob_mod
import logging
import shutil
import subprocess
import sys
import re
import requests
import os
import yaml
import json
import base64
import sys
import time

from multiprocessing import Process, Pipe
from cico_gitlab_trigger import GitlabTrigger

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s:%(levelname)s:%(message)s",
    datefmt="%d/%b/%Y %H:%M:%S",
    stream=sys.stdout,
)

# TODO convert this to argument
MACHINES_NUM = 2
MACHINES_MIN_THRESHOLD = 1000


def run(
    cmd,
    shell=True,
    check=True,
    capture_output=True,
    encoding="utf-8",
    verbose=False,
    *a,
    **kw,
):
    if capture_output:
        kw["stdout"] = subprocess.PIPE
        kw["stderr"] = subprocess.PIPE
    rc = subprocess.run(
        cmd,
        *a,
        shell=shell,
        check=check,
        encoding=encoding,
        **kw,
    )
    logging.debug(f"executed '{cmd}': returned {rc.returncode}")
    if verbose:
        if rc.stdout:
            logging.debug(f"STDOUT:\n'{rc.stdout}")
        if rc.stderr:
            logging.debug(f"STDERR:\n'{rc.stderr}")
    return rc


class Machine:
    def __init__(self, id, release, name):
        self.release = release
        self.release_num = release.split("-")[0]
        self.id = id
        self.name = name
        self.copr_repo = False
        self.results_common = f"../"
        self.rpms_dir = "../rpms/"
        self.build_dir = "/root/nm-build/"
        self.tmt_log = f"../tmt.m{self.id}.log"
        self.artifact_dir = "../"
        self.rpms_build_dir = (
            f"{self.build_dir}/NetworkManager/contrib/fedora/rpm/*/RPMS/*/"
        )
        self.commit_needs_rebase = False

        self.ssh_options = " ".join(
            [
                "-o UserKnownHostsFile=/dev/null",
                "-o StrictHostKeyChecking=no",
                "-o ServerAliveInterval=10",
                "-o ServerAliveCountMax=240",
            ]
        )

        self.rpm_exclude_list = [
            "*-connectivity-*",
            "*-devel*",
        ]

        self._pipe = None
        self._proc = None
        self._last_cmd_ret = None

        self.cmd_async(self._setup)

    def ssh(self, cmd, check=True, verbose=False):
        return run(
            f"ssh {self.ssh_options} root@{self.name} {cmd}",
            check=check,
            verbose=verbose,
        )

    def scp_to(self, what, where, check=True):
        return self._scp(what, f"root@{self.name}:{where}", check=check)

    def scp_from(self, what, where, check=True):
        return self._scp(f"root@{self.name}:{what}", where, check=check)

    def rsync_from(self, what, where, check=True):
        return run(
            f"rsync -aq root@{self.name}:{what} {where}",
            check=check,
            verbose=True,
        )

    def _scp(self, what, where, check=True):
        return run(f"scp -v {self.ssh_options} -r {what} {where}", check=check)

    def cmd_async(self, cmd, *args):
        self._last_cmd_ret = None
        ret, self._pipe = Pipe()
        self._proc = Process(target=self._cmd_wrap_async(cmd, *args), args=(ret,))
        self._proc.start()

    def _cmd_wrap_async(self, cmd, *args):
        def run(ret):
            try:
                rc = cmd(*args)
                ret.send(rc)
            except Exception as e:
                ret.send(e)

        return run

    def cmd_wait(self, timeout=None):
        if self._proc is not None:
            self._proc.join(timeout=timeout)
            if self._proc.is_alive():
                return False
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
            try:
                rc = self._pipe.recv()
            except Exception as e:
                logging.debug(
                    f"Exception during wait for command on machine {self.id}. Probably job was canceled."
                )
                rc = e
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

    def _wait_for_machine(self, retry=12, timeout=None):
        end_time = None
        if timeout is not None:
            end_time = time.time() + timeout
        for _ in range(retry):
            if self.ssh("true", check=False).returncode == 0:
                return
            if end_time and end_time < time.time():
                break
        self.ssh("true")

    def _setup(self):
        self._wait_for_machine()
        self.ssh(
            "sed -i"
            " -e \\'s/^#*ClientAliveInterval.*/ClientAliveInterval 10/\\'"
            " -e \\'s/^#*ClientAliveCountMax.*/ClientAliveCountMax 240/\\'"
            " /etc/ssh/sshd_config"
        )
        self._update()
        release = self.release_num
        dnf_install = "dnf -y install"
        if int(release) == 9:
            dnf_package = f"https://dl.fedoraproject.org/pub/epel/epel{{,-next}}-release-latest-{release}.noarch.rpm"
        else:
            # There is not next repo in epel 10 yet
            dnf_package = f"https://dl.fedoraproject.org/pub/epel/epel-release-latest-{release}.noarch.rpm"
        # enable epel repos
        self.ssh(f"{dnf_install} {dnf_package}")
        # For some reason names can differ, so enable both powertools
        self.ssh("yum install -y \\'dnf-command\\(config-manager\\)\\'")
        self.ssh("yum config-manager --set-enabled PowerTools", check=False)
        self.ssh("yum config-manager --set-enabled powertools", check=False)
        self.ssh("yum config-manager --set-enabled crb", check=False)
        # Enable build deps for NM
        self.ssh("yum -y copr enable nmstate/nm-build-deps")
        # install NM packages
        self.ssh(
            "yum -y install crda wget bash-completion \
                    NetworkManager-team \
                    NetworkManager-ppp NetworkManager-wifi \
                    NetworkManager-adsl NetworkManager-ovs \
                    NetworkManager-tui NetworkManager-wwan \
                    NetworkManager-bluetooth NetworkManager-libnm-devel \
                    --skip-broken"
        )
        return True

    def restartNM(self):
        NM_restart = self.ssh(
            "systemctl restart NetworkManager", verbose=True, check=False
        )
        if NM_restart.returncode != 0:
            logging.debug("Unable to start NetworkManager, dumping last core (if any).")
            self.ssh("coredumpctl list", check=False, verbose=True)
            self.ssh(
                f"coredumpctl dump > ../core.dump.m{self.id}", check=False, verbose=True
            )
            raise Exception("Unable to start NetworkManager.")

    def _update(self):
        logging.debug(f"Update machine {self.id}")
        self.ssh("dnf -y upgrade --nobest", verbose=True)
        self.restartNM()
        self.ssh("nmcli d", verbose=True)
        self.ssh("nmcli device connect eth0", check=False, verbose=True)
        self._reboot()

    def prepare(self):
        logging.debug(f"Prepare machine {self.id}")
        # enable NM debug/trace logs
        self.scp_to(
            "contrib/conf/95-nmci-test.conf",
            "/etc/NetworkManager/conf.d/95-nmci-test.conf",
        )
        self.restartNM()
        # execute envsetup via ssh, keep log separate from tmt
        self.scp_to("prepare/", "/tmp/prepare/")
        self.ssh(
            f"cd /tmp\\; bash -x prepare/envsetup.sh setup first_test_setup &> ../envsetup.m{self.id}.log"
        )
        return True

    def prepare_async(self):
        self.cmd_async(self.prepare)

    def _reboot(self):
        self.ssh("reboot", check=False)
        # give some time to shutdown, _wait_for_machine()
        # succeedes when machine is shutting down
        time.sleep(10)
        # give even more time as 60s seems to be nt enough
        self._wait_for_machine(retry=120, timeout=600)
        logging.debug(f"Machine {self.id} is back online after update")

    def build(self, refspec, mr="custom", repo=""):
        run("mkdir -p ../rpms/")

        # el8 workarounds
        if self.release_num.startswith("8"):
            self.ssh("yum -y install crda make")

        # remove NM packages
        self.ssh("rpm -ea --nodeps \\$\\(rpm -qa \\| grep NetworkManager\\)")

        logging.debug(f"Building from refspec id {refspec} of repo '{repo}'")
        self.scp_to("run/centos-ci/scripts/build.sh", "/tmp/build.sh")
        ret = self.ssh(
            f"BUILD_REPO={repo} sh /tmp/build.sh {refspec} {mr} &> {self.artifact_dir}/build.log",
            check=False,
        )
        if ret.returncode != 0:
            logging.debug("Build failed, copy config.log!")
            self.scp_from(
                f"{self.build_dir}/NetworkManager/config.log", "../", check=False
            )
            # copy unit test log files
            log_files = self.ssh(
                f"find {self.build_dir}/NetworkManager/ -iname test-*.log", verbose=True
            ).stdout
            for log in log_files.strip("\n").split("\n"):
                if log:
                    self.scp_from(
                        log,
                        "../"
                        + log.replace(f"{self.build_dir}/NetworkManager/", "").replace(
                            "/", "_"
                        ),
                    )
            return False
        else:
            logging.debug(
                "rpms in build dir:\n"
                + self.ssh(f"find {self.build_dir} | grep -F .rpm").stdout
            )
            # do not copy connectivity and devel packaqes
            excludes = " ".join(
                [f"{self.rpms_build_dir}/{e}.rpm" for e in self.rpm_exclude_list]
            )
            self.ssh(f"rm -rf {excludes}")
            git_merge_base_command = f"cd  {self.build_dir}/NetworkManager\\; git merge-base --is-ancestor main HEAD"
            self.commit_needs_rebase = (
                self.ssh(git_merge_base_command, check=False).returncode != 0
            )
            self.scp_from(f"{self.rpms_build_dir}/*.rpm", self.rpms_dir)
        return True

    def build_async(self, refspec, mr="custom", repo=""):
        self.cmd_async(self.build, refspec, mr, repo)

    def install_NM(self):
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
            elif "pptp" in rpm:
                continue
            delete_rpms += " " + rpm
        if delete_rpms.strip():
            self.ssh(f"rpm -ea --nodeps {delete_rpms}")

        excludes = " ".join([f'--exclude \\"{e}\\"' for e in self.rpm_exclude_list])
        if self.copr_repo:
            repo = ""
            if self.copr_repo != "stock":
                repo = f"--repo \\'*{self.copr_repo}\\'"
            self.ssh(
                f"yum -y install {repo} \\'NetworkManager*\\' {excludes}",
                verbose=True,
            )
        else:
            self.ssh("mkdir -p rpms")
            self.scp_to(f"{self.rpms_dir}/*.rpm", "rpms")
            # excludes not needed build, as the rpms should not be copied from build_machine
            self.ssh("yum -y install ./rpms/NetworkManager*.rpm")
        self.ssh("systemctl restart NetworkManager")
        return True

    def install_NM_async(self):
        self.cmd_async(self.install_NM)

    def _generate_tmt_plan(self, tests, plan_name):
        """Generate a local fmf plan file with test list and connect provision."""
        test_lines = "\n".join([f"        - /tests/{t}$" for t in tests])
        plan_content = (
            f"discover:\n"
            f"    how: fmf\n"
            f"    test:\n"
            f"{test_lines}\n"
            f"provision:\n"
            f"    how: connect\n"
            f"    guest: {self.name}\n"
            f"    user: root\n"
        )
        plan_dir = "plan/centos_ci"
        os.makedirs(plan_dir, exist_ok=True)
        with open(f"{plan_dir}/{plan_name}.fmf", "w") as f:
            f.write(plan_content)

    def _get_tmt_run_dir(self):
        """Return the tmt run directory in the artifacts area."""
        return os.path.abspath(f"{self.artifact_dir}/tmt_m{self.id}")

    def _get_tmt_results_dir(self, plan_name):
        """Return the local tmt results directory path."""
        return f"{self._get_tmt_run_dir()}/plan/centos_ci/{plan_name}/data/reports"

    def _rename_tmt_report(self, filename):
        """Rename tmt report from XXXX_TEST_NAME.html to old naming convention.

        tmt format:  XXXX_TEST_NAME.html (or FAIL_XXXX_TEST_NAME.html for failures)
        old format:  report_NetworkManager-ci-M{id}_Test{XXXX}_{TEST_NAME}.html
                     (or FAIL-report_... for failures)
        """
        name_no_ext = filename.rsplit(".html", 1)[0]
        fail_prefix = ""
        if name_no_ext.startswith("FAIL_"):
            fail_prefix = "FAIL-"
            name_no_ext = name_no_ext[len("FAIL_") :]
        parts = name_no_ext.split("_", 1)
        if len(parts) == 2:
            counter, test_name = parts
            return f"{fail_prefix}report_NetworkManager-ci-M{self.id}_Test{counter}_{test_name}.html"
        return f"{fail_prefix}report_NetworkManager-ci-M{self.id}_{name_no_ext}.html"

    def _copy_tmt_results(self, tmt_results_dir):
        """Copy and rename tmt HTML reports to match old naming convention."""
        if not tmt_results_dir or not os.path.isdir(tmt_results_dir):
            logging.debug(f"TMT results dir not found: {tmt_results_dir}")
            return
        for html_file in glob_mod.glob(f"{tmt_results_dir}/*.html"):
            new_name = self._rename_tmt_report(os.path.basename(html_file))
            shutil.copy2(html_file, f"{self.results_common}/{new_name}")

    def _load_tmt_results(self, plan_name):
        """Load tmt results from JSON or YAML file."""
        results_base = (
            f"{self._get_tmt_run_dir()}/plan/centos_ci/{plan_name}/execute/results"
        )
        # Try JSON first (used with TMT_STATE_FORMAT=json), fall back to YAML
        for ext, loader in [
            (".json", json.load),
            (".yaml", yaml.safe_load),
        ]:
            path = results_base + ext
            if os.path.isfile(path):
                with open(path) as f:
                    return loader(f)
        return None

    def _generate_summary_from_tmt_results(self, plan_name):
        """Parse tmt results to generate summary.txt compatible with old format."""
        passed = []
        failed = []
        skipped = []
        try:
            results = self._load_tmt_results(plan_name)
            if results is None:
                logging.debug(
                    f"M{self.id}: could not find tmt results.json or results.yaml"
                )
            else:
                for entry in results:
                    name = entry.get("name", "").lstrip("/tests/")
                    result = entry.get("result", "")
                    if result == "pass":
                        passed.append(name)
                    elif result in ("fail", "error"):
                        failed.append(name)
                    else:
                        skipped.append(name)
        except (OSError, IOError) as e:
            logging.debug(f"M{self.id}: could not read tmt results: {e}")
        except (yaml.YAMLError, json.JSONDecodeError) as e:
            logging.debug(f"M{self.id}: failed to parse tmt results: {e}")

        summary_path = f"{self._get_tmt_run_dir()}/summary.txt"
        with open(summary_path, "w") as f:
            f.write(f"{len(passed)}\n")
            f.write(f"{len(failed)}\n")
            f.write(f"{len(skipped)}\n")
            f.write(f"{' '.join(failed)}\n")
            f.write(f"{' '.join(skipped)}\n")
        logging.debug(
            f"M{self.id}: summary - passed:{len(passed)} "
            f"failed:{len(failed)} skipped:{len(skipped)}"
        )

    def runtests(self, tests):
        # Log pkg state right before the tests
        self.ssh(f"rpm -qa > ../packages.m{self.id}.list")
        self.tests = tests
        self.tests_num = len(tests)

        plan_name = f"machine_{self.id}"
        self._generate_tmt_plan(tests, plan_name)

        # Run tmt locally on orchestrating machine, it connects to node
        logging.debug(
            f"M{self.id}: running tmt with plan {plan_name} "
            f"({self.tests_num} tests) on node {self.name}"
        )
        tmt_run_dir = self._get_tmt_run_dir()
        ret = run(
            f"TMT_STATE_FORMAT=json python3.12 -m tmt run --id {tmt_run_dir} "
            f"plan --name /plan/centos_ci/{plan_name} "
            f"2>&1 | tee {self.tmt_log}",
            check=False,
        )

        self.ssh(
            f"journalctl -b --no-pager -o short-monotonic --all \\| bzip2 --best > ../journal.m{self.id}.log.bz2"
        )

        # Parse tmt results.yaml and generate summary.txt
        self._generate_summary_from_tmt_results(plan_name)

        # Copy and rename results from local tmt workdir
        tmt_results = self._get_tmt_results_dir(plan_name)
        self._copy_tmt_results(tmt_results)
        return ret

    def runtests_async(self, tests):
        # set properties also here, as _async sets properties on forked object
        self.tests = tests
        self.tests_num = len(tests)

        self.cmd_async(self.runtests, tests)

    def poll_tmt_results(self):
        """Copy intermediate results from local tmt workdir during execution."""
        plan_name = f"machine_{self.id}"
        tmt_results = self._get_tmt_results_dir(plan_name)
        if not tmt_results or not os.path.isdir(tmt_results):
            return
        for html_file in glob_mod.glob(f"{tmt_results}/*.html"):
            new_name = self._rename_tmt_report(os.path.basename(html_file))
            dest = f"{self.results_common}/{new_name}"
            if os.path.exists(dest):
                continue
            logging.debug(f"M{self.id}: polling result {new_name}")
            shutil.copy2(html_file, dest)


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
        self.default_exlude = ["dcb", "wifi", "infiniband", "wol", "sriov", "gsm"]
        self.m_num = MACHINES_NUM
        self.m_thresh = MACHINES_MIN_THRESHOLD
        self.timing_cache = {}
        self._default_test_time = 10
        self._release_num = ""

    def load_timing(self, build_url, release):
        """Fetch per-feature timing from last completed main branch build."""
        from timing_data import get_feature_times

        self._release_num = release.split("-")[0]
        self.timing_cache = get_feature_times(build_url, release, self.mapper)
        if self.timing_cache:
            # With real durations the total is much smaller than with
            # static 10-min defaults, so disable the static threshold
            # to let average_time drive the distribution.
            self.m_thresh = 0
            total = sum(v["total_minutes"] for v in self.timing_cache.values())
            count = sum(v["test_count"] for v in self.timing_cache.values())
            self._default_test_time = total / count if count else 10
            logging.debug(
                f"Loaded timing for {len(self.timing_cache)} features "
                f"(default {self._default_test_time:.2f} min/test)"
            )
        else:
            logging.debug("No timing data available, using mapper timeouts")

    def _parse_features_string(self, features):
        if "best" in features:
            features = None
            if self.gitlab is not None:
                features = [
                    f
                    for f in self.gitlab.changed_features
                    if f not in self.default_exlude
                ]
            if features is None or features == []:
                features = ["all"]
            logging.debug(f"running best effort execution to shorten time: {features}")
            return features
        elif features.startswith("covering:"):
            features = features.split(":", 1)
            if len(features) != 2:
                logging.debug(
                    "Unexpected feature list, unable to parse 'covering' tests"
                )
                return ["all"]
            # to be compatible with internal trigger, split by comma
            features[1] = features[1].split(",")
            return features

        elif features.startswith("tests:"):
            features = features.split(":", 1)
            if len(features) != 2:
                logging.debug("Unexpected feature list, unable to parse 'tests'")
                return ["all"]
            # to be compatible with internal trigger, split by comma
            features[1] = features[1].split(",")
            return features
        elif not features or "all" in features:
            return ["all"]
        else:
            return [x.strip() for x in features.split(",")]

    def get_tests_for_machines(self, features):
        if not self.mapper:
            return [["pass"]]

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
                if (
                    new_time < average_time
                    or new_time < self.m_thresh
                    or i + 1 == self.m_num
                ):
                    m_time[i] = new_time
                    m_tests[i].extend(tests[f])
                    break

        while [] in m_tests:
            m_tests.remove([])

        if len(m_tests) > self.m_num:
            logging.debug(
                "Something unexpected happened with test processing: " + m_tests
            )
            return [["pass"]]

        if len(m_tests) == 0:
            logging.debug("No tests to run, running just '@pass'")
            m_tests = [["pass"]]

        return m_tests

    def _get_tests_and_times_for_features(self, features=["all"]):
        if not self.mapper:
            return None

        times = {}
        tests = {}
        all = (
            "all" in features
            or "*" in features
            or "covering" in features
            or "tests" in features
        )
        all_tests = "tests" in features and ("all" in features[1] or "*" in features[1])
        for test in self.mapper["testmapper"]["default"]:
            for test_name in test:
                f = test[test_name]["feature"]
                if f in self.default_exlude:
                    continue
                # if features are in form ["tests", ["test1","test2",...]]
                if (
                    "tests" in features
                    and test_name not in features[1]
                    and not all_tests
                ):
                    continue
                if f not in features and not all:
                    continue
                # Use cached actual duration if available, otherwise
                # fall back to mapper timeout or default.
                # If timing data is loaded but a feature is missing,
                # it was likely skipped on this OS -- count it as 0.
                if f in self.timing_cache:
                    t = self.timing_cache[f]["avg_per_test_minutes"]
                elif self.timing_cache:
                    # Skipped-feature fallback: based on observed overhead
                    # per skipped test. c9s skips more features and has
                    # higher per-test overhead; c10s skips fewer and
                    # benefits from a lower value to avoid distorting
                    # the distribution.
                    t = 0.1 if self._release_num == "9" else 0
                elif "timeout" in test[test_name]:
                    t = int(test[test_name]["timeout"][:-1])
                else:
                    t = self._default_test_time
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
    DUFFY_AUTH = "--auth-name networkmanager --auth-key $CICO_API_KEY"
    DUFFY = f"duffy client --url https://duffy.ci.centos.org/api/v1 {DUFFY_AUTH}"

    def __init__(self):
        self.copr_repo = False
        self.mapper = Mapper()
        self.machines = []
        self.machine_list = "../machines"
        self.build_machine = None
        self.phase = ""
        self.results_common = "../"
        self.exit_code = 0

    def _abort(self, msg=""):
        if self.gitlab:
            self.gitlab.set_pipeline("canceled", self.release.replace("-stream", ""))
            # if we have config.log, build failed
            if os.path.isfile("../config.log"):
                self._gitlab_message = "NetworkManager build from source failed!"
            else:
                self._gitlab_message = "Job unexpectedly aborted!"
            if msg:
                self._gitlab_message += "\n\nReason: " + msg
            self._post_results()
        # if self.build_machine:
        #     self.build_machine.cmd_terminate()
        # for m in self.machines:
        #     m.cmd_terminate()
        # self.done()
        logging.debug("Aborting job (exitting with 2).")
        if msg:
            logging.debug(f"Reason: {msg}")
        self.exit_code = 2
        sys.exit(2)

    def _skip(self, msg=""):
        logging.debug(f"Skipping, reason: {msg}\nExit with {self.exit_code}")
        sys.exit(self.exit_code)
        sys.exit(2)

    def _set_gitlab(self, trigger_data, gl_token):
        if not trigger_data or not gl_token:
            self.gitlab = None
            logging.debug(
                f"trigger or token not set! token: {not not gl_token},"
                f" data: {not not trigger_data}"
            )
            return

        # hide it to /tmp, which is not visible in Workspace
        with open("/tmp/python-gitlab.cfg", "w") as cfg:
            cfg.write("[global]\n")
            cfg.write("default = gitlab.freedesktop.org\n")
            # cfg.write("ssl_verify = false\n")
            cfg.write("timeout = 30\n")
            cfg.write("[gitlab.freedesktop.org]\n")
            cfg.write("url = https://gitlab.freedesktop.org\n")
            cfg.write(f"private_token = {gl_token}\n")

        content = base64.b64decode(trigger_data).decode("utf-8").strip()
        data = json.loads(content)
        logging.debug(data)
        gitlab_trigger = GitlabTrigger(data, ["/tmp/python-gitlab.cfg"])
        self.gitlab = gitlab_trigger
        if self.mapper:
            self.mapper.gitlab = gitlab_trigger

    def _get_machine_summaries(self):
        self.exit_code = 0
        self.passed = 0
        self.failed_tests = []
        self.skipped_tests = []
        for m in self.machines:
            summary_file = f"{m._get_tmt_run_dir()}/summary.txt"
            if not os.path.isfile(summary_file):
                m._gitlab_message = (
                    f"**M{m.id}: NO RESULTS**: no summary.txt retrieved!"
                )
                logging.debug(f"M{m.id}: no summary.txt file")
                self.exit_code = 1
                continue
            with open(summary_file) as rf:
                lines = rf.read().strip("\n").split("\n")
            if len(lines) not in [3, 4, 5]:
                m._gitlab_message = (
                    f"**M{m.id}: BAD RESULTS**: unexpected summary.txt file"
                )
                logging.debug(f"M{m.id}: unexpected summary.txt file: {lines}")
                self.exit_code = 1
                continue
            m.status = "PASS"
            if lines[1] != "0" or (lines[0] == "0" and lines[2] == "0"):
                m.status = "FAIL"
                self.exit_code = 1
            try:
                m.passed = int(lines[0])
                self.passed += m.passed
                m.failed = int(lines[1])
                m.skipped = int(lines[2])
            except Exception as e:
                m._gitlab_message = (
                    f"**M{m.id}: BAD RESULTS**: unexpected summary.txt file"
                )
                logging.debug(f"M{m.id}: unexpected summary.txt file: {lines}")
                logging.debug(e)
                self.exit_code = 1
                continue
            m.undef = m.tests_num - (m.passed + m.failed + m.skipped)
            undef_str = ""
            if m.undef != 0:
                self.exit_code = 1
                m.status = "TIMEOUT"
                undef_str = ",  Missing: {undef}"
            msg = (
                f"**M{m.id} {m.status}**: "
                f"Passed: {m.passed}, Failed: {m.failed}, "
                f"Skipped: {m.skipped}{undef_str}"
            )
            m._gitlab_message = msg
            if len(lines) >= 4:
                for t in lines[3].split(" "):
                    if t:
                        self.failed_tests.append(t)

            if len(lines) >= 5:
                for t in lines[4].split(" "):
                    if t:
                        self.skipped_tests.append(t)

    def _fetch_last_main_failures(self):
        jenkins_url = "https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-main-c9s/lastCompletedBuild/artifact/junit.xml"
        junit_xml = run(f"curl -s {jenkins_url}")
        import xml.etree.ElementTree as ET

        try:
            tests = ET.fromstring(junit_xml.stdout)
        except:
            return False
        f = []
        for t in tests.iter("testcase"):
            if t.findall(".//failure"):
                f.append(t.attrib["name"])
        return f

    def _generate_gitlab_message(self):
        machine_lines = [m._gitlab_message for m in self.machines]
        if len(self.machines) > 1:
            machine_lines.append(
                f"Passed: {self.passed}, Failed {len(self.failed_tests)}, Skipped {len(self.skipped_tests)}."
            )
        elif len(machine_lines):
            machine_lines[0] = machine_lines[0].split("**:")[1]

        status = "UNSTABLE: Some tests failed"
        if self.exit_code == 0:
            status = "STABLE: All tests passed!"

        commit = None
        if self.gitlab is not None:
            commit = self.gitlab.commit
        message = [
            f"Commit: {commit}",
            f"Result: {status}",
            *machine_lines,
            f"Executed on: CentOS {self.release}",
        ]

        if self.failed_tests:
            message.append(self._collapse("Failed tests:", " ".join(self.failed_tests)))
        if self.skipped_tests:
            message.append(
                self._collapse("Skipped tests:", " ".join(self.skipped_tests))
            )

        main_failures = self._fetch_last_main_failures()
        if main_failures == False:
            last_main_status = "Failed to fetch/parse last junit.xml"
        elif main_failures == []:
            last_main_status = "SUCCESS"
        else:
            last_main_status = "FAILED: " + " ".join(main_failures)
        message.append(
            self._collapse("Last main branch build status:", last_main_status)
        )

        if self.build_machine and self.build_machine.commit_needs_rebase:
            message.append("**Warning:** MR is not rebased!")

        self._gitlab_message = "\n\n".join(message)
        logging.debug("Gitlab Message:\n\n" + self._gitlab_message)

    def _collapse(self, title, message):
        if len(message) > 80:
            return "\n".join(
                [
                    "<p>",
                    "<details>",
                    f"<summary><em>{title}</em></summary>",
                    "",
                    message,
                    "",
                    "</details>",
                    "</p>",
                ]
            )
        else:
            return f"*{title}*\n\n{message}"

    def _post_results(self, message=None):
        if not message:
            message = self._gitlab_message
        if hasattr(self, "build_url"):
            message = f"{self.build_url}\n\n{message}"
        if self.gitlab:
            if self.gitlab.repository == "NetworkManager-ci":
                try:
                    self.gitlab.play_commit_job()
                except Exception:
                    pass
            # post message to MR pipeline thread
            self.gitlab.post_mr_discussion(message)
            comments = self.gitlab.get_mr_discussions(self.gitlab.commit)
            unstable = [c for c in comments if "Result: STABLE" not in c]
            resolved = unstable == []
            self.gitlab.set_mr_discussion_resolved(resolved)

    def _generate_junit(self):
        logging.debug("Generate JUNIT")

        failed = []
        html_fails = []
        passed = []
        for f in os.listdir(self.results_common):
            if not f.endswith(".html"):
                continue
            f = f.split(".html")[0]
            if f.startswith("FAIL-"):
                f = f.replace("FAIL-", "", 1)
                failed.append(f)
            else:
                passed.append(f)

        import xml.etree.ElementTree as ET

        root = ET.ElementTree()
        testsuite = ET.Element("testsuite", tests=str(len(passed) + len(failed)))
        for test in passed:
            name = test[test.find("_Test") + 10 :]
            testcase = ET.Element("testcase", classname="tests", name=name)
            system_out = ET.Element("system-out")
            system_out.text = f"LOG:\n{self.build_url}/artifact/{test}.html"
            testcase.append(system_out)
            testsuite.append(testcase)
        for test in failed:
            name = test[test.find("_Test") + 10 :]
            html_fails.append(name)
            testcase = ET.Element("testcase", classname="tests", name=name)
            failure = ET.Element("failure")
            failure.text = f"Error\nLOG:\n{self.build_url}/artifact/FAIL-{test}.html"
            testcase.append(failure)
            testsuite.append(testcase)
        no_html_fails = [test for test in self.failed_tests if test not in html_fails]
        for test in no_html_fails:
            testcase = ET.Element("testcase", classname="tests", name=test)
            failure = ET.Element("failure")
            failure.text = "Error\nNo HTML reprted!"
            testcase.append(failure)
            testsuite.append(testcase)
        root._setroot(testsuite)
        root.write(f"{self.results_common}/junit.xml")
        self.exit_code = 0
        if len(failed):
            self.exit_code = 1
        logging.debug("JUNIT Done")

    def parse_args(self):
        logging.basicConfig(level=logging.DEBUG)
        logging.debug("reading params")
        parser = argparse.ArgumentParser()
        parser.add_argument("-t", "--test_branch", default="main")
        parser.add_argument("-c", "--code_refspec", default=None)
        parser.add_argument("-f", "--features", default="all")
        parser.add_argument("-b", "--build_id")
        parser.add_argument("-g", "--gitlab_token")
        parser.add_argument("-d", "--trigger_data")
        parser.add_argument(
            "-r",
            "--nm_repo",
            default=None,
        )
        parser.add_argument("-v", "--os_version", default="c8s")
        parser.add_argument(
            "-D", "--do_not_touch_NM", action="store_true", default=False
        )

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
        if not self.repo:
            # get cloned NM-ci repo - FD gitlab (or github if FD gitlab is down)
            nm_ci_repo = run("git remote get-url origin").stdout.strip()
            self.repo = nm_ci_repo.replace("NetworkManager-ci", "NetworkManager")
        self.release = args.os_version
        self.release_num = self.release.split("-")[0]

        self.mr = "custom"
        gl_token = args.gitlab_token
        if gl_token is None:
            gl_token = os.environ.get("GL_TOKEN", None)
        self._set_gitlab(args.trigger_data, gl_token)
        if self.gitlab is not None:
            if self.gitlab.repository == "NetworkManager":
                self.mr = f"mr{self.gitlab.merge_request_id}"

    def check_if_copr_possible(self):
        p = re.compile("nm-1-[0-9][0-9]")
        # Let's check if we have stable branch"
        if self.refspec == "stock":
            self.copr_repo = "stock"
        if self.refspec == "main":
            self.copr_repo = "NetworkManager-main-debug"
        elif self.refspec == "nm-1-28":
            self.copr_repo = "NetworkManager-CI-1.28-git"
        elif self.refspec == "nm-1-26":
            self.copr_repo = "NetworkManager-CI-1.26-git"
        elif p.match(self.refspec):
            branch = "1." + self.refspec.split("-")[-1]
            self.copr_repo = f"NetworkManager-{branch}-debug"
        logging.debug(f"COPR repo: {self.copr_repo}")

    def wait_for_machines(self, abort_on_fail=True, poll_results=False):
        logging.debug(f"Waiting for {self.phase} to finish...")
        check_interval = 30 if poll_results else 5
        running_machines = list(self.machines)
        while len(running_machines):
            for m in running_machines:
                if m.cmd_is_active():
                    if poll_results:
                        m.poll_tmt_results()
                    continue
                # m is finished
                running_machines.remove(m)
                if m.cmd_is_failed():
                    if abort_on_fail:
                        self._abort(
                            f"Failed {self.phase} on machine {m.id} ({m.name})."
                        )
                    else:
                        logging.debug(
                            f"Failed {self.phase} on machine {m.id} ({m.name})."
                        )
            time.sleep(check_interval)
        return [not m.cmd_is_failed() for m in self.machines]

    def _get_nodes(self, number):
        nodes = []
        if self.release == "10-stream":
            self.pool = "virt-ec2-t2-centos-10s-x86_64"
        elif self.release == "9-stream":
            self.pool = "virt-ec2-t2-centos-9s-x86_64"
        elif self.release == "8-stream":
            self.pool = "virt-ec2-t2-centos-8s-x86_64"
        else:
            self.pool = None

        retry_count = 0
        reserve_cmd = f"{self.DUFFY} request-session pool={self.pool},quantity={number}"
        while True:
            duffy = run(
                reserve_cmd,
                check=False,
            )
            content = duffy.stdout.strip()
            logging.debug(f"machine content {content}")
            data = {}
            try:
                data = json.loads(content)
            except json.decoder.JSONDecodeError:
                retry_count += 1
            if "error" in data:
                retry_count += 1
            if "session" in data:
                break
            if retry_count >= 180:
                self._abort(f"Unable to reserve a machine '{self.id}' in 180 minutes")
            time.sleep(60)

        for i in range(number):
            nodes.append(
                data["session"]["nodes"][i]["data"]["provision"]["public_hostname"]
            )

        # We use this to return all machines
        session_id = data["session"]["id"]

        return session_id, nodes

    def done(self):
        return_cmd = f"{self.DUFFY} retire-session {self.session_id}"
        run(return_cmd)

    def create_machines(self, retry=3):
        self.phase = "create"
        if self.gitlab:
            self.gitlab.set_pipeline("running", self.release.replace("-stream", ""))

        self.tests = self.mapper.get_tests_for_machines(self.features)
        logging.debug(
            f"tests distributed to {len(self.tests)} machines: {[len(x) for x in self.tests]}"
        )
        machines_num = len(self.tests)

        self.session_id, node = self._get_nodes(machines_num)

        for i in range(machines_num):
            m = Machine(i, self.release, node[i])
            self.machines.append(m)
            with open(self.machine_list, "a") as ml:
                ml.write(f"{m.id}:{m.name}\n")

        with open("../session_id", "a") as sid:
            sid.write(f"{self.session_id}\n")

        if not self.copr_repo:
            self.build_machine = self.machines[0]

        if not all(self.wait_for_machines(abort_on_fail=False)):
            logging.debug(
                f"Failed to get up-to-date machine(s), {retry} attempts left."
            )
            self.done()
            self.machines = []
            if retry <= 0:
                self._abort("Unable to create machines that are up-to-date.")
            self.create_machines(retry - 1)

    def install_tmt(self):
        logging.debug("Installing tmt on orchestrating machine")
        ret = run(
            "python3.12 -m pip install tmt[report-html,provision-connect]",
            check=False,
            verbose=True,
        )
        if ret.returncode != 0:
            self._abort("Failed to install tmt on orchestrating machine")

    def prepare_machines(self):
        self.phase = "prepare"
        for m in self.machines:
            m.prepare_async()

    def build(self):
        if self.copr_repo:
            for m in self.machines:
                m.copr_repo = self.copr_repo
                if self.copr_repo != "stock":
                    m.ssh(f"dnf -y copr enable networkmanager/{self.copr_repo}")
        else:
            if not self.build_machine.build(self.refspec, self.mr, self.repo):
                self._abort(
                    f"Unable to build NetworkManager from source commit {self.repo}-/commit/{self.refspec}."
                )

    def install_NM_on_machines(self):
        self.phase = "install NM"
        for m in self.machines:
            m.install_NM_async()

    def run_tests_on_machines(self):
        self.phase = "runtests"
        for m in self.machines:
            tests = self.tests[m.id]
            logging.debug(
                f"Running {len(tests)} tests on machine {m.id}:\n" + "\n".join(tests)
            )
            m.runtests_async(tests)

    def merge_machines_results(self):
        for m in self.machines:
            plan_name = f"machine_{m.id}"
            output_dir = (
                f"{m._get_tmt_run_dir()}/plan/centos_ci/{plan_name}"
                f"/execute/data/guest/default-0/tests"
            )
            if os.path.isdir(output_dir):
                for output_file in sorted(glob_mod.glob(f"{output_dir}/*/output.txt")):
                    test_name = os.path.basename(os.path.dirname(output_file))
                    logging.debug(f"M{m.id}: output of {test_name}:")
                    with open(output_file, errors="ignore") as f:
                        print(f.read())
            else:
                logging.debug(f"M{m.id}: no test output dir found at {output_dir}")

        # this also computes exit_code
        self._get_machine_summaries()

        self._generate_gitlab_message()

        self._generate_junit()

        if self.gitlab:
            if self.exit_code == 0:
                self.gitlab.set_pipeline("success", self.release.replace("-stream", ""))
            if self.exit_code == 1:
                self.gitlab.set_pipeline("failed", self.release.replace("-stream", ""))
            # should not be needed, already exited in _abort()
            if self.exit_code == 2:
                self.gitlab.set_pipeline(
                    "canceled", self.release.replace("-stream", "")
                )
            self._post_results()

        logging.debug(f"All Done. Exit with {self.exit_code}")
        sys.exit(self.exit_code)


def main():
    runner = Runner()
    runner.parse_args()
    runner.mapper.load_timing(getattr(runner, "build_url", ""), runner.release)
    runner.install_tmt()
    runner.check_if_copr_possible()
    runner.create_machines()
    runner.wait_for_machines(abort_on_fail=True)
    runner.build()
    runner.install_NM_on_machines()
    runner.wait_for_machines(abort_on_fail=True)
    runner.prepare_machines()
    runner.wait_for_machines(abort_on_fail=True)
    runner.run_tests_on_machines()
    runner.wait_for_machines(abort_on_fail=False, poll_results=True)
    runner.merge_machines_results()


if __name__ == "__main__":
    main()
