 Feature: nmcli: openvpn

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:


    @ver-1.12
    @openvpn @openvpn4
    @openvpn_ipv4
    Scenario: nmcli - openvpn - add and connect IPv4 connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS" is not visible with command "nmcli c show openvpn"
    And "default" is visible with command "ip r |grep ^default | grep -v eth0"


    @rhbz1641742
    @ver+=1.12
    @openvpn @openvpn4
    @openvpn_ipv4
    Scenario: nmcli - openvpn - add and connect IPv4 connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Finish "nmcli con up openvpn ifname tun0"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default" is visible with command "ip r |grep ^default | grep -v eth0"


    @rhbz1505886
    @ver+=1.0.8
    @openvpn @openvpn4
    @openvpn_ipv4_neverdefault
    Scenario: nmcli - openvpn - add neverdefault IPv4 connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "ipv4.never-default yes"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
     And "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
     And "IP6.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default" is not visible with command "ip r |grep ^default | grep -v eth0"


    @ver+=1.0.8
    @openvpn @openvpn6
    @openvpn_ipv6
    Scenario: nmcli - openvpn - add and connect IPv6 connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::2/64" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default dev tun" is visible with command "ip -6 r s default | grep -v eth0" in "40" seconds


    @rhbz1505886
    @ver+=1.0.8
    @openvpn @openvpn6 @eth10_disconnect
    @openvpn_ipv6_neverdefault
    Scenario: nmcli - openvpn - add neverdefault IPv6 connection
    * Delete connection "testeth0"
    * Bring "up" connection "testeth10"
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "ipv6.never-default yes"
    * Bring "down" connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::2/64" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default" is not visible with command "ip -6 r s default | grep -v eth10"


    @rhbz1267004
    @openvpn
    @openvpn_set_mtu
    Scenario: nmcli - openvpn - set mtu
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "1400" is visible with command "ip a s tun1"
    Then "1500" is visible with command "ip a s eth0"


    @firewall @openvpn
    @openvpn_set_firewall_zone
    Scenario: nmcli - openvpn - set firewall zone
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "connection.zone public"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "tun1" is visible with command "firewall-cmd --get-active-zones"

    @openvpn
    @openvpn_terminate
    Scenario: nmcli - openvpn - terminate connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "vpn.persistent true"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Execute "kill -9 $(ps aux|grep 'openvpn --remote' | awk '{print $2'})"
    * Execute "kill -9 $(ps aux|grep 'openvpn --remote' | awk '{print $2'})"
    * Execute "kill -9 $(ps aux|grep 'openvpn --remote' | awk '{print $2'})"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show openvpn" in "15" seconds


    @openvpn
    @openvpn_delete_active_connection
    Scenario: nmcli - openvpn - delete connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "vpn.persistent true"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Delete connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show openvpn" in "5" seconds


    @openvpn
    @openvpn_persist
    Scenario: nmcli - openvpn - persist connection
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Execute "systemctl restart openvpn@trest-server"
    * Execute "sleep 3"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
