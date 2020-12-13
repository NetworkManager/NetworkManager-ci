#!/usr/bin/env python
import os
import sys
import time
import signal
import traceback

import nmci.lib
import nmci.tags
import nmci.run

TIMER = 0.5

IS_NMTUI = 'nmtui' in __file__

# the order of these steps is as follows
# 1. before scenario
# 2. before tag
# 3. after scenario
# 4. after tag


def before_all(context):

    def on_signal(signum, frame):
        assert False, "killed externally (timeout)"

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    def embed_data(mime_type, data, caption):
        # If data is empty we want to finish html tag by at least one character
        non_empty_data = " " if not data else data
        for formatter in context._runner.formatters:
            if "html" in formatter.name and getattr(formatter, "embedding", None) is not None:
                formatter.embedding(mime_type=mime_type, data=non_empty_data, caption=caption)
                return True
        return False

    def _set_title(title, append=False, tag="span", **kwargs):
        for formatter in context._runner.formatters:
            if "html" in formatter.name and getattr(formatter, "set_title", None) is not None:
                formatter.set_title(title=title, append=append, tag=tag, **kwargs)
                return True
        return False

    def _run(command, *a, **kw):
        out, err, code = nmci.run.run(command, *a, **kw)
        command_calls = getattr(context, "command_calls", [])
        command_calls.append((command, code, out, err))
        return out, err, code

    def _command_output(command, *a, **kw):
        out, err, code = nmci.run.run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
            % (command, code, out, err)
        command_calls = getattr(context, "command_calls", [])
        command_calls.append((command, code, out, err))
        return out

    def _command_output_err(command, *a, **kw):
        out, err, code = nmci.run.run(command, *a, **kw)
        assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
            % (command, code, out, err)
        command_calls = getattr(context, "command_calls", [])
        command_calls.append((command, code, out, err))
        return out, err

    def _command_code(command, *a, **kw):
        out, err, code = nmci.run.run(command, *a, **kw)
        command_calls = getattr(context, "command_calls", [])
        command_calls.append((command, code, out, err))
        return code

    context.embed = embed_data
    context.set_title = _set_title
    context.command_code = _command_code
    context.run = _run
    context.command_output = _command_output
    context.command_output_err = _command_output_err

    if IS_NMTUI:
        """
        Being executed before all features
        """

        # Kill initial setup
        nmci.run.run("sudo pkill nmtui")

        # Store scenario start cursor for session logs
        context.log_cursor = nmci.lib.new_log_cursor()



def before_scenario(context, scenario):
    # set important context attributes
    context.nm_restarted = False
    context.nm_pid = nmci.lib.nm_pid()
    context.crashed_step = False
    context.log_cursor = ""
    context.arch = nmci.run.command_output("uname -p").strip()
    context.IS_NMTUI = IS_NMTUI

    if IS_NMTUI:
        os.environ['TERM'] = 'dumb'
        # Do the cleanup
        if os.path.isfile('/tmp/tui-screen.log'):
            os.remove('/tmp/tui-screen.log')
        fd = open('/tmp/tui-screen.log', 'a+')
        nmci.lib.dump_status_nmtui(fd, 'before')
        fd.write('Screen recordings after each step:' + '\n----------------------------------\n')
        fd.flush()
        fd.close()
        context.log = None
    else:
        if not os.path.isfile('/tmp/nm_wifi_configured') \
                and not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
            if nmci.run.command_code("nmcli device |grep testeth0 |grep ' connected'") != 0:
                nmci.run.run("sudo nmcli connection modify testeth0 ipv4.may-fail no")
                nmci.run.run("sudo nmcli connection up id testeth0")
                for attempt in range(0, 10):
                    if nmci.run.command_code("nmcli device |grep testeth0 |grep ' connected'") == 0:
                        break
                    time.sleep(1)

        os.environ['TERM'] = 'dumb'
        context.log = open('/tmp/log_%s.html' % scenario.name, 'w')

        # dump status before the test preparation starts
        nmci.lib.dump_status_nmcli(context, 'before %s' % scenario.name)
        context.start_timestamp = int(time.time())

    excepts = []
    if 'eth0' in scenario.tags \
            or 'delete_testeth0' in scenario.tags \
            or 'connect_testeth0' in scenario.tags \
            or 'restart' in scenario.tags \
            or 'dummy' in scenario.tags:
        try:
            nmci.tags.skip_restarts_bs(context, scenario)
        except Exception as e:
            excepts.append(str(e))

    for tag in nmci.tags.tag_registry:
        if tag.tag_name in scenario.tags and tag.before_scenario is not None:
            try:
                tag.before_scenario(context, scenario)
            except Exception:
                excepts.append(traceback.format_exc())
    assert not excepts, "Exceptions in before_scenario():\n" + "\n\n".join(excepts)

    context.nm_pid = nmci.lib.nm_pid()

    context.crashed_step = False

    print(("NetworkManager process id before: %s" % context.nm_pid))

    if context.nm_pid is not None and context.log is not None:
        context.log.write(
            "NetworkManager memory consumption before: %d KiB\n" % nmci.lib.nm_size_kb())
        if os.path.isfile("/etc/systemd/system/NetworkManager.service") \
                and nmci.run.command_code(
                    "grep -q valgrind /etc/systemd/system/NetworkManager.service") == 0:
            nmci.run.run("LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                         " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                         stdout=context.log, stderr=context.log)

    context.log_cursor = nmci.lib.new_log_cursor()


