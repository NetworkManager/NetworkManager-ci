    Feature: nmcli: ipv6

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @con_ipv6_remove
    @ipv6_method_static_without_IP
    Scenario: nmcli - ipv6 - method - static without IP
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
      * Open editor for connection "con_ipv6"
      * Submit "set ipv6.method static" in editor
      * Save in editor
    Then Error type "ipv6.addresses: this property cannot be empty for" while saving in editor


    @con_ipv6_remove
    @ipv6_method_manual_with_IP
    Scenario: nmcli - ipv6 - method - manual + IP
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method manual" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "2607:f0d0:1002:51::4/64" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/128" is visible with command "ip a s eth3"


    @con_ipv6_remove
    @ipv6_method_static_with_IP
    Scenario: nmcli - ipv6 - method - static + IP
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4, 1050:0:0:0:5:600:300c:326b" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "2607:f0d0:1002:51::4/128" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/128" is visible with command "ip a s eth3"


    @con_ipv6_remove
    @ipv6_addresses_IP_with_netmask
    Scenario: nmcli - ipv6 - addresses - IP slash netmask
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method manual" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4/63, 1050:0:0:0:5:600:300c:326b/121" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "2607:f0d0:1002:51::4/63" is visible with command "ip a s eth3" in "45" seconds
    Then "1050::5:600:300c:326b/121" is visible with command "ip a s eth3"
    # reproducer for 997759
    Then "IPV6_DEFAULTGW" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv6"


    @con_ipv6_remove
    @ipv6_addresses_yes_when_static_switch_asked
    Scenario: nmcli - ipv6 - addresses - IP and yes to manual question
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.addresses dead:beaf::1" in editor
     * Submit "yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     Then "inet6 dead:beaf" is visible with command "ip a s eth10" in "45" seconds
     Then "inet6 2620" is not visible with command "ip a s eth10" in "45" seconds


    @con_ipv6_remove
    @ipv6_addresses_no_when_static_switch_asked
    Scenario: nmcli - ipv6 - addresses - IP and no to manual question
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.addresses dead:beaf::1" in editor
     * Submit "no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     Then "inet6 dead:beaf" is visible with command "ip a s eth10" in "45" seconds
     Then "inet6 2620" is visible with command "ip a s eth10" in "45" seconds


    @con_ipv6_remove @eth0
    @ipv6_addresses_invalid_netmask
    Scenario: nmcli - ipv6 - addresses - IP slash invalid netmask
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4/321" in editor
    Then Error type "failed to set 'addresses' property: invalid prefix '321'; <1-128> allowed" while saving in editor


    @con_ipv6_remove @eth0
    @ipv6_addresses_IP_with_mask_and_gw
    Scenario: nmcli - ipv6 - addresses - IP slash netmask and gw
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2607:f0d0:1002:51::4/64" in editor
     * Submit "set ipv6.gateway 2607:f0d0:1002:51::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "2607:f0d0:1002:51::4/64" is visible with command "ip a s eth3" in "45" seconds
    Then "default via 2607:f0d0:1002:51::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"


    @con_ipv6_remove @eth0
    @ipv6_addresses_set_several_IPv6s_with_masks_and_gws
    Scenario: nmcli - ipv6 - addresses - several IPs slash netmask and gw
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses fc01::1:5/68, fb01::1:6/112" in editor
     * Submit "set ipv6.addresses fc02::1:21/96" in editor
     * Submit "set ipv6.gateway fc01::1:1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "fc02::1:21/96" is visible with command "ip a s eth3" in "45" seconds
    Then "fc01::1:5/68" is visible with command "ip a s eth3"
    Then "fb01::1:6/112" is visible with command "ip a s eth3"
    Then "default via fc01::1:1 dev eth3" is visible with command "ip -6 route"


    @con_ipv6_remove
    @ipv6_addresses_delete_IP_moving_method_back_to_auto
    Scenario: nmcli - ipv6 - addresses - delete IP and set method back to auto
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses fc01::1:5/68" in editor
     * Submit "set ipv6.gateway fc01::1:1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.addresses" in editor
     * Enter in editor
     * Submit "set ipv6.gateway" in editor
     * Enter in editor
     * Submit "set ipv6.method auto" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "fc01::1:5/68" is not visible with command "ip a s eth10" in "45" seconds
    Then "default via fc01::1:1 dev eth3" is not visible with command "ip -6 route"
    Then "2620:52:0:" is visible with command "ip a s eth10"


    @con_ipv6_remove @eth0
    @ver-=1.9.1
    @ipv6_routes_set_basic_route
    Scenario: nmcli - ipv6 - routes - set basic route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2000::2/126" in editor
     * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
     * Save in editor
     * Quit editor
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv62 autoconnect no"
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.routes 3030::1/128 2001::2 1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is visible with command "ip -6 route"


    @rhbz1505893
    @con_ipv6_remove @eth0
    @ver+=1.9.2
    @ipv6_routes_set_basic_route
    Scenario: nmcli - ipv6 - routes - set basic route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2000::2/126" in editor
     * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
     * Save in editor
     * Quit editor
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv62 autoconnect no"
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.routes 3030::1/128 2001::2 1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 100" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 101" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is visible with command "ip -6 route"


    @rhbz1373698
    @ver+=1.8.0
    @ver-=1.9.1
    @con_ipv6_remove
    @ipv6_route_set_route_with_options
    Scenario: nmcli - ipv6 - routes - set route with options
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no ipv6.method manual ipv6.addresses 2000::2/126 ipv6.route-metric 258"
    * Execute "nmcli con modify con_ipv6 ipv6.routes '1010::1/128 2000::1 1024 cwnd=15 lock-mtu=true mtu=1600'"
    * Bring "up" connection "con_ipv6"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 15" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
     And "default" is visible with command "ip r |grep eth0"

    @rhbz1373698
    @ver+=1.9.2
    @con_ipv6_remove
    @ipv6_route_set_route_with_options
    Scenario: nmcli - ipv6 - routes - set route with options
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no ipv6.method manual ipv6.addresses 2000::2/126 ipv6.route-metric 258"
    * Execute "nmcli con modify con_ipv6 ipv6.routes '1010::1/128 2000::1 1024 cwnd=15 lock-mtu=true mtu=1600'"
    * Bring "up" connection "con_ipv6"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 15" is visible with command "ip -6 route" in "45" seconds
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 258" is visible with command "ip -6 route"
     And "default" is visible with command "ip r |grep eth0"


    @con_ipv6_remove @eth0
    @ver-=1.9.1
    @ipv6_routes_remove_basic_route
    Scenario: nmcli - ipv6 - routes - remove basic route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2000::2/126" in editor
     * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
     * Save in editor
     * Quit editor
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv62 autoconnect no"
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.routes 3030::1/128 2001::2 1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.routes" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.routes" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
    Then "2000::2/126" is visible with command "ip a s eth3"
    Then "2001::1/126" is visible with command "ip a s eth2"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is not visible with command "ip -6 route"
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is not visible with command "ip -6 route"


    @rhbz1505893
    @con_ipv6_remove @eth0
    @ver+=1.9.2
    @ipv6_routes_remove_basic_route
    Scenario: nmcli - ipv6 - routes - remove basic route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2000::2/126" in editor
     * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
     * Save in editor
     * Quit editor
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv62 autoconnect no"
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.routes 3030::1/128 2001::2 1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.routes" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "con_ipv62"
     * Submit "set ipv6.routes" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Bring "up" connection "con_ipv62"
    Then "2000::2/126" is visible with command "ip a s eth3"
    Then "2001::1/126" is visible with command "ip a s eth2"
    Then "1010::1 via 2000::1 dev eth3\s+proto static\s+metric 1" is not visible with command "ip -6 route"
    Then "2000::/126 dev eth3\s+proto kernel\s+metric 1" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth2\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2\s+proto static\s+metric 1" is not visible with command "ip -6 route"


    @con_ipv6_remove @eth0
    @ver-=1.9.1
    @ipv6_routes_device_route
    Scenario: nmcli - ipv6 - routes - set device route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes 1010::1/128 :: 3, 3030::1/128 2001::2 2 " in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "3030::1 via 2001::2 dev eth3\s+proto static\s+metric 2" is visible with command "ip -6 route"
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric 3" is visible with command "ip -6 route"


    @con_ipv6_remove @eth0
    @ver+=1.9.2
    @ipv6_routes_device_route
    Scenario: nmcli - ipv6 - routes - set device route
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes 1010::1/128 :: 3, 3030::1/128 2001::2 2 " in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "3030::1 via 2001::2 dev eth3\s+proto static\s+metric 2" is visible with command "ip -6 route"
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric 3" is visible with command "ip -6 route"


    @rhbz1452684
    @con_ipv6_remove
    @ver+=1.10
    @ipv6_routes_with_src
    Scenario: nmcli - ipv6 - routes - set route with src
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no ipv6.method manual ipv6.addresses 2000::2/126 ipv6.route-metric 256"
     * Execute "nmcli con modify con_ipv6 ipv6.routes '1010::1/128 src=2000::2'"
     * Bring "up" connection "con_ipv6"
    Then "1010::1 dev eth3\s+proto static\s+metric 256" is visible with command "ip -6 route"
     And "2000::\/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"


    @rhbz1436531
    @ver+=1.10
    @con_ipv6_remove @flush_300
    @ipv6_route_set_route_with_tables
    Scenario: nmcli - ipv6 - routes - set route with tables
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 ipv6.route-table 300 ipv6.may-fail no"
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
    @ver-=1.10.99
    @con_ipv6_remove @flush_300
    @ipv6_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv6 - routes - set route with tables reapply
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 ipv6.may-fail no"
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
    @con_ipv6_remove @flush_300
    @ipv6_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv4 - routes - set route with tables reapply
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 ipv6.may-fail no"
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


    @con_ipv6_remove
    @ipv6_correct_slaac_setting
    Scenario: NM - ipv6 - correct slaac setting
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 autoconnect no"
     * Execute "nmcli connection modify con_ipv6 ipv6.may-fail no"
     * Bring "up" connection "con_ipv6"
    Then "2620:52:0:.*::/64 dev eth10\s+proto ra" is visible with command "ip -6 r show |grep -v eth0" in "20" seconds
    Then "2620:52:0:" is visible with command "ip -6 a s eth10 |grep global |grep noprefix" in "20" seconds


    @con_ipv6_remove @eth0 @long @tshark @not_on_s390x
    @ipv6_limited_router_solicitation
    Scenario: NM - ipv6 - limited router solicitation
     * Add connection type "ethernet" named "con_ipv6" for device "eth2"
     * Bring "up" connection "con_ipv6"
     * Finish "tshark -i eth2 -Y frame.len==62 -V -x -a duration:120 > /tmp/solicitation.txt"
     When "empty" is not visible with command "file /tmp/solicitation.txt" in "150" seconds
     Then Check solicitation for "eth2" in "/tmp/solicitation.txt"


    @rhbz1068673
    @con_ipv6_remove
    @ipv6_block_just_routing_RA
    Scenario: NM - ipv6 - block just routing RA
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Bring "up" connection "con_ipv6"
    Then "1" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_defrtr"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_rtr_pref"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/accept_ra_pinfo"


    @con_ipv6_remove
    @ipv6_routes_invalid_IP
    Scenario: nmcli - ipv6 - routes - set invalid route - non IP
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes non:rout:set:up" in editor
    Then Error type "failed to set 'routes' property:" while saving in editor


    @con_ipv6_remove @eth0
    @ver-=1.9.1
    @ipv6_routes_without_gw
    Scenario: nmcli - ipv6 - routes - set invalid route - missing gw
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes 1010::1/128" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"

    @con_ipv6_remove @eth0
    @ver+=1.9.2
    @ipv6_routes_without_gw
    Scenario: nmcli - ipv6 - routes - set invalid route - missing gw
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.routes 1010::1/128" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "default via 4000::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route" in "45" seconds
    Then "2001::/126 dev eth3\s+proto kernel\s+metric 100" is visible with command "ip -6 route"
    Then "1010::1 dev eth3\s+proto static\s+metric" is visible with command "ip -6 route"


    @con_ipv6_remove @eth0
    @ipv6_dns_manual_IP_with_manual_dns
    Scenario: nmcli - ipv6 - dns - method static + IP + dns
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.may-fail no" in editor
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.dns 4000::1, 5000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "nameserver 4000::1" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "nameserver 5000::1" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 10." is visible with command "cat /etc/resolv.conf"


    @con_ipv6_remove @eth0
    @ipv6_dns_auto_with_more_manually_set
    Scenario: nmcli - ipv6 - dns - method auto + dns
     * Add connection type "ethernet" named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.may-fail no" in editor
     * Submit "set ipv6.dns 4000::1, 5000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "nameserver 4000::1" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "nameserver 5000::1" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is visible with command "cat /etc/resolv.conf"


    @con_ipv6_remove
    @ipv6_dns_ignore-auto-dns_with_manually_set_dns
    Scenario: nmcli - ipv6 - dns - method auto + dns + ignore automaticaly obtained
     * Add connection type "ethernet" named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.ignore-auto-dns yes" in editor
     * Submit "set ipv6.dns 4000::1, 5000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "nameserver 4000::1" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "nameserver 5000::1" is visible with command "cat /etc/resolv.conf"


    @con_ipv6_remove @eth0
    @ipv6_dns_add_more_when_already_have_some
    Scenario: nmcli - ipv6 - dns - add dns when one already set
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method static" in editor
     * Submit "set ipv6.addresses 2001::1/126" in editor
     * Submit "set ipv6.gateway 4000::1" in editor
     * Submit "set ipv6.dns 4000::1, 5000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.dns 2000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "nameserver 4000::1" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "nameserver 5000::1" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 2000::1" is visible with command "cat /etc/resolv.conf"


    @con_ipv6_remove @eth0
    @ipv6_dns_remove_manually_set
    Scenario: nmcli - ipv6 - dns - method auto then delete all dns
     * Add connection type "ethernet" named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.dns 4000::1, 5000::1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.dns" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "nameserver 4000::1" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 5000::1" is not visible with command "cat /etc/resolv.conf"


    @con_ipv6_remove @eth0
    @ipv6_dns-search_set
    Scenario: nmcli - ipv6 - dns-search - add dns-search
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv4.ignore-auto-dns yes" in editor
     * Submit "set ipv6.dns-search google.com" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "google.com" is visible with command "cat /etc/resolv.conf" in "45" seconds


    @con_ipv6_remove @eth0
    @ipv6_dns-search_remove
    Scenario: nmcli - ipv6 - dns-search - remove dns-search
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv4.ignore-auto-dns yes" in editor
     * Submit "set ipv6.dns-search google.com" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.dns-search" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then " google.com" is not visible with command "cat /etc/resolv.conf"


    @NM @con_ipv6_remove @eth0
    @ipv6_ignore-auto-dns_set
    Scenario: nmcli - ipv6 - ignore auto obtained dns
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv4.ignore-auto-dns yes" in editor
     * Submit "set ipv6.ignore-auto-dns yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then " google.com" is not visible with command "cat /etc/resolv.conf"
    Then "virtual" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver " is not visible with command "cat /etc/resolv.conf" in "45" seconds


    @NM @con_ipv6_remove @eth0
    @ipv6_ignore-auto-dns_set-generic
    Scenario: nmcli - ipv6 - ignore auto obtained dns - generic
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method disabled" in editor
     * Submit "set ipv4.ignore-auto-dns yes" in editor
     * Submit "set ipv6.ignore-auto-dns yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then " google.com" is not visible with command "cat /etc/resolv.conf"
    Then "virtual" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver " is not visible with command "cat /etc/resolv.conf" in "45" seconds


    @con_ipv6_remove
    @ipv6_method_link-local
    Scenario: nmcli - ipv6 - method - link-local
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method link-local" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
    Then "inet6 fe80::" is visible with command "ip -6 a s eth3"
    Then "scope global" is not visible with command "ip -6 a s eth3"


    @con_ipv6_remove
    @ipv6_may_fail_set_true
    Scenario: nmcli - ipv6 - may-fail - set true
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.method dhcp" in editor
     * Submit "set ipv6.may-fail yes" in editor
     * Save in editor
     * Quit editor
    Then Bring "up" connection "con_ipv6"


    @con_ipv6_remove
    @ipv6_method_ignored
    Scenario: nmcli - ipv6 - method - ignored
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv6 autoconnect no"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv4.method static" in editor
     * Submit "set ipv4.addresses 192.168.122.253/24" in editor
     * Submit "set ipv6.method ignore" in editor
     * Save in editor
     * Quit editor
    Then Bring "up" connection "con_ipv6"
    # VVV commented out because of fe80 is still on by kernel very likely
    # Then "scope link" is not visible with command "ip -6 a s eth10"
    Then "scope global" is not visible with command "ip a -6 s eth10" in "45" seconds
    # reproducer for 1004255
    Then Bring "down" connection "con_ipv6"
    Then "eth10 " is not visible with command "ip -6 route |grep -v fe80"


    @rhbz1643841
    @ver+=1.19
    @con_ipv6_remove
    @ipv6_method_disabled
    Scenario: nmcli - ipv6 - method disabled
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname eth3"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is visible with command "ip a show dev eth3"
    * Modify connection "con_ipv6" changing options "ipv6.method disabled"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is not visible with command "ip a show dev eth3"
    * Modify connection "con_ipv6" changing options "ipv6.method auto"
    * Bring "up" connection "con_ipv6"
    Then "inet6" is visible with command "ip a show dev eth3"


    @con_ipv6_remove @eth10_disconnect
    @ipv6_never-default_set_true
    Scenario: nmcli - ipv6 - never-default - set
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.never-default yes " in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "testeth10"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
     * Bring "up" connection "con_ipv6"
    When "default via " is not visible with command "ip -6 route |grep eth10" in "45" seconds
    Then "default via " is not visible with command "ip -6 route |grep eth10" for full "45" seconds


    @con_ipv6_remove @eth10_disconnect
    @ipv6_never-default_remove
    Scenario: nmcli - ipv6 - never-default - remove
     * Add connection type "ethernet" named "con_ipv6" for device "eth10"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.never-default yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "con_ipv6"
     * Open editor for connection "con_ipv6"
     * Submit "set ipv6.never-default" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "testeth10"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
     * Bring "up" connection "con_ipv6"
    When "default via " is visible with command "ip -6 route |grep eth10" in "45" seconds
    Then "default via " is visible with command "ip -6 route |grep eth10" for full "45" seconds


    @not_under_internal_DHCP @con_ipv6_remove @tshark
    @ipv6_dhcp-hostname_set
    Scenario: nmcli - ipv6 - dhcp-hostname - set dhcp-hostname
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv6 autoconnect no"
    * Run child "sudo tshark -i eth2 -f 'port 546' -V -x > /tmp/ipv6-hostname.log"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv6.may-fail true" in editor
    * Submit "set ipv6.method dhcp" in editor
    * Submit "set ipv6.dhcp-hostname r.cx" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    When "empty" is not visible with command "file /tmp/ipv6-hostname.log" in "150" seconds
    Then "r.cx" is visible with command "grep r.cx /tmp/ipv6-hostname.log" in "245" seconds
    * Execute "sudo pkill tshark"


    @not_under_internal_DHCP @con_ipv6_remove @tshark
    @ipv6_dhcp-hostname_remove
    Scenario: nmcli - ipv6 - dhcp-hostname - remove dhcp-hostname
    * Add connection type "ethernet" named "con_ipv6" for device "eth2"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv6.may-fail true" in editor
    * Submit "set ipv6.method dhcp" in editor
    * Submit "set ipv6.dhcp-hostname r.cx" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    * Bring "down" connection "con_ipv6"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv6.dhcp-hostname" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    * Bring "down" connection "con_ipv6"
    * Run child "sudo tshark -i eth2 -f 'port 546' -V -x > /tmp/tshark.log"
    * Bring "up" connection "con_ipv6"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Finish "sleep 5"
    * Execute "sudo pkill tshark"
    Then "r.cx" is not visible with command "cat /tmp/tshark.log" in "45" seconds


    @restore_hostname @con_ipv6_remove @eth2_disconnect @tshark
    @ipv6_send_fqdn.fqdn_to_dhcpv6
    Scenario: NM - ipv6 - - send fqdn.fqdn to dhcpv6
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv6 autoconnect no"
    * Execute "hostnamectl set-hostname dacan.local"
    * Run child "sudo tshark -i eth2 -f 'port 546' -V -x > /tmp/ipv6-hostname.log"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv6.method dhcp" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    When "empty" is not visible with command "file /tmp/ipv6_hostname.log" in "150" seconds
    Then "dacan.local" is visible with command "cat /tmp/ipv6-hostname.log" in "145" seconds
     And "0. = O bit" is visible with command "cat /tmp/ipv6-hostname.log"
    * Execute "sudo pkill tshark"


    @con_ipv6_remove @teardown_testveth
    @ipv6_secondary_address
    Scenario: nmcli - ipv6 - secondary
    * Prepare simulated test "testX6" device
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6"
    * Bring "up" connection "con_ipv6"
    Then "2" is visible with command "ip a s testX6 |grep 'inet6 .* global' |wc -l" in "45" seconds


    @con_ipv6_remove
    @ipv6_ip6-privacy_0
    Scenario: nmcli - ipv6 - ip6_privacy - 0
    * Add connection type "ethernet" named "con_ipv6" for device "eth10"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 2" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    * Finish "sleep 2"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv6.ip6-privacy 0" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"
    Then "global temporary dynamic" is not visible with command "ip a s eth10" in "45" seconds


    @con_ipv6_remove
    @ipv6_ip6-privacy_1
    Scenario: nmcli - ipv6 - ip6_privacy - 1
    * Add connection type "ethernet" named "con_ipv6" for device "eth10"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 1" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"
    Then Global temporary ip is not based on mac of device "eth10"


    @con_ipv6_remove
    @ipv6_ip6-privacy_2
    Scenario: nmcli - ipv6 - ip6_privacy - 2
    * Add connection type "ethernet" named "con_ipv6" for device "eth10"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 2" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv6"
    When "2620" is visible with command "ip a s eth10" in "45" seconds
     And "tentative dynamic" is not visible with command "ip a s eth10" in "45" seconds
    Then "2" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr" in "45" seconds
    Then Global temporary ip is not based on mac of device "eth10"


    @rhbz1187525
    @con_ipv6_remove @privacy @restart
    @ipv6_ip6-default_privacy
    Scenario: nmcli - ipv6 - ip6_privacy - default value
    * Execute "echo 1 > /proc/sys/net/ipv6/conf/default/use_tempaddr"
    * Add connection type "ethernet" named "con_ipv6" for device "eth10"
    * Bring "up" connection "con_ipv6"
    When "1" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"
    * Execute "echo '[connection.ip6-privacy]' > /etc/NetworkManager/conf.d/01-default-ip6-privacy.conf"
    * Execute "echo 'ipv6.ip6-privacy=2' >> /etc/NetworkManager/conf.d/01-default-ip6-privacy.conf"
    * Restart NM
    * Bring "down" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    When "2" is visible with command "cat /proc/sys/net/ipv6/conf/eth10/use_tempaddr"


    @con_ipv6_remove
    @ver-=1.11.2
    @ipv6_ip6-privacy_incorrect_value
    Scenario: nmcli - ipv6 - ip6_privacy - incorrect value
    * Add connection type "ethernet" named "con_ipv6" for device "eth3"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 3" in editor
    Then Error type "failed to set 'ip6-privacy' property: '3' is not valid\; use 0, 1, or 2" while saving in editor
    * Submit "set ipv6.ip6-privacy RHX" in editor
    Then Error type "failed to set 'ip6-privacy' property: 'RHX' is not a number" while saving in editor


    @con_ipv6_remove
    @ver+=1.11.3
    @ipv6_ip6-privacy_incorrect_value
    Scenario: nmcli - ipv6 - ip6_privacy - incorrect value
    * Add connection type "ethernet" named "con_ipv6" for device "eth3"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.ip6-privacy 3" in editor
    Then Error type "failed to set 'ip6-privacy' property: invalid option '3', use one of \[unknown,disabled,prefer-public-addr,prefer-temp-addr\]" while saving in editor
    * Submit "set ipv6.ip6-privacy RHX" in editor
    Then Error type "failed to set 'ip6-privacy' property: invalid option 'RHX', use one of \[unknown,disabled,prefer-public-addr,prefer-temp-addr\]" while saving in editor


    @rhbz1073824
    @veth @con_ipv6_remove @restart
    @ipv6_take_manually_created_ifcfg
    Scenario: ifcfg - ipv6 - use manually created link-local profile
    * Append "DEVICE='eth10'" to ifcfg file "con_ipv6"
    * Append "ONBOOT=yes" to ifcfg file "con_ipv6"
    * Append "NETBOOT=yes" to ifcfg file "con_ipv6"
    * Append "UUID='aa17d688-a38d-481d-888d-6d69cca781b8'" to ifcfg file "con_ipv6"
    * Append "BOOTPROTO=dhcp" to ifcfg file "con_ipv6"
    * Append "TYPE=Ethernet" to ifcfg file "con_ipv6"
    * Append "NAME='con_ipv6'" to ifcfg file "con_ipv6"
    * Restart NM
    Then "aa17d688-a38d-481d-888d-6d69cca781b8" is visible with command "nmcli -f UUID connection show -a"


    @rhbz1640237
    @ver+=1.16
    @scapy
    @ipv6_lifetime_too_low
    Scenario: NM - ipv6 - valid lifetime too low should be ignored
    * Finish "ip link add test10 type veth peer name test11"
    * Finish "nmcli c add type ethernet ifname test10"
    * Finish "nmcli c add type ethernet ifname test11"
    * Execute "nmcli con modify ethernet-test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet-test11 ipv4.method disabled ipv6.method auto ipv6.address dead::dead/128 ipv6.gateway dead::beaf/128"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Execute "sleep 2"
    * Send lifetime scapy packet with lifetimes "300" "140"
    * Execute "sleep 2"
    * Send lifetime scapy packet with lifetimes "20" "10"
    * Execute "sleep 2"
    Then "IPv6" lifetimes are slightly smaller than "300" and "10" for device "test11"
    * Execute "sleep 2"
    * Send lifetime scapy packet with lifetimes "7600" "7400"
    * Execute "sleep 2"
    * Send lifetime scapy packet with lifetimes "20" "10"
    * Execute "sleep 2"
    # there is 7200 here (2h), because of RFC 4862, section-5.5.3.e).3.
    Then "IPv6" lifetimes are slightly smaller than "7200" and "10" for device "test11"


    @rhbz1318945
    @ver+=1.4.0
    @scapy
    @ipv6_lifetime_no_padding
    Scenario: NM - ipv6 - RA lifetime with no padding
    * Finish "ip link add test10 type veth peer name test11"
    * Finish "nmcli c add type ethernet ifname test10"
    * Finish "nmcli c add type ethernet ifname test11"
    * Execute "nmcli con modify ethernet-test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet-test11 ipv4.method disabled ipv6.method auto ipv6.address dead::dead/128 ipv6.gateway dead::beaf/128"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Execute "sleep 2"
    * Send lifetime scapy packet
    Then "IPv6" lifetimes are slightly smaller than "3600" and "1800" for device "test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_with_low_hlimit
    Scenario: NM - ipv6 - drop scapy packet with lower hop limit
    * Finish "ip link add test10 type veth peer name test11"
    * Finish "nmcli c add type ethernet ifname test10"
    * Finish "nmcli c add type ethernet ifname test11"
    * Execute "nmcli con modify ethernet-test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet-test11 ipv4.method disabled ipv6.method auto ipv6.address dead::dead/128 ipv6.gateway dead::beaf/128"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Execute "sleep 2"
    * Send lifetime scapy packet with "250"
    Then "valid_lft forever preferred_lft forever" is visible with command "ip a s test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_with_255_hlimit
    Scenario: NM - ipv6 - scapy packet with 255 hop limit
    * Finish "ip link add test10 type veth peer name test11"
    * Finish "nmcli c add type ethernet ifname test10"
    * Finish "nmcli c add type ethernet ifname test11"
    * Execute "nmcli con modify ethernet-test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet-test11 ipv4.method disabled ipv6.method auto ipv6.address dead::dead/128 ipv6.gateway dead::beaf/128"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Execute "sleep 2"
    * Send lifetime scapy packet with "255"
    Then "IPv6" lifetimes are slightly smaller than "3605" and "1805" for device "test11"


    @rhbz1329366
    @ver+=1.4.0
    @scapy
    @ipv6_drop_ra_from_non_ll_address
    Scenario: NM - ipv6 - drop scapy packet from non LL address
    * Finish "ip link add test10 type veth peer name test11"
    * Finish "nmcli c add type ethernet ifname test10"
    * Finish "nmcli c add type ethernet ifname test11"
    * Execute "nmcli con modify ethernet-test10 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet-test11 ipv4.method disabled ipv6.method auto ipv6.address dead::dead/128 ipv6.gateway dead::beaf/128"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test11 up"
    * Execute "nmcli --wait 0 c up ethernet-test10"
    * Execute "nmcli --wait 0 c up ethernet-test11"
    When "ethernet-test10" is visible with command "nmcli con sh -a"
    When "ethernet-test11" is visible with command "nmcli con sh -a"
    * Execute "sleep 2"
    * Send lifetime scapy packet from "ff02::1"
    Then "valid_lft forever preferred_lft forever" is visible with command "ip a s test11"


    @rhbz1170530
    @add_testeth10 @con_ipv6_remove @restart
    @ipv6_keep_connectivity_on_assuming_connection_profile
    Scenario: NM - ipv6 - keep connectivity on assuming connection profile
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname eth10 autoconnect no"
    * Bring up connection "con_ipv6"
    * Wait for at least "20" seconds
    Then Check ipv6 connectivity is stable on assuming connection profile "con_ipv6" for device "eth10"


    @rhbz1083133 @rhbz1098319 @rhbz1127718
    @veth @eth3_disconnect
    #@ver-=1.11.1
    @ipv6_add_static_address_manually_not_active
    Scenario: NM - ipv6 - add a static address manually to non-active interface (legacy 1.10 behavior and older)
    Given "testeth3" is visible with command "nmcli connection"
    Given "eth3\s+ethernet\s+connected" is not visible with command "nmcli device"
    Given "state UP" is visible with command "ip a s eth3"
    * "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    * Execute "ip -6 addr add 2001::dead:beef:01/64 dev eth3"
    Then "0" is visible with command "cat /proc/sys/net/ipv6/conf/eth3/disable_ipv6"
    Then "inet6 2001::dead:beef:1/64 scope global" is visible with command "ip a s eth3"
    # Newer versions of NM no longer create IPv6 LL addresses for externally assumed devices.
    # This test is obsoleted by @ipv6_add_static_address_manually_not_active (1.12+), but this
    # behavior won't be backported to older versions.
    Then "addrgenmode none " is visible with command "ip -d l show eth3"
    Then "inet6 fe80" is visible with command "ip a s eth3" in "45" seconds
    # the assumed connection is created, give just some time for DAD to complete
    Then "eth3\s+ethernet\s+connected\s+eth3" is visible with command "nmcli device" in "45" seconds


    @rhbz1083133 @rhbz1098319 @rhbz1127718
    @veth @eth3_disconnect
    @ver+=1.11.2
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
    # the connection is assumed externally, meaning it has "addrgenmode none". NM is not
    # interferring with the device, hence there is no IPv6 LL address. Which is a problem,
    # but a problem of the user who takes over the device without setting the addrgenmode
    # to its liking.
    Then "addrgenmode none " is visible with command "ip -d l show eth3"
    Then "inet6 fe80" is not visible with command "ip a s eth3" for full "45" seconds
    #
    # the assumed connection is created, give just some time for DAD to complete
    Then "eth3\s+ethernet\s+connected\s+eth3" is visible with command "nmcli device"


    @rhbz1138426
    @restart @add_testeth10
    @ipv6_no_assumed_connection_for_ipv6ll_only
    Scenario: NM - ipv6 - no assumed connection on IPv6LL only device
    * Delete connection "testeth10"
    * Stop NM
    * Execute "ip a flush dev eth10; ip l set eth10 down; ip l set eth10 up"
    When "fe80" is visible with command "ip a s eth10" in "45" seconds
    * Execute "systemctl start NetworkManager.service"
    Then "eth10.*eth10" is not visible with command "nmcli con"


    @rhbz1194007
    @ver+=1.8
    @mtu @kill_dnsmasq_ip6
    @ipv6_set_ra_announced_mtu
    Scenario: NM - ipv6 - set RA received MTU
    * Finish "ip link add test10 type veth peer name test10p"
    * Finish "ip link add test11 type veth peer name test11p"
    * Finish "ip link add name vethbr6 type bridge forward_delay 2 stp_state 1"
    * Finish "ip link set dev vethbr6 up"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test10p up"
    * Finish "ip link set dev test11 up"
    * Finish "ip link set dev test11p up"
    * Finish "ip link set dev test10p master vethbr6"
    * Finish "ip link set dev test11p master vethbr6"
    * Finish "nmcli connection add type ethernet con-name tc16 ifname test10 autoconnect no"
    * Finish "nmcli connection add type ethernet con-name tc26 ifname test11 autoconnect no mtu 1100 ip6 fd01::1/64"
    * Bring "up" connection "tc26"
    When "test11:connected:tc26" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "45" seconds
    * Execute "/usr/sbin/dnsmasq --pid-file=/tmp/dnsmasq_ip6.pid --no-resolv --bind-interfaces -i test11 --enable-ra --dhcp-range=::1,::400,constructor:test11,ra-only,64,15s"
    * Bring "up" connection "tc16"
    Then "1280" is visible with command "sysctl net.ipv6.conf.test10.mtu" in "45" seconds


    @rhbz1243958
    @ver+=1.4.0
    @eth0 @mtu
    @nm-online_wait_for_ipv6_to_finish
    Scenario: NM - ipv6 - nm-online wait for non tentative ipv6
    * Finish "ip link add test10 type veth peer name test10p"
    * Finish "ip link set dev test10 up"
    * Finish "ip link set dev test10p up"
    * Finish "nmcli connection add type ethernet con-name tc16 ifname test10 autoconnect no ip4 192.168.99.1/24 ip6 2620:52:0:beef::1/64"
    * Finish "nmcli connection modify tc16 ipv6.may-fail no"
    Then "tentative" is not visible with command "nmcli connection down testeth0 ; nmcli connection down tc16; sleep 2; nmcli connection up id tc16; time nm-online ;ip a s test10|grep 'global tentative'; nmcli connection up testeth0"


    @ver-=1.5
    @rhbz1183015
    @con_ipv6_remove
    @ipv6_shared_connection_error
    Scenario: NM - ipv6 - shared connection
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname eth3 autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv4.method disabled ipv6.method shared"
    Then "Sharing IPv6 connections is not supported yet" is visible with command "nmcli connection up id con_ipv6"


    @rhbz1256822
    @ver+=1.6
    @con_ipv6_remove @two_bridged_veths6
    @ipv6_shared_connection
    Scenario: nmcli - ipv6 - shared connection
    * Prepare veth pairs "test10,test11" bridged over "vethbr6"
    * Add a new connection of type "ethernet" and options "con-name tc26 ifname test11 ipv6.method shared ipv6.addresses 1::1/64"
    * Add a new connection of type "ethernet" and options "con-name tc16 ifname test10"
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
    @con_ipv6_remove @teardown_testveth
    @ipv6_no_activation_schedule_error_in_logs
    Scenario: NM - ipv6 - no activation scheduled error
    * Prepare simulated test "testA6" device
    * Add connection type "ethernet" named "con_ipv6" for device "testA6"
    * Execute "nmcli connection modify con_ipv6 ipv6.may-fail no ipv4.method disabled"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    Then "activation_source_schedule" is not visible with command "journalctl --since -4m|grep error"


    @rhbz1268866
    @con_ipv6_remove @internal_DHCP @teardown_testveth @long
    @ipv6_NM_stable_with_internal_DHCPv6
    Scenario: NM - ipv6 - stable with internal DHCPv6
    * Prepare simulated test "testX6" device
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6 autoconnect no"
    * Open editor for connection "con_ipv6"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.method dhcp" in editor
    * Save in editor
    * Quit editor
    * Execute "nmcli con up id con_ipv6" for "100" times

    @ver-=1.6
    @con_ipv6_remove @restart @selinux_allow_ifup @teardown_testveth
    @persistent_default_ipv6_gw
    Scenario: NM - ipv6 - persistent default ipv6 gw
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6"
    * Wait for at least "3" seconds
    * Stop NM
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for at least "10" seconds
    * Execute "ip r del 169.254.0.0/16"
    When "default" is visible with command "ip -6 r |grep testX6" in "20" seconds
    And "default" is visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds
    * Restart NM
    Then "default via fe" is visible with command "ip -6 r |grep testX6 |grep 'metric 1'" in "50" seconds
    And "default via fe" is not visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds


    @ver+=1.7 @ver-=1.10.0
    @con_ipv6_remove @restart @selinux_allow_ifup @teardown_testveth
    @persistent_default_ipv6_gw
    Scenario: NM - ipv6 - persistent default ipv6 gw
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6"
    * Wait for at least "3" seconds
    * Stop NM
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for at least "10" seconds
    * Execute "ip r del 169.254.0.0/16"
    When "default" is visible with command "ip -6 r |grep testX6" in "20" seconds
    And "default" is visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds
    * Restart NM
    * Wait for at least "10" seconds
    Then "default via fe" is visible with command "ip -6 r |grep testX6 |grep 'metric 1024'" in "50" seconds
    And "default via fe" is not visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds


    @ver+=1.10.1
    @skip_in_ootpa @skip_in_fedora #as we have no initscripts anymore
    @con_ipv6_remove @restart @selinux_allow_ifup @teardown_testveth
    @persistent_default_ipv6_gw
    Scenario: NM - ipv6 - persistent default ipv6 gw
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6"
    * Wait for at least "3" seconds
    * Stop NM
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for at least "20" seconds
    When "default" is visible with command "ip -6 r |grep testX6" in "20" seconds
    And "default" is visible with command "ip -6 r |grep testX6 |grep expire" in "45" seconds
    * Restart NM
    Then "default via fe" is visible with command "ip -6 r |grep testX6 |grep expire" for full "20" seconds
     And "default via fe" is visible with command "ip -6 r |grep testX6 |grep 'metric 1024'" in "50" seconds


    @rhbz1274894
    @ver+=1.9.2
    @skip_in_ootpa @skip_in_fedora #as we have no initscripts anymore
    @con_ipv6_remove @restart @selinux_allow_ifup @teardown_testveth
    @persistent_ipv6_routes
    Scenario: NM - ipv6 - persistent ipv6 routes
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6 ipv4.method disabled"
    * Wait for at least "3" seconds
    * Stop NM
    * Execute "rm -rf /var/run/NetworkManager"
    * Prepare simulated test "testX6" device
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_defrtr=1"
    * Execute "sysctl net.ipv6.conf.testX6.accept_ra_pinfo=1"
    * Execute "ifup testX6"
    * Wait for at least "10" seconds
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
    @ver+=1.8.0
    @con_ipv6_remove @rhel7_only
    @ipv6_honor_ip_order
    Scenario: NM - ipv6 - honor IP order from configuration upon reapply
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname eth2 autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv6.method manual ipv6.addresses 2001:db8:e:10::4/64,2001:db8:e:10::57/64,2001:db8:e:10::30/64"
    * Bring "up" connection "con_ipv6"
    When "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2" in "45" seconds
    * Execute "nmcli con modify con_ipv6 ipv6.addresses 2001:db8:e:10::30/64,2001:db8:e:10::57/64,2001:db8:e:10::4/64"
    * Execute "nmcli dev reapply eth2"
    Then "2001:db8:e:10::4/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::30/64" is visible with command "ip a show eth2"


    @rhbz1394500
    @ver+=1.8.0
    @con_ipv6_remove @not_in_rhel
    @ipv6_honor_ip_order
    Scenario: NM - ipv6 - honor IP order from configuration upon reapply
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname eth2 autoconnect no"
    * Execute "nmcli con modify con_ipv6 ipv6.method manual ipv6.addresses 2001:db8:e:10::4/64,2001:db8:e:10::57/64,2001:db8:e:10::30/64"
    * Bring "up" connection "con_ipv6"
    When "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2" in "45" seconds
    * Execute "nmcli con modify con_ipv6 ipv6.addresses 2001:db8:e:10::30/64,2001:db8:e:10::57/64,2001:db8:e:10::4/64"
    * Execute "nmcli dev reapply eth2"
    Then "2001:db8:e:10::30/64 scope global.*2001:db8:e:10::57/64 scope global.*2001:db8:e:10::4/64" is visible with command "ip a show eth2"


    @con_ipv6_remove
    @ver-=1.19.1
    @ipv6_describe
    Scenario: nmcli - ipv6 - describe
     * Add connection type "ethernet" named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv6"
     * Submit "goto ipv6" in editor
     Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty." are present in describe output for object "method"

     Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses of DNS servers." are present in describe output for object "dns"
     Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+Array of DNS search domains." are present in describe output for object "dns-search"
     Then Check "=== \[addresses\] ===\s+\[NM property description\]\s+Array of IP addresses.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses formatted as:\s+ip\[/prefix\], ip\[/prefix\],...\s+Missing prefix is regarded as prefix of 128.\s+Example: 2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b" are present in describe output for object "addresses"
     Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes." are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured nameservers and search domains are ignored and only nameservers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"


    @con_ipv6_remove
    @ver+=1.19.2
    @ipv6_describe
    Scenario: nmcli - ipv6 - describe
     * Add connection type "ethernet" named "con_ipv6" for device "eth3"
     * Open editor for connection "con_ipv6"
     When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv6"
     * Submit "goto ipv6" in editor

     Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"disabled\", \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty. For IPv4 method \"shared\", the IP subnet can be configured by adding one manual IPv4 address or otherwise 10.42.x.0\/24 is chosen. Note that the shared method must be configured on the interface which shares the internet to a subnet, not on the uplink which is shared." are present in describe output for object "method"

     Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses of DNS servers." are present in describe output for object "dns"
     Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+Array of DNS search domains." are present in describe output for object "dns-search"
     Then Check "=== \[addresses\] ===\s+\[NM property description\]\s+Array of IP addresses.\s+\[nmcli specific description\]\s+Enter a list of IPv6 addresses formatted as:\s+ip\[/prefix\], ip\[/prefix\],...\s+Missing prefix is regarded as prefix of 128.\s+Example: 2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b" are present in describe output for object "addresses"
     Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes." are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured nameservers and search domains are ignored and only nameservers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"


    @rhbz1449873
    @ver+=1.8.0
    @AAA
    @ipv6_keep_external_addresses
    Scenario: NM - ipv6 - keep external addresses
    * Execute "ip link add AAA type dummy"
    * Execute "ip link set dev AAA up"
    * Wait for at least "1" seconds
    * Execute "for i in $(seq 3000); do ip addr add 2017::$i/64 dev AAA; done"
    When "3000" is visible with command "ip addr show dev AAA | grep 'inet6 2017::' -c" in "2" seconds
    Then "3000" is visible with command "ip addr show dev AAA | grep 'inet6 2017::' -c" for full "6" seconds


    @rhbz1457242
    @ver+=1.8.0
    @eth3_disconnect
    @ipv6_keep_external_routes
    Scenario: NM - ipv6 - keep external routes
    * Execute "ip link set eth3 down; ip addr flush eth3; ethtool -A eth3 rx off tx off; ip link set eth3 up"
    * Execute "ip addr add fc00:a::10/64 dev eth3; ip -6 route add fc00:b::10/128 via fc00:a::1"
    When "fc00:b" is visible with command "ip -6 r" in "2" seconds
    Then "fc00:b" is visible with command "ip -6 r" for full "45" seconds


    @rhbz1446367
    @ver+=1.8.0
    @ethernet @teardown_testveth
    @nmcli_general_finish_dad_without_carrier
    Scenario: nmcli - general - finish dad with no carrier
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name ethernet0 autoconnect no"
    * Prepare simulated veth device "testX6" wihout carrier
    * Execute "nmcli con modify ethernet0 ipv4.may-fail no ipv4.method manual ipv4.addresses 1.2.3.4/24"
    * Execute "nmcli con modify ethernet0 ipv4.may-fail yes ipv6.method manual ipv6.addresses 2001::2/128"
    * Bring "up" connection "ethernet0"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE connection show ethernet0" in "45" seconds
     And "1.2.3.4" is visible with command "ip a s testX6"
     And "2001::2" is visible with command "ip a s testX6"
     And "tentative" is visible with command "ip a s testX6" for full "45" seconds


    @rhbz1508001
    @ver+=1.10.0
    @con_ipv6_remove @teardown_testveth @restart
    @ipv4_dad_not_preventing_ipv6
    Scenario: NM - ipv6 - add address after ipv4 DAD fail
    * Prepare simulated test "testX6" device
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6 ipv4.may-fail yes ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 2001 ipv6.may-fail yes"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE connection show con_ipv6" in "145" seconds
     And "2620:dead:beaf" is visible with command "ip a s testX6"


    @rhbz1470930
    @ver+=1.8.3
    @ethernet @teardown_testveth @netcat
    @ipv6_preserve_cached_routes
    Scenario: NM - ipv6 - preserve cached routes
    * Prepare simulated test "testX6" device for IPv6 PMTU discovery
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name ethernet0 autoconnect no"
    * Execute "nmcli con modify ethernet0 ipv4.method disabled ipv6.method auto"
    * Execute "nmcli con modify ethernet0 ipv6.routes 'fd02::/64 fd01::1'"
    * Execute "ip l set testX6 up"
    * Bring "up" connection "ethernet0"
    * Execute "dd if=/dev/zero bs=1M count=10 | nc fd02::2 8080"
    Then "mtu 1400" is visible with command "ip route get fd02::2" for full "40" seconds


    @rhbz1368018
    @ver+=1.8
    @con_ipv6_ifcfg_remove @con_ipv6_remove @restart @kill_dhclient @teardown_testveth
    @persistent_ipv6_after_device_rename
    Scenario: NM - ipv6 - persistent ipv6 after device rename
    * Prepare simulated test "testX6" device
    * Add a new connection of type "ethernet" and options "ifname testX6 con-name con_ipv6"
    * Bring "down" connection "con_ipv6"
    * Bring "up" connection "con_ipv6"
    * Execute "echo -e 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-con_ipv6"
    * Restart NM
    When "0" is visible with command "cat /proc/sys/net/ipv6/conf/testX6/disable_ipv6"
    * Rename device "testX6" to "festY"
    * Execute "dhclient -1 festY" without waiting for process to finish
    * Wait for at least "45" seconds
    * Execute "kill -9 $(pidof dhclient)"
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
    @con_ipv6_remove @stop_radvd @two_bridged_veths6 @eth0
    @ipv6_multiple_default_routes
    Scenario: NM - ipv6 - multiple default ipv6 routes
    * Prepare veth pairs "test10" bridged over "vethbr6"
    * Execute "ip -6 addr add dead:beef::1/64 dev vethbr6"
    * Execute "ip -6 addr add beef:dead::1/64 dev test10p"
    * Execute "ip -6 addr add fe80::dead:dead:dead:dead/64 dev test10p"
    * Start radvd server with config from "tmp/radvd.conf"
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname test10 ipv6.may-fail no"
    Then "2" is visible with command "ip -6 r | grep default -A 3|grep 'via fe80' |grep test10 |wc -l" in "60" seconds


    @rhbz1414093
    @ver+=1.12
    @con_ipv6_remove
    @ipv6_duid
    Scenario: NM - ipv6 - test ipv6.dhcp-duid option
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname test10"
    Then Modify connection "con_ipv6" changing options "ipv6.dhcp-duid 01:23:45:67:ab"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid lease"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid ll"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid llt"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-ll"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-llt"
     And Modify connection "con_ipv6" changing options "ipv6.dhcp-duid stable-uuid"


    @rhbz1369905
    @ver+=1.16
    @con_ipv6_remove @teardown_testveth
    @ipv6_manual_addr_before_dhcp
    Scenario: nmcli - ipv6 - set manual values immediately
    * Prepare simulated test "testX6" device
    * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname testX6 autoconnect no ipv4.may-fail no ipv6.method dhcp ipv6.addresses 2000::1/128 ipv6.routes '1010::1/128 2000::2 101'"
    * Execute "ip netns exec testX6_ns kill -SIGSTOP $(cat /tmp/testX6_ns.pid)"
    * Run child "sleep 10 && ip netns exec testX6_ns kill -SIGCONT $(cat /tmp/testX6_ns.pid)"
    * Run child "sleep 2 && nmcli con up con_ipv6"
    Then "2000::1/128" is visible with command "ip a s testX6" in "5" seconds
     And "1010::1 via 2000::2 dev testX6\s+proto static\s+metric 10[0-1]" is visible with command "ip -6 route"
     And "2000::1 dev testX6 proto kernel metric 10[0-1] pref medium" is visible with command "ip -6 route"
     And "2000::2 dev testX6 proto static metric 10[0-1] pref medium" is visible with command "ip -6 route"
     # And "namespace 192.168.3.11" is visible with command "cat /etc/resolv.conf" in "10" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv6" in "45" seconds


     @rhbz1548237
     @ver+=1.18.0
     @con_ipv6_remove @teardown_testveth
     @ipv6_survive_external_link_restart
     Scenario: nmcli - ipv6 - survive external link restart
     * Prepare simulated test "testX6" device
     * Add a new connection of type "ethernet" and options "con-name con_ipv6 ifname testX6 ipv6.may-fail no"
     * Add a new connection of type "ethernet" and options "con-name con_ipv62 ifname eth3"
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
