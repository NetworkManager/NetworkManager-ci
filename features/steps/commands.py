# pylint: disable=function-redefined
# type: ignore [no-redef]
import glob
import json
import operator
import os
import pexpect
import re
import requests
import shlex
import time
from behave import step  # pylint: disable=no-name-in-module

import nmci


@step('Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = context.pexpect_spawn("bash")
    bash.send(cmd)
    bash.send("\t")
    time.sleep(1)
    bash.send("\r\n")
    time.sleep(1)
    bash.sendeof()


@step('Check noted values "{i1}" and "{i2}" are the same')
def check_same_noted_values(context, i1, i2):
    assert (
        context.noted[i1].strip() == context.noted[i2].strip()
    ), "Noted values: %s != %s !" % (
        context.noted[i1].strip(),
        context.noted[i2].strip(),
    )


@step('Check noted values "{i1}" and "{i2}" are not the same')
def check_same_noted_values_equals(context, i1, i2):
    assert (
        context.noted[i1].strip() != context.noted[i2].strip()
    ), "Noted values: %s == %s !" % (
        context.noted[i1].strip(),
        context.noted[i2].strip(),
    )


@step('Check noted value "{i2}" difference from "{i1}" is "{operator_kw}" "{dif}"')
def check_dif_in_values_temp(context, i1, i2, operator_kw, dif):
    real_dif = int(context.noted[i2].strip()) - int(context.noted[i1].strip())
    assert compare_values(operator_kw.lower(), real_dif, int(dif)), (
        f'The difference between "{i2}" and "{i1}" is '
        f'"|{context.noted[i2].strip()}-{context.noted[i1].strip()}| = {real_dif}", '
        f'which is not "{operator_kw}" {dif}'
    )


@step('Check noted value is within "{r_min}" to "{r_max}" range')
@step('Check noted value "{index}" is within "{r_min}" to "{r_max}" range')
def check_noted_value_in_range(context, r_min, r_max, index="noted-value"):
    assert (
        int(r_min) <= int(context.noted[index]) <= int(r_max)
    ), f'Noted value "{context.noted[index]}" is not within range: "{r_min}"-"{r_max}"'


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


def get_reproducer_command_v(rname, options):
    cmd = nmci.util.base_dir("contrib/reproducers", rname)
    assert os.access(
        cmd, os.X_OK
    ), f'Reproducer "{rname}" not found in "./contrib/reproducers/"'
    args = [cmd]
    if options:
        args += list(shlex.split(options))
    return args


def get_reproducer_command(rname, options):
    return " ".join(shlex.quote(a) for a in get_reproducer_command_v(rname, options))


@step('Execute reproducer "{rname}"')
@step('Execute reproducer "{rname}" with options "{options}"')
@step('Execute reproducer "{rname}" for "{number}" times')
@step('Execute reproducer "{rname}" with options "{options}" for "{number}" times')
def execute_reproducer(context, rname, options="", number=1):
    orig_nm_pid = nmci.nmutil.nm_pid()
    argv = get_reproducer_command_v(rname, options)
    nm_pid_refresh_count = getattr(context, "nm_pid_refresh_count", 0)
    for i in range(int(number)):
        nmci.process.run_stdout(argv, timeout=180, ignore_stderr=True)
        if nm_pid_refresh_count < 1:
            curr_nm_pid = nmci.nmutil.nm_pid()
            assert (
                curr_nm_pid == orig_nm_pid
            ), f"NM crashed as original pid was {orig_nm_pid} but now is {curr_nm_pid}"


@step('Execute "{command}" without waiting for process to finish')
def execute_command_nowait(context, command):
    context.pexpect_service(command, shell=True)


@step('Execute "{command}" without output redirect')
def execute_command_noout(context, command):
    context.run(command, stdout=None, stderr=None)


@step('Execute "{command}" for "{number}" times')
def execute_multiple_times(context, command, number):
    orig_nm_pid = nmci.nmutil.nm_pid()

    i = 0
    while i < int(number):
        context.command_code(command)
        curr_nm_pid = nmci.nmutil.nm_pid()
        assert (
            curr_nm_pid == orig_nm_pid
        ), "NM crashed as original pid was %s but now is %s" % (
            orig_nm_pid,
            curr_nm_pid,
        )
        i += 1


@step('Terminate "{process}"')
@step('Terminate "{process}" with signal "{signal}"')
@step('Terminate all processes named "{process}"')
@step('Terminate all processes named "{process}" with signal "{signal}"')
def pkill_process(context, process, signal="TERM"):
    pids = " ".join(context.command_output(f"pgrep {process}").split("\n"))
    context.process.run_stdout(f"/usr/bin/kill -{signal} {pids}")
    ticks = 25  # 5 seconds
    while ticks > 0:
        # This works for multiple pids, because kill would return 0
        # if it could signal *any* of the pids
        if context.command_code(f"/usr/bin/kill -0 {pids}") == 1:
            return True
        ticks = ticks - 1
        time.sleep(0.2)
    raise Exception(f"Not all processed {pids} terminated on time")


@step('"{command}" fails')
def wait_for_process(context, command):
    assert context.command_code(command) != 0
    time.sleep(0.1)


@step("Restore hostname from the noted value")
def restore_hostname(context):
    context.command_code("hostname %s" % context.noted["noted-value"])
    time.sleep(0.5)


@step('Hostname is visible in log "{log}"')
@step('Hostname is visible in log "{log}" in "{seconds}" seconds')
def hostname_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" % log
    while seconds > 0:
        if context.command_code(cmd) == 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception("Hostname not visible in log in %d seconds" % (orig_seconds))


@step('Hostname is not visible in log "{log}"')
@step('Hostname is not visible in log "{log}" for full "{seconds}" seconds')
def hostname_not_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = "grep $(hostname -s) '%s'" % log
    while seconds > 0:
        if context.command_code(cmd) != 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception(
        "Hostname visible in log after %d seconds" % (orig_seconds - seconds)
    )


@step('Nameserver "{server}" is set')
@step('Nameserver "{server}" is set in "{seconds}" seconds')
@step('Domain "{server}" is set')
@step('Domain "{server}" is set in "{seconds}" seconds')
def get_nameserver_or_domain(context, server, seconds=1):
    if context.command_code("systemctl is-active systemd-resolved.service -q") == 0:
        # We have systemd-resolvd running
        cmd = "resolvectl dns; resolvectl domain"
    else:
        cmd = "cat /etc/resolv.conf"
    return check_pattern_command(context, cmd, server, seconds)


@step('Nameserver "{server}" is not set')
@step('Nameserver "{server}" is not set in "{seconds}" seconds')
@step('Domain "{server}" is not set')
@step('Domain "{server}" is not set in "{seconds}" seconds')
def get_nameserver_or_domain_not(context, server, seconds=1):
    if context.command_code("systemctl is-active systemd-resolved.service -q") == 0:
        # We have systemd-resolvd running
        cmd = "systemd-resolve --status |grep -A 100 Link"
    else:
        cmd = "cat /etc/resolv.conf"
    return check_pattern_command(context, cmd, server, seconds, check_type="not")


@step('Noted value contains "{pattern}"')
@step('Noted value "{index}" contains "{pattern}"')
def noted_value_contains(context, pattern, index="noted-value"):
    assert (
        re.search(pattern, context.noted[index]) is not None
    ), "Noted value '%s' does not match the pattern '%s'!" % (
        context.noted[index],
        pattern,
    )


@step('Noted value does not contain "{pattern}"')
@step('Noted value "{index}" does not contain "{pattern}"')
def noted_value_does_not_contain(context, pattern, index="noted-value"):
    assert (
        re.search(pattern, context.noted[index]) is None
    ), "Noted value '%s' does match the pattern '%s'!" % (context.noted[index], pattern)


@step('Note the output of "{command}"')
@step('Note the output of "{command}" as value "{index}"')
def note_the_output_as(context, command, index="noted-value"):
    if not hasattr(context, "noted"):
        context.noted = {}
    command = nmci.process.WithShell(command)
    context.noted[index] = nmci.process.run_stdout(command, ignore_stderr=True).strip()


@step('Note the number of lines of "{command}"')
@step('Note the number of lines with pattern "{pattern}" of "{command}"')
@step('Note the number of lines of "{command}" as value "{index}"')
@step(
    'Note the number of lines with pattern "{pattern}" of "{command}" as value "{index}"'
)
def note_the_output_lines_as(context, command, index="noted-value", pattern=None):
    if not hasattr(context, "noted"):
        context.noted = {}
    out = nmci.process.run_stdout(command, ignore_stderr=True)
    if pattern is not None:
        out = [line for line in out.split("\n") if re.search(pattern, line)]
    else:
        out = [line for line in out.split("\n") if line]
    nmci.embed.embed_data(
        "Noted", f"[{index}] counted {len(out)} lines ({out})", fail_only=True
    )
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


def check_pattern_command(
    context,
    command,
    pattern,
    seconds,
    check_type="default",
    check_class="default",
    timeout=180,
    maxread=100000,
):
    seconds = float(seconds)
    xtimeout = nmci.util.start_timeout(seconds)

    # Adjust the poll interval based the timeout. Since the command output gets
    # recorded in the test artifacts, we want to keep the number of polls
    # reasonable.
    if seconds < 60:
        interval = 0.5
    elif seconds <= 200:
        interval = 1
    else:
        interval = 4

    while xtimeout.loop_sleep(interval):
        proc = context.pexpect_spawn(
            command, shell=True, timeout=timeout, maxread=maxread, codec_errors="ignore"
        )
        if check_class == "exact":
            ret = proc.expect_exact([pattern, pexpect.EOF])
        elif check_class == "json":
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
            assert (
                ret == 0
            ), f'Pattern "{pattern}" disappeared after {nmci.misc.format_duration(xtimeout.elapsed_time())} seconds, output was:\n{proc.before}'
        elif check_type == "not_full":
            assert (
                ret != 0
            ), f'Pattern "{pattern}" appeared after {nmci.misc.format_duration(xtimeout.elapsed_time())} seconds, output was:\n{proc.before}{proc.after}'
    if check_type == "default":
        assert (
            False
        ), f'Did not see the pattern "{pattern}" in {nmci.misc.format_duration(seconds)} seconds, output was:\n{proc.before}'
    elif check_type == "not":
        assert (
            False
        ), f'Did still see the pattern "{pattern}" in {nmci.misc.format_duration(seconds)} seconds, output was:\n{proc.before}{proc.after}'


def compare_values(keyword, value1, value2):
    func_mapper = {
        "at least": operator.ge,
        "at most": operator.le,
        "exactly": operator.eq,
        "more than": operator.gt,
        "less than": operator.lt,
        "different than": operator.ne,
    }

    assert keyword in func_mapper, (
        f'Invalid operator keyword: "{keyword}",' " supported operators are:\n     "
    ) + "\n     ".join(func_mapper.keys())

    return func_mapper[keyword](value1, value2)


def check_lines_command(
    context,
    command,
    condition1,
    seconds,
    timeout=180,
    interval=1,
    maxread=100000,
    pattern=None,
    condition2=None,
):

    xtimeout = nmci.util.start_timeout(seconds)

    while xtimeout.loop_sleep(interval):
        proc = context.pexpect_spawn(
            command, shell=True, timeout=timeout, maxread=maxread, codec_errors="ignore"
        )
        proc.expect([pexpect.EOF])

        if pattern is not None:
            out = [line for line in proc.before.split("\n") if re.search(pattern, line)]
            pattern_text = f'containing pattern "{pattern}"'
        else:
            out = [line for line in proc.before.split("\n") if line]
            pattern_text = ""

        ret = compare_values(condition1["op"], len(out), int(condition1["n_lines"]))
        if condition2 is not None:
            ret &= compare_values(
                condition2["op"], len(out), int(condition2["n_lines"])
            )

        if ret:
            return True

    assert condition2 is None, (
        f"""Command "{command}" {pattern_text} did not return """
        f""" "{condition1['op']}" "{condition1['n_lines']}" """
        f""" and "{condition2['op']}" "{condition2['n_lines']}" lines, """
        f"""but "{len(out)}", output was:\n"""
    ) + "\n".join(out)

    assert False, (
        f"""Command "{command}" {pattern_text} did not return """
        f""" "{condition1['op']}" "{condition1['n_lines']}" lines, but "{len(out)}", output was:\n"""
    ) + "\n".join(out)


@step('Noted value is visible with command "{command}"')
@step('Noted value is visible with command "{command}" in "{seconds}" seconds')
def noted_visible_command(context, command, seconds=2):
    check_pattern_command(
        context, command, context.noted["noted-value"], seconds, check_class="exact"
    )


@step('Noted value is not visible with command "{command}"')
@step('Noted value is not visible with command "{command}" in "{seconds}" seconds')
def noted_not_visible_command(context, command, seconds=2):
    return check_pattern_command(
        context,
        command,
        context.noted["noted-value"],
        seconds,
        check_type="not",
        check_class="exact",
    )


@step('Noted value "{index}" is visible with command "{command}"')
@step(
    'Noted value "{index}" is visible with command "{command}" in "{seconds}" seconds'
)
def noted_index_visible_command(context, command, index, seconds=2):
    return check_pattern_command(
        context, command, context.noted[index], seconds, check_class="exact"
    )


@step('Noted value "{index}" is not visible with command "{command}"')
@step(
    'Noted value "{index}" is not visible with command "{command}" in "{seconds}" seconds'
)
def noted_index_not_visible_command(context, command, index, seconds=2):
    return check_pattern_command(
        context,
        command,
        context.noted[index],
        seconds,
        check_type="not",
        check_class="exact",
    )


@step('"{pattern}" is visible with reproducer "{rname}"')
@step('"{pattern}" is visible with reproducer "{rname}" with options "{options}"')
@step('"{pattern}" is visible with reproducer "{rname}" in "{seconds}" seconds')
@step(
    '"{pattern}" is visible with reproducer "{rname}" with options "{options}" in "{seconds}" seconds'
)
def pattern_visible_reproducer(context, pattern, rname, options="", seconds=2):
    command = get_reproducer_command(rname, options)
    return check_pattern_command(context, command, pattern, seconds)


@step('"{pattern}" is not visible with reproducer "{rname}"')
@step('"{pattern}" is not visible with reproducer "{rname}" with options "{options}"')
@step('"{pattern}" is not visible with reproducer "{rname}" in "{seconds}" seconds')
@step(
    '"{pattern}" is not visible with reproducer "{rname}" with options "{options}" in "{seconds}" seconds'
)
def pattern_visible_reproducer(context, pattern, rname, options="", seconds=2):
    command = get_reproducer_command(rname, options)
    return check_pattern_command(context, command, pattern, seconds, check_type="not")


@step('"{pattern}" is visible with command "{command}"')
@step('"{pattern}" is visible with command "{command}" in "{seconds}" seconds')
def pattern_visible_command(context, command, pattern, seconds=2):
    return check_pattern_command(context, command, pattern, seconds)


@step('"{pattern}" is not visible with command "{command}"')
@step('"{pattern}" is not visible with command "{command}" in "{seconds}" seconds')
def pattern_not_visible_command(context, command, pattern, seconds=2):
    return check_pattern_command(context, command, pattern, seconds, check_type="not")


@step('String "{string}" is visible with command "{command}"')
@step('String "{string}" is visible with command "{command}" in "{seconds}" seconds')
def string_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_class="exact")


