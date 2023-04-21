#!/usr/bin/env python
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright (C) 2011 Red Hat, Inc.
#

import dbus
import sys


def path_to_value(path):
    if sys.version_info[0] == 3:
        array = bytearray("file://" + path + "\0", "utf-8")
    else:
        array = "file://" + path + "\0"
    return dbus.ByteArray(array)


s_con = dbus.Dictionary(
    {
        "type": "802-11-wireless",
        "uuid": "7371bb78-c1f7-42a3-a9db-5b9566e8ca07",
        "id": "wifi-wlan0",
    }
)

if sys.version_info[0] == 3:
    homewifi = bytearray("homewifi", "utf-8")
else:
    homewifi = "homewifi"

s_wifi = dbus.Dictionary(
    {"ssid": dbus.ByteArray(homewifi), "security": "802-11-wireless-security"}
)

s_wsec = dbus.Dictionary({"key-mgmt": "wpa-eap"})

s_8021x = dbus.Dictionary(
    {
        "eap": ["tls"],
        "identity": "Bill Smith",
        "client-cert": path_to_value("/tmp/certs/client.pem"),
        "ca-cert": "somerandomstring",
        "private-key": path_to_value("/tmp/certs/client.pem"),
        "private-key-password": "12345testing",
    }
)

s_ip4 = dbus.Dictionary({"method": "auto"})
s_ip6 = dbus.Dictionary({"method": "ignore"})

con = dbus.Dictionary(
    {
        "connection": s_con,
        "802-11-wireless": s_wifi,
        "802-11-wireless-security": s_wsec,
        "802-1x": s_8021x,
        "ipv4": s_ip4,
        "ipv6": s_ip6,
    }
)


bus = dbus.SystemBus()

proxy = bus.get_object(
    "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings"
)
settings = dbus.Interface(proxy, "org.freedesktop.NetworkManager.Settings")

settings.AddConnection(con)
