Feature: nmcli: ipv4

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ipv4
    @ipv4_method_static_no_IP
    Scenario: nmcli - ipv4 - method - static without IP
     * Add connection type "ethernet" named "ethie" for device "eth1"
     * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Save in editor
    Then Error type "connection verification failed: ipv4.addresses:" while saving in editor


    @rhbz979288
    @ipv4
    @ipv4_method_manual_with_IP
    Scenario: nmcli - ipv4 - method - manual + IP
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method manual" in editor
    * Submit "set ipv4.addresses 192.168.122.253" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.122.253/32" is visible with command "ip a s eth1"
    Then "dhclient-eth1.pid" is not visible with command "ps aux|grep dhclient"


    @ipv4
    @ipv4_method_static_with_IP
    Scenario: nmcli - ipv4 - method - static + IP
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.122.253/32" is visible with command "ip a s eth1"


    @ipv4
    @ipv4_addresses_manual_when_asked
    Scenario: nmcli - ipv4 - addresses - IP allowing manual when asked
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.addresses 192.168.122.253" in editor
    * Submit "yes" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.122.253/32" is visible with command "ip a s eth1"


    @ipv4
    @ipv4_addresses_IP_slash_mask
    Scenario: nmcli - ipv4 - addresses - IP slash netmask
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/24" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    #reproducer for 1034900
    Then "192.168.122.253/24 brd 192.168.122.255" is visible with command "ip a s eth1"


    @ipv4 @eth0
    @ipv4_change_in_address
    Scenario: nmcli - ipv4 - addresses - change in address
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
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
    * Bring "up" connection "ethie"
    Then "1.1.1.99/24 brd 1.1.1.255" is visible with command "ip a s eth1"
    Then "default via 1.1.1.4" is visible with command "ip route"
    Then "default via 1.1.1.1" is not visible with command "ip route"


    @ipv4
    @ipv4_addresses_IP_slash_invalid_mask
    Scenario: nmcli - ipv4 - addresses - IP slash invalid netmask
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/192.168.122.1" in editor
    Then Error type "failed to set 'addresses' property: invalid prefix '192.168.122.1'; <1-32> allowed" while saving in editor


    @rhbz1073824
    @veth @ipv4 @delete_testeth0
    @ipv4_take_manually_created_ifcfg_with_ip
    Scenario: nmcli - ipv4 - use manually created ipv4 profile
    * Append "DEVICE='eth10'" to ifcfg file "ethie"
    * Append "ONBOOT=yes" to ifcfg file "ethie"
    * Append "NETBOOT=yes" to ifcfg file "ethie"
    * Append "UUID='aa17d688-a38d-481d-888d-6d69cca781b8'" to ifcfg file "ethie"
    * Append "BOOTPROTO=none" to ifcfg file "ethie"
    #* Append "HWADDR='52:54:00:32:77:59'" to ifcfg file "ethie"
    * Append "TYPE=Ethernet" to ifcfg file "ethie"
    * Append "NAME='ethie'" to ifcfg file "ethie"
    * Append "IPADDR='10.0.0.2'" to ifcfg file "ethie"
    * Append "PREFIX='24'" to ifcfg file "ethie"
    * Append "GATEWAY='10.0.0.1'" to ifcfg file "ethie"
    * Restart NM
    Then "aa17d688-a38d-481d-888d-6d69cca781b8" is visible with command "nmcli -f UUID connection show -a"


    @ipv4
    @ipv4_addresses_IP_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - IP slash netmask and route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/24" in editor
    * Submit "set ipv4.gateway 192.168.122.96" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.122.253/24" is visible with command "ip a s eth1"
    Then "default via 192.168.122.96 dev eth1\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.122.253" is visible with command "ip route"
    Then "2" is visible with command "ip r |grep 'default via 1' |wc -l"


    @ipv4 @eth0
    @ipv4_addresses_more_IPs_slash_mask_and_route
    Scenario: nmcli - ipv4 - addresses - several IPs slash netmask and route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.22.253/24, 192.168.122.253/16" in editor
    * Submit "set ipv4.addresses 192.168.222.253/8" in editor
    * Submit "set ipv4.gateway 192.168.22.96" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.22.253/24" is visible with command "ip a s eth1"
    Then "192.168.122.253/16" is visible with command "ip a s eth1"
    Then "192.168.222.253/8" is visible with command "ip a s eth1"
    Then "default via 192.168.22.96 dev eth1\s+proto static\s+metric" is visible with command "ip route"
    Then "1" is visible with command "ip r |grep 'default via 1' |wc -l"


    @ipv4
    @ipv4_method_back_to_auto
    Scenario: nmcli - ipv4 - addresses - delete IP and set method back to auto
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.22.253/24, 192.168.122.253/16" in editor
    * Submit "set ipv4.gateway 192.168.22.96" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.addresses" in editor
    * Enter in editor
    * Submit "set ipv4.gateway" in editor
    * Enter in editor
    * Submit "set ipv4.method auto" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "192.168.22.253/24" is not visible with command "ip a s eth1"
    Then "192.168.22.96" is not visible with command "ip route"
    Then "192.168.122.253/24" is not visible with command "ip a s eth1"
    Then "192.168.122.95" is not visible with command "ip route"


    @ipv4_2 @eth0
    @ipv4_route_set_basic_route
    Scenario: nmcli - ipv4 - routes - set basic route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.3.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.3.11 1" in editor
    * Submit "set ipv4.route-metric 21" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Add connection type "ethernet" named "ethie2" for device "eth2"
    * Open editor for connection "ethie2"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.1.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.2.0/24 192.168.1.11 2" in editor
    * Submit "set ipv4.route-metric 22" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie2"
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 22" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth1\s+proto static\s+metric" is visible with command "ip route"


    @rhbz1373698
    @ver+=1.8.0
    @ipv4
    @ipv4_route_set_route_with_options
    Scenario: nmcli - ipv4 - routes - set route with options
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "nmcli con modify ethie ipv4.routes '192.168.5.0/24 192.168.3.11 1024 cwnd=14 lock-mtu=true mtu=1600'"
    * Bring "up" connection "ethie"
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth1\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"


    @rhbz1373698
    @ver+=1.8.0
    @ipv4 @restart
    @ipv4_route_set_route_with_src_new_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in new syntax
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "nmcli con modify ethie ipv4.routes '192.168.122.3 src=192.168.3.10'"
    * Bring "up" connection "ethie"
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth1\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"
     And "192.168.122.3/32\s+src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show ethie"


    @rhbz1373698
    @ver+=1.8.0
    @ipv4
    @ipv4_route_set_route_with_src_old_syntax
    Scenario: nmcli - ipv4 - routes - set route with src in old syntax
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "echo '192.168.122.3 src 192.168.3.10 dev eth1' > /etc/sysconfig/network-scripts/route-ethie"
    * Execute "nmcli connection reload"
    * Bring "up" connection "ethie"
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth1\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show ethie"


    @rhbz1452648
    @ver+=1.8.0
    @ipv4
    @ipv4_route_modify_route_with_src_old_syntax_no_metric
    Scenario: nmcli - ipv4 - routes - modify route with src and no\s+metric in old syntax
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "echo '1.2.3.4 src 2.3.4.5 dev eth1' > /etc/sysconfig/network-scripts/route-ethie"
    * Execute "nmcli connection reload"
    * Execute "nmcli con modify ethie ipv4.routes '192.168.122.3 src=192.168.3.10'"
    * Bring "up" connection "ethie"
    Then "null" is not visible with command "cat /etc/sysconfig/network-scripts/route-ethie"
     And "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth1\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show ethie"


    @rhbz1373698
    @ver+=1.8.0
    @ipv4 @restart
    @ipv4_route_set_route_with_src_old_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src old syntaxt restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "echo '192.168.122.3 src 192.168.3.10 dev eth1' > /etc/sysconfig/network-scripts/route-ethie"
    * Execute "nmcli connection reload"
    * Bring "up" connection "ethie"
    * Stop NM
    * Execute "ip addr flush dev eth1"
    * Execute "rm -rf /var/run/NetworkManager"
    * Start NM
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth1\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show ethie"


    @rhbz1373698
    @ver+=1.8.0
    @ipv4 @restart
    @ipv4_route_set_route_with_src_new_syntax_restart_persistence
    Scenario: nmcli - ipv4 - routes - set route with src new syntaxt restart persistence
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.route-metric 256"
    * Execute "nmcli con modify ethie ipv4.routes '192.168.122.3 src=192.168.3.10'"
    * Stop NM
    * Execute "ip addr flush dev eth1"
    * Execute "rm -rf /var/run/NetworkManager"
    * Start NM
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
     And "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
     And "192.168.122.3 dev eth1\s+proto static\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
     And "default" is visible with command "ip r |grep eth0"
     And "2" is visible with command "ip r |grep eth0 |wc -l"
     And "192.168.122.3/32 src=192.168.3.10" is visible with command "nmcli -g ipv4.routes connection show ethie"


    @rhbz1302532
    @ipv4 @restart
    @no_metric_route_connection_restart_persistence
    Scenario: nmcli - ipv4 - routes - no\s+metric route connection restart persistence
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.3.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.3.11" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    When "eth1:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Restart NM
    Then "eth1:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds



    @rhbz1436531
    @ver+=1.10
    @eth @flush_300
    @ipv4_route_set_route_with_tables
    Scenario: nmcli - ipv4 - routes - set route with tables
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie ipv4.route-table 300"
    When "connected" is visible with command "nmcli -g state,device device |grep eth1$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show table 300"
     And "eth1" is not visible with command "ip r"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show ethie |awk -F '/' '{print $1}') dev eth1"
    When "10.20.30.0\/24 via 192.168.100.* dev eth1" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show table 300"
    * Bring "up" connection "ethie"
    When "connected" is visible with command "nmcli -g state,device device |grep eth1$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.100.* dev eth1" is not visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show table 300"
     And "eth1" is not visible with command "ip r"


    @rhbz1436531
    @ver+=1.10
    @eth @flush_300
    @ipv4_route_set_route_with_tables_reapply
    Scenario: nmcli - ipv4 - routes - set route with tables reapply
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie"
    When "connected" is visible with command "nmcli -g state,device device |grep eth1$" in "20" seconds
    # This is cripppled in kernel VVV 1535977
    # Then "default" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show"
    * Execute "ip route add table 300 10.20.30.0/24 via $(nmcli -g IP4.ADDRESS con show ethie |awk -F '/' '{print $1}') dev eth1"
    When "10.20.30.0\/24 via 192.168.100.* dev eth1" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show"
    * Execute "nmcli device reapply eth1"
    When "connected" is visible with command "nmcli -g state,device device |grep eth1$" in "20" seconds
    Then "10.20.30.0\/24 via 192.168.100.* dev eth1" is visible with command "ip r show table 300"
     And "192.168.100.0\/24 dev eth1 proto kernel scope link src 192.168.100.* metric 10[0-2]" is visible with command "ip r show"


    @rhbz1503769
    @ver+=1.10
    @ethie
    @ipv4_restore_default_route_externally
    Scenario: nmcli - ipv4 - routes - restore externally
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie"
    When "connected" is visible with command "nmcli -g state,device device |grep eth1$" in "20" seconds
     And "default" is visible with command "ip r |grep eth1"
    * Execute "ip route delete default dev eth1"
    When "default" is not visible with command "ip r |grep eth1"
    * Execute "ip route add default via 192.168.100.1 metric 103"
    Then "default" is visible with command "ip r |grep eth1"


    @rhbz1164441
    @ver-=1.10.0
    @ipv4_2
    @ipv4_route_remove_basic_route
    Scenario: nmcli - ipv4 - routes - remove basic route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.3.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.3.11 1" in editor
    * Save in editor
    * Quit editor
    * Add connection type "ethernet" named "ethie2" for device "eth2"
    * Open editor for connection "ethie2"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.1.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.2.0/24 192.168.1.11 2" in editor
    * Save in editor
    * Quit editor
    * Open editor for connection "ethie"
    * Submit "set ipv4.routes" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie2"
    * Submit "set ipv4.routes" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie2"
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 10[0-2]" is visible with command "ip route" in "5" seconds
    Then "default via 192.168.4.1 dev eth2\s+proto static\s+metric 10[0-2]" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric 2" is not visible with command "ip route"
    Then "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 10[0-1]" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 10[0-1]" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth1\s+proto static\s+metric 1" is not visible with command "ip route"


    @rhbz1164441
    @ver+=1.10.2
    @ipv4_2
    @ipv4_route_remove_basic_route
    Scenario: nmcli - ipv4 - routes - remove basic route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.3.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.3.11 1" in editor
    * Save in editor
    * Quit editor
    * Add connection type "ethernet" named "ethie2" for device "eth2"
    * Open editor for connection "ethie2"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.1.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.2.0/24 192.168.1.11 2" in editor
    * Save in editor
    * Quit editor
    * Open editor for connection "ethie"
    * Submit "set ipv4.routes" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie2"
    * Submit "set ipv4.routes" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie2"
    Then "default via 192.168.4.1 dev eth1\s+proto static\s+metric 103" is visible with command "ip route" in "5" seconds
    Then "default via 192.168.4.1 dev eth2\s+proto static\s+metric 104" is visible with command "ip route" in "5" seconds
    Then "192.168.1.0/24 dev eth2\s+proto kernel\s+scope link\s+src 192.168.1.10" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.1.11 dev eth2\s+proto static\s+metric 2" is not visible with command "ip route"
    Then "192.168.3.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
    Then "192.168.4.1 dev eth1\s+proto static\s+scope link\s+metric 103" is visible with command "ip route"
    Then "192.168.4.1 dev eth2\s+proto static\s+scope link\s+metric 104" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev eth1\s+proto static\s+metric 1" is not visible with command "ip route"


    @ipv4 @eth0
    @ipv4_route_set_device_route
    Scenario: nmcli - ipv4 - routes - set device route
    * Add connection type "ethernet" named "ethie" for device "eth10"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.routes 192.168.1.0/24 0.0.0.0, 192.168.2.0/24 192.168.122.5" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "default via 192.168.122.1 dev eth10\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.1.0/24 dev eth10\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.2.0/24 via 192.168.122.5 dev eth10\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth10\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @rhbz1439376
    @ver+=1.8.0
    @ipv4
    @ipv4_host_destination_route
    Scenario: nmcli - ipv4 - routes - host destination
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no ip4 192.168.122.123/24 ipv4.routes '10.20.30.10/24 192.168.122.2'"
    * Bring "up" connection "ethie"
    Then "^connected" is visible with command "nmcli -t -f STATE,DEVICE device |grep eth1" in "5" seconds


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


    @ipv4
    @ipv4_route_set_invalid_non_IP_route
    Scenario: nmcli - ipv4 - routes - set invalid route - non IP
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.routes 255.255.255.256" in editor
    Then Error type "failed to set 'routes' property:" while saving in editor


    @ipv4 @eth0
    @ipv4_route_set_invalid_missing_gw_route
    Scenario: nmcli - ipv4 - routes - set invalid route - missing gw
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.routes 192.168.1.0/24" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "default via 192.168.122.1 dev eth1\s+proto static\s+metric" is visible with command "ip route"
    Then "192.168.1.0/24 dev eth1\s+proto static\s+scope link\s+metric" is visible with command "ip route"
    Then "192.168.122.0/24 dev eth1\s+proto kernel\s+scope link\s+src 192.168.122.2" is visible with command "ip route"


    @ver+=1.4.0
    @ipv4 @eth0
    @ipv4_routes_not_reachable
    Scenario: nmcli - ipv4 - routes - set unreachable route
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.2/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.routes 192.168.1.0/24 192.168.3.11 1" in editor
    * Submit "set ipv6.method ignore" in editor
    * Save in editor
    * Quit editor
    * Bring up connection "ethie" ignoring error
    Then "\(disconnected\)" is visible with command "nmcli device show eth1" in "5" seconds


    @ipv4 @eth0
    @ipv4_dns_manual
    Scenario: nmcli - ipv4 - dns - method static + IP + dns
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.dns 8.8.8.8, 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8\s+nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @ipv4 @eth0
    @ipv4_dns_manual_when_method_auto
    Scenario: nmcli - ipv4 - dns - method auto + dns
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns 8.8.8.8, 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is visible with command "cat /etc/resolv.conf"


    @ipv4 @eth0
    @ipv4_dns_manual_when_ignore_auto_dns
    Scenario: nmcli - ipv4 - dns - method auto + dns + ignore automaticaly obtained
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.ignore-auto-dns yes" in editor
    * Submit "set ipv4.dns 8.8.8.8, 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @rhbz1405431
    @ver+=1.6.0
    @ipv4 @restart @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns
    Scenario: nmcli - ipv4 - preserve resolveconf if ignore_auto_dns
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "ethie"
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
    @ipv4 @restart @delete_testeth0
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var1
    Scenario: NM - ipv4 - preserve resolveconf if ignore_auto_dns with NM service up
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "ethie"
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
    @ipv4 @delete_testeth0 @restore_hostname
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var2
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "ethie"
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
    @ver+=1.8.0
    @ipv4 @delete_testeth0 @restore_hostname
    @ipv4_ignore_resolveconf_with_ignore_auto_dns_var3
    Scenario: NM - ipv4 - preserve resolveconf when hostnamectl is called and ignore_auto_dns set
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes"
    * Bring "down" connection "ethie"
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

    * Execute "ip add add 1.2.3.1/24 dev eth1"
    Then "braunberg" is visible with command "hostnamectl --static" for full "5" seconds
     And "boston.com" is visible with command "cat /etc/resolv.conf"
     And "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @rhel7_only
    @ipv4 @restore_resolvconf @restart
    @ipv4_dns_resolvconf_rhel7_default
    Scenario: nmcli - ipv4 - dns - rhel7 default
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "20" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.dns 8.8.8.8"
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf: symbolic link to `/tmp/resolv.conf" is visible with command "file /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @ipv4 @restore_resolvconf @restart
    @ipv4_dns_resolvconf_symlinked
    Scenario: nmcli - ipv4 - dns - symlink
    * Bring "down" connection "testeth0"
    * Execute "echo -e '[main]\nrc-manager=symlink' > /etc/NetworkManager/conf.d/99-resolv.conf"
    * Execute "systemctl restart NetworkManager"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "20" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.dns 8.8.8.8"
    * Bring "up" connection "ethie"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ethie" in "20" seconds
    Then "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
     And "are identical" is visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf: symbolic link to `/tmp/resolv.conf" is visible with command "file /etc/resolv.conf"


    @rhbz+=1423490
    @ver+=1.8.0
    @ipv4 @restore_resolvconf @restart
    @ipv4_dns_resolvconf_file
    Scenario: nmcli - ipv4 - dns - file
    * Bring "down" connection "testeth0"
    * Execute "echo -e '[main]\nrc-manager=file' > /etc/NetworkManager/conf.d/99-resolv.conf"
    * Execute "systemctl restart NetworkManager"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "20" seconds
    * Execute "cp /etc/resolv.conf /tmp/resolv_orig.conf"
    * Execute "mv -f /etc/resolv.conf /tmp/resolv.conf"
    * Execute "ln -s /tmp/resolv.conf /etc/resolv.conf"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 ipv4.dns 8.8.8.8"
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "20" seconds
     And "nameserver 8.8.8.8" is visible with command "cat /var/run/NetworkManager/resolv.conf"
     And "are identical" is not visible with command "diff -s /tmp/resolv.conf /tmp/resolv_orig.conf"
     And "/etc/resolv.conf: symbolic link to `/tmp/resolv.conf" is visible with command "file /etc/resolv.conf"


    @ipv4 @eth0
    @ipv4_dns_add_another_one
    Scenario: nmcli - ipv4 - dns - add dns when one already set
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.122.253/24" in editor
    * Submit "set ipv4.gateway 192.168.122.1" in editor
    * Submit "set ipv4.dns 8.8.8.8" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is not visible with command "cat /etc/resolv.conf"


    @ipv4 @eth0
    @ipv4_dns_delete_all
    Scenario: nmcli - ipv4 - dns - method auto then delete all dns
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns 8.8.8.8, 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 8.8.4.4" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 192.168.100.1" is visible with command "cat /etc/resolv.conf"


    @ipv4
    @reload_dns @eth0
    Scenario: nmcli - ipv4 - dns - reload
    * Add connection type "ethernet" named "ethie" for device "eth0"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns 8.8.8.8, 8.8.4.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    When "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds
    When "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    * Execute "echo 'INVALID_DNS' > /etc/resolv.conf"
    * Execute "sudo kill -SIGUSR1 $(pidof NetworkManager)"
    Then "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds
    Then "nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf"
    * Execute "sleep 3"
    Then Ping "boston.com"


    @rhbz1228707
    @ver+=1.2.0
    @ipv4_2 @eth0
    @dns_priority
    Scenario: nmcli - ipv4 - dns - priority
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 autoconnect no -- ipv4.method manual ipv4.addresses 192.168.1.2/24 ipv4.dns 8.8.4.4 ipv4.dns-priority 300"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth1 autoconnect no -- ipv4.method manual ipv4.addresses 192.168.2.2/24 ipv4.dns 8.8.8.8 ipv4.dns-priority 200"
    * Bring "up" connection "ethie"
    * Bring "up" connection "ethie2"
    When "nameserver 8.8.8.8\s+nameserver 8.8.4.4" is visible with command "cat /etc/resolv.conf" in "10" seconds
    * Execute "nmcli con modify ethie ipv4.dns-priority 100"
    * Execute "nmcli con modify ethie ipv6.dns-priority 300"
    * Bring "up" connection "ethie"
    * Bring "up" connection "ethie2"
    Then "nameserver 8.8.4.4\s+nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf" in "10" seconds


    @ipv4 @eth0
    @ipv4_dns-search_add
    Scenario: nmcli - ipv4 - dns-search - add dns-search
    * Add connection type "ethernet" named "ethie" for device "eth0"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns-search google.com" in editor
    * Submit "set ipv4.may-fail no" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "google.com" is visible with command "cat /etc/resolv.conf"
    Then Ping "maps"
    Then Ping "maps.google.com"


    @ipv4 @eth0
    @ipv4_dns-search_remove
    Scenario: nmcli - ipv4 - dns-search - remove dns-search
    * Add connection type "ethernet" named "ethie" for device "eth0"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns-search google.com" in editor
    * Submit "set ipv4.may-fail no" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dns-search" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then " google.com" is not visible with command "cat /etc/resolv.conf"
    Then Unable to ping "maps"
    Then Ping "maps.google.com"


    @tshark @ipv4
    @ver-=1.7.9
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-hostname RHA" in editor
    #* Submit "set ipv4.send-hostname yes" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "RHA" is visible with command "cat /tmp/tshark.log"


    @rhbz1443437
    @ver+=1.8.0
    @tshark @ipv4
    @ipv4_dhcp-hostname_set
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-hostname R.C" in editor
    #* Submit "set ipv4.send-hostname yes" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "R.C" is visible with command "cat /tmp/tshark.log"
    Then "Option: \(12\) Host Name\s+Length: 3\s+Host Name: R.C" is visible with command "cat /tmp/tshark.log" in "5" seconds


    @tshark @ipv4
    @ipv4_dhcp-hostname_remove
    Scenario: nmcli - ipv4 - dhcp-hostname - remove dhcp-hostname
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-hostname RHB" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-hostname" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
   Then "RHB" is not visible with command "cat /tmp/tshark.log"


    @rhbz1255507
    @tshark @ipv4
    @nmcli_ipv4_set_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - set dhcp-fqdn
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-fqdn foo.bar.com" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth9.conf"
     And "foo.bar.com" is visible with command "cat /tmp/tshark.log"
     And "Encoding: Binary encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Server" is visible with command "cat /tmp/tshark.log"


    @rhbz1255507
    @ver+=1.3.0
    @tshark @ipv4
    @nmcli_ipv4_override_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - override dhcp-fqdn
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "up" connection "ethie"
    * Execute "echo 'send fqdn.encoded off;' > /etc/dhcp/dhclient-eth9.conf"
    * Execute "echo 'send fqdn.server-update off;' >> /etc/dhcp/dhclient-eth9.conf"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-fqdn foo.bar.com" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "foo.bar.com" is visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth9.conf"
     And "foo.bar.com" is visible with command "cat /tmp/tshark.log"
     And "Encoding: ASCII encoding" is visible with command "cat /tmp/tshark.log"
     And "Server: Client" is visible with command "cat /tmp/tshark.log"


    @tshark @ipv4
    @nmcli_ipv4_remove_fqdn
    Scenario: nmcli - ipv4 - dhcp-fqdn - remove dhcp-fqdn
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-fqdn foo.bar.com" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-fqdn" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
     Then "foo.bar.com" is not visible with command "grep fqdn /var/lib/NetworkManager/dhclient-eth9.conf"
      And "foo.bar.com" is not visible with command "cat /tmp/tshark.log"


    @tshark @ipv4
    @ipv4_do_not_send_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - don't send
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Execute "nmcli con modify ethie ipv4.may-fail no"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-hostname RHC" in editor
    * Submit "set ipv4.dhcp-send-hostname no" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/hostname.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "RHC" is not visible with command "cat /tmp/hostname.log"


    @tshark @ipv4 @restore_hostname
    @ipv4_send_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - send real hostname
    * Execute "hostnamectl set-hostname foobar.test"
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Execute "nmcli con modify ethie ipv4.may-fail no"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then Hostname is visible in log "/tmp/tshark.log"


    @tshark @ipv4
    @ipv4_ignore_sending_real_hostname
    Scenario: nmcli - ipv4 - dhcp-send-hostname - ignore sending real hostname
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Execute "nmcli con modify ethie ipv4.may-fail no"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-send-hostname no" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 > /tmp/real.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then Hostname is not visible in log "/tmp/real.log"


    @rhbz1264410
    @ipv4 @eth0
    @ipv4_add_dns_options
    Scenario: nmcli - ipv4 - dns-options - add
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name ethie autoconnect no"
    * Execute "nmcli con modify ethie ipv4.dns-options debug ipv4.may-fail no"
    * Bring "up" connection "ethie"
    Then "options debug" is visible with command "cat /etc/resolv.conf" in "5" seconds


    @ipv4 @eth0
    @ipv4_remove_dns_options
    Scenario: nmcli - ipv4 - dns-options - remove
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name ethie autoconnect no"
    * Execute "nmcli con modify ethie ipv4.dns-options debug ipv4.may-fail no"
    * Bring "up" connection "ethie"
    * Execute "nmcli con modify ethie ipv4.dns-options ' '"
    * Bring "up" connection "ethie"
    Then "options debug" is not visible with command "cat /etc/resolv.conf" in "5" seconds


    @ipv4 @eth0
    @ipv4_dns-search_ignore_auto_routes
    Scenario: nmcli - ipv4 - dns-search - dns-search + ignore auto obtained routes
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name ethie autoconnect no"
    * Open editor for connection "ethie"
    * Submit "set ipv6.method ignore" in editor
    * Submit "set ipv6.ignore-auto-dns yes" in editor
    * Submit "set ipv4.dns-search google.com" in editor
    * Submit "set ipv4.ignore-auto-dns yes" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then " google.com" is visible with command "cat /etc/resolv.conf"
    Then "virtual" is not visible with command "cat /etc/resolv.conf"


    @ipv4
    @ipv4_method_link-local
    Scenario: nmcli - ipv4 - method - link-local
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method link-local" in editor
    * Submit "set ipv6.method ignore" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "169.254" is visible with command "ip a s eth1" in "10" seconds


    @eth9 @ipv4
    @ipv4_dhcp_client_id_set
    Scenario: nmcli - ipv4 - dhcp-client-id - set client id
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-client-id AB" in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 -x > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Finish "sleep 5; sudo pkill tshark"
    Then "AB" is visible with command "cat /tmp/tshark.log"
    #Then "walderon" is visible with command "cat /var/lib/NetworkManager/dhclient-eth9.conf"
    #VVV verify bug 999503
    Then "exceeds max \(255\) for precision" is not visible with command "grep exceeds max /var/log/messages"


    @ipv4 @tshark
    @ipv4_dhcp_client_id_remove
    Scenario: nmcli - ipv4 - dhcp-client-id - remove client id
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-client-id BC" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Bring "down" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-client-id" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Run child "sudo tshark -l -O bootp -i eth9 -x > /tmp/tshark.log"
    * Wait for at least "10" seconds
    * Bring "up" connection "ethie"
    * Execute "sleep 5; sudo pkill tshark"
    Then "BC" is not visible with command "cat /tmp/tshark.log"


    @rhbz1531173
    @ver+=1.10
    @eth9 @ipv4 @internal_DHCP @restart
    @ipv4_set_very_long_dhcp_client_id
    Scenario: nmcli - ipv4 - dhcp-client-id - set long client id
    * Add connection type "ethernet" named "ethie" for device "eth9"
    * Bring "down" connection "ethie"
    * Execute "nmcli connection modify ethie ipv4.dhcp-client-id $(printf '=%.0s' {1..999})"
    Then Bring "up" connection "ethie"


    @ipv4
    @ipv4_may-fail_yes
    Scenario: nmcli - ipv4 - may-fail - set true
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
    * Open editor for connection "ethie"
    * Submit "set ipv4.dhcp-client-id 1" in editor
    * Submit "set ipv4.may-fail yes" in editor
    * Submit "set ipv6.method manual" in editor
    * Submit "set ipv6.addresses ::1" in editor
    * Save in editor
    * Quit editor
    Then Bring "up" connection "ethie"


    @ipv4
    @ipv4_method_disabled
    Scenario: nmcli - ipv4 - method - disabled
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method disabled" in editor
    * Submit "set ipv6.method manual" in editor
    * Submit "set ipv6.addresses ::1" in editor
    * Save in editor
    * Quit editor
    Then Bring "up" connection "ethie"


    @ipv4 @eth0
    @ipv4_never-default_set
    Scenario: nmcli - ipv4 - never-default - set
    * Add connection type "ethernet" named "ethie" for device "eth10"
    * Open editor for connection "ethie"
    * Submit "set ipv4.never-default yes" in editor
    * Submit "set ipv4.may-fail no" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "default via 10." is not visible with command "ip route"


    @ipv4 @eth0
    @ipv4_never-default_remove
    Scenario: nmcli - ipv4 - never-default - remove
    * Add connection type "ethernet" named "ethie" for device "eth10"
    * Open editor for connection "ethie"
    * Submit "set ipv4.never-default yes" in editor
    * Submit "set ipv4.may-fail no" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.never-default" in editor
    * Enter in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    Then "default via 10." is visible with command "ip route"


    @rhbz1313091
    @ver+=1.2.0
    @ipv4 @restart
    @ipv4_never_default_restart_persistence
    Scenario: nmcli - ipv4 - never-default - restart persistence
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method manual" in editor
    * Submit "set ipv4.addresses 1.2.3.4/24" in editor
    * Submit "set ipv4.gateway 1.2.3.1" in editor
    * Submit "set ipv4.never-default yes" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethie"
    * Restart NM
    Then "eth1:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @mtu @kill_dnsmasq
    @set_mtu_from_DHCP
    Scenario: NM - ipv4 - set dhcp received MTU
    * Finish "ip link add test1 type veth peer name test1p"
    * Finish "ip link add test2 type veth peer name test2p"
    * Finish "brctl addbr vethbr"
    * Finish "ip link set dev vethbr up"
    * Finish "brctl addif vethbr test1p test2p"
    * Finish "ip link set dev test1 up"
    * Finish "ip link set dev test1p up"
    * Finish "ip link set dev test2 up"
    * Finish "ip link set dev test2p up"
    * Finish "nmcli connection add type ethernet con-name tc1 ifname test1 ip4 192.168.99.1/24"
    * Finish "nmcli connection add type ethernet con-name tc2 ifname test2"
    * Bring "up" connection "tc1"
    When "test1:connected:tc1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "/usr/sbin/dnsmasq --pid-file=/tmp/dnsmasq.pid --conf-file --no-hosts --keep-in-foreground --bind-interfaces --except-interface=lo --clear-on-reload --strict-order --listen-address=192.168.99.1 --dhcp-range=192.168.99.10,192.168.99.254,60m --dhcp-option=option:router,192.168.99.1 --dhcp-lease-max=50 --dhcp-option-force=26,1800 &"
    * Bring "up" connection "tc2"
    Then "mtu 1800" is visible with command "ip a s test2"


    @eth @teardown_testveth @long
    @renewal_gw_after_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "nmcli connection modify ethie ipv4.may-fail no"
    * Bring "up" connection "ethie"
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    When "default" is not visible with command "ip r |grep testX" in "130" seconds
    When "ethie" is not visible with command "nmcli connection s -a" in "800" seconds
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "400" seconds
    Then "default via 192.168.99.1 dev testX" is visible with command "ip r"


    @rhbz1503587
    @ver+=1.10
    @eth @teardown_testveth @long
    @renewal_gw_after_long_dhcp_outage
    Scenario: NM - ipv4 - renewal gw after DHCP outage
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    When "default" is not visible with command "ip r |grep testX" in "130" seconds
    * Execute "sleep 500"
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "130" seconds
    Then "default via 192.168.99.1 dev testX" is visible with command "ip r"


    @rhbz1262922
    @ver+=1.2.0
    @eth @teardown_testveth
    @dhcp-timeout
    Scenario: NM - ipv4 - add dhcp-timeout
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "nmcli connection modify ethie ipv4.dhcp-timeout 60"
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "sleep 50; ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)" without waiting for process to finish
    * Bring "up" connection "ethie"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "10" seconds
    Then "default via 192.168.99.1 dev testX" is visible with command "ip r"


    @rhbz1350830
    @ver+=1.10.0
    @eth @teardown_testveth
    @dhcp-timeout_infinity
    Scenario: NM - ipv4 - add dhcp-timeout infinity
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "nmcli connection modify ethie ipv4.dhcp-timeout infinity"
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "sleep 70; ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)" without waiting for process to finish
    * Bring "up" connection "ethie"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "10" seconds
     And "default via 192.168.99.1 dev testX" is visible with command "ip r"
     And "IPV4_DHCP_TIMEOUT=2147483647" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethie"


    @rhbz1350830
    @ver+=1.10.0
    @eth @remove_custom_cfg
    @dhcp-timeout_default_in_cfg
    Scenario: nmcli - ipv4 - dhcp_timout infinity in cfg file
    * Execute "echo -e '[connection-eth-dhcp-timeout]\nmatch-device=type:ethernet\nipv4.dhcp-timeout=2147483647' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "systemctl restart NetworkManager"
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "sleep 50; ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)" without waiting for process to finish
    * Restart NM
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "60" seconds
     And "default via 192.168.99.1 dev testX" is visible with command "ip r"
     And "IPV4_DHCP_TIMEOUT=2147483647" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethie"


    @rhbz1246496
    @eth @teardown_testveth @long
    @renewal_gw_after_dhcp_outage_for_assumed_var0
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for on-disk assumed
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    When "default" is visible with command "ip r |grep testX" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX" in "30" seconds
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Restart NM
    When "ethie" is visible with command "nmcli con sh -a" in "30" seconds
    When "default" is not visible with command "ip r |grep testX" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX" in "10" seconds
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show ethie" in "60" seconds
    Then "default" is visible with command "ip r| grep testX"
    When "inet 192.168.99" is visible with command "ip a s testX"


    @rhbz1265239
    @ver-=1.10.0
    @teardown_testveth @long
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    When "default" is visible with command "ip r |grep testX" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX" in "30" seconds
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "systemctl stop NetworkManager"
    * Execute "sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ethie"
    * Execute "systemctl start NetworkManager"
    When "default" is not visible with command "ip r |grep testX" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX" in "10" seconds
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "routers = 192.168.99.1" is visible with command "nmcli con show testX" in "400" seconds
    Then "default" is visible with command "ip r| grep testX" in "150" seconds
    When "inet 192.168.99" is visible with command "ip a s testX" in "10" seconds


    @rhbz1518091
    @ver+=1.10.1
    @teardown_testveth @long
    @renewal_gw_after_dhcp_outage_for_assumed_var1
    Scenario: NM - ipv4 - assumed address renewal after DHCP outage for in-memory assumed
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    When "default" is visible with command "ip r |grep testX" in "30" seconds
    When "inet 192" is visible with command "ip a s |grep testX" in "30" seconds
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "systemctl stop NetworkManager"
    * Execute "sudo rm -rf /etc/sysconfig/network-scripts/ifcfg-ethie"
    * Execute "systemctl start NetworkManager"
    When "default" is not visible with command "ip r |grep testX" in "130" seconds
    When "inet 192.168.99" is not visible with command "ip a s testX" in "10" seconds
    * Execute "ip netns exec testX_ns kill -SIGCONT $(cat /tmp/testX_ns.pid)"
    Then "default" is not visible with command "ip r| grep testX" for full "150" seconds
    Then "inet 192.168.99" is not visible with command "ip a s testX" in "10" seconds


    @rhbz1205405
    @eth @teardown_testveth @long
    @manual_routes_preserved_when_never-default_yes
    Scenario: NM - ipv4 - don't touch manual route with never-default
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "nmcli connection modify ethie ipv4.may-fail no"
    * Execute "nmcli connection modify ethie ipv4.never-default yes"
    * Bring "up" connection "ethie"
    When "default" is not visible with command "ip r |grep testX"
    * Execute "ip route add default via 192.168.99.1 dev testX metric 666"
    * Execute "sleep 70"
    Then "default via 192.168.99.1 dev testX\s+metric 666" is visible with command "ip r"


    @rhbz1205405
    @teardown_testveth @eth @long
    @manual_routes_removed_when_never-default_no
    Scenario: NM - ipv4 - rewrite manual route with dhcp renewal
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Execute "nmcli connection modify ethie ipv4.may-fail no"
    * Execute "nmcli connection modify ethie ipv4.never-default no"
    * Bring "up" connection "ethie"
    * Execute "ip route add default via 192.168.99.1 dev testX\s+metric 666"
    Then "default via 192.168.99.1 dev testX\s+metric 666" is not visible with command "ip r" in "70" seconds


    @rhbz1284261
    @no_config_server @eth @teardown_testveth
    @ipv4_remove_default_route_for_no_carrier
    Scenario: NM - ipv4 - remove default route for no carrier
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    When "default" is visible with command "ip r | grep testX" in "10" seconds
    * Execute "ip netns exec testX_ns ip link set dev testXp down"
    Then "default" is not visible with command "ip r |grep testX" in "10" seconds
     And "ethie" is not visible with command "nmcli con show -a"


     @rhbz1259063
     @ver+=1.4.0
     @eth @teardown_testveth
     @ipv4_dad
     Scenario: NM - ipv4 - DAD
     * Prepare simulated test "testX" device
     * Add connection type "ethernet" named "ethie" for device "testX"
     * Execute "nmcli connection modify ethie ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24"
     * Bring "up" connection "ethie"
     When "testX:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     * Execute "nmcli connection modify ethie ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.1/24 ipv4.dad-timeout 5000"
     * Bring up connection "ethie" ignoring error
     When "testX:connected:ethie" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     * Execute "nmcli connection modify ethie ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.99.2/24 ipv4.dad-timeout 5000"
     * Bring "up" connection "ethie"
     Then "testX:connected:ethie" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @eth
    @custom_shared_range_preserves_restart
    Scenario: nmcli - ipv4 - shared custom range preserves restart
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 autoconnect no"
    * Execute "nmcli connection modify ethie ipv4.addresses 192.168.100.1/24 ipv4.method shared connection.autoconnect yes"
    * Restart NM
    Then "ipv4.addresses:\s+192.168.100.1/24" is visible with command "nmcli con show ethie"


    @ver+=1.4
    @two_bridged_veths
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
    @ver+=1.7
    @two_bridged_veths @kill_dnsmasq
    @ipv4_method_shared_with_already_running_dnsmasq
    Scenario: nmcli - ipv4 - method shared when dnsmasq does run
    * Note the output of "pidof NetworkManager" as value "1"
    * Prepare veth pairs "test1,test2" bridged over "vethbr"
    * Execute "dnsmasq --interface test1 --pid-file=/tmp/dnsmasq.pid &"
    * Add a new connection of type "ethernet" and options "con-name tc1 autoconnect no ifname test1 ipv4.method shared ipv6.method ignore"
    * Add a new connection of type "ethernet" and options "con-name tc2 autoconnect no ifname test2 ipv4.may-fail yes ipv6.method manual ipv6.addresses 1::1/128"
    Then Bring "up" connection "tc1"
     And Bring "up" connection "tc2"
     And Note the output of "pidof NetworkManager" as value "2"
     And Check noted values "1" and "2" are the same


    @rhbz1172780
    @ipv4 @netaddr @long
    @ipv4_do_not_remove_second_ip_route
    Scenario: nmcli - ipv4 - do not remove secondary ip subnet route
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth1 autoconnect no"
    * Bring up connection "ethie"
    * "192.168" is visible with command "ip a s eth1" in "20" seconds
    * "dev eth1\s+proto kernel\s+scope link" is visible with command "ip route"
    * Add a secondary address to device "eth1" within the same subnet
    Then "dev eth1\s+proto kernel\s+scope link" is visible with command "ip route" for full "80" seconds


    @ipv4
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


    @rhbz1394500
    @ver+=1.4.0
    @ipv4
    @ipv4_honor_ip_order_1
    Scenario: NM - ipv4 - honor IP order from configuration
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 autoconnect no"
    * Execute "nmcli con modify ethie ipv4.method manual ipv4.addresses 192.168.1.5/24,192.168.1.4/24,192.168.1.3/24"
    * Bring "up" connection "ethie"
    Then "inet 192.168.1.5/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2"
    Then "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"
    Then "inet 192.168.1.3/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"


    @rhbz1394500
    @ver+=1.4.0
    @ipv4
    @ipv4_honor_ip_order_2
    Scenario: NM - ipv4 - honor IP order from configuration upon reapply
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 autoconnect no"
    * Execute "nmcli con modify ethie ipv4.method manual ipv4.addresses 192.168.1.3/24,192.168.1.4/24,192.168.1.5/24"
    * Bring "up" connection "ethie"
    When "inet 192.168.1.3/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2" in "5" seconds
    When "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2" in "5" seconds
    When "inet 192.168.1.5/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2" in "5" seconds
    * Execute "nmcli con modify ethie ipv4.addresses 192.168.1.5/24,192.168.1.4/24,192.168.1.3/24"
    * Execute "nmcli dev reapply eth2"
    Then "inet 192.168.1.5/24 brd 192.168.1.255 scope global( noprefixroute)? eth2" is visible with command "ip a show eth2"
    Then "inet 192.168.1.4/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"
    Then "inet 192.168.1.3/24 brd 192.168.1.255 scope global secondary" is visible with command "ip a show eth2"


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 100" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 101" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1
    @ipv4_2 @restore_rp_filters
    @not_in_rhel
    @ipv4_rp_filter_set_loose
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 101" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 102" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893 @rhbz1492472
    @ver+=1.9.1
    @ipv4_2 @restore_rp_filters
    @rhel7_only
    @ipv4_rp_filter_set_loose_rhel
    Scenario: NM - ipv4 - set loose RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 101" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 102" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_do_not_touch
    Scenario: NM - ipv4 - don't touch disabled RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 0 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 100" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 101" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_do_not_touch
    Scenario: NM - ipv4 - don't touch disabled RP filter
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 0 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 101" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 102" is visible with command "ip r" in "5" seconds
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "0" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"


    @rhbz1394344
    @ver+=1.8.0 @ver-=1.9.0
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 100" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 101" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "ethie"
    * Delete connection "ethie2"
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter" in "5" seconds


    @rhbz1394344 @rhbz1505893
    @ver+=1.9.1
    @not_in_rhel
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_reset
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 101" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 102" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "2" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "ethie"
    * Delete connection "ethie2"
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter" in "5" seconds


    @rhbz1394344 @rhbz1505893 @rhbz1492472
    @ver+=1.9.1
    @rhel7_only
    @ipv4_2 @restore_rp_filters
    @ipv4_rp_filter_reset_rhel
    Scenario: NM - ipv4 - reset RP filter back
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth2/rp_filter"
    * Execute "echo 1 > /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Add a new connection of type "ethernet" and options "con-name ethie ifname eth2 ip4 192.168.11.1/24"
    * Add a new connection of type "ethernet" and options "con-name ethie2 ifname eth3 ip4 192.168.11.2/24"
    When "192.168.11.0/24 dev eth2.*src 192.168.11.1\s+metric 101" is visible with command "ip r" in "5" seconds
     And "192.168.11.0/24 dev eth3.*src 192.168.11.2\s+metric 102" is visible with command "ip r" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter"
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter"
    * Delete connection "ethie"
    * Delete connection "ethie2"
    Then "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth2/rp_filter" in "5" seconds
     And "1" is visible with command "cat /proc/sys/net/ipv4/conf/eth3/rp_filter" in "5" seconds


    @rhbz1448987
    @ver+=1.8.0
    @ipv4 @teardown_testveth @kill_dhcrelay
    @ipv4_dhcp_do_not_add_route_to_server
    Scenario: NM - ipv4 - don't add route to server
    * Prepare simulated test "testX" device with DHCPv4 server on different network
    * Add a new connection of type "ethernet" and options "con-name ethie ifname testX autoconnect no"
    * Bring "up" connection "ethie"
    Then "10.0.0.0/24 via 172.16.0.1 dev testX" is visible with command "ip route"
    Then "10.0.0.1 via.*dev testX" is not visible with command "ip route"
    Then "10.0.0.1 dev testX" is not visible with command "ip route"


    @rhbz1449873
    @ver+=1.8.0
    @BBB
    @ipv4_keep_external_addresses
    Scenario: NM - ipv4 - keep external addresses
    * Execute "ip link add BBB type dummy"
    * Execute "ip link set dev BBB up"
    * Execute "for i in $(seq 20); do for j in $(seq 200); do ip addr add 10.3.$i.$j/16 dev BBB; done; done"
    Then "4000" is visible with command "ip addr show dev BBB | grep 'inet 10.3.' -c"
    * Execute "sleep 6"
    Then "4000" is visible with command "ip addr show dev BBB | grep 'inet 10.3.' -c"


    @rhbz1428334
    @ver+=1.10.0
    @ipv4
    @ipv4_route_onsite
    Scenario: nmcli - ipv4 - routes - add device route if onsite specified
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie ipv4.method manual ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.3.254"
    * Execute "echo '10.200.200.2/31 via 172.16.0.254' > /etc/sysconfig/network-scripts/route-ethie"
    * Execute "nmcli connection reload"
    * Bring up connection "ethie" ignoring error
    When "(connected)" is not visible with command "nmcli device show eth1" in "15" seconds
    * Execute "nmcli connection modify ethie ipv4.routes '10.200.200.2/31 172.16.0.254 111 onlink=true'"
    * Bring "up" connection "ethie"
    Then "default via 192.168.3.254 dev eth1 proto static metric 101" is visible with command "ip r"
     And "10.200.200.2/31 via 172.16.0.254 dev eth1 proto static metric 111 onlink" is visible with command "ip r"
     And "192.168.3.0/24 dev eth1 proto kernel scope link src 192.168.3.10 metric 101" is visible with command "ip r"


    @rhbz1482772
    @ver+=1.10
    @ipv4
    @ipv4_multiple_ip4
    Scenario: nmcli - ipv4 - method - static using multiple "ip4" options
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie ip4 192.168.124.1/24 ip4 192.168.125.1/24"
    * Bring "up" connection "ethie"
    Then "192.168.124.1/24" is visible with command "ip a s eth1"
    Then "192.168.125.1/24" is visible with command "ip a s eth1"
