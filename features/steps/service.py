# pylint: disable=no-name-in-module
# type: ignore[no-redef]
from behave import step
import time
import os

import nmci


@step("Reboot")
@step('Reboot within "{timeout}" seconds')
def reboot(context, timeout=None):
    nmci.nmutil.reboot_NM_service(timeout)


@step("Start NM")
@step('Start NM in "{seconds}" seconds')
def start_nm(context, seconds=None):
    if seconds:
        seconds = float(seconds)
    nmci.nmutil.start_NM_service(timeout=seconds)


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
def resload_nm(context):
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
@step('Start NM in valgrind using tool "{tool}"')
def NM_valgrind_start(context, tool="memcheck"):
    assert (
        getattr(context, "nm_valgrind_proc", None) is None
    ), "NM already running in valgrind"
    context.nm_valgrind_proc = None
    nmci.cleanup.add_callback(lambda: NM_valgrind_stop(context), "stop-NM-valgrind")
    nmci.cleanup.add_NM_service("restart")
    # do not use nmutil, we do not want cleanup NM start registered
    nmci.process.systemctl("stop NetworkManager")
    context.nm_pid = 0
    tool_cmd = f"--tool={tool}"

    if tool == "memcheck":
        tool_cmd += " --leak-check=full --errors-for-leak-kinds=definite --show-leak-kinds=definite"

        def _mem_size(pid):
            leak_summary = nmci.process.run_stdout(
                f"vgdb --pid={pid} leak_check summary", ignore_stderr=True
            )
            still_reachable = int(
                leak_summary.split("still reachable:")[1]
                .strip()
                .split(" ")[0]
                .replace(",", "")
            )
            return int(still_reachable / 1024)

        context.nm_valgrind_mem_size = _mem_size

        def _final_check(proc):
            proc.expect(["ERROR SUMMARY", nmci.pexpect.TIMEOUT], timeout=5)
            proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
            # proc.before is string after "ERROR SUMMARY" and before EOF
            return proc.before

        context.nm_valgrind_final_check = _final_check

    elif tool == "massif":
        context.nm_valgrind_massif_f = nmci.util.tmp_dir(
            f"massif.{str(nmci.util.random_int(nmci.util.nmci_random_seed()))}"
        )
        tool_cmd += (
            f" --massif-out-file={context.nm_valgrind_massif_f} --detailed-freq=1"
        )

        def _mem_size(pid):
            snap_file = nmci.util.tmp_dir(f"snap.{pid}")
            # trunc file to prevent using old data
            nmci.process.run(
                f"vgdb --pid={pid} snapshot {snap_file}", ignore_stderr=True
            )

            mem_heap = 0
            for line in nmci.util.file_get_content_simple(snap_file).split("\n"):
                if "mem_heap" in line:
                    mem_heap += int(int(line.split("=")[1]) / 1024)
            assert mem_heap > 0, "unable to read mem usage"
            return mem_heap

        context.nm_valgrind_mem_size = _mem_size

        def _final_check(proc):
            pid = proc.pid
            snap_file = nmci.util.tmp_dir(f"snap.{pid}")
            # trunc file to prevent using old data
            nmci.util.file_set_content(snap_file)
            nmci.process.run(
                f"vgdb --pid={pid} detailed_snapshot {snap_file}", ignore_stderr=True
            )

            proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
            nmci.embed.embed_file_if_exists(
                "MASSIF", nmci.cext.context.nm_valgrind_massif_f
            )
            os.remove(nmci.cext.context.nm_valgrind_massif_f)
            # massif can not do leak checks return no error
            return ": 0 errors"

        context.nm_valgrind_final_check = _final_check

    nm_valgrind_cmd = (
        f"valgrind --vgdb=yes {tool_cmd} --num-callers=99 NetworkManager --no-daemon"
    )

    for i in range(2):
        context.nm_valgrind_proc = nmci.pexpect.pexpect_service(
            nm_valgrind_cmd, env={**os.environ, "G_SLICE": "always-malloc"}
        )
        proc = context.nm_valgrind_proc
        alive = nmci.nmutil.wait_for_nm_bus(10 * (i + 1), do_assert=False)
        if alive:
            if tool == "massif":
                snap_file = nmci.util.tmp_dir(f"snap.{proc.pid}")
                nmci.util.file_set_content(snap_file)
            return True
        proc.kill(15)
        r = proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
        if r == 1:
            print("NM valgrind did not exit in 5s after kill 15, doing kill 9")
            proc.kill(9)
            r = proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
        nmci.process.systemctl("stop NetworkManager")

    context.nm_valgrind_proc = None
    assert False, "NM did not start under valgrind"


@step("Stop NM in valgrind")
def NM_valgrind_stop(context):
    proc = getattr(context, "nm_valgrind_proc", None)
    if proc is None:
        return
    context.nm_valgrind_proc = None
    results = ": no data"
    proc.kill(15)
    results = context.nm_valgrind_final_check(proc)
    r = proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
    if r == 1:
        print(
            "NM in valgrind did not finish in 5s after signal TERM, sending signal KILL"
        )
        proc.kill(9)
        proc.expect([nmci.pexpect.EOF, nmci.pexpect.TIMEOUT], timeout=5)
    nmci.nmutil.start_NM_service()
    assert " 0 errors" in results, f"ERROR SUMMARY{results}"
