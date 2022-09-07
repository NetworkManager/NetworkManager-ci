Feature: nmcli - vlan

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ifcfg-rh
    @vlan_add_default_device
    Scenario: nmcli - vlan - add default device
     * Add "vlan" connection named "eth7.99" with options "dev eth7 id 99"
     Then "eth7.99:" is visible with command "ifconfig"
     Then Check ifcfg-name file created for connection "eth7.99"


    @rhbz1456911
    @ver+=1.8.0
    @vlan_add_beyond_range
    Scenario: nmcli - vlan - add vlan beyond range
     * Cleanup connection "vlan"
     Then "0-4094 but is 4095" is visible with command "nmcli con add type vlan con-name vlan autoconnect no id 4095 dev eth7"
      And "vlan" is not visible with command "nmcli con show"


    @rhbz1273879
    @restart_if_needed
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
    @kill_dnsmasq_vlan @restart_if_needed
    @vlan_ipv4_ipv6_restart_persistence
    Scenario: NM - vlan - ipv4 and ipv6 restart persistence
    * Prepare veth pairs "test1" bridged over "vethbr"
    * Add "ethernet" connection named "vlan1" for device "test1" with options "ipv4.method disabled ipv6.method ignore"
    * Add "vlan" connection named "tc1" with options
          """
          dev vethbr
          id 100
          ipv4.method manual
          ipv4.addresses 10.1.0.1/24
          ipv6.method manual
          ipv6.addresses 1::1/64
          """
    * Wait for "3" seconds
    * Run child "dnsmasq --log-facility=/tmp/dnsmasq.log --dhcp-range=10.1.0.10,10.1.0.15,2m --pid-file=/tmp/dnsmasq_vlan.pid --dhcp-range=1::100,1::fff,slaac,64,2m --enable-ra --interface=vethbr.100 --bind-interfaces"
    * Add "vlan" connection named "tc2" with options "dev test1 id 100"
    * Execute "ip add add 1::666/128 dev test1"
    * Wait for "5" seconds
    * Stop NM
    Then "inet 10.1.0.1" is visible with command "ip a s test1.100" for full "5" seconds
     And "inet6 1::" is visible with command "ip a s test1.100"
     And "inet6 fe80" is visible with command "ip a s test1.100"


    @vlan_remove_connection
    Scenario: nmcli - vlan - remove connection
    Given "inet 10.42." is not visible with command "ifconfig"
    * Add "vlan" connection named "eth7.299" with options "autoconnect no dev eth7 id 299"
    * Open editor for connection "eth7.299"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.299"
    * "inet 10.42." is visible with command "ifconfig"
    * Delete connection "eth7.299"
    * Wait for "5" seconds
    Then "inet 10.42." is not visible with command "ifconfig"
    Then ifcfg-"eth7.299" file does not exist


    @vlan_connection_up
    Scenario: nmcli - vlan - connection up
    * Add "vlan" connection named "eth7.99" with options "autoconnect no dev eth7 id 99"
    * Open editor for connection "eth7.99"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * "eth7.99" is not visible with command "ifconfig"
    * Bring up connection "eth7.99"
    Then "eth7.99" is visible with command "ifconfig"


    @vlan_reup_connection
    Scenario: nmcli - vlan - connection up while up
    * Add "vlan" connection named "eth7.99" with options "autoconnect yes dev eth7 id 99 ip4 1.2.3.4/24"
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


    @vlan_connection_down
    Scenario: nmcli - vlan - connection down
    * "inet 10.42." is not visible with command "ifconfig"
    * Add "vlan" connection named "eth7.399" with options "autoconnect no dev eth7 id 399"
    * Open editor for connection "eth7.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Bring down connection "eth7.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan_connection_down_with_autoconnect
    Scenario: nmcli - vlan - connection down (autoconnect on)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add "vlan" connection named "eth7.399" with options "autoconnect no dev eth7 id 399"
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
    * Wait for "10" seconds
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan_change_id_with_no_interface_set
    Scenario: nmcli - vlan - change id without interface set
    * Cleanup connection "eth7.55"
    * Add "vlan" connection named "eth7.65" with options "autoconnect no dev eth7 id 65"
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


    @vlan_change_id
    Scenario: nmcli - vlan - change id
    * Cleanup device "eth7.265"
    * Cleanup connection "eth7.265"
    * Add "vlan" connection named "eth7.165" with options "autoconnect no dev eth7 id 165"
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


    @vlan_describe_all
    Scenario: nmcli - vlan - describe all
    * Open editor for a type "vlan"
    Then Check "parent|id|flags|ingress-priority-map|egress-priority-map" are present in describe output for object "vlan"


    @rhbz1244048
    @assertion_failure
    Scenario: nmcli - vlan - assertion failure
    * Add "vlan" connection named "eth7.99" for device "eth7.101" with options "autoconnect no dev eth7 id 99"
    * Open editor for connection "eth7.99"
    * Set a property named "vlan.flags" to "1" in editor
    * Save in editor
    * No error appeared in editor
    * Quit editor


    @vlan_describe_separately
    Scenario: nmcli - vlan - describe separately
    * Open editor for a type "vlan"
    Then Check "\[parent\]" are present in describe output for object "vlan.parent"
    Then Check "\[id\]" are present in describe output for object "vlan.id"
    Then Check "\[flags\]" are present in describe output for object "vlan.flags"
    Then Check "\[ingress-priority-map\]" are present in describe output for object "vlan.ingress-priority-map"
    Then Check "\[egress-priority-map\]" are present in describe output for object "vlan.egress-priority-map"


    @vlan_disconnect_device
    Scenario: nmcli - vlan - disconnect device
    * "inet 10.42." is not visible with command "ifconfig"
    * Add "vlan" connection named "eth7.399" with options "autoconnect no dev eth7 id 399"
    * Open editor for connection "eth7.399"
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "eth7.399"
    * "inet 10.42." is visible with command "ifconfig"
    * Disconnect device "eth7.399"
    Then "inet 10.42." is not visible with command "ifconfig"


    @vlan_disconnect_device_with_autoconnect
    Scenario: nmcli - vlan - disconnect device (with autoconnect)
    * "inet 10.42." is not visible with command "ifconfig"
    * Add "vlan" connection named "eth7.499" with options "autoconnect no dev eth7 id 499"
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


    @vlan_device_tagging
    Scenario: nmcli - vlan - device tagging
    * Execute "yum -y install wireshark"
    * Add "vlan" connection named "eth7.80" with options "dev eth7 id 80"
    * "eth7.80:" is visible with command "ifconfig" in "10" seconds
    * Run child "ping -I eth7.80 8.8.8.8"
    Then "ID: 80" is visible with command "tshark -i eth7 -T fields -e vlan" in "150" seconds
    Then Kill children


    @vlan_on_bridge
    Scenario: nmcli - vlan - on bridge
    * Add "bridge" connection named "vlan_bridge7" for device "bridge7" with options "stp no"
    * Add "vlan" connection named "vlan_bridge7.15" with options "dev bridge7 id 15"
    Then "bridge7.15:" is visible with command "ifconfig"


    @rhbz1586191
    @ver+=1.12.0
    @vlan_over_bridge_over_team_over_nic
    Scenario: nmcli - vlan - over brdge on team
    * Add "team" connection named "vlan_team7" for device "team7" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          mtu 9000
          config '{ "runner": {"name":"lacp", "fast_rate":true }}'
          """
    * Add "team-slave" connection named "vlan_team7.0" for device "eth7" with options "mtu 9000 master team7"
    * Add "vlan" connection named "vlan_bridge7.15" with options
          """
          dev team7
          id 15
          ipv4.method disabled
          ipv6.method ignore
          master bridge7
          connection.slave-type bridge
          """
    * Add "bridge" connection named "vlan_bridge7" for device "bridge7" with options
          """
          ipv4.method manual
          ipv6.method ignore
          ipv4.addresses '11.0.0.1/24'
          """
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
    @restart_if_needed @testeth7_disconnect
    @vlan_not_duplicated
    Scenario: nmcli - vlan - do not duplicate mtu and ipv4 vlan
    * Add "vlan" connection named "vlan" with options "dev eth7 id 80"
    * Modify connection "vlan" changing options "ethe.mtu 1450 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "testeth7"
    * Bring "up" connection "vlan"
    * Restart NM
    Then "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1376199
    @ver+=1.8.0
    @restart_if_needed @testeth7_disconnect
    @vlan_not_stalled_after_connection_delete
    Scenario: nmcli - vlan - delete vlan device after restart
    * Add "vlan" connection named "vlan" with options "dev eth7 id 80"
    * Modify connection "vlan" changing options "ethe.mtu 1450 ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Bring "up" connection "testeth7"
    * Bring "up" connection "vlan"
    * Restart NM
    When "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Delete connection "vlan"
    Then "eth7.80" is not visible with command "nmcli device" in "5" seconds


    @rhbz1264322
    @restart_if_needed
    @vlan_update_mac_from_bond
    Scenario: nmcli - vlan - update mac address from bond
    # Setup given in the bug description
    * Add "bridge" connection named "vlan_bridge7" for device "bridge7" with options "autoconnect no"
    * Modify connection "vlan_bridge7" changing options "bridge.stp no connection.autoconnect yes"
    * Modify connection "vlan_bridge7" changing options "ipv4.method manual ipv4.address '192.168.1.11/24' ipv4.gateway '192.168.1.1'"
    * Modify connection "vlan_bridge7" changing options "ipv4.dns 8.8.8.8 ipv4.dns-search boston.com"
    * Bring up connection "vlan_bridge7"
    * Add "bond" connection named "vlan_bond7" for device "bond7" with options "autoconnect no mode active-backup"
    * Modify connection "vlan_bond7" changing options "ipv4.method disabled ipv6.method ignore connection.autoconnect yes"
    * Bring up connection "vlan_bond7"
    * Add "bond-slave" connection named "vlan_bond7.7" for device "eth7" with options "master bond7"
    * Add "vlan" connection named "vlan_vlan7" for device "vlan7" with options "autoconnect no dev bond7 id 7"
    * Modify connection "vlan_vlan7" changing options "connection.master bridge7 connection.slave-type bridge connection.autoconnect yes"
    * Bring up connection "vlan_vlan7"
    # Check all is up
    * "connected:vlan_bond7.7" is visible with command "nmcli -t -f STATE,CONNECTION device" in "5" seconds
    # Delete bridge and bond outside NM, leaving the vlan device (with its mac set)
    * Stop NM
    * Execute "ip link del bond7"
    * Execute "ip link del bridge7"
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
    @del_test1112_veths
    @bring_up_very_long_device_name
    Scenario: nmcli - general - bring up very_long_device_name
    * Create "veth" device named "very_long_name" with options "peer name test11"
    * Add "ethernet" connection named "vlan1" for device "very_long_name" with options
          """
          -- ipv4.method manual
          ipv4.addresses '1.2.3.4/24'
          """
    * Bring "up" connection "vlan1"
    * Add "vlan" connection named "vlan" with options
          """
          dev very_long_name
          id 1024
          -- ipv4.method manual
          ipv4.addresses '1.2.3.55/24'
          """
    * Bring "up" connection "vlan"
    Then "very_long_name:connected:vlan1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "very_long_.1024:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 1.2.3.4\/24" is visible with command "ip a s very_long_name"
     And "inet 1.2.3.55\/24" is visible with command "ip a s very_long_.1024"


    @rhbz1312281 @rhbz1250225
    @ver+=1.4.0
    @ifcfg-rh
    @reorder_hdr
    Scenario: nmcli - vlan - reorder HDR
    * Add "vlan" connection named "vlan" for device "vlan" with options "dev eth7 id 80 ip4 1.2.3.4/32"
    When "REORDER_HDR" is visible with command "ip -d l show vlan"
     And "REORDER_HDR=yes" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
    * Modify connection "vlan" changing options "vlan.flags 0"
    * Bring "up" connection "vlan"
    Then "REORDER_HDR=no\s+VLAN_FLAGS=NO_REORDER_HDR" is visible with command "grep HDR /etc/sysconfig/network-scripts/ifcfg-vlan"
     And "REORDER_HDR" is not visible with command "ip -d l show vlan"


    @rhbz1363995
    @ver+=1.4 @ver-=1.24
    @vlan_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Cleanup device "vlan"
    * Execute "ip link add link eth7 name vlan type vlan id 80"
    * Execute "ip link set dev vlan up"
    * Execute "ip add add 30.0.0.1/24 dev vlan"
    When "vlan:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"
    * Execute "ip link set dev vlan down"
    Then "vlan:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"


    @rhbz1363995 @rhbz1816202
    @ver+=1.25
    @vlan_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Cleanup device "vlan"
    * Execute "ip link add link eth7 name vlan type vlan id 80"
    * Execute "ip link set dev vlan up"
    * Execute "ip add add 30.0.0.1/24 dev vlan"
    When "vlan:connected \(externally\):vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"
    * Execute "ip link set dev vlan down"
    Then "vlan:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s vlan"


    @rhbz1414186
    @ver+=1.6
    @restart_if_needed
    @vlan_mtu_from_parent
    Scenario: nmcli - vlan - MTU from parent
    * Add "ethernet" connection named "vlan1" for device "eth7" with options
          """
          802-3-ethernet.mtu 9000
          ipv4.method disabled
          ipv6.method ignore
          """
    * Bring "down" connection "vlan1"
    * Bring "up" connection "vlan1"
    * Add "vlan" connection named "vlan" for device "vlan" with options "dev eth7 id 80 ip4 1.2.3.4/32"
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
    @vlan_mtu_reapply
    Scenario: nmcli - vlan - MTU from parent
    * Add "ethernet" connection named "vlan1" for device "eth7" with options
          """
          802-3-ethernet.mtu 2000
          ipv4.method disabled
          ipv6.method ignore
          """
    * Bring "up" connection "vlan1"
    * Add "vlan" connection named "eth7.299" for device "eth7.299" with options
          """
          dev eth7
          id 299
          802-3-ethernet.mtu 2000
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          """
    * Add "vlan" connection named "eth7.399" for device "eth7.399" with options
          """
          dev eth7
          id 399
          802-3-ethernet.mtu 2000
          ipv4.method manual
          ipv4.addresses 1.2.3.5/24
          """
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


    @rhbz1779162
    @ver+=1.22.0
    @vlan_mtu_device_reapply
    Scenario: nmcli - vlan - MTU device reapply
    * Add "ethernet" connection named "vlan1" for device "eth7" with options
          """
          802-3-ethernet.mtu 2000
          ipv4.method disabled
          ipv6.method ignore
          """
    * Bring "up" connection "vlan1"
    * Add "vlan" connection named "eth7.299" for device "eth7.299" with options
          """
          dev eth7
          id 299
          802-3-ethernet.mtu 2000
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          """
    * Add "vlan" connection named "eth7.399" for device "eth7.399" with options
          """
          dev eth7
          id 399
          802-3-ethernet.mtu 2000
          ipv4.method manual
          ipv4.addresses 1.2.3.5/24
          """
    When "mtu 2000" is visible with command "ip a s eth7" in "10" seconds
    When "mtu 2000" is visible with command "ip a s eth7.299" in "10" seconds
    When "mtu 2000" is visible with command "ip a s eth7.399" in "10" seconds
    * Modify connection "eth7.399" changing options "ethe.mtu 1800"
    * Execute "nmcli device reapply eth7.399"
    Then "mtu 2000" is visible with command "ip a s eth7.299" in "10" seconds
    Then "mtu 2000" is visible with command "ip a s eth7" in "10" seconds
    Then "mtu 1800" is visible with command "ip a s eth7.399" in "10" seconds


    @rhbz1414901
    @ver+=1.10.0
    @restart_if_needed
    @vlan_mtu_from_parent_with_slow_dhcp
    Scenario: nmcli - vlan - MTU from parent
    * Prepare simulated test "test77" device
    * Add "ethernet" connection named "vlan1" for device "test77" with options
          """
          802-3-ethernet.mtu 9000
          ipv4.method auto
          ipv6.method auto
          """
    * Bring "down" connection "vlan1"
    * Bring "up" connection "vlan1"
    * Add "vlan" connection named "vlan2" for device "vlan" with options
          """
          802-3-ethernet.mtu 9000
          dev test77
          id 80
          ip4 1.2.3.4/32
          """
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
    @default_route_for_vlan_over_team
    Scenario: NM - vlan - default route for vlan over team
    * Add "team" connection named "vlan_team7" for device "team7"
    * Add "team-slave" connection named "vlan_team7.0" for device "eth7" with options "master team7"
    * Add "vlan" connection named "vlan_team7.1" with options
          """
          dev team7
          id 1
          mtu 1500
          ipv4.method manual
          ipv4.addresses 192.168.168.16/24
          ipv4.gateway 192.168.103.1
          ipv6.method manual
          ipv6.addresses 2168::16/64
          ipv4.dns 8.8.8.8
          """
    * Bring "up" connection "vlan_team7"
    * Bring "up" connection "vlan_team7.0"
    * Bring "up" connection "vlan_team7.1"
    When "Exactly" "1" lines with pattern "team7.1" are visible with command "ip r show default" in "2" seconds
    * Execute "for i in `seq 1 23`; do ip link set team7 addr 00:00:11:22:33:$i; done"
    Then "Exactly" "1" lines with pattern "team7.1" are visible with command "ip r show default" in "2" seconds


    @rhbz1553595
    @ver+=1.10.2 @ver-=1.17.90
    @restart_if_needed
    @vlan_on_bond_autoconnect
    Scenario: NM - vlan - autoconnect vlan on bond specified as UUID
    * Add "bond" connection named "bond0" for device "nm-bond"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show bond0"
    * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
    * Add slave connection for master "nm-bond" on device "eth4" named "bond0.1"
    * Add "vlan" connection named "vlan_bond7" with options "dev nm-bond id 7 ip4 192.168.168.16/24 autoconnect no"
    * Modify connection "vlan_bond7" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan_bond7 connection.autoconnect yes"
    * Reboot
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1553595 @rhbz1701585
    @ver+=1.18.0 @ver-=1.29
    @restart_if_needed
    @vlan_on_bond_autoconnect
    Scenario: NM - vlan - autoconnect vlan on bond specified as UUID
    * Add "bond" connection named "bond0" for device "nm-bond"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show bond0"
    * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
    * Add slave connection for master "nm-bond" on device "eth4" named "bond0.1"
    * Add "vlan" connection named "vlan_bond7" with options "dev nm-bond id 7 ip4 192.168.168.16/24 autoconnect no"
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


    @rhbz1553595 @rhbz1701585 @rhbz1937723
    @ver+=1.30.0
    @restart_if_needed
    @vlan_on_bond_autoconnect
    Scenario: NM - vlan - autoconnect vlan on bond specified as UUID
    * Add "bond" connection named "bond0" for device "nm-bond" with options "mtu 9000"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show bond0"
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options
          """
          master nm-bond
          connection.slave-type bond
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options
          """
          master nm-bond
          connection.slave-type bond
          """
    * Add "vlan" connection named "vlan_bond7" with options "dev nm-bond id 7 ip4 192.168.168.16/24 autoconnect no"
    * Modify connection "vlan_bond7" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan_bond7 connection.autoconnect yes"
    * Reboot
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond.7" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond" in "20" seconds
    Then "9000" is visible with command "ip a s eth1" in "20" seconds
    Then "9000" is visible with command "ip a s eth4" in "20" seconds
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond.7" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond" in "20" seconds
    Then "9000" is visible with command "ip a s eth1" in "20" seconds
    Then "9000" is visible with command "ip a s eth4" in "20" seconds
    * Execute "nmcli networking off"
    * Restart NM
    * Execute "nmcli networking on"
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "nm-bond.7:connected:vlan_bond7" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond.7" in "20" seconds
    Then "9000" is visible with command "ip a s nm-bond" in "20" seconds
    Then "9000" is visible with command "ip a s eth1" in "20" seconds
    Then "9000" is visible with command "ip a s eth4" in "20" seconds


    @rhbz1659063
    @ver+=1.14
    @static_route_persists_mac_change
    Scenario: NM - vlan - static route is not deleted after NM changes MAC
    * Prepare simulated test "test77" device
    * Add "bond" connection named "bond0" for device "nm-bond"
    #* Add "bond" connection for device "nm-bond" with options "autoconnect no ethernet.cloned-mac-address preserve"
    * Add "vlan" connection named "vlan_bond7" with options
          """
          autoconnect no
          ethernet.cloned-mac-address preserve
          ipv4.method disabled
          ipv6.method ignore
          vlan.id 7
          vlan.parent nm-bond
          """
    * Add "ethernet" connection named "bond0.0" for device "test77" with options
          """
          autoconnect no
          ethernet.cloned-mac-address preserve
          master nm-bond
          slave-type bond
          """
    * Bring "up" connection "bond0"
    * Bring "up" connection "vlan_bond7"
    * Execute "ip addr add 192.168.168.16/24 dev nm-bond.7"
    * Execute "ip route add 192.168.169.3/32 via 192.168.168.16 dev nm-bond.7"
    * Bring "up" connection "bond0.0"
    Then "192.168.169.3 via 192.168.168.16 dev nm-bond.7" is visible with command "ip r"


    @ver+=1.12
    @restart_if_needed
    @vlan_create_macvlan_on_vlan
    Scenario: nmcli - vlan - create macvlan on vlan
    * Add "vlan" connection named "eth7.99" with options "dev eth7 id 99"
    * Add "vlan" connection named "eth7.299" with options "dev eth7 id 299"
    * Add "macvlan" connection named "vlan1" for device "mvl1" with options "mode bridge macvlan.parent eth7.99"
    * Add "macvlan" connection named "vlan2" for device "mvl2" with options "mode bridge macvlan.parent eth7.99"
    * Add "macvlan" connection named "vlan" for device "mvl" with options "mode bridge macvlan.parent eth7.299"
    * Restart NM


    @rhbz1716438
    @ver+=1.18.3 @ver-=1.26
    @vlan_L2_UUID
    Scenario: NM - vlan - L2 only master via UUID
    * Add "ethernet" connection named "vlan1" for device "eth7" with options "ipv4.method disabled ipv6.method ignore"
    * Note the output of "nmcli --mode tabular -t -f connection.uuid connection show vlan1"
    * Add "vlan" connection named "vlan" for device "eth7.80" with options "dev eth7 id 80 ip4 192.168.1.2/24"
    * Modify connection "vlan" property "vlan.parent" to noted value
    * Execute "nmcli connection modify vlan connection.autoconnect yes"
    * Bring "up" connection "vlan"
    Then "eth7:connected:vlan1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "eth7.80:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1716438 @rhbz1818697
    @ver+=1.27
    @vlan_L2_UUID
    Scenario: NM - vlan - L2 only master via UUID
    * Add "ethernet" connection named "vlan1" for device "eth7" with options "ipv4.method disabled ipv6.method ignore"
    * Add "vlan" connection named "vlan" for device "eth7.80" with options
          """
          dev eth7
          id 80
          ipv4.dhcp-timeout 5
          vlan.parent $(nmcli --mode tabular -t -f connection.uuid connection show vlan1)
          ipv6.method ignore
          """
    * Bring "up" connection "vlan1"
    Then "eth7:connected:vlan1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "\(connect" is visible with command "nmcli device show eth7.80" in "10" seconds
    * Wait for "10" seconds
    Then "\(connect" is visible with command "nmcli device show eth7.80" in "10" seconds


    @rhbz1765047
    @ver+=1.22.8
    @vlan_no_autoconnect_after_modify
    Scenario: nmcli - vlan - no autoconnect after modify
    * Add "vlan" connection named "vlan" with options "dev eth7 id 80 ip4 192.168.1.2/24 autoconnect yes"
    Then "eth7.80" is visible with command "ip l" in "5" seconds
    And "vlan" is visible with command "nmcli -t -f name con show --active" in "5" seconds
    * Bring "down" connection "vlan"
    Then "eth7.80" is not visible with command "ip l"
    And "vlan" is not visible with command "nmcli -t -f name con show --active"
    * Modify connection "vlan" changing options "+ipv4.address 192.168.1.3/24"
    Then "eth7.80" is not visible with command "ip l" for full "5" seconds
    And "vlan" is not visible with command "nmcli -t -f name con show --active"


    @rhbz1066705
    @vxlan_interface_recognition
    Scenario: NM - vxlan - interface support
    * Create "vxlan" device named "dummy0" with options "id 42 group 239.1.1.1 dev eth7"
    When "unmanaged" is visible with command "nmcli device show dummy0" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add fd00::666/8 dev dummy0"
    Then "connected" is visible with command "nmcli device show dummy0" in "10" seconds
    Then vxlan device "dummy0" check for parent "eth7"


    #@rhbz1768388
    #@ver+=1.22
    #@vxlan_dbus_shows_port_numbers
    #Scenario: NM - vxlan - dbus shows port numbers
    #* Add "vxlan" connection named "vlan1" for device "vlan1" with options
    #   """
    #   vxlan.destination-port 70
    #   vxlan.source-port-max 50
    #   vxlan.source-port-min 30
    #   id 70
    #   dev eth7
    #   ip4 1.2.3.4/24
    #   remote 1.2.3.1
    #   """
    #* Execute "nmcli con up vlan1"
    #Then vxlan device "vlan1" check for ports "70, 30, 50"


    @rhbz1768388
    @ver+=1.22
    @vxlan_libnm_shows_port_numbers
    Scenario: NM - vxlan - libnm shows port numbers
    * Add "vxlan" connection named "vlan1" for device "vlan1" with options
          """
          vxlan.destination-port 70
          vxlan.source-port-max 50
          vxlan.source-port-min 30
          id 70
          dev eth7
          ip4 1.2.3.4/24
          remote 1.2.3.1
          """
    * Execute "nmcli con up vlan1"
    Then "70" is visible with command "/usr/bin/python contrib/gi/nmclient_get_connection_property.py vlan1 destination-port"
    Then "30" is visible with command "/usr/bin/python contrib/gi/nmclient_get_connection_property.py vlan1 source-port-min"
    Then "50" is visible with command "/usr/bin/python contrib/gi/nmclient_get_connection_property.py vlan1 source-port-max"
    Then "70" is visible with command "/usr/bin/python contrib/gi/nmclient_get_device_property.py vlan1 get_dst_port"
    Then "30" is visible with command "/usr/bin/python contrib/gi/nmclient_get_device_property.py vlan1 get_src_port_min"
    Then "50" is visible with command "/usr/bin/python contrib/gi/nmclient_get_device_property.py vlan1 get_src_port_max"


    @rhbz1774074
    @ver+=1.22
    @vxlan_do_not_up_if_no_master
    Scenario: NM - vxlan - do not up when no master
    * Add "vxlan" connection named "vlan1" for device "vlan1" with options
          """
          vxlan.parent not-exists
          id 70
          remote 172.25.1.1
          """
    Then "--" is visible with command "nmcli connection  |grep vlan1" for full "2" seconds


    @rhbz1933041 @rhbz1926599 @rhbz1231526
    @ver+=1.30 @rhelver+=8
    @logging_info_only @many_vlans @restart_if_needed
    @vlan_create_many_vlans
    Scenario: NM - vlan - create 500 (x86_64) or 200 (aarch64, s390x...) vlans
    # Prepare veth pair with the other end in namespace
    # Create 500 (from 10 to 510) vlans on top of eth11p
    # Run dnsmasq inside the namespace to server incoming connections
    * Execute "sh prepare/vlans.sh setup $N_VLANS"
    # Create 501 profiles which should be autoconnected after a while
    * Execute "for i in $(seq 10 $((N_VLANS + 10))); do nmcli con add type vlan con-name eth11.$i id $i dev eth11 ipv4.may-fail no ipv6.method disable; done"
   # Wait till we have "all" addresses assigned
    * Note the output of "echo $((N_VLANS + 1))"
    Then Noted number of lines with pattern "eth11.* connected" is visible with command "nmcli device" in "500" seconds
    # Simulate reboot and delete all devices
    * Stop NM
    * Execute "for i in $(seq 10 $((N_VLANS + 10))); do ip link del eth11.$i; done"
    * Reboot
    # Wait till we have "all" addresses assigned again
    Then Noted number of lines with pattern "eth11.* connected" is visible with command "nmcli device" in "500" seconds
    # Then Execute "nmcli  device |grep eth11 > /tmp/eth11s"


    @ver+=1.32 @rhelver+=8 @skip_in_kvm @skip_in_centos
    @logging_info_only @remove_vlan_range
    @vlan_create_1000_bridges_over_1000_vlans
    Scenario: NM - vlan - create 1000 bridges over 1000 VLANs
    * Add bridges over VLANs in range from "1" to "1000" on interface "eth7" via libnm
    # Let's give libnm some time to settle all 1000 devices, we can fail if just 1
    Then "Exactly" "1000" lines with pattern "vlan" are visible with command "nmcli -w 60 c" in "4" seconds
    Then "Exactly" "1000" lines with pattern "bridge" are visible with command "nmcli -w 60 c" in "1" seconds
    Then "Exactly" "1000" lines with pattern ": br[0-9]" are visible with command "ip l" in "1" seconds
    Then "Exactly" "1000" lines with pattern ": eth7\.[0-9]" are visible with command "ip l" in "1" seconds


    @rhbz1907960
    @ver+=1.31
    @vlan_ifname_vlan0_with_id_7
    Scenario: NM - vlan - use ID 7 with ifname vlan0
    * Add "vlan" connection named "vlan" for device "vlan0" with options
          """
          vlan.id 7
          dev eth7
          ipv4.method disable
          ipv6.method ignore
          """
    Then "7" is visible with command "nmcli -g vlan.id con show id vlan"
    Then " 802.1Q id 7 " is visible with command "ip -d link show dev vlan0"


    @rhbz1942331
    @ver+=1.31
    @vlan_accept_all_mac_addresses
    Scenario: nmcli - vlan - accept-all-mac-addresses (promisc mode)
    * Add "vlan" connection named "vlan" for device "eth7.80" with options
          """
          id 80 dev eth7
          autoconnect no
          ipv4.method disable ipv6.method disable
          """
    * Bring "up" connection "vlan"
    Then "PROMISC" is not visible with command "ip link show dev eth7.80"
    * Modify connection "vlan" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "vlan"
    Then "PROMISC" is visible with command "ip link show dev eth7.80"
    * Modify connection "vlan" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "vlan"
    Then "PROMISC" is not visible with command "ip link show dev eth7.80"


    @rhbz1942331
    @ver+=1.31
    @vlan_accept_all_mac_addresses_external_device
    Scenario: nmcli - vlan - accept-all-mac-addresses (promisc mode)
    # promisc off -> default
    * Execute "ip link add link eth7 name eth7.80 type vlan id 80 && ip link set dev eth7.80 promisc off"
    When "PROMISC" is not visible with command "ip link show dev eth7.80"
    * Add "vlan" connection named "vlan" for device "eth7.80" with options
          """
          id 80 dev eth7
          autoconnect no
          ipv4.method disable ipv6.method disable
          802-3-ethernet.accept-all-mac-addresses default
          """
    * Bring "up" connection "vlan"
    Then "PROMISC" is not visible with command "ip link show dev eth7.80"
    * Bring "down" connection "vlan"
    # promisc on -> default
    * Execute "ip link set dev eth7.80 promisc on"
    When "PROMISC" is visible with command "ip link show dev eth7.80"
    * Bring "up" connection "vlan"
    Then "PROMISC" is visible with command "ip link show dev eth7.80"
    * Bring "down" connection "vlan"
    # promisc off -> true
    * Execute "ip link set dev eth7.80 promisc off"
    When "PROMISC" is not visible with command "ip link show dev eth7.80"
    * Modify connection "vlan" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "vlan"
    Then "PROMISC" is visible with command "ip link show dev eth7.80"
    * Bring "down" connection "vlan"
    # promisc on -> false
    * Execute "ip link set dev eth7.80 promisc on"
    When "PROMISC" is visible with command "ip link show dev eth7.80"
    * Modify connection "vlan" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "vlan"
    Then "PROMISC" is not visible with command "ip link show dev eth7.80"
