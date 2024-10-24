#!/usr/bin/python3l

import scapy.all as scapy

IFACE = "veth1"

if __name__ == "__main__":
    ra = (
        scapy.Ether(src="00:00:de:aa:bb:cc", dst="33:33:00:00:00:01")
        / scapy.IPv6(src="fe80::deff:feaa:bbcc", dst="FF02::1")
        / scapy.ICMPv6ND_RA(routerlifetime=0, reachabletime=0)
        / scapy.ICMPv6NDOptSrcLLAddr(lladdr="00:11:22:33:44:55")
        / scapy.ICMPv6NDOptPrefixInfo(
            prefixlen=64, validlifetime=0x6, preferredlifetime=0x6, prefix="dead::"
        )
        / scapy.ICMPv6NDOptRouteInfo(plen=1, len=5)
    )

    scapy.sendp(ra, iface=IFACE, verbose=0)
