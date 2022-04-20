import pexpect
import time
from behave import step

import nmci.lib


@step(u'Add a connection named "{name}" for device "{ifname}" to "{vpn}" VPN')
def add_vpnc_connection_for_iface(context, name, ifname, vpn):
    cli = context.pexpect_spawn('nmcli connection add con-name %s type vpn ifname %s vpn-type %s' % (name, ifname, vpn))
    r = cli.expect(['Error', pexpect.EOF])
    time.sleep(1)
    assert r != 0, 'Got an Error while adding %s connection %s for device %s\n%s%s' % (vpn, name, ifname, cli.after, cli.buffer)
    
    context.cleanup["connections"].add(name)


@step(u'Add "{typ}" connection with options')
@step(u'Add "{typ}" connection with options "{options}"')
@step(u'Add "{typ}" connection named "{name}"')
@step(u'Add "{typ}" connection named "{name}" with options')
@step(u'Add "{typ}" connection named "{name}" with options "{options}"')
@step(u'Add "{typ}" connection named "{name}" for device "{ifname}"')
@step(u'Add "{typ}" connection named "{name}" for device "{ifname}" with options')
@step(u'Add "{typ}" connection named "{name}" for device "{ifname}" with options "{options}"')
def add_new_connection(context, typ, name=None, ifname=None, options=None):
    if options is None:
        options = context.text.replace("\n", " ") if context.text is not None else " "
    conn_name = f"con-name {name}" if name is not None else ""
    iface = f"ifname {ifname}" if ifname is not None else ""

    cli = context.pexpect_spawn(f"nmcli connection add type {typ} {conn_name} {iface} {options}", shell=True)
    assert cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF]) == 2, \
        'Got an Error while creating connection of type %s with options %s\n%s%s' % (typ, options, cli.after, cli.buffer)

    if name is not None:
        context.cleanup["connections"].add(name)
    if ifname is not None:
        nmci.lib.add_iface_to_cleanup(context, ifname)


@step(u'Add infiniband port named "{name}" for device "{ifname}" with parent "{parent}" and p-key "{pkey}"')
def add_port(context, name, ifname, parent, pkey):
    cli = context.pexpect_spawn('nmcli connection add type infiniband con-name %s ifname %s parent %s p-key %s' % (name, ifname, parent, pkey))
    r = cli.expect(['Error', pexpect.EOF])
    assert r == 1, 'Got an Error while adding %s connection %s for device %s\n%s%s' % (name, ifname, cli.after, cli.buffer)
    time.sleep(1)


@step(u'Modify connection "{connection}" property "{prop}" to noted value')
def modify_connection_with_noted(context, connection, prop):
    cli = context.pexpect_spawn('nmcli connection modify %s %s %s' % (connection, prop, context.noted['noted-value']))
    r = cli.expect(['Error', pexpect.EOF])
    assert r == 1, 'Got an Error while changing %s property for connection %s to %s\n%s%s' % (prop, connection, context.noted['noted-value'], cli.after, cli.buffer)


@step(u'Add slave connection for master "{master}" on device "{device}" named "{name}"')
def open_slave_connection(context, master, device, name):
    if master.find("team") != -1:
        cli = context.pexpect_spawn('nmcli connection add type team-slave ifname %s con-name %s master %s' % (device, name, master))
        r = cli.expect(['Error', pexpect.EOF])
    if master.find("bond") != -1:
        cli = context.pexpect_spawn('nmcli connection add type bond-slave ifname %s con-name %s master %s' % (device, name, master))
        r = cli.expect(['Error', pexpect.EOF])

    assert r == 1, 'Got an Error while adding slave connection %s on device %s for master %s\n%s%s' % (name, device, master, cli.after, cli.buffer)
    context.cleanup["connections"].add(name)
    nmci.lib.add_iface_to_cleanup(context, device)


@step(u'Bring "{action}" connection "{name}"')
def start_stop_connection(context, action, name):
    if action == "down":
        if context.command_code("nmcli connection show --active |grep %s" % name) != 0:
            print("Warning: Connection is down no need to down it again")
            return

    cli = context.pexpect_spawn('nmcli connection %s id %s' % (action, name),  timeout=180)

    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, 'Got an Error while %sing connection %s\n%s%s' % (action, name, cli.after, cli.buffer)
    assert r != 1, 'nmcli connection %s %s timed out (90s)' % (action, name)
    assert r != 2, 'nmcli connection %s %s timed out (180s)' % (action, name)


@step(u'Bring up connection "{name}" for "{device}" device')
def start_connection_for_device(context, name, device):
    cli = context.pexpect_spawn('nmcli connection up id %s ifname %s' % (name, device),  timeout=180)
    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, 'Got an Error while uping connection %s on %s\n%s%s' % (name, device, cli.after, cli.buffer)
    assert r != 1, 'nmcli connection up %s timed out (90s)' % (name)
    assert r != 2, 'nmcli connection up %s timed out (180s)' % (name)


