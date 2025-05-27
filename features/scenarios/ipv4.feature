Feature: nmcli: ipv4

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ipv4_method_static_no_IP
    Scenario: nmcli - ipv4 - method - static without IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Save in editor
    Then Error type "connection verification failed: ipv4" while saving in editor


    @rhbz979288
    @ipv4_method_manual_with_IP
    Scenario: nmcli - ipv4 - method - manual + IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.122.253
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.122.253/32" is visible with command "ip a s eth3"
    Then "dhclient-eth3.pid" is not visible with command "ps aux|grep dhclient"


    @ipv4_method_static_with_IP
    Scenario: nmcli - ipv4 - method - static + IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.122.253/32" is visible with command "ip a s eth3"


    @ipv4_addresses_manual_when_asked
    Scenario: nmcli - ipv4 - addresses - IP allowing manual when asked
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.addresses 192.168.122.253" in editor
    * Submit "yes" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv4"
    Then "192.168.122.253/32" is visible with command "ip a s eth3"


    @rhbz1034900
    @ipv4_addresses_IP_slash_mask
    Scenario: nmcli - ipv4 - addresses - IP slash netmask
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.122.253/24 brd 192.168.122.255" is visible with command "ip a s eth3"


    @ipv4_change_in_address
    Scenario: nmcli - ipv4 - addresses - change in address
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method manual" in editor
    * Submit "set ipv4.addresses 1.1.1.99/24" in editor
    * Submit "set ipv4.gateway 1.1.1.1" in editor
    * Save in editor
    * Submit "goto ipv4" in editor
    * Submit "goto gateway" in editor
    * Submit "change" in editor
    * Backspace in editor
    * Submit "4" in editor
    * Submit "back" in editor
    * Submit "back" in editor
    * Save in editor
    * Submit "print" in editor
    * Quit editor
    * Bring "up" connection "con_ipv4"
    Then "1.1.1.99/24 brd 1.1.1.255" is visible with command "ip a s eth3"
    Then "default via 1.1.1.4" is visible with command "ip route"
    Then "default via 1.1.1.1" is not visible with command "ip route"


    @ipv4_addresses_IP_slash_invalid_mask
    Scenario: nmcli - ipv4 - addresses - IP slash invalid netmask
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/192.168.122.1" in editor
    Then Error type "failed to set 'addresses' property: invalid prefix '192.168.122.1'; <[01]-32> allowed" while saving in editor


    @rhbz1073824
    @delete_testeth0 @restart_if_needed
    @ipv4_take_manually_created_keyfile_with_ip
    Scenario: nmcli - ipv4 - use manually created ipv4 profile
    * Create keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection"
      """
      [connection]
      uuid=aa17d688-a38d-481d-888d-6d69cca781b8
      autoconnect=yes
      interface-name=eth3
      type=ethernet
      id=con_ipv4

      [ipv4]
      method=manual
      address1=10.0.0.2/24,10.0.0.1
      """
    * Restart NM
    Then "aa17d688-a38d-481d-888d-6d69cca781b8" is visible with command "nmcli -f UUID connection show -a" in "5" seconds


    @ipv4_addresses_IP_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - IP slash netmask and route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.96
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.122.253/24" is visible with command "ip a s eth3"
    Then "default via 192.168.122.96 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.253" is visible with command "ip route"
    Then "eth0" is visible with command "ip r |grep 'default via 1'" in "5" seconds
    Then "eth3" is visible with command "ip r |grep 'default via 1'" in "5" seconds


    @ipv4_addresses_more_IPs_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - several IPs slash netmask and route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses '192.168.22.253/24, 192.168.122.253/16, 192.168.222.253/8'
          ipv4.gateway 192.168.22.96
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.22.253/24" is visible with command "ip a s eth3"
    Then "192.168.122.253/16" is visible with command "ip a s eth3"
    Then "192.168.222.253/8" is visible with command "ip a s eth3"
    Then "default via 192.168.22.96 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "eth3" is visible with command "ip r |grep 'default via 1'" in "5" seconds


    @rhbz663730
    @ver+=1.9.2
    @route_priorities
    Scenario: nmcli - ipv4 - route priorities
     * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "autoconnect no ipv4.may-fail no"
     * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "autoconnect no ipv4.may-fail no"
     * Bring "up" connection "con_ipv4"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2"
     When "metric 1" is visible with command "ip r |grep default |grep eth3"
     * Modify connection "con_ipv42" changing options "ipv4.route-metric 200"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2"
     When "metric 200" is visible with command "ip r |grep default |grep eth3"
     * Modify connection "con_ipv42" changing options "ipv4.route-metric -1"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2"
     When "metric 1" is visible with command "ip r |grep default |grep eth3"


    @rhbz1943153
    @ver+=1.39.3
    @ipv4_method_back_to_auto
    Scenario: nmcli - ipv4 - addresses - delete IP and set method back to auto
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses '192.168.22.253/24, 192.168.122.253/16'
          ipv4.gateway 192.168.22.96
          """
    * Modify connection "con_ipv4" changing options "ipv4.method auto ipv4.addresses '' ipv4.gateway ''"
    * Bring "up" connection "con_ipv4"
    Then "192.168.22.253/24" is not visible with command "ip a s eth3"
    Then "192.168.22.96" is not visible with command "ip route"
    Then "192.168.122.253/24" is not visible with command "ip a s eth3"
    Then "192.168.122.95" is not visible with command "ip route"
    Then "dhcp4.dhcp_server_identifier" is visible with command "cat /run/NetworkManager/devices/$(ip link show eth3 | cut -d ':' -f 1 | head -n 1)"
    And "dhcp4.dhcp_lease_time" is visible with command "cat /run/NetworkManager/devices/$(ip link show eth3 | cut -d ':' -f 1 | head -n 1)"


    @ipv4_route_set_basic_route
    Scenario: nmcli - ipv4 - routes - set basic route
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.1.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.2.0/24 192.168.1.11 2'
          ipv4.route-metric 22
          """
    * Add "ethernet" connection named "con_ipv4_2" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.3.11 1'
          ipv4.route-metric 21
          """
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route" in "5" seconds
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 22" is visible with command "ip route"
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route" in "5" seconds
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric" is visible with command "ip route"


    @ver+=1.36
    @ipv4_route_set_route_with_table
    Scenario: nmcli - ipv4 - routes - set route with table
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.1.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.1.10 1 table=100'
          """
    Then "192.168.1.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route" in "5" seconds
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.1.10 dev eth3" is visible with command "ip route list table 100"


    @ver+=1.51.5
    @ver/rhel/9/5+=1.48.10.5
    @ipv4_route_add_route_with_table_reapply
    Scenario: nmcli - ipv4 - routes - set route with table
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.1.10/24
          ipv4.gateway 192.168.4.1
          """
    When "192.168.1.10/24" is visible with command "ip a s eth3" in "5" seconds
    * Modify connection "con_ipv4" changing options "ipv4.routes '192.168.5.0/24 192.168.1.10 1 table=100'"
    * Execute "nmcli device reapply eth3"
    Then "192.168.5.0/24 via 192.168.1.10 dev eth3" is visible with command "ip route list table 100" in "5" seconds


    @RHEL-68459
    @ver+=1.51.5
    @ver/rhel/9/5+=1.48.10.5
    @ipv4_route_delete_route_with_table_reapply
    Scenario: nmcli - ipv4 - routes - set route with table
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.1.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.1.10 1 table=100'
          """
    When "192.168.5.0/24 via 192.168.1.10 dev eth3" is visible with command "ip route list table 100" in "5" seconds
    * Modify connection "con_ipv4" changing options "ipv4.routes ''"
    * Execute "nmcli device reapply eth3"
    Then "192.168.5.0/24" is not visible with command "ip route list table 100" in "5" seconds


    @RHEL-66262
    @ver+=1.51.5
    @ver/rhel/9/5+=1.48.10.5
    @ipv4_route_cleanup_route_with_table
    Scenario: nmcli - ipv4 - routes - cleanup route with table
    # Must set method=static without addresses. Otherwise, the kernel cleanups the routes,
    # thus the bug cannot be reproduced.
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.routes '192.168.5.0/24 192.168.1.10 1 table=100'
          """
    When "192.168.5.0/24 via 192.168.1.10 dev eth3" is visible with command "ip route list table 100" in "5" seconds
    * Bring "down" connection "con_ipv4"
    Then "192.168.5.0/24" is not visible with command "ip route list table 100" in "5" seconds
    # Try again, now deleting the connection instead of just putting it down
    * Bring "up" connection "con_ipv4"
    When "192.168.5.0/24 via 192.168.1.10 dev eth3" is visible with command "ip route list table 100" in "5" seconds
    * Delete connection "con_ipv4"
    Then "192.168.5.0/24" is not visible with command "ip route list table 100" in "5" seconds


    @rhbz1373698 @rhbz1714438 @rhbz1937823 @rhbz2013587 @rhbz2090946
    @ver+=1.39.10
    @ver-1.53.2
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '
            192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600,
            0.0.0.0/0 192.168.4.1 mtu=1600,
            192.168.6.0/24 type=blackhole
            '
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev eth3 proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev eth3 proto static metric 256" is visible with command "ip r"
    And "blackhole 192.168.6.0/24 proto static scope link metric 256" is visible with command "ip r"
    * Modify connection "con_ipv4" changing options "ipv4.routes '192.168.7.0/24 type=prohibit, 192.168.8.0/24 type=unreachable'"
    * Modify connection "con_ipv4" changing options "+ipv4.routes '1.1.1.1/24 192.168.4.1 advmss=1440 quickack=1 rto_min=100'"
    * Bring "up" connection "con_ipv4"
    Then "unreachable 192.168.8.0/24 proto static scope link metric 256" is visible with command "ip r"
    And "prohibit 192.168.7.0/24 proto static scope link metric 256" is visible with command "ip r"
    And "advmss\s+1440\s+rto_min\s+100ms\s+quickack\s+1" is visible with command "ip r"


    @rhbz1373698 @rhbz1714438 @rhbz1937823 @rhbz2013587 @rhbz2090946 @RHEL-83752
    @ver+=1.53.2
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '
            192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600,
            0.0.0.0/0 192.168.4.1 mtu=1600,
            192.168.6.0/24 type=blackhole
            '
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev eth3 proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev eth3 proto static metric 256" is visible with command "ip r"
    And "blackhole 192.168.6.0/24 proto static scope link metric 256" is visible with command "ip r"
    * Modify connection "con_ipv4" changing options "ipv4.routes '192.168.7.0/24 type=prohibit, 192.168.8.0/24 type=unreachable'"
    * Modify connection "con_ipv4" changing options "+ipv4.routes '1.1.1.1/24 192.168.4.1 advmss=1440 quickack=1 rto_min=100'"
    * Bring "up" connection "con_ipv4"
    Then "unreachable 192.168.8.0/24 proto static scope link metric 256" is visible with command "ip r"
    And "prohibit 192.168.7.0/24 proto static scope link metric 256" is visible with command "ip r"
    And "advmss\s+1440\s+rto_min\s+lock\s+100ms\s+quickack\s+1" is visible with command "ip r"


    @ver+=1.41.7
    @ipv4_route_set_single_route_with_weight
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"


    @ver+=1.41.7
    @ipv4_route_set_ecmp_route_with_weight
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5, 192.168.5.0/24 192.168.3.12 weight=10'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth3 weight 5" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"


    @rhbz2158365
    @ver+=1.41.7
    @ipv4_route_set_ecmp_route_with_weight_and_drop_weight
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5, 192.168.5.0/24 192.168.3.12 weight=10'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth3 weight 5" is visible with command "ip route"
    * Execute "nmcli connection modify con_ipv4 ipv4.routes '192.168.5.0/24 192.168.3.11, 192.168.5.0/24 192.168.3.12'"
    * Execute "nmcli c up con_ipv4"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.12 dev eth3\s+proto static\s+metric 256" is visible with command "ip route"


    @ver+=1.41.7
    @ipv4_route_set_ecmp_route_with_weight_and_modify
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5, 192.168.5.0/24 192.168.3.12 weight=10'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth3 weight 5" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
    * Execute "nmcli connection modify con_ipv4 ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5'"
    * Execute "nmcli c up con_ipv4"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is not visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth3 weight 5" is not visible with command "ip route"


    @ver+=1.41.7
    @ver-1.45.9
    @ipv4_route_set_ecmp_routes_in_two_profiles
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.12 weight=10'
          """
    * Add "ethernet" connection named "con_ipv4_2" for device "eth2" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.20/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5'
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4_2" in "5" seconds
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth2 weight 5" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"


    @RHEL-1682
    @ver+=1.45.9
    @ipv4_route_set_ecmp_routes_in_two_profiles
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.12 weight=10'
          """
    * Add "ethernet" connection named "con_ipv4_2" for device "eth2" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.20/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 weight=5'
          """
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev eth3 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev eth2 weight 5" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "at most" "1" lines with pattern "proto static metric 256" are visible with command "ip -4 route show to 192.168.5.0/24"


    @rhbz2158394
    @ver+=1.41.7
    @ipv4_route_set_ecmp_routes_dummy_and_reactivate_connection
    Scenario: nmcli - ipv4 - routes - set ecmp route with dummy and reactivate connection
    * Add "dummy" connection named "con_ipv4" for device "dummy0" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.12 weight=10, 192.168.5.0/24 192.168.3.11 weight=5'
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev dummy0 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev dummy0 weight 5" is visible with command "ip route"
    * Bring "down" connection "con_ipv4"
    Then "192.168.5.0/24\s+proto static\s+metric 256" is not visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev dummy0 weight 10" is not visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev dummy0 weight 5" is not visible with command "ip route"
    * Bring "up" connection "con_ipv4"
    Then "192.168.5.0/24\s+proto static\s+metric 256" is visible with command "ip route"
    Then "nexthop via 192.168.3.12 dev dummy0 weight 10" is visible with command "ip route"
    Then "nexthop via 192.168.3.11 dev dummy0 weight 5" is visible with command "ip route"


    @rhbz1373698
    @ver+=1.8.0
    @restart_if_needed
    @ipv4_route_set_route_with_src_new_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in new syntax
    * Note the number of lines with pattern "eth0" of "ip r" as value "1"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.122.3 src=192.168.3.10'
          """
    When "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth3\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     * Note the number of lines with pattern "eth0" of "ip r" as value "2"
    Then Check noted values "1" and "2" are the same
     And "192.168.122.3/32\s+src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show con_ipv4"


    @rhbz1373698
    @ver+=1.8.0
    @restart_if_needed
    @ipv4_route_set_route_with_src_new_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src new syntaxt restart persistence
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.122.3 src=192.168.3.10'
          """
    * Stop NM
    * Execute "ip addr flush dev eth3"
    * Execute "rm -rf /var/run/NetworkManager"
    * Start NM
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth3\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show con_ipv4"


    @rhbz1302532
    @restart_if_needed
    @no_metric_route_connection_restart_persistence
    Scenario: nmcli - ipv4 - routes - no\s+metric route connection restart persistence
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.3.11'
          """
    When "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Restart NM
    Then "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds



    @rhbz1436531
    @ver+=1.10
    @flush_300
    @ipv4_route_externally_set_route_with_table
    Scenario: nmcli - ipv4 - routes - externally set route with tables
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.may-fail no ipv4.route-table 300"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show table 300"
     And "eth3" is not visible with command "ip r"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show con_ipv4 |awk -F '/' '{print $1}') dev eth3"
    When "10.20.30.0\/24 via 192.168.10[0-3].* dev eth3" is visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show table 300"
    * Bring "up" connection "con_ipv4"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.10[0-3].* dev eth3" is not visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show table 300"
     And "eth3" is not visible with command "ip r"


    @rhbz1436531
    @ver+=1.10
    @flush_300
    @ipv4_route_externally_set_route_with_table_and_reapply
    Scenario: nmcli - ipv4 - routes - externally set route with tables reapply
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show con_ipv4 |awk -F '/' '{print $1}') dev eth3"
    When "10.20.30.0\/24 via 192.168.10[0-3].* dev eth3" is visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show"
    * Execute "nmcli device reapply eth3"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.10[0-3].* dev eth3" is visible with command "ip r show table 300"
     And "192.168.10[0-3].0\/2[2-4] dev eth3 proto kernel scope link src 192.168.10[0-3].* metric 1" is visible with command "ip r show"


    @rhbz1907661
    @ver+=1.31
    @ver+=1.30.3
    @rhelver+=8
    @check_local_routes
    Scenario: nmcli - ipv4 - test handling of local routes
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.address '192.0.2.1/24,192.0.2.2/24'
          ipv6.method manual
          ipv6.addresses '1:2:3:4:5::1/64,1:2:3:4:5::2/64'
          """

    When "eth3\:ethernet\:connected\:con_ipv4" is visible with command "nmcli -t device" in "5" seconds
    When "192.0.2.1" is visible with command "ip a s eth3"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth3 table local proto kernel scope link src 192.0.2.1" is visible with command "ip r show table all"
    When "192.0.2.0/24 dev eth3 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table all"
    When "local 192.0.2.1 dev eth3 table local proto kernel scope host src 192.0.2.1" is visible with command "ip r show table all"
    When "local 192.0.2.2 dev eth3 table local proto kernel scope host src 192.0.2.1" is visible with command "ip r show table all"
    When "broadcast 192.0.2.255 dev eth3 table local proto kernel scope link src 192.0.2.1" is visible with command "ip r show table all"
    When "local 1:2:3:4:5::1 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all" in "5" seconds
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all" in "5" seconds

    * Execute "nmcli device modify eth3 ipv4.address 192.0.2.2/24"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth3 table local proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "local 1:2:3:4:5::1 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all" in "5" seconds
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all" in "5" seconds

    * Execute "nmcli device modify eth3 ipv6.address 1:2:3:4:5::2/64"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth3 table local proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "1:2:3:4:5::1" is not visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all" in "5" seconds


    @rhbz1503769
    @ver+=1.10
    @ipv4_restore_default_route_externally
    Scenario: nmcli - ipv4 - routes - restore externally
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
     And "default" is visible with command "ip r |grep eth3"
    * Execute "ip route delete default dev eth3"
    When "default" is not visible with command "ip r |grep eth3"
    * Execute "ip route add default via 192.168.100.1 metric 1"
    Then "default" is visible with command "ip r |grep eth3"


    @rhbz1164441
    @ver+=1.10.2
    @ipv4_route_remove_basic_route
    Scenario: nmcli - ipv4 - routes - remove basic route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.may-fail no
          ipv4.method static
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.3.11 200'
          """
    * Add "ethernet" connection named "con_ipv42" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.method static
          ipv4.addresses 192.168.1.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.2.0/24 192.168.1.11 300'
          """
    * Modify connection "con_ipv4" changing options "ipv4.routes ''"
    * Modify connection "con_ipv4" changing options "ipv4.routes ''"
    * Bring "up" connection "con_ipv4"
    * Bring "up" connection "con_ipv42"
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 1" is visible with command "ip route" in "5" seconds
    Then "default via 192.168.4.1 dev eth2\s+proto static\s+metric 1" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric 200" is not visible with command "ip route"
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 1" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 1" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 300      " is not visible with command "ip route"



    @ipv4_route_set_device_route
    Scenario: nmcli - ipv4 - routes - set device route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.may-fail no
          ipv4.method static
          ipv4.addresses 192.168.122.2/24
          ipv4.gateway 192.168.122.1
          ipv4.routes '192.168.1.0/24 0.0.0.0, 192.168.2.0/24 192.168.122.5'
          """
    Then "^connected" is visible with command "nmcli -t -f STATE,DEVICE device |grep eth3" in "5" seconds
    Then "default via 192.168.122.1 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.1.0/24 dev eth3\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.122.5 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @rhbz1439376
    @ver+=1.8.0
    @ipv4_host_destination_route
    Scenario: nmcli - ipv4 - routes - host destination
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ip4 192.168.122.123/24
          ipv4.routes '10.20.30.10/24 192.168.122.2'
          """
    Then "^connected" is visible with command "nmcli -t -f STATE,DEVICE device |grep eth3" in "5" seconds


    @preserve_route_to_generic_device
    Scenario: nmcli - ipv4 - routes - preserve generic device route
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Execute "ip r add default via 0.0.0.0 dev dummy0"
    * Execute "ip a add 1.2.3.4/24 dev dummy0"
    Then "default dev dummy0" is visible with command "ip route"
    Then "1.2.3.0/24 dev dummy0\s+proto kernel\s+scope link\s+src 1.2.3.4" is visible with command "ip route"
    Then "IP4.ADDRESS\[1\]:\s+1.2.3.4/24" is visible with command "nmcli dev show dummy0" in "10" seconds
    Then "IP4.GATEWAY:\s+0.0.0.0" is visible with command "nmcli dev show dummy0"


    @ipv4_route_set_invalid_non_IP_route
    Scenario: nmcli - ipv4 - routes - set invalid route - non IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.routes 255.255.255.256" in editor
    Then Error type "failed to set 'routes' property:" while saving in editor


    @ipv4_route_set_invalid_missing_gw_route
    Scenario: nmcli - ipv4 - routes - set invalid route - missing gw
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.2/24
          ipv4.gateway 192.168.122.1
          ipv4.routes 192.168.1.0/24
          """
    Then "default via 192.168.122.1 dev eth3\s+proto static\s+metric" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth3\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @ver+=1.11.3
    @ipv4_routes_not_reachable
    Scenario: nmcli - ipv4 - routes - set unreachable route
    # Since version 1.11.3 NM automatically adds a device route to the
    # route gateway when it is not directly reachable
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.2/24
          ipv4.gateway 192.168.122.1
          ipv4.routes '192.168.1.0/24 192.168.3.11 1'
          """
    Then "\(connected\)" is visible with command "nmcli device show eth3" in "5" seconds
    Then "192.168.3.11\s+dev eth3\s+proto static" is visible with command "ip r"


    @ipv4_dns_manual
    Scenario: nmcli - ipv4 - dns - method static + IP + dns
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.1
          ipv4.dns '8.8.8.8, 8.8.4.4'
          """
    Then Nameserver "8.8.8.8" is set in "10" seconds
    Then Nameserver "8.8.4.4" is set
    Then Nameserver "192.168.100.1" is not set



    @ipv4_dns_manual_when_method_auto
    Scenario: nmcli - ipv4 - dns - method auto + dns
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.dns '8.8.8.8, 8.8.4.4'"
    Then Nameserver "8.8.8.8" is set in "10" seconds
    Then Nameserver "8.8.4.4" is set
    Then Nameserver "192.168.100.1" is set in "5" seconds



    @ipv4_dns_manual_when_ignore_auto_dns
    Scenario: nmcli - ipv4 - dns - method auto + dns + ignore automaticaly obtained
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.1
          ipv4.dns '8.8.8.8, 8.8.4.4'
          ipv4.ignore-auto-dns yes
          """
    Then Nameserver "8.8.8.8" is set in "10" seconds
    Then Nameserver "8.8.4.4" is set
    Then Nameserver "192.168.100.1" is not set


    @rhbz1405431
    @ver+=1.6.0
    @not_with_systemd_resolved
    @restart_if_needed @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns
    Scenario: nmcli - ipv4 - preserve resolveconf if ignore_auto_dns
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.ignore-auto-dns yes
          ipv6.ignore-auto-dns yes
          """
    * Bring "down" connection "con_ipv4"
    * Stop NM
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    * Start NM
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Restart NM
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Restart NM
    Then Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set


    @rhbz1426748
    @ver+=1.8.0
    @not_with_systemd_resolved
    @restart_if_needed @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var1
    Scenario: NM - ipv4 - preserve resolveconf if ignore_auto_dns with NM service up
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.ignore-auto-dns yes
          ipv6.ignore-auto-dns yes
          """
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Restart NM
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Restart NM
    Then Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set


    @rhbz1344303
    @ver+=1.8.0
    @rhelver-=8
    @not_with_systemd_resolved
    @restore_hostname @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var2
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.ignore-auto-dns yes
          ipv6.ignore-auto-dns yes
          """
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Execute "hostnamectl set-hostname braunberg"
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Execute "hostnamectl set-hostname --transient BraunBerg"
    Then Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set


    @rhbz1422610
    @ver+=1.8.0
    @not_with_systemd_resolved
    @restore_hostname @eth3_disconnect @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var3
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.ignore-auto-dns yes
          ipv6.ignore-auto-dns yes
          """
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
    * Execute "hostnamectl set-hostname --static ''"
    * Execute "hostnamectl set-hostname --transient BraunBerg"
    When Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set
     And "BraunBerg" is visible with command "hostnamectl --transient" in "5" seconds

    * Execute "ip add add 1.2.3.1/24 dev eth3"
     And Domain "boston.com" is set
     And Nameserver "1.2.3.4" is set


    @rhbz1423490
    @ver+=1.8.0
    @not_with_systemd_resolved
    @restore_resolvconf @restart_if_needed
    @ipv4_dns_resolvconf_symlinked
    Scenario: nmcli - ipv4 - dns - symlink
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          """
    * Bring "up" connection "con_ipv4"
    * Create NM config file "95-nmci-resolv.conf" with content
      """
      [main]
      rc-manager=symlink
      """
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    When Nameserver "nameserver" is set in "0" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options
        """
        ipv4.dns 8.8.8.8
        """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
     And "are identical" is visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


    @rhbz1423490
    @ver+=1.8.0
    @rhel_pkg @not_with_systemd_resolved
    @restore_resolvconf @restart_if_needed
    @ipv4_dns_resolvconf_file
    Scenario: nmcli - ipv4 - dns - file
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          """
    * Bring "up" connection "con_ipv4"
    * Create NM config file "95-nmci-resolv.conf" with content
      """
      [main]
      rc-manager=file
      """
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    When Nameserver "nameserver" is set in "0" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options
        """
        ipv4.dns 8.8.8.8
        """
    * Bring "up" connection "con_ipv42"
    Then Nameserver "8.8.8.8" is set in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


    @ipv4_dns_add_another_one
    Scenario: nmcli - ipv4 - dns - add dns when one already set
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.1
          ipv4.dns '8.8.8.8'
          """
    * Bring "up" connection "con_ipv4"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.dns 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv4"
    Then Nameserver "8.8.8.8" is set in "5" seconds
    Then Nameserver "8.8.4.4" is set
    Then Nameserver "192.168.100.1" is not set


    @ipv4_dns_delete_all
    Scenario: nmcli - ipv4 - dns - method auto then delete all dns
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.1
          ipv4.dns '8.8.8.8, 8.8.4.4'
          """
    * Modify connection "con_ipv4" changing options "ipv4.dns ''"
    * Bring "up" connection "con_ipv4"
    Then Nameserver "8.8.8.8" is not set
    Then Nameserver "8.8.4.4" is not set
    Then Nameserver "192.168.100.1" is set in "5" seconds


    @not_with_systemd_resolved
    @eth0
    @reload_dns
    Scenario: nmcli - ipv4 - dns - reload
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          ipv4.dns '8.8.8.8, 8.8.4.4'
          """
    * Bring "up" connection "con_ipv4"
    When Nameserver "8.8.8.8" is set in "10" seconds
    When Nameserver "8.8.4.4" is set
    * Execute "echo 'INVALID_DNS' > /etc/resolv.conf"
    * Execute "sudo kill -SIGUSR1 $(pidof NetworkManager)"
    Then Nameserver "8.8.8.8" is set in "45" seconds
    Then Nameserver "8.8.4.4" is set
    * Wait for "3" seconds
    Then Ping "boston.com"


    @ver+=1.32.3
    @eth0
    @ipv4_dns-search_add
    Scenario: nmcli - ipv4 - dns-search - show dns-search
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          ipv4.dns-search google.com
          """
    When "eth0:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    When Domain "google.com" is set in "45" seconds
    Then Ping "maps"
    Then Ping "maps.google.com"
    Then "google.com" is visible with command "nmcli -g ipv4.dns-search connection show con_ipv4"
    Then Note the output of "nmcli -g ipv4.dns-search connection show con_ipv4" as value "2"
     And Note the output of "nmcli -g IP4.SEARCHES device show eth0" as value "1"
     And Check noted values "1" and "2" are the same


    @rhbz2006677
    @ver+=1.35.2
    @eth0
    @ipv4_dns-search_remove
    Scenario: nmcli - ipv4 - dns-search - remove dns-search
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          ipv4.dns-search google.com
          """
    * Modify connection "con_ipv4" changing options "ipv4.dns-search ''"
    * Bring "up" connection "con_ipv4"
    Then Domain "google.com" is not set
    Then Unable to ping "maps"
    Then Ping "maps.google.com"


    @rhbz1443437 @rhbz1649376
    @ver+=1.21.90
    @tshark
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname example.com
          """
    * Bring "down" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 11\s+Host Name: example.com" is visible with command "cat /tmp/tshark.log"


    @tshark
    @ipv4_dhcp-hostname_remove
    Scenario: nmcli - ipv4 - dhcp-hostname - remove dhcp-hostname
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname RHB
          """
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-hostname ''"
    * Bring "down" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
   Then "RHB" is not visible with command "cat /tmp/tshark.log" in "10" seconds


    @rhbz1255507
    @tshark @restore_resolvconf
    @nmcli_ipv4_set_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - set dhcp-fqdn
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-fqdn foo.bar.com
          """
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    #Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth2.conf"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Encoding: Binary encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Server" is visible with command "cat /tmp/tshark.log"


    @rhbz1255507 @rhbz1649368
    @ver+=1.22
    @tshark @restore_resolvconf
    @nmcli_ipv4_override_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-fqdn foo.bar.com
          ipv4.dhcp-hostname-flags fqdn-clear-flags
          """
    * Bring "up" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log"
    Then "Boot Request \(1\).*Flags: 0x00\s+" is visible with command "cat /tmp/tshark.log"


    @rhbz1255507 @rhbz1649368
    @ver+=1.22
    @tshark @restore_resolvconf
    @nmcli_ipv4_override_fqdn_var1
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-fqdn foo.bar.com
          ipv4.dhcp-hostname-flags 'fqdn-serv-update fqdn-encoded'
          """
    * Bring "up" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log"
    Then "Boot Request \(1\).*Flags: 0x05" is visible with command "cat /tmp/tshark.log"


    @tshark
    @nmcli_ipv4_remove_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - remove dhcp-fqdn
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv4.dhcp-fqdn foo.bar.com
          ipv4.may-fail no
          """
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-fqdn ''"
    * Bring "up" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i testX4 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
     Then "foo.bar.com" is not visible with command "grep fqdn /var/lib/NetworkManager/dhclient-testX4.conf" in "10" seconds
      And "foo.bar.com" is not visible with command "cat /tmp/tshark.log" for full "5" seconds


    @tshark
    @ipv4_do_not_send_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - don't send
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname RHC
          ipv4.dhcp-send-hostname no
          """
    * Run child "tshark -l -O bootp -i eth2 > /tmp/hostname.log"
    When "cannot|empty" is not visible with command "file /tmp/hostname.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "RHC" is not visible with command "cat /tmp/hostname.log" in "10" seconds


    @tshark @restore_hostname
    @ipv4_send_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - send real hostname
    * Execute "hostnamectl set-hostname foobar.test"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ipv4.may-fail no"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Hostname is visible in log "/tmp/tshark.log" in "10" seconds


    @tshark
    @ipv4_ignore_sending_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - ignore sending real hostname
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-send-hostname no
          """
    * Run child "tshark -l -O bootp -i eth2 > /tmp/real.log"
    When "cannot|empty" is not visible with command "file /tmp/real.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Hostname is not visible in log "/tmp/real.log" for full "10" seconds


    @rhbz1264410
    @eth0 @fedoraver-=32
    @ipv4_add_dns_options
    Scenario: nmcli - ipv4 - dns-options - add
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.dns-options debug
          ipv4.may-fail no
          """
    Then Domain "options debug" is set in "45" seconds


    @not_with_systemd_resolved
    @eth0
    @ipv4_remove_dns_options
    Scenario: nmcli - ipv4 - dns-options - remove
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.dns-options debug
          ipv4.may-fail no
          """
    * Modify connection "con_ipv4" changing options "ipv4.dns-option ''"
    * Bring "up" connection "con_ipv4"
    Then Domain "options debug" is not set in "5" seconds


    @ipv4_dns-search_ignore_auto_routes
    Scenario: nmcli - ipv4 - dns-search - dns-search + ignore auto obtained routes
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv6.method ignore
          ipv6.ignore-auto-dns yes
          ipv4.dns-search google.com
          ipv4.ignore-auto-dns yes
          ipv4.dns 127.0.0.1
          """
    Then Domain "google.com" is set in "45" seconds
    Then Domain "virtual" is not set


    @ipv4_method_link-local
    Scenario: nmcli - ipv4 - method - link-local
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method link-local
          ipv6.method ignore
          """
    Then "169.254" is visible with command "ip a s eth3" in "10" seconds

    @ver+=1.51.1
    @ipv4_link-local_fallback_static
    Scenario: nmcli - ipv4 - link-local=fallback
    * Add "dummy" connection named "con_ipv4" for device "dummy0" with options
          """
          ipv4.link-local fallback
          ipv4.dhcp-timeout infinity
          """
    Then "169.254" is visible with command "ip a s dummy0" in "10" seconds
    * Delete connection "con_ipv4"
    * Add "dummy" connection named "con_ipv4" for device "dummy0" with options
          """
          ipv4.link-local fallback
          ipv4.addresses 10.1.1.1/32
          ipv6.method ignore
          """
    When "10.1.1.1" is visible with command "ip a s dummy0" in "10" seconds
    Then "169.254" is not visible with command "ip a s dummy0" in "10" seconds

    @ver+=1.51.1
    @ipv4_link-local_fallback_dhcp
    Scenario: nmcli - ipv4 - link-local=fallback + dhcp
    * Prepare simulated test "testX4" device
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv4.link-local fallback
          ipv4.dhcp-timeout infinity
          """
    Then "169.254" is visible with command "ip a s testX4" in "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "169.254" is not visible with command "ip a s testX4" in "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    Then "169.254" is visible with command "ip a s testX4" in "130" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "169.254" is not visible with command "ip a s testX4" in "10" seconds

    @ver+=1.11.3 @rhelver+=8
    @tcpdump
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id AB
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 3: \"AB\"" is visible with command "cat /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:ee"
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 4: hardware-type 192, ff:ee:ee" is visible with command "cat /tmp/tcpdump.log" in "10" seconds


    @gnomebz793957
    @ver+=1.11.3 @rhelver-=7 @fedoraver-=0 @not_with_rhel_pkg
    @tcpdump
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id AB
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 3: \"AB\"" is visible with command "cat /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:ee"
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 4: hardware-type 192, ff:ee:ee" is visible with command "cat /tmp/tcpdump.log" in "10" seconds


    @ver+=1.11.2 @rhelver-=7 @rhel_pkg
    @tshark
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id AB
          """
    * Run child "tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "AB" is visible with command "cat /tmp/tshark.log" in "10" seconds
    #Then "walderon" is visible with command "cat /var/lib/NetworkManager/dhclient-eth2.conf"
    #VVV verify bug 999503
     And "exceeds max \(255\) for precision" is not visible with command "grep exceeds max /var/log/messages"


    @gnomebz793957
    @ver+=1.11.2
    @tcpdump @internal_DHCP @restart_if_needed
    @ipv4_dhcp_client_id_set_internal
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id with internal client
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id abcd
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 5: \"abcd\"" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:11"
    * Execute "pkill tcpdump"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 4: hardware-type 192, ff:ee:11" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds


    @ver+=1.45.4.2000
    @ipv4_dhcp_client_id_none
    Scenario: nmcli - ipv4 - dhcp-client-id - unset client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.dhcp-client-id none
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "BOOTP/DHCP" is visible with command "cat /tmp/tcpdump.log" in "30" seconds
    Then "Client-ID" is not visible with command "cat /tmp/tcpdump.log"


    @ver+=1.45.4.2000
    @internal_DHCP @restart_if_needed
    @ipv4_dhcp_client_id_none_internal
    Scenario: nmcli - ipv4 - dhcp-client-id - unset client id with internal client
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.dhcp-client-id none
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "BOOTP/DHCP" is visible with command "cat /tmp/tcpdump.log" in "30" seconds
    Then "Client-ID" is not visible with command "cat /tmp/tcpdump.log"


    @ver+=1.45.4.2000
    @dhclient_DHCP
    @ipv4_dhcp_client_id_none_dhclient
    Scenario: nmcli - ipv4 - dhcp-client-id - unset client id with dhclient
    * Execute "rm -f /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.d/*"
    * Write file "/etc/dhcp/dhclient.conf" with content
          """
          send dhcp-client-identifier = 01:01:02:03:04:05:06;
          """
    * Restart NM
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.dhcp-client-id none
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "BOOTP/DHCP" is visible with command "cat /tmp/tcpdump.log" in "30" seconds
    Then "Client-ID" is not visible with command "cat /tmp/tcpdump.log"


    @tshark
    @ipv4_dhcp_client_id_remove
    Scenario: nmcli - ipv4 - dhcp-client-id - remove client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id BCBCBCBC
          """
    * Execute "rm -rf /var/lib/NetworkManager/*lease"
    * Bring "down" connection "con_ipv4"
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id ''"
    * Run child "tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "BCBCBCBC" is not visible with command "cat /tmp/tshark.log" in "10" seconds


    @rhbz1531173
    @ver+=1.10
    @internal_DHCP @restart_if_needed
    @ipv4_set_very_long_dhcp_client_id
    Scenario: nmcli - ipv4 - dhcp-client-id - set long client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ipv4.may-fail no autoconnect no"
    * Execute "nmcli connection modify con_ipv4 ipv4.dhcp-client-id $(printf '=%.0s' {1..999})"
    Then Bring "up" connection "con_ipv4"


    @rhbz1661165
    @ver+=1.15.1 @not_with_rhel_pkg
    @internal_DHCP @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to mac with internal plugins
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep -E 'Client-ID (Option )?\(?61\)?' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver+=8 @rhel_pkg
    @internal_DHCP @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to mac with internal plugins
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep -E 'Client-ID (Option )?\(?61\)?' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @internal_DHCP @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to duid with internal plugins
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "00:02:00:00:ab:11" is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


    @ver+=1.45.4.2000
    @dhclient_DHCP
    @ipv4_dhcp_client_id_default_dhclient_set
    Scenario: NM - ipv4 - ipv4 client id should default to the value from dhclient.conf
    * Execute "rm -f /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.d/*"
    * Write file "/etc/dhcp/dhclient.conf" with content
          """
          send dhcp-client-identifier = 01:01:02:03:04:05:06;
          """
    * Restart NM
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "BOOTP/DHCP" is visible with command "cat /tmp/tcpdump.log" in "30" seconds
    Then "01:02:03:04:05:06" is visible with command "grep 'Client-ID' /tmp/tcpdump.log"


    @ver+=1.45.4.2000 @rhelver+=9
    @dhclient_DHCP
    @ipv4_dhcp_client_id_default_dhclient_unset
    Scenario: NM - ipv4 - ipv4 client id should default to unset if it's missing in dhclient.conf
    * Execute "rm -f /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.d/*"
    * Restart NM
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "BOOTP/DHCP" is visible with command "cat /tmp/tcpdump.log" in "30" seconds
    Then "Client-ID" is not visible with command "cat /tmp/tcpdump.log"


    @ipv4_may-fail_yes
    Scenario: nmcli - ipv4 - may-fail - set true
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.dhcp-client-id 1
          ipv4.may-fail yes
          ipv6.method manual
          ipv6.addresses ::1
          """
    Then Bring "up" connection "con_ipv4"


    @ipv4_method_disabled
    Scenario: nmcli - ipv4 - method - disabled
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method manual
          ipv6.addresses ::1
          """
    Then Bring "up" connection "con_ipv4"


    @rhbz1785039
    @ver+=1.25
    @eth0
    @ipv4_never-default_set
    Scenario: nmcli - ipv4 - never-default - set
    * Doc: "Configuring NetworkManager to avoid using a specific profile to provide a default gateway"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.may-fail no
          ipv4.never-default yes
          """
    * Bring "up" connection "con_ipv4"
    When "default via 1" is not visible with command "ip route"
    * Modify connection "con_ipv4" changing options "ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.4"
    * Bring "up" connection "con_ipv4"
    When "default via 1.2.3.4" is visible with command "ip route"
    * Modify connection "con_ipv4" changing options "ipv4.never-default yes"
    * Bring "up" connection "con_ipv4"
    Then "default via 1" is not visible with command "ip route"


    @eth0
    @ipv4_never-default_remove
    Scenario: nmcli - ipv4 - never-default - remove
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.may-fail no
          ipv4.never-default yes
          """
    * Modify connection "con_ipv4" changing options "ipv4.never-default ''"
    * Bring "up" connection "con_ipv4"
    Then "default via 192." is visible with command "ip route"


    @rhbz1313091
    @ver+=1.2.0
    @restart_if_needed
    @ipv4_never_default_restart_persistence
    Scenario: nmcli - ipv4 - never-default - restart persistence
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.may-fail no
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          ipv4.gateway 1.2.3.1
          ipv4.never-default yes
          """
    * Restart NM
    Then "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @kill_dnsmasq_ip4
    @set_mtu_from_DHCP
    Scenario: NM - ipv4 - set dhcp received MTU
    * Create "veth" device named "test1" with options "peer name test1p"
    * Create "veth" device named "test2" with options "peer name test2p"
    * Create "bridge" device named "vethbr"
    * Execute "ip link set dev vethbr up"
    * Execute "ip link set test1p master vethbr"
    * Execute "ip link set test2p master vethbr"
    * Execute "ip link set dev test1 up"
    * Execute "ip link set dev test1p up"
    * Execute "ip link set dev test2 up"
    * Execute "ip link set dev test2p up"
    * Add "ethernet" connection named "tc1" for device "test1" with options "ip4 192.168.99.1/24"
    * Add "ethernet" connection named "tc2" for device "test2"
    * Bring "up" connection "tc1"
    When "test1:connected:tc1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "/usr/sbin/dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --pid-file=/tmp/dnsmasq_ip4.pid --conf-file --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --strict-order --listen-address=192.168.99.1 --dhcp-range=192.168.99.10,192.168.99.254,60m --dhcp-option=option:router,192.168.99.1 --dhcp-lease-max=50 --dhcp-option-force=26,1800 &"
    * Bring "up" connection "tc2"
    Then "mtu 1800" is visible with command "ip a s test2"


    @rhbz1262922
    @ver+=1.2.0
    @dhcp-timeout
    Scenario: NM - ipv4 - add dhcp-timeout
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "ipv4.dhcp-timeout 60 autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 50; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "10" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


    @rhbz1350830
    @ver+=1.10.0
    @dhcp-timeout_infinity
    Scenario: NM - ipv4 - add dhcp-timeout infinity
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv4.dhcp-timeout infinity
          autoconnect no
          """
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 70; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "10" seconds
     And "default via 192.168.99.1 dev testX4" is visible with command "ip r"
     And Check keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" has options
      """
      ipv4.dhcp-timeout=2147483647
      """


    @rhbz1350830
    @ver+=1.10.0
    @restart_if_needed
    @dhcp-timeout_default_in_cfg
    Scenario: nmcli - ipv4 - dhcp_timout infinity in cfg file
    * Create NM config file with content
      """
      [connection-eth-dhcp-timeout]
      match-device=type:ethernet;type:veth
      ipv4.dhcp-timeout=2147483647
      """
    * Execute "systemctl reload NetworkManager"
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 50; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Restart NM
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "180" seconds
     And "default via 192.168.99.1 dev testX4" is visible with command "ip r"
     And "dhcp-timeout=2147483647" is not visible with command "cat /etc/NetworkManager/system-connections/con_ipv4"


    @rhbz1518091 @rhbz1246496 @rhbz1503587
    @ver+=1.11 @skip_in_centos
    @long @restart_if_needed
    @dhcp4_outages_in_various_situation
    Scenario: NM - ipv4 - all types of dhcp outages
    * Doc: "Configuring the DHCP timeout behavior of a NetworkManager connection"
    * Commentary
    """
    Docs are covered by testB4 device and con_delayed_reboot
    """
    ################# PREPARE testX4 AND testY4 ################################
    ## testX4 con_ipv4 for renewal_gw_after_dhcp_outage_for_assumed_var1
    * Prepare simulated test "testX4" device with "192.168.199" ipv4 and "dead:beaf:1" ipv6 dhcp address prefix
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    ## testY4 connie for renewal_gw_after_dhcp_outage_for_assumed_var0
    * Prepare simulated test "testY4" device with "192.168.200" ipv4 and "dead:beaf:2" ipv6 dhcp address prefix
    * Add "ethernet" connection named "connie" for device "testY4"
    * Bring "up" connection "connie"
    When "default" is visible with command "ip r |grep testX4" in "30" seconds
    When "default" is visible with command "ip r |grep testY4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testY4" in "30" seconds
    ##########################################################################

    ## STOP DHCP SERVERS for testY4 and testX4
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "ip netns exec testY4_ns kill -SIGSTOP $(cat /tmp/testY4_ns.pid)"
    ## STOP NM
    * Stop NM
    # REMOVE con_ipv4 keyfile file
    * Remove file "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" if exists
    ## RESTART NM AGAIN
    * Start NM

    ################# PREPARE testZ4 AND testA4 ################################
    ## testA4 and con_ipv42 for renewal_gw_after_long_dhcp_outage
    * Prepare simulated test "testA4" device with "192.168.202" ipv4 and "dead:beaf:4" ipv6 dhcp address prefix
    * Add "ethernet" connection named "con_ipv42" for device "testA4" with options "ipv4.may-fail no"
    ## testZ4 and profie for renewal_gw_after_dhcp_outage
    * Prepare simulated test "testZ4" device with "192.168.201" ipv4 and "dead:beaf:3" ipv6 dhcp address prefix
    * Add "ethernet" connection named "profie" for device "testZ4" with options "ipv4.may-fail no"
    ## testB4 and con_delayed_reboot for autoactivation after fail - with DHCP stopped
    * Prepare simulated test "testB4" device with "192.168.203" ipv4 and "dead:beaf:5" ipv6 dhcp address prefix
    * Execute "ip netns exec testB4_ns kill -SIGSTOP $(cat /tmp/testB4_ns.pid)"
    * Add "ethernet" connection named "con_delayed_reboot" for device "testB4" with options
      """
      ipv4.dhcp-timeout 30
      ipv4.may-fail no
      ipv6.dhcp-timeout 30
      """
    * Bring "up" connection "con_ipv42"
    * Bring "up" connection "profie"
    # Do not bring up con_delayed_reboot, it should autoconnect
    When "default" is visible with command "ip r |grep testA4" in "30" seconds
    When "default" is visible with command "ip r |grep testZ4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testA4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testZ4" in "30" seconds
    ##########################################################################

    ## STOP DHCP SERVERS for testA4 and testZ4
    * Execute "ip netns exec testA4_ns kill -SIGSTOP $(cat /tmp/testA4_ns.pid)"
    * Execute "ip netns exec testZ4_ns kill -SIGSTOP $(cat /tmp/testZ4_ns.pid)"

    ## WAIT FOR all devices are w/o routes
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "default" is not visible with command "ip r |grep testY4" in "130" seconds
    When "default" is not visible with command "ip r |grep testZ4" in "130" seconds
    When "default" is not visible with command "ip r |grep testA4" in "130" seconds
    When "default" is not visible with command "ip r |grep testB4" in "130" seconds
    When "inet 192.168." is not visible with command "ip a s testX4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testY4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testZ4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testA4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testB4" in "10" seconds
    # con_delayed_reboot connection should disconnect after 120s timeout, but try again in 5 minutes
    When "con_delayed reboot" is not visible with command "nmcli c show -a" in "130" seconds

    ### RESTART DHCP servers for testX4 and testY4 and testB4 devices
    * Execute "ip netns exec testY4_ns kill -SIGCONT $(cat /tmp/testY4_ns.pid)"
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    * Execute "ip netns exec testB4_ns kill -SIGCONT $(cat /tmp/testB4_ns.pid)"
    # Default route for testX4 should not be back in 150s as the device is now external
    When "default" is not visible with command "ip r| grep testX4" for full "150" seconds
    # Default route for testY4 should be back in the same timeframe
    Then "default" is visible with command "ip r| grep testY4" in "150" seconds
    Then "inet 192.168." is not visible with command "ip a s testX4"
    Then "inet 192.168." is visible with command "ip a s testY4"
    Then "routers = 192.168" is visible with command "nmcli con show connie"
    # con_delayed_reboot should activate on testB4 in 300s afetr fail, we already waited 150s
    Then "default" is visible with command "ip r| grep testB4" in "170" seconds
    Then "inet 192.168." is visible with command "ip a s testB4"
    Then "routers = 192.168" is visible with command "nmcli con show con_delayed_reboot"

    ## RESTART DHCP server for testA4 after 500s (we already waited for 130 + 150 + 170)
    * Execute "sleep 60 && ip netns exec testA4_ns kill -SIGCONT $(cat /tmp/testA4_ns.pid)"
    Then "routers = 192.168" is visible with command "nmcli con show con_ipv42" in "300" seconds
    Then "default via 192.168.* dev testA4" is visible with command "ip r"

    ## WAIT FOR profie to be down for 900 (we already waited 400)
    When "profie" is not visible with command "nmcli connection s -a" in "500" seconds
    ## RESTART DHCP server for testZ4 and wait for reconnect
    * Execute "ip netns exec testZ4_ns kill -SIGCONT $(cat /tmp/testZ4_ns.pid)"
    Then "routers = 192.168" is visible with command "nmcli con show profie" in "400" seconds
    Then "default via 192.168.* dev testZ4" is visible with command "ip r"


    @ver+=1.26
    @manual_routes_removed
    Scenario: NM - ipv4 - celan manual routes upon reapply
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "ipv4.may-fail no autoconnect no"
    * Bring "up" connection "con_ipv4"
    * Execute "ip route add default via 192.168.99.1 dev testX4 metric 666"
    When "default via 192.168.99.1 dev testX4\s+metric 666" is visible with command "ip r"
    * Execute "nmcli device reapply testX4"
    Then "default via 192.168.99.1 dev testX4\s+metric 666" is not visible with command "ip r" in "2" seconds


    @rhbz1259063
    @ver+=1.4.0
    @ver-1.45
    @ipv4_dad
    Scenario: NM - ipv4 - DAD
    * Prepare simulated test "testD4" device
    * Add "ethernet" connection named "con_ipv4" for device "testD4" with options
          """
          ipv4.may-fail no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          ipv4.dad-timeout 0
          """
    * Bring "up" connection "con_ipv4"
    When "testD4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 5000"
    * Bring "up" connection "con_ipv4" ignoring error
    When "testD4:connected:con_ipv4" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.2/24 ipv4.dad-timeout 5000"
    * Bring "up" connection "con_ipv4"
    Then "testD4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1259063
    @rhbz2123212
    @RHEL-2205
    @ver+=1.45
    @ipv4_dad
    Scenario: NM - ipv4 - DAD
    * Prepare simulated test "testD4" device
    * Execute "ip -n testD4_ns link set testD4p addr 00:99:88:77:66:55"
    * Add "ethernet" connection named "con_ipv4" for device "testD4" with options
          """
          ipv4.may-fail no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          ipv4.dad-timeout 0
          """
    When Bring "up" connection "con_ipv4"
    Then "testD4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Start following journal
    * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 5000"
    When Bring "up" connection "con_ipv4" ignoring error
    * Wait for "5" seconds
    Then "testD4:connected:con_ipv4" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    Then "192.168.99.1" is not visible with command "ip addr show dev testD4" in "10" seconds
    Then "<info>.*192.168.99.1 cannot be configured because it is already in use in the network by host 00:99:88:77:66:55" is visible in journal in "1" seconds
    * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.2/24 ipv4.dad-timeout 5000"
    When Bring "up" connection "con_ipv4"
    Then "testD4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1713380
    @ver+=1.39
    @kill_dnsmasq_ip4 @tshark
    @ipv4_send_dhcpdecline_on_ip_conflict
    Scenario: NM - ipv4 - with ipv4.dad-timeout > 0, perform DAD and send DHCPDECLINE after duplicate detection
    * Add "ethernet" connection named "test" for device "dad" with options "autoconnect no ipv4.dhcp-client-id AB ipv4.dad-timeout 10"
    # setup: add two more NSs in addition to dad_ns, one with dnsmasq and other with interface
    # with a duplicate address
    * Prepare simulated test "dad" device without DHCP
    * Create "bridge" device named "br0" in namespace "dad_ns"
    * Add namespace "dup_ns"
    * Create "veth" device named "dup" in namespace "dup_ns" with options "peer name dupp netns dad_ns"
    * Execute "ip -n dup_ns link set dup up ; ip -n dup_ns addr add 192.168.123.40/24 dev dup"
    * Add namespace "dhcp_ns"
    * Create "veth" device named "dhcp" in namespace "dhcp_ns" with options "peer name dhcpp netns dad_ns"
    * Execute "ip -n dhcp_ns link set dhcp up ; ip -n dhcp_ns addr add 192.168.123.1/24 dev dhcp"
    * Execute "for if in dadp dhcpp dupp; do ip -n dad_ns link set $if master br0 ; done"
    * Execute "for if in br0 dadp dhcpp dupp ; do ip -n dad_ns link set $if up ; done"
    * Execute "ip link set dad up"
    * Execute "ip netns exec dad_ns nft add table bridge filter"
    * Execute "ip netns exec dad_ns nft add chain bridge filter forward '{ type filter hook forward priority 0; }'"
    * Execute "ip netns exec dad_ns nft add rule bridge filter forward iif dhcpp oif dupp ether type arp drop"
    * Execute "ip netns exec dad_ns nft add rule bridge filter forward iif dupp oif dhcpp ether type arp drop"
    * Execute "ip netns exec dad_ns nft list ruleset"
    # note MAC of dad interface
    * Execute "ip l show dev dad | tr '\n' ' ' | sed -e 's/.*link\/ether \([^[:space:]]\+\).*/\1/' > /tmp/dad-mac"
    * Run child "ip netns exec dhcp_ns dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --pid-file=/tmp/dnsmasq_ip4.pid --listen-address=192.168.123.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.123.50,192.168.123.250,2m --dhcp-host=id:AB,192.168.123.40" without shell
    # Verify that ARP reply is received on DAD request
    * "Unicast reply from 192.168.123.40" is visible with command "arping -D -I dad 192.168.123.40"
    * Run child "tshark -n -l -i dad 'arp or port 67 or port 68' > /tmp/tshark.log"
    When Bring "up" connection "test" ignoring error
    Then "192.168.123.40" is not visible with command "ip a show dev dad"
    And Execute "grep -q "DHCPDECLINE(dhcp) 192.168.123.40 $(</tmp/dad-mac)" /tmp/dnsmasq_ip4.log"


    @restart_if_needed
    @custom_shared_range_preserves_restart
    Scenario: nmcli - ipv4 - shared custom range preserves restart
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_ipv4 ipv4.addresses 192.168.100.1/24 ipv4.method shared connection.autoconnect yes"
    * Restart NM
    Then "ipv4.addresses:\s+192.168.100.1/24" is visible with command "nmcli con show con_ipv4"


    @rhbz1834907
    @ver+=1.25
    @permissive @firewall
    @ipv4_method_shared
    Scenario: nmcli - ipv4 - method shared
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Add "ethernet" connection named "tc1" for device "test1" with options
          """
          autoconnect no
          ipv4.method shared
          ipv6.method ignore
          """
    * Add "ethernet" connection named "tc2" for device "test2" with options "autoconnect no "
    Then Bring "up" connection "tc1"
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same


    @ver+=1.51.5
    @ipv4_method_shared_configurable_dhcp_range
    Scenario: nmcli - ipv4 - method shared configurable dhcp range
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Commentary
      """
      Clean lease file after the test, if the test is run again,
      the address is leased to the previous (already destroyed) veth.
      """
    * Cleanup execute "rm -f /var/lib/NetworkManager/dnsmasq-test1.leases"
    * Add "ethernet" connection named "tc1" for device "test1" with options
          """
          ipv4.method shared
          ipv4.addresses 192.168.10.1/24
          ipv4.shared-dhcp-range 192.168.10.10,192.168.10.10
          autoconnect yes
          """
    * Add "ethernet" connection named "tc2" for device "test2" with options "autoconnect no"
    Then Bring "up" connection "tc2"
    And "192.168.10.10/24" is visible with command "ip a show dev test2" in "10" seconds


    @rhbz1404148
    @ver+=1.10
    @kill_dnsmasq_ip4
    @ipv4_method_shared_with_already_running_dnsmasq
    Scenario: nmcli - ipv4 - method shared when dnsmasq does run
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Execute "ip addr add 10.42.0.1/24 dev test1"
    * Execute "ip link set up dev test1"
    * Execute "/usr/sbin/dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --log-dhcp --log-queries --conf-file=/dev/null --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --pid-file=/tmp/dnsmasq_ip4.pid & sleep 2"
    * Add "ethernet" connection named "tc1" for device "test1" with options
          """
          autoconnect no
          ipv4.method shared
          ipv6.method ignore
          """
    * Add "ethernet" connection named "tc2" for device "test2" with options
          """
          autoconnect no
          ipv4.may-fail yes
          ipv6.method manual
          ipv6.addresses 1::1/128
          """
    * Bring "up" connection "tc1" ignoring error
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same
     And "disconnected" is visible with command "nmcli  device show test1" in "10" seconds


    @rhbz1172780
    @netaddr @long
    @ipv4_do_not_remove_second_ip_route
    Scenario: nmcli - ipv4 - do not remove secondary ip subnet route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Bring "up" connection "con_ipv4"
    * "192.168" is visible with command "ip a s eth3" in "20" seconds
    * "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route"
    * Add a secondary address to device "eth3" within the same subnet
    Then "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route" for full "80" seconds


    @ver+=1.31.1 @ver-=1.51.2
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check regex "=== \[method\] ===\s+\[NM property description\]\s+(The IPv4 connection method|IP configuration method).*" in describe output for object "method"

    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+.*DNS.*8.8.8.8" are present in describe output for object "dns"

    Then Check regex "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." in describe output for object "dns-search"

    Then Check "ip\[/prefix\], ip\[/prefix\],\.\.\." are present in describe output for object "addresses"

    Then Check "gateway" are present in describe output for object "gateway"

    Then Check "=== \[routes\] ===\s+\[NM property description\]\s+A list of IPv4 destination addresses, prefix length, optional IPv4 next hop addresses, optional route metric, optional attribute. The valid syntax is: \"ip\[/prefix\] \[next-hop\] \[metric\] \[attribute=val\]...\[,ip\[/prefix\]...\]\". For example \"192.0.2.0/24 10.1.1.1 77, 198.51.100.0/24\".\s+\[nmcli specific description\]\s+Enter a list of IPv4 routes formatted as:\s+ip\[/prefix\] \[next-hop\] \[metric\],...\s+Missing prefix is regarded as a prefix of 32.\s+Missing next-hop is regarded as 0.0.0.0.\s+Missing metric means default \(NM/kernel will set a default value\).\s+Examples: 192.168.2.0/24 192.168.2.1 3, 10.1.0.0/16 10.0.0.254\s+10.1.2.0/24\s+" are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured name ?servers and search domains are ignored and only name ?servers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-client-id\] ===\s+\[NM property description\]\s+A string sent to the DHCP server to identify the local machine which the DHCP server may use to customize the DHCP lease and options." are present in describe output for object "dhcp-client-id"

    Then Check "=== \[dhcp-send-hostname\] ===\s+\[NM property description\]\s+If TRUE, a hostname is sent to the DHCP server when acquiring a lease. Some DHCP servers use this hostname to update DNS databases, essentially providing a static hostname for the computer.  If the \"dhcp-hostname\" property is NULL and this property is TRUE, the current persistent hostname of the computer is sent." are present in describe output for object "dhcp-send-hostname"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"



    @ver+=1.51.3
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check regex "=== \[method\] ===\s+\[NM property description\]\s+(The IPv4 connection method|IP configuration method).*" in describe output for object "method"

    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+.*DNS.*8.8.8.8" are present in describe output for object "dns"

    Then Check regex "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." in describe output for object "dns-search"

    Then Check "ip\[/prefix\], ip\[/prefix\],\.\.\." are present in describe output for object "addresses"

    Then Check "gateway" are present in describe output for object "gateway"

    Then Check "=== \[routes\] ===\s+\[NM property description\]\s+A list of IPv4 destination addresses, prefix length, optional IPv4 next hop addresses, optional route metric, optional attribute. The valid syntax is: \"ip\[/prefix\] \[next-hop\] \[metric\] \[attribute=val\]...\[,ip\[/prefix\]...\]\". For example \"192.0.2.0/24 10.1.1.1 77, 198.51.100.0/24\".\s+\[nmcli specific description\]\s+Enter a list of IPv4 routes formatted as:\s+ip\[/prefix\] \[next-hop\] \[metric\],...\s+Missing prefix is regarded as a prefix of 32.\s+Missing next-hop is regarded as 0.0.0.0.\s+Missing metric means default \(NM/kernel will set a default value\).\s+Examples: 192.168.2.0/24 192.168.2.1 3, 10.1.0.0/16 10.0.0.254\s+10.1.2.0/24\s+" are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured name ?servers and search domains are ignored and only name ?servers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-client-id\] ===\s+\[NM property description\]\s+A string sent to the DHCP server to identify the local machine which the DHCP server may use to customize the DHCP lease and options." are present in describe output for object "dhcp-client-id"

    Then Check "=== \[dhcp-send-hostname\] ===\s+\[NM property description\]\s+If TRUE, a hostname is sent to the DHCP server when acquiring a lease. Some DHCP servers use this hostname to update DNS databases, essentially providing a static hostname for the computer.  If the dhcp-hostname property is NULL and this property is TRUE, the current persistent hostname of the computer is sent. The default value is default \(-1\). In this case the global value from NetworkManager configuration is looked up. If it's not set, the value from dhcp-send-hostname-deprecated, which defaults to TRUE, is used for backwards compatibility. In the future this will change and, in absence of a global default, it will always fallback to TRUE." are present in describe output for object "dhcp-send-hostname"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"


    @rhbz1394500
    @ver+=1.4.0
    @ipv4_honor_ip_order_1
    Scenario: NM - ipv4 - honor IP order from configuration
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.method manual
          ipv4.addresses '192.168.1.5/24,192.168.1.4/24,192.168.1.3/24'
          """
    Then "inet 192.168.1.5/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2" in "5" seconds
    Then "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"
    Then "inet 192.168.1.3/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"


    @rhbz1394500
    @ver+=1.4.0
    @ipv4_honor_ip_order_2
    Scenario: NM - ipv4 - honor IP order from configuration upon reapply
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.method manual
          ipv4.addresses '192.168.1.3/24,192.168.1.4/24,192.168.1.5/24'
          """
    When "inet 192.168.1.3/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2" in "5" seconds
    When "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2" in "5" seconds
    When "inet 192.168.1.5/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2" in "5" seconds
    * Modify connection "con_ipv4" changing options "ipv4.addresses '192.168.1.5/24,192.168.1.4/24,192.168.1.3/24'"
    * Execute "nmcli dev reapply eth2"
    Then "inet 192.168.1.5/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2"
    Then "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"
    Then "inet 192.168.1.3/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"


    @rhbz1394344 @rhbz1505893 @rhbz1492472
    @ver+=1.9.1
    @restore_rp_filters
    @rhel_pkg
    @ipv4_rp_filter_set_loose_rhel
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1
    @restore_rp_filters @rhel_pkg
    @ipv4_rp_filter_do_not_touch
    Scenario: NM - ipv4 - don't touch disabled RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 0 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893 @rhbz1492472
    @ver+=1.9.1
    @rhel_pkg
    @restore_rp_filters
    @ipv4_rp_filter_reset_rhel
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "con_ipv4"
    * Delete connection "con_ipv42"
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter" in "5" seconds


    @rhbz1448987
    @ver+=1.8.0
    @kill_dhcrelay
    @ipv4_dhcp_do_not_add_route_to_server
    Scenario: NM - ipv4 - don't add route to server
    * Prepare simulated test "testX4" device with DHCPv4 server on different network
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    Then "10.0.0.0/24 via 172.16.0.1 dev testX4" is visible with command "ip route" in "45" seconds
    Then "10.0.0.1 via.*dev testX4" is not visible with command "ip route"
    Then "10.0.0.1 dev testX4" is not visible with command "ip route"


    @rhbz1449873
    @ver+=1.8.0
    @ignore_backoff_message
    @ipv4_keep_external_addresses
    Scenario: NM - ipv4 - keep external addresses
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Execute "for i in $(seq 20); do for j in $(seq 200); do ip addr add 10.3.$i.$j/16 dev dummy0; done; done"
    When "4000" is visible with command "ip addr show dev dummy0 | grep 'inet 10.3.' -c"
    * Wait for "6" seconds
    Then "4000" is visible with command "ip addr show dev dummy0 | grep 'inet 10.3.' -c"


    @rhbz1428334
    @ver+=1.10.0
    @ipv4_route_onsite
    Scenario: nmcli - ipv4 - routes - add device route if onsite specified
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.3.254
          """
    * Update the keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection"
          """
          [ipv4]
          route1=10.200.200.2/31,172.16.0.254
          """
    * Restart NM
    * Modify connection "con_ipv4" changing options "ipv4.routes '10.200.200.2/31 172.16.0.254 111 onlink=true'"
    * Bring "up" connection "con_ipv4"
    Then "default via 192.168.3.254 dev eth3 proto static metric 1" is visible with command "ip r"
     And "10.200.200.2/31 via 172.16.0.254 dev eth3 proto static metric 111 onlink" is visible with command "ip r"
     And "192.168.3.0/24 dev eth3 proto kernel scope link src 192.168.3.10 metric 1" is visible with command "ip r"


    @rhbz1482772
    @ver+=1.10
    @ipv4_multiple_ip4
    Scenario: nmcli - ipv4 - method - static using multiple "ip4" options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ip4 192.168.124.1/24
          ip4 192.168.125.1/24
          """
    Then "192.168.124.1/24" is visible with command "ip a s eth3" in "45" seconds
    Then "192.168.125.1/24" is visible with command "ip a s eth3"


    @rhbz1519299
    @ver+=1.12
    @ipv4_dhcp-hostname_shared_persists
    Scenario: nmcli - ipv4 - ipv4 dhcp-hostname persists after method shared set
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.dhcp-hostname test"
    When "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
    And Check keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" has options
      """
      ipv4.dhcp-hostname=test
      """
     * Modify connection "con_ipv4" changing options "ipv4.method shared"
    When "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
    And Check keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" has options
      """
      ipv4.dhcp-hostname=test
      """
     * Modify connection "con_ipv4" changing options "ipv4.method shared"
    Then "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
    And Check keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" has options
      """
      ipv4.dhcp-hostname=test
      """

    @rhbz1573780
    @ver+=1.12
    @skip_in_centos
    @long
    @nm_dhcp_lease_renewal_link_down
    Scenario: NM - ipv4 - link down during dhcp renewal causes NM to never ask for new lease
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "ipv4.may-fail no"
    When "192.168" is visible with command "ip a s testX4" in "40" seconds
    * Execute "ip netns exec testX4_ns ip link set testX4p down"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    When "192.168" is not visible with command "ip a s testX4" in "140" seconds
    * Execute "ip netns exec testX4_ns ip link set testX4p up"
    * Wait for "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "IP4.ADDRESS" is visible with command "nmcli -f ip4.address device show testX4" in "60" seconds


    @rhbz1688329
    @ver+=1.22.0
    @long
    @dhcp_renewal_with_ipv6
    Scenario: NM - ipv4 - start dhcp after timeout with ipv6 already in
    * Prepare simulated test "testX4" device
    * Execute "ip netns exec testX4_ns pkill -SIGSTOP -F /tmp/testX4_ns.pid"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv6.method manual
          ipv6.addresses dead::beaf/128
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    * Execute "sleep 45 && ip netns exec testX4_ns pkill -SIGCONT -F /tmp/testX4_ns.pid"
    Then "192.168" is visible with command "ip a s testX4" in "20" seconds


    @rhbz1636715
    @ver+=1.36
    @ipv4_prefix_route_missing_after_ip_link_down_up
    Scenario: NM - ipv4 - preffix route is missing after putting link down and up
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          """
    When "192.168.3.0/24 dev eth3" is visible with command "ip r" in "5" seconds
    * Execute "ip link set eth3 down; ip link set eth3 up"
    * Execute "ip link set eth3 down; ip link set eth3 up"
    Then "192.168.3.0/24 dev eth3" is visible with command "ip r" in "5" seconds


    @rhbz1369905
    @ver+=1.16
    @ipv4_manual_addr_before_dhcp
    Scenario: nmcli - ipv4 - set manual values immediately
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          autoconnect no
          ipv4.method auto
          ipv4.addresses 192.168.3.10/24
          ipv4.routes '192.168.5.0/24 192.168.3.11 101'
          """
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Run child "sleep 10 && ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    * Run child "nmcli con up con_ipv4"
    Then "192.168.3.10/24" is visible with command "ip a s testX4" in "5" seconds
     And "192.168.5.0/24 via 192.168.3.11 dev testX4\s+proto static\s+metric 101" is visible with command "ip route"
     # And "namespace 192.168.3.11" is visible with command "cat /etc/resolv.conf" in "10" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds


    @ver+=1.35.3
    @ipv4_manual_addr_preferred_over_dhcp
    Scenario: nmcli - ipv4 - manual preferred over DHCP
    * Prepare simulated test "testS" device with "192.168.13" ipv4 and daemon options "--dhcp-host=00:11:22:33:44:55,192.168.13.37,foo"
    * Add "ethernet" connection named "con_general" for device "testS" with options
          """
          autoconnect no
          ethernet.cloned-mac-address 00:11:22:33:44:55
          ipv6.method disabled
          ipv4.address 192.168.13.37/24
          """
    * Bring "up" connection "con_general"
    Then "192.168.13.37.*valid_lft forever preferred_lft forever" is visible with command "ip -oneline a s testS" in "10" seconds


    @rhbz1652653 @rhbz1696881
    @ver+=1.40.3
    @ver+=1.41.4
    @restart_if_needed
    @ipv4_routing_rules_manipulation
    Scenario: NM - ipv4 - routing rules manipulation
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Bring "up" connection "con_ipv4"
    * Modify connection "con_ipv4" changing options "ipv4.routing-rules 'priority 5 table 6, priority 6 from 192.168.6.7/32 table 7, priority 7 from 0.0.0.0/0 table 8' autoconnect yes"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    When "5:\s+from all lookup 6 proto static\s+6:\s+from 192.168.6.7 lookup 7 proto static\s+7:\s+from all lookup 8 proto static" is visible with command "ip rule"
    * Bring "down" connection "con_ipv4"
    Then "5:\s+from all lookup 6 proto static\s+6:\s+from 192.168.6.7 lookup 7 proto static\s+7:\s+from all lookup 8 proto static" is not visible with command "ip rule"
    And "Exactly" "3" lines are visible with command "ip rule"


    @rhbz2167805
    @ver+=1.42.1
    @ver+=1.43.2
    @restart_if_needed
    @ipv4_replace_local_rule
    Scenario: NM - ipv4 - replace local route rule
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.replace-local-rule yes"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "0:	from all lookup local" is not visible with command "ip rule"
    * Bring "down" connection "con_ipv4"
    Then "0:	from all lookup local" is visible with command "ip rule"
    * Add "ethernet" connection named "con_ipv42" for device "eth4" with options "ipv4.replace-local-rule no"
    * Bring "up" connection "con_ipv42"
    Then "0:	from all lookup local" is visible with command "ip rule"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "0:	from all lookup local" is not visible with command "ip rule"


    @rhbz1634657
    @ver+=1.37.90
    @ver+=1.36.7
    @ver/rhel/8/6+=1.36.0.6
    @ver/rhel/9/0+=1.36.0.5
    @internal_DHCP
    @dhcp_multiple_router_options
    Scenario: NM - ipv4 - dhcp server sends multiple router options
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "option:router,192.168.99.10,192.168.99.20,192.168.99.21"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "default via 192.168.99.10 proto dhcp src 192.168.99.[0-9]+ metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n1"
     And "default via 192.168.99.20 proto dhcp src 192.168.99.[0-9]+ metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n2"
     And "default via 192.168.99.21 proto dhcp src 192.168.99.[0-9]+ metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n3"


    @rhbz1663253
    @ver+=1.20
    @dhclient_DHCP
    @dhcp_private_option_dhclient
    Scenario: NM - ipv4 - dhcp server sends private options dhclient
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "unknown_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep unknown_245); echo ${A#*:}"
    Then "private_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep private_245); echo ${A#*:}"


    @rhbz1663253
    @ver+=1.20
    @internal_DHCP
    @dhcp_private_option_internal
    Scenario: NM - ipv4 - dhcp server sends private options internal
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "private_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep private_245); echo ${A#*:}"


    @rhbz1767681 @rhbz1686634
    @ver+=1.18.4
    @tshark
    @ipv4_send_arp_announcements
    Scenario: NM - ipv4 - check that gratuitous ARP announcements are sent"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Add "ethernet" connection named "tc1" for device "test1" with options "ip4 172.21.1.1/24 ipv6.method ignore"
    * Run child "tshark -l -i test2 arp > /tmp/tshark.log"
    * Wait for "8" seconds
    * Bring "up" connection "tc1"
    Then "ok" is visible with command "[ $(grep -c 'Gratuitous ARP for 172.21.1.1'|ARP Announcement for 172.21.1.1' /tmp/tshark.log) -gt 1 ] && echo ok" in "60" seconds


    @tshark
    @dhcp_reboot
    Scenario: DHCPv4 reboot
    # Check that the client reuses an existing lease
    * Execute "rm /tmp/testX4_ns.lease | true"
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    * Note the output of "nmcli -g ip4.address device show testX4" as value "testX4_ip1"
    * Bring "down" connection "con_ipv4"
    * Run child "tshark -l -i testX4 udp port 67 > /tmp/tshark.log"
    # Wait for tshark to start
    * Wait for "10" seconds
    * Bring "up" connection "con_ipv4"
    * Note the output of "nmcli -g ip4.address device show testX4" as value "testX4_ip2"
    Then Check noted values "testX4_ip1" and "testX4_ip2" are the same
    # Check that the client directly requested the address without going through a discover
    Then "DHCP Discover" is not visible with command "cat /tmp/tshark.log"
    Then "DHCP Request" is visible with command "cat /tmp/tshark.log"


    @internal_DHCP @tshark
    @dhcp_reboot_nak
    Scenario: DHCPv4 reboot NAK
    # Check that the client performs a reboot when there is an existing lease and the server replies with a NAK
    * Execute "rm /tmp/testX4_ns.lease | true"
    # Start with the --dhcp-authoritative option so that the server will not ignore unknown leases
    * Prepare simulated test "testX4" device with daemon options "--dhcp-authoritative"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Execute "echo ADDRESS=172.25.1.14 > /var/lib/NetworkManager/internal-$(nmcli -g connection.uuid connection show con_ipv4)-testX4.lease"
    * Run child "tshark -l -i testX4 udp port 67 > /tmp/tshark.log"
    * Wait for "10" seconds
    * Bring "up" connection "con_ipv4"
    Then "192\.168\.99\..." is visible with command "ip a show dev testX4"
    Then "DHCP Request" is visible with command "cat /tmp/tshark.log"
    Then "DHCP NAK" is visible with command "cat /tmp/tshark.log"
    Then "DHCP Discover" is visible with command "cat /tmp/tshark.log"
    Then "DHCP Offer" is visible with command "cat /tmp/tshark.log"
    Then "DHCP ACK" is visible with command "cat /tmp/tshark.log"


    @rhbz1784508
    @dhcpd @long
    @dhcp_rebind
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "10.10.10.1"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Wait for "10" seconds
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds


    @rhbz1806516
    @ver+=1.22.7
    @skip_in_centos
    @long @clean_iptables
    @dhcp_rebind_with_firewall
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "10.10.10.1"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Execute "iptables -A OUTPUT -p udp --dport 67 -j REJECT"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Wait for "10" seconds
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds


    @rhbz1841937
    @ver+=1.25.2
    @skip_in_centos
    @long
    @dhcp_rebind_with_firewall_var2
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "192.168.99.1"
    * Execute "ip netns exec testX4_ns iptables -A INPUT -p udp --dport 67 -j REJECT"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Wait for "10" seconds
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds


    @dhcp_option_classless_routes
    Scenario: DHCPv4 classless routes option parsing
    * Prepare simulated test "testX4" device with dhcp option "option:classless-static-route,10.0.0.0/8,192.168.99.3,20.1.0.0/16,192.168.99.4,30.1.1.0/28,192.168.99.5"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "10.0.0.0/8 via 192.168.99.3" is visible with command "ip route show dev testX4"
    Then "20.1.0.0/16 via 192.168.99.4" is visible with command "ip route show dev testX4"
    Then "30.1.1.0/28 via 192.168.99.5" is visible with command "ip route show dev testX4"


    @rhbz1959461
    @ver+=1.31.5
    @rhelver+=8
    @internal_DHCP
    @dhcp_option_ms_classless_routes
    Scenario: DHCPv4 Microsoft classless routes option parsing
    * Prepare simulated test "testX4" device with dhcp option "249,10.0.0.0/9,192.168.99.2,20.1.0.0/16,192.168.99.3"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "10.0.0.0/9 via 192.168.99.2" is visible with command "ip route show dev testX4"
    Then "20.1.0.0/16 via 192.168.99.3" is visible with command "ip route show dev testX4"
    Then "ms_classless_static_routes = 10.0.0.0/9 192.168.99.2 20.1.0.0/16 192.168.99.3" is visible with command "nmcli connection show con_ipv4"



    @dhcp_option_domain_search
    Scenario: DHCPv4 domain search option parsing
    * Prepare simulated test "testX4" device with dhcp option "option:domain-search,corp.example.com,db.example.com,test.com"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "corp\.example\.com db\.example\.com test\.com" is visible with command "grep search /etc/resolv.conf" in "2" seconds


    @rhbz1979387
    @ver+=1.32.6
    @dhcp_option_filename
    Scenario: DHCPv4 filename option parsing
    * Prepare simulated test "testX4" device with dhcp option "option:bootfile-name,test.bin"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "test.bin" is visible with command "nmcli -t -f DHCP4 c s con_ipv4"


    @rhbz1764986
    @ver+=1.22.4
    @ipv4_31_netprefix_ptp_link
    Scenario: nmcli - ipv4 - addresses - manual with 31 bits network prefix length
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 172.16.0.2/31
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "5" seconds
    Then "172.16.0.2/31" is visible with command "ip a s eth3"
    Then "brd 172.16.0.3" is not visible with command "ip a s eth3"


    @rhbz1749358
    @ver+=1.22.0
    @ipv4_dhcp_iaid_unset
    Scenario: nmcli - ipv4 - IAID unset which defaults to ifname
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.dhcp-client-id duid"
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add "bridge" connection named "br88" for device "br88" with options "bridge.stp false ipv4.dhcp-client-id duid"
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are not the same


    @rhbz1749358
    @ver+=1.22.0
    @ipv4_dhcp_iaid_ifname
    Scenario: nmcli - ipv4 - IAID ifname
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.dhcp-client-id duid
          ipv4.dhcp-iaid ifname
          """
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "40" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          bridge.stp false
          ipv4.dhcp-client-id duid
          ipv4.dhcp-iaid ifname
          """
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "40" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are not the same


    @rhbz1749358
    @ver+=1.22.0
    @ipv4_dhcp_iaid_mac
    Scenario: nmcli - ipv4 - IAID mac
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.dhcp-client-id duid
          ipv4.dhcp-iaid mac
          """
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add "bridge" connection named "br88" for device "br88" with options
          """
          bridge.stp false
          ipv4.dhcp-client-id duid
          ipv4.dhcp-iaid mac
          """
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are the same


    @rhbz1700415
    @ver+=1.22.0
    @eth3_disconnect
    @ipv4_external_addresses_no_double_routes
    Scenario: NM - ipv4 - no routes are added by NM for external addresses
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.47.1/24
          """
    When "192.168.47.1/24" is visible with command "ip a sh dev eth3" in "30" seconds
    * Execute "ip a add 1.2.3.4/32 dev eth3; ip a add 4.3.2.1/30 dev eth3"
    When "4.3.2.1/30" is visible with command "ip a sh dev eth3" in "30" seconds
    * Execute "ip link set dev eth3 down; ip link set dev eth3 up"
    Then "1.2.3.4" is not visible with command "ip r show dev eth3" for full "10" seconds
    Then "4.3.2.0/30.*4.3.2.0/30" is not visible with command "ip r show dev eth3"


    @rhbz1871042
    @ver+=1.26.4
    @ipv4_dhcp_vendor_class_keyfile
    Scenario: NM - ipv4 - ipv4.dhcp-vendor-class-identifier is translated to keyfile
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.dhcp-vendor-class-identifier RedHat
          """
    Then Check keyfile "/etc/NetworkManager/system-connections/con_ipv4.nmconnection" has options
      """
      ipv4.dhcp-vendor-class-identifier=RedHat
      """
    * Replace "dhcp-vendor-class-identifier=RedHat" with "dhcp-vendor-class-identifier=RH" in file "/etc/NetworkManager/system-connections/con_ipv4.nmconnection"
    * Reload connections
    Then "RH" is visible with command "nmcli -g ipv4.dhcp-vendor-class-identifier con show con_ipv4"


    @rhbz1979192
    @ver+=1.32.10
    @ipv4_spurious_leftover_route
    Scenario: NM - ipv4 - NetworkManager configures wrong, spurious "local" route for IP address after DHCP address change
    * Prepare simulated test "testX4" device without DHCP
    * Execute "ip -n testX4_ns addr add dev testX4p 192.168.99.1/24"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.30,192.168.99.39,2m" without shell
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    * Execute "pkill -F /tmp/testX4_ns.pid; sleep 1"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.40,192.168.99.49,2m" without shell
    * Execute "ip l set testX4 up"
    When "192.168.99.4" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.3" is not visible with command "ip -4 r show table all dev testX4 scope link"
    * Execute "pkill -F /tmp/testX4_ns.pid; sleep 1"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.59,2m" without shell
    * Execute "ip l set testX4 up"
    When "192.168.99.5" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.[34]" is not visible with command "ip -4 r show table all dev testX4 scope link"


    @rhbz1861527
    # at least two bugs:
    #   * NM < 1.43.6: https://bugzilla.redhat.com/show_bug.cgi?id=2179890
    #   * iproute 6.1: https://bugzilla.redhat.com/show_bug.cgi?id=2183967
    @ver+=1.35.7
    @ignore_backoff_message
    @logging_info_only
    @ipv4_ignore_nonstatic_routes
    Scenario: NM - ipv4 - ignore routes that are neither static nor RA nor DHCP
    * Commentary
    """
    RHEL 9.2 has iproute-6.1, which is bug mentioned above (`ip` is killed by OOM).
    """
    * Skip if next step fails:
    * "6.1" is not visible with command "ip -V" in "0" seconds
    * Prepare simulated test "many_routes4" device using dhcpd and server identifier "192.168.1.1" and ifindex "65004"
    * Add "ethernet" connection named "con_ipv4" for device "many_routes4"
    * Commentary
        """
        Clean up the device early with ip so that in case of some problems, the restarted
        NM doesn't have to cope with 100000s of routes
        """
    * Cleanup execute "ip link delete many_routes4" with timeout "10" seconds and priority "-45"
    * Cleanup execute "sleep 2" with timeout "3" seconds and priority "-44"
    * Bring "up" connection "con_ipv4"
    # wait until `connecting` or `activating` is finished
    When "ing" is not visible with command "nmcli -f general.state c show con_ipv6" in "10" seconds
    * Note "ipv4" routes on interface "many_routes4" as value "ip_routes_before"
    Then Check "ipv4" route list on NM device "many_routes4" matches "ip_routes_before"
    * Note "ipv4" routes on NM device "many_routes4" as value "nm_routes_before"
    When Execute "for i in {5..8} {10..15} 17 18 42 99 {186..192} ; do ip r add 192.168.${i}.0/24 proto ${i} dev many_routes4; done"
    Then Check "ipv4" route list on NM device "many_routes4" matches "nm_routes_before"
    # If more routes are needed, just adjust argument to the generating script and When check
    * Execute "prepare/bird_routes.py many_routes4 4 2000000 > /tmp/nmci-bird-routes-v4"
    * Execute "ip -b /tmp/nmci-bird-routes-v4"
    When There are "at least" "2000000" IP version "4" routes for device "many_routes4" in "5" seconds
    Then Check "ipv4" route list on NM device "many_routes4" matches "nm_routes_before"
     And "--" is visible with command "nmcli -f ipv4.routes c show id con_ipv4" in "5" seconds
    * Delete connection "con_ipv4"
    Then There are "at most" "5" IP version "4" routes for device "many_routes4" in "5" seconds


    @rhbz2040683
    @ver+=1.35.7
    @ipv4_route-table_reapply
    Scenario: nmcli - ipv4 - route-table config and reapply take effect immediately
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv4.method auto
          ipv4.route-table 1000
          ipv4.may-fail no
          """
    * Bring "up" connection "con_ipv4"
    Then "testX4" is visible with command "ip route ls table 1000" in "10" seconds
    * Modify connection "con_ipv4" changing options "ipv4.route-table 1001"
    * Execute "nmcli device reapply testX4"
    Then "testX4" is visible with command "ip route ls table 1001" in "10" seconds
    And "testX4" is not visible with command "ip route ls table 1000" in "10" seconds


    @rhbz2117352
    @ver+=1.41.7
    @ipv4_dhcp_reapply_keep_lease
    Scenario: nmcli - ipv4 - reapply device with DHCP and keep lease
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          ipv4.method auto
          ipv4.may-fail no
          """
    * Bring "up" connection "con_ipv4"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "10" seconds
    * Run child "ip -4 monitor addr dev testX4"
    * Modify connection "con_ipv4" changing options "ipv4.routes 172.25.67.89"
    * Execute "nmcli device reapply testX4"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "10" seconds
    And Do not expect "Deleted" in children in "2" seconds


    @rhbz2047788
    @ver+=1.32.7
    @ipv4_required_timeout_set
    Scenario: nmcli - ipv4 - connection with required timeout
    * Prepare simulated test "testX4" device without DHCP
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
          """
          autoconnect no
          ipv4.method auto
          ipv6.method manual
          ipv6.addresses 2607:f0d0:1002:51::4/64
          ipv4.may-fail yes
          ipv4.required-timeout 10000
          """
    * Execute "nmcli c up con_ipv4" without waiting for process to finish
    When "activated" is not visible with command "nmcli -g GENERAL.STATE con show con_ipv4" for full "9" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "10" seconds
     And "." is not visible with command "nmcli -f IP4.ADDRESS  -t con show con_ipv4"


    @rhbz2065187
    @ver/rhel/8/4+=1.30.0.16
    @ver/rhel/8/6+=1.36.0.8
    @ver+=1.39.10
    @scapy
    @dhcp_internal_ack_after_nak
    Scenario: NM - ipv4 - get IPv4 if ACK received after NAK from different server
    * Prepare simulated test "testX4" device without DHCP
    # Script sends packets like this:
    # | <- DHCP Discover
    # | -> DHCP Offer
    # | <- DHCP Request
    # | -> DHCP Nak (from different server)
    # | -> DHCP Ack
    # And this prevented internal DHCP client from getting the ack.
    * Execute "ip netns exec testX4_ns python3l contrib/reproducers/repro_2059673.py" without waiting for process to finish
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "40" seconds
    Then "172.25.1.200" is visible with command "ip a s testX4"


    @rhbz2105088
    @RHEL-26777
    @ver+=1.36.7
    @rhelver+=8
    @ver/rhel/8/6+=1.36.0.8
    @scapy
    @dhcp_internal_nak_in_renewing
    Scenario: NM - ipv4 - NAK received while renewing
    * Prepare simulated test "testX4" device without DHCP
    * Commentary
        """
        Script sends packets like this:
        | <- DHCP Discover
        | -> DHCP Offer
        | <- DHCP Request
        | -> DHCP Ack      # after this, state is BOUND
        | <- DHCP Request  # renewal after 20 seconds
        | -> DHCP Nak
        | <- DHCP Discover
        | -> DHCP Offer    # Now the internal clients shows error "selecting lease failed: -131"
                           # and can't renew the lease
        """
    * Run child "ip netns exec testX4_ns python3l contrib/reproducers/repro_2105088.py testX4p"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "10" seconds
    * Expect "DHCP Nak" in children in "30" seconds
    * Wait for "2" seconds
    Then "172.25.1.200" is visible with command "ip a s testX4" for full "10" seconds


    @rhbz1995372
    @ver+=1.35
    @ipv4_check_addr_order
    Scenario: nmcli - ipv4 - check IPv4 address order
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_con" for device "testX4" with options "ipv4.method auto ipv4.may-fail no"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "/192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli connection modify con_con ipv4.addresses '192.168.99.2/24,192.168.99.3/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.2/24 192.168.99.3/24 /192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli connection modify con_con ipv4.addresses '192.168.99.2/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.2/24 /192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli device modify testX4 +ipv4.addresses '192.168.99.4/24'"
    Then Check "ipv4" address list "192.168.99.2/24 /192.168.99.[0-9]+/24 /192.168.99.[0-9]+/24$" on device "testX4" in "3" seconds
     And "192.168.99.2/24" is visible with command "ip addr show dev testX4 primary"
     And "192.168.99.4/24" is visible with command "ip addr show dev testX4 secondary"
     And "192.168.99.([0-24-9][0-9]*|3[0-9]+)/24" is visible with command "ip addr show dev testX4 secondary"
    * Execute "nmcli device modify testX4 ipv4.addresses ''"
    Then Check "ipv4" address list "/192.168.99.[0-9]+/24$" on device "testX4" in "3" seconds
    * Execute "nmcli connection modify con_con ipv4.method manual ipv4.addresses '192.168.99.2/24,192.168.99.3/24,192.168.99.4/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.2/24 192.168.99.3/24 192.168.99.4/24" on device "testX4"


    @rhbz2132754
    @ver+=1.41.6
    @ver+=1.40.9
    @ipv4_reapply_preserve_external_ip
    Scenario: @ipv4_reapply_preserve_external_ip
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"

    * Execute "ip addr add 10.42.1.5/24 dev testX4"
    * Execute "ip addr add 10:42:1::5/64 dev testX4"
    * Execute "ip route append 10.43.1.3/32 dev testX4"
    * Execute "ip route append 10:43:1::3/128 dev testX4"
    * Execute "nmcli device reapply testX4"
    * Wait for "0.2" seconds
    Then "10.42.1.5" is not visible with command "ip -4 addr show dev testX4"
    Then "10:42:1::5" is not visible with command "ip -6 addr show dev testX4"
    Then "10.43.1.3" is not visible with command "ip -4 route show dev testX4"
    Then "10:43:1::3" is not visible with command "ip -6 route show dev testX4"

    * Execute "ip addr add 10.42.1.5/24 dev testX4"
    * Execute "ip addr add 10:42:1::5/64 dev testX4"
    * Execute "ip route append 10.43.1.3/32 dev testX4"
    * Execute "ip route append 10:43:1::3/128 dev testX4"
    * Execute "contrib/gi/device-reapply.py reapply testX4"
    * Wait for "0.2" seconds
    Then "10.42.1.5" is not visible with command "ip -4 addr show dev testX4"
    Then "10:42:1::5" is not visible with command "ip -6 addr show dev testX4"
    Then "10.43.1.3" is not visible with command "ip -4 route show dev testX4"
    Then "10:43:1::3" is not visible with command "ip -6 route show dev testX4"

    * Execute "ip addr add 10.42.1.5/24 dev testX4"
    * Execute "ip addr add 10:42:1::5/64 dev testX4"
    * Execute "ip route append 10.43.1.3/32 dev testX4"
    * Execute "ip route append 10:43:1::3/128 dev testX4"
    * Execute "contrib/gi/device-reapply.py reapply testX4 --preserve-external-ip"
    * Wait for "0.2" seconds
    Then "10.42.1.5" is visible with command "ip -4 addr show dev testX4"
    Then "10:42:1::5" is visible with command "ip -6 addr show dev testX4"
    Then "10.43.1.3" is visible with command "ip -4 route show dev testX4"
    Then "10:43:1::3" is visible with command "ip -6 route show dev testX4"

    ### MTPCP notes:
    # * NM behaviour is well described in man page:
    #   https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nm-settings-nmcli.html#nm-settings-nmcli.property.connection.mptcp-flags
    # * systems may and will differ in default setting of 'net.mptcp.enabled' so each scenario
    #   should set it explicitly itself
    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_no_flags_no_defroute
    Scenario: MPTCP with no explicit configuration and no default route
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Execute "ip mptcp endpoint show"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    # no mptcp subflows configuveth1 by default with local routes only
    Then "exactly" "0" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_no_flags
    Scenario: MPTCP with no explicit configuration
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    * Execute "ip netns exec mptcp ss -santi 'dport :9006'"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_disabled
    Scenario: MPTCP disabled in NM
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 connection.mptcp-flags 0x1 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 connection.mptcp-flags 0x1 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    Then "exactly" "0" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_enabled
    # no endpoints configuveth1 despite 'enabled' flag because no lon-local route is present
    Scenario: MPTCP with no explicit configuration
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 connection.mptcp-flags 0x2 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 connection.mptcp-flags 0x2 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "sleep 0.2"
    Then "exactly" "0" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x2_0x4
    Scenario: MPTCP enabled even without sysctl
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "0"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 connection.mptcp-flags 0x6 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 connection.mptcp-flags 0x6 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    Then "exactly" "2" lines are visible with command "ip mptcp endpoint show"
    # endpoints are configuveth1 but not effective
    Then "mptcp" is not visible with command "cat /tmp/network-traffic.log"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x2_0x8
    Scenario: MPTCP enabled even without default route
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 connection.mptcp-flags 0xa ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 connection.mptcp-flags 0xa ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x10
    Scenario: MPTCP with flag signal
    * Prepare simulated MPTCP setup with "2" veths named "veth" and MPTCP type "signal"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 connection.mptcp-flags 0x10 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 connection.mptcp-flags 0x10 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines with pattern "signal" are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x20
    Scenario: MPTCP with flag subflow
    * Prepare simulated MPTCP setup with "2" veths named "veth"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 connection.mptcp-flags 0x20 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 connection.mptcp-flags 0x20 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines with pattern "subflow" are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x40
    Scenario: MPTCP with flag backup
    * Prepare simulated MPTCP setup with "2" veths named "veth" and MPTCP type "backup"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 connection.mptcp-flags 0x40 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 connection.mptcp-flags 0x40 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines with pattern "backup" are visible with command "ip mptcp endpoint show"


    @rhbz2029636
    @tcpdump
    @ver+=1.40
    @dump_status_verbose
    @ipv4_mptcp_flags_0x80
    Scenario: MPTCP with flag fullmesh
    * Prepare simulated MPTCP setup with "2" veths named "veth" and MPTCP type "fullmesh"
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 2 add_addr_accepted 2"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "ipv4.method static ipv4.addresses 192.168.80.10/24 ipv4.gateway 192.168.80.1 connection.mptcp-flags 0x80 ipv6.method disabled"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "ipv4.method static ipv4.addresses 192.168.81.10/24 ipv4.gateway 192.168.81.1 connection.mptcp-flags 0x80 ipv6.method disabled"
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Execute "mptcpize run ncat -c 'echo hello world!' 192.168.80.1 9006"
    Then "hello world!" is visible with command "cat /tmp/nmci-mptcp-ncat.log"
    Then "exactly" "2" lines with pattern "fullmesh" are visible with command "ip mptcp endpoint show"


    @rhbz2120471
    @ver+=1.41.3
    @dump_status_verbose
    @ipv4_mptcp_reapply_change_flag
    Scenario: MPTCP changes are applied upon reapply
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 3 add_addr_accepted 2"
    * Restart NM
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.method auto ipv6.method auto"
    * Bring "up" connection "con_ipv4"
    Then "(?m)dev eth3\s*$" is visible with command "ip mptcp endpoint" in "5" seconds
    Then "signal" is not visible with command "ip mptcp endpoint show | grep eth3"
    Then "signal" is not visible with command "nmcli -f connection.mptcp-flags c s con_ipv4"
    * Modify connection "con_ipv4" changing options "connection.mptcp-flags signal"
    When Execute "nmcli device reapply eth3"
    Then "(?m)signal dev eth3\s*$" is visible with command "ip mptcp endpoint" in "5" seconds
    Then "signal" is visible with command "nmcli -f connection.mptcp-flags c s con_ipv4"


    @rhbz2120471
    @ver+=1.41.3
    @dump_status_verbose
    @ipv4_mptcp_remove_endpoints
    Scenario: MPTCP remove endpoint that are no longer available
    * Set sysctl "net.mptcp.enabled" to "1"
    * Set ip mptcp limits to "subflow 3 add_addr_accepted 2"
    * Restart NM
    * Add "ethernet" connection named "eth3" for device "eth3" with options "ipv6.method disabled"
    * Add "ethernet" connection named "eth10" for device "eth10" with options "ipv6.method disabled"
    * Bring "up" connection "eth3"
    * Bring "up" connection "eth10"
    Then "(?m)dev eth3\s*$" is visible with command "ip mptcp endpoint" in "5" seconds
    Then "(?m)dev eth10\s*$" is visible with command "ip mptcp endpoint" in "5" seconds
    When Bring "down" connection "eth3"
    Then "eth3" is not visible with command "ip mptcp endpoint" in "5" seconds


    @RHEL-78752
    @ver+=1.52
    @ipv4_mptcp_endpoints_dad
    Scenario: MPTCP ensure endpoints are created correctly with DAD active
    * Set sysctl "net.mptcp.enabled" to "1"
    * Add namespace "ns1"
    * Execute "ip netns exec ns1 sysctl -w net.mptcp.enabled=1"
    * Create "veth" device named "v1" with options "peer name v1p netns ns1"
    * Create "veth" device named "v2" with options "peer name v2p netns ns1"
    * Execute "ip link set v1 up"
    * Execute "ip link set v2 up"
    * Execute "ip -n ns1 link set v1p up"
    * Execute "ip -n ns1 link set v2p up"
    * Execute "ip -n ns1 addr add dev v1p 172.20.1.100/24"
    * Execute "ip -n ns1 addr add dev v2p 172.20.2.100/24"
    * Add "ethernet" connection named "v1" for device "v1" with options
      """
      ip4 172.20.1.1/24
      ipv6.method disabled
      ipv4.dad-timeout 200
      connection.mptcp-flags also-without-default-route,subflow
      autoconnect no
      """
    * Add "ethernet" connection named "v2" for device "v2" with options
      """
      ip4 172.20.2.1/24
      ipv6.method disabled
      ipv4.dad-timeout 200
      connection.mptcp-flags also-without-default-route,subflow
      autoconnect no
      """
    * Bring "up" connection "v1"
    * Execute "ip mptcp endpoint show"
    * Run child "ip netns exec ns1 mptcpize run iperf3 -s"
    * Wait for "1" seconds
    * Run child "mptcpize run iperf3 -c 172.20.1.100 -t 30"
    * Wait for "5" seconds
    * Bring "up" connection "v2"
    * Wait for "2" seconds
    * Execute "ip mptcp endpoint show"
    * Execute "ss -nti0"
    Then "ESTAB.* 172.20.1.1:.* 172.20.1.100:5201 .* tcp-ulp-mptcp" is visible with command "ss -nti0"
    Then "ESTAB.* 172.20.2.1%v2:.* 172.20.1.100:5201 .* tcp-ulp-mptcp" is visible with command "ss -nti0"


    @rhbz2046293
    @ver+=1.43.3
    @ipv4_prefsrc_route
    Scenario: Configure IPv4 routes with prefsrc
    * Prepare simulated test "testX1" device with "192.168.51.10" ipv4 and "2620:dead:beaf:51" ipv6 dhcp address prefix
    * Add "ethernet" connection named "x1" for device "testX1" with options "ipv4.dad-timeout 500 ipv4.routes '1.51.0.51/32 src=192.168.51.10, 1.51.0.52/32 src=192.168.52.10' ipv4.route-metric 161 ipv6.method disabled"
    Then Check "inet" route list on NM device "testX1" matches "1.51.0.51/32\ 161    192.168.51.0/24\ 161    0.0.0.0/0\ 192.168.51.1\ 161" in "8" seconds
    Then "1.51.0.51 proto static scope link src 192.168.51.10 metric 161" is visible with command "ip -d -4 route show dev testX1"

    * Commentary
      """
      The route with src=192.168.98.5 cannot be configured yet. That keeps the device "connecting".
      """
    Then "connecting" is visible with command "nmcli -g GENERAL.STATE device show testX1"

    * Commentary
      """
      We are unable to configure the route src=2621:dead:beaf::52 yet. NetworkManager
      is internally waiting for some seconds, before considering that condition an
      error. Randomly wait, to either hit that condition or not.
      """
    * Wait for up to "12" random seconds

    * Prepare simulated test "testX2" device with "192.168.52.10" ipv4 and "2621:dead:beaf:52" ipv6 dhcp address prefix
    * Add "ethernet" connection named "x2" for device "testX2" with options "ipv4.routes '1.52.0.52/32 src=192.168.52.10, 1.52.0.51/32 src=192.168.51.10' ipv4.route-metric 162 ipv6.method disabled"
    Then Check "inet" route list on NM device "testX2" matches "1.52.0.51/32\ 162    1.52.0.52/32\ 162    192.168.52.0/24\ 162    0.0.0.0/0\ 192.168.52.1\ 162" in "8" seconds
    Then Check "inet" route list on NM device "testX1" matches "1.51.0.51/32\ 161    1.51.0.52/32\ 161    192.168.51.0/24\ 161    0.0.0.0/0\ 192.168.51.1\ 161" in "0" seconds
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show testX2"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show testX1"
    Then "1.52.0.51 proto static scope link src 192.168.51.10 metric 162" is visible with command "ip -d -4 route show dev testX2"
    Then "1.52.0.52 proto static scope link src 192.168.52.10 metric 162" is visible with command "ip -d -4 route show dev testX2"
    Then "1.51.0.51 proto static scope link src 192.168.51.10 metric 161" is visible with command "ip -d -4 route show dev testX1"
    Then "1.51.0.52 proto static scope link src 192.168.52.10 metric 161" is visible with command "ip -d -4 route show dev testX1"


    @rhbz2102212
    @ver+=1.43.3
    @ipv4_no_route_without_addr
    Scenario: Only configure IPv4 routes when having an IP address
    * Prepare simulated test "testX" device
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Add "ethernet" connection named "con" for device "testX" with options
          """
          ipv4.routes '192.168.155.0/24 144'
          """
    Then "192.168.155.0" is not visible with command "ip -4 route show dev testX" for full "3.5" seconds
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con" in "8" seconds
    Then "192.168.155.0" is visible with command "ip -4 route show dev testX"


    @rhbz2169512
    @logging_info_only
    @ver+=1.43.4
    @ipv4_keep_track_l3_despite_too_many_netlink
    Scenario: Keep track of NM-requested l3 changes (v4)
    * Cleanup namespace "nev1"
    * Cleanup namespace "nev2"
    * Cleanup namespace "nev3"
    * Add "101" "dummy" connections named "v4con" for devices "dummy" with options
        """
        autoconnect yes
        ipv4.method disabled
        ipv6.method disabled
        """
    * Run child "contrib/netlink-events-l3.sh nev1 200 200 180"
    * Run child "contrib/netlink-events-l3.sh nev2 200 200 180"
    * Run child "contrib/netlink-events-l3.sh nev3 200 200 180"
    * Run child "contrib/netlink-events-l3.sh nev4 200 200 180"
    * Run child "contrib/netlink-events-l3.sh nev5 200 200 180"
    * Run child "contrib/netlink-events-l3.sh nev6 200 200 180"
    * Execute "for i in {0..100} ; do nmcli c modify v4con_$i ipv4.method manual ipv4.addresses 172.16.${i}.1/24; done"
    * Execute "for i in {0..100} ; do nmcli d reapply dummy_$i & done"
    * Commentary
      """
      IP should be aware of the changes, while NM might not receive the updates.
      """
    Then "exactly" "101" lines with pattern "172\.16" are visible with command "ip -o -4 addr show type dummy" in "60" seconds
    * Execute "pkill -F .tmp/nev1-events.pid"
    * Execute "pkill -F .tmp/nev2-events.pid"
    * Execute "pkill -F .tmp/nev3-events.pid"
    * Execute "pkill -F .tmp/nev4-events.pid"
    * Execute "pkill -F .tmp/nev5-events.pid"
    * Execute "pkill -F .tmp/nev6-events.pid"
    * Commentary
      """
      NM should receive the updates when number of messages decreases.
      """
    Then "exactly" "101" lines with pattern "inet4 172\.16" are visible with command "nmcli" in "60" seconds


    @RHEL-8423 @RHEL-8420
    @RHEL-20598 @RHEL-20599 @RHEL-20600
    @ver/rhel/8/6+=1.36.0.18
    @ver/rhel/8/8+=1.40.16.8
    @ver/rhel/8/9+=1.40.16.14
    @ver/rhel/8+=1.40.16.11
    @ver+=1.42.2.10
    @ipv4_reapply_hostname_from_dhcp
    Scenario: Reapply hostname from DHCP
    * Prepare simulated test "testX" device with "192.0.2" ipv4 and daemon options "--no-hosts --dhcp-host=testX,192.0.2.15 --dhcp-option=option:dns-server,1.1.1.1 --dhcp-option=option:domain-name,example.com --dhcp-option=option:ntp-server,192.0.2.1 --clear-on-reload --interface=testXp --enable-ra --no-ping"
    * Add "ethernet" connection named "con" for device "testX" with options "ipv4.method auto ipv6.method ignore"
    * Bring "up" connection "con"
    Then Nameserver "1.1.1.1" is set
    * Execute reproducer "repro_8423.py" with options "testX 192.0.2.15"
    * Wait for "5" seconds
    * Execute "kill `cat /tmp/testX_ns.pid`"
    * Wait for "1" seconds
    * Run child "ip netns exec testX_ns dnsmasq --pid-file=/tmp/testX_ns.pid --dhcp-host=testX,192.0.2.15 --dhcp-option=option:dns-server,8.8.8.8 --dhcp-option=option:domain-name,example.com --dhcp-option=option:ntp-server,192.0.2.1 --clear-on-reload --interface=testXp --enable-ra --no-ping --log-dhcp --conf-file=/dev/null --dhcp-leasefile=/tmp/testX_ns.lease --dhcp-range=192.0.2.10,192.0.2.15,2m"
    Then Nameserver "8.8.8.8" is set in "120" seconds


    @RHEL-5098
    @ver+=1.45.10
    @keyfile
    @ipv4_allow_static_routes_without_address
    Scenario: NM - ipv4 - configuring static routes to device without IPv4 address
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.routes 192.168.1.0/24
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "192.168.1.0/24 dev eth3\s+proto static\s+scope link\s+metric" is visible with command "ip route" in "2" seconds


    @RHEL-16040
    @ver+=1.46.0
    @keyfile
    @tshark
    @ipv4_dhcp_dscp
    Scenario: NM - ipv4 - set custom DHCP DSCP value
    * Prepare simulated test "testX" device
    * Add "ethernet" connection named "con_ipv4" for device "testX" with options
          """
          connection.autoconnect no
          ipv6.method disabled
          """

    * Commentary
      """
      Checking for the default (CS0) DSCP value in DHCPDISCOVER(1) and DHCPREQUEST(3) packets
      """
    * Execute "rm -f /var/lib/NetworkManager/*-testX.lease"
    * Run child "tshark -n -l -O ip,bootp -i testX -f 'udp port 67'"
    * Bring "up" connection "con_ipv4"
    Then Expect "DSCP: CS0," in children in "2" seconds
    Then Expect "Protocol \(Discover\)" in children in "1" seconds
    Then Expect "DSCP: CS0," in children in "2" seconds
    Then Expect "Protocol \(Request\)" in children in "1" seconds
    * Kill children with signal "9"

    * Commentary
      """
      Checking for the CS6 DSCP value in DHCPDISCOVER(1) and DHCPREQUEST(3) packets
      """
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-dscp CS6"
    * Execute "rm -f /var/lib/NetworkManager/*-testX.lease"
    * Run child "tshark -l -O ip,bootp -i testX -f 'udp port 67'"
    * Execute "sleep 2"
    * Bring "up" connection "con_ipv4"
    Then Expect "DSCP: CS6," in children in "2" seconds
    Then Expect "Protocol \(Discover\)" in children in "1" seconds
    Then Expect "DSCP: CS6," in children in "2" seconds
    Then Expect "Protocol \(Request\)" in children in "1" seconds
    * Kill children with signal "9"

    * Commentary
      """
      Checking for the CS4 DSCP value in DHCPDISCOVER(1) and DHCPREQUEST(3) packets
      """
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-dscp CS4"
    * Execute "rm -f /var/lib/NetworkManager/*-testX.lease"
    * Run child "tshark -l -O ip,bootp -i testX -f 'udp port 67'"
    * Execute "sleep 2"
    * Bring "up" connection "con_ipv4"
    Then Expect "DSCP: CS4," in children in "2" seconds
    Then Expect "Protocol \(Discover\)" in children in "1" seconds
    Then Expect "DSCP: CS4," in children in "2" seconds
    Then Expect "Protocol \(Request\)" in children in "1" seconds
    * Kill children with signal "9"

    * Commentary
      """
      Checking for the CS4 DSCP value in DHCPREQUEST(3) during renewal, which uses
      a connected (UDP) socket instead of the packet socket.
      """
    * Execute "sleep 30"
    * Run child "tshark -l -O ip,bootp -i testX -f 'udp port 67'"
    Then Expect "DSCP: CS4," in children in "40" seconds
    Then Expect "Protocol \(Request\)" in children in "1" seconds


    @RHEL-24127
    @ver+=1.46.0.1
    @ipv4_renew_lease_after_dhcp_restart
    Scenario: NM - ipv4 - renew lease after DHCP restart
    * Prepare simulated test "testX" device without DHCP
    * Execute "ip -n testX_ns addr add dev testXp 172.25.10.1/24"
    * Run child "ip netns exec testX_ns dnsmasq --bind-interfaces --interface testXp -d --dhcp-range=172.25.10.100,172.25.10.200,60"
    * Add "ethernet" connection named "con_ipv4" for device "testX" with options
          """
          ipv4.method auto
          ipv6.method disabled
          connection.autoconnect no
          """
    * Bring "up" connection "con_ipv4"
    Then "172.*" is visible with command "nmcli -g IP4.ADDRESS device show testX" in "20" seconds
    * Kill children with signal "15"
    Then "172.*" is not visible with command "nmcli -g IP4.ADDRESS device show testX" in "180" seconds
    * Run child "ip netns exec testX_ns dnsmasq --bind-interfaces --interface testXp -d --dhcp-range=172.25.10.100,172.25.10.200,60"
    Then "172.*" is visible with command "nmcli -g IP4.ADDRESS device show testX" in "20" seconds


    @ver+=1.47.1
    @tcpdump
    @ipv4_dhcp_send_release
    Scenario: nmcli - ipv4 - dhcp-send-release - set send release to true
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          autoconnect no
          ipv4.may-fail no
          ipv4.dhcp-send-release yes
          """
    * Bring "up" connection "con_ipv4"
    * Run child "tcpdump -i eth2 -v -n"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "8" seconds
    * Bring "down" connection "con_ipv4"
    Then Expect "DHCP-Message .*53.*, length 1: Release" in children in "10" seconds


    @RHEL-67918
    @ver+=1.51.5
    @tcpdump
    @ipv4_dhcp_send_release_reactivate
    Scenario: nmcli - ipv4 - dhcp-send-release - set send release to true and quickly reactivate
    * Commentary
    """
    Reactivate connection being activated with autoconnect=yes, NM should not crash and activation should pass.
    """
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          autoconnect yes
          ipv4.may-fail no
          ipv4.dhcp-send-release yes
          """
    * Bring "up" connection "con_ipv4"


    @ver+=1.47.1
    @tcpdump
    @ipv4_dhcp_send_release_disabled
    Scenario: nmcli - ipv4 - dhcp-send-release - set send release to false
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          autoconnect no
          ipv4.may-fail no
          ipv4.dhcp-send-release no
          """
    * Run child "stdbuf -oL -eL tcpdump -i eth2 -v -n"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "8" seconds
    * Bring "down" connection "con_ipv4"
    Then Do not expect "DHCP-Message .*53.*, length 1: Release" in children in "10" seconds


    @RHEL-56565
    @ver+=1.51.3
    @tshark
    @restart_if_needed
    @ipv4_set_dhcp_send_hostname_global_config
    Scenario: nmcli - ipv4 - set ipv4.dhcp-send-hostname in global config
    * Create NM config file with content
      """
      [connection]
      match-device=type:ethernet
      ipv4.dhcp-send-hostname=0
      """
    * Restart NM
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.dhcp-hostname example.com
          ipv4.may-fail no
          """
    * Bring "down" connection "con_ipv4"
    * Run child "tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "cannot|empty" is not visible with command "file /tmp/tshark.log" in "150" seconds

    * Bring "up" connection "con_ipv4"
    Then "example.com" is not visible with command "cat /tmp/tshark.log" for full "45" seconds
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-send-hostname true"
    * Bring "up" connection "con_ipv4"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "245" seconds


    @RHEL-14370
    @ver+=1.51.3
    @dhcp4_ipv6_only_no_min_wait
    @ipv4_dhcp_ipv6_only_preferred
    Scenario: nmcli - ipv4 - DHCP option "IPv6-only preferred"
    * Prepare simulated test "testX" device with "none" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix
    * Commentary
      """
      Check that the interface doesn't get the IPv4 address when the IPv6-only preferred
      option is enabled on both sides
      """
    * Execute "ip -n testX_ns addr add dev testXp 172.25.10.1/24"
    * Run child "ip netns exec testX_ns dnsmasq --bind-interfaces --interface testXp -d --port 0 --dhcp-range=172.25.10.100,172.25.10.200,60 --dhcp-option=108,8i"
    * Add "ethernet" connection named "con_general" for device "testX" with options
          """
          autoconnect no
          ipv4.dhcp-ipv6-only-preferred yes
          ipv6.may-fail no
          """
    * Bring "up" connection "con_general"
    Then "inet6 2620" is visible with command "ip addr show dev testX"
    Then "inet 172.25" is not visible with command "ip addr show dev testX" for full "15" seconds

    * Commentary
      """
      Now disable the option on server side and check that the interface gets the IPv4 address
      """
    * Kill children with signal "15"
    * Run child "ip netns exec testX_ns dnsmasq --bind-interfaces --interface testXp -d --port 0 --dhcp-range=172.25.10.100,172.25.10.200,60"
    Then "inet 172.25" is visible with command "ip addr show dev testX" in "15" seconds


    @RHEL-14370
    @ver+=1.51.3
    @ipv4_dhcp_ipv6_only_preferred_global
    Scenario: nmcli - ipv4 - DHCP option "IPv6-only preferred" with global value
    * Create NM config file "90-ipv6-only-preferred.conf" with content
      """
      [connection.ipv4-dhcp-ipv6-only-preferred]
      ipv4.dhcp-ipv6-only-preferred=1
      """
    * Restart NM
    * Prepare simulated test "testX" device with "192.168.12" ipv4 and daemon options "--dhcp-option=108,1800i"
    * Prepare simulated test "testY" device with "192.168.13" ipv4 and daemon options "--dhcp-option=108,1800i"
    * Prepare simulated test "testZ" device with "192.168.14" ipv4 and daemon options "--dhcp-option=108,1800i"
    * Add "ethernet" connection named "con_ipv4_X" for device "testX" with options "autoconnect no"
    * Add "ethernet" connection named "con_ipv4_Y" for device "testY" with options "autoconnect no ipv6.method disabled"
    * Add "ethernet" connection named "con_ipv4_Z" for device "testZ" with options "autoconnect no ipv4.dhcp-ipv6-only-preferred no"
    * Bring "up" connection "con_ipv4_X"
    * Bring "up" connection "con_ipv4_Y"
    * Bring "up" connection "con_ipv4_Z"
    # Since both IP methods are "may-fail=yes", give some more time for them to complete
    * Wait for "10" seconds
    * Commentary
    """
    Device testX has IPv6-only-preferred enabled globally and should not get an IPv4 address
    """
    Then "inet6 2620" is visible with command "ip addr show dev testX"
    Then "inet 192.168.12" is not visible with command "ip addr show dev testX"
    * Commentary
    """
    Device testY has IPv6-only-preferred enabled globally and IPv6 disabled: it should get an IPv4
    """
    Then "inet6 2620" is not visible with command "ip addr show dev testY"
    Then "inet 192.168.13" is visible with command "ip addr show dev testY"
    * Commentary
    """
    Device testZ has IPv6-only-preferred disabled in the profile: it should get both IPv4 and IPv6
    """
    Then "inet6 2620" is visible with command "ip addr show dev testZ"
    Then "inet 192.168.14" is visible with command "ip addr show dev testZ"


    @RHEL-47301
    @ver+=1.51.5
    @ipv4_add_frr_routes_just_once
    Scenario: nmcli - ipv4 - add frr routes just once
    * Commentary
    """
        We need arp disabled device so let's add dummy
            Alternatively we can use 'ip link set dev ethX arp off'
        Let's check that we see committing IPv4 just once if ACD fails.
    """
    * Add "dummy" connection named "dummy0*" for device "dummy0" with options
          """
          ip4 172.20.1.1/24
          ipv6.method disabled
          """
    * Wait for "35" seconds
    Then "IPv4" is not visible with command "journalctl -u NetworkManager --since='30 seconds ago' | grep $(cat /sys/class/net/dummy0/ifindex) | grep -E 'start announcing|committing IPv4 configuration'"
    Then "DHCP-Message .*53.*, length 1: Release" is not visible with command "cat /tmp/tcpdump.log" in "10" seconds


    @RHEL-45878
    @ver+=1.51.2
    @eth0
    @ipv4_add_dns_routes
    Scenario: NM - ipv4 - add DNS routes
    * Add "ethernet" connection named "con2" for device "eth2" with options
          """
          connection.autoconnect no
          ipv4.method manual
          ipv4.addresses 172.16.1.1/24
          ipv4.gateway 172.16.1.254
          ipv4.dns 192.1.1.1
          ipv6.method disabled
          """
    * Add "ethernet" connection named "con3" for device "eth3" with options
          """
          connection.autoconnect no
          ipv4.method manual
          ipv4.addresses 172.16.2.1/24
          ipv4.gateway 172.16.2.254
          ipv4.dns 192.2.2.2
          ipv6.method disabled
          """

    * Commentary
    """
    Without 'routed-dns' the name server on eth3 is reached via eth2
    """
    * Bring "up" connection "con2"
    * Bring "up" connection "con3"
    Then "via 172.16.1.254 dev eth2" is visible with command "ip route get 192.1.1.1"
    Then "via 172.16.1.254 dev eth2" is visible with command "ip route get 192.2.2.2"

    * Commentary
    """
    With 'routed-dns' each name server is reachable via the corresponding interface
    """
    * Modify connection "con2" changing options "ipv4.routed-dns yes"
    * Modify connection "con3" changing options "ipv4.routed-dns yes"
    * Bring "up" connection "con2"
    * Bring "up" connection "con3"
    Then "via 172.16.1.254 dev eth2" is visible with command "ip route get 192.1.1.1"
    Then "via 172.16.2.254 dev eth3" is visible with command "ip route get 192.2.2.2"
    Then "fwmark 0x4e55 lookup 20053" is visible with command "ip rule show prio 20053"
    Then "2" is visible with command "ip route show table 20053 | wc -l"

    * Commentary
    """
    Check that live reapply works
    """
    * Execute "nmcli device modify eth3 ipv4.routed-dns no"
    Then "via 172.16.1.254 dev eth2" is visible with command "ip route get 192.2.2.2"
    * Execute "nmcli device modify eth3 ipv4.routed-dns yes"
    Then "via 172.16.2.254 dev eth3" is visible with command "ip route get 192.2.2.2"

    * Commentary
    """
    Routes are deleted after bringing the connections down
    """
    * Bring "down" connection "con2"
    * Bring "down" connection "con3"
    Then "0" is visible with command "ip route show table 20053 | wc -l"


    @RHEL-45878
    @ver+=1.51.2
    @eth0 @restart_if_needed
    @ipv4_add_dns_routes_global
    Scenario: NM - ipv4 - add DNS routes with global default value
    * Create NM config file "10-routed-dns.conf" with content
    """
    [connection-routed-dns]
    ipv4.routed-dns=1
    """
    * Restart NM
    * Prepare simulated test "testX" device with "172.16.1" ipv4 and daemon options "--dhcp-option=6,192.1.1.1"
    * Prepare simulated test "testY" device with "172.16.2" ipv4 and daemon options "--dhcp-option=6,192.2.2.2"
    * Add "ethernet" connection named "con2" for device "testX" with options "autoconnect no"
    * Add "ethernet" connection named "con3" for device "testY" with options "autoconnect no"

    * Commentary
    """
    Each name server is reachable via the corresponding interface, due to the global default
    """
    * Bring "up" connection "con2"
    * Bring "up" connection "con3"
    Then "via 172.16.1.1 dev testX" is visible with command "ip route get 192.1.1.1"
    Then "via 172.16.2.1 dev testY" is visible with command "ip route get 192.2.2.2"
    Then "fwmark 0x4e55 lookup 20053" is visible with command "ip rule show prio 20053"
    Then "2" is visible with command "ip route show table 20053 | wc -l"

    * Commentary
    """
    Routes are deleted after bringing the connections down
    """
    * Bring "down" connection "con2"
    * Bring "down" connection "con3"
    Then "0" is visible with command "ip route show table 20053 | wc -l"


    @RHEL-60237
    @ver+=1.53.2.2
    @ipv4_forwarding_with_sysctl_default_forwarding_disabled
    Scenario: NM - ipv4 - Configure IPv4 forwarding with sysctl default forwarding disabled
    * Set sysctl "net.ipv4.conf.default.forwarding" to "0"
    * Create "veth" device named "veth0" with options "peer name veth0_p"
    * Create "veth" device named "veth1" with options "peer name veth1_p"
    * Add "ethernet" connection named "veth0" for device "veth0" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.0.10/24
          ipv4.forwarding yes
          connection.zone trusted
          """
    * Add "ethernet" connection named "veth1" for device "veth1" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.1.10/24
          ipv4.forwarding yes
          connection.zone trusted
          """
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Add namespace "ns0"
    * Add namespace "ns1"
    * Execute "ip link set veth0_p netns ns0"
    * Execute "ip link set veth1_p netns ns1"
    * Execute "ip netns exec ns0 ip link set dev veth0_p up"
    * Execute "ip netns exec ns1 ip link set dev veth1_p up"
    * Execute "ip netns exec ns0 ip addr add 192.168.0.20/24 dev veth0_p"
    * Execute "ip netns exec ns1 ip addr add 192.168.1.20/24 dev veth1_p"
    * Execute "ip netns exec ns0 ip route add default via 192.168.0.10"
    * Execute "ip netns exec ns1 ip route add default via 192.168.1.10"
    Then " 0% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds
    Then " 0% packet loss" is visible with command "ip netns exec ns1 ping -c 1 192.168.0.20" in "20" seconds


    @RHEL-60237
    @ver+=1.53.2.2
    @ipv4_forwarding_with_sysctl_default_forwarding_enabled
    Scenario: NM - ipv4 - Configure IPv4 forwarding with sysctl default forwarding enabled
    * Set sysctl "net.ipv4.conf.default.forwarding" to "1"
    * Create "veth" device named "veth0" with options "peer name veth0_p"
    * Create "veth" device named "veth1" with options "peer name veth1_p"
    * Add "ethernet" connection named "veth0" for device "veth0" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.0.10/24
          ipv4.forwarding no
          connection.zone trusted
          """
    * Add "ethernet" connection named "veth1" for device "veth1" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.1.10/24
          ipv4.forwarding no
          connection.zone trusted
          """
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Add namespace "ns0"
    * Add namespace "ns1"
    * Execute "ip link set veth0_p netns ns0"
    * Execute "ip link set veth1_p netns ns1"
    * Execute "ip netns exec ns0 ip link set dev veth0_p up"
    * Execute "ip netns exec ns1 ip link set dev veth1_p up"
    * Execute "ip netns exec ns0 ip addr add 192.168.0.20/24 dev veth0_p"
    * Execute "ip netns exec ns1 ip addr add 192.168.1.20/24 dev veth1_p"
    * Execute "ip netns exec ns0 ip route add default via 192.168.0.10"
    * Execute "ip netns exec ns1 ip route add default via 192.168.1.10"
    Then "100% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds
    Then "100% packet loss" is visible with command "ip netns exec ns1 ping -c 1 192.168.0.20" in "20" seconds


    @RHEL-60237
    @ver+=1.53.2.2
    @ipv4_shared_connection_with_sysctl_default_forwarding_disabled
    Scenario: NM - ipv4 - Configure IPv4 shared connection with sysctl default forwarding enabled
    * Set sysctl "net.ipv4.conf.default.forwarding" to "0"
    * Create "veth" device named "veth0" with options "peer name veth0_p"
    * Create "veth" device named "veth1" with options "peer name veth1_p"
    * Commentary
      """
      With a shared connection, NAT is enabled on veth0, translating outgoing traffic to the shared IP.
      However, this configuration does not allow traffic originating in the reverse direction.
      """
    * Add "ethernet" connection named "veth0" for device "veth0" with options
          """
          autoconnect no
          ipv4.method shared
          ipv4.address 192.168.0.10/24
          connection.zone trusted
          """
    * Add "ethernet" connection named "veth1" for device "veth1" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.1.10/24
          ipv4.forwarding auto
          connection.zone trusted
          """
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Add namespace "ns0"
    * Add namespace "ns1"
    * Execute "ip link set veth0_p netns ns0"
    * Execute "ip link set veth1_p netns ns1"
    * Execute "ip netns exec ns0 ip link set dev veth0_p up"
    * Execute "ip netns exec ns1 ip link set dev veth1_p up"
    * Execute "ip netns exec ns0 ip addr add 192.168.0.20/24 dev veth0_p"
    * Execute "ip netns exec ns1 ip addr add 192.168.1.20/24 dev veth1_p"
    * Execute "ip netns exec ns0 ip route add default via 192.168.0.10"
    * Execute "ip netns exec ns1 ip route add default via 192.168.1.10"
    Then " 0% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds


    @RHEL-60237
    @ver+=1.53.2.2
    @ipv4_multiple_shared_connections_with_sysctl_default_forwarding_disabled
    Scenario: NM - ipv4 - Configure multiple IPv4 shared connections with sysctl default forwarding disabled
    * Set sysctl "net.ipv4.conf.default.forwarding" to "0"
    * Create "veth" device named "veth0" with options "peer name veth0_p"
    * Create "veth" device named "veth1" with options "peer name veth1_p"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.method shared
          ipv4.address 192.168.3.10/24
          """
    * Bring "up" connection "con_ipv4"
    * Add "ethernet" connection named "veth0" for device "veth0" with options
          """
          autoconnect no
          ipv4.method shared
          ipv4.address 192.168.0.10/24
          connection.zone trusted
          """
    * Add "ethernet" connection named "veth1" for device "veth1" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 192.168.1.10/24
          ipv4.forwarding auto
          connection.zone trusted
          """
    * Bring "up" connection "veth0"
    * Bring "up" connection "veth1"
    * Add namespace "ns0"
    * Add namespace "ns1"
    * Execute "ip link set veth0_p netns ns0"
    * Execute "ip link set veth1_p netns ns1"
    * Execute "ip netns exec ns0 ip link set dev veth0_p up"
    * Execute "ip netns exec ns1 ip link set dev veth1_p up"
    * Execute "ip netns exec ns0 ip addr add 192.168.0.20/24 dev veth0_p"
    * Execute "ip netns exec ns1 ip addr add 192.168.1.20/24 dev veth1_p"
    * Execute "ip netns exec ns0 ip route add default via 192.168.0.10"
    * Execute "ip netns exec ns1 ip route add default via 192.168.1.10"
    Then " 0% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds
    * Bring "down" connection "con_ipv4"
    Then "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/forwarding" in "5" seconds
    Then " 0% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds
    * Bring "down" connection "veth0"
    Then "100% packet loss" is visible with command "ip netns exec ns0 ping -c 1 192.168.1.20" in "20" seconds
    Then "100% packet loss" is visible with command "ip netns exec ns1 ping -c 1 192.168.0.20" in "20" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv4/conf/veth0/forwarding" in "10" seconds
    Then "0" is visible with command "cat /proc/sys/net/ipv4/conf/veth1/forwarding" in "10" seconds


    @RHEL-60237
    @ver+=1.53.2.2
    @ipv4_shared_connection_with_forwarding_ignore
    Scenario: NM - ipv4 - Configure IPv4 shared connection with forwarding ignore
    * Set sysctl "net.ipv4.conf.default.forwarding" to "1"
    * Set sysctl "net.ipv4.conf.eth3.forwarding" to "0"
    * Create "veth" device named "test1g" with options "peer name test1gp"
    * Add "ethernet" connection named "test1gp" for device "test1gp" with options
          """
          autoconnect no
          ipv4.method shared
          ipv4.address 172.16.0.1/24
          connection.zone trusted
          """
    * Bring "up" connection "test1gp"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 172.16.0.8/24
          ipv4.forwarding ignore
          """
    * Bring "up" connection "con_ipv4"
    Then "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/forwarding" in "10" seconds
    * Bring "down" connection "test1gp"
    Then "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/forwarding" in "10" seconds
    * Bring "down" connection "con_ipv4"
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/forwarding" in "10" seconds
