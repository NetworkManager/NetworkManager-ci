#!/usr/bin/env python3l
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
# !!! WARNING !!! do not use context.cext instead of context.embed here,
#                 as it is not available in GUI projects!

from behave import step  # pylint: disable=no-name-in-module
from qecore.step_matcher import use_step_matcher
import subprocess
import os
import sys
import re
from time import sleep

# NetworkManager-ci is cloned to NMci subdir in GUI projects
sys.path.append("./NMci/")

import nmci.util

NM_CI_PATH = os.path.realpath(__file__).replace("contrib/gui/steps.py", "")
NM_CI_RUNNER_PATH = f"{NM_CI_PATH}contrib/gui/nm-ci-runner.sh"
NM_CI_RUNNER_CMD = f"{NM_CI_RUNNER_PATH} {NM_CI_PATH}"


####################
# helper functions #
####################


def init_command_embeds(context):
    def get_hook(old_hook, before=True):
        def hook_runner(*args, **kwargs) -> None:
            if old_hook is not None:
                old_hook(*args, **kwargs)
            if before:
                if nmci.cext.context._step_level == 0:
                    nmci.cext.context.gui_commands_embed = None
                nmci.cext.context._step_level += 1
            else:
                nmci.cext.context._step_level -= 1
            if nmci.cext.context._step_level < 0:
                nmci.cext.context._step_level = 0

        return hook_runner

    if not getattr(context, "gui_commands_hook_set", False):
        nmci.cext.context = context
        context._step_level = 1
        context.gui_commands_embed = None
        context.gui_commands_hook_set = True
        hooks = context._runner.hooks
        hooks["before_step"] = get_hook(hooks.get("before_step", None), before=True)
        hooks["after_step"] = get_hook(hooks.get("after_step", None), before=False)
        context._runner.hooks = hooks


def embed_command(cmd, rc, out, err):
    data_formatted = f"{'-'*30}\n`{cmd}` returned {rc}.\n"
    if out:
        data_formatted += f"STDOUT:\n{out}\n\n"
    if err:
        data_formatted += f"STDERR:\n{err}\n\n"
    # Make consistent 1-empty-line space between commands
    data_formatted = data_formatted.rstrip("\n") + "\n\n"
    context = nmci.cext.context
    if context is None:
        return
    if context.gui_commands_embed is None:
        context.gui_commands_embed = context.embed("text", data_formatted, "Commands")
    else:
        embed = context.gui_commands_embed
        data_formatted = embed.data + data_formatted
        embed.set_data(embed.mime_type, data_formatted, embed.caption)


def utf_only_open_read(file, mode="r"):
    # This file is used by out-of-tree components. This
    # function is only here for backward compatibility with
    # those. Don't use!
    #
    # Argument "mode" is unused.
    return nmci.util.file_get_content_simple(file)


def cmd_output_rc(cmd, **kwargs):
    ret = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        encoding="utf-8",
        errors="ignore",
        **kwargs,
    )
    embed_command(cmd, ret.returncode, ret.stdout, "")
    return (ret.stdout, ret.returncode)


def arch():
    a, _ = cmd_output_rc("arch")
    return a.strip("\n")


def check_star_expr(needle, haystack):
    if needle.startswith("*") and needle.endswith("*"):
        assert (
            needle[1:-1] in haystack
        ), f"searched '{needle}' is no infix of '{haystack}'"
    elif needle.endswith("*"):
        assert haystack.startswith(
            needle[:-1]
        ), f"searched '{needle}' is no prefix of '{haystack}'"
    elif needle.startswith("*"):
        assert haystack.endswith(
            needle[1:]
        ), f"searched '{needle}' is no suffix of '{haystack}'"
    else:
        assert haystack == needle, f"searched '{needle}' is not '{haystack}'"


def remove_braces(option):
    if "[" in option:
        option = option[: option.index("[")]
    return option


def nmcli_out_to_dic(out):
    nmcli_lines = out.strip().split("\n")
    if nmcli_lines == [""]:
        return {}
    nmcli_dic = {}
    for line in nmcli_lines:
        opt, val = line.split(":", 1)
        nmcli_dic[opt] = val
        opt_no_braces = remove_braces(opt)
        if opt_no_braces != opt:
            val_orig = nmcli_dic.get(opt_no_braces, "")
            if val_orig:
                nmcli_dic[opt_no_braces] = val_orig + "," + val
            else:
                nmcli_dic[opt_no_braces] = val
    return nmcli_dic


