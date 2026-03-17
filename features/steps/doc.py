# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import os

import yaml
from behave import step

import nmci

_data_file = os.path.join(
    os.path.dirname(__file__), "..", "..", "contrib", "doc", "doc_chapters.yaml"
)
with open(_data_file) as f:
    _data = yaml.safe_load(f)

chapters = _data["chapters"]
guides = _data["guides"]
rh_versions = _data["rh_versions"]

_BASE_URL = "https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux"


@step('Doc: "{name}"')
@step('Doc "{guide}": "{name}"')
def doc_step(context, name, guide="Configuring and managing networking"):
    if name not in chapters:
        if "bond" in context.scenario.tags and f"Bonding: {name}" in chapters:
            name = f"Bonding: {name}"
        elif "team" in context.scenario.tags and f"Teaming: {name}" in chapters:
            name = f"Teaming: {name}"
    assert name in chapters, "Chapter not found"
    assert guide in guides, "Guide not found"
    links = [
        (
            f"{_BASE_URL}/{rh_ver}/html-single/{guides[guide]}/index#{chapters[name]}",
            f"RHEL {rh_ver}",
        )
        for rh_ver in rh_versions
    ]
    nmci.embed.embed_link("Links", links)
