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

from behave import step
from qecore.step_matcher import use_step_matcher
import subprocess
import os
import sys
from time import sleep

NM_CI_PATH = os.path.realpath(__file__).replace("contrib/gui/steps.py", "")
NM_CI_RUNNER_PATH = f"{NM_CI_PATH}contrib/gui/nm-ci-runner.sh"
NM_CI_RUNNER_CMD = f"{NM_CI_RUNNER_PATH} {NM_CI_PATH}"


####################
# helper functions #
####################


def utf_only_open_read(file, mode='r'):
    # Opens file and read it w/o non utf-8 chars
    if sys.version_info.major < 3:
        return open(file, mode).read().decode('utf-8', 'ignore').encode('utf-8')
    else:
        return open(file, mode, encoding='utf-8', errors='ignore').read()


def cmd_output_rc(cmd, **kwargs):
    ret = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        check=False, encoding="utf-8", errors="ignore", **kwargs)
    return (ret.stdout, ret.returncode)


def cmd_output_rc_embed(context, cmd, **kwargs):
    output, rc = cmd_output_rc(cmd, **kwargs)
    context.embed("text/plain", f"{cmd}\nRC: {rc}\nOutput:\n{output}", caption="Command")
    return (output, rc)


def libreswan_teardown(context):
    subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} "
                    "prepare/libreswan.sh teardown &> /tmp/libreswan_teardown.log", shell=True)
    teardown_log = utf_only_open_read("/tmp/libreswan_teardown.log")
    conf = utf_only_open_read("/opt/ipsec/connection.conf")
    context.embed("text/plain", teardown_log, caption="Libreswan Teardown")
    context.embed("text/plain", conf, caption="Libreswan Config")


def gsm_teardown(context):
    subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} prepare/gsm_sim.sh teardown", shell=True)


def openvpn_teardown(context):
    subprocess.call("sudo pkill -TERM openvpn", shell=True)


def wifi_teardown():
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh teardown", shell=True) == 0, \
        "wifi teardown failed !!!"


def hostapd_teardown():
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wired.sh teardown", shell=True) == 0, \
        "8021x teardown failed !!!"


####################
# steps defintions #
####################

@step('Delete connection "{connection}"')
@step('Delete connections "{connection}"')
def remove_connection_id(context, connection):
    out, rc = cmd_output_rc(f"sudo nmcli con del {connection}", shell=True)
    assert rc == 0, f"Deletion of '{connection}' failed.\n{out}"


@step('Delete all connections of type "{type}"')
def remove_connection_type(context, type):
    out, rc = cmd_output_rc(
        "sudo nmcli con delete "
        f"$(sudo nmcli -g type,uuid con show | grep '^{type}:' | sed 's/^{type}://g')",
        shell=True)
    assert rc == 0, f"Deletion of connections of type '{type}' failed.\n{out}"


use_step_matcher("qecore")


@step('Add connection "{connection}" | with options "{options}"')
def add_connection(context, connection, options=None):
    context.execute_steps(f"""
        * Delete connection \"{connection}\" after scenario
        """)
    if options is None:
        options = ""
        for row in context.table:
            options += f"{row[0]} {row[1]} "
    out, rc = cmd_output_rc(f"nmcli con add con-name {connection} {options}", shell=True)
    assert rc == 0, f"Add connection '{connection}' with options {options} failed.\n{out}"


@step('Modify connection "{connection}" | changing options "{options}"')
def modify_connection(context, connection, options=None):
    if options is None:
        options = ""
        for row in context.table:
            options += f"{row[0]} {row[1]} "
    out, rc = cmd_output_rc(f"nmcli con mod {connection} {options}", shell=True)
    assert rc == 0, f"Modify connection '{connection}' changing options {options} failed.\n{out}"


@step('Check connection "{connection}" is | '
      'having options "{options}" with values "{values}" | '
      'in "{seconds}" seconds')
def check_connection(context, connection, options=None, values=None, seconds=2):
    if options is None:
        options, values = [], []
        for row in context.table:
            options.append(row[0])
            values.append(row[1])
    else:
        options, values = options.split(","), values.split(",")
        assert len(options) == len(values), \
            f"Differrent number of options and values.\noptions: {options}\nvalues: {values}"

    # need function, because .index() can raise exception
    def remove_braces(x):
        if "[" in x:
            x = x[:x.index("[")]
        return x

    options_args = ",".join(set([remove_braces(option) for option in options]))
    nmcli_cmd = f"nmcli -t -f {options_args} con show {connection} --show-secrets"

    last_error = None
    for _ in range(int(seconds)):
        try:
            out, rc = cmd_output_rc(nmcli_cmd, shell=True)
            assert rc == 0, f"Connection show with options '{options_args}' failed.\n{out}"

            nmcli_lines = out.split('\n')
            for option, value in zip(options, values):
                if value.endswith("*"):
                    found = False
                    for line in nmcli_lines:
                        if line.startswith(f"{option}:{value[:-1]}"):
                            found = True
                            break
                    assert found, f"'{option}' is not '{value}' in '{connection}':\n{out}"
                else:
                    assert f"{option}:{value}" in nmcli_lines, \
                        f"'{option}' is not '{value}' in '{connection}':\n{out}"
            # break if no assert
            return
        except AssertionError as e:
            last_error = e
            sleep(1)
    raise last_error


