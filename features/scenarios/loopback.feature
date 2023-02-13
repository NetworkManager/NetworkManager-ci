Feature: nmcli: loopback

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.41.6
    @loopback_modify_iface_address
    Scenario: nmcli - loopback - cannot remove the loopback addresses
    When "lo" is visible with command "nmcli device show"
    * Execute "nmcli d modify lo ipv4.addresses '192.168.0.1/24' ipv6.addresses '2620:52:0:beef::1/64'"
    Then "Exactly" "2" lines are visible with command "nmcli -g IP4.ADDRESS -m multiline device show lo"
    And "Exactly" "2" lines are visible with command "nmcli -g IP6.ADDRESS -m multiline device show lo"
    * Reboot
    Then "192.168.0.1/24" is not visible with command "nmcli -g IP4.ADDRESS device show lo"
    And "2620:52:0:beef::1/64" is not visible with command "nmcli -g IP6.ADDRESS device show lo"
    And "127.0.0.1/8" is visible with command "nmcli -g IP4.ADDRESS device show lo"
    And "::1/128" is visible with command "nmcli -f IP6.ADDRESS device show lo"


    @ver+=1.41.6
    @loopback_invalid_profile_options
    Scenario: nmcli - loopback - set invalid profile options
    When "lo" is visible with command "nmcli device show"
    * Cleanup connection "conn_loopback" and device "lo"
    Then "Failed" is visible with command "nmcli con add type loopback ifname lo con-name conn_loopback ipv4.method disabled"
    And "Failed" is visible with command "nmcli con add type loopback ifname lo con-name conn_loopback ipv6.method disabled"


    @ver+=1.41.6
    @loopback_add_connection
    Scenario: nmcli - loopback - add basic loopback profile with options
    * Add "loopback" connection named "conn_loopback" for device "lo" with options 
      """
      ipv4.method auto
      ipv4.addresses 192.168.0.1/24
      ipv6.method manual
      loopback.mtu 1536
      ipv6.addresses '2607:f0d0:1002:51::4/64, 1050:0:0:0:5:600:300c:326b'
      autoconnect yes
      """
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show conn_loopback" in "10" seconds
    And "192.168.0.1/24" is visible with command "nmcli -g ipv4.addresses con show conn_loopback"
    And "2607:f0d0:1002:51::4/64" is visible with command "nmcli -g ipv6.addresses -m multiline con show conn_loopback"
    And "1050::5:600:300c:326b/128" is visible with command "nmcli -g ipv6.addresses -m multiline con show conn_loopback"
    And "mtu 1536" is visible with command "ip a s lo |grep mtu" in "15" seconds
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show conn_loopback" in "10" seconds
    And "2607:f0d0:1002:51::4/64" is visible with command "nmcli -f IP6.ADDRESS dev show lo"
    And "192.168.0.1/24" is visible with command "nmcli -f IP4.ADDRESS dev show lo"
    And "mtu 1536" is visible with command "ip a s lo | grep mtu" in "15" seconds


    @ver+=1.41.6
    @dns_dnsmasq
    @loopback_dns_dnsmasq_default
    Scenario: nmcli - loopback - dnsmasq - single connection with default route
    * Add "loopback" connection named "conn_loopback" for device "lo" with options
          """
          ipv4.method manual
          ipv4.addresses 172.16.1.1/24
          ipv4.gateway 172.16.1.2
          ipv4.dns 172.16.1.53
          ipv4.dns-search con_dns.domain
          """
    * Bring "up" connection "conn_loopback"
    Then device "lo" has DNS server "172.16.1.53"
    Then device "lo" has DNS domain "."
    Then device "lo" has DNS domain "con_dns.domain"
    Then device "lo" has DNS domain "1.16.172.in-addr.arpa"


    @ver+=1.41.6
    @loopback_set_route_with_options
    Scenario: nmcli - loopback - set route with options
    * Add "loopback" connection named "conn_loopback" for device "lo" with options
          """
          autoconnect no
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
    * Bring "up" connection "conn_loopback"
    Then "default via 192.168.4.1 dev lo\s+proto static\s+metric 256" is visible with command "ip route" in "20" seconds
    Then "192.168.3.0/24 dev lo\s+proto kernel\s+scope link\s+src 192.168.3.10\s+metric 256" is visible with command "ip route"
    Then "192.168.4.1 dev lo\s+proto static\s+scope link\s+metric 256" is visible with command "ip route"
    Then "192.168.5.0/24 via 192.168.3.11 dev lo\s+proto static\s+metric 1024\s+mtu lock 1600 cwnd 14" is visible with command "ip route"
    And "default via 192.168.4.1 dev lo proto static metric 256 mtu 1600" is visible with command "ip r"
    And "default via 192.168.4.1 dev lo proto static metric 256" is visible with command "ip r"
    And "blackhole 192.168.6.0/24 proto static scope link metric 256" is visible with command "ip r"


    @ver+=1.41.6
    @loopback_set_iface_as_bond_port
    Scenario: nmcli - loopback - cannot set loopback interface as a port
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ipv4.addresses 1.2.3.4/24 ipv4.method manual
          """
    Then "loopback profile cannot be a port" is visible with command "nmcli connection add type loopback con-name conn_loopback ifname lo master nm-bond"


    @ver+=1.41.6
    @openvswitch
    @loopback_set_iface_as_ovs_port
    Scenario: nmcli - loopback - cannot set loopback interface as a port
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge0"
    Then "loopback profile cannot be a port" is visible with command "nmcli connection add type loopback con-name conn_loopback ifname lo conn.master port1 slave-type ovs-port"


    @ver+=1.41.6
    @loopback_multi_connect
    Scenario: nmcli - loopback - multi-connect option works with loopback
    * Add "loopback" connection named "con_con" for device "*" with options
      """
      connection.multi-connect multiple
      """
    Then "lo" is visible with command "nmcli device | grep con_con" in "10" seconds
    And "eth5" is not visible with command "nmcli device | grep con_con"


    @ver+=1.41.6
    @loopback_match_renamed_iface
    Scenario: nmcli - loopback - assign profile to renamed loopback interface
    * Rename device "lo" to "bestdevice"
    * Add "loopback" connection named "conn_loopback" for device "bestdevice" with options "autoconnect no"
    * Bring "up" connection "conn_loopback"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show conn_loopback" in "10" seconds


    @ver+=1.41.6
    @loopback_multiple_profiles
    Scenario: nmcli - loopback - create multiple profiles
    * Add "loopback" connection named "conn_loopback" for device "lo" with options
      """
      ipv4.method manual
      ipv4.addresses 172.16.1.1/24
      ipv6.method auto
      autoconnect no
      """
    * Add "loopback" connection named "conn_loopback1" for device "lo" with options
      """
      ipv4.method auto
      ipv4.dhcp-timeout 5
      ipv6.method manual
      ipv6.addresses 2607:f0d0:1002:51::4/64
      """
    * Bring "up" connection "conn_loopback"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show conn_loopback" in "10" seconds
    And "activated" is not visible with command "nmcli -g GENERAL.STATE con show conn_loopback1" in "10" seconds
    * Bring "up" connection "conn_loopback1"
    Then "activated" is not visible with command "nmcli -g GENERAL.STATE con show conn_loopback" in "10" seconds
    And "activated" is visible with command "nmcli -g GENERAL.STATE con show conn_loopback1" in "10" seconds
