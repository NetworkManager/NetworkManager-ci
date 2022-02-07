#!/usr/bin/env python3

import pytest
import re
import subprocess
import sys
import time

from . import git
from . import ip
from . import misc
from . import util
from . import process


def test_misc_test_version_tag_eval():
    def _ver_eval(ver_tags, version):
        r = misc.test_version_tag_eval(ver_tags, version)
        assert r is True or r is False

        def _invert_op(op):
            if op == "+=":
                return "-"
            if op == "+":
                return "-="
            if op == "-":
                return "+="
            assert op == "-="
            return "+"

        ver_tags_invert = [(_invert_op(op), ver) for op, ver in ver_tags]

        r2 = misc.test_version_tag_eval(ver_tags_invert, version)
        assert r2 is True or r2 is False
        if r == r2:
            pytest.fail(
                f'Version "{version}" is {"satisfied" if r else "unsatisfied"} by {ver_tags}, but it is also wrongly {"satisfied" if r2 else "unsatisfied"} by the inverse {ver_tags_invert}'
            )

        return r

    assert _ver_eval([("+=", [1, 26])], [1, 28, 5])
    assert _ver_eval([("+=", [1, 26])], [1, 26, 5])
    assert _ver_eval([("+=", [1, 26])], [1, 26, 0])
    assert not _ver_eval([("+=", [1, 26])], [1, 25, 6])
    assert not _ver_eval([("+=", [1, 26])], [1, 25, 0])

    assert _ver_eval([("+", [1, 26])], [1, 28, 5])
    assert not _ver_eval([("+", [1, 26])], [1, 26, 5])
    assert not _ver_eval([("+", [1, 26])], [1, 26, 0])
    assert not _ver_eval([("+", [1, 26])], [1, 25, 6])
    assert not _ver_eval([("+", [1, 26])], [1, 25, 0])

    assert not _ver_eval([("-=", [1, 26])], [1, 28, 5])
    assert _ver_eval([("-=", [1, 26])], [1, 26, 5])
    assert _ver_eval([("-=", [1, 26])], [1, 26, 0])
    assert _ver_eval([("-=", [1, 26])], [1, 25, 6])
    assert _ver_eval([("-=", [1, 26])], [1, 25, 0])

    assert not _ver_eval([("-", [1, 26])], [1, 28, 5])
    assert not _ver_eval([("-", [1, 26])], [1, 26, 5])
    assert not _ver_eval([("-", [1, 26])], [1, 26, 0])
    assert _ver_eval([("-", [1, 26])], [1, 25, 6])
    assert _ver_eval([("-", [1, 26])], [1, 25, 0])

    assert _ver_eval([("+=", [1, 26, 0])], [1, 28, 5])
    assert _ver_eval([("+=", [1, 26, 0])], [1, 26, 5])
    assert _ver_eval([("+=", [1, 26, 0])], [1, 26, 0])
    assert not _ver_eval([("+=", [1, 26, 0])], [1, 25, 6])
    assert not _ver_eval([("+=", [1, 26, 0])], [1, 25, 0])

    assert _ver_eval([("+", [1, 26, 0])], [1, 28, 5])
    assert _ver_eval([("+", [1, 26, 0])], [1, 26, 5])
    assert not _ver_eval([("+", [1, 26, 0])], [1, 26, 0])
    assert not _ver_eval([("+", [1, 26, 0])], [1, 25, 6])
    assert not _ver_eval([("+", [1, 26, 0])], [1, 25, 0])

    assert not _ver_eval([("-=", [1, 26, 0])], [1, 28, 5])
    assert not _ver_eval([("-=", [1, 26, 0])], [1, 26, 5])
    assert _ver_eval([("-=", [1, 26, 0])], [1, 26, 0])
    assert _ver_eval([("-=", [1, 26, 0])], [1, 25, 6])
    assert _ver_eval([("-=", [1, 26, 0])], [1, 25, 0])

    assert not _ver_eval([("-", [1, 26, 0])], [1, 28, 5])
    assert not _ver_eval([("-", [1, 26, 0])], [1, 26, 5])
    assert not _ver_eval([("-", [1, 26, 0])], [1, 26, 0])
    assert _ver_eval([("-", [1, 26, 0])], [1, 25, 6])
    assert _ver_eval([("-", [1, 26, 0])], [1, 25, 0])

    assert _ver_eval([("+=", [1, 26, 2])], [1, 28, 5])
    assert _ver_eval([("+=", [1, 26, 2])], [1, 26, 5])
    assert _ver_eval([("+=", [1, 26, 2])], [1, 26, 2])
    assert not _ver_eval([("+=", [1, 26, 2])], [1, 26, 0])
    assert not _ver_eval([("+=", [1, 26, 2])], [1, 25, 6])
    assert not _ver_eval([("+=", [1, 26, 2])], [1, 25, 0])

    assert _ver_eval([("+", [1, 26, 2])], [1, 28, 5])
    assert _ver_eval([("+", [1, 26, 2])], [1, 26, 5])
    assert not _ver_eval([("+", [1, 26, 2])], [1, 26, 2])
    assert not _ver_eval([("+", [1, 26, 2])], [1, 26, 0])
    assert not _ver_eval([("+", [1, 26, 2])], [1, 25, 6])
    assert not _ver_eval([("+", [1, 26, 2])], [1, 25, 0])

    assert not _ver_eval([("-=", [1, 26, 2])], [1, 28, 5])
    assert not _ver_eval([("-=", [1, 26, 2])], [1, 26, 5])
    assert _ver_eval([("-=", [1, 26, 2])], [1, 26, 2])
    assert _ver_eval([("-=", [1, 26, 2])], [1, 26, 0])
    assert _ver_eval([("-=", [1, 26, 2])], [1, 25, 6])
    assert _ver_eval([("-=", [1, 26, 2])], [1, 25, 0])

    assert not _ver_eval([("-", [1, 26, 2])], [1, 28, 5])
    assert not _ver_eval([("-", [1, 26, 2])], [1, 26, 5])
    assert not _ver_eval([("-", [1, 26, 2])], [1, 26, 2])
    assert _ver_eval([("-", [1, 26, 2])], [1, 26, 0])
    assert _ver_eval([("-", [1, 26, 2])], [1, 25, 6])
    assert _ver_eval([("-", [1, 26, 2])], [1, 25, 0])

    assert _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 28, 5])
    assert _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 26, 5])
    assert not _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 26, 2])
    assert not _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 26, 0])
    assert not _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 25, 6])
    assert not _ver_eval([("+", [1, 26, 2]), ("+", [1, 27])], [1, 25, 0])

    assert not _ver_eval(
        [("+=", [1, 26, 8]), ("+=", [1, 28, 6]), ("+=", [1, 29, 4])], [1, 28, 5]
    )
    assert _ver_eval(
        [("+=", [1, 26, 8]), ("+=", [1, 28, 6]), ("+=", [1, 29, 4])], [1, 28, 8]
    )

    assert _ver_eval([("+=", [1, 26, 8]), ("+=", [1, 28])], [1, 28, 5])
    assert _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28])], [1, 29, 0])
    assert not _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28])], [1, 28, 5])
    assert not _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28, 4])], [1, 28, 2])
    assert not _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28, 4])], [1, 28, 4])
    assert _ver_eval([("+=", [1, 26, 8]), ("+=", [1, 28, 4])], [1, 28, 4])
    assert _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28, 4])], [1, 28, 5])
    assert _ver_eval([("+=", [1, 26, 8]), ("+", [1, 28, 4])], [1, 29, 0])

    # the following is a special case during release candidate phase.
    # Imagine a fix/feature gets added to (before) 1.29.3, and also
    # backported to nm-1-28 branch. At that time, 1.28.0 is not yet released,
    # but nm-1-28 is after 1.27.90 and the backport happens (before) 1.27.90.
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 26, 0],
    )
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 26, 4],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 26, 5],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 26, 6],
    )
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 27, 0],
    )
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 27, 90],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 27, 91],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 27, 92],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 27, 99],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 28, 0],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 28, 1],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 28, 2],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 28, 99],
    )
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 29, 0],
    )
    assert not _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 29, 1],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 29, 2],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 29, 3],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 29, 99],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 30, 0],
    )
    assert _ver_eval(
        [
            ("+=", [1, 26, 5]),
            ("+=", [1, 27, 91]),
            ("+=", [1, 28, 0]),
            ("+=", [1, 29, 2]),
        ],
        [1, 30, 2],
    )

    # Now the inverse...
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 26, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 26, 4],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 26, 5],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 26, 6],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 27, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 27, 90],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 27, 91],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 27, 92],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 27, 99],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 28, 0],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 28, 1],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 28, 2],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 28, 99],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 29, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 29, 1],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 29, 2],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 29, 3],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 29, 99],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 30, 0],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2])],
        [1, 30, 2],
    )