@step(u'Bring up connection "{connection}"')
def bring_up_connection(context, connection):
    cli = context.pexpect_spawn('nmcli connection up %s' % connection, timeout=180)
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, 'Got an Error while upping connection %s\n%s%s' % (connection, cli.after, cli.buffer)
    assert r != 1, 'nmcli connection up %s timed out (180s)' % connection


@step(u'Bring up connection "{connection}" ignoring error')
def bring_up_connection_ignore_error(context, connection):
    cli = context.pexpect_spawn('nmcli connection up %s' % connection, timeout=180)
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    assert r != 1, 'nmcli connection up %s timed out (180s)' % connection


@step(u'Bring down connection "{connection}"')
def bring_down_connection(context, connection):
    cli = context.pexpect_spawn('nmcli connection down %s' % connection, timeout=180)
    r = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    assert r != 0, 'Got an Error while downing a connection %s\n%s%s' % (connection, cli.after, cli.buffer)
    assert r != 1, 'nmcli connection down %s timed out (180s)' % connection


@step(u'Bring down connection "{connection}" ignoring error')
def bring_down_connection_ignoring(context, connection):
    cli = context.pexpect_spawn('nmcli connection down %s' % connection, timeout=180)
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    assert r != 1, 'nmcli connection down %s timed out (180s)' % connection


@step(u'Check if "{name}" is active connection')
def is_active_connection(context, name):
    cli = context.pexpect_spawn('nmcli -t -f NAME connection show --active')
    r = cli.expect([name, pexpect.EOF])
    assert r == 0, 'Connection %s is not active' % name


@step(u'Check if "{name}" is not active connection')
def is_nonactive_connection(context, name):
    cli = context.pexpect_spawn('nmcli -t -f NAME connection show --active')
    r = cli.expect([name, pexpect.EOF])
    assert r == 1, 'Connection %s is active' % name


@step(u'Delete connection "{connection}"')
def delete_connection(context, connection):
    cli = context.pexpect_spawn('nmcli connection delete %s' % connection, timeout=95)
    res = cli.expect(['Error', pexpect.TIMEOUT, pexpect.EOF])
    assert res != 0, 'Got an Error while deleting connection %s\n%s%s' % (connection, cli.after, cli.buffer)
    assert res != 1, 'Deleting connection %s timed out (95s)' % connection


@step(u'Fail up connection "{name}" for "{device}"')
def fail_up_connection_for_device(context, name, device):
    cli = context.pexpect_spawn('nmcli connection up id %s ifname %s' % (name, device),  timeout=180)
    r = cli.expect(['Error', 'Timeout', pexpect.TIMEOUT, pexpect.EOF])
    assert r != 3, 'nmcli connection up %s for device %s was succesfull. this should not happen' % (name, device)


@step(u'"{user}" is able to see connection "{name}"')
def is_readable(context, user, name):
    cli = context.pexpect_spawn('sudo -u %s nmcli connection show configured %s' % (user, name))
    assert cli.expect(['connection.id:\\s+gsm', 'Error', pexpect.TIMEOUT, pexpect.EOF]) == 0, \
        'Error while getting connection %s' % name


@step(u'"{user}" is not able to see connection "{name}"')
def is_not_readable(context, user, name):
    cli = context.pexpect_spawn('sudo -u %s nmcli connection show configured %s' % (user, name))
    assert cli.expect(['connection.id:\\s+gsm', 'Error', pexpect.TIMEOUT, pexpect.EOF]) != 0, \
        'Connection %s is readable even if it should not be %s' % name


@step(u'Modify connection "{name}" changing options "{options}"')
def modify_connection(context, name, options):
    out = context.command_output("nmcli connection modify %s %s" % (name, options))
    assert 'Error' not in out, 'Got an Error while modifying %s options %s\n%s' % (name, options, out)


@step(u'Reload connections')
def reload_connections(context):
    nmci.lib.reload_NM_connections(context)
    time.sleep(0.5)


@step(u'Start generic connection "{connection}" for "{device}"')
def start_generic_connection(context, connection, device):
    cli = context.pexpect_spawn('nmcli connection up %s ifname %s' % (connection, device), timeout=180)
    r = cli.expect([pexpect.EOF, pexpect.TIMEOUT])
    assert r == 0, 'nmcli connection up %s timed out (180s)' % connection
    time.sleep(4)


def libnm_get_connection(nm_client, con_name):
    con = None
    for c in nm_client.get_connections():
        if c.get_id() == con_name:
            assert not con, "multiple connections with id '%s'" % con_name
            con = c
    assert con, "no connection with id '%s'" % con_name
    return con


def parse_NM_settings_flags_string(NMflags, flags):
    flags = [f.strip() for f in flags.split(',')]
    nm_flags = NMflags.NONE
    for flag in flags:
        if flag:
            nm_flags |= getattr(NMflags, flag)
    return nm_flags


