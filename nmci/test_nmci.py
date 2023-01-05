#!/usr/bin/env python3

import os
import pytest
import random
import re
import socket
import subprocess
import sys
import tempfile
import time

import nmci


def rnd_bool():
    return random.random() > 0.5


###############################################################################


class Stub:
    def __init__(self, obj, attr, value):
        self.value = value
        self.obj = obj
        self.attr = attr

    def __enter__(self):
        try:
            self.cached = getattr(self.obj, self.attr)
        except Exception:
            self.has = False
        setattr(self.obj, self.attr, self.value)

    def __exit__(self, type, value, traceback):
        if hasattr(self, "cached"):
            setattr(self.obj, self.attr, self.cached)
        else:
            delattr(self.obj, self.attr)

    def __call__(self, func):
        # Stub is a context manager, so we can use it with
        # "with". But it's also callable, so we can use it as
        # function decorator.
        def f():
            with self:
                func()

        return f

    @staticmethod
    def misc_nm_version_detect(version):
        return Stub(nmci.misc, "_nm_version_detect_cached", version)

    @staticmethod
    def misc_distro_detect(version):
        return Stub(nmci.misc, "_distro_detect_cached", version)


###############################################################################


def create_test_context():
    class ContextTest:
        def __init__(self):
            import xml.etree.ElementTree as ET

            class Formatter:
                pass

            formatter = Formatter()
            formatter.name = "html"
            formatter.embedding = None
            formatter.actual = {
                "act_step_embed_span": ET.SubElement(ET.Element("foo"), "span"),
            }
            formatter._doEmbed = lambda span, mime_type, data, caption: None

            class Runner:
                pass

            self._runner = Runner()
            self._runner.formatters = [formatter]

    context = ContextTest()

    nmci.cext.setup(context)

    nmci.embed._to_embed = []
    nmci.cleanup._cleanup_lst = []

    return context


###############################################################################


def test_stub1():

    v = ("fedora", [35])
    assert not hasattr(nmci.misc, "_distro_detect_cached")
    with Stub.misc_distro_detect(v):
        assert nmci.misc._distro_detect_cached is v
        assert nmci.misc.distro_detect() is v
    assert not hasattr(nmci.misc, "_distro_detect_cached")

    v = ("upstream", [1, 39, 3, 30276])
    assert not hasattr(nmci.misc, "_nm_version_detect_cached")
    with Stub.misc_nm_version_detect(v):
        assert nmci.misc._nm_version_detect_cached is v
        assert nmci.misc.nm_version_detect() is v
    assert not hasattr(nmci.misc, "_nm_version_detect_cached")


@Stub.misc_distro_detect(("fedora", [35]))
def test_stub2():
    v = ("fedora", [35])
    assert nmci.misc._distro_detect_cached == v
    assert nmci.misc.distro_detect() == v


@Stub.misc_nm_version_detect(("upstream", [1, 39, 3, 30276]))
def test_stub3():
    v = ("upstream", [1, 39, 3, 30276])
    assert nmci.misc._nm_version_detect_cached == v
    assert nmci.misc.nm_version_detect() == v


###############################################################################


def test_util_compare_strv_list():

    nmci.util.compare_strv_list([], [])

    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(["a"], [])

    nmci.util.compare_strv_list(["a"], ["a"], ignore_order=True)

    nmci.util.compare_strv_list(["a"], ["a"])
    nmci.util.compare_strv_list(["a"], ["a", "b"])
    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(["a"], ["a", "b"], ignore_extra_strv=False)

    nmci.util.compare_strv_list(["a", "b"], ["a", "b"])
    nmci.util.compare_strv_list(["a", "b"], ["b", "a"])
    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(["a", "b"], ["b", "a"], ignore_order=False)

    nmci.util.compare_strv_list(["/^a", "/b"], ["a", "ab"])
    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(["/^a", "b"], ["a", "ab"], match_mode="plain")

    nmci.util.compare_strv_list(
        ["b", "."], ["a", "b"], match_mode="regex", ignore_order=True
    )
    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(
            ["b", "."], ["a", "b"], match_mode="regex", ignore_order=False
        )

    nmci.util.compare_strv_list(
        ["b", "[ac]", "[ac]"], ["a", "b", "c"], match_mode="regex", ignore_order=True
    )
    with pytest.raises(ValueError):
        nmci.util.compare_strv_list(
            ["b", "[ac]", "[ac]"],
            ["a", "b", "c"],
            match_mode="regex",
            ignore_order=False,
        )

    nmci.util.compare_strv_list(["?a"], [], ignore_order=True)
    nmci.util.compare_strv_list(["?a"], ["a"], ignore_order=True)
    nmci.util.compare_strv_list(["?/a", "aa"], ["aa", ""])


def test_util_compare_strv_list_rnd():
    def rnd_match_mode():
        if random.random() < 1.0 / 3:
            return "plain"
        if random.random() < 2.0 / 3:
            return "regex"
        return "auto"

    strv_full = [(chr(c + 97) + "a") for c in range(26)]
    for n_rand in range(100):
        strv_len = random.randint(0, len(strv_full))
        if rnd_bool():
            strv = strv_full[:strv_len]
        else:
            strv = random.choices(strv_full, k=strv_len)

        expected_len = random.randint(0, len(strv))
        expected = strv[:expected_len]
        random.shuffle(expected)

        has_extra_strv = [s for s in strv if (s not in expected)]
        has_same_order = [s for s in strv if (s in expected)] == expected

        expected_regex = []
        for e in expected:
            r = random.random()
            if r < 0.02:
                e = ".*"
            elif r < 0.04:
                e = "a"
            elif r < 0.06:
                e = f"[{e[0]}a]"
            expected_regex.append(e)

        nmci.util.compare_strv_list(
            expected=expected,
            strv=strv,
            match_mode=rnd_match_mode(),
            ignore_extra_strv=(has_extra_strv or rnd_bool()),
            ignore_order=(not has_same_order or rnd_bool()),
        )

        nmci.util.compare_strv_list(
            expected=expected_regex,
            strv=strv,
            match_mode="regex",
            ignore_extra_strv=(has_extra_strv or rnd_bool()),
            ignore_order=(not has_same_order or rnd_bool()),
        )

        if has_extra_strv:
            with pytest.raises(ValueError):
                nmci.util.compare_strv_list(
                    expected=expected,
                    strv=strv,
                    match_mode=rnd_match_mode(),
                    ignore_extra_strv=False,
                    ignore_order=True,
                )
        if has_same_order:
            nmci.util.compare_strv_list(
                expected=expected,
                strv=strv,
                match_mode=rnd_match_mode(),
                ignore_extra_strv=has_extra_strv or rnd_bool(),
                ignore_order=False,
            )