MAC_RE = re.compile("([0-9A-F]{2}:){5}([0-9A-F]){2}")


def get_ip_l_mac(ifname):
    out, rc = cmd_output_rc(f"ip link show dev {ifname}", shell=True)
    assert rc == 0, f"Unable to get mac for '{ifname}': {out}"
    mac = out.strip().split("\n")[1].strip().split(" ")[1].upper()
    assert MAC_RE.match(mac) is not None, f"Inavlid MAC for {ifname}: {mac}\n{out}"
    return mac


def get_mac(ifname):
    out, rc = cmd_output_rc(f"ethtool -P {ifname}", shell=True)
    assert rc == 0, f"Unable to get mac for '{ifname}': {out}"
    mac = out.strip().split(" ")[-1].upper()
    if MAC_RE.match(mac) is None:
        mac = get_ip_l_mac(ifname)
    return mac


def netdev_replace(context, s):
    if not s:
        return s
    if "<netdev" not in s:
        return s
    netdevs = getattr(context, "netdevs", [])
    for i in range(len(netdevs)):
        s = s.replace(f"<netdev{i+1}>", netdevs[i])
        if f"<netdev{i+1}:mac>" in s:
            s = s.replace(f"<netdev{i+1}:mac>", get_mac(netdevs[i]))
    assert "<netdev" not in s, f"Some netdev not found: {s}"
    return s


def nmcli_eval(context, s, strip_prefix=False):
    if not s:
        return s
    if "<nmcli" not in s:
        return s
    nmcli_re = re.compile("<nmcli[^>]*>")
    for command in nmcli_re.findall(s):
        cmd_list = command.strip("<>").split(":")
        assert len(cmd_list) == 4, (
            f"Unable to parse nmcli command {command}, "
            "must be <nmcli:(dev|con):name:attribute>"
        )
        _, obj, name, attr = cmd_list
        nmcli_cmd = (
            f'nmcli -t -f {remove_braces(attr)} {obj} show "{name}" --show-secrets'
        )
        out, rc = cmd_output_rc(nmcli_cmd, shell=True)
        assert rc == 0, f"command '{nmcli_cmd}' failed:\n{out}"
        nmcli_dic = nmcli_out_to_dic(out)
        value = nmcli_dic[attr]
        if strip_prefix:
            value = value.rsplit("/", 1)[0]
        s = s.replace(command, value)
    return s


def libreswan_teardown(context):
    cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} "
        "prepare/libreswan.sh teardown &> /tmp/libreswan_teardown.log",
        shell=True,
    )
    teardown_log = nmci.util.file_get_content_simple("/tmp/libreswan_teardown.log")
    conf = nmci.util.file_get_content_simple("/opt/ipsec/connection.conf")
    context.embed("text/plain", teardown_log, caption="Libreswan Teardown")
    context.embed("text/plain", conf, caption="Libreswan Config")


def gsm_teardown():
    cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/gsm_sim.sh teardown", shell=True
    )


def openvpn_teardown():
    cmd_output_rc("sudo pkill -TERM openvpn", shell=True)


def wifi_teardown():
    _p = subprocess.PIPE
    wifi_status = subprocess.run(
        "sudo nmcli radio wifi", check=False, shell=True, stdout=_p, stderr=_p
    ).stdout.decode("utf-8")
    if not wifi_status or "enabled" not in wifi_status:
        print(f"Enabling wifi, as it was found: {wifi_status}!")
        cmd_output_rc("sudo nmcli radio wifi on", shell=True)
        sleep(1)
    assert (
        cmd_output_rc(
            f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh teardown",
            shell=True,
        )[1]
        == 0
    ), "wifi teardown failed !!!"


def hostapd_teardown():
    assert (
        cmd_output_rc(
            f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wired.sh teardown",
            shell=True,
        )[1]
        == 0
    ), "8021x teardown failed !!!"


####################
# steps defintions #
####################


@step('Delete connection "{connection}"')
@step('Delete connections "{connection}"')
def remove_connection_id(context, connection):
    init_command_embeds(context)
    out, rc = cmd_output_rc(f"sudo nmcli con del {connection}", shell=True)
    assert rc == 0, f"Deletion of '{connection}' failed.\n{out}"


