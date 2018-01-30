@testplan
Feature: nmcli - ovs

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

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
    @ver+=1.10
    @openvswitch
    @nmcli_add_basic_openvswitch_configuration
    Scenario: nmcli - openvswitch - add basic setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface port1 conn.master bridge0 con-name ovs-port0"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master port1 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    Then "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"port1\"\s+Interface \"eth2\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_add_openvswitch_bond_configuration
    Scenario: nmcli - openvswitch - add bond setup
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    Then "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
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
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    Then "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
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
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    * Delete connection "ovs-eth2"
    Then "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth3"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
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
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    * Delete connection "ovs-port0"
    * Delete connection "ovs-bond0"
    When "bond0" is not visible with command "ovs-vsctl show"
     And "port0" is not visible with command "ovs-vsctl show"
    * Delete connection "ovs-bridge0"
    Then "Bridge \"bridge0\"" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.100.*\/24" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     And "ovs" is not visible with comand "nmcli device"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_remove_openvswitch_master_bridge_configuration_only
    Scenario: nmcli - openvswitch - remove master bridge connection
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    * Delete connection "ovs-bridge0"
    Then "Bridge \"bridge0\"" is not visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth3"\s+type: system" is not visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is not visible with command "ovs-vsctl show"
     And "master ovs-system" is not visible with command "ip a s eth2"
     And "master ovs-system" is not visible with command "ip a s eth3"
     And "192.168.100.*\/24" is not visible with command "ip a s iface0"
     And "fe80::" is not visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is not visible with command "ip r"
     And "ovs" is not visible with comand "nmcli device"


    @rhbz1540218
    @ver+=1.10
    @openvswitch
    @nmcli_reconnect_openvswitch_vlan_configuration
    Scenario: nmcli - openvswitch - reconnect all connections
    * Add a new connection of type "ovs-bridge" and options "conn.interface bridge0 con-name ovs-bridge0"
    * Add a new connection of type "ovs-port" and options "conn.interface port0 conn.master bridge0 con-name ovs-port0 ovs-port.tag 120"
    * Add a new connection of type "ovs-port" and options "conn.interface bond0 conn.master bridge0 con-name ovs-bond0 ovs-port.tag 120"
    * Add a new connection of type "ethernet" and options "conn.interface eth2 conn.master bond0 slave-type ovs-port con-name ovs-eth2"
    * Add a new connection of type "ethernet" and options "conn.interface eth3 conn.master bond0 slave-type ovs-port con-name ovs-eth3"
    * Add a new connection of type "ovs-interface" and options "conn.interface iface0 conn.master port0 con-name ovs-iface0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
    # VVV Reconnect master bridge connection
    * Bring "up" connection "ovs-bridge0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
     And "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1rhbz1540218 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect port connection
    * Bring "up" connection "ovs-port0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
     And "Bridge \"bridge0\"" is virhbz1540218sible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond master connection
    * Bring "up" connection "ovs-bond0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
     And "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect bond slave connection
    * Bring "up" connection "ovs-eth3"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
     And "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
    # VVV Reconnect iface connection
    * Bring "up" connection "ovs-iface0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "20" seconds
     And "Bridge \"bridge0\"" is visible with command "ovs-vsctl show"
     And "Port \"bond0\"\s+tag: 120\s+Interface \"eth[2-3]\"\s+type: system\s+Interface \"eth[2-3]\"\s+type: system" is visible with command "ovs-vsctl show"
     And "Port \"port0\"\s+tag: 120\s+Interface \"iface0\"\s+type: internal" is visible with command "ovs-vsctl show"
     And "master ovs-system" is visible with command "ip a s eth2"
     And "master ovs-system" is visible with command "ip a s eth3"
     And "192.168.100.*\/24" is visible with command "ip a s iface0"
     And "fe80::" is visible with command "ip a s iface0"
     And "default via 192.168.100.1 dev iface0 proto dhcp metric 800" is visible with command "ip r"
