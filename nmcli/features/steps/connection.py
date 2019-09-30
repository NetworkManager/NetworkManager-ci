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


def libnm_get_connection(nm_client, con_name):
    con = None
    for c in nm_client.get_connections():
        if c.get_id() == con_name:
            if con:
                raise Exception("multiple connections with id '%s'" % con_name)
            con = c
    if not con:
        raise Exception("no connection with id '%s'" % con_name)
    return con

def parse_NM_settings_flags_string(NMflags, flags):
    flags = [ f.strip() for f in flags.split(',')]
    nm_flags = NMflags.NONE
    for flag in flags:
        if flag:
            nm_flags |= getattr(NMflags, flag)
    return nm_flags


@step(u'Add connection with name "{name}" and uuid "{uuid}" using libnm')
@step(u'Add connection with name "{name}" and uuid "{uuid}" using libnm with flags "{flags}"')
def clone_connection(context, name, uuid, flags="TO_DISK"):
    import gi
    gi.require_version('NM', '1.0')
    from gi.repository import GLib, NM

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    if uuid == "random":
        uuid = NM.utils_uuid_generate()
    elif uuid == "noted":
        uuid = context.noted_value
    elif uuid.startswith("noted."):
        index = uuid.replace("noted.","")
        uuid = context.noted[index]
    nm_flags = parse_NM_settings_flags_string(NM.SettingsAddConnection2Flags, flags)

    con2 = NM.SimpleConnection()
    s_con = NM.SettingConnection(type="802-3-ethernet", id=name, uuid=uuid)
    con2.add_setting(s_con)

    result = {}

    def _add_connection2_cb(cl, async_result, user_data):
        try:
            nm_client.add_connection2_finish(async_result)
        except Exception as e:
            result['error'] = e
        main_loop.quit()

    nm_client.add_connection2(con2.to_dbus(NM.ConnectionSerializationFlags.ALL), nm_flags, None, False, None, _add_connection2_cb, None)

    main_loop.run()

    if 'error' in result:
        raise Exception('add connection %s failed: %s' % (name, result['error']))


@step(u'Clone connection "{con_src}" to "{con_dst}" using libnm')
@step(u'Clone connection "{con_src}" to "{con_dst}" using libnm with flags "{flags}"')
def clone_connection(context, con_src, con_dst, flags="TO_DISK"):
    import gi
    gi.require_version('NM', '1.0')
    from gi.repository import GLib, NM

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    con = libnm_get_connection(nm_client, con_src)
    nm_flags = parse_NM_settings_flags_string(NM.SettingsAddConnection2Flags, flags)

    con2 = NM.SimpleConnection.new_clone(con)
    s_con = con2.get_setting_connection()
    s_con.set_property(NM.SETTING_CONNECTION_ID, con_dst)
    s_con.set_property(NM.SETTING_CONNECTION_UUID, NM.utils_uuid_generate())
    result = {}

    def _add_connection2_cb(cl, async_result, user_data):
        try:
            nm_client.add_connection2_finish(async_result)
        except Exception as e:
            result['error'] = e
        main_loop.quit()

    nm_client.add_connection2(con2.to_dbus(NM.ConnectionSerializationFlags.ALL), nm_flags, None, False, None, _add_connection2_cb, None)

    main_loop.run()

    if 'error' in result:
        raise Exception('add connection %s failed: %s' % (con_dst, result['error']))


@step(u'Update connection "{con_name}" changing options "{options}" using libnm')
@step(u'Update connection "{con_name}" changing options "{options}" using libnm with flags "{flags}"')
def update2_connection_autoconnect(context, con_name, options, flags=""):
    import gi
    gi.require_version('NM', '1.0')
    from gi.repository import GLib, NM

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    con = libnm_get_connection(nm_client, con_name)
    nm_flags = parse_NM_settings_flags_string(NM.SettingsUpdate2Flags, flags)

    con2 = NM.SimpleConnection.new_clone(con)
    s_con = con2.get_setting_connection()
    for option in options.split(','):
        option = [ o.strip() for o in option.split(':') ]
        if len(option) == 3:
            if option[1].lower().startswith('i'):
                option[1]= int(option[2])
            elif option[1].lower().startswith('f'):
                option[1]= float(option[2])
            elif option[1].lower().startswith('b'):
                if option[2].lower().startswith('t'):
                    option[1] = True
                else:
                    option[1] = False
            else:
                option[1] = option[2]
        value = option[1]
        s_con.set_property(getattr(NM, option[0]), value)

    result = {}

    def _update2_cb(con, async_result, user_data):
        try:
            con.update2_finish(async_result)
        except Exception as e:
            result['error'] = e
        main_loop.quit()

    con.update2(con2.to_dbus(NM.ConnectionSerializationFlags.ALL), nm_flags, None, None, _update2_cb, None)

    main_loop.run()

    if 'error' in result:
        raise Exception('update2 connection %s failed: %s' % (con_name, result['error']))