@step('String "{string}" is not visible with command "{command}"')
@step(
    'String "{string}" is not visible with command "{command}" in "{seconds}" seconds'
)
def string_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(
        context, command, string, seconds, check_type="not", check_class="exact"
    )


@step('JSON "{string}" is visible with command "{command}"')
@step('JSON "{string}" is visible with command "{command}" in "{seconds}" seconds')
def json_visible_command(context, command, string, seconds=2):
    return check_pattern_command(context, command, string, seconds, check_class="json")


@step('JSON "{string}" is not visible with command "{command}"')
@step('JSON "{string}" is not visible with command "{command}" in "{seconds}" seconds')
def json_not_visible_command(context, command, string, seconds=2):
    return check_pattern_command(
        context, command, string, seconds, check_type="not", check_class="json"
    )


@step(
    'Noted number of lines with pattern "{pattern}" is visible with command "{command}" in "{seconds}" seconds'
)
@step(
    'Noted number of lines "{index}" with pattern "{pattern}" is visible with command "{command}" in "{seconds}" seconds'
)
def noted_lines_visible_command(
    context, command, index="noted-value", seconds=2, pattern=None
):
    return check_lines_command(
        context=context,
        command=command,
        condition1={"n_lines": context.noted[index], "op": "exactly"},
        seconds=seconds,
        pattern=pattern,
    )


