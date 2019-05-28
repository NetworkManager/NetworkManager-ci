# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob

from steps import command_output, command_code, additional_sleep



@step(u'Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = pexpect.spawn("bash", encoding='utf-8')
    bash.send(cmd)
    bash.send('\t')
    sleep(1)
    bash.send('\r\n')
    sleep(1)
    bash.sendeof()


@step(u'Check RSS writable memory in noted value "{i2}" differs from "{i1}" less than "{dif}"')
def check_rss_rw_dif(context, i2, i1, dif):
    # def sum_rss_writable_memory(context, pmap_raw):
    #     total = 0
    #     for line in pmap_raw.split("\n"):
    #         vals = line.split()
    #         if (len(vals) > 2):
    #             total += int(vals[2])
    #     return total
    #
    # sum2 = int(sum_rss_writable_memory(context, context.noted[i2]))
    # sum1 = int(sum_rss_writable_memory(context, context.noted[i1]))
    sum2 = int(context.noted[i2])
    sum1 = int(context.noted[i1])
    assert (sum1 + int(dif) > sum2), \
     "rw RSS mem: %d + %s !> %d !" % (sum1, dif, sum2)


@step(u'Check noted value "{i2}" difference from "{i1}" is lower than "{dif}"')
def check_dif_in_values(context, i2, i1, dif):
    assert (int(context.noted[i1].strip()) + int(dif)) > int(context.noted[i2].strip()), \
     "Noted values: %s + %s !> %s !" % (context.noted[i1].strip(), dif, context.noted[i2].strip())


@step(u'Check noted values "{i1}" and "{i2}" are the same')
def check_same_noted_values(context, i1, i2):
    assert context.noted[i1].strip() == context.noted[i2].strip(), \
     "Noted values: %s != %s !" % (context.noted[i1].strip(), context.noted[i2].strip())


@step(u'Check noted values "{i1}" and "{i2}" are not the same')
def check_same_noted_values(context, i1, i2):
    assert context.noted[i1].strip() != context.noted[i2].strip(), \
     "Noted values: %s == %s !" % (context.noted[i1].strip(), context.noted[i2].strip())


@step(u'Check noted output contains "{pattern}"')
def check_noted_output_contains(context, pattern):
    assert re.search(pattern, context.noted_value) is not None, "Noted output does not contain the pattern %s" % pattern


@step(u'Check noted output does not contain "{pattern}"')
def check_noted_output_contains(context, pattern):
    assert re.search(pattern, context.noted_value) is None, "Noted output contains the pattern %s" % pattern


@step(u'Execute "{command}"')
def execute_command(context, command):
    command_code(context, command)
    sleep(0.3)


@step(u'Execute "{command}" without waiting for process to finish')
def execute_command(context, command):
    Popen(command, shell=True)


@step(u'Execute "{command}" for "{number}" times')
def execute_multiple_times(context, command, number):
    orig_nm_pid = check_output('pidof NetworkManager', shell=True).decode('utf-8')

    i = 0
    while i < int(number):
        command_code(context, command)
        curr_nm_pid = check_output('pidof NetworkManager', shell=True).decode('utf-8')
        assert curr_nm_pid == orig_nm_pid, 'NM crashed as original pid was %s but now is %s' %(orig_nm_pid, curr_nm_pid)
        i += 1


@step(u'Finish "{command}"')
def wait_for_process(context, command):
    assert command_code(context, command) == 0
    sleep(0.1)


@step(u'"{command}" fails')
def wait_for_process(context, command):
    assert command_code(context, command) != 0
    sleep(0.1)


@step(u'Restore hostname from the noted value')
def restore_hostname(context):
    command_code('nmcli g hostname %s' % context.noted_value)
    sleep(0.5)


@step(u'Hostname is visible in log "{log}"')
@step(u'Hostname is visible in log "{log}" in "{seconds}" seconds')
def hostname_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" %log
    while seconds > 0:
        if command_code(context, cmd) == 0:
            return True
        seconds = seconds - 1
        sleep(1)
    raise Exception('Hostname not visible in log in %d seconds' % (orig_seconds))


@step(u'Hostname is not visible in log "{log}"')
@step(u'Hostname is not visible in log "{log}" for full "{seconds}" seconds')
def hostname_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" %log
    while seconds > 0:
        if command_code(context, cmd) != 0:
            return True
        seconds = seconds - 1
        sleep(1)
    raise Exception('Hostname visible in log after %d seconds' % (orig_seconds - seconds))


@step(u'Noted value contains "{pattern}"')
def note_print_property_b(context, pattern):
    assert re.search(pattern, context.noted) is not None, "Noted value does not match the pattern!"


@step(u'Note the output of "{command}" as value "{index}"')
def note_the_output_as(context, command, index):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted[index] = command_output(context, command+" 2>/dev/null").strip()

@step(u'Note the output of "{command}"')
def note_the_output_of(context, command):
    context.noted_value = command_output(context, command).strip()


@step(u'Noted value is not visible with command "{command_not}"')
@step(u'Noted value "{index}" is not visible with command "{command_not}"')
@step(u'"{pattern}" is not visible with command "{command_not}"')
@step(u'String "{string}" is not visible with command "{command_not}"')
@step(u'Noted value is not visible with command "{command_not}" in "{seconds}" seconds')
@step(u'Noted value "{index}" is not visible with command "{command_not}" in "{seconds}" seconds')
@step(u'"{pattern}" is not visible with command "{command_not}" in "{seconds}" seconds')
@step(u'String "{string}" is not visible with command "{command_not}" in "{seconds}" seconds')
@step(u'Noted value is visible with command "{command}"')
@step(u'Noted value "{index}" is visible with command "{command}"')
@step(u'"{pattern}" is visible with command "{command}"')
@step(u'String "{string}" is visible with command "{command}"')
@step(u'Noted value is visible with command "{command}" in "{seconds}" seconds')
@step(u'Noted value "{index}" is visible with command "{command}" in "{seconds}" seconds')
@step(u'"{pattern}" is visible with command "{command}" in "{seconds}" seconds')
@step(u'String "{string}" is visible with command "{command}" in "{seconds}" seconds')
def check_pattern_visible_with_command_in_time(context, command=None, command_not=None, seconds=2, pattern=None, index=None, string=None):
    exact_check = False
    not_check = False
    if command is None:
        command = command_not
        not_check = True
    if pattern is None and index is None:
        pattern = context.noted_value
        exact_check = True
    if index is not None:
        pattern = context.noted[index]
        exact_check = True
    if string is not None:
        pattern = string
        exact_check = True
    seconds = int(seconds)
    orig_seconds = seconds
    while seconds > 0:
        proc = pexpect.spawn('/bin/bash', ['-c', command], timeout = 180, logfile=context.log, encoding='utf-8')
        if exact_check:
            ret = proc.expect_exact([pattern, pexpect.EOF])
        else:
            ret = proc.expect([pattern, pexpect.EOF])
        if not_check:
            if ret != 0:
                return True
        else:
            if ret == 0:
                return True
        seconds = seconds - 1
        sleep(1)
    if not_check:
        raise Exception('Did still see the pattern %s in %d seconds' % (pattern, orig_seconds))
    else:
        raise Exception('Did not see the pattern %s in %d seconds' % (pattern, orig_seconds))


@step(u'"{pattern}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    seconds = int(seconds)
    orig_seconds = seconds
    while seconds > 0:
        proc = pexpect.spawn('/bin/bash', ['-c', command], timeout = 180, logfile=context.log, encoding='utf-8')
        if proc.expect([pattern, pexpect.EOF]) == 0:
            pass
        else:
            raise Exception('Pattern %s disappeared after %d seconds' % (pattern, orig_seconds-seconds))
        seconds = seconds - 1
        sleep(1)


@step(u'"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    seconds = int(seconds)
    orig_seconds = seconds
    while seconds > 0:
        proc = pexpect.spawn('/bin/bash', ['-c', command], timeout = 180, logfile=context.log, encoding='utf-8')
        if proc.expect([pattern, pexpect.EOF]) != 0:
            pass
        else:
            raise Exception('Pattern %s appeared in %d seconds' % (pattern, orig_seconds-seconds))
        seconds = seconds - 1
        sleep(1)


@step(u'"{pattern}" is visible with tab after "{command}"')
def check_pattern_visible_with_tab_after_command(context, pattern, command):
    os.system('echo "set page-completions off" > ~/.inputrc')
    exp = pexpect.spawn('/bin/bash', logfile=context.log, encoding='utf-8')
    exp.send(command)
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendeof()

    assert exp.expect([pattern, pexpect.EOF]) == 0, 'pattern %s is not visible with "%s"' % (pattern, command)


@step(u'"{pattern}" is not visible with tab after "{command}"')
def check_pattern_not_visible_with_tab_after_command(context, pattern, command):
    os.system('echo "set page-completions off" > ~/.inputrc')
    exp = pexpect.spawn('/bin/bash', logfile=context.log, encoding='utf-8')
    exp.send(command)
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendeof()

    assert exp.expect([pattern, pexpect.EOF, pexpect.TIMEOUT]) != 0, 'pattern %s is visible with "%s"' % (pattern, command)


@step(u'Run child "{command}"')
def run_child_process(context, command):
    Popen(command, shell=True)


@step(u'Start following journal')
def start_tailing_journal(context):
    context.journal = pexpect.spawn('sudo journalctl --follow -o cat', timeout = 180, logfile=context.log, encoding='utf-8')
    sleep(0.3)


@step(u'Look for "{content}" in journal')
def find_tailing_journal(context, content):
    if context.journal.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in journal output before timeout (180s)' % content)


@step(u'Terminate spawned process "{command}"')
def terminate_spawned_process(context, command):
    assert context.spawned_processes[command].terminate() == True


@step(u'Wait for at least "{secs}" seconds')
def wait_for_x_seconds(context,secs):
    sleep(int(secs))
    assert True


@step(u'Look for "{content}" in tailed file')
def find_tailing(context, content):
    if context.tail.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in tail output before timeout (180s)' % content)


@step(u'Start tailing file "{archivo}"')
def start_tailing(context, archivo):
    context.tail = pexpect.spawn('sudo tail -f %s' % archivo, timeout = 180, logfile=context.log, encoding='utf-8')
    sleep(0.3)


@step('Ping "{domain}"')
@step('Ping "{domain}" "{number}" times')
def ping_domain(context, domain, number=2):
    if number != 2:
        ping = pexpect.spawn("ping -q -4 -c %s %s" %(number, domain), logfile=context.log, encoding='utf-8')
    else:
        ping = pexpect.spawn("curl -s %s" %(domain), logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus == 0, "msg: %s" % ping.before


@step(u'Ping "{domain}" from "{device}" device')
def ping_domain_from_device(context, domain, device):
    ping = pexpect.spawn("ping -4 -c 2 -I %s %s" %(device, domain), logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus == 0, "msg: %s" % ping.before


@step(u'Ping6 "{domain}"')
def ping6_domain(context, domain):
    ping = pexpect.spawn("ping6 -c 2 %s" %domain, logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus == 0, "msg: %s" % ping.before


@step(u'Unable to ping "{domain}"')
def cannot_ping_domain(context, domain):
    ping = pexpect.spawn('curl %s' %domain, logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus != 0


@step(u'Unable to ping "{domain}" from "{device}" device')
def cannot_ping_domain_from_device(context, domain, device):
    ping = pexpect.spawn('ping -c 2 -I %s %s ' %(device, domain), logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus != 0


@step(u'Unable to ping6 "{domain}"')
def cannot_ping6_domain(context, domain):
    ping = pexpect.spawn('ping6 -c 2 %s' %domain, logfile=context.log, encoding='utf-8')
    ping.expect([pexpect.EOF])
    ping.close()
    assert ping.exitstatus != 0




@step(u'Metered status is "{value}"')
def check_metered_status(context, value):
    cmd = 'dbus-send --system --print-reply --dest=org.freedesktop.NetworkManager \
                                                /org/freedesktop/NetworkManager \
                                                org.freedesktop.DBus.Properties.Get \
                                                string:"org.freedesktop.NetworkManager" \
                                                string:"Metered" |grep variant| awk \'{print $3}\''
    ret = check_output(cmd, shell=True).decode('utf-8').strip()
    assert ret == value, "Metered value is %s but should be %s" %(ret, value)

@step(u'Network trafic "{state}" dropped')
def network_dropped(context, state):
    if state == "is":
        assert command_code(context, 'ping -c 1 -W 1 boston.com') != 0
    if state == "is not":
        assert command_code(context, 'ping -c 1 -W 1 boston.com') == 0


@step(u'Network trafic "{state}" dropped on "{device}"')
def network_dropped_two(context, state, device):
    if state == "is":
        assert command_code(context, 'ping -c 2 -I %s -W 1 8.8.8.8' % device) != 0
    if state == "is not":
        assert command_code(context, 'ping -c 2 -I %s -W 1 8.8.8.8' % device) == 0


@step(u'Send lifetime scapy packet')
@step(u'Send lifetime scapy packet with "{hlim}"')
@step(u'Send lifetime scapy packet from "{srcaddr}"')
@step(u'Send lifetime scapy packet with lifetimes "{valid}" "{pref}"')
def send_packet(context, srcaddr=None, hlim=None, valid=3600, pref=1800):
    from scapy.all import get_if_hwaddr
    from scapy.all import sendp, Ether, IPv6
    from scapy.all import ICMPv6ND_RA
    from scapy.all import ICMPv6NDOptPrefixInfo

    in_if = "test10"
    out_if = "test11"

    p = Ether(dst=get_if_hwaddr(out_if), src=get_if_hwaddr(in_if))
    if srcaddr or hlim:
        if hlim:
            p /= IPv6(dst="ff02::1", hlim=int(hlim))
        else:
            p /= IPv6(dst="ff02::1", src=srcaddr)
    else:
        p /= IPv6(dst="ff02::1")

    valid, pref = int(valid), int(pref)

    p /= ICMPv6ND_RA()
    p /= ICMPv6NDOptPrefixInfo(prefix="fd00:8086:1337::", prefixlen=64, validlifetime=valid, preferredlifetime=pref)
    sendp(p, iface=in_if)
    sendp(p, iface=in_if)

    sleep(3)


@step(u'Set logging for "{domain}" to "{level}"')
def set_logging(context, domain, level):
    if level == " ":
        cli = pexpect.spawn('nmcli g l domains %s' % (domain), timeout = 60, logfile=context.log, encoding='utf-8')
    else:
        cli = pexpect.spawn('nmcli g l level %s domains %s' % (level, domain), timeout = 60, logfile=context.log, encoding='utf-8')

    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r != 3:
        raise Exception('Something bad happened when changing log level')
