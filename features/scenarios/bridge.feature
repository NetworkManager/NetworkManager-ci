Feature: nmcli - bridge

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver-=1.24
    @bridge_options
    Scenario: nmcli - bridge - add custom bridge
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          autoconnect no
          priority 5
          forward-delay 3
          hello-time 3
          max-age 15
          ageing-time 500000
          """
    * Bring "up" connection "br88" ignoring error
    Then "br88" is visible with command "ip link show type bridge"
    Then "DELAY=3.*BRIDGING_OPTS=\"priority=5 hello_time=3 max_age=15 ageing_time=500000\".*NAME=br88.*ONBOOT=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-br88"


    @ver+=1.25 @ver-=1.35.0
    @rhelver+=8
    @bridge_options
    Scenario: nmcli - bridge - add custom bridge
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          ageing-time 10
          forward-delay 5
          bridge.group-address 01:80:C2:00:00:04
          group-forward-mask 8
          hello-time 3
          bridge.mac-address 02:02:02:02:02:02
          max-age 15
          bridge.multicast-hash-max 4
          bridge.multicast-last-member-count 2
          bridge.multicast-last-member-interval 2
          bridge.multicast-membership-interval 2
          bridge.multicast-querier yes
          bridge.multicast-querier-interval 3
          bridge.multicast-query-interval 200
          bridge.multicast-query-response-interval 3
          bridge.multicast-query-use-ifaddr yes
          bridge.multicast-router enable
          bridge.multicast-snooping true
          bridge.multicast-startup-query-count 2
          bridge.multicast-startup-query-interval 500
          ip4 192.0.2.1/24
          bridge.vlan-filtering 1
          bridge.vlan-protocol 802.1ad
          bridge.vlan-stats-enabled 1
          """
    * Bring "up" connection "br88" ignoring error
    Then "br88" is visible with command "ip link show type bridge"
    Then "1000" is visible with command "cat /sys/class/net/br88/bridge/ageing_time"
    Then "500" is visible with command "cat /sys/class/net/br88/bridge/forward_delay"
    Then "01:80:c2:00:00:04" is visible with command "cat /sys/class/net/br88/bridge/group_addr"
    Then "0x8" is visible with command "cat /sys/class/net/br88/bridge/group_fwd_mask"
    Then "300" is visible with command "cat /sys/class/net/br88/bridge/hello_time"
    Then "1500" is visible with command "cat /sys/class/net/br88/bridge/max_age"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_last_member_count"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_last_member_interval"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_membership_interval"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_querier"
    Then "3" is visible with command "cat /sys/class/net/br88/bridge/multicast_querier_interval"
    Then "200" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_interval"
    Then "3" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_response_interval"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_use_ifaddr"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_router"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_snooping"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_startup_query_count"
    Then "500" is visible with command "cat /sys/class/net/br88/bridge/multicast_startup_query_interval"
    Then "802.1ad" is visible with command "ip -d link show br88"
    Then "vlan_stats_enabled 1" is visible with command "ip -d link show br88"


    @rhbz1871950
    @ver+=1.35
    @rhelver+=8
    @bridge_options
    Scenario: nmcli - bridge - add custom bridge
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          ageing-time 10
          forward-delay 5
          bridge.group-address 01:80:C2:00:00:04
          group-forward-mask 8
          hello-time 3
          bridge.mac-address 02:02:02:02:02:02
          max-age 15
          bridge.multicast-hash-max 4
          bridge.multicast-last-member-count 2
          bridge.multicast-last-member-interval 2
          bridge.multicast-membership-interval 2
          bridge.multicast-querier yes
          bridge.multicast-querier-interval 3
          bridge.multicast-query-interval 200
          bridge.multicast-query-response-interval 3
          bridge.multicast-query-use-ifaddr yes
          bridge.multicast-router enable
          bridge.multicast-snooping true
          bridge.multicast-startup-query-count 2
          bridge.multicast-startup-query-interval 500
          ip4 192.0.2.1/24
          bridge.vlan-filtering 1
          bridge.vlan-protocol 802.1ad
          bridge.vlan-stats-enabled 1
          """
    * Bring "up" connection "br88" ignoring error
    Then "br88" is visible with command "ip link show type bridge"
    Then "1000" is visible with command "cat /sys/class/net/br88/bridge/ageing_time"
    Then "500" is visible with command "cat /sys/class/net/br88/bridge/forward_delay"
    Then "01:80:c2:00:00:04" is visible with command "cat /sys/class/net/br88/bridge/group_addr"
    Then "0x8" is visible with command "cat /sys/class/net/br88/bridge/group_fwd_mask"
    Then "300" is visible with command "cat /sys/class/net/br88/bridge/hello_time"
    Then "1500" is visible with command "cat /sys/class/net/br88/bridge/max_age"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_last_member_count"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_last_member_interval"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_membership_interval"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_querier"
    Then "3" is visible with command "cat /sys/class/net/br88/bridge/multicast_querier_interval"
    Then "200" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_interval"
    Then "3" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_response_interval"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_query_use_ifaddr"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_router"
    Then "1" is visible with command "cat /sys/class/net/br88/bridge/multicast_snooping"
    Then "2" is visible with command "cat /sys/class/net/br88/bridge/multicast_startup_query_count"
    Then "500" is visible with command "cat /sys/class/net/br88/bridge/multicast_startup_query_interval"
    Then "802.1ad" is visible with command "ip -d link show br88"
    Then "vlan_stats_enabled 1" is visible with command "ip -d link show br88"
    * Modify connection "br88" changing options "bridge.ageing-time 0"
    * Bring "up" connection "br88" ignoring error
    Then "^0" is visible with command "cat /sys/class/net/br88/bridge/ageing_time"


    @rhbz1358615
    #obsoleted by bridge_options test
    @ver+=1.10.2 @ver-=1.24
    @bridge_add_forward_delay
    Scenario: nmcli - bridge - add forward delay
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          autoconnect no
          priority 5
          group-forward-mask 8
          ip4 1.2.3.4/24
          """
    * Bring "up" connection "br88"
    Then "br88" is visible with command "ip link show type bridge"
    And "BRIDGING_OPTS=\"priority=5 group_fwd_mask=8\"" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-br88"
    And "0x8" is visible with command "cat /sys/class/net/br88/bridge/group_fwd_mask"


    @rhbz1358615
    @ver+=1.10.2
    @bridge_modify_forward_delay
    Scenario: nmcli - bridge - modify forward delay
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          autoconnect no
          priority 5
          group-forward-mask 8
          ip4 1.2.3.4/24
          """
    * Execute "nmcli con modify br88 bridge.group-forward-mask 0"
    * Bring "up" connection "br88"
    And "group_fwd_mask=8" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-br88"
    And "0x0" is visible with command "cat /sys/class/net/br88/bridge/group_fwd_mask"


    @bridge_connection_up
    Scenario: nmcli - bridge - up
    * Add "bridge" connection named "br11" for device "br11" with options "autoconnect no bridge.stp no"
    * "br11" is not visible with command "ip link show type bridge"
    * Bring "up" connection "br11" ignoring error
    Then "br11" is visible with command "ip link show type bridge"


    @bridge_connection_down
    Scenario: nmcli - bridge - down
    * Add "bridge" connection named "br11" for device "br11" with options
          """
          autoconnect no
          bridge.stp off
          ip4 192.168.1.15/24
          """
    * Bring "up" connection "br11" ignoring error
    * "br11" is visible with command "ip link show type bridge"
    * "inet 192.168.1.15" is visible with command "ip a s br11"
    * Bring "down" connection "br11"
    * "inet 192.168.1.15" is not visible with command "ip a s br11"


    @bridge_disconnect_device
    Scenario: nmcli - bridge - disconnect device
    * Add "bridge" connection named "br11" for device "br11" with options
          """
          bridge.stp off
          autoconnect no
          ip4 192.168.1.10/24
          """
    * Bring "up" connection "br11" ignoring error
    * "br11" is visible with command "ip link show type bridge"
    * "inet 192.168.1.10" is visible with command "ip a s br11"
    * Disconnect device "br11"
    * "inet 192.168.1.10" is not visible with command "ip a s br11"


    @bridge_describe_all
    Scenario: nmcli - bridge - describe all
    * Open editor for a type "bridge"
    Then Check "mac-address|stp|priority|forward-delay|hello-time|max-age|ageing-time" are present in describe output for object "bridge"


    @bridge_describe_separately
    Scenario: nmcli - bridge - describe separately
    * Open editor for a type "bridge"
    Then Check "\[mac-address\]" are present in describe output for object "bridge.mac-address"
    Then Check "\[stp\]" are present in describe output for object "bridge.stp"
    Then Check "\[priority\]" are present in describe output for object "bridge.priority"
    Then Check "\[forward-delay\]" are present in describe output for object "bridge.forward-delay"
    Then Check "\[hello-time\]" are present in describe output for object "bridge.hello-time"
    Then Check "\[max-age\]" are present in describe output for object "bridge.max-age"
    Then Check "\[ageing-time\]" are present in describe output for object "bridge.ageing-time"


    @bridge_delete_connection
    Scenario: nmcli - bridge - delete connection
    * Add "bridge" connection named "br11" for device "br11" with options "bridge.stp off"
    * Bring "up" connection "br11" ignoring error
    * Delete connection "br11"
    Then ifcfg-"br11" file does not exist


    @bridge_delete_connection_while_up
    Scenario: nmcli - bridge - delete connection while up
    * Add "bridge" connection named "br12" for device "br12" with options
          """
          bridge.stp off
          autoconnect no
          ip4 192.168.1.19/24
          """
    * Bring "up" connection "br12" ignoring error
    * "inet 192.168.1.19" is visible with command "ip a s br12"
    * Delete connection "br12"
    Then "inet 192.168.1.19" is not visible with command "ip a s br12"
    Then ifcfg-"br12" file does not exist


    #obsoleted by bridge_options test
    @ver-=1.24
    @bridge_set_mac
    Scenario: nmcli - bridge - set mac address
    * Add "bridge" connection named "br12" for device "br12" with options "bridge.stp off autoconnect no"
    * Open editor for connection "br12"
    * Set a property named "bridge.mac-address" to "f0:de:aa:fb:bb:cc" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "br12" ignoring error
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip a s br12"


    @rhbz1386872 @rhbz1516659
    @ver+=1.8.0
    @bridge_set_mac_var1
    Scenario: nmcli - bridge - set mac address via two properties
    * Add "bridge" connection named "br12" for device "br12" with options
          """
          autoconnect no
          bridge.stp off
          ethernet.cloned-mac-address 02:02:02:02:02:02
          """
    * Open editor for connection "br12"
    * Set a property named "bridge.mac-address" to "f0:de:aa:fb:bb:cc" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "br12" ignoring error
    Then "ether 02:02:02:02:02:02" is visible with command "ip a s br12"


    @rhbz1386872
    @ver+=1.8.0 @ver-=1.24
    #obsoleted by bridge_options test
    @bridge_set_mac_var2
    Scenario: nmcli - bridge - set mac address via ethernet only
    * Add "bridge" connection named "br12" for device "br12" with options
          """
          autoconnect no
          bridge.stp off
          ethernet.cloned-mac-address 02:02:02:02:02:02
          """
    * Bring "up" connection "br12" ignoring error
    Then "ether 02:02:02:02:02:02" is visible with command "ip a s br12"


    @rhbz2124443
    @ver+=1.41.3
    @ver/rhel/8+=1.40.0.2
    @bridge_new_lower_mac_port_unchanged_ip_addresses_v4
    Scenario: nmcli - bridge - mac and IP addresses are kept after attaching of port with lower MAC
    * Add "bridge" connection named "brX" for device "brX" with options
          """
          bridge.stp off
          ipv4.may-fail no
          ipv6.method disabled
          """
    * Add "ethernet" connection named "testX" for device "testX"
    * Note the value of property "connection.uuid" of connection "brX"
    * Modify connection "testX" property "master" to noted value
    * Bring "up" connection "brX"
    * Prepare simulated test "testX" device with "30" leasetime
    * "(connected)" is visible with command "nmcli device show brX" in "10" seconds
    * Execute "ip a"
    * Note the output of "ip a show brX | grep ' inet ' | sed -e 's/^.*inet \([^ ]\+\) .*$/\1/'"
    * Create "veth" device named "veth0p" with options "peer name veth0 address 00:00:00:00:00:01"
    When Execute "ip link set veth0 master brX"
    * Wait for "10" seconds
    Then Noted value is visible with command "ip -4 a show brX"


    @rhbz2124443
    @ver+=1.41.3
    @ver/rhel/8+=1.40.0.2
    @bridge_new_lower_mac_port_unchanged_ip_addresses_v6
    Scenario: nmcli - bridge - mac and IP addresses are kept after attaching of port with lower MAC
    * Add "bridge" connection named "brX" for device "brX" with options
          """
          bridge.stp off
          ipv4.method disabled
          ipv6.may-fail no ipv6.dhcp-duid llt
          """
    * Add "ethernet" connection named "testX" for device "testX"
    * Note the value of property "connection.uuid" of connection "brX"
    * Modify connection "testX" property "master" to noted value
    * Bring "up" connection "brX"
    * Prepare simulated test "testX" device with "30" leasetime
    * "(connected)" is visible with command "nmcli device show brX" in "10" seconds
    * Execute "ip a"
    * Note the output of "ip a show brX scope global | grep ' inet6 ' | head -n1 | sed -e 's/^.*inet6 \([^ ]\+\) .*$/\1/'" as value "ipv6_1"
    * Note the output of "ip a show brX scope global | grep ' inet6 ' | tail -n1 | sed -e 's/^.*inet6 \([^ ]\+\) .*$/\1/'" as value "ipv6_2"
    * Create "veth" device named "veth0p" with options "peer name veth0 address 00:00:00:00:00:01"
    When Execute "ip link set veth0 master brX"
    # v6 "lease" is 120 s despite shorter setting
    * Wait for "140" seconds
    Then Noted value "ipv6_1" is visible with command "ip -6 a show dev brX scope global"
    Then Noted value "ipv6_2" is visible with command "ip -6 a show dev brX scope global"


    @ifcfg-rh
    @bridge_add_slave
    Scenario: nmcli - bridge - add slave
    #* Execute "nmcli dev con eth4"
    * Cleanup connection "bridge-slave-eth4.80"
    * Add "bridge" connection named "br15" for device "br15" with options "autoconnect no bridge.stp off"
    * Check ifcfg-name file created for connection "br15"
    * Add "vlan" connection named "eth4.80" with options "dev eth4 id 80"
    * Check ifcfg-name file created for connection "eth4.80"
    * Add "bridge-slave" connection with options "ifname eth4.80 autoconnect no master br15"
    Then "BRIDGE=br15" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth4.80"


    @ifcfg-rh
    @bridge_remove_slave
    Scenario: nmcli - bridge - remove slave
    #* Execute "nmcli dev con eth4"
    * Add "bridge" connection named "br15" for device "br15" with options "autoconnect no bridge.stp off"
    * Check ifcfg-name file created for connection "br15"
    * Add "vlan" connection named "eth4.80" with options "dev eth4 id 80"
    * Check ifcfg-name file created for connection "eth4.80"
    * Add "bridge-slave" connection named "br15-slave" for device "eth4.80" with options "autoconnect no master br15"
    * Check ifcfg-name file created for connection "br15-slave"
    * Delete connection "br15-slave"
    Then ifcfg-"br15-slave" file does not exist


    @ifcfg-rh
    @bridge_up_with_slaves
    Scenario: nmcli - bridge - up with slaves
    * Add "bridge" connection named "br15" for device "br15" with options "bridge.stp on ip4 192.168.1.19/24"
    * Add "vlan" connection named "eth4.80" with options "dev eth4 id 80"
    * Check ifcfg-name file created for connection "eth4.80"
    * Add "vlan" connection named "eth4.90" with options "dev eth4 id 90"
    * Check ifcfg-name file created for connection "eth4.90"
    * Add "bridge-slave" connection named "br15-slave1" for device "eth4.80" with options "master br15"
    * Check ifcfg-name file created for connection "br15-slave1"
    * Add "bridge-slave" connection named "br15-slave2" for device "eth4.90" with options "master br15"
    * Check ifcfg-name file created for connection "br15-slave2"
    * Bring "up" connection "br15"
    Then  "br15" is visible with command "ip link show type bridge"


    @bridge_up_slave
    Scenario: nmcli - bridge - up slave
    * Add "bridge" connection named "br10" for device "br10" with options "bridge.stp off ip4 192.168.1.19/24"
    * Add "bridge-slave" connection named "br10-slave" for device "eth4" with options "autoconnect no master br10"
    * Bring "up" connection "br10-slave"
    Then  "eth4.*master br10" is visible with command "ip link show type bridge_slave"
    Then Disconnect device "br10"
    Then  "eth4.*master br10" is not visible with command "ip link show type bridge_slave"


    @rhbz1158529
    @bridge_slaves_start_via_master
    Scenario: nmcli - bridge - start slave via master
    * Cleanup connection "bridge-slave-eth4"
    * Cleanup device "eth4"
    * Add "bridge" connection named "br10" for device "br10" with options "bridge.stp off"
    * Add "bridge-slave" connection with options "ifname eth4 autoconnect no master br10"
    * Open editor for connection "br10"
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.19/24" in editor
    * Set a property named "connection.autoconnect-slaves" to "1" in editor
    * Save in editor
    * Quit editor
    Then Disconnect device "br10"
    * Bring "up" connection "br10"
    Then  "eth4.*master br10" is visible with command "ip link show type bridge_slave"
    Then Disconnect device "br10"


    @rhbz1437598
    @ver+=1.10.0
    @bridge_autoconnect_slaves_when_master_reconnected
    Scenario: nmcli - bridge - start slave upon master reconnection
    * Add "bridge" connection named "br10" for device "br10" with options "bridge.stp on"
    * Add "bridge-slave" connection named "br10-slave" for device "eth4" with options "master br10"
    * Open editor for connection "br10"
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.19/24" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "br10"
    When "(connected)" is visible with command "nmcli device show br10" in "10" seconds
    * Disconnect device "br10"
    When "disconnected" is visible with command "nmcli device show eth4" in "5" seconds
     And "(connected)" is not visible with command "nmcli device show br10" in "5" seconds
    * Bring "up" connection "br10"
     And "(connected)" is visible with command "nmcli device show eth4" in "5" seconds
     And "(connected)" is visible with command "nmcli device show br10" in "5" seconds


    @eth4_disconnect
    @bridge_dhcp_config_with_ethernet_port
    Scenario: nmcli - bridge - dhcp config with ethernet port
    * Add "bridge" connection named "bridge0" for device "bridge0" with options "bridge.stp off"
    * Add "bridge-slave" connection named "bridge-slave-eth4" for device "eth4" with options "master bridge0"
    * Bring "up" connection "bridge-slave-eth4"
    Then "eth4.*master bridge0" is visible with command "ip link show type bridge_slave" in "10" seconds
    Then "bridge0:.*192.168.*inet6" is visible with command "ip a" in "30" seconds



    @eth4_disconnect
    @bridge_dhcp_config_with_multiple_ethernet_ports
    Scenario: nmcli - bridge - dhcp config with multiple ethernet ports
    * Prepare simulated test "test44" device
    * Add "bridge" connection named "bridge4" for device "br4" with options "bridge.stp on"
    * Add "bridge-slave" connection named "bridge4.0" for device "eth4" with options "master br4"
    * Bring "up" connection "bridge4.0"
    * Add "bridge-slave" connection named "bridge4.1" for device "test44" with options "master br4"
    * Bring "up" connection "bridge4.1"
    Then "eth4.*master br4" is visible with command "ip a" in "10" seconds
    Then "test44.*master br4" is visible with command "ip a"
    Then "br4:.*192.168.*inet6" is visible with command "ip a" in "60" seconds


    @eth4_disconnect
    @bridge_static_config_with_multiple_ethernet_ports
    Scenario: nmcli - bridge - dhcp config with multiple ethernet ports
    * Prepare simulated test "test44" device
    * Add "bridge" connection named "bridge4" for device "br4" with options
          """
          autoconnect no
          bridge.stp on
          ip4 192.168.1.19/24
          """
    * Add "bridge-slave" connection named "bridge4.0" for device "eth4" with options "master br4"
    * Bring "up" connection "bridge4.0"
    * Add "bridge-slave" connection named "bridge4.1" for device "test44" with options "master br4"
    * Bring "up" connection "bridge4.1"
    Then "eth4.*master br4" is visible with command "ip a" in "10" seconds
    Then "test44.*master br4" is visible with command "ip a"
    Then "br4:.*192.168.1.19" is visible with command "ip a" in "30" seconds


    @rhbz1548265
    @ver+=1.10.2
    @bridge_autoconnect_slaves_all
    Scenario: nmcli - bridge - autoconnect-slaves connects also otherwise busy devices
    # if the master is autoconnect-slaves, then it will forcefully activate all slaves,
    # even if the device is currently busy with another (non-slave) profile.
    * Add "ethernet" connection named "bridge-nonslave-eth4" for device "eth4" with options "autoconnect no"
    * Add "bridge" connection named "bridge4" for device "br15" with options
          """
          autoconnect no
          connection.autoconnect-slaves yes
          bridge.stp yes
          bridge.forward-delay 2
          """
    * Add "bridge-slave" connection named "bridge-slave-eth4" for device "eth4" with options
          """
          master br15
          autoconnect no
          """
    * Bring "up" connection "bridge-nonslave-eth4"
    When "eth4\s+ethernet\s+connected\s+bridge-nonslave-eth4" is visible with command "nmcli d"
     And "br15" is not visible with command "nmcli d"
     And "br15" is not visible with command "ip l"
    * Bring "up" connection "bridge4"
    Then "br15\s+bridge\s+connected\s+bridge4" is visible with command "nmcli d" in "40" seconds
     And "eth4\s+ethernet\s+connected\s+bridge-slave-eth4" is visible with command "nmcli d"


    @rhbz1548265
    @ver+=1.10.2
    @bridge_autoconnect_slaves_all_modified
    Scenario: nmcli - bridge - autoconnect-slaves connects also otherwise busy devices
    # if the master is autoconnect-slaves, then it will forcefully activate all slaves,
    # even if the device is currently busy with another (non-slave) profile.
    # This case is slightly different, because the currently active profile
    # is the slave profile itself, but it was activated as a non-slave profile.
    * Add "ethernet" connection named "bridge-nonslave-eth4" for device "eth4" with options "autoconnect no"
    * Bring "up" connection "bridge-nonslave-eth4"
    When "eth4\s+ethernet\s+connected\s+bridge-nonslave-eth4" is visible with command "nmcli d"
    * Execute "nmcli con modify bridge-nonslave-eth4 master br15 slave-type bridge"
    * Add "bridge" connection named "bridge4" for device "br15" with options
          """
          autoconnect yes
          connection.autoconnect-slaves yes
          bridge.stp yes
          bridge.forward-delay 2
          """
    Then "br15\s+bridge\s+connected\s+bridge4" is visible with command "nmcli d" in "40" seconds
     And "eth4\s+ethernet\s+connected\s+bridge-nonslave-eth4" is visible with command "nmcli d"
     And "eth4.*master br15" is visible with command "ip a s eth4"


    @need_config_server
    @bridge_server_ingore_carrier_with_dhcp
    Scenario: nmcli - bridge - server ingore carrier with_dhcp
    * Add "bridge" connection named "bridge4" for device "br4" with options "bridge.stp off"
    * Add "bridge-slave" connection named "bridge-slave-eth4" for device "eth4" with options "master br4"
    * Bring "up" connection "bridge-slave-eth4"
    Then "eth4.*master br4" is visible with command "ip a s eth4" in "40" seconds
    Then "br4:.*192.168" is visible with command "ip a s br4" in "45" seconds


    @ver+=1.25 @ver-=1.27
    @rhelver+=8
    @rhbz1030947 @rhbz1816202
    @bridge_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bridge - reflect changes from outside of NM
    * Create "bridge" device named "br0"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev br0 up"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Create "dummy" device named "dummy0"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add 1.1.1.1/24 dev br0"
    When "br0\s+bridge\s+connected \(externally\)\s+br0" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dummy0 master br0"
    When "dummy0\s+dummy\s+connected \(externally\)\s+dummy" is visible with command "nmcli d" in "5" seconds
    Then "BRIDGE.SLAVES:\s+dummy0" is visible with command "nmcli -f bridge.slaves dev show br0"


    @ver+=1.28
    @rhbz1030947 @rhbz1816202 @rhbz1869079
    @rhelver+=8
    @bridge_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bridge - reflect changes from outside of NM
    * Create "bridge" device named "br0"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev br0 up"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link add dummy0 type dummy"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add 1.1.1.1/24 dev br0"
    When "br0\s+bridge\s+connected \(externally\)\s+br0" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dummy0 master br0"
    When "dummy0\s+dummy\s+connected \(externally\)\s+dummy" is visible with command "nmcli d" in "5" seconds
    When "BRIDGE.SLAVES:\s+dummy0" is visible with command "nmcli -f bridge.slaves dev show br0"
    * Add "dummy" connection named "dummy1" for device "dummy0" with options
          """
          ipv4.method disabled
          ipv6.method disabled
          """
    * Bring "up" connection "dummy1"
    Then "dummy0\s+dummy\s+connected\s+dummy1" is visible with command "nmcli d" in "5" seconds
    Then "BRIDGE.SLAVES:\s+dummy0" is not visible with command "nmcli -f bridge.slaves dev show br0" in "5" seconds
    Then "master" is not visible with command "ip a s dummy0"


    @restart_if_needed
    @bridge_assumed_connection_race
    Scenario: NM - bridge - no crash when bridge started and shutdown immediately
    * Create 300 bridges and delete them
    Then "active" is visible with command "systemctl is-active NetworkManager.service"


    @not_on_aarch64 @skip_str
    @1000 @unload_kernel_modules
    @bridge_manipulation_with_1000_slaves
    Scenario: NM - bridge - manipulation with 1000 slaves bridge
    * Add "bridge" connection named "bridge4" for device "bridge0" with options "bridge.stp off"
    * Execute "for i in $(seq 0 1000); do ip link add port$i type dummy; ip link set port$i master bridge0; done"
    * Delete connection "bridge4"
    * Settle with RTNETLINK
    * Wait for "5" seconds
    Then Compare kernel and NM master-slave devices
    Then "GENERAL.DEVICE:\s+port999" is visible with command "nmcli device show port999"


    @firewall
    @bridge_assumed_connection_no_firewalld_zone
    Scenario: NM - bridge - no firewalld zone for bridge assumed connection
    * Create "bridge" device named "br0"
    * Execute "sudo ip link set dev br0 up"
    * Execute "sudo ip addr add 1.1.1.2/24 dev br0"
    When "IP4.ADDRESS\[1\]:\s+1.1.1.2\/24" is visible with command "nmcli con show br0" in "5" seconds
    Then "br0" is not visible with command "firewall-cmd --get-active-zones" in "5" seconds


    @ver+=1.1.1
    @bridge_assumed_connection_ip_methods
    Scenario: NM - bridge - Layer2 changes for bridge assumed connection
    * Create "bridge" device named "br0"
    * Create "dummy" device named "dummy0"
    * Execute "sudo ip link set dummy0 master br0"
    When "br0" is not visible with command "nmcli con"
    * Execute "sudo ip link set dev br0 up"
    * Execute "sudo ip link set dev dummy0 up"
    * Execute "sudo ip addr add 1.1.1.2/24 dev dummy0"
    * Execute "sudo ip addr add 1::3/128 dev br0"
    * Execute "sudo ip addr add 1.1.1.3/24 dev br0"
    Then "ipv4.method:\s+manual.*ipv4.addresses:\s+1.1.1.3\/24.*ipv6.method:\s+manual.*ipv6.addresses:\s+1::3\/128" is visible with command "nmcli connection show br0" in "5" seconds


    @rhbz1269199
    @restart_if_needed @long
    @bridge_external_unmanaged
    Scenario: bridge_external_unmanaged: add external bridge, ensure is unmanaged
    * Execute "sudo sh -c 'nmcli general logging level DEBUG'"
    Then Externally created bridge has IP when NM overtakes it repeated "30" times
    * Cleanup device "br0"


    @rhbz1169936
    @restart_if_needed
    @outer_bridge_restart_persistence
    Scenario: NM - bridge - bridge restart persistence
    * Prepare veth pairs "test1" bridged over "vethbr"
    * Restart NM
    Then "test1p.*master vethbr" is visible with command "ip link show type bridge_slave" in "5" seconds


    @rhbz1363995
    @ver+=1.4 @ver-=1.24
    @bridge_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Create "bridge" device named "br0"
    * Execute "ip link set dev br0 up"
    * Execute "ip add add 30.0.0.1/24 dev br0"
    When "br0:connected:br0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"
    * Execute "ip link set dev br0 down"
    Then "br0:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"


    @rhbz1363995 @rhbz1816202
    @ver+=1.25
    @bridge_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Create "bridge" device named "br0"
    * Execute "ip link set dev br0 up"
    * Execute "ip add add 30.0.0.1/24 dev br0"
    When "br0:connected \(externally\):br0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"
    * Execute "ip link set dev br0 down"
    Then "br0:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"


     @rhbz1355656
     @ver+=1.4
     @restart_if_needed
     @bridge_slave_to_ethernet_conversion
     Scenario: nmcli - bridge - slave to ethernet conversion
     * Add "bridge" connection named "bridge0" for device "bridge0" with options
           """
           bridge.stp off
           ipv4.method manual
           ipv4.address '192.168.99.99/24'
           ipv6.method ignore
           """
     * Add "ethernet" connection named "bridge4.1" for device "eth4"
     * Modify connection "bridge4.1" changing options "connection.master bridge0 connection.slave-type bridge"
     When "connection.master:\s+bridge0" is visible with command "nmcli c s bridge4.1 | grep 'master:'"
      And "connection.slave-type:\s+bridge" is visible with command "nmcli c s bridge4.1 | grep 'slave-type:'"
     * Execute "nmcli con modify bridge4.1 connection.master "" connection.slave-type """
   #  * Modify connection "bridge4.1" changing options "connection.master '' connection.slave-type ''"
     When "connection.master:\s+bridge0" is not visible with command "nmcli c s bridge4.1 | grep 'master:'"
      And "connection.slave-type:\s+bridge" is not visible with command "nmcli c s bridge4.1 | grep 'slave-type:'"
      And "BRIDGE" is not visible with command "grep BRIDGE /etc/sysconfig/network-scripts/ifcfg-bridge4.1"
     * Delete connection "bridge0"
     * Bring "up" connection "bridge4.1"

     * Disconnect device "eth4"
     * Reload connections
     Then "connection.master:\s+bridge0" is not visible with command "nmcli c s bridge4.1 | grep 'master:'"
      And "connection.slave-type:\s+bridge" is not visible with command "nmcli c s bridge4.1 | grep 'slave-type:'"
      And "BRIDGE" is not visible with command "grep BRIDGE /etc/sysconfig/network-scripts/ifcfg-bridge4.1"
      And Bring "up" connection "bridge4.1"


    @ver+=1.10
    @bridge_delete_connection_with_device
    Scenario: nmcli - bridge - delete with device
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.stp off
          autoconnect yes
          ip4 192.168.1.19/24
          """
    * Delete connection "bridge0"
    Then "bridge0" is not visible with command "nmcli dev"


    @ver+=1.10
    @restart_if_needed
    @bridge_delete_connection_without_device
    Scenario: nmcli - bridge - delete without device
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.stp off
          autoconnect yes
          ip4 192.168.1.19/24
          """
    * Reboot
    * Delete connection "bridge0"
    Then "bridge0" is visible with command "nmcli dev"


    @rhbz1576254
    @ver+=1.10
    @bridge_ipv6
    Scenario: nmcli - bridge - ipv6
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.stp off
          ip4 172.16.3.1/24
          ipv6.method auto
          ipv6.address fd01:42::1/64
          bridge.forward-delay 5
          autoconnect no
          """
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options
          """
          master bridge0
          autoconnect no
          """
    * Bring "up" connection "bridge-slave-eth4"
    Then "fe80" is visible with command "ip a show dev bridge0" in "20" seconds
     And "fd01:42::1/64" is visible with command "ip a show dev bridge0" in "20" seconds


    @rhbz1593939
    @ver+=1.14 @ver-1.41.2
    @eth4_disconnect @cleanup @restart_if_needed
    @bridge_detect_initrd_device
    Scenario: NM - bridge - nm detects initrd bridge
    * Add "bridge" connection named "bridge0" for device "bridge0" with options "bridge.stp no"
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options "master bridge0"
    * "." is visible with command "nmcli -g IP4.ADDRESS  c s bridge0" in "45" seconds
    * Stop NM
    * Execute "ip link set bridge0 type bridge forward_delay 0"
    * Execute "ip link set eth4 type bridge_slave cost 4"
    * Wait for "2" seconds
    * Reboot
    * Start NM
    * Wait for "2" seconds
    Then "Exactly" "1" lines with pattern "^bridge-slave-eth4" are visible with command "nmcli connection"
     And "Exactly" "1" lines with pattern "^bridge0" are visible with command "nmcli connection"
     And "\neth4" is not visible with command "nmcli connection show"


    @rhbz1593939
    @ver+=1.41.2
    @eth4_disconnect @cleanup @restart_if_needed
    @bridge_detect_initrd_device
    Scenario: NM - bridge - nm detects initrd bridge
    * Add "bridge" connection named "bridge-br0" for device "br0" with options "bridge.stp no"
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options "master bridge-br0"
    * "." is visible with command "nmcli -g IP4.ADDRESS  c s bridge-br0" in "45" seconds
    * Stop NM
    * Execute "ip link set br0 type bridge forward_delay 0"
    * Execute "ip link set eth4 type bridge_slave cost 4"
    * Wait for "2" seconds
    * Reboot
    * Start NM
    * Wait for "2" seconds
    Then "Exactly" "1" lines with pattern "^bridge-slave-eth4" are visible with command "nmcli connection"
     And "Exactly" "1" lines with pattern "^bridge-br0" are visible with command "nmcli connection"
     And "\neth4" is not visible with command "nmcli connection show"


    @rhbz1652910
    @ver+=1.17.3
    @bridge_vlan_filtering_no_pvid
    Scenario: NM - bridge - bridge vlan filtering no pvid
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.vlan-default-pvid 0
          bridge.vlan-filtering yes
          bridge.vlans 10
          """
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options
          """
          master bridge0
          slave-type bridge
          bridge-port.vlans 4094
          """
    Then "bridge0\s+10\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'" in "10" seconds
     And "eth4\s+4094\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'"


    @rhbz1652910
    @ver+=1.17.3
    @bridge_vlan_filtering_default_pvid
    Scenario: NM - bridge - bridge vlan filtering default pvid
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.vlan-filtering yes
          bridge.vlans '10-14 untagged'
          """
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options
          """
          master bridge0
          slave-type bridge
          bridge-port.vlans '4 untagged, 5'
          """
    Then "bridge0\s+1 PVID untagged\s+10 untagged\s+11 untagged\s+12 untagged\s+13 untagged\s+14 untagged\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'" in "10" seconds
     And "eth4\s+1 PVID untagged\s+4 untagged\s+5\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'"


    @rhbz1652910
    @ver+=1.17.3
    @bridge_vlan_filtering_non_default_pvid
    Scenario: NM - bridge - bridge vlan filtering non-default pvid
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          bridge.vlan-filtering yes
          bridge.vlan-default-pvid 80
          bridge.vlans '1-10, 100 pvid, 200 untagged'
          """
    * Add "ethernet" connection named "bridge-slave-eth4" for device "eth4" with options
          """
          master bridge0
          slave-type bridge
          bridge-port.vlans '4000-4010'
          """
    Then "bridge0\s+1\s+2\s+3\s+4\s+5\s+6\s+7\s+8\s+9\s+10\s+80 untagged\s+100 PVID\s+200 untagged\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'" in "10" seconds
     And "eth4\s+80 PVID untagged\s+4000\s+4001\s+4002\s+4003\s+4004\s+4005\s+4006\s+4007\s+4008\s+4009\s+4010\s" is visible with command "bridge vlan | sed 's/Egress Untagged/untagged/g'"


    @rhbz1679230
    @ver+=1.19
    @remove_custom_cfg @restart_if_needed
    @bridge_device_created_unmanaged
    Scenario: NM - bridge - virtual bridge created by NM should not be unmanaged
    * Execute "echo -e '[device]\nmatch-device=*\nmanaged=0' > /etc/NetworkManager/conf.d/99-xxcustom.conf;"
    * Restart NM
    * Add "bridge" connection named "bridge0" for device "bridge0"
    Then "unmanaged" is not visible with command "nmcli device | grep bridge0"
    * Delete connection "bridge0"
    Then "unmanaged" is not visible with command "nmcli device | grep bridge0"
     And "bridge0:" is not visible with command "ip link"


    @rhbz1795919
    @ver+=1.22.0
    @bridge_no_link_till_master
    Scenario: NM - bridge - no link till master
    * Add "dummy" connection named "bridge-slave-eth4" for device "dummy0" with options
          """
          ip4 172.25.1.1/24
          master nm-bridge
          slave-type bridge
          """
    When "dummy0" is not visible with command "ip a s"
    When Path "/sys/class/net/dummy0/ifindex" does not exist
    * Execute "sleep 1 && nmcli con up bridge-slave-eth4 || true"
    When "dummy0" is not visible with command "ip a s"
    When Path "/sys/class/net/dummy0/ifindex" does not exist
    * Add "bridge" connection named "bridge0" for device "nm-bridge" with options "ip4 172.25.2.1/24"
    Then "/sys/class/net/dummy0/ifindex" is file
    Then "nm-bridge\s+bridge\s+connected\s+bridge0" is visible with command "nmcli d" in "10" seconds
    Then "dummy0\s+dummy\s+connected\s+bridge-slave-eth4" is visible with command "nmcli d" in "10" seconds


    @rhbz1791378
    @ver+=1.22.0
    @skip_in_centos
    @bridge_down_to_l2_only
    Scenario: NM - bridge - go to L2 when DHCP is gone
    * Prepare simulated test "test44" device
    * Add "bridge" connection named "bridge4" for device "br4" with options
          """
          bridge.stp off
          ipv4.dhcp-timeout infinity
          ipv6.method disable
          """
    * Add "bridge-slave" connection named "bridge4.1" for device "test44" with options "master br4"
    * Bring "up" connection "bridge4.1"
    When "br4:connected:bridge4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    When "192.168.99" is visible with command "ip a s br4" in "20" seconds
    * Execute "ip netns exec test44_ns pkill -SIGSTOP -F /tmp/test44_ns.pid"
    When "192.168.99" is not visible with command "ip a s br4" in "150" seconds
    Then "br4:connected:bridge4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    Then "test44:connected:bridge4.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Wait for "20" seconds
    * Execute "ip netns exec test44_ns pkill -SIGCONT -F /tmp/test44_ns.pid"
    Then "192.168.99" is visible with command "ip a s br4" in "60" seconds
    Then "br4:connected:bridge4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    Then "test44:connected:bridge4.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1816517 @rhbz1848888
    @ver+=1.25
    @bridge_remove_slaves_ipv6ll
    Scenario: nmcli - bridge - remove slave's ipv6ll
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dummy0 up && sleep 2"
    * Execute "nmcli dev set dummy0 managed yes"
    When "fe80" is visible with command "ip a s dummy0" in "5" seconds
    * Add "bridge" connection named "bridge4" for device "br4" with options "ip4 172.25.89.1/24"
    * Add "dummy" connection named "bridge-slave-eth4" for device "dummy0" with options "master br4 autoconnect no"
    * Bring "up" connection "bridge-slave-eth4"
    When "br4:connected:bridge4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    When "dummy0:connected:bridge-slave-eth4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    Then "inet" is not visible with command "ip a s dummy0" in "5" seconds
    # Reproducer for 1848888
    Then "fe80" is not visible with command "python contrib/gi/nmclient_get_device_property.py dummy0 get_ip6_config"


    @rhbz1778590
    @ver+=1.29 @ver-=1.32 @rhelver+=8
    @bridge_set_mtu
    Scenario: nmcli - bridge - mtu handling
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          mtu 1500
          """
    * Add "dummy" connection named "bridge-slave-eth4" for device "dummy0" with options
          """
          master br0
          autoconnect no
          mtu 9000
          """
    * Bring "up" connection "bridge0"
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 1500" is visible with command "ip a s br0"
    When "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds
    * Delete connection "bridge0"
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          802-3-ethernet.mtu 0
          """
    * Bring "up" connection "bridge0"
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 9000" is visible with command "ip a s br0"
    When "mtu 9000" is visible with command "ip a s dummy0"
    * Modify connection "bridge0" changing options "802-3-ethernet.mtu 1500"
    * Execute "sudo nmcli d reapply br0"
    * Bring "up" connection "bridge-slave-eth4"
    Then "mtu 1500" is visible with command "ip a s br0"
    Then "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds


    @rhbz1973536
    @ver+=1.33
    @ver-1.39.5
    @rhelver+=8
    @bridge_set_mtu
    Scenario: nmcli - bridge - mtu handling
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          mtu 1500
          """
    * Bring "up" connection "bridge0"
    When "mtu 1500" is visible with command "ip a s br0" in "5" seconds
    * Modify connection "bridge0" changing options "remove 802-3-ethernet"
    * Bring "up" connection "bridge0"
    When "mtu 1499" is not visible with command "ip a s br0" for full "2" seconds
    * Add "dummy" connection named "bridge-slave-eth4" for device "dummy0" with options
          """
          master br0
          autoconnect no
          mtu 9000
          """
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds
    * Delete connection "bridge0"
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          802-3-ethernet.mtu 0
          """
    * Bring "up" connection "bridge0"
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 9000" is visible with command "ip a s br0"
    When "mtu 9000" is visible with command "ip a s dummy0"
    * Modify connection "bridge0" changing options "802-3-ethernet.mtu 1500"
    * Execute "sudo nmcli d reapply br0"
    * Bring "up" connection "bridge-slave-eth4"
    Then "mtu 1500" is visible with command "ip a s br0"
    Then "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds


    @rhbz1973536 @rhbz2076131
    @ver+=1.39.5
    @rhelver+=8
    @bridge_set_mtu
    Scenario: nmcli - bridge - mtu handling
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          """
    * Modify connection "bridge0" changing options "mtu 1500"
    * Execute "sudo nmcli d reapply br0"
    * Bring "up" connection "bridge0"
    When "mtu 1500" is visible with command "ip a s br0" in "5" seconds
    * Modify connection "bridge0" changing options "remove 802-3-ethernet"
    * Bring "up" connection "bridge0"
    When "mtu 1499" is not visible with command "ip a s br0" for full "2" seconds
    * Add "dummy" connection named "bridge-slave-eth4" for device "dummy0" with options
          """
          master br0
          autoconnect no
          mtu 9000
          """
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds
    * Delete connection "bridge0"
    * Add "bridge" connection named "bridge0" for device "br0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.autoconnect-slaves no
          802-3-ethernet.mtu 0
          """
    * Bring "up" connection "bridge0"
    * Bring "up" connection "bridge-slave-eth4"
    When "mtu 9000" is visible with command "ip a s br0"
    When "mtu 9000" is visible with command "ip a s dummy0"
    * Modify connection "bridge0" changing options "802-3-ethernet.mtu 1500"
    * Execute "sudo nmcli d reapply br0"
    * Bring "up" connection "bridge-slave-eth4"
    Then "mtu 1500" is visible with command "ip a s br0"
    Then "mtu 9000" is visible with command "ip a s dummy0"
    When "1500" is visible with command "nmcli -g GENERAL.MTU d show br0" in "5" seconds


    @rhbz1942331
    @ver+=1.31
    @bridge_accept_all_mac_addresses
    Scenario: nmcli - bridge - accept-all-mac-addresses (promisc mode)
    * Add "bridge" connection named "bridge0" for device "bridge0" with options "autoconnect no"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is not visible with command "ip link show dev bridge0"
    * Modify connection "bridge0" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is visible with command "ip link show dev bridge0"
    * Modify connection "bridge0" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is not visible with command "ip link show dev bridge0"


    @rhbz1942331
    @ver+=1.31
    @bridge_accept_all_mac_addresses_external_device
    Scenario: nmcli - bridge - accept-all-mac-addresses (promisc mode)
    # promisc off -> default
    * Execute "ip link add bridge0 type bridge && ip link set dev bridge0 promisc off"
    When "PROMISC" is not visible with command "ip link show dev bridge0"
    * Add "bridge" connection named "bridge0" for device "bridge0" with options
          """
          autoconnect no 802-3-ethernet.accept-all-mac-addresses default
          """
    * Bring "up" connection "bridge0"
    Then "PROMISC" is not visible with command "ip link show dev bridge0"
    * Bring "down" connection "bridge0"
    # promisc on -> default
    * Execute "ip link set dev bridge0 promisc on"
    When "PROMISC" is visible with command "ip link show dev bridge0"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is visible with command "ip link show dev bridge0"
    * Bring "down" connection "bridge0"
    # promisc off -> true
    * Execute "ip link set dev bridge0 promisc off"
    When "PROMISC" is not visible with command "ip link show dev bridge0"
    * Modify connection "bridge0" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is visible with command "ip link show dev bridge0"
    * Bring "down" connection "bridge0"
    # promisc on -> false
    * Execute "ip link set dev bridge0 promisc on"
    When "PROMISC" is visible with command "ip link show dev bridge0"
    * Modify connection "bridge0" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "bridge0"
    Then "PROMISC" is not visible with command "ip link show dev bridge0"


    @rhbz1949023
    @ver+=1.36
    @bridge_controller_port_terminology
    Scenario: bridge - use controller/port terminology
    * Add "bridge" connection named "bridge0" for device "bridge0" with options "autoconnect no"
    # update to controller/port when nmcli also gets update.
    * Add "dummy" connection named "dummy0" for device "dummy0" with options "master bridge0"
    * Bring "up" connection "dummy0"
    # list ports using libnm
    Then "dummy0" is visible with command "contrib/naming/ports-libnm.py bridge0"
    # list ports using dbus
    Then Note the output of "contrib/naming/ports-dbus.sh bridge0 dummy0"
     And Noted value contains "dbus ports:ao \d+"


    @rhbz2079054
    @ver+=1.39.5
    @bridge_keepaddr_unmanaged_device
    Scenario: bridge - keep addresses on unmanaged device
    * Cleanup device "testbr"
    * Execute reproducer "repro_2079054.sh"


    @rhbz2092762
    @ver+=1.40.0
    @bridge_keep_unmanaged_device_on_reapply
    Scenario: nmcli - bridge - keep unmanaged device attached to the bridge upon reapply
    * Add "bridge" connection named "br0" for device "br0" with options
      """
      bridge.stp off
      bridge.vlan-filtering off
      """
    * Create "veth" device named "vethfoo1" with options "peer name vethfoo2"
    * Execute "nmcli device set vethfoo1 managed no"
    * Execute "ip link set vethfoo1 master br0"
    * Execute "ip link set vethfoo1 up"
    Then "vethfoo1" is visible with command "bridge link"
    And "unmanaged" is visible with command "nmcli device | grep vethfoo1"
    And "no" is visible with command "nmcli -g bridge.stp connection show br0"
    And "no" is visible with command "nmcli -g bridge.vlan-filtering connection show br0"
    And "auto" is visible with command "nmcli -g 802-3-ethernet.mtu connection show br0"
    * Modify connection "br0" changing options "bridge.stp on bridge.vlan-filtering on ethernet.mtu 1600"
    * Execute "nmcli device reapply br0"
    Then "vethfoo1" is visible with command "bridge link"
    And "unmanaged" is visible with command "nmcli device | grep vethfoo1"
    And "yes" is visible with command "nmcli -g bridge.stp connection show br0"
    And "yes" is visible with command "nmcli -g bridge.vlan-filtering connection show br0"
    And "1600" is visible with command "nmcli -g 802-3-ethernet.mtu connection show br0"