@step('Delete all connections of type "{type}"')
def remove_connection_type(context, type):
    init_command_embeds(context)
    out, rc = cmd_output_rc(
        "sudo nmcli con delete "
        f"$(sudo nmcli -g type,uuid con show | grep '^{type}:' | sed 's/^{type}://g')",
        shell=True,
    )
    assert rc == 0, f"Deletion of connections of type '{type}' failed.\n{out}"


use_step_matcher("qecore")


@step('Add connection "{connection}" | with options "{options}"')
def add_connection(context, connection, options=None):
    init_command_embeds(context)
    context.execute_steps(
        f"""
        * Delete connection \"{connection}\" after scenario
        """
    )
    if options is None:
        options = ""
        for row in context.table:
            options += f"{row[0]} {row[1]} "
    options = netdev_replace(context, options)
    out, rc = cmd_output_rc(
        f"nmcli con add con-name {connection} {options}", shell=True
    )
    assert (
        rc == 0
    ), f"Add connection '{connection}' with options {options} failed.\n{out}"


@step('Modify connection "{connection}" | changing options "{options}"')
def modify_connection(context, connection, options=None):
    init_command_embeds(context)
    if options is None:
        options = ""
        for row in context.table:
            options += f"{row[0]} {row[1]} "
    options = netdev_replace(context, options)
    out, rc = cmd_output_rc(f"nmcli con mod {connection} {options}", shell=True)
    assert (
        rc == 0
    ), f"Modify connection '{connection}' changing options {options} failed.\n{out}"


@step(
    'Check connection "{connection}" is | '
    'having options "{options}" with values "{values}" | '
    'in "{seconds}" seconds'
)
def check_connection(context, connection, options=None, values=None, seconds=2):
    init_command_embeds(context)
    if options is None:
        options, values = [], []
        for row in context.table:
            options.append(row[0])
            values.append(netdev_replace(context, row[1]))
    else:
        values = netdev_replace(context, values)
        options, values = options.split(","), values.split(",")
        assert len(options) == len(
            values
        ), f"Differrent number of options and values.\noptions: {options}\nvalues: {values}"

    options_args = ",".join(set([remove_braces(option) for option in options]))
    nmcli_cmd = f"nmcli -t -f {options_args} con show {connection} --show-secrets"

    last_error = None
    for _ in range(int(seconds)):
        try:
            out, rc = cmd_output_rc(nmcli_cmd, shell=True)
            assert (
                rc == 0
            ), f"Connection show with options '{options_args}' failed.\n{out}"
            nmcli_dic = nmcli_out_to_dic(out)

            for option, value in zip(options, values):
                val_nmcli = nmcli_dic.get(option, None)
                if val_nmcli is None:
                    assert not value, f"searched '{value}' in unset option '{option}'"
                else:
                    check_star_expr(value, val_nmcli)

            # if no assert every option was found
            return
        except AssertionError as e:
            last_error = e
            sleep(1)
    context.embed("text/plain", out, "nmcli STDOUT")
    raise last_error


@step('Connection "{connection}" is activated | in "{seconds:d}" seconds')
def connection_activated(context, connection, seconds=10):
    init_command_embeds(context)
    context.execute_steps(
        f'* Check connection "{connection}" is having options "GENERAL.STATE" '
        f'with values "activated" in "{seconds}" seconds'
    )


@step('Connection "{connection}" is not activated | for full "{seconds:d}" seconds')
def connection_not_activated(context, connection, seconds=10):
    init_command_embeds(context)
    nmcli_cmd = f"nmcli -t -f GENERAL.STATE con show {connection}"
    for i in range(int(seconds)):
        out, rc = cmd_output_rc(nmcli_cmd, shell=True)
        assert rc == 0, f"Connection show GENRAL.STATE failed.\n{out}"
        nmcli_dic = nmcli_out_to_dic(out)
        val = nmcli_dic.get("GENERAL.STATE", "")
        assert (
            val != "activated"
        ), f"Connection '{connection}' activated after {i} seconds"
        sleep(1)


CONNECTIONS_LIST_CMD = "nmcli -t -f NAME con show "
ACTIVE_CONNECTIONS_LIST_CMD = f"{CONNECTIONS_LIST_CMD} --active"
DEVICE_STATE_LIST_CMD = "nmcli -t -f STATE,DEVICE dev"


