#! /usr/bin/python

import sys
import gi

gi.require_version("NM", "1.0")
from gi.repository import NM

prop = sys.argv[1]
nm_client = NM.Client.new(None)

print(nm_client.get_property(prop))
