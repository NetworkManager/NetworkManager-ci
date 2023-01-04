# pylint: disable=unused-argument
import time
import os
import re
from behave import step  # pylint: disable=no-name-in-module
import nmci


@step('Check bond "{bond}" in proc')
def check_bond_in_proc(context, bond):
    proc_file = nmci.util.file_get_content_simple(f"/proc/net/bonding/{bond}")
    assert "Ethernet Channel Bonding Driver" in proc_file, f"{bond} is not in proc"


@step('Check slave "{slave}" in bond "{bond}" in proc')
def check_slave_in_bond_in_proc(context, slave, bond):
    timeout = nmci.util.start_timeout(6)
    while timeout.loop_sleep(0.2):
        if not os.path.isfile(f"/proc/net/bonding/{bond}"):
            continue
        proc_file = nmci.util.file_get_content_simple(f"/proc/net/bonding/{bond}")
        slave_re = re.compile(f"Slave Interface: {slave}\\s+MII Status: up")
        if re.search(slave_re, proc_file) is not None:
            return True
    assert False, f"Slave {slave} not in {bond}"


@step('Check slave "{slave}" in team "{team}" is "{state}"')
def check_slave_in_team_is_up(context, slave, team, state):
    check_cmd = f"sudo teamdctl {team} port present {slave}"
    timeout = nmci.util.start_timeout(3)
    while timeout.loop_sleep(0.2):
        result = nmci.process.run_code(check_cmd, ignore_stderr=True)
        if state == "up" and result == 0:
            return True
        if state == "down" and result != 0:
            return True
    assert False, f"Device {slave} was not found '{state}' in dump of team {slave}"


@step('Check "{bond}" has "{slave}" in proc')
def check_slave_present_in_bond_in_proc(context, slave, bond):
    # DON'T USE THIS STEP UNLESS YOU HAVE A GOOD REASON!!
    # this is not looking for up state as arp connections are sometimes down.
    # it's always better to check whether slave is up
    proc_file = nmci.util.file_get_content_simple(f"/proc/net/bonding/{bond}")
    slave_re = re.compile(f"Slave Interface: {slave}\\s+MII Status:")
    assert re.search(slave_re, proc_file) is not None, f"Slave {slave} is not in {bond}"


@step('Check slave "{slave}" not in bond "{bond}" in proc')
def check_slave_not_in_bond_in_proc(context, slave, bond):
    if not os.path.isfile(f"/proc/net/bonding/{bond}"):
        return
    proc_file = nmci.util.file_get_content_simple(f"/proc/net/bonding/{bond}")
    slave_re = re.compile(f"Slave Interface: {slave}\\s+MII Status: up")
    if re.search(slave_re, proc_file) is None:
        return True
    assert False, f"Slave {slave} is in {bond}"


@step('Check bond "{bond}" state is "{state}"')
def check_bond_state(context, bond, state):
    timeout = nmci.util.start_timeout(1)
    while timeout.loop_sleep(0.2):
        result = nmci.process.run_search_stdout(
            f"ip addr show dev {bond} up", f"\\d+: {bond}:"
        )
        if state == "up" and result is not None:
            return True
        if state == "down" and result is None:
            return True
    assert False, f"{bond} is not in {state} state"


@step('Check bond "{bond}" link state is "{state}"')
def check_bond_link_state(context, bond, state):
    if not os.path.isfile(f"/proc/net/bonding/{bond}") and state == "down":
        return
    timeout = nmci.util.start_timeout(8)
    while timeout.loop_sleep(0.2):
        proc_file = nmci.util.file_get_content_simple(f"/proc/net/bonding/{bond}")
        if f"MII Status: {state}" in proc_file:
            return True
    assert False, f"{bond} is not in {state} link state"


@step("Create 300 bridges and delete them")
def create_delete_bridges(context):
    for _ in range(300):
        nmci.ip.link_add("br0", "bridge")
        nmci.ip.address_add("1.1.1.1/24", ifname="br0")
        nmci.ip.link_delete(ifname="br0")


@step("Settle with RTNETLINK")
def settle(context):
    # This is a temporary measure until we have a proper API
    # and a nmcli command to actually settle with platform
    NM = nmci.util.NM  # pylint: disable=invalid-name
    client = NM.Client.new(None)  # pylint: disable=assignment-from-no-return

    timeout = nmci.util.start_timeout(60)
    while timeout.loop_sleep(0.1):
        devs1 = client.get_devices()
        time.sleep(1)
        devs2 = client.get_devices()

        if len(devs1) != len(devs2):
            continue

        different = False
        for dev1, dev2 in zip(devs1, devs2):
            if dev1.get_iface() != dev2.get_iface():
                different = True
                break
        if not different:
            return
    assert False, "Not settled in 60 seconds"


@step('Externally created bridge has IP when NM overtakes it repeated "{number}" times')
def external_bridge_check(context, number):
    addr = "10.1.1.1/24"
    ifname = "br0"
    nmci.cleanup.cleanup_add_iface(ifname)
    for _ in range(int(number)):
        nmci.ip.link_add(ifname=ifname, link_type="bridge")
        nmci.ip.address_add(addr, ifname=ifname)
        nmci.ip.link_set(ifname=ifname, up=True)
        nmci.ip.address_expect(
            [addr], ifname=ifname, wait_for_address=5, with_plen=True
        )

        timeout = nmci.util.start_timeout(5)
        while timeout.loop_sleep(0.5):
            devs = [
                d
                for d in nmci.nmutil.device_status(name=ifname, get_ipaddrs=True)
                if d["STATE"].startswith("connected") and addr in d["ip4-addresses"]
            ]
            if devs:
                break
        assert devs, f"Bridge {ifname} is not connected or adress missing."

        nmci.ip.link_delete(ifname=ifname)

        timeout = nmci.util.start_timeout(5)
        while timeout.loop_sleep(0.5):
            devs = nmci.nmutil.device_status(name=ifname)
            if not devs:
                break
        assert not devs, f"Bridge {ifname} still visible with `nmcli device`:\n{devs}"


@step('Team "{team}" is down')
def team_is_down(context, team):
    context.additional_sleep(2)
    timeout = nmci.util.start_timeout(1)
    while timeout.loop_sleep(0.2):
        if (
            nmci.process.run_code(f"teamdctl {team} state dump", ignore_stderr=True)
            != 0
        ):
            return
    assert False, f'team "{team}" exists'


@step('Team "{team}" is up')
def team_is_up(context, team):
    context.additional_sleep(2)
    timeout = nmci.util.start_timeout(1)
    while timeout.loop_sleep(0.2):
        if (
            nmci.process.run_code(f"teamdctl {team} state dump", ignore_stderr=True)
            == 0
        ):
            return
    assert False, f'team "{team}" does not exist'


@step('Check that "{cap}" capability is loaded')
def check_cap_loaded(context, cap):
    NM = nmci.util.NM  # pylint: disable=invalid-name
    nmc = NM.Client.new(None)  # pylint: disable=assignment-from-no-return
    cap_id = getattr(NM.Capability, cap)
    caps = nmc.get_capabilities()
    assert cap_id in caps, f"capability {cap} (id {cap_id}) is not in {caps}"
