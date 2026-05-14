#!/usr/bin/python3
"""Fetch test report timestamps from Jenkins artifacts and update timing cache.

Usage:
    python3 update_timing_cache.py <jenkins_artifact_url> [--cache <path>] [--mapper <path>]

Example:
    python3 update_timing_cache.py \
        https://jenkins-networkmanager.apps.ocp.cloud.ci.centos.org/job/NetworkManager-main-c10s/848/artifact/

The script:
1. Fetches the Jenkins artifact directory listing HTML page
2. Parses HTML report filenames and their timestamps
3. Computes per-test duration from consecutive timestamps (within each machine)
4. Maps test names to features using mapper.yaml
5. Aggregates per-feature total time
6. Updates the timing cache JSON file (exponential moving average)
"""

import argparse
import json
import os
import re
import sys
import urllib.request
from datetime import datetime, timezone


# Regex to match report filenames and their timestamps in Jenkins HTML
# Format: <a href="[FAIL-]report_NetworkManager-ci-M{id}_Test{NNNN}_{name}.html">...
#         <td class="fileSize">May 13, 2026, 10:12:43 PM</td>
# Note: Jenkins uses \u202f (narrow no-break space) before AM/PM
REPORT_RE = re.compile(
    r'<a href="(?:FAIL-)?report_NetworkManager-ci-M(\d+)_Test(\d+)_([^"]+)\.html">'
    r".*?"
    r'<td class="fileSize">\s*'
    r"([A-Z][a-z]+ \d{1,2}, \d{4},\s*\d{1,2}:\d{2}:\d{2}[\s\u202f]*[AP]M)"
    r"\s*</td>",
    re.DOTALL,
)

# Timestamp format (the narrow no-break space is stripped before parsing)
TIMESTAMP_FMT = "%b %d, %Y, %I:%M:%S %p"

# Weight for new data in exponential moving average (0.0-1.0)
EMA_WEIGHT = 0.7


