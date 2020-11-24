#!/usr/bin/env python3

import sys
import re
import subprocess
import json
import collections

###############################################################################


def die(msg):
    print(msg)
    sys.exit(1)


def ovs_get_external_ids(typ, name):

    p = subprocess.run(
        ["ovs-vsctl", "-f", "json", "--columns=name,external-ids", "list", typ],
        stdout=subprocess.PIPE,
        check=True,
    )

    doc = json.loads(p.stdout)

    for iface in doc["data"]:

        if iface[0] == name:
            d2 = iface[1]
            assert d2[0] == "map"
            result = collections.OrderedDict()
            for tupl in d2[1]:
                result[tupl[0]] = tupl[1]
            return result

    die("Did not find external-ids for %s.%s" % (typ, name))


###############################################################################

if __name__ == "__main__":

    if len(sys.argv) < 3:
        die("missing arguments")

    typ = sys.argv[1]
    if typ not in ["Bridge", "Port", "Interface"]:
        die(f"first argument must be Bridge/Port/Interface but is {typ}")

    name = sys.argv[2]

    keys = sys.argv[3:]

    if len(keys) % 2 != 0:
        die("Requires key/value pairs as arguments but got %s" % (" ".join(keys)))

    data0 = ovs_get_external_ids(typ, name)

    data = data0.copy()

    for i in range(int(len(keys) / 2)):
        key = keys[i * 2]
        val = keys[i * 2 + 1]

        val2 = data.get(key)

        if val2 is None:
            die(
                "expects to have key '%s', but it was not found for %s.%s: %s"
                % (key, typ, name, data0)
            )

        if val[0] == "~":
            if not re.match(val[1:], val2):
                die(
                    "expects to have key '%s' with pattern %s, but it has an unexpected value for %s.%s: %s"
                    % (key, val, typ, name, data0)
                )
        else:
            if val[0] == "=":
                v = val[1:]
            else:
                v = val
            if val2 != v:
                die(
                    "expects to have key '%s' with value '%s', but it has an unexpected value for %s.%s: %s"
                    % (key, val, typ, name, data0)
                )

        del data[key]

    if data:
        die(
            "we have unexpected keys for %s.%s: %s // %s"
            % (typ, name, ", ".join(['"' + k + '"' for k in data]), data0)
        )
