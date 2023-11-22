#!/usr/bin/env python3

import dbus
import re


BUS_NAME = "org.freedesktop.NetworkManager"


def assert_invalid_routes(family: str, routes):
    assert family in ("ipv4", "ipv6")

    conn = {
        "connection": {
            "type": "802-3-ethernet",
            "autoconnect": False,
            "id": "con_dbus",
            "interface-name": "eth1",
        },
        family: {
            "method": "auto",
            "routes": routes,
        },
    }

    bus = dbus.SystemBus()
    settings_obj = bus.get_object(BUS_NAME, "/org/freedesktop/NetworkManager/Settings")
    settings_iface = dbus.Interface(
        settings_obj, "org.freedesktop.NetworkManager.Settings"
    )

    try:
        settings_iface.AddConnection(conn)
    except dbus.exceptions.DBusException as e:
        prop_name = family + ".routes"
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


invalid_ipv6 = dbus.ByteArray(
    b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11\x12\x13\x14\x15"
)
valid_ipv6 = dbus.ByteArray(
    b"\x01\x02\x03\x04\x05\x06\x07\x08\x09\x10\x11\x12\x13\x14\x15\x16"
)

# ipv4: invalid length address
assert_invalid_routes("ipv4", [dbus.Array([1, 2, 3], signature="u")])

# ipv4: invalid prefix
assert_invalid_routes("ipv4", [dbus.Array([0, 33, 0, 0], signature="u")])

# ipv6: invalid length address
assert_invalid_routes(
    "ipv6", [(invalid_ipv6, dbus.UInt32(64), valid_ipv6, dbus.UInt32(0))]
)

# ipv6: invalid length next-hop
assert_invalid_routes(
    "ipv6", [(valid_ipv6, dbus.UInt32(64), invalid_ipv6, dbus.UInt32(0))]
)

# ipv6: invalid prefix
assert_invalid_routes(
    "ipv6", [(valid_ipv6, dbus.UInt32(129), valid_ipv6, dbus.UInt32(0))]
)

# error is returned also when there are other valid addresses
assert_invalid_routes(
    "ipv4",
    [dbus.Array([0, 24, 0, 0], signature="u"), dbus.Array([0, 33, 0], signature="u")],
)
assert_invalid_routes(
    "ipv6",
    [
        (valid_ipv6, dbus.UInt32(64), valid_ipv6, dbus.UInt32(0)),
        (valid_ipv6, dbus.UInt32(129), valid_ipv6, dbus.UInt32(0)),
    ],
)
