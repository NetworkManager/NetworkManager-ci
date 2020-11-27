import sys

from . import util


class _DBus:
    def bus_get(self, bus_type=None, cancellable=None):

        Gio = util.Gio

        if bus_type is None:
            bus_type = Gio.BusType.SYSTEM

        return Gio.bus_get_sync(bus_type, cancellable)

    def call(
        self,
        bus_name,
        object_path,
        interface_name,
        method_name,
        parameters=None,
        reply_type=None,
        flags=None,
        timeout_msec=None,
        bus_type=None,
        cancellable=None,
    ):

        GLib = util.GLib

        if flags is None:
            flags = util.Gio.DBusCallFlags.NONE

        if timeout_msec is None:
            timeout_msec = 5000

        dbus_con = self.bus_get(bus_type, cancellable)

        return dbus_con.call_sync(
            bus_name,
            object_path,
            interface_name,
            method_name,
            parameters,
            util.gvariant_type(reply_type),
            flags,
            timeout_msec,
            cancellable,
        )

    def get_property(
        self,
        bus_name,
        object_path,
        interface_name,
        property_name,
        reply_type=None,
        flags=None,
        timeout_msec=None,
        bus_type=None,
        cancellable=None,
    ):

        if reply_type is bool:
            v = self.get_property(
                bus_name=bus_name,
                object_path=object_path,
                interface_name=interface_name,
                property_name=property_name,
                reply_type="b",
                flags=flags,
                timeout_msec=timeout_msec,
                bus_type=bus_type,
                cancellable=cancellable,
            )
            return v.get_boolean()

        if reply_type is str:
            v = self.get_property(
                bus_name=bus_name,
                object_path=object_path,
                interface_name=interface_name,
                property_name=property_name,
                reply_type="s",
                flags=flags,
                timeout_msec=timeout_msec,
                bus_type=bus_type,
                cancellable=cancellable,
            )
            return v.get_string()

        GLib = util.GLib

        variant = GLib.Variant.new_tuple(
            GLib.Variant.new_string(interface_name),
            GLib.Variant.new_string(property_name),
        )

        v = self.call(
            bus_name=bus_name,
            object_path=object_path,
            interface_name="org.freedesktop.DBus.Properties",
            method_name="Get",
            parameters=variant,
            reply_type="(v)",
            flags=flags,
            timeout_msec=timeout_msec,
            bus_type=bus_type,
            cancellable=cancellable,
        )
        v = v.get_child_value(0)
        assert v.is_of_type(GLib.VariantType("v"))
        v = v.get_variant()

        if reply_type is not None:

            rt = util.gvariant_type(reply_type)
            if not v.is_of_type(rt):
                raise Exception(
                    'Property %s.%s on %s, %s expected type "%s" but got %s'
                    % (
                        interface_name,
                        property_name,
                        bus_name,
                        object_path,
                        rt.dup_string(),
                        repr(v),
                    )
                )

        return v


sys.modules[__name__] = _DBus()
