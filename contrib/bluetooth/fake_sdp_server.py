#!/usr/bin/env python3
"""
Fake SDP server for NM-CI bluetooth DUN testing.
Listens on L2CAP PSM 1 (SDP) on a given BT address and sends garbage,
triggering NM's SDP error path in _connect_sdp_search_io_cb().

Usage: fake_sdp_server.py <bind_addr>
  Example: fake_sdp_server.py 00:AA:01:01:00:01
"""

import sys
import socket

AF_BLUETOOTH = 31
BTPROTO_L2CAP = 0
PSM_SDP = 1


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <bluetooth_address>", file=sys.stderr)
        sys.exit(1)

    bind_addr = sys.argv[1]

    sock = socket.socket(AF_BLUETOOTH, socket.SOCK_SEQPACKET, BTPROTO_L2CAP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((bind_addr, PSM_SDP))
    sock.listen(5)

    print(f"[fake-sdp] Listening on {bind_addr} PSM {PSM_SDP}", flush=True)

    while True:
        try:
            conn, client_info = sock.accept()
            print(f"[fake-sdp] Connection from {client_info}", flush=True)
            conn.send(b"\xde\xad\xbe\xef\x00\x01\x02\x03")
            conn.close()
        except Exception as e:
            print(f"[fake-sdp] Error: {e}", flush=True)


if __name__ == "__main__":
    main()
