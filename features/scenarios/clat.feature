Feature: nmcli: clat

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)

    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_ethernet
    Scenario: nmcli - clat - CLAT on Ethernet interface with the well-known prefix
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96"
    * Start servers in the CLAT environment for device "testX"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    * Verify the CLAT connection over device "testX"
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_ethernet_plen64
    Scenario: nmcli - clat - CLAT on Ethernet interface with a /64 NAT64 prefix
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "2001:db8:122:344::/64"
    * Start servers in the CLAT environment for device "testX"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    * Verify the CLAT connection over device "testX"
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_vlan
    Scenario: nmcli - clat - CLAT on VLAN interface
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "2001:db8:122:300::/56" over VLAN "42"
    * Start servers in the CLAT environment for device "testX"
    * Add "ethernet" connection named "testX-base" for device "testX" with options
          """
          ipv4.method disabled
          ipv6.method disabled
          autoconnect no
          """
    * Add "vlan" connection named "testX-vlan-clat" for device "testX.42" with options
          """
          vlan.parent testX
          vlan.id 42
          ipv4.clat auto
          autoconnect no
          """
    * Bring "up" connection "testX-base"
    * Bring "up" connection "testX-vlan-clat"
    * Verify the CLAT connection over device "testX.42"
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_multiple_instances
    Scenario: nmcli - clat - CLAT on multiple interfaces
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "2001:db8::/32" and IPv6 prefix "2002:aaaa::"
    * Prepare a CLAT environment on device "testY" with NAT64 prefix "2001:db9:100::/40" and IPv6 prefix "2002:bbbb::"
    * Prepare a CLAT environment on device "testZ" with NAT64 prefix "2001:dba:111::/48" and IPv6 prefix "2002:cccc::"
    * Start servers in the CLAT environment for device "testX" on address "203.0.113.1"
    * Start servers in the CLAT environment for device "testY" on address "203.0.113.2"
    * Start servers in the CLAT environment for device "testZ" on address "203.0.113.3"
    # the default route is on testX. With rp_filter enabled, it would be impossible to check
    # connectivity on other interfaces
    * Execute "echo 2 > /proc/sys/net/ipv4/conf/testY/rp_filter"
    * Execute "echo 2 > /proc/sys/net/ipv4/conf/testZ/rp_filter"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Add "ethernet" connection named "testY-clat" for device "testY" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Add "ethernet" connection named "testZ-clat" for device "testZ" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    * Bring "up" connection "testY-clat"
    * Bring "up" connection "testZ-clat"
    * Verify the CLAT connection over device "testX"
    * Verify the CLAT connection over non-default device "testY" with CLAT address "192.0.0.6" and server "203.0.113.2"
    * Verify the CLAT connection over non-default device "testZ" with CLAT address "192.0.0.7" and server "203.0.113.3"
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_disabled
    Scenario: nmcli - clat - CLAT disabled in the connection
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96" and IPv6 prefix "2002:aaaa::"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat no
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    Then Check "ipv4" address list "/172.25.42.[0-9]+/24$" on device "testX" in "10" seconds
    Then Check "ipv6" address list "/2002:aaaa::[0-9a-f:]+/64 /fe80::[0-9a-f:]+/64" on device "testX" in "10" seconds
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_auto_no_opt108
    Scenario: nmcli - clat - CLAT without option 108
    # The network provides a NAT64 prefix, but the DHCPv4 server doesn't send option 108.
    # NM has CLAT "auto", and it should be stay disabled since there is native IPv4 connectivity.
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96" and option 108 "off"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat auto
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    Then Check "ipv4" address list "/172.25.42.[0-9]+/24$" on device "testX" in "10" seconds
    Then Check "ipv6" address list "/2002:aaaa::[0-9a-f:]+/64 /fe80::[0-9a-f:]+/64" on device "testX" in "10" seconds
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_auto_ipv4_manual
    Scenario: nmcli - clat - CLAT with IPv4 manual configuration
    # NM has CLAT "auto", and it should stay disabled since there is native IPv4 connectivity
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat force
          ipv4.method manual
          ipv4.addresses 172.25.42.113/24
          ipv4.gateway 172.25.42.1
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    Then Check "ipv4" address list "172.25.42.113/24" on device "testX" in "10" seconds
    Then Check "ipv6" address list "/2002:aaaa::[0-9a-f:]+/64 /fe80::[0-9a-f:]+/64" on device "testX" in "10" seconds
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_mtu_ra
    Scenario: nmcli - clat - CLAT with custom MTU from RA
    # The IPv4 default route MTU should be the IPv6 MTU advertised by the router minus 28
    # (due to the conversion of the IPv4 header into IPv6)
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96" and IPv6 MTU "1300"
    * Start servers in the CLAT environment for device "testX"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat force
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    Then "mtu 1272" is visible with command "ip -4 route list default dev testX"
    * Verify the CLAT connection over device "testX"
    * Ignore possible AVC "bpf"


    @ver+=1.57.1
    @rhelver+=10
    @permissive
    @delete_testeth0
    @clat_mtu_static
    Scenario: nmcli - clat - CLAT with custom MTU
    # The IPv4 default route MTU should be the static IPv6 MTU from the connection minus 28
    # (due to the conversion of the IPv4 header into IPv6)
    * Prepare a CLAT environment on device "testX" with NAT64 prefix "64:ff9b::/96"
    * Start servers in the CLAT environment for device "testX"
    * Add "ethernet" connection named "testX-clat" for device "testX" with options
          """
          ipv4.clat force
          ipv6.mtu 1430
          autoconnect no
          """
    * Bring "up" connection "testX-clat"
    Then "mtu 1402" is visible with command "ip -4 route list default dev testX"
    * Verify the CLAT connection over device "testX"
    * Ignore possible AVC "bpf"
