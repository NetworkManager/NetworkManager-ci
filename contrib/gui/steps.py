#!/usr/bin/env python3
# behave steps for GUI projects
#
# How to configure GUI project:
#
# add this repo as submodule in root of behve project (the same level as features dir)
# and then `git mv NetworkManager-ci NMci`
#
# in steps.py use:
#        from NMci.contrib.gui.steps import *
#
# in environment.py ensure that the following lines are in after_scenario:
#        hook = getattr(context, "after_scenario_hook", None)
#        if hook: hook()

from behave import step
import subprocess
import os
import sys
from time import sleep

NM_CI_PATH = os.path.realpath(__file__).replace("contrib/gui/steps.py", "")
NM_CI_RUNNER_PATH = f"{NM_CI_PATH}contrib/gui/nm-ci-runner.sh"
NM_CI_RUNNER_CMD = f"{NM_CI_RUNNER_PATH} {NM_CI_PATH}"

#######################
# after_scenario hook #
#######################

# USAGE: in step definition call:
# add_after_scenario_hook(context, callback_function, [arguments to callback])


class Hook:
    hooks = []

    def __call__(self):
        for fun, args, kwargs in self.hooks:
            # use try block for each hook, so that crash of one hook
            # will not have an influence of the other hooks
            try:
                fun(*args, **kwargs)
            except Exception as e:
                print("Exception in after_scenario hook:")
                print(e.traceback)
        # clean up hoooks, in case of multiple scenarios
        self.hooks = []

    def append_hook(self, fun, *args, **kwargs):
        self.hooks.append((fun, args, kwargs))


def add_after_scenario_hook(context, fun, *args, **kwargs):
    hook = getattr(context, "after_scenario_hook", Hook())
    hook.append_hook(fun, *args, **kwargs)
    context.after_scenario_hook = hook


####################
# helper functions #
####################


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        return open(file, mode).read().decode('utf-8', 'ignore').encode('utf-8')
    else:
        return open(file, mode, encoding='utf-8', errors='ignore').read()


def libreswan_teardown(context):
    with open("/tmp/libreswan.log", "a") as f:
        f.write("\n\n### TEARDOWN ###\n\n")
    subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} "
                    "prepare/libreswan.sh teardown &>> /tmp/libreswan.log", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/libreswan.log"), "LIBRESWAN")


def gsm_teardown(context):
    subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} prepare/gsm_sim.sh teardown", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/gsm_sim.log"), "GSM_SIM")


def openvpn_teardown(context):
    subprocess.call("sudo nmcli connection delete con_vpn", shell=True)
    subprocess.call("sudo kill -9 $(pidof openvpn)", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/openvpn.log"), "OPENVPN")


####################
# steps defintions #
####################


@step('Restore "{device}" with connection "{connection}"')
def restore_device(context, device, connection):
    add_after_scenario_hook(
        context, subprocess.call, f"sudo nmcli connection up id {connection} "
        f"|| sudo nmcli con add con-name {connection} type ethernet ifname {device}", shell=True)


@step('Run NetworkManager-ci envsetup')
def nm_env(context):
    tags = ','.join(context.scenario.tags)
    ret = subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} envsetup '{tags}' &> /tmp/nm_envsetup_log.txt", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/nm_envsetup_log.txt"),
                  "NM envsetup")
    assert ret == 0, "NetworkManager-ci envsetup failed !!!"
    ret = subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} install &> /tmp/nm_dep_pkg_install_log.txt", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/nm_dep_pkg_install_log.txt"),
                  "NM Deps Install")
    assert ret == 0, "Unable to install required packages !!!"


@step('Prepare libreswan')
@step('Prepare libreswan mode "{mode}" DH group "{dh_group}" phase1 algorithm "{phase1_al}" ike "{ike}"')
def prepare_libreswan(context, mode="aggressive", dh_group="5", phase1_al="aes", ike="ikev1"):
    add_after_scenario_hook(context, libreswan_teardown, context)
    subprocess.call("sudo systemctl restart NetworkManager", shell=True)

    cmd = f"sudo bash {NM_CI_RUNNER_CMD} prepare/libreswan.sh " \
          f"{mode} {dh_group} {phase1_al} {ike} &>> /tmp/libreswan.log"
    with open('/tmp/libreswan.log', 'w') as f:
        f.write(cmd + '\n\n\n')
    assert subprocess.call(cmd, shell=True) == 0, "libreswan setup failed !!!"
    add_after_scenario_hook(context, subprocess.call,
                            "sudo nmcli con delete con_libreswan", shell=True)


@step('Prepare simulated gsm')
@step('Prepare simulated gsm named "{modem}"')
def prepare_gsm(context, modem="modemu"):
    add_after_scenario_hook(context, gsm_teardown, context)
    add_after_scenario_hook(context, subprocess.call,
                            "sudo nmcli con delete "
                            "$(nmcli -g type,uuid con show | grep gsm: | sed 's/^gsm://g')",
                            shell=True)
    assert subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} "
                           f"prepare/gsm_sim.sh {modem} &> /tmp/gsm_sim.log",
                           shell=True) == 0, "gsm_sim setup failed !!!"
    for i in range(20):
        out = subprocess.check_output(["mmcli", "-L"], stderr=subprocess.STDOUT).decode("utf-8")
        if "No modems were found" not in out:
            return
        sleep(1)
    assert False, "No modems were found using `mmcli -L' in 20 seconds"


@step('Prepare openvpn')
@step('Prepare openvpn version "{version}"')
def prepare_openvpn(context, version="ip46"):
    add_after_scenario_hook(context, openvpn_teardown, context)
    assert subprocess.call(
        f"sudo cp -r {NM_CI_PATH}/tmp/openvpn/sample-keys /tmp/", shell=True) == 0, \
        "Unable to copy openvpn keys, please check directories in NM-ci repo"
    subprocess.call("sudo systemctl restart NetworkManager", shell=True)
    server = subprocess.Popen(
        f"sudo openvpn /tmp/openvpn-{version}.conf &> /tmp/openvpn.log", shell=True)
    running = False
    try:
        server.wait(6)
    except subprocess.TimeoutExpired:
        running = True
    assert running, f"openvpn server did not start, exitcode: {server.returncode}"


@step('Prepare Wi-Fi')
@step('Prepare Wi-Fi with certificates from "{certs_dir}"')
def prepare_wifi(context, certs_dir="tmp/8021x/certs"):
    add_after_scenario_hook(
        context, subprocess.call, "sudo nmcli con delete $(sudo nmcli -g uuid,type c show "
        "| grep 802-11-wireless | grep -o '^[^:]*' )", shell=True)
    add_after_scenario_hook(
        context, lambda c: c.embed("text/plain", utf_only_open_read("/tmp/hostapd_wireless.log"),
                                   "Wireless"),
        context)
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh {certs_dir} namespace"
        f"&> /tmp/hostapd_wireless.log", shell=True) == 0, f"wifi setup failed !!!"


@step('Teardown Wi-Fi')
def teardown_wifi(context):
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh teardown", shell=True) == 0, \
        "wifi teardown failed !!!"
    context.scenario.skip("Skipping Wi-Fi teardown test")
