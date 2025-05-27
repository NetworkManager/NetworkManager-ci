Feature: nmcli: gsm

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.39.7
    @permissive @gsm_sim
    @gsm_sim_create_assisted_connection
    Scenario: nmcli - gsm_sim - create an assisted connection
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Submit "gsm" in editor
    * Expect "Interface name"
    * Enter in editor
    * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
    * Submit "no" in editor
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    And "default" is visible with command "ip r |grep 700"
    * Ignore possible AVC "ModemManager"


    @ver+=1.12.0
    @permissive @gsm_sim
    @gsm_sim_create_default_connection
    Scenario: nmcli - gsm_sim - create a connection
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
     * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     And "default" is visible with command "ip r |grep 700"
     And "172.31.82.2 peer 172.31.82.1" is visible with command "ip addr show $(nmcli -g general.ip-iface device show modemu)"
     And Nameserver "172.16.1.1" is set
     * Ignore possible AVC "ModemManager"


    @ver+=1.12.0
    @permissive @gsm_sim
    @gsm_sim_disconnect
    Scenario: nmcli - gsm_sim - disconnect
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
     * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
     * Bring "down" connection "gsm"
    Then "GENERAL.STATE:.*activated" is not visible with command "nmcli con show gsm" in "60" seconds
     And "default" is not visible with command "ip r |grep 700"
     * Ignore possible AVC "ModemManager"


    @rhbz1388613 @rhbz1460217
    @ver+=1.12.0
    @permissive @gsm_sim
    @gsm_sim_mtu
    Scenario: nmcli - gsm_sim - mtu
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
     * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "default" is visible with command "ip r |grep 700" in "60" seconds
     And "mtu 1500" is visible with command "nmcli |grep gsm"
    * Execute "nmcli con modify gsm gsm.mtu 1600"
    * Bring "down" connection "gsm"
    * Wait for "2" seconds
    * Execute "sh prepare/gsm_sim.sh teardown"
    * Wait for "2" seconds
    * Run child "sh prepare/gsm_sim.sh modemu"
    When "gsm" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    Then "mtu 1600" is visible with command "ip a s |grep mtu" in "10" seconds
     And "mtu 1600" is visible with command "nmcli |grep gsm"
     * Ignore possible AVC "ModemManager"


    @rhbz1585611
    @ver+=1.12
    @permissive @gsm_sim
    @gsm_sim_route_metric
    Scenario: nmcli - gsm_sim - route metric
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
     * Add "gsm" connection named "gsm" for device "\*" with options "autoconnect no apn internet"
    * Bring "up" connection "gsm"
    When "default" is visible with command "ip r |grep 700" in "60" seconds
    And "proto kernel scope" is visible with command "ip r |grep 700"
    * Execute "nmcli con modify gsm ipv4.route-metric 120"
    * Bring "down" connection "gsm"
    * Wait for "2" seconds
    * Execute "sh prepare/gsm_sim.sh teardown"
    * Wait for "2" seconds
    * Run child "sh prepare/gsm_sim.sh modemu"
    When "gsm" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
    * Bring "up" connection "gsm"
    When "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    Then "default" is visible with command "ip r |grep 120" in "60" seconds
    And "proto kernel scope" is visible with command "ip r |grep 120"
    * Ignore possible AVC "ModemManager"


    @ver+=1.12.0
    @permissive @gsm_sim
    @gsm_sim_load_from_file
    Scenario: nmcli - gsm_sim - load connection from file
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
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
    * Ignore possible AVC "ModemManager"


    @ver+=1.18.0
    @permissive @gsm_sim
    @gsm_sim_profile_with_serials
    Scenario: nmcli - gsm_sim - serial
    Given "modemu" is visible with command "nmcli device status | grep -v unmanaged" in "60" seconds
     * Add "gsm" connection named "gsm" for device "\*" with options
           """
           autoconnect no
           apn internet
           ipv6.method ignore
           serial.baud 5
           serial.send-delay 100
           """
     * Bring "up" connection "gsm"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli con show gsm" in "60" seconds
    Then "serial.baud:\s+5" is visible with command "nmcli con show gsm"
    Then "serial.send-delay:\s+100" is visible with command "nmcli con show gsm"
     And "default" is visible with command "ip r |grep 700"
     * Ignore possible AVC "ModemManager"
