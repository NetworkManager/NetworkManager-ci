# -*- coding: UTF-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals
from behave import step
from time import sleep, time
import pexpect
import os
import re
import subprocess
from subprocess import Popen, check_output, call
from glob import glob

from steps import command_output, command_code, additional_sleep



@step(u'Activate connection')
def activate_connection(context):
    prompt = pexpect.spawn('activate', encoding='utf-8')
    context.prompt = prompt


@step(u'Add a connection named "{name}" for device "{ifname}" to "{vpn}" VPN')
def add_vpnc_connection_for_iface(context, name, ifname, vpn):
    cli = pexpect.spawn('nmcli connection add con-name %s type vpn ifname %s vpn-type %s' % (name, ifname, vpn), logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    sleep(1)
    if r == 0:
        raise Exception('Got an Error while adding %s connection %s for device %s\n%s%s' % (vpn, name, ifname, cli.after, cli.buffer))

@step(u'Add connection type "{typ}" named "{name}" for device "{ifname}"')
def add_connection_for_iface(context, typ, name, ifname):
    cli = pexpect.spawn('nmcli connection add type %s con-name %s ifname %s' % (typ, name, ifname), logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while adding %s connection %s for device %s\n%s%s' % (typ, name, ifname, cli.after, cli.buffer))

@step(u'Add a new connection of type "{typ}" ifname "{ifname}" and options "{options}"')
def add_new_default_connection(context, typ, ifname, options):
    pass


@step(u'Add a new connection of type "{typ}" and options "{options}"')
def add_new_default_connection_without_ifname(context, typ, options):
    cli = pexpect.spawn('nmcli connection add type %s %s' % (typ, options), logfile=context.log, encoding='utf-8')
    if cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF]) == 0:
        raise Exception('Got an Error while creating connection of type %s with options %s\n%s%s' % (typ,options,cli.after,cli.buffer))


