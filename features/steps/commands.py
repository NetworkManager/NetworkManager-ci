import json
import os
import pexpect
import re
import time
import operator
from behave import step

import nmci

@step(u'Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = context.pexpect_spawn("bash")
    bash.send(cmd)
    bash.send('\t')
    time.sleep(1)
    bash.send('\r\n')
    time.sleep(1)
    bash.sendeof()


@step(u'Check noted values "{i1}" and "{i2}" are the same')
def check_same_noted_values(context, i1, i2):
    assert context.noted[i1].strip() == context.noted[i2].strip(), \
     "Noted values: %s != %s !" % (context.noted[i1].strip(), context.noted[i2].strip())


@step(u'Check noted values "{i1}" and "{i2}" are not the same')
def check_same_noted_values_equals(context, i1, i2):
    assert context.noted[i1].strip() != context.noted[i2].strip(), \
     "Noted values: %s == %s !" % (context.noted[i1].strip(), context.noted[i2].strip())


@step(u'Check noted value "{i2}" difference from "{i1}" is "{operator_kw}" "{dif}"')
def check_dif_in_values_temp(context, i1, i2, operator_kw, dif):
    real_dif = abs(int(context.noted[i2].strip()) - int(context.noted[i1].strip()))
    assert compare_values(operator_kw.lower(), real_dif, int(dif)), (
        f'The difference between "{i2}" and "{i1}" is '
        f'"|{context.noted[i2].strip()}-{context.noted[i1].strip()}| = {real_dif}", '
        f'which is not "{operator_kw}" {dif}'
    )


@step(u'Check noted value is within "{r_min}" to "{r_max}" range')
@step(u'Check noted value "{index}" is within "{r_min}" to "{r_max}" range')
def check_noted_value_in_range(context, r_min, r_max, index='noted-value'):
    assert int(r_min) <= int(context.noted[index]) <= int(r_max), (
        f'Noted value "{context.noted[index]}" is not within range: "{r_min}"-"{r_max}"'
    )


@step('Execute "{command}"')
def execute_command(context, command):
    context.process.run_stdout(
        command,
        shell=True,
        ignore_returncode=False,
        ignore_stderr=True,
        as_bytes=True,
        timeout=None,
    )


def get_reproducer_command(rname, options):
    dirpath = "contrib/reproducers"
    command = None
    for repro in os.listdir(dirpath):
        if rname in repro:
            repro_path = os.path.join(dirpath, repro)
            command = f"bash {repro_path} {options}" if ".sh" in repro else f"python {repro_path} {options}"
            break
    assert command is not None, f'Invalid reproducer name - {rname}'
    return command


@step(u'Execute reproducer "{rname}"')
@step(u'Execute reproducer "{rname}" with options "{options}"')
@step(u'Execute reproducer "{rname}" for "{number}" times')
@step(u'Execute reproducer "{rname}" with options "{options}" for "{number}" times')
def execute_reproducer(context, rname, options="", number=1):
    orig_nm_pid = nmci.nmutil.nm_pid()
    command = get_reproducer_command(rname, options)
    nm_pid_refresh_count = getattr(context, "nm_pid_refresh_count", 0)
    i = 0
    while i < int(number):
        assert context.command_code(command) == 0
        if nm_pid_refresh_count < 1:
            curr_nm_pid = nmci.nmutil.nm_pid()
            assert curr_nm_pid == orig_nm_pid, \
                f'NM crashed as original pid was {orig_nm_pid} but now is {curr_nm_pid}'
        i += 1


@step(u'Execute "{command}" without waiting for process to finish')
def execute_command_nowait(context, command):
    context.pexpect_service(command, shell=True)


@step(u'Execute "{command}" without output redirect')
def execute_command_noout(context, command):
    context.run(command, stdout=None, stderr=None)


@step(u'Execute "{command}" for "{number}" times')
def execute_multiple_times(context, command, number):
    orig_nm_pid = nmci.nmutil.nm_pid()

    i = 0
    while i < int(number):
        context.command_code(command)
        curr_nm_pid = nmci.nmutil.nm_pid()
        assert curr_nm_pid == orig_nm_pid, 'NM crashed as original pid was %s but now is %s' %(orig_nm_pid, curr_nm_pid)
        i += 1


@step(u'Terminate "{process}"')
@step(u'Terminate "{process}" with signal "{signal}"')
@step(u'Terminate all processes named "{process}"')
@step(u'Terminate all processes named "{process}" with signal "{signal}"')
def pkill_process(context, process, signal='TERM'):
    pids = ' '.join(context.command_output(f"pgrep {process}").split("\n"))
    context.process.run_stdout(f"/usr/bin/kill -{signal} {pids}")
    ticks = 25 # 5 seconds
    while ticks > 0:
        # This works for multiple pids, because kill would return 0
        # if it could signal *any* of the pids
        if context.command_code(f"/usr/bin/kill -0 {pids}") == 1:
            return True
        ticks = ticks - 1
        time.sleep(0.2)
    raise Exception(f"Not all processed {pids} terminated on time")


@step(u'"{command}" fails')
def wait_for_process(context, command):
    assert context.command_code(command) != 0
    time.sleep(0.1)


@step(u'Restore hostname from the noted value')
def restore_hostname(context):
    context.command_code('hostname %s' % context.noted['noted-value'])
    time.sleep(0.5)


@step(u'Hostname is visible in log "{log}"')
@step(u'Hostname is visible in log "{log}" in "{seconds}" seconds')
def hostname_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" %log
    while seconds > 0:
        if context.command_code(cmd) == 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception('Hostname not visible in log in %d seconds' % (orig_seconds))


@step(u'Hostname is not visible in log "{log}"')
@step(u'Hostname is not visible in log "{log}" for full "{seconds}" seconds')
def hostname_not_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" %log
    while seconds > 0:
        if context.command_code(cmd) != 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception('Hostname visible in log after %d seconds' % (orig_seconds - seconds))


@step(u'Nameserver "{server}" is set')
@step(u'Nameserver "{server}" is set in "{seconds}" seconds')
@step(u'Domain "{server}" is set')
@step(u'Domain "{server}" is set in "{seconds}" seconds')
def get_nameserver_or_domain(context, server, seconds=1):
    if context.command_code('systemctl is-active systemd-resolved.service -q') == 0:
        # We have systemd-resolvd running
        cmd = 'resolvectl dns; resolvectl domain'
    else:
        cmd = 'cat /etc/resolv.conf'
    return check_pattern_command(context, cmd, server, seconds)


@step(u'Nameserver "{server}" is not set')
@step(u'Nameserver "{server}" is not set in "{seconds}" seconds')
@step(u'Domain "{server}" is not set')
@step(u'Domain "{server}" is not set in "{seconds}" seconds')
def get_nameserver_or_domain_not(context, server, seconds=1):
    if context.command_code('systemctl is-active systemd-resolved.service -q') == 0:
        # We have systemd-resolvd running
        cmd = 'systemd-resolve --status |grep -A 100 Link'
    else:
        cmd = 'cat /etc/resolv.conf'
    return check_pattern_command(context, cmd, server, seconds, check_type="not")


@step(u'Noted value contains "{pattern}"')
@step(u'Noted value "{index}" contains "{pattern}"')
def noted_value_contains(context, pattern, index='noted-value'):
    assert re.search(pattern, context.noted[index]) is not None, \
        "Noted value '%s' does not match the pattern '%s'!" % (context.noted[index], pattern)


@step(u'Noted value does not contain "{pattern}"')
@step(u'Noted value "{index}" does not contain "{pattern}"')
def noted_value_does_not_contain(context, pattern, index='noted-value'):
    assert re.search(pattern, context.noted[index]) is None, \
        "Noted value '%s' does match the pattern '%s'!" % (context.noted[index], pattern)


@step(u'Note the output of "{command}"')
@step(u'Note the output of "{command}" as value "{index}"')
def note_the_output_as(context, command, index='noted-value'):
    if not hasattr(context, 'noted'):
        context.noted = {}
    # use nmci as embed might be big in general
    command = nmci.process.WithShell(command)
    context.noted[index] = nmci.process.run_stdout(command, ignore_stderr=True, process_hook=None).strip()


@step(u'Note the number of lines of "{command}"')
@step(u'Note the number of lines with pattern "{pattern}" of "{command}"')
@step(u'Note the number of lines of "{command}" as value "{index}"')
@step(u'Note the number of lines with pattern "{pattern}" of "{command}" as value "{index}"')
def note_the_output_lines_as(context, command, index='noted-value', pattern=None):
    if not hasattr(context, 'noted'):
        context.noted = {}
    # use nmci as embed might be big in general
    if pattern is not None:
        out = [line for line in nmci.process.run_stdout(command, ignore_stderr=True, process_hook=None).split('\n') if re.search(pattern, line)]
    else:
        out = [line for line in nmci.process.run_stdout(command, ignore_stderr=True, process_hook=None).split('\n') if line]
    context.noted[index] = str(len(out))


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


def check_pattern_command(context, command, pattern, seconds, check_type="default", check_class='default', timeout=180, maxread=100000,):
    xtimeout = nmci.util.start_timeout(seconds)
    interval = 1
    if int(seconds) < 60:
        interval = 0.5
    if int(seconds) > 200:
        interval = 4
    while xtimeout.loop_sleep(interval):
        proc = context.pexpect_spawn(command, shell=True, timeout=timeout, maxread=maxread, codec_errors='ignore')
        if check_class == 'exact':
            ret = proc.expect_exact([pattern, pexpect.EOF])
        elif check_class == 'json':
            proc.expect([pexpect.EOF])
            ret = json_compare(json.loads(pattern), json.loads(proc.before))
        else:
            ret = proc.expect([pattern, pexpect.EOF])
        if check_type == "default":
            if ret == 0:
                return True
        elif check_type == "not":
            if ret != 0:
                return True
        elif check_type == "full":
            assert ret == 0, 'Pattern "%s" disappeared after %s seconds, ouput was:\n%s' % (pattern, xtimeout.ticking_duration(), proc.before)
        elif check_type == "not_full":
            assert ret != 0, 'Pattern "%s" appeared after %s seconds, output was:\n%s%s' % (pattern, xtimeout.ticking_duration(), proc.before, proc.after)
    if check_type == "default":
        assert False, 'Did not see the pattern "%s" in %d seconds, output was:\n%s' % (pattern, int(seconds), proc.before)
    elif check_type == "not":
        assert False, 'Did still see the pattern "%s" in %d seconds, output was:\n%s%s' % (pattern, int(seconds), proc.before, proc.after)



def compare_values(keyword, value1, value2):
    func_mapper = {
        'at least':operator.ge,
        'at most': operator.le,
        'exactly': operator.eq,
        'more than': operator.gt,
        'less than': operator.lt,
        'different than': operator.ne
        }

    assert keyword in func_mapper, (
        f'Invalid operator keyword: "{keyword}",'
        ' supported operators are:\n     '
        )  + "\n     ".join(func_mapper.keys())

    return func_mapper[keyword](value1, value2)


def check_lines_command(context, command, condition1, seconds,
                        timeout=180, interval=1,
                        maxread=100000, pattern=None,
                        condition2=None):

    xtimeout = nmci.util.start_timeout(seconds)

    while xtimeout.loop_sleep(interval):
        proc = context.pexpect_spawn(
            command,
            shell=True,
            timeout=timeout,
            maxread=maxread,
            codec_errors='ignore')
        proc.expect([pexpect.EOF])

        if pattern is not None:
            out = [line for line in proc.before.split('\n') if re.search(pattern, line)]
            pattern_text = f'containing pattern "{pattern}"'
        else:
            out = [line for line in proc.before.split('\n') if line]
            pattern_text = ''

        ret = compare_values(condition1['op'], len(out), int(condition1['n_lines']))
        if condition2 is not None:
            ret &= compare_values(condition2['op'], len(out), int(condition2['n_lines']))

        if ret:
            return True

    assert condition2 is None, (
        f'''Command "{command}" {pattern_text} did not return '''
        f''' "{condition1['op']}" "{condition1['n_lines']}" '''
        f''' and "{condition2['op']}" "{condition2['n_lines']}" lines, '''
        f'''but "{len(out)}", output was:\n'''
        ) + '\n'.join(out)

    assert False, (
        f'''Command "{command}" {pattern_text} did not return '''
        f''' "{condition1['op']}" "{condition1['n_lines']}" lines, but "{len(out)}", output was:\n'''
        ) + '\n'.join(out)


@step(u'Noted value is visible with command "{command}"')
@step(u'Noted value is visible with command "{command}" in "{seconds}" seconds')
def noted_visible_command(context, command, seconds=2):
    check_pattern_command(context, command, context.noted['noted-value'], seconds, check_class='exact')


@step(u'Noted value is not visible with command "{command}"')
@step(u'Noted value is not visible with command "{command}" in "{seconds}" seconds')
def noted_not_visible_command(context, command, seconds=2):
    return check_pattern_command(context, command, context.noted['noted-value'], seconds, check_type="not", check_class='exact')


@step(u'Noted value "{index}" is visible with command "{command}"')
@step(u'Noted value "{index}" is visible with command "{command}" in "{seconds}" seconds')
def noted_index_visible_command(context, command, index, seconds=2):
    return check_pattern_command(context, command, context.noted[index], seconds, check_class='exact')


@step(u'Noted value "{index}" is not visible with command "{command}"')
@step(u'Noted value "{index}" is not visible with command "{command}" in "{seconds}" seconds')
def noted_index_not_visible_command(context, command, index, seconds=2):
    return check_pattern_command(context, command, context.noted[index], seconds, check_type="not", check_class='exact')


@step(u'"{pattern}" is visible with reproducer "{rname}"')
@step(u'"{pattern}" is visible with reproducer "{rname}" with options "{options}"')
@step(u'"{pattern}" is visible with reproducer "{rname}" in "{seconds}" seconds')
@step(u'"{pattern}" is visible with reproducer "{rname}" with options "{options}" in "{seconds}" seconds')
def pattern_visible_reproducer(context, pattern, rname, options="", seconds=2):
    command = get_reproducer_command(rname, options)
    return check_pattern_command(context, command, pattern, seconds)


@step(u'"{pattern}" is not visible with reproducer "{rname}"')
@step(u'"{pattern}" is not visible with reproducer "{rname}" with options "{options}"')
@step(u'"{pattern}" is not visible with reproducer "{rname}" in "{seconds}" seconds')
@step(u'"{pattern}" is not visible with reproducer "{rname}" with options "{options}" in "{seconds}" seconds')
def pattern_visible_reproducer(context, pattern, rname, options="", seconds=2):
    command = get_reproducer_command(rname, options)
    return check_pattern_command(context, command, pattern, seconds, check_type="not")


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
    return check_pattern_command(context, command, string, seconds, check_class='exact')


@step(u'String "{string}" is not visible with command "{command}"')
@step(u'String "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def string_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_type="not", check_class='exact')


@step(u'JSON "{string}" is visible with command "{command}"')
@step(u'JSON "{string}" is visible with command "{command}" in "{seconds}" seconds')
def json_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_class='json')


@step(u'JSON "{string}" is not visible with command "{command}"')
@step(u'JSON "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def json_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_type="not", check_class='json')


@step(u'Noted number of lines with pattern "{pattern}" is visible with command "{command}" in "{seconds}" seconds')
@step(u'Noted number of lines "{index}" with pattern "{pattern}" is visible with command "{command}" in "{seconds}" seconds')
def noted_lines_visible_command(context, command, index='noted-value', seconds=2, pattern=None):
    return check_lines_command(
        context=context,
        command=command,
        condition1={'n_lines': context.noted[index], 'op': "exactly"},
        seconds=seconds,
        pattern=pattern
        )


@step(u'"{operator_kw1}" "{n_lines1}" and "{operator_kw2}" "{n_lines2}" lines are visible with command "{command}" in "{seconds}" seconds')
@step(u'"{operator_kw1}" "{n_lines1}" and "{operator_kw2}" "{n_lines2}" lines with pattern "{pattern}" are visible with command "{command}" in "{seconds}" seconds')
def range_lines_visible_command(context, command, n_lines1, n_lines2, operator_kw1, operator_kw2,
                                seconds=2, pattern=None):
    return check_lines_command(
        context=context,
        command=command,
        condition1={'n_lines': n_lines1, 'op': operator_kw1.lower()},
        condition2={'n_lines': n_lines2, 'op': operator_kw2.lower()},
        seconds=seconds,
        pattern=pattern
        )


@step(u'"{operator_kw}" "{n_lines}" lines are visible with command "{command}"')
@step(u'"{operator_kw}" "{n_lines}" lines are visible with command "{command}" in "{seconds}" seconds')
@step(u'"{operator_kw}" "{n_lines}" lines with pattern "{pattern}" are visible with command "{command}"')
@step(u'"{operator_kw}" "{n_lines}" lines with pattern "{pattern}" are visible with command "{command}" in "{seconds}" seconds')
def lines_visible_command(context, command, n_lines, operator_kw, seconds=2, pattern=None):
    return check_lines_command(
        context=context,
        command=command,
        condition1={'n_lines': n_lines, 'op': operator_kw.lower()},
        seconds=seconds,
        pattern=pattern
        )


@step(u'"{pattern}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="full")


@step(u'"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_not_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="not_full")


@step(u'Noted value is visible with command "{command}" for full "{seconds}" seconds')
@step(u'Noted value "{index}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, command, seconds, index='noted_value'):
    return check_pattern_command(context, command, context.noted[index], seconds, check_type="full")


@step(u'Noted value is not visible with command "{command}" for full "{seconds}" seconds')
@step(u'Noted value "{index}" is not visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_not_visible_with_command_fortime(context, command, seconds, index='noted_value'):
    return check_pattern_command(context, command, context.noted[index], seconds, check_type="not_full")


@step(u'"{pattern}" is visible with tab after "{command}"')
def check_pattern_visible_with_tab_after_command(context, pattern, command):
    exp = context.pexpect_spawn('/bin/bash')
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendeof()

    assert exp.expect([pattern, pexpect.EOF]) == 0, 'pattern %s is not visible with "%s"' % (pattern, command)


@step(u'"{pattern}" is not visible with tab after "{command}"')
def check_pattern_not_visible_with_tab_after_command(context, pattern, command):
    exp = context.pexpect_spawn('/bin/bash')
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendcontrol('i')
    exp.sendeof()

    assert exp.expect([pattern, pexpect.EOF, pexpect.TIMEOUT]) != 0, 'pattern %s is visible with "%s"' % (pattern, command)


@step(u'Run child "{command}"')
def run_child_process(context, command):
    nmci.pexpect.pexpect_service(command, shell=True, label=True)


@step(u'Run child "{command}" without shell')
def run_child_process_no_shell(context, command):
    nmci.pexpect.pexpect_service(command, label=True)


@step(u'Start following journal')
def start_tailing_journal(context):
    context.journal = context.pexpect_service('sudo journalctl --follow -o cat', timeout=180)
    time.sleep(0.3)


@step(u'Look for "{content}" in journal')
def find_tailing_journal(context, content):
    if context.journal.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in journal output before timeout (180s)' % content)


@step(u'Wait for "{secs}" seconds')
def wait_for_x_seconds(context, secs):
    time.sleep(float(secs))


@step(u'Look for "{content}" in tailed file')
def find_tailing(context, content):
    assert context.tail.expect([content, pexpect.TIMEOUT, pexpect.EOF]) != 1, \
        'Did not see the "%s" in tail output before timeout (180s)' % content


@step(u'Start tailing file "{archivo}"')
def start_tailing(context, archivo):
    context.tail = context.pexpect_service('sudo tail -f %s' % archivo, timeout=180)
    time.sleep(0.3)


@step('Ping "{domain}"')
@step('Ping "{domain}" "{number}" times')
def ping_domain(context, domain, number=2):
    if number != 2:
        rc = context.command_code("ping -q -4 -c %s %s" % (number, domain))
    else:
        rc = context.command_code("curl -s %s" % (domain))
    assert rc == 0


@step(u'Ping "{domain}" from "{device}" device')
def ping_domain_from_device(context, domain, device):
    rc = context.command_code("ping -4 -c 2 -I %s %s" % (device, domain))
    assert rc == 0


@step(u'Ping6 "{domain}"')
def ping6_domain(context, domain):
    rc = context.command_code("ping6 -c 2 %s" % domain)
    assert rc == 0


@step(u'Unable to ping "{domain}"')
def cannot_ping_domain(context, domain):
    rc = context.command_code('curl %s' % domain)
    assert rc != 0


@step(u'Unable to ping "{domain}" from "{device}" device')
def cannot_ping_domain_from_device(context, domain, device):
    assert context.process.run(["ping", "-c", "2", "-I", device, domain], timeout=30).returncode != 0


@step(u'Unable to ping6 "{domain}"')
def cannot_ping6_domain(context, domain):
    assert context.process.run(f'ping6 -c 2 {domain}', timeout=30).returncode != 0


@step(u'Metered status is "{value}"')
@step(u'Metered status is "{value}" in "{seconds}" seconds')
def check_metered_status(context, value, seconds = None):
    value = int(value)
    timeout = nmci.util.start_timeout(seconds)
    while timeout.loop_sleep(0.2):
        ret = nmci.nmutil.get_metered()
        if ret == value:
            return
    assert ret == value, f"Metered value is {ret} but should be {value}"


@step(u'Network trafic "{state}" dropped')
def network_dropped(context, state):
    if state == "is":
        assert context.command_code('ping -c 1 -W 1 boston.com') != 0
    if state == "is not":
        assert context.command_code('ping -c 1 -W 1 boston.com') == 0


@step(u'Network trafic "{state}" dropped on "{device}"')
def network_dropped_two(context, state, device):
    if state == "is":
        assert context.command_code('ping -c 2 -I %s -W 1 8.8.8.8' % device) != 0
    if state == "is not":
        assert context.command_code('ping -c 2 -I %s -W 1 8.8.8.8' % device) == 0


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
        cli = context.pexpect_spawn('nmcli g l domains %s' % (domain), timeout=60)
    else:
        cli = context.pexpect_spawn('nmcli g l level %s domains %s' % (level, domain), timeout=60)

    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r != 3:
        assert False, 'Something bad happened when changing log level'


@step(u'Note NM log')
def note_NM_log(context):
    if not hasattr(context, 'noted'):
        context.noted = {}
    context.noted['noted-value'] = nmci.misc.journal_show("NetworkManager", cursor=context.log_cursor, journal_args="-o cat")


@step(u'Check coredump is not found in "{seconds}" seconds')
def check_no_coredump(context, seconds):
    # check core limit is unlimited (soft and hard)
    # if it is not the case, the check_coredump may fail, and we do not have cores!
    with open(f"/proc/{context.nm_pid}/limits") as limits_f:
        for limit in limits_f.readlines():
            if "max core file size" in limit.lower():
                # there should be 2 "unlimited" columns
                if "unlimited" not in limit.replace("unlimited", "", 1):
                    nmci.embed.embed_data("Core Limits", limit)
                    # exit cleanly, test is marked @xfail
                    return

    # segfault NM
    context.process.run_stdout("pkill -SIGSEGV NetworkManager")

    # check if coredump is found
    timeout = nmci.util.start_timeout(seconds)
    while timeout.loop_sleep(0.5):
        nmci.ctx.check_coredump(context)
        assert not nmci.embed.coredump_reported, "Coredump found"


@step('Check "{family}" address list "{expected}" on device "{ifname}"')
@step('Check "{family}" address list "{expected}" on device "{ifname}" in "{seconds}" seconds')
def check_address_expect(context, family, expected, ifname, seconds=None):

    expected = re.split(r"[,; ]+", expected)
    if seconds is not None:
        seconds = float(seconds)
    family = nmci.ip.addr_family_norm(family)

    try:
        nmci.ip.address_expect(
            expected=expected,
            ifname=ifname,
            match_mode='auto',
            with_plen=True,
            ignore_order=False,
            ignore_extra=False,
            addr_family=family,
            wait_for_address=seconds,
        )
    except Exception:
        print(">>> about to fail check_address_expect():")
        os.system('ip -d address show')
        raise


@step(u'Load nftables')
@step(u'Load nftables "{ruleset}"')
@step(u'Load nftables in "{ns}" namespace')
@step(u'Load nftables "{ruleset}" in "{ns}" namespace')
def load_nftables(context, ns=None, ruleset=None):
    import nftables
    from pyroute2 import netns
    if ruleset is None:
        ruleset = context.text

    nmci.cleanup.cleanup_add_nft(ns)
    if ns is None:
        nsprefix = ""
        nft = nftables.Nftables()
    else:
        nsprefix = f"ip netns exec {ns} "
        netns.pushns(ns)
        nft = nftables.Nftables()
        netns.popns()

    # why doesn't nmci/process.py handle stdin?
    file = "/tmp/nmci-nft-ruleset-to-load"
    with open(file, 'w') as f:
        f.write(ruleset)
    nft_status = [f"nftables ruleset{f' in namespace {ns}' if ns else ''} before this step:"]
    nft_status.append(nft.cmd("list ruleset")[1])
    context.process.run(f"{nsprefix}nft -f {file}")
    nft_status.append(f"\nnftables ruleset{f' in namespace {ns}' if ns else ''} after this step:")
    nft_status.append(nft.cmd("list ruleset")[1])
    nmci.embed.embed_data("State of nftables", "\n".join(nft_status), fail_only=True)
    os.remove(file)


@step(u'Cleanup nftables')
@step(u'Cleanup nftables in namespace "{ns}"')
def flush_nftables(context, ns=None):
    nmci.cleanup.cleanup_add_nft(ns)
