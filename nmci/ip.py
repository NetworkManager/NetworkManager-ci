import sys
import subprocess

from . import util


class _IP:
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
        jstr = util.process_run(
            ["ip", "-j", "-d", "link", "show"], as_utf8=True, timeout=2
        )

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