@step('"{connection}" is in connections list | in "{seconds}" seconds')
def connection_list(context, connection, seconds=2):
    init_command_embeds(context)
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' not in list of connections:\n{out}"


@step('"{connection}" is not in connections list | in "{seconds}" seconds')
def not_connection_list(context, connection, seconds=2):
    init_command_embeds(context)
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection not in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' is in list of connections:\n{out}"


@step('"{connection}" is in active connections list | in "{seconds}" seconds')
def active_connection_list(context, connection, seconds=2):
    init_command_embeds(context)
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(ACTIVE_CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' not in list of active connections:\n{out}"


@step('"{connection}" is not in active connections list | in "{seconds}" seconds')
def not_active_connection_list(context, connection, seconds=2):
    init_command_embeds(context)
    for _ in range(int(seconds)):
        out, rc = cmd_output_rc(ACTIVE_CONNECTIONS_LIST_CMD, shell=True)
        if rc == 0 and connection not in out.split("\n"):
            return
        sleep(1)
    assert False, f"'{connection}' is in list of active connections:\n{out}"


@step('"{device}" device is "{state}" | in "{seconds}" seconds')
def device_state(context, device, state, seconds=10):
    init_command_embeds(context)
    device = netdev_replace(context, device)
    outs = ""
    for i in range(int(seconds)):
        out, rc = cmd_output_rc(DEVICE_STATE_LIST_CMD, shell=True)
        if rc == 0 and f"{state}:{device}" in out.split("\n"):
            return
        outs += f"{DEVICE_STATE_LIST_CMD} #{i}\n{out}\n"
        sleep(1)
    context.embed("text/plain", outs, caption="Device States")
    assert False, f"'{device}' is not '{state}':\n{out}"


use_step_matcher("parse")


@step('Delete connection "{connection}" after scenario')
@step('Delete connections "{connection}" after scenario')
def remove_connection_id_after_scenario(context, connection):
    init_command_embeds(context)
    context.sandbox.add_after_scenario_hook(
        cmd_output_rc, f"sudo nmcli con del {connection}", shell=True
    )


@step('Delete all connections of type "{type}" after scenario')
def remove_connection_type_after_scenario(context, type):
    init_command_embeds(context)
    context.sandbox.add_after_scenario_hook(
        cmd_output_rc,
        "sudo nmcli con delete "
        f"$(sudo nmcli -g type,uuid con show | grep '^{type}:' | sed 's/^{type}://g')",
        shell=True,
    )


@step('Restore "{device}" with connection "{connection}"')
def restore_device(context, device, connection):
    init_command_embeds(context)
    check_cmd = "nmcli -t -f NAME,DEVICE,FILENAME con show"
    check_cmd_out, _ = cmd_output_rc(check_cmd, shell=True)
    con_lines = check_cmd_out.strip("\n").split("\n")
    cfiles = [
        x.split(":", 2)[2] for x in con_lines if x.startswith(f"{connection}:{device}:")
    ]
    assert len(cfiles) == 1, f"Unable to find unique connection, found {cfiles}"
    cfile = cfiles[0]
    assert os.path.isfile(
        cfile
    ), f"unable to find configuration file for '{connection}' on {device}:\n{check_cmd_out}"
    assert (
        cmd_output_rc(f"sudo cp -a '{cfile}' '/tmp/backup_{connection}'", shell=True)[1]
        == 0
    ), f"unable to backup file '{cfile}'"

    def restore(connection, cfile):
        cmd_output_rc(f"sudo mv '/tmp/backup_{connection}' '{cfile}'", shell=True)
        cmd_output_rc("sudo nmcli con reload", shell=True)
        assert (
            cmd_output_rc(f"sudo nmcli con up '{connection}'", shell=True)[1] == 0
        ), f"Activation of '{connection}' failed"

    context.sandbox.add_after_scenario_hook(restore, connection, cfile)


@step("Run NetworkManager-ci envsetup")
def nm_env(context):
    init_command_embeds(context)
    tags = ",".join(context.scenario.tags)
    _, ret = cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} envsetup '{tags}' &> /tmp/nm_envsetup_log.txt",
        shell=True,
    )
    context.embed(
        "text/plain",
        nmci.util.file_get_content_simple("/tmp/nm_envsetup_log.txt"),
        "NM envsetup",
    )
    if not os.path.isfile("/tmp/nm_envsetup_log.first.txt"):
        cmd_output_rc(
            "cp /tmp/nm_envsetup_log.txt /tmp/nm_envsetup_log.first.txt", shell=True
        )
    else:
        context.embed(
            "text/plain",
            nmci.util.file_get_content_simple("/tmp/nm_envsetup_log.first.txt"),
            "First NM envsetup",
        )
    assert ret == 0, "NetworkManager-ci envsetup failed !!!"
    context.execute_steps("* Install packages")
    cmd_output_rc("sudo chown -R test:test ./NMci", shell=True)
    nmci.cext.setup(context)
    nmci.embed.set_number_embeds(False)
    context.nm_pid = nmci.nmutil.nm_pid()
    nmci.util.dump_status("before scenario", "NM Status")
    context.sandbox.add_after_scenario_hook(
        nmci.util.dump_status, "after scenario", "NM Status"
    )
    context.sandbox.add_after_scenario_hook(nmci.embed.process_embeds)


