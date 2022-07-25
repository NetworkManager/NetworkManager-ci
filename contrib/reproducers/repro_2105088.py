#!/usr/bin/env python3

# Reproducer for:
#   https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/993
#   https://bugzilla.redhat.com/show_bug.cgi?id=2105088
# Sends a NAK when the current lease is renewed

from scapy.all import *
from datetime import datetime
import time
import sys

SERVER_IP = "172.25.1.1"
CLIENT_IP = "172.25.1.200"
SERVER_MAC = "00:01:02:09:04:05"
SUBNET_MASK = "255.255.255.0"
GATEWAY = "172.25.1.254"

DHCP_TYPE_UNKNOWN = 0
DHCP_TYPE_DISCOVER = 1
DHCP_TYPE_OFFER = 2
DHCP_TYPE_REQUEST = 3
DHCP_TYPE_DECLINE = 4
DHCP_TYPE_ACK = 5
DHCP_TYPE_NAK = 6

state = "None"
iface = ""


def log(msg):
    print("{} | {}".format(datetime.now(), msg))


def send_offer(pkt):
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
                ("message-type", DHCP_TYPE_OFFER),
                ("server_id", SERVER_IP),
                ("lease_time", 30),
                ("renewal_time", 15),
                ("rebinding_time", 25),
                ("subnet_mask", SUBNET_MASK),
                ("router", GATEWAY),
                ("end"),
            ]
        ),
        iface=iface,
        verbose=0,
    )
    log("-> DHCP Offer")


def send_ack(pkt):
    global state
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
                ("message-type", DHCP_TYPE_ACK),
                ("server_id", SERVER_IP),
                ("lease_time", 30),
                ("renewal_time", 15),
                ("rebinding_time", 25),
                ("subnet_mask", SUBNET_MASK),
                ("router", GATEWAY),
                ("end"),
            ]
        ),
        iface=iface,
        verbose=0,
    )
    log("-> DHCP Ack")
    state = "Bound"


def send_nak(pkt):
    global state
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
                ("message-type", DHCP_TYPE_NAK),
                ("server_id", SERVER_IP),
                ("error_message", "requested address not available"),
                ("end"),
            ]
        ),
        iface=iface,
        verbose=0,
    )
    log("-> DHCP Nak")
    state = "None"


def on_discover(pkt):
    log("<- DHCP Discover")
    send_offer(pkt)


def on_request(pkt):
    global state
    log("<- DHCP Request (state {})".format(state))
    if state == "Bound":
        send_nak(pkt)
        state = "None"
    else:
        send_ack(pkt)


def handle_dhcp_packet(pkt):
    if not pkt[DHCP]:
        return

    message_type = DHCP_TYPE_UNKNOWN
    for opt in pkt[DHCP].options:
        if opt[0] == "message-type":
            message_type = opt[1]

    if message_type == DHCP_TYPE_DISCOVER:
        on_discover(pkt)

    if message_type == DHCP_TYPE_REQUEST:
        on_request(pkt)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: {} INTERFACE".format(sys.argv[0]))
        sys.exit(1)

    iface = sys.argv[1]

    sniff(
        iface=iface,
        filter="udp and src port 68 and dst port 67",
        prn=handle_dhcp_packet,
    )
