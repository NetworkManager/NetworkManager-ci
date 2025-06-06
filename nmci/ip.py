import re
import socket

import nmci


def __getattr__(attr):
    return getattr(_module, attr)


IP_NAMESPACE_ALL = object()
IP_LINK_NOMASTER = object()
IGNORED_STDERR_MESSAGES = ["Dump was interrupted and may be inconsistent.\n"]


class _IP:

    IP_NAMESPACE_ALL = IP_NAMESPACE_ALL
    IP_LINK_NOMASTER = IP_LINK_NOMASTER

    def addr_family_norm(self, addr_family):
        """
        Normalize address family.

        :param addr_family: address family
        :type addr_family: socket.AddressFamily or string
        :return: socket constant or None
        :rtype: socket.AddressFamily
        """
        if addr_family in [socket.AF_INET, socket.AF_INET6]:
            return addr_family
        if addr_family is None or addr_family == socket.AF_UNSPEC:
            return None
        if addr_family in ["4", "inet", "ip4", "ipv4", "IPv4"]:
            return socket.AF_INET
        if addr_family in ["6", "inet6", "ip6", "ipv6", "IPv6"]:
            return socket.AF_INET6
        self.addr_family_check(addr_family)

    def addr_family_check(self, addr_family):
        """
        Check that address family is :code:`socket.AF_INET` or :code:`socket.AF_INET6`.

        :param addr_family: address family
        :type addr_family: socket.AddressFamily
        :raises ValueError: when invalid address family provided
        """
        if addr_family != socket.AF_INET and addr_family != socket.AF_INET6:
            raise ValueError(f"invalid address family {addr_family}")

    def addr_family_num(self, addr_family, allow_none=False):
        """
        Number represenation (4 or 6) of address family.

        :param addr_family: address family
        :type addr_family: socket.AddressFamily or string
        :param allow_none: whether to accept None value, defaults to False
        :type allow_none: bool, optional
        :return: number representation of address family
        :rtype: int
        """
        addr_family = self.addr_family_norm(addr_family)
        if addr_family == socket.AF_INET:
            return 4
        if addr_family == socket.AF_INET6:
            return 6
        if addr_family is None and allow_none:
            return None
        self.addr_family_check(addr_family)

    def addr_zero(self, addr_family, with_plen=True):
        """
        Zero IP address for given family

        :param addr_family: address family
        :type addr_family: socket.AddressFamily or str
        :param with_plen: append addres range ("/0"), default True
        :type with_plen: bool, optional
        :return: zero address
        :rtype: int
        """
        plen = ""
        if with_plen:
            plen = f"/0"
        addr_family = self.addr_family_norm(addr_family)
        if addr_family == socket.AF_INET:
            return f"0.0.0.0{plen}"
        if addr_family == socket.AF_INET6:
            return f"::{plen}"
        self.addr_family_check(addr_family)

    def addr_family_plen(self, addr_family):
        """
        IP address length for given family

        :param addr_family: address family
        :type addr_family: socket.AddressFamily or str
        :return: length of address
        :rtype: int
        """
        addr_family = self.addr_family_norm(addr_family)
        if addr_family == socket.AF_INET:
            return 32
        if addr_family == socket.AF_INET6:
            return 128
        self.addr_family_check(addr_family)

    def ipaddr_parse(self, s, addr_family=None):
        """
        Parse IP address from string. If address family is not provided
        both IPv4 and IPv6 addresses are accepted.

        :param s: address
        :type s: str or bytes
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str or None, optional
        :return: normalized address with detected address family
        :rtype: tuple, str and socket.AddressFamily
        """
        s = nmci.util.bytes_to_str(s)
        addr_family = self.addr_family_norm(addr_family)
        if addr_family is not None:
            a = socket.inet_pton(addr_family, s)
        else:
            a = None
            addr_family = None
            try:
                a = socket.inet_pton(socket.AF_INET, s)
                addr_family = socket.AF_INET
            except Exception:
                a = socket.inet_pton(socket.AF_INET6, s)
                addr_family = socket.AF_INET6
        return (socket.inet_ntop(addr_family, a), addr_family)

    def ipaddr_norm(self, s, addr_family=None):
        """
        Normalize IP address. If address family is not provided
        both IPv4 and IPv6 addresses are accepted.

        :param s: address
        :type s: str or bytes
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str or None, optional
        :return: normalized address
        :rtype: str
        """
        addr, addr_family = self.ipaddr_parse(s, addr_family)
        return addr

    def ipaddr_plen_parse(self, s, addr_family=None):
        """
        Parse IP address and prefix from string. If address family is not provided
        both IPv4 and IPv6 addresses are accepted.

        :param s: address with prefix, e.g "1.2.3.4/31"
        :type s: str or bytes
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str or None, optional
        :raises ValueError: when provided address or plen is invalid
        :return: tuple of normalized address, address family and prefix
        :rtype: tuple, str and socket.AddressFamily and int
        """
        addr_family = self.addr_family_norm(addr_family)
        s = nmci.util.bytes_to_str(s)
        s0 = s
        m = re.match("^(.*)/(.*)", s)
        if m:
            s = m.group(1)
            p = m.group(2)
        else:
            p = None

        try:
            a, f = self.ipaddr_parse(s, addr_family=addr_family)
        except Exception:
            raise ValueError(f"invalid address in {s0}")

        if p is not None:
            try:
                p = int(p)
            except Exception:
                p = -1
            if p < 0 or p > self.addr_family_plen(f):
                raise ValueError(f"invalid plen in {s0}")

        return (a, f, p)

    def ipaddr_plen_norm(self, s, addr_family=None):
        """
        Normalize IP address and prefix. If address family is not provided
        both IPv4 and IPv6 addresses are accepted.

        :param s: address with prefix, e.g "1.2.3.4/31"
        :type s: str or bytes
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str or None, optional
        :raises ValueError: when provided address or plen is invalid
        :return: normalized adrress with prefix
        :rtype: str
        """
        (addr, addr_family, plen) = self.ipaddr_plen_parse(s, addr_family)
        if plen is None:
            return addr
        return f"{addr}/{plen}"

    def ipaddr_zero(self, addr_family):
        """
        Zero address for given address family

        :param addr_family: address family
        :type addr_family: socket.AddressFamily or string
        :return: "0.0.0.0" or "::"
        :rtype: str
        """
        if self.addr_family_num(addr_family) == 4:
            return "0.0.0.0"
        else:
            return "::"

    def mac_aton(self, mac_str, force_len=None):
        """
        Convert MAC address to bytes.
        We also accept None and '' for convenience, None yiels None, '' yields [].

        :param mac_str: mac address
        :type mac_str: str
        :param force_len: length of address in bits, defaults to None
        :type force_len: int, optional
        :return: MAC address in bytes
        :rtype: bytes
        """
        if mac_str is None:
            return mac_str
        mac_str = nmci.util.bytes_to_str(mac_str)
        i = 0
        b = []
        for c in mac_str:
            if i == 2:
                if c != ":":
                    raise ValueError("not a valid MAC address: '%s'" % (mac_str))
                i = 0
                continue
            try:
                if i == 0:
                    n = int(c, 16) * 16
                    i = 1
                else:
                    if not i == 1:
                        raise AssertionError("i != 1 - value is {0}".format(i))
                    n = n + int(c, 16)
                    i = 2
                    b.append(n)
            except Exception:
                raise ValueError("not a valid MAC address: '%s'" % (mac_str))
        if i == 1:
            raise ValueError("not a valid MAC address: '%s'" % (mac_str))
        if force_len is not None:
            if force_len != len(b):
                raise ValueError(
                    "not a valid MAC address of length %s: '%s'" % (force_len, mac_str)
                )
        return b

    def mac_ntoa(self, mac):
        """
        Convert bytes to MAC address string

        :param mac_str: mac address
        :type mac_str: str
        :param force_len: length of address in bits, defaults to None
        :type force_len: int, optional
        :return: MAC address
        :rtype: str
        """
        if mac is None:
            return None
        return ":".join(["%02x" % c for c in bytearray(mac)])

    def mac_norm(self, mac_str, force_len=None):
        """
        Normalize MAC address string.
        We also accept None and '' for convenience, None yiels None, '' yields [].

        :param mac_str: mac address
        :type mac_str: str
        :param force_len: length of address in bits, defaults to None
        :type force_len: int, optional
        :return: normalized MAC address
        :rtype: str
        """
        return self.mac_ntoa(self.mac_aton(mac_str, force_len))

    def address_show(
        self,
        binary=None,
        ifindex=None,
        ifname=None,
        addr_family=None,
        atype=None,
        namespace=None,
    ):
        """
        Get addresses via :code:`ip address show`. Possibility to filter output
        by providing ifindex or ifname.

        :param binary: whether to return bytes, defaults to None
        :type binary: bool, optional
        :param ifindex: index of interface to show, defaults to None
        :type ifindex: int or str, optional
        :param ifname: interafce name to show, defaults to None
        :type ifname: _type_, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param atype: output only addresses of the following type, one of "inet", "inet6", "link/ether", defaults to None
        :type atype: str, optional
        :param namespace: namespace to match, defaults to None
        :type namespace: str, optional
        :return: addresses for matched inetrafces
        :rtype: dict
        """
        select_ifindex = ifindex
        select_ifname = ifname
        select_addr_family = self.addr_family_norm(addr_family)
        select_atype = atype

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        # binary is:
        #   False: expect all stings to be UTF-8, the result only contains decoded strings
        #   True: expect at least some of the names to be binary, all the ifnames are bytes
        #   None: expect a mix. The ifnames that can be decoded as UTF-8 are returned
        #     as strings, otherwise as bytes.

        assert binary is None or binary is True or binary is False

        cmd_argv = ["ip", *ns_args, "-d", "address", "show"]
        cmd_res = nmci.process.run(
            cmd_argv, as_bytes=True, ignore_returncode=False, ignore_stderr=True
        )

        if cmd_res.stderr and not nmci.util.str_matches(
            nmci.util.bytes_to_str(cmd_res.stderr, "replace"), IGNORED_STDERR_MESSAGES
        ):
            nmci.process.raise_results(cmd_argv, "printed something to stderr", cmd_res)

        out = cmd_res.stdout

        result = []

        lines = out.split(b"\n")
        i = 0

        if lines and not lines[-1]:
            del lines[-1]

        if not lines:
            raise Exception("output of ip link is empty")

        ifindexes = {}

        while i < len(lines):
            line = lines[i]
            i += 1

            # currently we only parse a subset of the parameters

            m = re.match(rb"^([0-9]+): *([^:@]+)(@[^:]*)?: <([^>]*)>", line)
            if not m:
                raise Exception("Unexpected line in ip link output: %s" % (line))

            ifindex = int(m.group(1))
            ifname = nmci.util.binary_to_str(m.group(2), binary)

            assert ifindex not in ifindexes
            ifindexes[ifindex] = ifname

            i0 = i
            while i < len(lines):
                line = lines[i]

                m = re.match(rb"^( +)", line)
                if not m:
                    break
                if i == i0:
                    indent_prefix = b"^" + m.group(1)

                atype = None

                i += 1

                m = re.match(
                    indent_prefix + b"(inet|inet6|link/ether) +([0-9a-f:./]+) +(.*)$",
                    line,
                )
                if m:
                    atype = nmci.util.bytes_to_str(m.group(1))
                    if atype == "link/ether":
                        addr = self.mac_norm(m.group(2))
                        plen = None
                        addr_family = None
                    else:
                        addr, addr_family, plen = self.ipaddr_plen_parse(
                            m.group(2),
                            addr_family=(
                                socket.AF_INET if atype == "inet" else socket.AF_INET6
                            ),
                        )
                else:
                    pass

                if atype is not None:
                    ip_data = {
                        "ifindex": ifindex,
                        "ifname": ifname,
                        "type": atype,
                        "addr_family": addr_family,
                        "address": addr,
                        "plen": plen,
                    }
                    result.append(ip_data)

                while i < len(lines) and re.match(indent_prefix + b" ", lines[i]):
                    # Skip over additional lines that are part of the current address.
                    i += 1

        if select_atype is not None:
            result = [a for a in result if a["type"] == select_atype]

        if select_addr_family is not None:
            result = [a for a in result if a["addr_family"] == select_addr_family]

        if select_ifindex is not None:
            result = [a for a in result if a["ifindex"] == select_ifindex]

        if select_ifname is not None:
            result = [
                a
                for a in result
                if nmci.util.str_to_bytes(a["ifname"])
                == nmci.util.str_to_bytes(select_ifname)
            ]

        return result

    def address_expect(
        self,
        expected,
        ifindex=None,
        ifname=None,
        match_mode="auto",
        with_plen=False,
        ignore_order=False,
        ignore_extra=True,
        addr_family=None,
        wait_for_address=None,
        addrs=None,
        namespace=None,
    ):
        """
        Check if expected address is present on interface.

        :param expected: list of expected addresses
        :type expected: list of str or re.Pattern
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param match_mode: see :code:`nmci.util.compare_strv_list`, defaults to "auto"
        :type match_mode: str, optional
        :param with_plen: whether to strip prefix or not, defaults to False
        :type with_plen: bool, optional
        :param ignore_order: whether to ignore address order, defaults to False
        :type ignore_order: bool, optional
        :param ignore_extra: whether to addresses must match exactly, defaults to True
        :type ignore_extra: bool, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param wait_for_address: timeout until address must be present, defaults to None
        :type wait_for_address: float, optional
        :param addrs: addreses, if set will not query :code:`address_show()`, defaults to None
        :type addrs: dict, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :return: adresses of the matched interfaces
        :rtype: dict
        """
        addr_family = self.addr_family_norm(addr_family)

        if wait_for_address is not None:
            err = None
            timeout = nmci.util.start_timeout(wait_for_address)
            while timeout.loop_sleep(0.1):
                try:
                    return self.address_expect(
                        expected=expected,
                        ifindex=ifindex,
                        ifname=ifname,
                        match_mode=match_mode,
                        with_plen=with_plen,
                        ignore_order=ignore_order,
                        ignore_extra=ignore_extra,
                        addr_family=addr_family,
                        wait_for_address=None,
                        addrs=None,
                        namespace=namespace,
                    )
                except ValueError as e:
                    err = e
            raise ValueError(f"Requested configuration not ready after timeout: {err}")

        if addrs is None:
            addrs = self.address_show(
                ifindex=ifindex,
                ifname=ifname,
                addr_family=addr_family,
                namespace=namespace,
            )

        s_addrs = [
            (f'{a["address"]}/{a["plen"]}' if with_plen else f'{a["address"]}')
            for a in addrs
            if a["addr_family"] in [socket.AF_INET, socket.AF_INET6]
            and (addr_family is None or addr_family == a["addr_family"])
        ]

        try:
            nmci.util.compare_strv_list(
                expected=expected,
                strv=s_addrs,
                match_mode=match_mode,
                ignore_extra_strv=ignore_extra,
                ignore_order=ignore_order,
            )
        except ValueError as e:
            raise ValueError(f"List of addresses unexpected: {e} (full list: {addrs})")

        return addrs

    def address_flush(
        self,
        ifname=None,
        *,
        ifindex=None,
        wait_for_device=None,
        addr_family=None,
        namespace=None,
    ):
        """
        Flush addresses on given interface.

        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interafec index, defaults to None
        :type ifindex: int or str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        """
        if ifname is None or ifindex is not None or wait_for_device is not None:
            li = self.link_show(
                ifindex=ifindex,
                ifname=ifname,
                timeout=wait_for_device,
                namespace=namespace,
            )
            ifname = li["ifname"]

        filter_addr_family = []
        if addr_family is not None:
            filter_addr_family.append(f"-{self.addr_family_num(addr_family)}")

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        nmci.process.run_stdout(
            ["ip", *ns_args, *filter_addr_family, "addr", "flush", "dev", ifname],
            as_bytes=True,
        )

    def address_add(
        self,
        address,
        ifname=None,
        *,
        ifindex=None,
        wait_for_device=None,
        addr_family=None,
        namespace=None,
    ):
        """
        Add IP address to interface.

        :param address: IP address to add
        :type address: str
        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interafce index, defaults to None
        :type ifindex: int or str, optional
        :param wait_for_device: timeout for device to appear, defaults to None
        :type wait_for_device: float, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        """
        if ifname is None or ifindex is not None or wait_for_device is not None:
            li = self.link_show(
                ifindex=ifindex,
                ifname=ifname,
                timeout=wait_for_device,
                namespace=namespace,
            )
            ifname = li["ifname"]

        filter_addr_family = []
        if addr_family is not None:
            filter_addr_family.append(f"-{self.addr_family_num(addr_family)}")

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        nmci.process.run_stdout(
            [
                "ip",
                *ns_args,
                *filter_addr_family,
                "addr",
                "add",
                address,
                "dev",
                ifname,
            ],
            as_bytes=True,
        )

    def link_show_all(self, binary=None, namespace=None):
        """
        Show all links. Parameter binary can be:

        :code:`False`: expect all stings to be UTF-8, the result only contains decoded strings
        :code:`True`: expect at least some of the names to be binary, all the ifnames are bytes
        :code:`None`: expect a mix. The ifnames that can be decoded as UTF-8 are returned as strings, otherwise as bytes.

        :param binary: whether output should be string or binary or mixed, defaults to None
        :type binary: bool, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :return: Attributes of all availiable links
        :rtype: dict
        """

        assert binary is None or binary is True or binary is False

        ns_args = {"": []}
        if namespace is not None:
            if namespace is IP_NAMESPACE_ALL:
                for ns in self.netns_list():
                    ns_args[ns] = ["-n", ns]
            else:
                ns_args = {namespace: ["-n", namespace]}

        outs = {}
        for ns, ns_arg in ns_args.items():
            outs[ns] = nmci.process.run_stdout(
                ["ip", *ns_arg, "-d", "link", "show"], as_bytes=True
            )

        result = []

        for ns, out in outs.items():
            lines = out.split(b"\n")
            i = 0

            if lines and not lines[-1]:
                del lines[-1]

            if not lines:
                raise Exception("output of ip link is empty")

            while i < len(lines):
                line = lines[i]
                i += 1

                # currently we only parse a subset of the parameters

                ip_data = {}

                m = re.match(rb"^([0-9]+): *([^:@]+)(@[^:]*)?: <([^>]*)>", line)
                if not m:
                    raise Exception("Unexpected line in ip link output: %s" % (line))

                ip_data["ifindex"] = int(m.group(1))
                ip_data["ifname"] = nmci.util.binary_to_str(m.group(2), binary)

                g = m.group(4)
                g = [s.decode() for s in g.split(b",")]
                ip_data["flags"] = g

                if m.group(3):
                    parentdev = m.group(3).removeprefix(b"@")
                    ip_data["parentdev"] = nmci.util.binary_to_str(parentdev, binary)
                else:
                    ip_data["parentdev"] = None

                while i < len(lines):
                    line = lines[i]
                    if not re.match(rb"^ +", line):
                        break
                    i += 1

                ip_data["namespace"] = ns

                result.append(ip_data)

        return result

    def _link_show(
        self,
        ifname=None,
        ifindex=None,
        flags=None,
        binary=None,
        allow_missing=False,
        namespace=None,
    ):
        """
        Show single link. Interface name or index must be provided.

        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param flags: interafce has to have given flags, defaults to None
        :type flags: str, optional
        :param binary: see :code:`link_show_all()`, defaults to None
        :type binary: bool, optional
        :param allow_missing: does not raise Exception if none interafce matched, defaults to False
        :type allow_missing: bool, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :return: attributes of matched interafce or None
        :rtype: dict
        """
        if ifindex is None and ifname is None:
            raise ValueError("Missing argument, either ifindex or ifname must be given")

        if ifname is None:
            ifname_b = None
        elif isinstance(ifname, str):
            ifname_b = ifname.encode()
        else:
            ifname_b = ifname

        result = []

        for data in self.link_show_all(binary=True, namespace=namespace):
            ii = data["ifindex"]
            if ifindex is not None and int(ifindex) != ii:
                continue
            if ifname_b is not None:
                ii = data["ifname"]
                if ifname_b != ii:
                    continue
            if flags is not None:
                if isinstance(flags, str):
                    if flags not in data["flags"]:
                        continue
                else:
                    if not all([(f in data["flags"]) for f in flags]):
                        continue

            result.append(data)

        # If the users asks for a certain ifindex/ifname, then we require
        # to find exactly one interface. Otherwise, we will fail.
        if len(result) != 1:
            if ifindex is None:
                s = 'ifname="%s"' % (ifname)
            elif ifname is None:
                s = "ifindex=%s" % (ifindex)
            else:
                s = 'ifindex=%s, ifname="%s"' % (ifindex, ifname)
            if not result:
                if allow_missing:
                    return None
                raise KeyError("Could not find interface with " + s)
            raise KeyError("Could not find unique interface with " + s)

        data = result[0]

        data["ifname"] = nmci.util.binary_to_str(data["ifname"], binary)
        if data["parentdev"]:
            data["parentdev"] = nmci.util.binary_to_str(data["parentdev"], binary)

        return data

    def link_show(self, ifname=None, *, timeout=None, **kwargs):
        """
        Show single link. Interface name or index must be provided.

        :param timeout: timeout until device must appear, defaults to None
        :type timeout: float, optional
        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param flags: interafce has to have given flags, defaults to None
        :type flags: str, optional
        :param binary: see :code:`link_show_all()`, defaults to None
        :type binary: bool, optional
        :param allow_missing: does not raise Exception if none interafce matched, defaults to False
        :type allow_missing: bool, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :return: attributes of matched interafce or None
        :rtype: dict
        """
        xtimeout = nmci.util.start_timeout(timeout)
        while xtimeout.loop_sleep(0.08):
            try:
                return self._link_show(ifname=ifname, **kwargs)
            except Exception:
                if xtimeout.is_none():
                    raise
                pass

        raise Exception(
            f"Requested interface not found or not ready within timeout (args={kwargs})"
        )

    def link_show_maybe(self, ifname=None, *, allow_missing=True, **kwargs):
        """
        Show single link. Interface name or index must be provided.

        :param timeout: timeout until device must appear, defaults to None
        :type timeout: float, optional
        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param flags: interafce has to have given flags, defaults to None
        :type flags: str, optional
        :param binary: see :code:`link_show_all()`, defaults to None
        :type binary: bool, optional
        :param allow_missing: does not raise Exception if none interafce matched, defaults to True
        :type allow_missing: bool, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :return: attributes of matched interafce or None
        :rtype: dict
        """
        return self.link_show(ifname=ifname, allow_missing=allow_missing, **kwargs)

    def link_set(
        self,
        ifname=None,
        *args,
        ifindex=None,
        up=None,
        wait_for_device=None,
        namespace=None,
        name=None,
        netns=None,
        master=None,
        **kwargs,
    ):
        """
        Set link attributes. Additional arguments are appended to
        :code:`ip link set ...` command. Additional keyword arguments are
        appended with separated space: :code:`peer='p_name'` is appended as
        :code:`'peer' 'p_name'`.

        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param up: if set, interface is set :code:`up` or :code:`down`, defaults to None
        :type up: bool, optional
        :param wait_for_device: timeout for device to appear, defaults to None
        :type wait_for_device: float, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param name: new name for interface, defaults to None
        :type name: str, optional
        :param netns: new namespace for interface, defaults to None
        :type netns: str, optional
        :param master: new master of interface, defaults to None
        :type master: str, optional
        """
        if ifname is None or ifindex is not None or wait_for_device is not None:
            li = self.link_show(
                ifindex=ifindex,
                ifname=ifname,
                timeout=wait_for_device,
                namespace=namespace,
            )
            ifname = li["ifname"]

        merged_args = []
        if up is not None:
            merged_args.append("up" if up else "down")

        if name is not None:
            merged_args += ["name", name]

        if netns is not None:
            merged_args += ["netns", netns]

        if master is IP_LINK_NOMASTER:
            merged_args.append("nomaster")
        elif master is not None:
            merged_args += ["master", master]

        merged_args += list(args)
        merged_args += [arg for item in kwargs.items() for arg in item]

        assert merged_args, "Nothing to be set."

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        nmci.process.run_stdout(
            ["ip", *ns_args, "link", "set", ifname, *merged_args], as_bytes=True
        )

    def link_delete(
        self, ifname=None, *, ifindex=None, accept_nodev=False, namespace=None
    ):
        """
        Delete link.

        :param ifname: interafce name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param accept_nodev: whether to raise if device already not present, defaults to False
        :type accept_nodev: bool, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        """
        if ifname is None or ifindex is not None:
            li = self.link_show_maybe(ifindex=ifindex, namespace=namespace)
            if li is None:
                if accept_nodev:
                    return
                raise Exception(f"Interface with ifindex {ifindex} not found")
            if ifname is not None and ifname != li["ifname"]:
                raise Exception(
                    f"Failure deleting interface because interface with ifindex {ifindex} is called \"{li['ifname']}\" and not \"{ifname}\""
                )
            ifname = li["ifname"]

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        try:
            nmci.process.run_stdout(
                ["ip", *ns_args, "link", "delete", ifname], as_bytes=True
            )
        except Exception:
            if accept_nodev:
                if ifindex is not None:
                    if (
                        self.link_show_maybe(ifindex=ifindex, namespace=namespace)
                        is None
                    ):
                        return
                elif self.link_show_maybe(ifname=ifname, namespace=namespace) is None:
                    return
            # The interface either still exists, or the caller requested a failure
            # trying to delete a non-existing interface.
            raise

    def link_add(
        self,
        ifname,
        link_type,
        *args,
        address=None,
        ifindex=None,
        namespace=None,
        parent_link=None,
        wait_for_device=None,
        **kwargs,
    ):
        """
        Add new link. Additional arguments are appended to
        :code:`ip link add ...` command. Additional keyword arguments are
        appended with separated space: :code:`peer='p_name'` is appended as
        :code:`'peer' 'p_name'`.

        :param ifname: interface name
        :type ifname: str
        :param link_type: interface type
        :type link_type: str
        :param address: MAC address, defaults to None
        :type address: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param parent_link: name of parent link (e.g. for vlan type), defaults to None
        :type parent_link: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        """
        merged_args = list(args)
        for key, value in kwargs.items():
            merged_args += [key, value]

        if link_type == "veth" and ifindex is not None:
            merged_args += ["index", str(ifindex + 1)]

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        common_args = []
        if ifindex is not None:
            common_args += ["index", str(ifindex)]
        if address is not None:
            common_args += ["address", address]

        parent_link_args = []
        if parent_link is not None:
            parent_link_args = ["link", parent_link]

        nmci.process.run_stdout(
            [
                "ip",
                *ns_args,
                "link",
                "add",
                *parent_link_args,
                ifname,
                *common_args,
                "type",
                link_type,
                *merged_args,
            ],
            as_bytes=True,
        )

        if wait_for_device:
            self.link_show(
                ifname, namespace=namespace, ifindex=ifindex, timeout=wait_for_device
            )

    def netns_list(self, with_binary=False, verbose=True):
        """
        List availiable namespaces.

        :param with_binary: whether to return as bytes, defaults to False
        :type with_binary: bool, optional
        :param verbose: whether to embed output, defaults to True
        :type verbose: bool, optional
        :return: list of interface names
        :rtype: list of str
        """

        embed_combine_tag = (
            nmci.embed.TRACE_COMBINE_TAG if verbose else nmci.embed.NO_EMBED
        )
        out = nmci.process.run_stdout(
            "ip netns list", as_bytes=True, embed_combine_tag=embed_combine_tag
        )

        if not out:
            return []

        if out.endswith(b"\n"):
            out = out[:-1]

        # We just split by newlines. That is wrong, if the netns name
        # contains a newline (which it can *sigh*).
        #
        # We can also not use json output, because the iproute2 version
        # might be compiled without JSON support and because iproute2 will
        # blindly output non-UTF-8 names (which namespace names can contain *sigh*).
        #
        # We can also not simply list "/var/run/netns", because not every
        # file there might be a valid netns. We would have to open the file
        # and check whether the FD is valid (which is too cumbersome).
        #
        # So this is it.
        #
        # The result is a list of string or byte, depending on whether
        # the name can be decoded as utf-8.
        #
        # Also, strip "(id: X)" part if present.

        id_regexp = re.compile(b" \\(id: [0-9]*\\)$")
        lines = out.split(b"\n")
        lines_without_ids = [re.sub(id_regexp, b"", l) for l in lines]

        namespaces = [nmci.util.binary_to_str(b) for b in lines_without_ids]

        if with_binary:
            namespaces = [x for x in namespaces if not isinstance(x, bytes)]

        return namespaces

    def netns_add(self, name, cleanup=True):
        """
        Add namespace

        :param name: name if the namespace
        :type name: str
        :param cleanup: whether to clean up the namespace after scenario. Defaults to True
        :type cleanup: bool
        """
        if cleanup:
            nmci.cleanup.add_namespace(name)
        if name in self.netns_list():
            self.netns_delete(name)
            # fail scenario if we didn't succeed in cleaning up the NS
            if name in self.netns_list():
                raise Exception(f"Failed to clean up leftover netns {name}!")
        nmci.process.run_stdout(["ip", "netns", "add", name])

    def netns_delete(self, name, check=True):
        """
        Delete namespace

        :param name: name of namespace
        :type name: str
        :param check: whether to raise if namespace already deleted, defaults to True
        :type check: bool, optional
        """
        nmci.process.run_stdout(
            ["ip", "netns", "delete", name],
            ignore_returncode=not check,
            ignore_stderr=not check,
        )

    def _route(
        self,
        route,
        ifname=None,
        action=None,
        *args,
        ifindex=None,
        addr_family=None,
        namespace=None,
        wait_for_device=None,
        **kwargs,
    ):
        """
        Perform route action.  Additional arguments are appended to
        :code:`ip route ...` command. Additional keyword arguments are
        appended with separated space: :code:`peer='p_name'` is appended as
        :code:`'peer' 'p_name'`.

        :param route: route, address and prefix or :code:`'default'`
        :type route: str
        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param action: one of 'add', 'del', 'show', 'flush', defaults to None
        :type action: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        :return: STDOUT of :code:`ip route` command
        :rtype: str
        """
        assert action in [
            "add",
            "del",
            "show",
            "flush",
        ], f"Unknown action: :code:`{action}`."

        show_or_flush = action in ["show", "flush"]
        route_arg = []
        addr_family_arg = []
        if not show_or_flush:
            route_norm, addr_family_detect, plen = self.ipaddr_plen_parse(
                route, addr_family
            )
            route_arg = [f"{route_norm}/{plen}"]
            addr_family_arg = [f"-{self.addr_family_num(addr_family_detect)}"]
        elif addr_family is not None:
            addr_family_arg = [f"-{self.addr_family_num(addr_family)}"]

        if (
            (ifname is None and not show_or_flush)
            or ifindex is not None
            or wait_for_device is not None
        ):
            li = self.link_show(
                ifindex=ifindex,
                ifname=ifname,
                timeout=wait_for_device,
                namespace=namespace,
            )
            ifname = li["ifname"]

        ifname_arg = ["dev", ifname] if ifname is not None else []

        ns_arg = ["-n", namespace] if namespace is not None else []

        merged_args = list(args)
        merged_args += [arg for item in kwargs.items() for arg in item]

        return nmci.process.run_stdout(
            [
                "ip",
                *addr_family_arg,
                *ns_arg,
                "route",
                action,
                *route_arg,
                *merged_args,
                *ifname_arg,
            ]
        )

    def route_add(
        self,
        route,
        ifname=None,
        *args,
        ifindex=None,
        addr_family=None,
        namespace=None,
        wait_for_device=None,
        **kwargs,
    ):
        """
        Add route.  Additional arguments are appended to
        :code:`ip route ...` command. Additional keyword arguments are
        appended with separated space: :code:`peer='p_name'` is appended as
        :code:`'peer' 'p_name'`.

        :param route: route, address and prefix or :code:`'default'`
        :type route: str
        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        """
        self._route(
            route,
            ifname,
            "add",
            *args,
            addr_family=addr_family,
            ifindex=ifindex,
            namespace=namespace,
            wait_for_device=wait_for_device,
            **kwargs,
        )

    def route_del(
        self,
        route,
        ifname=None,
        *args,
        ifindex=None,
        namespace=None,
        addr_family=None,
        wait_for_device=None,
        **kwargs,
    ):
        """
        Delete route.  Additional arguments are appended to
        :code:`ip route ...` command. Additional keyword arguments are
        appended with separated space: :code:`peer='p_name'` is appended as
        :code:`'peer' 'p_name'`.

        :param route: route, address and prefix or :code:`'default'`
        :type route: str
        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        """
        self._route(
            route,
            ifname,
            "del",
            *args,
            addr_family=addr_family,
            ifindex=ifindex,
            namespace=namespace,
            wait_for_device=wait_for_device,
            **kwargs,
        )

    def route_flush(
        self,
        ifname=None,
        ifindex=None,
        namespace=None,
        wait_for_device=None,
        addr_family=None,
    ):
        """
        Flush routes.

        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        """
        self._route(
            None,
            ifname,
            "flush",
            addr_family=addr_family,
            ifindex=ifindex,
            namespace=namespace,
            wait_for_device=wait_for_device,
        )

    def route_show(
        self,
        ifname=None,
        ifindex=None,
        namespace=None,
        wait_for_device=None,
        addr_family=None,
    ):
        """
        Show routes. Returned in dictionary, where keys are routes (address with prefix)
        and value is additinal arguments (allowing simple checks: :code:`'1.2.3.4/10' in route_show()`)
        TODO will not work if multiple route is having different options.

        :param ifname: interface name, defaults to None
        :type ifname: str, optional
        :param ifindex: interface index, defaults to None
        :type ifindex: int or str, optional
        :param addr_family: address family, defaults to None
        :type addr_family: socket.AddressFamily or str, optional
        :param namespace: namespace, defaults to None
        :type namespace: str, optional
        :param wait_for_device: timeout until device appears, defaults to None
        :type wait_for_device: float, optional
        :return: routes in dictionary, keyword is route address with prefix, value additional argument.
        """
        result = {}
        routes = self._route(
            None,
            ifname,
            "show",
            addr_family=addr_family,
            ifindex=ifindex,
            namespace=namespace,
            wait_for_device=wait_for_device,
        )
        routes_lines = routes.strip("\n").split("\n")
        for route in routes_lines:
            if not route:
                continue
            route, params_str = route.split(" ", 1)
            if route != "default":
                route = (
                    route
                    if "/" in route
                    else f"{route}/{self.addr_family_plen(addr_family)}"
                )
            params = {}
            key = None
            for param in params_str.split(" "):
                if key is None:
                    key = param
                else:
                    params[key] = param
                    key = None
            result[route] = params
        return result


_module = _IP()