@step("Install packages")
def nm_install_pkgs(context):
    init_command_embeds(context)
    _, ret = cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} install &> /tmp/nm_dep_pkg_install_log.txt",
        shell=True,
    )
    context.embed(
        "text/plain",
        nmci.util.file_get_content_simple("/tmp/nm_dep_pkg_install_log.txt"),
        "NM Deps Install",
    )
    assert ret == 0, "Unable to install required packages !!!"


use_step_matcher("qecore")


@step('Prepare libreswan | mode "{mode}"')
def prepare_libreswan(context, mode="aggressive"):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reson="Libreswan not available on 's390x'")
        return
    context.execute_steps("""* Delete all connections of type "vpn" after scenario""")
    cmd = (
        f"sudo MODE={mode} bash {NM_CI_RUNNER_CMD} "
        f"prepare/libreswan.sh &> /tmp/libreswan_setup.log"
    )
    _, ret = cmd_output_rc(cmd, shell=True)
    setup_log = nmci.util.file_get_content_simple("/tmp/libreswan_setup.log")
    context.embed("text/plain", setup_log, "Libreswan Setup")
    assert ret == 0, "libreswan setup failed !!!"


@step('Prepare simulated gsm | named "{modem}"')
def prepare_gsm(context, modem="modemu"):
    init_command_embeds(context)
    context.sandbox.add_after_scenario_hook(
        lambda context: context.embed(
            "text/plain",
            nmci.util.file_get_content_simple("/tmp/gsm_sim.log"),
            "GSM_SIM",
        ),
        context,
    )
    context.execute_steps("""* Delete all connections of type "gsm" after scenario""")
    cmd_output_rc(
        "sudo semodule --list | grep ModemManager ||"
        "sudo semodule -i NMci/contrib/selinux-policy/ModemManager.pp",
        shell=True,
    )
    # Without redirect to `cat`, bahave output gets broken in GUI components
    subprocess.Popen(
        f"sudo bash {NM_CI_RUNNER_CMD} "
        f"prepare/gsm_sim.sh {modem} | cat &> /tmp/gsm_sim.log",
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    modem_found = False
    for i in range(20):
        out = cmd_output_rc("mmcli -L", shell=True)[0]
        if "No modems were found" not in out:
            modem_found = True
            break
        sleep(1)
    assert modem_found, "No modems were found using `mmcli -L' in 20 seconds"
    modem_found = False
    for i in range(20):
        out = cmd_output_rc("nmcli -g device device", shell=True)[0].split("\n")
        if f"{modem}_p1" in out:
            modem_found = True
            break
        sleep(1)
    assert (
        modem_found
    ), f"Modem '{modem}' was not found using `nmcli -g device device' in 20 seconds"


@step('Prepare openvpn | version "{version}" | in "{path}"')
def prepare_openvpn(context, version="ip46", path="/tmp/openvpn-"):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reson="OpenVPN not available on 's390x'")
        return
    context.sandbox.add_after_scenario_hook(
        lambda context: context.embed(
            "text/plain",
            nmci.util.file_get_content_simple("/tmp/openvpn.log"),
            "OPENVPN",
        ),
        context,
    )
    context.execute_steps("""* Delete all connections of type "vpn" after scenario""")
    _, rc = cmd_output_rc(
        f"sudo rsync -r {NM_CI_PATH}/contrib/openvpn/ /tmp/", shell=True
    )
    assert (
        rc == 0
    ), "Unable to copy openvpn keys, please check directories in NM-ci repo"

    _, rc = cmd_output_rc("sudo chcon -R -t home_cert_t /tmp/sample-keys/", shell=True)
    assert (
        rc == 0
    ), "Unable to fix selinux labels of openvpn keys, please check directories in NM-ci repo"

    out, rc = cmd_output_rc(
        f"sudo cp -f {path}{version}.conf /tmp/openvpn-running.conf", shell=True
    )
    assert rc == 0, f"Unable to copy '{path}{version}.conf':\n{out}"

    # are we running already? try to reload
    if cmd_output_rc("sudo pkill -HUP openvpn", shell=True)[1] == 0:
        return

    # Without redirect to `cat`, bahave output gets broken in GUI components
    server = subprocess.Popen(
        "sudo openvpn /tmp/openvpn-running.conf | cat &> /tmp/openvpn.log", shell=True
    )
    running = False
    try:
        server.wait(6)
    except subprocess.TimeoutExpired:
        running = True
    assert running, f"openvpn server did not start, exitcode: {server.returncode}"


