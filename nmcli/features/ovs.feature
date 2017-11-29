@testplan
Feature: nmcli - ovs

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    Background:
    * Execute "modprobe openvswitch"
    * "openvswitch" is visible with command "lsmod"
    * Execute "yum -y install openvswitch"
    * Execute "systemctl restart openvswitch"

    @ver+=1.10
    @openvswitch
    @openvswitch_interface_recognized
    Scenario: nmcli - ethernet - openvswitch interface recognized
    * Execute "ovs-vsctl add-br ovsbr0"
    * "ovsbr0" is visible with command "ip a"
    Then "ovsbr0\s+openvswitch\s+unmanaged" is visible with command "nmcli device"


    @ver+=1.10
    @ethernet
    @openvswitch
    @openvswitch_ignore_ovs_network_setup
    Scenario: nmcli - ethernet - openvswitch ignore ovs network setup
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name eth1 autoconnect no"
    * Check ifcfg-name file created for connection "eth1"
    * Execute "mv -f /tmp/eth1tmp /etc/sysconfig/network-scripts/ifcfg-eth1"
    * Execute "echo -e 'DEVICE=eth1\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSPort\nOVS_BRIDGE=ovsbridge0\nBOOTPROTO=none\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-eth1"
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Restart NM
    * Execute "ifup eth1"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a s ovsbridge0"
    Then "ovs-system" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "eth1\s+ethernet\s+disconnected" is visible with command "nmcli device"
    Then "eth1\s+ovs-port\s+unmanaged" is visible with command "nmcli device"


    @ver+=1.10
    @ethernet
    @openvswitch
    @openvswitch_ignore_ovs_vlan_network_setup
    Scenario: nmcli - ethernet - openvswitch ignore ovs network setup
    * Execute "echo -e 'DEVICE=intbr0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSIntPort\nOVS_BRIDGE=ovsbridge0\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-intbr0"
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Restart NM
    * Execute "ifup intbr0"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a"
    Then "intbr0" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "intbr0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"

    @ver+=1.10
    @ethernet
    @openvswitch
    @openvswitch_ignore_ovs_bond_network_setup
    Scenario: nmcli - ethernet - openvswitch ignore ovs network setup
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name eth1 autoconnect no"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name eth2 autoconnect no"
    * Execute """echo -e 'DEVICE=bond0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBond\nOVS_BRIDGE=ovsbridge0\nBOOTPROTO=none\nBOND_IFACES="eth1 eth2"\nOVS_OPTIONS="bond_mode=balance-tcp lacp=active"\nHOTPLUG=no' >> /etc/sysconfig/network-scripts/ifcfg-bond0"""
    * Execute "echo -e 'DEVICE=ovsbridge0\nONBOOT=yes\nDEVICETYPE=ovs\nTYPE=OVSBridge\nBOOTPROTO=static\nIPADDR=192.168.14.5\nNETMASK=255.255.255.0\nHOTPLUG=no' > /etc/sysconfig/network-scripts/ifcfg-ovsbridge0"
    * Restart NM
    * Execute "ifup bond0"
    * Execute "ifup ovsbridge0"
    Then "ovsbridge0" is visible with command "ip a"
    Then "inet 192.168.14.5" is visible with command "ip a"
    #VVV  Should this be visible???
    #Then "bond0" is visible with command "ip a"
    Then "ovsbridge0\s+ovs-bridge\s+unmanaged" is visible with command "nmcli device"
    Then "bond0\s+ovs-port\s+unmanaged" is visible with command "nmcli device"
