#!/usr/bin/python3

"""
Sync FMF stories (requirements) to Polarion as Requirement work items.

Usage:
    cd ~/NetworkManager-ci
    python3 contrib/utils/sync_requirements_to_polarion.py

Requires:
    - ~/.pylero with correct credentials
    - pylero installed
"""

import os
import sys

import yaml

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

import nmci
from nmci.test_nmci import generate_stories, generate_stories_fmf, generate_tests

POLARION_PROJECT = "RHELNST"
POLARION_URL = "https://polarion.example.org/polarion/#/project"

# Load tests.fmf and generate mapper
with open("tests.fmf", "r") as t_fmf:
    tests_fmf = yaml.load(t_fmf, Loader=yaml.SafeLoader)

mapper = generate_tests(nmci.misc.get_mapper_obj(), tests_fmf)

# Load existing stories.fmf
stories_fmf = {}
if os.path.isfile("stories.fmf"):
    with open("stories.fmf", "r") as s_fmf:
        stories_fmf = yaml.load(s_fmf, Loader=yaml.SafeLoader) or {}

stories = generate_stories(mapper, stories_fmf)

# Try to connect to Polarion
PolarionWorkItem = None

try:
    from pylero.work_item import _WorkItem as PolarionWorkItem
except Exception:
    print("Unable to connect to Polarion, not syncing requirement links")

if PolarionWorkItem:
    for story in stories:
        if story["polarion_link"]:
            print(f"/{story['name']} linked already")
            continue
        try:
            # Query by story UUID
            qr = PolarionWorkItem.query(str(story["id"]), fields=["work_item_id"])
            if qr:
                polarion_id = qr[0].work_item_id
            else:
                # Create new Requirement work item
                from pylero.work_item import Requirement

                req = Requirement.create(
                    POLARION_PROJECT,
                    f"NetworkManager {story['summary']}",
                    story["description"] or "",
                    severity="should_have",
                )
                req.tc_id = str(story["id"])
                req.update()
                polarion_id = req.work_item_id
                print(
                    f"Created Polarion requirement {polarion_id} for /{story['name']}"
                )

            url = f"{POLARION_URL}/{POLARION_PROJECT}/workitem?id={polarion_id}"
            story["polarion_link"] = url
            print(f"Linked /{story['name']} to {url}")
        except Exception as e:
            print(f"Error syncing /{story['name']}: {e}")

# Regenerate stories.fmf with updated Polarion links
generate_stories_fmf(stories)
