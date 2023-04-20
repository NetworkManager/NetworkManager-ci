#!/usr/bin/env python3

from scapy.all import *
from datetime import datetime
import time

IFACE = "testX4p"
SERVER_IP = "172.25.1.1"
SERVER_IP_OTHER = "192.168.1.1"
CLIENT_IP = "172.25.1.200"
SERVER_MAC = "00:01:02:09:04:05"
SERVER_MAC_OTHER = "00:10:22:30:44:55"
SUBNET_MASK = "255.255.255.0"
GATEWAY = "172.25.1.254"


def log(msg):
    print("{} | {}".format(datetime.now(), msg))


def handle_dhcp_packet(pkt):

    if pkt[DHCP] and pkt[DHCP].options[0][1] == 1:
        print("")
        log("<- DHCP Discover")
        sendp(
            Ether(src=SERVER_MAC, dst=pkt[Ether].src)
            / IP(src=SERVER_IP, dst="255.255.255.255")
            / UDP(sport=67, dport=68)
            / BOOTP(
                op=2,
                yiaddr=CLIENT_IP,
                siaddr=SERVER_IP,
                giaddr=GATEWAY,
                chaddr=bytes.fromhex(pkt[Ether].src.replace(":", "")),
                xid=pkt[BOOTP].xid,
            )
            / DHCP(
                options=[
                    ("message-type", "offer"),
                    ("server_id", SERVER_IP),
                    ("lease_time", 180),
                    ("renewal_time", 60),
                    ("rebinding_time", 120),
                    ("subnet_mask", SUBNET_MASK),
                    ("router", GATEWAY),
                    ("end"),
                ]
            ),
            iface=IFACE,
            verbose=0,
        )
        log("-> DHCP Offer")

    if pkt[DHCP] and pkt[DHCP].options[0][1] == 3:
        log("<- DHCP Request")

        # send NAK from a different server
        sendp(
            Ether(src=SERVER_MAC_OTHER, dst=pkt[Ether].src)
            / IP(src=SERVER_IP_OTHER, dst=CLIENT_IP)
            / UDP(sport=67, dport=68)
            / BOOTP(
                op=2,
                yiaddr=CLIENT_IP,
                siaddr=SERVER_IP,
                giaddr=GATEWAY,
                chaddr=bytes.fromhex(pkt[Ether].src.replace(":", "")),
                xid=pkt[BOOTP].xid,
            )
            / DHCP(
                options=[
                    ("message-type", "nak"),
                    ("server_id", SERVER_IP_OTHER),
                    ("error_message", "requested address not available"),
                    ("end"),
                ]
            ),
            iface=IFACE,
            verbose=0,
        )
        log("-> DHCP Nak")

        time.sleep(0.1)

        # send correct ACK
        sendp(
            Ether(src=SERVER_MAC, dst=pkt[Ether].src)
            / IP(src=SERVER_IP, dst=CLIENT_IP)
            / UDP(sport=67, dport=68)
            / BOOTP(
                op=2,
                yiaddr=CLIENT_IP,
                siaddr=SERVER_IP,
                giaddr=GATEWAY,
                chaddr=bytes.fromhex(pkt[Ether].src.replace(":", "")),
                xid=pkt[BOOTP].xid,
            )
            / DHCP(
                options=[
                    ("message-type", "ack"),
                    ("server_id", SERVER_IP),
                    ("lease_time", 180),
                    ("renewal_time", 60),
                    ("rebinding_time", 120),
                    ("subnet_mask", SUBNET_MASK),
                    ("router", GATEWAY),
                    ("end"),
                ]
            ),
            iface=IFACE,
            verbose=0,
        )
        log("-> DHCP Ack")


if __name__ == "__main__":
    sniff(iface=IFACE, filter="udp and (port 67 or 68)", prn=handle_dhcp_packet)
