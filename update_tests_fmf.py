#!/usr/bin/python3

import os

import nmci

from nmci.test_nmci import (
    generate_fmf,
    generate_stories,
    generate_stories_fmf,
    generate_tests,
)

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
                url = f"https://polarion.example.org/polarion/#/project/RHELNST/workitem?id={polarion_id}"
                entries["link"] = [{"implements": url}]
                print(f"Linked {testname} to {url}")
            except Exception as e:
                print(e)
        else:
            print(f"{testname} linked already")

mapper = generate_tests(nmci.misc.get_mapper_obj(), tests_fmf)

generate_fmf(
    mapper,
    "fmf_template.j2",
    "tests.fmf",
)

# Generate stories.fmf for requirements
stories_fmf = {}
if os.path.isfile("stories.fmf"):
    with open("stories.fmf", "r") as s_fmf:
        stories_fmf = yaml.load(s_fmf, Loader=yaml.SafeLoader) or {}

stories = generate_stories(mapper, stories_fmf)
generate_stories_fmf(stories)
