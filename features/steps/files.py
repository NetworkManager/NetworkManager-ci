# pylint: disable=function-redefined,no-name-in-module
# type: ignore[no-redef]
import os
import time
import re
import configparser
from behave import step
import shutil

import commands
import nmci


@step('Write file "{path}" with content')
def fill_file_with_content(context, path):
    nmci.cleanup.add_file(path)
    nmci.util.file_set_content(path, context.text)


@step("Create NM config file with content")
@step('Create NM config file with content and cleanup priority "{priority}"')
@step('Create NM config file "{filename}" with content')
@step('Create NM config file "{filename}" with content and "{operation}" NM')
def create_config_file(
    context, filename="96-nmci-custom.conf", priority="PRIORITY_FILE", operation=None
):
    if not filename.startswith("/"):
        path = os.path.join("/etc/NetworkManager/conf.d", filename)
    else:
        path = filename
    prio = getattr(nmci.cleanup.Cleanup, priority, None)
    if prio is None:
        prio = int(priority)

    do_op = operation
    if operation is None:
        do_op = lambda: True
        # if operation is None, restart is done in Scenario, so register NM restart cleanup
        nmci.cleanup.add_NM_service(priority=prio)

    content = context.text
    content = nmci.misc.str_replace_dict(content, getattr(context, "noted", {}))

    nmci.nmutil.add_NM_config(content, path, cleanup_priority=prio, op=do_op)


@step('Cleanup NM config file "{cfg}"')
def cleanup_NM_cfg(context, cfg):
    nmci.cleanup.add_NM_config(cfg)


@step('Create udev rule "{fname}" with content')
def create_udev_file(context, fname):
    if not fname.startswith("/"):
        path = os.path.join("/etc/udev/rules.d", fname)
    else:
        path = fname

    nmci.cleanup.add_udev_rule(path)

    content = context.text
    content = nmci.misc.str_replace_dict(content, getattr(context, "noted", {}))

    nmci.util.file_set_content(path, content)
    nmci.util.update_udevadm()


@step('Append lines to file "{name}"')
@step('Append "{line}" to file "{name}"')
def append_to_file(context, name, line=None):
    if line is None:
        line = context.text if context.text is not None else " "
    old = nmci.util.file_get_content_simple(name) if os.path.isfile(name) else ""
    nmci.util.file_set_content(name, old + line + "\n")


@step('Replace "{substring}" with "{replacement}" in file "{path}"')
def replace_substring(context, substring, replacement, path):
    content = nmci.util.file_get_content_simple(path)
    content = re.sub(substring, replacement, content)
    nmci.util.file_set_content(path, content)


@step('Append "{line}" to ifcfg file "{name}"')
def append_to_ifcfg(context, line, name):
    path = f"/etc/sysconfig/network-scripts/ifcfg-{name}"
    old = nmci.util.file_get_content_simple(path) if os.path.isfile(path) else ""
    nmci.util.file_set_content(path, old + line + "\n")
    nmci.cleanup.add_iface(name)
    nmci.cleanup.add_connection(name)


@step('Check file "{file1}" is contained in file "{file2}"')
def check_file_is_contained(context, file1, file2):
    f1_content = nmci.util.file_get_content_simple(file1).splitlines(keepends=True)
    f2_content = nmci.util.file_get_content_simple(file2).splitlines(keepends=True)
    diff = set(f1_content).difference(f2_content)
    assert not len(
        diff
    ), f"Following lines in '{file1}' are not in '{file2}':\n" + "".join(diff)


@step('Check file "{file1}" is identical to file "{file2}"')
def check_file_is_identical(context, file1, file2):
    import filecmp

    if filecmp.cmp(file1, file2):
        return

    nmci.embed.embed_data(file1, nmci.util.file_get_content_simple(file1))
    nmci.embed.embed_data(file2, nmci.util.file_get_content_simple(file2))
    assert False, f"Files '{file1}' and '{file2}' differ"


