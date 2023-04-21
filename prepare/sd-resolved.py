#!/usr/bin/env python3
# -*- Mode: python; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Copyright 2018 Red Hat, Inc.

import dbus, sys, ipaddress


def AddrToString(addr):
    if len(addr) == 4:
        return str(ipaddress.IPv4Address(bytes(addr)))
    elif len(addr) == 16:
        return str(ipaddress.IPv6Address(bytes(addr)))


def Usage():
    print("Usage: {} <IFNAME>".format(sys.argv[0]))
    sys.exit(1)


if len(sys.argv) < 2:
    Usage()

with open("/sys/class/net/{}/ifindex".format(sys.argv[1]), "r") as sysfile:
    ifindex = int(sysfile.read())

bus = dbus.SystemBus()
proxy = bus.get_object("org.freedesktop.resolve1", "/org/freedesktop/resolve1")
link_path = proxy.GetLink(ifindex, dbus_interface="org.freedesktop.resolve1.Manager")

link_proxy = bus.get_object("org.freedesktop.resolve1", link_path)
prop_iface = dbus.Interface(link_proxy, "org.freedesktop.DBus.Properties")
dns = prop_iface.Get("org.freedesktop.resolve1.Link", "DNS")
domains = prop_iface.Get("org.freedesktop.resolve1.Link", "Domains")
mdns = prop_iface.Get("org.freedesktop.resolve1.Link", "MulticastDNS")

for d in dns:
    print("DNS: {}".format(AddrToString(d[1])))

for d in domains:
    print("Domain: {} {}".format("(routing)" if d[1] == 1 else "(search)", d[0]))

print("MulticastDns: {}".format(mdns))
