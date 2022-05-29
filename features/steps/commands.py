import json
import os
import pexpect
import re
import time
from behave import step

import nmci
import nmci.misc
import nmci.nmutil


@step(u'Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = context.pexpect_spawn("bash")
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
def check_same_noted_values_equals(context, i1, i2):
    assert context.noted[i1].strip() != context.noted[i2].strip(), \
     "Noted values: %s == %s !" % (context.noted[i1].strip(), context.noted[i2].strip())


@step(u'Execute "{command}"')
def execute_command(context, command):
    assert context.command_code(command) == 0


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
def noted_value_contains(context, pattern):
    assert re.search(pattern, context.noted['noted-value']) is not None, \
        "Noted value '%s' does not match the pattern '%s'!" % (context.noted['noted-value'], pattern)


@step(u'Noted value does not contain "{pattern}"')
def noted_value_does_not_contain(context, pattern):
    assert re.search(pattern, context.noted['noted-value']) is None, \
        "Noted value '%s' does match the pattern '%s'!" % (context.noted['noted-value'], pattern)


@step(u'Note the output of "{command}" as value "{index}"')
def note_the_output_as(context, command, index):
    if not hasattr(context, 'noted'):
        context.noted = {}
    # use nmci as embed might be big in general
    context.noted[index] = nmci.command_output_err(command)[0].strip()


@step(u'Note the output of "{command}"')
def note_the_output_of(context, command):
    if not hasattr(context, 'noted'):
        context.noted = {}
    # use nmci as embed might be big in general
    context.noted['noted-value'] = nmci.command_output(command).strip()


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
    start_time = time.clock_gettime(nmci.util.CLOCK_BOOTTIME)
    wait_seconds = float(seconds)
    assert wait_seconds >= 0
    end_time = start_time + wait_seconds
    while True:
        proc = context.pexpect_spawn(command, shell=True, timeout=timeout, maxread=maxread, codec_errors='ignore')
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

        now = time.clock_gettime(nmci.util.CLOCK_BOOTTIME)

        if check_type == "default":
            if ret == 0:
                return True
        elif check_type == "not":
            if ret != 0:
                return True
        elif check_type == "full":
            assert ret == 0, 'Pattern "%s" disappeared after %s seconds, ouput was:\n%s' % (pattern, now - start_time, proc.before)
        elif check_type == "not_full":
            assert ret != 0, 'Pattern "%s" appeared after %s seconds, output was:\n%s%s' % (pattern, now - start_time, proc.before, proc.after)

        if now >= end_time:
            break
        time.sleep(min(interval, end_time - now + 0.01))

    if check_type == "default":
        assert False, 'Did not see the pattern "%s" in %d seconds, output was:\n%s' % (pattern, int(seconds), proc.before)
    elif check_type == "not":
        assert False, 'Did still see the pattern "%s" in %d seconds, output was:\n%s%s' % (pattern, int(seconds), proc.before, proc.after)


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
def noted_index_visible_command(context, command, index, seconds=2):
    return check_pattern_command(context, command, context.noted[index], seconds, exact_check=True)


@step(u'Noted value "{index}" is not visible with command "{command}"')
@step(u'Noted value "{index}" is not visible with command "{command}" in "{seconds}" seconds')
def noted_index_not_visible_command(context, command, index, seconds=2):
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
def json_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, json_check=True)


@step(u'JSON "{string}" is not visible with command "{command}"')
@step(u'JSON "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def json_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_type="not", json_check=True)


@step(u'"{pattern}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="full")


@step(u'"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_not_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="not_full")


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
    context.children = getattr(context, "children", [])
    child = context.pexpect_service(command, shell=True)
    context.children.append(child)


@step(u'Run child "{command}" without shell')
def run_child_process_no_shell(context, command):
    context.children = getattr(context, "children", [])
    child = context.pexpect_service(command)
    context.children.append(child)


@step(u'Kill children')
def kill_children(context):
    for child in getattr(context, "children", []):
        child.kill(9)


@step(u'Start following journal')
def start_tailing_journal(context):
    context.journal = context.pexpect_service('sudo journalctl --follow -o cat', timeout=180)
    time.sleep(0.3)


@step(u'Look for "{content}" in journal')
def find_tailing_journal(context, content):
    if context.journal.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception('Did not see the "%s" in journal output before timeout (180s)' % content)


@step(u'Wait for at least "{secs}" seconds')
def wait_for_x_seconds(context, secs):
    time.sleep(int(secs))
    assert True


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
    if seconds is not None:
        end_time = time.clock_gettime(nmci.util.CLOCK_BOOTTIME) + float(seconds)
    while True:
        ret = nmci.nmutil.get_metered()
        if ret == value:
            return
        if seconds is None or time.clock_gettime(nmci.util.CLOCK_BOOTTIME) > end_time:
            assert ret == value, f"Metered value is {ret} but should be {value}"
        time.sleep(0.2)


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
    for i in range(int(seconds)):
        nmci.lib.check_coredump(context)
        if context.crash_embeded:
            assert False, "Coredump found"
        time.sleep(1)


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
