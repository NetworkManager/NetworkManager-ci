#!/usr/bin/env python3
"""
Minimal BlueZ D-Bus mock for NM-CI bluetooth testing.
Owns 'org.bluez' on the system bus and presents:
  /org/bluez/hci0          - Adapter1 + NetworkServer1 (powered, connectable)
  /org/bluez/hci0/dev_...  - Device1 (paired, trusted, connected, with DUN UUID)

NM's bluez5 manager watches ObjectManager.GetManagedObjects() for these.
Raw SDP/L2CAP goes through the kernel BT stack (btvirt), not through this mock.

Usage: mock_bluez.py [adapter_addr] [remote_addr]
  Defaults: adapter=00:AA:01:00:00:00 remote=00:AA:01:01:00:01
"""

import sys
import signal
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

DUN_UUID = "00001103-0000-1000-8000-00805f9b34fb"

ADAPTER_ADDR = sys.argv[1] if len(sys.argv) > 1 else "00:AA:01:00:00:00"
REMOTE_ADDR = sys.argv[2] if len(sys.argv) > 2 else "00:AA:01:01:00:01"

ADAPTER_PATH = "/org/bluez/hci0"
DEVICE_PATH = ADAPTER_PATH + "/dev_" + REMOTE_ADDR.replace(":", "_")

ADAPTER_PROPS = {
    "org.bluez.NetworkServer1": {},
    "org.bluez.Adapter1": {
        "Address": dbus.String(ADAPTER_ADDR),
        "AddressType": dbus.String("public"),
        "Name": dbus.String("btvirt-mock-adapter"),
        "Alias": dbus.String("btvirt-mock-adapter"),
        "Class": dbus.UInt32(0),
        "Powered": dbus.Boolean(True),
        "Discoverable": dbus.Boolean(False),
        "DiscoverableTimeout": dbus.UInt32(0),
        "Pairable": dbus.Boolean(True),
        "PairableTimeout": dbus.UInt32(0),
        "Discovering": dbus.Boolean(False),
        "UUIDs": dbus.Array([], signature="s"),
        "Modalias": dbus.String(""),
        "Roles": dbus.Array(["central", "peripheral"], signature="s"),
    },
}

DEVICE_PROPS = {
    "org.bluez.Device1": {
        "Address": dbus.String(REMOTE_ADDR),
        "AddressType": dbus.String("public"),
        "Name": dbus.String("btvirt-mock-remote"),
        "Alias": dbus.String("btvirt-mock-remote"),
        "Class": dbus.UInt32(0),
        "Appearance": dbus.UInt16(0),
        "Icon": dbus.String(""),
        "Paired": dbus.Boolean(True),
        "Bonded": dbus.Boolean(True),
        "Trusted": dbus.Boolean(True),
        "Blocked": dbus.Boolean(False),
        "LegacyPairing": dbus.Boolean(False),
        "Connected": dbus.Boolean(True),
        "UUIDs": dbus.Array([DUN_UUID], signature="s"),
        "Adapter": dbus.ObjectPath(ADAPTER_PATH),
        "ServicesResolved": dbus.Boolean(True),
        "ManufacturerData": dbus.Dictionary({}, signature="qv"),
        "ServiceData": dbus.Dictionary({}, signature="sv"),
        "RSSI": dbus.Int16(-50),
    },
}


class MockBluezRoot(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, "/")

    @dbus.service.method(
        "org.freedesktop.DBus.ObjectManager", out_signature="a{oa{sa{sv}}}"
    )
    def GetManagedObjects(self):
        return dbus.Dictionary(
            {
                dbus.ObjectPath(ADAPTER_PATH): ADAPTER_PROPS,
                dbus.ObjectPath(DEVICE_PATH): DEVICE_PROPS,
            },
            signature="oa{sa{sv}}",
        )


class MockAdapter(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, ADAPTER_PATH)

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v"
    )
    def Get(self, interface, prop):
        return ADAPTER_PROPS.get(interface, {}).get(prop)

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface):
        return ADAPTER_PROPS.get(interface, {})

    @dbus.service.method("org.bluez.NetworkServer1", in_signature="ss")
    def Register(self, uuid, bridge):
        pass

    @dbus.service.method("org.bluez.NetworkServer1", in_signature="s")
    def Unregister(self, uuid):
        pass

    @dbus.service.method("org.bluez.Adapter1")
    def StartDiscovery(self):
        pass

    @dbus.service.method("org.bluez.Adapter1")
    def StopDiscovery(self):
        pass


class MockDevice(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, DEVICE_PATH)

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="ss", out_signature="v"
    )
    def Get(self, interface, prop):
        return DEVICE_PROPS.get(interface, {}).get(prop)

    @dbus.service.method(
        "org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}"
    )
    def GetAll(self, interface):
        return DEVICE_PROPS.get(interface, {})

    @dbus.service.method("org.bluez.Device1")
    def Connect(self):
        pass

    @dbus.service.method("org.bluez.Device1")
    def Disconnect(self):
        pass

    @dbus.service.method("org.bluez.Device1", in_signature="s")
    def ConnectProfile(self, uuid):
        pass

    @dbus.service.method("org.bluez.Device1", in_signature="s")
    def DisconnectProfile(self, uuid):
        pass


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    name = dbus.service.BusName("org.bluez", bus, do_not_queue=True)

    root = MockBluezRoot(bus)
    adapter = MockAdapter(bus)
    device = MockDevice(bus)

    loop = GLib.MainLoop()

    def quit_handler(signum, frame):
        loop.quit()

    signal.signal(signal.SIGTERM, quit_handler)
    signal.signal(signal.SIGINT, quit_handler)

    print(f"[mock-bluez] Running on system bus as org.bluez", flush=True)
    print(f"[mock-bluez] Adapter: {ADAPTER_PATH} ({ADAPTER_ADDR})", flush=True)
    print(
        f"[mock-bluez] Device:  {DEVICE_PATH} ({REMOTE_ADDR}) UUIDs=[DUN]", flush=True
    )

    loop.run()


if __name__ == "__main__":
    main()
