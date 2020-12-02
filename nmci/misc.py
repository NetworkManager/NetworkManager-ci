import os
import re
import subprocess
import sys

from . import ip
from . import sdresolved
from . import util


class _Misc:

    TEST_NAME_VALID_CHAR_REGEX = "[-a-z_.A-Z0-9+=]"

    def test_name_normalize(self, test_name):
        test_name0 = test_name
        m = re.match("^[^_]*NetworkManager[^_]*_[^_]*Test[^_]*_(.*)$", test_name)
        if m:
            test_name = m.group(1)
        if test_name[0] == "@":
            test_name = test_name[1:]
        if not re.match("^" + self.TEST_NAME_VALID_CHAR_REGEX + "+$", test_name):
            raise ValueError(f"Invalid test name {test_name0}")
        return test_name

    def test_get_feature_files(self, feature):

        import glob

        if feature[0] == "/":
            feature_dir = os.path.join(feature, "features")
        else:
            feature_dir = util.base_dir(feature, "features")

        return glob.glob(feature_dir + "/*.feature")

    def test_load_tags_from_features(self, feature, test_name=None):

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
        s = util.process_run(
            [util.util_dir("helpers/nmlog-parse-dnsmasq.sh"), ifname], as_utf8=True
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


sys.modules[__name__] = _Misc()
