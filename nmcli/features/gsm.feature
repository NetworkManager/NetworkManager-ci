Feature: nmcli: gsm


    @ver+=1.2.0
    @eth0 @gsm
    @gsm_create_assisted_connection
    Scenario: nmcli - gsm - create an assisted connection
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Submit "gsm" in editor
    * Expect "Interface name"
    * Enter in editor
    * Expect "APN"
    * Submit "internet" in editor
    * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
    * Submit "no" in editor
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     * Ping "8.8.8.8" "7" times


    @eth0 @gsm
    @gsm_create_default_connection
    Scenario: nmcli - gsm - create a connection
     * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     And "default" is visible with command "ip r |grep 700"
     And Ping "8.8.8.8" "7" times


    @eth0 @gsm
    @gsm_disconnect
    Scenario: nmcli - gsm - disconnect
     * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
     * Bring "down" connection "gsm"
    Then "GENERAL.STATE:.*activated" is not visible with command "nmcli con show gsm" in "20" seconds
     And "default" is not visible with command "ip r |grep 700"
     And Unable to ping "8.8.8.8"


    @rhbz1388613 @rhbz1460217
    @ver+=1.8.0
    @eth0 @gsm
    @gsm_mtu
    Scenario: nmcli - gsm - mtu
    * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "mtu 1500" is visible with command "ip a s |grep $(nmcli |grep gsm |tail -1 |awk '{print $NF}')"
     And "mtu 1500" is visible with command "nmcli |grep gsm"
    * Execute "nmcli con modify gsm gsm.mtu 1600"
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    Then "mtu 1600" is visible with command "ip a s |grep $(nmcli |grep gsm |tail -1 |awk '{print $NF}')"
     And "mtu 1600" is visible with command "nmcli |grep gsm"


    # Modems are not stable enough to test such things VVV
    # @ver+=1.2.0
    # @eth0 @gsm
    # @gsm_up_down_up
    # Scenario: nmcli - gsm - reconnect with down
    #  * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
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
    # @eth0 @gsm
    # @gsm_up_up
    # Scenario: nmcli - gsm - reconnect without down
    #  * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
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
    @eth0 @gsm
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
     * Execute "nmcli con reload"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     * Ping "8.8.8.8" "7" times

    @ver+=1.8.0
    @gsm @connectivity @eth0
    @gsm_connectivity_check
    Scenario: nmcli - gsm - connectivity check
    * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     And "none|limited" is visible with command "nmcli g" in "60" seconds
    * Execute "nmcli con modify gsm ipv4.dns 10.38.5.26"
    * Bring "up" connection "gsm"
    Then "full" is visible with command "nmcli g" in "60" seconds
     And Ping "nix.cz" "7" times