@step('ifcfg-"{con_name}" file does not exist')
def ifcfg_doesnt_exist(context, con_name):
    cat = context.pexpect_spawn(f"cat /etc/sysconfig/network-scripts/ifcfg-{con_name}")
    assert cat.expect("No such file") == 0, f"Ifcfg-{con_name} exists!"


@step('"{filename}" is file')
@step('"{filename}" is file in "{seconds}" seconds')
def is_file(context, filename, seconds=5):
    for _ in range(int(seconds)):
        if os.path.isfile(filename):
            return
        time.sleep(1)
    ls = nmci.process.run_stdout(f'ls -la "{filename}"', shell=True, ignore_stderr=True)
    assert os.path.isfile(filename), f'"{filename}" is not a file:\n{ls}'


@step('Path "{path}" does not exist')
def no_path(context, path):
    if os.path.exists(path):
        time.sleep(3)
        assert not os.path.exists(path), f'"{path}" is valid path'


@step('"{filename}" is symlink')
@step('"{filename}" is symlink with destination "{destination}"')
def is_symlink(context, filename, destination=None):
    if "<noted_value>" in filename:
        filename = filename.replace("<noted_value>", context.noted["noted-value"])
    assert os.path.islink(filename), f'"{filename}" is not a symlink'
    realpath = os.path.realpath(filename)
    if destination is None:
        return True
    assert (
        realpath == destination
    ), f'symlink "{filename}" has destination "{realpath}" instead of "{destination}"'


@step('Remove file "{filename}" if exists')
def remove_file(context, filename):
    if os.path.isfile(filename):
        os.remove(filename)


@step('Remove symlink "{filename}" if exists')
def remove_symlink(context, filename):
    if os.path.islink(filename):
        os.remove(filename)


@step("Create symlink {source} with destination {destination}")
def create_symlink(context, source, destination):
    os.symlink(destination, source)


@step("Check ifcfg-name file created with noted connection name")
def check_ifcfg_exists(context):
    command = f"cat /etc/sysconfig/network-scripts/ifcfg-{context.noted['noted-value']}"
    pattern = f"NAME={context.noted['noted-value']}"
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step('Check ifcfg-name file created for connection "{con_name}"')
def check_ifcfg_exists_given_device(context, con_name):
    context.additional_sleep(1)
    command = f"cat /etc/sysconfig/network-scripts/ifcfg-{con_name}"
    pattern = f"NAME={con_name}"
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step('Write dispatcher "{path}" file with params "{params}"')
@step('Write dispatcher "{path}" file with params')
@step('Write dispatcher "{path}" file copied from "{source}"')
@step('Write dispatcher "{path}" file')
def write_dispatcher_file(context, path, params=None, source=None):
    if not path.startswith("/"):
        path = f"/etc/NetworkManager/dispatcher.d/{path}"
    image_mode = False
    if path.startswith("/usr/"):
        p_cmdline = nmci.util.file_get_content_simple("/proc/cmdline")
        image_mode = "ostree" in p_cmdline
        if image_mode:
            nmci.process.run_stdout("mount -o remount,rw lazy /usr")
    dir_name = os.path.dirname(path)
    if not os.path.exists(dir_name):
        os.makedirs(dir_name)
    if not params and bool(context.text):
        params = context.text

    nmci.cleanup.add_file(
        "/tmp/dispatcher.txt",
        priority=nmci.Cleanup.PRIORITY_FILE + 1,
    )
    if image_mode:
        nmci.cleanup.add_callback(
            lambda: nmci.process.run("mount -o remount,rw lazy /usr"),
            f"image-mode-unlock",
            priority=nmci.cleanup.Cleanup.PRIORITY_FILE - 1,
        )
        nmci.cleanup.add_callback(
            lambda: nmci.process.run("mount -o remount,ro lazy /usr"),
            f"image-mode-lock",
            priority=nmci.cleanup.Cleanup.PRIORITY_FILE + 1,
        )
    nmci.cleanup.add_file(path)

    if source is None:
        nmci.util.file_set_content("/tmp/dispatcher.txt", "")
        content = "#!/bin/bash\n"
        if params:
            content += params
        content += "\necho $2 >> /tmp/dispatcher.txt\n"
        nmci.util.file_set_content(path, content)
    else:
        shutil.copyfile(f"{nmci.util.BASE_DIR}/contrib/dispatcher/{source}", path)

    nmci.process.exec.chmod("+x", path)
    if image_mode:
        nmci.process.run_stdout("mount -o remount,ro lazy /usr")


