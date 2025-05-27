Feature: nmcli - dns

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    # PLEASE DO USE ETH2 AND ETH3 DEVICES ONLY

##########################################
# SYSTEMD-RESOLVED TESTS
##########################################

    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @dns_systemd_resolved @rhelver+=8
    @dns_resolved_two_default
    Scenario: NM - dns - two connections with default route

    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has "default" DNS default-route
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has "default" DNS default-route
    Then device "eth3" has DNS domain "con_dns2.domain" for "domain-search"

    Then "nameserver 127.0.0.53" is visible with command "cat /etc/resolv\.conf" in "5" seconds


    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @dns_systemd_resolved @rhelver+=8
    @dns_resolved_one_default
    Scenario: NM - dns - two connections, one with default route

    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has "default" DNS default-route
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # eth3 doesn't have a default route and so doesn't get the "." domain
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has "no" DNS default-route
    Then device "eth3" has DNS domain "con_dns2.domain" for "domain-search"


    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @dns_systemd_resolved @rhelver+=8
    @dns_resolved_two_default_with_priority
    Scenario: NM - dns - two connections with default route, one has higher priority

    # Create connection on eth2 with default route and higher priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has "default" DNS default-route
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # eth3 doesn't have the "." domain because eth2 has higher priority
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has "no" DNS default-route
    Then device "eth3" has DNS domain "con_dns2.domain" for "domain-search"


    @rhbz1512966
    @ver+=1.11.3
    @dns_systemd_resolved @rhelver+=8
    @dns_resolved_two_default_with_negative_priority
    Scenario: NM - dns - two connections with default route, one has negative priority

    # Create connection on eth2 with default route and negative priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority -100"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "domain-routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # eth3 configuration is overridden by eth2 with negative priority
    Then device "eth3" does not have DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "."
    Then device "eth3" does not have DNS domain "con_dns2.domain"


    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @rhelver+=8 @fedoraver+=31
    @dns_systemd_resolved @eth0
    @dns_resolved_no_default
    Scenario: NM - dns - two connections without default route

    # Create connection on eth2 without default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Since there is no default route eth2 gets the "." domain
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has "default" DNS default-route
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # Since there is no default route eth3 gets the "." domain
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has "default" DNS default-route
    Then device "eth3" has DNS domain "con_dns2.domain" for "domain-search"


    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @openvpn @openvpn4 @dns_systemd_resolved @rhelver+=8
    @dns_resolved_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN

    # Create ethernet connection
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" has "default" DNS default-route
    Then device "tun1" has DNS domain "vpn.domain" for "domain-search"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"
    Then device "eth2" has "no" DNS default-route


    @rhbz1512966
    @ver+=1.26.5
    @ver+=1.27.91
    @ver+=1.28.0
    @ver+=1.29.2
    @openvpn @openvpn4 @dns_systemd_resolved @rhelver+=8
    @dns_resolved_split_tunnel_vpn
    Scenario: NM - dns - split-tunnel VPN

    # Create ethernet connection with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes"
    * Bring "up" connection "openvpn"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has "default" DNS default-route
    Then device "eth2" has DNS domain "con_dns.domain" for "domain-search"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" has "no" DNS default-route
    Then device "tun1" has DNS domain "vpn.domain" for "domain-search"


    @rhbz1888229
    @ver+=1.28 @rhelver+=8 @fedoraver+=33
    @dns_systemd_resolved @eth0
    @dns_resolved_add_remove_ipv6_dns
    Scenario: nmcli - dns - add remove ipv6 dns under resolved
    * Add "ethernet" connection named "con_dns" for device "eth10" with options
          """
          ipv4.method disabled
          ip6 fd01::1/64
          ipv6.dns '4000::1 5000::1'
          ipv6.gateway fd01::2
          autoconnect no
          """
    * Bring "up" connection "con_dns"
    When Nameserver "4000::1" is set in "10" seconds
    When Nameserver "5000::1" is set
    * Modify connection "con_dns" changing options "ipv6.dns ''"
    * Bring "up" connection "con_dns"
    Then Nameserver "4000::1" is not set
    Then Nameserver "5000::1" is not set


    @rhbz1878166
    @rhelver+=8
    @ver+=1.30
    @dns_systemd_resolved
    @dns_resolved_dnssec_opts
    Scenario: NM - dns - dnssec
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"
    Then "edns0" is visible with command "grep options /etc/resolv.conf"
    Then "trust-ad" is visible with command "grep options /etc/resolv.conf"



    @rhbz2015460
    @ver+=1.12
    @dns_systemd_resolved
    @dns_resolved_mdns
    Scenario: NM - dns - mdns
    * Add "ethernet" connection named "con_mdns" for device "eth2" with options
      """
      autoconnect no
      connection.mdns yes
      """
    * Bring "up" connection "con_mdns"
    Then "yes" is visible with command "resolvectl mdns eth2"
    * Execute "nmcli connection modify con_mdns connection.mdns no"
    * Bring "up" connection "con_mdns"
    Then "no" is visible with command "resolvectl mdns eth2"


