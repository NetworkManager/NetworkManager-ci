import glob
import os
import re
import subprocess
import yaml
import json
import xml.etree.ElementTree as ET

import nmci.git
import nmci.ip
import nmci.sdresolved
import nmci.util
import nmci.process


class _Misc:

    TEST_NAME_VALID_CHAR_SET = "-a-zA-Z0-9_.+=/"

    def test_name_normalize(self, test_name):
        test_name0 = test_name
        m = re.match("^[^_]*NetworkManager[^_]*_[^_]*Test[^_]*_(.*)$", test_name)
        if m:
            test_name = m.group(1)
        if test_name and test_name[0] == "@":
            test_name = test_name[1:]
        if not re.match("^[" + self.TEST_NAME_VALID_CHAR_SET + "]+$", test_name):
            raise ValueError(f"Invalid test name {test_name0}")
        return test_name

    def test_get_feature_files(self, feature="*"):

        feature_dir = ""

        if feature[0] != "/":
            feature_dir = nmci.util.base_dir("features", "scenarios")

        if not feature.endswith(".feature"):
            feature = feature + ".feature"

        feature_path = os.path.join(feature_dir, feature)
        return glob.glob(feature_path)

    _re_tag = re.compile("^\\s*@([" + TEST_NAME_VALID_CHAR_SET + "]+)($|\\s+(.*))$")
    _re_sce = re.compile(r"^\s*Scenario: +")

    def _test_load_tags_from_file(self, filename, test_name=None):
        with open(filename, "rb") as f:
            i_line = 0
            tags = []
            for cur_line in f:
                i_line += 1
                cur_line = cur_line.decode("utf-8", errors="strict")

                s = cur_line
                tag_added = False
                while True:
                    m = self._re_tag.match(s)
                    if not m:
                        if tag_added:
                            if s and s[0] != "#":
                                # We found tags on the same line, but now there is some garbage(??)
                                raise Exception(
                                    f"Invalid tag at {filename}:{i_line}: followed by garbage and not a # comment"
                                )
                        break
                    tags.append(m.group(1))
                    s = m.group(3)
                    tag_added = True
                    if s is None:
                        break

                scenario_line = not tag_added and self._re_sce.match(cur_line)

                if not tags:
                    # We are in between tags and have no tags yet. Proceed to next line.
                    if scenario_line:
                        # Hm? A "Scenario:" but not tags? That's wrong.
                        raise Exception(
                            f"Unexpected scenario without any tags at {filename}:{i_line}"
                        )
                    continue

                if not scenario_line:
                    if tag_added:
                        # Good, we just found a tag on the current line.
                        continue
                    if re.match("^\\s*(#.*)?$", cur_line):
                        # an empty or comment line between tags is also fine.
                        continue
                    if re.match("^Feature:", cur_line):
                        # These were the tags for the feature. We ignore them.
                        tags = []
                        continue
                    raise Exception(
                        f"Invalid feature file {filename}:{i_line}: all tags are expected in consecutive lines"
                    )

                if test_name is None or test_name in tags:
                    yield tags
                tags = []

        if tags:
            raise Exception(
                f"Invalid feature file {filename}:{i_line}: contains tags without a Scenario"
            )

    def test_load_tags_from_file(self, filename, test_name=None):
        # We memoize the result of the parsing. Feel free to
        # delattr(self, "_test_load_tags_from_file_cache") to
        # prune the cache.
        k = (filename, test_name)
        if hasattr(self, "_test_load_tags_from_file_cache"):
            l = self._test_load_tags_from_file_cache.get(k, None)
            if l is not None:
                return l
        else:
            self._test_load_tags_from_file_cache = {}

        if test_name is None:
            l = list(self._test_load_tags_from_file(filename))
        else:
            l = self.test_load_tags_from_file(filename)
            l = [tags for tags in l if test_name in tags]

        self._test_load_tags_from_file_cache[k] = l
        return l

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

        test_tags = []
        for filename in feature_files:
            for tags in self.test_load_tags_from_file(filename, test_name):
                test_tags.append(tags)

        return test_tags

    def get_mapper_obj(self):
        if not os.path.isfile("mapper.json") or (
            os.path.getmtime("mapper.json") < os.path.getmtime("mapper.yaml")
        ):
            with open("mapper.yaml", "r") as m_yaml:
                mapper = yaml.load(m_yaml, Loader=yaml.CSafeLoader)
            with open("mapper.json", "w") as m_json:
                json.dump(mapper, m_json)
            return mapper
        with open("mapper.json", "r") as m_file:
            return json.load(m_file)

    def get_mapper_tests(self, mapper, feature="*"):
        all_features = ["*", "all"]
        testmappers = [x for x in mapper["testmapper"]]

        def flatten_test(test):
            testname = list(test.keys())[0]
            test = test[testname]
            test["testname"] = testname
            if testname.startswith("gsm_hub"):
                test["feature"] = "gsm"
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

        m = re.match(r"^(.*)\.((el|fc)([0-9]+)(_([0-9]+))?)$", version)
        if m:
            if m.group(3) == "el":
                d = "rhel"
            else:
                d = "fedora"
            pkg_suffix = {
                "full": m.group(2),
                "dist": d,
                "dist_1": m.group(4),
                "dist_2": m.group(6),
            }
            version_base = m.group(1)
        else:
            pkg_suffix = None
            version_base = version

        m = re.match(
            r"^([0-9]+\.[0-9]+\.[0-9]+([-.][0-9]+(\.[0-9]+)*)?)([-.].+)??$",
            version_base,
        )
        if m:
            v = [int(x) for x in m.group(1).replace("-", ".").split(".")]
            if len(v) < 4:
                stream = "unknown"
            elif v[3] > 1000:
                stream = "upstream"
            elif pkg_suffix:
                stream = f"{pkg_suffix['dist']}-{pkg_suffix['dist_1']}"
                if pkg_suffix["dist_2"]:
                    stream = f"{stream}-{pkg_suffix['dist_2']}"
            else:
                stream = "unknown"
            return (stream, v)

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
            current_version_str = nmci.process.run_stdout(["NetworkManager", "-V"])

        v = self.nm_version_parse(current_version_str)
        self._nm_version_detect_cached = v
        return v

    def distro_detect(self, use_cached=True):

        if use_cached and hasattr(self, "_distro_detect_cached"):
            return self._distro_detect_cached

        distro_version = [
            int(x)
            for x in nmci.process.run_stdout(
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

    class HitRaceException(Exception):
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
        # 2) if both '-=' and '+=' are present, they might either define single closed range
        #    e.g. "ver+=1.26, ver-=1.30", or a "hole" (buggy interval), e.g. "ver-=1.26, ver+=1.30".
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
        # 4) for each '+' version tag that comes right after '+' version tag (when sorted ascending),
        #    there is added '-' tag, keeping only first 2 parts of version:
        #    - "ver+=1.28.6 ver+=1.30.1" is equivalent to "ver+=1.28.6 ver-1.30 ver+=1.30.1"
        #      meaning, that 1.29.x is satisfied, but 1.30.0 is skipped
        #
        # 5) for each '-' version tag that comes right before '-' version tag (when sorted ascending),
        #    there is added '+' tag keeping only first 2 parts of version and adding "9999.9999" :
        #    - "ver-=1.28.6 ver-=1.30.1" is equivalent to "ver-=1.28.6 ver+1.28.9999.9999 ver-=1.30.1"

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

        # make all the tags equal length, treat "+" and "-=" as upper range
        def _fill_ver(op, ver):
            ver = list(ver)
            while len(ver) < l_version:
                if op in ["+", "-="]:
                    ver.append(9999)
                else:
                    ver.append(0)
            return (op, ver)

        ver_tags = [_fill_ver(op, ver) for op, ver in ver_tags]

        l_keep = 2
        if l_version <= 2:
            l_keep = 1

        def _compute_aux_tag(sign, version):
            inv_sign = sign.replace("+", "-") if "+" in sign else sign.replace("-", "+")
            # If version is += 1.28.2, do not add -=1.28.0, but rather -1.28.0
            # However, +=1.28.0 should be -=1.28.0 - so it is overlapping, rather than touching
            if any(version[l_keep:]):
                inv_sign = inv_sign.replace("=", "")
            if "+" in sign:
                version = version[:l_keep] + [0] * (l_version - l_keep)
            else:
                version = version[:l_keep] + [9999] * (l_version - l_keep)
            return (inv_sign, version)

        # Compute auxiliary tags to make stops at version breaks
        # This trims version into first 2 parts
        #  - if we are in "+" pass, and we see +=1.34.2 +=1.36.8
        #    add tag -1.36.0 so, versions between 1.34.2 and 1.35
        #    are not skipped
        #  - if we are in "-" pass and we see -=1.34.2 -=1.36.8
        #    add tag +1.34.9999 so, versions 1.35.X are not skipped
        def _add_aux_tags(ver_tags, sign):
            new_tags = []
            if not ver_tags:
                return ver_tags
            # first 2
            ver_tags = list(ver_tags)
            last_tag = None
            for tag in ver_tags:
                if sign in tag[0]:
                    if last_tag is not None and last_tag != tag[1][:2]:
                        aux_tag = _compute_aux_tag(*tag)
                        if aux_tag:
                            new_tags.append(aux_tag)
                    last_tag = tag[1][:2]
                else:
                    last_tag = None
            return new_tags

        # this is to compare the tags with same version
        # but different operator
        _op_idx = lambda op: ["-", "-=", "+=", "+"].index(op)

        # key for sorting the version tags
        _cmp_ver = lambda x: x[1] + [_op_idx(x[0])]

        ver_tags.sort(key=_cmp_ver)

        # "-" pass to compute range for "-" and "-=" tags
        # process in descending order
        ver_tags_1 = list(reversed(_add_aux_tags(reversed(ver_tags), "-")))

        # "+" pass to compute range for "+" and "+=" tags
        # do this over original list, as "-" pass might add
        # "+" tags, which we should ignore here
        ver_tags_2 = _add_aux_tags(ver_tags, "+")

        # join 2 lists, duplicates should not be an issue
        ver_tags = sorted(ver_tags + ver_tags_1 + ver_tags_2, key=_cmp_ver)

        def _eval(tag, version):
            if tag is None:
                return True
            op, tag_ver = tag
            if op == "+":
                return version > tag_ver
            elif op == "+=":
                return version >= tag_ver
            elif op == "-":
                return version < tag_ver
            elif op == "-=":
                return version <= tag_ver

        def _search_closest_tags(ver_tags, version):
            lo, hi = None, None
            for v in ver_tags:
                if v[1] <= version:
                    lo = v

            for v in reversed(ver_tags):
                if v[1] >= version:
                    hi = v

            return lo, hi

        low_range, high_range = _search_closest_tags(ver_tags, version)

        # check if closest tags are satisfied or not
        if not _eval(low_range, version):
            return False
        if not _eval(high_range, version):
            return False
        return True

    def test_find_feature_file(self, test_name, feature="*"):
        test_name = self.test_name_normalize(test_name=test_name)
        mapper_feature = [
            i["feature"]
            for i in self.get_mapper_tests(self.get_mapper_obj(), feature)
            if i["testname"] == test_name
        ][0]
        return f"{nmci.util.base_dir('features', 'scenarios')}/{mapper_feature}.feature"

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
        s = nmci.process.run_stdout(
            [nmci.util.util_dir("helpers/nmlog-parse-dnsmasq.sh"), ifname], timeout=20
        )
        import json

        return json.loads(s)

    def get_dns_info(self, dns_plugin, ifindex=None, ifname=None):

        if ifindex is None and ifname is None:
            raise ValueError("Missing argument, either ifindex or ifname must be given")

        ifdata = nmci.ip.link_show(ifindex=ifindex, ifname=ifname)

        if dns_plugin == "dnsmasq":
            info = self.nmlog_parse_dnsmasq(ifdata["ifname"])
            info["default_route"] = any((s == "." for s in info["domains"]))
            info["domains"] = [(s, "routing") for s in info["domains"]]
        elif dns_plugin == "systemd-resolved":
            info = nmci.sdresolved.link_get_all(ifdata["ifindex"])
            pass
        else:
            raise ValueError(f'Invalid dns_plugin "{dns_plugin}"')

        info["dns_plugin"] = dns_plugin
        return info

    def html_report_tag_links(self):

        if not nmci.embed.has_html_formatter():
            return

        scenario = nmci.embed.get_current_scenario()
        if not scenario:
            return

        html_tags = scenario.tags
        from . import tags

        try:
            git_url = nmci.git.config_get_origin_url()
            git_commit = nmci.git.rev_parse("HEAD")
        except Exception:
            git_url = None
            git_commit = None

        for tag in html_tags:
            tag_name = tag.behave_tag.lstrip("@")

            if tag_name.startswith("rhbz"):
                tag.set_link(
                    "https://bugzilla.redhat.com/" + tag_name.replace("rhbz", "")
                )
            elif tag_name in tags.tag_registry and git_url:
                lineno = tags.tag_registry[tag_name].lineno
                tag.set_link(f"{git_url}/-/tree/{git_commit}/nmci/tags.py#L{lineno}")
            else:
                lineno = scenario.location.line
                filename = scenario.location.filename
                tag.set_link(f"{git_url}/-/tree/{git_commit}/{filename}#L{lineno}")

    def html_report_file_links(self):

        if not nmci.embed.has_html_formatter():
            return

        scenario = nmci.embed.get_current_scenario()
        if not scenario:
            return

        try:
            git_url = nmci.git.config_get_origin_url()
            git_commit = nmci.git.rev_parse("HEAD")
        except Exception:
            return

        url_base = f"{git_url}/-/tree/{git_commit}/"

        for step in scenario.steps:
            if ":" not in step.location:
                continue
            filename = step.location.rsplit(":", 1)[0]
            lineno = step.location.split(":")[-1]
            step.location_link = url_base + filename + "#L" + lineno

    def journal_get_cursor(self):
        m = nmci.process.run_search_stdout(
            "journalctl --lines=0 --quiet --show-cursor --system",
            "^-- cursor: +([^ ].*[^ ]) *\n$",
            ignore_stderr=True,
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
                syslog_identifier = ["-t", nmci.util.bytes_to_str(syslog_identifier)]
            else:
                syslog_identifier = (["-t", s] for s in syslog_identifier)
                syslog_identifier = [c for pair in syslog_identifier for c in pair]
        else:
            syslog_identifier = []

        if cursor:
            cursor = ["--cursor=" + nmci.util.bytes_to_str(cursor)]
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

        with tempfile.TemporaryFile(dir=nmci.util.tmp_dir()) as f_out:
            nmci.process.run(
                ["journalctl", "--all", "--no-pager"]
                + service
                + syslog_identifier
                + cursor
                + short
                + journal_args,
                ignore_returncode=False,
                ignore_stderr=True,
                stdout=f_out,
                timeout=180,
            )

            f_out.seek(0)

            d = nmci.util.fd_get_content(
                f_out, max_size=max_size, warn_max_size=warn_max_size
            ).data

        if not as_bytes:
            d = d.decode(encoding="utf-8", errors="replace")

        if prefix is not None:
            if as_bytes:
                d = nmci.util.str_to_bytes(prefix) + b"\n" + d
            else:
                d = nmci.util.bytes_to_str(prefix) + "\n" + d

        if suffix is not None:
            if as_bytes:
                d = d + b"\n" + nmci.util.str_to_bytes(suffix)
            else:
                d = d + "\n" + nmci.util.bytes_to_str(suffix)

        return d

    def list_to_intervals(self, numbers):
        """
        Converts list of sorted numbers to string containing intervals.
        Example: [1,2,4,5,6,7,10] -> "1,2,4..7,10"
        """
        intervals = []
        last_interval = []
        # Append None, so last last_interval will be processed within the loop
        for number in numbers + [None]:
            if not last_interval:
                last_interval.append(number)
                continue
            if last_interval[-1] + 1 == number:
                last_interval.append(number)
                continue
            # prevent 1..1 and 1..2
            if len(last_interval) <= 2:
                for num in last_interval:
                    intervals.append(f"{num}")
            else:
                intervals.append(f"{last_interval[0]}..{last_interval[-1]}")
            last_interval = [number]
        return ",".join(intervals)

    def format_duration(self, seconds):
        return f"{seconds:.3f}s"

    def format_dict(self, values, connector=" = ", separator=", "):
        parts = []
        for key, value in values.items():
            parts.append(f"{key}{connector}{value}")
        return separator.join(parts)

    def str_replace_dict(self, text, values, dict_name="noted"):
        result = []
        text_split = text.split(f"<{dict_name}:")
        result = [text_split[0]]
        del text_split[0]
        for part in text_split:
            try:
                dict_key, rest = part.split(">", 1)
            except ValueError:
                assert False, f"Unterminated <{dict_name}:...> sequence:\n{text}"
            assert dict_key in values, f"Value for '{dict_key}' is not in {dict_name}"
            result.append(values[dict_key])
            result.append(rest)
        return "".join(result)