def test_misc_test_version_tag_eval():
    def _assert_ver(ver_tags, *versions):

        SATISFIED = {True: "satisfied", False: "unsatisfied"}

        def _ver_parse(version):
            assert re.match("^[0-9.]+$", version)
            return [int(x) for x in version.split(".")]

        def _ver_parse_tag(version):
            if version.startswith("+=") or version.startswith("-="):
                op = version[:2]
            elif version.startswith("+") or version.startswith("-"):
                op = version[:1]
            else:
                raise Exception(
                    f'Invalid version tag "{version}" (does not start with +/-/+=/-=)'
                )
            return op, _ver_parse(version[len(op) :])

        def _ver_parse_check(version):
            if (
                version.endswith("+-")
                or version.endswith("-+")
                or version.endswith("++")
                or version.endswith("--")
            ):
                op, version = version[-2:], version[: len(version) - 2]
            else:
                raise Exception(
                    f'Invalid check version "{version}" (does not end with +-/-+/++/--)'
                )
            return op, _ver_parse(version)

        def _invert_op(op):
            if op == "+=":
                return "-"
            if op == "+":
                return "-="
            if op == "-":
                return "+="
            assert op == "-="
            return "+"

        ver_tags_parsed = [_ver_parse_tag(v) for v in ver_tags.split(" ") if v]
        versions_parsed = [_ver_parse_check(v) for v in versions]

        ver_tags_invert = [(_invert_op(op), ver) for op, ver in ver_tags_parsed]

        for check_op, version in versions_parsed:
            r = nmci.misc.test_version_tag_eval(ver_tags_parsed, version)
            assert r is True or r is False
            expected = check_op[0] == "+"
            if expected != r:
                pytest.fail(
                    f'Version "{version}" is wrongly {SATISFIED[r]} for "{ver_tags}"'
                )

            r = nmci.misc.test_version_tag_eval(ver_tags_invert, version)
            assert r is True or r is False
            expected = check_op[1] == "+"
            if expected != r:
                pytest.fail(
                    f'Version "{version}" is wrongly {SATISFIED[r]} for inverted version "{ver_tags}"'
                )

    _assert_ver(
        "+=1.26",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0+-",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "+1.26",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0-+",
        "1.26.5-+",
        "1.28.5+-",
    )

    _assert_ver(
        "-=1.26",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0+-",
        "1.26.5+-",
        "1.28.5-+",
    )

    _assert_ver(
        "-1.26",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0-+",
        "1.26.5-+",
        "1.28.5-+",
    )

    _assert_ver(
        "+=1.26.0",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0+-",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "+1.26.0",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0-+",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "-=1.26.0",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0+-",
        "1.26.5-+",
        "1.28.5-+",
    )

    _assert_ver(
        "-1.26.0",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0-+",
        "1.26.5-+",
        "1.28.5-+",
    )

    _assert_ver(
        "+=1.26.2",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0-+",
        "1.26.2+-",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "+1.26.2",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0-+",
        "1.26.2-+",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "-=1.26.2",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0+-",
        "1.26.2+-",
        "1.26.5-+",
        "1.28.5-+",
    )

    _assert_ver(
        "-1.26.2",
        "1.25.0+-",
        "1.25.6+-",
        "1.26.0+-",
        "1.26.2-+",
        "1.26.5-+",
        "1.28.5-+",
    )

    _assert_ver(
        "+1.26.2 +1.27",
        "1.25.0-+",
        "1.25.6-+",
        "1.26.0-+",
        "1.26.2-+",
        "1.26.5+-",
        "1.28.5+-",
    )

    _assert_ver(
        "+=1.26.8 +=1.28.6 +=1.29.4",
        "1.28.5-+",
        "1.28.8+-",
    )

    _assert_ver(
        "+=1.26.8 +=1.28",
        "1.28.5+-",
        "1.29.0+-",
        "1.28.4+-",
        "1.28.5+-",
        "1.29.0+-",
    )
    _assert_ver(
        "+=1.26.8 +1.28",
        "1.28.5-+",
        "1.28.2-+",
        "1.28.4-+",
    )

    # the following is a special case during release candidate phase.
    # Imagine a fix/feature gets added to (before) 1.29.3.and also
    # backported to nm-1-28 branch. At that time.1.28.0 is not yet released,
    # but nm-1-28 is after 1.27.90 and the backport happens (before) 1.27.90.
    _assert_ver(
        "+=1.26.5 +=1.27.91 +=1.28.0 +=1.29.2",
        "1.26.0-+",
        "1.26.4-+",
        "1.26.5+-",
        "1.26.6+-",
        "1.27.0-+",
        "1.27.90-+",
        "1.27.91+-",
        "1.27.92+-",
        "1.27.99+-",
        "1.28.0+-",
        "1.28.1+-",
        "1.28.2+-",
        "1.28.99+-",
        "1.29.0-+",
        "1.29.1-+",
        "1.29.2+-",
        "1.29.3+-",
        "1.29.99+-",
        "1.30.0+-",
        "1.30.2+-",
    )

    # Now the inverse...
    _assert_ver(
        "-1.26.5 -1.27.91 -1.28.0 -1.29.2",
        "1.26.0+-",
        "1.26.4+-",
        "1.26.5-+",
        "1.26.6-+",
        "1.27.0+-",
        "1.27.90+-",
        "1.27.91-+",
        "1.27.92-+",
        "1.27.99-+",
        "1.28.0-+",
        "1.28.1-+",
        "1.28.2-+",
        "1.28.99-+",
        "1.29.0+-",
        "1.29.1+-",
        "1.29.2-+",
        "1.29.3-+",
        "1.29.99-+",
        "1.30.0-+",
        "1.30.2-+",
    )

    # check all subintervals in mixed ranges: +++1.26.5---1.27.91+++1.28.0---1.29.2+++++
    # _assert_ver also check inverted intervals
    _assert_ver(
        "-1.26.5 +1.27.91 -1.28.0 +=1.29.2",
        "1.24.2+-",
        "1.26.0+-",
        "1.26.2+-",
        "1.26.5-+",
        "1.26.8-+",
        "1.27.0-+",
        "1.27.91-+",
        "1.27.99+-",
        "1.28.0-+",
        "1.28.2-+",
        "1.29.0-+",
        "1.29.2+-",
        "1.30.2+-",
    )

    _assert_ver(
        "+=1.26.5 -=1.27.91 +=1.28.0 -1.29.2",
        "1.24.2-+",
        "1.26.0-+",
        "1.26.2-+",
        "1.26.5+-",
        "1.26.8+-",
        "1.27.0+-",
        "1.27.91+-",
        "1.27.99-+",
        "1.28.0+-",
        "1.28.2+-",
        "1.29.0+-",
        "1.29.2-+",
        "1.30.2-+",
    )

    # Check mixed intervals with large holes and overlaping intervals
    _assert_ver(
        "+=1.26.5 +=1.28.4 -=1.34.2 -=1.36.2 +=1.40",
        "1.20.1-+",
        "1.26.1-+",
        "1.26.5+-",
        "1.26.6+-",
        "1.27.0++",
        "1.27.4++",
        "1.28.1-+",
        "1.28.4+-",
        "1.28.6+-",
        "1.30.0+-",
        "1.34.0+-",
        "1.34.2+-",
        "1.34.3-+",
        "1.35.0++",
        "1.35.3++",
        "1.36.0+-",
        "1.36.1+-",
        "1.36.2+-",
        "1.36.3-+",
        "1.38.0-+",
        "1.39.5-+",
        "1.40.0+-",
        "1.40.5+-",
        "1.50.5+-",
    )

    # and inverted tags
    _assert_ver(
        "-1.26.5 -1.28.4 +1.34.2 +1.36.2 -1.40",
        "1.20.1+-",
        "1.26.1+-",
        "1.26.5-+",
        "1.26.6-+",
        "1.27.0++",
        "1.27.4++",
        "1.28.1+-",
        "1.28.4-+",
        "1.28.6-+",
        "1.30.0-+",
        "1.34.0-+",
        "1.34.2-+",
        "1.34.3+-",
        "1.35.0++",
        "1.35.3++",
        "1.36.0-+",
        "1.36.1-+",
        "1.36.2-+",
        "1.36.3+-",
        "1.38.0+-",
        "1.39.5+-",
        "1.40.0-+",
        "1.40.5-+",
        "1.50.5-+",
    )

    # Fix in the same release multiple times
    _assert_ver(
        "+=1.20.2 -1.20.5 +1.20.7 -1.20.10",
        "1.2.1-+",
        "1.20.1-+",
        "1.20.10-+",
        "1.20.16-+",
        "1.20.2+-",
        "1.20.3+-",
        "1.20.4+-",
        "1.20.5-+",
        "1.20.6-+",
        "1.20.7-+",
        "1.20.8+-",
        "1.20.9+-",
        "1.30.4-+",
    )

    _assert_ver(
        "-1.20.2 +=1.20.5 -=1.20.7 +=1.20.10",
        "1.2.1+-",
        "1.20.0+-",
        "1.20.1+-",
        "1.20.10+-",
        "1.20.16+-",
        "1.20.2-+",
        "1.20.3-+",
        "1.20.4-+",
        "1.20.5+-",
        "1.20.6+-",
        "1.20.7+-",
        "1.20.8-+",
        "1.20.9-+",
        "1.30.4+-",
    )