@step(u'Add infiniband port named "{name}" for device "{ifname}" with parent "{parent}" and p-key "{pkey}"')
def add_port(context, name, ifname, parent, pkey):
    cli = pexpect.spawn('nmcli connection add type infiniband con-name %s ifname %s parent %s p-key %s' % (name, ifname, parent, pkey), logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while adding %s connection %s for device %s\n%s%s' % (typ, name, ifname, cli.after, cli.buffer))
    sleep(1)


@step(u'Modify connection "{connection}" property "{prop}" to noted value')
def modify_connection_with_noted(context, connection, prop):
    cli = pexpect.spawn('nmcli connection modify %s %s %s' % (connection, prop, context.noted_value), encoding='utf-8')
    r = cli.expect(['Error', pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while changing %s property for connection %s to %s\n%s%s' % (prop, connection, context.noted_value, cli.after, cli.buffer))


@step(u'Add slave connection for master "{master}" on device "{device}" named "{name}"')
def open_slave_connection(context, master, device, name):
    if master.find("team") != -1:
        cli = pexpect.spawn('nmcli connection add type team-slave ifname %s con-name %s master %s' % (device, name, master), logfile=context.log, encoding='utf-8')
        r = cli.expect(['Error', pexpect.EOF])
    if master.find("bond") != -1:
        cli = pexpect.spawn('nmcli connection add type bond-slave ifname %s con-name %s master %s' % (device, name, master), logfile=context.log, encoding='utf-8')
        r = cli.expect(['Error', pexpect.EOF])

    if r == 0:
        raise Exception('Got an Error while adding slave connection %s on device %s for master %s\n%s%s' % (name, device, master, cli.after, cli.buffer))



@step(u'Bring "{action}" connection "{name}"')
def start_stop_connection(context, action, name):
    if action == "down":
        if command_code(context, "nmcli connection show --active |grep %s" %name) != 0:
            print ("Warning: Connection is down no need to down it again")
            return

    cli = pexpect.spawn('nmcli connection %s id %s' % (action, name), logfile=context.log,  timeout=180, encoding='utf-8')

    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while %sing connection %s\n%s%s' % (action, name, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli connection %s %s timed out (90s)' % (action, name))
    elif r == 2:
        raise Exception('nmcli connection %s %s timed out (180s)' % (action, name))


@step(u'Bring up connection "{name}" for "{device}" device')
def start_connection_for_device(context, name, device):
    cli = pexpect.spawn('nmcli connection up id %s ifname %s' % (name, device), logfile=context.log,  timeout=180, encoding='utf-8')
    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:

        raise Exception('Got an Error while uping connection %s on %s\n%s%s' % (name, device, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli connection up %s timed out (90s)' % (name))
    elif r == 2:
        raise Exception('nmcli connection up %s timed out (180s)' % (name))


@step(u'Bring up connection "{connection}"')
def bring_up_connection(context, connection):
    cli = pexpect.spawn('nmcli connection up %s' % connection, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while upping connection %s\n%s%s' % (connection, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli connection up %s timed out (180s)' % connection)


@step(u'Bring up connection "{connection}" ignoring error')
def bring_up_connection_ignore_error(context, connection):
    cli = pexpect.spawn('nmcli connection up %s' % connection, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    if r == 1:
        raise Exception('nmcli connection up %s timed out (180s)' % connection)


@step(u'Bring down connection "{connection}"')
def bring_down_connection(context, connection):
    cli = pexpect.spawn('nmcli connection down %s' % connection, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if r == 0:
        raise Exception('Got an Error while downing a connection %s\n%s%s' % (connection, cli.after, cli.buffer))
    elif r == 1:
        raise Exception('nmcli connection down %s timed out (180s)' % connection)


@step(u'Bring down connection "{connection}" ignoring error')
def bring_down_connection_ignoring(context, connection):
    cli = pexpect.spawn('nmcli connection down %s' % connection, timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    if r == 1:
        raise Exception('nmcli connection down %s timed out (180s)' % connection)


@step(u'Bring up connection "{connection}" ignoring everything')
def bring_up_connection_ignore_everything(context, connection):
    subprocess.Popen('nmcli connection up %s' % connection, shell=True)
    sleep(1)


@step(u'Check if "{name}" is active connection')
def is_active_connection(context, name):
    cli = pexpect.spawn('nmcli -t -f NAME connection show --active', logfile=context.log, encoding='utf-8')
    r = cli.expect([name,pexpect.EOF])
    if r == 1:
        raise Exception('Connection %s is not active' % name)


@step(u'Check if "{name}" is not active connection')
def is_nonactive_connection(context, name):
    cli = pexpect.spawn('nmcli -t -f NAME connection show --active', logfile=context.log, encoding='utf-8')
    r = cli.expect([name,pexpect.EOF])
    if r == 0:
        raise Exception('Connection %s is active' % name)


@step(u'Delete connection "{connection}"')
def delete_connection(context,connection):
    cli = pexpect.spawn('nmcli connection delete %s' % connection, timeout = 95, logfile=context.log, encoding='utf-8')
    res = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    if res == 0:
        raise Exception('Got an Error while deleting connection %s\n%s%s' % (connection, cli.after, cli.buffer))
    elif res == 1:
        raise Exception('Deleting connection %s timed out (95s)' % connection)


@step(u'Fail up connection "{name}" for "{device}"')
def fail_up_connection_for_device(context, name, device):
    cli = pexpect.spawn('nmcli connection up id %s ifname %s' % (name, device), logfile=context.log,  timeout=180, encoding='utf-8')
    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    if r == 3:
        raise Exception('nmcli connection up %s for device %s was succesfull. this should not happen' % (name, device))


@step(u'"{user}" is able to see connection "{name}"')
def is_readable(context, user, name):
    cli = pexpect.spawn('sudo -u %s nmcli connection show configured %s' %(user, name), encoding='utf-8')
    if cli.expect(['connection.id:\s+gsm', 'Error', pexpect.TIMEOUT, pexpect.EOF]) != 0:
        raise Exception('Error while getting connection %s' % name)


@step(u'"{user}" is not able to see connection "{name}"')
def is_not_readable(context, user, name):
    cli = pexpect.spawn('sudo -u %s nmcli connection show configured %s' %(user, name), encoding='utf-8')
    if cli.expect(['connection.id:\s+gsm', 'Error', pexpect.TIMEOUT, pexpect.EOF]) == 0:
        raise Exception('Connection %s is readable even if it should not be %s' % name)


@step(u'Modify connection "{name}" changing options "{options}"')
def modify_connection(context, name, options):
    cli = pexpect.spawn('nmcli connection modify %s %s' % (name, options), logfile=context.log, encoding='utf-8')
    if cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF]) == 0:
        raise Exception('Got an Error while modifying %s options %s\n%s%s' % (name,options,cli.after,cli.buffer))


@step(u'Reload connections')
def reload_connections(context):
    command_code(context, "nmcli con reload")
    sleep(0.5)


@step(u'Start generic connection "{connection}" for "{device}"')
def start_generic_connection(context, connection, device):
    cli = pexpect.spawn('nmcli connection up %s ifname %s' % (connection, device), timeout = 180, logfile=context.log, encoding='utf-8')
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    if r != 0:
        raise Exception('nmcli connection up %s timed out (180s)' % connection)
    sleep(4)
