Feature: nmcli - hsr


    @rhelver+=9 @fedoraver+=32
    @ver+=1.45.6
    @ver/rhel/9/4+=1.45.9.1
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


    # We are using the newest ip command but we still need some kernel changes
    # that are present in 6.18 and will be backported to CentOS Streams.
    @rhelver+=10 @fedoraver+=44
    @ver+=1.55.5
    @hsr_interlink
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
    * Add "ethernet" connection named "interlink" for device "eth3" with options
        """
        ipv4.method disabled
        ipv6.method disabled
        """
    * Add "hsr" connection named "prp0*" for device "prp0" with options
        """
        hsr.port1 eth1
        hsr.port2 eth2
        hsr.interlink eth3
        ipv4.method manual
        ipv4.addresses 192.168.2.10
        """
    Then "192.168.2.10" is visible with command "contrib/ip_hsr/ip a show prp0"
    Then "slave1 eth1 slave2 eth2 interlink eth3" is visible with command "contrib/ip_hsr/ip -d link show prp0"


    @rhelver+=10 @fedoraver+=44
    @ver+=1.55.5
    @hsr_proto_version
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
    * Add "hsr" connection named "prp0*" for device "prp0" with options
        """
        hsr.port1 eth1
        hsr.port2 eth2
        hsr.protocol-version 1
        ipv4.method manual
        ipv4.addresses 192.168.2.10
        """
    Then "192.168.2.10" is visible with command "contrib/ip_hsr/ip a show prp0"
    Then "slave1 eth1 slave2 eth2" is visible with command "contrib/ip_hsr/ip -d link show prp0"
    Then "version 1" is visible with command "contrib/ip_hsr/ip -d link show prp0"
    * Commentary
        """
        Modify protocol to the newer version 2012+ (aka 1)
        Kernel doesn't support change so we need to do full down/up
        """
    * Modify connection "prp0*" changing options "hsr.protocol-version 0"
    * Bring "down" connection "prp0*"
    * Bring "up" connection "prp0*"
    Then "192.168.2.10" is visible with command "contrib/ip_hsr/ip a show prp0"
    Then "slave1 eth1 slave2 eth2" is visible with command "contrib/ip_hsr/ip -d link show prp0"
    Then "version 0" is visible with command "contrib/ip_hsr/ip -d link show prp0"