def test_misc_nm_version_parse():
    def _assert(version, expect_stream, expect_version):
        assert (expect_stream, expect_version) == nmci.misc.nm_version_parse(version)

    _assert("1.31.1-28009.copr.067893f8d3.fc33", "upstream", [1, 31, 1, 28009])
    _assert("1.26.0-12.el8_3", "rhel-8-3", [1, 26, 0, 12])
    _assert("1.26.0-12.el8", "rhel-8", [1, 26, 0, 12])
    _assert("1.26.0-0.5.el8", "rhel-8", [1, 26, 0, 0, 5])
    _assert("1.26.0-0.5.el8_10", "rhel-8-10", [1, 26, 0, 0, 5])
    _assert("1.26.0-foo", "unknown", [1, 26, 0])
    _assert("1.26.6-1.fc33", "fedora-33", [1, 26, 6, 1])
    _assert("1.26.6-0.2.fc33", "fedora-33", [1, 26, 6, 0, 2])
    _assert("1.31.2-28040.11545c0ca0.el8", "upstream", [1, 31, 2, 28040])
    _assert("1.36.0-9.rh1000000.1.el8_6", "rhel-8-6", [1, 36, 0, 9])
    _assert("1.36.0-9.rh1000000.1.el8", "rhel-8", [1, 36, 0, 9])
    _assert("1.31.2-28040.11545c0ca0.el8", "upstream", [1, 31, 2, 28040])
    _assert("1.36.0-9.19.rh1000000.1.el8", "rhel-8", [1, 36, 0, 9, 19])
    _assert("1.36.0-10009.19.rh1000000.1.el8", "upstream", [1, 36, 0, 10009, 19])


def test_misc_test_version_tag_parse_ver():
    def _assert(version_tag, expect_stream, expect_op, expect_version):
        (stream, op, version) = nmci.misc.test_version_tag_parse_ver(version_tag)
        assert expect_stream == stream
        assert expect_op == op
        assert expect_version == version

    def _assert_inval(version_tag):
        with pytest.raises(ValueError):
            nmci.misc.test_version_tag_parse_ver(version_tag)

    _assert("ver+=1", [], "+=", [1])
    _assert("ver/rhel+=1", ["rhel"], "+=", [1])
    _assert("ver/rhel/8+=1", ["rhel", "8"], "+=", [1])

    _assert_inval("ver/rhel/8")
    _assert_inval("ver/rhel/8/+=1")
    _assert_inval("ver/rhel//8+=1")


def test_misc_test_version_tag_filter_for_stream():
    def _assert(nm_stream, version_tags, expected_tags):
        tags2 = [nmci.misc.test_version_tag_parse_ver(v) for v in version_tags]
        tags3 = nmci.misc.test_version_tag_filter_for_stream(tags2, nm_stream)

        exp2 = [nmci.misc.test_version_tag_parse(e, "") for e in expected_tags]
        assert tags3 == exp2

    _assert("rhel-8", ["ver+5"], ["+5"])
    _assert("rhel-8", ["ver+5", "ver/rhel+6"], ["+6"])
    _assert("rhel-8", ["ver+5", "ver/rhel/8+7"], ["+7"])
    _assert("rhel-8", ["ver+5", "ver/rhel/7+7"], ["+5"])


def test_misc_list_to_intervals():
    lst = list(range(8)) + list(range(10, 12)) + list(range(20, 30)) + [34]
    lst_str = nmci.misc.list_to_intervals(lst)
    assert lst_str == "0..7,10,11,20..29,34"

    lst = [1]
    lst_str = nmci.misc.list_to_intervals(lst)
    assert lst_str == "1"

    lst = [3, 4]
    lst_str = nmci.misc.list_to_intervals(lst)
    assert lst_str == "3,4"

    lst = [3, 4, 5]
    lst_str = nmci.misc.list_to_intervals(lst)
    assert lst_str == "3..5"


def test_misc_format_dict():
    dct = {"a": "x", "b": "y"}
    dct_str = nmci.misc.format_dict(dct)
    assert dct_str == "a = x, b = y"

    dct_str = nmci.misc.format_dict(dct, connector=":", separator=";")
    assert dct_str == "a:x;b:y"

    dct = {"a": "x"}
    dct_str = nmci.misc.format_dict(dct)
    assert dct_str == "a = x"

    dct = {}
    dct_str = nmci.misc.format_dict(dct)
    assert dct_str == ""


def test_misc_str_replace_dict():
    dct = {"a": "x", "b": "y", "ab": "hey"}
    result_str = nmci.misc.str_replace_dict("Hello <noted:a>, I am <noted:b>.", dct)
    assert result_str == "Hello x, I am y."

    result_str = nmci.misc.str_replace_dict(
        "Hello <d:a>, I am <d:b>.", dct, dict_name="d"
    )
    assert result_str == "Hello x, I am y."

    result_str = nmci.misc.str_replace_dict(
        "Hello <d:a>, I am <x:ab>.", dct, dict_name="d"
    )
    assert result_str == "Hello x, I am <x:ab>."
    result_str = nmci.misc.str_replace_dict(result_str, dct, dict_name="x")
    assert result_str == "Hello x, I am hey."

    # empty dict, nothing to replace
    assert nmci.misc.str_replace_dict("do not change", {}) == "do not change"

    # invalid key
    with pytest.raises(AssertionError):
        result_str = nmci.misc.str_replace_dict(
            "Hello <d:z>, I am <d:b>.", dct, dict_name="d"
        )

    # unterminated sequence
    with pytest.raises(AssertionError):
        result_str = nmci.misc.str_replace_dict(
            "Hello <d:a, I am <d:b>.", dct, dict_name="d"
        )


