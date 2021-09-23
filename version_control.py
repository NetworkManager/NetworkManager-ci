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
import nmci.misc


test_name = nmci.misc.test_name_normalize(test_name=sys.argv[2])

test_tags_list = nmci.misc.test_load_tags_from_features(
    feature=sys.argv[1], test_name=test_name
)

if not test_tags_list:
    sys.stderr.write("test with tag '%s' not defined!\n" % test_name)
    sys.exit(1)


try:
    result = nmci.misc.test_tags_select(
        test_tags_list, nmci.misc.nm_version_detect(), nmci.misc.distro_detect()
    )
except nmci.misc.SkipTestException as e:
    sys.stderr.write("skip test '%s': %s\n" % (test_name, str(e)))
    sys.exit(77)
except Exception as e:
    sys.stderr.write("error checking test '%s': %s\n" % (test_name, str(e)))
    sys.exec(1)

print("-t " + (" -t ".join(result)))
sys.exit(0)
