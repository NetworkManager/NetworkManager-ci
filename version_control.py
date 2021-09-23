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


(current_nm_stream, current_nm_version) = nmci.misc.nm_version_detect()

distro_version = [
    int(x)
    for x in check_output(
        ["sed", "s/.*release *//;s/ .*//;s/Beta//;s/Alpha//", "/etc/redhat-release"]
    )
    .decode("utf-8")
    .split(".")
]
if call(["grep", "-qi", "fedora", "/etc/redhat-release"]) == 0:
    current_rhel_version = None
    current_fedora_version = distro_version
else:
    current_rhel_version = distro_version
    current_fedora_version = None
    if current_rhel_version == [8]:
        # CentOS stream only gives "CentOS Stream release 8". Hack a minor version
        # number
        current_rhel_version = [8, 99]

test_name = nmci.misc.test_name_normalize(sys.argv[2])

test_tags = nmci.misc.test_load_tags_from_features(sys.argv[1], test_name=test_name)
if not test_tags:
    sys.stderr.write("test with tag '%s' not defined!\n" % test_name)
    sys.exit(1)

result = None


def ver_param_to_str(
    current_nm_stream, current_nm_version, current_rhel_version, current_fedora_version
):

    current_nm_version = ".".join([str(c) for c in current_nm_version])
    if current_rhel_version:
        current_rhel_version = ".".join([str(c) for c in current_rhel_version])
    if current_fedora_version:
        current_fedora_version = ".".join([str(c) for c in current_fedora_version])
    return "ver:%s, stream:%s%s%s" % (
        current_nm_version,
        current_nm_stream,
        f", rhelver:{current_rhel_version}" if current_rhel_version else "",
        f", fedoraver:{current_fedora_version}" if current_fedora_version else "",
    )


for tags in test_tags:
    tags_ver = []
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
        elif tag == "rhel_pkg":
            if not (current_rhel_version and current_nm_stream.startswith("rhel")):
                run = False
        elif tag == "not_with_rhel_pkg":
            if current_rhel_version and current_nm_stream.startswith("rhel"):
                run = False
        elif tag == "fedora_pkg":
            if not (current_fedora_version and current_nm_stream.startswith("fedora")):
                run = False
        elif tag == "not_with_fedora_pkg":
            if current_fedora_version and current_nm_stream.startswith("fedora"):
                run = False
    if not run:
        continue

    if not nmci.misc.test_version_tag_eval(tags_ver, current_nm_version):
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
                    current_nm_stream,
                    current_nm_version,
                    current_rhel_version,
                    current_fedora_version,
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
                current_nm_stream,
                current_nm_version,
                current_rhel_version,
                current_fedora_version,
            )
        )
    )
    sys.exit(77)

print("-t " + (" -t ".join(result)))
sys.exit(0)
