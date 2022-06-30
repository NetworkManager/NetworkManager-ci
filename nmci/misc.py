import glob
import os
import re
import subprocess
import sys
import yaml

import xml.etree.ElementTree as ET

from . import git
from . import ip
from . import sdresolved
from . import util
from . import process


class _Misc:

    TEST_NAME_VALID_CHAR_REGEX = "[-a-z_.A-Z0-9+=/]"

    def test_name_normalize(self, test_name):
        test_name0 = test_name
        m = re.match("^[^_]*NetworkManager[^_]*_[^_]*Test[^_]*_(.*)$", test_name)
        if m:
            test_name = m.group(1)
        if test_name and test_name[0] == "@":
            test_name = test_name[1:]
        if not re.match("^" + self.TEST_NAME_VALID_CHAR_REGEX + "+$", test_name):
            raise ValueError(f"Invalid test name {test_name0}")
        return test_name

    def test_get_feature_files(self, feature="*"):

        feature_dir = ""

        if feature[0] != "/":
            feature_dir = util.base_dir("features", "scenarios")

        if not feature.endswith(".feature"):
            feature = feature + ".feature"

        feature_path = os.path.join(feature_dir, feature)
        return glob.glob(feature_path)

    def test_load_tags_from_features(
        self,
        feature=None,
        test_name=None,
        feature_file=None,
    ):

        if feature_file is not None:
            assert feature is None
            feature_files = [feature_file]
        else:
            if feature is None:
                feature = "*"
            feature_files = self.test_get_feature_files(feature=feature)

        re_chr = re.compile("^@" + self.TEST_NAME_VALID_CHAR_REGEX + "+$")
        re_tag = re.compile(r"^\s*(@[^#]*)")
        re_sce = re.compile(r"^\s*Scenario")
        re_wsp = re.compile(r"\s")
        test_tags = []
        line = ""
        for filename in feature_files:
            with open(filename, "rb") as f:
                for cur_line in f:
                    cur_line = cur_line.decode("utf-8", "error")
                    m = re_tag.match(cur_line)
                    if m:
                        line += " " + m.group(1)
                        continue

                    if not line:
                        continue
                    if not re_sce.match(cur_line):
                        continue

                    words = re_wsp.split(line)
                    line = ""

                    # remove empty tokens.
                    words = [w for w in words if w]

                    if not all((re_chr.match(s) for s in words)):
                        raise ValueError(
                            "unexpected characters in tags in file %s: %s"
                            % (filename, " ".join(words))
                        )

                    words = [s[1:] for s in words]

                    if test_name is None or test_name in words:
                        test_tags.append(words)

        return test_tags

    def get_mapper_obj(self):
        with open(util.base_dir() + "/mapper.yaml", "r") as mapper_file:
            mapper_content = mapper_file.read()
            return yaml.load(mapper_content, Loader=yaml.BaseLoader)

    def get_mapper_tests(self, mapper, feature="*"):
        all_features = ["*", "all"]
        testmappers = [x for x in mapper["testmapper"]]

        def flatten_test(test):
            testname = list(test.keys())[0]
            test = test[testname]
            test["testname"] = testname
            return test

        mapper_tests = [
            flatten_test(x) for tm in testmappers for x in mapper["testmapper"][tm]
        ]
        return [
            test
            for test in mapper_tests
            if (
                "feature" in test
                and (test["feature"] == feature or feature in all_features)
            )
            or ("feature" not in test and feature in all_features)
        ]

    def nm_version_parse(self, version):

        # Parses the version string from `/sbin/NetworkManager -V` and detects a version
        # array and a stream string.
        #
        # In particular, the stream is whether this is a package from upstream or from
        # dist-git (fedora/fedpkg or rhel/rhpkg).
        #
        # Since a package build for e.g. rhel-8.3 always has the suffix .el8, we cannot
        # use that reliably to detect the stream. Well, we can, but all el8 packages
        # that are not actually "rhel-8" stream, must have a unique version tag.
        # Like for example copr builds of upstream have.

        m = re.match(
            r"^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)\.(fc|el)([0-9]+)(_([0-9]+))?$",
            version,
        )
        if m and int(m.group(4)) < 1000:
            if m.group(5) == "el":
                s = "rhel"
            else:
                s = "fedora"
            if m.group(7):
                stream = "%s-%s-%s" % (s, int(m.group(6)), int(m.group(8)))
            else:
                stream = "%s-%s" % (s, int(m.group(6)))
            return (stream, [int(m.group(x)) for x in range(1, 5)])

        m = re.match(
            r"^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)\.([0-9]+)\.(fc|el)([0-9]+)(_([0-9]+))?$",
            version,
        )
        if m and int(m.group(4)) < 1000:
            if m.group(6) == "el":
                s = "rhel"
            else:
                s = "fedora"
            if m.group(8):
                stream = "%s-%s-%s" % (s, int(m.group(7)), int(m.group(9)))
            else:
                stream = "%s-%s" % (s, int(m.group(7)))
            return (stream, [int(m.group(x)) for x in range(1, 6)])

        m = re.match(
            r"^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)\.[a-z0-9]+\.(el|fc)[0-9]+$",
            version,
        )
        if m and int(m.group(4)) >= 1000:
            return ("upstream", [int(m.group(x)) for x in range(1, 5)])

        m = re.match(r"^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)\.copr.*$", version)
        if m and int(m.group(4)) >= 1000:
            return ("upstream", [int(m.group(x)) for x in range(1, 5)])

        m = re.match(r"^([0-9]+)\.([0-9]+)\.([0-9]+)-.*$", version)
        if m:
            return ("unknown", [int(m.group(x)) for x in range(1, 4)])

        raise ValueError('cannot parse version "%s"' % (version))

    def test_version_tag_parse(self, version_tag, tag_candidate):

        version_tag0 = version_tag

        if not version_tag.startswith(tag_candidate):
            raise ValueError(
                f'tag "{version_tag0}" does not start with "{tag_candidate}"'
            )

        version_tag = version_tag[len(tag_candidate) :]

        if version_tag == "-" or version_tag == "+":
            # as a special case, we support plain @ver+/@ver- tags. They
            # make sense to always enabled/disable a test per stream.
            # For example, if a certain test should never run with a RHEL
            # package, use "@ver/rhel-"
            return (version_tag, [])

        if version_tag.startswith("+=") or version_tag.startswith("-="):
            op = version_tag[0:2]
            ver = version_tag[2:]
        elif version_tag.startswith("+") or version_tag.startswith("-"):
            op = version_tag[0:1]
            ver = version_tag[1:]
        else:
            raise ValueError(
                f'tag "{version_tag0}" does not have a suitable "+-" part for "{tag_candidate}"'
            )

        if not re.match("^[0-9.]+$", ver):
            raise ValueError(
                f'tag "{version_tag0}" does not have a suitable version number for "{tag_candidate}"'
            )

        ver_arr = [int(x) for x in ver.split(".")]
        return (op, ver_arr)

    def test_version_tag_parse_ver(self, version_tag):
        # This parses tags in the form @ver$STREAM$OP$VERSION where
        # - $STREAM is for example "", "/upstream", "/fedora", "/fedora/33", "/rhel", "/rhel/8". It matches
        #   the stream returned by nm_version_parse().
        # - $OP is the comparison operator ("-", "-=", "+", "+=")
        # - -VERSION is the version number to compare. Corresponds the version returned by nm_version_parse().

        if not version_tag.startswith("ver"):
            raise ValueError(f'version tag "{version_tag}" does not start with "ver""')

        v = version_tag[len("ver") :]
        stream = []
        while True:
            m = re.match("^/([^/\\-+=]+)", v)
            if not m:
                break
            stream.append(m.group(1))
            v = v[(1 + len(m.group(1))) :]

        version = self.test_version_tag_parse(version_tag, "/".join(("ver", *stream)))
        return (stream, *version)

    def test_version_tag_filter_for_stream(self, tags_ver, nm_stream):
        # - tags_ver is a list of version tags parsed by test_version_tag_parse_ver() (that is
        #   it contains a 3-tuple of (stream, op, version).
        # - nm_stream is the stream detected by nm_version_parse(), for example
        #   "rhel-8-10" or "fedora-33".
        #
        # This function now returns a list of (op,version) tuple, but only selecting
        # those that have a matching stream... that means, if the nm_stream is
        # "rhel-8-10", then:
        #  - if exist, it will return all tags_ver with stream ["rhel", "8", "10"]
        #  - if exist, it will return all tags_ver with stream ["rhel", "8"]
        #  - if exist, it will return all tags_ver with stream ["rhel"]
        #  - if exist, it will return all tags_ver with stream []
        #
        # With this scheme, you can have a default version tag that always matches (@ver+=1.39),
        # but you can override it for rhel (@ver/rhel+=x) or even for rhel-8 only (@ver/rhel/8+=x)

        if not tags_ver:
            return tags_ver

        nm_streams = nm_stream.split("-")
        assert all(s for s in nm_streams)
        while True:
            if any((nm_streams == t[0] for t in tags_ver)):
                return [(t[1], t[2]) for t in tags_ver if nm_streams == t[0]]
            if not nm_streams:
                # nothing found. Return empty.
                return []
            nm_streams = nm_streams[:-1]

    def nm_version_detect(self, use_cached=True):
        if use_cached and hasattr(self, "_nm_version_detect_cached"):
            return self._nm_version_detect_cached

        # gather current system info (versions, pkg vs. build)
        if "NM_VERSION" in os.environ:
            current_version_str = os.environ["NM_VERSION"]
        elif os.path.isfile("/tmp/nm_version_override"):
            with open("/tmp/nm_version_override") as f:
                current_version_str = f.read()
        else:
            current_version_str = process.run_stdout(["NetworkManager", "-V"])

        v = self.nm_version_parse(current_version_str)
        self._nm_version_detect_cached = v
        return v

    def distro_detect(self, use_cached=True):

        if use_cached and hasattr(self, "_distro_detect_cached"):
            return self._distro_detect_cached

        distro_version = [
            int(x)
            for x in process.run_stdout(
                [
                    "sed",
                    "s/.*release *//;s/ .*//;s/Beta//;s/Alpha//",
                    "/etc/redhat-release",
                ],
            ).split(".")
        ]

        if subprocess.call(["grep", "-qi", "fedora", "/etc/redhat-release"]) == 0:
            distro_flavor = "fedora"
        else:
            distro_flavor = "rhel"
            if len(distro_version) == 1:
                # CentOS stream only gives "CentOS Stream release 8". Hack a minor version
                # number
                distro_version.append(99)

        v = (distro_flavor, distro_version)
        self._distro_detect_cached = v
        return v

    def ver_param_to_str(self, nm_stream, nm_version, distro_flavor, distro_version):
        nm_version = ".".join([str(c) for c in nm_version])
        distro_version = ".".join([str(c) for c in distro_version])
        return f"{nm_stream}:{nm_version} ({distro_flavor}:{distro_version})"

    def test_tags_match_version(self, test_tags, nm_version_info, distro_version_info):
        (nm_stream, nm_version) = nm_version_info
        (distro_flavor, distro_version) = distro_version_info

        nm_stream_base = nm_stream.split("-")[0]

        tags_ver = []
        tags_rhelver = []
        tags_fedoraver = []
        run = True
        has_any = False
        for tag in test_tags:
            has_any = True
            if tag.startswith("ver"):
                tags_ver.append(self.test_version_tag_parse_ver(tag))
            elif tag.startswith("rhelver"):
                tags_rhelver.append(self.test_version_tag_parse(tag, "rhelver"))
            elif tag.startswith("fedoraver"):
                tags_fedoraver.append(self.test_version_tag_parse(tag, "fedoraver"))
            elif tag == "rhel_pkg":
                # "@rhel_pkg" (and "@fedora_pkg") have some overlap with
                # "@ver/rhel+"
                #
                # - if the test already specifies some @ver$OP$VERSION, then
                #   it's similar to "@ver- @ver/rhel$OP$VERSION" (for all @ver tags)
                # - if the test does not specify other @ver tags, then it's similar
                #   to "@ver- @ver/rhel+".
                #
                # These tags are still useful aliases. Also note that they take
                # into account distro_flavor, while @ver/rhel does not take it
                # into account. If you rebuild a rhel package on Fedora, then
                # @ver/rhel would not care that you are on Fedora, while @rhel_pkg
                # would.
                if not (distro_flavor == "rhel" and nm_stream_base == "rhel"):
                    run = False
            elif tag == "not_with_rhel_pkg":
                if distro_flavor == "rhel" and nm_stream_base == "rhel":
                    run = False
            elif tag == "fedora_pkg":
                if not (distro_flavor == "fedora" and nm_stream_base == "fedora"):
                    run = False
            elif tag == "not_with_fedora_pkg":
                if distro_flavor == "fedora" and nm_stream_base == "fedora":
                    run = False
        if not has_any:
            return None
        if not run:
            return None

        tags_ver = self.test_version_tag_filter_for_stream(tags_ver, nm_stream)
        if not self.test_version_tag_eval(tags_ver, nm_version):
            return None

        if distro_flavor == "rhel" and not self.test_version_tag_eval(
            tags_rhelver, distro_version
        ):
            return None
        if distro_flavor == "fedora" and not self.test_version_tag_eval(
            tags_fedoraver, distro_version
        ):
            return None

        return test_tags

    class SkipTestException(Exception):
        pass

    class InvalidTagsException(Exception):
        pass

    def test_tags_select(self, test_tags_list, nm_version_info, distro_version_info):

        (nm_stream, nm_version) = nm_version_info
        (distro_flavor, distro_version) = distro_version_info

        result = None

        for test_tags in test_tags_list:
            t = self.test_tags_match_version(
                test_tags, nm_version_info, distro_version_info
            )
            if not t:
                continue
            if result:
                raise self.InvalidTagsException(
                    "multiple matches in environment '%s': %r and %r"
                    % (
                        self.ver_param_to_str(
                            nm_stream, nm_version, distro_flavor, distro_version
                        ),
                        result,
                        test_tags,
                    )
                )
            result = t

        if not result:
            raise self.SkipTestException(
                "skipped in environment '%s'"
                % (
                    self.ver_param_to_str(
                        nm_stream, nm_version, distro_flavor, distro_version
                    ),
                )
            )

        return result

    def test_version_tag_eval(self, ver_tags, version):

        # This is how we interpret the "ver+"/"ver-" version tags.
        # This scheme makes sense for versioning schemes where we have a main
        # branch (where major releases get tagged) and stable branches (with
        # minor releases). This is the versioning scheme of NetworkManager
        # ("ver" tag) but it also works for "rhelver"/"fedoraver".
        #
        # Currently it only supports a main branch (with major releases)
        # and stable branches (with minor releases) that branch off the
        # main branch. It does not support a second level of bugfix branches
        # that branch off stable branches, but that could be implemented too.
        #
        # Notes:
        #
        # 1) the version tags '-'/'+' are just convenience forms of '-='/'+='. They
        #    need no special consideration ("+1.28.5" is exactly the same as "+=1.28.6").
        #
        # 2) if both '-=' and '+=' are present, then both groups must be satisfied
        #    at the same time. E.g. "ver+=1.24, ver-=1.28" to define a range.
        #    That means, we evaluate
        #      (not has-minus or minus-satisfied) and (not has-plus or plus-satisfied)
        #
        # 3) version tags can either specify the full version ("ver+=1.26.4") or only the major
        #    component ("ver+=1.27").
        #    Of all the version tags of the same '+'/'-' group, the shortest and highest one also
        #    determines the next major version.
        #    For example, with "ver+=1.26.4, ver+=1.28.2" both tags have 3 components (they
        #    both are the "shortest"). Of these, "ver+=1.28.2" is the highest one. From that we
        #    automatically also get "ver+=1.29[.0]" and ver+=2[.0.0]".
        #    This means, if you specify the latest stable version (1.28.2) that introduced a feature,
        #    then automatically all newer major versions are covered.
        #    Basically, the shortest and highest tag determines the major branch. If you have
        #    more tags of the same '+'/'-' type, then those are only for the stable branch.
        #    With example "ver+=1.26.4, ver+=1.28.2", the first tag only covers 1.26.4+ stable
        #    versions, nothing else.
        #
        # 4) for '+' group, the version tags are effectively OR-ed. Examples:
        #    - "ver+=1.28.6" covers 1.28.6+ and 1.29+ and 2+
        #    - "ver+=1.28.6, ver+=1.30.4" covers 1.28.6+, 1.30.4+ and 1.31+, but does not cover 1.30.2
        #    - "ver+=1.28.6, ver+1.30" covers 1.28.6+, 1.31+, 2+, but does not cover 1.30.x
        #
        # 5) '-' is the inverse of '+'. For example, "ver+=1.28.5" is the same as
        #    "not(ver-1.28.5)". Or for example, if one test that specifies "ver+=1.28.6, ver+=1.29.4"
        #    and another test "ver-1.28.6, ver-1.29.4", then the tags are mutually exclusive.
        #
        # 6) with 4) and 5), it follows that for '-' group, the version tags are effectively AND-ed.
        #    This is due to De Morgan's laws. For example,
        #           "not(ver+=1.28.5 and ver+=1.30)"
        #        == "not(not(ver-1.28.5) and not(ver-1.30))"
        #        == "not(not(ver-1.28.5)) or not(not(ver-1.30))"
        #        == "ver-1.28.5 or ver-1.30"

        l_version = len(version)
        assert l_version > 0
        assert all([v >= 0 for v in version])

        ver_tags = list(ver_tags)

        if not ver_tags:
            # no version tags means it's a PASS.
            return True

        # Check for the always enabled/disabled tag (which is
        # encoded by op="+"/"-" and len=[]). If such a tag
        # is present, it must be alone.
        for op, ver in ver_tags:
            if ver:
                continue
            assert op in ["+", "-"]
            assert len(ver_tags) == 1
            return op == "+"

        for op, ver in ver_tags:
            assert op in ["+=", "+", "-=", "-"]
            assert all([type(v) is int and v >= 0 for v in ver])
            if len(ver) > l_version:
                raise ValueError(
                    'unexpectedly long version tag %s%s to compare "%s"'
                    % (op, ver, version)
                )

        # '+' is only a special case of '+=', and '-=' is only a special
        # case of '-'. Reduce the cases we have to handle.
        def _simplify_ver(op, ver):
            if op == "+":
                op = "+="
                ver = list(ver)
                ver[-1] += 1
            elif op == "-=":
                op = "-"
                ver = list(ver)
                ver[-1] += 1
            return (op, ver)

        ver_tags = [_simplify_ver(op, ver) for op, ver in ver_tags]

        def _eval(ver_tags, version):

            if not ver_tags:
                return None

            is_val_len_first = True

            for ver_len in range(1, len(version) + 1):

                ver_l = [ver for ver in ver_tags if len(ver) == ver_len]

                if not ver_l:
                    continue

                version_l = version[0:ver_len]

                ver_l.sort(reverse=True)

                has_match = False
                is_first = True
                for ver in ver_l:
                    m = ver <= version_l
                    if is_val_len_first:
                        if (
                            not is_first
                            and ver[0 : ver_len - 1] != version_l[0 : ver_len - 1]
                        ):
                            m = False
                    else:
                        if ver[0 : ver_len - 1] != version_l[0 : ver_len - 1]:
                            m = False

                    is_first = False
                    if m:
                        has_match = True
                        break

                if has_match:
                    return True

                is_val_len_first = False

            return False

        # See above: the '+' group gets OR-ed while the '-' group gets
        # AND-ed.  This is achieved by using the same _eval() call,
        # and then inverting @v2 (De Morgan's laws).
        v1 = _eval([ver for op, ver in ver_tags if op == "+="], version)
        v2 = _eval([ver for op, ver in ver_tags if op == "-"], version)

        if v2 is not None:
            v2 = not v2

        if v1 is None:
            v1 = True
        if v2 is None:
            v2 = True
        return v1 and v2

    def test_find_feature_file(self, test_name, feature="*"):

        test_name = self.test_name_normalize(test_name=test_name)

        r = process.run(
            [
                "grep",
                f"@\\<{test_name}\\>",
                "-l",
                "--",
                *self.test_get_feature_files(feature=feature),
            ]
        )

        if r.returncode == 1:
            assert r.stdout == ""
            raise Exception(f"test {test_name} not found")

        files = r.stdout.split("\n")
        if len(files) != 2 or files[-1] != "":
            raise Exception(f"test {test_name} found not exactly once: [{r.stdout}]")

        return files[0]

    def test_version_check(self, test_name, feature="*"):
        # this checks for tests with given tag and returns all tags of the first test satisfying all conditions
        #
        # this parses tags: ver{-,+,-=,+=}, rhelver{-,+,-=,+=}, fedoraver{-,+,-=,+=}, [not_with_]rhel_pkg, [not_with_]fedora_pkg.
        #
        # {rhel,fedora}ver tags restricts only their distros, so rhelver+=8 runs on all Fedoras, if fedoraver not restricted
        # to not to run on rhel / fedora use tags rhelver-=0 / fedoraver-=0 (or something similar)
        #
        # {rhel,fedora}_pkg means to run only on stock RHEL/Fedora package
        # not_with_{rhel,fedora}_pkg means to run only on daily build (not patched stock package)
        # similarly, *_pkg restricts only their distros, rhel_pkg will run on all Fedoras (build and stock pkg)
        #
        # since the first satisfying test is returned, the last test does not have to contain distro restrictions
        # and it will run only in remaining conditions - so order of the tests matters in this case

        test_name = self.test_name_normalize(test_name=test_name)

        feature_file = self.test_find_feature_file(test_name=test_name, feature=feature)

        test_tags_list = self.test_load_tags_from_features(
            feature_file=feature_file, test_name=test_name
        )

        if not test_tags_list:
            raise Exception(f"test with tag '{test_name}' not defined!\n")

        try:
            result = self.test_tags_select(
                test_tags_list, self.nm_version_detect(), self.distro_detect()
            )
        except self.SkipTestException as e:
            raise self.SkipTestException(f"skip test '{test_name}': {e}")
        except Exception as e:
            raise Exception(f"error checking test '{test_name}': {e}")

        return (feature_file, test_name, list(result))

    def nmlog_parse_dnsmasq(self, ifname):
        s = process.run_stdout(
            [util.util_dir("helpers/nmlog-parse-dnsmasq.sh"), ifname], timeout=20
        )
        import json

        return json.loads(s)

    def get_dns_info(self, dns_plugin, ifindex=None, ifname=None):

        if ifindex is None and ifname is None:
            raise ValueError("Missing argument, either ifindex or ifname must be given")

        ifdata = ip.link_show(ifindex=ifindex, ifname=ifname)

        if dns_plugin == "dnsmasq":
            info = self.nmlog_parse_dnsmasq(ifdata["ifname"])
            info["default_route"] = any((s == "." for s in info["domains"]))
            info["domains"] = [(s, "routing") for s in info["domains"]]
        elif dns_plugin == "systemd-resolved":
            info = sdresolved.link_get_all(ifdata["ifindex"])
            pass
        else:
            raise ValueError('Invalid dns_plugin "%"' % (dns_plugin))

        info["dns_plugin"] = dns_plugin
        return info

    def html_report_tag_links(self, scenario_el):
        from . import tags

        tags_el = scenario_el.find(".//span[@class='tag']")
        try:
            git_url = git.config_get_origin_url()
            git_commit = git.call_rev_parse("HEAD")
        except:
            git_url = None
            git_commit = None
        if tags_el is not None:
            tags_list = tags_el.text.split(" ")
            tags_el.text = ""
            for tag in tags_list:
                if tag.startswith("@rhbz"):
                    link = ET.SubElement(
                        tags_el,
                        "a",
                        {
                            "href": "https://bugzilla.redhat.com/"
                            + tag.replace("@rhbz", "").strip(", "),
                            "target": "_blank",
                            "style": "color:inherit",
                        },
                    )
                    link.text = tag
                elif tag.strip("@, ") in tags.tag_registry and git_url:
                    lineno = tags.tag_registry[tag.strip("@, ")].lineno
                    link = ET.SubElement(
                        tags_el,
                        "a",
                        {
                            "href": f"{git_url}/-/tree/{git_commit}/nmci/tags.py#L{lineno}",
                            "target": "_blank",
                            "style": "color:inherit",
                        },
                    )
                    link.text = tag
                else:
                    tag_el = ET.SubElement(tags_el, "span")
                    tag_el.text = tag

    def html_report_file_links(self, scenario_el):
        try:
            git_url = git.config_get_origin_url()
            git_commit = git.call_rev_parse("HEAD")
        except:
            return
        url_base = f"{git_url}/-/tree/{git_commit}/"
        file_els = [scenario_el.find(".//span[@class='scenario_file']")]
        file_els += scenario_el.findall(".//div[@class='step_file']/span")

        for file_el in file_els:
            if file_el is not None:
                if file_el.text == "<unknown>":
                    # this happens if the behave step was not found.
                    continue
                file_name, line = file_el.text.split(":", 2)
                link = ET.SubElement(
                    file_el,
                    "a",
                    {
                        "href": url_base + file_name + "#L" + line,
                        "target": "_blank",
                        "style": "color:inherit",
                    },
                )
                link.text = file_el.text
                file_el.text = ""

    def journal_get_cursor(self):
        m = process.run_search_stdout(
            "journalctl --lines=0 --quiet --show-cursor",
            "^-- cursor: +([^ ].*[^ ]) *\n$",
        )
        return m.group(1)

    def journal_show(
        self,
        service=None,
        *,
        syslog_identifier=None,
        cursor=None,
        short=False,
        journal_args=None,
        as_bytes=False,
        max_size=None,
        warn_max_size=True,
        prefix=None,
        suffix=None,
    ):
        if service:
            if isinstance(service, str) or isinstance(service, bytes):
                service = ["-u", service]
            else:
                service = (["-u", s] for s in service)
                service = [c for pair in service for c in pair]
        else:
            service = []

        if syslog_identifier:
            if isinstance(syslog_identifier, str) or isinstance(
                syslog_identifier, bytes
            ):
                syslog_identifier = ["-t", util.bytes_to_str(syslog_identifier)]
            else:
                syslog_identifier = (["-t", s] for s in syslog_identifier)
                syslog_identifier = [c for pair in syslog_identifier for c in pair]
        else:
            syslog_identifier = []

        if cursor:
            cursor = ["--cursor=" + util.bytes_to_str(cursor)]
        else:
            cursor = []

        if short:
            short = ["-o", "short-unix", "--no-hostname"]
        else:
            short = []

        if not journal_args:
            journal_args = []
        elif isinstance(journal_args, str):
            import shlex

            journal_args = shlex.split(journal_args)
        else:
            journal_args = list(journal_args)

        if max_size is None:
            max_size = 50 * 1024 * 1024

        import tempfile

        with tempfile.TemporaryFile(dir=util.tmp_dir()) as f_out:
            process.run(
                ["journalctl", "--all", "--no-pager"]
                + service
                + syslog_identifier
                + cursor
                + short
                + journal_args,
                ignore_returncode=False,
                stdout=f_out,
                timeout=180,
            )

            f_out.seek(0)

            d = util.fd_get_content(
                f_out, max_size=max_size, warn_max_size=warn_max_size
            ).data

        if not as_bytes:
            d = d.decode(encoding="utf-8", errors="replace")

        if prefix is not None:
            if as_bytes:
                d = util.str_to_bytes(prefix) + b"\n" + d
            else:
                d = util.bytes_to_str(prefix) + "\n" + d

        if suffix is not None:
            if as_bytes:
                d = d + b"\n" + util.str_to_bytes(suffix)
            else:
                d = d + "\n" + util.bytes_to_str(suffix)

        return d

    COREDUMP_TYPE_SYSTEMD_COREDUMP = "systemd-coredump"
    COREDUMP_TYPE_ABRT = "abrt"

    def _coredump_reported_file(self):
        return util.tmp_dir("reported_crashes")

    def coredump_is_reported(self, dump_id):
        filename = self._coredump_reported_file()
        if os.path.isfile(filename):
            dump_id += "\n"
            with open(filename) as f:
                for line in f:
                    if dump_id == line:
                        return True
        return False

    def coredump_report(self, dump_id):
        with open(self._coredump_reported_file(), "a") as f:
            f.write(dump_id + "\n")

    def coredump_list_on_disk(self, dump_type=None):
        if dump_type == self.COREDUMP_TYPE_SYSTEMD_COREDUMP:
            g = "/var/lib/systemd/coredump/*"
        elif dump_type == self.COREDUMP_TYPE_ABRT:
            g = "/var/spool/abrt/ccpp*"
        else:
            assert False, f"Invalid dump_type {dump_type}"
        return glob.glob(g)


sys.modules[__name__] = _Misc()
