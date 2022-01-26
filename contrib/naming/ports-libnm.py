#!/usr/bin/env python3

import sys
import gi

gi.require_version("NM", "1.0")
from gi.repository import GLib, NM

dev_iface = sys.argv[1]
c = NM.Client.new(None)
dev = c.get_device_by_iface(dev_iface)
if dev is None:
   sys.exit("Device '%s' not found" % dev_iface)
ports = dev.get_ports()
for port in ports:
    print(port.get_iface())
