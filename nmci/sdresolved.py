import nmci


def __getattr__(attr):
    return getattr(_module, attr)


class _SDResolved:
    """
    This class provides access to the sd-resolved D-Bus API. It is a singleton
    and can be accessed via the :code:`nmci.sdresolved` module.
    """

    def get_link(self, ifindex):
        """
        Resolve the ifindex to a D-Bus path.

        :param ifindex: the ifindex to resolve
        :type ifindex: int or str
        :return: the resolved D-Bus path
        :rtype: str
        """
        if isinstance(ifindex, str) and ifindex.startswith(
            "/org/freedesktop/resolve1/link/"
        ):
            # We accept that the ifindex is already a resolved D-Bus path.
            # In that case, we return it unmodified.
            return ifindex

        GLib = nmci.util.GLib

        v = nmci.dbus.call(
            bus_name="org.freedesktop.resolve1",
            object_path="/org/freedesktop/resolve1",
            interface_name="org.freedesktop.resolve1.Manager",
            method_name="GetLink",
            parameters=GLib.Variant.new_tuple(GLib.Variant.new_int32(ifindex)),
            reply_type="(o)",
        )
        return v.get_child_value(0).get_string()

    def link_get_domains(self, ifindex):
        """Resolve the ifindex to a D-Bus path,
        and retrieve all domains.

        :param ifindex: the ifindex to resolve
        :type ifindex: int or str
        :return: list of Domains
        :rtype: list of (str, str)
        """
        object_path = self.get_link(ifindex)

        v = nmci.dbus.get_property(
            bus_name="org.freedesktop.resolve1",
            object_path=object_path,
            interface_name="org.freedesktop.resolve1.Link",
            property_name="Domains",
            reply_type="a(sb)",
        )

        result = []
        for v_i in v:
            result.append((v_i[0], "routing" if v_i[1] else "search"))
        return result

    def link_get_dns(self, ifindex):
        """Resolve the ifindex to a D-Bus path,
        and retrieve all DNS addresses for the given ifindex.

        :param ifindex: the ifindex to resolve
        :type ifindex: int or str
        :raises: GLib.Error if the DNS property is not available
        :return: list of DNS addresses
        :rtype: list of str
        """
        object_path = self.get_link(ifindex)

        v = nmci.dbus.get_property(
            bus_name="org.freedesktop.resolve1",
            object_path=object_path,
            interface_name="org.freedesktop.resolve1.Link",
            property_name="DNS",
            reply_type="a(iay)",
        )

        import ipaddress

        result = []
        for v_i in v:
            addr_family, addr_bin = v_i
            if addr_family == 2:
                a = ipaddress.IPv4Address(bytes(addr_bin))
            elif addr_family == 6:
                a = ipaddress.IPv6Address(bytes(addr_bin))
            else:
                raise Exception("Invalid response for DNS: %s" % (repr(v)))
            result.append(str(a))
        return result

    def link_get_default_route(self, ifindex):
        """Resolve the ifindex to a D-Bus path,
        and retrieve the default routes for the given ifindex.

        :param ifindex: the ifindex to resolve
        :type ifindex: int or str
        :raises: GLib.Error if the DefaultRoute property is not available
        :return: list of default routes
        :rtype: list of str
        """
        object_path = self.get_link(ifindex)

        try:
            v = nmci.dbus.get_property(
                bus_name="org.freedesktop.resolve1",
                object_path=object_path,
                interface_name="org.freedesktop.resolve1.Link",
                property_name="DefaultRoute",
                reply_type=bool,
            )
        except Exception as e:
            if (
                isinstance(e, nmci.util.GLib.Error)
                and e.domain == "g-dbus-error-quark"
                and e.code == nmci.util.Gio.DBusError.UNKNOWN_PROPERTY
            ):
                # DefaultRoute property was only added in v240. We accept the missing API
                # and return None.
                return None
            raise

        return v

    def link_get_all(self, ifindex):
        """Resolve the ifindex to a D-Bus path,
        and retrieve all DNS addresses, domains, and default routes
        for the given ifindex.

        :param ifindex: the ifindex to resolve
        :type ifindex: int or str
        :return: dict of DNS addresses, domains, and default routes
        :rtype: dict
        """
        ifindex = self.get_link(ifindex)
        return {
            "dns": self.link_get_dns(ifindex),
            "domains": self.link_get_domains(ifindex),
            "default_route": self.link_get_default_route(ifindex),
        }


_module = _SDResolved()
