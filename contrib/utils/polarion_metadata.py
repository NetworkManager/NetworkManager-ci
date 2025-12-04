#!/usr/bin/env python3

import json
import re
import subprocess

nvra = (
    subprocess.run(
        "rpm -q NetworkManager", stdout=subprocess.PIPE, check=False, shell=True
    )
    .stdout.decode("utf-8", errors="ignore")
    .strip()
)

nvr = nvra.rsplit(".", 1)[0]
arch = nvra.rsplit(".", 1)[-1]
arch_p = arch.replace("_", "")

distro = "Unknown"
plan = ""
compose = (
    subprocess.run(
        ". prepare/envsetup/utils.sh; get_rhel_compose",
        stdout=subprocess.PIPE,
        check=False,
        shell=True,
    )
    .stdout.decode("utf-8", errors="ignore")
    .strip()
)
compose_split = re.split(r"[.-]", compose)
if len(compose_split) > 2:
    a, b, c = compose_split[:3]
    distro = f"{a}-{b}.{c}"
    plan = f"{b}_{c}_ga"

hostname = (
    subprocess.run("hostname", stdout=subprocess.PIPE, check=False, shell=True)
    .stdout.decode("utf-8", errors="ignore")
    .strip()
)

mode = "package"

if subprocess.call("grep -q ostre /proc/cmdline", shell=True) == 0:
    mode = "image"

props_dic = {
    "polarion-custom-arch": arch_p,
    "polarion-custom-assignee": "fpokryvk",
    "polarion-custom-build": nvr,
    "polarion-custom-composeid": compose,
    "polarion-custom-description": f"NetworkManager {distro} general {arch}",
    "polarion-custom-plannedin": plan,
    "polarion-custom-platform": distro,
    "polarion-custom-poolteam": "rhel-sst-network-management",
    "polarion-custom-hostname": hostname,
    "polarion-project-id": "RHELNST",
    "polarion-user-id": "fpokryvk",
    "polarion-testrun-title": f"NetworkManager {distro} general {arch}",
    "polarion-project-span-ids": "RHELNST,RHELNST",
    "polarion-custom-deploymentMode": mode,
}

print(json.dumps(props_dic))
