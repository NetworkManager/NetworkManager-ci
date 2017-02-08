import dbus
import logging
import uuid
import socket
import struct
import time

NM_BUS = "org.freedesktop.NetworkManager"
OBJ_PRE = "/org/freedesktop/NetworkManager"
IF_PRE = NM_BUS

def main():
    s_bond_con = dbus.Dictionary({
        'type' : 'bond',
        'autoconnect' : dbus.Boolean(False),
        'uuid' : str(uuid.uuid4()),
        'id' : 'bond0'})
    s_bond = dbus.Dictionary({
        'interface-name' : 'nm-bond',
        'options' : {'mode' : '1',
                     'miimon' : '100'}})
    s_ipv4 = []
    address = '192.168.222.1'
    ip = struct.unpack("=I", socket.inet_pton(socket.AF_INET, address))[0]
    s_ipv4.append(dbus.Array([ip, '24', 0], signature='u'))
    ipv4 = dbus.Dictionary({
	'addresses' : s_ipv4,
	'method' : 'manual'}, signature='sv')
    connection = dbus.Dictionary({
        'bond' : s_bond,
        'ipv4' : ipv4,
        'connection' : s_bond_con})
    bus = dbus.SystemBus()
    settings_obj = bus.get_object(NM_BUS, OBJ_PRE + "/Settings")
    settings_if = dbus.Interface(settings_obj, IF_PRE + ".Settings")
    con_obj_path = settings_if.AddConnection(connection)
    logging.debug("Added NM connection: %s" % con_obj_path) 
    print ("%s" % con_obj_path)
    nm_obj = bus.get_object(NM_BUS, OBJ_PRE)
    nm_if = dbus.Interface(nm_obj, IF_PRE)
    time.sleep(1)
    try:
        device_obj_path = nm_if.GetDeviceByIpIface("nm-bond")
    except:
        device_obj_path = "/"
    acon_obj_path = nm_if.ActivateConnection(con_obj_path,
                                             device_obj_path, "/")
    act_con = bus.get_object(NM_BUS, acon_obj_path)
    act_con_props = dbus.Interface(act_con, "org.freedesktop.DBus.Properties" )
    
    

if __name__ == "__main__":
    main()
