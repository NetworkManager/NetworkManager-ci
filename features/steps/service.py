# pylint: disable=no-name-in-module
from behave import step
import time

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


@step("Start NM in valgrind")
def NM_valgrind_start(context):
    assert (
        getattr(context, "nm_valgrind_proc", None) is None
    ), "NM already running in valgrind"
    context.nm_valgrind_proc = None
    nmci.cleanup.add_callback(lambda: NM_valgrind_stop(context), "stop-NM-valgrind")
    nmci.cleanup.add_NM_service("restart")
    # do not use nmutil, we do not want cleanup NM start registered
    nmci.process.systemctl("stop NetworkManager")
    nm_valgrind_cmd = (
        "valgrind --vgdb=yes --leak-check=full --errors-for-leak-kinds=definite "
        "--show-leak-kinds=definite --num-callers=99 NetworkManager --no-daemon"
    )
    context.nm_valgrind_proc = nmci.pexpect.pexpect_service(nm_valgrind_cmd)
    context.nm_pid = 0

    with nmci.util.start_timeout(40, "NM not ready in 40s") as t:
        restarted = False
        while t.loop_sleep(1):
            if (
                nmci.process.run_search_stdout(
                    "nmcli c 2>&1", "not running", shell=True, ignore_returncode=True
                )
                is None
            ):
                break
            if t.elapsed_time() > 15 and not restarted:
                print("NM in valgrind not ready in 10s, restarting...")
                restarted = True
                proc = context.nm_valgrind_proc
                proc.kill(15)
                r = proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
                if r == 1:
                    print("NM valgrind did not exit in 5s after kill 15, doing kill 9")
                    proc.kill(9)
                    r = proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
                nmci.process.systemctl("stop NetworkManager")
                context.nm_valgrind_proc = nmci.pexpect.pexpect_service(nm_valgrind_cmd)


@step("Stop NM in valgrind")
def NM_valgrind_stop(context):
    proc = getattr(context, "nm_valgrind_proc", None)
    if proc is None:
        return
    context.nm_valgrind_proc = None
    results = ": no data"
    proc.kill(15)
    r = proc.expect(["ERROR SUMMARY", nmci.pexpect.TIMEOUT], timeout=5)
    if r == 1:
        proc.kill(9)
        time.sleep(2)
    proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
    # proc.before is string between "ERROR SUMMARY" and EOF (excluded).
    results = proc.before
    nmci.nmutil.start_NM_service()
    assert " 0 errors" in results, f"ERROR SUMMARY{results}"
