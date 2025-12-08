 Feature: nmcli: openvpn

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:


    @rhbz1641742
    @ver+=1.12
    @openvpn @openvpn4
    @openvpn_ipv4
    Scenario: nmcli - openvpn - add and connect IPv4 connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Execute "nmcli con up openvpn ifname tun0"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS" is not visible with command "nmcli c show openvpn |grep -v fe80::"
     And "default" is visible with command "ip r |grep ^default | grep -v eth0"


    @rhbz1505886
    @ver+=1.0.8
    @openvpn @openvpn4
    @openvpn_ipv4_neverdefault
    Scenario: nmcli - openvpn - add neverdefault IPv4 connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "ipv4.never-default yes"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
     And "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
     And "IP6.ADDRESS" is not visible with command "nmcli c show openvpn |grep -v fe80::"
     And "default" is not visible with command "ip r |grep ^default | grep -v eth0"


    @rhelver+=9
    @openvpn @openvpn6
    @openvpn_ipv6
    Scenario: nmcli - openvpn - add and connect IPv6 connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::.*/64" is visible with command "nmcli c show openvpn"
     And "IP6.ADDRESS.*fe80::" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default dev tun" is visible with command "ip -6 r s default | grep -v eth0" in "40" seconds


    @rhelver+=9 
    @delete_testeth0 @openvpn @openvpn6 @eth10_disconnect
    @openvpn_ipv6_neverdefault
    Scenario: nmcli - openvpn - add neverdefault IPv6 connection
    * Bring "up" connection "testeth10"
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "ipv6.never-default yes"
    * Bring "down" connection "openvpn"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::.*/64" is visible with command "nmcli c show openvpn"
     And "IP6.ADDRESS.*fe80::" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS" is not visible with command "nmcli c show openvpn"
     And "default" is not visible with command "ip -6 r s default | grep -v eth10"


    @rhbz1267004
    @openvpn
    @openvpn_set_mtu
    Scenario: nmcli - openvpn - set mtu
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.MTU device show eth0" as value "eth0_mtu1"
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Bring "up" connection "openvpn"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.MTU device show eth0" as value "eth0_mtu2"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "1400" is visible with command "ip a s tun1"
    Then Check noted values "eth0_mtu1" and "eth0_mtu2" are the same


    @firewall @openvpn
    @openvpn_set_firewall_zone
    Scenario: nmcli - openvpn - set firewall zone
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "connection.zone public"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP4.ADDRESS.*172.31.70.*/32" is visible with command "nmcli c show openvpn"
    Then "tun1" is visible with command "firewall-cmd --get-active-zones"


    @openvpn
    @openvpn_terminate
    Scenario: nmcli - openvpn - terminate connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "vpn.persistent true"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Bring "down" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show openvpn" in "15" seconds


    @openvpn
    @openvpn_delete_active_connection
    Scenario: nmcli - openvpn - delete connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "vpn.persistent true"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Delete connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show openvpn" in "5" seconds


    @RHEL-5420
    @openvpn
    @openvpn_persist
    Scenario: nmcli - openvpn - persist connection
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "vpn.persistent true"
    * Bring "up" connection "openvpn"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    * Execute "pkill -F /tmp/openvpn.pid"
    * Wait for "3" seconds
    * Run child "openvpn --writepid /tmp/openvpn.pid --config /etc/openvpn/trest-server.conf"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn" in "10" seconds


    @RHEL-43720 @RHEL-44712
    @rhelver+=9
    @ver+=1.48.2
    @ver+=1.46.2
    @ver/rhel/9+=1.48.2.2
    @ver/rhel/9/4+=1.46.0.11
    @permissive
    @openvpn @oath
    @openvpn_2fa
    Scenario: nmcli - openvpn - test 2FA
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options
      """
      +vpn.data connection-type=password,username=trest@redhat,password-flags=2,challenge-response-flags=2
      """
    * Spawn "nmcli -a con up id openvpn" command
    * Expect "Password"
    * Submit "secret"
    * Deny client by challenge-response
    * Expect "Enter PIN"
    * Expect "challenge-response"
    * Submit "123456"
    * Auth client
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn" in "10" seconds


    @RHEL-43720 @RHEL-44712
    @rhelver+=9
    @ver+=1.48.2
    @ver+=1.46.2
    @ver/rhel/9+=1.48.2.2
    @ver/rhel/9/4+=1.46.0.11
    @permissive
    @openvpn @oath
    @openvpn_2fa_save_password
    Scenario: nmcli - openvpn - test 2FA
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options
      """
      +vpn.data connection-type=password,username=trest@redhat,password-flags=0,challenge-response-flags=2
      +vpn.secrets password=secret
      """
    * Spawn "nmcli -a con up id openvpn" command
    * Deny client by challenge-response
    * Expect "Enter PIN"
    * Expect "challenge-response"
    * Submit "123456"
    * Auth client
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn" in "10" seconds


    @RHEL-70160 @RHEL-69901
    @ver+=1.51.6
    @ver/rhel/9/5+=1.48.10.5
    @ver/rhel/9/4+=1.46.0.34
    @openvpn @openvpn4
    @openvpn_add_routing_rules
    Scenario: nmcli - openvpn - add routing rules
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Modify connection "openvpn" changing options "ipv4.route-table 127"
    * Modify connection "openvpn" changing options "ipv6.route-table 200"
    * Modify connection "openvpn" changing options "ipv4.routing-rules 'priority 16383 from all table 127'"
    * Modify connection "openvpn" changing options "ipv6.routing-rules 'priority 16600 from all table 200'"
    * Bring "up" connection "openvpn"

    When "activated" is visible with command "nmcli -g GENERAL.STATE con show openvpn" in "45" seconds
    Then "16383:\s+from all lookup 127 proto static" is visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is visible with command "ip -6 rule"
    And "default" is visible with command "ip r show table 127 |grep ^default | grep -v eth0"
    * Bring "down" connection "openvpn"
    Then "16383:\s+from all lookup 127 proto static" is not visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is not visible with command "ip -6 rule"
    And "default" is not visible with command "ip r show table 127 |grep ^default | grep -v eth0"