@step(
    '"{operator_kw1}" "{n_lines1}" and "{operator_kw2}" "{n_lines2}" lines are visible with command "{command}" in "{seconds}" seconds'
)
@step(
    '"{operator_kw1}" "{n_lines1}" and "{operator_kw2}" "{n_lines2}" lines with pattern "{pattern}" are visible with command "{command}" in "{seconds}" seconds'
)
def range_lines_visible_command(
    context,
    command,
    n_lines1,
    n_lines2,
    operator_kw1,
    operator_kw2,
    seconds=2,
    pattern=None,
):
    return check_lines_command(
        context=context,
        command=command,
        condition1={"n_lines": n_lines1, "op": operator_kw1.lower()},
        condition2={"n_lines": n_lines2, "op": operator_kw2.lower()},
        seconds=seconds,
        pattern=pattern,
    )


@step('"{operator_kw}" "{n_lines}" lines are visible with command "{command}"')
@step(
    '"{operator_kw}" "{n_lines}" lines are visible with command "{command}" in "{seconds}" seconds'
)
@step(
    '"{operator_kw}" "{n_lines}" lines with pattern "{pattern}" are visible with command "{command}"'
)
@step(
    '"{operator_kw}" "{n_lines}" lines with pattern "{pattern}" are visible with command "{command}" in "{seconds}" seconds'
)
def lines_visible_command(
    context, command, n_lines, operator_kw, seconds=2, pattern=None
):
    return check_lines_command(
        context=context,
        command=command,
        condition1={"n_lines": n_lines, "op": operator_kw.lower()},
        seconds=seconds,
        pattern=pattern,
    )


