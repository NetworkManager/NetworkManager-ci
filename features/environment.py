#!/usr/bin/env python
import os
import sys
import time
import signal
import traceback
import pexpect

import xml.etree.ElementTree as ET

import nmci
import nmci.lib
import nmci.tags
import nmci.misc

TIMER = 0.5

DEBUG = os.environ.get("NMCI_DEBUG", "").lower() not in ["", "n", "no", "f", "false", "0"]

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

    context.no_step = True

    nmci.lib.set_up_embedding(context)
    nmci.lib.set_up_commands(context)

    def _additional_sleep(seconds):
        if context.IS_NMTUI:
            time.sleep(seconds)

    context.additional_sleep = _additional_sleep

    context.crash_embeded = False

    context.DEBUG = DEBUG


# print exception traceback
def before_scenario(context, scenario):
    try:
        _before_scenario(context, scenario)
    except Exception as E:
        E_tb = traceback.format_exc()
        print(E_tb)
        raise E


def _before_scenario(context, scenario):
    time_begin = time.time()
    context.before_scenario_step_el = ET.Element(
        "li", {"class": "step passed", "style": "margin-bottom:1rem;"})
    ET.SubElement(context.before_scenario_step_el, "b").text = "Before scenario"
    duration_el = ET.SubElement(context.before_scenario_step_el,
                                "small", {"class": "step_duration"})
    embed_el = ET.SubElement(context.before_scenario_step_el, "div")
    context.html_formatter.actual["act_step_embed_span"] = embed_el

    # set important context attributes
    context.nm_restarted = False
    context.nm_pid = nmci.lib.nm_pid()
    context.crashed_step = False
    context.log_cursor = ""
    context.log_cursor_before_tags = nmci.lib.new_log_cursor()
    context.arch = nmci.command_output("uname -p").strip()
    context.IS_NMTUI = "nmtui" in scenario.effective_tags
    context.rh_release = nmci.command_output("cat /etc/redhat-release")
    release_i = context.rh_release.find("release ")
    if release_i >= 0:
        context.rh_release_num = float(context.rh_release[release_i:].split(" ")[1])
    else:
        context.rh_release_num = 0
    context.hypervisor = nmci.run("systemd-detect-virt")[0].strip()

    os.environ['TERM'] = 'dumb'

    # dump status before the test preparation starts
    nmci.lib.dump_status(context, 'Before Scenario', fail_only=False)

    if context.IS_NMTUI:
        nmci.run("sudo pkill nmtui")
        # Do the cleanup
        if os.path.isfile('/tmp/tui-screen.log'):
            os.remove('/tmp/tui-screen.log')
        fd = open('/tmp/tui-screen.log', 'a+')
        fd.write('Screen recordings after each step:' + '\n----------------------------------\n')
        fd.flush()
        fd.close()
    else:
        if not os.path.isfile('/tmp/nm_wifi_configured') \
                and not os.path.isfile('/tmp/nm_dcb_inf_wol_sriov_configured'):
            if nmci.command_code("nmcli device |grep testeth0 |grep ' connected'") != 0:
                nmci.run("sudo nmcli connection modify testeth0 ipv4.may-fail no")
                nmci.run("sudo nmcli connection up id testeth0")
                for attempt in range(0, 10):
                    if nmci.command_code("nmcli device |grep testeth0 |grep ' connected'") == 0:
                        break
                    time.sleep(1)
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

    for tag_name in scenario.tags:
        tag = nmci.tags.tag_registry.get(tag_name, None)
        if tag is not None and tag._before_scenario is not None:
            print("Executing @" + tag_name)
            t_start = time.time()
            t_status = "passed"
            try:
                tag.before_scenario(context, scenario)
            except Exception:
                t_status = "failed"
                excepts.append(traceback.format_exc())
            print(f"  @{tag_name} ... {t_status} in {time.time() - t_start:.3f}s")

    context.nm_pid = nmci.lib.nm_pid()

    context.crashed_step = False

    print(("NetworkManager process id before: %s" % context.nm_pid))

    context.log_cursor = nmci.lib.new_log_cursor()

    nmci.lib.process_commands(context, "before_scenario")

    duration = time.time() - time_begin
    status = "failed" if excepts else "passed"
    print(f"before_scenario ... {status} in {duration:.3f}s")
    duration_el.text = f"({duration:.3f}s)"

    nmci.lib.check_crash(context, 'crash outside steps (before scenario)')

    if excepts:
        context.before_scenario_step_el.set("class", "step failed")
        context.embed("text/plain", "\n\n".join(excepts), "Exception in before scenario tags")
        assert False, "Exception in before scenario tags"


def after_step(context, step):
    context.no_step = False
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

    nmci.lib.process_commands(context, "")

    if context.IS_NMTUI:
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
        nmci.lib.check_crash(context, step.name)


# print exception traceback
def after_scenario(context, scenario):
    try:
        _after_scenario(context, scenario)
    except Exception as E:
        E_tb = traceback.format_exc()
        print(E_tb)
        raise E


