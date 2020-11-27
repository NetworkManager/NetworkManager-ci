import json
import os
import pexpect
import re
import subprocess
import time
from behave import step

from steps import command_output, command_code, additional_sleep


@step(u'Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = pexpect.spawn("bash", encoding='utf-8')
    bash.send(cmd)
    bash.send('\t')
    time.sleep(1)
    bash.send('\r\n')
    time.sleep(1)
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
    assert re.search(pattern, context.noted['noted-value']) is not None, "Noted output does not contain the pattern %s" % pattern


@step(u'Check noted output does not contain "{pattern}"')
def check_noted_output_contains(context, pattern):
    assert re.search(pattern, context.noted['noted-value']) is None, "Noted output contains the pattern %s" % pattern


@step(u'Execute "{command}"')
def execute_command(context, command):
    command_code(context, command)
    time.sleep(0.3)


@step(u'Execute "{command}" without waiting for process to finish')
def execute_command(context, command):
    subprocess.Popen(command, shell=True)


@step(u'Execute "{command}" for "{number}" times')
def execute_multiple_times(context, command, number):
    orig_nm_pid = subprocess.check_output('pidof NetworkManager', shell=True).decode('utf-8', 'ignore')

    i = 0
    while i < int(number):
        command_code(context, command)
        curr_nm_pid = subprocess.check_output('pidof NetworkManager', shell=True).decode('utf-8', 'ignore')
        assert curr_nm_pid == orig_nm_pid, 'NM crashed as original pid was %s but now is %s' %(orig_nm_pid, curr_nm_pid)
        i += 1


@step(u'Finish "{command}"')
def wait_for_process(context, command):
    assert command_code(context, command) == 0
    time.sleep(0.1)


@step(u'"{command}" fails')
def wait_for_process(context, command):
    assert command_code(context, command) != 0
    time.sleep(0.1)


@step(u'Restore hostname from the noted value')
def restore_hostname(context):
    command_code('nmcli g hostname %s' % context.noted['noted-value'])
    time.sleep(0.5)


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
        time.sleep(1)
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
        time.sleep(1)
    raise Exception('Hostname visible in log after %d seconds' % (orig_seconds - seconds))


@step(u'Nameserver "{server}" is set')
@step(u'Nameserver "{server}" is set in "{seconds}" seconds')
@step(u'Domain "{server}" is set')
@step(u'Domain "{server}" is set in "{seconds}" seconds')
def get_nameserver_or_domain(context, server, seconds=1):
    if subprocess.call('systemctl is-active systemd-resolved.service -q', shell=True) == 0:
        # We have systemd-resolvd running
        cmd = 'resolvectl dns; resolvectl domain'
    else:
        cmd = 'cat /etc/resolv.conf'
    return check_pattern_command(context, cmd, server, seconds)


@step(u'Nameserver "{server}" is not set')
@step(u'Nameserver "{server}" is not set in "{seconds}" seconds')
@step(u'Domain "{server}" is not set')
@step(u'Domain "{server}" is not set in "{seconds}" seconds')
def get_nameserver_or_domain(context, server, seconds=1):
    if subprocess.call('systemctl is-active systemd-resolved.service -q', shell=True) == 0:
        # We have systemd-resolvd running
        cmd = 'systemd-resolve --status |grep -A 100 Link'
    else:
        cmd = 'cat /etc/resolv.conf'
    return check_pattern_command(context, cmd, server, seconds, check_type="not")


@step(u'Noted value contains "{pattern}"')
def note_print_property_b(context, pattern):
    assert re.search(pattern, context.noted['noted-value']) is not None, "Noted value '%s' does not match the pattern '%s'!" % (context.noted['noted-value'], pattern)


@step(u'Note the output of "{command}" as value "{index}"')
def note_the_output_as(context, command, index):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted[index] = command_output(context, command+" 2>/dev/null").strip()

@step(u'Note the output of "{command}"')
def note_the_output_of(context, command):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = command_output(context, command).strip()

def json_compare(pattern, out):
    pattern_type = type(pattern)
    if pattern_type is dict:
        for x in pattern:
            if x in out:
                r = json_compare(pattern[x], out[x])
                if r != 0:
                    return r
            else:
                return 1
        return 0
    elif pattern_type is list:
        assert False, "TODO: compare lists soomehow"
    else:
        if out == pattern:
            return 0
        else:
            return 1

def check_pattern_command(context, command, pattern, seconds, check_type="default", exact_check=False, timeout=180, maxread=100000, interval=1, json_check=False):
    seconds = int(seconds)
    orig_seconds = seconds
    while seconds > 0:
        proc = pexpect.spawn('/bin/bash', ['-c', command], timeout = timeout, maxread=maxread, logfile=context.log, encoding='utf-8', codec_errors='ignore')
        if exact_check:
            ret = proc.expect_exact([pattern, pexpect.EOF])
        elif json_check:
            proc.expect([pexpect.EOF])
            out = proc.before
            json_out = json.loads(out)
            json_pattern = json.loads(pattern)
            ret = json_compare(json_pattern, json_out)
        else:
            ret = proc.expect([pattern, pexpect.EOF])
        if check_type == "default":
            if ret == 0:
                return True
        elif check_type == "not":
            if ret != 0:
                return True
        elif check_type == "full":
            assert ret == 0, 'Pattern "%s" disappeared after %d seconds, ouput was:\n%s' % (pattern, orig_seconds-seconds, proc.before)
        elif check_type == "not_full":
            assert ret != 0, 'Pattern "%s" appeared after %d seconds, output was:\n%s%s' % (pattern, orig_seconds-seconds, proc.before, proc.after)
        seconds = seconds - 1
        time.sleep(interval)
    if check_type == "default":
        raise Exception('Did not see the pattern "%s" in %d seconds, output was:\n%s' % (pattern, orig_seconds, proc.before))
    elif check_type == "not":
        raise Exception('Did still see the pattern "%s" in %d seconds, output was:\n%s%s' % (pattern, orig_seconds, proc.before, proc.after))
    return True


@step(u'Noted value is visible with command "{command}"')
@step(u'Noted value is visible with command "{command}" in "{seconds}" seconds')
def noted_visible_command(context, command, seconds=2):
    check_pattern_command(context, command, context.noted['noted-value'], seconds, exact_check=True)


@step(u'Noted value is not visible with command "{command}"')
@step(u'Noted value is not visible with command "{command}" in "{seconds}" seconds')
def noted_not_visible_command(context, command, seconds=2):
    return check_pattern_command(context, command, context.noted['noted-value'], seconds, check_type="not", exact_check=True)


@step(u'Noted value "{index}" is visible with command "{command}"')
@step(u'Noted value "{index}" is visible with command "{command}" in "{seconds}" seconds')
def noted_visible_command(context, command, index, seconds=2):
    return check_pattern_command(context, command, context.noted[index], seconds, exact_check=True)


@step(u'Noted value "{index}" is not visible with command "{command}"')
@step(u'Noted value "{index}" is not visible with command "{command}" in "{seconds}" seconds')
def noted_not_visible_command(context, command, index, seconds=2):
    return check_pattern_command(context, command, context.noted[index], seconds, check_type="not", exact_check=True)


@step(u'"{pattern}" is visible with command "{command}"')
@step(u'"{pattern}" is visible with command "{command}" in "{seconds}" seconds')
def pattern_visible_command(context, command, pattern, seconds=2):
    return check_pattern_command(context, command, pattern, seconds)


@step(u'"{pattern}" is not visible with command "{command}"')
@step(u'"{pattern}" is not visible with command "{command}" in "{seconds}" seconds')
def pattern_not_visible_command(context, command, pattern, seconds=2):
    return check_pattern_command(context, command, pattern, seconds, check_type="not")


@step(u'String "{string}" is visible with command "{command}"')
@step(u'String "{string}" is visible with command "{command}" in "{seconds}" seconds')
def string_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, exact_check=True)


