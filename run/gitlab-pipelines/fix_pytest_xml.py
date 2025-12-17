#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import sys

with open(sys.argv[1]) as xf:
    xunit_str = xf.read()

xunit_xml = ET.fromstring(xunit_str)


for failure in xunit_xml.findall(".//failure"):
    msg = failure.attrib.get("message")
    if msg:
        failure.text = "Message:\n" + msg + "\n\nDebug output:\n" + failure.text

xunit_str = ET.tostring(xunit_xml)

with open(sys.argv[1], "wb") as xf:
    xf.write(xunit_str)