##########################################
# DEFAULT DNS TESTS
##########################################

    @rhbz2218448
    @ver+=1.36.9
    @ver+=1.38.7
    @ver+=1.40.19
    @ver+=1.42.9
    @ver+=1.43.10
    @not_with_systemd_resolved
    @eth0
    @dns_best_after_reconnect
    Scenario: NM - dns - check that the best connection is honored after reconnecting
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.254"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.route-metric 100"

    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.16.2.1/24 ipv4.gateway 172.16.2.254"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.16.2.53 ipv4.route-metric 200"

    * Bring "up" connection "con_dns"
    * Bring "up" connection "con_dns2"
    * Bring "down" connection "con_dns"
    * Bring "up" connection "con_dns"
    # We can see various search options before nameserver section thus .*
    Then "^# Generated by NetworkManager\n.*nameserver 172.16.1.53\nnameserver 172.16.2.53" is visible with command "cat /etc/resolv.conf"


    @rhbz1228707
    @ver+=1.2.0
    @not_with_systemd_resolved
    @dns_priority
    Scenario: nmcli - ipv4 - dns - priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options
          """
          -- ipv4.method manual
          ipv4.addresses 192.168.1.2/24
          ipv4.gateway 172.16.1.2
          ipv4.dns 2.3.4.1
          ipv4.dns-priority 300
          """
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options
          """
          -- ipv4.method manual
          ipv4.addresses 192.168.2.2/24
          ipv4.gateway 172.16.1.2
          ipv4.dns 1.2.3.4
          ipv4.dns-priority 200
          """
    When Nameserver "1.2.3.4.*2.3.4.1" is set in "5" seconds
    * Modify connection "con_dns" changing options "ipv4.dns-priority 100"
    * Modify connection "con_dns" changing options "ipv6.dns-priority 300"
    * Bring "up" connection "con_dns"
    * Bring "up" connection "con_dns2"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds
    * Bring "up" connection "con_dns"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds


    @not_with_systemd_resolved
    @restart_if_needed
    @dns_priority_config
    Scenario: nmcli - ipv4 - dns - set priority in config
    * Create NM config file with content
      """
      [connection]
      ipv4.dns-priority=200
      """
    * Execute "systemctl reload NetworkManager"
    * Add "ethernet" connection named "con_dns" for device "eth2" with options
          """
          -- ipv4.method manual
          ipv4.addresses 192.168.1.2/24
          ipv4.dns 2.3.4.1
          ipv4.dns-priority 150
          """
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options
          """
          -- ipv4.method manual
          ipv4.addresses 192.168.2.2/24
          ipv4.dns 1.2.3.4
          """
    * Bring "up" connection "con_dns"
    * Bring "up" connection "con_dns2"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds
    * Bring "up" connection "con_dns"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds
    # check that 0 in config makes it default (50 VPN, 100 other)
    * Create NM config file with content
      """
      [connection]
      ipv4.dns-priority=0
      """
    * Execute "systemctl reload NetworkManager"
    * Modify connection "con_dns" changing options "ipv4.dns-priority 40"
    * Bring "up" connection "con_dns"
    * Bring "up" connection "con_dns2"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds
    * Bring "up" connection "con_dns"
    Then Nameserver "2.3.4.1.*1.2.3.4" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @dns_default_two_default
    Scenario: NM - dns - two connections with default route
    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    Then Nameserver "172.16.1.53" is set in "5" seconds
     And Nameserver "172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @eth0
    @dns_default_one_default
    Scenario: NM - dns - two connections, one with default route
    * Bring "down" connection "testeth0"

    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    Then Nameserver "172.16.1.53.*172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.16.1.53.*nameserver 172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @dns_default_two_default_with_priority
    Scenario: NM - dns - two connections with default route, one has higher priority

    # Create connection on eth2 with default route and higher priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    Then Nameserver "172.16.1.53.*172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.16.1.53.*172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @dns_default_two_default_with_negative_priority
    Scenario: NM - dns - two connections with default route, one has negative priority

    # Create connection on eth2 with default route and negative priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority -100"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    Then Nameserver "172.16.1.53" is set in "5" seconds
     And Nameserver "172.17.1.53" is not set in "5" seconds
    Then Domain "search.*con_dns.domain" is set in "5" seconds
    Then Domain "con_dns2.domain" is not set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.16.1.53" is set in "5" seconds
     And Nameserver "172.17.1.53" is not set in "5" seconds
    Then Domain "search.*con_dns.domain" is set in "5" seconds
    Then Domain "con_dns2.domain" is not set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3 @fedoraver+=31
    @not_with_systemd_resolved
    @eth0
    @dns_default_no_default
    Scenario: NM - dns - two connections without default route

    # Create connection on eth2 without default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    Then Nameserver "172.16.1.53" is set in "5" seconds
     And Nameserver "172.17.1.53" is set in "5" seconds
    Then Domain "search.*con_dns.domain.*con_dns2.domain" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @openvpn @openvpn4
    @dns_default_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN

    # Create ethernet connection
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds


    @rhbz1512966
    @ver+=1.11.3
    @not_with_systemd_resolved
    @openvpn @openvpn4
    @dns_default_split_tunnel_vpn
    Scenario: NM - dns - split-tunnel VPN

    # Create ethernet connection with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes"
    * Bring "up" connection "openvpn"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds


    @ver+=1.11.3
    @not_with_systemd_resolved
    @openvpn @openvpn4
    @dns_default_split_tunnel_vpn_same_priority
    Scenario: NM - dns - split-tunnel VPN - same dns priority

    # Create ethernet connection with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes ipv4.dns-priority 10"
    * Bring "up" connection "openvpn"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds

    * Bring "up" connection "con_dns"

    Then Nameserver "172.31.70.53.*172.16.1.53" is set in "5" seconds
    Then Domain "search.*vpn.domain.*con_dns.domain" is set in "5" seconds


