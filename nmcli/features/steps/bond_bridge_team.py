# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals

import os
import pexpect
import re
import subprocess
import time
from behave import step

from steps import command_code, additional_sleep


@step(u'Check bond "{bond}" in proc')
def check_bond_in_proc(context, bond):
    child = pexpect.spawn('cat /proc/net/bonding/%s ' % (bond) , logfile=context.log, encoding='utf-8')
    assert child.expect(['Ethernet Channel Bonding Driver', pexpect.EOF]) == 0; "%s is not in proc" % bond


@step(u'Check slave "{slave}" in bond "{bond}" in proc')
def check_slave_in_bond_in_proc(context, slave, bond):
    child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond), logfile=context.log, encoding='utf-8')
    if child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) != 0:
        time.sleep(1)
        child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond), logfile=context.log, encoding='utf-8')
        assert child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) == 0, "Slave %s is not in %s" % (slave, bond)
    else:
        return True


@step(u'Check slave "{slave}" in team "{team}" is "{state}"')
def check_slave_in_team_is_up(context, slave, team, state):
    #time.sleep(2)
    r = command_code(context, 'sudo teamdctl %s port present %s' %(team, slave))
    if state == "up":
        if r != 0:
            time.sleep(1)
            r = command_code(context, 'sudo teamdctl %s port present %s' %(team, slave))
            if r != 0:
                raise Exception('Device %s was not found in dump of team %s' % (slave, team))

    if state == "down":
        if r == 0:
            time.sleep(1)
            r = command_code(context, 'sudo teamdctl %s port present %s' %(team, slave))
            if r == 0:
                raise Exception('Device %s was found in dump of team %s' % (slave, team))

@step(u'Check "{bond}" has "{slave}" in proc')
def check_slave_present_in_bond_in_proc(context, slave, bond):
    # DON'T USE THIS STEP UNLESS YOU HAVE A GOOD REASON!!
    # this is not looking for up state as arp connections are sometimes down.
    # it's always better to check whether slave is up
    child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond), logfile=context.log, encoding='utf-8')
    assert child.expect(["Slave Interface: %s\s+MII Status:" % slave, pexpect.EOF]) == 0, "Slave %s is not in %s" % (slave, bond)


@step(u'Check slave "{slave}" not in bond "{bond}" in proc')
def check_slave_not_in_bond_in_proc(context, slave, bond):
    child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond), logfile=context.log, encoding='utf-8')
    assert child.expect(["Slave Interface: %s\s+MII Status: up" % slave, pexpect.EOF]) != 0, "Slave %s is in %s" % (slave, bond)


@step(u'Check bond "{bond}" state is "{state}"')
def check_bond_state(context, bond, state):
    child = pexpect.spawn('ip addr show dev %s up' % (bond), encoding='utf-8')
    exp = 0 if state == "up" else 1
    r = child.expect(["\\d+: %s:" %  bond, pexpect.EOF])
    assert r == exp, "%s not in %s state" % (bond, state)


@step(u'Check bond "{bond}" link state is "{state}"')
def check_bond_link_state(context, bond, state):
    ret = False
    if os.system('ls /proc/net/bonding/%s' %bond) != 0 and state == "down":
        return
    i = 40
    while i > 0:
        child = pexpect.spawn('cat /proc/net/bonding/%s' % (bond), encoding='utf-8')
        if child.expect(["MII Status: %s" %  state, pexpect.EOF]) == 0:
            return
        else:
            time.sleep(0.2)
            i-=1
    assert child.expect(["MII Status: %s" %  state, pexpect.EOF]) == 0, "%s is not in %s link state" % (bond, state)


@step(u'Create 300 bridges and delete them')
def create_delete_bridges(context):
    i = 0
    while i < 300:
        subprocess.Popen('ip link add name br0 type bridge' , shell=True).wait()
        subprocess.Popen('ip addr add 1.1.1.1/24 dev br0' , shell=True).wait()
        subprocess.Popen('ip link delete dev br0' , shell=True).wait()
        i += 1


@step(u'Settle with RTNETLINK')
def settle(context):
    # This is a temporary measure until we have a proper API
    # and a nmcli command to actually settle with platform
    from gi.repository import NM
    client = NM.Client.new (None)

    while True:
         devs = client.get_devices()
         time.sleep(1)
         devs2 = client.get_devices()

         if len(devs) != len(devs2):
             continue

         different = False
         for i in range(0, len(devs)):
             if devs[i].get_iface() != devs2[i].get_iface():
                 different = True
                 break
         if not different:
             break


@step(u'Externally created bridge has IP when NM overtakes it repeated "{number}" times')
def external_bridge_check(context, number):
    i = 0
    while i < int(number):
        context.execute_steps(u"""
            * Execute "sudo sh -c 'ip link add name br0 type bridge ; ip addr add 10.1.1.1/24 dev br0 ; ip link set br0 up'"
            * "10.1.1.1/24" is visible with command "ip addr show br0" in "4" seconds
            * "GENERAL.STATE:\s+100 \(connected" is visible with command "nmcli device show br0" in "4" seconds
            * "IP4.ADDRESS.+10.1.1.1/24" is visible with command "nmcli device show br0"
            * Execute "sudo sh -c 'ip link del br0'"
            * "br0" is not visible with command "nmcli device" in "5" seconds
        """)
        i += 1


@step(u'Team "{team}" is down')
def team_is_down(context, team):
    additional_sleep(2)
    if command_code(context, 'teamdctl %s state dump' %team) == 0:
        time.sleep(1)
        assert command_code(context, 'teamdctl %s state dump' %team) != 0, 'team "%s" exists' % (team)


@step(u'Team "{team}" is up')
def team_is_down(context, team):
    additional_sleep(2)
    if command_code(context, 'teamdctl %s state dump' %team) != 0:
        time.sleep(1)
        assert command_code(context, 'teamdctl %s state dump' %team) == 0, 'team "%s" does not exist' % (team)


@step(u'Check that "{cap}" capability is loaded')
def check_cap_loaded(context, cap):
    import gi
    gi.require_version('NM', '1.0')
    from gi.repository import NM

    nmc = NM.Client.new()
    cap_id = getattr(NM.Capability, cap)
    caps = nmc.get_capabilities()
    assert cap_id in caps, "capability %s (id %d) is not in %s" % (cap, cap_id, str(caps))
