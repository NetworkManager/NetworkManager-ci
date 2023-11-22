#!/usr/bin/env python3

import dbus
import re


BUS_NAME = "org.freedesktop.NetworkManager"

bus = dbus.SystemBus()
settings_obj = bus.get_object(BUS_NAME, "/org/freedesktop/NetworkManager/Settings")
settings_iface = dbus.Interface(settings_obj, "org.freedesktop.NetworkManager.Settings")

conn = {
    "connection": {
        "type": "802-3-ethernet",
        "autoconnect": False,
        "id": "con_dbus",
        "interface-name": "eth1",
    },
    "ipv6": {
        "method": "auto",
        "dns": [
            dbus.ByteArray(
                b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11\x12\x13\x14\x15"
            )
        ],
    },
}

try:
    settings_iface.AddConnection(conn)
except dbus.exceptions.DBusException as e:
    prop_name = "ipv6.dns"
    assert (
        not re.search(
            r"can't set property of type '.*' from value of type '.*'",
            e.get_dbus_message(),
        )
        and e.get_dbus_name().endswith("InvalidProperty")
        and e.get_dbus_message().startswith(prop_name)
    ), f"Expected 'InvalidProperty: {prop_name}', got '{e.get_dbus_name()}: {e.get_dbus_message()}'"
except Exception as e:
    raise Exception(f"Expected 'InvalidProperty: {prop_name}', got '{e}'")
else:
    raise Exception(
        f"Expected 'InvalidProperty: {prop_name}', but didn't get any error"
    )
