#!/usr/bin/python

import gi
import time
from subprocess import check_output
import socket
import sys

gi.require_version("NM", "1.0")
from gi.repository import Gio, GLib, NM

# callback function, data should contain dictionary, with name of the function to call under "fn_name" key
def cb(caller, result, data):
    try:
        fn = getattr(caller, data["fn_name"])
        fn(result)
    except Exception as e:
        print("Error: %s" % e)
    main_loop.quit()


def die(msg="Error: exiting..."):
    print(msg)
    sys.exit(1)


# parse arguments - connection name and device name
try:
    c_name, d_name = sys.argv[1:3]
except:
    print("Error: not enough arguments, need connection name and device name")

nmclient = NM.Client.new()
main_loop = GLib.MainLoop()

# ged device and connection objects
d = nmclient.get_device_by_iface(d_name) or die(
    "Error: could not find device %s" % d_name
)
c = nmclient.get_connection_by_id(c_name) or die(
    "Error: could not find connection %s" % c_name
)

# create new connection and copy settings, do not copy wired settings
nc = NM.SimpleConnection.new()
nc.add_setting(c.get_setting_connection())
nc.add_setting(c.get_setting_ip4_config())

# replace the settings in original connection (will remove wired settings)
c.replace_settings_from_connection(nc)

# async update connection
c.commit_changes_async(True, None, cb, {"fn_name": "commit_changes_finish"})

main_loop.run()

# device reapply should NOT fail with message:
# nm-device-error-quark: Can't reapply any changes to '802-3-ethernet' setting (3)
# https://bugzilla.redhat.com/show_bug.cgi?id=1703960
try:
    d.reapply(c, 0, 0, None)
except Exception as e:
    print("Error: %s" % e)
