#!/usr/bin/python3
# SPDX-License-Identifier: LGPL-2.1-or-later

import os
import sys
import socket

import gi

gi.require_version("NM", "1.0")
from gi.repository import NM, GLib, Gio, GObject


def device_get_applied_connection(device):
    mainloop = GLib.MainLoop()
    r = []

    def cb(device, result):
        try:
            connection, version_id = device.get_applied_connection_finish(result)
        except Exception as e:
            r.append(e)
        else:
            r.append(connection)
            r.append(version_id)
        mainloop.quit()

    device.get_applied_connection_async(0, None, cb)
    mainloop.run()
    if len(r) == 1:
        raise r[0]
    connection, version_id = r
    return connection, version_id


def device_reapply(device, connection, version_id, reapply_flags):
    mainloop = GLib.MainLoop()
    r = []

    def cb(device, result):
        try:
            device.reapply_finish(result)
        except Exception as e:
            r.append(e)
        mainloop.quit()

    device.reapply_async(connection, version_id or 0, reapply_flags, None, cb)
    mainloop.run()
    if len(r) == 1:
        raise r[0]


def main():
    nmc = NM.Client.new()

    device = [d for d in nmc.get_devices() if d.get_iface() == sys.argv[1]]
    if not device:
        raise Exception(f'Device "{sys.argv[1]}" not found')
    if len(device) != 1:
        raise Exception(f'Not unique device "{sys.argv[1]}" found')
    device = device[0]

    reapply_flags = 0

    (nm_conn, version_id) = device_get_applied_connection(device)
    nm_ip4_set = nm_conn.get_setting_ip4_config()
    nm_ip4_set.add_address(NM.IPAddress.new(socket.AF_INET, sys.argv[2], 24))
    device_reapply(device, nm_conn, version_id, reapply_flags)


if __name__ == "__main__":
    main()