CONNECTIONS_LIST_CMD = "nmcli -t -f NAME con show "
ACTIVE_CONNECTIONS_LIST_CMD = f"{CONNECTIONS_LIST_CMD} --active"


@step('"{connection}" is in connections list | in "{seconds}" seconds')
def connection_list(context, connection, seconds=2):
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' not in list of connections:\n{out}"


@step('"{connection}" is not in connections list | in "{seconds}" seconds')
def not_connection_list(context, connection, seconds=2):
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection not in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' is in list of connections:\n{out}"


@step('"{connection}" is in active connections list | in "{seconds}" seconds')
def active_connection_list(context, connection, seconds=2):
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(ACTIVE_CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' not in list of active connections:\n{out}"


@step('"{connection}" is not in active connections list | in "{seconds}" seconds')
def not_active_connection_list(context, connection, seconds=2):
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(ACTIVE_CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection not in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' is in list of active connections:\n{out}"


use_step_matcher("parse")


@step('Delete connection "{connection}" after scenario')
@step('Delete connections "{connection}" after scenario')
def remove_connection_id_after_scenario(context, connection):
    context.sandbox.add_after_scenario_hook(
        subprocess.call, f"sudo nmcli con del {connection}", shell=True)


@step('Delete all connections of type "{type}" after scenario')
def remove_connection_type_after_scenario(context, type):
    context.sandbox.add_after_scenario_hook(
        subprocess.call,
        "sudo nmcli con delete "
        f"$(sudo nmcli -g type,uuid con show | grep '^{type}:' | sed 's/^{type}://g')",
        shell=True)


@step('Restore "{device}" with connection "{connection}"')
def restore_device(context, device, connection):
    check_cmd = "nmcli -t -f NAME,DEVICE con show"
    check_cmd_out, _ = cmd_output_rc(check_cmd, shell=True)
    assert f"{connection}:{device}" in check_cmd_out, \
        f"'{connection}:{device}' not found in nmcli output:\n{check_cmd_out}"

    cfile = f"/etc/sysconfig/network-scripts/ifcfg-{connection}"
    if not os.path.isfile(cfile):
        cfile = f"/etc/NetworkManager/system-connections/{connection}.nmconnection"
    assert os.path.isfile(cfile), f"unable to find configuration file for '{connection}'"
    assert subprocess.call(f"sudo cp '{cfile}' '/tmp/backup_{connection}'", shell=True) == 0, \
        f"unable to backup file '{cfile}'"

    def restore(connection, cfile):
        subprocess.call(f"sudo mv '/tmp/backup_{connection}' '{cfile}'", shell=True)
        subprocess.call("sudo nmcli con reload", shell=True)
        assert subprocess.call(f"sudo nmcli con up '{connection}'", shell=True) == 0, \
            f"Activation of '{connection}' failed"

    context.sandbox.add_after_scenario_hook(restore, connection, cfile)


@step('Run NetworkManager-ci envsetup')
def nm_env(context):
    tags = ','.join(context.scenario.tags)
    ret = subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} envsetup '{tags}' &> /tmp/nm_envsetup_log.txt", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/nm_envsetup_log.txt"),
                  "NM envsetup")
    assert ret == 0, "NetworkManager-ci envsetup failed !!!"
    nm_install_pkgs(context)


@step('Install packages')
def nm_install_pkgs(context):
    ret = subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} install &> /tmp/nm_dep_pkg_install_log.txt", shell=True)
    context.embed("text/plain", utf_only_open_read("/tmp/nm_dep_pkg_install_log.txt"),
                  "NM Deps Install")
    assert ret == 0, "Unable to install required packages !!!"


use_step_matcher("qecore")


@step('Prepare libreswan | mode "{mode}"')
def prepare_libreswan(context, mode="aggressive"):
    context.execute_steps("""* Delete all connections of type "vpn" after scenario""")
    cmd = f"sudo MODE={mode} bash {NM_CI_RUNNER_CMD} " \
          f"prepare/libreswan.sh &> /tmp/libreswan_setup.log"
    ret = subprocess.call(cmd, shell=True)
    setup_log = utf_only_open_read("/tmp/libreswan_setup.log")
    context.embed("text/plain", setup_log, "Libreswan Setup")
    assert ret == 0, "libreswan setup failed !!!"


