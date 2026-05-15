#!/usr/bin/python3
"""Fetch per-feature test timing from Jenkins artifact directory listing.

Parses HTML report file timestamps from the last completed main branch
build to compute per-feature durations. Used by node_runner.py Mapper
to distribute tests across machines based on actual measured times.

Can be imported as a module or run standalone for debugging:
    python3 timing_data.py 10-stream
    python3 timing_data.py 9-stream
"""

import logging
import re
import urllib.request


JENKINS_BASE = "https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org"

# Regex to match report filenames and their timestamps in Jenkins HTML
# Format: <a href="[FAIL-]report_NetworkManager-ci-M{id}_Test{NNNN}_{name}.html">
#         ... <td class="fileSize">May 13, 2026, 10:12:43 PM</td>
# Note: Jenkins uses \u202f (narrow no-break space) before AM/PM
_REPORT_RE = re.compile(
    r'<a href="(?:FAIL-)?report_NetworkManager-ci-M(\d+)_Test(\d+)_([^"]+)\.html">'
    r".*?"
    r'<td class="fileSize">\s*'
    r"([A-Z][a-z]+ \d{1,2}, \d{4},\s*\d{1,2}:\d{2}:\d{2}[\s\u202f]*[AP]M)"
    r"\s*</td>",
    re.DOTALL,
)

_TIMESTAMP_FMT = "%b %d, %Y, %I:%M:%S %p"


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


def _fetch_artifact_page(url):
    """Fetch the Jenkins artifact directory listing page."""
    if not url.endswith("/"):
        url += "/"
    req = urllib.request.Request(url, headers={"User-Agent": "NM-CI-timing/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def _parse_report_entries(html):
    """Parse report filenames, machine IDs, test numbers, and timestamps.

    Returns a list of (machine_id, test_number, test_name, timestamp) tuples.
    """
    from datetime import datetime

    entries = []
    seen = set()
    for match in _REPORT_RE.finditer(html):
        machine_id = int(match.group(1))
        test_num = int(match.group(2))
        test_name = match.group(3)
        ts_str = match.group(4)
        # Deduplicate (same file appears multiple times in Jenkins HTML)
        key = (machine_id, test_num, test_name)
        if key in seen:
            continue
        seen.add(key)
        # Strip narrow no-break space and other whitespace variants
        ts_str = re.sub(r"[\s\u202f]+", " ", ts_str).strip()
        try:
            ts = datetime.strptime(ts_str, _TIMESTAMP_FMT)
        except ValueError:
            continue
        entries.append((machine_id, test_num, test_name, ts))
    return entries


def _compute_test_durations(entries):
    """Compute per-test duration in minutes from consecutive timestamps.

    Tests are grouped by machine and sorted by test number.
    Duration of test[i] = timestamp[i+1] - timestamp[i].
    The last test in each machine uses 5 minutes as a default estimate.
    """
    machines = {}
    for machine_id, test_num, test_name, ts in entries:
        machines.setdefault(machine_id, []).append((test_num, test_name, ts))

    durations = {}
    for machine_id in sorted(machines.keys()):
        tests = sorted(machines[machine_id], key=lambda x: x[0])
        for i, (test_num, test_name, ts) in enumerate(tests):
            if i + 1 < len(tests):
                delta = (tests[i + 1][2] - ts).total_seconds() / 60.0
                if delta < 0 or delta > 120:
                    delta = 5.0
            else:
                delta = 5.0
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

    Determines the correct Jenkins project from the current build URL and
    release version, fetches the artifact directory listing of the last
    completed build, parses HTML report timestamps, and computes per-feature
    durations.

    Args:
        build_url: current Jenkins build URL
        release: OS version string (e.g. "10-stream", "9-stream")
        mapper_data: pre-loaded mapper.yaml dict

    Returns:
        dict: feature -> {"total_minutes": float, "test_count": int,
                          "avg_per_test_minutes": float}
        Returns empty dict on any failure.
    """
    try:
        project = _resolve_project(build_url, release)
        artifact_url = f"{JENKINS_BASE}/job/{project}/lastCompletedBuild/artifact/"
        logging.debug(f"Fetching timing data from {artifact_url}")

        html = _fetch_artifact_page(artifact_url)

        entries = _parse_report_entries(html)
        if not entries:
            logging.debug("No report entries found in artifact listing")
            return {}
        logging.debug(f"Parsed {len(entries)} test report timestamps")

        durations = _compute_test_durations(entries)

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
        print("No timing data retrieved")
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