def test_misc_nm_version_parse():
    def _assert(version, expect_stream, expect_version):
        (stream, version) = misc.nm_version_parse(version)
        assert expect_stream == stream
        assert expect_version == version

    _assert("1.31.1-28009.copr.067893f8d3.fc33", "upstream", [1, 31, 1, 28009])
    _assert("1.26.0-12.el8_3", "rhel-8-3", [1, 26, 0, 12])
    _assert("1.26.0-12.el8", "rhel-8", [1, 26, 0, 12])
    _assert("1.26.0-0.5.el8", "rhel-8", [1, 26, 0, 0, 5])
    _assert("1.26.0-0.5.el8_10", "rhel-8-10", [1, 26, 0, 0, 5])
    _assert("1.26.0-foo", "unknown", [1, 26, 0])
    _assert("1.26.6-1.fc33", "fedora-33", [1, 26, 6, 1])
    _assert("1.26.6-0.2.fc33", "fedora-33", [1, 26, 6, 0, 2])
    _assert("1.31.2-28040.11545c0ca0.el8", "upstream", [1, 31, 2, 28040])


def test_feature_tags():

    from . import tags

    mapper = misc.get_mapper_obj()
    mapper_tests = misc.get_mapper_tests(mapper)
    mapper_tests = [test["testname"] for test in mapper_tests]

    unique_tags = set()
    tag_registry_used = set()
    all_test_tags = misc.test_load_tags_from_features("*")

    def check_ver(tag):
        for ver_prefix, ver_len in [
            ["ver", 3],
            ["rhelver", 2],
            ["fedoraver", 1],
        ]:
            if not tag.startswith(ver_prefix):
                continue
            op, ver = misc.test_version_tag_parse(tag, ver_prefix)
            assert type(op) is str
            assert type(ver) is list
            assert op in ["+", "+=", "-", "-="]
            assert ver
            assert all([type(v) is int for v in ver])
            assert all([v >= 0 for v in ver])
            assert len(ver) <= ver_len
            assert tag.startswith(ver_prefix + op)
            return True
        return tag in [
            "rhel_pkg",
            "not_with_rhel_pkg",
            "fedora_pkg",
            "not_with_fedora_pkg",
        ]

    def check_bugzilla(tag):
        if tag.startswith("rhbz"):
            assert re.match("^rhbz[0-9]+$", tag)
            return True
        if tag.startswith("gnomebz"):
            assert re.match("^gnomebz[0-9]+$", tag)
            return True
        return False

    def check_registry(tag):
        return tag in tags.tag_registry

    def check_mapper(tag):
        return tag in mapper_tests

    for test_tags in all_test_tags:
        assert test_tags
        assert type(test_tags) is list
        test_in_mapper = False
        for tag in test_tags:
            assert type(tag) is str
            assert tag
            assert re.match("^[-a-z_.A-Z0-9+=]+$", tag)
            assert re.match("^" + misc.TEST_NAME_VALID_CHAR_REGEX + "+$", tag)
            assert (
                test_tags.count(tag) == 1
            ), f'tag "{tag}" is not unique in {test_tags}'
            is_ver = check_ver(tag)
            is_bugzilla = check_bugzilla(tag)
            is_registry = check_registry(tag)
            is_mapper = check_mapper(tag)
            test_in_mapper = test_in_mapper or is_mapper
            if is_registry:
                tag_registry_used.add(tag)
            assert (
                is_ver or is_bugzilla or is_registry or is_mapper
            ), f'tag "{tag}" has no effect'
            assert [is_ver, is_bugzilla, is_registry, is_mapper].count(True) == 1, (
                f'tag "{tag}" is multipurpose ({"mapper, " if is_mapper else ""}'
                f'{"registry, " if is_registry else ""}{"ver, " if is_ver else ""}'
                f'{"bugzilla, " if is_bugzilla else ""})'
            )

        assert test_in_mapper, f"none of {test_tags} is in mapper"

        tt = tuple(test_tags)
        if tt in unique_tags:
            pytest.fail(f'test_tags "{test_tags}" are duplicate')
        unique_tags.add(tt)

    # for tag in tags.tag_tag_registry:
    #    assert tag in tag_registry_used, f'tag "{tag}" is defined but never used'


