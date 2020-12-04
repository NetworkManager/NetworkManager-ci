#!/bin/bash

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Copyright 2018 Red Hat, Inc.

set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ifname>"
    exit 1
fi

SINCE="$(systemctl show NetworkManager | sed -n 's/^ExecMainStartTimestamp=\(.*\) [A-Z0-9]\+$/\1/p')"

DEVICE="$1"

read -r -d '' AWK_PROGRAM <<EOF || true
/updating plugin dnsmasq/ {
    delete servers;
    delete domains;
}

match(\$0, /adding nameserver '(.*)@(.*)' for domain "(.*)"/, m) {
    if (m[2] == "$DEVICE") {
        servers[m[1]] = 1;
        domains[m[3]] = 1;
    }
}

match(\$0, /adding nameserver '(.*)@(.*)'$/, m) {
    if (m[2] == "$DEVICE") {
        servers[m[1]] = 1;
        domains["."] = 1;
    }
}

END {
    printf("{\\n");
    printf("    \"dns\": [");
    delim = "\\n";
    for (d in servers) {
        printf("%s        \"%s\"", delim, d);
        delim = ",\\n";
    }
    printf("\\n    ],\\n");
    printf("    \"domains\": [");
    delim = "\\n";
    for (d in domains) {
        printf("%s        \"%s\"", delim, d);
        delim = ",\\n";
    }
    printf("\\n    ]\\n");
    print "}";
}
EOF

journalctl -u NetworkManager --since "$SINCE" | awk "$AWK_PROGRAM"
