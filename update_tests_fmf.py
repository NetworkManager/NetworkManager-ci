#!/usr/bin/python3

import nmci

from nmci.test_nmci import generate_fmf, generate_tests

import yaml

with open("tests.fmf", "r") as t_fmf:
    tests_fmf = yaml.load(t_fmf, Loader=yaml.SafeLoader)

PolarionWorkItem = None

try:
    from pylero.work_item import _WorkItem as PolarionWorkItem
except:
    print("Unable to connect to polarion, not syncing links")

if PolarionWorkItem:
    for testname, entries in tests_fmf.items():
        if not testname.startswith("/"):
            continue
        if "link" not in entries:
            try:
                qr = PolarionWorkItem.query(entries["id"], fields=["work_item_id"])
                polarion_id = qr[0].work_item_id
                url = f"https://polarion.engineering.redhat.com/polarion/#/project/RHELNST/workitem?id={polarion_id}"
                entries["link"] = [{"implements": url}]
                print(f"Linked {testname} to {url}")
            except Exception as e:
                print(e)
        else:
            print(f"{testname} linked already")

generate_fmf(
    generate_tests(nmci.misc.get_mapper_obj(), tests_fmf),
    "fmf_template.j2",
    "tests.fmf",
)
