Feature: nmcli - ppp

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @not_on_s390x @pppoe @del_test1112_veths
    @connect_to_pppoe_via_pap
    Scenario: NM - ppp - connect with pap auth
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set dev test11 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.111.2" authenticated via "pap"
    * Start pppoe server with "isp" and IP "192.168.111.254" on device "test12"
    * Add "pppoe" connection named "ppp" for device "my-ppp" with options
          """
          pppoe.parent test11
          service isp username test password networkmanager
          autoconnect no
          """
    * Bring "up" connection "ppp"
    Then Nameserver "8.8.8.8" is set in "5" seconds
    Then Nameserver "8.8.4.4" is set in "5" seconds
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is visible with command "ip a s my-ppp"
    And "default via 192.168.111.254 dev my-ppp" is visible with command "ip r"


    @ver/rhel/8+=1.36.6
    @ver/rhel/9+=1.36.6
    @not_on_s390x @pppoe @del_test1112_veths
    @connect_to_pppoe_via_chap
    Scenario: NM - ppp - connect with chap auth
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set dev test11 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.111.2" authenticated via "chap"
    * Start pppoe server with "isp" and IP "192.168.111.254" on device "test12"
    * Add "pppoe" connection named "ppp" for device "test11" with options
          """
          service isp username test password networkmanager
          autoconnect no
          """
    * Bring "up" connection "ppp"
    Then Nameserver "8.8.8.8" is set in "5" seconds
    Then Nameserver "8.8.4.4" is set in "5" seconds
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is visible with command "ip a s"
    And "default via 192.168.111.254 dev ppp" is visible with command "ip r"


    @not_on_s390x @pppoe @del_test1112_veths
    @disconnect_from_pppoe
    Scenario: NM - ppp - disconnect
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set dev test11 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.111.2" authenticated via "chap"
    * Start pppoe server with "isp" and IP "192.168.111.254" on device "test12"
    * Add "pppoe" connection named "ppp" for device "my-ppp" with options
          """
          pppoe.parent test11
          service isp username test password networkmanager
          autoconnect no
          """
    * Bring "up" connection "ppp"
    * Bring "down" connection "ppp"
    Then Nameserver "8.8.8.8" is not set in "5" seconds
    Then Nameserver "8.8.4.4" is not set in "5" seconds
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is not visible with command "ip a s my-ppp"
    And "default via 192.168.111.254 dev my-ppp" is not visible with command "ip r"


    @rhbz1110465
    @ver+=1.4.0
    @fedoraver-=0
    @not_on_s390x @pppoe @del_test1112_veths @firewall
    @update_firewall_zone_upon_reconnect
    Scenario: NM - ppp - firewall zone update upon reconnect
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set dev test11 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.111.2" authenticated via "pap"
    * Start pppoe server with "isp" and IP "192.168.111.254" on device "test12"
    * Add "pppoe" connection named "ppp" for device "my-ppp" with options
          """
          pppoe.parent test11
          service isp username test password networkmanager
          autoconnect no
          """
    * Modify connection "ppp" changing options "connection.zone external"
    * Bring "up" connection "ppp"
    When "external" is visible with command "firewall-cmd --get-zone-of-interface=my-ppp" in "10" seconds
     And Nameserver "8.8.8.8" is set in "5" seconds
     And Nameserver "8.8.4.4" is set in "5" seconds
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is visible with command "ip a s my-ppp"
    And "default via 192.168.111.254 dev my-ppp" is visible with command "ip r"
    * Execute "ip link set dev test12 down && sleep 2 && ip link set dev test12 up"
    Then "external" is visible with command "firewall-cmd --get-zone-of-interface=my-ppp" in "10" seconds
    # Wait till down and reconnect
    * Wait for "5" seconds
     And Nameserver "8.8.8.8" is set in "45" seconds
     And Nameserver "8.8.4.4" is set in "5" seconds
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is visible with command "ip a s my-ppp"
    And "default via 192.168.111.254 dev my-ppp" is visible with command "ip r"


    @rhbz1478694
    @ver+=1.9.1
    @not_on_s390x @pppoe @del_test1112_veths
    @pppoe_over_vlan
    Scenario: NM - ppp - pppoe over vlan
    # We have sometimes residuals from previos tests
    * Execute "ip link del ppp0 || true"
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set test11 up"
    * Execute "ip link set test12 up"
    * Execute "ip link add link test11 vlan1 type vlan id 51"
    * Execute "ip link add link test12 vlan2 type vlan id 51"
    * Execute "ip link set vlan1 up"
    * Execute "ip link set vlan2 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.111.2" authenticated via "pap"
    * Start pppoe server with "isp" and IP "192.168.111.254" on device "vlan1"
    * Add "pppoe" connection named "ppp" for device "my-ppp" with options
          """
          pppoe.parent vlan2
          service isp username test password networkmanager
          autoconnect no
          """
    * Bring "up" connection "ppp"
    Then "inet 192.168.111.2 peer 192.168.111.254/32" is visible with command "ip a s my-ppp"
    And "default via 192.168.111.254 dev my-ppp" is visible with command "ip r"


    @rhbz1854892
    @ver+=1.26 @rhelver+=8
    @not_on_s390x @pppoe @del_test1112_veths @restart_if_needed
    @pppoe_and_ethernet_together
    Scenario: NM - ppp - pppoe and ethernet profiles
    * Execute "ip link add test11 type veth peer name test12"
    * Execute "ip link set test11 up"
    * Execute "ip link set test12 up"
    * Prepare pppoe server for user "test" with "networkmanager" password and IP "192.168.99.2" authenticated via "pap"
    * Start pppoe server with "isp" and IP "192.168.99.254" on device "test12"
    * Add "ethernet" connection named "ppp2" for device "test11" with options
          """
          ipv4.method manual ipv4.addresses 192.168.99.123/24
          ipv4.gateway 192.168.99.1
          """\
    * Add "pppoe" connection named "ppp" for device "my-ppp" with options
          """
          pppoe.parent test11
          service isp username test password networkmanager
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ppp" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ppp2" in "45" seconds
    When Nameserver "8.8.8.8" is set in "5" seconds
    When Nameserver "8.8.4.4" is set in "5" seconds
    When "inet 192.168.99.2 peer 192.168.99.254/32" is visible with command "ip a s my-ppp"
    When "192.168.99.254 dev my-ppp\s+proto kernel\s+scope link\s+src 192.168.99.2" is visible with command "ip r"
    When "default via 192.168.99.254 dev my-ppp.*\s+proto static\s+metric" is visible with command "ip r"
    When "default via 192.168.99.1 dev test11" is visible with command "ip r"
    When "192.168.99.0/24 dev test11 proto kernel scope link src 192.168.99" is visible with command "ip r"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ppp" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ppp2" in "45" seconds
    Then Nameserver "8.8.4.4" is set in "5" seconds
    When "inet 192.168.99.2 peer 192.168.99.254/32" is visible with command "ip a s my-ppp"
    When "192.168.99.254 dev my-ppp\s+proto kernel\s+scope link\s+src 192.168.99.2" is visible with command "ip r"
    When "default via 192.168.99.254 dev my-ppp.*\s+proto static\s+metric" is visible with command "ip r"
    When "default via 192.168.99.1 dev test11" is visible with command "ip r"
    When "192.168.99.0/24 dev test11 proto kernel scope link src 192.168.99" is visible with command "ip r"
