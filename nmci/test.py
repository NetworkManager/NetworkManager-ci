#!/usr/bin/env python3

import pytest
import re
import subprocess
import yaml

from . import ip
from . import misc
from . import util
from . import tags as tag_registry


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

    with open(util.base_dir() + "/mapper.yaml", "r") as mapper_file:
        mapper_content = mapper_file.read()
    mapper_yaml = yaml.load(mapper_content, Loader=yaml.BaseLoader)
    testmappers = [x for x in mapper_yaml["testmapper"]]
    mapper_tests = [
        list(x.keys())[0] for tm in testmappers for x in mapper_yaml["testmapper"][tm]
    ]

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
        return tag in tag_registry.tag_registry

    def check_mapper(tag):
        return tag in mapper_tests

    for feature in ["nmcli", "nmtui"]:
        all_tags = misc.test_load_tags_from_features(feature)

        tag_registry_used = set()
        unique_tags = set()
        for tags in all_tags:
            assert tags
            assert type(tags) is list
            test_in_mapper = False
            for tag in tags:
                assert type(tag) is str
                assert tag
                assert re.match("^[-a-z_.A-Z0-9+=]+$", tag)
                assert re.match("^" + misc.TEST_NAME_VALID_CHAR_REGEX + "+$", tag)
                assert tags.count(tag) == 1, f'tag "{tag}" is not unique in {tags}'
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

            assert test_in_mapper, f"none of {tags} is in mapper"

            tt = tuple(tags)
            if tt in unique_tags:
                pytest.fail(f'tags "{tags}" are duplicate over the {feature} tests')
            unique_tags.add(tt)

        # for tag in tag_registry.tag_tag_registry:
        #    assert tag in tag_registry_used, f'tag "{tag}" is defined but never used'


def test_black_code_fromatting():

    files = [
        util.base_dir(),
    ]

    try:
        proc = subprocess.run(
            ["black", "-q", "--diff"] + files,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError:
        pytest.skip("python black is not available")

    assert not proc.stderr
    assert not proc.stdout
    assert proc.returncode == 0


def test_ip_link_show_all():

    l0 = ip._link_show_all_legacy()
    l1 = ip.link_show_all()

    def _normalize(i):
        return (i["ifindex"], i["ifname"])

    assert [_normalize(i) for i in l0] == [_normalize(i) for i in l1]
