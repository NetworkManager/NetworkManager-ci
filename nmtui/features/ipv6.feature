Feature: IPv6 TUI tests

  Background:
  * Prepare virtual terminal environment


    @ipv6
    @nmtui_ipv6_addresses_static_no_address
    Scenario: nmtui - ipv6 - addresses - static IPv6 without address
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then ".*Unable to add new connection.*ipv6.addresses: this property cannot.*be empty for 'method=manual'.*" is visible on screen


    @ipv6
    @nmtui_ipv6_addresses_static_no_mask
    Scenario: nmtui - ipv6 - addresses - static IPv6 configuration without netmask
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4"
    * Confirm the connection settings
    Then "eth1\s+ethernet\s+connected\s+ethernet" is visible with command "nmcli device" in "10" seconds
    Then "inet6 2607:f0d0:1002:51::4/128" is visible with command "ip -6 a s eth1"


    @ipv6
    @nmtui_ipv6_addresses_static_with_mask
    Scenario: nmtui - ipv6 - addresses - static IPv6 configuration with netmask
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/63"
    * In this property also add "1050:0:0:0:5:600:300c:326b/121"
    * Confirm the connection settings
    Then "eth1\s+ethernet\s+connected\s+ethernet" is visible with command "nmcli device" in "10" seconds
    Then "2607:f0d0:1002:51::4/63" is visible with command "ip -6 a s eth1"
    Then "1050::5:600:300c:326b/121" is visible with command "ip -6 a s eth1"
    Then "dynamic" is not visible with command "ip -6 a s eth1"


    @ipv6
    @nmtui_ipv6_addresses_auto_with_manual
    Scenario: nmcli - ipv6 - addresses - auto with manual address present
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth10"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "dead:beef::1/24"
    * Confirm the connection settings
    Then "dynamic" is visible with command "ip -6 a s eth10" in "30" seconds
    Then "inet6 dead:beef" is visible with command "ip -6 a s eth10"


    @ipv6
    @nmtui_ipv6_addresses_IP_slash_invalid_netmask
    Scenario: nmtui - ipv6 - addresses - IP slash invalid netmask
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/321"
    * Cannot confirm the connection settings


    @ipv6
    @nmtui_ipv6_addresses_IP_slash_netmask_and_gateway_manual
    Scenario: nmtui - ipv6 - addresses - IP slash netmask and gateway
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/64"
    * Set "Gateway" field to "2607:f0d0:1002:51::1"
    * Confirm the connection settings
    Then "2607:f0d0:1002:51::4/64" is visible with command "ip a s eth1"
    Then "IPV6_DEFAULTGW=2607:f0d0:1002:51::1" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet"
    Then "dynamic" is not visible with command "ip -6 a s eth1"


    @ipv6
    @nmtui_ipv6_addresses_several_IPs_slash_netmask_and_gateway_manual
    Scenario: nmtui - ipv6 - addresses - several IPs slash netmask and route - manual
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "fc01::1:5/68"
    * In this property also add "fc01::1:6/112"
    * In this property also add "fc01::1:21/96"
    * Set "Gateway" field to "fc01::1:1"
    * Confirm the connection settings
    * Wait for at least "3" seconds
    Then "IPV6_DEFAULTGW=fc01::1:1" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet"
    Then "fc01::1:5/68" is visible with command "ip -6 a s eth1"
    Then "fc01::1:6/112" is visible with command "ip -6 a s eth1"
    Then "fc01::1:21/96" is visible with command "ip -6 a s eth1"
    Then "fc01::1:0/112 dev eth1" is visible with command "ip -6 route"
    Then "fc01::/96 dev eth1" is visible with command "ip -6 route"
    Then "fc01::/68 dev eth1" is visible with command "ip -6 route"
    Then "dynamic" is not visible with command "ip -6 a s eth1"


    @ipv6
    @nmtui_ipv6_addresses_several_IPs_slash_netmask_and_gateway_auto
    Scenario: nmtui - ipv6 - addresses - several IPs slash netmask and route - auto
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth10"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "fc01::1:5/68"
    * In this property also add "fc01::1:6/112"
    * In this property also add "fc01::1:21/96"
    * Set "Gateway" field to "fc01::1:1"
    * Confirm the connection settings
    Then "IPV6_DEFAULTGW=fc01::1:1" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet"
    Then "dynamic" is visible with command "ip -6 a s eth10" in "30" seconds
    Then "fc01::1:5/68" is visible with command "ip -6 a s eth10"
    Then "fc01::1:6/112" is visible with command "ip -6 a s eth10"
    Then "fc01::1:21/96" is visible with command "ip -6 a s eth10"


    @ipv6
    @nmtui_ipv6_addresses_delete_ip_and_back_to_auto
    Scenario: nmtui - ipv6 - addresses - delete IP and set method back to auto
    * Prepare new connection of type "Ethernet" named "ethernet"
    * Set "Device" field to "eth10"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "fc01::1:5/68"
    * Set "Gateway" field to "fc01::1:1"
    * Confirm the connection settings
    * "dynamic" is not visible with command "ip -6 a s eth10"
    * Select connection "ethernet" in the list
    * Choose to "<Edit...>" a connection
    * Set "IPv6 CONFIGURATION" category to "Automatic"
    * Come in "IPv6 CONFIGURATION" category
    * Remove all "Addresses" property items
    * Confirm the connection settings
    * Bring up connection "ethernet"
    Then "fc01::1:5/68" is not visible with command "ip a s eth10"
    Then "dynamic" is visible with command "ip -6 a s eth10" in "10" seconds


    @ipv6
    @nmtui_ipv6_routes_set_basic_route
    Scenario: nmtui - ipv6 - routes - set basic route
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2000::2/126"
    * Add ip route "1010::1/128 2000::1 1"
    * Confirm the connection settings
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet2"
    * Set "Device" field to "eth2"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::1/126"
    * Add ip route "3030::1/128 2001::2 1"
    * Confirm the connection settings
    Then "1010::1 via 2000::1 dev eth1  proto static  metric 1" is visible with command "ip -6 route"
    Then "2000::/126 dev eth1  proto kernel  metric 256" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2  proto kernel  metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2  proto static  metric 1" is visible with command "ip -6 route"


    @ipv6
    @nmtui_ipv6_routes_remove_basic_route
    Scenario: nmtui - ipv6 - routes - remove basic route
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2000::2/126"
    * Add ip route "1010::1/128 2000::1 1"
    * Confirm the connection settings
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet2"
    * Set "Device" field to "eth2"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::1/126"
    * Add ip route "3030::1/128 2001::2 1"
    * Confirm the connection settings
    * Select connection "ethernet1" in the list
    * Choose to "<Edit...>" a connection
    * Come in "IPv6 CONFIGURATION" category
    * Remove all routes
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Edit a connection" from main screen
    * Select connection "ethernet2" in the list
    * Choose to "<Edit...>" a connection
    * Come in "IPv6 CONFIGURATION" category
    * Remove all routes
    * Confirm the connection settings
    * Bring up connection "ethernet1"
    * Bring up connection "ethernet2"
    Then "2000::2/126" is visible with command "ip a s eth1"
    Then "2001::1/126" is visible with command "ip a s eth2"
    Then "1010::1 via 2000::1 dev eth1  proto static  metric 1" is not visible with command "ip -6 route"
    Then "2000::/126 dev eth1  proto kernel  metric 256" is visible with command "ip -6 route"
    Then "2001::/126 dev eth2  proto kernel  metric 256" is visible with command "ip -6 route"
    Then "3030::1 via 2001::2 dev eth2  proto static  metric 1" is not visible with command "ip -6 route"


    @ipv6
    @nmtui_ipv6_routes_set_device_route
    Scenario: nmtui - ipv6 - routes - set device route
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::1/126"
    * Set "Gateway" field to "4000::1"
    * Add ip route "1010::1/128 :: 3"
    * Add ip route "3030::1/128 2001::2 2"
    * Confirm the connection settings
    Then "3030::1 via 2001::2 dev eth1  proto static  metric 2" is visible with command "ip -6 route"
    Then "2001::/126 dev eth1  proto kernel  metric 256" is visible with command "ip -6 route"
    Then "1010::1 dev eth1  proto static  metric 3" is visible with command "ip -6 route"


    @ipv6
    @eth0
    @nmtui_ipv6_routes_several_default_routes_metrics
    Scenario: nmtui - ipv6 - addresses - several default gateways and metrics
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "fc01::1:5/68"
    * Set "Gateway" field to "fc01::1:1"
    * Confirm the connection settings
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet2"
    * Set "Device" field to "eth2"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "fc05::1:5/68"
    * Set "Gateway" field to "fc05::1:1"
    * Confirm the connection settings
    Then "inet6 fc01::1:5/68" is visible with command "ip a s eth1" in "10" seconds
    Then "inet6 fc05::1:5/68" is visible with command "ip a s eth2" in "10" seconds
    Then "default via fc01::1:1 dev eth1  proto static  metric 100" is visible with command "ip -6 route" in "10" seconds
    Then "default via fc05::1:1 dev eth2  proto static  metric 101" is visible with command "ip -6 route" in "10" seconds
    Then "fc01::/68 dev eth1  proto kernel" is visible with command "ip -6 route" in "10" seconds
    Then "fc05::/68 dev eth2  proto kernel" is visible with command "ip -6 route" in "10" seconds


    @ipv6
    @nmtui_ipv6_routes_set_invalid_route_destination
    Scenario: nmtui - ipv6 - routes - set invalid route - destination
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Come in "IPv6 CONFIGURATION" category
    Then Cannot add ip route "1010::fffff/128"
    * Press "ENTER" key
    Then Cannot add ip route "dead::beef/129"
    * Press "ENTER" key
    Then Cannot add ip route "192.168.1.142/32"
    * Press "ENTER" key
    Then Cannot add ip route ":::/32"
    * Press "ENTER" key
    Then Cannot add ip route "::::"
    * Press "ENTER" key
    Then Cannot add ip route "string"


    @ipv6
    @nmtui_ipv6_routes_set_invalid_route_hop
    Scenario: nmtui - ipv6 - routes - set invalid route - hop
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Come in "IPv6 CONFIGURATION" category
    Then Cannot add ip route "1010::1/128 1010::fffff/128"
    * Press "ENTER" key
    Then Cannot add ip route "1010::1/128 dead::beef/129"
    * Press "ENTER" key
    Then Cannot add ip route "1010::1/128 192.168.1.142/32"
    * Press "ENTER" key
    Then Cannot add ip route "1010::1/128 :::/32"
    * Press "ENTER" key
    Then Cannot add ip route "1010::1/128 ::::"
    * Press "ENTER" key


    @ipv6
    @nmtui_ipv6_dns_method_static_+_IP_+_dns
    Scenario: nmtui - ipv6 - dns - method static + IP + dns
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "2001::1"
    * In "DNS servers" property add "4000::1"
    * In this property also add "5000::1"
    * Confirm the connection settings
    Then "nameserver 4000::1.+nameserver 5000::1" is visible with command "cat /etc/resolv.conf"


    @ipv6
    @nmtui_ipv6_dns_method_auto_+_dns
    Scenario: nmtui - ipv6 - dns - method auto + dns
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth10"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "4000::1"
    * In this property also add "5000::1"
    * Confirm the connection settings
    Then "nameserver 4000::1.+nameserver 5000::1" is visible with command "cat /etc/resolv.conf"


    @ipv6
    @nmtui_ipv6_dns_add_dns_when_one_already_set
    Scenario: nmtui - ipv6 - dns - add dns when one already set
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "2001::1"
    * In "DNS servers" property add "4000::1"
    * Confirm the connection settings
    * Select connection "ethernet1" in the list
    * Choose to "<Edit...>" a connection
    * Come in "IPv6 CONFIGURATION" category
    * Set "DNS servers" field to "4000::1"
    * In this property also add "5000::1"
    * Confirm the connection settings
    * Bring up connection "ethernet1"
    Then "nameserver 4000::1.+nameserver 5000::1" is visible with command "cat /etc/resolv.conf" in "10" seconds


    @ipv6
    @nmtui_ipv6_dns_method_auto_then_delete_all_dns
    Scenario: nmtui - ipv6 - dns - method auto then delete all dns
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "4000::1"
    * In this property also add "5000::1"
    * Confirm the connection settings
    * "nameserver 4000::1.+nameserver 5000::1" is visible with command "cat /etc/resolv.conf" in "10" seconds
    * Select connection "ethernet1" in the list
    * Choose to "<Edit...>" a connection
    * Come in "IPv6 CONFIGURATION" category
    * Remove all "DNS servers" property items
    * Confirm the connection settings
    * Bring up connection "ethernet1"
    Then "nameserver 4000::1" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 5000::1" is not visible with command "cat /etc/resolv.conf"


    @ipv6
    @nmtui_ipv6_dns_search_add_dns_search
    Scenario: nmtui - ipv6 - dns-search - add dns-search
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Come in "IPv6 CONFIGURATION" category
    * In "Search domains" property add "heaven.com"
    * Confirm the connection settings
    Then " heaven.com" is visible with command "cat /etc/resolv.conf" in "10" seconds


    @ipv6
    @nmtui_ipv6_dns_search_remove_dns_search
    Scenario: nmtui - ipv6 - dns-search - remove dns-search
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Come in "IPv6 CONFIGURATION" category
    * In "Search domains" property add "heaven.com"
    * Confirm the connection settings
    * " heaven.com" is visible with command "cat /etc/resolv.conf" in "10" seconds
    * Select connection "ethernet1" in the list
    * Choose to "<Edit...>" a connection
    * Come in "IPv6 CONFIGURATION" category
    * Remove all "Search domains" property items
    * Confirm the connection settings
    * Bring up connection "ethernet1"
    Then " heaven.com" is not visible with command "cat /etc/resolv.conf"


    @ipv6
    @nmtui_ipv6_method_link_local
    Scenario: nmtui - ipv6 - method - link-local
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv6 CONFIGURATION" category to "Link-Local"
    * Confirm the connection settings
    Then "inet6 fe80::" is visible with command "ip -6 a s eth1" in "10" seconds
    Then "scope global" is not visible with command "ip -6 a s eth1"


    @bz1108839
    @ipv6
    @nmtui_ipv6_may_connection_required
    Scenario: nmtui - ipv6 -  connection required
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * Ensure "Require IPv6 addressing for this connection" is checked
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "IPV6_FAILURE_FATAL=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet1"
    Then "ipv6.may-fail:\s+no" is visible with command "nmcli con show ethernet1"


    @bz1108839
    @ipv6
    @nmtui_ipv6_may_connection_not_required
    Scenario: nmtui - ipv6 -  connection not required
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * Ensure "Require IPv6 addressing for this connection" is not checked
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "IPV6_FAILURE_FATAL=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet1"
    Then "ipv6.may-fail:\s+yes" is visible with command "nmcli con show ethernet1"


    @ipv6
    @nmtui_ipv6_method_ignore
    Scenario: nmtui - ipv6 - method - ignore
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Set "Device" field to "eth1"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Set "IPv6 CONFIGURATION" category to "Ignore"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * Bring up connection "ethernet1"
    Then "IPV6INIT=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet1"
    Then "inet6 ((?!fe80).)" is not visible with command "ip -6 a s eth1"


    @ipv6
    @nmtui_ipv6_never_default_unset
    Scenario: nmtui - ipv6 - never-default - unset
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * Ensure "Never use this network for default route" is not checked
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "IPV6_DEFROUTE=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet1"
    Then "ipv6.never-default:\s+no" is visible with command "nmcli con show ethernet1"


    @ipv6
    @nmtui_ipv6_never_default_set
    Scenario: nmtui - ipv6 - never-default - set
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * Ensure "Never use this network for default route" is checked
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "IPV6_DEFROUTE=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet1"
    Then "ipv6.never-default:\s+yes" is visible with command "nmcli con show ethernet1"


    @ipv6
    @nmtui_ipv6_invalid_address
    Scenario: nmtui - ipv6 - invalid address
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "1010::fffff/128"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "dead::beef/129"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "192.168.1.142/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add ":::/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "::::"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "string"
    Then Cannot confirm the connection settings


    @ipv6
    @nmtui_ipv6_invalid_gateway
    Scenario: nmtui - ipv6 - invalid gateway
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "1010::fffff/128"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "dead::beef/129"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "192.168.1.142/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to ":::/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001::2/126"
    * Set "Gateway" field to "::::"
    Then Cannot confirm the connection settings

    @ipv6
    @nmtui_ipv6_invalid_dns
    Scenario: nmtui - ipv6 - invalid dns
    * Prepare new connection of type "Ethernet" named "ethernet1"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "1010::fffff/128"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "dead::beef/129"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "192.168.1.142/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add ":::/32"
    * Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "ethernet"
    * Come in "IPv6 CONFIGURATION" category
    * In "DNS servers" property add "::::"
    Then Cannot confirm the connection settings


    @bz1131434
    @ipv6
    @nmtui_ipv6_addresses_can_add_after_removing_invalid
    Scenario: nmtui - ipv6 - addresses - add address after removing invalid one
    Given Prepare new connection of type "Ethernet" named "ethernet"
    Given Set "Device" field to "eth1"
    Given Set "IPv6 CONFIGURATION" category to "Manual"
    Given Come in "IPv6 CONFIGURATION" category
    Given In "Addresses" property add "99999999999"
    When Remove all "Addresses" property items
    Then In "Addresses" property add "dead::beef"
    Then Confirm the connection settings
    Then "inet6 dead::beef" is visible with command "ip -6 a s eth1" in "10" seconds