def test_feature_tags():

    from . import tags

    mapper = nmci.misc.get_mapper_obj()
    mapper_tests = nmci.misc.get_mapper_tests(mapper)
    mapper_tests = [test["testname"] for test in mapper_tests]

    unique_tags = set()
    tag_registry_used = set()
    all_test_tags = nmci.misc.test_load_tags_from_features("*")

    def check_ver(tag):
        for ver_prefix, ver_len in [
            ["ver", 3],
            ["rhelver", 2],
            ["fedoraver", 1],
        ]:
            if not tag.startswith(ver_prefix):
                continue
            if ver_prefix == "ver":
                stream, op, ver = nmci.misc.test_version_tag_parse_ver(tag)
                assert type(stream) is list
            else:
                stream = None
                op, ver = nmci.misc.test_version_tag_parse(tag, ver_prefix)
            assert type(op) is str
            assert type(ver) is list
            assert op in ["+", "+=", "-", "-="]
            if ver == []:
                assert op in ["+", "-"]
            else:
                assert ver
            assert all([type(v) is int for v in ver])
            assert all([v >= 0 for v in ver])
            if ver_prefix == "ver":
                assert ver_len == 3
                if not stream:
                    assert len(ver) <= 3
                elif stream[0] == "rhel":
                    assert len(ver) <= 4
                else:
                    assert len(ver) <= 3
            else:
                assert len(ver) <= ver_len
            if ver_prefix == "ver":
                assert type(stream) is list
                assert tag.startswith("/".join(("ver", *stream)) + op)
            else:
                assert tag.startswith(ver_prefix + op)
            assert tag == (
                "/".join((ver_prefix, *(stream or [])))
                + op
                + ".".join(str(v) for v in ver)
            )
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

    assert check_ver("ver+=1.3")
    assert ([], "+=", [1, 3]) == nmci.misc.test_version_tag_parse_ver("ver+=1.03")
    with pytest.raises(AssertionError):
        assert check_ver("ver+=1.03")

    for test_tags in all_test_tags:
        assert test_tags
        assert type(test_tags) is list
        test_in_mapper = False
        for tag in test_tags:
            assert type(tag) is str
            assert tag
            assert re.match("^[-a-z_.A-Z0-9+=/]+$", tag)
            assert re.match("^[" + nmci.misc.TEST_NAME_VALID_CHAR_SET + "]+$", tag)
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
    mapper = nmci.misc.get_mapper_obj()
    mapper_tests = nmci.misc.get_mapper_tests(mapper)

    feature_tests = {}

    for test in mapper_tests:
        feature = test.get("feature", None)
        testname = test["testname"]
        if feature is None:
            continue
        if feature not in feature_tests:
            feature_tags = nmci.misc.test_load_tags_from_features(feature)
            feature_tests[feature] = feature_tags
        else:
            feature_tags = feature_tests[feature]
        found = False
        for test_tags in feature_tags:
            if testname in test_tags:
                found = True
                break
        assert found, f"test @{testname} not defined in feature file {feature}"


def test_scen_uniqueness_in_mapper():
    """
    Each test name is:
      * tagged with just one mapper feature
      * found in just one feature file
    """
    mapper_tests = nmci.misc.get_mapper_tests(nmci.misc.get_mapper_obj())
    feature_files = frozenset(nmci.misc.test_get_feature_files())

    # convert mapper_tests to:
    # {'test1': ['feature_a'], 'test2': ['feature_b']}
    # and assert that length of every list in values is 1
    tests_dict = dict()
    for mapper_test in mapper_tests:
        testname = mapper_test["testname"]
        if "feature" not in mapper_test:
            # tests that have to be manually enabled by uncommenting feature
            # as of now @gsm_hub and @gsm_hub_simple
            continue
        feature = mapper_test["feature"]
        if testname not in tests_dict:
            tests_dict[testname] = {feature}
        else:
            tests_dict[testname].add(feature)

    # test mapper uniqueness: only one feature is in set in tests_dict['testname']
    for i in tests_dict:
        assert len(tests_dict[i]) == 1, (
            f"Expected @{i} tagged with exactly one feature, got "
            # back to this when we convert featureless_tests to sth else (another tag?)
            # f"""{'0' if len(tests_dict[i]) == 0 else f'{tests_dict[i]}'}"""
            f"{tests_dict[i]}"
        )

    # test uniqueness in feature files
    path_tmpl = (f"{nmci.util.base_dir('features', 'scenarios')}/", ".feature")
    for i in tests_dict:
        correct_feature = tests_dict[i].pop()
        filtered_files = feature_files.difference(correct_feature.join(path_tmpl))
        for file in filtered_files:
            match = re.search(
                rf"\n\s*@{i}(\s*#[^\n]*)?\n(\s*#[^\n]*\n)*\s*Scenario:",
                file,
            )
            assert (
                match is None
            ), f"in addition to {correct_feature}.feature, {i} was found in {file}"


def test_last_scen_tag_is_test_tag_and_correctly_tagged():
    """
    Last scenario tag:
      * is alone on the line (save for whitespace and comment)
      * exists in mapper
      * is correctly tagged with some feature in mapper, or
        exists without feature (to handle tags with feature
        commented out that have to be enabled manually)
      * does not end with suffix "_timeout"
    """
    mapper_tests = nmci.misc.get_mapper_tests(nmci.misc.get_mapper_obj())
    feature_files = frozenset(nmci.misc.test_get_feature_files())

    # do this before mapper_tests conversion
    featureless_tests = set(i["testname"] for i in mapper_tests if "feature" not in i)

    # convert to dict so we can use feature = mapper_tests[i]
    mapper_tests = {i["testname"]: i["feature"] for i in mapper_tests if "feature" in i}

    re_last_tag = re.compile(
        r"(?P<full>\n\s*(?P<garbage_before_last_tag>[^\n#]*)@(?P<last_tag>[^#\s\n]+)(\s*#[^\n]*)?\n(\s*#[^\n]*\n)*\s*Scenario:[^\n]*\n)"
    )

    for file in feature_files:
        assert file.endswith(
            ".feature"
        ), f"feature file {file} must end with '.feature'"
        feature = os.path.basename(file)[:-8]
        with open(file, "r") as f:
            # returns: [{'garbage_before_last_tag': '',
            #               last_tag: 'test_id', full: '@tag\n Scenario:'}, ...]
            last_tags = [m.groupdict() for m in re_last_tag.finditer(f.read())]
        for tag in last_tags:
            assert len(tag["garbage_before_last_tag"]) == 0, (
                f"before last scenario tag @{tag['last_tag']} in file "
                f"{file}, there is something: "
                f"'{tag['garbage_before_last_tag']}'. Full lines "
                f"are:{tag['full']}"
            )
            assert not tag["last_tag"].endswith(
                "_timeout"
            ), f"test @{tag['last_tag']} ends with '_timeout'"
            if tag["last_tag"] in featureless_tests:
                continue
            assert tag["last_tag"] in (
                mapper_tests.keys()
            ), f"@{tag['last_tag']} not found in test mapper tests!"
            assert feature == mapper_tests[tag["last_tag"]], (
                f"features don't match for @{tag['last_tag']} in file "
                f"{file}, thus expecting mapper feature {feature}, but "
                f"mapper feature is {mapper_tests[tag['last_tag']]}!"
            )