def fetch_artifact_page(url):
    """Fetch the Jenkins artifact directory listing page."""
    if not url.endswith("/"):
        url += "/"
    req = urllib.request.Request(url, headers={"User-Agent": "NM-CI-timing-cache/1.0"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read().decode("utf-8", errors="ignore")


def parse_report_entries(html):
    """Parse report filenames, machine IDs, test numbers, and timestamps.

    Returns a list of (machine_id, test_number, test_name, timestamp) tuples.
    """
    entries = []
    seen = set()
    for match in REPORT_RE.finditer(html):
        machine_id = int(match.group(1))
        test_num = int(match.group(2))
        test_name = match.group(3)
        ts_str = match.group(4)
        # Deduplicate (same file appears multiple times in Jenkins HTML)
        key = (machine_id, test_num, test_name)
        if key in seen:
            continue
        seen.add(key)
        # Strip narrow no-break space and other whitespace variants before AM/PM
        ts_str = re.sub(r"[\s\u202f]+", " ", ts_str).strip()
        try:
            ts = datetime.strptime(ts_str, TIMESTAMP_FMT)
        except ValueError:
            print(f"Warning: could not parse timestamp '{ts_str}' for {test_name}")
            continue
        entries.append((machine_id, test_num, test_name, ts))
    return entries


def compute_test_durations(entries):
    """Compute per-test duration in minutes from consecutive timestamps.

    Tests are grouped by machine and sorted by test number.
    Duration of test[i] = timestamp[i+1] - timestamp[i].
    The last test in each machine gets 5 minutes as a default estimate.
    """
    # Group by machine
    machines = {}
    for machine_id, test_num, test_name, ts in entries:
        machines.setdefault(machine_id, []).append((test_num, test_name, ts))

    durations = {}  # test_name -> duration_minutes
    for machine_id in sorted(machines.keys()):
        tests = sorted(machines[machine_id], key=lambda x: x[0])
        for i, (test_num, test_name, ts) in enumerate(tests):
            if i + 1 < len(tests):
                next_ts = tests[i + 1][2]
                delta = (next_ts - ts).total_seconds() / 60.0
                # Sanity: if delta is negative or > 120 min, use default
                if delta < 0 or delta > 120:
                    delta = 5.0
            else:
                # Last test in machine - use default
                delta = 5.0
            durations[test_name] = delta
    return durations


def load_mapper(mapper_path):
    """Load mapper.yaml and build a test_name -> feature mapping."""
    try:
        import yaml
    except ImportError:
        # Fallback: try to parse the essential mapping without pyyaml
        print("Warning: pyyaml not available, cannot map tests to features")
        return {}

    with open(mapper_path) as f:
        mapper = yaml.safe_load(f)

    test_to_feature = {}
    if mapper and "testmapper" in mapper:
        for section in mapper["testmapper"].values():
            if not isinstance(section, list):
                continue
            for test in section:
                for test_name, test_data in test.items():
                    if isinstance(test_data, dict) and "feature" in test_data:
                        test_to_feature[test_name] = test_data["feature"]
    return test_to_feature


def aggregate_by_feature(durations, test_to_feature):
    """Aggregate per-test durations into per-feature totals.

    Returns dict: feature -> {"total_minutes": float, "test_count": int}
    """
    features = {}
    unmapped = 0
    for test_name, duration in durations.items():
        feature = test_to_feature.get(test_name)
        if not feature:
            unmapped += 1
            continue
        if feature not in features:
            features[feature] = {"total_minutes": 0.0, "test_count": 0}
        features[feature]["total_minutes"] += duration
        features[feature]["test_count"] += 1

    if unmapped:
        print(f"Note: {unmapped} tests could not be mapped to a feature")

    # Compute average
    for f_data in features.values():
        if f_data["test_count"] > 0:
            f_data["avg_per_test_minutes"] = round(
                f_data["total_minutes"] / f_data["test_count"], 3
            )
        else:
            f_data["avg_per_test_minutes"] = 10.0
        f_data["total_minutes"] = round(f_data["total_minutes"], 2)

    return features


def update_cache(cache_path, new_features):
    """Load existing cache, merge new data using EMA, and save.

    For features present in both old and new data, the new total is:
        updated = EMA_WEIGHT * new + (1 - EMA_WEIGHT) * old
    For features only in new data, they are added directly.
    For features only in old data, they are kept unchanged.
    """
    cache = {}
    if os.path.isfile(cache_path):
        try:
            with open(cache_path) as f:
                cache = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            print(f"Warning: could not load existing cache: {e}")
            cache = {}

    old_features = cache.get("features", {})
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")

    merged = dict(old_features)
    for feature, new_data in new_features.items():
        if feature in merged:
            old = merged[feature]
            old_total = old.get("total_minutes", new_data["total_minutes"])
            old_avg = old.get("avg_per_test_minutes", new_data["avg_per_test_minutes"])
            merged[feature] = {
                "total_minutes": round(
                    EMA_WEIGHT * new_data["total_minutes"]
                    + (1 - EMA_WEIGHT) * old_total,
                    2,
                ),
                "test_count": new_data["test_count"],
                "avg_per_test_minutes": round(
                    EMA_WEIGHT * new_data["avg_per_test_minutes"]
                    + (1 - EMA_WEIGHT) * old_avg,
                    3,
                ),
                "last_updated": now,
            }
        else:
            merged[feature] = {
                **new_data,
                "last_updated": now,
            }

    cache["features"] = merged

    with open(cache_path, "w") as f:
        json.dump(cache, f, indent=2, sort_keys=True)
        f.write("\n")

    return cache


def main():
    parser = argparse.ArgumentParser(
        description="Update test timing cache from Jenkins artifact timestamps"
    )
    parser.add_argument("url", help="Jenkins artifact directory URL")
    parser.add_argument(
        "--cache",
        default=os.path.join(os.path.dirname(__file__), "timing_cache.json"),
        help="Path to timing cache JSON file (default: timing_cache.json in script dir)",
    )
    parser.add_argument(
        "--mapper",
        default=os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "mapper.yaml"
        ),
        help="Path to mapper.yaml (default: ../../mapper.yaml relative to script)",
    )
    args = parser.parse_args()

    print(f"Fetching artifact listing from {args.url}")
    html = fetch_artifact_page(args.url)

    entries = parse_report_entries(html)
    if not entries:
        print("No report entries found in artifact listing")
        sys.exit(1)
    print(f"Found {len(entries)} test reports")

    durations = compute_test_durations(entries)
    print(f"Computed durations for {len(durations)} tests")

    test_to_feature = load_mapper(args.mapper)
    if not test_to_feature:
        print(f"Warning: no test-to-feature mapping loaded from {args.mapper}")

    features = aggregate_by_feature(durations, test_to_feature)
    print(f"Aggregated {len(features)} features:")
    for f_name in sorted(features.keys()):
        f_data = features[f_name]
        print(
            f"  {f_name}: {f_data['total_minutes']:.1f} min "
            f"({f_data['test_count']} tests, "
            f"avg {f_data['avg_per_test_minutes']:.2f} min/test)"
        )

    cache = update_cache(args.cache, features)
    print(f"\nTiming cache updated: {args.cache}")
    print(f"Total features in cache: {len(cache.get('features', {}))}")


if __name__ == "__main__":
    main()
