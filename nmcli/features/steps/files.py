import os
import pexpect
import re
import subprocess
import time
from behave import step

import commands
import nmci_step


@step('Append "{line}" to file "{name}"')
def append_to_file(context, line, name):
    cmd = 'sudo echo "%s" >> %s' % (line, name)
    nmci_step.command_code(context, cmd)


@step('Append "{line}" to ifcfg file "{name}"')
def append_to_ifcfg(context, line, name):
    cmd = 'sudo echo "%s" >> /etc/sysconfig/network-scripts/ifcfg-%s' % (line, name)
    nmci_step.command_code(context, cmd)


@step(u'Check file "{file1}" is contained in file "{file2}"')
def check_file_is_contained(context, file1, file2):
    with open(file1) as f1_lines:
        with open(file2) as f2_lines:
            diff = set(f1_lines).difference(f2_lines)
    assert not bool(diff)


@step(u'Check file "{file1}" is identical to file "{file2}"')
def check_file_is_identical(context, file1, file2):
    import filecmp
    assert filecmp.cmp(file1, file2)


@step(u'ifcfg-"{con_name}" file does not exist')
def ifcfg_doesnt_exist(context, con_name):
    cat = pexpect.spawn('cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name, logfile=context.log, encoding='utf-8')
    assert cat.expect('No such file') == 0, 'Ifcfg-%s exists!' % con_name



@step('"{filename}" is file')
@step('"{filename}" is file in "{seconds}" seconds')
def is_file(context, filename, seconds=5):
    for _ in range(int(seconds)):
        if os.path.isfile(filename):
            return
        time.sleep(1)
    ls = nmci_step.command_output(context, 'ls -la "%s"' % filename)
    assert os.path.isfile(filename), '"%s" is not a file:\n%s' % (filename, ls)


@step('Path "{path}" does not exist')
def is_file(context, path):
    if os.path.exists(path):
        time.sleep(3)
        assert not os.path.exists(path), '"%s" is valid path' % path
    return True


@step('"{filename}" is symlink')
@step('"{filename}" is symlink with destination "{destination}"')
def is_file(context, filename, destination=None):
    if "<noted_value>" in filename:
        filename = filename.replace("<noted_value>", context.noted['noted-value'])
    assert os.path.islink(filename), '"%s" is not a symlink' % filename
    realpath = os.path.realpath(filename)
    if destination is None:
        return True
    assert realpath == destination, 'symlink "%s" has destination "%s" instead of "%s"' % (filename, realpath, destination)
    return True


@step('Remove file "{filename}" if exists')
def remove_file(context, filename):
    if os.path.isfile(filename):
        os.remove(filename)
    return True


@step('Remove symlink "{filename}" if exists')
def remove_file(context, filename):
    if os.path.islink(filename):
        os.remove(filename)
    return True


@step('Create symlink {source} with destination {destination}')
def create_symlink(context, source, destination):
    cmd = 'sudo ln -s "%s" "%s"' % (destination, source)
    nmci_step.command_code(context, cmd)


@step(u'Check ifcfg-name file created with noted connection name')
def check_ifcfg_exists(context):
    command = 'cat /etc/sysconfig/network-scripts/ifcfg-%s' % context.noted['noted-value']
    pattern = 'NAME=%s' % context.noted['noted-value']
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step(u'Check ifcfg-name file created for connection "{con_name}"')
def check_ifcfg_exists_given_device(context, con_name):
    nmci_step.additional_sleep(1)
    command = 'cat /etc/sysconfig/network-scripts/ifcfg-%s' % con_name
    pattern = 'NAME=%s' % con_name
    return commands.check_pattern_command(context, command, pattern, seconds=2)


@step(u'Write dispatcher "{path}" file with params "{params}"')
@step(u'Write dispatcher "{path}" file')
def write_dispatcher_file(context, path, params=None):
    if path.startswith("/"):
        disp_file = path
        dir = os.path.dirname(disp_file)
        if not os.path.exists(dir):
            os.makedirs(dir)
    else:
        disp_file  = '/etc/NetworkManager/dispatcher.d/%s' % path
    f = open(disp_file,'w')
    f.write('#!/bin/bash\n')
    if params:
        f.write(params)
    f.write('\necho $2 >> /tmp/dispatcher.txt\n')
    f.close()
    nmci_step.command_code(context, 'chmod +x %s' % disp_file)
    nmci_step.command_code(context, "> /tmp/dispatcher.txt")
    time.sleep(8)


@step('Reset /etc/hosts')
def reset_hosts(context):
    cmd = "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"
    nmci_step.command_code(context, cmd)
    cmd = "echo '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6' >> /etc/hosts"
    nmci_step.command_code(context, cmd)


@step(u'Check solicitation for "{dev}" in "{file}"')
def check_solicitation(context, dev, file):
    #file = '/tmp/solicitation.txt'
    #dev = 'enp0s25'
    cmd = "ip a s %s |grep ff:ff|awk {'print $2'}" %dev
    mac = ""
    for line in nmci_step.command_output(context, cmd).split('\n'):
        if line.find(':') != -1:
            mac = line.strip()

    mac_last_4bits = mac.split(':')[-2]+mac.split(':')[-1]
    dump = open(file, 'r')

    assert mac_last_4bits not in dump.readlines(), "Route solicitation from %s was found in tshark dump" % mac