def after_step(context, step):
    if ("DEVICE_CAP_AP" in step.name or "DEVICE_CAP_ADHOC" in step.name) \
            and "is set in WirelessCapabilites" in step.name and \
            step.status == 'failed' and step.step_type == 'given':
        print("Omiting the test as device does not support AP/ADHOC mode")
        sys.exit(77)
    # for nmcli_wifi_right_band_80211a - HW dependent 'passes'
    if "DEVICE_CAP_FREQ_5GZ" in step.name \
            and "is set in WirelessCapabilites" in step.name and \
            step.status == 'failed' and step.step_type == 'given':
        print("Omitting the test as device does not support 802.11a")
        sys.exit(77)
    # for testcase_306559
    if "DEVICE_CAP_FREQ_5GZ" in step.name \
            and "is not set in WirelessCapabilites" in step.name and \
            step.status == 'failed' and step.step_type == 'given':
        print("Omitting the test as device supports 802.11a")
        sys.exit(77)

    command_calls = getattr(context, "command_calls", [])
    # array of 4-tuples: (command, code, stdout, stderr)
    if command_calls:
        message = "\n\n".join(["'%s' returned %d:\nSTDOUT:\n%s\nSTDERR:\n%s\n" % call
                               for call in command_calls])
        context.embed("text/plain", message, caption="COMMANDS")

    if IS_NMTUI:
        """Teardown after each step.
        Here we make screenshot and embed it (if one of formatters supports it)
        """
        if os.path.isfile('/tmp/nmtui.out'):
            # This doesn't need utf_only_open_read as it's strictly utf-8
            context.stream.feed(open('/tmp/nmtui.out', 'r').read().encode('utf-8'))
        nmci.lib.print_screen(context.screen)
        nmci.lib.log_screen(step.name, context.screen, '/tmp/tui-screen.log')

        if step.status == 'failed':
            # Test debugging - set DEBUG_ON_FAILURE to drop to ipdb on step failure
            if os.environ.get('DEBUG_ON_FAILURE'):
                import ipdb
                ipdb.set_trace()  # flake8: noqa

    else:
        """
        """
        # This is for RedHat's STR purposes sleep
        if os.path.isfile('/tmp/nm_skip_restarts'):
            time.sleep(0.4)

        if not context.nm_restarted and not context.crashed_step:
            new_pid = nmci.lib.nm_pid()
            if new_pid != context.nm_pid:
                print('NM Crashed as new PID %s is not old PID %s'
                      % (new_pid, context.nm_pid))
                context.crashed_step = step.name



