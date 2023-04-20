#!/usr/bin/env python
# Author: Beniamino Galvani <bgalvani@redhat.com>

import gi

gi.require_version("NM", "1.0")
from gi.repository import GLib, NM
import sys, socket, uuid


def create_profile():
    profile = NM.SimpleConnection.new()

    s_con = NM.SettingConnection.new()
    s_con.set_property(NM.SETTING_CONNECTION_ID, "bond0")
    s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, "nm-bond")
    s_con.set_property(NM.SETTING_CONNECTION_UUID, str(uuid.uuid4()))
    s_con.set_property(NM.SETTING_CONNECTION_TYPE, "bond")

    s_bond = NM.SettingBond.new()

    s_ip4 = NM.SettingIP4Config.new()
    s_ip4.set_property(NM.SETTING_IP_CONFIG_METHOD, "manual")
    s_ip4.add_address(NM.IPAddress.new(socket.AF_INET, "172.19.0.1", 32))

    s_ip6 = NM.SettingIP6Config.new()
    s_ip6.set_property(NM.SETTING_IP_CONFIG_METHOD, "ignore")

    profile.add_setting(s_con)
    profile.add_setting(s_ip4)
    profile.add_setting(s_ip6)
    profile.add_setting(s_bond)

    return profile


def activate_cb(client, result, data):
    try:
        client.activate_connection_finish(result)
        print("Connection activated")
    except Exception as e:
        sys.stderr.write("Error activating connection: %s\n" % e)

    main_loop.quit()


def add_cb(client, result, data):
    try:
        con = client.add_connection_finish(result)
        print("Connection added")
        client.activate_connection_async(con, None, None, None, activate_cb, None)
    except Exception as e:
        sys.stderr.write("Error adding connection: %s\n" % e)
        main_loop.quit()


if __name__ == "__main__":
    main_loop = GLib.MainLoop()
    client = NM.Client.new(None)
    con = create_profile()
    client.add_connection_async(con, False, None, add_cb, None)

    main_loop.run()
