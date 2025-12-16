#!/usr/bin/env python3

import io
import json
import os
import requests
import sys
import xml.etree.ElementTree as ET
import yaml

POLARION_IMPORT_URL = os.environ.get("POLARION_IMPORT_URL")
POLARION_USER = os.environ.get("POLARION_USER")
POLARION_PASSWORD = os.environ.get("POLARION_PASSWORD")

auth = None
if POLARION_USER and POLARION_PASSWORD:
    auth = requests.auth.HTTPBasicAuth(POLARION_USER, POLARION_PASSWORD)

with open("tests.fmf", "r") as t_fmf:
    tests_fmf = yaml.load(t_fmf, Loader=yaml.SafeLoader)

xunit_url = sys.argv[1]
xunit_url_base = sys.argv[1].rsplit("/", 1)[0]

req = requests.get(xunit_url, verify=False)
if req.status_code != 200:
    raise Exception(f"Unable to get xunit.xml: HTTP {req.status_code}")
xunit_str = req.text

req = requests.get(xunit_url_base + "/polarion_metadata.json", verify=False)
if req.status_code != 200:
    raise Exception(f"Unable to get polarion_metadata.json: HTTP {req.status_code}")
polarion_metadata_str = req.text

xunit_xml = ET.fromstring(xunit_str)

for tc in xunit_xml.findall(".//testcase"):
    tc_name = f"/{tc.attrib['name']}"
    tc_link = None
    if tc_name in tests_fmf:
        try:
            tc_link = tests_fmf[tc_name]["link"][0]["implements"]
        except:
            pass
    else:
        for tc_head, tc_content in tests_fmf.items():
            if tc_head.endswith(tc_name):
                try:
                    tc_link = tc_content["link"][0]["implements"]
                    tc_name = tc_head
                except:
                    pass
                break

    if tc_link:
        tc_id = tc_link.split("id=")[-1]
        props = ET.Element("properties")
        props_dic = {
            "polarion-testcase-id": tc_id,
            "polarion-testcase-project-id": tc_id.split("-")[0],
        }
        for p_name, p_val in props_dic.items():
            prop = ET.Element("property", attrib={"name": p_name, "value": p_val})
            props.append(prop)

        tc.append(props)
    tc.attrib = {"name": "/tests" + tc_name}

if xunit_xml.tag == "testsuite":
    testsutes = ET.Element("testsuites")
    testsutes.append(xunit_xml)
    xunit_xml = testsutes

polarion_metadata = json.loads(polarion_metadata_str)
polarion_metadata["polarion-custom-logs"] = xunit_url_base
props = ET.Element("properties")
for p_name, p_val in polarion_metadata.items():
    prop = ET.Element("property", attrib={"name": p_name, "value": p_val})
    props.append(prop)
xunit_xml.append(props)

updated_xml_bytes = ET.tostring(xunit_xml, encoding="utf8")

xml_file = {"file": ("junit.xml", io.BytesIO(updated_xml_bytes), "application/xml")}

if not POLARION_IMPORT_URL:
    print("POLARION_IMPORT_URL not defined in env. exitting...")
    print(updated_xml_bytes)
    sys.exit(1)

requests.post(POLARION_IMPORT_URL, files=xml_file, auth=auth, verify=False)