@step('Prepare simulated gsm | named "{modem}"')
def prepare_gsm(context, modem="modemu"):
    context.sandbox.add_after_scenario_hook(
        lambda c: c.embed("text/plain", utf_only_open_read("/tmp/gsm_sim.log"), "GSM_SIM"),
        context)
    context.execute_steps("""* Delete all connections of type "gsm" after scenario""")
    assert subprocess.call(f"sudo bash {NM_CI_RUNNER_CMD} "
                           f"prepare/gsm_sim.sh {modem} &> /tmp/gsm_sim.log",
                           shell=True) == 0, "gsm_sim setup failed !!!"
    for i in range(20):
        out = subprocess.check_output(["mmcli", "-L"], stderr=subprocess.STDOUT).decode("utf-8")
        if "No modems were found" not in out:
            return
        sleep(1)
    assert False, "No modems were found using `mmcli -L' in 20 seconds"


@step('Prepare openvpn | version "{version}" | in "{path}"')
def prepare_openvpn(context, version="ip46", path="/tmp/openvpn-"):
    context.sandbox.add_after_scenario_hook(
        lambda c: c.embed("text/plain", utf_only_open_read("/tmp/openvpn.log"), "OPENVPN"),
        context)
    context.execute_steps("""* Delete all connections of type "vpn" after scenario""")
    assert subprocess.call(
        f"sudo rsync -r {NM_CI_PATH}/contrib/openvpn/ /tmp/", shell=True) == 0, \
        "Unable to copy openvpn keys, please check directories in NM-ci repo"

    out, rc = cmd_output_rc(
        f"sudo cp -f {path}{version}.conf /tmp/openvpn-running.conf", shell=True)
    assert rc == 0, f"Unable to copy '{path}{version}.conf':\n{out}"

    # are we running already? try to reload
    if subprocess.call("sudo pkill -HUP openvpn", shell=True) == 0:
        return

    server = subprocess.Popen(
        "sudo openvpn /tmp/openvpn-running.conf &> /tmp/openvpn.log", shell=True)
    running = False
    try:
        server.wait(6)
    except subprocess.TimeoutExpired:
        running = True
    assert running, f"openvpn server did not start, exitcode: {server.returncode}"


@step('Prepare Wi-Fi | with certificates from "{certs_dir}"')
def prepare_wifi(context, certs_dir="tmp/8021x/certs"):
    context.execute_steps("""* Delete all connections of type "802-11-wireless" after scenario""")
    context.sandbox.add_after_scenario_hook(
        lambda c: c.embed("text/plain", utf_only_open_read("/tmp/hostapd_wireless.log"), "WI-FI"),
        context)
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh {certs_dir} namespace"
        f"&> /tmp/hostapd_wireless.log", shell=True) == 0, f"wifi setup failed !!!"


@step('Prepare 8021x | with certificates from "{certs_dir}"')
def prepare_8021x(context, certs_dir="tmp/8021x/certs"):
    context.sandbox.add_after_scenario_hook(
        lambda c: c.embed("text/plain", utf_only_open_read("/tmp/hostapd_wired.log"), "8021X"),
        context)
    assert subprocess.call(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wired.sh {certs_dir}"
        f"&> /tmp/hostapd_wired.log", shell=True) == 0, f"8021x setup failed !!!"


use_step_matcher("parse")


@step('Teardown Wi-Fi')
def teardown_wifi(context):
    wifi_teardown()


@step('Teardown Wi-Fi after scenario')
@step('Teardown Wi-Fi after test')
def teardown_wifi_hook(context):
    context.sandbox.add_after_scenario_hook(wifi_teardown)


@step('Teardown libreswan')
def teardown_libreswan(context):
    libreswan_teardown(context)


@step('Teardown libreswan after scenario')
@step('Teardown libreswan after test')
def teardown_libreswan_hook(context):
    context.sandbox.add_after_scenario_hook(libreswan_teardown, context)


@step('Teardown openvpn')
def teardown_openvpn(context):
    openvpn_teardown(context)


@step('Teardown openvpn after scenario')
@step('Teardown openvpn after test')
def teardown_openvpn_hook(context):
    context.sandbox.add_after_scenario_hook(openvpn_teardown, context)


@step('Teardown gsm')
def teardown_gsm(context):
    gsm_teardown(context)


@step('Teardown gsm after scenario')
@step('Teardown gsm after test')
def teardown_gsm_hook(context):
    context.sandbox.add_after_scenario_hook(gsm_teardown, context)


@step('Teardown 8021x')
def teardown_8021x(context):
    hostapd_teardown()


@step('Teardown 8021x after scenario')
@step('Teardown 8021x after test')
def teardown_8021x_hook(context):
    context.sandbox.add_after_scenario_hook(hostapd_teardown)
