#!/usr/bin/env python
import os
import sys
import time
import signal
import re
import shutil
import traceback

from behave.model_core import Status
import xml.etree.ElementTree as ET

import nmci

from features.steps.nmtui import get_cursored_screen, log_tui_screen

TIMER = 0.5

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

    nmci.cext.setup(context)

    def _additional_sleep(seconds):
        if context.IS_NMTUI:
            time.sleep(seconds)

    context.additional_sleep = _additional_sleep


# print exception traceback
def before_scenario(context, scenario):
    nmci.misc.journal_send(f"Entering before_scenario() of: {scenario.name}")
    try:
        status = _before_scenario(context, scenario)
    except Exception as E:
        E_tb = traceback.format_exc()
        print(E_tb)
        nmci.embed.before_scenario_finish("failed")
        if context.cext.scenario_skipped:
            # reset skipped flag, we do not want to skip when exception
            context.cext.scenario_skipped = False
            nmci.embed.formatter_add_scenario(scenario)
        raise E
    nmci.embed.before_scenario_finish(status)
    if context.cext.scenario_skipped:
        nmci.embed.formatter_add_scenario(scenario)
    nmci.misc.journal_send(f"Leaving before_scenario() of: {scenario.name}")


def _before_scenario(context, scenario):
    time_begin = time.time()
    context.time_begin_scen = time_begin

    # set important context attributes
    assert not nmci.cleanup._cleanup_lst
    # reset scenario skip flag
    context.cext.scenario_skipped = False
    nmci.util.set_verbose(False)
    # Treat before_scenario() as step
    context.step_level = 1
    nmci.nmutil.context_set_nm_restarted(context, reset=True)
    # Pause FAF reporting - to prevent incomplete/missing reports
    #  With this file present, FAF wait up to 120s until it starts uploading
    #  This file is removed after, after_crash_reset() is called and machine is back online
    #  It is then restored after the test that removed it (via nmci.cleanup)
    nmci.util.file_set_content("/tmp/pause_faf_reporting")
    context.nm_pid = nmci.nmutil.nm_pid()
    # if skip_check_count == 1 in after_scenario(),
    # the failed status is treated as skip.
    context.skip_check_count = 0
    context.crashed_step = False
    context.crash_upload = True
    context.coredump_pid_pkg = {}
    context.noted = {}
    context.log_cursor = ""
    context.log_cursor_before_tags = nmci.misc.journal_get_cursor()
    context.arch = nmci.process.run_stdout(
        "arch", embed_combine_tag=nmci.embed.NO_EMBED
    ).strip()
    context.IS_NMTUI = "nmtui" in scenario.effective_tags
    with open("/etc/redhat-release") as release_f:
        context.rh_release = release_f.read()
    _, context.rh_release_num = nmci.misc.distro_detect(
        release_file_content=context.rh_release
    )

    # skip on invalid version - this shuld not happen but is handy when executing multiple tests in single report
    if (
        nmci.misc.test_tags_match_version(
            scenario.tags, nmci.misc.nm_version_detect(), nmci.misc.distro_detect()
        )
        is None
    ):
        try:
            nmci.cext.skip("Skipping on this NM/RHEL/Fedora version")
        except nmci.misc.SkipTestException:
            pass

    os.environ["TERM"] = "dumb"

    # collect failed services' logs and reset them
    failed_services = nmci.misc.systemd_list_units(states=["failed"])
    if len(failed_services) > 0:
        statuses = nmci.process.systemctl(
            f"status {' '.join(failed_services)}", embed_combine_tag=nmci.embed.NO_EMBED
        )
        nmci.embed.embed_data("failed services' statuses", statuses.stdout)
    for s in failed_services:
        nmci.embed.embed_service_log(
            f"service in failed state: {s}",
            syslog_identifier=s,
            fail_only=True,
            cursor=False,
            journal_args="--since -12h",
        )
    if len(failed_services) > 0:
        nmci.process.systemctl("reset-failed")

    if os.path.exists("/tmp/nmci-ausearch-checkpoint-file"):
        nmci.embed.embed_avcs("after the previous scenario")
    else:
        nmci.embed.embed_avcs("on this system so far")

    if "dump_status_verbose" in scenario.tags:
        nmci.util.dump_status_verbose = True

    # dump status before the test preparation starts
    nmci.util.dump_status("Before Scenario")

    nmci.embed.set_title(f"NMCI: {scenario.tags[-1]}")

    if context.IS_NMTUI:
        nmci.process.run_code("pkill nmtui", ignore_stderr=True)
        context.screen_logs = []
    else:
        if not os.path.isfile("/tmp/nm_wifi_configured") and not os.path.isfile(
            "/tmp/nm_dcb_inf_wol_sriov_configured"
        ):
            if "testeth0:connected" not in context.process.nmcli(
                "-t -f connection,state device", embed_combine_tag="testeth0 check"
            ):
                context.process.nmcli(
                    "connection modify testeth0 ipv4.may-fail no",
                    embed_combine_tag="testeth0 check",
                )
                context.process.nmcli(
                    "connection up id testeth0", embed_combine_tag="testeth0 check"
                )
                for _ in range(0, 10):
                    if "testeth0:connected" not in context.process.nmcli(
                        "-t -f connection,state device",
                        embed_combine_tag="testeth0 check",
                    ):
                        break
                    time.sleep(1)
        context.start_timestamp = int(time.time())

    excepts = []
    if (
        "eth0" in scenario.tags
        or "delete_testeth0" in scenario.tags
        or "connect_testeth0" in scenario.tags
        or "restart" in scenario.tags
        or "dummy" in scenario.tags
    ):
        try:
            nmci.tags.skip_restarts_bs(context, scenario)
        except nmci.misc.SkipTestException:
            pass
        except Exception as e:
            excepts.append(str(e))

    for tag_name in scenario.tags:
        if context.cext.scenario_skipped:
            break
        tag = nmci.tags.tag_registry.get(tag_name, None)
        if tag is None:
            continue
        try:
            tag.before_scenario(context, scenario)
        except nmci.misc.SkipTestException:
            pass
        except Exception:
            excepts.append(traceback.format_exc())

    # Lower step_level back to 0
    context.step_level = 0

    context.nm_pid = nmci.nmutil.nm_pid()

    print(("NetworkManager process id before: %s" % context.nm_pid))

    context.log_cursor = nmci.misc.journal_get_cursor()

    nmci.pexpect.process_pexpect_spawn()

    duration = time.time() - time_begin
    status = "failed" if excepts else "passed"
    if status == "passed" and context.cext.scenario_skipped:
        status = "skipped"
    print(f"before_scenario ... {status} in {duration:.3f}s")

    nmci.crash.check_crash(context, "crash outside steps (before scenario)")

    nmci.embed.after_step()

    if excepts:
        nmci.embed.embed_data(
            "Exception in before scenario tags",
            "\n\n".join(excepts),
        )
        assert False, "Exception in before scenario tags:\n\n" + "\n\n".join(excepts)

    return status


