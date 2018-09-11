@testplan
Feature: nmcli - dns

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    # PLEASE DO USE ETH2 AND ETH3 DEVICES ONLY

##########################################
# SYSTEMD-RESOLVED TESTS
##########################################

    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @not_in_rhel7
        @dns_resolved_two_default
    Scenario: NM - dns - two connections with default route

    # Create connection on eth2 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # Check eth3 configuration
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has DNS domain "." for "routing"
    Then device "eth3" has DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_one_default
    Scenario: NM - dns - two connections, one with default route

    # Create connection on eth2 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # eth3 doesn't have a default route and so doesn't get the "." domain
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain"." for "routing"
    Then device "eth3" has DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_two_default_with_priority
    Scenario: NM - dns - two connections with default route, one has higher priority

    # Create connection on eth2 with default route and higher priority
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # eth3 doesn't have the "." domain because eth2 has higher priority
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "." for "routing"
    Then device "eth3" has DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_two_default_with_negative_priority
    Scenario: NM - dns - two connections with default route, one has negative priority

    # Create connection on eth2 with default route and negative priority
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority -100"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24 ipv4.gateway 172.17.1.2"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # eth3 configuration is overridden by eth2 with negative priority
    Then device "eth3" does not have DNS server "172.17.1.53"
    Then device "eth3" does not have DNS domain "." for "routing"
    Then device "eth3" does not have DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @eth0 @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_no_default
    Scenario: NM - dns - two connections without default route

    # Create connection on eth2 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
    * Execute "nmcli connection modify con_dns2 ipv4.method manual ipv4.addresses 172.17.1.1/24"
    * Execute "nmcli connection modify con_dns2 ipv4.dns 172.17.1.53 ipv4.dns-search con_dns2.domain"
    * Bring "up" connection "con_dns2"

    # Since there is no default route eth2 gets the "." domain
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # Since there is no default route eth3 gets the "." domain
    Then device "eth3" has DNS server "172.17.1.53"
    Then device "eth3" has DNS domain "." for "routing"
    Then device "eth3" has DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @openvpn @openvpn4 @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN

    # Create ethernet connection
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" has DNS domain "." for "routing"
    Then device "tun1" has DNS domain "vpn.domain" for "search"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"
    Then device "eth2" does not have DNS domain "." for "routing"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @openvpn @openvpn4 @dns_systemd_resolved @not_in_rhel7
    @dns_resolved_split_tunnel_vpn
    Scenario: NM - dns - split-tunnel VPN

    # Create ethernet connection with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con modify openvpn ipv4.never-default yes"
    * Bring "up" connection "openvpn"

    # Check eth2 configuration
    Then device "eth2" has DNS server "172.16.1.53"
    Then device "eth2" has DNS domain "." for "routing"
    Then device "eth2" has DNS domain "con_dns.domain" for "search"

    # Check tun1 configuration
    Then device "tun1" has DNS server "172.31.70.53"
    Then device "tun1" does not have DNS domain "." for "routing"
    Then device "tun1" has DNS domain "vpn.domain" for "search"

##########################################
# DNSMASQ TESTS
##########################################

    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_two_default
    Scenario: NM - dns - two connections with default route

    # Create connection on eth2 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
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
    @con_dns_remove @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_one_default
    Scenario: NM - dns - two connections, one with default route

    # Create connection on eth2 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
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


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_two_default_with_priority
    Scenario: NM - dns - two connections with default route, one has higher priority

    # Create connection on eth2 with default route and higher priority
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority 10"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
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
    @con_dns_remove @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_two_default_with_negative_priority
    Scenario: NM - dns - two connections with default route, one has negative priority

    # Create connection on eth2 with default route and negative priority
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Execute "nmcli connection modify con_dns ipv4.dns-priority -100"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
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
    @con_dns_remove @eth0 @dns_dnsmasq
    @dns_dnsmasq_no_default
    Scenario: NM - dns - two connections without default route

    # Create connection on eth2 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create connection on eth3 without default route
    * Add a new connection of type "ethernet" and options "con-name con_dns2 ifname eth3 autoconnect no"
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
    @con_dns_remove @openvpn @openvpn4 @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_full_tunnel_vpn
    Scenario: NM - dns - full-tunnel VPN

    # Create ethernet connection
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create full-tunnel VPN connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
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
    @con_dns_remove @openvpn @openvpn4 @dns_dnsmasq @not_in_rhel7
    @dns_dnsmasq_split_tunnel_vpn
    Scenario: NM - dns - split-tunnel VPN

    # Create ethernet connection with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv4.gateway 172.16.1.2"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.dns-search con_dns.domain"
    * Bring "up" connection "con_dns"

    # Create split-tunnel VPN connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
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
