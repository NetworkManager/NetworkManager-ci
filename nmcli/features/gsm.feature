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
     * Ping "8.8.8.8" "7" times


    @eth0 @gsm
    @gsm_disconnect
    Scenario: nmcli - gsm - disconnect
     * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
     * Bring "down" connection "gsm"
    Then "GENERAL.STATE:.*activated" is not visible with command "nmcli con show gsm" in "20" seconds
     * Unable to ping "8.8.8.8"


    @rhbz1388613
    @ver+=1.8.0
    @eth0 @gsm
    @gsm_mtu
    Scenario: nmcli - gsm - mtu
    * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "mtu 1500" is visible with command "ip a s |grep $(nmcli |grep gsm |tail -1 |awk '{print $NF}')"
    * Execute "nmcli con modify gsm gsm.mtu 1600"
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "20" seconds
    Then "mtu 1600" is visible with command "ip a s |grep $(nmcli |grep gsm |tail -1 |awk '{print $NF}')"

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


    @eth0 @gsm
    @gsm_measure_signal_quality
    Scenario: nmcli - gsm - measure signal quality
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
        * Bring "up" connection "gsm"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        Then signal quality can be measured


    @eth0 @gsm
    @gsm_check_ipv6_support
    Scenario: nmcli - gsm - check if ipv6 addressing is supported
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
        * Bring "up" connection "gsm"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        Then "IPv6" addressing is supported


    @eth0 @gsm
    @gsm_check_connection_stability
    Scenario: nmcli - gsm - check if a GSM connection is stable for at least 60 sec
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
        * Bring "up" connection "gsm"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        * Execute "sleep 60"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm"


    @eth0 @gsm
    @gsm_check_autoconnect
    Scenario: nmcli - gsm - check property autoconnect of a connection
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect yes apn internet"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        Then "yes" is visible with command "nmcli -f connection.autoconnect con show gsm | awk -F: '{print $2}'"


    @eth0 @gsm
    @gsm_check_apn
    Scenario: nmcli - gsm - check apn string of a connection
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
        * Bring "up" connection "gsm"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        Then "internet" is visible with command "nmcli -f gsm.apn con show gsm | awk -F: '{print $2}'"


    @eth0 @gsm
    @gsm_check_ipv4_settings
    Scenario: nmcli - gsm - check ipv4 settings of a connection
        * Add a new connection of type "gsm" and options "ifname \* con-name gsm autoconnect no apn internet"
        * Bring "up" connection "gsm"
        Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
        Then "auto" is visible with command "nmcli -f ipv4.method con show gsm | awk -F: '{print $2}'"
        Then "192.168.99.[0-9]*/24" is visible with command "nmcli -f IP4.ADDRESS con show gsm | awk -F: '{print $2}'"
        Then "192.168.99.[0-9]*" is visible with command "nmcli -f IP4.GATEWAY con show gsm | awk -F: '{print $2}'"
        Then "192.168.99.0/24" is visible with command "nmcli -f IP4.ROUTE con show gsm | awk -F: '{print $2}'"
        Then "8.8.8.8" is visible with command "nmcli -f IP4.DNS con show gsm | awk -F: '{print $2}'"