@step("Reset /etc/hosts")
def reset_hosts(context):
    nmci.util.file_set_content(
        "/etc/hosts",
        "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4\n"
        "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6\n",
    )


@step('Check solicitation for "{dev}" in "{file}"')
def check_solicitation(context, dev, file):
    # file = '/tmp/solicitation.txt'
    # dev = 'enp0s25'
    cmd = f"ip a s {dev} |grep ff:ff|awk {{'print $2'}}"
    mac = ""
    for line in nmci.process.run_stdout(cmd, shell=True, ignore_stderr=True).split(
        "\n"
    ):
        if line.find(":") != -1:
            mac = line.strip()

    mac_last_4bits = mac.split(":")[-2] + mac.split(":")[-1]
    dump_content = nmci.util.file_get_content_simple(file).splitlines(keepends=True)

    assert (
        mac_last_4bits not in dump_content
    ), f"Route solicitation from {mac} was found in tshark dump"


@step('Check keyfile "{file}" has options')
def check_keyfile(context, file):
    cp = configparser.ConfigParser()
    f_content = nmci.util.file_get_content_simple(file)
    assert file in cp.read(
        file
    ), f"File '{file}' is not valid config file:\n{f_content}"
    for line in context.text.split("\n"):
        opt, value = line.split("=")
        opt = opt.split(".")
        value = value.strip()
        cfg_val = cp.get(*opt)
        assert cfg_val == value, f"'{line}' not found in file '{file}'\n{f_content}"


@step("Update the noted keyfile")
@step('Update the keyfile in the noted value "{note}"')
@step('Update the keyfile "{file}"')
def step_update_keyfile(context, file=None, note="noted-value"):
    """
    Note: no backup/restore mechanism is part of this step, use only for files
    that will be deleted after scenario to avoid affecting environment in the
    scenarios following the one where this step is used
    """
    if file is None:
        file = context.noted[note]
    assert context.text, "text has to be non-empty!"
    nmci.misc.keyfile_update(file, context.text)


@step('Check ifcfg-file "{file}" has options')
def check_ifcfg(context, file):
    assert os.path.isfile(file), f"File '{file}' does not exist"
    cfg = [opt.strip() for opt in nmci.util.file_get_content_simple(file).splitlines()]
    for line in context.text.split("\n"):
        cfg_str = "\n".join(cfg)
        assert line in cfg, f"'{line}' not found in file '{file}':\n{cfg_str}"


@step('Create ifcfg-file "{file}"')
@step('Create keyfile "{file}"')
def create_network_profile_file(context, file):
    nmci.cleanup.add_NM_service(operation="restart")
    nmci.cleanup.add_file(
        file,
        priority=nmci.Cleanup.PRIORITY_FILE + 1,
    )

    content = context.text
    if os.path.isfile(content):
        nmci.embed.embed_file_if_exists(file, content)
        content = nmci.util.file_get_content_simple(content)

    nmci.util.file_set_content(file, content)
    assert (
        nmci.process.run_code(["chmod", "600", file]) == 0
    ), f"Unable to set permissions on '{file}'"

    # Restore selinux context - crash in imagemode
    nmci.process.run_stdout(f"restorecon {file}")

    for line in content.split("\n"):
        if re.match(r"(id|name)=", line, re.IGNORECASE):
            name = line.split("=")[1]
            if name:
                nmci.cleanup.add_connection(name)
        elif re.match(r"(DEVICE|interface-name)=", line, re.IGNORECASE):
            iface = line.split("=")[1]
            if iface:
                nmci.cleanup.add_iface(iface)