##########################################
# DNSMASQ TESTS
##########################################

    @rhbz1512966
    @ver+=1.11.3
    @dns_dnsmasq
    @dns_dnsmasq_two_default
    Scenario: NM - dns - two connections with default route

    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"
    Then device "eth2" has DNS domain "1.16.172.in-addr.arpa"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has DNS domain "."
    Then device "eth3" has DNS domain "con_dns2.domain"
    Then device "eth3" has DNS domain "1.17.172.in-addr.arpa"


    @rhbz1512966
    @ver+=1.11.3
    @dns_dnsmasq
    @dns_dnsmasq_one_default
    Scenario: NM - dns - two connections, one with default route

    # Create connection on eth2 with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "."
    Then device "eth3" has DNS domain "con_dns2.domain"


    @rhbz1628576
    @ver+=1.12
    @dns_dnsmasq @regenerate_veth @skip_str
    @dns_dnsmasq_driver_removal
    Scenario: NM - dns - remove driver
    * Prepare simulated test "testX4" device

    # Create connection on testX4 with default route
    * Add "ethernet" connection named "con_dns" for device "testX4" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Check testX4 configuration
    Then device "testX4" has DNS server "172.16.1.53"
    Then device "testX4" has DNS domain "."
    Then device "testX4" has DNS domain "con_dns.domain"

    # Unload veth Driver
    * Execute "modprobe -r veth"

    # NM should still be working
    * Bring "up" connection "testeth0"


    @rhbz1512966
    @ver+=1.11.3
    @dns_dnsmasq
    @dns_dnsmasq_two_default_with_priority
    Scenario: NM - dns - two connections with default route, one has higher priority

    # Create connection on eth2 with default route and higher priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "."
    Then device "eth3" has DNS domain "con_dns2.domain"


    @rhbz1512966
    @ver+=1.11.3
    @dns_dnsmasq
    @dns_dnsmasq_two_default_with_negative_priority
    Scenario: NM - dns - two connections with default route, one has negative priority

    # Create connection on eth2 with default route and negative priority
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority -100"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"
    Then device "eth2" has DNS domain "1.16.172.in-addr.arpa"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "."
    Then device "eth3" does not have DNS domain "con_dns2.domain"
    Then device "eth3" has DNS domain "1.17.172.in-addr.arpa"


    @rhbz1512966
    @ver+=1.11.3
    @dns_dnsmasq @eth0
    @dns_dnsmasq_no_default
    Scenario: NM - dns - two connections without default route

    # Create connection on eth2 without default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add "ethernet" connection named "con_dns2" for device "eth3" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Since there is no default route eth2 gets the "." domain
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"

    # Since there is no default route eth3 gets the "." domain
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has DNS domain "."
    Then device "eth3" has DNS domain "con_dns2.domain"


    @rhbz1512966
    @ver+=1.11.3
    @openvpn @openvpn4 @dns_dnsmasq
    @dns_dnsmasq_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN

    # Create ethernet connection
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" has DNS domain "."
    Then device "tun1" has DNS domain "vpn.domain"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "con_dns.domain"
    Then device "eth2" does not have DNS domain "."


    @rhbz1512966
    @ver+=1.11.3
    @openvpn @openvpn4 @dns_dnsmasq
    @dns_dnsmasq_split_tunnel_vpn
    Scenario: NM - dns - split-tunnel VPN

    # Create ethernet connection with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes"
    * Bring "up" connection "openvpn"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" does not have DNS domain "."
    Then device "tun1" has DNS domain "vpn.domain"


    @rhbz1878166
    @rhelver+=8
    @ver+=1.30
    @dns_dnsmasq
    @dns_dnsmasq_dnssec_opts
    Scenario: NM - dns - dnssec
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"
    Then "edns0" is visible with command "grep options /etc/resolv.conf"
    Then "trust-ad" is visible with command "grep options /etc/resolv.conf"

