#!/usr/bin/env python3

import io
import json
import os
import re
import requests
import sys
import xml.etree.ElementTree as ET
import yaml

USAGE = f"""
USAGE:

export POLARION_IMPORT_URL=
export POLARION_USER=
export POLARION_PASSWORD=
python3 {sys.argv[0]} http://jenkins/job/47/artefact/junit.xml scheduleTask=0day

This gets junit.xml and polarion_metadata.json from the url, merges that with data specified on command line and uploads to polarion.
You can override any polarion option set either in polarion_metadata.json or computed in this uploader.
You can omit prefix "polarion-custom" (e.g in scheduleTask), for non-custom fields you have to use full name (e.g polarion-user-id).
If POLARION_ variables are not set in env, resulting XML is printed to stdout.
"""

# Import polarion configuration from env
POLARION_IMPORT_URL = os.environ.get("POLARION_IMPORT_URL")
POLARION_USER = os.environ.get("POLARION_USER")
POLARION_PASSWORD = os.environ.get("POLARION_PASSWORD")

TEST_CYCLES = {
    "CTC1": "Comprehensive Test Cycle 1",
    "CTC2": "Comprehensive Test Cycle 2",
    "CUT": "Components Upgrade Testing",
    "0day": "0 Day Testing",
    "RC": "RC Baseline Test Cycle",
    "RCQualification": "RC Compose Qualification",
}

auth = None
if POLARION_USER and POLARION_PASSWORD:
    auth = requests.auth.HTTPBasicAuth(POLARION_USER, POLARION_PASSWORD)

with open("tests.fmf", "r") as t_fmf:
    tests_fmf = yaml.load(t_fmf, Loader=yaml.SafeLoader)

xunit_url = sys.argv[1]
xunit_url_base = sys.argv[1].rsplit("/", 1)[0]
subcomponent = re.search("NetworkManager-[a-z]+", xunit_url_base)
if subcomponent:
    subcomponent = subcomponent.group(0)
if not subcomponent or "default" in subcomponent or "veth" in subcomponent:
    subcomponent = "NetworkManager"

additional_options = [x.split("=", 1) for x in sys.argv[2:]]
additional_options = dict(
    (k if k.startswith("polarion") else "polarion-custom-" + k, v)
    for k, v in additional_options
)

test_cycle = additional_options.get("polarion-custom-scheduleTask")
if not test_cycle:
    raise Exception(
        f"scheduleTask not specified, you have to set this as argument: e.g. scheduleTask=CTC1\n\n{USAGE}"
    )
if test_cycle not in TEST_CYCLES:
    raise Exception(
        f"scheduleTask (Test Cycle) must be one of {list(TEST_CYCLES.keys())}\n\n{USAGE}"
    )

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
    testsuites = ET.Element("testsuites")
    testsuites.append(xunit_xml)
    xunit_xml = testsuites

polarion_metadata = json.loads(polarion_metadata_str)
polarion_metadata["polarion-custom-logs"] = xunit_url_base

# Use test_cycle in title and description
if test_cycle:
    polarion_metadata["polarion-custom-description"] = (
        polarion_metadata["polarion-custom-description"]
        .replace("general", test_cycle)
        .replace("NetworkManager", subcomponent)
    )
    polarion_metadata["polarion-testrun-title"] = (
        polarion_metadata["polarion-testrun-title"]
        .replace("general", test_cycle)
        .replace("NetworkManager", subcomponent)
    )

# merge additional options and polarion metadata
polarion_metadata = {**polarion_metadata, **additional_options}

polarion_metadata["polarion-custom-component"] = (
    "NetworkManager,NetworkManager-libreswan"
    if "gsm" not in subcomponent
    else "ModemManager,libqmi,libqrtr-glib,libmbim"
)

props = ET.Element("properties")
for p_name, p_val in polarion_metadata.items():
    prop = ET.Element("property", attrib={"name": p_name, "value": p_val})
    props.append(prop)
xunit_xml.append(props)

updated_xml_bytes = ET.tostring(xunit_xml, encoding="utf8")

xml_file = {"file": ("junit.xml", io.BytesIO(updated_xml_bytes), "application/xml")}

if not POLARION_IMPORT_URL:
    sys.stderr.write("POLARION_IMPORT_URL not defined in env. exitting...")
    print(updated_xml_bytes)
    sys.exit(1)

requests.post(POLARION_IMPORT_URL, files=xml_file, auth=auth, verify=False)
