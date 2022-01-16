#!/bin/bash

ip netns add route
ip netns add server
ip link add veth0s type veth peer name veth0s_p netns server
ip link add veth0r type veth peer name veth0r_p netns route
ip link add veth1r type veth peer name veth1r_p netns route
ip link add veth0c type veth peer name veth0c_p
ip link add veth1c type veth peer name veth1c_p
nmcli device set veth0c managed yes
nmcli device set veth0c_p managed yes
nmcli device set veth1c managed yes
nmcli device set veth1c_p managed yes
nmcli device set veth0s managed yes
nmcli device set veth0r managed yes
nmcli device set veth1r managed yes

cat > topo1.yaml << EOF
---
interfaces:
  - name: ovs1
    type: ovs-interface
    state: up
  - name: veth0c
    type: ethernet
    state: up
  - name: veth0c_p
    type: ethernet
    state: up
  - name: veth1c_p
    type: ethernet
    state: up
  - name: veth1c
    type: ethernet
    state: up
  - name: veth0s
    type: ethernet
    state: up
  - name: veth0r
    type: ethernet
    state: up
  - name: veth1r
    type: ethernet
    state: up
  - name: bond_test
    type: bond
    state: up
    link-aggregation:
      mode: balance-rr
      port:
      - veth0c_p
      - veth1c_p
    ipv4:
      address:
      - ip: 1.1.1.1
        prefix-length: 24
      enabled: true
      dhcp: false
    ipv6:
      address:
      - ip: 1000::1
        prefix-length: 64
      enabled: true
      dhcp: false
  - name: ovs-br0
    type: ovs-bridge
    state: up
    bridge:
      options:
        fail-mode: ''
        mcast-snooping-enable: false
        rstp: false
        stp: true
      port:
        - name: ovs1
        - name: veth0r
        - name: veth0c
        - name: veth1c
  - name: br_test
    type: linux-bridge
    state: up
    bridge:
      port:
        - name: veth0s
          stp-hairpin-mode: false
          stp-path-cost: 100
          stp-priority: 32
        - name: veth1r
          stp-hairpin-mode: false
          stp-path-cost: 100
          stp-priority: 32
    ipv4:
      enabled: false
      dhcp: false
  - name: bond_test.3
    type: vlan
    state: up
    ipv4:
      address:
      - ip: 1.1.3.1
        prefix-length: 24
      enabled: true
      dhcp: false
    ipv6:
      address:
      - ip: 1000:3::1
        prefix-length: 64
      enabled: true
      dhcp: false
    vlan:
      base-iface: bond_test
      id: 3
routes:
  config:
    - destination: 2.1.1.0/24
      next-hop-address: 1.1.1.254
      next-hop-interface: bond_test
      table-id: 254
    - destination: 2000::/64
      next-hop-address: 1000::a
      next-hop-interface: bond_test
      table-id: 254
EOF
ip a s |grep 111

nmstatectl set topo1.yaml; RC=$?

ip link delete veth0c ||true
ip link delete veth0r ||true
ip link delete veth1c ||true
ip link delete veth1r ||true
nmcli connection delete id ovs1 bond_test bond_test.3 br_test ovs-br0 ovs-port-ovs1 ovs-port-veth0c ovs-port-veth0r ovs-port-veth1c veth0c veth0c_p veth0r  veth1c veth1c_p veth1r || true

# delete residual connections (sometimes named without ovs-port prefix)
nmcli connection delete ovs1-port veth0c-port veth0r-port veth0s veth1c-port || true

# Workaround for bug https://bugzilla.redhat.com/show_bug.cgi?id=1935026
ovs-vsctl del-br ovs-br0 || true

ip netns del route || true
ip netns del server || true
sleep 2

exit $RC
