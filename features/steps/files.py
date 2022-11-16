import os
import time
import re
import configparser
from behave import step  # pylint: disable=no-name-in-module

import commands
import nmci


@step('Append lines to file "{name}"')
@step('Append "{line}" to file "{name}"')
def append_to_file(context, name, line=None):
    if line is None:
        line = context.text if context.text is not None else " "
    cmd = 'sudo echo "%s" >> %s' % (line, name)
    context.command_code(cmd)


@step('Append "{line}" to ifcfg file "{name}"')
def append_to_ifcfg(context, line, name):
    cmd = 'sudo echo "%s" >> /etc/sysconfig/network-scripts/ifcfg-%s' % (line, name)
    context.command_code(cmd)
    nmci.cleanup.cleanup_add_connection(name)


@step(u'Check file "{file1}" is contained in file "{file2}"')
def check_file_is_contained(context, file1, file2):
    with open(file1) as f1_lines:
        with open(file2) as f2_lines:
            diff = set(f1_lines).difference(f2_lines)
    assert not len(diff), f"Following lines in '{file1}' are not in '{file2}':\n" + "".join(diff)


@step(u'Check file "{file1}" is identical to file "{file2}"')
def check_file_is_identical(context, file1, file2):
    import filecmp

    if filecmp.cmp(file1, file2):
        return

    nmci.embed.embed_data(file1, nmci.util.file_get_content_simple(file1))
    nmci.embed.embed_data(file2, nmci.util.file_get_content_simple(file2))
    assert False, f"Files '{file1}' and '{file2}' differ"


@step(u'ifcfg-"{con_name}" file does not exist')
def ifcfg_doesnt_exist(context, con_name):
    cat = context.pexpect_spawn('cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name)
    assert cat.expect('No such file') == 0, 'Ifcfg-%s exists!' % con_name


@step('"{filename}" is file')
@step('"{filename}" is file in "{seconds}" seconds')
def is_file(context, filename, seconds=5):
    for _ in range(int(seconds)):
        if os.path.isfile(filename):
            return
        time.sleep(1)
    ls = context.command_output('ls -la "%s"' % filename)
    assert os.path.isfile(filename), '"%s" is not a file:\n%s' % (filename, ls)


@step('Path "{path}" does not exist')
def no_path(context, path):
    if os.path.exists(path):
        time.sleep(3)
        assert not os.path.exists(path), '"%s" is valid path' % path


@step('"{filename}" is symlink')
@step('"{filename}" is symlink with destination "{destination}"')
def is_symlink(context, filename, destination=None):
    if "<noted_value>" in filename:
        filename = filename.replace("<noted_value>", context.noted['noted-value'])
    assert os.path.islink(filename), '"%s" is not a symlink' % filename
    realpath = os.path.realpath(filename)
    if destination is None:
        return True
    assert realpath == destination, 'symlink "%s" has destination "%s" instead of "%s"' % (filename, realpath, destination)


@step('Remove file "{filename}" if exists')
def remove_file(context, filename):
    if os.path.isfile(filename):
        os.remove(filename)


@step('Remove symlink "{filename}" if exists')
def remove_symlink(context, filename):
    if os.path.islink(filename):
        os.remove(filename)


@step('Create symlink {source} with destination {destination}')
def create_symlink(context, source, destination):
    cmd = 'sudo ln -s "%s" "%s"' % (destination, source)
    context.command_code(cmd)


@step(u'Check ifcfg-name file created with noted connection name')
def check_ifcfg_exists(context):
    command = 'cat /etc/sysconfig/network-scripts/ifcfg-%s' % context.noted['noted-value']
    pattern = 'NAME=%s' % context.noted['noted-value']
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step(u'Check ifcfg-name file created for connection "{con_name}"')
def check_ifcfg_exists_given_device(context, con_name):
    context.additional_sleep(1)
    command = 'cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name
    pattern = 'NAME=%s' % con_name
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step(u'Write dispatcher "{path}" file with params "{params}"')
@step(u'Write dispatcher "{path}" file with params')
@step(u'Write dispatcher "{path}" file')
def write_dispatcher_file(context, path, params=None):
    if not path.startswith("/"):
        path = "/etc/NetworkManager/dispatcher.d/%s" % path
    dir_name = os.path.dirname(path)
    if not os.path.exists(dir_name):
        os.makedirs(dir_name)
    if not params and bool(context.text):
        params = context.text

    nmci.cleanup.cleanup_file(
        "/tmp/dispatcher.txt",
        priority=nmci.cleanup.Cleanup.PRIORITY_FILE + 1,
    )
    nmci.util.file_set_content("/tmp/dispatcher.txt", "")

    nmci.cleanup.cleanup_file(path)

    with open(path, "w") as f:
        f.write("#!/bin/bash\n")
        if params:
            f.write(params)
        f.write("\necho $2 >> /tmp/dispatcher.txt\n")
    nmci.process.exec.chmod("+x", path)
    time.sleep(8)


@step('Reset /etc/hosts')
def reset_hosts(context):
    cmd = "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"
    context.command_code(cmd)
    cmd = "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts"
    context.command_code(cmd)


@step(u'Check solicitation for "{dev}" in "{file}"')
def check_solicitation(context, dev, file):
    #file = '/tmp/solicitation.txt'
    #dev = 'enp0s25'
    cmd = "ip a s %s |grep ff:ff|awk {'print $2'}" %dev
    mac = ""
    for line in context.command_output(cmd).split('\n'):
        if line.find(':') != -1:
            mac = line.strip()

    mac_last_4bits = mac.split(':')[-2]+mac.split(':')[-1]
    dump = open(file, 'r')

    assert mac_last_4bits not in dump.readlines(), "Route solicitation from %s was found in tshark dump" % mac


@step(u'Check keyfile "{file}" has options')
def check_keyfile(context, file):
    cp = configparser.ConfigParser()
    assert file in cp.read(file), "File '%s' is not valid config file" % file
    for line in context.text.split("\n"):
        opt, value = line.split("=")
        opt = opt.split(".")
        value = value.strip()
        cfg_val = cp.get(*opt)
        assert cfg_val == value, "'%s' not found in file '%s'" % (line, file)


@step(u'Check ifcfg-file "{file}" has options')
def check_ifcfg(context, file):
    assert os.path.isfile(file), "File '%s' does not exist" % file
    with open(file) as f:
        cfg = [opt.strip() for opt in f.readlines()]
    for line in context.text.split("\n"):
        assert line in cfg, "'%s' not found in file '%s':\n%s" % (line, file, "\n".join(cfg))


@step(u'Create ifcfg-file "{file}"')
@step(u'Create keyfile "{file}"')
def create_network_profile_file(context, file):
    with open(file, "w") as f:
        f.write(context.text)
    assert nmci.process.run_code(["chmod", "600", file]) == 0, f"Unable to set permissions on '{file}'"
    nmci.nmutil.reload_NM_connections()

    for line in context.text.split("\n"):
        if re.match(r'(id|name)=', line):
            name = line.split('=')[1]
            if name:
                nmci.cleanup.cleanup_add_connection(name)
        elif re.match(r'(DEVICE|interface-name)=', line):
            iface = line.split('=')[1]
            if iface:
                nmci.cleanup.cleanup_add_iface(iface)
