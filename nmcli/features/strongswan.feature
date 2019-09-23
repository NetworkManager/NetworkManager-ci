Feature: nmcli: strongswan

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @ver+=1.12
    @strongswan
    @strongswan_add_profile
    Scenario: nmcli - strongswan - add and connect a connection
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Bring "up" connection "strongswan"
    Then "172.31.70.0/24 .*dev strongswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan"
    Then "172.29.100.1/32" is visible with command "nmcli -g IP4.ADDRESS c show strongswan"
    Then "172.29.100.1/32" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    Then "172.31.70.*/24" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    #Then "172.31.70.1" is visible with command "nmcli -g IP4.GATEWAY d show strongswan1"


    @ver+=1.12
    @strongswan @long
    @strongswan_connection_renewal
    Scenario: NM - strongswan - main connection lifetime renewal
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Bring "up" connection "strongswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan" for full "130" seconds
    Then "172.31.70.0/24 .*dev strongswan1" is visible with command "ip route"
    Then "172.29.100.1/32" is visible with command "nmcli -g IP4.ADDRESS c show strongswan"
    Then "172.29.100.1/32" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    Then "172.31.70.*/24" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    #Then "172.31.70.1" is visible with command "nmcli -g IP4.GATEWAY d show strongswan1"


    @ver+=1.12
    @strongswan
    @strongswan_terminate
    Scenario: nmcli - strongswan - terminate connection
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Bring "up" connection "strongswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan"
    * Bring "down" connection "strongswan"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show strongswan" in "10" seconds


    @ver+=1.12
    @strongswan
    @strongswan_delete_active_profile
    Scenario: nmcli - strongswan - delete active profile
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Bring "up" connection "strongswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan"
    * Delete connection "strongswan"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show strongswan" in "10" seconds
    Then "172.29.100.0/24 .*dev strongswan1" is not visible with command "ip route" in "10" seconds


    @ver+=1.12
    @strongswan
    @strongswan_dns
    Scenario: nmcli - strongswan - dns
    Given "nameserver 172.31.70.1" is visible with command "cat /etc/resolv.conf"
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Bring "up" connection "strongswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan"
     And "nameserver 8.8.8.8" is visible with command "cat /etc/resolv.conf"
     And "nameserver 172.31.70.1" is visible with command "cat /etc/resolv.conf"
    * Delete connection "strongswan"
    When "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show strongswan" in "10" seconds
    Then "nameserver 8.8.8.8" is not visible with command "cat /etc/resolv.conf"
     And "nameserver 172.31.70.1" is visible with command "cat /etc/resolv.conf"


     @ver+=1.12
    @strongswan
    @strongswan_start_as_secondary
    Scenario: nmcli - strongswan - start as secondary
    * Add a connection named "strongswan" for device "\*" to "strongswan" VPN
    * Use user "budulinek" with secret "12345678901234567890" for gateway "172.31.70.1" on Strongswan connection "strongswan"
    * Execute "sleep 2; nmcli con modify str1 connection.secondaries strongswan; sleep 3"
    * Bring "down" connection "str1"
    * Execute "ip link set dev strongswan1 up"
    * Bring "up" connection "str1"
    Then "strongswan" is visible with command "nmcli con show -a" in "60" seconds
    Then "str1" is visible with command "nmcli con show -a" in "60" seconds
    Then "172.31.70.0/24 .*dev strongswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show strongswan"
    Then "IP4.ADDRESS.*172.29.100.1/32" is visible with command "nmcli c show strongswan"
    Then "172.29.100.1/32" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    Then "172.31.70.*/24" is visible with command "nmcli -g IP4.ADDRESS d show strongswan1"
    #Then "172.31.70.1" is visible with command "nmcli -g IP4.GATEWAY d show strongswan1"
