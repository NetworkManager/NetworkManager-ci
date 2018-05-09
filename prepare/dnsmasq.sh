#!/bin/sh
# -*- Mode: sh; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Copyright 2018 Red Hat, Inc.

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ifname>"
    exit 1
fi

since="$(systemctl show NetworkManager | sed -n 's/^ExecMainStartTimestamp=\(.*\) [A-Z0-9]\+$/\1/p')"

awk_program="
/updating plugin dnsmasq/ {
    delete servers;
    delete domains;
}

match(\$0, /adding nameserver '(.*)@(.*)' for domain \"(.*)\"/, m) {
    if (m[2] == \"$1\") {
        servers[m[1]] = 1;
        domains[m[3]] = 1;
    }
}

match(\$0, /adding nameserver '(.*)@(.*)'\$/, m) {
    if (m[2] == \"$1\") {
        servers[m[1]] = 1;
        domains[\".\"] = 1;
    }
}

END {
    for (d in servers)
        print \"DNS: \" d;
    for (d in domains)
        print \"Domain: (routing) \" d;
}"

journalctl -u NetworkManager --since "$since" | awk "$awk_program"