@step('"{pattern}" is visible with command "{command}" for full "{seconds}" seconds')
def check_pattern_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="full")


@step(
    '"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds'
)
def check_pattern_not_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(
        context, command, pattern, seconds, check_type="not_full"
    )


@step('Noted value is visible with command "{command}" for full "{seconds}" seconds')
@step(
    'Noted value "{index}" is visible with command "{command}" for full "{seconds}" seconds'
)
def check_pattern_visible_with_command_fortime(
    context, command, seconds, index="noted_value"
):
    return check_pattern_command(
        context, command, context.noted[index], seconds, check_type="full"
    )


@step(
    'Noted value is not visible with command "{command}" for full "{seconds}" seconds'
)
@step(
    'Noted value "{index}" is not visible with command "{command}" for full "{seconds}" seconds'
)
def check_pattern_not_visible_with_command_fortime(
    context, command, seconds, index="noted_value"
):
    return check_pattern_command(
        context, command, context.noted[index], seconds, check_type="not_full"
    )


@step('"{pattern}" is visible with tab after "{command}"')
def check_pattern_visible_with_tab_after_command(context, pattern, command):
    exp = context.pexpect_spawn("/bin/bash")
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendeof()

    assert (
        exp.expect([pattern, pexpect.EOF]) == 0
    ), 'pattern %s is not visible with "%s"' % (pattern, command)