##########################################
# DNSMASQ RESTART/KILL TESTS
##########################################

    @ver+=1.15.1
    @dns_dnsmasq @restore_resolvconf
    @dns_dnsmasq_kill
    Scenario: NM - dns - dnsmasq gets restarted when killed
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Bring "up" connection "con_dns"
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"
    * Execute "pkill -f 'dnsmasq .* --conf-dir=/etc/NetworkManager/dnsmasq.d'"
    # Check that NM restarts dnsmasq and also keeps resolv.conf pointing at it
    Then "1" is visible with command "pgrep -c -P `pidof NetworkManager` dnsmasq" in "10" seconds
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"


    @ver+=1.21.2
    @dns_dnsmasq @restore_resolvconf
    @dns_dnsmasq_kill_ratelimit
    # When dnsmasq dies, NM restarts it. But if dnsmasq dies too many
    # times (5 times) in a short period (30 seconds), NM stops respawning
    # it for one minute.
    Scenario: NM - dns - dnsmasq rate-limiting
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Bring "up" connection "con_dns"
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"
    * Execute "for i in `seq 12`; do pkill -P `pidof NetworkManager` dnsmasq; sleep 1; done"
    * Wait for "10" seconds
    # Check dnsmasq is no longer running. Since 1.21.1, resolv.conf still points to localhost
    Then "0" is visible with command "pgrep -c -P `pidof NetworkManager` dnsmasq"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"


    @rhbz2120763
    @ver+=1.40.10
    @dns_dnsmasq
    @dns_dnsmasq_kill_when_nm_restarts
    Scenario: Kill dnsmasq process upon NM restart when dns=none in config
    When "dnsmasq" is visible with command "pgrep dnsmasq -laf | grep -v 'dhcp-range'"
    * Replace "dns=dnsmasq" with "dns=none" in file "/etc/NetworkManager/conf.d/96-nmci-test-dns.conf"
    * Restart NM
    Then "dnsmasq" is not visible with command "pgrep dnsmasq -laf | grep -v '--dhcp-range'"