def test_file_set_content(tmp_path):
    fn = tmp_path / "test-file-set-content"

    nmci.util.file_set_content(fn)
    with open(fn, "rb") as f:
        assert b"" == f.read()
    os.remove(fn)

    nmci.util.file_set_content(fn, [])
    with open(fn, "rb") as f:
        assert b"" == f.read()
    os.remove(fn)

    nmci.util.file_set_content(fn, ["Test"])
    with open(fn, "rb") as f:
        assert b"Test\n" == f.read()

    assert (b"Test\n", True) == nmci.util.file_get_content(fn, encoding=None)
    assert nmci.util.FileGetContentResult("Test\n", True) == nmci.util.file_get_content(
        fn
    )
    assert ("Tes", False) == nmci.util.file_get_content(
        fn, max_size=3, warn_max_size=False
    )
    assert (
        "Tes\n\nWARNING: size limit reached after reading 3 of 5 bytes. Output is truncated",
        False,
    ) == nmci.util.file_get_content(fn, max_size=3)
    assert ("Test", False) == nmci.util.file_get_content(
        fn, max_size=4, warn_max_size=False
    )
    assert ("Test\n", True) == nmci.util.file_get_content(fn, max_size=5)

    d = nmci.util.file_get_content(fn, max_size=6, warn_max_size=False)
    assert "Test\n" == d.data
    assert d.full_file is True

    nmci.util.file_set_content(fn, [])
    with open(fn, "rb") as f:
        assert b"" == f.read()

    nmci.util.file_set_content(fn, [""])
    with open(fn, "rb") as f:
        assert b"\n" == f.read()

    nmci.util.file_set_content(fn, [b"bin_data:", b"\x01\xF2\x03\x04"])
    with open(fn, "rb") as f:
        assert b"bin_data:\n\x01\xF2\x03\x04\n" == f.read()

    assert (b"bin_data:\n\x01\xF2\x03\x04\n", True) == nmci.util.file_get_content(
        fn, encoding=None
    )

    assert (b"bin_data:\n\x01\xF2", False) == nmci.util.file_get_content(
        fn, encoding=None, max_size=12, warn_max_size=False
    )

    assert (b"bin_data:\n\x01\xF2\x03", False) == nmci.util.file_get_content(
        fn, encoding=None, max_size=13, warn_max_size=False
    )

    with pytest.raises(UnicodeDecodeError):
        assert ("bin_data:\n\x01�\x03\x04\n", True) == nmci.util.file_get_content(fn)

    with pytest.raises(UnicodeDecodeError):
        assert ("bin_data:\n\x01�\x03\x04\n", True) == nmci.util.file_get_content(
            fn, errors="strict"
        )

    assert ("bin_data:\n\x01�\x03\x04\n", True) == nmci.util.file_get_content(
        fn, errors="replace"
    )
    assert ("bin_data:\n\x01", False) == nmci.util.file_get_content(
        fn, errors="replace", max_size=11, warn_max_size=False
    )
    assert ("bin_data:\n\x01�", False) == nmci.util.file_get_content(
        fn, errors="replace", max_size=12, warn_max_size=False
    )
    assert ("bin_data:\n\x01�\x03", False) == nmci.util.file_get_content(
        fn, errors="replace", max_size=13, warn_max_size=False
    )

    os.remove(fn)

    nmci.util.file_set_content(fn, ("line1", "line2"))
    with open(fn, "r") as f:
        assert "line1\nline2\n" == f.read()
    os.remove(fn)

    def line_range(prefix, n):
        i = 0
        while i < n:
            yield prefix + str(i)
            i += 1

    nmci.util.file_set_content(fn, line_range("line:", 3))
    with open(fn, "r") as f:
        assert "line:0\nline:1\nline:2\n" == f.read()
    os.remove(fn)

    nmci.util.file_set_content(fn, "this message\n should not be modified")
    with open(fn, "r") as f:
        assert "this message\n should not be modified" == f.read()
    os.remove(fn)