@step(
    'Prepare Wi-Fi | with certificates from "{certs_dir}" | with crypto "{crypto}" | with "{ap_num}" APs'
)
def prepare_wifi(context, certs_dir="contrib/8021x/certs", crypto="default", ap_num=""):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"Wi-Fi not available on '{arch()}'")
        return
    context.execute_steps(
        """* Delete all connections of type "802-11-wireless" after scenario"""
    )
    context.sandbox.add_after_scenario_hook(
        lambda context: context.embed(
            "text/plain",
            nmci.util.file_get_content_simple("/tmp/hostapd_wireless.log"),
            "WI-FI",
        ),
        context,
    )
    if crypto == "legacy":
        cmd_output_rc(
            "sudo sed '-i.bak' s/'^##'/''/g /etc/pki/tls/openssl.cnf", shell=True
        )
        context.sandbox.add_after_scenario_hook(
            cmd_output_rc,
            "sudo mv -f /etc/pki/tls/openssl.cnf.bak /etc/pki/tls/openssl.cnf",
            shell=True,
        )
    for _ in range(2):
        try:
            assert (
                cmd_output_rc(
                    f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wireless.sh {certs_dir} namespace {crypto}_crypto many_ap={ap_num}"
                    "&> /tmp/hostapd_wireless.log",
                    shell=True,
                )[1]
                == 0
            ), "wifi setup failed !!!"

            # wait for wifi rescan
            rescan_cmd = "sudo nmcli -g ssid dev wifi list"
            for i in range(20):
                _cmd = rescan_cmd
                if i % 5 == 0:
                    _cmd += " --rescan yes"
                wifi_list = cmd_output_rc(_cmd, shell=True)[0].split("\n")
                if "open" in wifi_list:
                    return
                sleep(2)
            assert False, f"'open' network not visible {wifi_list}"
        except AssertionError:
            print("Setup failed for the first time, retrying in 10s...")
            wifi_teardown()
            sleep(10)
    assert False, "Unable to prepare wi-fi."


@step('Prepare 8021x | with certificates from "{certs_dir}" | with crypto "{crypto}"')
def prepare_8021x(context, certs_dir="contrib/8021x/certs", crypto=None):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"802.1x not available on '{arch()}'")
        return
    context.sandbox.add_after_scenario_hook(
        lambda context: context.embed(
            "text/plain",
            nmci.util.file_get_content_simple("/tmp/hostapd_wired.log"),
            "8021X",
        ),
        context,
    )
    assert (
        cmd_output_rc(
            f"sudo bash {NM_CI_RUNNER_CMD} prepare/hostapd_wired.sh {certs_dir}"
            "&> /tmp/hostapd_wired.log",
            shell=True,
        )[1]
        == 0
    ), "8021x setup failed !!!"

    if crypto == "legacy":
        cmd_output_rc(
            "sudo sed '-i.bak' s/'^##'/''/g /etc/pki/tls/openssl.cnf", shell=True
        )
        cmd_output_rc("sudo systemctl restart wpa_supplicant", shell=True)
        cmd_output_rc("sudo systemctl restart nm-hostapd", shell=True)

        context.sandbox.add_after_scenario_hook(
            cmd_output_rc,
            "sudo mv -f /etc/pki/tls/openssl.cnf.bak /etc/pki/tls/openssl.cnf",
            shell=True,
        )
        context.sandbox.add_after_scenario_hook(
            cmd_output_rc, "sudo systemctl restart wpa_supplicant", shell=True
        )
        context.sandbox.add_after_scenario_hook(
            cmd_output_rc, "sudo systemctl restart nm-hostapd", shell=True
        )
    elif crypto is not None:
        assert False, f"Unknown crypto type: '{crypto}', allowed value: 'legacy'"


