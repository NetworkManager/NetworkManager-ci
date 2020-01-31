@testplan
Feature: nmcli - vlan

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @vlan
    @vlan_add_default_device
    Scenario: nmcli - vlan - add default device
     * Add a new connection of type "vlan" and options "con-name eth7.99 dev eth7 id 99"
     Then "eth7.99:" is visible with command "ifconfig"
     Then Check ifcfg-name file created for connection "eth7.99"


    @rhbz1456911
    @ver+=1.8.0
    @vlan
    @vlan_add_beyond_range
    Scenario: nmcli - vlan - add vlan beyond range
     Then "0-4094 but is 4095" is visible with command "nmcli con add type vlan con-name vlan autoconnect no id 4095 dev eth7"
      And "vlan" is not visible with command "nmcli con show"


    @rhbz1273879
    @restart @vlan
    @nmcli_vlan_restart_persistence
    Scenario: nmcli - vlan - restart persistence
    * Stop NM
    * Append "NAME=eth7.99" to ifcfg file "eth7.99"
    * Append "ONBOOT=yes" to ifcfg file "eth7.99"
    * Append "BOOTPROTO=none" to ifcfg file "eth7.99"
    * Append "IPADDR=172.31.3.10" to ifcfg file "eth7.99"
    * Append "TYPE=Vlan" to ifcfg file "eth7.99"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7.99"
    * Append "DEVICE=eth7.99" to ifcfg file "eth7.99"
    * Append "PHYSDEV=eth7" to ifcfg file "eth7.99"
    * Restart NM
    Then "eth7.99\s+vlan\s+connected" is visible with command "nmcli device" in "10" seconds
    * Restart NM
    Then "eth7.99\s+vlan\s+connected" is visible with command "nmcli device" in "10" seconds


    @rhbz1378418
    @ver+=1.4.0
    @restart @two_bridged_veths @kill_dnsmasq_vlan
    @vlan_ipv4_ipv6_restart_persistence
    Scenario: NM - vlan - ipv4 and ipv6 restart persistence
    * Prepare veth pairs "test1" bridged over "vethbr"
    * Add a new connection of type "ethernet" and options "ifname test1 con-name vlan1 ipv4.method disabled ipv6.method ignore"
    * Add a new connection of type "vlan" and options "dev vethbr id 100 con-name tc1 ipv4.method manual ipv4.addresses 10.1.0.1/24 ipv6.method manual ipv6.addresses 1::1/64"
    * Wait for at least "3" seconds
    * Run child "dnsmasq --dhcp-range=10.1.0.10,10.1.0.15,2m --pid-file=/tmp/dnsmasq_vlan.pid --dhcp-range=1::100,1::fff,slaac,64,2m --enable-ra --interface=vethbr.100 --bind-interfaces"
    * Add a new connection of type "vlan" and options "dev test1 id 100 con-name tc2"
    * Execute "ip add add 1::666/128 dev test1"
    * Wait for at least "5" seconds
    * Stop NM
    Then "inet 10.1.0.1" is visible with command "ip a s test1.100" for full "5" seconds
     And "inet6 1::" is visible with command "ip a s test1.100"
     And "inet6 fe80" is visible with command "ip a s test1.100"



    @vlan
    @vlan_remove_connection
    Scenario: nmcli - vlan - remove connection
    Given "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth7.299 autoconnect no dev eth7 id 299"
    * Open editor for connection "eth7.299"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.299"
    * "inet 10.42." is visible with command "ifconfig"
    * Delete connection "eth7.299"
    * Wait for at least "5" seconds
    Then "inet 10.42." is not visible with command "ifconfig"
    Then ifcfg-"eth7.299" file does not exist


    @vlan
    @vlan_connection_up
    Scenario: nmcli - vlan - connection up
    * Add a new connection of type "vlan" and options "con-name eth7.99 autoconnect no dev eth7 id 99"
    * Open editor for connection "eth7.99"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * "eth7.99" is not visible with command "ifconfig"
    * Bring up connection "eth7.99"
    Then "eth7.99" is visible with command "ifconfig"


    @vlan
    @vlan_reup_connection
    Scenario: nmcli - vlan - connection up while up
    * Add a new connection of type "vlan" and options "con-name eth7.99 autoconnect yes dev eth7 id 99 ip4 1.2.3.4/24"
    Then "eth7.99\s+vlan\s+connected" is visible with command "nmcli device" in "30" seconds
    * Open editor for connection "eth7.99"
    * Set a property named "ipv4.method" to "shared" in editor
    * Enter in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    # With no errors
    Then Bring up connection "eth7.99"
     And "1.2.3.4" is not visible with command "ip a s eth7.99"


    @vlan
    @vlan_connection_down
    Scenario: nmcli - vlan - connection down
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth7.399 autoconnect no dev eth7 id 399"
    * Open editor for connection "eth7.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Bring down connection "eth7.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_connection_down_with_autoconnect
    Scenario: nmcli - vlan - connection down (autoconnect on)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth7.399 autoconnect no dev eth7 id 399"
    * Open editor for connection "eth7.399"
    * Set a property named "connection.autoconnect" to "yes" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Submit "yes" in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Bring down connection "eth7.399"
    * Wait for at least "10" seconds
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_change_id_with_no_interface_set
    Scenario: nmcli - vlan - change id without interface set
    * Add a new connection of type "vlan" and options "con-name eth7.65 autoconnect no dev eth7 id 65"
    * Open editor for connection "eth7.65"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Quit editor
    * Check value saved message showed in editor
    * Bring up connection "eth7.65"
    * "eth7.65@eth7" is visible with command "ip a"
    * Open editor for connection "eth7.65"
    * Set a property named "vlan.id" to "55" in editor
    * Save in editor
    * No error appeared in editor
    * Bring down connection "eth7.65"
    * Bring up connection "eth7.65"
    * "eth7.55@eth7" is visible with command "ip a"


    @vlan
    @vlan_change_id
    Scenario: nmcli - vlan - change id
    * Add a new connection of type "vlan" and options "con-name eth7.165 autoconnect no dev eth7 id 165"
    * Open editor for connection "eth7.165"
    * Set a property named "ipv4.method" to "shared" in editor
    * No error appeared in editor
    * Save in editor
    * Quit editor
    * Check value saved message showed in editor
    * Bring up connection "eth7.165"
    * Bring down connection "eth7.165"
    * Open editor for connection "eth7.165"
    * Set a property named "vlan.id" to "265" in editor
    * Set a property named "vlan.interface-name" to "eth7.265" in editor
    * Set a property named "connection.id" to "eth7.265" in editor
    * Set a property named "connection.interface-name" to "eth7.265" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * "eth7.265:" is not visible with command "ifconfig"
    * "inet 10.42.0.1" is not visible with command "ifconfig"
    * Bring up connection "eth7.265"
    Then "eth7.265:" is visible with command "ifconfig"
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
    * Add a new connection of type "vlan" and options "con-name eth7.99 autoconnect no ifname eth7.101 dev eth7 id 99"
    * Open editor for connection "eth7.99"
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
    * Add a new connection of type "vlan" and options "con-name eth7.399 autoconnect no dev eth7 id 399"
    * Open editor for connection "eth7.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Disconnect device "eth7.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_disconnect_device_with_autoconnect
    Scenario: nmcli - vlan - disconnect device (with autoconnect)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add a new connection of type "vlan" and options "con-name eth7.499 autoconnect no dev eth7 id 499"
    * Open editor for connection "eth7.499"
    * Set a property named "connection.autoconnect" to "yes" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Submit "yes" in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.499"
    * "inet 10.42." is visible with command "ifconfig"
    * Disconnect device "eth7.499"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan
    @vlan_device_tagging
    Scenario: nmcli - vlan - device tagging
    * Execute "yum -y install wireshark"
    * Add a new connection of type "vlan" and options "con-name eth7.80 dev eth7 id 80"
    * "eth7.80:" is visible with command "ifconfig" in "10" seconds
    * Spawn "ping -I eth7.80 8.8.8.8" command
    Then "ID: 80" is visible with command "tshark -i eth7 -T fields -e vlan" in "150" seconds
    Then Terminate spawned process "ping -I eth7.80 8.8.8.8"


    @vlan
    @vlan_on_bridge
    Scenario: nmcli - vlan - on bridge
    * Add a new connection of type "bridge" and options "con-name vlan_bridge7 ifname bridge7 stp no"
    * Add a new connection of type "vlan" and options "con-name vlan_bridge7.15 dev bridge7 id 15"
    Then "bridge7.15:" is visible with command "ifconfig"


    @rhbz1586191
    @ver+=1.12.0
    @vlan
    @vlan_over_bridge_over_team_over_nic
    Scenario: nmcli - vlan - over brdge on team
    * Add a new connection of type "team" and options "con-name vlan_team7 ifname team7 ipv4.method disabled ipv6.method ignore mtu 9000 config '{ "runner": {"name":"lacp", "fast_rate":true }}'"
    * Add a new connection of type "team-slave" and options "con-name vlan_team7.0 ifname eth7 mtu 9000 master team7"
    * Add a new connection of type "vlan" and options "con-name vlan_bridge7.15 dev team7 id 15 ipv4.method disabled ipv6.method ignore master bridge7 connection.slave-type bridge "
    * Add a new connection of type "bridge" and options "con-name vlan_bridge7 ifname bridge7 ipv4.method manual ipv6.method ignore ipv4.addresses "11.0.0.1/24""
    When "9000" is visible with command "ip a s eth7"
     And "9000" is visible with command "ip a s bridge7"
     And "9000" is visible with command "ip a s team7"
     And "9000" is visible with command "ip a s team7.15"

    * Reboot
    Then "9000" is visible with command "ip a s eth7" in "10" seconds
     And "9000" is visible with command "ip a s bridge7" in "10" seconds
     And "9000" is visible with command "ip a s team7" in "10" seconds
     And "9000" is visible with command "ip a s team7.15" in "10" seconds


    @rhbz1276343
    @vlan @restart
    @vlan_not_duplicated
    Scenario: nmcli - vlan - do not duplicate mtu and ipv4 vlan
    * Add a new connection of type "vlan" and options "con-name vlan dev eth7 id 80"
    * Modify connection "vlan" changing options "ethe.mtu 1450 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "testeth7"
    * Bring "up" connection "vlan"
    * Restart NM
    Then "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1376199
    @ver+=1.8.0
    @restart @vlan
    @vlan_not_stalled_after_connection_delete
    Scenario: nmcli - vlan - delete vlan device after restart
    * Add a new connection of type "vlan" and options "con-name vlan dev eth7 id 80"
    * Modify connection "vlan" changing options "ethe.mtu 1450 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "testeth7"
    * Bring "up" connection "vlan"
    * Restart NM
    When "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Delete connection "vlan"
    Then "eth7.80" is not visible with command "nmcli device" in "5" seconds


    @rhbz1264322
    @restart @vlan
    @vlan_update_mac_from_bond
    Scenario: nmcli - vlan - update mac address from bond
    # Setup given in the bug description
    * Add a new connection of type "bridge" and options "ifname bridge7 con-name vlan_bridge7 autoconnect no"
    * Modify connection "vlan_bridge7" changing options "bridge.stp no connection.autoconnect yes"
    * Modify connection "vlan_bridge7" changing options "ipv4.method manual ipv4.address '192.168.1.11/24' ipv4.gateway '192.168.1.1'"
    * Modify connection "vlan_bridge7" changing options "ipv4.dns 8.8.8.8 ipv4.dns-search boston.com"
    * Bring up connection "vlan_bridge7"
    * Add a new connection of type "bond" and options "ifname bond7 con-name vlan_bond7 autoconnect no mode active-backup"
    * Modify connection "vlan_bond7" changing options "ipv4.method disabled ipv6.method ignore connection.autoconnect yes"
    * Bring up connection "vlan_bond7"
    * Add a new connection of type "bond-slave" and options "ifname eth7 con-name vlan_bond7.7 master bond7"
    * Add a new connection of type "vlan" and options "ifname vlan7 con-name vlan_vlan7 autoconnect no dev bond7 id 7"
    * Modify connection "vlan_vlan7" changing options "connection.master bridge7 connection.slave-type bridge connection.autoconnect yes"
    * Bring up connection "vlan_vlan7"
    # Check all is up
    * "connected:vlan_bond7.7" is visible with command "nmcli -t -f STATE,CONNECTION device" in "5" seconds
    # Delete bridge and bond outside NM, leaving the vlan device (with its mac set)
    * Stop NM
    * Finish "ip link del bond7"
    * Finish "ip link del bridge7"
    * Start NM
    # Check the configuration has been restored in full after by NM again
    Then "connected:vlan_bridge7" is visible with command "nmcli -t -f STATE,CONNECTION device" in "30" seconds
    Then "connected:vlan_vlan7" is visible with command "nmcli -t -f STATE,CONNECTION device"
    Then "connected:vlan_bond7" is visible with command "nmcli -t -f STATE,CONNECTION device"
    Then "connected:vlan_bond7.7" is visible with command "nmcli -t -f STATE,CONNECTION device"
    * Note the output of "ip a s bond7 | grep link/ether | awk '{print $2}'" as value "bond_mac"
    * Note the output of "ip a s vlan7 | grep link/ether | awk '{print $2}'" as value "vlan_mac"
    # And that the VLAN mac has changed according to the recreated other devices
    Then Check noted values "bond_mac" and "vlan_mac" are the same


    @rhbz1300755
    @ver+=1.4.0
    @vlan @del_test1112_veths @ipv4
    @bring_up_very_long_device_name
    Scenario: nmcli - general - bring up very_long_device_name
    * Execute "ip link add very_long_name type veth peer name test11"
    * Add a new connection of type "ethernet" and options "ifname very_long_name con-name vlan1 -- ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "vlan1"
    * Add a new connection of type "vlan" and options "dev very_long_name id 1024 con-name vlan -- ipv4.method manual ipv4.addresses 1.2.3.55/24"
    * Bring "up" connection "vlan"
    Then "very_long_name:connected:vlan1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "very_long_.1024:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 1.2.3.4\/24" is visible with command "ip a s very_long_name"
     And "inet 1.2.3.55\/24" is visible with command "ip a s very_long_.1024"


    @rhbz1312281 @rhbz1250225
    @ver+=1.4.0
    @vlan
    @reorder_hdr
    Scenario: nmcli - vlan - reorder HDR
    * Add a new connection of type "vlan" and options "con-name vlan ifname vlan dev eth7 id 80 ip4 1.2.3.4/32"
    When "REORDER_HDR" is visible with command "ip -d l show vlan"
     And "REORDER_HDR=yes" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
    * Modify connection "vlan" changing options "vlan.flags 0"
    * Bring "up" connection "vlan"
    Then "REORDER_HDR=no\s+VLAN_FLAGS=NO_REORDER_HDR" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
     And "REORDER_HDR" is not visible with command "ip -d l show vlan"


    @rhbz1363995
    @ver+=1.4
    @dummy @vlan
    @vlan_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Execute "ip link add link eth7 name vlan type vlan id 80"
    * Execute "ip link set dev vlan up"
    * Execute "ip add add 30.0.0.1/24 dev vlan"
    When "vlan:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"
    * Execute "ip link set dev vlan down"
    Then "vlan:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"


    @rhbz1231526
    @ver+=1.8.0
    @vlan_create_many_vlans
    Scenario: NM - vlan - create 255 vlans
    * Execute "for i in {1..255}; do ip link add link eth7 name vlan.$i type vlan id $i; ip link set dev vlan.$i up; ip add add 30.0.0.$i/24 dev vlan.$i;done" without waiting for process to finish
    When "30.0.0.255/24" is visible with command "ip a s vlan.255" in "60" seconds
    Then "^[1]?[0-9][0-9][0-9]\s+" is visible with command "G_DBUS_DEBUG=message nmcli c 2>&1 |grep 'GDBus-debug:Message:' |wc -l" in "30" seconds


    @rhbz1414186
    @ver+=1.6
    @eth @vlan @restart
    @vlan_mtu_from_parent
    Scenario: nmcli - vlan - MTU from parent
    * Add a new connection of type "ethernet" and options "con-name vlan1 ifname eth7 802-3-ethernet.mtu 9000 ipv4.method disabled ipv6.method ignore"
    * Bring "down" connection "vlan1"
    * Bring "up" connection "vlan1"
    * Add a new connection of type "vlan" and options "con-name vlan ifname vlan dev eth7 id 80 ip4 1.2.3.4/32"
    When "mtu 9000" is visible with command "ip a s vlan" in "10" seconds
    * Stop NM
    * Execute "ip link set dev eth7 down"
    * Execute "ip link del vlan"
    * Execute "rm -rf /var/run/NetworkManager"
    Then "mtu 9000" is not visible with command "ip a s vlan"
    * Start NM
    When "mtu 9000" is visible with command "ip a s vlan" in "10" seconds


    @rhbz1770691
    @ver+=1.20.0
    @eth @vlan
    @vlan_mtu_reapply
    Scenario: nmcli - vlan - MTU from parent
    * Add a new connection of type "ethernet" and options "con-name vlan1 ifname eth7 802-3-ethernet.mtu 2000 ipv4.method disabled ipv6.method ignore"
    * Bring "up" connection "vlan1"
    * Add a new connection of type "vlan" and options "con-name eth7.299 ifname eth7.299 dev eth7 id 299 802-3-ethernet.mtu 2000 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Add a new connection of type "vlan" and options "con-name eth7.399 ifname eth7.399 dev eth7 id 399 802-3-ethernet.mtu 2000 ipv4.method manual ipv4.addresses 1.2.3.5/24"
    When "mtu 2000" is visible with command "ip a s eth7" in "10" seconds
    When "mtu 2000" is visible with command "ip a s eth7.299" in "10" seconds
    When "mtu 2000" is visible with command "ip a s eth7.399" in "10" seconds
    * Modify connection "eth7.299" changing options "ethe.mtu 2200"
    * Modify connection "vlan1" changing options "ethe.mtu 2200"
    * Bring "up" connection "eth7.299"
    * Bring "up" connection "vlan1"
    Then "mtu 2200" is visible with command "ip a s eth7.299" in "10" seconds
    Then "mtu 2200" is visible with command "ip a s eth7" in "10" seconds
    Then "mtu 2000" is visible with command "ip a s eth7.399" in "10" seconds


    @rhbz1414901
    @ver+=1.10.0
    @vlan @restart @teardown_testveth
    @vlan_mtu_from_parent_with_slow_dhcp
    Scenario: nmcli - vlan - MTU from parent
    * Prepare simulated test "test77" device
    * Add a new connection of type "ethernet" and options "con-name vlan1 ifname test77 802-3-ethernet.mtu 9000 ipv4.method auto ipv6.method auto"
    * Bring "down" connection "vlan1"
    * Bring "up" connection "vlan1"
    * Add a new connection of type "vlan" and options "con-name vlan2 ifname vlan 802-3-ethernet.mtu 9000 dev test77 id 80 ip4 1.2.3.4/32"
    When "mtu 9000" is visible with command "ip a s vlan" in "10" seconds
    * Stop NM
    * Execute "ip link set dev test77 mtu 1500"
    * Execute "ip link del vlan"
    Then "mtu 9000" is not visible with command "ip a s vlan"
    * Execute "ip netns exec test77_ns kill -SIGSTOP $(cat /tmp/test77_ns.pid)"
    * Start NM
    * Execute "sleep 5 && ip netns exec test77_ns kill -SIGCONT $(cat /tmp/test77_ns.pid)"
    Then "mtu 9000" is visible with command "ip a s test77" in "10" seconds
    Then "mtu 9000" is visible with command "ip a s vlan" in "10" seconds


    @rhbz1437066
    @ver+=1.4.0
    @vlan
    @default_route_for_vlan_over_team
    Scenario: NM - vlan - default route for vlan over team
    * Add a new connection of type "team" and options "con-name vlan_team7 ifname team7"
    * Add a new connection of type "team-slave" and options "con-name vlan_team7.0 ifname eth7 master team7"
    * Add a new connection of type "vlan" and options "con-name vlan_team7.1 dev team7 id 1 mtu 1500 ipv4.method manual ipv4.addresses 192.168.168.16/24 ipv4.gateway 192.168.103.1 ipv6.method manual ipv6.addresses 2168::16/64 ipv4.dns 8.8.8.8"
    * Bring "up" connection "vlan_team7"
    * Bring "up" connection "vlan_team7.0"
    * Bring "up" connection "vlan_team7.1"
    When "1" is visible with command "ip r |grep team7.1 |grep default |wc -l" in "2" seconds
    * Execute "for i in `seq 1 23`; do ip link set team7 addr 00:00:11:22:33:$i; done"
    Then "1" is visible with command "ip r |grep team7.1 |grep default |wc -l" in "2" seconds


    @rhbz1553595
    @ver+=1.10.2 @ver-=1.17.90
    @vlan @bond @slaves @restart
    @vlan_on_bond_autoconnect
    Scenario: NM - vlan - autoconnect vlan on bond specified as UUID
    * Add connection type "bond" named "bond0" for device "nm-bond"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show bond0"
    * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
    * Add slave connection for master "nm-bond" on device "eth4" named "bond0.1"
    * Add a new connection of type "vlan" and options "con-name vlan_bond7 dev nm-bond id 7 ip4 192.168.168.16/24 autoconnect no"
    * Modify connection "vlan_bond7" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan_bond7 connection.autoconnect yes"
    * Reboot
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1553595 @rhbz1701585
    @ver+=1.18.0
    @vlan @bond @slaves @restart
    @vlan_on_bond_autoconnect
    Scenario: NM - vlan - autoconnect vlan on bond specified as UUID
    * Add connection type "bond" named "bond0" for device "nm-bond"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show bond0"
    * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
    * Add slave connection for master "nm-bond" on device "eth4" named "bond0.1"
    * Add a new connection of type "vlan" and options "con-name vlan_bond7 dev nm-bond id 7 ip4 192.168.168.16/24 autoconnect no"
    * Modify connection "vlan_bond7" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan_bond7 connection.autoconnect yes"
    * Reboot
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Execute "nmcli networking off"
    * Restart NM
    * Execute "nmcli networking on"
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1659063
    @ver+=1.14
    @vlan @bond @slaves @teardown_testveth
    @static_route_persists_mac_change
    Scenario: NM - vlan - static route is not deleted after NM changes MAC
    * Prepare simulated test "test77" device
    * Add connection type "bond" named "bond0" for device "nm-bond"
    * Add a new connection of type "bond" ifname "nm-bond" and options "autocnnect no ethernet.cloned-mac-address preserve"
    * Add a new connection of type "vlan" and options "autoconnect no ethernet.cloned-mac-address preserve con-name vlan_bond7 ipv4.method disabled ipv6.method ignore vlan.id 7 vlan.parent nm-bond"
    * Add a new connection of type "ethernet" and options "autoconnect no con-name bond0.0 ethernet.cloned-mac-address preserve ifname test77 master nm-bond slave-type bond"
    * Bring "up" connection "bond0"
    * Bring "up" connection "vlan_bond7"
    * Execute "ip addr add 192.168.168.16/24 dev nm-bond.7"
    * Execute "ip route add 192.168.169.3/32 via 192.168.168.16 dev nm-bond.7"
    * Bring "up" connection "bond0.0"
    Then "192.168.169.3 via 192.168.168.16 dev nm-bond.7" is visible with command "ip r"


    @ver+=1.12
    @vlan @restart
    @vlan_create_macvlan_on_vlan
    Scenario: nmcli - vlan - create macvlan on vlan
    * Add a new connection of type "vlan" and options "con-name eth7.99 dev eth7 id 99"
    * Add a new connection of type "vlan" and options "con-name eth7.299 dev eth7 id 299"
    * Add a new connection of type "macvlan" and options "con-name vlan1 mode bridge macvlan.parent eth7.99 ifname mvl1"
    * Add a new connection of type "macvlan" and options "con-name vlan2 mode bridge macvlan.parent eth7.99 ifname mvl2"
    * Add a new connection of type "macvlan" and options "con-name vlan mode bridge macvlan.parent eth7.299 ifname mvl"
    * Restart NM


    @rhbz1716438
    @ver+=1.18.3
    @vlan
    @vlan_L2_UUID
    Scenario: NM - vlan - L2 only master via UUID
    * Add a new connection of type "ethernet" and options "con-name vlan1 ifname eth7 ipv4.method disabled ipv6.method ignore"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show vlan1"
    * Add a new connection of type "vlan" and options "con-name vlan ifname eth7.80 dev eth7 id 80 ip4 192.168.1.2/24"
    * Modify connection "vlan" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan connection.autoconnect yes"
    * Bring "up" connection "vlan"
    Then "eth7:connected:vlan1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1066705
    @dummy
    @vxlan_interface_recognition
    Scenario: NM - vxlan - interface support
    * Execute "/sbin/ip link add dummy0 type vxlan id 42 group 239.1.1.1 dev eth7"
    When "unmanaged" is visible with command "nmcli device show dummy0" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add fd00::666/8 dev dummy0"
    Then "connected" is visible with command "nmcli device show dummy0" in "10" seconds
    Then vxlan device "dummy0" check for parent "eth7"


    @rhbz1768388
    @ver+=1.22
    @vlan
    @vxlan_dbus_shows_port_numbers
    Scenario: NM - vxlan - dbus shows port numbers
    * Add a new connection of type "vxlan" and options "ifname vlan1 con-name vlan1 vxlan.destination-port 70 vxlan.source-port-max 50 vxlan.source-port-min 30 id 70 dev eth7 ip4 1.2.3.4/24 remote 1.2.3.1"
    * Execute "nmcli con up vlan1"
    Then vxlan device "vlan1" check for ports "70, 30, 50"


    @rhbz1768388
    @ver+=1.22
    @vlan
    @vxlan_libnm_shows_port_numbers
    Scenario: NM - vxlan - libnm shows port numbers
    * Add a new connection of type "vxlan" and options "ifname vlan1 con-name vlan1 vxlan.destination-port 70 vxlan.source-port-max 50 vxlan.source-port-min 30 id 70 dev eth7 ip4 1.2.3.4/24 remote 1.2.3.1"
    * Execute "nmcli con up vlan1"
    Then "70" is visible with command "python tmp/nmclient_get_connection_property.py vlan1 destination-port"
    Then "30" is visible with command "python tmp/nmclient_get_connection_property.py vlan1 source-port-min"
    Then "50" is visible with command "python tmp/nmclient_get_connection_property.py vlan1 source-port-max"
    Then "70" is visible with command "python tmp/nmclient_get_device_property.py vlan1 get_dst_port"
    Then "30" is visible with command "python tmp/nmclient_get_device_property.py vlan1 get_src_port_min"
    Then "50" is visible with command "python tmp/nmclient_get_device_property.py vlan1 get_src_port_max"


    @rhbz1774074
    @ver+=1.22
    @vlan
    @vxlan_do_not_up_if_no_master
    Scenario: NM - vxlan - do not up when no master
    * Add a new connection of type "vxlan" and options "ifname vlan1 con-name vlan1 vxlan.parent not-exists id 70 remote 172.25.1.1"
    Then "--" is visible with command "nmcli connection  |grep vlan1" for full "2" seconds
