#!/bin/python3

import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "..", ".."))

import nmci.misc

if len(sys.argv) != 2:
    print("Invalid arguments. Call with test name as parameter")
    sys.exit(1)

try:
    (feature, test_name, tags) = nmci.misc.test_version_check(test_name=sys.argv[1])
except Exception as e:
    print(str(e))
    if isinstance(e, nmci.misc.SkipTestException):
        sys.exit(77)
    sys.exit(1)

print(feature)
print(test_name)
for t in tags:
    print(t)
