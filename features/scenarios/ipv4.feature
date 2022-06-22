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
    Then Error type "connection verification failed: ipv4.addresses:" while saving in editor


    @rhbz979288
    @ipv4_method_manual_with_IP
    Scenario: nmcli - ipv4 - method - manual + IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.122.253
          """
    Then "192.168.122.253/32" is visible with command "ip a s eth3"
    Then "dhclient-eth3.pid" is not visible with command "ps aux|grep dhclient"


    @ipv4_method_static_with_IP
    Scenario: nmcli - ipv4 - method - static + IP
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253
          """
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
    @ipv4_take_manually_created_ifcfg_with_ip
    Scenario: nmcli - ipv4 - use manually created ipv4 profile
    * Append "DEVICE='eth3'" to ifcfg file "con_ipv4"
    * Append "ONBOOT=yes" to ifcfg file "con_ipv4"
    * Append "NETBOOT=yes" to ifcfg file "con_ipv4"
    * Append "UUID='aa17d688-a38d-481d-888d-6d69cca781b8'" to ifcfg file "con_ipv4"
    * Append "BOOTPROTO=none" to ifcfg file "con_ipv4"
    #* Append "HWADDR='52:54:00:32:77:59'" to ifcfg file "con_ipv4"
    * Append "TYPE=Ethernet" to ifcfg file "con_ipv4"
    * Append "NAME='con_ipv4'" to ifcfg file "con_ipv4"
    * Append "IPADDR='10.0.0.2'" to ifcfg file "con_ipv4"
    * Append "PREFIX='24'" to ifcfg file "con_ipv4"
    * Append "GATEWAY='10.0.0.1'" to ifcfg file "con_ipv4"
    * Restart NM
    Then "aa17d688-a38d-481d-888d-6d69cca781b8" is visible with command "nmcli -f UUID connection show -a"


    @ipv4_addresses_IP_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - IP slash netmask and route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.96
          """
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

    @ver-=1.39.2
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
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.routes '192.168.5.0/24 192.168.3.11 1'
          ipv4.route-metric 21
          """
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 22" is visible with command "ip route"
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric" is visible with command "ip route"


    @rhbz1373698
    @ver+=1.8.0
    @ver-=1.21.90
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"


    @rhbz1373698 @rhbz1714438
    @ver+=1.22.0
    @ver-=1.35.0
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Doc: "Configuring a static route using an nmcli command"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600, 0.0.0.0/0 192.168.4.1 mtu=1600'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev eth3 proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev eth3 proto static metric 256" is visible with command "ip r"


    @rhbz1373698 @rhbz1714438 @rhbz1937823 @rhbz2013587
    @ver+=1.36.0
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600, 0.0.0.0/0 192.168.4.1 mtu=1600, 192.168.6.0/24 type=blackhole'
          """
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev eth3 proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev eth3 proto static metric 256" is visible with command "ip r"
    And "blackhole 192.168.6.0/24 proto static scope link metric 256" is visible with command "ip r"
    * Modify connection "con_ipv4" changing options "ipv4.routes '192.168.7.0/24 type=prohibit, 192.168.8.0/24 type=unreachable'"
    * Bring "up" connection "con_ipv4"
    Then "unreachable 192.168.8.0/24 proto static scope link metric 256" is visible with command "ip r"
    And "prohibit 192.168.7.0/24 proto static scope link metric 256" is visible with command "ip r"


    @rhbz1373698
    @ver+=1.8.0
    @restart_if_needed
    @ipv4_route_set_route_with_src_new_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in new syntax
    * Note the output of "ip r |grep eth0 |wc -l" as value "1"
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
     * Note the output of "ip r |grep eth0 |wc -l" as value "2"
    Then Check noted values "1" and "2" are the same
     And "192.168.122.3/32\s+src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show con_ipv4"


    @rhbz1373698
    @ver+=1.8.0
    @ifcfg-rh
    @ipv4_route_set_route_with_src_old_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in old syntax
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          """
    * Execute "echo '192.168.122.3 src 192.168.3.10 dev eth3' > /etc/sysconfig/network-scripts/route-con_ipv4"
    * Reload connections
    * Bring "up" connection "con_ipv4"
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth3\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show con_ipv4"


    @rhbz1452648
    @ver+=1.8.0
    @ifcfg-rh
    @ipv4_route_modify_route_with_src_old_syntax_no_metric
    Scenario: nmcli - ipv4 - routes - modify route with src and no metric in old syntax
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          """
    * Execute "echo '1.2.3.4 src 2.3.4.5 dev eth3' > /etc/sysconfig/network-scripts/route-con_ipv4"
    * Reload connections
    * Modify connection "con_ipv4" changing options "ipv4.routes '192.168.122.3 src=192.168.3.10'"
    * Bring "up" connection "con_ipv4"
    Then "null" is not visible with command "cat /etc/sysconfig/network-scripts/route-con_ipv4"
     And "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth3\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show con_ipv4"


    @rhbz1373698
    @ver+=1.8.0
    @restart_if_needed @ifcfg-rh
    @ipv4_route_set_route_with_src_old_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src old syntaxt restart persistence
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.3.10/24
          ipv4.gateway 192.168.4.1
          ipv4.route-metric 256
          """
    * Execute "echo '192.168.122.3 src 192.168.3.10 dev eth3' > /etc/sysconfig/network-scripts/route-con_ipv4"
    * Reload connections
    * Bring "up" connection "con_ipv4"
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
    @ipv4_route_set_route_with_tables
    Scenario: nmcli - ipv4 - routes - set route with tables
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
    @ipv4_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv4 - routes - set route with tables reapply
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
    When "local 1:2:3:4:5::1 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"

    * Execute "nmcli device modify eth3 ipv4.address 192.0.2.2/24"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth3 table local proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "local 1:2:3:4:5::1 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"

    * Execute "nmcli device modify eth3 ipv6.address 1:2:3:4:5::2/64"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth3 table local proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "1:2:3:4:5::1" is not visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth3 table local proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"

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


    @ver+=1.4.0
    @ver-=1.11.2
    @ipv4_routes_not_reachable
    Scenario: nmcli - ipv4 - routes - set unreachable route
    * Add "ethernet" connection named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.routes 192.168.1.0/24 192.168.3.11 1" in editor
    * Submit "set ipv6.method ignore" in editor
    * Save in editor
    * Quit editor
    * Bring up connection "con_ipv4" ignoring error
    Then "\(disconnected\)" is visible with command "nmcli device show eth3" in "5" seconds


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
    Then "\(connected\)" is visible with command "nmcli device show eth3"
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
    Then Nameserver "192.168.100.1" is set



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
    @restore_hostname @eth3_disconnect @ifcfg-rh @delete_testeth0
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
    @rhelver-=7 @rhel_pkg
    @not_with_systemd_resolved
    @restore_resolvconf @restart_if_needed
    @ipv4_dns_resolvconf_rhel7_default
    Scenario: nmcli - ipv4 - dns - rhel7 default
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.dns 8.8.8.8"
    * Bring "up" connection "con_ipv4"
    Then Nameserver "8.8.8.8" is set in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


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
    * Execute "echo -e '[main]\nrc-manager=symlink' > /etc/NetworkManager/conf.d/99-resolv.conf"
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
    * Execute "echo -e '[main]\nrc-manager=file' > /etc/NetworkManager/conf.d/99-resolv.conf"
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
    * Execute "sleep 3"
    Then Ping "boston.com"


    @ver-=1.32.2
    @eth0
    @ipv4_dns-search_add
    Scenario: nmcli - ipv4 - dns-search - add dns-search
    * Add "ethernet" connection named "con_ipv4" for device "eth0" with options
          """
          ipv4.may-fail no
          ipv4.dns-search google.com
          """
    When "eth0:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    When Domain "google.com" is set in "45" seconds
    Then Ping "maps"
    Then Ping "maps.google.com"


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


    @ver-=1.35.1
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
    # Workaround for 2006677
    * Execute "sleep 1"
    Then Domain "google.com" is not set
    Then Unable to ping "maps"
    Then Ping "maps.google.com"


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


    @rhbz1443437
    @ver+=1.8.0 @ver-=1.20
    @tshark
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname RC
          """
    * Bring "down" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "RC" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 2\s+Host Name: RC" is visible with command "cat /tmp/tshark.log"


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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    #Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth2.conf"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Encoding: Binary encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Server" is visible with command "cat /tmp/tshark.log"


    @rhbz1255507
    @ver+=1.3.0
    @ver-=1.21.90
    @tshark @not_under_internal_DHCP @restore_resolvconf
    @nmcli_ipv4_override_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-fqdn foo.bar.com
          """
    * Execute "echo 'send fqdn.encoded off;' > /etc/dhcp/dhclient-eth2.conf"
    * Execute "echo 'send fqdn.server-update off;' >> /etc/dhcp/dhclient-eth2.conf"
    * Bring "up" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth2.conf" in "10" seconds
     And "foo.bar.com" is visible with command "cat /tmp/tshark.log"
     And "Encoding: ASCII encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Client" is visible with command "cat /tmp/tshark.log"


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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i testX4 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/hostname.log"
    When "empty" is not visible with command "file /tmp/hostname.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "RHC" is not visible with command "cat /tmp/hostname.log" in "10" seconds


    @tshark @restore_hostname
    @ipv4_send_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - send real hostname
    * Execute "hostnamectl set-hostname foobar.test"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ipv4.may-fail no"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/real.log"
    When "empty" is not visible with command "file /tmp/real.log" in "150" seconds
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


    @ver+=1.11.3 @rhelver+=8
    @tcpdump
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id AB
          """
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
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
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
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
    * Run child "sudo tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
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
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 5: \"abcd\"" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:11"
    * Execute "pkill tcpdump"
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID (Option )?\(?61\)?, length 4: hardware-type 192, ff:ee:11" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds


    @rhbz1642023
    @rhelver+=8
    @ver+=1.14
    @ver-=1.21.0
    @rhel_pkg
    @internal_DHCP @restart_if_needed
    @ipv4_dhcp_client_id_change_lease_restart
    Scenario: nmcli - ipv4 - dhcp-client-id - lease file change should not be considered even after NM restart
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Execute "rm /tmp/ipv4_client_id.lease"
    * Execute "sudo ln -s /var/lib/NetworkManager/internal-$(nmcli -f connection.uuid -t con show id con_ipv4 | sed 's/.*://')-eth2.lease /tmp/ipv4_client_id.lease"
    When "CLIENTID=" is visible with command "cat /tmp/ipv4_client_id.lease" in "10" seconds
    * Stop NM
    * Execute "cp /tmp/ipv4_client_id.lease /tmp/ipv4_client_id.lease.copy"
    * Execute "sudo sed 's/CLIENTID=.*/CLIENTID=00000000000000000000000000000000000000/' < /tmp/ipv4_client_id.lease.copy > /tmp/ipv4_client_id.lease"
    When "CLIENTID=00000000000000000000000000000000000000" is visible with command "cat /tmp/ipv4_client_id.lease" in "5" seconds
    * Start NM
    Then "CLIENTID=00000000000000000000000000000000000000" is not visible with command "cat /tmp/ipv4_client_id.lease" in "10" seconds


    @tshark
    @ipv4_dhcp_client_id_remove
    Scenario: nmcli - ipv4 - dhcp-client-id - remove client id
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-client-id BC
          """
    * Execute "rm -rf /var/lib/NetworkManager/*lease"
    * Bring "down" connection "con_ipv4"
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id ''"
    * Run child "sudo tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "BC" is not visible with command "cat /tmp/tshark.log" in "10" seconds


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
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep -E 'Client-ID (Option )?\(?61\)?' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver+=8 @rhel_pkg
    @internal_DHCP @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to mac with internal plugins
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep -E 'Client-ID (Option )?\(?61\)?' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @internal_DHCP @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to duid with internal plugins
    * Add "ethernet" connection named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "00:02:00:00:ab:11" is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


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
    * Execute "/usr/sbin/dnsmasq --pid-file=/tmp/dnsmasq_ip4.pid --conf-file --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --strict-order --listen-address=192.168.99.1 --dhcp-range=192.168.99.10,192.168.99.254,60m --dhcp-option=option:router,192.168.99.1 --dhcp-lease-max=50 --dhcp-option-force=26,1800 &"
    * Bring "up" connection "tc2"
    Then "mtu 1800" is visible with command "ip a s test2"


    @ver-1.11
    @long
    @renewal_gw_after_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "ipv4.may-fail no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "con_ipv4" is not visible with command "nmcli connection s -a" in "800" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "400" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


    @rhbz1503587
    @ver+=1.10 @ver-1.11
    @long
    @renewal_gw_after_long_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "ipv4.may-fail no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    * Execute "sleep 500"
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "130" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


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
    @ifcfg-rh
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
     And "IPV4_DHCP_TIMEOUT=2147483647" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"


    @rhbz1350830
    @ver+=1.10.0
    @remove_custom_cfg @restart_if_needed
    @dhcp-timeout_default_in_cfg
    Scenario: nmcli - ipv4 - dhcp_timout infinity in cfg file
    * Execute "echo -e '[connection-eth-dhcp-timeout]\nmatch-device=type:ethernet;type:veth\nipv4.dhcp-timeout=2147483647' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "systemctl reload NetworkManager"
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 50; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Restart NM
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "180" seconds
     And "default via 192.168.99.1 dev testX4" is visible with command "ip r"
     And "IPV4_DHCP_TIMEOUT=2147483647" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"


    @rhbz1246496
    @ver-1.11
    @long @restart_if_needed
    @renewal_gw_after_dhcp_outage_for_assumed_var0
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for on-disk assumed
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "default" is visible with command "ip r |grep testX4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX4" in "30" seconds
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Restart NM
    When "con_ipv4" is visible with command "nmcli con sh -a" in "30" seconds
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX4" in "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "60" seconds
    Then "default" is visible with command "ip r| grep testX4"
    When "inet 192.168.99" is visible with command "ip a s testX4"


    @rhbz1265239
    @ver-=1.10.0
    @long @restart_if_needed
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "default" is visible with command "ip r |grep testX4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX4" in "30" seconds
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Stop NM
    * Execute "sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Start NM
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX4" in "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show testX4" in "400" seconds
    Then "default" is visible with command "ip r| grep testX4" in "150" seconds
    When "inet 192.168.99" is visible with command "ip a s testX4" in "10" seconds


    @rhbz1518091
    @ver+=1.10.1 @ver-1.11
    @long @restart_if_needed
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "default" is visible with command "ip r |grep testX4" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX4" in "30" seconds
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Stop NM
    * Execute "sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Start NM
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX4" in "10" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "default" is not visible with command "ip r| grep testX4" for full "150" seconds
    Then "inet 192.168.99" is not visible with command "ip a s testX4" in "10" seconds


    @rhbz1518091 @rhbz1246496 @rhbz1503587
    @ver+=1.11 @skip_in_centos
    @long @restart_if_needed @ifcfg-rh
    @dhcp4_outages_in_various_situation
    Scenario: NM - ipv4 - all types of dhcp outages
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
    # REMOVE con_ipv4 ifcfg file
    * Execute "sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    ## RESTART NM AGAIN
    * Start NM

    ################# PREPARE testZ4 AND testA4 ################################
    ## testA4 and con_ipv42 for renewal_gw_after_long_dhcp_outage
    * Prepare simulated test "testA4" device with "192.168.202" ipv4 and "dead:beaf:4" ipv6 dhcp address prefix
    * Add "ethernet" connection named "con_ipv42" for device "testA4" with options "ipv4.may-fail no"
    ## testZ4 and profie for renewal_gw_after_dhcp_outage
    * Prepare simulated test "testZ4" device with "192.168.201" ipv4 and "dead:beaf:3" ipv6 dhcp address prefix
    * Add "ethernet" connection named "profie" for device "testZ4" with options "ipv4.may-fail no"
    * Bring "up" connection "con_ipv42"
    * Bring "up" connection "profie"
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
    When "inet 192.168." is not visible with command "ip a s testX4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testY4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testZ4" in "10" seconds
    When "inet 192.168." is not visible with command "ip a s testA4" in "10" seconds

    ### RESTART DHCP servers for testX4 and testY4 devices
    * Execute "ip netns exec testY4_ns kill -SIGCONT $(cat /tmp/testY4_ns.pid)"
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    # Default route for testX4 should not be back in 150s as the device is now external
    When "default" is not visible with command "ip r| grep testX4" for full "150" seconds
    # Default route for testY4 should be back in the same timeframe
    Then "default" is visible with command "ip r| grep testY4" in "150" seconds
    Then "inet 192.168." is not visible with command "ip a s testX4"
    Then "inet 192.168." is visible with command "ip a s testY4"
    Then "routers = 192.168" is visible with command "nmcli con show connie"

    ## RESTART DHCP server for testA4 after 500s (we already waited for 130 + 150)
    * Execute "sleep 120 && ip netns exec testA4_ns kill -SIGCONT $(cat /tmp/testA4_ns.pid)"
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
     @ipv4_dad
     Scenario: NM - ipv4 - DAD
     * Prepare simulated test "testX4" device
     * Add "ethernet" connection named "con_ipv4" for device "testX4" with options
           """
           ipv4.may-fail no
           ipv4.method manual
           ipv4.addresses 192.168.99.1/24
           """
     When "testX4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 5000"
     * Bring up connection "con_ipv4" ignoring error
     When "testX4:connected:con_ipv4" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.2/24 ipv4.dad-timeout 5000"
     * Bring "up" connection "con_ipv4"
     Then "testX4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @restart_if_needed
    @custom_shared_range_preserves_restart
    Scenario: nmcli - ipv4 - shared custom range preserves restart
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_ipv4 ipv4.addresses 192.168.100.1/24 ipv4.method shared connection.autoconnect yes"
    * Restart NM
    Then "ipv4.addresses:\s+192.168.100.1/24" is visible with command "nmcli con show con_ipv4"


    @rhbz1834907
    @ver+=1.4 @ver-=1.24
    @permissive
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


    @rhbz1404148
    @ver+=1.10
    @kill_dnsmasq_ip4 @ifcfg-rh
    @ipv4_method_shared_with_already_running_dnsmasq
    Scenario: nmcli - ipv4 - method shared when dnsmasq does run
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Execute "ip addr add 10.42.0.1/24 dev test1"
    * Execute "ip link set up dev test1"
    * Execute "/usr/sbin/dnsmasq --log-dhcp --log-queries --conf-file=/dev/null --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --pid-file=/tmp/dnsmasq_ip4.pid & sleep 2"
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
    * Bring up connection "tc1" ignoring error
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same
     And "disconnected" is visible with command "nmcli  device show test1" in "10" seconds


    @rhbz1172780
    @netaddr @long
    @ipv4_do_not_remove_second_ip_route
    Scenario: nmcli - ipv4 - do not remove secondary ip subnet route
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Bring up connection "con_ipv4"
    * "192.168" is visible with command "ip a s eth3" in "20" seconds
    * "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route"
    * Add a secondary address to device "eth3" within the same subnet
    Then "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route" for full "80" seconds



    @ver-=1.19.1
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty." are present in describe output for object "method"

    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv4 addresses of DNS servers.\s+Example: 8.8.8.8, 8.8.4.4" are present in describe output for object "dns"

    Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." are present in describe output for object "dns-search"

    Then Check "ip\[/prefix\], ip\[/prefix\],\.\.\." are present in describe output for object "addresses"

    Then Check "gateway" are present in describe output for object "gateway"

    Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes.\s+\[nmcli specific description\]\s+Enter a list of IPv4 routes formatted as:\s+ip\[/prefix\] \[next-hop\] \[metric\],...\s+Missing prefix is regarded as a prefix of 32.\s+Missing next-hop is regarded as 0.0.0.0.\s+Missing metric means default \(NM/kernel will set a default value\).\s+Examples: 192.168.2.0/24 192.168.2.1 3, 10.1.0.0/16 10.0.0.254\s+10.1.2.0/24" are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured nameservers and search domains are ignored and only nameservers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-client-id\] ===\s+\[NM property description\]\s+A string sent to the DHCP server to identify the local machine which the DHCP server may use to customize the DHCP lease and options." are present in describe output for object "dhcp-client-id"

    Then Check "=== \[dhcp-send-hostname\] ===\s+\[NM property description\]\s+If TRUE, a hostname is sent to the DHCP server when acquiring a lease. Some DHCP servers use this hostname to update DNS databases, essentially providing a static hostname for the computer.  If the \"dhcp-hostname\" property is NULL and this property is TRUE, the current persistent hostname of the computer is sent." are present in describe output for object "dhcp-send-hostname"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"



    @ver+=1.19.2 @ver-=1.31.0
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"disabled\", \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty. For IPv4 method \"shared\", the IP subnet can be configured by adding one manual IPv4 address or otherwise 10.42.x.0\/24 is chosen. Note that the shared method must be configured on the interface which shares the internet to a subnet, not on the uplink which is shared." are present in describe output for object "method"


    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv4 addresses of DNS servers.\s+Example: 8.8.8.8, 8.8.4.4" are present in describe output for object "dns"

    Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." are present in describe output for object "dns-search"

    Then Check "ip\[/prefix\], ip\[/prefix\],\.\.\." are present in describe output for object "addresses"

    Then Check "gateway" are present in describe output for object "gateway"

    Then Check "=== \[routes\] ===\s+\[NM property description\]\s+Array of IP routes.\s+\[nmcli specific description\]\s+Enter a list of IPv4 routes formatted as:\s+ip\[/prefix\] \[next-hop\] \[metric\],...\s+Missing prefix is regarded as a prefix of 32.\s+Missing next-hop is regarded as 0.0.0.0.\s+Missing metric means default \(NM/kernel will set a default value\).\s+Examples: 192.168.2.0/24 192.168.2.1 3, 10.1.0.0/16 10.0.0.254\s+10.1.2.0/24" are present in describe output for object "routes"

    Then Check "=== \[ignore-auto-routes\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured routes are ignored and only routes specified in the \"routes\" property, if any, are used." are present in describe output for object "ignore-auto-routes"

    Then Check "=== \[ignore-auto-dns\] ===\s+\[NM property description\]\s+When \"method\" is set to \"auto\" and this property to TRUE, automatically configured name ?servers and search domains are ignored and only name ?servers and search domains specified in the \"dns\" and \"dns-search\" properties, if any, are used." are present in describe output for object "ignore-auto-dns"

    Then Check "=== \[dhcp-client-id\] ===\s+\[NM property description\]\s+A string sent to the DHCP server to identify the local machine which the DHCP server may use to customize the DHCP lease and options." are present in describe output for object "dhcp-client-id"

    Then Check "=== \[dhcp-send-hostname\] ===\s+\[NM property description\]\s+If TRUE, a hostname is sent to the DHCP server when acquiring a lease. Some DHCP servers use this hostname to update DNS databases, essentially providing a static hostname for the computer.  If the \"dhcp-hostname\" property is NULL and this property is TRUE, the current persistent hostname of the computer is sent." are present in describe output for object "dhcp-send-hostname"

    Then Check "=== \[dhcp-hostname\] ===\s+\[NM property description\]\s+If the \"dhcp-send-hostname\" property is TRUE, then the specified name will be sent to the DHCP server when acquiring a lease." are present in describe output for object "dhcp-hostname"

    Then Check "=== \[never-default\] ===\s+\[NM property description\]\s+If TRUE, this connection will never be the default connection for this IP type, meaning it will never be assigned the default route by NetworkManager." are present in describe output for object "never-default"

    Then Check "=== \[may-fail\] ===\s+\[NM property description\]\s+If TRUE, allow overall network configuration to proceed even if the configuration specified by this property times out.  Note that at least one IP configuration must succeed or overall network configuration will still fail.  For example, in IPv6-only networks, setting this property to TRUE on the NMSettingIP4Config allows the overall network configuration to succeed if IPv4 configuration fails but IPv6 configuration completes successfully." are present in describe output for object "may-fail"



    @ver+=1.31.1
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"disabled\", \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty. For IPv4 method \"shared\", the IP subnet can be configured by adding one manual IPv4 address or otherwise 10.42.x.0\/24 is chosen. Note that the shared method must be configured on the interface which shares the internet to a subnet, not on the uplink which is shared." are present in describe output for object "method"


    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv4 addresses of DNS servers.\s+Example: 8.8.8.8, 8.8.4.4" are present in describe output for object "dns"

    Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+(List|Array) of DNS search domains." are present in describe output for object "dns-search"

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


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @restore_rp_filters
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1 @ver-1.14
    @restore_rp_filters
    @not_with_rhel_pkg
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


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


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @restore_rp_filters
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


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "con_ipv4"
    * Delete connection "con_ipv42"
    Then "." is not visible with command "diff /proc/sys/net/ipv4/conf/eth2/rp_filter /proc/sys/net/ipv4/conf/default/rp_filter" in "5" seconds
     And "." is not visible with command "diff /proc/sys/net/ipv4/conf/eth3/rp_filter /proc/sys/net/ipv4/conf/default/rp_filter" in "5" seconds


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1 @ver-1.14
    @not_with_rhel_pkg
    @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add "ethernet" connection named "con_ipv4" for device "eth2" with options "ip4 192.168.11.1/24"
    * Add "ethernet" connection named "con_ipv42" for device "eth3" with options "ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "con_ipv4"
    * Delete connection "con_ipv42"
    Then "." is not visible with command "diff /proc/sys/net/ipv4/conf/eth2/rp_filter /proc/sys/net/ipv4/conf/default/rp_filter" in "5" seconds
     And "." is not visible with command "diff /proc/sys/net/ipv4/conf/eth3/rp_filter /proc/sys/net/ipv4/conf/default/rp_filter" in "5" seconds


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
    @ipv4_keep_external_addresses
    Scenario: NM - ipv4 - keep external addresses
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Execute "for i in $(seq 20); do for j in $(seq 200); do ip addr add 10.3.$i.$j/16 dev dummy0; done; done"
    When "4000" is visible with command "ip addr show dev dummy0 | grep 'inet 10.3.' -c"
    * Execute "sleep 6"
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
    * Execute "echo '10.200.200.2/31 via 172.16.0.254' > /etc/sysconfig/network-scripts/route-con_ipv4"
    * Reload connections
    * Execute "nmcli connection modify con_ipv4 ipv4.routes '10.200.200.2/31 172.16.0.254 111 onlink=true'"
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
    @ifcfg-rh
    @ipv4_dhcp-hostname_shared_persists
    Scenario: nmcli - ipv4 - ipv4 dhcp-hostname persists after method shared set
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "ipv4.dhcp-hostname test"
    When "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
     And "DHCP_HOSTNAME=test" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
     * Modify connection "con_ipv4" changing options "ipv4.method shared"
    When "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
     And "DHCP_HOSTNAME=test" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
     * Modify connection "con_ipv4" changing options "ipv4.method shared"
    Then "test" is visible with command "nmcli -f ipv4.dhcp-hostname con show con_ipv4"
     And "DHCP_HOSTNAME=test" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"


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
    * Wait for at least "10" seconds
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
    @ver+=1.12
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
    Then "192.168.3.10/24" is visible with command "ip a s testX4"
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
    @ver+=1.18.4
    @restart_if_needed
    @ipv4_routing_rules_manipulation
    Scenario: NM - ipv4 - routing rules manipulation
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options "autoconnect no"
    * Bring "up" connection "con_ipv4"
    * Modify connection "con_ipv4" changing options "ipv4.routing-rules 'priority 5 table 6, priority 6 from 192.168.6.7/32 table 7' autoconnect yes"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    When "5:\s+from all lookup 6\s+6:\s+from 192.168.6.7 lookup 7" is visible with command "ip rule"
    * Bring "down" connection "con_ipv4"
    Then "5:\s+from all lookup 6\s+6:\s+from 192.168.6.7 lookup 7" is not visible with command "ip rule"
    And "3" is visible with command "ip rule |wc -l"


    @rhbz1634657
    @ver+=1.16
    @ver-1.37.90
    @ver-1.36.7
    @ver/rhel/8/6-1.36.0.6
    @internal_DHCP
    @dhcp_multiple_router_options
    Scenario: NM - ipv4 - dhcp server sends multiple router options
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "option:router,192.168.99.10,192.168.99.20,192.168.99.21"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "default via 192.168.99.10 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n1"
     And "default via 192.168.99.20 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n2"
     And "default via 192.168.99.21 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n3"


    @rhbz1634657
    @ver+=1.37.90
    @ver+=1.36.7
    @ver/rhel/8/6+=1.36.0.6
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
    * Run child "sudo tshark -l -i test2 arp > /tmp/tshark.log"
    * Execute "sleep 8"
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
    * Run child "sudo tshark -l -i testX4 udp port 67 > /tmp/tshark.log"
    # Wait for tshark to start
    * Execute "sleep 10"
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
    * Run child "sudo tshark -l -i testX4 udp port 67 > /tmp/tshark.log"
    * Execute "sleep 10"
    * Bring "up" connection "con_ipv4"
    Then "192\.168\.99\..." is visible with command "ip a show dev testX4"
    Then "DHCP Request" is visible with command "cat /tmp/tshark.log"
    Then "DHCP NAK" is visible with command "cat /tmp/tshark.log"
    Then "DHCP Discover" is visible with command "cat /tmp/tshark.log"
    Then "DHCP Offer" is visible with command "cat /tmp/tshark.log"
    Then "DHCP ACK" is visible with command "cat /tmp/tshark.log"


    @rhbz1784508
    @kill_children @dhcpd @long
    @dhcp_rebind
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "10.10.10.1"
    * Add "ethernet" connection named "con_ipv4" for device "testX4" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Execute "sleep 10"
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
    * Execute "sleep 10"
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
    * Execute "sleep 10"
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
    @ifcfg-rh
    @ipv4_dhcp_vendor_class_ifcfg
    Scenario: NM - ipv4 - ipv4.dhcp-vendor-class-identifier is translated to ifcfg
    * Add "ethernet" connection named "con_ipv4" for device "eth3" with options
          """
          ipv4.dhcp-vendor-class-identifier RedHat
          """
    Then "RedHat" is visible with command "grep 'DHCP_VENDOR_CLASS_IDENTIFIER=' /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Execute "sed -i 's/DHCP_VENDOR_CLASS_IDENTIFIER=.*/DHCP_VENDOR_CLASS_IDENTIFIER=RH/' /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Reload connections
    Then "RH" is visible with command "nmcli -g ipv4.dhcp-vendor-class-identifier con show con_ipv4"


    @rhbz1979192
    @ver+=1.32.6
    @ver-=1.32.8
    @ipv4_spurious_leftover_route
    Scenario: NM - ipv4 - NetworkManager configures wrong, spurious "local" route for IP address after DHCP address change
    * Prepare simulated test "testX4" device without DHCP
    * Execute "ip -n testX4_ns addr add dev testX4p 192.168.99.1/24"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.30,192.168.99.39,2m" without shell
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    # VVV Sleep 1 To avoid rhbz2005013
    * Execute "pkill -F /tmp/testX4_ns.pid; sleep 1"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.40,192.168.99.49,2m" without shell
    # VVV Sleep 1 To avoid rhbz2005013
    * Execute "sleep 1; ip l set testX4 up"
    When "192.168.99.4" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.3" is not visible with command "ip -4 r show table all dev testX4 scope link"
    # VVV Sleep 1 To avoid rhbz2005013
    * Execute "pkill -F /tmp/testX4_ns.pid; sleep 1"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.59,2m" without shell
    # VVV Sleep 1 To avoid rhbz2005013
    * Execute "sleep 1; ip l set testX4 up"
    When "192.168.99.5" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.[34]" is not visible with command "ip -4 r show table all dev testX4 scope link"


    @rhbz1979192
    @ver+=1.32.10
    @ipv4_spurious_leftover_route
    Scenario: NM - ipv4 - NetworkManager configures wrong, spurious "local" route for IP address after DHCP address change
    * Prepare simulated test "testX4" device without DHCP
    * Execute "ip -n testX4_ns addr add dev testX4p 192.168.99.1/24"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.30,192.168.99.39,2m" without shell
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    * Execute "pkill -F /tmp/testX4_ns.pid"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.40,192.168.99.49,2m" without shell
    * Execute "ip l set testX4 up"
    When "192.168.99.4" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.3" is not visible with command "ip -4 r show table all dev testX4 scope link"
    * Execute "pkill -F /tmp/testX4_ns.pid"
    * Execute "ip l set testX4 down"
    * Run child "ip netns exec testX4_ns dnsmasq --pid-file=/tmp/testX4_ns.pid --listen-address=192.168.99.1 --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.59,2m" without shell
    * Execute "ip l set testX4 up"
    When "192.168.99.5" is visible with command "ip -4 r show table all dev testX4 scope link" in "60" seconds
    Then "192.168.99.[34]" is not visible with command "ip -4 r show table all dev testX4 scope link"


    @rhbz1861527
    @ver+=1.35.7
    @logging_info_only
    @ipv4_ignore_nonstatic_routes
    Scenario: NM - ipv4 - ignore routes that are neither static nor RA nor DHCP
    * Prepare simulated test "testX4" device using dhcpd and server identifier "192.168.1.1"
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    * Note the output of "nmcli -f ipv6.routes c show id con_ipv4" as value "nm_routes_before"
    When Execute "for i in {5..8} {10..15} 17 18 42 99 {186..192} ; do ip r add 192.168.${i}.0/24 proto ${i} dev testX4; done"
    * Note the output of "nmcli -f ipv6.routes c show id con_ipv4" as value "nm_routes_after_types"
    * Execute "nmcli -f ip6.route d show testX4"
    Then Check noted values "nm_routes_before" and "nm_routes_after_types" are the same
    # If more routes are needed, just adjust argument to the generating script and When check
    * Execute "prepare/bird_routes.py testX4 4 2000000 > /tmp/nmci-bird-routes-v4"
    * Execute "ip -b /tmp/nmci-bird-routes-v4"
    When There are "at least" "2000000" IP version "4" routes for device "testX4" in "5" seconds
    Then "--" is visible with command "nmcli -f ipv4.routes c show id con_ipv4" in "5" seconds
     And Execute "nmcli -f ip4.route d show testX4"
    * Delete connection "con_ipv4"
    Then There are "at most" "5" IP version "4" routes for device "testX4" in "5" seconds


    @rhbz2040683
    @ver+=1.35.7
    @ipv4_route-table_reapply
    Scenario: nmcli - ipv4 - route-table	config and reapply take	effect immediately
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


    @rhbz2047788
    @ver+=1.32.7
    @ipv4_required_timeout
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
    @ver+=1.30
    @rhelver+=8
    @scapy
    @dhcp_internal_ack_after_nak
    Scenario: NM - ipv4 - get IPv4 if ACK received after NAK
    * Prepare simulated test "testX4" device without DHCP
    # Script sends packets like this:
    # | <- DHCP Discover
    # | -> DHCP Offer
    # | <- DHCP Request
    # | -> DHCP Nak
    # | -> DHCP Ack
    # And this prevented internal DHCP client from getting the ack.
    * Execute "ip netns exec testX4_ns python contrib/reproducers/repro_2059673.py" without waiting for process to finish
    * Add "ethernet" connection named "con_ipv4" for device "testX4"
    * Bring "up" connection "con_ipv4"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "40" seconds
    Then "172.25.1.200" is visible with command "ip a s testX4"


    @rhbz1995372
    @ver+=1.35
    @ipv4_check_addr_order
    Scenario: nmcli - ipv4 - check IPv4 address order
    * Prepare simulated test "testX4" device
    * Add "ethernet" connection named "con_con" for device "testX4" with options "ipv4.method auto ipv4.may-fail no"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "/192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli connection modify con_con ipv4.addresses '192.168.99.1/24,192.168.99.2/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.1/24 192.168.99.2/24 /192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli connection modify con_con ipv4.addresses '192.168.99.1/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.1/24 /192.168.99.[0-9]+/24$" on device "testX4"
    * Execute "nmcli device modify testX4 +ipv4.addresses '192.168.99.3/24'"
    Then Check "ipv4" address list "192.168.99.1/24 192.168.99.3/24 /192.168.99.[0-9]+/24$" on device "testX4" in "3" seconds
    * Execute "nmcli device modify testX4 ipv4.addresses ''"
    Then Check "ipv4" address list "/192.168.99.[0-9]+/24$" on device "testX4" in "3" seconds
    * Execute "nmcli connection modify con_con ipv4.method manual ipv4.addresses '192.168.99.1/24,192.168.99.2/24,192.168.99.3/24'"
    * Bring "up" connection "con_con"
    Then Check "ipv4" address list "192.168.99.1/24 192.168.99.2/24 192.168.99.3/24" on device "testX4"
