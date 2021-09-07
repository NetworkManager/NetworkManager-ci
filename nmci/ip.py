import re
import subprocess
import sys
import time

from . import util


class _IP:
    def _link_show_all_manual_parsing(self, binary):

        # binary is:
        #   False: expect all stings to be UTF-8, the result only contains decoded strings
        #   True: expect at least some of the names to be binary, all the ifnames are bytes
        #   None: expect a mix. The ifnames that can be decoded as UTF-8 are returned
        #     as strings, otherwise as bytes.
        as_utf8 = binary is False
        try_decode_as_utf8 = binary is not False

        jstr = util.process_run(
            ["ip", "-d", "link", "show"], as_utf8=as_utf8, timeout=2
        )

        result = []

        lines = jstr.split("\n" if as_utf8 else b"\n")
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

            if as_utf8:
                r = r"^([0-9]+): *([^:@]+)(@[^:]*)?: <([^>]*)>"
            else:
                r = rb"^([0-9]+): *([^:@]+)(@[^:]*)?: <([^>]*)>"

            m = re.match(r, line)
            if not m:
                raise Exception("Unexpected line in ip link output: %s" % (line))

            ip_data["ifindex"] = int(m.group(1))

            g = m.group(2)
            if not as_utf8 and try_decode_as_utf8:
                # If requested, we try to parse the binary output as utf-8.
                # In this mode, some of the names will be UTF-8, and some binary.
                try:
                    g = g.decode("utf-8")
                except:
                    pass
            ip_data["ifname"] = g

            g = m.group(4)
            if as_utf8:
                g = g.split(",")
            else:
                g = [s.decode("utf-8") for s in g.split(b",")]
            ip_data["flags"] = g

            while i < len(lines):
                line = lines[i]
                if not re.match(r"^ +" if as_utf8 else rb"^ +", line):
                    break
                i += 1

            result.append(ip_data)

        return result

    def link_show_all(self, binary=None):

        assert binary is None or binary is True or binary is False

        # We require iproute2 to give valid UTF-8. That means, you cannot use this
        # function if you have any interfaces with a non-UTF-8 name (like after
        # `ip link add $'d\xccf\\c' type dummy`).
        #
        # And of course, in those cases `iproute2` wouldn't even output valid
        # JSON to begin with, because JSON can only be UTF-8 (although `jq` wouldn't
        # complain about that).
        #
        # If you need to support non-UTF-8 names, this function is not for you.

        if getattr(self, "_ip_link_no_json", False):
            return self._link_show_all_manual_parsing(binary=binary)

        argv = ["ip", "-json", "-details", "link", "show"]

        proc = subprocess.run(
            argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=2
        )

        if proc.stderr:

            if proc.returncode == 255 and re.match(
                r'Option "-json" is unknown, try "ip -help"\.',
                proc.stderr.decode("utf-8", "replace"),
            ):
                self._ip_link_no_json = True
                return self._link_show_all_manual_parsing(binary=binary)

            # if anything was printed to stderr, we consider that
            # a fail.
            raise Exception(
                "`%s` printed something on stderr: %s"
                % (" ".join(argv), proc.stderr.decode("utf-8", "replace"))
            )

        if proc.returncode != 0:
            raise Exception(
                "`%s` returned exit code %s" % (" ".join(argv), proc.returncode)
            )

        try:
            jstr = proc.stdout.decode("utf-8", errors="strict")
        except UnicodeDecodeError:
            if binary is False:
                raise
            jstr = None

        if jstr is None:
            return self._link_show_all_manual_parsing(binary=binary)

        import json

        return json.loads(jstr)

    def _link_show(self, ifindex=None, ifname=None, flags=None):

        if ifindex is None and ifname is None:
            raise ValueError("Missing argument, either ifindex or ifname must be given")

        if ifname is None:
            ifname_b = None
        elif isinstance(ifname, str):
            ifname_b = ifname.encode("utf-8")
        else:
            ifname_b = ifname

        result = []

        for data in self.link_show_all():
            ii = data["ifindex"]
            if ifindex is not None and int(ifindex) != ii:
                continue
            if ifname_b is not None:
                ii = data["ifname"]
                if isinstance(ii, str):
                    ii = ii.encode("utf-8")
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
                raise KeyError("Could not find interface with " + s)
            raise KeyError("Could not find unique interface with " + s)

        return result[0]

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

    def link_set(self, ifindex=None, ifname=None, up=None, wait_for_device=None):

        li = self.link_show(ifindex=ifindex, ifname=ifname, timeout=wait_for_device)

        if up is not None:
            if up:
                arg = "up"
            else:
                arg = "down"
            util.process_run(["ip", "link", "set", li["ifname"], arg], timeout=1)


sys.modules[__name__] = _IP()