def before_step(context, step):
    nmci.misc.journal_send(f"At before_step()")
    context.step_level += 1
    context.current_step = step


def after_step(context, step):
    nmci.misc.journal_send(f"Entering after_step()")
    context.no_step = False
    context.step_level -= 1

    if isinstance(step.exception, nmci.misc.SkipTestException):
        step.exception = None
        step.exc_traceback = None
        step.status = Status.skipped
        step.error_message = None

    if context.step_level == 0:
        nmci.pexpect.process_pexpect_spawn()

    if context.IS_NMTUI:
        """Teardown after each step.
        Here we make screenshot and embed it (if one of formatters supports it)
        """
        if os.path.isfile("/tmp/nmtui.out"):
            context.stream.feed(
                nmci.util.file_get_content_simple("/tmp/nmtui.out").encode("utf-8")
            )
        # do not append step.name if no substeps called
        if context.screen_logs or context.step_level > 0:
            context.screen_logs.append(step.name)
        context.screen_logs += get_cursored_screen(context.screen)
        if context.step_level == 0:
            log_tui_screen(context, context.screen_logs)
            context.screen_logs = []

        if step.status == "failed":
            # Test debugging - set DEBUG_ON_FAILURE to drop to ipdb on step failure
            if os.environ.get("DEBUG_ON_FAILURE"):
                import ipdb

                ipdb.set_trace()  # flake8: noqa

    else:
        """ """
        # This is for RedHat's STR purposes sleep
        if os.path.isfile("/tmp/nm_skip_restarts"):
            time.sleep(0.4)

    # after_step() is called for each substep of context.execute_steps() call,
    # this code is to be executed only for steps present in feature file
    if context.step_level == 0:
        nmci.crash.check_crash(context, step.name)
        nmci.embed.after_step()
        if step.name.startswith("Prepare "):
            nmci.util.dump_status("After this step")

        # handle skip_check_count as last part, only for feature file steps
        if context.skip_check_count == 1:
            if step.status != Status.passed:
                try:
                    nmci.cext.skip(f"Skipping because step is {step.status.name}")
                except nmci.misc.SkipTestException:
                    pass
                step.status = Status.skipped
        context.skip_check_count -= 1
    nmci.misc.journal_send(f"Leaving after_step()")


