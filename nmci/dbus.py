import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _DBus:

    REPLY_TYPE_U = object()

    def name_is_bus_name(self, name, check=False):
        """Check if given name is valid bus name

        :param name: bus name
        :type name: str
        :param check: whether to raise if name is invalid, defaults to False
        :type check: bool, optional
        :raises ValueError: if name is invalid
        :return: True if name is valid, False otherwise
        :rtype: bool
        """
        if nmci.util.Gio.dbus_is_name(name):
            return True
        if check:
            raise ValueError(f'Invalid D-Bus bus name "{name}"')
        return False

    def name_is_interface_name(self, name, check=False):
        """Check if given name is valid interface name

        :param name: interface name
        :type name: str
        :param check: whether to raise if name is invalid, defaults to False
        :type check: bool, optional
        :raises ValueError: if name is invalid
        :return: True if name is valid, False otherwise
        :rtype: bool
        """
        if nmci.util.Gio.dbus_is_interface_name(name):
            return True
        if check:
            raise ValueError(f'Invalid D-Bus interface name "{name}"')
        return False

    def name_is_object_path(self, name, check=False):
        """Check if given name is valid object path

        :param name: object path
        :type name: str
        :param check: whether to raise if path is invalid, defaults to False
        :type check: bool, optional
        :raises ValueError: if path is invalid
        :return: True if path is valid, False otherwise
        :rtype: bool
        """
        if isinstance(name, str) and nmci.util.GLib.Variant.is_object_path(name):
            return True
        if check:
            raise ValueError(f'Invalid D-Bus object path "{name}"')
        return False

    def _object_path_norm(self, obj_path, default_prefix):
        if isinstance(obj_path, nmci.util.GLib.Variant):
            assert obj_path.get_type_string() == "o"
            obj_path = obj_path.get_string()
        if obj_path == "/":
            return None
        if default_prefix is not None:
            try:
                x = int(obj_path)
                return f"{default_prefix}/{x}"
            except Exception:
                pass
        return obj_path

    def object_path_norm(self, obj_path, default_prefix=None):
        """The D-Bus object paths is usually something like
        "/org/freedesktop/NetworkManager/Devices/43".

        For convenience, allow obj_path to be only a number, in
        which case default_prefix will be prepended.

        :param obj_path: path of the object
        :type obj_path: str
        :param default_prefix: path prefix, if given object path is relative, defaults to None
        :type default_prefix: str, optional
        :return: normalized object path
        :rtype: str
        """
        p = self._object_path_norm(obj_path, default_prefix)
        assert p is None or nmci.dbus.name_is_object_path(p, check=True)
        return p

    def bus_get(self, bus_type=None, cancellable=None):
        """Returns new bus

        :param bus_type: type of the bus, defaults to None
        :type bus_type: Gio.BusType, optional
        :param cancellable: cancellable object, defaults to None
        :type cancellable: Gio.Cancellable, optional
        :return: new bus
        :rtype: Gio.Bus
        """

        Gio = nmci.util.Gio

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
        """Call method on bus

        :param bus_name: name of the bus
        :type bus_name: str
        :param object_path: path of the object
        :type object_path: str
        :param interface_name: name of the bus interface
        :type interface_name: str
        :param method_name: name of the method to be called
        :type method_name: str
        :param parameters: method parametrs, defaults to None
        :type parameters: Gio.Variant, optional
        :param reply_type: type of the reply, defaults to None
        :type reply_type: GLib.VariantType, optional
        :param flags: flags, defaults to Gio.DBusCallFlags.NONE
        :type flags: Gio.DBusCallFlags, optional
        :param timeout_msec: timeout for given call, defaults to None
        :type timeout_msec: int, optional
        :param bus_type: type of bus, defaults to None
        :type bus_type: Gio.BusType, optional
        :param cancellable: cancellable object, defaults to None
        :type cancellable: Gio.Cancellable, optional
        :return: returns method reply
        :rtype: Glib.Variant
        """

        self.name_is_bus_name(bus_name, check=True)
        self.name_is_interface_name(interface_name, check=True)
        self.name_is_object_path(object_path, check=True)

        if flags is None:
            flags = nmci.util.Gio.DBusCallFlags.NONE

        if timeout_msec is None:
            timeout_msec = 5000

        dbus_con = self.bus_get(bus_type, cancellable)

        return dbus_con.call_sync(
            bus_name,
            object_path,
            interface_name,
            method_name,
            parameters,
            nmci.util.gvariant_type(reply_type),
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
        """Get property of given object

        :param bus_name: name of the bus
        :type bus_name: str
        :param object_path: path of the object
        :type object_path: str
        :param interface_name: name of the bus interface
        :type interface_name: str
        :param property_name: name of the property to get
        :type property_name: str
        :param reply_type: type of the reply, defaults to None
        :type reply_type: GLib.VariantType, optional
        :param flags: flags, defaults to Gio.DBusCallFlags.NONE
        :type flags: Gio.DBusCallFlags, optional
        :param timeout_msec: timeout for given call, defaults to None
        :type timeout_msec: int, optional
        :param bus_type: type of bus, defaults to None
        :type bus_type: Gio.BusType, optional
        :param cancellable: cancellable object, defaults to None
        :type cancellable: Gio.Cancellable, optional
        :return: returns method reply
        :rtype: Glib.Variant
        """

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

        if reply_type is self.REPLY_TYPE_U:
            v = self.get_property(
                bus_name=bus_name,
                object_path=object_path,
                interface_name=interface_name,
                property_name=property_name,
                reply_type="u",
                flags=flags,
                timeout_msec=timeout_msec,
                bus_type=bus_type,
                cancellable=cancellable,
            )
            return v.get_uint32()

        GLib = nmci.util.GLib

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

            rt = nmci.util.gvariant_type(reply_type)
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

    def get_all_properties(
        self,
        bus_name,
        object_path,
        interface_name,
        flags=None,
        timeout_msec=None,
        bus_type=None,
        cancellable=None,
    ):
        """Get all properties of given object

        :param bus_name: name of the bus
        :type bus_name: str
        :param object_path: path of the object
        :type object_path: str
        :param interface_name: name of the bus interface
        :type interface_name: str
        :param flags: flags, defaults to Gio.DBusCallFlags.NONE
        :type flags: Gio.DBusCallFlags, optional
        :param timeout_msec: timeout for given call, defaults to None
        :type timeout_msec: int, optional
        :param bus_type: type of bus, defaults to None
        :type bus_type: Gio.BusType, optional
        :param cancellable: cancellable object, defaults to None
        :type cancellable: Gio.Cancellable, optional
        :return: returns method reply
        :rtype: Glib.Variant
        """

        GLib = nmci.util.GLib

        variant = GLib.Variant.new_tuple(
            GLib.Variant.new_string(interface_name),
        )

        v = self.call(
            bus_name=bus_name,
            object_path=object_path,
            interface_name="org.freedesktop.DBus.Properties",
            method_name="GetAll",
            parameters=variant,
            reply_type="(a{sv})",
            flags=flags,
            timeout_msec=timeout_msec,
            bus_type=bus_type,
            cancellable=cancellable,
        )
        v = v.get_child_value(0)
        assert v.is_of_type(GLib.VariantType("a{sv}"))

        result = {}
        for k in v.keys():
            result[k] = v.lookup_value(k)

        return result


_module = _DBus()
