import time
from behave import step  # pylint: disable=no-name-in-module

import nmci


@step(u'Reboot')
def reboot(context):
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service()
    for x in range(1, 11):
        context.command_code("sudo ip link set dev eth%d down" % int(x))
        context.command_code("sudo ip addr flush dev eth%d" % int(x))

    context.command_code("sudo ip link set dev em1 down")
    context.command_code("sudo ip addr flush dev em1")

    context.command_code("ip link del nm-bond")
    context.command_code("ip link del nm-team")
    context.command_code("ip link del team7")
    context.command_code("ip link del bridge7")
    context.command_code("ip link del bond-bridge")

    # for nmtui
    context.command_code("ip link del bond0")
    context.command_code("ip link del team0")
    # for vrf devices
    context.command_code("ip link del vrf0")
    context.command_code("ip link del vrf1")
    # for pppoe test
    context.command_code("sudo ip addr flush dev test11")
    # for various eth11 tests
    context.command_code("sudo ip link set dev eth11 down")
    context.command_code("sudo ip addr flush dev eth11")
    # for sriov tests
    context.command_code("sudo ip link set dev p4p1 down")
    context.command_code("sudo ip addr flush dev p4p1")

    # for veth tests
    context.command_code("sudo ip link del veth11")
    context.command_code("sudo ip link del veth12")

    context.command_code("rm -rf /var/run/NetworkManager")

    time.sleep(1)
    assert nmci.nmutil.restart_NM_service(reset=False, timeout=10), "NM restart failed"
    time.sleep(2)


@step(u'Start NM')
def start_NM(context):
    context.nm_restarted = True
    assert nmci.nmutil.start_NM_service(), "NM start failed"


@step(u'Start NM without PID wait')
def start_NM_no_pid(context):
    context.nm_restarted = True
    assert nmci.nmutil.start_NM_service(pid_wait=False, timeout=10), "NM start failed"


@step(u'Restart NM')
def restart_NM(context):
    context.nm_restarted = True
    assert nmci.nmutil.restart_NM_service(reset=False), "NM restart failed"
    # For stability reasons 1 is not enough, please do not lower this
    time.sleep(2)


@step(u'Restart NM in background')
def restart_NM_background(context):
    context.nm_restarted = True
    context.pexpect_service("systemctl restart NetworkManager")
    context.nm_pid_refresh_count = 2


@step(u'Kill NM with signal "{signal}"')
@step(u'Kill NM')
def kill_NM(context, signal=""):
    context.nm_restarted = True
    if signal:
        signal = "-" + signal
    context.run("kill %s $(pidof NetworkManager) && sleep 5" % (signal), shell=True)
    context.nm_pid = nmci.nmutil.nm_pid()


@step(u'Stop NM')
def stop_NM(context):
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service(), "NM stop failed"


@step(u'Stop NM and clean "{device}"')
def stop_NM_and_clean(context, device):
    context.nm_restarted = True
    assert nmci.nmutil.stop_NM_service(), "NM stop failed"
    assert context.command_code("sudo ip addr flush dev %s" % (device)) == 0
    assert context.command_code("sudo ip link set %s down" % (device)) == 0


@step(u'NM is restarted within next "{N}" steps')
def pause_restart_check(context, N):
    context.nm_restarted = True
    context.nm_pid_refresh_count = int(N) + 1