##########################################
# SYSTEMD-DNSCONFD TESTS
##########################################


    @RHEL-67917 @RHEL-80307
    @ver+=1.51.90
    @ver-=1.53.1
    @dns_dnsconfd
    @dns_dnsconfd_unbound_dns_over_tls
    Scenario: NM - dns - dnsconfd dns over tls via unbound
    * Note the output of "ip r |head -n 1|awk '{print $3}'" as value "gateway"
    * Note the output of "ip a s eth0  |grep inet |head -n 1 |awk '{print $2}'" as value "ipv4"
    * Add "ethernet" connection named "con_dns" for device "eth0" with options
        """
        ipv6.method disable
        ipv4.method manual
        ipv4.addresses <noted:ipv4>
        ipv4.gateway <noted:gateway>
        ipv4.dns-search google.com
        ipv4.dns dns+tls://8.8.8.8#dns.google
        """
    * Commentary
        """
        Let's stop dnsconfd service to see if it is started correctly by NM
        """
    * Execute "systemctl stop dnsconfd"

    * Bring "up" connection "con_dns"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show eth0"
    Then Ping "meet"
    Then Ping "nix.cz"
    * Execute "nmcli device reapply eth0"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show eth0"
    Then Ping "meet"
    Then Ping "nix.cz"


    @RHEL-67917 @RHEL-80307 @RHEL-83175
    @ver+=1.53.2
    @dns_dnsconfd
    @dns_dnsconfd_unbound_dns_over_tls
    Scenario: NM - dns - dnsconfd dns over tls via unbound
    * Note the output of "ip r |head -n 1|awk '{print $3}'" as value "gateway"
    * Note the output of "ip a s eth0  |grep inet |head -n 1 |awk '{print $2}'" as value "ipv4"
    * Add "ethernet" connection named "con_dns" for device "eth0" with options
        """
        ipv6.method disable
        ipv4.method manual
        ipv4.addresses <noted:ipv4>
        ipv4.gateway <noted:gateway>
        ipv4.dns-search google.com
        ipv4.dns dns+tls://8.8.8.8#dns.google
        """
    * Commentary
        """
        Let's check if NM doesn't crash when unbound is masked
        """
    * Execute "systemctl mask unbound"
    * Bring "up" connection "con_dns"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show eth0"
    * Commentary
        """
        Ping will not work here as we have crippled dnsconfd/unbound connection
        """
    * Execute "systemctl unmask unbound"
    * Commentary
        """
        Let's stop dnsconfd service to see if it is started correctly by NM
        """
    * Execute "systemctl stop dnsconfd"
    * Bring "up" connection "con_dns"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show eth0"
    Then Ping "meet"
    Then Ping "nix.cz"
    * Execute "nmcli device reapply eth0"
    Then "connected" is visible with command "nmcli -g GENERAL.STATE device show eth0"
    Then Ping "meet"
    Then Ping "nix.cz"


    @RHEL-67917
    @ver+=1.51.90
    @dns_dnsconfd
    @openvpn @openvpn4
    @dns_dnsconfd_unbound_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN
    # Create ethernet connection
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" has DNS domain "."
    Then device "tun1" has DNS domain "vpn.domain"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "con_dns.domain"

    # Failing as #RHEL-81709
    # Then device "eth2" does not have DNS domain "."



    @RHEL-67917
    @ver+=1.51.90
    @dns_dnsconfd
    @openvpn @openvpn4
    @dns_dnsconfd_unbound_split_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN
    # Create ethernet connection with default route
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes"
    * Bring "up" connection "openvpn"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "."
    Then device "eth2" has DNS domain "con_dns.domain"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" does not have DNS domain "."
    Then device "tun1" has DNS domain "vpn.domain"


    @attach_dnsconfd_log
    @ver+=1.52.0
    @dns_dnsconfd_unbound
    Scenario: NM - dnsconf - run upsteam test suite
    * Commentary
      """
      Run whole test suite reusing the NM packages from the host.
      All tests should pass in c9s, c10s, rhel9.7+ and rhel10.0+
      See dnsconfd_summary bellow for logs and dnsconfd_full to
      see full debug log.
      """
    * Execute "contrib/dnsconfd/test.sh &> /tmp/dnsconfd.txt </dev/null"