# print exception traceback
def after_scenario(context, scenario):
    nmci.misc.journal_send(f"Entering after_scenario() of {scenario.name}")
    try:
        status = _after_scenario(context, scenario)
    except Exception as E:
        E_tb = traceback.format_exc()
        print(E_tb)
        nmci.embed.after_scenario_finish("failed")
        raise E
    nmci.embed.after_scenario_finish(status)
    nmci.misc.journal_send(f"Leaving after_scenario() of {scenario.name}")


def _after_scenario(context, scenario):
    time_begin = time.time()

    nmci.misc.html_report_tag_links()
    nmci.misc.html_report_file_links()

    if scenario.status == "failed":
        nmci.util.set_verbose(True)

    skipped = context.cext.scenario_skipped

    nm_pid_after = nmci.nmutil.nm_pid()
    if not nm_pid_after:
        nmci.crash.check_crash(
            context, "crash outside steps (last step before after_scenario)"
        )
        # print("Entering NM as it was found stopped")
        # nmci.nmutil.restart_NM_service()

    if context.IS_NMTUI:
        if os.path.isfile("/tmp/tui-screen.log"):
            nmci.embed.embed_data(
                "TUI",
                nmci.util.file_get_content_simple("/tmp/tui-screen.log"),
            )
        # Stop TUI
        nmci.process.run_code("killall nmtui", ignore_stderr=True)
        if os.path.isfile("/tmp/nmtui.out"):
            os.remove("/tmp/nmtui.out")

    print(
        (
            "NetworkManager process id after: %s (now %s)"
            % (nm_pid_after, context.nm_pid)
        )
    )

    if scenario.status == "failed" or nmci.util.DEBUG:
        nmci.util.dump_status("After Scenario")

    nmci.pexpect.process_pexpect_spawn()

    excepts = []

    nmci.misc.journal_send(
        f"Starting to process cleanups after scenario: {scenario.name}"
    )
    for ex in nmci.cleanup.process_cleanup():
        if not isinstance(ex, nmci.misc.SkipTestException):
            excepts.append(
                "".join(traceback.format_exception(ex, ex, ex.__traceback__))
            )

    nmci.misc.journal_send(
        f"Finished processing cleanups after scenario: {scenario.name}"
    )

    # check for crash reports and embed them
    # sets nmci.embed.coredump_reported if crash found
    # always check coredumps before FAF to guess FAF pkg_name!
    nmci.crash.check_coredump(context)
    nmci.crash.check_faf(context)

    nmci.crash.check_crash(context, "crash outside steps (after_scenario tags)")

    scenario_fail = (
        scenario.status == "failed" or context.crashed_step or len(excepts) > 0
    )

    filter_args = " + ".join(
        [
            "_SYSTEMD_UNIT=NetworkManager.service",
            "SYSLOG_IDENTIFIER=runtest",
            "SYSLOG_IDENTIFIER=nmci",
        ]
    )
    log = nmci.misc.journal_show(
        cursor=context.log_cursor_before_tags,
        prefix="~~~~~~~~~~~~~~~~~~~~~~~~~~ NM LOG ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
        journal_args=f"{filter_args} -o cat",
    )
    backoff_r = re.compile("backoff for [0-9]+ seconds before the resync.")
    if "ignore_backoff_message" not in scenario.tags and backoff_r.search(log):
        excepts.append("`backoff` message found in NM journal")
        scenario_fail = True

    if scenario_fail:
        nmci.util.set_verbose(True)

    if nmci.util.is_verbose():
        # Attach journalctl logs
        print("Attaching NM log")
        nmci.embed.embed_data("NM", log)

    if context.crashed_step:
        print("\n\n" + ("!" * 80))
        print(
            "!! NM CRASHED. NEEDS INSPECTION. FAILING THE TEST                      !!"
        )
        print("!!  %-74s !!" % ("CRASHING STEP: " + context.crashed_step))
        print(("!" * 80) + "\n\n")
        nmci.embed.embed_data("CRASHED_STEP_NAME", context.crashed_step)
        if not nmci.embed.coredump_reported:
            msg = "!!! no crash report detected, but NM PID changed !!!"
            nmci.embed.embed_data("NO_COREDUMP/NO_FAF", msg)
        if not nmci.embed.is_faf_reported():
            try:
                nmci.crash.after_crash_reset()
            except Exception as e:
                excepts.append(e)

    nmci.embed.embed_avcs("during this scenario")

    # collect failed services' logs and reset them
    failed_services = nmci.misc.systemd_list_units(states=["failed"])
    if len(failed_services) > 0:
        statuses = nmci.process.systemctl(
            f"status {' '.join(failed_services)}", embed_combine_tag=nmci.embed.NO_EMBED
        )
        nmci.embed.embed_data("failed services' statuses", statuses.stdout)
    for s in failed_services:
        nmci.embed.embed_service_log(
            f"service failed during scenario run: {s}",
            syslog_identifier=s,
            cursor=False,
            journal_args="--since -12h",
        )
    if len(failed_services) > 0:
        nmci.process.systemctl("reset-failed")

    if nmci.util.is_verbose():
        nmci.util.dump_status("After Clean")

    # process embeds as last thing before asserts
    try:
        nmci.embed.process_embeds()
    except Exception:
        excepts.append(traceback.format_exc())

    if not skipped and context.cext.scenario_skipped:
        excepts.append("Skip in after_scenario() detected.")

    if excepts or context.crashed_step:
        # reset skip flag, so we do not skip fail
        context.cext.scenario_skipped = False
    if excepts:
        nmci.embed.embed_data("Exception in after scenario tags", "\n\n".join(excepts))

    duration = time.time() - time_begin
    status = "failed" if excepts else "passed"
    if status == "passed" and skipped:
        status = "skipped"
    print(f"after_scenario ... {status} in {duration:.3f}s")

    stdout = nmci.misc.journal_show(
        cursor=context.log_cursor_before_tags,
        journal_args=f"SYSLOG_IDENTIFIER=runtest -o cat",
    )
    nmci.embed.embed_data("STDOUT", stdout)
    nmci.embed.process_embeds()

    # we need to keep state "passed" here, as '@crash' test is expected to fail
    if "crash" in scenario.effective_tags and not nmci.embed.coredump_reported:
        print("No crashdump found")
        return

    if context.crashed_step:
        assert False, "Crash happened"

    assert not excepts, "Exceptions in after scenario:\n\n" + "\n\n".join(excepts)

    return status


def after_tag(context, tag):
    if tag == "nmtui":
        context.IS_NMTUI = True
    if context.IS_NMTUI:
        if tag in ("vlan", "bridge", "bond", "team", "inf"):
            if hasattr(context, "is_virtual"):
                context.is_virtual = False


def after_all(context):
    if context.cext.scenario_skipped:
        for f in context._runner.formatters:
            f.close()
        sys.exit(77)
    print("ALL DONE")
