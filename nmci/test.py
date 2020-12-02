#!/usr/bin/env python3

import pytest
import re
import subprocess

from . import misc
from . import util


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
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 26, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 26, 4],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 26, 5],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 26, 6],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 27, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 27, 90],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 27, 91],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 27, 92],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 27, 99],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 28, 0],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 28, 1],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 28, 2],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 28, 99],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 29, 0],
    )
    assert _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 29, 1],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 29, 2],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 29, 3],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 29, 99],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 30, 0],
    )
    assert not _ver_eval(
        [("-", [1, 26, 5]), ("-", [1, 27, 91]), ("-", [1, 28, 0]), ("-", [1, 29, 2]),],
        [1, 30, 2],
    )


def test_feature_tags():

    for feature in ["nmcli", "nmtui"]:
        all_tags = misc.test_load_tags_from_features(feature)

        unique_tags = set()
        for tags in all_tags:
            assert tags
            assert type(tags) is list
            for tag in tags:
                assert type(tag) is str
                assert tag
                assert re.match("^[-a-z_.A-Z0-9+=]+$", tag)
                assert re.match("^" + misc.TEST_NAME_VALID_CHAR_REGEX + "+$", tag)
                if sum([1 for s in tags if s == tag]) != 1:
                    pytest.fail(f'tag "{tag}" is not unique in {tags}')

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

                if tag.startswith("rhbz"):
                    assert re.match("^rhbz[0-9]+$", tag)

            tt = tuple(tags)
            if tt in unique_tags:
                pytest.fail(f'tags "{tags}" are duplicate over the {feature} tests')
            unique_tags.add(tt)


def test_black_code_fromatting():

    files = [
        util.base_dir("nmci"),
        util.base_dir("version_control.py"),
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