def test_mapper_feature_file():
    """
    Check that feature defined in mapper coresponds to .feature file name
    """
    mapper = misc.get_mapper_obj()
    mapper_tests = misc.get_mapper_tests(mapper)

    feature_tests = {}

    for test in mapper_tests:
        feature = test.get("feature", None)
        testname = test["testname"]
        if feature is None:
            continue
        if feature not in feature_tests:
            feature_tags = misc.test_load_tags_from_features(feature)
            feature_tests[feature] = feature_tags
        else:
            feature_tags = feature_tests[feature]
        found = False
        for test_tags in feature_tags:
            if testname in test_tags:
                found = True
                break
        assert found, f"test @{testname} not defined in feature file {feature}"


def test_black_code_fromatting():

    files = [
        util.base_dir("nmci"),
        util.base_dir("version_control.py"),
    ]

    exclude = [
        "--exclude",
        "nmci/(tags)\\.py",
    ]

    try:
        proc = subprocess.run(
            ["black", "-q", "--diff"] + exclude + files,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError:
        pytest.skip("python black is not available")

    assert not proc.stderr
    assert not proc.stdout
    assert proc.returncode == 0


def test_process_run():

    assert process.run(["true"]).returncode == 0
    assert process.run(["true"])[0] == 0
    assert process.run("false")[0] == 1

    assert process.run("echo hello", shell=True).stdout == "hello\n"
    assert process.run(["echo hallo"], shell=True, as_bytes=True).stdout == b"hallo\n"

    assert process.run_check(["true"]) == ""
    assert process.run_check("echo hallo") == "hallo\n"

    try:
        process.run("which true")
        has_which = True
    except Exception:
        has_which = False

    if has_which:
        assert process.run("which bogusafsdf", ignore_stderr=True).returncode != 0
        assert process.run("which true").returncode == 0

        assert process.run(["which", "true"]).returncode == 0
        assert process.run(["which", b"true"]).returncode == 0
        assert process.run([b"which", "true"]).returncode == 0
        assert process.run([b"which", b"true"]).returncode == 0

    assert process.run(["sh", "-c", "echo -n hallo"]) == process.RunResult(
        0, "hallo", ""
    )

    assert process.run(["sh", "-c", b"echo -n hallo"]) == process.RunResult(
        0, "hallo", ""
    )

    assert process.run(
        ["sh", b"-c", b"echo -n hallo"], as_bytes=True
    ) == process.RunResult(0, b"hallo", b"")

    r = process.run(
        ["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2"],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == process.RunResult(0, b"hallo", b"hello2")

    with pytest.raises(Exception):
        process.run(["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2"], as_bytes=True)

    r = process.run(
        ["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2; exit 5"],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == process.RunResult(5, b"hallo", b"hello2")

    r = process.run(
        [
            "sh",
            b"-c",
            b"echo -n hallo; echo -n h\x1B[2Jnonutf\xccf\\cello2 >&2; exit 5",
        ],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == process.RunResult(5, b"hallo", b"h\x1b[2Jnonutf\xccfcello2")

    with pytest.raises(Exception):
        process.run(
            [
                "sh",
                b"-c",
                b"echo -n hallo; echo -n h\x1B[2Jnonutf\xccf\\cello2 >&2; exit 5",
            ],
            ignore_stderr=True,
        )

    r = process.run(
        "kill -9 $$", shell=True, ignore_returncode=process.IGNORE_RETURNCODE_ALL
    )
    assert r == process.RunResult(-9, "", "")

    with pytest.raises(Exception):
        process.run("kill -9 $$'", shell=True, ignore_returncode=True)

    assert process.run("exit 15", shell=True, ignore_returncode=True).returncode == 15
    with pytest.raises(Exception):
        process.run("exit 15", shell=True, ignore_returncode=False)

    with pytest.raises(Exception):
        process.run_check("exit 15", shell=True)

    r = process.run(
        "echo -n xstderr >&2 ; echo -n xstdout; exit 77", shell=True, ignore_stderr=True
    )
    assert r == (77, "xstdout", "xstderr")


def test_git_call_ref_parse():

    try:
        process.run_check(["git", "rev-parse", "HEAD"])
    except:
        pytest.skip("not a suitable git repo")

    assert re.match("^[0-9a-f]{40}$", git.call_rev_parse("HEAD"))


def test_git_config_get_origin_url():
    try:
        process.run_check(["git", "config", "--get", "remote.origin.url"])
    except:
        pytest.skip('not a suitable git repo (as no "remote.origin.url")')

    assert git.config_get_origin_url().startswith("https://")


def test_ip_link_show_all():

    l0 = ip.link_show_all(binary=None)

    def _normalize(i):
        return (i["ifindex"], util.str_to_bytes(i["ifname"]), i["flags"])

    assert [_normalize(i) for i in l0] == [_normalize(i) for i in ip.link_show_all()]
    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in ip.link_show_all(binary=None)
    ]
    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in ip.link_show_all(binary=True)
    ]
    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in ip.link_show_all(binary=False)
    ]

    l = ip.link_show(ifname="lo", binary=None)
    assert l["ifname"] == "lo"

    l = ip.link_show(ifname="lo", binary=False)
    assert l["ifname"] == "lo"

    l = ip.link_show(ifname="lo", binary=True)
    assert l["ifname"] == b"lo"


def test_clock_boottime():

    try:
        c = time.CLOCK_BOOTTIME
    except AttributeError:
        assert sys.version_info[:2] < (3, 7)
    else:
        assert c == util.CLOCK_BOOTTIME

    t = time.clock_gettime(util.CLOCK_BOOTTIME)
    assert type(t) is float
    assert t > 0


def test_test_tags_select():

    t = misc.test_tags_select(
        [["ver+=1.4", "ver-=1.20", "foo1"], ["ver+1.21", "foo2"]],
        ("upstream", [1, 5, 0]),
        ("fedora", [34]),
    )
    assert t == ["ver+=1.4", "ver-=1.20", "foo1"]

    t = misc.test_tags_select(
        [["ver+=1.4", "foo1", "fedoraver-33"], ["ver+1.4", "fedoraver+=33", "foo2"]],
        ("upstream", [1, 5, 0]),
        ("fedora", [34]),
    )
    assert t == ["ver+1.4", "fedoraver+=33", "foo2"]

    with pytest.raises(misc.InvalidTagsException) as e:
        misc.test_tags_select(
            [["ver+=1.4", "ver-=1.30", "foo1"], ["ver+=1.21", "foo2"]],
            ("upstream", [1, 21, 0]),
            ("fedora", [34]),
        )

    with pytest.raises(misc.SkipTestException) as e:
        misc.test_tags_select(
            [["ver+=1.4", "ver-=1.20", "foo1"], ["ver+1.21", "foo2"]],
            ("upstream", [1, 2, 0]),
            ("fedora", [34]),
        )
