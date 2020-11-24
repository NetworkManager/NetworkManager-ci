@testplan
Feature: nmcli - ovs

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.22
    @openvswitch_capability
    Scenario: NM - openvpswitch - check that OVS is in capabilities
    Then Check that "OVS" capability is loaded


    @ver+=1.10
    @openvswitch
    @openvswitch_interface_recognized
    Scenario: NM - openvswitch - openvswitch interface recognized
    * Execute "ovs-vsctl add-br ovsbr0"
    * "ovsbr0" is visible with command "ip a"
    When "ovsbr0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
     And "ovsbr0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"
     And "ovsbr0\s+ovs-interface\s+disconnected" is visible with command "nmcli device"
    * Execute "ovs-vsctl del-br ovsbr0"
    Then "ovsbr0" is not visible with command "nmcli device"


    @ver+=1.10
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @openvswitch
    @openvswitch_ignore_ovs_network_setup
    Scenario: NM - openvswitch - ignore ovs network setup
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name eth1 autoconnect no"
    * Check ifcfg-name file created for connection "eth1"
    * Execute "mv -f /tmp/eth1tmp /etc/sysconfig/network-scripts/ifcfg-eth1"
    * Execute "echo -e 'DEVICE=eth1\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSPort\nOVS_BRIDGE=ovsbridge0\nBOOTPROTO=none\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-eth1"
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Execute "ifup eth1"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a s ovsbridge0"
    Then "ovs-system" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "eth1\s+ethernet\s+disconnected" is visible with command "nmcli device"
    Then "eth1\s+ovs-port\s+unmanaged" is visible with command "nmcli device"


    @ver+=1.10
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @openvswitch
    @openvswitch_ignore_ovs_vlan_network_setup
    Scenario: NM - openvswitch - ignore ovs network setup
    * Execute "echo -e 'DEVICE=intbr0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSIntPort\nOVS_BRIDGE=ovsbridge0\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-intbr0"
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Execute "ifup intbr0"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a"
    Then "intbr0" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "intbr0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"


    @ver+=1.10
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @openvswitch
    @openvswitch_ignore_ovs_bond_network_setup
    Scenario: NM - openvswitch - ignore ovs network setup
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name eth1 autoconnect no"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name eth2 autoconnect no"
    * Execute """echo -e 'DEVICE=bond0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBond\nOVS_BRIDGE=ovsbridge0\nBOOTPROTO=none\nBOND_IFACES="eth1 eth2"\nOVS_OPTIONS="bond_mode=balance-tcp lacp=active"\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-bond0"""
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Execute "ifup bond0"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a"
    #VVV  Should this be visible???
    #Then "bond0" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "bond0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"


    @rhbz1540218
    @ver+=1.10 @ver-1.16
    @openvswitch
    @nmcli_add_basic_openvswitch_configuration
    Scenario: nmcli - openvswitch - add basic setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface port1 conn.master ovsbridge0 con-name ovs-port1"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master port1 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port1[\"]?\s+Interface [\"]?eth2[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218 @rhbz1519176
    @ver+=1.16.2
    @openvswitch
    @nmcli_add_basic_openvswitch_configuration
    Scenario: nmcli - openvswitch - add basic setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface port1 conn.master ovsbridge0 con-name ovs-port1"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master port1 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port1[\"]?\s+Interface [\"]?eth2[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_add_openvswitch_bond_configuration
    Scenario: nmcli - openvswitch - add bond setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_add_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - add vlan setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_remove_one_openvswitch_bond_configuration
    Scenario: nmcli - openvswitch - remove bond slave connection
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-eth2"
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_remove_openvswitch_ports_and_master_bridge_configuration
    Scenario: nmcli - openvswitch - remove ports and master bridge connections
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-port0"
    * Delete connection "ovs-bond0"
    When "bond0" is not visible with command "ovs-vsctl show"
     And "port0" is not visible with command "ovs-vsctl show"
    * Delete connection "ovs-bridge0"
    Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.100.*\/24" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     And "ovs" is not visible with command "nmcli device"


    @rhbz1540218
    @ver+=1.10 @ver-1.16
    @openvswitch
    @nmcli_remove_openvswitch_master_bridge_configuration_only
    Scenario: nmcli - openvswitch - remove master bridge connection
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-bridge0"
    Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.100.*\/24" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     #And "ovs" is not visible with command "nmcli device"


    @rhbz1540218
    @ver+=1.16.2
    @openvswitch
    @nmcli_remove_openvswitch_master_bridge_configuration_only
    Scenario: nmcli - openvswitch - remove master bridge connection
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-bridge0"
    Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.100.*\/24" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     And "ovs" is not visible with command "nmcli device"


    @rhbz1540218
    @ver+=1.10 @ver-1.17
    @openvswitch
    @nmcli_reconnect_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - reconnect all connections
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    # VVV Reconnect master bridge connection
    # * Bring "up" connection "ovs-bridge0"
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    #  And "Bridge [\"]?bridge0[\"]?" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    #  And "master ovs-system" is visible with command "ip a s eth2"
    #  And "master ovs-system" is visible with command "ip a s eth3"
    #  And "192.168.100.*\/24" is visible with command "ip a s iface0"
    #  And "fe80::" is visible with command "ip a s iface0"
    #  And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect port connection
    # * Bring "up" connection "ovs-port0"
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    #  And "Bridge [\"]?bridge0[\"]?" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    #  And "master ovs-system" is visible with command "ip a s eth2"
    #  And "master ovs-system" is visible with command "ip a s eth3"
    #  And "192.168.100.*\/24" is visible with command "ip a s iface0"
    #  And "fe80::" is visible with command "ip a s iface0"
    #  And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond master connection
    * Bring "up" connection "ovs-bond0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond slave connection
    * Bring "up" connection "ovs-eth3"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect iface connection
    * Bring "down" connection "ovs-iface0"
    * Bring "up" connection "ovs-iface0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218 @rhbz1543557
    @ver+=1.18.0
    @openvswitch
    @nmcli_reconnect_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - reconnect all connections
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    # VVV Reconnect master bridge connection
    * Bring "up" connection "ovs-bridge0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect port connection
    * Bring "up" connection "ovs-port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond master connection
    * Bring "up" connection "ovs-bond0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond slave connection
    * Bring "up" connection "ovs-eth3"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect iface connection
    * Bring "down" connection "ovs-iface0"
    * Bring "up" connection "ovs-iface0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10 @ver=-1.18.7
    @openvswitch @restart
    @NM_reboot_openvswitch_vlan_configuration
    Scenario: NM - openvswitch - reboot
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Stop NM
    * Execute "ovs-vsctl del-br ovsbridge0"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.100.*\/24" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"


    @rhbz1540218 @rhbz1734032
    @ver+=1.18.8
    @openvswitch @restart
    @NM_reboot_openvswitch_vlan_configuration
    Scenario: NM - openvswitch - reboot
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Stop NM
    * Execute "ovs-vsctl del-br ovsbridge0"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.100.*\/24" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.100.*\/24" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.100.*\/24" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1740557 @rhbz1852612 @rhbz1845216 @rhbz1855563
    @ver+=1.18.8
    @openvswitch @disp
    @ovs_cloned_mac_set_on_iface
    Scenario: nmcli - openvswitch - mac address set iface
    * Execute "systemctl restart NetworkManager-dispatcher"
    * Execute "echo -e '#!/bin/bash\nsleep 1' >/etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Execute "chmod +x /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no  802-3-ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported from 1.26
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported from 1.26
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported from 1.26
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"


    @rhbz1740557 @rhbz1852612 @rhbz1855563
    @ver+=1.18.8 @ver-=1.25
    @openvswitch @disp
    @ovs_cloned_mac_set_on_iface
    Scenario: nmcli - openvswitch - mac address set iface
    * Execute "systemctl restart NetworkManager-dispatcher"
    * Execute "echo -e '#!/bin/bash\nsleep 1' >/etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Execute "chmod +x /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no  802-3-ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    # Was not backported
    # When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"


    @rhbz1740557 @rhbz1852612 @rhbz1855563
    @ver+=1.26
    @openvswitch @disp
    @ovs_cloned_mac_set_on_iface
    Scenario: nmcli - openvswitch - mac address set iface
    * Execute "systemctl restart NetworkManager-dispatcher"
    * Execute "echo -e '#!/bin/bash\nsleep 1' >/etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Execute "chmod +x /etc/NetworkManager/dispatcher.d/pre-down.d/97-disp"
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no  802-3-ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "00:11:22:33:44:55" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:44:55" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:44:55"" is visible with command "sudo ovs-vsctl list interface"


    @rhbz1786937
    @ver+=1.18.8
    @openvswitch @mtu
    @ovs_mtu
    Scenario: nmcli - openvswitch - mtu
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0 ethernet.mtu 9000"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2 ethernet.mtu 9000"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3 ethernet.mtu 9000"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no  802-3-ethernet.cloned-mac-address 00:11:22:33:44:55 ethernet.mtu 9000"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "9000" is visible with command "ip a s iface0"
    Then "9000" is visible with command "ip a s eth2"
    Then "9000" is visible with command "ip a s eth3"
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "9000" is visible with command "ip a s iface0"
    Then "9000" is visible with command "ip a s eth2"
    Then "9000" is visible with command "ip a s eth3"


    @rhbz1740557
    @ver+=1.18.0
    @openvswitch
    @ovs_cloned_mac_with_the_same_bridge_iface_name
    Scenario: nmcli - openvswitch - mac address set on ovs-bridge (iface name is the same)
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0 802-3-ethernet.cloned-mac-address 00:11:22:33:44:55"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface ovsbridge0 conn.master port0 con-name ovs-iface0 ipv4.may-fail no"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "00:11:22:33:44:55" is visible with command "ip a s ovsbridge0"


    @rhbz1676551
    @ver+=1.12
    @rhelver-=7 @fedoraver-=0
    @openvswitch @restart @vlan @bond @slaves
    @restart_NM_with_mixed_setup
    Scenario: NM -  openvswitch - restart NM when OVS is unmanaged
    * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 ipv4.method manual ipv4.addresses 10.0.0.2/16 ipv4.gateway 10.0.0.1"
    * Add a new connection of type "vlan" and options "con-name vlan1 dev nm-bond id 101 ipv6.method ignore ipv4.method manual ipv4.method manual ipv4.addresses 10.200.208.98/16  ipv4.routes 224.0.0.0/4"
    * Add a new connection of type "vlan" and options "con-name vlan2 dev nm-bond id 201 ipv6.method ignore ipv4.method manual ipv4.addresses 10.201.0.13/24 ipv4.gateway 10.201.0.1"
    * Add a new connection of type "ethernet" and options "ifname eth2 master nm-bond con-name bond0.0"
    * Add a new connection of type "ethernet" and options "ifname eth3 master nm-bond con-name bond0.1"
    * Execute "ovs-vsctl add-br ovsbr0 -- add-port ovsbr0 nm-bond"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
     And "224.0.0.0/4 dev nm-bond.101" is visible with command "ip r"
     And "10.200.0.0/16 dev nm-bond.101" is visible with command "ip r"
     And "10.201.0.0/24 dev nm-bond.201" is visible with command "ip r"
     And "default via" is visible with command "ip r |grep nm-bond"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
     And "224.0.0.0/4 dev nm-bond.101" is visible with command "ip r"
     And "10.200.0.0/16 dev nm-bond.101" is visible with command "ip r"
     And "10.201.0.0/24 dev nm-bond.201" is visible with command "ip r"
     And "default via" is visible with command "ip r |grep nm-bond"


     @rhbz1676551 @rhbz1612503
     @ver+=1.19.5
     @openvswitch @dpdk
     @add_dpdk_port
     Scenario: NM -  openvswitch - add dpdk device
     * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0 ovs-bridge.datapath-type netdev"
     * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
     * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ovs-dpdk.devargs 0000:42:10.0"
     Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface\s+[\"]?iface0[\"]?\s+type: dpdk\s+options: {dpdk-devargs=[\"]?0000:42:10.0[\"]?}" is visible with command "ovs-vsctl show"


    @rhbz1676551 @rhbz1612503
    @ver+=1.19.5
    @openvswitch @dpdk
    @add_dpdk_bond_sriov
    Scenario: NM -  openvswitch - add dpdk device
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0 ovs-bridge.datapath-type netdev"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master ovsbridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0 ovs-dpdk.devargs 0000:42:10.0"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface1 conn.master bond0 con-name ovs-iface1 ovs-dpdk.devargs 0000:42:10.2"
    * Add a new connection of type "ethernet" and options "conn.interface em1 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Bring "up" connection "ovs-eth3"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface1" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+Interface\s+[\"]?iface0[\"]?\s+type: dpdk\s+options: {dpdk-devargs=[\"]?0000:42:10.0[\"]?}" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface\s+[\"]?iface1[\"]?\s+type: dpdk\s+options: {dpdk-devargs=[\"]?0000:42:10.2[\"]?}\s+Interface\s+[\"]?em1[\"]?\s+type: system|Port [\"]?bond0[\"]?\s+tag: 120\s+Interface\s+[\"]?em1[\"]?\s+type: system\s+Interface\s+[\"]?iface1[\"]?\s+type: dpdk\s+options: {dpdk-devargs=[\"]?0000:42:10.2[\"]?}" is visible with command "ovs-vsctl show"


    @rhbz1804167
    @ver+=1.22.7
    @openvswitch
    @clear_ovs_settings
    Scenario: NM -  openvswitch - clear ovs settings
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ethernet" and options "ifname eth2 master port0 con-name eth2 slave-type ovs-port"
    When "slave-type:\s+ovs-port" is visible with command "nmcli con show eth2"
    When "connection.master:\s+port0" is visible with command "nmcli con show eth2"
    When "ovs-interface" is visible with command "nmcli con show eth2"
    * Send "remove ovs-interface; remove connection.master; remove connection.slave-type" via editor to "eth2"
    Then "slave-type:\s+ovs-port" is not visible with command "nmcli con show eth2"
    Then "connection.master:\s+port0" is not visible with command "nmcli con show eth2"
    Then "ovs-interface" is not visible with command "nmcli con show eth2"


    @rhbz1845216
    @ver+=1.25 @rhelver+=8
    @openvswitch
    @ovs_patch_add
    Scenario: NM -  openvswitch - add ovs patch
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master ovsbridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-interface" and options "ifname patch0 master port0 ovs-interface.type patch ovs-patch.peer patch1 con-name ovs-patch0"
    * Add a new connection of type "ovs-bridge" and options "conn.interface ovsbridge1 con-name ovs-bridge1"
    * Add a new connection of type "ovs-port" and options "conn.interface port1 conn.master ovsbridge1 con-name ovs-port0"
    * Add a new connection of type "ovs-interface" and options "ifname patch1 master port1 ovs-interface.type patch ovs-patch.peer patch0 con-name ovs-patch1"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-patch0" in "10" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-patch1" in "10" seconds
    Then "Interface patch0\s*type: patch\s*options: \{peer\=patch1\}" is visible with command "ovs-vsctl show"
    Then "Interface patch1\s*type: patch\s*options: \{peer\=patch0\}" is visible with command "ovs-vsctl show"


    @rhbz1866227
    @ver+=1.29.1
    @openvswitch
    @ovs_external_ids
    Scenario: NM -  openvswitch - add dpdk device
    * Add a new connection of type "ovs-bridge" and options "    conn.interface i-ovs-br0    con-name c-ovs-br0    autoconnect no"
    * Add a new connection of type "ovs-port" and options "      conn.interface i-ovs-port0  con-name c-ovs-port0  autoconnect no conn.master i-ovs-br0"
    * Add a new connection of type "ovs-interface" and options " conn.interface i-ovs-iface0 con-name c-ovs-iface0 autoconnect no conn.master i-ovs-port0   ovs-interface.type internal ipv4.method disabled ipv6.method disabled"

    * Finish "python3 tmp/ovs-external-ids.py set id c-ovs-br0 br0-key0 br0-val0 br0-key1 br0-val1"
    Then "br0-key0.*br0-val0.*br0-key1.*br0-val1" is visible with command "python3 tmp/ovs-external-ids.py get id c-ovs-br0"
    * Finish "python3 tmp/ovs-external-ids.py set id c-ovs-port0 port0-key0 port0-val0"
    Then "port0-key0.*port0-val0" is visible with command "python3 tmp/ovs-external-ids.py get id c-ovs-port0"
    * Finish "python3 tmp/ovs-external-ids.py set id c-ovs-iface0 iface0-key0 iface0-val0 iface0-key1 iface0-val1 iface0-key2 iface0-val2"
    Then "iface0-key0.*iface0-val0.*iface0-key1.*iface0-val1.*iface0-key2.*iface0-val2" is visible with command "python3 tmp/ovs-external-ids.py get id c-ovs-iface0"

    * Bring "up" connection "c-ovs-iface0"
    * Finish "tmp/ovs-assert-external-ids.py Bridge    i-ovs-br0    NM.connection.uuid ~. br0-key0 br0-val0 br0-key1 br0-val1"
    * Finish "tmp/ovs-assert-external-ids.py Port      i-ovs-port0  NM.connection.uuid ~. port0-key0 port0-val0"
    * Finish "tmp/ovs-assert-external-ids.py Interface i-ovs-iface0 NM.connection.uuid ~. iface0-key0 iface0-val0 iface0-key1 iface0-val1 iface0-key2 iface0-val2"

    * Finish "python3 tmp/ovs-external-ids.py apply iface i-ovs-port0 -port0-key0 port0-key3 port0-val3"
    * Finish "tmp/ovs-assert-external-ids.py Port i-ovs-port0 NM.connection.uuid ~. port0-key3 port0-val3"

    * Finish "ovs-vsctl set Bridge i-ovs-br0 external-ids:foo=boo"
    * Finish "tmp/ovs-assert-external-ids.py Bridge i-ovs-br0 NM.connection.uuid ~. br0-key0 br0-val0 br0-key1 br0-val1 foo boo"
    * Finish "python3 tmp/ovs-external-ids.py apply iface i-ovs-br0 -br0-key0 br0-key3 br0-val3"
    * Finish "tmp/ovs-assert-external-ids.py Bridge i-ovs-br0 NM.connection.uuid ~. br0-key1 br0-val1 br0-key3 br0-val3 foo boo"
