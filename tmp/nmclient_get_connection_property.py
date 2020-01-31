#! /usr/bin/python

import sys
import gi
gi.require_version('NM', '1.0')
from gi.repository import NM

# Usage nmclient_get_connection_property $connection $property
property = sys.argv[2]
connection = sys.argv[1]

nmclient = NM.Client.new(None)
connections = nmclient.get_connections()
conn = None
for c in connections:
    if connection == c.get_id():
        conn = c
        for section in conn.get_settings():
            try:
                val = section.get_property(property)
                break
            except:
                continue
        if val:
            print (val)
            exit(0)

print ("No such property for connection %s:%s" %(connection,property))
exit(1)
