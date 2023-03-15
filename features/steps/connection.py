# pylint: disable=unused-argument,line-too-long,function-redefined
# type: ignore [no-redef]
from behave import step  # pylint: disable=no-name-in-module

import nmci


@step('Add "{typ}" connection with options')
@step('Add "{typ}" connection with options "{options}"')
@step('Add "{typ}" connection named "{name}"')
@step('Add "{typ}" connection named "{name}" with options')
@step('Add "{typ}" connection named "{name}" with options "{options}"')
@step('Add "{typ}" connection named "{name}" for device "{ifname}"')
@step('Add "{typ}" connection named "{name}" for device "{ifname}" with options')
@step(
    'Add "{typ}" connection named "{name}" for device "{ifname}" with options "{options}"'
)
def add_new_connection(context, typ, name=None, ifname=None, options=None):
    conn_name = ""
    if name is not None:
        nmci.cleanup.cleanup_add_connection(name)
        conn_name = f"con-name {name}"

    iface = ""
    if ifname is not None:
        nmci.cleanup.cleanup_add_iface(ifname)
        iface = f"ifname {ifname}"

    if options is None:
        options = context.text.replace("\n", " ") if context.text is not None else " "
    options = nmci.misc.str_replace_dict(options, context.noted)

    nmci.process.nmcli(f"connection add type {typ} {conn_name} {iface} {options}")


@step('Add "{count}" "{typ}" connections named "{name}" for devices "{ifname}"')
@step(
    'Add "{count}" "{typ}" connections named "{name}" for devices "{ifname}" with options'
)
@step(
    'Add "{count}" "{typ}" connections named "{name}" for devices "{ifname}" with options "{options}"'
)
def add_multiple_new_connections(
    context, count, typ, name=None, ifname=None, options=None
):
    for i in range(int(count)):
        _con_name = f"{name}_{i}"
        _dev_name = f"{ifname}_{i}"
        add_new_connection(context, typ, _con_name, _dev_name, options)


@step(
    'Add insecure "{typ}" connection named "{name}" for device "{ifname}" with options'
)
def add_insecure(context, typ, name, ifname):
    nmci.cleanup.cleanup_add_connection(name)
    options = context.text.replace("\n", " ") if context.text is not None else " "
    options = nmci.misc.str_replace_dict(options, context.noted)
    command = f"con add type {typ} con-name {name} ifname {ifname} {options}"
    result = nmci.process.nmcli_force(command)

    message = ""
    if result.stdout:
        message += f"\nSTDOUT:\n{result.stdout}\n"
    if result.stderr:
        message += f"\nSTDERR:\n{result.stderr}\n"

    assert (
        result.returncode == 0
    ), f"Command `nmcli {command}` returned {result.returncode}\n{message}"
    assert (
        "Error" not in result.stdout
    ), f"Command `nmcli {command}` returned {result.returncode}\nprinted 'Error' in STDOUT\n{message}"

    err_split = result.stderr.strip("\n").split("\n")
    err_filter = [line for line in err_split if line and "Warning" not in line]
    assert (
        not err_filter
    ), f"Command `nmcli {command}` returned {result.returncode}\nprinted more than 'Warning' to STDERR\n{message}"


@step(
    'Add infiniband port named "{name}" for device "{ifname}" with parent "{parent}" and p-key "{pkey}"'
)
def add_port(context, name, ifname, parent, pkey):
    nmci.process.nmcli(
        f"connection add type infiniband con-name {name} ifname {ifname} parent {parent} p-key {pkey}"
    )


@step('Modify connection "{connection}" property "{prop}" to noted value')
@step('Modify connection "{connection}" property "{prop}" to noted value "{index}"')
def modify_connection_with_noted(context, connection, prop, index="noted-value"):
    nmci.process.nmcli(f"connection modify {connection} {prop} {context.noted[index]}")


@step('Add slave connection for master "{master}" on device "{device}" named "{name}"')
def open_slave_connection(context, master, device, name):
    if "team" in master:
        con_type = "team-slave"
    elif "bond" in master:
        con_type = "bond-slave"
    else:
        raise ValueError("could not guess connection type")

    nmci.cleanup.cleanup_add_connection(name)
    nmci.cleanup.cleanup_add_iface(device)

    nmci.process.nmcli(
        f"connection add type {con_type} ifname {device} con-name {name} master {master}"
    )


@step('Bring "{action}" connection "{name}"')
@step('Bring "{action}" connection "{name}" for "{device}" device')
def start_stop_connection(context, name, action, device=""):
    if action == "down":
        if name not in nmci.process.nmcli("connection show --active"):
            print("Warning: Connection is down no need to down it again")
            return
    if device:
        device = f"ifname {device}"

    nmci.process.nmcli(f"connection {action} id {name} {device}", timeout=180)


