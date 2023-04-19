# pylint: disable=no-name-in-module
from behave import step

import nmci


@step("Reboot")
@step('Reboot within "{timeout}" seconds')
def reboot(context, timeout=None):
    nmci.nmutil.reboot_NM_service(timeout)


@step("Start NM")
def start_nm(context):
    nmci.nmutil.start_NM_service()


@step("Start NM without PID wait")
def start_nm_no_pid(context):
    nmci.nmutil.start_NM_service(pid_wait=False)


@step("Restart NM")
@step('Restart NM within "{timeout}" seconds')
def restart_nm(context, timeout=None):
    nmci.nmutil.restart_NM_service(timeout=timeout)


@step("Restart NM in background")
def restart_nm_background(context):
    nmci.nmutil.context_set_nm_restarted(context)
    context.pexpect_service("systemctl restart NetworkManager")
    context.nm_pid_refresh_count = 2


@step("Reload NM")
def restart_nm(context):
    nmci.nmutil.reload_NM_service(synchronous=True)


@step('Kill NM with signal "{signal}"')
@step("Kill NM")
def kill_nm(context, signal=""):
    nmci.nmutil.context_set_nm_restarted(context)

    signal_args = []
    if signal:
        signal_args = [f"-{signal}"]
    nm_pid = nmci.nmutil.nm_pid()

    if nm_pid:
        nmci.process.run_stdout(["kill", *signal_args, str(nm_pid)])

        context.nm_pid = nmci.nmutil.wait_for_nm_pid(old_pid=nm_pid)

    # TODO: this check is not reliable, sometimes it fails, sometimes it passes
    # assert not context.nm_pid, f"NetworkManager running after kill! PID:{context.nm_pid}"
    context.nm_pid_refresh_count = 1


@step("Stop NM")
def stop_nm(context):
    nmci.nmutil.stop_NM_service()


@step('Stop NM and clean "{device}"')
def stop_nm_and_clean(context, device):
    nmci.nmutil.stop_NM_service()
    nmci.ip.link_set(ifname=device, up=False)
    nmci.ip.address_flush(ifname=device)


@step('NM is restarted within next "{steps}" steps')
def pause_restart_check(context, steps):
    nmci.nmutil.context_set_nm_restarted(context)
    context.nm_pid_refresh_count = int(steps) + 1