@step("Prepare wireguard")
def prepare_wireguard(context):
    init_command_embeds(context)
    output, rc = cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/wireguard.sh", shell=True
    )
    assert rc == 0, f"wireguard setup failed!!!\n{output}"


@step('Prepare netdevsim | num "{num}"')
def prepare_netdevsim(context, num="1"):
    init_command_embeds(context)
    _, rc = cmd_output_rc(
        f"sudo bash {NM_CI_RUNNER_CMD} prepare/netdevsim.sh setup {num}"
        "&> /tmp/netdevsim.log",
        shell=True,
    )
    context.embed(
        "text/plain",
        nmci.util.file_get_content_simple("/tmp/netdevsim.log"),
        "Netdevsim Setup",
    )
    assert rc == 0, "netdevsim setup failed !!!"
    ifnames, rc = cmd_output_rc(
        "sudo ls /sys/bus/netdevsim/devices/netdevsim0/net/",
        shell=True,
    )
    ifnames = ifnames.strip().split()
    assert len(ifnames) == int(
        num
    ), f"created {len(ifnames)} instead of {num} devices: {ifnames}"
    context.netdevs = ifnames


use_step_matcher("parse")


@step("Teardown Wi-Fi")
def teardown_wifi(context):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"Wi-Fi not available on '{arch()}'")
        return
    wifi_teardown()


@step("Teardown Wi-Fi after scenario")
@step("Teardown Wi-Fi after test")
def teardown_wifi_hook(context):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"Wi-Fi not available on '{arch()}'")
        return
    context.sandbox.add_after_scenario_hook(wifi_teardown)


@step("Teardown libreswan")
def teardown_libreswan(context):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reason="Libreswan not available on 's390x'")
        return
    libreswan_teardown(context)


@step("Teardown libreswan after scenario")
@step("Teardown libreswan after test")
def teardown_libreswan_hook(context):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reason="Libreswan not available on 's390x'")
        return
    context.sandbox.add_after_scenario_hook(libreswan_teardown, context)


@step("Teardown openvpn")
def teardown_openvpn(context):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reason="OpenVPN not available on 's390x'")
        return
    openvpn_teardown()


@step("Teardown openvpn after scenario")
@step("Teardown openvpn after test")
def teardown_openvpn_hook(context):
    init_command_embeds(context)
    if arch() == "s390x":
        context.scenario.skip(reason="OpenVPN not available on 's390x'")
        return
    context.sandbox.add_after_scenario_hook(openvpn_teardown)


@step("Teardown gsm")
def teardown_gsm(context):
    init_command_embeds(context)
    gsm_teardown()


@step("Teardown gsm after scenario")
@step("Teardown gsm after test")
def teardown_gsm_hook(context):
    init_command_embeds(context)
    context.sandbox.add_after_scenario_hook(gsm_teardown)


@step("Teardown 8021x")
def teardown_8021x(context):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"Wi-Fi not available on '{arch()}'")
        return
    hostapd_teardown()


@step("Teardown 8021x after scenario")
@step("Teardown 8021x after test")
def teardown_8021x_hook(context):
    init_command_embeds(context)
    if arch() != "x86_64":
        context.scenario.skip(reason=f"Wi-Fi not available on '{arch()}'")
        return
    context.sandbox.add_after_scenario_hook(hostapd_teardown)


use_step_matcher("qecore")


@step("Teardown netdevsim")
def teardown_netdevsim(context):
    init_command_embeds(context)
    assert (
        cmd_output_rc("echo 0 | sudo tee /sys/bus/netdevsim/del_device", shell=True)[1]
        == 0
    ), "unable to delete netdevsim device"
    context.netdevs = []


@step("Teardown netdevsim after scenario")
@step("Teardown netdevsim after test")
def teardown_netdevsim_hook(context):
    init_command_embeds(context)
    context.sandbox.add_after_scenario_hook(teardown_netdevsim, context)


use_step_matcher("parse")
