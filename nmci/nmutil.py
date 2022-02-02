import sys

from . import dbus


class _NMUtil:
    def get_metered(self):
        return dbus.get_property(
            bus_name="org.freedesktop.NetworkManager",
            object_path="/org/freedesktop/NetworkManager",
            interface_name="org.freedesktop.NetworkManager",
            property_name="Metered",
            reply_type=dbus.REPLY_TYPE_U,
        )


sys.modules[__name__] = _NMUtil()
