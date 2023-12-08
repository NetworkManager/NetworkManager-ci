Feature: nmcli - hsr


    @rhelver+=9 @fedoraver+=32
    @ver+=1.45.6
    @hsr_with_prp_protocol
    Scenario: NM - hsr - PRP protocol enabled
    * Add "ethernet" connection named "port1" for device "eth1" with options
	"""
	ethernet.cloned-mac-address 70:FF:76:1C:0E:8D
	ipv4.method disabled
	ipv6.method disabled
	"""
    * Add "ethernet" connection named "port2" for device "eth2" with options
	"""
	ethernet.cloned-mac-address 70:FF:76:1C:0E:8D
	ipv4.method disabled
	ipv6.method disabled
	"""
    * Add "hsr" connection named "prp0" for device "prp0" with options
    """
    hsr.port1 eth1
    hsr.port2 eth2
    hsr.prp yes
    ipv4.method manual
    ipv4.addresses 192.168.2.10
    """
    Then "192.168.2.10" is visible with command "ip a show prp0"
    Then "slave1 eth1 slave2 eth2" is visible with command "ip -d link show prp0"
    Then "proto 1" is visible with command "ip -d link show prp0"