def test_process_run():

    assert nmci.process.run(["true"]).returncode == 0
    assert nmci.process.run(["true"])[0] == 0
    assert nmci.process.run("false")[0] == 1

    assert nmci.process.run("echo hello", shell=True).stdout == "hello\n"
    assert (
        nmci.process.run(["echo hallo"], shell=True, as_bytes=True).stdout == b"hallo\n"
    )

    assert nmci.process.run_stdout(["true"]) == ""
    assert nmci.process.run_stdout("echo hallo") == "hallo\n"

    try:
        nmci.process.run("which true")
        has_which = True
    except Exception:
        has_which = False

    if has_which:
        assert nmci.process.run("which bogusafsdf", ignore_stderr=True).returncode != 0
        assert nmci.process.run("which true").returncode == 0

        assert nmci.process.run(["which", "true"]).returncode == 0
        assert nmci.process.run(["which", b"true"]).returncode == 0
        assert nmci.process.run([b"which", "true"]).returncode == 0
        assert nmci.process.run([b"which", b"true"]).returncode == 0

    assert nmci.process.run(["sh", "-c", "echo -n hallo"]) == nmci.process.RunResult(
        0, "hallo", ""
    )

    assert nmci.process.run(["sh", "-c", b"echo -n hallo"]) == nmci.process.RunResult(
        0, "hallo", ""
    )

    assert nmci.process.run(
        ["sh", b"-c", b"echo -n hallo"], as_bytes=True
    ) == nmci.process.RunResult(0, b"hallo", b"")

    r = nmci.process.run(
        ["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2"],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == nmci.process.RunResult(0, b"hallo", b"hello2")

    with pytest.raises(Exception):
        nmci.process.run(
            ["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2"], as_bytes=True
        )

    r = nmci.process.run(
        ["sh", b"-c", b"echo -n hallo; echo -n hello2 >&2; exit 5"],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == nmci.process.RunResult(5, b"hallo", b"hello2")

    r = nmci.process.run(
        [
            "sh",
            b"-c",
            b"echo -n hallo; echo -n h\x1B[2Jnonutf\xccf\\cello2 >&2; exit 5",
        ],
        as_bytes=True,
        ignore_stderr=True,
    )
    assert r == nmci.process.RunResult(5, b"hallo", b"h\x1b[2Jnonutf\xccfcello2")

    with pytest.raises(Exception):
        nmci.process.run(
            [
                "sh",
                b"-c",
                b"echo -n hallo; echo -n h\x1B[2Jnonutf\xccf\\cello2 >&2; exit 5",
            ],
            ignore_stderr=True,
        )

    r = nmci.process.run(
        "kill -9 $$", shell=True, ignore_returncode=nmci.process.IGNORE_RETURNCODE_ALL
    )
    assert r == nmci.process.RunResult(-9, "", "")

    with pytest.raises(Exception):
        nmci.process.run("kill -9 $$'", shell=True, ignore_returncode=True)

    assert (
        nmci.process.run("exit 15", shell=True, ignore_returncode=True).returncode == 15
    )
    with pytest.raises(Exception):
        nmci.process.run("exit 15", shell=True, ignore_returncode=False)

    with pytest.raises(Exception):
        nmci.process.run_stdout("exit 15", shell=True)

    r = nmci.process.run(
        "echo -n xstderr >&2 ; echo -n xstdout; exit 77", shell=True, ignore_stderr=True
    )
    assert r == (77, "xstdout", "xstderr")

    assert nmci.process.run_search_stdout("echo hallo", "hallo")
    assert nmci.process.run_search_stdout("echo hallo", b"hallo")
    assert not nmci.process.run_search_stdout("echo Hallo", b"hallo")
    assert nmci.process.run_search_stdout("echo -e 'Hallo\nworld'", "Hallo.*world")
    assert not nmci.process.run_search_stdout(
        "echo -e 'Hallo\nworld'", "Hallo.*world", pattern_flags=0
    )
    assert nmci.process.run_search_stdout("echo Hallo", b"hallo", pattern_flags=re.I)

    assert nmci.process.run_search_stdout(
        "echo hallo", re.compile(b"h"), pattern_flags=0
    )
    assert nmci.process.run_search_stdout(
        "echo hallo", re.compile("h"), pattern_flags=0
    )
    assert nmci.process.run_search_stdout("echo", re.compile("^"), pattern_flags=0)

    m = nmci.process.run_search_stdout(
        "echo -n hallo", re.compile("^h(all.)$"), pattern_flags=0
    )
    assert m
    assert m.group(1) == "allo"

    m = nmci.process.run_search_stdout(
        "echo -n hallo", re.compile(b"^h(all.)$"), pattern_flags=0
    )
    assert m
    assert m.group(1) == b"allo"

    assert not nmci.process.run_search_stdout(
        "echo Hallo >&2", b"hallo", shell=True, ignore_stderr=True, pattern_flags=re.I
    )

    assert nmci.process.run_search_stdout(
        "echo stderr >&2; echo hallo",
        b"hall[o]",
        shell=True,
        ignore_stderr=True,
        pattern_flags=re.I,
    )

    with pytest.raises(Exception):
        assert nmci.process.run_search_stdout(
            "echo Hallo >&2", b"hallo", shell=True, pattern_flags=re.I
        )

    assert os.getcwd() + "\n" == nmci.process.run_stdout("pwd", cwd=None)

    assert os.getcwd() + "\n" == nmci.process.run_stdout("pwd", shell=True, cwd=None)

    assert nmci.util.base_dir() + "\n" == nmci.process.run_stdout("pwd")

    assert nmci.util.base_dir() + "\n" == nmci.process.run_stdout("pwd", shell=True)

    d = nmci.util.base_dir("nmci")
    assert d + "\n" == nmci.process.run_stdout("pwd", shell=True, cwd=d)

    d = nmci.util.base_dir("nmci/helpers")
    assert d + "\n" == nmci.process.run_stdout("pwd", cwd=d)

    os.environ["NMCI_TEST_XXX1"] = "global"

    assert f"foo//{os.environ.get('NMCI_TEST_XXX1')}" == nmci.process.run_stdout(
        'echo -n "$HI//$NMCI_TEST_XXX1"', shell=True, env_extra={"HI": "foo"}
    )

    assert "foo//" == nmci.process.run_stdout(
        'echo -n "$HI//$NMCI_TEST_XXX1"', shell=True, env={"HI": "foo"}
    )

    assert "foo2//" == nmci.process.run_stdout(
        'echo -n "$HI//$NMCI_TEST_XXX1"',
        shell=True,
        env={"HI": "foo"},
        env_extra={"HI": "foo2"},
    )

    with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_out:
        r = nmci.process.run("echo -n hello-out", stdout=f_out)
        assert r == nmci.process.RunResult(0, "", "")
        f_out.seek(0)
        assert b"hello-out" == f_out.read()

    with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_out:
        with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_err:
            r = nmci.process.run(
                "echo -n hello-out; echo -n hello-err >&2",
                shell=True,
                stdout=f_out,
                stderr=f_err,
            )
            assert r == nmci.process.RunResult(0, "", "")

            f_out.seek(0)
            assert b"hello-out" == f_out.read()

            f_err.seek(0)
            assert b"hello-err" == f_err.read()

    with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_out:
        with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_err:
            r = nmci.process.run(
                "echo -n hello-out; echo -n hello-err >&2",
                shell=True,
                stdout=f_out,
                stderr=subprocess.STDOUT,
            )
            assert r == nmci.process.RunResult(0, "", "")

            f_out.seek(0)
            assert b"hello-outhello-err" == f_out.read()

            f_err.seek(0)
            assert b"" == f_err.read()


def test_git_call_ref_parse():

    try:
        nmci.process.run_stdout(["git", "rev-parse", "HEAD"])
    except Exception:
        pytest.skip("not a suitable git repo")

    assert re.match("^[0-9a-f]{40}$", nmci.git.rev_parse("HEAD"))


def test_git_config_get_origin_url():
    try:
        nmci.process.run_stdout(["git", "config", "--get", "remote.origin.url"])
    except Exception:
        pytest.skip('not a suitable git repo (as no "remote.origin.url")')

    assert nmci.git.config_get_origin_url().startswith("https://")


def test_ip_link_show_all():

    l0 = nmci.ip.link_show_all(binary=None)

    stdout = nmci.process.run("ip link show", as_bytes=True).stdout
    try:
        stdout.decode("utf-8", errors="strict")
        has_binary = False
    except UnicodeDecodeError:
        # we test here the real system. If you had any non-utf8 links,
        # it would break the test. Detect that.
        has_binary = True

    def _normalize(i):
        return (i["ifindex"], nmci.util.str_to_bytes(i["ifname"]), i["flags"])

    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in nmci.ip.link_show_all()
    ]
    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in nmci.ip.link_show_all(binary=None)
    ]
    assert [_normalize(i) for i in l0] == [
        _normalize(i) for i in nmci.ip.link_show_all(binary=True)
    ]

    if not has_binary:
        assert [_normalize(i) for i in l0] == [
            _normalize(i) for i in nmci.ip.link_show_all(binary=False)
        ]
    else:
        with pytest.raises(UnicodeDecodeError):
            nmci.ip.link_show_all(binary=False)

    lo = nmci.ip.link_show(ifname="lo", binary=None)
    assert lo["ifname"] == "lo"

    lo = nmci.ip.link_show(ifname="lo", binary=False)
    assert lo["ifname"] == "lo"

    lo = nmci.ip.link_show(ifname="lo", binary=True)
    assert lo["ifname"] == b"lo"

    if has_binary:
        pytest.skip(
            "The system has binary interface names (check `ip link`). Some tests were skipped."
        )


def test_ip_address_show():
    addrs = nmci.ip.address_show()

    if not any(
        [
            a["ifname"] == "lo" and a["ifindex"] == 1 and a["address"] == "127.0.0.1"
            for a in addrs
        ]
    ):
        pytest.skip(
            'The systems seems to have no IP addresses and/or "lo" interface. Skip address tests.'
        )

    nmci.ip.address_expect(expected=["127.0.0.1"], ifindex=1, addrs=addrs)
    with pytest.raises(ValueError):
        nmci.ip.address_expect(
            expected=["127.0.0.1"], ifindex=1, with_plen=True, addrs=addrs
        )

    nmci.ip.address_expect(
        expected=["127.0.0.1/8"], ifindex=1, with_plen=True, addrs=addrs
    )
    with pytest.raises(ValueError):
        nmci.ip.address_expect(expected=["127.0.0.1/8"], ifindex=1, addrs=addrs)

    nmci.ip.address_expect(
        expected=["127.0.0.1/8"], ifindex=1, with_plen=True, wait_for_address=0.1
    )
    with pytest.raises(ValueError):
        nmci.ip.address_expect(
            expected=["127.0.0.1/8"], ifindex=1, wait_for_address=0.1
        )