def _after_scenario(context, scenario):
    time_begin = time.time()
    context.after_scenario_step_el = ET.Element(
        "li", {"class": "step passed", "style": "margin-top:1rem;"})
    ET.SubElement(context.after_scenario_step_el, "b").text = "After scenario"
    duration_el = ET.SubElement(context.after_scenario_step_el, "small", {"class": "step_duration"})
    embed_el = ET.SubElement(context.after_scenario_step_el, "div")
    context.html_formatter.actual["act_step_embed_span"] = embed_el

    nmci.misc.html_report_tag_links(context.html_formatter.scenario_el)
    nmci.misc.html_report_file_links(context.html_formatter.scenario_el)

    nm_pid_after = nmci.lib.nm_pid()
    if not nm_pid_after:
        nmci.lib.check_crash(context, 'crash outside steps (last step before after_scenario)')
        print("Starting NM as it was found stopped")
        nmci.lib.restart_NM_service(context)

    if context.IS_NMTUI:
        if os.path.isfile('/tmp/tui-screen.log'):
            context.embed("text/plain",
                          nmci.lib.utf_only_open_read('/tmp/tui-screen.log'),
                          caption="TUI")
        # Stop TUI
        nmci.run("sudo killall nmtui &> /dev/null")
        if os.path.isfile('/tmp/nmtui.out'):
            os.remove('/tmp/nmtui.out')

    print(("NetworkManager process id after: %s (now %s)" % (nm_pid_after, context.nm_pid)))

    if scenario.status == 'failed' or DEBUG:
        nmci.lib.dump_status(context, 'After Scenario', fail_only=True)

    # run after_scenario tags (in reverse order)
    excepts = []
    scenario_tags = list(scenario.tags)
    scenario_tags.reverse()
    for tag_name in scenario_tags:
        tag = nmci.tags.tag_registry.get(tag_name, None)
        if tag is not None and tag._after_scenario is not None:
            print("Executing @" + tag_name)
            t_start = time.time()
            t_status = "passed"
            try:
                tag.after_scenario(context, scenario)
            except Exception:
                t_status = "failed"
                excepts.append(traceback.format_exc())
            print(f"  @{tag_name} ... {t_status} in {time.time() - t_start:.3f}s")

    nmci.lib.check_crash(context, 'crash outside steps (after_scenario tags)')

    # check for crash reports and embed them
    # sets crash_embeded if crash found
    nmci.lib.check_coredump(context)
    nmci.lib.check_faf(context)

    nmci.lib.process_commands(context, "after_scenario")

    scenario_fail = scenario.status == 'failed' or context.crashed_step or DEBUG or len(excepts) > 0

    # Attach postponed or "fail_only" embeds
    # !!! all embed calls with "fail_only" after this are ignored !!!
    nmci.lib.process_embeds(context, scenario_fail)

    if scenario_fail:
        # Attach journalctl logs
        print("Attaching NM log")
        log = "~~~~~~~~~~~~~~~~~~~~~~~~~~ NM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
        log += nmci.lib.NM_log(context.log_cursor)[:20000001] or "NM log is empty!"
        context.embed('text/plain', log, caption="NM")

    if context.crashed_step:
        print("\n\n" + ("!"*80))
        print("!! NM CRASHED. NEEDS INSPECTION. FAILING THE TEST                      !!")
        print("!!  %-74s !!" % ("CRASHING STEP: " + context.crashed_step))
        print(("!"*80) + "\n\n")
        context.embed('text/plain', context.crashed_step, caption="CRASHED_STEP_NAME")
        if not context.crash_embeded:
            msg = "!!! no crash report detected, but NM PID changed !!!"
            context.embed('text/plain', msg, caption="NO_COREDUMP/NO_FAF")
        nmci.lib.after_crash_reset(context)

    if scenario_fail:
        nmci.lib.dump_status(context, 'After Clean', fail_only=False)

    if excepts or context.crashed_step:
        context.after_scenario_step_el.set("class", "step failed")
    if excepts:
        context.embed("text/plain", "\n\n".join(excepts), "Exception in after scenario tags")

    # add Before/After scenario steps to HTML
    context.html_formatter.steps.insert(0, context.before_scenario_step_el)
    context.html_formatter.steps.append(context.after_scenario_step_el)

    duration = time.time() - time_begin
    status = "failed" if excepts else "passed"
    print(f"after_scenario ... {status} in {duration:.3f}s")

    duration_el.text = f"({duration:.3f}s)"

    # we need to keep state "passed" here, as '@crash' test is expected to fail
    if 'crash' in scenario.effective_tags and not context.crash_embeded:
        print("No crashdump found")
        return

    if context.crashed_step:
        assert False, "Crash happened"

    assert not excepts, "Exception in after scenario tags"


def after_tag(context, tag):
    if tag == "nmtui":
        context.IS_NMTUI = True
    if context.IS_NMTUI:
        if tag in ('vlan', 'bridge', 'bond', 'team', 'inf'):
            if hasattr(context, 'is_virtual'):
                context.is_virtual = False


def after_all(context):
    print("ALL DONE")
