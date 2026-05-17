#!/usr/bin/python3
"""Fetch per-feature test timing from Jenkins artifacts.

Parses nmci-exec.m{N}.log files from the last completed main branch
build to compute per-feature durations. These log files are generated
by runtest.sh, which appends START/END lines with timestamps for each
test execution.

Used by node_runner.py Mapper to distribute tests across machines
based on actual measured times. When exec logs are not available
(older builds), returns empty dict so that node_runner.py falls back
to mapper timeout-based distribution.

Can be imported as a module or run standalone for debugging:
    python3 timing_data.py 10-stream
    python3 timing_data.py 9-stream
"""

import logging
import re
import urllib.request
from datetime import datetime


JENKINS_BASE = "https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org"

_EXEC_LOG_RE = re.compile(
    r"^(START|END)\s+(\S+)\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s*$"
)

_EXEC_LOG_TS_FMT = "%Y-%m-%d %H:%M:%S"


def _resolve_project(build_url, release):
    """Determine the Jenkins project name to fetch timing data from.

    Extracts the project name from the current build URL. Projects ending
    with "-mr" (e.g. NetworkManager-test-mr, NetworkManager-code-mr) and
    the "custom" project are mapped to the corresponding main branch
    project. All other projects are kept as-is.

    Args:
        build_url: current Jenkins build URL
            e.g. ".../job/NetworkManager-main-c10s/848/"
            e.g. ".../job/NetworkManager-test-mr/6445/"
            e.g. ".../job/custom/123/"
        release: OS version string, e.g. "10-stream", "9-stream"

    Returns:
        Jenkins project name to fetch timing data from.
    """
    # Extract project name from URL: .../job/PROJECT/BUILD_NUM/...
    match = re.search(r"/job/([^/]+)/", build_url)
    if not match:
        release_num = release.split("-")[0]
        return f"NetworkManager-main-c{release_num}s"

    project = match.group(1)
    if project.endswith("-mr") or project == "custom":
        release_num = release.split("-")[0]
        return f"NetworkManager-main-c{release_num}s"

    return project