@step('Bring "{action}" connection "{name}" ignoring error')
def bring_up_connection_ignore_error(context, name, action):
    nmci.process.nmcli_force(f"connection {action} id {name}", timeout=180)


@step('Check if "{name}" is active connection')
def is_active_connection(context, name):
    active_list = nmci.process.nmcli("-t -f NAME connection show --active").split("\n")
    assert name in active_list, f"Connection {name} is not active"


@step('Check if "{name}" is not active connection')
def is_nonactive_connection(context, name):
    active_list = nmci.process.nmcli("-t -f NAME connection show --active").split("\n")
    assert name not in active_list, f"Connection {name} is not active"


@step('Delete connection "{name}"')
def delete_connection(context, name):
    nmci.process.nmcli(f"connection delete {name}", timeout=95)


@step('Fail up connection "{name}" for "{device}"')
def fail_up_connection_for_device(context, name, device):
    try:
        nmci.process.nmcli(f"connection up id {name}", timeout=180)
    except Exception:  # pylint: disable=broad-except
        return
    raise Exception(
        f"nmcli connection up {name} for device {device} was succesfull. this should not happen"
    )


@step('Modify connection "{name}" changing options "{options}"')
@step('Modify connection "{name}" changing options')
def modify_connection(context, name, options=None):
    if options is None:
        options = context.text.replace("\n", " ") if context.text is not None else " "
    options = nmci.misc.str_replace_dict(options, context.noted)
    nmci.process.nmcli(f"con modify {name} {options}")


@step("Wait for testeth0")
def wait_for_eth0(context):
    nmci.veth.wait_for_testeth0()


@step("Reload connections")
def reload_connections(context):
    nmci.nmutil.reload_NM_connections()


def libnm_get_connection(nm_client, con_name):
    con = None
    for connection in nm_client.get_connections():
        if connection.get_id() == con_name:
            assert not con, f"multiple connections with id '{con_name}'"
            con = connection
    assert con, f"no connection with id '{con_name}'"
    return con


def parse_nm_settings_flags_string(nm_flags, flags):
    flags = [f.strip() for f in flags.split(",")]
    nm_flags = nm_flags.NONE
    for flag in flags:
        if flag:
            nm_flags |= getattr(nm_flags, flag)
    return nm_flags


@step('Add connection with name "{name}" and uuid "{uuid}" using libnm')
@step(
    'Add connection with name "{name}" and uuid "{uuid}" using libnm with flags "{flags}"'
)
def add_connection(context, name, uuid, flags="TO_DISK"):
    nmci.cleanup.cleanup_add_connection(name)

    NM = nmci.util.NM  # pylint: disable=invalid-name
    GLib = nmci.util.GLib  # pylint: disable=invalid-name

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    if uuid == "random":
        uuid = NM.utils_uuid_generate()
    elif uuid == "noted":
        uuid = context.noted["noted-value"]
    elif uuid.startswith("noted."):
        index = uuid.replace("noted.", "")
        uuid = context.noted[index]
    nm_flags = parse_nm_settings_flags_string(NM.SettingsAddConnection2Flags, flags)

    con2 = NM.SimpleConnection()
    s_con = NM.SettingConnection(type="802-3-ethernet", id=name, uuid=uuid)
    con2.add_setting(s_con)

    result = {}

    def _add_connection2_cb(cli, async_result, user_data):
        try:
            nm_client.add_connection2_finish(async_result)
        except Exception as exc:  # pylint: disable=broad-except
            result["error"] = exc
        main_loop.quit()

    nm_client.add_connection2(
        con2.to_dbus(NM.ConnectionSerializationFlags.ALL),
        nm_flags,
        None,
        False,
        None,
        _add_connection2_cb,
        None,
    )

    main_loop.run()

    assert "error" not in result, f'Add connection {name} failed: {result["error"]}'


@step('Clone connection "{con_src}" to "{con_dst}" using libnm')
@step('Clone connection "{con_src}" to "{con_dst}" using libnm with flags "{flags}"')
def clone_connection(context, con_src, con_dst, flags="TO_DISK"):
    nmci.cleanup.cleanup_add_connection(con_dst)

    NM = nmci.util.NM  # pylint: disable=invalid-name
    GLib = nmci.util.GLib  # pylint: disable=invalid-name

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    con = libnm_get_connection(nm_client, con_src)
    nm_flags = parse_nm_settings_flags_string(NM.SettingsAddConnection2Flags, flags)

    con2 = NM.SimpleConnection.new_clone(con)
    s_con = con2.get_setting_connection()
    s_con.set_property(NM.SETTING_CONNECTION_ID, con_dst)
    s_con.set_property(NM.SETTING_CONNECTION_UUID, NM.utils_uuid_generate())
    result = {}

    def _add_connection2_cb(cli, async_result, user_data):
        try:
            nm_client.add_connection2_finish(async_result)
        except Exception as exc:  # pylint: disable=broad-except
            result["error"] = exc
        main_loop.quit()

    nm_client.add_connection2(
        con2.to_dbus(NM.ConnectionSerializationFlags.ALL),
        nm_flags,
        None,
        False,
        None,
        _add_connection2_cb,
        None,
    )

    main_loop.run()

    assert (
        "error" not in result
    ), f'Clone connection {con_dst} failed: {result["error"]}'