def test_clock_boottime():

    try:
        c = time.CLOCK_BOOTTIME
    except AttributeError:
        assert sys.version_info[:2] < (3, 7)
    else:
        assert c == nmci.util.CLOCK_BOOTTIME

    t = time.clock_gettime(nmci.util.CLOCK_BOOTTIME)
    assert type(t) is float
    assert t > 0


def test_test_tags_select():

    t = nmci.misc.test_tags_select(
        [["ver+=1.4", "ver-=1.20", "foo1"], ["ver+1.21", "foo2"]],
        ("upstream", [1, 5, 0]),
        ("fedora", [34]),
    )
    assert t == ["ver+=1.4", "ver-=1.20", "foo1"]

    t = nmci.misc.test_tags_select(
        [["ver+=1.4", "foo1", "fedoraver-33"], ["ver+1.4", "fedoraver+=33", "foo2"]],
        ("upstream", [1, 5, 0]),
        ("fedora", [34]),
    )
    assert t == ["ver+1.4", "fedoraver+=33", "foo2"]

    with pytest.raises(nmci.misc.InvalidTagsException):
        nmci.misc.test_tags_select(
            [["ver+=1.4", "ver-=1.30", "foo1"], ["ver+=1.21", "foo2"]],
            ("upstream", [1, 21, 0]),
            ("fedora", [34]),
        )

    with pytest.raises(nmci.misc.SkipTestException):
        nmci.misc.test_tags_select(
            [["ver+=1.4", "ver-=1.20", "foo1"], ["ver+1.21", "foo2"]],
            ("upstream", [1, 2, 0]),
            ("fedora", [34]),
        )


def test_context_set_up_commands():
    context = create_test_context()

    def _assert_embed(context, pattern):
        assert len(nmci.embed._to_embed) == 1
        embed_data = nmci.embed._to_embed[0]
        nmci.embed._to_embed.clear()
        assert isinstance(embed_data, nmci.embed.EmbedData)
        assert embed_data.fail_only is True
        assert embed_data._caption.startswith("Command `")
        assert re.search(pattern, embed_data._data)

    context.process.run_stdout("true")
    _assert_embed(context, "true")

    context.process.run("false")
    _assert_embed(context, "false")

    with pytest.raises(Exception):
        context.process.run_stdout("false")
    _assert_embed(context, "false")

    context.process.run("echo")
    _assert_embed(context, "echo")

    with pytest.raises(Exception):
        context.process.run("echo out; echo err 1>&2; false", shell=True)
    _assert_embed(context, "echo out")

    context.process.run(
        "echo -e '\\xfa'; echo -e '\\xfb' 1>&2",
        shell=True,
        ignore_stderr=True,
        as_bytes=True,
    )
    _assert_embed(context, "echo -e ")


def test_process_run_shell_auto():

    with pytest.raises(Exception):
        nmci.process.run("date|grep .")

    with pytest.raises(Exception):
        nmci.process.run("date|grep .", shell=False)

    assert (
        "20"
        in nmci.process.run("date|grep .", env_extra={"LANG": "C"}, shell=True).stdout
    )

    assert (
        "20"
        in nmci.process.run(
            nmci.process.WithShell("date|grep ."), env_extra={"LANG": "C"}
        ).stdout
    )

    assert "$SHELL" == nmci.process.run("echo -n $SHELL", shell=False).stdout
    assert (
        "$SHELL"
        == nmci.process.run("echo -n $SHELL", shell=nmci.process.SHELL_AUTO).stdout
    )
    assert "$SHELL" == nmci.process.run("echo -n $SHELL").stdout
    assert "$SHELL" != nmci.process.run("echo -n $SHELL", shell=True).stdout
    assert "$SHELL" != nmci.process.run(nmci.process.WithShell("echo -n $SHELL")).stdout


def test_process_popen():

    proc = nmci.process.Popen("echo -n hallo").proc
    proc.wait()
    assert proc.stdout.read() == b"hallo"

    proc = nmci.process.Popen("echo -n $SHELL").proc
    proc.wait()
    assert proc.stdout.read() == b"$SHELL"

    proc = nmci.process.Popen(nmci.process.WithShell("echo -n $SHELL")).proc
    proc.wait()
    assert proc.stdout.read() != b"$SHELL"

    pc = nmci.process.Popen("echo -n hello")
    while pc.read_and_poll() is None:
        time.sleep(0.05)
    assert pc.returncode == 0
    assert pc.stdout == b"hello"
    assert pc.stderr == b""

    pc = nmci.process.Popen(nmci.process.WithShell("echo -n foo; echo -n hello 1>&2"))
    pc.read_and_wait()
    assert pc.returncode == 0
    assert pc.stdout == b"foo"
    assert pc.stderr == b"hello"


def test_ip_link_add_nonutf8():

    if os.environ.get("NMCI_ROOT_TEST") != "1":
        pytest.skip("skip root test. Run with NMCI_ROOT_TEST=1")

    ifname = b"\xCB[2Jnonutf\xCCf\\c"

    if not nmci.ip.link_show_maybe(ifname=ifname):
        nmci.process.run_stdout(["ip", "link", "add", "name", ifname, "type", "dummy"])

        # udev might rename the interface, try to workaround the race.
        time.sleep(0.1)

        if not nmci.ip.link_show_maybe(ifname=ifname):
            # hm. Did udev rename the interface and replace non-UTF-8 chars
            # with "_"?
            ifname = "_[2Jnonutf_f\\c"
            assert nmci.ip.link_show(ifname=ifname)

    nmci.ip.link_delete(ifname)


@Stub.misc_distro_detect(("fedora", [35]))
@Stub.misc_nm_version_detect(("upstream", [1, 39, 3, 30276]))
def test_misc_version_control():

    assert nmci.misc.test_version_check(test_name="@pass", feature="general",) == (
        nmci.util.base_dir("features/scenarios/general.feature"),
        "pass",
        ["pass"],
    )

    for stream, version in [
        ("rhel-8-6", [1, 36, 0, 4]),
    ]:
        with Stub.misc_nm_version_detect((stream, version)):
            assert nmci.misc.test_version_check(test_name="ipv6_check_addr_order") == (
                nmci.util.base_dir("features/scenarios/ipv6.feature"),
                "ipv6_check_addr_order",
                [
                    "rhbz1995372",
                    "ver+=1.36",
                    "ver-1.36.7",
                    "ver-1.38",
                    "ipv6_check_addr_order",
                ],
            )

    for stream, version in [
        ("upstream", [1, 39, 0, 30276]),
        ("upstream", [1, 39, 1, 30276]),
    ]:
        with Stub.misc_nm_version_detect((stream, version)):
            assert nmci.misc.test_version_check(test_name="ipv6_check_addr_order") == (
                nmci.util.base_dir("features/scenarios/ipv6.feature"),
                "ipv6_check_addr_order",
                [
                    "rhbz1995372",
                    "ver+=1.36.7",
                    "ver+=1.38",
                    "ver/rhel/8+=1.36.7",
                    "ver/rhel/8+=1.38",
                    "ver/rhel/8-1.39.7.2",
                    "ipv6_check_addr_order",
                ],
            )

    with pytest.raises(Exception):
        nmci.misc.test_version_check(
            test_name="no-exist",
            feature=nmci.util.base_dir("features/scenarios/general.feature"),
        )


