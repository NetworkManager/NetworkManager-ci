Feature: nmcli: ipv4

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @con_ipv4_remove
    @ipv4_method_static_no_IP
    Scenario: nmcli - ipv4 - method - static without IP
     * Add connection type "ethernet" named "con_ipv4" for device "eth3"
     * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Save in editor
    Then Error type "connection verification failed: ipv4.addresses:" while saving in editor


    @rhbz979288
    @con_ipv4_remove
    @ipv4_method_manual_with_IP
    Scenario: nmcli - ipv4 - method - manual + IP
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.122.253"
    Then "192.168.122.253/32" is visible with command "ip a s eth3"
    Then "dhclient-eth3.pid" is not visible with command "ps aux|grep dhclient"


    @con_ipv4_remove
    @ipv4_method_static_with_IP
    Scenario: nmcli - ipv4 - method - static + IP
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253"
    Then "192.168.122.253/32" is visible with command "ip a s eth3"


    @con_ipv4_remove
    @ipv4_addresses_manual_when_asked
    Scenario: nmcli - ipv4 - addresses - IP allowing manual when asked
    * Add connection type "ethernet" named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.addresses 192.168.122.253" in editor
    * Submit "yes" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv4"
    Then "192.168.122.253/32" is visible with command "ip a s eth3"


    @rhbz1034900
    @con_ipv4_remove
    @ipv4_addresses_IP_slash_mask
    Scenario: nmcli - ipv4 - addresses - IP slash netmask
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253/24"
    Then "192.168.122.253/24 brd 192.168.122.255" is visible with command "ip a s eth3"


    @con_ipv4_remove
    @ipv4_change_in_address
    Scenario: nmcli - ipv4 - addresses - change in address
    * Add connection type "ethernet" named "con_ipv4" for device "eth3"
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


    @con_ipv4_remove
    @ipv4_addresses_IP_slash_invalid_mask
    Scenario: nmcli - ipv4 - addresses - IP slash invalid netmask
    * Add connection type "ethernet" named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/192.168.122.1" in editor
    Then Error type "failed to set 'addresses' property: invalid prefix '192.168.122.1'; <1-32> allowed" while saving in editor


    @rhbz1073824
    @veth @con_ipv4_remove @delete_testeth0 @restart
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


    @con_ipv4_remove
    @ipv4_addresses_IP_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - IP slash netmask and route
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253/24 ipv4.gateway 192.168.122.96"
    Then "192.168.122.253/24" is visible with command "ip a s eth3"
    Then "default via 192.168.122.96 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.253" is visible with command "ip route"
    Then "eth0" is visible with command "ip r |grep 'default via 1'" in "5" seconds
    Then "eth3" is visible with command "ip r |grep 'default via 1'" in "5" seconds


    @con_ipv4_remove
    @ipv4_addresses_more_IPs_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - several IPs slash netmask and route
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses '192.168.22.253/24, 192.168.122.253/16, 192.168.222.253/8' ipv4.gateway 192.168.22.96"
    Then "192.168.22.253/24" is visible with command "ip a s eth3"
    Then "192.168.122.253/16" is visible with command "ip a s eth3"
    Then "192.168.222.253/8" is visible with command "ip a s eth3"
    Then "default via 192.168.22.96 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "eth3" is visible with command "ip r |grep 'default via 1'" in "5" seconds


    @rhbz663730
    @ver+=1.6.0
    @ver-=1.9.1
    @con_ipv4_remove
    @route_priorities
    Scenario: nmcli - ipv4 - route priorities
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 autoconnect no ipv4.may-fail no"
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv42 autoconnect no ipv4.may-fail no"
     * Bring "up" connection "con_ipv4"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2" in "10" seconds
     When "metric 1" is visible with command "ip r |grep default |grep eth3" in "10" seconds
     * Modify connection "con_ipv42" changing options "ipv4.route-metric 200"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2" in "10" seconds
     When "metric 200" is visible with command "ip r |grep default |grep eth3" in "10" seconds
     * Modify connection "con_ipv42" changing options "ipv4.route-metric -1"
     * Bring "up" connection "con_ipv42"
     When "metric 1" is visible with command "ip r |grep default |grep eth2" in "10" seconds
     When "metric 1" is visible with command "ip r |grep default |grep eth3" in "10" seconds


    @rhbz663730
    @ver+=1.9.2
    @con_ipv4_remove
    @route_priorities
    Scenario: nmcli - ipv4 - route priorities
     * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 autoconnect no ipv4.may-fail no"
     * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv42 autoconnect no ipv4.may-fail no"
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


    @con_ipv4_remove
    @ipv4_method_back_to_auto
    Scenario: nmcli - ipv4 - addresses - delete IP and set method back to auto
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses '192.168.22.253/24, 192.168.122.253/16' ipv4.gateway 192.168.22.96"
    * Modify connection "con_ipv4" changing options "ipv4.method auto ipv4.addresses '' ipv4.gateway ''"
    * Bring "up" connection "con_ipv4"
    Then "192.168.22.253/24" is not visible with command "ip a s eth3"
    Then "192.168.22.96" is not visible with command "ip route"
    Then "192.168.122.253/24" is not visible with command "ip a s eth3"
    Then "192.168.122.95" is not visible with command "ip route"


    @con_ipv4_remove
    @ipv4_route_set_basic_route
    Scenario: nmcli - ipv4 - routes - set basic route
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.1.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.2.0/24 192.168.1.11 2' ipv4.route-metric 22"
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11 1' ipv4.route-metric 21"
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 22" is visible with command "ip route"
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric" is visible with command "ip route"


    @rhbz1373698
    @ver+=1.8.0
    @ver-=1.21.90
    @con_ipv4_remove
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256 ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600'"
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"


    @rhbz1373698 @rhbz1714438
    @ver+=1.22.0
    @con_ipv4_remove
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256 ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600, 0.0.0.0/0 192.168.4.1 mtu=1600'"
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev eth3 proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev eth3 proto static metric 256" is visible with command "ip r"


    @rhbz1373698
    @ver+=1.8.0
    @con_ipv4_remove @restart
    @ipv4_route_set_route_with_src_new_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in new syntax
    * Note the output of "ip r |grep eth0 |wc -l" as value "1"
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256 ipv4.routes '192.168.122.3 src=192.168.3.10'"
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
    @ifcfg-rh @con_ipv4_remove
    @ipv4_route_set_route_with_src_old_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in old syntax
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
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
    @ifcfg-rh @con_ipv4_remove
    @ipv4_route_modify_route_with_src_old_syntax_no_metric
    Scenario: nmcli - ipv4 - routes - modify route with src and no metric in old syntax
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
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
    @con_ipv4_remove @restart @ifcfg-rh
    @ipv4_route_set_route_with_src_old_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src old syntaxt restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
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
    @con_ipv4_remove @restart
    @ipv4_route_set_route_with_src_new_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src new syntaxt restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256 ipv4.routes '192.168.122.3 src=192.168.3.10'"
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
    @con_ipv4_remove @restart
    @no_metric_route_connection_restart_persistence
    Scenario: nmcli - ipv4 - routes - no\s+metric route connection restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11'"
    When "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Restart NM
    Then "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds



    @rhbz1436531
    @ver+=1.10
    @con_ipv4_remove @flush_300
    @ipv4_route_set_route_with_tables
    Scenario: nmcli - ipv4 - routes - set route with tables
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no ipv4.route-table 300"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show table 300"
     And "eth3" is not visible with command "ip r"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show con_ipv4 |awk -F '/' '{print $1}') dev eth3"
    When "10.20.30.0\/24 via 192.168.100.* dev eth3" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show table 300"
    * Bring "up" connection "con_ipv4"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.100.* dev eth3" is not visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show table 300"
     And "eth3" is not visible with command "ip r"


    @rhbz1436531
    @ver+=1.10
    @con_ipv4_remove @flush_300
    @ipv4_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv4 - routes - set route with tables reapply
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show con_ipv4 |awk -F '/' '{print $1}') dev eth3"
    When "10.20.30.0\/24 via 192.168.100.* dev eth3" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show"
    * Execute "nmcli device reapply eth3"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.100.* dev eth3" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth3 proto kernel scope link src 192.168.100.* metric 1" is visible with command "ip r show"


    @rhbz1503769
    @ver+=1.10
    @con_ipv4_remove
    @ipv4_restore_default_route_externally
    Scenario: nmcli - ipv4 - routes - restore externally
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no"
    When "connected" is visible with command "nmcli -g state,device device |grep eth3$" in "20" seconds
     And "default" is visible with command "ip r |grep eth3"
    * Execute "ip route delete default dev eth3"
    When "default" is not visible with command "ip r |grep eth3"
    * Execute "ip route add default via 192.168.100.1 metric 1"
    Then "default" is visible with command "ip r |grep eth3"


    @rhbz1164441
    @ver-=1.10.0
    @con_ipv4_remove
    @ipv4_route_remove_basic_route
    Scenario: nmcli - ipv4 - routes - remove basic route
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no ipv4.method static ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11 2'"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv42 ipv4.may-fail no ipv4.method static ipv4.addresses 192.168.1.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.2.0/24 192.168.1.11 3'"
    * Modify connection "con_ipv4" changing options "ipv4.routes ''"
    * Modify connection "con_ipv42" changing options "ipv4.routes ''"
    * Bring "up" connection "con_ipv4"
    * Bring "up" connection "con_ipv42"
    Then "default via 192.168.4.1 dev eth3\s+proto static\s+metric 1" is visible with command "ip route" in "5" seconds
    Then "default via 192.168.4.1 dev eth2\s+proto static\s+metric 1" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric 3" is not visible with command "ip route"
    Then "192.168.3.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth3\s+proto static\s+scope link\s+metric 1" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 1" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth3\s+proto static\s+metric 1" is not visible with command "ip route"


    @rhbz1164441
    @ver+=1.10.2
    @con_ipv4_remove
    @ipv4_route_remove_basic_route
    Scenario: nmcli - ipv4 - routes - remove basic route
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no ipv4.method static ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11 200'"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv42 ipv4.may-fail no ipv4.method static ipv4.addresses 192.168.1.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.2.0/24 192.168.1.11 300'"
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


    @con_ipv4_remove
    @ipv4_route_set_device_route
    Scenario: nmcli - ipv4 - routes - set device route
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no ipv4.method static ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.routes '192.168.1.0/24 0.0.0.0, 192.168.2.0/24 192.168.122.5'"
    Then "^connected" is visible with command "nmcli -t -f STATE,DEVICE device |grep eth3" in "5" seconds
    Then "default via 192.168.122.1 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.1.0/24 dev eth3\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.122.5 dev eth3\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @rhbz1439376
    @ver+=1.8.0
    @con_ipv4_remove
    @ipv4_host_destination_route
    Scenario: nmcli - ipv4 - routes - host destination
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ip4 192.168.122.123/24 ipv4.routes '10.20.30.10/24 192.168.122.2'"
    Then "^connected" is visible with command "nmcli -t -f STATE,DEVICE device |grep eth3" in "5" seconds


    @dummy
    @preserve_route_to_generic_device
    Scenario: nmcli - ipv4 - routes - preserve generic device route
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Execute "ip r add default via 0.0.0.0 dev dummy0"
    * Execute "ip a add 1.2.3.4/24 dev dummy0"
    Then "default dev dummy0" is visible with command "ip route"
    Then "1.2.3.0/24 dev dummy0\s+proto kernel\s+scope link\s+src 1.2.3.4" is visible with command "ip route"
    Then "IP4.ADDRESS\[1\]:\s+1.2.3.4/24" is visible with command "nmcli dev show dummy0" in "10" seconds
    Then "IP4.GATEWAY:\s+0.0.0.0" is visible with command "nmcli dev show dummy0"


    @con_ipv4_remove
    @ipv4_route_set_invalid_non_IP_route
    Scenario: nmcli - ipv4 - routes - set invalid route - non IP
    * Add connection type "ethernet" named "con_ipv4" for device "eth3"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.routes 255.255.255.256" in editor
    Then Error type "failed to set 'routes' property:" while saving in editor


    @con_ipv4_remove
    @ipv4_route_set_invalid_missing_gw_route
    Scenario: nmcli - ipv4 - routes - set invalid route - missing gw
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.routes 192.168.1.0/24"
    Then "default via 192.168.122.1 dev eth3\s+proto static\s+metric" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth3\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth3\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @ver+=1.4.0
    @ver-=1.11.2
    @con_ipv4_remove
    @ipv4_routes_not_reachable
    Scenario: nmcli - ipv4 - routes - set unreachable route
    * Add connection type "ethernet" named "con_ipv4" for device "eth3"
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
    @con_ipv4_remove
    @ipv4_routes_not_reachable
    Scenario: nmcli - ipv4 - routes - set unreachable route
    # Since version 1.11.3 NM automatically adds a device route to the
    # route gateway when it is not directly reachable
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.2/24 ipv4.gateway 192.168.122.1 ipv4.routes '192.168.1.0/24 192.168.3.11 1'"
    Then "\(connected\)" is visible with command "nmcli device show eth3"
    Then "192.168.3.11\s+dev eth3\s+proto static" is visible with command "ip r"


    @con_ipv4_remove
    @ipv4_dns_manual
    Scenario: nmcli - ipv4 - dns - method static + IP + dns
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253/24 ipv4.gateway 192.168.122.1 ipv4.dns '8.8.8.8, 8.8.4.4'"
    Then "nameserver 8.8.8.8.*nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf" in "10" seconds
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @con_ipv4_remove
    @ipv4_dns_manual_when_method_auto
    Scenario: nmcli - ipv4 - dns - method auto + dns
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.dns '8.8.8.8, 8.8.4.4'"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is visible with command "cat /etc/resolv.conf"


    @con_ipv4_remove
    @ipv4_dns_manual_when_ignore_auto_dns
    Scenario: nmcli - ipv4 - dns - method auto + dns + ignore automaticaly obtained
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253/24 ipv4.gateway 192.168.122.1 ipv4.dns '8.8.8.8, 8.8.4.4' ipv4.ignore-auto-dns yes"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @rhbz1405431
    @ver+=1.6.0
    @con_ipv4_remove @restart @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns
    Scenario: nmcli - ipv4 - preserve resolveconf if ignore_auto_dns
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "con_ipv4"
    * Stop NM
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    * Start NM
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Restart NM
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Restart NM
    Then "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"


    @rhbz1426748
    @ver+=1.8.0
    @con_ipv4_remove @restart @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var1
    Scenario: NM - ipv4 - preserve resolveconf if ignore_auto_dns with NM service up
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Restart NM
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Restart NM
    Then "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"


    @rhbz1344303
    @ver+=1.8.0
    @con_ipv4_remove @delete_testeth0 @restore_hostname
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var2
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "hostnamectl set-hostname braunberg"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "hostnamectl set-hostname --transient BraunBerg"
    Then "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"


    @rhbz1422610
    @ver+=1.8.0 @fedoraver-=32
    @con_ipv4_remove @delete_testeth0 @restore_hostname @eth3_disconnect @ifcfg-rh
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var3
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "con_ipv4"
    * Execute "echo 'search boston.com' > /etc/resolv.conf"
    * Execute "echo 'nameserver 1.2.3.4' >> /etc/resolv.conf"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "hostnamectl set-hostname braunberg"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "hostnamectl set-hostname --transient BraunBerg"
    When "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
     And "BraunBerg" is visible with command "hostnamectl --transient" in "5" seconds

    * Execute "ip add add 1.2.3.1/24 dev eth3"
    Then "braunberg" is visible with command "hostnamectl --static" for full "5" seconds
     And "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @con_ipv4_remove @restore_resolvconf @restart
    @ipv4_dns_resolvconf_rhel7_default
    Scenario: nmcli - ipv4 - dns - rhel7 default
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dns 8.8.8.8"
    * Bring "up" connection "con_ipv4"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @con_ipv4_remove @restore_resolvconf @restart
    @ipv4_dns_resolvconf_symlinked
    Scenario: nmcli - ipv4 - dns - symlink
    * Bring "down" connection "testeth0"
    * Execute "echo -e '[main]\nrc-manager=symlink' > /etc/NetworkManager/conf.d/99-resolv.conf"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    When "nameserver" is visible with command "cat /etc/resolv.conf" in "20" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dns 8.8.8.8"
    * Bring "up" connection "con_ipv4"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    Then "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
     And "are identical" is visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @con_ipv4_remove @restore_resolvconf @restart
    @ipv4_dns_resolvconf_file
    Scenario: nmcli - ipv4 - dns - file
    * Bring "down" connection "testeth0"
    * Execute "echo -e '[main]\nrc-manager=file' > /etc/NetworkManager/conf.d/99-resolv.conf"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    When "nameserver" is visible with command "cat /etc/resolv.conf" in "20" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dns 8.8.8.8"
    * Bring "up" connection "con_ipv4"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf -> /tmp/resolv.conf" is visible with command "ls -all /etc/resolv.conf"


    @con_ipv4_remove
    @ipv4_dns_add_another_one
    Scenario: nmcli - ipv4 - dns - add dns when one already set
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method static ipv4.addresses 192.168.122.253/24 ipv4.gateway 192.168.122.1 ipv4.dns '8.8.8.8'"
    * Bring "up" connection "con_ipv4"
    * Open editor for connection "con_ipv4"
    * Submit "set ipv4.dns 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "con_ipv4"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @con_ipv4_remove
    @ipv4_dns_delete_all
    Scenario: nmcli - ipv4 - dns - method auto then delete all dns
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.addresses 192.168.122.253/24 ipv4.gateway 192.168.122.1 ipv4.dns '8.8.8.8, 8.8.4.4'"
    * Modify connection "con_ipv4" changing options "ipv4.dns ''"
    * Bring "up" connection "con_ipv4"
    Then "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is visible with command "cat /etc/resolv.conf"


    @con_ipv4_remove @eth0
    @reload_dns
    Scenario: nmcli - ipv4 - dns - reload
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_ipv4 ipv4.may-fail no ipv4.dns '8.8.8.8, 8.8.4.4'"
    * Bring "up" connection "con_ipv4"
    When "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds
    When "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    * Execute "echo 'INVALID_DNS' > /etc/resolv.conf"
    * Execute "sudo kill -SIGUSR1 $(pidof NetworkManager)"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    * Execute "sleep 3"
    Then Ping "boston.com"


    @con_ipv4_remove @eth0
    @ipv4_dns-search_add
    Scenario: nmcli - ipv4 - dns-search - add dns-search
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_ipv4 ipv4.may-fail no ipv4.dns-search google.com"
    When "google.com" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then Ping "maps"
    Then Ping "maps.google.com"


    @con_ipv4_remove @eth0
    @ipv4_dns-search_remove
    Scenario: nmcli - ipv4 - dns-search - remove dns-search
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_ipv4 ipv4.may-fail no ipv4.dns-search google.com"
    * Modify connection "con_ipv4" changing options "ipv4.dns-search ''"
    * Bring "up" connection "con_ipv4"
    Then " google.com" is not visible with command "cat /etc/resolv.conf"
    Then Unable to ping "maps"
    When "nameserver" is visible with command "cat /etc/resolv.conf" in "10" seconds
    Then Ping "maps.google.com"


    @rhbz1443437
    @ver+=1.8.0 @ver-=1.20
    @tshark @con_ipv4_remove
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-hostname RC"
    * Bring "down" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "RC" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 2\s+Host Name: RC" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"


    @rhbz1443437 @rhbz1649376
    @ver+=1.21.90
    @tshark @con_ipv4_remove
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-hostname example.com"
    * Bring "down" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 11\s+Host Name: example.com" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"


    @tshark @con_ipv4_remove
    @ipv4_dhcp-hostname_remove
    Scenario: nmcli - ipv4 - dhcp-hostname - remove dhcp-hostname
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-hostname RHB"
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-hostname ''"
    * Bring "down" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
   Then "RHB" is not visible with command "cat /tmp/tshark.log" in "10" seconds
    * Finish "sudo pkill tshark"


    @rhbz1255507
    @tshark @con_ipv4_remove @restore_resolvconf
    @nmcli_ipv4_set_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - set dhcp-fqdn
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-fqdn foo.bar.com"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    #Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth2.conf"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Encoding: Binary encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Server" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"


    @rhbz1255507
    @ver+=1.3.0
    @ver-=1.21.90
    @tshark @con_ipv4_remove @not_under_internal_DHCP @restore_resolvconf
    @nmcli_ipv4_override_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-fqdn foo.bar.com"
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
    * Finish "sudo pkill tshark"


    @rhbz1255507 @rhbz1649368
    @ver+=1.22
    @tshark @con_ipv4_remove @restore_resolvconf
    @nmcli_ipv4_override_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-fqdn foo.bar.com ipv4.dhcp-hostname-flags fqdn-clear-flags"
    * Bring "up" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log"
    Then "Boot Request \(1\).*Flags: 0x00\s+" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"


    @rhbz1255507 @rhbz1649368
    @ver+=1.22
    @tshark @con_ipv4_remove @restore_resolvconf
    @nmcli_ipv4_override_fqdn_var1
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-fqdn foo.bar.com ipv4.dhcp-hostname-flags 'fqdn-serv-update fqdn-encoded'"
    * Bring "up" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "foo.bar.com" is visible with command "cat /tmp/tshark.log"
    Then "Boot Request \(1\).*Flags: 0x05" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"


    @tshark @con_ipv4_remove @teardown_testveth
    @nmcli_ipv4_remove_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - remove dhcp-fqdn
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.dhcp-fqdn foo.bar.com ipv4.may-fail no"
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-fqdn ''"
    * Bring "up" connection "con_ipv4"
    * Run child "sudo tshark -l -O bootp -i testX4 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
     Then "foo.bar.com" is not visible with command "grep fqdn /var/lib/NetworkManager/dhclient-testX4.conf" in "10" seconds
      And "foo.bar.com" is not visible with command "cat /tmp/tshark.log" for full "5" seconds
    * Finish "sudo pkill tshark"


    @tshark @con_ipv4_remove
    @ipv4_do_not_send_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - don't send
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-hostname RHC ipv4.dhcp-send-hostname no"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/hostname.log"
    When "empty" is not visible with command "file /tmp/hostname.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "RHC" is not visible with command "cat /tmp/hostname.log" in "10" seconds
    * Finish "sudo pkill tshark"


    @tshark @con_ipv4_remove @restore_hostname
    @ipv4_send_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - send real hostname
    * Execute "hostnamectl set-hostname foobar.test"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Hostname is visible in log "/tmp/tshark.log" in "10" seconds
    * Finish "sudo pkill tshark"


    @tshark @con_ipv4_remove
    @ipv4_ignore_sending_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - ignore sending real hostname
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-send-hostname no"
    * Run child "sudo tshark -l -O bootp -i eth2 > /tmp/real.log"
    When "empty" is not visible with command "file /tmp/real.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Hostname is not visible in log "/tmp/real.log" for full "10" seconds
    * Finish "sudo pkill tshark"


    @rhbz1264410
    @con_ipv4_remove @eth0
    @ipv4_add_dns_options
    Scenario: nmcli - ipv4 - dns-options - add
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.dns-options debug ipv4.may-fail no"
    Then "options debug" is visible with command "cat /etc/resolv.conf" in "45" seconds


    @con_ipv4_remove @eth0
    @ipv4_remove_dns_options
    Scenario: nmcli - ipv4 - dns-options - remove
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.dns-options debug ipv4.may-fail no"
    * Modify connection "con_ipv4" changing options "ipv4.dns-option ''"
    * Bring "up" connection "con_ipv4"
    Then "options debug" is not visible with command "cat /etc/resolv.conf" in "5" seconds


    @con_ipv4_remove @eth0
    @ipv4_dns-search_ignore_auto_routes
    Scenario: nmcli - ipv4 - dns-search - dns-search + ignore auto obtained routes
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv6.method ignore ipv6.ignore-auto-dns yes ipv4.dns-search google.com ipv4.ignore-auto-dns yes"
    Then "google.com" is visible with command "cat /etc/resolv.conf" in "45" seconds
    Then "virtual" is not visible with command "cat /etc/resolv.conf"


    @con_ipv4_remove
    @ipv4_method_link-local
    Scenario: nmcli - ipv4 - method - link-local
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method link-local ipv6.method ignore"
    Then "169.254" is visible with command "ip a s eth3" in "10" seconds


    @ver+=1.11.3 @rhelver+=8
    @eth2 @con_ipv4_remove @tcpdump
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-client-id AB"
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 3: \"AB\"" is visible with command "cat /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:ee"
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 4: hardware-type 192, ff:ee:ee" is visible with command "cat /tmp/tcpdump.log" in "10" seconds


    @gnome793957
    @ver+=1.11.3 @rhelver-=7 @not_with_rhel_pkg
    @eth2 @con_ipv4_remove @tcpdump
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-client-id AB"
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 3: \"AB\"" is visible with command "cat /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:ee"
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 4: hardware-type 192, ff:ee:ee" is visible with command "cat /tmp/tcpdump.log" in "10" seconds


    @ver+=1.11.2 @rhlever-=7 @rhel_pkg
    @eth2 @con_ipv4_remove @tshark
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-client-id AB"
    * Run child "sudo tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "AB" is visible with command "cat /tmp/tshark.log" in "10" seconds
    #Then "walderon" is visible with command "cat /var/lib/NetworkManager/dhclient-eth2.conf"
    #VVV verify bug 999503
     And "exceeds max \(255\) for precision" is not visible with command "grep exceeds max /var/log/messages"
    * Finish "sudo pkill tshark"


    @gnome793957
    @ver+=1.11.2
    @con_ipv4_remove @tcpdump @internal_DHCP @restart
    @ipv4_dhcp_client_id_set_internal
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id with internal client
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-client-id abcd"
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 5: \"abcd\"" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds
    #### Then try hexadecimal client-id
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id c0:ff:ee:11"
    * Execute "pkill tcpdump"
    * Run child "sudo tcpdump -i eth2 -v -n > /tmp/tcpdump.log"
    * Bring "up" connection "con_ipv4"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "Client-ID Option 61, length 4: hardware-type 192, ff:ee:11" is visible with command "grep 61 /tmp/tcpdump.log" in "10" seconds


    @rhbz1642023
    @ver+=1.14
    @ver-=1.21.0
    @con_ipv4_remove @restart @rhelver+=8 @rhel_pkg @internal_DHCP
    @ipv4_dhcp_client_id_change_lease_restart
    Scenario: nmcli - ipv4 - dhcp-client-id - lease file change should not be considered even after NM restart
    * Add connection type "ethernet" named "con_ipv4" for device "eth2"
    * Execute "rm /tmp/ipv4_client_id.lease"
    * Execute "sudo ln -s /var/lib/NetworkManager/internal-$(nmcli -f connection.uuid -t con show id con_ipv4 | sed 's/.*://')-eth2.lease /tmp/ipv4_client_id.lease"
    When "CLIENTID=" is visible with command "cat /tmp/ipv4_client_id.lease" in "10" seconds
    * Stop NM
    * Execute "cp /tmp/ipv4_client_id.lease /tmp/ipv4_client_id.lease.copy"
    * Execute "sudo sed 's/CLIENTID=.*/CLIENTID=00000000000000000000000000000000000000/' < /tmp/ipv4_client_id.lease.copy > /tmp/ipv4_client_id.lease"
    When "CLIENTID=00000000000000000000000000000000000000" is visible with command "cat /tmp/ipv4_client_id.lease" in "5" seconds
    * Start NM
    Then "CLIENTID=00000000000000000000000000000000000000" is not visible with command "cat /tmp/ipv4_client_id.lease" in "10" seconds


    @con_ipv4_remove @tshark
    @ipv4_dhcp_client_id_remove
    Scenario: nmcli - ipv4 - dhcp-client-id - remove client id
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no ipv4.dhcp-client-id BC"
    * Execute "rm -rf /var/lib/NetworkManager/*lease"
    * Bring "down" connection "con_ipv4"
    * Modify connection "con_ipv4" changing options "ipv4.dhcp-client-id ''"
    * Run child "sudo tshark -l -O bootp -i eth2 -x > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "BC" is not visible with command "cat /tmp/tshark.log" in "10" seconds
    * Execute "sudo pkill tshark"


    @rhbz1531173
    @ver+=1.10
    @eth2 @con_ipv4_remove @internal_DHCP @restart
    @ipv4_set_very_long_dhcp_client_id
    Scenario: nmcli - ipv4 - dhcp-client-id - set long client id
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_ipv4 ipv4.may-fail no autoconnect no"
    * Execute "nmcli connection modify con_ipv4 ipv4.dhcp-client-id $(printf '=%.0s' {1..999})"
    Then Bring "up" connection "con_ipv4"


    @rhbz1661165
    @ver+=1.15.1 @not_with_rhel_pkg
    @internal_DHCP @con_ipv4_remove @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to mac with internal plugins
    * Add connection type "ethernet" named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @ver+=1.12 @ver-1.15 @not_with_rhel_pkg
    @internal_DHCP @con_ipv4_remove @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to duid with internal plugins
    * Add connection type "ethernet" named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "00:02:00:00:ab:11" is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver+=8 @rhel_pkg
    @internal_DHCP @con_ipv4_remove @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to mac with internal plugins
    * Add connection type "ethernet" named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    * Note MAC address output for device "eth2" via ip command
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then Noted value is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


    @rhbz1661165
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @internal_DHCP @con_ipv4_remove @tcpdump @no_config_server
    @ipv4_dhcp_client_id_default
    Scenario: NM - ipv4 - ipv4 client id should default to duid with internal plugins
    * Add connection type "ethernet" named "con_ipv4" for device "eth2"
    * Run child "sudo tcpdump -i eth2 -v -n -l > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Bring "up" connection "con_ipv4"
    Then "00:02:00:00:ab:11" is visible with command "grep 'Option 61' /tmp/tcpdump.log" in "10" seconds


    @con_ipv4_remove
    @ipv4_may-fail_yes
    Scenario: nmcli - ipv4 - may-fail - set true
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.dhcp-client-id 1 ipv4.may-fail yes ipv6.method manual ipv6.addresses ::1"
    Then Bring "up" connection "con_ipv4"


    @con_ipv4_remove
    @ipv4_method_disabled
    Scenario: nmcli - ipv4 - method - disabled
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.method disabled ipv6.method manual ipv6.addresses ::1"
    Then Bring "up" connection "con_ipv4"


    @ver-=1.16
    @con_ipv4_remove @eth0
    @ipv4_never-default_set
    Scenario: nmcli - ipv4 - never-default - set
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.may-fail no ipv4.never-default yes "
    * Bring "up" connection "con_ipv4"
    Then "default via 192." is not visible with command "ip route"


    @rhbz1785039
    @ver+=1.25
    @con_ipv4_remove @eth0
    @ipv4_never-default_set
    Scenario: nmcli - ipv4 - never-default - set
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.may-fail no ipv4.never-default yes "
    * Bring "up" connection "con_ipv4"
    When "default via 1" is not visible with command "ip route"
    * Modify connection "con_ipv4" changing options "ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.4"
    * Bring "up" connection "con_ipv4"
    When "default via 1.2.3.4" is visible with command "ip route"
    * Modify connection "con_ipv4" changing options "ipv4.never-default yes"
    * Bring "up" connection "con_ipv4"
    Then "default via 1" is not visible with command "ip route"


    @con_ipv4_remove @eth0
    @ipv4_never-default_remove
    Scenario: nmcli - ipv4 - never-default - remove
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no ipv4.may-fail no ipv4.never-default yes "
    * Modify connection "con_ipv4" changing options "ipv4.never-default ''"
    * Bring "up" connection "con_ipv4"
    Then "default via 192." is visible with command "ip route"


    @rhbz1313091
    @ver+=1.2.0
    @con_ipv4_remove @restart
    @ipv4_never_default_restart_persistence
    Scenario: nmcli - ipv4 - never-default - restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.may-fail no ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1 ipv4.never-default yes"
    * Restart NM
    Then "eth3:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @mtu @kill_dnsmasq_ip4
    @set_mtu_from_DHCP
    Scenario: NM - ipv4 - set dhcp received MTU
    * Finish "ip link add test1 type veth peer name test1p"
    * Finish "ip link add test2 type veth peer name test2p"
    * Finish "ip link add name vethbr type bridge"
    * Finish "ip link set dev vethbr up"
    * Finish "ip link set test1p master vethbr"
    * Finish "ip link set test2p master vethbr"
    * Finish "ip link set dev test1 up"
    * Finish "ip link set dev test1p up"
    * Finish "ip link set dev test2 up"
    * Finish "ip link set dev test2p up"
    * Finish "nmcli connection add type ethernet con-name tc1 ifname test1 ip4 192.168.99.1/24"
    * Finish "nmcli connection add type ethernet con-name tc2 ifname test2"
    * Bring "up" connection "tc1"
    When "test1:connected:tc1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "/usr/sbin/dnsmasq --pid-file=/tmp/dnsmasq_ip4.pid --conf-file --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --strict-order --listen-address=192.168.99.1 --dhcp-range=192.168.99.10,192.168.99.254,60m --dhcp-option=option:router,192.168.99.1 --dhcp-lease-max=50 --dhcp-option-force=26,1800 &"
    * Bring "up" connection "tc2"
    Then "mtu 1800" is visible with command "ip a s test2"


    @ver-1.11
    @con_ipv4_remove @teardown_testveth @long
    @renewal_gw_after_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    When "con_ipv4" is not visible with command "nmcli connection s -a" in "800" seconds
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "400" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


    @rhbz1503587
    @ver+=1.10 @ver-1.11
    @con_ipv4_remove @teardown_testveth @long
    @renewal_gw_after_long_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    When "default" is not visible with command "ip r |grep testX4" in "130" seconds
    * Execute "sleep 500"
    * Execute "ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "130" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


    @rhbz1262922
    @ver+=1.2.0
    @con_ipv4_remove @teardown_testveth
    @dhcp-timeout
    Scenario: NM - ipv4 - add dhcp-timeout
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.dhcp-timeout 60 autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 50; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "10" seconds
    Then "default via 192.168.99.1 dev testX4" is visible with command "ip r"


    @rhbz1350830
    @ver+=1.10.0
    @con_ipv4_remove @teardown_testveth @ifcfg-rh
    @dhcp-timeout_infinity
    Scenario: NM - ipv4 - add dhcp-timeout infinity
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.dhcp-timeout infinity autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 70; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "10" seconds
     And "default via 192.168.99.1 dev testX4" is visible with command "ip r"
     And "IPV4_DHCP_TIMEOUT=2147483647" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"


    @rhbz1350830
    @ver+=1.10.0
    @con_ipv4_remove @remove_custom_cfg @teardown_testveth @restart
    @dhcp-timeout_default_in_cfg
    Scenario: nmcli - ipv4 - dhcp_timout infinity in cfg file
    * Execute "echo -e '[connection-eth-dhcp-timeout]\nmatch-device=type:ethernet;type:veth\nipv4.dhcp-timeout=2147483647' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "systemctl reload NetworkManager"
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Execute "sleep 50; ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)" without waiting for process to finish
    * Restart NM
    * Bring "up" connection "con_ipv4"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show con_ipv4" in "180" seconds
     And "default via 192.168.99.1 dev testX4" is visible with command "ip r"
     And "IPV4_DHCP_TIMEOUT=2147483647" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-con_ipv4"


    @rhbz1246496
    @ver-1.11
    @con_ipv4_remove @teardown_testveth @long @restart
    @renewal_gw_after_dhcp_outage_for_assumed_var0
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for on-disk assumed
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
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
    @teardown_testveth @long @restart
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
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
    @teardown_testveth @long @restart
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
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


    @rhbz1503587 @rhbz1518091 @rhbz1246496 @rhbz1503587
    @ver+=1.11
    @con @profie @con_ipv4_remove @teardown_testveth @long @restart @ifcfg-rh
    @dhcp4_outages_in_various_situation
    Scenario: NM - ipv4 - all types of dhcp outages
    ################# PREPARE testX4 AND testY4 ################################
    ## testX4 con_ipv4 for renewal_gw_after_dhcp_outage_for_assumed_var1
    * Prepare simulated test "testX4" device with "192.168.199" ipv4 and "dead:beaf:1" ipv6 dhcp address prefix
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
    * Bring "up" connection "con_ipv4"
    ## testY4 connie for renewal_gw_after_dhcp_outage_for_assumed_var0
    * Prepare simulated test "testY4" device with "192.168.200" ipv4 and "dead:beaf:2" ipv6 dhcp address prefix
    * Add a new connection of type "ethernet" and options "ifname testY4 con-name connie"
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
    * Add a new connection of type "ethernet" and options "ifname testA4 con-name con_ipv42 ipv4.may-fail no"
    ## testZ4 and profie for renewal_gw_after_dhcp_outage
    * Prepare simulated test "testZ4" device with "192.168.201" ipv4 and "dead:beaf:3" ipv6 dhcp address prefix
    * Add a new connection of type "ethernet" and options "ifname testZ4 con-name profie ipv4.may-fail no"
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


    @ver+=1.11
    @con_ipv4_remove @teardown_testveth @long
    @dhcp_change_pool
    Scenario: NM - ipv4 - renewal after changed DHCP pool
    # Check that the address is renewed immediately after a NAK
    # from server due to changed configuration.
    # https://bugzilla.gnome.org/show_bug.cgi?id=783391
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:cafe" ipv6 dhcp address prefix
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no ipv6.method ignore autoconnect no"
    * Bring "up" connection "con_ipv4"
    When "default via 192.168.99.1 dev testX4" is visible with command "ip r"
    * Restart dhcp server on "testX4" device with "192.168.98" ipv4 and "2620:cafe" ipv6 dhcp address prefix
    Then "default via 192.168.98.1 dev testX4" is visible with command "ip r" in "130" seconds


    @rhbz1205405
    @con_ipv4_remove @teardown_testveth @long
    @manual_routes_preserved_when_never-default_yes
    Scenario: NM - ipv4 - don't touch manual route with never-default
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no ipv4.never-default yes autoconnect no"
    * Bring "up" connection "con_ipv4"
    When "default" is not visible with command "ip r |grep testX4"
    * Execute "ip route add default via 192.168.99.1 dev testX4 metric 666"
    * Execute "sleep 70"
    Then "default via 192.168.99.1 dev testX4\s+metric 666" is visible with command "ip r"


    @rhbz1205405
    @teardown_testveth @con_ipv4_remove @long
    @manual_routes_removed_when_never-default_no
    Scenario: NM - ipv4 - rewrite manual route with dhcp renewal
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no ipv4.never-default no autoconnect no"
    * Bring "up" connection "con_ipv4"
    * Execute "ip route add default via 192.168.99.1 dev testX4\s+metric 666"
    Then "default via 192.168.99.1 dev testX4\s+metric 666" is not visible with command "ip r" in "70" seconds


    @rhbz1284261
    @no_config_server @con_ipv4_remove @teardown_testveth
    @ipv4_remove_default_route_for_no_carrier
    Scenario: NM - ipv4 - remove default route for no carrier
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no"
    When "default" is visible with command "ip r | grep testX4" in "40" seconds
    * Execute "ip netns exec testX4_ns ip link set dev testX4p down"
    Then "default" is not visible with command "ip r |grep testX4" in "10" seconds
     And "con_ipv4" is not visible with command "nmcli con show -a"


     @rhbz1259063
     @ver+=1.4.0
     @con_ipv4_remove @teardown_testveth
     @ipv4_dad
     Scenario: NM - ipv4 - DAD
     * Prepare simulated test "testX4" device
     * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24"
     When "testX4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 5000"
     * Bring up connection "con_ipv4" ignoring error
     When "testX4:connected:con_ipv4" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     * Modify connection "con_ipv4" changing options "ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.2/24 ipv4.dad-timeout 5000"
     * Bring "up" connection "con_ipv4"
     Then "testX4:connected:con_ipv4" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @con_ipv4_remove @restart
    @custom_shared_range_preserves_restart
    Scenario: nmcli - ipv4 - shared custom range preserves restart
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_ipv4 ipv4.addresses 192.168.100.1/24 ipv4.method shared connection.autoconnect yes"
    * Restart NM
    Then "ipv4.addresses:\s+192.168.100.1/24" is visible with command "nmcli con show con_ipv4"


    @rhbz1834907
    @ver+=1.4 @ver-=1.24
    @two_bridged_veths @permissive
    @ipv4_method_shared
    Scenario: nmcli - ipv4 - method shared
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Add a new connection of type "ethernet" and options "con-name tc1 autoconnect no ifname test1 ipv4.method shared ipv6.method ignore"
    * Add a new connection of type "ethernet" and options "con-name tc2 autoconnect no ifname test2"
    Then Bring "up" connection "tc1"
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same


    @rhbz1834907
    @ver+=1.25
    @two_bridged_veths @permissive @firewall
    @ipv4_method_shared
    Scenario: nmcli - ipv4 - method shared
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Add a new connection of type "ethernet" and options "con-name tc1 autoconnect no ifname test1 ipv4.method shared ipv6.method ignore"
    * Add a new connection of type "ethernet" and options "con-name tc2 autoconnect no ifname test2"
    Then Bring "up" connection "tc1"
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same


    @rhbz1404148
    @ver+=1.10
    @two_bridged_veths @kill_dnsmasq_ip4 @ifcfg-rh
    @ipv4_method_shared_with_already_running_dnsmasq
    Scenario: nmcli - ipv4 - method shared when dnsmasq does run
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Execute "/usr/sbin/dnsmasq --log-dhcp --log-queries --conf-file=/dev/null --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --pid-file=/tmp/dnsmasq_ip4.pid &"
    * Add a new connection of type "ethernet" and options "con-name tc1 autoconnect no ifname test1 ipv4.method shared ipv6.method ignore"
    * Add a new connection of type "ethernet" and options "con-name tc2 autoconnect no ifname test2 ipv4.may-fail yes ipv6.method manual ipv6.addresses 1::1/128"
    * Bring up connection "tc1" ignoring error
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same
     And "disconnected" is visible with command "nmcli  device show test1" in "10" seconds


    @rhbz1172780
    @con_ipv4_remove @netaddr @long
    @ipv4_do_not_remove_second_ip_route
    Scenario: nmcli - ipv4 - do not remove secondary ip subnet route
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 autoconnect no"
    * Bring up connection "con_ipv4"
    * "192.168" is visible with command "ip a s eth3" in "20" seconds
    * "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route"
    * Add a secondary address to device "eth3" within the same subnet
    Then "dev eth3\s+proto kernel\s+scope link" is visible with command "ip route" for full "80" seconds


    @con_ipv4_remove
    @ver-=1.19.1
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty." are present in describe output for object "method"

    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv4 addresses of DNS servers.\s+Example: 8.8.8.8, 8.8.4.4" are present in describe output for object "dns"

    Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+Array of DNS search domains." are present in describe output for object "dns-search"

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


    @con_ipv4_remove
    @ver+=1.19.2
    @ipv4_describe
    Scenario: nmcli - ipv4 - describe
    * Open editor for a type "ethernet"
    When Check "\[method\]|\[dns\]|\[dns-search\]|\[addresses\]|\[gateway\]|\[routes\]|\[ignore-auto-routes\]|\[ignore-auto-dns\]|\[dhcp-hostname\]|\[never-default\]|\[may-fail\]" are present in describe output for object "ipv4"
    * Submit "goto ipv4" in editor

    Then Check "=== \[method\] ===\s+\[NM property description\]\s+IP configuration method. NMSettingIP4Config and NMSettingIP6Config both support \"disabled\", \"auto\", \"manual\", and \"link-local\". See the subclass-specific documentation for other values. In general, for the \"auto\" method, properties such as \"dns\" and \"routes\" specify information that is added on to the information returned from automatic configuration.  The \"ignore-auto-routes\" and \"ignore-auto-dns\" properties modify this behavior. For methods that imply no upstream network, such as \"shared\" or \"link-local\", these properties must be empty. For IPv4 method \"shared\", the IP subnet can be configured by adding one manual IPv4 address or otherwise 10.42.x.0\/24 is chosen. Note that the shared method must be configured on the interface which shares the internet to a subnet, not on the uplink which is shared." are present in describe output for object "method"


    Then Check "=== \[dns\] ===\s+\[NM property description\]\s+Array of IP addresses of DNS servers.\s+\[nmcli specific description\]\s+Enter a list of IPv4 addresses of DNS servers.\s+Example: 8.8.8.8, 8.8.4.4" are present in describe output for object "dns"

    Then Check "=== \[dns-search\] ===\s+\[NM property description\]\s+Array of DNS search domains." are present in describe output for object "dns-search"

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


    @rhbz1394500
    @ver+=1.4.0
    @con_ipv4_remove
    @ipv4_honor_ip_order_1
    Scenario: NM - ipv4 - honor IP order from configuration
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ipv4.method manual ipv4.addresses '192.168.1.5/24,192.168.1.4/24,192.168.1.3/24'"
    Then "inet 192.168.1.5/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2" in "5" seconds
    Then "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"
    Then "inet 192.168.1.3/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"


    @rhbz1394500
    @ver+=1.4.0
    @con_ipv4_remove
    @ipv4_honor_ip_order_2
    Scenario: NM - ipv4 - honor IP order from configuration upon reapply
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ipv4.method manual ipv4.addresses '192.168.1.3/24,192.168.1.4/24,192.168.1.5/24'"
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
    @con_ipv4_remove @restore_rp_filters
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1 @ver-1.14
    @con_ipv4_remove @restore_rp_filters
    @not_with_rhel_pkg
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893 @rhbz1492472
    @ver+=1.9.1
    @con_ipv4_remove @restore_rp_filters
    @rhel_pkg
    @ipv4_rp_filter_set_loose_rhel
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @con_ipv4_remove @restore_rp_filters
    @ipv4_rp_filter_do_not_touch
    Scenario: NM - ipv4 - don't touch disabled RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 0 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1
    @con_ipv4_remove @restore_rp_filters @rhel_pkg
    @ipv4_rp_filter_do_not_touch
    Scenario: NM - ipv4 - don't touch disabled RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 0 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 1" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 1" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @con_ipv4_remove @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
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
    @con_ipv4_remove @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
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
    @con_ipv4_remove @restore_rp_filters
    @ipv4_rp_filter_reset_rhel
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name con_ipv42 ifname eth3 ip4 192.168.11.2/24"
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
    @con_ipv4_remove @teardown_testveth @kill_dhcrelay
    @ipv4_dhcp_do_not_add_route_to_server
    Scenario: NM - ipv4 - don't add route to server
    * Prepare simulated test "testX4" device with DHCPv4 server on different network
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname testX4"
    Then "10.0.0.0/24 via 172.16.0.1 dev testX4" is visible with command "ip route" in "45" seconds
    Then "10.0.0.1 via.*dev testX4" is not visible with command "ip route"
    Then "10.0.0.1 dev testX4" is not visible with command "ip route"


    @rhbz1449873
    @ver+=1.8.0
    @dummy
    @ipv4_keep_external_addresses
    Scenario: NM - ipv4 - keep external addresses
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Execute "for i in $(seq 20); do for j in $(seq 200); do ip addr add 10.3.$i.$j/16 dev dummy0; done; done"
    When "4000" is visible with command "ip addr show dev dummy0 | grep 'inet 10.3.' -c"
    * Execute "sleep 6"
    Then "4000" is visible with command "ip addr show dev dummy0 | grep 'inet 10.3.' -c"


    @rhbz1428334
    @ver+=1.10.0
    @con_ipv4_remove
    @ipv4_route_onsite
    Scenario: nmcli - ipv4 - routes - add device route if onsite specified
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.3.254"
    * Execute "echo '10.200.200.2/31 via 172.16.0.254' > /etc/sysconfig/network-scripts/route-con_ipv4"
    * Reload connections
    * Execute "nmcli connection modify con_ipv4 ipv4.routes '10.200.200.2/31 172.16.0.254 111 onlink=true'"
    * Bring "up" connection "con_ipv4"
    Then "default via 192.168.3.254 dev eth3 proto static metric 1" is visible with command "ip r"
     And "10.200.200.2/31 via 172.16.0.254 dev eth3 proto static metric 111 onlink" is visible with command "ip r"
     And "192.168.3.0/24 dev eth3 proto kernel scope link src 192.168.3.10 metric 1" is visible with command "ip r"


    @rhbz1482772
    @ver+=1.10
    @con_ipv4_remove
    @ipv4_multiple_ip4
    Scenario: nmcli - ipv4 - method - static using multiple "ip4" options
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ip4 192.168.124.1/24 ip4 192.168.125.1/24"
    Then "192.168.124.1/24" is visible with command "ip a s eth3" in "45" seconds
    Then "192.168.125.1/24" is visible with command "ip a s eth3"


    @rhbz1519299
    @ver+=1.12
    @con_ipv4_remove @ifcfg-rh
    @ipv4_dhcp-hostname_shared_persists
    Scenario: nmcli - ipv4 - ipv4 dhcp-hostname persists after method shared set
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.dhcp-hostname test"
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
    @con_ipv4_remove @teardown_testveth @long
    @nm_dhcp_lease_renewal_link_down
    Scenario: NM - ipv4 - link down during dhcp renewal causes NM to never ask for new lease
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv4.may-fail no"
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
    @teardown_testveth @long
    @dhcp_renewal_with_ipv6
    Scenario: NM - ipv4 - start dhcp after timeout with ipv6 already in
    * Prepare simulated test "testX4" device
    * Execute "ip netns exec testX4_ns pkill -SIGSTOP -F /tmp/testX4_ns.pid"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 ipv6.method manual ipv6.addresses dead::beaf/128"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds
    * Execute "sleep 45 && ip netns exec testX4_ns pkill -SIGCONT -F /tmp/testX4_ns.pid"
    Then "192.168" is visible with command "ip a s testX4" in "20" seconds


    @rhbz1636715
    @ver+=1.12
    @con_ipv4_remove
    @ipv4_prefix_route_missing_after_ip_link_down_up
    Scenario: NM - ipv4 - preffix route is missing after putting link down and up
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 192.168.3.10/24"
    When "192.168.3.0/24 dev eth3" is visible with command "ip r" in "5" seconds
    * Execute "ip link set eth3 down; ip link set eth3 up"
    * Execute "ip link set eth3 down; ip link set eth3 up"
    Then "192.168.3.0/24 dev eth3" is visible with command "ip r" in "5" seconds


    @rhbz1369905
    @ver+=1.16
    @con_ipv4_remove @teardown_testveth
    @ipv4_manual_addr_before_dhcp
    Scenario: nmcli - ipv4 - set manual values immediately
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname testX4 autoconnect no ipv4.method auto ipv4.addresses 192.168.3.10/24 ipv4.routes '192.168.5.0/24 192.168.3.11 101'"
    * Execute "ip netns exec testX4_ns kill -SIGSTOP $(cat /tmp/testX4_ns.pid)"
    * Run child "sleep 10 && ip netns exec testX4_ns kill -SIGCONT $(cat /tmp/testX4_ns.pid)"
    * Run child "nmcli con up con_ipv4"
    Then "192.168.3.10/24" is visible with command "ip a s testX4"
     And "192.168.5.0/24 via 192.168.3.11 dev testX4\s+proto static\s+metric 101" is visible with command "ip route"
     # And "namespace 192.168.3.11" is visible with command "cat /etc/resolv.conf" in "10" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ipv4" in "45" seconds


    @rhbz1652653 @rhbz1696881
    @ver+=1.18.4
    @con_ipv4_remove @restart
    @ipv4_routing_rules_manipulation
    Scenario: NM - ipv4 - routing rules manipulation
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 autoconnect no"
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
    @con_ipv4_remove @teardown_testveth @internal_DHCP
    @dhcp_multiple_router_options
    Scenario: NM - ipv4 - dhcp server sends multiple router options
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "option:router,192.168.99.10,192.168.99.20,192.168.99.21"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "default via 192.168.99.10 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n1"
     And "default via 192.168.99.20 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n2"
     And "default via 192.168.99.21 proto dhcp metric " is visible with command "ip -4 r show dev testX4 | grep ^default | head -n3"


    @rhbz1663253
    @ver+=1.20
    @con_ipv4_remove @teardown_testveth @dhclient_DHCP
    @dhcp_private_option_dhclient
    Scenario: NM - ipv4 - dhcp server sends private options dhclient
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "unknown_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep unknown_245); echo ${A#*:}"
    Then "private_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep private_245); echo ${A#*:}"


    @rhbz1663253
    @ver+=1.20
    @con_ipv4_remove @teardown_testveth @internal_DHCP
    @dhcp_private_option_internal
    Scenario: NM - ipv4 - dhcp server sends private options internal
    * Prepare simulated test "testX4" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4"
    When "192.168.99." is visible with command "ip a show dev testX4" in "40" seconds
    Then "private_245 = aa:bb:cc:dd" is visible with command "A=$(nmcli -t -f DHCP4 c s con_ipv4 | grep private_245); echo ${A#*:}"


    @rhbz1767681 @rhbz1686634
    @ver+=1.18.4
    @two_bridged_veths @tshark
    @ipv4_send_arp_announcements
    Scenario: NM - ipv4 - check that gratuitous ARP announcements are sent"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Add a new connection of type "ethernet" and options "con-name tc1 ifname test1 ip4 172.21.1.1/24 ipv6.method ignore"
    * Run child "sudo tshark -l -i test2 arp > /tmp/tshark.log"
    * Execute "sleep 8"
    * Bring "up" connection "tc1"
    Then "ok" is visible with command "[ $(grep -c 'Gratuitous ARP for 172.21.1.1'|ARP Announcement for 172.21.1.1' /tmp/tshark.log) -gt 1 ] && echo ok" in "60" seconds


    @tshark @con_ipv4_remove @teardown_testveth
    @dhcp_reboot
    Scenario: DHCPv4 reboot
    # Check that the client reuses an existing lease
    * Execute "rm /tmp/testX4_ns.lease"
    * Prepare simulated test "testX4" device
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
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


    @internal_DHCP @tshark @con_ipv4_remove @teardown_testveth
    @dhcp_reboot_nak
    Scenario: DHCPv4 reboot NAK
    # Check that the client performs a reboot when there is an existing lease and the server replies with a NAK
    * Execute "rm /tmp/testX4_ns.lease"
    # Start with the --dhcp-authoritative option so that the server will not ignore unknown leases
    * Prepare simulated test "testX4" device with daemon options "--dhcp-authoritative"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
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
    @teardown_testveth @con_ipv4_remove @kill_children @dhcpd @long
    @dhcp_rebind
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "10.10.10.1"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Execute "sleep 10"
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds


    @rhbz1806516
    @ver+=1.22.7
    @teardown_testveth @con_ipv4_remove @long @clean_iptables
    @dhcp_rebind_with_firewall
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "10.10.10.1"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
    * Execute "iptables -A OUTPUT -p udp --dport 67 -j REJECT"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Execute "sleep 10"
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds


    @rhbz1841937
    @ver+=1.25.2
    @teardown_testveth @con_ipv4_remove @long
    @dhcp_rebind_with_firewall_var2
    Scenario: DHCPv4 rebind
    * Execute "systemctl stop dhcpd"
    * Prepare simulated test "testX4" device using dhcpd and server identifier "192.168.99.1"
    * Execute "ip netns exec testX4_ns iptables -A INPUT -p udp --dport 67 -j REJECT"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    When "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "20" seconds
    * Execute "sleep 10"
    Then "valid_lft 14[0-9]" is visible with command "ip -4 addr show dev testX4" in "140" seconds



    @con_ipv4_remove @teardown_testveth
    @dhcp_option_classless_routes
    Scenario: DHCPv4 classless routes option parsing
    * Prepare simulated test "testX4" device with dhcp option "option:classless-static-route,10.0.0.0/8,192.168.99.3,20.1.0.0/16,192.168.99.4,30.1.1.0/28,192.168.99.5"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "10.0.0.0/8 via 192.168.99.3" is visible with command "ip route show dev testX4"
    Then "20.1.0.0/16 via 192.168.99.4" is visible with command "ip route show dev testX4"
    Then "30.1.1.0/28 via 192.168.99.5" is visible with command "ip route show dev testX4"


    @con_ipv4_remove @teardown_testveth
    @dhcp_option_domain_search
    Scenario: DHCPv4 domain search option parsing
    * Prepare simulated test "testX4" device with dhcp option "option:domain-search,corp.example.com,db.example.com,test.com"
    * Add a new connection of type "ethernet" and options "ifname testX4 con-name con_ipv4 autoconnect no ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "corp\.example\.com db\.example\.com test\.com" is visible with command "grep search /etc/resolv.conf" in "2" seconds

    @rhbz1764986
    @ver+=1.22.4
    @con_ipv4_remove
    @ipv4_31_netprefix_ptp_link
    Scenario: nmcli - ipv4 - addresses - manual with 31 bits network prefix length
    * Add a new connection of type "ethernet" and options "ifname eth3 con-name con_ipv4 ipv4.method manual ipv4.addresses 172.16.0.2/31"
    Then "172.16.0.2/31" is visible with command "ip a s eth3"
    Then "brd 172.16.0.3" is not visible with command "ip a s eth3"


    @rhbz1749358
    @ver+=1.22.0
    @con_ipv4_remove @bridge
    @ipv4_dhcp_iaid_unset
    Scenario: nmcli - ipv4 - IAID unset which defaults to ifname
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dhcp-client-id duid"
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add a new connection of type "bridge" and options "con-name br88 ifname br88 bridge.stp false ipv4.dhcp-client-id duid"
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are not the same


    @rhbz1749358
    @ver+=1.22.0
    @con_ipv4_remove @bridge
    @ipv4_dhcp_iaid_ifname
    Scenario: nmcli - ipv4 - IAID ifname
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dhcp-client-id duid ipv4.dhcp-iaid ifname"
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add a new connection of type "bridge" and options "con-name br88 ifname br88 bridge.stp false ipv4.dhcp-client-id duid ipv4.dhcp-iaid ifname"
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are not the same


    @rhbz1749358
    @ver+=1.22.0
    @con_ipv4_remove @bridge
    @ipv4_dhcp_iaid_mac
    Scenario: nmcli - ipv4 - IAID mac
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dhcp-client-id duid ipv4.dhcp-iaid mac"
    When "inet" is visible with command "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s eth3 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_eth3"
    * Add a new connection of type "bridge" and options "con-name br88 ifname br88 bridge.stp false ipv4.dhcp-client-id duid ipv4.dhcp-iaid mac"
    * Modify connection "con_ipv4" changing options "connection.master br88 connection.slave-type bridge"
    * Bring "up" connection "br88"
    * Bring "up" connection "con_ipv4"
    When "inet" is visible with command "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" in "10" seconds
    * Note the output of "ip a s br88 | grep -E -o 'inet\s+[0-9.]*'" as value "ipv4_br88"
    Then Check noted values "ipv4_eth3" and "ipv4_br88" are the same


    @rhbz1700415
    @ver+=1.22.0
    @con_ipv4_remove @eth3_disconnect
    @ipv4_external_addresses_no_double_routes
    Scenario: NM - ipv4 - no routes are added by NM for external addresses
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.method manual ipv4.addresses 192.168.47.1/24"
    When "192.168.47.1/24" is visible with command "ip a sh dev eth3" in "30" seconds
    * Execute "ip a add 1.2.3.4/32 dev eth3; ip a add 4.3.2.1/30 dev eth3"
    When "4.3.2.1/30" is visible with command "ip a sh dev eth3" in "30" seconds
    * Execute "ip link set dev eth3 down; ip link set dev eth3 up"
    Then "1.2.3.4" is not visible with command "ip r show dev eth3" for full "10" seconds
    Then "4.3.2.0/30.*4.3.2.0/30" is not visible with command "ip r show dev eth3"


    @rhbz1871042
    @ver+=1.26
    @con_ipv4_remove @ifcfg-rh
    @ipv4_dhcp_vendor_class_ifcfg
    Scenario: NM - ipv4 - ipv4.dhcp-vendor-class-identifier is translated to ifcfg
    * Add a new connection of type "ethernet" and options "con-name con_ipv4 ifname eth3 ipv4.dhcp-vendor-class-identifier RedHat"
    Then "RedHat" is visible with command "grep 'DHCP_VENDOR_CLASS_IDENTIFIER=' /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Execute "sed -i 's/DHCP_VENDOR_CLASS_IDENTIFIER=.*/DHCP_VENDOR_CLASS_IDENTIFIER=RH/' /etc/sysconfig/network-scripts/ifcfg-con_ipv4"
    * Reload connections
    Then "RH" is visible with command "nmcli -g ipv4.dhcp-vendor-class-identifier con show con_ipv4"
