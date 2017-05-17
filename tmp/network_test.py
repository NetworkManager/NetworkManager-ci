#!/usr/bin/python

import sys, threading, time

# Talk to Network Manager through Gnome Introspection
# https://wiki.gnome.org/Projects/NetworkManager/Developers
# NM Overview https://lazka.github.io/pgi-docs/NM-1.0/index.html
import gi
gi.require_version('NM', '1.0')
from gi.repository import GLib, NM

# Create client for NetworkManager
nmclient = NM.Client.new(None)

# Create GLib message pump, needed for async NM.Client calls
thread = threading.Thread(target=lambda: GLib.MainLoop().run())
thread.daemon = True
thread.start()

connection_name = sys.argv[1]
connection = nmclient.get_connection_by_id(connection_name)


def _activate_callback(client, result, data):
    # data is a threading.Event() used for signalling done
    try:
        client.activate_connection_finish(result)
        print "Successfully activated"
    except Exception as e:
        print "Failed activating connection: {}".format(e)
    data.set()


def activate_connection():
    activation_done = threading.Event()
    nmclient.activate_connection_async(
        connection, None, None, None,
        _activate_callback, activation_done)
    if not activation_done.wait(timeout=30):
        raise Exception(
            "Timeout during activation of {}"
            .format(connection_name))
    print "Done activating"


before_cons = nmclient.get_active_connections()

print "Active connections before: %d" % (len(before_cons))
print
print "before_cons:  %s" % before_cons
print

counter = 1

for nmobj in before_cons:
	print
	print " Connection %d: %s" % (counter, nmobj.get_uuid())
	print " Connection state: %s" % nmobj.get_state()
        print " get_devices():  %s" % nmobj.get_devices()

	for device in nmobj.get_devices():
		print "  Device: %s" % device.get_iface()

	counter += 1

print
print "Activating connection %s..." % connection_name

activate_connection()

after_cons = nmclient.get_active_connections()

loop = 2

while loop != 0:

	print
	print "Active connections after: %d" % (len(after_cons))
	print
	print "after_cons:  %s" % after_cons

	counter = 1

	for nmobj in after_cons:
		print
		print " Connection %d: %s" % (counter, nmobj.get_uuid())
		print " Connection state: %s" % nmobj.get_state()
		print " get_devices():  %s" % nmobj.get_devices()

		for device in nmobj.get_devices():
			print "  Device: %s" % device.get_iface()

		counter += 1

	print
	print "Sleeping for 3 seconds..."
	time.sleep(3)
	loop -= 1
