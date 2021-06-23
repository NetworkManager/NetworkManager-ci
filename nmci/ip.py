import re
import sys
import subprocess

from . import util


class _IP:
    def _link_show_all_legacy(self):

        jstr = util.process_run(["ip", "-d", "link", "show"], as_utf8=True, timeout=2)

        result = []

        lines = jstr.split("\n")
        i = 0

        if lines and not lines[-1]:
            del lines[-1]

        if not lines:
            raise Exception("output of ip link is empty")

        while i < len(lines):
            line = lines[i]
            i += 1

            # currently we only parse 'ifindex' and 'ifname'

            ip_data = {}

            m = re.match(r"^([0-9]+): *([^:@]+)[:@].*", line)
            if not m:
                raise Exception("Unexpected line in ip link output: %s" % (line))

            ip_data["ifindex"] = int(m.group(1))
            ip_data["ifname"] = m.group(2)

            while i < len(lines):
                line = lines[i]
                if not re.match(r"^ +", line):
                    break
                i += 1

            result.append(ip_data)

        return result

    def _link_show_all_legacy_raw(self):

        jstr = util.process_run(["ip", "-d", "link", "show"], as_utf8=False, timeout=2)

        result = []

        lines = jstr.split(b"\n")
        i = 0

        if lines and not lines[-1]:
            del lines[-1]

        if not lines:
            raise Exception("output of ip link is empty")

        while i < len(lines):
            line = lines[i]
            i += 1

            # currently we only parse 'ifindex' and 'ifname'

            ip_data = {}

            m = re.match(rb"^([0-9]+): *([^:@]+)[:@].*", line)
            if not m:
                raise Exception("Unexpected line in ip link output: %s" % (line))

            ip_data["ifindex"] = int(m.group(1))
            ip_data["ifname"] = m.group(2)

            while i < len(lines):
                line = lines[i]
                if not re.match(rb"^ +", line):
                    break
                i += 1

            result.append(ip_data)

        return result

    def link_show_all(self):

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
            return self._link_show_all_legacy()

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
                return self._link_show_all_legacy()

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

        jstr = proc.stdout.decode("utf-8", errors="strict")

        import json

        return json.loads(jstr)

    def link_show(self, ifindex=None, ifname=None):

        if ifindex is None and ifname is None:
            raise ValueError("Missing argument, either ifindex or ifname must be given")

        result = []
        for data in self.link_show_all():
            ii = data["ifindex"]
            if ifindex is not None and int(ifindex) != ii:
                continue
            ii = data["ifname"]
            if ifname is not None and ifname != ii:
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


sys.modules[__name__] = _IP()
