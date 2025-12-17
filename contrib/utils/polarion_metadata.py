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

sestatus = (
    subprocess.run(
        "sestatus",
        stdout=subprocess.PIPE,
        check=False,
    )
    .stdout.decode("utf-8", errors="ignore")
    .strip()
    .split("\n")
)

selinux_state = "disabled"
selinux_mode = "permissive"

for line in sestatus:
    if line.startswith("SELinux status:"):
        selinux_state = line.split(" ")[-1]
    if line.startswith("Current mode:"):
        selinux_mode = line.split(" ")[-1]

deployment_mode = "package"

if subprocess.call("grep -q ostre /proc/cmdline", shell=True) == 0:
    deployment_mode = "image"

props_dic = {
    "polarion-custom-arch": arch_p,
    "polarion-custom-assignee": "fpokryvk",
    "polarion-custom-build": nvr,
    "polarion-custom-composeid": compose,
    "polarion-custom-description": f"NetworkManager {distro} general {arch}",
    "polarion-custom-plannedin": plan,
    "polarion-custom-platform": distro,
    "polarion-custom-poolteam": "rhel-net-mgmt",
    "polarion-custom-hostname": hostname,
    "polarion-custom-selinux_state": selinux_state,
    "polarion-custom-selinux_mode": selinux_mode,
    "polarion-custom-selinux_policy": "targeted",  # default
    "polarion-custom-deploymentMode": deployment_mode,
    "polarion-project-id": "RHELNST",
    "polarion-user-id": "fpokryvk",
    "polarion-testrun-title": f"NetworkManager {distro} general {arch}",
    "polarion-project-span-ids": "RHELNST,RHELNST",
}

print(json.dumps(props_dic))
