#!/usr/bin/python
# all credits to Gris Ge https://bugzilla.redhat.com/show_bug.cgi?id=1642625#c11
from subprocess import check_call
import sys

import gi

gi.require_version("NM", "1.0")
from gi.repository import Gio, GLib, NM


nmclient = NM.Client.new()

conn_name = sys.argv[1]
conn_ifname = sys.argv[2]

conn = nmclient.get_connection_by_id(conn_name)

if not conn:
    check_call(
        [
            "nmcli",
            "c",
            "add",
            "type",
            "ethernet",
            "ifname",
            conn_ifname,
            "connection.id",
            conn_name,
        ]
    )
    nmclient = NM.Client.new()
    conn = nmclient.get_connection_by_id("con_general")
    if not conn:
        print("Failed to find newly created connection")
        exit()

cancellable = Gio.Cancellable.new()
mainloop = GLib.MainLoop()

user_data = cancellable


def _active_connection_callback(src_object, result, user_data):
    user_data.cancel()
    mainloop.quit()


nmclient.activate_connection_async(
    conn, None, None, cancellable, _active_connection_callback, user_data
)

mainloop.run()