def test_misc_test_find_feature_file():

    assert nmci.misc.test_find_feature_file("pass") == nmci.util.base_dir(
        "features/scenarios/general.feature"
    )
    assert nmci.misc.test_find_feature_file("pass", "general") == nmci.util.base_dir(
        "features/scenarios/general.feature"
    )
    with pytest.raises(Exception):
        nmci.misc.test_find_feature_file("no-exist")


def test_ctx_pexpect():

    context = create_test_context()

    p = context.pexpect_spawn("true")
    assert p.expect(["Error", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF]) == 2

    p = context.pexpect_spawn("echo helloworld", shell=True)
    assert p.expect(["world", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF]) == 0

    p = context.pexpect_service("echo foobar")
    assert p.expect(["xxx", "foobar", nmci.pexpect.TIMEOUT, nmci.pexpect.EOF]) == 1

    nmci.pexpect.process_pexpect_spawn()

    nmci.embed.process_embeds(True)


def test_util_consume_list():

    lst = []
    assert list(nmci.util.consume_list(lst)) == []
    assert lst == []

    lst = [1]
    assert list(nmci.util.consume_list(lst)) == [1]
    assert lst == []

    lst = [1, "b"]
    assert list(nmci.util.consume_list(lst)) == [1, "b"]
    assert lst == []


def test_context_cleanup():

    create_test_context()

    nmci.cleanup.cleanup_add_iface("eth0")

    assert [c.name for c in nmci.cleanup._cleanup_lst] == ["iface-reset-eth0"]

    nmci.cleanup.cleanup_add_iface("eth1")

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "iface-reset-eth1",
        "iface-reset-eth0",
    ]

    nmci.cleanup.cleanup_add_iface("eth0")

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "iface-reset-eth0",
        "iface-reset-eth1",
    ]

    nmci.cleanup.cleanup_add(lambda: None, name="foo")

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "foo",
        "iface-reset-eth0",
        "iface-reset-eth1",
    ]

    nmci.cleanup._cleanup_add(
        nmci.cleanup.Cleanup(name="foo", callback=lambda: None, priority=50)
    )

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "foo",
        "iface-reset-eth0",
        "iface-reset-eth1",
        "foo",
    ]

    nmci.cleanup.cleanup_add(
        name="bar", unique_tag=(1,), callback=lambda: None, priority=49
    )

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "foo",
        "iface-reset-eth0",
        "iface-reset-eth1",
        "bar",
        "foo",
    ]

    nmci.cleanup.cleanup_add(
        name="bar", unique_tag=(1,), callback=lambda: None, priority=19
    )

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "foo",
        "bar",
        "iface-reset-eth0",
        "iface-reset-eth1",
        "foo",
    ]

    del nmci.cleanup._cleanup_lst[2:4]

    assert [c.name for c in nmci.cleanup._cleanup_lst] == [
        "foo",
        "bar",
        "foo",
    ]

    for ex in nmci.cleanup.process_cleanup():
        assert ex is None

    assert nmci.cleanup._cleanup_lst == []

    nmci.cleanup.cleanup_add(
        name="bar", unique_tag=(1,), callback=lambda: 1 / 0, priority=19
    )

    for ex in nmci.cleanup.process_cleanup():
        import traceback

        assert type(ex) is ZeroDivisionError
        assert traceback.format_exception(ex, ex, ex.__traceback__)


def test_util_start_timeout():

    t = nmci.util.start_timeout(None)
    assert not t.expired()
    assert t.is_none()

    t = nmci.util.start_timeout(0)
    assert t.expired()
    assert not t.is_none()

    t = nmci.util.start_timeout(0.0)
    assert t.expired()
    assert not t.is_none()

    t = nmci.util.start_timeout(-1)
    assert t.expired()
    assert not t.is_none()

    t = nmci.util.start_timeout("100000")
    assert not t.expired()

    t = nmci.util.start_timeout(100000.1)
    assert not t.expired()

    t = nmci.util.start_timeout("0.05")
    while not t.expired():
        time.sleep(0.01)
    assert t.expired()

    loop = 0
    t = nmci.util.start_timeout(0)
    while t.loop_sleep(1):
        assert loop == 0
        loop += 1
    assert loop == 1

    loop = 0
    t = nmci.util.start_timeout(t)
    while t.loop_sleep(1):
        assert loop == 0
        loop += 1
    assert loop == 1

    t = nmci.util.start_timeout(0)
    while t.sleep(1):
        assert False

    t = nmci.util.start_timeout(t)
    while t.sleep(1):
        assert False


def test_str_matches():
    assert nmci.util.str_matches("a", "a")
    assert nmci.util.str_matches("a", re.compile("a"))
    assert nmci.util.str_matches("a", ["b", re.compile("a")])
    assert not nmci.util.str_matches("x", ["b", re.compile("a")])


def test_ipaddr_parse_and_norm():

    assert nmci.ip.ipaddr_parse("1.2.3.4") == ("1.2.3.4", socket.AF_INET)
    assert nmci.ip.ipaddr_parse("fe80::00:2") == ("fe80::2", socket.AF_INET6)

    with pytest.raises(Exception):
        nmci.ip.ipaddr_parse("fe80::1", "4")

    with pytest.raises(Exception):
        nmci.ip.ipaddr_plen_norm("bee::4", "4")

    assert nmci.ip.addr_family_norm(socket.AF_UNSPEC) is None

    assert nmci.ip.ipaddr_norm("1.2.3.4") == "1.2.3.4"
    assert nmci.ip.ipaddr_norm("0::1") == "::1"

    assert nmci.ip.ipaddr_norm("1.2.3.4", addr_family="4") == "1.2.3.4"
    with pytest.raises(Exception):
        nmci.ip.ipaddr_norm("1.2.3.4", addr_family="6")

    assert nmci.ip.ipaddr_plen_norm("1.2.3.4", addr_family="4") == "1.2.3.4"
    with pytest.raises(Exception):
        nmci.ip.ipaddr_plen_norm("1.2.3.4", addr_family="6")

    assert nmci.ip.ipaddr_plen_parse("1.2.3.4/5", addr_family="4") == (
        "1.2.3.4",
        socket.AF_INET,
        5,
    )
    assert (
        nmci.ip.ipaddr_plen_norm("1.2.3.4/5", addr_family=socket.AF_UNSPEC)
        == "1.2.3.4/5"
    )


# This test should always run as last. Keep it at the bottom
# of the file.
def test_black_code_fromatting():

    if os.environ.get("NMCI_NO_BLACK") == "1":
        pytest.skip("skip formatting test with python-black (NMCI_NO_BLACK=1)")

    files = [
        nmci.util.base_dir("contrib/gui/steps.py"),
        nmci.util.base_dir("features/environment.py"),
        nmci.util.base_dir("features/steps/connection.py"),
        nmci.util.base_dir("features/steps/vpn.py"),
        nmci.util.base_dir("features/steps/service.py"),
        nmci.util.base_dir("nmci"),
        nmci.util.base_dir("nmci/helpers/version_control.py"),
    ]

    exclude = [
        # "--exclude",
        # "nmci/(tags)\\.py",
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
