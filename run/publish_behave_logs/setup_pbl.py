#!/usr/bin/env python3

import dbus
import os
import re
import shutil
from subprocess import run, PIPE, STDOUT
import sys
import xml.etree.ElementTree as ET

inst = [
    "/usr/bin/dnf",
    "-y",
    "install",
    "httpd",
    "python3-libselinux",
    "python3-inotify",
]
inst_el7 = [
    "/usr/bin/yum",
    "-y",
    "install",
    "httpd",
    "libselinux-python",
    "python-inotify",
]
name_short = "pbl"
server_root = "/etc/httpd"
document_root = "/var/www/html"
httpd_conf = "/conf/".join((server_root, "httpd.conf"))
httpd_welcome_file = "/conf.d/".join((server_root, "welcome.conf"))
httpd_welcome_conf = "# disable welcome page"
httpd_listen = "Listen 8080"
httpd_custom_file = "99-publish_behave_logs.conf"
httpd_custom_file_full = "/conf.d/".join((server_root, httpd_custom_file))
firewalld_etc = "/etc/firewalld"
source_dir = os.path.dirname(__file__)


# install packages
with open("/etc/redhat-release", "r") as f:
    rh_release = f.read()

if "Maipo" in rh_release:
    inst = inst_el7

installed = run(inst, encoding="UTF-8")

if installed.returncode != 0:
    raise SystemExit("\n\nPackage installation failed!")

os.makedirs(document_root, exist_ok=True)


# set up apache
try:
    with open(httpd_welcome_file, "r+") as f:
        welcome_orig = f.read()
        f.truncate(0)
        f.seek(0)
        f.write(httpd_welcome_conf)

    with open(httpd_conf, "r+", encoding="UTF-8") as f:
        conf_orig = f.read()
        conf_new = re.sub("(?m)^Listen\s+.*$", httpd_listen, conf_orig)
        f.truncate(0)
        f.seek(0)
        f.write(conf_new)

    shutil.copy("/".join((source_dir, httpd_custom_file)), httpd_custom_file_full)

    # raise exception if configuration test fails
    configtest = run(
        ("apachectl", "configtest"),
        check=True,
        stdout=PIPE,
        stderr=STDOUT,
        encoding="UTF-8",
    )
except:
    with open(httpd_welcome_file, "w") as f:
        f.truncate(0)
        f.write(welcome_orig)

    with open(httpd_conf) as f:
        f.truncate(0)
        f.write(conf_orig)

    os.remove(httpd_custom_file_full)

    raise SystemExit(
        f"apachectl configtest failed! configtest output was:\n\n{configtest.stdout}"
    )
sys.stderr.write("httpd configured\n")


shutil.copy("/".join((source_dir, "publish_behave_logs")), "/usr/local/bin/")
if "Maipo" in rh_release:
    shutil.copy(
        "/".join((source_dir, "publish_behave_logs.service.el7")),
        "/etc/systemd/system/publish_behave_logs.service",
    )
else:
    shutil.copy(
        "/".join((source_dir, "publish_behave_logs.service")), "/etc/systemd/system/"
    )
os.symlink(
    "/etc/systemd/system/publish_behave_logs.service",
    "/etc/systemd/system/multi-user.target.wants/publish_behave_logs.service",
)
os.symlink(
    "/usr/lib/systemd/system/httpd.service",
    "/etc/systemd/system/multi-user.target.wants/httpd.service",
)
sys.stderr.write("service files installed\n")


shutil.copy(
    "/".join([source_dir, "service.xml"]),
    "/".join([firewalld_etc, "services", name_short + ".xml"]),
)
shutil.copy(
    "/".join([source_dir, "policy.xml"]),
    "/".join([firewalld_etc, "policies", name_short + ".xml"]),
)


# load and restart systemd services
have_dbus = False
try:
    dbus_system_bus = dbus.SystemBus()
    have_dbus = True
except dbus.exceptions.DBusException:
    pass


if have_dbus:
    dbus_systemd = dbus_system_bus.get_object(
        "org.freedesktop.systemd1", "/org/freedesktop/systemd1"
    )
    dbus_systemd_manager = dbus.Interface(
        dbus_systemd, "org.freedesktop.systemd1.Manager"
    )

    dbus_systemd_manager.EnableUnitFiles(
        ["httpd.service", "publish_behave_logs.service"], False, True
    )
    dbus_systemd_manager.Reload()

    dbus_systemd_manager.RestartUnit("publish_behave_logs.service", "replace")
    dbus_systemd_manager.RestartUnit("httpd.service", "replace")
    dbus_systemd_manager.ReloadOrTryRestartUnit("firewalld.service", "replace")
    sys.stderr.write("services enabled and started, all should be set now\n")
else:
    msg = [
        "systemd not found on dbus. Please do the following:",
        "- reload units: systemctl daemon-reload",
        "- enable pbl: systemctl enable --now publish_behave_logs.service"
        "- if firewalld is active, restart it: systemctl restart firewalld",
        "",
    ]
    sys.stderr.write("\n".join(msg))