def after_scenario(context, scenario):
    if IS_NMTUI:
        # record the network status after the test
        if os.path.isfile('/tmp/tui-screen.log'):
            fd = open('/tmp/tui-screen.log', 'a+')
            nmci.lib.dump_status_nmtui(fd, 'after')
            fd.flush()
            fd.close()
        if os.path.isfile('/tmp/tui-screen.log'):
            context.embed("text/plain",
                          nmci.lib.utf_only_open_read('/tmp/tui-screen.log'),
                          caption="TUI")
        # Stop TUI
        nmci.run.run("sudo killall nmtui &> /dev/null")
        os.remove('/tmp/nmtui.out')
        # Attach journalctl logs if failed
        if scenario.status == 'failed' and hasattr(context, "embed"):
            logs = nmci.lib.NM_log(context.log_cursor) or "NM log is empty!"
            context.embed('text/plain', logs, caption="NM")
    else:
        nm_pid_after = nmci.lib.nm_pid()
        print(("NetworkManager process id after: %s (was %s)" % (nm_pid_after, context.nm_pid)))

        if scenario.status == 'failed':
            nmci.lib.dump_status_nmcli(context, 'after %s' % scenario.name)

    # run after_scenario tags (in reverse order)
    excepts = []
    tag_registry = list(nmci.tags.tag_registry)
    tag_registry.reverse()
    for tag in tag_registry:
        if tag.tag_name in scenario.tags and tag.after_scenario is not None:
            try:
                tag.after_scenario(context, scenario)
            except Exception:
                excepts.append(traceback.format_exc())

    if not IS_NMTUI:
        # check for crash reports and embed them
        # sets crash_embeded and crashed_step, if crash found

        if 'no_abrt' in scenario.tags:
            nmci.lib.check_coredump(context, False)
            nmci.lib.check_faf(context, False)
        else:
            nmci.lib.check_coredump(context)
            nmci.lib.check_faf(context)

        if scenario.status == 'failed' or context.crashed_step:
            nmci.lib.dump_status_nmcli(context, 'after cleanup %s' % scenario.name)

            # Attach journalctl logs
            print("Attaching NM log")
            log = "~~~~~~~~~~~~~~~~~~~~~~~~~~ NM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
            log += nmci.lib.NM_log(context.log_cursor)[:20000001] or "NM log is empty!"
            context.embed('text/plain', log, caption="NM")

        if nm_pid_after is not None and context.nm_pid == nm_pid_after:
            context.log.write(
                "NetworkManager memory consumption after: %d KiB\n" % nmci.lib.nm_size_kb())
            if os.path.isfile("/etc/systemd/system/NetworkManager.service") \
                    and nmci.run.command_code(
                        "grep -q valgrind /etc/systemd/system/NetworkManager.service") == 0:
                time.sleep(3)
                nmci.run.run(
                    "LOGNAME=root HOSTNAME=localhost gdb /usr/sbin/NetworkManager "
                    " -ex 'target remote | vgdb' -ex 'monitor leak_check summary' -batch",
                    stdout=context.log, stderr=context.log)

        context.log.close()
        print("Attaching MAIN log")
        log = nmci.lib.utf_only_open_read("/tmp/log_%s.html" % scenario.name)
        context.embed('text/plain', log, caption="MAIN")

        if context.crashed_step:
            print("\n\n" + ("!"*80))
            print("!! NM CRASHED. NEEDS INSPECTION. FAILING THE TEST                      !!")
            print("!!  %-74s !!" % ("CRASHING STEP: " + context.crashed_step))
            print(("!"*80) + "\n\n")
            context.embed('text/plain', context.crashed_step, caption="CRASHED_STEP_NAME")
            if not context.crash_embeded:
                msg = "!!! no crash report detected, but NM PID changed !!!"
                context.embed('text/plain', msg, caption="NO_COREDUMP/NO_FAF")

        assert not excepts, "Exceptions in after_scenario(): \n " + "\n\n".join(excepts)


def after_tag(context, tag):
    if IS_NMTUI:
        if tag in ('vlan', 'bridge', 'bond', 'team', 'inf'):
            if hasattr(context, 'is_virtual'):
                context.is_virtual = False


def after_all(context):
    print("ALL DONE")