@step(u'String "{string}" is not visible with command "{command}"')
@step(u'String "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def string_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_type="not", exact_check=True)


@step(u'JSON "{string}" is visible with command "{command}"')
@step(u'JSON "{string}" is visible with command "{command}" in "{seconds}" seconds')
def string_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, json_check=True)


@step(u'JSON "{string}" is not visible with command "{command}"')
@step(u'JSON "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def string_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_type="not", json_check=True)


@step(u'"{pattern}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="full")


@step(u'"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_not_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="not_full")

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
    children = getattr(context, "children", [])
    children.append(subprocess.Popen(command, shell=True))
    context.children = children


@step(u'Run child "{command}" without shell')
def run_child_process_no_shell(context, command):
    children = getattr(context, "children", [])
    children.append(subprocess.Popen(command.split(" "), stdout=context.log, stderr=context.log))
    context.children = children

@step(u'Kill children')
def kill_children(context):
    if hasattr(context, "children"):
        for child in context.children:
            child.kill()


@step(u'Start following journal')
def start_tailing_journal(context):
    context.journal = pexpect.spawn('sudo journalctl --follow -o cat', timeout = 180, logfile=context.log, encoding='utf-8')
    time.sleep(0.3)


@step(u'Look for "{content}" in journal')
def find_tailing_journal(context, content):
    if context.journal.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in journal output before timeout (180s)' % content)


@step(u'Terminate spawned process "{command}"')
def terminate_spawned_process(context, command):
    assert context.spawned_processes[command].terminate() == True


@step(u'Wait for at least "{secs}" seconds')
def wait_for_x_seconds(context,secs):
    time.sleep(int(secs))
    assert True


@step(u'Look for "{content}" in tailed file')
def find_tailing(context, content):
    if context.tail.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in tail output before timeout (180s)' % content)


@step(u'Start tailing file "{archivo}"')
def start_tailing(context, archivo):
    context.tail = pexpect.spawn('sudo tail -f %s' % archivo, timeout = 180, logfile=context.log, encoding='utf-8')
    time.sleep(0.3)


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
    ret = subprocess.check_output(cmd, shell=True).decode('utf-8', 'ignore').strip()
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
@step(u'Send lifetime scapy packet to dst "{prefix}"')
@step(u'Send lifetime scapy packet with lifetimes "{valid}" "{pref}"')

def send_packet(context, srcaddr=None, hlim=None, valid=3600, pref=1800, prefix="fd00:8086:1337::"):
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
    p /= ICMPv6NDOptPrefixInfo(prefix=prefix, prefixlen=64, validlifetime=valid, preferredlifetime=pref)
    sendp(p, iface=in_if)
    sendp(p, iface=in_if)

    time.sleep(3)


@step(u'Set logging for "{domain}" to "{level}"')
def set_logging(context, domain, level):
    if level == " ":
        cli = pexpect.spawn('nmcli g l domains %s' % (domain), timeout = 60, logfile=context.log, encoding='utf-8')
    else:
        cli = pexpect.spawn('nmcli g l level %s domains %s' % (level, domain), timeout = 60, logfile=context.log, encoding='utf-8')

    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r != 3:
        raise Exception('Something bad happened when changing log level')


@step(u'Note NM log')
def note_NM_log(context):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = subprocess.check_output( "sudo journalctl -all -u NetworkManager --no-pager -o cat %s" % context.log_cursor, shell=True).decode('utf-8', 'ignore')
