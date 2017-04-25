@testplan
Feature: nmcli - bridge

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

	@cleanbridge
    Scenario: Clean bridge
    * "eth0" is visible with command "ifconfig"


    @bridge
    @bridge_add_default
    Scenario: nmcli - bridge - add default bridge
    * Add a new connection of type "bridge" and options " "
    * Open editor for connection "bridge"
    * "nm-bridge:" is visible with command "ifconfig"
    * Note the "connection.id" property from editor print output
    * Quit editor
    Then Check ifcfg-name file created with noted connection name


	@bridge
    @bridge_add_custom_one
    Scenario: nmcli - bridge - add custom bridge
    * Add a new connection of type "bridge" and options "con-name br88 autoconnect no ifname br88 priority 5 forward-delay 3 hello-time 3 max-age 15 ageing-time 500000"
    * Bring up connection "br88" ignoring error
    * "br88:" is visible with command "ifconfig"
    Then "br88" is visible with command "brctl show"
    Then "DELAY=3.*BRIDGING_OPTS=\"priority=5 hello_time=3 max_age=15 ageing_time=500000\".*NAME=br88.*ONBOOT=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-br88"


	@bridge
    @bridge_connection_up
    Scenario: nmcli - bridge - up
    * Add a new connection of type "bridge" and options "con-name br11 ifname br11 autoconnect no"
    * Check ifcfg-name file created for connection "br11"
    * "br11" is not visible with command "brctl show"
    * Bring up connection "br11" ignoring error
    Then "br11" is visible with command "brctl show"


	@bridge
    @bridge_connection_down
    Scenario: nmcli - bridge - down
    * Add a new connection of type "bridge" and options "con-name br11 ifname br11 autoconnect no ip4 192.168.1.15/24"
    * Bring up connection "br11" ignoring error
    * "br11" is visible with command "brctl show"
    * "inet 192.168.1.15" is visible with command "ifconfig"
    * Bring down connection "br11"
    * "inet 192.168.1.15" is not visible with command "ifconfig"


	@bridge
    @bridge_disconnect_device
    Scenario: nmcli - bridge - disconnect device
    * Add a new connection of type "bridge" and options "con-name br11 ifname br11 autoconnect no ip4 192.168.1.10/24"
    * Bring up connection "br11" ignoring error
    * "br11" is visible with command "brctl show"
    * "inet 192.168.1.10" is visible with command "ifconfig"
    * Disconnect device "br11"
    * "inet 192.168.1.10" is not visible with command "ifconfig"


    @bridge
    @bridge_describe_all
    Scenario: nmcli - bridge - describe all
    * Open editor for a type "bridge"
    Then Check "mac-address|stp|priority|forward-delay|hello-time|max-age|ageing-time" are present in describe output for object "bridge"


    @bridge
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


	@bridge
    @bridge_delete_connection
    Scenario: nmcli - bridge - delete connection
    * Add a new connection of type "bridge" and options "con-name br11 ifname br11"
    * Check ifcfg-name file created for connection "br11"
    * Bring up connection "br11" ignoring error
    * Delete connection "br11"
    Then ifcfg-"br11" file does not exist


	@bridge
    @bridge_delete_connection_while_up
    Scenario: nmcli - bridge - delete connection while up
    * Add a new connection of type "bridge" and options "con-name br12 ifname br12 autoconnect no ip4 192.168.1.19/24"
    * Bring up connection "br12" ignoring error
    * "inet 192.168.1.19" is visible with command "ifconfig"
    * Delete connection "br12"
    Then "inet 192.168.1.19" is not visible with command "ifconfig"
    Then ifcfg-"br12" file does not exist


    @bridge
    @bridge_set_mac
    Scenario: nmcli - bridge - set mac address
    * Add a new connection of type "bridge" and options "con-name br12 ifname br12 autoconnect no"
    * Check ifcfg-name file created for connection "br12"
    * Open editor for connection "br12"
    * Set a property named "bridge.mac-address" to "f0:de:aa:fb:bb:cc" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "br12" ignoring error
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip a s br12"


	@bridge
    @bridge_add_slave
    Scenario: nmcli - bridge - add slave
    #* Execute "nmcli dev con eth1"
    * Add a new connection of type "bridge" and options "con-name br15 ifname br15 autoconnect no"
    * Check ifcfg-name file created for connection "br15"
    * Add a new connection of type "vlan" and options "con-name eth1.80 dev eth1 id 80"
    * Check ifcfg-name file created for connection "eth1.80"
    * Add a new connection of type "bridge-slave" and options "autoconnect no ifname eth1.80 master br15"
    Then "BRIDGE=br15" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth1.80"

	@bridge
    @bridge_remove_slave
    Scenario: nmcli - bridge - remove slave
    #* Execute "nmcli dev con eth1"
    * Add a new connection of type "bridge" and options "con-name br15 ifname br15 autoconnect no"
    * Check ifcfg-name file created for connection "br15"
    * Add a new connection of type "vlan" and options "con-name eth1.80 dev eth1 id 80"
    * Check ifcfg-name file created for connection "eth1.80"
    * Add a new connection of type "bridge-slave" and options "con-name br15-slave autoconnect no ifname eth1.80 master br15"
    * Check ifcfg-name file created for connection "br15-slave"
    * Delete connection "br15-slave"
    Then ifcfg-"br15-slave" file does not exist


	@bridge
    @bridge_up_with_slaves
    Scenario: nmcli - bridge - up with slaves
    * Add a new connection of type "bridge" and options "con-name br15 ifname br15 ip4 192.168.1.19/24"
    * Add a new connection of type "vlan" and options "con-name eth1.80 dev eth1 id 80"
    * Check ifcfg-name file created for connection "eth1.80"
    * Add a new connection of type "vlan" and options "con-name eth1.90 dev eth1 id 90"
    * Check ifcfg-name file created for connection "eth1.90"
    * Add a new connection of type "bridge-slave" and options "con-name br15-slave1 ifname eth1.80 master br15"
    * Check ifcfg-name file created for connection "br15-slave1"
    * Add a new connection of type "bridge-slave" and options "con-name br15-slave2 ifname eth1.90 master br15"
    * Check ifcfg-name file created for connection "br15-slave2"
    * Bring up connection "br15"
    Then  "br15" is visible with command "brctl show"


	@bridge
    @bridge_up_slave
    Scenario: nmcli - bridge - up slave
    * Add a new connection of type "bridge" and options "con-name br10 ifname br10 ip4 192.168.1.19/24"
    * Add a new connection of type "bridge-slave" and options "con-name br10-slave autoconnect no ifname eth1 master br10"
    * Check ifcfg-name file created for connection "br10-slave"
    * Bring up connection "br10-slave"
    Then  "br10.*eth1" is visible with command "brctl show"
    Then Disconnect device "br10"


    @rhbz1158529
    @bridge
    @bridge_slaves_start_via_master
    Scenario: nmcli - bridge - start slave via master
    * Add a new connection of type "bridge" and options "con-name br10 ifname br10"
    * Add a new connection of type "bridge-slave" and options "con-name br10-slave autoconnect no ifname eth1 master br10"
    * Open editor for connection "br10"
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.19/24" in editor
    * Set a property named "connection.autoconnect-slaves" to "1" in editor
    * Save in editor
    * Quit editor
    Then Disconnect device "br10"
    * Bring up connection "br10"
    Then  "br10.*eth1" is visible with command "brctl show"
    Then Disconnect device "br10"


    @bridge
    @eth1_disconnect
    @bridge_dhcp_config_with_ethernet_port
    Scenario: nmcli - bridge - dhcp config with ethernet port
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
    * Check ifcfg-name file created for connection "bridge0"
    * Add a new connection of type "bridge-slave" and options "ifname eth1 con-name bridge-slave-eth1 master bridge0"
    * Bring up connection "bridge-slave-eth1"
    Then "bridge0.*eth1" is visible with command "brctl show" in "10" seconds
    Then "eth1.*master bridge0" is visible with command "ip a"
    Then "eth2" is visible with command "ip a"
    Then "bridge0:.*192.168.*inet6" is visible with command "ip a" in "30" seconds


    @bridge
    @eth1_disconnect
    @bridge_dhcp_config_with_multiple_ethernet_ports
    Scenario: nmcli - bridge - dhcp config with multiple ethernet ports
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
    * Check ifcfg-name file created for connection "bridge0"
    * Add a new connection of type "bridge-slave" and options "ifname eth1 con-name bridge-slave-eth1 master bridge0"
    * Bring up connection "bridge-slave-eth1"
    * Add a new connection of type "bridge-slave" and options "ifname eth2 con-name bridge-slave-eth2 master bridge0"
    * Bring up connection "bridge-slave-eth2"
    * Add a new connection of type "bridge-slave" and options "ifname eth3 con-name bridge-slave-eth3 master bridge0"
    * Bring up connection "bridge-slave-eth3"
    Then "bridge0.*eth1.*eth2.*eth3" is visible with command "brctl show" in "10" seconds
    Then "eth1.*master bridge0" is visible with command "ip a"
    Then "eth2.*master bridge0" is visible with command "ip a"
    Then "eth3.*master bridge0" is visible with command "ip a"
    Then "bridge0:.*192.168.*inet6" is visible with command "ip a" in "60" seconds


    @bridge
    @eth1_disconnect
    @bridge_static_config_with_multiple_ethernet_ports
    Scenario: nmcli - bridge - dhcp config with multiple ethernet ports
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0 autoconnect no ip4 192.168.1.19/24"
    * Add a new connection of type "bridge-slave" and options "ifname eth1 con-name bridge-slave-eth1 master bridge0"
    * Bring up connection "bridge-slave-eth1"
    * Add a new connection of type "bridge-slave" and options "ifname eth2 con-name bridge-slave-eth2 master bridge0"
    * Bring up connection "bridge-slave-eth2"
    * Add a new connection of type "bridge-slave" and options "ifname eth3 con-name bridge-slave-eth3 master bridge0"
    * Bring up connection "bridge-slave-eth3"
    Then "bridge0.*eth1.*eth2.*eth3" is visible with command "brctl show" in "10" seconds
    Then "eth1.*master bridge0" is visible with command "ip a"
    Then "eth2.*master bridge0" is visible with command "ip a"
    Then "eth3.*master bridge0" is visible with command "ip a"
    Then "bridge0:.*192.168.1.19" is visible with command "ip a" in "30" seconds


    @bridge
    @need_config_server
    @bridge_server_ingore_carrier_with_dhcp
    Scenario: nmcli - bridge - server ingore carrier with_dhcp
    * Disconnect device "eth1"
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
    * Check ifcfg-name file created for connection "bridge0"
    * Add a new connection of type "bridge-slave" and options "ifname eth1 con-name bridge-slave-eth1 master bridge0"
    * Bring up connection "bridge-slave-eth1"
    Then "bridge0.*eth1" is visible with command "brctl show" in "10" seconds
    Then "eth1.*master bridge0" is visible with command "ip a s eth1"
    Then "bridge0:.*192.168" is visible with command "ip a s bridge0" in "45" seconds


    @ver-=1.1
    @rhbz1030947
    @dummy
    @bridge_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bridge - reflect changes from outside of NM
    * Execute "ip link add br0 type bridge"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev br0 up"
    When "br0\s+bridge\s+disconnected" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link add dummy0 type dummy"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add 1.1.1.1/24 dev br0"
    When "br0\s+bridge\s+connected\s+br0" is visible with command "nmcli d" in "5" seconds
    * Execute "brctl addif br0 dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d" in "5" seconds
    Then "BRIDGE.SLAVES:\s+dummy0" is visible with command "nmcli -f bridge.slaves dev show br0"


    @ver+=1.1.1
    @rhbz1030947
    @dummy
    @bridge_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bridge - reflect changes from outside of NM
    * Execute "ip link add br0 type bridge"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev br0 up"
    When "br0\s+bridge\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link add dummy0 type dummy"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add 1.1.1.1/24 dev br0"
    When "br0\s+bridge\s+connected\s+br0" is visible with command "nmcli d" in "5" seconds
    * Execute "brctl addif br0 dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d" in "5" seconds
    Then "BRIDGE.SLAVES:\s+dummy0" is visible with command "nmcli -f bridge.slaves dev show br0"


    @restart
    @bridge_assumed_connection_race
    Scenario: NM - bridge - no crash when bridge started and shutdown immediately
    * Create 300 bridges and delete them
    Then "active" is visible with command "systemctl is-active NetworkManager.service"


    @1000 @not_on_aarch64
    @bridge_manipulation_with_1000_slaves
    Scenario: NM - bridge - manipulation with 1000 slaves bridge
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
    * Execute "for i in $(seq 0 1000); do ip link add port$i type dummy; ip link set port$i master bridge0; done"
    * Delete connection "bridge0"
    * Settle with RTNETLINK
    Then Compare kernel and NM devices
    Then "GENERAL.DEVICE:\s+port999" is visible with command "nmcli device show port999"


    @firewall
    @dummy
    @bridge_assumed_connection_no_firewalld_zone
    Scenario: NM - bridge - no firewalld zone for bridge assumed connection
    * Execute "sudo ip link add br0 type bridge"
    * Execute "sudo ip link set dev br0 up"
    * Execute "sudo ip addr add 1.1.1.2/24 dev br0"
    When "IP4.ADDRESS\[1\]:\s+1.1.1.2\/24" is visible with command "nmcli con show br0" in "5" seconds
    Then "br0" is not visible with command "firewall-cmd --get-active-zones" in "5" seconds


    @ver-=1.1
    @dummy
    @bridge_assumed_connection_ip_methods
    Scenario: NM - bridge - Layer2 changes for bridge assumed connection
    * Execute "sudo ip link add br0 type bridge"
    * Execute "sudo ip link add dummy0 type dummy"
    * Execute "sudo ip link set dummy0 master br0"
    When "br0" is not visible with command "nmcli con"
    * Execute "sudo ip link set dev br0 up"
    When "ipv4.method:\s+disabled.*ipv6.method:\s+ignore" is visible with command "nmcli connection show br0" in "5" seconds
    * Execute "sudo ip link set dev dummy0 up"
    * Execute "sudo ip addr add 1.1.1.2/24 dev dummy0"
    When "ipv4.method:\s+disabled.*ipv6.method:\s+link-local" is visible with command "nmcli connection show br0" in "5" seconds
    * Execute "sudo ip addr add 1::3/128 dev br0"
    * Execute "sudo ip addr add 1.1.1.3/24 dev br0"
    Then "ipv4.method:\s+manual.*ipv4.addresses:\s+1.1.1.3\/24.*ipv6.method:\s+manual.*ipv6.addresses:\s+1::3\/128" is visible with command "nmcli connection show br0" in "5" seconds


    @ver+=1.1.1
    @dummy
    @bridge_assumed_connection_ip_methods
    Scenario: NM - bridge - Layer2 changes for bridge assumed connection
    * Execute "sudo ip link add br0 type bridge"
    * Execute "sudo ip link add dummy0 type dummy"
    * Execute "sudo ip link set dummy0 master br0"
    When "br0" is not visible with command "nmcli con"
    * Execute "sudo ip link set dev br0 up"
    * Execute "sudo ip link set dev dummy0 up"
    * Execute "sudo ip addr add 1.1.1.2/24 dev dummy0"
    * Execute "sudo ip addr add 1::3/128 dev br0"
    * Execute "sudo ip addr add 1.1.1.3/24 dev br0"
    Then "ipv4.method:\s+manual.*ipv4.addresses:\s+1.1.1.3\/24.*ipv6.method:\s+manual.*ipv6.addresses:\s+1::3\/128" is visible with command "nmcli connection show br0" in "5" seconds


    @rhbz1269199
    @dummy @restart @long
    @bridge_external_unmanaged
    Scenario: bridge_external_unmanaged: add external bridge, ensure is unmanaged
    * Execute "sudo sh -c 'nmcli general logging level DEBUG'"
    Then Externally created bridge has IP when NM overtakes it repeated "30" times


    @rhbz1169936
    @two_bridged_veths
    @outer_bridge_restart_persistence
    Scenario: NM - bridge - bridge restart persistence
    * Prepare veth pairs "test1" bridged over "vethbr"
    * Restart NM
    Then "vethbr.*test1p" is visible with command "brctl show vethbr" in "5" seconds


    @rhbz1363995
    @ver+=1.4
    @dummy
    @bridge_preserve_assumed_connection_ips
    Scenario: nmcli - bridge - preserve assumed connection's addresses
    * Execute "ip link add br0 type bridge"
    * Execute "ip link set dev br0 up"
    * Execute "ip add add 30.0.0.1/24 dev br0"
    When "br0:connected:br0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"
    * Execute "ip link set dev br0 down"
    Then "br0:unmanaged" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "inet 30.0.0.1\/24" is visible with command "ip a s br0"


     @rhbz1355656
     @ver+=1.4
     @bridge @restart @eth
     @bridge_slave_to_ethernet_conversion
     Scenario: nmcli - bridge - slave to ethernet conversion
     * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0 ipv4.method manual ipv4.address '192.168.99.99/24' ipv6.method ignore"
     * Add connection type "ethernet" named "ethie" for device "eth1"
     * Modify connection "ethie" changing options "connection.master bridge0 connection.slave-type bridge"
     When "connection.master:\s+bridge0" is visible with command "nmcli c s ethie | grep 'master:'"
      And "connection.slave-type:\s+bridge" is visible with command "nmcli c s ethie | grep 'slave-type:'"
     * Execute "nmcli con modify ethie connection.master "" connection.slave-type """
   #  * Modify connection "ethie" changing options "connection.master '' connection.slave-type ''"
     When "connection.master:\s+bridge0" is not visible with command "nmcli c s ethie | grep 'master:'"
      And "connection.slave-type:\s+bridge" is not visible with command "nmcli c s ethie | grep 'slave-type:'"
      And "BRIDGE" is not visible with command "grep BRIDGE /etc/sysconfig/network-scripts/ifcfg-ethie"
     * Delete connection "bridge0"
     * Bring "up" connection "ethie"
     * Disconnect device "eth1"
     * Execute "nmcli con reload"
     Then "connection.master:\s+bridge0" is not visible with command "nmcli c s ethie | grep 'master:'"
      And "connection.slave-type:\s+bridge" is not visible with command "nmcli c s ethie | grep 'slave-type:'"
      And "BRIDGE" is not visible with command "grep BRIDGE /etc/sysconfig/network-scripts/ifcfg-ethie"
      And Bring "up" connection "ethie"