##########################################
# OTHER TESTS
##########################################


    @rhbz1676635
    @ver+=1.17.3
    @ver-1.40.16.4
    # adjust version if no-aaaa backported to rhel8.8
    @ver/rhel/8/8-1.40.16.2000
    @ver-1.42.5
    @not_with_systemd_resolved
    @dns_multiple_options
    Scenario: nmcli - dns - add more options to ipv4.dns-options
    * Add "ethernet" connection named "con_dns" for device "\*" with options "autoconnect no ipv4.dns-options ndots:2"
    * Modify connection "con_dns" changing options "+ipv4.dns-options timeout:2"
    Then "timeout\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "-ipv4.dns-options ndots:2"
    Then "timeout\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "-ipv4.dns-options timeout:2"
    Then "timeout\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "ifname eth2 +ipv4.dns-options 'attempts:2 timeout:5 ndots:1'"
    * Bring "up" connection "con_dns"
    Then "options[^\n]*attempts:2" is visible with command "cat /etc/resolv\.conf" in "5" seconds
     And "options[^\n]*timeout:5" is visible with command "cat /etc/resolv\.conf" in "5" seconds
     And "options[^\n]*ndots:1" is visible with command "cat /etc/resolv\.conf" in "5" seconds


    @rhbz1676635
    @rhbz2176137
    @ver+=1.40.16.4
    # adjust version if no-aaaa backported to rhel8.8
    @ver/rhel/8/8+=1.40.16.2000
    @ver+=1.42.5
    @ver+=1.43.6.1
    @not_with_systemd_resolved
    @dns_multiple_options
    Scenario: nmcli - dns - add more options to ipv4.dns-options
    * Add "ethernet" connection named "con_dns" for device "\*" with options "autoconnect no ipv4.dns-options ndots:2"
    * Modify connection "con_dns" changing options "+ipv4.dns-options timeout:2"
    Then "timeout\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "-ipv4.dns-options ndots:2"
    Then "timeout\\:2" is visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "-ipv4.dns-options timeout:2"
    Then "timeout\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
     And "ndots\\:2" is not visible with command "nmcli -g ipv4.dns-options con show id con_dns"
    * Modify connection "con_dns" changing options "ifname eth2 +ipv4.dns-options 'attempts:2 timeout:5 ndots:1 no-aaaa'"
    * Bring "up" connection "con_dns"
    Then "options[^\n]*attempts:2" is visible with command "cat /etc/resolv\.conf" in "5" seconds
     And "options[^\n]*timeout:5" is visible with command "cat /etc/resolv\.conf" in "5" seconds
     And "options[^\n]*ndots:1" is visible with command "cat /etc/resolv\.conf" in "5" seconds
     And "options[^\n]*no-aaaa" is visible with command "cat /etc/resolv\.conf" in "5" seconds


    @remove_dns_clean @restart_if_needed
    @not_with_systemd_resolved
    @dns_none
    Scenario: NM - dns none setting
    * Create NM config file "90-nmci-test-dns-none.conf" with content
      """
      [main]
      dns=none
      """
    * Restart NM
    * Execute "echo 'nameserver 1.2.3.4' | bash -c 'cat > /etc/resolv.conf'"
    * Execute "systemctl mask sendmail"
    * Bring "up" connection "testeth0"
    * Execute "systemctl unmask sendmail"
    Then Nameserver "1.2.3.4" is set in "5" seconds
    Then Nameserver "1[0-9]" is not set in "5" seconds


    @remove_dns_clean @restart_if_needed
    @not_with_systemd_resolved
    @remove_dns_none
    Scenario: NM - dns  none removal
    * Create NM config file "90-nmci-test-dns-none.conf" with content
      """
      [main]
      dns=none
      """
    * Restart NM
    * Execute "echo 'nameserver 1.2.3.4' | bash -c 'cat > /etc/resolv.conf'"
    * Execute "systemctl mask sendmail"
    * Bring "up" connection "testeth0"
    * Execute "systemctl unmask sendmail"
    When Nameserver "1[0-9]" is not set in "5" seconds
    When Nameserver "1.2.3.4" is set in "5" seconds
    * Execute "rm -rf /etc/NetworkManager/conf.d/90-nmci-test-dns-none.conf"
    * Restart NM
    * Bring "up" connection "testeth0"
    Then Nameserver "1.2.3.4" is not set in "5" seconds
    Then Nameserver "1[0-9]" is set in "45" seconds


    @rhbz1593661
    @ver+=1.12
    @not_with_systemd_resolved
    @restore_resolvconf @eth8_disconnect @restart_if_needed
    @resolv_conf_dangling_symlink
    Scenario: NM - dns - follow resolv.conf when dangling symlink
    * Add "ethernet" connection named "con_dns" for device "eth8" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.244.4/24
          ipv4.gateway 192.168.244.1
          ipv4.dns 192.168.244.1
          ipv6.method ignore
          """
    * Stop NM
    * Create NM config file with content
      """
      [main]
      rc-manager=file
      """
    * Remove file "/etc/resolv.conf" if exists
    * Remove file "/run/no-resolv.conf" if exists
    * Create symlink "/etc/resolv.conf" with destination "/run/no-resolv.conf"
    * Start NM
    * Wait for "2" seconds
    Then "/etc/resolv.conf" is symlink with destination "/run/no-resolv.conf"
    * Stop NM
    When "/etc/resolv.conf" is symlink with destination "/run/no-resolv.conf"
    * Remove symlink "/etc/resolv.conf" if exists
    * Wait for "3" seconds
    * Start NM
    Then "/run/no-resolv.conf" is file
    * Remove file "/run/no-resolv.conf" if exists


    @rhbz1593661
    @ver+=1.12 @rhelver+=8
    @not_with_systemd_resolved
    @restore_resolvconf @restart_if_needed
    @resolv_conf_do_not_overwrite_symlink
    Scenario: NM - dns - do not overwrite dns symlink
    * Add "ethernet" connection named "con_dns" for device "eth8" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.244.4/24
          ipv4.gateway 192.168.244.1
          ipv4.dns 192.168.244.1
          ipv6.method ignore
          """
    * Stop NM
    * Remove file "/etc/resolv.conf" if exists
    * Execute "echo 'nameserver 1.2.3.4' > /run/no-resolv.conf"
    * Execute "chcon -t net_conf_t /run/no-resolv.conf || true"
    * Create symlink "/etc/resolv.conf" with destination "/run/no-resolv.conf"
    * Start NM
    * Wait for "2" seconds
    Then "/etc/resolv.conf" is symlink with destination "/run/no-resolv.conf"
    Then "nameserver 1.2.3.4" is visible with command "cat /run/no-resolv.conf"


    @rhbz2134563
    @ver+=1.41.3
    @ver+=1.40.1
    @ver+=1.38.5
    @ver+=1.36.9
    @ver/rhel/8+=1.36.0.11
    @ver/rhel/8+=1.40.0.3
    @not_with_systemd_resolved
    @eth0 @restore_resolvconf @restart_if_needed
    @resolv_conf_dns_priority
    Scenario: NM - dns - sort servers in resolv.conf by priority
    * Prepare simulated test "testD1" device with "192.168.99" ipv4 and "none" ipv6 dhcp address prefix and "60s" leasetime and daemon options " "
    * Prepare simulated test "testD2" device with "192.168.100" ipv4 and "2620:dead:beef" ipv6 dhcp address prefix and "1800s" leasetime and daemon options "--dhcp-option=6,9.9.9.9"
    * Add "ethernet" connection named "con_dns1" for device "testD1" with options
          """
          ipv4.dns 8.8.8.8 ipv4.dns-search example.com
          ipv4.ignore-auto-dns yes ipv4.dns-priority 40
          ipv6.dns 2001::1 ipv6.ignore-auto-dns yes ipv6.dns-priority 41
          """
    * Add "ethernet" connection named "con_dns2" for device "testD2" with options "ipv4.route-metric 50"
    When Nameserver "9.9.9.9" is set in "50" seconds
    # Order is wrong after 58s, does not relate to lease time, even when changed leasetime to 20s, the order is wrong in 58s
    Then "BEGIN\nnameserver 8.8.8.8\nnameserver 2001::1\nnameserver 9.9.9.9" is visible with command "echo BEGIN; grep -v -e search -e '^#' /etc/resolv.conf" for full "70" seconds


    @rhbz2100456
    @ver+=1.41.3
    @ver/rhel/8+=1.36.0.9
    @not_with_systemd_resolved
    @kill_dnsmasq_ip4 @kill_dnsmasq_ip6
    @tshark
    @dns_openshift_dualstack_slow_v4
    Scenario: OpenShift OCP node gets nameserver on network with slow IPv4
    * Prepare simulated test "testX6" device with a bridged peer with bridge options "mcast_snooping 0" and veths to namespaces "v4, v6"
    * Execute "ip -n v4 a add 192.168.99.1/24 dev veth0"
    * Execute "ip -n v6 a add 2620:dead:beaf::1/64 dev veth0"
    * Run child "ip netns exec v4 dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --pid-file=/tmp/dnsmasq_ip4.pid --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.250,2m --dhcp-option=6,192.168.99.1" without shell
    * Run child "ip netns exec v6 dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --enable-ra --dhcp-range=::,constructor:veth0,slaac,64,2m --dhcp-option=option6:dns-server,[2620:dead:beaf::1]"" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 67 or port 68 or port 546 or port 547' > /tmp/tshark.log"
    * Execute "tc -n testX6_ns qdisc add dev v4 root netem delay 1900ms"
    * Execute "tc -n v4 qdisc add dev veth0 root netem delay 1900ms"
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "up" connection "con_ipv6" ignoring error
    Then "nameserver 2620:dead:beaf::1" is visible with command "cat /run/NetworkManager/resolv.conf" in "45" seconds


    @rhbz2100456
    @ver+=1.41.3
    @ver/rhel/8+=1.36.0.9
    @not_with_systemd_resolved
    @kill_dnsmasq_ip4 @kill_dnsmasq_ip6
    @tshark
    @dns_openshift_dualstack_slow_v6
    Scenario: OpenShift OCP node gets nameserver on network with slow IPv6
    * Prepare simulated test "testX6" device with a bridged peer with bridge options "mcast_snooping 0" and veths to namespaces "v4, v6"
    * Execute "ip -n v4 a add 192.168.99.1/24 dev veth0"
    * Execute "ip -n v6 a add 2620:dead:beaf::1/64 dev veth0"
    * Run child "ip netns exec v4 dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --pid-file=/tmp/dnsmasq_ip4.pid --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.250,2m --dhcp-option=6,192.168.99.1" without shell
    #* Run child "ip netns exec v6 dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --enable-ra --dhcp-range=::,constructor:veth0,slaac,64,2m --dhcp-option=option6:dns-server,[2620:dead:beaf::1]"" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 67 or port 68 or port 546 or port 547' > /tmp/tshark.log"
    * Execute "tc -n testX6_ns qdisc add dev v6 root netem delay 1900ms"
    * Execute "tc -n v6 qdisc add dev veth0 root netem delay 1900ms"
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "up" connection "con_ipv6" ignoring error
    Then "nameserver 192.168.99.1" is visible with command "cat /run/NetworkManager/resolv.conf" in "45" seconds


    @rhbz2100456
    @ver+=1.41.3
    @ver/rhel/8+=1.36.0.9
    @not_with_systemd_resolved
    @kill_dnsmasq_ip6
    @tshark
    @dns_openshift_v6_only_slow_v6
    Scenario: OpenShift OCP node gets nameserver on network with slow IPv6 only
    * Prepare simulated test "testX6" device with a bridged peer with bridge options "mcast_snooping 0" and veths to namespaces "v4, v6"
    * Execute "ip -n v6 a add 2620:dead:beaf::1/64 dev veth0"
    * Run child "ip netns exec v6 dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --enable-ra --dhcp-range=::,constructor:veth0,slaac,64,2m --dhcp-option=option6:dns-server,[2620:dead:beaf::1]"" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 67 or port 68 or port 546 or port 547' > /tmp/tshark.log"
    * Execute "tc -n testX6_ns qdisc add dev v6 root netem delay 1900ms"
    * Execute "tc -n v6 qdisc add dev veth0 root netem delay 1900ms"
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "up" connection "con_ipv6" ignoring error
    Then "nameserver 2620:dead:beaf::1" is visible with command "cat /run/NetworkManager/resolv.conf" in "45" seconds


    @rhbz2019306
    @ver+=1.43.0
    @ver+=1.42.0
    @ver+=1.41.91
    @ver/rhel/9/2+=1.42.2.20
    @dns_default @restart_if_needed
    @dns_global
    Scenario: NM - dns global options
    * Create NM config file "95-nmci-resolv.conf" with content
      """
      [global-dns]
      options=timeout:666
      """
    * Restart NM
    Then "options timeout:666" is visible with command "grep options /etc/resolv.conf" in "5" seconds


    @rhbz2189247
    @ver+=1.43.4
    @ver+=1.42.5
    @ver/rhel/9/2+=1.42.2.6
    @ver+=1.40.17
    @ver+=1.38.7
    @not_with_systemd_resolved
    @dns_reapply_on_disabled_ipv6
    Scenario: NM - dns - reapply after disabling IPv6
    # Create connection on eth2 with manual IPv6 address and IPv6 DNS specified
    * Add "ethernet" connection named "con_dns" for device "eth2" with options "autoconnect no"
    * Execute "nmcli connection modify con_dns ipv6.method manual ipv6.addresses 2607:f0d0:1002:51::4/64 ipv6.dns 2000::1"
    * Bring "up" connection "con_dns"
    Then "2000::1" is visible with command "grep nameserver /etc/resolv.conf" in "1" seconds
    Then "exactly" "2" lines with pattern "interface: eth2" are visible with command "nmcli | sed '/DNS configuration:/,/^[^ \t]/ !d'"
    * Execute "nmcli connection modify con_dns -ipv6.addresses 2607:f0d0:1002:51::4/64 -ipv6.dns 2000::1 ipv6.method disabled"
        * Execute "nmcli device reapply eth2"
    Then "2000::1" is not visible with command "grep nameserver /etc/resolv.conf" in "1" seconds
    Then "exactly" "1" lines with pattern "interface: eth2" are visible with command "nmcli | sed '/DNS configuration:/,/^[^ \t]/ !d'"


    @RHEL-92314 @RHEL-92020
    @ver+=1.53.4.2
    @dns_reapply_device_with_same_globals
    Scenario: NM - dns - reapply device with the same globals present
    * Create NM config file "90-nmci-test-dns-none.conf" with content
      """
        [global-dns]
        searches=example.net,example.org
        options=rotate,debug

        [global-dns-domain-*]
        servers=2001:db8:1::d1,2001:db8:1::d2,192.0.2.1
        options=

      """
    * Restart NM
    * Wait for "1" seconds
    * Add "dummy" connection named "dummy0*" for device "dummy0" with options
        """
        ipv4.method manual
        ipv4.dns-search example.net,example.org
        ipv4.addresses 192.0.2.251/24
        ipv4.dns 192.0.2.1
        ipv6.method manual
        ipv6.dns 2001:db8:1::d1,2001:db8:1::d2
        ipv6.addresses 2001:db8:1::1/64
        ipv6.dns-search example.net,example.org
        """
    * Modify connection "dummy0*" changing options "ipv6.dns-options rotate,debug"
    * Commentary
        """
        We shouldn't crash now
        """
    * Execute "nmcli device reapply dummy0"