@step('"{pattern}" is not visible with tab after "{command}"')
def check_pattern_not_visible_with_tab_after_command(context, pattern, command):
    exp = context.pexpect_spawn("/bin/bash")
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendeof()

    assert (
        exp.expect([pattern, pexpect.EOF, pexpect.TIMEOUT]) != 0
    ), 'pattern %s is visible with "%s"' % (pattern, command)


@step('Run child "{command}"')
def run_child_process(context, command):
    nmci.pexpect.pexpect_service(command, shell=True, label="child")


@step('Run child "{command}" without shell')
def run_child_process_no_shell(context, command):
    nmci.pexpect.pexpect_service(command, label="child")


@step("Wait for children")
def wait_for_children(context):
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        child.proc.wait()


@step('Expect "{pattern}" in children in "{seconds}" seconds')
def expect_children(context, pattern, seconds):
    seconds = float(seconds)
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        proc = child.proc
        r = proc.expect(
            [pattern, nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=seconds
        )
        assert (
            r != 1
        ), f"Child {proc.name} exited without '{pattern}' in output:\n{proc.before}"
        assert (
            r != 2
        ), f"Child {proc.name} did not output '{pattern}' within {seconds}s:\n{proc.before}"


@step('Do not expect "{pattern}" in children in "{seconds}" seconds')
def not_expect_children(context, pattern, seconds):
    seconds = float(seconds)
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        proc = child.proc
        r = proc.expect(
            [pattern, nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=seconds
        )
        assert (
            r != 0
        ), f"Child {proc.name} has '{pattern}' in output:\n{proc.before}{proc.after}"


@step("Start following journal")
def start_tailing_journal(context):
    context.journal = context.pexpect_service(
        "sudo journalctl --follow -o cat", timeout=180
    )
    with nmci.util.start_timeout(10) as t:
        while t.loop_sleep(0.2):
            nmci.process.run_stdout("logger nmci_journal_follow")
            if (
                context.journal.expect(
                    ["nmci_journal_follow", nmci.pexpect.TIMEOUT], timeout=0.2
                )
                == 0
            ):
                break


@step('Look for "{content}" in journal')
def find_tailing_journal(context, content):
    if context.journal.expect([content, pexpect.TIMEOUT, pexpect.EOF]) == 1:
        raise Exception(
            'Did not see the "%s" in journal output before timeout (180s)' % content
        )


@step('Wait for "{secs}" seconds')
def wait_for_x_seconds(context, secs):
    time.sleep(float(secs))


@step('Wait for up to "{secs}" random seconds')
def wait_for_x_seconds(context, secs):
    rnd = nmci.util.random_float(3288708979)
    secs = float(secs)
    secs = secs * rnd
    time.sleep(secs)


@step('Look for "{content}" in tailed file')
def find_tailing(context, content):
    assert context.tail.expect([content, pexpect.TIMEOUT, pexpect.EOF]) != 1, (
        'Did not see the "%s" in tail output before timeout (180s)' % content
    )


@step('Start tailing file "{archivo}"')
def start_tailing(context, archivo):
    context.tail = context.pexpect_service("sudo tail -f %s" % archivo, timeout=180)
    time.sleep(0.3)


@step('Ping "{domain}"')
@step('Ping "{domain}" "{number}" times')
def ping_domain(context, domain, number=2):
    if number != 2:
        rc = context.command_code("ping -q -4 -c %s %s" % (number, domain))
    else:
        rc = context.command_code("curl -s %s" % (domain))
    assert rc == 0


@step('Ping "{domain}" from "{device}" device')
def ping_domain_from_device(context, domain, device):
    rc = context.command_code("ping -4 -c 2 -I %s %s" % (device, domain))
    assert rc == 0


@step('Ping6 "{domain}"')
def ping6_domain(context, domain):
    rc = context.command_code("ping6 -c 2 %s" % domain)
    assert rc == 0


@step('Unable to ping "{domain}"')
def cannot_ping_domain(context, domain):
    rc = context.command_code("curl %s" % domain)
    assert rc != 0


@step('Unable to ping "{domain}" from "{device}" device')
def cannot_ping_domain_from_device(context, domain, device):
    assert (
        context.process.run(
            ["ping", "-c", "2", "-I", device, domain], timeout=30
        ).returncode
        != 0
    )


@step('Unable to ping6 "{domain}"')
def cannot_ping6_domain(context, domain):
    assert context.process.run(f"ping6 -c 2 {domain}", timeout=30).returncode != 0


@step('Metered status is "{value}"')
@step('Metered status is "{value}" in "{seconds}" seconds')
def check_metered_status(context, value, seconds=None):
    value = int(value)
    timeout = nmci.util.start_timeout(seconds)
    while timeout.loop_sleep(0.2):
        ret = nmci.nmutil.get_metered()
        if ret == value:
            return
    assert ret == value, f"Metered value is {ret} but should be {value}"


@step('Network trafic "{state}" dropped')
def network_dropped(context, state):
    if state == "is":
        assert context.command_code("ping -c 1 -W 1 boston.com") != 0
    if state == "is not":
        assert context.command_code("ping -c 1 -W 1 boston.com") == 0


@step('Network trafic "{state}" dropped on "{device}"')
def network_dropped_two(context, state, device):
    if state == "is":
        assert context.command_code("ping -c 2 -I %s -W 1 8.8.8.8" % device) != 0
    if state == "is not":
        assert context.command_code("ping -c 2 -I %s -W 1 8.8.8.8" % device) == 0


@step("Send lifetime scapy packet")
@step('Send lifetime scapy packet with "{hlim}"')
@step('Send lifetime scapy packet from "{srcaddr}"')
@step('Send lifetime scapy packet to dst "{prefix}"')
@step('Send lifetime scapy packet with lifetimes "{valid}" "{pref}"')
def send_packet(
    context, srcaddr=None, hlim=None, valid=3600, pref=1800, prefix="fd00:8086:1337::"
):
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
    p /= ICMPv6NDOptPrefixInfo(
        prefix=prefix, prefixlen=64, validlifetime=valid, preferredlifetime=pref
    )
    sendp(p, iface=in_if)
    sendp(p, iface=in_if)

    time.sleep(3)


@step('Set logging for "{domain}" to "{level}"')
def set_logging(context, domain, level):
    if level == " ":
        cli = context.pexpect_spawn("nmcli g l domains %s" % (domain), timeout=60)
    else:
        cli = context.pexpect_spawn(
            "nmcli g l level %s domains %s" % (level, domain), timeout=60
        )

    r = cli.expect(["Error", "Timeout", pexpect.TIMEOUT, pexpect.EOF])
    if r != 3:
        assert False, "Something bad happened when changing log level"


@step("Note NM log")
def note_NM_log(context):
    if not hasattr(context, "noted"):
        context.noted = {}
    context.noted["noted-value"] = nmci.misc.journal_show(
        "NetworkManager", cursor=context.log_cursor, journal_args="-o cat"
    )


@step('Note NM memory consumption as value "{index}"')
def note_NM_mem_consumption(context, index):
    try:
        mem = str(nmci.nmutil.nm_size_kb())
        context.noted[index] = mem
        context.process.run_stdout(f"echo {mem} >> /tmp/mem_consumption", shell=True)
    except nmci.util.ExpectedException as e:
        msg = f"<b>Daemon memory consumption:</b> unknown ({e})\n"


@step('Check coredump is not found in "{seconds}" seconds')
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
        nmci.crash.check_coredump(context)
        assert not nmci.embed.coredump_reported, "Coredump found"


@step('Check "{family}" address list "{expected}" on device "{ifname}"')
@step(
    'Check "{family}" address list "{expected}" on device "{ifname}" in "{seconds}" seconds'
)
def check_address_expect(context, family, expected, ifname, seconds=None):

    if seconds is not None:
        seconds = float(seconds)
    family = nmci.ip.addr_family_norm(family)

    try:
        nmci.ip.address_expect(
            expected=expected,
            ifname=ifname,
            match_mode="auto",
            with_plen=True,
            ignore_order=False,
            ignore_extra=False,
            addr_family=family,
            wait_for_address=seconds,
        )
    finally:
        nmci.process.run_stdout(f"ip -d -{nmci.ip.addr_family_num(family)} route show")


@step('Check "{addr_family}" route list on NM device "{ifname}" matches "{expected}"')
@step(
    'Check "{addr_family}" route list on NM device "{ifname}" matches "{expected}" in "{timeout}" seconds'
)
def check_routes_expect(context, ifname, addr_family, expected, timeout=2):

    addr_family = nmci.ip.addr_family_norm(addr_family)

    timeout = float(timeout)

    def do():

        devices = nmci.nmutil.device_status(name=ifname, get_ipaddrs=True)
        assert len(devices) == 1

        routes = devices[0][f"ip{nmci.ip.addr_family_num(addr_family)}config"][
            "_routes"
        ]

        try:
            nmci.util.compare_strv_list(
                expected,
                routes,
                ignore_extra_strv=False,
                ignore_order=True,
            )
        except ValueError as e:
            raise ValueError(f"List of routes unexpected: {e} (full list: {routes})")

    try:
        nmci.util.wait_for(do, timeout=timeout)
    finally:
        nmci.process.run_stdout(
            f"ip -d -{nmci.ip.addr_family_num(addr_family)} route show table all"
        )


@step("Load nftables")
@step('Load nftables "{ruleset}"')
@step('Load nftables in "{ns}" namespace')
@step('Load nftables "{ruleset}" in "{ns}" namespace')
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
    with open(file, "w") as f:
        f.write(ruleset)
    nft_status = [
        f"nftables ruleset{f' in namespace {ns}' if ns else ''} before this step:"
    ]
    nft_status.append(nft.cmd("list ruleset")[1])
    context.process.run(f"{nsprefix}nft -f {file}")
    nft_status.append(
        f"\nnftables ruleset{f' in namespace {ns}' if ns else ''} after this step:"
    )
    nft_status.append(nft.cmd("list ruleset")[1])
    nmci.embed.embed_data("State of nftables", "\n".join(nft_status), fail_only=True)
    os.remove(file)


@step("Cleanup nftables")
@step('Cleanup nftables in namespace "{ns}"')
def flush_nftables(context, ns=None):
    nmci.cleanup.cleanup_add_nft(ns)


@step('Run tier0 nmstate tests with log in "{log_file}"')
def run_nmstate(context, log_file):
    # Install podman and git clone nmstate
    nmci.veth.wait_for_testeth0()
    nmci.util.directory_remove("nmstate", recursive=True)
    nmci.process.run_stdout(
        "git clone https://github.com/nmstate/nmstate.git",
        ignore_stderr=True,
    )

    # Get environement variables
    release = "el9"
    if int(context.rh_release_num) == 8:
        release = "el8"

    # Create the first part of cmd to execute
    cmd = f"nmstate/automation/run-tests-in-nmci.sh --{release}"

    if os.path.exists("/root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"):
        cmd += (
            " --rpm-dir /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"
        )
    elif os.path.exists(
        "/tmp/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"
    ):
        cmd += (
            " --rpm-dir /root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/"
        )
    elif os.path.exists("/etc/yum.repos.d/nm-copr.repo"):
        with open("/etc/yum.repos.d/nm-copr.repo", "r") as repo:
            for line in repo.readlines():
                if line.startswith("baseurl"):
                    copr = line.split("/")[-4] + "/" + line.split("/")[-3]
                    cmd += f" --copr {copr}"
                    break
    elif (
        nmci.process.run_code(
            "dnf copr list | grep networkmanager/NetworkManager", shell=True
        )
        == 0
    ):
        copr = ""
        copr = nmci.process.run_stdout(
            "dnf copr list | grep networkmanager/NetworkManager | awk -F 'org/' '{print $2}'",
            shell=True,
        ).strip()
        cmd += f" --copr {copr}"
    # Here we have stock packages, let's download them
    else:
        dir_name = "/tmp/nm_stock_pkgs/"
        nmci.util.directory_remove(dir_name, recursive=True)
        os.mkdir(dir_name)
        koji = "koji"
        if "Enterprise" in context.rh_release:
            koji = "brew"
        if "CentOS" in context.rh_release:
            # TODO: what to do here?
            pass
        nmci.process.run_stdout(
            f"wget $(./contrib/utils/{koji}_links.sh '' $(NetworkManager --version | sed 's/-/ /g')) -P {dir_name}",
            ignore_stderr=True,
            shell=True,
            timeout=30,
        )
        cmd += " --rpm-dir /tmp/nm_stock_pkgs/"
    # Add all logging to the logfile
    cmd += f" &> {log_file} </dev/null"

    # And run it
    nmci.process.run_stdout(
        cmd,
        ignore_stderr=True,
        shell=True,
        timeout=1200,
    )


@step('Set sysctl "{sysctl}" to "{value}"')
def set_sysctl(context, sysctl, value):
    nmci.cleanup.cleanup_add_sysctls(sysctl)
    nmci.process.run(["sysctl", "-w", f"{sysctl}={value}"])


@step("Dump status")
def step_dump_status(context):
    nmci.util.dump_status("")


@step("NetworkManager is installed from a copr repo")
def copr_repo_check(context):
    import dnf

    base = dnf.Base()
    base.fill_sack()

    q = base.sack.query()
    i = q.installed()
    i = i.filter(name="NetworkManager")

    repo_name = ""
    for pkg in list(i):
        repo_name = pkg.from_repo
        break

    if "copr" not in repo_name:
        nmci.cext.skip(
            f"NetworkManager not installed from copr repo, REPO: {repo_name}"
        )

    base.read_all_repos()
    repo = base.repos.get(repo_name)
    context.copr_baseurl = repo.remote_location(" ").strip(
        " "
    )  # empty string as argument returns empty string
    assert (
        context.copr_baseurl
    ), f"Failed to set baseurl, `repo.remote_location` reurned '{context.copr_baseurl}'"


@step("Check last copr build is successful")
def check_last_copr_build(context):
    copr_log = "backend.log.gz"
    resp = requests.get(context.copr_baseurl, timeout=60)
    build_list = [
        row.replace("</a", "") for row in resp.text.split(">") if "</a" in row
    ]
    build_list = [row for row in build_list if row.endswith("-NetworkManager")]
    assert build_list, f"No builds found in copr: {context.copr_baseurl}."
    build_list.sort()
    build_list.reverse()

    for build in build_list[:4]:
        backend_url = f"{context.copr_baseurl}/{build}/{copr_log}"
        resp = requests.get(backend_url, timeout=60)
        nmci.embed.embed_link("Copr backend url", [(backend_url, backend_url)])
        nmci.embed.embed_data("Copr backend log", resp.text)
        if resp.status_code == 200:
            break

    assert (
        resp.status_code == 200
    ), f"Unable to retrieve backend log: {resp.status_code} {backend_url}."
    assert (
        "Worker failed build" not in resp.text
    ), f"Latest copr build in {context.copr_baseurl} is failed."
