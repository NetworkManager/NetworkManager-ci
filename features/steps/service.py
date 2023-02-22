# pylint: disable=no-name-in-module
from behave import step

import nmci


@step("Reboot")
@step('Reboot within "{timeout}" seconds')
def reboot(context, timeout=None):
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service()

    links = nmci.ip.link_show_all()
    link_ifnames = [li["ifname"] for li in links]

    ifnames_to_delete = [
        "nm-bond",
        "nm-team",
        "nm-bridge",
        "team7",
        "bridge7",
        "bond-bridge",
        # for nmtui
        "bond0",
        "team0",
        # for vrf devices
        "vrf0",
        "vrf1",
        # for veths
        "veth11",
        "veth12",
        # for macsec
        "macsec0",
        "macsec_veth.42",
    ]

    ifnames_to_down = [
        *[f"eth{i}" for i in range(1, 12)],
        "em1",
        # for sriov
        "p4p1",
        # for loopback
        "lo",
    ]

    ifnames_to_flush = [
        *[f"eth{i}" for i in range(1, 12)],
        "em1",
        # for sriov
        "p4p1",
        # for pppoe
        "test11",
        # for loopback
        "lo",
    ]

    for ifname in ifnames_to_delete:
        nmci.ip.link_delete(ifname=ifname, accept_nodev=True)

    for ifname in ifnames_to_down:
        if ifname in link_ifnames:
            nmci.ip.link_set(ifname=ifname, up=False)
            # We need to clean DNS records when shutting down devices
            if nmci.process.systemctl("is-active systemd-resolved").returncode == 0:
                nmci.process.run(f"resolvectl revert {ifname}", ignore_stderr=True)

    for ifname in ifnames_to_flush:
        if ifname in link_ifnames:
            nmci.ip.address_flush(ifname=ifname)

    nmci.util.directory_remove("/var/run/NetworkManager/", recursive=True)

    assert nmci.nmutil.start_NM_service(reset=True, timeout=timeout), "NM start failed"


@step("Start NM")
def start_nm(context):
    context.nm_restarted = True
    assert nmci.nmutil.start_NM_service(), "NM start failed"


@step("Start NM without PID wait")
def start_nm_no_pid(context):
    context.nm_restarted = True
    assert nmci.nmutil.start_NM_service(pid_wait=False), "NM start failed"


@step("Restart NM")
@step('Restart NM within "{timeout}" seconds')
def restart_nm(context, timeout=None):
    context.nm_restarted = True
    assert nmci.nmutil.restart_NM_service(timeout=timeout), "NM restart failed"


@step("Restart NM in background")
def restart_nm_background(context):
    context.nm_restarted = True
    context.pexpect_service("systemctl restart NetworkManager")
    context.nm_pid_refresh_count = 2


@step('Kill NM with signal "{signal}"')
@step("Kill NM")
def kill_nm(context, signal=""):
    context.nm_restarted = True

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
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service(), "NM stop failed"


@step('Stop NM and clean "{device}"')
def stop_nm_and_clean(context, device):
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service(), "NM stop failed"
    nmci.ip.link_set(ifname=device, up=False)
    nmci.ip.address_flush(ifname=device)


@step('NM is restarted within next "{steps}" steps')
def pause_restart_check(context, steps):
    context.nm_restarted = True
    context.nm_pid_refresh_count = int(steps) + 1
