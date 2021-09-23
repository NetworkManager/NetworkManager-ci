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


(nm_stream, nm_version) = nmci.misc.nm_version_detect()
(distro_flavor, distro_version) = nmci.misc.distro_detect()

test_name = nmci.misc.test_name_normalize(sys.argv[2])

test_tags = nmci.misc.test_load_tags_from_features(sys.argv[1], test_name=test_name)
if not test_tags:
    sys.stderr.write("test with tag '%s' not defined!\n" % test_name)
    sys.exit(1)


def ver_param_to_str(nm_stream, nm_version, distro_flavor, distro_version):
    nm_version = ".".join([str(c) for c in nm_version])
    distro_version = ".".join([str(c) for c in distro_version])
    return f"ver:{nm_version}, stream:{nm_stream}, {distro_flavor}:{distro_version}"


result = None


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
    if not run:
        continue

    if not nmci.misc.test_version_tag_eval(tags_ver, nm_version):
        continue
    if distro_flavor == "rhel" and not nmci.misc.test_version_tag_eval(
        tags_rhelver, distro_version
    ):
        continue
    if distro_flavor == "fedora" and not nmci.misc.test_version_tag_eval(
        tags_fedoraver, distro_version
    ):
        continue

    if result:
        sys.stderr.write(
            "test with tag '%s' has more than one match for %s: %r and %r!\n"
            % (
                ver_param_to_str(
                    nm_stream,
                    nm_version,
                    distro_flavor,
                    distro_version,
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
                nm_stream,
                nm_version,
                distro_flavor,
                distro_version,
            )
        )
    )
    sys.exit(77)

print("-t " + (" -t ".join(result)))
sys.exit(0)
