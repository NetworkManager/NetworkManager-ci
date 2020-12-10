#! /usr/bin/python

import sys
import gi

gi.require_version("NM", "1.0")
from gi.repository import NM

connection_name = sys.argv[1]
nm_client = NM.Client.new(None)

con = None
for c in nm_client.get_active_connections():
    if c.get_id() == connection_name:
        con = c
        break

if con != None:
    print(con.get_state_flags())
else:
    print("Error: no %s connection" % connection_name)
