import re
import socket

import nmci.process
import nmci.util


class _IP:
    def addr_family_norm(self, addr_family):
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
        if addr_family != socket.AF_INET and addr_family != socket.AF_INET6:
            raise ValueError(f"invalid address family {addr_family}")

    def addr_family_num(self, addr_family, allow_none=False):
        addr_family = self.addr_family_norm(addr_family)
        if addr_family == socket.AF_INET:
            return 4
        if addr_family == socket.AF_INET6:
            return 6
        if addr_family is None and allow_none:
            return None
        self.addr_family_check(addr_family)

    def addr_family_plen(self, addr_family):
        addr_family = self.addr_family_norm(addr_family)
        if addr_family == socket.AF_INET:
            return 32
        if addr_family == socket.AF_INET6:
            return 128
        self.addr_family_check(addr_family)

    def ipaddr_parse(self, s, addr_family=None):
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
        addr, addr_family = self.ipaddr_parse(s, addr_family)
        return addr

    def ipaddr_plen_parse(self, s, addr_family=None):
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
        (addr, addr_family, plen) = self.ipaddr_plen_parse(s, addr_family)
        if plen is None:
            return addr
        return f"{addr}/{plen}"

    def ipaddr_zero(self, addr_family):
        if self.addr_family_num(addr_family) == 4:
            return "0.0.0.0"
        else:
            return "::"

    def mac_aton(self, mac_str, force_len=None):
        # we also accept None and '' for convenience.
        # - None yiels None
        # - '' yields []
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
        if mac is None:
            return None
        return ":".join(["%02x" % c for c in bytearray(mac)])

    def mac_norm(self, mac_str, force_len=None):
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

        out = nmci.process.run_stdout(
            ["ip", *ns_args, "-d", "address", "show"], as_bytes=True
        )

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

        # binary is:
        #   False: expect all stings to be UTF-8, the result only contains decoded strings
        #   True: expect at least some of the names to be binary, all the ifnames are bytes
        #   None: expect a mix. The ifnames that can be decoded as UTF-8 are returned
        #     as strings, otherwise as bytes.

        assert binary is None or binary is True or binary is False

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        out = nmci.process.run_stdout(
            ["ip", *ns_args, "-d", "link", "show"], as_bytes=True
        )

        result = []

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

            while i < len(lines):
                line = lines[i]
                if not re.match(rb"^ +", line):
                    break
                i += 1

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

        return data

    def link_show(self, ifname=None, *, timeout=None, **kwargs):

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
        return self.link_show(ifname=ifname, allow_missing=allow_missing, **kwargs)

    def link_set(
        self,
        ifname=None,
        *,
        ifindex=None,
        up=None,
        wait_for_device=None,
        namespace=None,
        netns=None,
    ):

        if ifname is None or ifindex is not None or wait_for_device is not None:
            li = self.link_show(
                ifindex=ifindex,
                ifname=ifname,
                timeout=wait_for_device,
                namespace=namespace,
            )
            ifname = li["ifname"]

        args_set = [up is not None, netns is not None]
        assert any(args_set), "One of 'up' or 'netns' argument must be set."
        assert args_set.count(True) == 1, "Bot 'up' and 'netns' can not be set."

        if up is not None:
            if up:
                args = ["up"]
            else:
                args = ["down"]

        if netns is not None:
            args = ["netns", netns]

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        nmci.process.run_stdout(
            ["ip", *ns_args, "link", "set", ifname, *args], as_bytes=True
        )

    def link_delete(
        self, ifname=None, *, ifindex=None, accept_nodev=False, namespace=None
    ):

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

    def link_add(self, ifname, link_type, namespace=None, **kwargs):
        args = []
        for key, value in kwargs.items():
            args += [key, value]

        ns_args = []
        if namespace is not None:
            ns_args = ["-n", namespace]

        nmci.process.run_stdout(
            ["ip", *ns_args, "link", "add", ifname, "type", link_type, *args],
            as_bytes=True,
        )

    def netns_list(self, with_binary=False):

        out = nmci.process.run_stdout("ip netns list", as_bytes=True)

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

    def netns_add(self, name):
        nmci.process.run_stdout(["ip", "netns", "add", name])

    def netns_delete(self, name, check=True):
        nmci.process.run_stdout(
            ["ip", "netns", "delete", name],
            ignore_returncode=not check,
            ignore_stderr=not check,
        )
