import re
import subprocess
import sys
import time

from . import process
from . import util


class _IP:
    def link_show_all(self, binary=None):

        # binary is:
        #   False: expect all stings to be UTF-8, the result only contains decoded strings
        #   True: expect at least some of the names to be binary, all the ifnames are bytes
        #   None: expect a mix. The ifnames that can be decoded as UTF-8 are returned
        #     as strings, otherwise as bytes.

        assert binary is None or binary is True or binary is False

        out = process.run_check(["ip", "-d", "link", "show"], as_bytes=True)

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

            # currently we only parse a subsetof the parameters

            ip_data = {}

            r = rb"^([0-9]+): *([^:@]+)(@[^:]*)?: <([^>]*)>"

            m = re.match(r, line)
            if not m:
                raise Exception("Unexpected line in ip link output: %s" % (line))

            ip_data["ifindex"] = int(m.group(1))
            ip_data["ifname"] = util.binary_to_str(m.group(2), binary)

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
        self, ifindex=None, ifname=None, flags=None, binary=None, allow_missing=False
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

        for data in self.link_show_all(binary=True):
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

        data["ifname"] = util.binary_to_str(data["ifname"], binary)

        return data

    def link_show(self, timeout=None, **kwargs):

        if timeout is not None:
            # if we have a timeout, we will poll/wait, until a suitable
            # link is ready.
            end_time = time.monotonic() + timeout

        while True:

            try:
                return self._link_show(**kwargs)
            except:
                if timeout is None:
                    raise
                pass

            if time.monotonic() >= end_time:
                raise Exception(
                    "Requested interface not found or not ready within timeout (args=%s)"
                    % (kwargs,)
                )

            time.sleep(0.08)

    def link_show_maybe(self, allow_missing=True, **kwargs):
        return self.link_show(allow_missing=allow_missing, **kwargs)

    def link_set(self, ifindex=None, ifname=None, up=None, wait_for_device=None):

        li = self.link_show(ifindex=ifindex, ifname=ifname, timeout=wait_for_device)

        if up is not None:
            if up:
                arg = "up"
            else:
                arg = "down"
            process.run_check(["ip", "link", "set", li["ifname"], arg])

    def link_delete(self, ifname=None, *, ifindex=None):

        if ifname is None or ifindex is not None:
            li = self.link_show(ifindex=ifindex)
            ifname = li["ifname"]

        process.run_check(["ip", "link", "delete", ifname])


sys.modules[__name__] = _IP()
