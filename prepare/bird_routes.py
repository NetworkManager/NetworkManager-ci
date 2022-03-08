#!/usr/bin/env python3
"""
must be invoked with three arguments:
    dev (e.g. eth1)
    proto (4 or 6)
    count (number of addresses to generate)
"""

from sys import argv

def gen_addrs(dev, proto, count):
    lines = []
    for i in range(1, count + 1):
        a0 = i
        a1 = int(a0 / 256)
        a2 = int(a1 / 256)
        a3 = int(a2 / 256)
        if proto == 6:
            lines.append(f'route add 2001:{a3 % 256:x}{a2 % 256:02x}:{a1 % 256:x}{a0 % 256:02x}::/48 dev {dev} proto bird')
        elif proto == 4:
            lines.append(f'route add {a3 % 256}.{a2 % 256}.{a1 % 256}.{a0 % 256}/32 dev {dev} proto bird')
        else:
            raise SystemExit('protocol must be either 4 or 6')
    return '\n'.join(lines)

if __name__ == '__main__':
    print(gen_addrs(argv[1], int(argv[2]), int(argv[3])))