@step('Update connection "{con_name}" changing options "{options}" using libnm')
@step(
    'Update connection "{con_name}" changing options "{options}" using libnm with flags "{flags}"'
)
def update2_connection_autoconnect(context, con_name, options, flags=""):
    NM = nmci.util.NM  # pylint: disable=invalid-name
    GLib = nmci.util.GLib  # pylint: disable=invalid-name

    main_loop = GLib.MainLoop()
    nm_client = NM.Client.new(None)
    con = libnm_get_connection(nm_client, con_name)
    nm_flags = parse_nm_settings_flags_string(NM.SettingsUpdate2Flags, flags)

    con2 = NM.SimpleConnection.new_clone(con)
    s_con = con2.get_setting_connection()
    for option in options.split(","):
        option = [o.strip() for o in option.split(":")]
        if len(option) == 3:
            if option[1].lower().startswith("i"):
                option[1] = int(option[2])
            elif option[1].lower().startswith("f"):
                option[1] = float(option[2])
            elif option[1].lower().startswith("b"):
                if option[2].lower().startswith("t"):
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
        except Exception as exc:  # pylint: disable=broad-except
            result["error"] = exc
        main_loop.quit()

    con.update2(
        con2.to_dbus(NM.ConnectionSerializationFlags.ALL),
        nm_flags,
        None,
        None,
        _update2_cb,
        None,
    )

    main_loop.run()

    assert (
        "error" not in result
    ), f'Update connection {con_name} failed: {result["error"]}'


@step(
    'Add bridges over VLANs in range from "{begin}" to "{end}" on interface "{ifname}" via libnm'
)
def add_bridges_vlans_range(context, begin, end, ifname):
    begin = int(begin)
    end = int(end)
    assert begin > 0, f"invalid range: begin is not positive integer: {begin}"
    assert end > 0, f"invalid range: end is not positive integer: {end}"
    assert begin <= end, f"invalid range: begin is not less than end: {begin} > {end}"

    vlan_range = [f"{ifname}.{id}" for id in range(begin, end + 1)]
    vlan_range += [f"br{id}" for id in range(begin, end + 1)]
    context.vlan_range = getattr(context, "vlan_range", [])
    context.vlan_range += vlan_range

    NM = nmci.util.NM  # pylint: disable=invalid-name
    GLib = nmci.util.GLib  # pylint: disable=invalid-name

    nm_client = NM.Client.new(None)
    result = {}

    def _add_connection_cb(cli, async_result, user_data):
        try:
            cli.add_connection_finish(async_result)
        except Exception as exc:  # pylint: disable=broad-except
            result["error"] = exc
        if user_data is not None:
            user_data.quit()

    for i in range(begin, end + 1):
        main_loop = GLib.MainLoop()
        con = NM.SimpleConnection.new()
        uuid = NM.utils_uuid_generate()
        s_con = NM.SettingConnection(type="bridge", id=f"br{i}", uuid=uuid)
        s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, f"br{i}")
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
        s_con = NM.SettingConnection(type="vlan", id=f"{ifname}.{i}", uuid=uuid)
        s_con.set_property(NM.SETTING_CONNECTION_INTERFACE_NAME, f"{ifname}.{i}")
        s_con.set_property(NM.SETTING_CONNECTION_SLAVE_TYPE, "bridge")
        s_con.set_property(NM.SETTING_CONNECTION_MASTER, f"br{i}")
        s_vlan = NM.SettingVlan(id=i, parent=ifname)
        con.add_setting(s_con)
        con.add_setting(s_vlan)
        nm_client.add_connection_async(con, True, None, _add_connection_cb, main_loop)
        main_loop.run()

        assert "error" not in result, f"add connection {i} failed: {result['error']}"


@step('Cleanup connection "{connection}"')
@step('Cleanup connection "{connection}" and device "{device}"')
def cleanup_connection(context, connection, device=None):
    nmci.cleanup.cleanup_add_connection(connection)
    if device is not None:
        context.execute_steps(f'* Cleanup device "{device}"')


@step('Note the value of property "{prop}" of connection "{con}"')
@step(
    'Note the value of property "{prop}" of connection "{con}" as noted value "{index}"'
)
def note_gotten_value(context, prop, con, index="noted-value"):
    if not hasattr(context, "noted"):
        context.noted = {}
    context.noted[index] = nmci.process.nmcli(f"-g {prop} c s {con}")
