import os
import pexpect
import re
import subprocess
import time
from behave import step

import nmci_step


@step(u'Reboot')
def reboot(context):
    context.nm_restarted = True
    assert nmci_step.command_code(context, "sudo systemctl stop NetworkManager") == 0
    for x in range(1,11):
        nmci_step.command_code(context, "sudo ip link set dev eth%d down" %int(x))
        nmci_step.command_code(context, "sudo ip addr flush dev eth%d" %int(x))

    nmci_step.command_code(context, "sudo ip link set dev em1 down")
    nmci_step.command_code(context, "sudo ip addr flush dev em1")

    nmci_step.command_code(context, "ip link del nm-bond")
    nmci_step.command_code(context, "ip link del nm-team")
    nmci_step.command_code(context, "ip link del team7")
    nmci_step.command_code(context, "ip link del bridge7")

    # for nmtui
    nmci_step.command_code(context, "ip link del bond0")
    nmci_step.command_code(context, "ip link del team0")
    # for vrf devices
    nmci_step.command_code(context, "ip link del vrf0")
    nmci_step.command_code(context, "ip link del vrf1")
    # for pppoe test
    nmci_step.command_code(context, "sudo ip addr flush dev test11")
    # for veth tests
    nmci_step.command_code(context, "sudo ip link del test11")
    nmci_step.command_code(context, "sudo ip link del test12")

    nmci_step.command_code(context, "rm -rf /var/run/NetworkManager")

    time.sleep(1)
    assert nmci_step.command_code(context, "sudo systemctl restart NetworkManager") == 0
    time.sleep(2)


@step(u'Start NM')
def start_NM(context):
    context.nm_restarted = True
    assert nmci_step.command_code(context, "sudo systemctl start NetworkManager.service") == 0


@step(u'Restart NM')
def restart_NM(context):
    context.nm_restarted = True
    nmci_step.command_code(context, "systemctl restart NetworkManager") == 0
    # For stability reasons 1 is not enough, please do not lower this
    time.sleep(2)


@step(u'Kill NM with signal "{signal}"')
@step(u'Kill NM')
def stop_NM(context, signal=""):
    context.nm_restarted = True
    if signal:
        signal = "-" + signal
    subprocess.call("kill %s $(pidof NetworkManager) && sleep 5" % (signal), shell=True)


@step(u'Stop NM')
def stop_NM(context):
    context.nm_restarted = True
    assert nmci_step.command_code(context, "sudo systemctl stop NetworkManager.service") == 0


@step(u'Stop NM and clean "{device}"')
def stop_NM_and_clean(context, device):
    context.nm_restarted = True
    assert nmci_step.command_code(context, "sudo systemctl stop NetworkManager.service") == 0
    assert nmci_step.command_code(context, "sudo ip addr flush dev %s" %(device)) == 0
    assert nmci_step.command_code(context, "sudo ip link set %s down" %(device)) == 0
