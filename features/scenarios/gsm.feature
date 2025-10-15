Feature: nmcli: gsm

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    # @gsm_hub
    # Scenario: nmcli - gsm - hub
    # * Execute "echo 'This should not be reached' && false"

    # @gsm_hub_simple
    # Scenario: nmcli - gsm - hub
    # * Execute "echo 'This should not be reached' && false"

    @gsm
    @gsm_create_default_connection_mbim
    Scenario: nmcli - gsm - create a connection
    * Note the output of "nmcli | grep -B1 mbim | grep -o '"[^"]*"' | tr -d '"'" as value "mbim"
    * Add "gsm" connection named "gsm" for device "<noted:mbim>" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    # Workaround
    * Wait for "10" seconds
     And "default" is visible with command "ip r |grep 700"
     And Ping "nix.cz" "7" times


    @gsm
    @gsm_create_default_connection_qmi
    Scenario: nmcli - gsm - create a connection
    * Note the output of "nmcli | grep -B1 qmi | grep -o '"[^"]*"' | tr -d '"'" as value "qmi"
    * Add "gsm" connection named "gsm" for device "<noted:qmi>" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    # Workaround
    * Wait for "10" seconds
     And "default" is visible with command "ip r |grep 700"
     And Ping "nix.cz" "7" times


    @ver+=1.39.7
    @gsm
    @gsm_create_assisted_connection
    Scenario: nmcli - gsm - create an assisted connection
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Submit "gsm" in editor
    * Expect "Interface name"
    * Enter in editor
    * Submit "yes" in editor
    * Expect "Username"
    * Submit "user" in editor
    * Expect "Password"
    * Submit "pass" in editor
    * Expect "APN"
    * Submit "internet" in editor
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "gsm.password:\s+pass" is visible with command "nmcli connection show gsm --show-secrets"
    Then "gsm.username:\s+user" is visible with command "nmcli connection show gsm --show-secrets"
    Then "gsm.apn:internet" is visible with command "nmcli -t connection show gsm --show-secrets"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    # Workaround
    * Wait for "10" seconds

    And "default" is visible with command "ip r |grep 700"
    * Ping "8.8.8.8" "7" times


    @gsm
    @gsm_disconnect
    Scenario: nmcli - gsm - disconnect
     * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
     * Bring "down" connection "gsm"
    Then "GENERAL.STATE:.*activated" is not visible with command "nmcli con show gsm" in "20" seconds
    # Workaround
    * Wait for "10" seconds

     And "default" is not visible with command "ip r |grep 700"
     And Unable to ping "8.8.8.8"


    @gsm
    @gsm_create_one_minute_ping
    Scenario: nmcli - gsm - one minute ping
    * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     And "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" for full "60" seconds
    # Workaround
    * Wait for "10" seconds

     And "default" is visible with command "ip r |grep 700"
     And Ping "8.8.8.8" "7" times


    @rhbz1388613 @rhbz1460217
    @ver+=1.8.0
    @gsm
    @gsm_mtu
    Scenario: nmcli - gsm - mtu
    * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet gsm.mtu 1430"
    * Modify connection "gsm" changing options "gsm.mtu 1430"
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
     And "mtu 1430" is visible with command "ip a s |grep -v -e lo -e eth|grep mtu" in "5" seconds
     And "mtu 1430" is visible with command "nmcli |grep gsm"
     * Modify connection "gsm" changing options "gsm.mtu 1500"
     * Bring "up" connection "gsm"
     When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
     Then "mtu 1500" is visible with command "ip a s |grep -v -e lo -e eth|grep mtu" in "5" seconds
      And "mtu 1500" is visible with command "nmcli |grep gsm"


    @rhbz1585611
    @ver+=1.12
    @gsm
    @gsm_route_metric
    Scenario: nmcli - gsm - route metric
    * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "default" is visible with command "ip r |grep 700" in "20" seconds
    And "proto .* scope" is visible with command "ip r |grep 700"
    * Modify connection "gsm" changing options "ipv4.route-metric 120"
    * Bring "up" connection "gsm"
    * Wait for "5" seconds
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    Then "default" is visible with command "ip r |grep 120" in "20" seconds
    And "proto .* scope" is visible with command "ip r |grep 120"


    # Modems are not stable enough to test such things VVV
    # @ver+=1.2.0
    # @gsm
    # @gsm_up_down_up
    # Scenario: nmcli - gsm - reconnect with down
    #  * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "down" connection "gsm"
    #  And Unable to ping "8.8.8.8"
    # Then "GENERAL.STATE:.*activated" is not visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Ping "8.8.8.8" "7" times
    #
    #
    # @ver+=1.2.0
    # @gsm
    # @gsm_up_up
    # Scenario: nmcli - gsm - reconnect without down
    #  * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Bring "up" connection "gsm"
    # Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    #  * Ping "8.8.8.8" "7" times


    @ver+=1.2.0
    @gsm
    @gsm_load_from_file
    Scenario: nmcli - gsm - load connection from file
     * Append "[connection]" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "id=gsm" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "uuid=12345678-abcd-eeee-ffff-098106543210" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "type=gsm" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "autoconnect=false" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "[gsm]" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "apn=internet" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "number=*99#" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "[ipv4]" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "method=auto" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "[ipv6]" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "method=auto" to file "/etc/NetworkManager/system-connections/gsm"
     * Append "addr-gen-mode=stable-privacy" to file "/etc/NetworkManager/system-connections/gsm"
     * Execute "chmod 600 /etc/NetworkManager/system-connections/gsm"
     * Reload connections
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    # Workaround
    * Wait for "10" seconds

     * Ping "8.8.8.8" "7" times


    @ver+=1.8.0
    @connectivity @gsm
    @gsm_connectivity_check
    Scenario: nmcli - gsm - connectivity check
    When "none|limited" is visible with command "nmcli g" in "60" seconds
    * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     And "default" is visible with command "ip r |grep 700"
    * Modify connection "gsm" changing options "ipv4.dns 10.38.5.26"
    * Bring "up" connection "gsm"
    Then "full" is visible with command "nmcli g" in "80" seconds
     And Ping "nix.cz" "7" times
