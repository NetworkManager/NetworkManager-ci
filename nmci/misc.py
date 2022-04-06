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

    TEST_NAME_VALID_CHAR_REGEX = "[-a-z_.A-Z0-9+=]"

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

        import glob

        feature_dir = ""

        if feature[0] != "/":
            feature_dir = util.base_dir("features", "scenarios")

        if not feature.endswith(".feature"):
            feature = feature + ".feature"

        feature_path = os.path.join(feature_dir, feature)
        return glob.glob(feature_path)

    def test_load_tags_from_features(self, feature="*", test_name=None):

        re_chr = re.compile("^@" + self.TEST_NAME_VALID_CHAR_REGEX + "+$")
        re_tag = re.compile(r"^\s*(@[^#]*)")
        re_sce = re.compile(r"^\s*Scenario")
        re_wsp = re.compile(r"\s")
        test_tags = []
        line = ""
        for filename in self.test_get_feature_files(feature):
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

        if not version_tag.startswith(tag_candidate):
            raise ValueError(
                f'tag "{version_tag}" does not start with "{tag_candidate}"'
            )

        version_tag = version_tag[len(tag_candidate) :]

        if version_tag.startswith("+=") or version_tag.startswith("-="):
            op = version_tag[0:2]
            ver = version_tag[2:]
        elif version_tag.startswith("+") or version_tag.startswith("-"):
            op = version_tag[0:1]
            ver = version_tag[1:]
        else:
            raise ValueError(
                f'tag "{version_tag}" does not have a suitable "+-" part for "{tag_candidate}"'
            )

        if not re.match("^[0-9.]+$", ver):
            raise ValueError(
                'tag "{version_tag}" does not have a suitable version number for "{tag_candidate}"'
            )

        ver_arr = [int(x) for x in ver.split(".")]
        return (op, ver_arr)

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
            current_version_str = process.run_check(["NetworkManager", "-V"])

        v = self.nm_version_parse(current_version_str)
        self._nm_version_detect_cached = v
        return v

    def distro_detect(self, use_cached=True):

        if use_cached and hasattr(self, "_distro_detect_cached"):
            return self._distro_detect_cached

        distro_version = [
            int(x)
            for x in process.run_check(
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

        tags_ver = []
        tags_rhelver = []
        tags_fedoraver = []
        run = True
        has_any = False
        for tag in test_tags:
            has_any = True
            if tag.startswith("ver"):
                tags_ver.append(self.test_version_tag_parse(tag, "ver"))
            elif tag.startswith("rhelver"):
                tags_rhelver.append(self.test_version_tag_parse(tag, "rhelver"))
            elif tag.startswith("fedoraver"):
                tags_fedoraver.append(self.test_version_tag_parse(tag, "fedoraver"))
            elif tag == "rhel_pkg":
                if not (distro_flavor == "rhel" and nm_stream.startswith("rhel")):
                    run = False
            elif tag == "not_with_rhel_pkg":
                if distro_flavor == "rhel" and nm_stream.startswith("rhel"):
                    run = False
            elif tag == "fedora_pkg":
                if not (distro_flavor == "fedora" and nm_stream.startswith("fedora")):
                    run = False
            elif tag == "not_with_fedora_pkg":
                if distro_flavor == "fedora" and nm_stream.startswith("fedora"):
                    run = False
        if not has_any:
            return None
        if not run:
            return None

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

    def nmlog_parse_dnsmasq(self, ifname):
        s = process.run_check(
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


sys.modules[__name__] = _Misc()