def _fetch_url(url):
    """Fetch raw content from a URL. Returns string or None on failure."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "NM-CI-timing/1.0"})
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.read().decode("utf-8", errors="ignore")
    except Exception as e:
        logging.debug(f"Failed to fetch {url}: {e}")
        return None


def _parse_exec_log(content):
    """Parse nmci-exec.log content into per-test durations.

    Each test produces a pair of lines:
        START <test_name> <timestamp>
        END <test_name> <timestamp>

    Duration = END timestamp - START timestamp.
    Tests with START but no END (killed/crashed) are skipped.

    Returns:
        dict: test_name -> duration in minutes
    """
    starts = {}
    durations = {}

    for line in content.splitlines():
        match = _EXEC_LOG_RE.match(line)
        if not match:
            continue
        action, test_name, ts_str = match.groups()
        try:
            ts = datetime.strptime(ts_str, _EXEC_LOG_TS_FMT)
        except ValueError:
            continue

        if action == "START":
            starts[test_name] = ts
        elif action == "END" and test_name in starts:
            delta = (ts - starts.pop(test_name)).total_seconds() / 60.0
            if delta < 0:
                delta += 24 * 60  # day crossing
            durations[test_name] = delta

    return durations


def _build_test_to_feature(mapper_data):
    """Build test_name -> feature mapping from pre-loaded mapper data."""
    test_to_feature = {}
    if not mapper_data or "testmapper" not in mapper_data:
        return test_to_feature
    for section in mapper_data["testmapper"].values():
        if not isinstance(section, list):
            continue
        for test in section:
            for test_name, test_data in test.items():
                if isinstance(test_data, dict) and "feature" in test_data:
                    test_to_feature[test_name] = test_data["feature"]
    return test_to_feature


def _aggregate_by_feature(durations, test_to_feature):
    """Aggregate per-test durations into per-feature totals.

    Returns dict: feature -> {"total_minutes", "test_count", "avg_per_test_minutes"}
    """
    features = {}
    for test_name, duration in durations.items():
        feature = test_to_feature.get(test_name)
        if not feature:
            continue
        if feature not in features:
            features[feature] = {"total_minutes": 0.0, "test_count": 0}
        features[feature]["total_minutes"] += duration
        features[feature]["test_count"] += 1

    for f_data in features.values():
        if f_data["test_count"] > 0:
            f_data["avg_per_test_minutes"] = round(
                f_data["total_minutes"] / f_data["test_count"], 3
            )
        f_data["total_minutes"] = round(f_data["total_minutes"], 2)

    return features


def get_feature_times(build_url, release, mapper_data):
    """Fetch per-feature timing from the last completed main branch build.

    Tries to fetch nmci-exec.m{N}.log files from the last completed
    build artifacts. These contain accurate START/END timestamps per
    test, written by runtest.sh.

    If exec logs are not available (older builds without the logging),
    returns empty dict so that node_runner.py falls back to mapper
    timeout-based distribution.

    Args:
        build_url: current Jenkins build URL
        release: OS version string (e.g. "10-stream", "9-stream")
        mapper_data: pre-loaded mapper.yaml dict

    Returns:
        dict: feature -> {"total_minutes": float, "test_count": int,
                          "avg_per_test_minutes": float}
        Returns empty dict when exec logs are not available.
    """
    try:
        project = _resolve_project(build_url, release)
        artifact_url = f"{JENKINS_BASE}/job/{project}/lastCompletedBuild/artifact"

        # Fetch exec logs from both machines
        durations = {}
        found_any = False
        for machine_id in range(2):
            log_url = f"{artifact_url}/nmci-exec.m{machine_id}.log"
            logging.debug(f"Fetching exec log from {log_url}")
            content = _fetch_url(log_url)
            if content is None:
                continue
            found_any = True
            machine_durations = _parse_exec_log(content)
            logging.debug(
                f"Parsed {len(machine_durations)} test durations from m{machine_id}"
            )
            durations.update(machine_durations)

        if not found_any:
            logging.debug(
                "No nmci-exec logs found in artifacts, "
                "falling back to mapper timeouts"
            )
            return {}

        if not durations:
            logging.debug("Exec logs found but no test durations parsed")
            return {}

        test_to_feature = _build_test_to_feature(mapper_data)
        if not test_to_feature:
            logging.debug("No test-to-feature mapping available")
            return {}

        features = _aggregate_by_feature(durations, test_to_feature)
        logging.debug(f"Computed timing for {len(features)} features")
        return features

    except Exception as e:
        logging.debug(f"Failed to fetch timing data: {e}")
        return {}


if __name__ == "__main__":
    import sys
    import yaml

    logging.basicConfig(level=logging.DEBUG)

    release = sys.argv[1] if len(sys.argv) > 1 else "10-stream"
    # When run standalone, construct build_url for the main project directly
    release_num = release.split("-")[0]
    build_url = f"{JENKINS_BASE}/job/NetworkManager-main-c{release_num}s/1/"

    mapper_path = "mapper.yaml"
    if not __file__.endswith("timing_data.py"):
        mapper_path = "../../mapper.yaml"
    else:
        # Try relative to script location
        import os

        script_dir = os.path.dirname(os.path.abspath(__file__))
        candidate = os.path.join(script_dir, "..", "..", "mapper.yaml")
        if os.path.isfile(candidate):
            mapper_path = candidate

    with open(mapper_path) as f:
        mapper_data = yaml.safe_load(f)

    features = get_feature_times(build_url, release, mapper_data)
    if not features:
        print("No timing data retrieved (falling back to mapper timeouts)")
        sys.exit(1)

    total = sum(f["total_minutes"] for f in features.values())
    tests = sum(f["test_count"] for f in features.values())
    print(f"Total: {total:.1f} min, {tests} tests\n")
    for name in sorted(features):
        f = features[name]
        print(
            f"  {name:30s} {f['total_minutes']:6.1f} min "
            f"({f['test_count']:3d} tests, "
            f"avg {f['avg_per_test_minutes']:.2f} min/test)"
        )
