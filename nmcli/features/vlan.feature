@testplan
Feature: nmcli - vlan

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @cleanvlan
    Scenario: Clean vlan
    * "eth0" is visible with command "ifconfig"


    @vlan
    @vlan_add_default_device
    Scenario: nmcli - vlan - add default device
     * Add a new connection of type "vlan" and options "con-name eth1.99 dev eth1 id 99"
     Then "eth1.99:" is visible with command "ifconfig"
     Then Check ifcfg-name file created for connection "eth1.99"


    @rhbz1273879
    @restart @vlan
    @nmcli_vlan_restart_persistence
    Scenario: nmcli - vlan - restart persistence
    * Execute "systemctl stop NetworkManager"
    * Append "NAME=eth0.99" to ifcfg file "eth0.99"
    * Append "ONBOOT=yes" to ifcfg file "eth0.99"
    * Append "BOOTPROTO=none" to ifcfg file "eth0.99"
    * Append "IPADDR=172.31.3.10" to ifcfg file "eth0.99"
    * Append "TYPE=Vlan" to ifcfg file "eth0.99"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth0.99"
    * Append "DEVICE=eth0.99" to ifcfg file "eth0.99"
    * Append "PHYSDEV=eth0" to ifcfg file "eth0.99"
    * Restart NM
    Then "eth0.99\s+vlan\s+connected" is visible with command "nmcli device" in "10" seconds
    * Restart NM
    Then "eth0.99\s+vlan\s+connected" is visible with command "nmcli device" in "10" seconds


    @rhbz1378418
    @ver+=1.4.0
    @restart @two_bridged_veths @kill_dnsmasq @eth
    @vlan_ipv4_ipv6_restart_persistence
    Scenario: NM - vlan - ipv4 and ipv6 restart persistence
    * Prepare veth pairs "test1" bridged over "vethbr"
    * Add a new connection of type "ethernet" and options "ifname test1 con-name ethie ipv4.method disabled ipv6.method ignore"
    * Add a new connection of type "vlan" and options "dev vethbr id 100 con-name tc1 ipv4.method manual ipv4.addresses 10.0.0.1/24 ipv6.method manual ipv6.addresses 1::1/64"
    * Wait for at least "3" seconds
    * Run child "dnsmasq --dhcp-range=10.0.0.10,10.0.0.15,2m --dhcp-range=1::100,1::fff,slaac,64,2m --enable-ra --interface=vethbr.100 --bind-interfaces"
    * Add a new connection of type "vlan" and options "dev test1 id 100 con-name tc2"
    * Execute "ip add add 1::666/128 dev test1"
    * Wait for at least "5" seconds
    * Stop NM
    Then "inet 10.0.0.1" is visible with command "ip a s test1.100" for full "5" seconds
     And "inet6 1::" is visible with command "ip a s test1.100"
     And "inet6 fe80" is visible with command "ip a s test1.100"


    @vlan
    @vlan_remove_connection
    Scenario: nmcli - vlan - remove connection
    Given "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth1.299 autoconnect no dev eth1 id 299"
    * Open editor for connection "eth1.299"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth1.299"
    * "inet 10.42." is visible with command "ifconfig"
    * Delete connection "eth1.299"
    * Wait for at least "5" seconds
    Then "inet 10.42." is not visible with command "ifconfig"
    Then ifcfg-"eth1.299" file does not exist


    @vlan
    @vlan_connection_up
    Scenario: nmcli - vlan - connection up
    * Add a new connection of type "vlan" and options "con-name eth1.99 autoconnect no dev eth1 id 99"
    * Open editor for connection "eth1.99"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * "eth1.99" is not visible with command "ifconfig"
    * Bring up connection "eth1.99"
    Then "eth1.99" is visible with command "ifconfig"


    @vlan
    @vlan_reup_connection
    Scenario: nmcli - vlan - connection up while up
    * Add a new connection of type "vlan" and options "con-name eth1.99 autoconnect yes dev eth1 id 99 ip4 1.2.3.4/24"
    Then "eth1.99\s+vlan\s+connected" is visible with command "nmcli device" in "30" seconds
    * Open editor for connection "eth1.99"
    * Set a property named "ipv4.method" to "shared" in editor
    * Enter in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    # With no errors
    Then Bring up connection "eth1.99"
     And "1.2.3.4" is not visible with command "ip a s eth1.99"


    @vlan
    @vlan_connection_down
    Scenario: nmcli - vlan - connection down
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth1.399 autoconnect no dev eth1 id 399"
    * Open editor for connection "eth1.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth1.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Bring down connection "eth1.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_connection_down_with_autoconnect
    Scenario: nmcli - vlan - connection down (autoconnect on)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth1.399 autoconnect no dev eth1 id 399"
    * Open editor for connection "eth1.399"
    * Set a property named "connection.autoconnect" to "yes" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Submit "yes" in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth1.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Bring down connection "eth1.399"
    * Wait for at least "10" seconds
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_change_id_with_no_interface_set
    Scenario: nmcli - vlan - change id without interface set
    * Add a new connection of type "vlan" and options "con-name eth1.65 autoconnect no dev eth1 id 65"
    * Open editor for connection "eth1.65"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Quit editor
    * Check value saved message showed in editor
    * Bring up connection "eth1.65"
    * "eth1.65@eth1" is visible with command "ip a"
    * Open editor for connection "eth1.65"
    * Set a property named "vlan.id" to "55" in editor
    * Save in editor
    * No error appeared in editor
    * Bring down connection "eth1.65"
    * Bring up connection "eth1.65"
    * "eth1.55@eth1" is visible with command "ip a"


    @vlan
    @vlan_change_id
    Scenario: nmcli - vlan - change id
    * Add a new connection of type "vlan" and options "con-name eth1.165 autoconnect no dev eth1 id 165"
    * Open editor for connection "eth1.165"
    * Set a property named "ipv4.method" to "shared" in editor
    * No error appeared in editor
    * Save in editor
    * Quit editor
    * Check value saved message showed in editor
    * Bring up connection "eth1.165"
    * Bring down connection "eth1.165"
    * Open editor for connection "eth1.165"
    * Set a property named "vlan.id" to "265" in editor
    * Set a property named "vlan.interface-name" to "eth1.265" in editor
    * Set a property named "connection.id" to "eth1.265" in editor
    * Set a property named "connection.interface-name" to "eth1.265" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * "eth1.265:" is not visible with command "ifconfig"
    * "inet 10.42.0.1" is not visible with command "ifconfig"
    * Bring up connection "eth1.265"
    Then "eth1.265:" is visible with command "ifconfig"
    Then "inet 10.42.0.1" is visible with command "ifconfig"


    @vlan
    @vlan_describe_all
    Scenario: nmcli - vlan - describe all
    * Open editor for a type "vlan"
    Then Check "parent|id|flags|ingress-priority-map|egress-priority-map" are present in describe output for object "vlan"


    @rhbz1244048
    @vlan
    @assertion_failure
    Scenario: nmcli - vlan - assertion failure
    * Add a new connection of type "vlan" and options "con-name eth1.99 autoconnect no ifname eth1.101 dev eth1 id 99"
    * Open editor for connection "eth1.99"
    * Set a property named "vlan.flags" to "1" in editor
    * Save in editor
    * No error appeared in editor
    * Quit editor


    @vlan
    @vlan_describe_separately
    Scenario: nmcli - vlan - describe separately
    * Open editor for a type "vlan"
    Then Check "\[parent\]" are present in describe output for object "vlan.parent"
    Then Check "\[id\]" are present in describe output for object "vlan.id"
    Then Check "\[flags\]" are present in describe output for object "vlan.flags"
    Then Check "\[ingress-priority-map\]" are present in describe output for object "vlan.ingress-priority-map"
    Then Check "\[egress-priority-map\]" are present in describe output for object "vlan.egress-priority-map"


    @vlan
    @vlan_disconnect_device
    Scenario: nmcli - vlan - disconnect device
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth1.399 autoconnect no dev eth1 id 399"
    * Open editor for connection "eth1.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth1.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Disconnect device "eth1.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_disconnect_device_with_autoconnect
    Scenario: nmcli - vlan - disconnect device (with autoconnect)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth1.499 autoconnect no dev eth1 id 499"
    * Open editor for connection "eth1.499"
    * Set a property named "connection.autoconnect" to "yes" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Submit "yes" in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth1.499"
    * "inet 10.42." is visible with command "ifconfig"
    * Disconnect device "eth1.499"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_device_tagging
    Scenario: nmcli - vlan - device tagging
    * Execute "yum -y install wireshark"
    * Add a new connection of type "vlan" and options "con-name eth1.80 dev eth1 id 80"
    * "eth1.80:" is visible with command "ifconfig"
    * Spawn "ping -I eth1.80 8.8.8.8" command
    Then "ID: 80" is visible with command "tshark -i eth1 -T fields -e vlan"
    Then Terminate spawned process "ping -I eth1.80 8.8.8.8"


    @vlan
    @vlan_on_bridge
    Scenario: nmcli - vlan - on bridge
    * Add a new connection of type "bridge" and options "con-name bridge ifname bridge stp no"
    * Add a new connection of type "vlan" and options "con-name bridge.15 dev bridge id 15"
    Then "bridge.15:" is visible with command "ifconfig"


    @rhbz1276343
    @vlan @restart
    @vlan_not_duplicated
    Scenario: nmcli - vlan - do not duplicate mtu and ipv4 vlan
    * Add a new connection of type "vlan" and options "con-name vlan dev eth1 id 80"
    * Modify connection "vlan" changing options "eth.mtu 1450 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "testeth1"
    * Bring "up" connection "vlan"
    * Restart NM
    Then "eth1.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1264322
    @restart
    @vlan_update_mac_from_bond
    Scenario: nmcli - vlan - update mac address from bond
    # Setup given in the bug description
    * Add a new connection of type "bridge" and options "ifname br0 con-name bridge-br0 autoconnect no"
    * Modify connection "bridge-br0" changing options "bridge.stp no connection.autoconnect yes"
    * Modify connection "bridge-br0" changing options "ipv4.method manual ipv4.address '192.168.1.11/24' ipv4.gateway '192.168.1.1'"
    * Modify connection "bridge-br0" changing options "ipv4.dns 8.8.8.8 ipv4.dns-search boston.com"
    * Bring up connection "bridge-br0"
    * Add a new connection of type "bond" and options "ifname bond0 con-name bond-bond0 autoconnect no mode active-backup"
    * Modify connection "bond-bond0" changing options "ipv4.method disabled ipv6.method ignore connection.autoconnect yes"
    * Bring up connection "bond-bond0"
    * Add a new connection of type "bond-slave" and options "ifname eth1 con-name bond-slave-eth1 master bond0"
    * Add a new connection of type "bond-slave" and options "ifname eth2 con-name bond-slave-eth2 master bond0"
    * Add a new connection of type "vlan" and options "ifname vlan10 con-name vlan-vlan10 autoconnect no dev bond0 id 10"
    * Modify connection "vlan-vlan10" changing options "connection.master br0 connection.slave-type bridge connection.autoconnect yes"
    * Bring up connection "vlan-vlan10"
    # Check all is up
    * "connected:bond-slave-eth1" is visible with command "nmcli -t -f STATE,CONNECTION device" in "5" seconds
    * "connected:bond-slave-eth2" is visible with command "nmcli -t -f STATE,CONNECTION device" in "5" seconds
    # Delete bridge and bond outside NM, leaving the vlan device (with its mac set)
    * Finish "systemctl stop NetworkManager.service"
    * Finish "ip link del bond0"
    * Finish "ip link del br0"
    * Finish "systemctl start NetworkManager.service"
    # Check the configuration has been restored in full after by NM again
    Then "connected:bridge-br0" is visible with command "nmcli -t -f STATE,CONNECTION device" in "30" seconds
    Then "connected:vlan-vlan10" is visible with command "nmcli -t -f STATE,CONNECTION device"
    Then "connected:bond-bond0" is visible with command "nmcli -t -f STATE,CONNECTION device"
    Then "connected:bond-slave-eth1" is visible with command "nmcli -t -f STATE,CONNECTION device"
    Then "connected:bond-slave-eth2" is visible with command "nmcli -t -f STATE,CONNECTION device"
    * Note the output of "ip a s bond0 | grep link/ether | awk '{print $2}'" as value "bond_mac"
    * Note the output of "ip a s vlan10 | grep link/ether | awk '{print $2}'" as value "vlan_mac"
    # And that the VLAN mac has changed according to the recreated other devices
    Then Check noted values "bond_mac" and "vlan_mac" are the same


    @rhbz1300755
    @ver+=1.4.0
    @vlan @del_test1112_veths @ipv4
    @bring_up_very_long_device_name
    Scenario: nmcli - general - bring up very_long_device_name
    * Execute "ip link add very_long_name type veth peer name test11"
    * Add a new connection of type "ethernet" and options "ifname very_long_name con-name ethie -- ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "ethie"
    * Add a new connection of type "vlan" and options "dev very_long_name id 1024 con-name vlan -- ipv4.method manual ipv4.addresses 1.2.3.55/24"
    * Bring "up" connection "vlan"
    Then "very_long_name:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "very_long_.1024:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 1.2.3.4\/24" is visible with command "ip a s very_long_name"
     And "inet 1.2.3.55\/24" is visible with command "ip a s very_long_.1024"


    @rhbz1312281 @rhbz1250225
    @ver+=1.4.0
    @vlan
    @reorder_hdr
    Scenario: nmcli - vlan - reorder HDR
    * Add a new connection of type "vlan" and options "con-name vlan ifname vlan dev eth1 id 80 ip4 1.2.3.4/32"
    When "REORDER_HDR" is visible with command "ip -d l show vlan"
     And "REORDER_HDR=yes" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
    * Modify connection "vlan" changing options "vlan.flags 0"
    * Bring "up" connection "vlan"
    Then "REORDER_HDR=no\s+VLAN_FLAGS=NO_REORDER_HDR" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
     And "REORDER_HDR" is not visible with command "ip -d l show vlan"


    @rhbz1363995
    @ver+=1.4
    @dummy
    @vlan_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Execute "ip link add link eth1 name vlan type vlan id 80"
    * Execute "ip link set dev vlan up"
    * Execute "ip add add 30.0.0.1/24 dev vlan"
    When "vlan:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"
    * Execute "ip link set dev vlan down"
    Then "vlan:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"


    @rhbz1414186
    @ver+=1.6
    @eth @restart @vlan
    @vlan_mtu_from_parent
    Scenario: nmcli - vlan - MTU from parent
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 802-3-ethernet.mtu 9000 ipv4.method disabled ipv6.method ignore"
    * Bring "down" connection "ethie"
    * Bring "up" connection "ethie"
    * Add a new connection of type "vlan" and options "con-name vlan ifname vlan dev eth1 id 80 ip4 1.2.3.4/32"
    When "mtu 9000" is visible with command "ip a s vlan" in "10" seconds
    * Stop NM
    * Execute "ip link set dev eth1 down"
    * Execute "ip link del vlan"
    Then "mtu 9000" is not visible with command "ip a s vlan"
    * Start NM
    Then "mtu 9000" is visible with command "ip a s vlan"


    @rhgb1437066
    @ver+=1.4.0
    @team @team_slaves
    @default_route_for_vlan_over_team
    Scenario: NM - vlan - default route for vlan over team
    * Add a new connection of type "team" and options "con-name team0 ifname nm-team"
    * Add a new connection of type "team-slave" and options "con-name team0.0 ifname eth10 master nm-team"
    * Add a new connection of type "vlan" and options "con-name team0.1 dev nm-team id 1 mtu 1500 ipv4.method manual ipv4.addresses 192.168.168.16/24 ipv4.gateway 192.168.103.1 ipv6.method manual ipv6.addresses 2168::16/64 ipv4.dns 8.8.8.8"
    When "1" is visible with command "ip r |grep nm-team.1 |grep default |wc -l" in "2" seconds
    * Execute "for i in `seq 1 23`; do ip link set nm-team addr 00:00:11:22:33:$i; done"
    Then "1" is visible with command "ip r |grep nm-team.1 |grep default |wc -l" in "2" seconds
