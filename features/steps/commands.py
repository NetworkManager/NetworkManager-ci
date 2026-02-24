# pylint: disable=unused-argument,line-too-long
import glob
import json
import operator
import os
import pexpect
import re
import requests
import shlex
import subprocess
import time
from behave import step  # pylint: disable=no-name-in-module
import nmci


@step('Autocomplete "{cmd}" in bash and execute')
def autocomplete_command(context, cmd):
    bash = nmci.pexpect.pexpect_spawn("bash")
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
    ), f"Noted values: {context.noted[i1].strip()} != {context.noted[i2].strip()} !"


@step('Check noted values "{i1}" and "{i2}" are not the same')
def check_different_noted_values(context, i1, i2):
    assert (
        context.noted[i1].strip() != context.noted[i2].strip()
    ), f"Noted values: {context.noted[i1].strip()} == {context.noted[i2].strip()} !"


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


# ===================================================================
# COMMAND EXECUTION
# ===================================================================


@step('Execute "{command}"')
def execute_command(context, command):
    command = nmci.misc.str_replace_dict(command, context.noted)
    nmci.process.run_stdout(
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
    # Emebed reproducer file
    nmci.embed.embed_file_if_exists(rname, argv[0])
    nm_pid_refresh_count = getattr(context, "nm_pid_refresh_count", 0)
    for i in range(int(number)):
        nmci.process.run_stdout(argv, timeout=180, ignore_stderr=True)
        if nm_pid_refresh_count < 1:
            curr_nm_pid = nmci.nmutil.nm_pid()
            assert (
                curr_nm_pid == orig_nm_pid
            ), f"NM crashed as original pid was {orig_nm_pid} but now is {curr_nm_pid}"
        # log mem after each repro exec in stable_mem tests
        if hasattr(context, "nm_valgrind_proc"):
            nmci.nmutil.nm_size_kb()


@step('Execute "{command}" without waiting for process to finish')
def execute_command_nowait(context, command):
    nmci.pexpect.pexpect_service(command, shell=True)


@step('Execute "{command}" without output redirect')
def execute_command_noout(context, command):
    nmci.process.run(command, stdout=None, stderr=None)


@step('Execute "{command}" for "{number}" times')
def execute_multiple_times(context, command, number):
    orig_nm_pid = nmci.nmutil.nm_pid()

    i = 0
    while i < int(number):
        nmci.process.run(command, shell=True)
        curr_nm_pid = nmci.nmutil.nm_pid()
        assert (
            curr_nm_pid == orig_nm_pid
        ), f"NM crashed as original pid was {orig_nm_pid} but now is {curr_nm_pid}"
        i += 1


# ===================================================================
# PROCESS MANAGEMENT
# ===================================================================


@step('Terminate "{process}"')
@step('Terminate "{process}" with signal "{signal}"')
@step('Terminate all processes named "{process}"')
@step('Terminate all processes named "{process}" with signal "{signal}"')
def pkill_process(context, process, signal="TERM"):
    pids = " ".join(nmci.process.run_stdout(f"pgrep {process}").split("\n"))
    nmci.process.run_stdout(f"/usr/bin/kill -{signal} {pids}")
    ticks = 25  # 5 seconds
    while ticks > 0:
        # This works for multiple pids, because kill would return 0
        # if it could signal *any* of the pids
        if (
            nmci.process.run(f"/usr/bin/kill -0 {pids}", ignore_stderr=True).returncode
            == 1
        ):
            return True
        ticks = ticks - 1
        time.sleep(0.2)
    raise Exception(f"Not all processed {pids} terminated on time")


@step('"{command}" fails')
def wait_for_process(context, command):
    assert nmci.process.run(command, ignore_stderr=True, shell=True).returncode != 0
    time.sleep(0.1)


@step("Restore hostname from the noted value")
def restore_hostname(context):
    nmci.process.run(f"hostname {context.noted['noted-value']}", shell=True)
    time.sleep(0.5)


@step('Hostname is visible in log "{log}"')
@step('Hostname is visible in log "{log}" in "{seconds}" seconds')
def hostname_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = f"grep $(hostname -s) '{log}'"
    while seconds > 0:
        if nmci.process.run(cmd, shell=True).returncode == 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception(f"Hostname not visible in log in {orig_seconds} seconds")


@step('Hostname is not visible in log "{log}"')
@step('Hostname is not visible in log "{log}" for full "{seconds}" seconds')
def hostname_not_visible(context, log, seconds=1):
    seconds = int(seconds)
    orig_seconds = seconds
    cmd = f"grep $(hostname -s) '{log}'"
    while seconds > 0:
        if nmci.process.run(cmd, shell=True).returncode != 0:
            return True
        seconds = seconds - 1
        time.sleep(1)
    raise Exception(f"Hostname visible in log after {orig_seconds - seconds} seconds")


# ===================================================================
# NAMESERVER AND DOMAIN MANAGEMENT
# ===================================================================


@step('Nameserver "{server}" is set')
@step('Nameserver "{server}" is set in "{seconds}" seconds')
@step('Domain "{server}" is set')
@step('Domain "{server}" is set in "{seconds}" seconds')
@step('DNS option "{server}" is set')
@step('DNS option "{server}" is set in "{seconds}" seconds')
def get_nameserver_or_domain(context, server, seconds=1):
    if (
        nmci.process.run(
            "systemctl is-active systemd-resolved.service -q", shell=True
        ).returncode
        == 0
    ):
        # We have systemd-resolvd running
        cmd = "resolvectl dns; resolvectl domain"
    else:
        cmd = "cat /etc/resolv.conf"
    return check_pattern_command(context, cmd, server, seconds)


@step('Nameserver "{server}" is not set')
@step('Nameserver "{server}" is not set in "{seconds}" seconds')
@step('Domain "{server}" is not set')
@step('Domain "{server}" is not set in "{seconds}" seconds')
@step('DNS option "{server}" is not set')
@step('DNS option "{server}" is not set in "{seconds}" seconds')
def get_nameserver_or_domain_not(context, server, seconds=1):
    if nmci.process.systemctl("is-active systemd-resolved.service -q").returncode == 0:
        # We have systemd-resolvd running
        cmd = "systemd-resolve --status |grep -A 100 Link"
    else:
        cmd = "cat /etc/resolv.conf"
    return check_pattern_command(context, cmd, server, seconds, check_type="not")


# ===================================================================
# NOTED VALUES AND PATTERN MATCHING
# ===================================================================


@step('Noted value contains "{pattern}"')
@step('Noted value "{index}" contains "{pattern}"')
def noted_value_contains(context, pattern, index="noted-value"):
    assert (
        re.search(pattern, context.noted[index]) is not None
    ), f"Noted value '{context.noted[index]}' does not match the pattern '{pattern}'!"


@step('Noted value does not contain "{pattern}"')
@step('Noted value "{index}" does not contain "{pattern}"')
def noted_value_does_not_contain(context, pattern, index="noted-value"):
    assert (
        re.search(pattern, context.noted[index]) is None
    ), f"Noted value '{context.noted[index]}' does match the pattern '{pattern}'!"


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
    out = nmci.process.run_stdout(command, ignore_stderr=True, shell=True)
    if pattern is not None:
        out = [line for line in out.split("\n") if re.search(pattern, line)]
    else:
        out = [line for line in out.split("\n") if line]
    nmci.embed.embed_data(
        "Noted", f"[{index}] counted {len(out)} lines ({out})", fail_only=True
    )
    context.noted[index] = str(len(out))


# ===================================================================
# PATTERN AND COMMAND CHECKING UTILITIES
# ===================================================================


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

    pattern = nmci.misc.str_replace_dict(pattern, getattr(context, "noted", {}))
    command = nmci.misc.str_replace_dict(command, getattr(context, "noted", {}))

    while xtimeout.loop_sleep(interval):
        stdout = nmci.process.run_stdout(
            command,
            shell=True,
            ignore_returncode=True,
            ignore_stderr=True,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )
        if check_class == "exact":
            ret = 0 if pattern in stdout else 1
        elif check_class == "json":

            def obj_contains_all(needle, haystack):
                """
                Check if needle is "sub-object" of haystack, meaning
                needle must be fully contained in haystack,
                however haystack can contain someting more.

                Corenr case: list - this tries to ignore the order,
                but it searches for first match, so beware of generic needles:
                [{}, {"a":1}] is not found in [{"a":1}, {}], because
                first elements are matched ({} is sub-object of {"a":1}),
                however second objects no longer match. So, {} in the needle
                is too generic to match and might result in unexpected behaviour.
                """

                if isinstance(needle, str) or isinstance(needle, int):
                    return 0 if needle == haystack else 1
                if isinstance(needle, list):
                    if not isinstance(haystack, list):
                        return 1
                    hs = haystack.copy()
                    for i in needle:
                        found = False
                        for j in hs:
                            if obj_contains_all(i, j) == 0:
                                hs.remove(j)
                                found = True
                                break
                        if not found:
                            return 1
                    return 0
                if isinstance(needle, dict):
                    if not isinstance(haystack, dict):
                        return 1
                    for i in needle:
                        if i in haystack:
                            r = obj_contains_all(needle[i], haystack[i])
                            if r != 0:
                                return r
                        else:
                            return 1
                    return 0

            pattern_j = json.loads(pattern)
            stdout_j = json.loads(stdout)
            ret = obj_contains_all(pattern_j, stdout_j)
        else:
            ret = (
                0
                if re.search(pattern, stdout, flags=re.MULTILINE | re.DOTALL)
                is not None
                else 1
            )
        if check_type == "default":
            if ret == 0:
                return True
        elif check_type == "not":
            if ret != 0:
                return True
        elif check_type == "full":
            assert (
                ret == 0
            ), f'Pattern "{pattern}" disappeared after {nmci.misc.format_duration(xtimeout.elapsed_time())} seconds, output was:\n{stdout}'
        elif check_type == "not_full":
            assert (
                ret != 0
            ), f'Pattern "{pattern}" appeared after {nmci.misc.format_duration(xtimeout.elapsed_time())} seconds, output was:\n{stdout}'
    if check_type == "default":
        assert (
            False
        ), f'Did not see the pattern "{pattern}" in {nmci.misc.format_duration(seconds)} seconds, output was:\n{stdout}'
    elif check_type == "not":
        assert (
            False
        ), f'Did still see the pattern "{pattern}" in {nmci.misc.format_duration(seconds)} seconds, output was:\n{stdout}'


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
        f'Invalid operator keyword: "{keyword}", supported operators are:\n     '
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
        stdout = nmci.process.run_stdout(
            command,
            shell=True,
            ignore_returncode=True,
            ignore_stderr=True,
            stderr=subprocess.STDOUT,
            timeout=timeout,
        )

        if pattern is not None:
            out = [line for line in stdout.split("\n") if re.search(pattern, line)]
            pattern_text = f'containing pattern "{pattern}"'
        else:
            out = [line for line in stdout.split("\n") if line]
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
        f""" "{condition1["op"]}" "{condition1["n_lines"]}" """
        f""" and "{condition2["op"]}" "{condition2["n_lines"]}" lines, """
        f"""but "{len(out)}", output was:\n"""
    ) + "\n".join(out)

    assert False, (
        f"""Command "{command}" {pattern_text} did not return """
        f""" "{condition1["op"]}" "{condition1["n_lines"]}" lines, but "{len(out)}", output was:\n"""
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
def pattern_not_visible_reproducer(context, pattern, rname, options="", seconds=2):
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
def pattern_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(context, command, pattern, seconds, check_type="full")


@step(
    '"{pattern}" is not visible with command "{command}" for full "{seconds}" seconds'
)
def pattern_not_visible_with_command_fortime(context, pattern, command, seconds):
    return check_pattern_command(
        context, command, pattern, seconds, check_type="not_full"
    )


@step('Noted value is visible with command "{command}" for full "{seconds}" seconds')
@step(
    'Noted value "{index}" is visible with command "{command}" for full "{seconds}" seconds'
)
def noted_value_visible_with_command_fortime(
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
def noted_value_not_visible_with_command_fortime(
    context, command, seconds, index="noted_value"
):
    return check_pattern_command(
        context, command, context.noted[index], seconds, check_type="not_full"
    )


@step('"{pattern}" is visible with tab after "{command}"')
def pattern_visible_with_tab_after_command(context, pattern, command):
    exp = nmci.pexpect.pexpect_spawn("/bin/bash")
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendeof()

    assert (
        exp.expect([pattern, pexpect.EOF], timeout=5) == 0
    ), f'pattern {pattern} is not visible with "{command}"'


@step('"{pattern}" is not visible with tab after "{command}"')
def pattern_not_visible_with_tab_after_command(context, pattern, command):
    exp = nmci.pexpect.pexpect_spawn("/bin/bash")
    exp.send("bind 'set page-completions Off' ;\n")
    exp.send("bind 'set completion-query-items 0' ;\n")
    exp.send(command)
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendcontrol("i")
    exp.sendeof()

    assert (
        exp.expect([pattern, pexpect.EOF, pexpect.TIMEOUT], timeout=5) != 0
    ), f'pattern {pattern} is visible with "{command}"'


@step('Run child "{command}"')
def run_child_process(context, command):
    command = nmci.misc.str_replace_dict(command, context.noted)
    nmci.pexpect.pexpect_service(command, shell=True, label="child")


@step('Run child "{command}" without shell')
def run_child_process_no_shell(context, command):
    nmci.pexpect.pexpect_service(command, label="child")


@step("Wait for children")
def wait_for_children(context):
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        child.proc.wait()


@step('Expect "{pattern}" in children in "{seconds}" seconds')
def expect_children(context, pattern, seconds, proc_action=None):
    seconds = float(seconds)
    pattern = nmci.misc.str_replace_dict(pattern, context.noted)
    for child in nmci.pexpect.pexpect_service_find_all("child", running_only=True):
        # print(f"expect in {child.proc.pid} {child.proc.isalive()}")
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
        if proc_action is not None:
            proc_action(proc)


@step('Do not expect "{pattern}" in children in "{seconds}" seconds')
def not_expect_children(context, pattern, seconds):
    seconds = float(seconds)
    pattern = nmci.misc.str_replace_dict(pattern, context.noted)
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        proc = child.proc
        r = proc.expect(
            [pattern, nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=seconds
        )
        assert (
            r != 0
        ), f"Child {proc.name} has '{pattern}' in output:\n{proc.before}{proc.after}"


@step('Expect "{pattern}" in children in "{seconds}" seconds and kill')
@step(
    'Expect "{pattern}" in children in "{seconds}" seconds and kill with signal "{signal}"'
)
def expect_children_kill(context, pattern, seconds, signal=15):
    signal = int(signal)
    expect_children(context, pattern, seconds, lambda p: p.kill(signal))


@step("Kill children")
@step('Kill children with signal "{signal}"')
def kill_children(context, signal=9):
    for child in nmci.pexpect.pexpect_service_find_all("child"):
        # print(f"before kill {child.proc.pid} {child.proc.isalive()}")
        child.proc.kill(int(signal))
        # print(f"after kill {child.proc.pid} {child.proc.isalive()}")


@step("Start following journal")
def start_tailing_journal(context):
    context.journal = nmci.pexpect.pexpect_service(
        "journalctl --follow -o cat", timeout=180
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


@step('"{content}" is visible in journal')
@step('"{content}" is visible in journal in "{timeout}" seconds')
def find_in_tailing_journal(context, content, timeout=180):
    if (
        context.journal.expect(
            [content, pexpect.TIMEOUT, pexpect.EOF], timeout=float(timeout)
        )
        == 1
    ):
        raise Exception(
            f'Did not see the "{content}" in journal output before timeout ("{timeout}" seconds)'
        )


@step('"{content}" is not visible in journal')
@step('"{content}" is not visible in journal in "{timeout}" seconds')
def find_not_in_tailing_journal(context, content, timeout=2):
    if (
        context.journal.expect(
            [content, pexpect.TIMEOUT, pexpect.EOF], timeout=float(timeout)
        )
        == 0
    ):
        raise Exception(f'"{content}" was found in the journal output.')


@step('Start monitoring "{proc}" CPU usage with threshold "{thr}"')
def start_cpu_proc_monitor(context, proc, thr):
    context.proc_mon = getattr(context, "proc_mon", {})
    context.proc_mon[proc] = nmci.pexpect.pexpect_service(
        f"nmci/helpers/proc_cpu_usage_monitor.py {proc} {thr}"
    )


@step('NM was not using more than "{perc}%" of CPU')
def nm_cpu_usage(context, perc):
    perc = float(perc)
    context.proc_mon["NetworkManager"].kill(10)
    context.journal.expect("Average NetworkManager usage: [0-9.]*")
    msg = context.journal.after
    used_perc = float(msg.split(" ")[-1])
    assert used_perc <= perc, f"NM was using {used_perc}% of CPU, threshold {perc}%"


@step('Wait for "{secs}" seconds')
def wait_for_x_seconds(context, secs):
    time.sleep(float(secs))


@step('Wait for up to "{secs}" random seconds')
def wait_for_random_seconds(context, secs):
    rnd = nmci.util.random_float(3288708979)
    secs = float(secs)
    secs = secs * rnd
    time.sleep(secs)


@step('Look for "{content}" in tailed file')
def find_tailing(context, content):
    assert (
        context.tail.expect([content, pexpect.TIMEOUT, pexpect.EOF]) != 1
    ), f'Did not see the "{content}" in tail output before timeout (180s)'


@step('Start tailing file "{archivo}"')
def start_tailing(context, archivo):
    context.tail = nmci.pexpect.pexpect_service(f"tail -f {archivo}", timeout=180)
    time.sleep(0.3)


@step('Ping "{domain}"')
@step('Ping "{domain}" "{number}" times')
def ping_domain(context, domain, number=2):
    if number != 2:
        rc = nmci.process.run(
            f"ping -q -4 -c {number} {domain}",
            timeout=30,
            ignore_stderr=True,
        ).returncode
    else:
        rc = nmci.process.run(f"curl -s {domain}", timeout=30).returncode
    assert rc == 0


@step('Ping "{domain}" from "{device}" device')
def ping_domain_from_device(context, domain, device):
    rc = nmci.process.run(
        f"ping -4 -c 2 -I {device} {domain}", ignore_stderr=True
    ).returncode
    assert rc == 0


@step('Ping6 "{domain}"')
def ping6_domain(context, domain):
    rc = nmci.process.run(
        f"ping6 -c 2 {domain}", timeout=30, ignore_stderr=True
    ).returncode
    assert rc == 0


@step('Unable to ping "{domain}"')
def cannot_ping_domain(context, domain):
    rc = nmci.process.run(f"curl {domain}", timeout=30, ignore_stderr=True).returncode
    assert rc != 0


@step('Unable to ping "{domain}" from "{device}" device')
def cannot_ping_domain_from_device(context, domain, device):
    assert (
        nmci.process.run(
            ["ping", "-c", "2", "-I", device, domain],
            timeout=30,
            ignore_stderr=True,
        ).returncode
        != 0
    )


@step('Unable to ping6 "{domain}"')
def cannot_ping6_domain(context, domain):
    assert (
        nmci.process.run(
            f"ping6 -c 2 {domain}", timeout=30, ignore_stderr=True
        ).returncode
        != 0
    )


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
        assert (
            nmci.process.run("ping -c 1 -W 1 boston.com", ignore_stderr=True).returncode
            != 0
        )
    if state == "is not":
        assert (
            nmci.process.run("ping -c 1 -W 1 boston.com", ignore_stderr=True).returncode
            == 0
        )


@step('Network trafic "{state}" dropped on "{device}"')
def network_dropped_two(context, state, device):
    if state == "is":
        assert nmci.process.run(f"ping -c 2 -I {device} -W 1 8.8.8.8").returncode != 0
    if state == "is not":
        assert nmci.process.run(f"ping -c 2 -I {device} -W 1 8.8.8.8").returncode == 0


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
        cli = nmci.pexpect.pexpect_spawn(f"nmcli g l domains {domain}", timeout=60)
    else:
        cli = nmci.pexpect.pexpect_spawn(
            f"nmcli g l level {level} domains {domain}", timeout=60
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
    except nmci.util.ExpectedException as e:
        print(f"<b>Daemon memory consumption:</b> unknown ({e})")


@step(
    'Check NM memory consumption difference from "{i1}" is "{operator_kw}" "{dif}" in "{seconds}" seconds'
)
def check_NM_mem_consumption(context, i1, operator_kw, dif, seconds):
    with nmci.util.start_timeout(
        float(seconds), f"NM mem not in range in {seconds}s"
    ) as t:
        while t.loop_sleep(1):
            mem = nmci.nmutil.nm_size_kb()
            real_dif = mem - int(context.noted[i1].strip())
            if compare_values(operator_kw.lower(), real_dif, int(dif)):
                break


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
    nmci.process.run_stdout("pkill -SIGSEGV NetworkManager")

    # check if coredump is found
    timeout = nmci.util.start_timeout(seconds)
    while timeout.loop_sleep(0.5):
        nmci.crash.check_coredump(context)
        assert not nmci.embed.coredump_reported, "Coredump found"


@step('Check "{family}" address list "{expected}" on device "{ifname}"')
@step(
    'Check "{family}" address list "{expected}" on device "{ifname}" in "{seconds}" seconds'
)
@step('Check there are no "{family}" addresses on device "{ifname}"')
@step(
    'Check there are no "{family}" addresses on device "{ifname}" in "{seconds}" seconds'
)
def check_address_expect(context, family, ifname, expected=[], seconds=None):
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

    if expected in context.noted:
        expected = context.noted[expected]

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
            raise ValueError(f"List of routes unexpected: {e}")

    try:
        nmci.util.wait_for(do, timeout=timeout)
    finally:
        nmci.process.run_stdout(
            f"ip -d -{nmci.ip.addr_family_num(addr_family)} route show table all",
            timeout=60,
        )


@step('Note "{addr_family}" routes on NM device "{ifname}" as value "{index}"')
def note_routes_on_device(context, addr_family, ifname, index):
    addr_family = nmci.ip.addr_family_norm(addr_family)
    devices = nmci.nmutil.device_status(name=ifname, get_ipaddrs=True)
    assert len(devices) == 1

    routes = devices[0][f"ip{nmci.ip.addr_family_num(addr_family)}config"]["_routes"]

    context.noted[index] = routes
    nmci.embed.embed_data(f"Noted `{index}`", "\n".join(routes))


@step('Note "{addr_family}" routes on interface "{ifname}" as value "{index}"')
def note_routes_on_interface(context, addr_family, ifname, index):
    addr_family = nmci.ip.addr_family_norm(addr_family)
    routes = nmci.ip.route_show(ifname=ifname, addr_family=addr_family)
    routes_list = [f"{r} {routes[r]['metric']}" for r in routes if r != "default"]
    if "default" in routes:
        defroute = nmci.ip.addr_zero(addr_family, with_plen=True)
        via_addr = routes["default"]["via"]
        metric = routes["default"]["metric"]
        routes_list.append(f"{defroute} {via_addr} {metric}")
    context.noted[index] = routes_list
    nmci.embed.embed_data(f"Noted `{index}`", "\n".join(routes_list))


@step("Load nftables")
@step('Load nftables "{ruleset}"')
@step('Load nftables in "{ns}" namespace')
@step('Load nftables "{ruleset}" in "{ns}" namespace')
def load_nftables(context, ns=None, ruleset=None):
    import nftables
    from pyroute2 import netns

    if ruleset is None:
        ruleset = context.text

    nmci.cleanup.add_nft(ns)
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
    nmci.process.run(f"{nsprefix}nft -f {file}")
    nft_status.append(
        f"\nnftables ruleset{f' in namespace {ns}' if ns else ''} after this step:"
    )
    nft_status.append(nft.cmd("list ruleset")[1])
    nmci.embed.embed_data("State of nftables", "\n".join(nft_status), fail_only=True)
    os.remove(file)


@step('Cleanup file "{pattern}"')
def cleanup_files(context, pattern):
    nmci.cleanup.add_file(glob=pattern)


@step("Cleanup nftables")
@step('Cleanup nftables in namespace "{ns}"')
def flush_nftables(context, ns=None):
    nmci.cleanup.add_nft(ns)


@step("Cleanup execute")
@step('Cleanup execute "{command}"')
@step('Cleanup execute with timeout "{timeout}" seconds')
@step('Cleanup execute "{command}" with timeout "{timeout}" seconds')
@step('Cleanup execute "{command}" with priority "{priority}"')
@step(
    'Cleanup execute "{command}" with timeout "{timeout}" seconds and priority "{priority}"'
)
def cleanup_execute(context, command=None, timeout=5, priority=None):
    if command is None:
        command = context.text
    callbacks = lambda: nmci.process.run(
        command, ignore_stderr=True, shell=True, timeout=timeout
    )
    if priority is not None:
        priority = int(priority)
    else:
        priority = nmci.Cleanup.PRIORITY_CALLBACK_DEFAULT
    nmci.cleanup.add_callback(
        name="cleanup-execute",
        callback=callbacks,
        priority=priority,
    )


@step('Run tier0 nmstate tests with log in "{log_file}"')
def run_nmstate(context, log_file):
    # Install podman and git clone nmstate
    nmci.veth.wait_for_testeth0()
    nmci.util.directory_remove("/tmp/nmstate", recursive=True)
    # Use temporary repo to try some changes in dnf
    nmci.process.run_stdout(
        "git clone https://github.com/nmstate/nmstate.git /tmp/nmstate",
        ignore_stderr=True,
        timeout=20,
    )

    # Get environement variables
    release = "el9"
    if context.rh_release_num[0] == 8:
        release = "el8"
    if context.rh_release_num[0] == 10:
        release = "el10"
    if "fedora" in context.rh_release.lower():
        release = "fed"
    if "rawhide" in context.rh_release.lower():
        release = "rawhide"

    # Create the first part of cmd to execute
    cmd = f"/tmp/nmstate/automation/run-tests-in-nmci.sh --{release}"

    rpm_dir = ""
    for path in [
        "/root/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/",
        "/tmp/nm-build/NetworkManager/contrib/fedora/rpm/latest0/RPMS/",
        "/root/rpms/",
    ]:
        if os.path.exists(path):
            rpm_dir = f" --rpm-dir {path}"
            break
    if rpm_dir:
        cmd += rpm_dir
    elif os.path.exists("/etc/yum.repos.d/nm-copr.repo"):
        with open("/etc/yum.repos.d/nm-copr.repo", "r") as repo:
            for line in repo.readlines():
                if line.startswith("baseurl"):
                    copr = line.split("/")[-4] + "/" + line.split("/")[-3]
                    cmd += f" --copr {copr}"
                    break
    elif (
        nmci.process.dnf(
            "copr list | grep networkmanager/NetworkManager",
            shell=True,
            ignore_returncode=True,
            ignore_stderr=True,
            attempts=1,
        ).returncode
        == 0
    ):
        copr = nmci.process.dnf(
            "copr list | grep networkmanager/NetworkManager | grep -v libreswan | awk -F 'org/' '{print $2}'",
            shell=True,
            ignore_stderr=True,
            ignore_returncode=True,
            attempts=1,
        ).stdout.strip()
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
            f"wget --tries=5 --retry-connrefused --retry-on-http-error=404,500,502 --waitretry=2 $(./contrib/utils/{koji}_links.sh '' $(NetworkManager --version | sed 's/-/ /g')) -P {dir_name}",
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
        timeout=2000,
    )


@step('Set sysctl "{sysctl}" to "{value}"')
def set_sysctl(context, sysctl, value):
    nmci.cleanup.add_sysctls(sysctl)
    nmci.process.run(["sysctl", "-w", f"{sysctl}={value}"])


@step("Dump status")
def step_dump_status(context):
    nmci.util.dump_status("")


@step("NetworkManager is installed from a copr repo")
def copr_repo_check(context):
    repo_name = nmci.process.run_stdout(
        ["python3", "contrib/dnf/NetworkManager_repo.py"]
    ).strip()

    if "copr" not in repo_name:
        nmci.cext.skip(
            f"NetworkManager not installed from copr repo, REPO: {repo_name}"
        )

    context.copr_baseurl = nmci.process.run_stdout(
        ["python3", "contrib/dnf/repo_url.py", repo_name]
    ).strip()
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


@step("Skip if next step fails:")
def skip_if(context):
    # Do the check in the second after_step() call,
    # the first call is after_step() of this step.
    context.skip_check_count = 2


@step('Ensure that version of "{package}" package is at least')
def check_pkg_version_table(context, package):
    d_ver = []
    ver = ""
    for row in context.table:
        version, distro = row[0], row[1]
        if distro.startswith("rhel"):
            if "Enterprise Linux" not in context.rh_release:
                continue
            d = [int(x) for x in distro.replace("rhel", "").split(".")]
            d = [x for x, y in zip(d, context.rh_release_num) if x == y]
            # apply when matched prefix is longer
            if len(d) > len(d_ver):
                d_ver = d
                ver = version
        elif distro.startswith("c"):
            if "CentOS Stream" not in context.rh_release:
                continue
            d_ver = int(
                distro.replace("centos", "")
                .replace("c", "")
                .replace("stream", "")
                .replace("s", "")
            )
            if d_ver != context.rh_release_num[0]:
                continue
            ver = version
        elif distro in ["fedora", "rawhide"]:
            if "Fedora" not in context.rh_release:
                continue
            ver = version
        else:
            assert False, f"Unsupported distribution: {distro}."

    if ver:
        print("Will ensure", package, ver)
        check_package_version(context, package, ver)
    else:
        print("No distro matched")


@step('Ensure that version of "{package}" package is at least "{version}"')
@step(
    'Ensure that version of "{package}" package is at least "{version}" on "{distro}"'
)
def check_package_version(context, package, version, distro=None):
    # when these packages are updated/downgraded, NM is restarted
    PKGS_REQUIRE_NM_RESTART = ["NetworkManager-libreswan", "libndp"]

    if distro is not None:
        distro = distro.lower().replace("-", "")
        if distro.startswith("rhel"):
            if "Enterprise Linux" not in context.rh_release:
                nmci.embed.embed_data(
                    "Not upgrading",
                    f"Distro mismatch, not on {distro}:\n{context.rh_release}",
                )
                return
            d_ver = [int(x) for x in distro.replace("rhel", "").split(".")]
        elif distro.startswith("c"):
            if "CentOS Stream" not in context.rh_release:
                nmci.embed.embed_data(
                    "Not upgrading",
                    f"Distro mismatch, not on {distro}:\n{context.rh_release}",
                )
                return
            d_ver = [
                int(
                    distro.replace("centos", "")
                    .replace("c", "")
                    .replace("stream", "")
                    .replace("s", "")
                ),
                99,
            ]
        elif distro in ["fedora", "rawhide"]:
            if "Fedora" not in context.rh_release:
                nmci.embed.embed_data(
                    "Not upgrading",
                    f"Distro mismatch, not on {distro}:\n{context.rh_release}",
                )
                return
            d_ver = []
        else:
            assert False, f"Unsupported distribution: {distro}."
        for v1, v2 in zip(d_ver, context.rh_release_num):
            if v1 != v2:
                nmci.embed.embed_data(
                    "Not upgrading",
                    f"Distro version mismatch, not on {distro}:\n{context.rh_release}",
                )
                return

    # if version was passed as '1.27.4-1.el9', replace '-' with ' '
    if "-" in version:
        version = version.replace("-", " ")
    # do the same for the current version extracted via rpm
    current_version = nmci.process.run_stdout(
        f"rpm -q {package} --qf '%{{VERSION}} %{{RELEASE}}'"
    ).strip()
    # if version > current_version, upgrade the package
    if (
        int(
            nmci.process.run_stdout(
                f'''rpm --eval "%{{lua:print(rpm.vercmp('{version}', '{current_version}'))}}"'''
            )
        )
        > 0
    ):
        repo = "brew"
        # sswitch to koji(hub) on Fedora or CentOS stream
        if len(context.rh_release_num) == 1 or context.rh_release_num[1] == 99:
            repo = "koji"
        packages = nmci.process.run_stdout(
            f"timeout 10 contrib/utils/{repo}_links.sh {package} {version}",
            ignore_stderr=True,
            ignore_returncode=True,
            timeout=15,
        ).replace("\n", " ")
        if not packages:
            nmci.cext.skip(
                f'Version "{version}" of package "{package}" is not present among available packages'
            )
        nmci.process.dnf(
            f"upgrade --nobest {packages} -y",
        )
        nmci.cleanup.add_callback(
            name="cleanup-execute",
            callback=lambda: nmci.process.dnf(
                f"downgrade $(contrib/utils/{repo}_links.sh {package} {current_version}) -y",
                shell=True,
            ),
            priority=nmci.Cleanup.PRIORITY_FILE,
        )

        # restart NM and cleanup restart NM if package requires it
        if package in PKGS_REQUIRE_NM_RESTART:
            nmci.nmutil.restart_NM_service()
            nmci.cleanup.add_NM_service(operation="restart")


@step('DNF "{cmd}"')
def dnf(context, cmd):
    nmci.process.dnf(cmd)


@step('"{action}" Image Mode')
def image_mode_toggle(context, action):
    mode = None
    if action.lower() == "lock":
        mode = "ro"
    elif action.lower() == "unlock":
        mode = "rw"
    else:
        assert False, f"unrecognized action: {action}"
    with open("/proc/cmdline") as f:
        image_mode = "ostree" in f.read()
    if image_mode:
        # register cleanup to unlock and lock image during after scenario, set unique-tag to string to execute it only once
        nmci.cleanup.add_callback(
            lambda: nmci.process.run(f"mount -o remount,rw lazy /usr"),
            "image-mode-unlock",
            unique_tag=f"image-mode-unlock",
            priority=nmci.cleanup.Cleanup.PRIORITY_TAG - 1,
        )
        nmci.cleanup.add_callback(
            lambda: nmci.process.run(f"mount -o remount,ro lazy /usr"),
            "image-mode-lock",
            unique_tag=f"image-mode-lock",
            priority=nmci.cleanup.Cleanup.PRIORITY_FILE + 1,
        )
        nmci.process.run(f"mount -o remount,{mode} lazy /usr")


@step('Expect AVC "{pattern}"')
@step('Expect AVC "{pattern}" in "{timeout}" seconds')
def expect_avc(context, pattern, timeout=15):
    timeout = float(timeout)
    nmci.misc.get_avcs(re.compile(pattern), timeout=timeout)


@step('Ignore possible AVC "{pattern}"')
@step('Ignore possible AVC "{pattern}" in "{timeout}" seconds')
@step('Ignore possible AVC "{pattern}" on "{distro}"')
def ignore_avc(context, pattern, timeout=15, distro=None):
    if distro is not None:
        if distro.startswith("rhel"):
            if "Enterprise Linux" not in context.rh_release:
                return
            d_ver = [int(x) for x in distro.replace("rhel", "").split(".")]
            d_equal = [x for x, y in zip(d_ver, context.rh_release_num) if x == y]
            # apply when matched prefix is longer or equal
            if len(d_ver) > len(d_equal):
                return
        elif distro.startswith("c"):
            if "CentOS Stream" not in context.rh_release:
                return
            d_ver = int(
                distro.replace("centos", "")
                .replace("c", "")
                .replace("stream", "")
                .replace("s", "")
            )
            if d_ver != context.rh_release_num[0]:
                return
        elif distro in ["fedora", "rawhide"]:
            if "Fedora" not in context.rh_release:
                return
        else:
            assert False, f"Unsupported distribution: {distro}."

    context.ignore_avcs = getattr(context, "ignore_avcs", [])
    context.ignore_avcs.append(pattern)
    timeout = float(timeout)
    try:
        nmci.misc.get_avcs(re.compile(pattern), timeout=timeout)
    except AssertionError:
        nmci.embed.embed_exception("No AVC matched")


@step('Set global DNS config via busctl to "{value}"')
def busctl_global_dns_set(context, value):
    cmd = [
        "busctl",
        "set-property",
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager",
        "org.freedesktop.NetworkManager",
        "GlobalDnsConfiguration",
    ]
    nmci.cleanup.add_callback(
        lambda: nmci.process.run([*cmd, "a{sv}", "0"]),
        name="reset-dns-global-config-via-busctl",
        # we need to call this once, even if the step is executed multiple times
        unique_tag="GLOBAL_DNS_RESET",
        # do cleanup after NM is restarted after config drop
        priority=nmci.cleanup.Cleanup.PRIORITY_NM_SERVICE_RESTART + 1,
    )
    nmci.process.run([*cmd, *value.split()])


@step(
    'Set global DNS config via dbus to "{domains}" domains, "{searches}" searches, "{options}" options'
)
def dbus_global_dns_set(context, domains, searches, options):
    Variant = nmci.util.GLib.Variant
    value = {}
    if searches.lower().startswith("no"):
        value["searches"] = Variant("as", [])
    else:
        searches = [s.strip() for s in searches.split(",")]
        value["searches"] = Variant("as", searches)
    if options.lower().startswith("no"):
        value["options"] = Variant("as", [])
    else:
        options = [o.strip() for o in options.split(",")]
        value["options"] = Variant("as", options)
    if domains.lower().startswith("no"):
        value["domains"] = Variant("a{sv}", {})
    else:
        domains = domains.split(";")
        domains = [dom.split(":") for dom in domains]
        domains = [
            (dom.strip(), [s.strip() for s in srvs.split(",")])
            for (dom, srvs) in domains
        ]
        value["domains"] = Variant(
            "a{sv}",
            {
                dom: Variant("a{sv}", {"servers": Variant("as", srvs)})
                for (dom, srvs) in domains
            },
        )
    value = Variant.new_variant(Variant("a{sv}", value))

    nmci.cleanup.add_callback(
        lambda: nmci.dbus.set_property(
            "org.freedesktop.NetworkManager",
            "/org/freedesktop/NetworkManager",
            "org.freedesktop.NetworkManager",
            "GlobalDnsConfiguration",
            nmci.util.GLib.Variant.new_variant(Variant("a{sv}", {})),
        ),
        name="reset-dns-global-config-via-dbus",
        # we need to call this once, even if the step is executed multiple times
        unique_tag="GLOBAL_DNS_RESET",
        # do cleanup after NM is restarted after config drop
        priority=nmci.cleanup.Cleanup.PRIORITY_NM_SERVICE_RESTART + 1,
    )

    nmci.dbus.set_property(
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager",
        "org.freedesktop.NetworkManager",
        "GlobalDnsConfiguration",
        value,
    )


@step("Fail setting global DNS config via dbus")
def fail_dbus_global_dns_set(context):
    failed = False
    try:
        dbus_global_dns_set(context, "no", "no", "no")
    except nmci.util.GLib.GError as e:
        if "already set" in e.message:
            nmci.embed.embed_exception("Expected error")
            failed = True
        else:
            raise e
    assert failed, "Did not fail to set dbus property"


@step('Check that global DNS config is "{config}"')
def dbus_global_dns_get(context, config):
    cmd = [
        "busctl",
        "get-property",
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager",
        "org.freedesktop.NetworkManager",
        "GlobalDnsConfiguration",
    ]
    running_config = nmci.process.run_stdout(cmd).strip()
    assert (
        config == running_config
    ), f"Global DNS config mismatch, running != expected: `{running_config}` != `{config}`"


@step(
    'Check that global DNS config is "{domains}" domains, "{searches}" searches, "{options}" options'
)
def dbus_global_dns_get(context, domains, searches, options):
    c = nmci.dbus.get_property(
        "org.freedesktop.NetworkManager",
        "/org/freedesktop/NetworkManager",
        "org.freedesktop.NetworkManager",
        "GlobalDnsConfiguration",
    )
    value = {}
    Variant = nmci.util.GLib.Variant
    unset = True
    if searches.lower().startswith("no"):
        value["searches"] = Variant("as", [])
    else:
        unset = False
        searches = [s.strip() for s in searches.split(",")]
        value["searches"] = Variant("as", searches)
    if options.lower().startswith("no"):
        value["options"] = Variant("as", [])
    else:
        unset = False
        options = [o.strip() for o in options.split(",")]
        value["options"] = Variant("as", options)
    if domains.lower().startswith("no"):
        value["domains"] = Variant("a{sv}", {})
    else:
        unset = False
        domains = domains.split(";")
        domains = [dom.split(":") for dom in domains]
        domains = [
            (dom.strip(), [s.strip() for s in srvs.split(",")])
            for (dom, srvs) in domains
        ]
        value["domains"] = Variant(
            "a{sv}",
            {
                dom: Variant("a{sv}", {"servers": Variant("as", srvs)})
                for (dom, srvs) in domains
            },
        )
    # If none options is set, compile empty dictionary to Variant
    if unset:
        value = {}
    value = Variant("a{sv}", value)
    assert (
        c == value
    ), f"Running global DNS config and expected config differ: {c} != {value}"


@step('Allow user "{user}" in polkit')
def allow_user_polkit(context, user):
    conf = f"""
  polkit.addRule(function(action, subject) {{
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0 && subject.user == "{user}") {{
      return polkit.Result.YES;
    }}
  }});
"""
    polkit_rule_file = (
        f"/etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager-{user}.rules"
    )
    nmci.cleanup.add_file(polkit_rule_file, name=f"polkit-rule-file-for-{user}")
    nmci.util.file_set_content(polkit_rule_file, conf)


@step('Allow user "{user}" in polkit without modify.system')
def allow_user_polkit_no_modify_system(context, user):
    conf = f"""
  polkit.addRule(function(action, subject) {{
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0
        && action.id != "org.freedesktop.NetworkManager.settings.modify.system"
        && subject.user == "{user}") {{
      return polkit.Result.YES;
    }}
  }});
"""
    polkit_rule_file = (
        f"/etc/polkit-1/rules.d/50-org.freedesktop.NetworkManager-{user}.rules"
    )
    nmci.cleanup.add_file(polkit_rule_file, name=f"polkit-rule-file-for-{user}")
    nmci.util.file_set_content(polkit_rule_file, conf)
