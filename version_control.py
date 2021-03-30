#!/bin/python
#
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

import sys
import os
import logging
from subprocess import call, check_output

import nmci.misc


logging.basicConfig(level = logging.DEBUG)

# gather current system info (versions, pkg vs. build)
if "NM_VERSION" in os.environ:
    current_nm_version = os.environ["NM_VERSION"]
elif os.path.isfile("/tmp/nm_version_override"):
    with open("/tmp/nm_version_override") as f:
        current_nm_version = f.read()
else:
    current_nm_version = check_output(["NetworkManager", "-V"]).decode("utf-8")
current_nm_release = [int(x) for x in current_nm_version.split("-")[1].split(".el")[0].split(".")]
current_nm_version = [int(x) for x in current_nm_version.split("-")[0].split(".")]

distro_version = [
    int(x)
    for x in check_output(["sed", "s/.*release *//;s/ .*//", "/etc/redhat-release"])
    .decode("utf-8")
    .split(".")
]
if call(["grep", "-qi", "fedora", "/etc/redhat-release"]) == 0:
    current_rhel_version = None
    current_fedora_version = distro_version
else:
    current_rhel_version = distro_version
    current_fedora_version = None

logging.debug("release versions")
logging.debug(current_rhel_version)
logging.debug(current_fedora_version)
logging.debug(distro_version)
logging.debug(current_nm_release)
logging.debug(current_nm_version)

# TODO: incorrectly matching 0.7 release
pkg_ver = (
    check_output(["rpm", "--queryformat", "%{RELEASE}", "-q", "NetworkManager"])
    .decode("utf-8")
    .split(".")[0]
)
pkg = int(pkg_ver) < 200

test_name = nmci.misc.test_name_normalize(sys.argv[2])
test_tags = nmci.misc.test_load_tags_from_features(sys.argv[1], test_name)

if not test_tags:
    sys.stderr.write("test with tag '%s' not defined!\n" % test_name)
    sys.exit(1)

result = None


def ver_param_to_str(
    current_nm_version, current_rhel_version, current_fedora_version, pkg
):

    current_nm_version = ".".join([str(c) for c in current_nm_version])
    logging.debug(current_nm_version)

    if current_rhel_version:
        current_rhel_version = ".".join([str(c) for c in current_rhel_version])
    if current_fedora_version:
        current_fedora_version = ".".join([str(c) for c in current_fedora_version])
    return "ver:%s%s%s, pkg:%s" % (
        current_nm_version,
        f", rhelver:{current_rhel_version}" if current_rhel_version else "",
        f", fedoraver:{current_fedora_version}" if current_fedora_version else "",
        "pkg" if pkg else "upstream",
    )


for tags in test_tags:
    tags_ver = []
    tags_rel = []
    tags_rhelver = []
    tags_fedoraver = []

    run = True
    for tag in tags:
        if tag.startswith("ver"):
            tags_ver.append(nmci.misc.test_version_tag_parse(tag, "ver"))
        elif tag.startswith("rhelver"):
            tags_rhelver.append(nmci.misc.test_version_tag_parse(tag, "rhelver"))
        elif tag.startswith("fedoraver"):
            tags_fedoraver.append(nmci.misc.test_version_tag_parse(tag, "fedoraver"))
        elif tag.startswith("rhelpkgver"):
            tag_ver = tag.split('-')[0]
            # We need to process +/- as this has to be passed only to release
            cand = nmci.misc.test_version_tag_parse(tag_ver, "rhelpkgver")
            op = cand[0]
            ver = cand[1]
            if len(op) == 1:
                op_new = op+'='
            else:
                op_new = op
            logging.debug(tags_ver)
            tags_ver.append((op_new, ver))

            # Create release tag
            prefix = tag.split(op)[0]+op
            rel = tag.split('-')[1]
            tag_rel = prefix+rel
            tags_rel.append(nmci.misc.test_version_tag_parse(tag_rel, "rhelpkgver"))
            logging.debug(tags_rel)

        elif tag == "rhel_pkg":
            if not (current_rhel_version and pkg):
                run = False
        elif tag == "not_with_rhel_pkg":
            if current_rhel_version and pkg:
                run = False
        elif tag == "fedora_pkg":
            if not (current_fedora_version and pkg):
                run = False
        elif tag == "not_with_fedora_pkg":
            if current_fedora_version and pkg:
                run = False

    if not run:
        continue

    if not nmci.misc.test_version_tag_eval(tags_ver, current_nm_version):
        continue
    if tags_rel and not nmci.misc.test_version_tag_eval(tags_rel, current_nm_release):
        continue

    if current_rhel_version and not nmci.misc.test_version_tag_eval(
        tags_rhelver, current_rhel_version
    ):
        continue
    if current_fedora_version and not nmci.misc.test_version_tag_eval(
        tags_fedoraver, current_fedora_version
    ):
        continue

    if result:
        sys.stderr.write(
            "test with tag '%s' has more than one match for %s: %r and %r!\n"
            % (
                ver_param_to_str(
                    current_nm_version,
                    current_nm_release,
                    current_rhel_version,
                    current_fedora_version,
                    pkg,
                ),
                test_name,
                result,
                tags,
            )
        )
        sys.exit(1)

    result = tags

if not result:
    sys.stderr.write(
        "Skipping, version mismatch for %s.\n"
        % (
            ver_param_to_str(
                current_nm_version, current_rhel_version, current_fedora_version, pkg
            )
        )
    )
    sys.exit(77)

print("-t " + (" -t ".join(result)))
sys.exit(0)
