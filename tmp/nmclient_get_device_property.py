#! /usr/bin/python

import sys
import gi
gi.require_version('NM', '1.0')
from gi.repository import NM

# Usage nmclient_get_device_property $device $property
property = sys.argv[2]
device = sys.argv[1]

nmclient = NM.Client.new(None)
devices = nmclient.get_devices()
for d in devices:
    if device == d.get_iface():
        try:
            getattr(d,property)
        except:
            print ("No such property on device. %s:%s" %(device, property))
            print ("These are just available")
            print (dir(d))
            exit(1)
        device = d
        print(getattr(device,property)())
        exit(0)

print ("No such device. %s" %(device))

exit(1)
