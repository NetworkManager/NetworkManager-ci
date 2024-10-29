    Feature: nmcli: ipv6

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver-1.45.10
    @ipv6_method_static_without_IP
    Scenario: nmcli - ipv6 - method - static without IP
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "autoconnect no"
      * Open editor for connection "con_ipv6"
      * Submit "set ipv6.method static" in editor
      * Save in editor
    Then Error type "ipv6.addresses: this property cannot be empty for" while saving in editor


    @ipv6_method_manual_with_IP
    Scenario: nmcli - ipv6 - method - manual + IP
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.addresses '2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b'
          """
    Then "2607:f0d0:1002:51::4/64" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/128" is visible with command "ip a s eth3"


    @ipv6_method_static_with_IP
    Scenario: nmcli - ipv6 - method - static + IP
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method static
          ipv6.addresses '2607:f0d0:1002:51::4/128, 1050:0:0:0:5:600:300c:326b'
          """
    Then "2607:f0d0:1002:51::4/128" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/128" is visible with command "ip a s eth3"


    @ipv6_addresses_IP_with_netmask
    Scenario: nmcli - ipv6 - addresses - IP slash netmask
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.addresses '2607:f0d0:1002:51::4/63, 1050:0:0:0:5:600:300c:326b/121'
          """
    Then "2607:f0d0:1002:51::4/63" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/121" is visible with command "ip a s eth3"
    # reproducer for 997759
    Then "IPV6_DEFAULTGW" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv6"


    @ipv6_addresses_yes_when_static_switch_asked
    Scenario: nmcli - ipv6 - addresses - IP and yes to manual question
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.addresses dead:beaf::1" in editor
     * Submit "yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     Then "inet6 dead:beaf" is visible with command "ip a s eth10" in "45" seconds
     Then "inet6 2620" is not visible with command "ip a s eth10" in "45" seconds


    @ipv6_addresses_no_when_static_switch_asked
    Scenario: nmcli - ipv6 - addresses - IP and no to manual question
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.addresses dead:beaf::1" in editor
     * Submit "no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     Then "inet6 dead:beaf" is visible with command "ip a s eth10" in "45" seconds
     Then "inet6 2620" is visible with command "ip a s eth10" in "45" seconds


    @eth0
    @ipv6_addresses_invalid_netmask
    Scenario: nmcli - ipv6 - addresses - IP slash invalid netmask
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4/321" in editor
    Then Error type "failed to set 'addresses' property: invalid prefix '321'; <[01]-128> allowed" while saving in editor


    @eth0
    @ipv6_addresses_IP_with_mask_and_gw
    Scenario: nmcli - ipv6 - addresses - IP slash netmask and gw
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv4.method disabled
           ipv6.method static
           ipv6.addresses 2607:f0d0:1002:51::4/64
           ipv6.gateway 2607:f0d0:1002:51::1
           """
    Then "2607:f0d0:1002:51::4/64" is visible with command "ip a s eth3" in "45" seconds
    Then "default via 2607:f0d0:1002:51::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"


    @eth0
    @ipv6_addresses_set_several_IPv6s_with_masks_and_gws
    Scenario: nmcli - ipv6 - addresses - several IPs slash netmask and gw
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv4.method disabled
          ipv6.method static
          ipv6.addresses 'fc01::1:5/68, fb01::1:6/112, fc02::1:21/96'
          ipv6.gateway fc01::1:1
          """
    Then "fc02::1:21/96" is visible with command "ip a s eth3" in "45" seconds
    Then "fc01::1:5/68" is visible with command "ip a s eth3"
    Then "fb01::1:6/112" is visible with command "ip a s eth3"
    Then "default via fc01::1:1 dev eth3" is visible with command "ip -6 route"


    @ver-=1.39.2
    @ipv6_addresses_delete_IP_moving_method_back_to_auto
    Scenario: nmcli - ipv6 - addresses - delete IP and set method back to auto
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
           """
           ipv4.method disabled
           ipv6.method static
           ipv6.addresses fc01::1:5/68
           ipv6.gateway fc01::1:1
           """
     * Modify connection "con_ipv6" changing options "ipv6.addresses '' ipv6.gateway '' ipv6.method auto"
     * Bring "up" connection "con_ipv6"
    Then "fc01::1:5/68" is not visible with command "ip a s eth10" in "45" seconds
    Then "default via fc01::1:1 dev eth10" is not visible with command "ip -6 route"
    Then "2620:52:0:" is visible with command "ip a s eth10"


    @rhbz1943153
    @ver+=1.39.3
    @ipv6_addresses_delete_IP_moving_method_back_to_auto
    Scenario: nmcli - ipv6 - addresses - delete IP and set method back to auto
     * Prepare simulated test "testX6" device
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv4.method disabled
           ipv6.method static
           ipv6.addresses fc01::1:5/68
           ipv6.gateway fc01::1:1
           """
     * Modify connection "con_ipv6" changing options "ipv6.addresses '' ipv6.gateway '' ipv6.method auto"
     * Bring "up" connection "con_ipv6"
    Then "fc01::1:5/68" is not visible with command "ip a s testX6" in "45" seconds
    Then "default via fc01::1:1 dev testX6" is not visible with command "ip -6 route"
    Then "2620:dead:" is visible with command "ip a s testX6"
    Then "dhcp6.dhcp6_name_servers" is visible with command "cat /run/NetworkManager/devices/$(ip link show testX6 | cut -d ':' -f 1 | head -n 1)"
    And "dhcp6.ip6_address" is visible with command "cat /run/NetworkManager/devices/$(ip link show testX6 | cut -d ':' -f 1 | head -n 1)"


    @eth0
    @ver-=1.9.1
    @ipv6_routes_set_basic_route
    Scenario: nmcli - ipv6 - routes - set basic route
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv6.method static
           ipv6.addresses 2000::2/126
           ipv6.routes '1010::1/128 2000::1 1'
           """
     * Add "ethernet" connection named "con_ipv62" for device "eth2" with options
           """
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.routes '3030::1/128 2001::2 1'
           """
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is visible with command "ip -6 route"


    @rhbz1505893
    @eth0
    @ver+=1.9.2
    @ipv6_routes_set_basic_route
    Scenario: nmcli - ipv6 - routes - set basic route
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method static
          ipv6.addresses 2000::2/126
          ipv6.routes '1010::1/128 2000::1 1'
          """
    * Add "ethernet" connection named "con_ipv62" for device "eth2" with options
          """
          ipv6.method static
          ipv6.addresses 2001::1/126
          ipv6.routes '3030::1/128 2001::2 1'
          """
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 10" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 10" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is visible with command "ip -6 route"


    @rhbz1373698
    @ver+=1.8.0
    @ver-=1.9.1
    @ipv6_route_set_route_with_options
    Scenario: nmcli - ipv6 - routes - set route with options
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.addresses 2000::2/126
          ipv6.route-metric 258
          ipv6.routes '1010::1/128 2000::1 1024 cwnd=15 lock-mtu=true mtu=1600'
          """
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 15" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
     And "default" is visible with command "ip r |grep eth0"


    @rhbz1373698
    @ver+=1.9.2
    @ver-=1.35
    @ipv6_route_set_route_with_options
    Scenario: nmcli - ipv6 - routes - set route with options
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.addresses 2000::2/126
          ipv6.route-metric 258
          ipv6.routes '1010::1/128 2000::1 1024 cwnd=15 lock-mtu=true mtu=1600, ::/0 2001:1::1'
          """
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 15" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 258" is visible with command "ip -6 route"
    Then "2001:1::1 dev eth3\s+proto static" is visible with command "ip -6 route"
     And "default via 2001:1::1 dev eth3" is visible with command "ip -6 route"


    @rhbz1373698 @rhbz1937823 @rhbz2013587
    @ver+=1.36.0
    @ipv6_route_set_route_with_options
    Scenario: nmcli - ipv6 - routes - set route with options
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.addresses 2000::2/126
          ipv6.route-metric 258
          ipv6.routes '1010::1/128 2000::1 1024 cwnd=15 lock-mtu=true mtu=1600, ::/0 2001:1::1, 1020::1/128 type=blackhole'
          """
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 15" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 258" is visible with command "ip -6 route"
    Then "2001:1::1 dev eth3\s+proto static" is visible with command "ip -6 route"
    And "default via 2001:1::1 dev eth3" is visible with command "ip -6 route"
    And "blackhole 1020::1 dev lo proto static metric 258.*pref medium" is visible with command "ip -6 r"
    * Modify connection "con_ipv6" changing options "ipv6.routes '1030::1/128 type=prohibit, 1040::1/128 type=unreachable'"
    * Bring "up" connection "con_ipv6"
    Then "unreachable 1040::1 dev lo proto static metric 258.*pref medium" is visible with command "ip -6 r"
    And "prohibit 1030::1 dev lo proto static metric 258.*pref medium" is visible with command "ip -6 r"


    @eth0
    @ver-=1.9.1
    @ipv6_routes_remove_basic_route
    Scenario: nmcli - ipv6 - routes - remove basic route
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method static
          ipv6.addresses 2000::2/126
          ipv6.routes '1010::1/128 2000::1 1'
          """
    * Add "ethernet" connection named "con_ipv62" for device "eth2" with options
          """
          ipv6.method static
          ipv6.addresses 2001::1/126
          ipv6.routes '3030::1/128 2001::2 1'
          """
    * Modify connection "con_ipv6" changing options "ipv6.routes ''"
    * Modify connection "con_ipv62" changing options "ipv6.routes ''"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv62"
    Then "2000::2/126" is visible with command "ip a s eth3"
    Then "2001::1/126" is visible with command "ip a s eth2"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is not visible with command "ip -6 route"
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is not visible with command "ip -6 route"


    @rhbz1505893
    @eth0
    @ver+=1.9.2
    @ipv6_routes_remove_basic_route
    Scenario: nmcli - ipv6 - routes - remove basic route
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv6.method static
          ipv6.addresses 2000::2/126
          ipv6.routes '1010::1/128 2000::1 1'
          """
    * Add "ethernet" connection named "con_ipv62" for device "eth2" with options
          """
          ipv6.method static
          ipv6.addresses 2001::1/126
          ipv6.routes '3030::1/128 2001::2 1'
          """
    * Modify connection "con_ipv6" changing options "ipv6.routes ''"
    * Modify connection "con_ipv62" changing options "ipv6.routes ''"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv62"
    Then "2000::2/126" is visible with command "ip a s eth3"
    Then "2001::1/126" is visible with command "ip a s eth2"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is not visible with command "ip -6 route"
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is not visible with command "ip -6 route"


    @eth0
    @ver-=1.9.1
    @ipv6_routes_device_route
    Scenario: nmcli - ipv6 - routes - set device route
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.gateway 4000::1
           ipv6.routes '1010::1/128 :: 3, 3030::1/128 2001::2 2'
           """
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "3030::1 via 2001::2 dev eth3\s+proto static\s+metric 2" is visible with command "ip -6 route"
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric 3" is visible with command "ip -6 route"


    @eth0
    @ver+=1.9.2
    @ipv6_routes_device_route
    Scenario: nmcli - ipv6 - routes - set device route
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.gateway 4000::1
           ipv6.routes '1010::1/128 :: 3, 3030::1/128 2001::2 2'
           """
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "3030::1 via 2001::2 dev eth3\s+proto static\s+metric 2" is visible with command "ip -6 route"
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric 3" is visible with command "ip -6 route"


    @rhbz1452684 @rhbz1727193
    @ver+=1.18.3
    @ipv6_routes_with_src
    Scenario: nmcli - ipv6 - routes - set route with src
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv6.method manual
          ipv6.addresses 2000::2/126
          ipv6.route-metric 256
          ipv6.routes '2806:aabb:abba:abab:baba:bbaa:baab:bbbb/128 src=2000::2'
          """
    * Bring "up" connection "con_ipv6"
    Then "2806:aabb:abba:abab:baba:bbaa:baab:bbbb dev testX6 proto static src 2000::2 metric 256" is visible with command "ip -6 route" in "5" seconds
     And "2000::\/126 dev testX6\s+proto kernel\s+metric 256" is visible with command "ip -6 route"


    @rhbz1436531
    @ver+=1.10
    @flush_300
    @ipv6_route_set_route_with_tables
    Scenario: nmcli - ipv6 - routes - set route with tables
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv6.route-table 300
          ipv6.may-fail no
          """
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300" in "5" seconds
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
     And "eth10" is not visible with command "ip -6 r |grep -v fe80"
    * Execute "ip -6 route add table 300 2004::3/128 dev eth10"
    When "2004::3 dev eth10 metric 1024" is visible with command "ip -6 r show table 300"
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
    * Bring "up" connection "con_ipv6"
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
    Then "2004::3 dev eth10 metric 1024" is not visible with command "ip -6 r show table 300"
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show table 300"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show table 300"
     And "eth10" is not visible with command "ip -6 r |grep -v fe80"


    @rhbz1436531
    @ver+=1.10
    @ver-1.11
    @flush_300
    @ipv6_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv6 - routes - set route with tables reapply
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "2620.*::\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show"
    * Execute "ip -6 route add table 300 2004::3/128 dev eth10"
    When "2004::3 dev eth10 metric 1024" is visible with command "ip -6 r show table 300"
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
    * Execute "nmcli device reapply eth10"
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
    Then "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show |grep -v eth0" in "20" seconds
     And "2004::3 dev eth10 metric 1024" is not visible with command "ip -6 r show table 300"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"


    @rhbz1436531
    @ver+=1.11
    @flush_300
    @ipv6_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv4 - routes - set route with tables reapply
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
    * Execute "ip -6 route add table 300 2004::3/128 dev eth10"
    When "2004::3 dev eth10 metric 1024" is visible with command "ip -6 r show table 300"
     And "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
    * Execute "nmcli device reapply eth10"
    When "connected" is visible with command "nmcli -g state,device device |grep eth10$" in "20" seconds
    Then "2620.* dev eth10 proto kernel metric 1" is visible with command "ip -6 r show |grep -v eth0" in "20" seconds
     And "2004::3 dev eth10 metric 1024" is visible with command "ip -6 r show table 300"
     And "2620.*\/64 dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"
     And "fe80::\/64 dev eth10 proto kernel metric 1" is visible with command "ip -6 r show"
     And "default via fe80.* dev eth10 proto ra metric 1" is visible with command "ip -6 r show |grep -v eth0"


    @ipv6_correct_slaac_setting
    Scenario: NM - ipv6 - correct slaac setting
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.may-fail no"
    Then "2620:52:.*::/64 dev eth10\s+proto ra" is visible with command "ip -6 r show |grep -v eth0" in "20" seconds
    Then "2620:52:" is visible with command "ip -6 a s eth10 |grep global |grep noprefix" in "20" seconds


    @skip_in_centos
    @not_on_s390x @eth0 @tshark
    @ipv6_limited_router_solicitation
    Scenario: NM - ipv6 - limited router solicitation
     * Add "ethernet" connection named "con_ipv6" for device "eth2"
     * Execute "tshark -i eth2 -Y frame.len==62 -V -x -a duration:120 > /tmp/solicitation.txt"
     When "cannot|empty" is not visible with command "file /tmp/solicitation.txt" in "150" seconds
     Then Check solicitation for "eth2" in "/tmp/solicitation.txt"


    @rhbz1068673
    @ver-=1.19.90
    @ipv6_block_RA
    Scenario: NM - ipv6 - block RA
    * Add "ethernet" connection named "con_ipv6" for device "eth10"
    Then "1" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_defrtr"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_rtr_pref"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_pinfo"


    @rhbz1068673 @rhbz1734470
    @ver+=1.20.0
    @ipv6_block_RA
    Scenario: NM - ipv6 - block RA
    * Add "ethernet" connection named "con_ipv6" for device "eth10"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra" in "45" seconds


    @rhbz1734470
    @ver+=1.21.1
    @ver-1.47.2
    @stop_radvd
    @ipv6_accept_ra_handling
    Scenario: NM - ipv6 - accept RA handling
    * Prepare veth pairs "test10" bridged over "vethbr6"
    * Execute "ip -6 addr add 2001:db8:1::1/64 dev vethbr6"
    * Start radvd server with config from "contrib/ipv6/radvd2.conf"
    * Add "ethernet" connection named "con_ipv6" for device "test10" with options "ipv6.may-fail no"
    When "2001:db8" is visible with command "ip a s test10" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/test10/accept_ra"
    Then "300" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/retrans_time_ms"
    Then "12000" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/base_reachable_time_ms"
    Then "36" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/gc_stale_time"


    @rhbz1734470
    @ver+=1.47.2
    @stop_radvd
    @ipv6_accept_ra_handling
    Scenario: NM - ipv6 - accept RA handling
    * Prepare veth pairs "test10" bridged over "vethbr6"
    * Execute "ip -6 addr add 2001:db8:1::1/64 dev vethbr6"
    * Start radvd server with config from "contrib/ipv6/radvd2.conf"
    * Add "ethernet" connection named "con_ipv6" for device "test10" with options "ipv6.may-fail no"
    When "2001:db8" is visible with command "ip a s test10" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/test10/accept_ra"
    Then "300" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/retrans_time_ms"
    Then "12000" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/base_reachable_time_ms"
    Then "36" is visible with command "cat /proc/sys/net/ipv6/neigh/test10/gc_stale_time"
    Then "99" is visible with command "cat /proc/sys/net/ipv6/conf/test10/hop_limit"


    @ipv6_routes_invalid_IP
    Scenario: nmcli - ipv6 - routes - set invalid route - non IP
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes non:rout:set:up" in editor
    Then Error type "failed to set 'routes' property:" while saving in editor


    @eth0
    @ver-=1.9.1
    @ipv6_routes_without_gw
    Scenario: nmcli - ipv6 - routes - set invalid route - missing gw
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.gateway 4000::1
           ipv6.routes 1010::1/128
           """
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"

    @eth0
    @ver+=1.9.2
    @ipv6_routes_without_gw
    Scenario: nmcli - ipv6 - routes - set invalid route - missing gw
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.gateway 4000::1
           ipv6.routes 1010::1/128
           """
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 10" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"


    @rhbz2167805
    @ver+=1.42.1
    @ver+=1.43.2
    @restart_if_needed
    @ipv6_replace_local_rule
    Scenario: NM - ipv6 - replace local route rule
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "ipv6.replace-local-rule yes"
    * Bring "up" connection "con_ipv6"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds
    Then "0:	from all lookup local" is not visible with command "ip -6 rule"
    * Bring "down" connection "con_ipv6"
    Then "0:	from all lookup local" is visible with command "ip -6 rule"
    * Add "ethernet" connection named "con_ipv62" for device "eth4" with options "ipv6.replace-local-rule no"
    * Bring "up" connection "con_ipv62"
    Then "0:	from all lookup local" is visible with command "ip -6 rule"
    * Bring "up" connection "con_ipv6"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds
    Then "0:	from all lookup local" is not visible with command "ip -6 rule"


    @eth0
    @ipv6_dns_manual_IP_with_manual_dns
    Scenario: nmcli - ipv6 - dns - method static + IP + dns
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
           """
           ipv4.may-fail no
           ipv6.method static
           ipv6.addresses 2001::1/126
           ipv6.gateway 4000::1
           ipv6.dns '4000::1, 5000::1'
           """
    Then Nameserver "4000::1" is set in "45" seconds
    Then Nameserver "5000::1" is set
    Then Nameserver "10." is set in "45" seconds


    @eth0
    @ipv6_dns_auto_with_more_manually_set
    Scenario: nmcli - ipv6 - dns - method auto + dns
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
           """
           ipv4.may-fail no
           ipv6.dns '4000::1, 5000::1'
           """
    * Bring "up" connection "con_ipv6"
    When "2620:" is visible with command "ip a s eth10" in "15" seconds
    Then Nameserver "4000::1" is set
    Then Nameserver "5000::1" is set
    Then Nameserver "10." is set in "15" seconds


    @eth0
    @ipv6_dns_ignore-auto-dns_with_manually_set_dns
    Scenario: nmcli - ipv6 - dns - method auto + dns + ignore automaticaly obtained
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv6.ignore-auto-dns yes
          ipv6.dns '4000::1, 5000::1'
          """
    * Bring "up" connection "con_ipv6"
    Then Nameserver "4000::1" is set in "15" seconds
    Then Nameserver "5000::1" is set
    Then Nameserver "2620:" is not set


    @ver+=1.18
    @eth0
    @ipv6_dns_add_more_when_already_have_some
    Scenario: nmcli - ipv6 - dns - add dns when one already set
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.dns '4000::1'"
    * Modify connection "con_ipv6" changing options "+ipv6.dns 2000::1"
    * Bring "up" connection "con_ipv6"
    Then Nameserver "2000::1" is set in "45" seconds
    Then Nameserver "4000::1" is set


    @eth0
    @ipv6_dns_remove_manually_set
    Scenario: nmcli - ipv6 - dns - method auto then delete all dns
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ip6 fd01::1/64
          ipv6.dns '4000::1 5000::1'
          ipv6.gateway fd01::
          """
    * Bring "up" connection "con_ipv6"
    When Nameserver "4000::1" is set in "5" seconds
    When Nameserver "5000::1" is set in "5" seconds
    * Modify connection "con_ipv6" changing options "ipv6.dns ''"
    * Bring "up" connection "con_ipv6"
    Then Nameserver "4000::1" is not set
    Then Nameserver "5000::1" is not set


    @eth0
    @ipv6_dns-search_set
    Scenario: nmcli - ipv6 - dns-search - add dns-search
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv4.ignore-auto-dns yes
          ipv6.dns-search google.com
          """
    Then Domain "google.com" is set in "45" seconds


    @eth0
    @ipv6_dns-search_remove
    Scenario: nmcli - ipv6 - dns-search - remove dns-search
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ignore-auto-dns yes
          ipv6.dns-search google.com
          """
    * Modify connection "con_ipv6" changing options "ipv6.dns-search ''"
     * Bring "up" connection "con_ipv6"
    Then Domain " google.com" is not set


    @eth0
    @ipv6_ignore-auto-dns_set
    Scenario: nmcli - ipv6 - ignore auto obtained dns
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ignore-auto-dns yes
          ipv6.ignore-auto-dns yes
          """
    * Bring "up" connection "con_ipv6"
    Then Domain " google.com" is not set
    Then Domain "virtual" is not set


    @ipv6_method_link-local
    Scenario: nmcli - ipv6 - method - link-local
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "ipv6.method link-local"
    Then "inet6 fe80::" is visible with command "ip -6 a s eth3" in "20" seconds
    Then "scope global" is not visible with command "ip -6 a s eth3" in "20" seconds


    @ipv6_may_fail_set_true
    Scenario: nmcli - ipv6 - may-fail - set true
     * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
           """
           autoconnect no
           ipv6.method dhcp
           ipv6.may-fail yes
           """
    Then Bring "up" connection "con_ipv6"


    @ipv6_method_ignored
    Scenario: nmcli - ipv6 - method - ignored
     * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
           """
           ipv4.method static
           ipv4.addresses 192.168.122.253/24
           ipv6.method ignore
           """
    # VVV commented out because of fe80 is still on by kernel very likely
    # Then "scope link" is not visible with command "ip -6 a s eth10"
    Then "scope global" is not visible with command "ip -6 a s eth10" in "45" seconds
    # reproducer for 1004255
    Then Bring "down" connection "con_ipv6"
    Then "eth10 " is not visible with command "ip -6 route |grep -v fe80"


    @rhbz1643841
    @ver+=1.19
    @ipv6_method_disabled
    Scenario: nmcli - ipv6 - method disabled
    * Add "ethernet" connection named "con_ipv6" for device "eth3"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is visible with command "ip a show dev eth3"
    * Modify connection "con_ipv6" changing options "ipv6.method disabled"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is not visible with command "ip a show dev eth3"
    * Modify connection "con_ipv6" changing options "ipv6.method auto"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is visible with command "ip a show dev eth3"


    @eth10_disconnect
    @ipv6_never-default_set_true
    Scenario: nmcli - ipv6 - never-default - set
    * Doc: "Configuring NetworkManager to avoid using a specific profile to provide a default gateway"
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.never-default yes"
     * Bring "up" connection "testeth10"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
     * Bring "up" connection "con_ipv6"
    When "default via " is not visible with command "ip -6 route |grep eth10" in "45" seconds
    Then "default via " is not visible with command "ip -6 route |grep eth10" for full "45" seconds


    @eth10_disconnect
    @ipv6_never-default_remove
    Scenario: nmcli - ipv6 - never-default - remove
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options "ipv6.never-default yes"
    * Modify connection "con_ipv6" changing options "ipv6.never-default ''"
     * Bring "up" connection "testeth10"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
     * Bring "up" connection "con_ipv6"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
    Then "default via " is visible with command "ip -6 route |grep eth10" for full "45" seconds


    @not_under_internal_DHCP @tshark
    @ipv6_dhcp-hostname_set
    Scenario: nmcli - ipv6 - dhcp-hostname - set dhcp-hostname
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options
          """
          ipv6.may-fail true
          ipv6.method dhcp
          ipv6.dhcp-hostname r.cx
          """
    * Run child "tshark -i eth2 -f 'port 546' -V -x > /tmp/ipv6-hostname.log"
    * Bring "up" connection "con_ipv6"
    When "cannot|empty" is not visible with command "file /tmp/ipv6-hostname.log" in "150" seconds
    Then "r.cx" is visible with command "grep r.cx /tmp/ipv6-hostname.log" in "245" seconds


    @not_under_internal_DHCP @tshark
    @ipv6_dhcp-hostname_remove
    Scenario: nmcli - ipv6 - dhcp-hostname - remove dhcp-hostname
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options
          """
          ipv6.may-fail true
          ipv6.method dhcp
          ipv6.dhcp-hostname r.cx
          """
    * Bring "up" connection "con_ipv6"
    * Bring "down" connection "con_ipv6"
    * Modify connection "con_ipv6" changing options "ipv6.dhcp-hostname ''"
    * Bring "up" connection "con_ipv6"
    * Bring "down" connection "con_ipv6"
    * Run child "tshark -i eth2 -f 'port 546' -V -x > /tmp/tshark.log"
    * Bring "up" connection "con_ipv6"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Wait for "5" seconds
    * Execute "pkill tshark"
    Then "r.cx" is not visible with command "cat /tmp/tshark.log" in "45" seconds


    @restore_hostname @eth2_disconnect @tshark
    @ipv6_send_fqdn.fqdn_to_dhcpv6
    Scenario: NM - ipv6 - - send fqdn.fqdn to dhcpv6
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options "autoconnect no"
    * Execute "hostnamectl set-hostname dacan.local"
    * Run child "tshark -i eth2 -f 'port 546' -V -x > /tmp/ipv6_hostname.log"
    * Modify connection "con_ipv6" changing options "ipv6.method dhcp"
    * Bring "up" connection "con_ipv6"
    When "cannot|empty" is not visible with command "file /tmp/ipv6_hostname.log" in "150" seconds
    Then "dacan.local" is visible with command "cat /tmp/ipv6_hostname.log" in "145" seconds
     And "0.. = N bit" is visible with command "cat /tmp/ipv6_hostname.log"
     And "1 = S bit" is visible with command "cat /tmp/ipv6_hostname.log"


    @ipv6_secondary_address
    Scenario: nmcli - ipv6 - secondary
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "up" connection "con_ipv6"
    Then "Exactly" "2" lines with pattern "inet6 .* global" are visible with command "ip a s testX6" in "45" seconds


    @ipv6_ip6-privacy_0
    Scenario: nmcli - ipv6 - ip6_privacy - 0
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ip6-privacy 2
          """
    * Wait for "2" seconds
    * Modify connection "con_ipv6" changing options "ipv6.ip6-privacy 0"
    * Bring "up" connection "con_ipv6"
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"
    Then "global temporary dynamic" is not visible with command "ip a s eth10" in "45" seconds


    @ipv6_ip6-privacy_1
    Scenario: nmcli - ipv6 - ip6_privacy - 1
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ip6-privacy 1
          """
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"
    Then Global temporary ip is not based on mac of device "eth10"


    @ipv6_ip6-privacy_2
    Scenario: nmcli - ipv6 - ip6_privacy - 2
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ip6-privacy 2
          """
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "2" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr" in "45" seconds
    Then Global temporary ip is not based on mac of device "eth10"


    @ver+=1.47.3
    @ipv6_ip6-privacy_with_lifetime
    Scenario: nmcli - ipv6 - ip6_privacy - lifetime
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv4.method disabled
          ipv6.ip6-privacy 2
          ipv6.temp-valid-lifetime 20000
          ipv6.temp-preferred-lifetime 2000
          """
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "2" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr" in "45" seconds
    Then "20000" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/temp_valid_lft"
    Then "2000" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/temp_prefered_lft"
    Then Global temporary ip is not based on mac of device "eth10"


    @rhbz1187525
    @ver-1.47.3
    @restart_if_needed
    @ipv6_ip6-default_privacy
    Scenario: nmcli - ipv6 - ip6_privacy - default value
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "0"
    * Create "dummy" device named "dummy0"
    * Add "dummy" connection named "con_ipv6" for device "dummy0"
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "1"
    * Bring "up" connection "con_ipv6"
    When "1" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/use_tempaddr"
    * Create NM config file "96-nmci-custom.conf" with content
      """
      [connection.ip6-privacy]
      ipv6.ip6-privacy=2
      """
    * Restart NM
    * Bring "down" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    When "2" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/use_tempaddr"

    @restart_if_needed
    @ver+=1.47.3
    @ipv6_ip6-default_privacy
    Scenario: nmcli - ipv6 - ip6_privacy - default value
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "0"
    * Set sysctl "net.ipv6.conf.default.temp_valid_lft" to "604800"
    * Set sysctl "net.ipv6.conf.default.temp_prefered_lft" to "86400"
    * Create "dummy" device named "dummy0"
    * Add "dummy" connection named "con_ipv6" for device "dummy0"
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "1"
    * Set sysctl "net.ipv6.conf.default.temp_valid_lft" to "10000"
    * Set sysctl "net.ipv6.conf.default.temp_prefered_lft" to "1000"
    * Bring "up" connection "con_ipv6"
    Then "1" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/use_tempaddr"
    Then "10000" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/temp_valid_lft"
    Then "1000" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/temp_prefered_lft"
    * Create NM config file "96-nmci-custom.conf" with content
      """
      [connection.ip6-privacy]
      ipv6.ip6-privacy=2
      ipv6.temp-valid-lifetime=20000
      ipv6.temp-preferred-lifetime=2000
      """
    * Restart NM
    * Bring "down" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    Then "2" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/use_tempaddr"
    Then "20000" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/temp_valid_lft"
    Then "2000" is visible with command "cat /proc/sys/net/ipv6/conf/dummy0/temp_prefered_lft"


    @ver-=1.11.2
    @ipv6_ip6-privacy_incorrect_value
    Scenario: nmcli - ipv6 - ip6_privacy - incorrect value
    * Add "ethernet" connection named "con_ipv6" for device "eth3"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 3" in editor
    Then Error type "failed to set 'ip6-privacy' property: '3' is not valid\; use 0, 1, or 2" while saving in editor
    * Submit "set ipv6.ip6-privacy RHX" in editor
    Then Error type "failed to set 'ip6-privacy' property: 'RHX' is not a number" while saving in editor


    @ver+=1.11.3
    @ipv6_ip6-privacy_incorrect_value
    Scenario: nmcli - ipv6 - ip6_privacy - incorrect value
    * Add "ethernet" connection named "con_ipv6" for device "eth3"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 3" in editor
    Then Error type "failed to set 'ip6-privacy' property: invalid option '3', use one of \[unknown,disabled,prefer-public-addr,prefer-temp-addr\]" while saving in editor
    * Submit "set ipv6.ip6-privacy RHX" in editor
    Then Error type "failed to set 'ip6-privacy' property: invalid option 'RHX', use one of \[unknown,disabled,prefer-public-addr,prefer-temp-addr\]" while saving in editor


    @rhbz1073824
    @restart_if_needed
    @ipv6_take_manually_created_keyfile
    Scenario: keyfile - ipv6 - use manually created link-local profile
    * Create keyfile "/etc/NetworkManager/system-connections/con_ipv6.nmconnection"
      """
      [connection]
      autoconnect=yes
      interface-name=eth10
      uuid=aa17d688-a38d-481d-888d-6d69cca781b8
      type=ethernet
      id=con_ipv6

      [ipv6]
      method=dhcp
      """
    * Restart NM
    Then "aa17d688-a38d-481d-888d-6d69cca781b8" is visible with command "nmcli -f UUID connection show -a"


    @rhbz1640237
    @ver+=1.16
    @scapy
    @ipv6_lifetime_too_low
    Scenario: NM - ipv6 - valid lifetime too low should be ignored
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet with lifetimes "300" "140"
    * Wait for "2" seconds
    * Send lifetime scapy packet with lifetimes "20" "10"
    * Wait for "2" seconds
    Then "IPv6" lifetimes are slightly smaller than "300" and "10" for device "test11"
    * Wait for "2" seconds
    * Send lifetime scapy packet with lifetimes "7600" "7400"
    * Wait for "2" seconds
    * Send lifetime scapy packet with lifetimes "20" "10"
    * Wait for "2" seconds
    # there is 7200 here (2h), because of RFC 4862, section-5.5.3.e).3.
    Then "IPv6" lifetimes are slightly smaller than "7200" and "10" for device "test11"


    @rhbz1318945
    @ver+=1.4.0
    @scapy
    @ipv6_lifetime_no_padding
    Scenario: NM - ipv6 - RA lifetime with no padding
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet
    Then "IPv6" lifetimes are slightly smaller than "3600" and "1800" for device "test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_with_low_hlimit
    Scenario: NM - ipv6 - drop scapy packet with lower hop limit
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet with "250"
    Then "valid_lft forever preferred_lft forever" is visible with command "ip a s test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_with_255_hlimit
    Scenario: NM - ipv6 - scapy packet with 255 hop limit
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet with "255"
    Then "IPv6" lifetimes are slightly smaller than "3605" and "1805" for device "test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_from_non_ll_address
    Scenario: NM - ipv6 - drop scapy packet from non LL address
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet from "ff02::1"
    Then "valid_lft forever preferred_lft forever" is visible with command "ip a s test11"


    @rhbz1744895
    @ver+=1.22
    @ver-1.36.7
    @ver-1.37.91
    @ver-1.38.0
    @ver-1.39.2
    @ver/rhel/8+=1.22
    @ver/rhel/9+=1.22
    @ver/rhel/8-1.38.8
    @ver/rhel/9-1.38.8
    @scapy
    @ipv6_preserve_addr_order
    Scenario: NM - ipv6 - preserve address order
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet to dst "dead:beef::"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    When "1:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[.\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[.\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[.\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[.\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[.\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[.\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[.\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[.\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    Then "IP6.ADDRESS\[.\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    Then "IP6.ADDRESS\[.\]:\s+dead:beef::" is visible with command "nmcli device show test11"


    @rhbz1744895
    @ver+=1.36.7
    @ver+=1.37.91
    @ver+=1.38.0
    @ver+=1.39.2
    @ver/rhel/8+=1.38.8
    @ver/rhel/9+=1.38.8
    @scapy
    @ipv6_preserve_addr_order
    Scenario: NM - ipv6 - preserve address order
    * Execute "ip link add test10 type veth peer name test11"
    * Execute "nmcli c add type ethernet ifname test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli c add type ethernet ifname test11 ipv4.method disabled ipv6.method auto"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Wait for "2" seconds
    * Send lifetime scapy packet to dst "dead:beef::"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    When "1:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[[0-9]+\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[[0-9]+\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[[0-9]+\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[[0-9]+\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[[0-9]+\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[[0-9]+\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "IP6.ADDRESS\[[0-9]+\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    When "IP6.ADDRESS\[[0-9]+\]:\s+dead:beef::" is visible with command "nmcli device show test11"
    * Send lifetime scapy packet to dst "cafe:cafe::"
    * Send lifetime scapy packet to dst "dead:beef::"
    When "1:\s+inet6 dead:beef::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    When "2:\s+inet6 cafe:cafe::" is visible with command "ip a show dev test11 | grep inet6 | grep -v temporary | grep -n ."
    Then "IP6.ADDRESS\[[0-9]+\]:\s+cafe:cafe::" is visible with command "nmcli device show test11"
    Then "IP6.ADDRESS\[[0-9]+\]:\s+dead:beef::" is visible with command "nmcli device show test11"


    @rhbz1083133 @rhbz1098319 @rhbz1127718
    @eth3_disconnect
    @ver+=1.11.2 @ver-=1.24
    @ipv6_add_static_address_manually_not_active
    Scenario: NM - ipv6 - add a static address manually to non-active interface
    Given "testeth3" is visible with command "nmcli connection"
    Given "eth3\s+ethernet\s+connected" is not visible with command "nmcli device"
    Given "state UP" is visible with command "ip a s eth3"
    * "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    * Execute "ip -6 addr add 2001::dead:beef:01/64 dev eth3"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    Then "inet6 2001::dead:beef:1/64 scope global" is visible with command "ip a s eth3"
    #
    # the connection is assumed externally, meaning it has "addrgenmode none"
    # or "addr_gen_mode" sysctl set to "1". NM is not interferring with the
    # device, hence there is no IPv6 LL address. Which is a problem, but a
    # problem of the user who takes over the device without setting the
    # addrgenmode to its liking.
    Then "net.ipv6.conf.eth3.addr_gen_mode = 1" is visible with command "sysctl net.ipv6.conf.eth3.addr_gen_mode"
    Then "inet6 fe80" is not visible with command "ip a s eth3" for full "45" seconds
    #
    # the assumed connection is created, give just some time for DAD to complete
    Then "eth3\s+ethernet\s+connected\s+eth3" is visible with command "nmcli device"


    @rhbz1083133 @rhbz1098319 @rhbz1127718 @rhbz1816202
    @eth3_disconnect
    @ver+=1.25
    @ipv6_add_static_address_manually_not_active
    Scenario: NM - ipv6 - add a static address manually to non-active interface
    Given "testeth3" is visible with command "nmcli connection"
    Given "eth3\s+ethernet\s+connected" is not visible with command "nmcli device"
    Given "state UP" is visible with command "ip a s eth3"
    * "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    * Execute "ip -6 addr add 2001::dead:beef:01/64 dev eth3"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    Then "inet6 2001::dead:beef:1/64 scope global" is visible with command "ip a s eth3"
    #
    # the connection is assumed externally, meaning it has "addrgenmode none"
    # (or "addr_gen_mode" sysctl set to "1"). NM is not interferring with the
    # device, hence there is no IPv6 LL address. Which is a problem, but a
    # problem of the user who takes over the device without setting the
    # addrgenmode to its liking.
    Then "net.ipv6.conf.eth3.addr_gen_mode = 1" is visible with command "sysctl net.ipv6.conf.eth3.addr_gen_mode"
    Then "inet6 fe80" is not visible with command "ip a s eth3" for full "45" seconds
    #
    # the assumed connection is created, give just some time for DAD to complete
    Then "eth3\s+ethernet\s+connected \(externally\)\s+eth3" is visible with command "nmcli device"


    @rhbz1138426
    @restart_if_needed @add_testeth10
    @ipv6_no_assumed_connection_for_ipv6ll_only
    Scenario: NM - ipv6 - no assumed connection on IPv6LL only device
    * Delete connection "testeth10"
    * Stop NM
    * Execute "ip a flush dev eth10; ip l set eth10 down; ip l set eth10 up"
    When "fe80" is visible with command "ip a s eth10" in "45" seconds
    * Start NM
    Then "eth10.*eth10" is not visible with command "nmcli con"


    @rhbz1194007
    @ver+=1.8
    @kill_dnsmasq_ip6
    @ipv6_set_ra_announced_mtu
    Scenario: NM - ipv6 - set RA received MTU
    * Create "veth" device named "test10" with options "peer name test10p"
    * Create "veth" device named "test11" with options "peer name test11p"
    * Create "bridge" device named "vethbr6" with options "forward_delay 2 stp_state 1"
    * Execute "ip link set dev vethbr6 up"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test10p up"
    * Execute "ip link set dev test11 up"
    * Execute "ip link set dev test11p up"
    * Execute "ip link set dev test10p master vethbr6"
    * Execute "ip link set dev test11p master vethbr6"
    * Add "ethernet" connection named "tc16" for device "test10" with options "autoconnect no"
    * Add "ethernet" connection named "tc26" for device "test11" with options "autoconnect no mtu 1100 ip6 fd01::1/64"
    * Bring "up" connection "tc26"
    When "test11:connected:tc26" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "45" seconds
    * Execute "/usr/sbin/dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --no-resolv --bind-interfaces -i test11 --enable-ra --dhcp-range=::1,::400,constructor:test11,ra-only,64,15s"
    * Bring "up" connection "tc16"
    Then "1280" is visible with command "sysctl net.ipv6.conf.test10.mtu" in "45" seconds


    @rhbz1243958
    @ver+=1.4.0
    @eth0
    @nm-online_wait_for_ipv6_to_finish
    Scenario: NM - ipv6 - nm-online wait for non tentative ipv6
    * Create "veth" device named "test10" with options "peer name test10p"
    * Execute "ip link set dev test10 up"
    * Execute "ip link set dev test10p up"
    * Add "ethernet" connection named "tc16" for device "test10" with options
          """
          autoconnect no
          ip4 192.168.99.1/24
          ip6 2620:52:0:beef::1/64
          """
    * Execute "nmcli connection modify tc16 ipv6.may-fail no"
    Then "tentative" is not visible with command "nmcli connection down testeth0 ; nmcli connection down tc16; sleep 2; nmcli connection up id tc16; time nm-online ;ip a s test10|grep 'global tentative'; nmcli connection up testeth0"


    @ver-=1.5
    @rhbz1183015
    @ipv6_shared_connection_error
    Scenario: NM - ipv6 - shared connection
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options "autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv4.method disabled ipv6.method shared"
    Then "Sharing IPv6 connections is not supported yet" is visible with command "nmcli connection up id con_ipv6"


    @rhbz1256822
    @ver+=1.6
    @ipv6_shared_connection
    Scenario: nmcli - ipv6 - shared connection
    * Prepare veth pairs "test10,test11" bridged over "vethbr6"
    * Add "ethernet" connection named "tc26" for device "test11" with options
          """
          ipv6.method shared
          ipv6.addresses 1::1/64
          """
    * Add "ethernet" connection named "tc16" for device "test10"
    Then "inet6 1::1/64" is visible with command "ip a s test11" in "45" seconds
     And "inet6 fe80::" is visible with command "ip a s test11"
     And "inet6 1::" is visible with command "ip a s test10" in "45" seconds
     And "inet6 fe80::" is visible with command "ip a s test10"


    @rhbz1247156
    @ipv6_tunnel_module_removal
    Scenario: NM - ipv6 - ip6_tunnel module removal
    * Execute "modprobe ip6_tunnel"
    When "ip6_tunnel" is visible with command "lsmod |grep ip"
    * Execute "modprobe -r ip6_gre"
    * Execute "modprobe -r ip6_tunnel"
    Then "ip6_tunnel" is not visible with command "lsmod |grep ip" in "2" seconds


    @rhbz1269520
    @ipv6_no_activation_schedule_error_in_logs
    Scenario: NM - ipv6 - no activation scheduled error
    * Prepare simulated test "testA6" device
    * Add "ethernet" connection named "con_ipv6" for device "testA6"
    * Execute "nmcli connection modify con_ipv6 ipv6.may-fail no ipv4.method disabled"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    Then "activation_source_schedule" is not visible with command "journalctl -u NetworkManager --since -1m|grep error"


    @internal_DHCP @long
    @ver-=1.19.90
    @ipv6_DHCPv6
    Scenario: NM - ipv6 - internal DHCPv6
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method dhcp
          """
    * Bring "up" connection "con_ipv6"
    Then "testX6\s+ethernet\s+connected" is visible with command "nmcli device" in "20" seconds


    @rhbz1734470
    @ver+=1.20.0
    @internal_DHCP @long
    @ipv6_DHCPv6
    Scenario: NM - ipv6 - internal DHCPv6
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method ignore
          """
    * Bring "up" connection "con_ipv6"
    When "testX6\s+ethernet\s+connected" is visible with command "nmcli device" in "20" seconds
    When "Exactly" "2" lines with pattern "inet6" are visible with command "ip a s testX6" in "20" seconds
    * Modify connection "con_ipv6" changing options "ipv6.method dhcp"
    * Execute "nmcli dev reapply testX6"
    When "testX6\s+ethernet\s+connected" is visible with command "nmcli device" in "20" seconds
    Then "2620" is visible with command "ip a s testX6 |grep inet6" in "10" seconds
    Then "Different than" "3" lines with pattern "inet6" are visible with command "ip a s testX6" in "10" seconds
    Then "Exactly" "2" lines with pattern "inet6" are visible with command "ip a s testX6" in "10" seconds
    # VVV DHCPv6 doesn't give routes so this should not be present VVV
    Then "default via fe80" is not visible with command "ip -6 r |grep testX6"


    @rhbz1268866
    @skip_in_centos
    @internal_DHCP @long
    @ipv6_NM_stable_with_internal_DHCPv6
    Scenario: NM - ipv6 - stable with internal DHCPv6
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method dhcp
          """
    * Execute "nmcli con up id con_ipv6" for "50" times



    @ver+=1.10.1
    @skip_in_centos
    @rhelver-=7 @fedoraver-=0 #as we have no initscripts anymore
    @restart_if_needed @selinux_allow_ifup
    @persistent_default_ipv6_gw
    Scenario: NM - ipv6 - persistent default ipv6 gw
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Wait for "3" seconds
    * Stop NM
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for "20" seconds
    When "default" is visible with command "ip -6 r |grep testX6" in "20" seconds
    And "default" is visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds
    * Restart NM
    Then "default via fe" is visible with command "ip -6 r |grep testX6 |grep expire" for full "20" seconds
     And "default via fe" is visible with command "ip -6 r |grep testX6 |grep 'metric 1024'" in "50" seconds


    @rhbz1274894
    @ver+=1.9.2
    @skip_in_centos
    @rhelver-=7 @fedoraver-=0 #as we have no initscripts anymore
    @restart_if_needed @selinux_allow_ifup
    @persistent_ipv6_routes
    Scenario: NM - ipv6 - persistent ipv6 routes
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options "ipv4.method disabled"
    * Wait for "3" seconds
    * Stop NM
    * Execute "rm -rf /var/run/NetworkManager"
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for "10" seconds
    When "fe80" is visible with command "ip -6 r |grep testX6" in "45" seconds
    And "default" is visible with command "ip -6 r |grep testX6 |grep expire" in "20" seconds
    And "2620:dead:beaf::\/64" is visible with command "ip -6 r"
    * Restart NM
    Then "testX6\s+ethernet\s+connected\s+con_ipv6" is visible with command "nmcli device" in "245" seconds
    # VVV But the new one present from NM with metric 1xx
    Then "default via fe" is visible with command "ip -6 r |grep testX6 |grep 'metric 1'" in "20" seconds
    # VVV Link-local address should be still present
    And "fe80" is visible with command "ip -6 r |grep testX6" in "45" seconds
    # VVV Route should be exchanged for NM one with metric 1xx
    And "2620:dead:beaf::\/64 dev testX6\s+proto ra\s+metric 1" is visible with command "ip -6 r"
    # We don't care about the rest


    @rhbz1394500
    @ver+=1.8
    @ver-1.32.9
    @ipv6_honor_ip_order
    Scenario: NM - ipv6 - honor IP order from configuration upon reapply
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options "autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv6.method manual ipv6.addresses 2001:db8:e:10::4/64,2001:db8:e:10::57/64,2001:db8:e:10::30/64"
    * Bring "up" connection "con_ipv6"
    When "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2" in "45" seconds
    * Execute "nmcli con modify con_ipv6 ipv6.addresses 2001:db8:e:10::30/64,2001:db8:e:10::57/64,2001:db8:e:10::4/64"
    * Execute "nmcli dev reapply eth2"
    Then "2001:db8:e:10::4/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::30/64" is visible with command "ip a show eth2"


    @rhbz1988751
    @ver+=1.32.9
    @ver-1.36.7
    @ver-1.37.91
    @ver-1.38.0
    @ver-1.39.2
    @ver/rhel/8+=1.32.9
    @ver/rhel/9+=1.32.9
    @ver/rhel/9-1.39.7.2
    @ipv6_honor_ip_order
    Scenario: NM - ipv6 - honor IP order from configuration upon restart
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options "autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv6.method manual ipv6.addresses 2001:db8:e:10::4/64,2001:db8:e:10::57/64,2001:db8:e:10::30/64"
    * Bring "up" connection "con_ipv6"
    When "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2" in "45" seconds
    * Execute "nmcli con modify con_ipv6 ipv6.addresses 2001:db8:e:10::30/64,2001:db8:e:10::57/64,2001:db8:e:10::4/64"
    * Execute "nmcli dev reapply eth2"
    Then "2001:db8:e:10::4/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::30/64" is visible with command "ip a show eth2"
    * Restart NM
    Then "2001:db8:e:10::4/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::30/64" is visible with command "ip a show eth2"


    @rhbz1988751
    @ver+=1.36.7
    @ver+=1.37.91
    @ver+=1.38.0
    @ver+=1.39.2
    @ver/rhel/8-
    @ver/rhel/9+=1.39.7.2
    @ipv6_honor_ip_order
    Scenario: NM - ipv6 - honor IP order from configuration upon restart
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options "autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv6.method manual ipv6.addresses 2001:db8:e:10::4/64,2001:db8:e:10::57/64,2001:db8:e:10::30/64"
    * Bring "up" connection "con_ipv6"
    When "2001:db8:e:10::4/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::30/64" is visible with command "ip a show eth2" in "45" seconds
    * Execute "nmcli con modify con_ipv6 ipv6.addresses 2001:db8:e:10::30/64,2001:db8:e:10::57/64,2001:db8:e:10::4/64"
    * Execute "nmcli dev reapply eth2"
    Then "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2"
    * Restart NM
    Then "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2"


    @rhbz2073976
    @ver+=1.39.2
    @ipv6_keep_static_address_after_reapply
    Scenario: NM - ipv6 - keep static ipv6 address after reapply
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options
        """
        ipv4.method manual ipv4.address 10.16.1.10/24 ipv4.gateway 10.16.1.1 ipv4.dns 10.16.1.1
        ipv6.method manual ipv6.address 2001:db8:e:10::4/64
        """
    * Bring "up" connection "con_ipv6"
    When "inet6 2001:db8:e:10::4/64" is visible with command "ip a show eth2"
    * Modify connection "con_ipv6" changing options "ipv4.dns ''"
    When Execute "nmcli dev reapply eth2"
    Then "inet6 2001:db8:e:10::4/64" is visible with command "ip a show eth2"


    @rhbz2004212
    @ver+=1.32.10
    @ipv6_keep_route_upon_reapply
    Scenario: NM - ipv6 - keep routes upon reapply
    * Prepare simulated test "testX6" device without DHCP
    * Execute "ip -n testX6_ns addr add dev testX6p fd01::1/64"
    * Execute "ip -n testX6_ns link set dev testX6p up"
    * Execute "ip link set dev testX6 up"
    * Run child "ip netns exec testX6_ns radvd -n -C contrib/ipv6/radvd1.conf" without shell
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.route-table 254
          """
    * Bring "up" connection "con_ipv6"
    * Execute "nmcli d reapply testX6"
    Then "ff00" is visible with command "ip -6 route show table local dev testX6"


    @rhbz2004212
    @ver+=1.32.10
    @skip_in_centos
    @long
    @ipv6_keep_route_upon_reapply_full
    Scenario: NM - ipv6 - keep routes upon reapply, check address presence after timeout
    * Prepare simulated test "testX6" device without DHCP
    * Execute "ip -n testX6_ns addr add dev testX6p fd01::1/64"
    * Execute "ip -n testX6_ns link set dev testX6p up"
    * Execute "ip link set dev testX6 up"
    * Run child "ip netns exec testX6_ns radvd -n -C contrib/ipv6/radvd1.conf" without shell
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.route-table 254
          """
    * Bring "up" connection "con_ipv6"
    * Execute "nmcli d reapply testX6"
    Then "ff00" is visible with command "ip -6 route show table local dev testX6"
    Then "fd01" is visible with command "ip -6 addr show dev testX6" for full "50" seconds
    Then "ff00" is visible with command "ip -6 route show table local dev testX6"


    @rhbz2082230
    @ver+=1.39.5
    @no_config_server @no_auto_default
    @ipv6_no_extra_temp_addresses
    Scenario: NM - ipv6 - clear extra temporary addresses
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
        """
        ipv4.method disabled ipv6.ip6-privacy prefer-public-addr
        """
    * Bring "up" connection "con_ipv6"
    # reapply scenario, 1-2 temporary addresses may be present for DHCP
    * Modify connection "con_ipv6" changing options "ipv6.ip6-privacy prefer-temp-addr"
    When Execute "nmcli d reapply testX6"
    * Wait for "2" seconds
    Then "At least" "1" and "at most" "2" lines with pattern "inet6.*temporary" are visible with command "ip -6 a show testX6" in "2" seconds
    # no (temporary) address should appear after connection is brought down
    When Bring "down" connection "con_ipv6"
    Then "inet6" is not visible with command "ip -6 a show testX6"
    Then "connected" is not visible with command "nmcli c s --active | grep con_ipv6"
    # no (temporary) address should appear after connection times out (this requires @no_config_server)
    * Bring "up" connection "con_ipv6"
    * Execute "ip -n testX6_ns l set testX6p down"
    When "testX6" is not visible with command "nmcli c s --active" in "10" seconds
    Then "inet6" is not visible with command "ip -6 a show testX6"
    When Execute "ip -n testX6_ns l set testX6p up"
    Then "testX6" is visible with command "nmcli c s --active" in "5" seconds


    @rhbz2027267
    @ver+=1.35.5
    @long
    @internal_DHCP
    @ipv6_internal_client_dhcpv6_leases_renewal
    Scenario: NM renews DHCPv6 leases when using internal DHCP client
    * Execute "nmcli g logging level trace"
    * Prepare simulated test "testX6" device without DHCP
    * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
    * Execute "ip -n testX6_ns link set dev testX6p up"
    * Execute "echo > /tmp/ip6leases.conf"
    * Configure dhcpv6 prefix delegation server with address configuration mode "dhcp-stateful"
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method dhcp
          """
    * Bring "up" connection "con_ipv6"
    # extract T1 and T2 and compare they're shorter than a day (86400 s)
    Then Execute "journalctl -u NetworkManager --since -5s --no-pager | grep 'T1 and T2 equal to zero' | tail -n1 | sed -e 's/^.*\(T1=[0-9]\+\)sec, \(T2=[0-9]\+\)sec$/\1\n\2/' | while read LINE; do echo \"is ${LINE:0:2}=${LINE:3} lesser than 86400?\" ; test ${LINE:3} -lt 86400 ; done"


    @ver-=1.19.1
    @ipv6_describe
    Scenario: nmcli - ipv6 - describe
     * Add "ethernet" connection named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv6"
     * Submit "goto ipv6" in editor
     Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty." are present in describe output for object "method"

     Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses of DNS servers." are present in describe output for object "dns"
     Then Check regex "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." in describe output for object "dns-search"
     Then Check "=== \[addresses\] ===\s+\[NM property description\]\s+Array of IP addresses.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses formatted as:\s+ip\[/prefix\], ip\[/prefix\],...\s+Missing prefix is regarded as prefix of 128.\s+Example: 2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b" are present in describe output for object "addresses"
     Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes." are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured nameservers and search domains are ignored and only nameservers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"


    @ver+=1.19.2
    @ipv6_describe
    Scenario: nmcli - ipv6 - describe
     * Add "ethernet" connection named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv6"
     * Submit "goto ipv6" in editor

    Then Check regex "=== \[method\] ===\s+\[NM property description\]\s+(The IPv6 connection method|IP configuration method).*" in describe output for object "method"

     Then Check "=== \[dns\] ===\s+\[NM property description\]\s+.*DNS.*2607:f0d0:1002:51::4" are present in describe output for object "dns"

     Then Check regex "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." in describe output for object "dns-search"
     Then Check "=== \[addresses\] ===\s+\[NM property description\]\s+.*of IP(v6)? addresses.*\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses formatted as:\s+ip\[/prefix\], ip\[/prefix\],...\s+Missing prefix is regarded as prefix of 128.\s+Example: 2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b" are present in describe output for object "addresses"

     Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes." are present in describe output for object "routes"

     Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

     Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured name ?servers and search domains are ignored and only name ?servers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

     Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

     Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

     Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"


    @rhbz1449873
    @ver+=1.8.0
    @ignore_backoff_message
    @ipv6_keep_external_addresses
    Scenario: NM - ipv6 - keep external addresses
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Wait for "1" seconds
    * Execute "for i in $(seq 3000); do ip addr add 2017::$i/64 dev dummy0; done"
    When "3000" is visible with command "ip addr show dev dummy0 | grep 'inet6 2017::' -c" in "2" seconds
    Then "3000" is visible with command "ip addr show dev dummy0 | grep 'inet6 2017::' -c" for full "6" seconds


    @rhbz1457242
    @ver+=1.8.0
    @eth3_disconnect
    @ipv6_keep_external_routes
    Scenario: NM - ipv6 - keep external routes
    # * Reboot step added as a workaround for rhbz2117237, remove once fixed!
    * Reboot
    * Execute "ip link set eth3 down; ip addr flush eth3; ethtool -A eth3 rx off tx off; ip link set eth3 up; sleep 0.5"
    * Execute "ip addr add fc00:a::10/64 dev eth3; ip -6 route add fc00:b::10/128 via fc00:a::1; sleep 0.5"
    When "fc00:b" is visible with command "ip -6 r" in "2" seconds
    Then "fc00:b" is visible with command "ip -6 r" for full "45" seconds


    @rhbz1446367
    @ver+=1.8.0
    @ethernet
    @nmcli_general_finish_dad_without_carrier
    Scenario: nmcli - general - finish dad with no carrier
    * Add "ethernet" connection named "ethernet0" for device "testX6" with options "autoconnect no"
    * Prepare simulated veth device "testX6" without carrier
    * Execute "nmcli con modify ethernet0 ipv4.may-fail no ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Execute "nmcli con modify ethernet0 ipv4.may-fail yes ipv6.method manual ipv6.addresses 2001::2/128"
    * Bring "up" connection "ethernet0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE connection show ethernet0" in "45" seconds
     And "1.2.3.4" is visible with command "ip a s testX6"
     And "2001::2" is visible with command "ip a s testX6"
     And "tentative" is visible with command "ip a s testX6" for full "45" seconds


    @rhbz1508001
    @ver+=1.10.0
    @restart_if_needed
    @ipv4_dad_not_preventing_ipv6
    Scenario: NM - ipv6 - add address after ipv4 DAD fail
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.may-fail yes
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          ipv4.dad-timeout 2001
          ipv6.may-fail yes
          """
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE connection show con_ipv6" in "145" seconds
     And "2620:dead:beaf" is visible with command "ip a s testX6"


    @rhbz2096386
    @may_fail
    @ver+=1.39.10
    @restart_if_needed @kill_dnsmasq_ip6 @tshark
    @ipv6_may_fail_no_wait_for_dad_dhcp
    Scenario: NM - ipv6 - wait for DAD completion with may-fail=no, duplicate address assigned via DHCP
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          connection.autoconnect no
          ipv4.method disabled
          ipv6.may-fail no
          ipv6.method auto
          ipv6.dhcp-duid 00:11:22
          """
    # setup: add two more NSs in addition to testX6_ns, one with dnsmasq and other with interface
    # with a duplicate address
    * Prepare simulated test "testX6" device without DHCP
    * Create "bridge" device named "br0" in namespace "testX6_ns" with options "mcast_snooping 0"
    * Add namespace "dup_ns"
    * Create "veth" device named "dup" in namespace "dup_ns" with options "peer name dupp netns testX6_ns"
    * Execute "ip -n dup_ns link set dup up"
    * Add namespace "dhcp_ns"
    * Create "veth" device named "dhcp" in namespace "dhcp_ns" with options "peer name dhcpp netns testX6_ns"
    * Execute "ip -n dhcp_ns link set dhcp up ; ip -n dhcp_ns addr add 2620:dead:beaf::1/64 dev dhcp"
    * Execute "for if in testX6p dhcpp dupp; do ip -n testX6_ns link set $if master br0 ; done"
    * Execute "for if in testX6p dhcpp dupp br0 ; do ip -n testX6_ns link set $if up ; done"
    # block communication between duplicate address device and dnsmasq so that dnsmasq
    # can't be aware of conflict
    * Load nftables in "testX6_ns" namespace
        """
        table bridge filter {
          chain forward {
            type filter hook forward priority 0; policy accept;
            iif "dhcpp" oif "dupp" drop
            iif "dupp" oif "dhcpp" drop
          }
        }
        """
    * Run child "ip netns exec dhcp_ns dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --log-dhcp --log-queries=extra --pid-file=/tmp/dnsmasq_ip6.pid --interface=dhcp --conf-file=/dev/null --leasefile-ro --no-hosts --dhcp-range=2620:dead:beaf::,static,ra-only --dhcp-host=id:00:11:22,[::1234:5678],static" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 547 or port 546' > /tmp/tshark.log"
    * Execute "ip link set testX6 up"
    ### uncomment following steps to verify that address is assigned correctly in absence of duplicate address
    #* Bring "up" connection "con_ipv6"
    #Then "2620:dead:beaf[:0-9a-f]+1234:5678" is visible with command "ip a show testX6" in "10" seconds
    #Then Execute "ping -c 2 -I 2620:dead:beaf::1234:5678 2620:dead:beaf::1"
    #* Bring "down" connection "con_ipv6"
    * Execute "ip -n dup_ns addr add 2620:dead:beaf::1234:5678/64 dev dup"
    * Bring "up" connection "con_ipv6" ignoring error
    Then "2620:dead:beaf[:0-9a-f]+1234:5678" is not visible with command "ip a show testX6"
    # check that NM was offered a ::1234:5678 address by dnsmasq
    And "option:\s*5\s*iaaddr\s*2620:dead:beaf::1234:5678" is visible with command "cat /tmp/dnsmasq_ip6.log"
    # This is up to discussion - interface ends up with SLAAC or RA-derived address but it
    # won't be reachable by expected DNS name because it failed to get expected DHCP address
    And Check if "con_ipv6" is not active connection


    @rhbz2096386
    @may_fail
    @ver+=1.39.10
    @restart_if_needed @kill_dnsmasq_ip6 @tshark
    @ipv6_may_fail_no_wait_for_dad_eui
    Scenario: NM - ipv6 - wait for DAD completion with may-fail=no, duplicate address generated by SLAAC
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          connection.autoconnect no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv4.method disabled
          ipv6.may-fail no
          ipv6.method auto
          ipv6.addr-gen-mode eui64
          ipv6.ip6-privacy disabled
          """
    # setup: add two more NSs in addition to testX6_ns, one with dnsmasq and other with interface
    # with a duplicate address
    * Prepare simulated test "testX6" device without DHCP
    * Create "bridge" device named "br0" in namespace "testX6_ns" with options "mcast_snooping 0"
    * Add namespace "dup_ns"
    * Create "veth" device named "dup" in namespace "dup_ns" with options "peer name dupp netns testX6_ns"
    * Execute "ip -n dup_ns link set dup up"
    * Add namespace "dhcp_ns"
    * Create "veth" device named "dhcp" in namespace "dhcp_ns" with options "peer name dhcpp netns testX6_ns"
    * Execute "ip -n dhcp_ns link set dhcp up ; ip -n dhcp_ns addr add 2620:dead:beaf::1/64 dev dhcp"
    * Execute "for if in testX6p dhcpp dupp; do ip -n testX6_ns link set $if master br0 ; done"
    * Execute "for if in testX6p dhcpp dupp br0 ; do ip -n testX6_ns link set $if up ; done"
    * Run child "ip netns exec dhcp_ns dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --log-dhcp --log-queries=extra --pid-file=/tmp/dnsmasq_ip6.pid --interface=dhcp --conf-file=/dev/null --no-hosts --enable-ra --dhcp-range=2620:dead:beaf::,slaac" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 547 or port 546' > /tmp/tshark.log"
    * Execute "ip link set testX6 up"
    ### uncomment following steps to verify that address is assigned correctly in absence of duplicate address
    #* Bring "up" connection "con_ipv6"
    #Then "2620:dead:beaf:0*:ecaa:bbff:fecc:ddee" is visible with command "ip a show testX6" in "10" seconds
    #Then Execute "ping -c 2 -I 2620:dead:beaf::ecaa:bbff:fecc:ddee 2620:dead:beaf::1"
    #* Bring "down" connection "con_ipv6"
    * Execute "ip -n dup_ns addr add 2620:dead:beaf::ecaa:bbff:fecc:ddee/64 dev dup"
    * Bring "up" connection "con_ipv6" ignoring error
    Then "2620:dead:beaf:0*:ecaa:bbff:fecc:ddee" is not visible with command "ip a show testX6"
    # interface ended up with just link-local address so it can't have full connectivity
    And "limited" is visible with command "nmcli -f DEVICE,IP6-CONNECTIVITY d | grep testX6"


    @rhbz1470930
    @ver+=1.8.3
    @ethernet @netcat
    @ipv6_preserve_cached_routes
    Scenario: NM - ipv6 - preserve cached routes
    * Prepare simulated test "testX6" device for IPv6 PMTU discovery
    * Add "ethernet" connection named "ethernet0" for device "testX6" with options
        """
        autoconnect no
        ipv4.method disabled ipv6.method auto
        ipv6.routes 'fd02::/64 fd01::1'
        """
    * Execute "ip l set testX6 up"
    * Bring "up" connection "ethernet0"
    * Execute "sleep 1"
    * Execute "dd if=/dev/zero bs=1M count=10 | nc fd02::2 9000"
    Then "mtu 1400" is visible with command "ip route get fd02::2" for full "40" seconds


    @rhbz2010640
    @ver+=1.36.0
    @ethernet
    @ipv6_restart_prefixroute
    Scenario: NM - ipv6 - prefixroute won't disappear from external addresses on restart
    * Cleanup connection "eth1"
    * Execute "ip addr add fd00::1/64 dev eth1"
    When "fd00::1/64" is visible with command "nmcli device show eth1" for full "5" seconds
    * Restart NM
    Then "fd00::/64" is visible with command "ip -6 route show dev eth1" for full "5" seconds


    @rhbz1368018
    @ver+=1.8
    @kill_dhclient_custom @restart_if_needed
    @persistent_ipv6_after_device_rename
    Scenario: NM - ipv6 - persistent ipv6 after device rename
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "down" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Execute "nmcli device set testX6 managed no"
    * Restart NM
    When "0" is visible with command "cat /proc/sys/net/ipv6/conf/testX6/disable_ipv6"
    * Rename device "testX6" to "festY"
    * Execute "dhclient -4 -pf /tmp/dhclient_custom.pid festY" without waiting for process to finish
    * Wait for "45" seconds
    * Execute "pkill -F /tmp/dhclient_custom.pid"
    When "0" is visible with command "cat /proc/sys/net/ipv6/conf/festY/disable_ipv6"
    * Rename device "festY" to "testX6"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/testX6/disable_ipv6"


    @rhbz1462260
    @ver+=1.10.1
    @eth3_disconnect
    @add_ipv6_over_ipv4_configured_ext_device
    Scenario: NM - ipv6 - add ipv6 to external ipv4 configured device
    * Execute "ethtool -A eth3 rx on tx on; ip addr flush eth3; ethtool -A eth3 rx off tx off; ip link set eth3 up"
    * Execute "ip addr add 192.168.100.2/24 dev eth3; ip addr add fe01::1/64 dev eth3"
    Then "fe01::1" is visible with command "ip a show dev eth3" in "45" seconds


    @rhbz1445417
    @ver+=1.10
    @stop_radvd @eth0
    @ipv6_multiple_default_routes
    Scenario: NM - ipv6 - multiple default ipv6 routes
    * Prepare veth pairs "test10" bridged over "vethbr6"
    * Execute "ip -6 addr add dead:beef::1/64 dev vethbr6"
    * Execute "ip -6 addr add beef:dead::1/64 dev test10p"
    * Execute "ip -6 addr add fe80::dead:dead:dead:dead/64 dev test10p"
    * Start radvd server with config from "contrib/ipv6/radvd1.conf"
    * Add "ethernet" connection named "con_ipv6" for device "test10" with options "ipv6.may-fail no"
    Then "Exactly" "2" lines with pattern "test10" are visible with command "ip -6 r | grep default -A 3|grep 'via fe80'" in "60" seconds


    @rhbz1414093
    @ver+=1.12
    @ipv6_duid
    Scenario: NM - ipv6 - test ipv6.dhcp-duid option
    * Add "ethernet" connection named "con_ipv6" for device "test10"
    Then Modify connection "con_ipv6" changing options "ipv6.dhcp-duid 01:23:45:67:ab"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid lease"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid ll"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid llt"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-ll"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-llt"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-uuid"


    @rhbz1369905
    @ver+=1.16
    @ipv6_manual_addr_before_dhcp
    Scenario: nmcli - ipv6 - set manual values immediately
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv4.may-fail no
          ipv6.method dhcp
          ipv6.addresses 2000::1/128
          ipv6.routes '1010::1/128 2000::2 101'
          """
    * Execute "ip netns exec testX6_ns kill -SIGSTOP $(cat /tmp/testX6_ns.pid)"
    * Run child "sleep 10 && ip netns exec testX6_ns kill -SIGCONT $(cat /tmp/testX6_ns.pid)"
    * Run child "sleep 2 && nmcli con up con_ipv6"
    Then "2000::1/128" is visible with command "ip a s testX6" in "5" seconds
     And "1010::1 via 2000::2 dev testX6\s+proto static\s+metric 10[0-1]" is visible with command "ip -6 route"
     And "2000::1 dev testX6 proto kernel metric 10" is visible with command "ip -6 route"
     And "2000::2 dev testX6 proto static metric 10" is visible with command "ip -6 route"
     # And "namespace 192.168.3.11" is visible with command "cat /etc/resolv.conf" in "10" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds


     @rhbz1548237
     @ver+=1.18.0
     @ipv6_survive_external_link_restart
     Scenario: nmcli - ipv6 - survive external link restart
     * Prepare simulated test "testX6" device
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options "ipv6.may-fail no"
     * Add "ethernet" connection named "con_ipv62" for device "eth3"
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv62" in "45" seconds
     * Execute "ip link set dev eth3 down && sleep 1 && ip link set dev eth3 up"
     * Execute "ip link set dev testX6 down && sleep 1 && ip link set dev testX6 up"
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv62" in "45" seconds
     # TestX6 device (everything)
     Then "2620:dead:beaf" is visible with command "ip a s testX6"
     And "fe80" is visible with command "ip a s testX6"
     And "default" is visible with command "ip -6 r |grep testX6"
     # Eth3 device (just fe80)
     And "fe80" is visible with command "ip a s eth3"


     @rhbz1755467
     @ver+=1.22
     @internal_DHCP @dhcpd @rhelver+=8 @fedoraver-=35
     @ipv6_prefix_delegation_internal
     Scenario: nmcli - ipv6 - prefix delegation
     * Prepare simulated test "testX6" device without DHCP
     * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
     * Prepare simulated test "testY6" device without DHCP
     * Configure dhcpv6 prefix delegation server with address configuration mode "dhcp-stateful"
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv4.method disabled
           ipv6.method auto
           ipv6.route-metric 50
           autoconnect no
           """
     * Bring "up" connection "con_ipv6"
     When "inet6 fc01:" is visible with command "ip a show dev testX6" in "5" seconds
     * Add "ethernet" connection named "con_ipv62" for device "testY6" with options
           """
           ipv4.method disabled
           ipv6.method shared
           autoconnect no
           """
     * Bring "up" connection "con_ipv62"
     When "iaaddr" is visible with command "cat /tmp/ip6leases.conf" in "10" seconds
     When "iaprefix" is visible with command "cat /tmp/ip6leases.conf" in "10" seconds
     * Execute "ip netns exec testX6_ns ip route add $(grep -m 1 iaprefix /tmp/ip6leases.conf | sed -r 's/\s+iaprefix ([a-f0-9:/]+) \{.*/\1/') via $(grep -m 1 iaaddr /tmp/ip6leases.conf | sed -r 's/\s+iaaddr ([a-f0-9:]+) \{.*/\1/')"
     # no need to call, because of IPv6 autoconfiguration
     #Then Finish "ip netns exec testY6_ns rdisc -d -v"
     Then "inet6 fc01:bbbb:[a-f0-9:]+/64" is visible with command "ip -n testY6_ns a show dev testY6p" in "20" seconds
     And  "tentative" is not visible with command "ip -n testY6_ns a show dev testY6p" in "15" seconds
     And  Execute "ip netns exec testY6_ns ping -c2 fc01::1"


     @ver+=1.34
     @internal_DHCP @dhcpd @rhelver+=8
     @ipv6_prefix_delegation_ll_internal
     Scenario: nmcli - ipv6 - prefix delegation with link-local addressing
     # https://github.com/coreos/fedora-coreos-tracker/issues/888
     * Prepare simulated test "testX6" device without DHCP
     * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
     * Prepare simulated test "testY6" device without DHCP
     * Configure dhcpv6 prefix delegation server with address configuration mode "link-local"
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv4.method disabled
           ipv6.method auto
           ipv6.route-metric 50
           autoconnect no
           """
     * Bring "up" connection "con_ipv6"
     * Add "ethernet" connection named "con_ipv62" for device "testY6" with options
           """
           ipv4.method disabled
           ipv6.method shared
           autoconnect no
           """
     * Bring "up" connection "con_ipv62"
     When "iaprefix" is visible with command "cat /tmp/ip6leases.conf" in "10" seconds
     * Execute "ip netns exec testX6_ns ip route add $(grep -m 1 iaprefix /tmp/ip6leases.conf | sed -r 's/\s+iaprefix ([a-f0-9:/]+) \{.*/\1/') via $(ip addr show testX6 | grep -o 'fe80[a-f0-9:]*') dev testX6p"
     # no need to call, because of IPv6 autoconfiguration
     #Then Finish "ip netns exec testY6_ns rdisc -d -v"
     Then "inet6 fc01:bbbb:[a-f0-9:]+/64" is visible with command "ip -n testY6_ns a show dev testY6p" in "15" seconds
     And  "tentative" is not visible with command "ip -n testY6_ns a show dev testY6p" in "15" seconds
     And  Execute "ip netns exec testY6_ns ping -c2 fc01::1"


     @rhbz1755467
     @ver+=1.6
     @dhclient_DHCP @dhcpd @rhelver+=8
     @ipv6_prefix_delegation_dhclient
     Scenario: nmcli - ipv6 - prefix delegation
     * Execute "systemctl stop dhcpd"
     * Prepare simulated test "testX6" device without DHCP
     * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
     * Prepare simulated test "testY6" device without DHCP
     * Configure dhcpv6 prefix delegation server with address configuration mode "dhcp-stateful"
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv4.method disabled
           ipv6.method auto
           ipv6.route-metric 50
           autoconnect no
           """
     * Bring "up" connection "con_ipv6"
     When "inet6 fc01:" is visible with command "ip a show dev testX6" in "5" seconds
     * Add "ethernet" connection named "con_ipv62" for device "testY6" with options
           """
           ipv4.method disabled
           ipv6.method shared
           autoconnect no
           """
     * Bring "up" connection "con_ipv62"
     When "iaaddr" is visible with command "cat /tmp/ip6leases.conf" in "10" seconds
     When "iaprefix" is visible with command "cat /tmp/ip6leases.conf" in "10" seconds
     * Execute "ip netns exec testX6_ns ip route add $(grep -m 1 iaprefix /tmp/ip6leases.conf | sed -r 's/\s+iaprefix ([a-f0-9:/]+) \{.*/\1/') via $(grep -m 1 iaaddr /tmp/ip6leases.conf | sed -r 's/\s+iaaddr ([a-f0-9:]+) \{.*/\1/')"
     # no need to call, because of IPv6 autoconfiguration
     # Then Execute "ip netns exec testY6_ns rdisc -d -v"
     And  "inet6 fc01:bbbb:[a-f0-9:]+/64" is visible with command "ip -n testY6_ns a show dev testY6p" in "15" seconds
     And  "tentative" is not visible with command "ip -n testY6_ns a show dev testY6p" in "15" seconds
     And  Execute "ip netns exec testY6_ns ping -c2 fc01::1"


     @rhbz2083968
     @ver+=1.39.5
     @dhclient_DHCP @dhcpd
     @ipv6_ignore_address_lease_dhclient
     Scenario: nmcli - ipv6 - dhclient - do not assign addresses with otherconf flag
     * Execute "systemctl stop dhcpd"
     * Prepare simulated test "testX6" device without DHCP
     * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
     * Configure dhcpv6 prefix delegation server with address configuration mode "dhcp-stateless" and lease time "15" seconds
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv4.method disabled
           ipv6.method auto
           ipv6.route-metric 50
           autoconnect no
           """
     * Bring "up" connection "con_ipv6"
     Then "fc01:" is visible with command "ip a show dev testX6" in "5" seconds
     And "fc01::[a-z0-9]{4}/128" is not visible with command "ip a show dev testX6" for full "30" seconds
     And "fc01:[a-z0-9:]+/64" is visible with command "ip a show dev testX6"


     @rhbz1749358
     @ver+=1.22.0
     @internal_DHCP
     # dhclient support only ipv6.dhcp-iaid = mac
     @ipv6_dhcp_iaid_unset
     Scenario: nmcli - ipv6 - IAID unset which defaults to ifname
     * Prepare simulated test "testX6" device
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           """
     When "/128" is visible with command "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "30" seconds
     * Note the output of "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_testX6"
     * Add "bridge" connection named "br88" for device "br88" with options
           """
           bridge.stp false
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           """
     * Modify connection "con_ipv6" changing options "connection.master br88 connection.slave-type bridge"
     * Bring "up" connection "br88"
     * Bring "up" connection "con_ipv6"
     When "/128" is visible with command "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "30" seconds
     * Note the output of "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_br88"
     Then Check noted values "ipv6_testX6" and "ipv6_br88" are not the same


     @rhbz1749358
     @ver+=1.22.0
     @internal_DHCP
     # dhclient support only ipv6.dhcp-iaid = mac
     @ipv6_dhcp_iaid_ifname
     Scenario: nmcli - ipv6 - IAID ifname
     * Prepare simulated test "testX6" device
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           ipv6.dhcp-iaid ifname
           """
     When "/128" is visible with command "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "30" seconds
     * Note the output of "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_testX6"
     * Add "bridge" connection named "br88" for device "br88" with options
           """
           bridge.stp false
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           ipv6.dhcp-iaid ifname
           """
     * Modify connection "con_ipv6" changing options "connection.master br88 connection.slave-type bridge"
     * Bring "up" connection "br88"
     * Bring "up" connection "con_ipv6"
     When "/128" is visible with command "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "30" seconds
     * Note the output of "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_br88"
     Then Check noted values "ipv6_testX6" and "ipv6_br88" are not the same


     @rhbz1749358
     @ver+=1.22.0
     @ipv6_dhcp_iaid_mac
     Scenario: nmcli - ipv6 - IAID mac
     * Prepare simulated test "testX6" device
     * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
           """
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           ipv6.dhcp-iaid mac
           """
     When "/128" is visible with command "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "10" seconds
     * Note the output of "ip a s testX6 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_testX6"
     * Add "bridge" connection named "br88" for device "br88" with options
           """
           bridge.stp false
           ipv6.addr-gen-mode 0
           ipv6.dhcp-duid ll
           ipv6.dhcp-iaid mac
           """
     * Modify connection "con_ipv6" changing options "connection.master br88 connection.slave-type bridge"
     * Bring "up" connection "br88"
     * Bring "up" connection "con_ipv6"
     When "/128" is visible with command "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" in "30" seconds
     * Note the output of "ip a s br88 | grep inet6 | grep -o '[a-f0-9:]*/128'" as value "ipv6_br88"
     Then Check noted values "ipv6_testX6" and "ipv6_br88" are the same


    @rhbz1795957
    @skip_in_centos
    @ver+=1.22
    @long
    @solicitation_period_prolonging
    Scenario: NM - general - read router solicitation values
    * Prepare simulated test "testX6" device with "15s" leasetime
    # Connection should be alive for full 160s
    * Execute "echo 4 > /proc/sys/net/ipv6/conf/testX6/router_solicitations"
    * Execute "echo 40 > /proc/sys/net/ipv6/conf/testX6/router_solicitation_interval"
    * Execute "ip netns exec testX6_ns kill -SIGSTOP $(cat /tmp/testX6_ns.pid)"
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disable
          ipv6.may-fail no
          """
    When "con_ipv6" is visible with command "nmcli connection show -a"
    When "con_ipv6" is visible with command "nmcli connection show -a" for full "140" seconds
    * Execute "ip netns exec testX6_ns kill -SIGCONT $(cat /tmp/testX6_ns.pid)"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds


    @rhbz1801158
    @ver+=1.22.8
    @ipv6_ra_timeout_set
    Scenario: NM - ipv6 - add ra-timeout
    * Prepare simulated test "testX6" device
    * Execute "ip netns exec testX6_ns kill -SIGSTOP $(cat /tmp/testX6_ns.pid)"
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.ra-timeout 65
          autoconnect no
          """
    * Execute "nmcli con up con_ipv6" without waiting for process to finish
    When "con_ipv6" is visible with command "nmcli connection show -a"
    * Execute "sleep 60; ip netns exec testX6_ns kill -SIGCONT $(cat /tmp/testX6_ns.pid)" without waiting for process to finish
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "70" seconds


    @rhbz1819680
    @ver+=1.25
    @ipv6_token
    Scenario: NM - ipv6 - set token
    * Add "ethernet" connection named "con_ipv6" for device "eth10" with options
          """
          ipv6.token ::123
          ipv6.addr-gen-mode eui64
          """
    * Bring "up" connection "con_ipv6"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds
    Then "token ::123 dev eth10" is visible with command "ip token |grep eth10"


    @rhbz1858344
    @ver+=1.22.8
    @permissive @restore_hostname @eth0
    @dhcpv6_hostname
    Scenario: nmcli - ipv6 - secondary
    * Bring "down" connection "testeth0"
    * "OK" is visible with reproducer "repro_1858344.sh" in "10" seconds


    @rhbz1861527
    # at least two bugs:
    #   * https://bugzilla.redhat.com/show_bug.cgi?id=2179890 and
    #   * not-yet-reported memory issue somewhere causing OOMs
    @ver+=1.35.7
    @ignore_backoff_message
    @logging_info_only
    @ipv6_ignore_nonstatic_routes
    Scenario: NM - ipv6 - ignore routes that are neither static nor RA nor DHCP
    * Prepare simulated test "many_routes6" device with "30m" leasetime
    * Commentary
        """
        Clean up the device early with ip so that in case of some problems, the restarted
        NM doesn't have to cope with 100000s of routes
        """
    * Cleanup execute "ip link delete many_routes6" with timeout "10" seconds and priority "-45"
    * Cleanup execute "sleep 2" with timeout "3" seconds and priority "-44"
    * Add "ethernet" connection named "con_ipv6" for device "many_routes6"
    * Bring "up" connection "con_ipv6"
    # wait until `connecting` or `activating` is finished
    When "ing" is not visible with command "nmcli -f general.state c show con_ipv6" in "10" seconds
    # wait for DHCP routes
    When "2620:dead:beaf::[^/]" is visible with command "ip -6 r sh dev many_routes6" in "10" seconds
    * Note "ipv6" routes on interface "many_routes6" as value "ip_routes_before"
    Then Check "ipv6" route list on NM device "many_routes6" matches "ip_routes_before"
    * Note "ipv6" routes on NM device "many_routes6" as value "nm_routes_before"
    When Execute "for i in {5..8} {10..15} 17 18 42 99 {186..192} ; do ip -6 r add 1000:0:0:${i}::/64 proto ${i} dev many_routes6; done"
    Then Check "ipv6" route list on NM device "many_routes6" matches "nm_routes_before"
    # If more routes are needed, just adjust argument to the generating script and When check
    * Execute "prepare/bird_routes.py many_routes6 6 500000 > /tmp/nmci-bird-routes-v6"
    * Execute "ip -b /tmp/nmci-bird-routes-v6"
    When There are "at least" "500000" IP version "6" routes for device "many_routes6" in "5" seconds
    Then Check "ipv6" route list on NM device "many_routes6" matches "nm_routes_before"
    * Delete connection "con_ipv6"
    * Commentary
    """
    Wait before starting the check, as the check might block/slow down the route deletion.
    """
    * Wait for "5" seconds
    Then There are "at most" "5" IP version "6" routes for device "many_routes6" in "5" seconds


    @RHEL-26195
    @ver+=1.47.5
    @ver+=1.46.1
    @ver/rhel/9+=1.48
    @ver/rhel/9/4+=1.46.0.7
    @ignore_backoff_message
    @logging_info_only
    @ipv6_ignore_routes_changes
    Scenario: NM - ipv6 - ignore routes that are neither static nor RA nor DHCP
    * Prepare simulated test "many_routes6" device with ifindex "65006"
    * Commentary
        """
        Clean up the device early with ip so that in case of some problems, the restarted
        NM doesn't have to cope with 100000s of routes
        """
    * Cleanup execute "ip link delete many_routes6; sleep 2" with timeout "10" seconds and priority "-45"
    * Add "ethernet" connection named "con_ipv6" for device "many_routes6" with options
      """
      ipv4.method manual
      ipv4.addresses 192.168.0.1/24
      ipv6.method manual
      ipv6.addresses 2001::fee/48
      """
    * Bring "up" connection "con_ipv6"
    # wait until `connecting` or `activating` is finished
    When "ing" is not visible with command "nmcli -f general.state c show con_ipv6" in "10" seconds
    * Start following journal
    * Start monitoring "NetworkManager" CPU usage with threshold "25"
    # To speed up a bit, it is possible to stop NM while appending routes, but this can be reproducer
    * Stop NM
    * Append "2000000" routes of version "6" to "many_routes6" by "200000" in batch
    * Start NM in "40" seconds
    When "NetworkManager.*usage within threshold" is visible in journal
    * Commentary
      """
      Reset usage counter, measure only replace commands
      """
    Then NM was not using more than "110%" of CPU
    * Replace "300" routes of version "6" on "many_routes6" by "50" in batch
    # TODO - usage might exceed 25% in spike even on healthy NM
    # Then "ERROR: NetworkManager.*usage too high" is not visible in journal
    Then NM was not using more than "10%" of CPU
    * Flush routes of version "6" on "many_routes6"


    @rhbz2047788
    @ver+=1.32.7
    @ipv6_required_timeout_set
    Scenario: nmcli - ipv6 - connection with required timeout
    * Prepare simulated test "testX6" device without DHCP
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv4.method manual
          ipv6.method auto
          ipv4.addresses 192.168.99.47
          ipv6.may-fail yes
          ipv6.required-timeout 10000
          """
    * Execute "nmcli c up con_ipv6" without waiting for process to finish
    When "activated" is not visible with command "nmcli -g GENERAL.STATE con show con_ipv6" for full "9" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "10" seconds
    Then "Exactly" "1" lines are visible with command "nmcli -g IP6.ADDRESS -m multiline con show con_ipv6"


    @rhbz1837254
    @ver+=1.36.0
    @ipv6_handle_route_linking
    Scenario: Handle ipv6 route linking by kernel
    * Add "ethernet" connection named "con_ipv6" for device "eth3" with options
          """
          ipv4.method disabled
          ip6 fdb3:84e5:4ff4:55e3::1010/64
          ipv6.gateway fdb3:84e5:4ff4:55e3::1
          """
    * Bring "up" connection "con_ipv6"
    * Note the output of "ip -6 route list ::/0 dev eth3" as value "original"
    * Modify connection "con_ipv6" changing options "ipv6.gateway fdb3:84e5:4ff4:55e3::2"
    * Execute "nmcli d reapply eth3"
    * Execute "ip -6 route list ::/0 dev eth3"
    * Modify connection "con_ipv6" changing options "ipv6.gateway fdb3:84e5:4ff4:55e3::1"
    * Execute "nmcli d reapply eth3"
    * Note the output of "ip -6 route list ::/0 dev eth3" as value "reverted"
    Then Check noted values "original" and "reverted" are the same


    @rhbz1995372
    @ver+=1.32
    @ver-1.36
    @ipv6_check_addr_order
    Scenario: nmcli - ipv6 - check IPv6 address order
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv6.addr-gen-mode eui64
          ipv6.ip6-privacy disabled
          """
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64,1:2:3::102/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::102/64 1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli device modify testX6 +ipv6.addresses '1:2:3::103/64'"
    Then Check "ipv6" address list "1:2:3::103/64 1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli device modify testX6 ipv6.addresses ''"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli connection modify con_ipv6 ipv6.method manual ipv6.addresses '1:2:3::101/64,1:2:3::102/64,1:2:3::103/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::103/64 1:2:3::102/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds


    @rhbz1995372
    @ver+=1.36
    @ver-1.36.7
    @ver-1.38
    @ipv6_check_addr_order
    Scenario: nmcli - ipv6 - check IPv6 address order
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv6.addr-gen-mode eui64
          ipv6.ip6-privacy disabled
          """
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64,1:2:3::102/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 1:2:3::102/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli device modify testX6 +ipv6.addresses '1:2:3::103/64'"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 1:2:3::103/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli device modify testX6 ipv6.addresses ''"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli connection modify con_ipv6 ipv6.method manual ipv6.addresses '1:2:3::101/64,1:2:3::102/64,1:2:3::103/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::103/64 1:2:3::102/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds


    # rhel-8.7 and newer (since 1.39.7-2) has a special behavior.
    # See https://bugzilla.redhat.com/show_bug.cgi?id=2097270
    @rhbz1995372
    @ver-
    @ver/rhel/8+=1.39.7.2
    @ipv6_check_addr_order
    Scenario: nmcli - ipv6 - check IPv6 address order
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv6.addr-gen-mode eui64
          ipv6.ip6-privacy disabled
          """
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64,1:2:3::102/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::102/64 1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli device modify testX6 +ipv6.addresses '1:2:3::103/64'"
    Then Check "ipv6" address list "1:2:3::103/64 1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli device modify testX6 ipv6.addresses ''"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli connection modify con_ipv6 ipv6.method manual ipv6.addresses '1:2:3::101/64,1:2:3::102/64,1:2:3::103/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::103/64 1:2:3::102/64 1:2:3::101/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds


    @rhbz1995372
    @ver+=1.36.7
    @ver+=1.38
    @ver/rhel/8+=1.36.7
    @ver/rhel/8+=1.38
    @ver/rhel/8-1.39.7.2
    @ipv6_check_addr_order
    Scenario: nmcli - ipv6 - check IPv6 address order
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv6.addr-gen-mode eui64
          ipv6.ip6-privacy disabled
          """
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64,1:2:3::102/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::101/64 1:2:3::102/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli connection modify con_ipv6 ipv6.addresses '1:2:3::101/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::101/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6"
    * Execute "nmcli device modify testX6 +ipv6.addresses '1:2:3::103/64'"
    Then Check "ipv6" address list "1:2:3::101/64 1:2:3::103/64 /2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli device modify testX6 ipv6.addresses ''"
    Then Check "ipv6" address list "/2620:dead:beaf:[0-9a-f:]+/128 2620:dead:beaf:0:ecaa:bbff:fecc:ddee/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds
    * Execute "nmcli connection modify con_ipv6 ipv6.method manual ipv6.addresses '1:2:3::101/64,1:2:3::102/64,1:2:3::103/64'"
    * Bring "up" connection "con_ipv6"
    Then Check "ipv6" address list "1:2:3::101/64 1:2:3::102/64 1:2:3::103/64 fe80::ecaa:bbff:fecc:ddee/64" on device "testX6" in "6" seconds


    @rhbz2082682
    @ver+=1.39.10
    @restart_if_needed
    @ipv6_set_addr-gen_mode_global_config
    Scenario: nmcli - ipv6 - set ipv6.addr-gen mode in global config
    * Create NM config file with content
      """
      [connection]
      match-device=type:ethernet
      ipv6.addr-gen-mode=0
      """
    * Restart NM
    * Prepare simulated test "testX6" device
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          ethernet.cloned-mac-address ee:aa:bb:cc:dd:ee
          ipv6.ip6-privacy disabled
          """
    * Bring "up" connection "con_ipv6"
    Then "default" is visible with command "nmcli -g ipv6.addr-gen-mode con show con_ipv6"
    And "fe80::ecaa:bbff:fecc:ddee/64" is visible with command "ip a show dev testX6" in "10" seconds


    @RHEL-56565
    @ver+=1.51.3
    @restart_if_needed
    @ipv6_set_dhcp_send_hostname_global_config
    Scenario: nmcli - ipv6 - set ipv6.dhcp-send-hostname in global config
    * Create NM config file with content
      """
      [connection]
      match-device=type:ethernet
      ipv6.dhcp-send-hostname=0
      """
    * Restart NM
    * Add "ethernet" connection named "con_ipv6" for device "eth2" with options
          """
          ipv6.dhcp-hostname r.cx
          ipv6.may-fail true
          ipv6.method dhcp
          """
    * Bring "down" connection "con_ipv6"
    * Run child "tshark -i eth2 -f 'port 546' -V -x > /tmp/ipv6-hostname.log"
    * Bring "up" connection "con_ipv6"
    When "cannot|empty" is not visible with command "file /tmp/ipv6-hostname.log" in "50" seconds
    Then "r.cx" is not visible with command "cat /tmp/ipv6-hostname.log" for full "45" seconds
    * Modify connection "con_ipv6" changing options "ipv6.dhcp-send-hostname true"
    * Bring "up" connection "con_ipv6"
    Then "r.cx" is visible with command "grep r.cx /tmp/ipv6-hostname.log" in "45" seconds


    @rhbz2082685
    @ver+=1.41.2
    @ver-1.45.8
    @ipv6_stable_privacy_dad
    Scenario: nmcli - ipv6 - check that DAD is performed for stable-privacy SLAAC addresses
    * Prepare simulated test "testX6" device
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "1"
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          """
    * Bring "up" connection "con_ipv6"
    Then "2620:dead:beaf:.*/64" is visible with command "ip a show dev testX6"
    * Note the output of "ip -6 a s dev testX6 dynamic mngtmpaddr | grep -o '[a-f0-9:]*/64' | tee /tmp/ipv6addr.txt"
    * Bring "down" connection "con_ipv6"
    * Commentary
          """
          Now that we know the generated stable-privacy address for testX6 and
          the `con_ipv6` is down again, we can set it at the namespace end and
          reactivate `con_ipv6` again to cause a collision; then we can check:
            * testX6 gets a different privacy address
            * the now-duplicate address can only show up as either:
              * `tentative` (undergoing DAD)
              * `dadfailed`
              * `deprecated` (being removed)
          """
    * Execute "ip -n testX6_ns address add dev testX6p $(cat /tmp/ipv6addr.txt)"
    * Execute "sleep 5"
    * Bring "up" connection "con_ipv6"
    Then "2620:dead:beaf:.*/64" is visible with command "ip a show dev testX6 -tentative -dadfailed -deprecated" in "5" seconds
    Then Noted value is not visible with command "ip a show dev testX6 -tentative -dadfailed -deprecated"


    @rhbz2082685
    @RHEL-11811
    @ver+=1.45.8
    @ipv6_stable_privacy_dad
    Scenario: nmcli - ipv6 - check that DAD is performed for stable-privacy SLAAC addresses
    * Prepare simulated test "testX6" device
    * Set sysctl "net.ipv6.conf.default.use_tempaddr" to "1"
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          ipv4.method disabled
          ipv6.method auto
          ipv6.may-fail no
          """
    * Bring "up" connection "con_ipv6"
    Then "2620:dead:beaf:.*/64" is visible with command "ip a show dev testX6"
    * Note the output of "ip -6 a s dev testX6 dynamic mngtmpaddr | grep -o '[a-f0-9:]*/64' | tee /tmp/ipv6addr.txt"
    * Bring "down" connection "con_ipv6"
    * Commentary
          """
          Now that we know the generated stable-privacy address for testX6 and
          the `con_ipv6` is down again, we can set it at the namespace end and
          reactivate `con_ipv6` again to cause a collision; then we can check:
            * NM reports address conflict in the log
            * testX6 gets a different privacy address
            * the now-duplicate address can only show up as either:
              * `tentative` (undergoing DAD)
              * `dadfailed`
              * `deprecated` (being removed)
          """
    * Execute "ip -n testX6_ns address add dev testX6p $(cat /tmp/ipv6addr.txt)"
    * Execute "sleep 5"
    * Start following journal
    * Bring "up" connection "con_ipv6"
    Then "<info>.*Conflict detected for IPv6 address: 2620:dead:beaf.*" is visible in journal in "3" seconds
    Then "2620:dead:beaf:.*/64" is visible with command "ip a show dev testX6 -tentative -dadfailed -deprecated" in "3" seconds
    Then Noted value is not visible with command "ip a show dev testX6 -tentative -dadfailed -deprecated"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv6_mptcp_no_flags
    Scenario: MPTCP with no explicit configuration
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Execute "ip mptcp limits set subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method disabled ipv6.method static ipv6.addresses 2620:dead:beaf:50::c/64 ipv6.gateway 2620:dead:beaf:50::1"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method disabled ipv6.method static ipv6.addresses 2620:dead:beaf:51::c/64 ipv6.gateway 2620:dead:beaf:51::1"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 2620:dead:beaf:50::1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv6_mptcp_flags_0x8
    Scenario: MPTCP with flag no-defroute
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Execute "ip mptcp limits set subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method disabled ipv6.method static ipv6.addresses 2620:dead:beaf:50::c/64 connection.mptcp-flags 0x8"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method disabled ipv6.method static ipv6.addresses 2620:dead:beaf:51::c/64 connection.mptcp-flags 0x8"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 2620:dead:beaf:50::1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines are visible with command "ip mptcp endpoint show"


    @rhbz2060684
    @ver+=1.41.8
    @ipv6_route_cache_consistancy
    Scenario: ipv6 - check consistent route cache with "ip route replace"
    * Prepare simulated test "testX6" device
    * Execute "ip route append 1:2:3:4::/64 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::1 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::2 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::3 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1:2:3:4::1\ 1024  5:1::1/128\ 1:2:3:4::2\ 1024  5:1::1/128\ 1:2:3:4::3\ 1024"
    * Execute "ip route replace 5:1::1/128 nexthop via 1:2:3:4::5 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1:2:3:4::5\ 1024"

    * Execute "ip -6 route flush dev testX6"
    * Execute "ip route append 1:2:3:4::/64 dev testX6"
    * Execute "ip route append 5:1::1/128 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::1 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::2 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::3 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024  5:1::1/128\ 1:2:3:4::1\ 1024  5:1::1/128\ 1:2:3:4::2\ 1024  5:1::1/128\ 1:2:3:4::3\ 1024"
    * Execute "ip route replace 5:1::1/128 nexthop via 1:2:3:4::5 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024  5:1::1/128\ 1:2:3:4::5\ 1024"

    * Execute "ip -6 route flush dev testX6"
    * Execute "ip route append 1:2:3:4::/64 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::1 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::2 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::3 dev testX6"
    * Execute "ip route append 5:1::1/128 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024  5:1::1/128\ 1:2:3:4::1\ 1024  5:1::1/128\ 1:2:3:4::2\ 1024  5:1::1/128\ 1:2:3:4::3\ 1024"
    * Execute "ip route replace 5:1::1/128 nexthop via 1:2:3:4::5 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024  5:1::1/128\ 1:2:3:4::5\ 1024"

    * Execute "ip -6 route flush dev testX6"
    * Execute "ip route append 1:2:3:4::/64 dev testX6"
    * Execute "ip route append 5:1::1/128 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024"
    * Execute "ip route replace 5:1::1/128 nexthop via 1:2:3:4::5 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1:2:3:4::5\ 1024"

    * Execute "ip -6 route flush dev testX6"
    * Execute "ip route append 1:2:3:4::/64 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::1 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::2 dev testX6"
    * Execute "ip route append 5:1::1/128 nexthop via 1:2:3:4::3 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1:2:3:4::1\ 1024  5:1::1/128\ 1:2:3:4::2\ 1024  5:1::1/128\ 1:2:3:4::3\ 1024"
    * Execute "ip route replace 5:1::1/128 dev testX6"
    Then Check "inet6" route list on NM device "testX6" matches "1:2:3:4::/64\ 1024  5:1::1/128\ 1024"

    @rhbz2046293
    @ver+=1.43.3
    @ipv6_prefsrc_route
    Scenario: Configure IPv6 routes with prefsrc
    * Prepare simulated test "testX1" device with "192.168.51.10" ipv4 and "2620:dead:beaf::51" ipv6 dhcp address prefix
    * Add "ethernet" connection named "x1" for device "testX1" with options "ipv4.method disabled ipv6.routes '1::51/128 src=2620:dead:beaf::51, 1::52/128 src=2621:dead:beaf::52' ipv6.route-metric 161"
    Then Check "inet6" route list on NM device "testX1" matches "fe80::/64\ 1024    2620:dead:beaf::/64\ 161    2620:dead:beaf::51/128\ 161    /::/0\ fe80:.*\ 161    1::51/128\ 161" in "10" seconds
    Then "1::51 proto static scope global src 2620:dead:beaf::51 metric 161" is visible with command "ip -d -6 route show dev testX1"

    * Commentary
      """
      The route with src=2621:dead:beaf::52 cannot be configured yet. That keeps the device "connecting".
      """
    Then "connecting" is visible with command "nmcli -g GENERAL.STATE device show testX1"

    * Commentary
      """
      We are unable to configure the route src=2621:dead:beaf::52 yet. NetworkManager
      is internally waiting for some seconds, before considering that condition an
      error. Randomly wait, to either hit that condition or not.
      """
    * Wait for up to "12" random seconds

    * Prepare simulated test "testX2" device with "192.168.52.10" ipv4 and "2621:dead:beaf::52" ipv6 dhcp address prefix
    * Add "ethernet" connection named "x2" for device "testX2" with options "ipv4.method disabled ipv6.routes '2::52/128 src=2621:dead:beaf::52, 2::51/128 src=2620:dead:beaf::51' ipv6.route-metric 162"
    Then Check "inet6" route list on NM device "testX2" matches "fe80::/64\ 1024    2621:dead:beaf::/64\ 162    2621:dead:beaf::52/128\ 162    /::/0\ fe80:.*\ 162    2::51/128\ 162    2::52/128\ 162" in "10" seconds
    Then Check "inet6" route list on NM device "testX1" matches "fe80::/64\ 1024    2620:dead:beaf::/64\ 161    2620:dead:beaf::51/128\ 161    /::/0\ fe80:.*\ 161    1::51/128\ 161    1::52/128\ 161" in "0" seconds
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show testX2"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show testX1"
    Then "2::51 proto static scope global src 2620:dead:beaf::51 metric 162" is visible with command "ip -d -6 route show dev testX2"
    Then "2::52 proto static scope global src 2621:dead:beaf::52 metric 162" is visible with command "ip -d -6 route show dev testX2"
    Then "1::51 proto static scope global src 2620:dead:beaf::51 metric 161" is visible with command "ip -d -6 route show dev testX1"
    Then "1::52 proto static scope global src 2621:dead:beaf::52 metric 161" is visible with command "ip -d -6 route show dev testX1"


    @rhbz2207878
    @ver+=1.43.11
    @ver+=1.42.9
    @ver/rhel/9/2+=1.42.2.8
    @not_enable_ipv6_on_external
    Scenario: NM - ipv6 - do not re-enable IPv6 on the externally connected interface
    * Cleanup execute "echo 0 > /proc/sys/net/ipv6/conf/lo/disable_ipv6"
    * Execute "echo 1 > /proc/sys/net/ipv6/conf/lo/disable_ipv6"
    * Restart NM
    Then "lo\s+loopback\s+connected \(externally\)\s+lo" is visible with command "nmcli device"
    Then "0" is not visible with command "cat /proc/sys/net/ipv6/conf/lo/disable_ipv6"


    @RHEL-5098
    @ver+=1.45.10
    @keyfile
    @ipv6_allow_static_routes_without_address
    Scenario: NM - ipv6 - configuring static routes to device without IPv6 address
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv6.method manual
          ipv6.routes 1010::1/128
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "1010::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"


    @rhbz2284122
    @RHEL-39518
    @fedoraver+=41
    @scapy
    @ipv6_ndp_ipv6_route_information_buffer_overflow
    Scenario: NM - ipv6 - verify correct processing of v6 route information in NDP
    * Cleanup device "veth0"
    * Ensure that version of "libndp" package is at least
      | version      | distro   |
      | 1.9-1.el9    | c9s      |
      | 1.9-1.el10   | rhel10.0 |
      | 1.9-1.el9    | rhel9.5  |
      | 1.8-6.el9_4  | rhel9.4  |
      | 1.8-5.el9_2  | rhel9.2  |
      | 1.8-5.el9_0  | rhel9.0  |
      | 1.7-7.el8_10 | rhel8.10 |
      | 1.7-7.el8_8  | rhel8.8  |
      | 1.7-7.el8_6  | rhel8.6  |
      | 1.7-6.el8_4  | rhel8.4  |
      | 1.7-4.el8_2  | rhel8.2  |
    * Execute "ip link add veth0 type veth peer name veth1"
    * Execute "ip link set dev veth1 up"
    * Add "ethernet" connection named "con_veth0" for device "veth0"
    * Execute "ip link set dev veth0 up"
    * Run child "nmcli c up con_veth0"
    * Wait for "1" seconds
    * Execute reproducer "repro_2284122.py"
    * Wait for "1" seconds
    * Execute reproducer "repro_2284122.py"
    Then "dead" is visible with command "ip a s veth0" in "5" seconds
    * Commentary
        """
        On a system with unfixed libndp, NM should be crashed by now
        """
