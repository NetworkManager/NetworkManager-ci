import gi

gi.require_version("NM", "1.0")
from gi.repository import GLib, NM

###############################################################################


def abort(msg):
    raise AssertionError("%s" % (msg))


def mainloop_run(main_loop, timeout_ms=None):
    if timeout_ms is None:
        main_loop.run()
        return True

    result = []

    def _timeout_cb(unused):
        result.append(1)
        main_loop.quit()
        return False

    timeout_id = GLib.timeout_add(timeout_ms, _timeout_cb, None)
    main_loop.run()
    if result:
        return False
    GLib.source_remove(timeout_id)
    return True


def mainloop_run_assert(main_loop, timeout_ms=None):
    if not mainloop_run(main_loop, timeout_ms):
        abort("Timeout reached while iterating the mainloop waiting for something")


def find_connection(nm_client, connection_name):
    for c in nm_client.get_connections():
        if c.get_id() == connection_name:
            return c
    abort('Cannot find connection "%s"' % (connection_name))


###############################################################################

CONNECTION_NAME = "con_con2"

nm_client = NM.Client.new(None)

main_loop = GLib.MainLoop()

con = find_connection(nm_client, CONNECTION_NAME)
if con.get_setting_connection().get_property(NM.SETTING_CONNECTION_AUTOCONNECT):
    abort("autoconnect property has unexpected value (1)")

con2 = NM.SimpleConnection.new_clone(con)
con2.get_setting_connection().set_property(NM.SETTING_CONNECTION_AUTOCONNECT, 1)

update2_result = []


def update2_cb(con, async_result, user_data):
    try:
        r = con.update2_finish(async_result)
    except Exception as e:
        pass
    else:
        update2_result.append(1)
    main_loop.quit()


con.update2(
    con2.to_dbus(NM.ConnectionSerializationFlags.ALL),
    NM.SettingsUpdate2Flags.BLOCK_AUTOCONNECT,
    None,
    None,
    update2_cb,
    None,
)

mainloop_run_assert(main_loop, 2000)

if not update2_result:
    abort("failure to update connection")


con = find_connection(nm_client, CONNECTION_NAME)
if con.get_setting_connection().get_property(NM.SETTING_CONNECTION_AUTOCONNECT):
    # at this point, the value is not yet changed. I guess,
    # this is a bug in libnm, but assert against this presumably
    # undesired behavior. Maybe we should fix this (TODO).
    abort("autoconnect property has unexpected value (2)")


# wait for the connection to change...
signal_id = con.connect("changed", lambda con: main_loop.quit())
mainloop_run_assert(main_loop, 1000)
con.disconnect(signal_id)


con = find_connection(nm_client, CONNECTION_NAME)
if not con.get_setting_connection().get_property(NM.SETTING_CONNECTION_AUTOCONNECT):
    # now finally we expect the the autoconnect property is as
    # desired
    abort("autoconnect property has unexpected value (3)")
