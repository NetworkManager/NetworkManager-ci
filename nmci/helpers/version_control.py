#!/bin/python3

import sys
import os
import traceback

sys.path.append(os.path.join(os.path.dirname(__file__), "..", ".."))

import nmci.misc

if len(sys.argv) != 2:
    print("Invalid arguments. Call with test name as parameter")
    sys.exit(1)

test_name = sys.argv[1]

try:
    (feature, test_name, tags) = nmci.misc.test_version_check(test_name=test_name)
except nmci.misc.SkipTestException as e:
    sys.exit(77)
except nmci.misc.TestNotFoundException as e:
    print(f'Test "{test_name}" not found')
    sys.exit(1)
except Exception as e:
    traceback.print_exc()
    sys.exit(1)

print(feature)
print(test_name)
for t in tags:
    print(t)
