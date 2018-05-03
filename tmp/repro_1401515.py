import gi
from gi.repository import NM
gi.require_version('NM', '1.0')
from time import sleep

connection_name = 'con_con2'
nm_client = NM.Client.new(None)

con = None
for x in xrange(1,4):
    for c in nm_client.get_connections():
        if c.get_id() == connection_name:
            con = c
            break
    if con == None:
        sleep(2)
    else:
        break

con2 = NM.SimpleConnection.new_clone(con)
s_con = con2.get_setting_connection()
s_con.set_property(NM.SETTING_CONNECTION_AUTOCONNECT, 1)

con.update2(con2.to_dbus(NM.ConnectionSerializationFlags.ALL),
            NM.SettingsUpdate2Flags.BLOCK_AUTOCONNECT,
            None,
            None,
            None,
            None)

sleep(5)
