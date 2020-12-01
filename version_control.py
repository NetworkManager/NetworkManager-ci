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
from subprocess import call, check_output

import nmci.misc


# gather current system info (versions, pkg vs. build)
if "NM_VERSION" in os.environ:
    current_nm_version = os.environ["NM_VERSION"]
elif os.path.isfile("/tmp/nm_version_override"):
    with open("/tmp/nm_version_override") as f:
        current_nm_version = f.read()
else:
    current_nm_version = check_output(["NetworkManager", "-V"]).decode("utf-8")
current_nm_version = [int(x) for x in current_nm_version.split("-")[0].split(".")]

distro_version = [
    int(x)
    for x in check_output(["sed", "s/.*release *//;s/ .*//", "/etc/redhat-release"])
    .decode("utf-8")
    .split(".")
]
if call(["grep", "-qi", "fedora", "/etc/redhat-release"]) == 0:
    current_rhel_version = False
    current_fedora_version = distro_version
else:
    current_rhel_version = distro_version
    current_fedora_version = False
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

# compare two version lists, return True, iff tag does not violate current_version
def cmp(tag, tag_version, current_version):
    if not current_version:
        # return true here, because tag does nto violate version
        return True
    if "+=" in tag:
        if current_version < tag_version:
            return False
    elif "-=" in tag:
        if current_version > tag_version:
            return False
    elif "-" in tag:
        if current_version >= tag_version:
            return False
    elif "+" in tag:
        if current_version <= tag_version:
            return False
    return True


# pad version list to the specified length
# add 9999 if comparing -=, because we want -=1.20 to be true also for 1.20.5
def padding(tag, tag_version, length):
    app = 0
    if "-=" in tag:
        app = 9999
    while len(tag_version) < length:
        tag_version.append(app)
    return tag_version


# go through all the tests
for tags in test_tags:
    # so far, there is not tag violation, run is True
    run = True
    # check all tags for this test
    for tag in tags:
        if tag.startswith("ver+") or tag.startswith("ver-"):
            tag_nm_version = [
                int(x)
                for x in tag.replace("=", "")
                .replace("ver+", "")
                .replace("ver-", "")
                .split(".")
            ]
            tag_nm_version = padding(tag, tag_nm_version, 3)
            if not cmp(tag, tag_nm_version, current_nm_version):
                run = False
        elif tag.startswith("rhelver+") or tag.startswith("rhelver-"):
            tag_rhel_version = [
                int(x)
                for x in tag.replace("=", "")
                .replace("rhelver+", "")
                .replace("rhelver-", "")
                .split(".")
            ]
            tag_rhel_version = padding(tag, tag_rhel_version, 2)
            if not cmp(tag, tag_rhel_version, current_rhel_version):
                run = False
        elif tag.startswith("fedoraver+") or tag.startswith("fedoraver-"):
            tag_fedora_version = [
                int(x)
                for x in tag.replace("=", "")
                .replace("fedoraver+", "")
                .replace("fedoraver-", "")
                .split(".")
            ]
            # do not pad Fedora version - single number
            if not cmp(tag, tag_fedora_version, current_fedora_version):
                run = False
        elif tag == "rhel_pkg":
            if current_rhel_version and not pkg:
                run = False
        elif tag == "not_with_rhel_pkg":
            if current_rhel_version and pkg:
                run = False
        elif tag == "fedora_pkg":
            if current_fedora_version and not pkg:
                run = False
        elif tag == "not_with_fedora_pkg":
            if current_fedora_version and pkg:
                run = False
    if run:
        print(" -t ".join(tags))
        sys.exit(0)

# test definition found, but version mismatch
sys.stderr.write("Skipping, version mismatch.\n")
sys.exit(77)
