#!/usr/bin/env python3l

import dbus
import re


BUS_NAME = "org.freedesktop.NetworkManager"


def assert_invalid_addr_data(family: str, addrs):
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
            "route-data": dbus.Array(addrs, signature="a{sv}"),
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
        prop_name = family + ".route-data"
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


# ipv4: missing "dest" or "prefix"
assert_invalid_addr_data("ipv4", [{"dest": "1.2.3.4"}])
assert_invalid_addr_data("ipv4", [{"prefix": dbus.UInt32(24)}])

# ipv4: invalid address
assert_invalid_addr_data("ipv4", [{"dest": "1.2.3.4.5", "prefix": dbus.UInt32(24)}])
assert_invalid_addr_data("ipv4", [{"dest": "300.2.3.4", "prefix": dbus.UInt32(24)}])
assert_invalid_addr_data("ipv4", [{"dest": "1::2", "prefix": dbus.UInt32(24)}])

# ipv4: invalid prefix
assert_invalid_addr_data("ipv4", [{"dest": "1.2.3.4", "prefix": dbus.UInt32(33)}])

# ipv4: invalid next-hop
assert_invalid_addr_data(
    "ipv4", [{"next-hop": "1.2.3.4.5", "dest": "1.2.3.4", "prefix": dbus.UInt32(24)}]
)
assert_invalid_addr_data(
    "ipv4", [{"next-hop": "300.2.3.4", "dest": "1.2.3.4", "prefix": dbus.UInt32(24)}]
)
assert_invalid_addr_data(
    "ipv4", [{"next-hop": "1::2", "dest": "1.2.3.4", "prefix": dbus.UInt32(24)}]
)

# ipv6: missing "dest" or "prefix"
assert_invalid_addr_data("ipv6", [{"dest": "1::2"}])
assert_invalid_addr_data("ipv6", [{"prefix": dbus.UInt32(64)}])

# ipv6: invalid dest
assert_invalid_addr_data("ipv6", [{"dest": "1:2:3:4", "prefix": dbus.UInt32(64)}])
assert_invalid_addr_data("ipv6", [{"dest": "1::2::3", "prefix": dbus.UInt32(64)}])
assert_invalid_addr_data("ipv6", [{"dest": "1::xy", "prefix": dbus.UInt32(64)}])
assert_invalid_addr_data("ipv6", [{"dest": "1.2.3.4", "prefix": dbus.UInt32(64)}])

# ipv6: invalid prefix
assert_invalid_addr_data("ipv6", [{"dest": "1::2", "prefix": dbus.UInt32(129)}])

# ipv6: invalid next-hop
assert_invalid_addr_data(
    "ipv6", [{"next-hop": "1:2:3:4", "dest": "1::2", "prefix": dbus.UInt32(64)}]
)
assert_invalid_addr_data(
    "ipv6", [{"next-hop": "1::2::3", "dest": "1::2", "prefix": dbus.UInt32(64)}]
)
assert_invalid_addr_data(
    "ipv6", [{"next-hop": "1::xy", "dest": "1::2", "prefix": dbus.UInt32(64)}]
)
assert_invalid_addr_data(
    "ipv6", [{"next-hop": "1.2.3.4", "dest": "1::2", "prefix": dbus.UInt32(64)}]
)

# error is returned also when there are other valid routes
assert_invalid_addr_data(
    "ipv4",
    [
        {"dest": "1.2.3.4", "prefix": dbus.UInt32(24)},
        {"dest": "1.2.3.4.5", "prefix": dbus.UInt32(24)},
    ],
)
assert_invalid_addr_data(
    "ipv6",
    [
        {"dest": "1::2", "prefix": dbus.UInt32(64)},
        {"dest": "1::xy", "prefix": dbus.UInt32(64)},
    ],
)
