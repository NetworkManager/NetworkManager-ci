import dbus
import IPy
import uuid
import socket
import struct

def ip_to_str(ip):
    return '.'.join(reversed(str(IPy.IP(ip)).split('.')))

def print_ipv4(setting):
    for address in setting["ipv4"]["addresses"]:
        print ip_to_str(address[0]), address[1], ip_to_str(address[2])

def ip_to_int(ip_string):
    return struct.unpack("=I", socket.inet_aton(ip_string))[0]

def int_to_ip(ip_int):
    return socket.inet_ntoa(struct.pack("=I", ip_int))

bus = dbus.SystemBus()

o = bus.get_object('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager/Settings')
s = dbus.Dictionary({
    'connection': {
        'id': 'ethos',
        'uuid': str(uuid.uuid1()),
        'interface-name': 'nonexistant',
        'type': '802-3-ethernet',
    },
    'ipv4': {
        'addresses': dbus.Array([
            [ip_to_int('192.168.1.1'), dbus.UInt32(24L), 0]
        ], signature='au'),
        'method': 'manual'
    },
    '802-3-ethernet': {
    }
}, signature='sa{sv}')
object_path = o.AddConnection(s, dbus_interface='org.freedesktop.NetworkManager.Settings')

o = bus.get_object('org.freedesktop.NetworkManager', object_path)

setting = o.GetSettings(dbus_interface='org.freedesktop.NetworkManager.Settings.Connection')

print "Original state: 1 address without gateway"
print_ipv4(setting)
print

setting["ipv4"]["addresses"].append([ip_to_int('192.168.1.1'), dbus.UInt32(24L), ip_to_int('192.168.1.100')])

print "Updating: add address with gateway"
print_ipv4(setting)
print
o.Update(setting, dbus_interface='org.freedesktop.NetworkManager.Settings.Connection')

