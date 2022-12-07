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
    * Cleanup connection "ovsbridge0"
    * Add "ethernet" connection named "eth1" for device "eth1" with options "autoconnect no"
    * Check ifcfg-name file created for connection "eth1"
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
    * Cleanup connection "intbr0" and device "intbr0"
    * Cleanup connection "ovsbridge0" and device "ovsbridge0"
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
    * Cleanup connection "bond0" and device "bond0"
    * Cleanup connection "ovsbridge0" and device "ovsbridge0"
    * Add "ethernet" connection named "eth1" for device "eth1" with options "autoconnect no"
    * Add "ethernet" connection named "eth2" for device "eth2" with options "autoconnect no"
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


    @rhbz1540218 @rhbz1519176
    @ver+=1.16.2
    @openvswitch
    @nmcli_add_basic_openvswitch_configuration
    Scenario: nmcli - openvswitch - add basic setup
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge0"
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master port1
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port1[\"]?\s+Interface [\"]?eth2[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz2049103
    @ver+=1.41.1
    @openvswitch
    @nmcli_add_openvswitch_ofport_request
    Scenario: nmcli - openvswitch - add ofport request
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge0"
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master port1
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0 ovs-interface.ofport-request 10"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port1[\"]?\s+Interface [\"]?eth2[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "ofport_request\s+: 10" is visible with command "ovs-vsctl list interface"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port1[\"]?\s+Interface [\"]?eth2[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "ofport_request\s+: 10" is visible with command "ovs-vsctl list interface"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_add_openvswitch_bond_configuration
    Scenario: nmcli - openvswitch - add bond setup
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options "conn.master ovsbridge0"
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_add_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - add vlan setup
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_remove_one_openvswitch_bond_configuration
    Scenario: nmcli - openvswitch - remove bond slave connection
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-eth2"
    Then "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_remove_openvswitch_ports_and_master_bridge_configuration
    Scenario: nmcli - openvswitch - remove ports and master bridge connections
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Delete connection "ovs-port0"
    * Delete connection "ovs-bond0"
    When "bond0" is not visible with command "ovs-vsctl show"
     And "port0" is not visible with command "ovs-vsctl show"
    * Delete connection "ovs-bridge0"
    Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     And "ovs" is not visible with command "nmcli device"


    #@rhbz1540218
    #@ver+=1.10 @ver-1.16
    #@openvswitch
    #@nmcli_remove_openvswitch_master_bridge_configuration_only
    #Scenario: nmcli - openvswitch - remove master bridge connection
    #* Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    #* Add "ovs-port" connection named "ovs-port0" for device "port0" with options
    #   """
    #   conn.master ovsbridge0
    #    ovs-port.tag
    #   120"
    #
    #    #*
    #   Add
    #   """
    #* Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
    #   """
    #   conn.master ovsbridge0
    #   ovs-port.tag 120
    #   """
    #* Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
    #   """
    #   conn.master bond0
    #   slave-type ovs-port
    #   """
    #* Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
    #   """
    #   conn.master bond0
    #   slave-type ovs-port
    #   """
    #* Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    #When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    #* Delete connection "ovs-bridge0"
    #Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
    # And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
    # And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
    # And "master ovs-system" is not visible with command "ip a s eth2"
    # And "master ovs-system" is not visible with command "ip a s eth3"
    # And "192.168.10[0-3].*\/2[2-4]" is not visible with command "ip a s iface0"
    # And "fe80::" is not visible with command "ip a s iface0"
    # And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
    # #And "ovs" is not visible with command "nmcli device"


    #@rhbz1540218
    #@ver+=1.16.2
    #@openvswitch
    #@nmcli_remove_openvswitch_master_bridge_configuration_only
    #Scenario: nmcli - openvswitch - remove master bridge connection
    #* Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    #* Add "ovs-port" connection named "ovs-port0" for device "port0" with options
    #   """
    #   conn.master ovsbridge0
    #   ovs-port.tag 120
    #   """
    #* Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
    #   """
    #   conn.master ovsbridge0
    #   ovs-port.tag 120
    #   """
    #* Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
    #   """
    #   conn.master bond0
    #   slave-type ovs-port
    #   """
    #* Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
    #   """
    #   conn.master bond0
    #   slave-type ovs-port
    #   """
    #* Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    #When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    #* Delete connection "ovs-bridge0"
    #Then "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
    # And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth3[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
    # And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
    # And "master ovs-system" is not visible with command "ip a s eth2"
    # And "master ovs-system" is not visible with command "ip a s eth3"
    # And "192.168.10[0-3].*\/2[2-4]" is not visible with command "ip a s iface0"
    # And "fe80::" is not visible with command "ip a s iface0"
    # And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
    # And "ovs" is not visible with command "nmcli device"


    @rhbz1540218
    @ver+=1.10
    @ver-1.18
    @openvswitch
    @nmcli_reconnect_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - reconnect all connections
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options "conn.master port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    # VVV Reconnect master bridge connection
    # * Bring "up" connection "ovs-bridge0"
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    #  And "Bridge [\"]?bridge0[\"]?" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    #  And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    #  And "master ovs-system" is visible with command "ip a s eth2"
    #  And "master ovs-system" is visible with command "ip a s eth3"
    #  And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
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
    #  And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
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
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
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
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
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
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218 @rhbz1543557
    @ver+=1.18
    @openvswitch
    @nmcli_reconnect_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - reconnect all connections
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    # VVV Reconnect master bridge connection
    * Bring "up" connection "ovs-bridge0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    # VVV Reconnect port connection
    * Bring "up" connection "ovs-port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    # VVV Reconnect bond master connection
    * Bring "up" connection "ovs-bond0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    # VVV Reconnect bond slave connection
    * Bring "up" connection "ovs-eth3"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    # VVV Reconnect iface connection
    * Bring "down" connection "ovs-iface0"
    * Bring "up" connection "ovs-iface0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0" in "45" seconds
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218 @rhbz1734032 @rhbz2022275
    @ver+=1.18.8 @ver-1.41.6
    @openvswitch @restart_if_needed
    @NM_reboot_openvswitch_vlan_configuration
    Scenario: NM - openvswitch - reboot
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          """
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
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"


    @rhbz1540218 @rhbz1734032 @rhbz2022275 @rhbz2111959
    @ver+=1.41.6
    @openvswitch @restart_if_needed
    @NM_reboot_openvswitch_vlan_configuration
    Scenario: NM - openvswitch - reboot
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          ovs-port.trunks 1000-1003
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          ovs-port.trunks 9,10-15
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Stop NM
    * Execute "ovs-vsctl del-br ovsbridge0"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+trunks:\s+\[9, 10, 11, 12, 13, 14, 15\]\s+Interface eth[2-3]" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+trunks:\s+\[9, 10, 11, 12, 13, 14, 15\]\s+Interface eth[2-3]\s+type: system\s+Interface eth[2-3]\s+type: system" is visible with command "ovs-vsctl show"
    And "Port port0\s+tag: 120\s+trunks:\s+\[1000, 1001, 1002, 1003\]\s+Interface iface0\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+trunks:\s+\[9, 10, 11, 12, 13, 14, 15\]\s+Interface eth[2-3]\s+type: system\s+Interface eth[2-3]\s+type: system" is visible with command "ovs-vsctl show"
    And "Port port0\s+tag: 120\s+trunks:\s+\[1000, 1001, 1002, 1003\]\s+Interface iface0\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Modify connection "ovs-bond0" changing options "ovs-port.trunks ''"
    * Modify connection "ovs-port0" changing options "ovs-port.trunks ''"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+Interface eth[2-3]\s+type: system\s+Interface eth[2-3]\s+type: system" is visible with command "ovs-vsctl show"
    And "Port port0\s+tag: 120\s+Interface iface0\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Stop NM
    * Execute "ovs-vsctl del-br ovsbridge0"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+Interface eth[2-3]\s+type: system\s+Interface eth[2-3]\s+type: system" is visible with command "ovs-vsctl show"
    And "Port port0\s+tag: 120\s+Interface iface0\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
    And "Port bond0\s+tag: 120\s+Interface eth[2-3]\s+type: system\s+Interface eth[2-3]\s+type: system" is visible with command "ovs-vsctl show"
    And "Port port0\s+tag: 120\s+Interface iface0\s+type: internal" is visible with command "ovs-vsctl show"
    And "master ovs-system" is visible with command "ip a s eth2"
    And "master ovs-system" is visible with command "ip a s eth3"
    And "192.168.10[0-3].*\/2[2-4]" is visible with command "ip a s iface0"
    And "fe80::" is visible with command "ip a s iface0"
    And "default via 192.168.100.1 dev iface0 proto dhcp( src 192.168.10[0-3].[0-9]+)? metric 800" is visible with command "ip r"



    @rhbz2029937
    @ver+=1.36.0
    @openvswitch @restart_if_needed
    @NM_reboot_openvswitch_vlan_configuration_var2
    Scenario: NM - openvswitch - reboot - var2
    * Execute "ovs-vsctl add-br ovsbr0"
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.method static ipv4.address 192.168.99.1/24
          ipv6.method static ipv6.address 2014:99::1/64
          """

    * Add "ovs-bridge" connection named "ovs-bridge1" for device "ovsbridge1"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options
          """
          conn.master ovsbridge1
          ovs-port.tag 110
          """
    * Add "ovs-interface" connection named "ovs-iface1" for device "iface1" with options
          """
          conn.master port1
          ipv4.method static ipv4.address 192.168.99.2/24
          ipv6.method static ipv6.address 2014:99::2/64
          """
    * Reboot
    When "ovsbr0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge1" is visible with command "ovs-vsctl show" in "5" seconds
    * Reboot
    When "ovsbr0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge1" is visible with command "ovs-vsctl show" in "5" seconds
    * Reboot
    When "ovsbr0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge1" is visible with command "ovs-vsctl show" in "5" seconds
    * Reboot
    When "ovsbr0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge1" is visible with command "ovs-vsctl show" in "5" seconds
    * Reboot
    When "ovsbr0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge0" is visible with command "ovs-vsctl show" in "5" seconds
    When "ovsbridge1" is visible with command "ovs-vsctl show" in "5" seconds


    @rhbz1740557 @rhbz1852612 @rhbz1855563
    @ver+=1.18.8 @ver-=1.25
    @permissive @openvswitch @disp
    @ovs_cloned_mac_set_on_iface
    Scenario: nmcli - openvswitch - mac address set iface
    * Write dispatcher "pre-down.d/97-disp" file with params "sleep 1"
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          802-3-ethernet.cloned-mac-address
          00:11:22:33:44:55"
                    *
          Add
          """
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


    @rhbz1740557 @rhbz1852612 @rhbz1855563 @rhbz1868176
    @ver+=1.26
    @rhelver+=8
    @permissive @openvswitch @disp
    @ovs_cloned_mac_set_on_iface
    Scenario: nmcli - openvswitch - mac address set iface
    * Write dispatcher "pre-down.d/97-disp" file with params "sleep 1"
    * Prepare simulated test "testX" device with "192.168.97" ipv4 and daemon options "--dhcp-host=00:11:22:33:45:67,192.168.97.13,foobar"
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge0"
    * Add "ethernet" connection named "ovs-testX" for device "testX" with options
          """
          conn.master port0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port1
          ipv4.may-fail no
          802-3-ethernet.cloned-mac-address 00:11:22:33:45:67
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "192.168.97.13/24" is visible with command "ip a s iface0"
    When "00:11:22:33:45:67" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:45:67" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "192.168.97.13/24" is visible with command "ip a s iface0"
    When "00:11:22:33:45:67" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:45:67" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"
    # No sleep 2 as a reproducer of 1855563
    * Execute "nmcli networking off && nmcli networking on"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "192.168.97.13/24" is visible with command "ip a s iface0"
    When "00:11:22:33:45:67" is visible with command "ip a s iface0"
    When "GENERAL.HWADDR:\s+00:11:22:33:45:67" is visible with command "nmcli dev show iface0"
    When  "mac\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"
    When  "mac_in_use\s+: "00:11:22:33:45:67"" is visible with command "sudo ovs-vsctl list interface"


    @rhbz1786937
    @ver+=1.18.8
    @openvswitch @mtu @restart_if_needed
    @ovs_mtu
    Scenario: nmcli - openvswitch - mtu
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options "ethernet.mtu 9000"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          ethernet.mtu 9000
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          ethernet.mtu 9000
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          802-3-ethernet.cloned-mac-address 00:11:22:33:44:55
          ethernet.mtu 9000
          """
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
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
          """
          802-3-ethernet.cloned-mac-address 00:11:22:33:44:55
          """
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "ovsbridge0" with options
          """
          conn.master port0
          ipv4.may-fail no
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "00:11:22:33:44:55" is visible with command "ip a s ovsbridge0"


    @rhbz1676551
    @ver+=1.12
    @rhelver-=7 @fedoraver-=0
    @openvswitch @restart_if_needed
    @restart_NM_with_mixed_setup
    Scenario: NM -  openvswitch - restart NM when OVS is unmanaged
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ipv4.method manual
          ipv4.addresses 10.0.0.2/16
          ipv4.gateway 10.0.0.1
          """
    * Add "vlan" connection named "vlan1" with options
          """
          dev nm-bond
          id 101
          ipv6.method ignore
          ipv4.method manual
          ipv4.method manual
          ipv4.addresses 10.200.208.98/16
          ipv4.routes
          224.0.0.0/4"
          """
    * Add "vlan" connection named "vlan2" with options
          """
          dev nm-bond
          id 201
          ipv6.method ignore
          ipv4.method manual
          ipv4.addresses 10.201.0.13/24
          ipv4.gateway 10.201.0.1
          """
    * Add "ethernet" connection named "bond0.0" for device "eth2" with options "master nm-bond"
    * Add "ethernet" connection named "bond0.1" for device "eth3" with options "master nm-bond"
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
     * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
           """
           ovs-bridge.datapath-type netdev
           """
     * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
     * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
           """
           conn.master port0
           ovs-dpdk.devargs 0000:42:10.0
           """
     Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge ovsbridge0" is visible with command "ovs-vsctl show"
     And "Port port0" is visible with command "ovs-vsctl show"
     And "Port port0\s+Interface\s+iface0\s+type: dpdk\s+options: {dpdk-devargs=0000:42:10.0}" is visible with command "ovs-vsctl show"


     @rhbz2001563
     @ver+=1.35.4
     @openvswitch @dpdk
     @add_dpdk_port_n_rxq
     Scenario: NM -  openvswitch - add dpdk device and n_rxq argument
     * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
           """
           ovs-bridge.datapath-type netdev
           """
     * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
     * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
           """
           conn.master port0
           ovs-dpdk.devargs 0000:42:10.0
           ovs-dpdk.n-rxq 2
           """
     Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
     And "Bridge [\"]?ovsbridge0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?port0[\"]?\s+Interface\s+[\"]?iface0[\"]?\s+type: dpdk\s+options: {dpdk-devargs=[\"]?0000:42:10.0[\"]?, n_rxq=[\"]?2[\"]?}" is visible with command "ovs-vsctl show"


    @rhbz1676551 @rhbz1612503
    @ver+=1.19.5
    @openvswitch @dpdk
    @add_dpdk_bond_sriov
    Scenario: NM -  openvswitch - add dpdk device
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
          """
          ovs-bridge.datapath-type netdev
          """
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ovs-dpdk.devargs 0000:42:10.0
          """
    * Add "ovs-interface" connection named "ovs-iface1" for device "iface1" with options
          """
          conn.master bond0
          ovs-dpdk.devargs 0000:42:10.2
          """
    * Add "ethernet" connection named "ovs-eth3" for device "em1" with options "conn.master bond0 slave-type ovs-port"
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
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ethernet" connection named "eth2" for device "eth2" with options "master port0 slave-type ovs-port"
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
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "conn.master ovsbridge0"
    * Add "ovs-interface" connection named "ovs-patch0" for device "patch0" with options
          """
          master port0
          ovs-interface.type patch
          ovs-patch.peer patch1
          """
    * Add "ovs-bridge" connection named "ovs-bridge1" for device "ovsbridge1"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge1"
    * Add "ovs-interface" connection named "ovs-patch1" for device "patch1" with options
          """
          master port1
          ovs-interface.type patch
          ovs-patch.peer patch0
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-patch0" in "10" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-patch1" in "10" seconds
    Then "Interface patch0\s*type: patch\s*options: \{peer\=patch1\}" is visible with command "ovs-vsctl show"
    Then "Interface patch1\s*type: patch\s*options: \{peer\=patch0\}" is visible with command "ovs-vsctl show"


    @rhbz1866227
    @ver+=1.29.1
    @openvswitch
    @ovs_external_ids
    Scenario: NM -  openvswitch - add dpdk device
    * Add "ovs-bridge" connection named "c-ovs-br0" for device "i-ovs-br0" with options "autoconnect no"
    * Add "ovs-port" connection named "c-ovs-port0" for device "i-ovs-port0" with options
          """
          autoconnect no
          conn.master i-ovs-br0
          """
    * Add "ovs-interface" connection named "c-ovs-iface0" for device "i-ovs-iface0" with options
          """
          autoconnect no
          conn.master i-ovs-port0
          ovs-interface.type internal
          ipv4.method disabled
          ipv6.method disabled
          """

    * Execute "python3 contrib/ovs/ovs-external-ids.py set id c-ovs-br0 br0-key0 br0-val0 br0-key1 br0-val1"
    Then "br0-key0.*br0-val0.*br0-key1.*br0-val1" is visible with command "python3 contrib/ovs/ovs-external-ids.py get id c-ovs-br0"
    * Execute "python3 contrib/ovs/ovs-external-ids.py set id c-ovs-port0 port0-key0 port0-val0"
    Then "port0-key0.*port0-val0" is visible with command "python3 contrib/ovs/ovs-external-ids.py get id c-ovs-port0"
    * Execute "python3 contrib/ovs/ovs-external-ids.py set id c-ovs-iface0 iface0-key0 iface0-val0 iface0-key1 iface0-val1 iface0-key2 iface0-val2"
    Then "iface0-key0.*iface0-val0.*iface0-key1.*iface0-val1.*iface0-key2.*iface0-val2" is visible with command "python3 contrib/ovs/ovs-external-ids.py get id c-ovs-iface0"

    * Bring "up" connection "c-ovs-iface0"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Bridge    i-ovs-br0    NM.connection.uuid ~. br0-key0 br0-val0 br0-key1 br0-val1"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Port      i-ovs-port0  NM.connection.uuid ~. port0-key0 port0-val0"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Interface i-ovs-iface0 NM.connection.uuid ~. iface0-key0 iface0-val0 iface0-key1 iface0-val1 iface0-key2 iface0-val2"

    * Execute "python3 contrib/ovs/ovs-external-ids.py apply iface i-ovs-port0 -port0-key0 port0-key3 port0-val3"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Port i-ovs-port0 NM.connection.uuid ~. port0-key3 port0-val3"

    * Execute "ovs-vsctl set Bridge i-ovs-br0 external-ids:foo=boo"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Bridge i-ovs-br0 NM.connection.uuid ~. br0-key0 br0-val0 br0-key1 br0-val1 foo boo"
    * Execute "python3 contrib/ovs/ovs-external-ids.py apply iface i-ovs-br0 -br0-key0 br0-key3 br0-val3"
    * Execute "contrib/ovs/ovs-assert-external-ids.py Bridge i-ovs-br0 NM.connection.uuid ~. br0-key1 br0-val1 br0-key3 br0-val3 foo boo"


    @rhbz1861296
    @ver+=1.29
    @openvswitch @restart_if_needed
    @NM_clean_during_service_start
    Scenario: NM - openvswitch - clean during service start
    * Execute "ovs-vsctl add-br ovsbr0"
    * "ovsbr0" is visible with command "ip a"
    # Save no means to have just in memory profiles
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options "save no"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          save no
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          save no
          """
    * Add "ethernet" connection named "ovs-eth2" for device "eth2" with options
          """
          conn.master bond0
          slave-type ovs-port
          save no
          """
    * Add "ethernet" connection named "ovs-eth3" for device "eth3" with options
          """
          conn.master bond0
          slave-type ovs-port
          save no
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          save no
          """
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    * Reboot
    # This bridge was created by NM and should be gone
    And "Bridge [\"]?ovsbridge0[\"]?" is not visible with command "ovs-vsctl show"
    And "Port [\"]?bond0[\"]?\s+tag: 120\s+Interface [\"]?eth[2-3][\"]?\s+type: system\s+Interface [\"]?eth[2-3][\"]?\s+type: system" is not visible with command "ovs-vsctl show"
    And "Port [\"]?port0[\"]?\s+tag: 120\s+Interface [\"]?iface0[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
    And "master ovs-system" is not visible with command "ip a s eth2"
    And "master ovs-system" is not visible with command "ip a s eth3"
    # This bridge was not created by NM and should still be here
    Then "ovsbr0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    And "ovsbr0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"
    And "ovsbr0\s+ovs-interface\s+disconnected" is visible with command "nmcli device"
    Then "Bridge [\"]?ovsbr0[\"]?" is visible with command "ovs-vsctl show"
     And "Port [\"]?ovsbr0[\"]?\s+Interface [\"]?ovsbr0[\"]?\s+type: internal" is visible with command "ovs-vsctl show"


    @rhbz1923248 @rhbz1935026
    @ver+=1.36 @rhelver+=8.6
    @openvswitch @nmstate
    @ovs_nmstate
    Scenario: NM - openvswitch - nmstate
    # There was a connection up race here, here we do create two namespace
    # environment with 5 veth pairs and two namespaces and doing bond and
    # bridge operation inside OVS on top of that via nmstate.
    # Running 3 times just to be sure.
    When Execute reproducer "repro_1923248.sh" with options "setup"
    Then "Bridge [\"]?ovs-br0[\"]?" is visible with command "ovs-vsctl show"
     And "Port .*veth0r[\"]?\s+Interface [\"]?veth0r[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port .*veth1c[\"]?\s+Interface [\"]?veth1c[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port .*ovs1[\"]?\s+Interface [\"]?ovs1[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "Port .*veth0c[\"]?\s+Interface [\"]?veth0c[\"]?\s+type: system" is visible with command "ovs-vsctl show"
    When Execute reproducer "repro_1923248.sh" with options "clean"
    Then "Bridge [\"]?ovs-br0[\"]?" is not visible with command "ovs-vsctl show"
     And "Port .*veth0r[\"]?\s+Interface [\"]?veth0r[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port .*veth1c[\"]?\s+Interface [\"]?veth1c[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port .*ovs1[\"]?\s+Interface [\"]?ovs1[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
     And "Port .*veth0c[\"]?\s+Interface [\"]?veth0c[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
    When Execute reproducer "repro_1923248.sh" with options "setup"
    Then "Bridge [\"]?ovs-br0[\"]?" is visible with command "ovs-vsctl show"
     And "Port .*veth0r[\"]?\s+Interface [\"]?veth0r[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port .*veth1c[\"]?\s+Interface [\"]?veth1c[\"]?\s+type: system" is visible with command "ovs-vsctl show"
     And "Port .*ovs1[\"]?\s+Interface [\"]?ovs1[\"]?\s+type: internal" is visible with command "ovs-vsctl show"
     And "Port .*veth0c[\"]?\s+Interface [\"]?veth0c[\"]?\s+type: system" is visible with command "ovs-vsctl show"
    When Execute reproducer "repro_1923248.sh" with options "clean"
    Then "Bridge [\"]?ovs-br0[\"]?" is not visible with command "ovs-vsctl show"
     And "Port .*veth0r[\"]?\s+Interface [\"]?veth0r[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port .*veth1c[\"]?\s+Interface [\"]?veth1c[\"]?\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port .*ovs1[\"]?\s+Interface [\"]?ovs1[\"]?\s+type: internal" is not visible with command "ovs-vsctl show"
     And "Port .*veth0c[\"]?\s+Interface [\"]?veth0c[\"]?\s+type: system" is not visible with command "ovs-vsctl show"


    @rhbz1921107
    @ver+=1.30 @ver-=1.31
    @openvswitch @firewall
    @ovs_set_firewalld_zone
    Scenario: NM -  openvswitch - set firewalld zone
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          ipv4.method manual
          ipv4.addresses 172.16.0.1/24
          connection.zone public
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    Then "success" is visible with command "firewall-cmd --reload"
    Then "running" is visible with command "firewall-cmd --state"
    Then "public" is visible with command "firewall-cmd  --get-zone-of-interface=iface0" in "3" seconds


    @rhbz1921107 @rhbz1982403
    @ver+=1.32 @ver-=1.35
    @openvswitch @firewall
    @ovs_set_firewalld_zone
    Scenario: NM -  openvswitch - set firewalld zone
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          connection.zone public
          """
    Then "success" is visible with command "firewall-cmd --reload"
    Then "running" is visible with command "firewall-cmd --state"
    Then "public" is visible with command "firewall-cmd  --get-zone-of-interface=iface0" in "3" seconds


    @rhbz2052441
    @openvswitch
    @ovs_service_disabled_error
    Scenario: NM -  openvswitch - start with disabled service
    * Execute "systemctl stop openvswitch"
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ipv4.may-fail no
          """
    Then "Error" is visible with command "nmcli con up ovs-iface0"


    @rhbz2027490 @rhbz2026024
    @ver+=1.36
    @openvswitch @firewall
    @ovs_set_firewalld_zone
    Scenario: NM -  openvswitch - set firewalld zone
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "long_port_iface_name" with options
          """
          conn.master ovsbridge0
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master long_port_iface_name
          ipv4.may-fail no
          connection.zone public
          """
    Then "success" is visible with command "firewall-cmd --reload"
    Then "running" is visible with command "firewall-cmd --state"
    Then "public" is visible with command "firewall-cmd  --get-zone-of-interface=iface0" in "3" seconds


    @rhbz2001851
    @ver+=1.36
    @ver-=1.37
    @openvswitch @restart_if_needed
    @add_dpdk_port_with_mtu
    Scenario: NM - openvswitch - add dpdk device with preset MTU
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
          """
          ovs-bridge.datapath-type netdev
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.bond-mode balance-slb
          """
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "master ovsbridge0"
    * Add "ovs-interface" connection named "ovs-port1" for device "port0" with options
          """
          slave-type ovs-port
          master ovs-port0
          802-3-ethernet.mtu 9000
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master bond0
          ovs-dpdk.devargs 000:42:10.0
          ovs-interface.type dpdk
          802-3-ethernet.mtu 9000
          """
    * Add "ovs-interface" connection named "ovs-iface1" for device "iface1" with options
          """
          conn.master bond0
          ovs-dpdk.devargs 000:42:10.2
          ovs-interface.type dpdk
          802-3-ethernet.mtu 9000
          """
    Then "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface0"
    And "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface1"
    And "mtu 9000" is visible with command "ip a s dev port0"
    * Reboot
    Then "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface0"
    And "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface1"
    And "mtu 9000" is visible with command "ip a s dev port0"



    @rhbz2001851 @rhbz2001792
    @ver+=1.38
    @openvswitch @restart_if_needed
    @add_dpdk_port_with_mtu
    Scenario: NM - openvswitch - add dpdk device with preset MTU
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0" with options
          """
          ovs-bridge.datapath-type netdev
          """
    * Add "ovs-port" connection named "ovs-bond0" for device "bond0" with options
          """
          conn.master ovsbridge0
          ovs-port.bond-mode balance-slb
          """
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options "master ovsbridge0"
    * Add "ovs-interface" connection named "ovs-port1" for device "port0" with options
          """
          slave-type ovs-port
          master ovs-port0
          802-3-ethernet.mtu 9000
          ipv4.method static
          ipv4.address 192.168.123.100/24
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master bond0
          ovs-dpdk.devargs 000:42:10.0
          ovs-interface.type dpdk
          802-3-ethernet.mtu 9000
          """
    * Add "ovs-interface" connection named "ovs-iface1" for device "iface1" with options
          """
          conn.master bond0
          ovs-dpdk.devargs 000:42:10.2
          ovs-interface.type dpdk
          802-3-ethernet.mtu 9000
          """
    When "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface0"
    Then "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface1"
    And "mtu 9000" is visible with command "ip a s dev port0"
    And "192.168.123.100/24" is visible with command "ip a s dev port0"
    * Reboot
    When "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface0"
    Then "9000" is visible with command "nmcli -g 802-3-ethernet.mtu c show ovs-iface1"
    And "mtu 9000" is visible with command "ip a s dev port0"
    And "192.168.123.100/24" is visible with command "ip a s dev port0"


    @rhbz2077950
    @ver+=1.39.11
    @openvswitch @remove_custom_cfg @restart_if_needed
    @ovs_external_unmanaged_device
    Scenario: NM - openvswitch - ovs external device stays unmanaged
    * Cleanup device "ovs-int0"
    * Append lines to file "/etc/NetworkManager/conf.d/99-xxcustom.conf"
      """
      [device-unmanaged]
      match-device=interface-name:ovs-int0
      managed=no
      """
    * Restart NM
    * Execute "ovs-vsctl add-br ovs-br0"
    * Execute "ovs-vsctl add-port ovs-br0 ovs-int0 -- set interface ovs-int0 type=patch -- set interface ovs-int0 options:peer=ovs-br0"
    Then "unmanaged" is visible with command "nmcli device | grep ovs-int0" in "10" seconds
