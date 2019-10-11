@testplan
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
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @rhelver-=0
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
    @con_dns_remove @dns_systemd_resolved @rhelver-=0
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
    Then device "eth3" does not have DNS domain "." for "routing"
    Then device "eth3" has DNS domain "con_dns2.domain" for "search"


    @rhbz1512966
    @ver+=1.11.3
    @con_dns_remove @dns_systemd_resolved @rhelver-=0
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
    @con_dns_remove @dns_systemd_resolved @rhelver-=0
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
    @ver+=1.11.3 @rhelver-=0 @fedoraver+=31
    @con_dns_remove @eth0 @dns_systemd_resolved
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
    @con_dns_remove @openvpn @openvpn4 @dns_systemd_resolved @rhelver-=0
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
    @con_dns_remove @openvpn @openvpn4 @dns_systemd_resolved @rhelver-=0
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
    @con_dns_remove @dns_dnsmasq
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
    @con_dns_remove @dns_dnsmasq
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


    @rhbz1628576
    @ver+=1.12
    @con_dns_remove @dns_dnsmasq @regenerate_veth @teardown_testveth @skip_str
    @dns_dnsmasq_driver_removal
    Scenario: NM - dns - remove driver
    * Prepare simulated test "testX4" device

    # Create connection on testX4 with default route
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname testX4 autoconnect no"
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
    @con_dns_remove @dns_dnsmasq
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
    @con_dns_remove @dns_dnsmasq
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
    @con_dns_remove @openvpn @openvpn4 @dns_dnsmasq
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
    @con_dns_remove @openvpn @openvpn4 @dns_dnsmasq
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

##########################################
# DNSMASQ RESTART/KILL TESTS
##########################################

    @ver+=1.15.1
    @con_dns_remove @dns_dnsmasq
    @dns_dnsmasq_kill
    Scenario: NM - dns - dnsmasq gets restarted when killed
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Bring "up" connection "con_dns"
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"
    * Execute "pkill -f 'dnsmasq .* --conf-dir=/etc/NetworkManager/dnsmasq.d'"
    # Check that NM restarts dnsmasq and also keeps resolv.conf pointing at it
    Then "1" is visible with command "pgrep -c -P `pidof NetworkManager` dnsmasq" in "10" seconds
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"

    @ver+=1.15.1
    @ver-1.21.2
    @con_dns_remove @dns_dnsmasq
    @dns_dnsmasq_kill_ratelimit
    # When dnsmasq dies, NM restarts it. But if dnsmasq dies too many
    # times in a short period, NM stops respawning it for 5 minutes
    # and writes upstream servers to resolv.conf
    Scenario: NM - dns - dnsmasq rate-limiting
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Bring "up" connection "con_dns"
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"
    * Execute "for i in `seq 12`; do pkill -P `pidof NetworkManager` dnsmasq; sleep 1; done"
    * Execute "sleep 10"
    # Check dnsmasq is no longer running and resolv.conf points to upstream servers
    Then "0" is visible with command "pgrep -c -P `pidof NetworkManager` dnsmasq"
    Then "172.16.1.53" is visible with command "grep nameserver /etc/resolv.conf"

    @ver+=1.21.2
    @con_dns_remove @dns_dnsmasq
    @dns_dnsmasq_kill_ratelimit
    # When dnsmasq dies, NM restarts it. But if dnsmasq dies too many
    # times (5 times) in a short period (30 seconds), NM stops respawning
    # it for one minute.
    Scenario: NM - dns - dnsmasq rate-limiting
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname eth2 autoconnect no"
    * Execute "nmcli connection modify con_dns ipv4.dns 172.16.1.53 ipv4.method manual ipv4.addresses 172.16.1.1/24"
    * Bring "up" connection "con_dns"
    Then "1" is visible with command "grep nameserver -c /etc/resolv.conf"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"
    * Execute "for i in `seq 12`; do pkill -P `pidof NetworkManager` dnsmasq; sleep 1; done"
    * Execute "sleep 10"
    # Check dnsmasq is no longer running. Since 1.21.1, resolv.conf still points to localhost
    Then "0" is visible with command "pgrep -c -P `pidof NetworkManager` dnsmasq"
    Then "127.0.0.1" is visible with command "grep nameserver /etc/resolv.conf"


    @rhbz1676635
    @ver+=1.17.3
    @con_dns_remove
    @dns_multiple_options
    Scenario: nmcli - dns - add more options to ipv4.dns-options
    * Add a new connection of type "ethernet" and options "con-name con_dns ifname \* autoconnect no ipv4.dns-options ndots:2"
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
    Then "options[^\n]*attempts:2" is visible with command "cat /etc/resolv.conf" in "5" seconds
     And "options[^\n]*timeout:5" is visible with command "cat /etc/resolv.conf" in "5" seconds
     And "options[^\n]*ndots:1" is visible with command "cat /etc/resolv.conf" in "5" seconds


    @restart @remove_dns_clean
    @dns_none
    Scenario: NM - dns none setting
    * Execute "printf '[main]\ndns=none\n' | sudo tee /etc/NetworkManager/conf.d/90-test-dns-none.conf"
    * Restart NM
    * Execute "echo 'nameserver 1.2.3.4' | sudo bash -c 'cat > /etc/resolv.conf'"
    * Execute "systemctl mask sendmail"
    * Bring "up" connection "testeth0"
    * Execute "systemctl unmask sendmail"
    Then "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 1[0-9]" is not visible with command "cat /etc/resolv.conf"


    @restart @remove_dns_clean
    @remove_dns_none
    Scenario: NM - dns  none removal
    * Execute "printf '[main]\ndns=none\n' | sudo tee /etc/NetworkManager/conf.d/90-test-dns-none.conf"
    * Restart NM
    * Execute "echo 'nameserver 1.2.3.4' | sudo bash -c 'cat > /etc/resolv.conf'"
    * Execute "systemctl mask sendmail"
    * Bring "up" connection "testeth0"
    * Execute "systemctl unmask sendmail"
    When "nameserver 1[0-9]" is not visible with command "cat /etc/resolv.conf"
    When "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "sudo rm -rf /etc/NetworkManager/conf.d/90-test-dns-none.conf"
    * Restart NM
    * Bring "up" connection "testeth0"
    Then "nameserver 1.2.3.4" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 1[0-9]" is visible with command "cat /etc/resolv.conf" in "45" seconds