@step(u'Add connection with name "{name}" and uuid "{uuid}" using libnm')
@step(u'Add connection with name "{name}" and uuid "{uuid}" using libnm with flags "{flags}"')
def add_connection(context, name, uuid, flags="TO_DISK"):
    import gi
    gi.require_version('NM', '1.0')
    from gi.repository import GLib, NM

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    if uuid == "random":
        uuid = NM.utils_uuid_generate()
    elif uuid == "noted":
        uuid = context.noted['noted-value']
    elif uuid.startswith("noted."):
        index = uuid.replace("noted.", "")
        uuid = context.noted[index]
    nm_flags = parse_NM_settings_flags_string(NM.SettingsAddConnection2Flags, flags)

    con2 = NM.SimpleConnection()
    s_con = NM.SettingConnection(type="802-3-ethernet", id=name, uuid=uuid)
    con2.add_setting(s_con)

    result = {}
    context.cleanup["connections"].add(name)

    def _add_connection2_cb(cl, async_result, user_data):
        try:
            nm_client.add_connection2_finish(async_result)
        except Exception as e:
            result['error'] = e
        main_loop.quit()

    nm_client.add_connection2(con2.to_dbus(NM.ConnectionSerializationFlags.ALL), nm_flags, None, False, None, _add_connection2_cb, None)

    main_loop.run()

    assert 'error' not in result, \
        'add connection %s failed: %s' % (name, result['error'])


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

    assert 'error' not in result, \
        'add connection %s failed: %s' % (con_dst, result['error'])
    context.cleanup["connections"].add(con_dst)


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
        option = [o.strip() for o in option.split(':')]
        if len(option) == 3:
            if option[1].lower().startswith('i'):
                option[1] = int(option[2])
            elif option[1].lower().startswith('f'):
                option[1] = float(option[2])
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

    assert 'error' not in result, \
        'update2 connection %s failed: %s' % (con_name, result['error'])


@step(u'Add bridges over VLANs in range from "{begin}" to "{end}" on interface "{ifname}" via libnm')
def add_bridges_vlans_range(context, begin, end, ifname):
    try:
        begin = int(begin)
        end = int(end)
        assert begin > 0, f"invalid range: begin is not positive integer: {begin}"
        assert end > 0, f"invalid range: end is not positive integer: {end}"
        assert begin <= end, f"invalid range: begin is not less than end: {begin} > {end}"
    except Exception:
        assert False, f"begin and end must be positive integers: {begin}, {end}"

    vlan_range = [f"{ifname}.{id}" for id in range(begin, end+1)]
    vlan_range += [f"br{id}" for id in range(begin, end+1)]
    context.vlan_range = getattr(context, "vlan_range", [])
    context.vlan_range += vlan_range

    from nmci.util import GLib, NM
    nm_client = NM.Client.new(None)
    result = {}

    def _add_connection_cb(cl, async_result, user_data):
        try:
            cl.add_connection_finish(async_result)
        except Exception as e:
            result['error'] = e
        if user_data is not None:
            user_data.quit()

    for id in range(begin, end+1):

        main_loop = GLib.MainLoop()
        con = NM.SimpleConnection.new()
        uuid = NM.utils_uuid_generate()
        s_con = NM.SettingConnection(type="bridge", id=f"br{id}", uuid=uuid)
        s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, f"br{id}")
        s_bridge = NM.SettingBridge.new()
        s_ip4 = NM.SettingIP4Config.new()
        s_ip4.set_property(NM.SETTING_IP_CONFIG_METHOD, "disabled")
        s_ip6 = NM.SettingIP6Config.new()
        s_ip6.set_property(NM.SETTING_IP_CONFIG_METHOD, "disabled")
        con.add_setting(s_con)
        con.add_setting(s_bridge)
        con.add_setting(s_ip4)
        con.add_setting(s_ip6)
        nm_client.add_connection_async(con, True, None, _add_connection_cb, main_loop)
        main_loop.run()

        main_loop = GLib.MainLoop()
        con = NM.SimpleConnection.new()
        uuid = NM.utils_uuid_generate()
        s_con = NM.SettingConnection(type="vlan", id=f"{ifname}.{id}", uuid=uuid)
        s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, f"{ifname}.{id}")
        s_con.set_property(NM.SETTING_CONNECTION_SLAVE_TYPE, "bridge")
        s_con.set_property(NM.SETTING_CONNECTION_MASTER, f"br{id}")
        s_vlan = NM.SettingVlan(id=id, parent=ifname)
        con.add_setting(s_con)
        con.add_setting(s_vlan)
        nm_client.add_connection_async(con, True, None, _add_connection_cb, main_loop)
        main_loop.run()

        assert 'error' not in result, \
            f"add connection {id} failed: {result['error']}"


@step(u'Cleanup connection "{connection}"')
@step(u'Cleanup connection "{connection}" and device "{device}"')
def cleanup_connection(context, connection, device=None):
    context.cleanup["connections"].add(connection)
    if device is not None:
        context.execute_steps(f'* Cleanup device "{device}"')