#!/usr/bin/env python

import gi

gi.require_version("NM", "1.0")
from gi.repository import GLib, NM, Gio
import uuid
import sys

test_res = []

################################################

# async callback, appends test result to test_res list
def add_con_cb(client, result, data):
    try:
        client.add_connection_finish(result)
        # test result is False, because exception should be thrown
        test_res.append(1)
    except Exception as e:
        s_e = str(e)
        if "Operation was cancelled" in s_e:
            test_res.append(0)
        else:
            # operation was not canceled, but other error occured
            print("Operation was not cancelled: %s" % s_e)
            test_res.append(1)
    main_loop.quit()


################################################

connection = sys.argv[1]

cancellable = Gio.Cancellable.new()

main_loop = GLib.MainLoop()

# create connection profile
profile = NM.SimpleConnection.new()
s_con = NM.SettingConnection.new()
s_con.set_property(NM.SETTING_CONNECTION_ID, connection)
s_con.set_property(NM.SETTING_CONNECTION_UUID, str(uuid.uuid4()))
s_con.set_property(NM.SETTING_CONNECTION_TYPE, "802-3-ethernet")

s_wired = NM.SettingWired.new()

s_ip4 = NM.SettingIP4Config.new()
s_ip4.set_property(NM.SETTING_IP_CONFIG_METHOD, "auto")

s_ip6 = NM.SettingIP6Config.new()
s_ip6.set_property(NM.SETTING_IP_CONFIG_METHOD, "auto")

profile.add_setting(s_con)
profile.add_setting(s_ip4)
profile.add_setting(s_ip6)
profile.add_setting(s_wired)

# create nm client
client = NM.Client.new(None)

# add connection asynchronously
client.add_connection_async(profile, False, cancellable, add_con_cb, None)
# cancel it
cancellable.cancel()
main_loop.run()

# test_res[0] should be 0, iff successfully cancelled
exit(test_res[0])
