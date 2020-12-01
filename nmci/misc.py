import os
import re
import subprocess
import sys

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


sys.modules[__name__] = _Misc()
