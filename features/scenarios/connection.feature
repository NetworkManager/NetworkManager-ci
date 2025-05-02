Feature: nmcli: connection

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @connection_help
    Scenario: nmcli - connection - help and autocompletion
    Then "COMMAND :=  { show | up | down | add | modify | edit | delete | reload | load }\s+show\s+up\s+down\s+add\s+modify\s+edit\s+edit\s+delete\s+reload\s+load" is visible with command "nmcli connection help"
    Then "--active" is visible with tab after "nmcli connection show "
    Then "autoconnect" is visible with tab after "nmcli connection add "
    Then "con-name" is visible with tab after "nmcli connection add "
    Then "help" is visible with tab after "nmcli connection add "
    Then "ifname" is visible with tab after "nmcli connection add "
    Then "type" is visible with tab after "nmcli connection add "
    Then "add" is visible with tab after "nmcli connection "
    Then "down" is visible with tab after "nmcli connection "
    Then "help" is visible with tab after "nmcli connection "
    Then "modify" is visible with tab after "nmcli connection "
    Then "show" is visible with tab after "nmcli connection "
    Then "delete" is visible with tab after "nmcli connection "
    Then "edit" is visible with tab after "nmcli connection "
    Then "load" is visible with tab after "nmcli connection "
    Then "reload" is visible with tab after "nmcli connection "
    Then "up" is visible with tab after "nmcli connection "
    Then "Usage: nmcli connection add { OPTIONS | help }\s+OPTIONS \:= COMMON_OPTIONS TYPE_SPECIFIC_OPTIONS IP_OPTIONS\s+COMMON_OPTIONS:\s+type <type>\s+ifname <interface name> |\s+ethernet\:\s+wifi:\s+ssid <SSID>\s+gsm:\s+apn <APN>\s+cdma:\s+infiniband:\s+bluetooth:\s+vlan:\s+dev <parent device \(connection  UUID, ifname, or MAC\)>\s+bond:\s+bond-slave:\s+master <master \(ifname or connection UUID\)>\s+team:\s+team-slave:\s+master <master \(ifname or connection UUID\)>\s+bridge:\s+bridge-slave:\s+master <master \(ifname or connection UUID\)>\svpn:\s+vpn-type vpnc|openvpn|pptp|openconnect|openswan\s+olpc-mesh:\s+ssid" is visible with command "nmcli connection add help"


    @connection_names_autocompletion
    Scenario: nmcli - connection - names autocompletion
    Then "testeth0" is visible with tab after "nmcli connection edit id "
    Then "testeth6" is visible with tab after "nmcli connection edit id "
    Then "con_con" is not visible with tab after "nmcli connection edit id "
    * Add "ethernet" connection named "con_con" for device "eth5"
    Then "con_con" is visible with tab after "nmcli connection edit "
    Then "con_con" is visible with tab after "nmcli connection edit id "


    @rhbz1375933
    @nmcli_device_autocompletion
    Scenario: nmcli - connection - device autocompletion
    * Cleanup connection "con_con"
    Then "eth0|eth1|eth10" is visible with tab after "nmcli connection add type ethernet ifname "


    @rhbz1367736
    @connection_objects_autocompletion
    Scenario: nmcli - connection - objects autocompletion
    * Cleanup connection "con_con"
    Then "ipv4.dad-timeout" is visible with tab after "nmcli connection add type bond -- ipv4.method manual ipv4.addresses 1.1.1.1/24 ip"


    @rhbz1301226
    @ver+=1.4.0
    @802_1x_objects_autocompletion
    Scenario: nmcli - connection - 802_1x objects autocompletion
    * "802.1x" is visible with tab after "nmcli  connection add type ethernet ifname eth5 con-name con_con2 802-"
    * Cleanup connection "con_con2"
    * Add "ethernet" connection named "con_con" for device "eth5" with options "802-1x.identity jdoe 802-1x.eap leap"
    Then "802-1x.eap:\s+leap\s+802-1x.identity:\s+jdoe" is visible with command "nmcli con show con_con"


    @rhbz1391170
    @ver+=1.8.0
    @connection_get_value
    Scenario: nmcli - connection - get value
    Then "testeth0\s+eth0" is visible with command "nmcli -g connection.id,connection.interface-name connection show testeth0"
     And "--" is visible with command "nmcli connection show testeth0 |grep connection.master"
     And "--" is not visible with command "nmcli -t connection show testeth0 |grep connection.master"


    @rhbz842975
    @connection_no_error
    Scenario: nmcli - connection - no error shown
    Then "error" is not visible with command "nmcli -f DEVICE connection"
    Then "error" is not visible with command "nmcli -f DEVICE dev"
    Then "error" is not visible with command "nmcli -f DEVICE nm"


    @connection_delete_while_editing
    Scenario: nmcli - connection - delete opened connection
     * Add "ethernet" connection named "con_con" for device "eth5"
     * Open editor for "con_con" with timeout
     * Delete connection "con_con" and hit Enter


    @rhbz1168657
    @connection_double_delete
    Scenario: nmcli - connection - double delete
     * Add "ethernet" connection named "con_con" for device "\*"
     * Delete connection "con_con con_con"


    @rhbz1171751
    @ver+=1.18
    @connection_profile_duplication
    Scenario: nmcli - connection - profile duplication
     * Prepare simulated test "testXc" device
     * Add "ethernet" connection named "con_con" for device "testXc" with options "autoconnect no"
     * Execute "nmcli device set testXc managed no"
     * Reload connections
     * Remove file "/etc/NetworkManager/system-connections/con_con.nmconnection" if exists
     * Reload connections
     * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect no"
     * Reload connections
     Then "Exactly" "1" lines with pattern "con_con" are visible with command "nmcli c"
     * Bring "up" connection "con_con"


    @rhbz1174164
    @add_testeth5
    @connection_veth_profile_duplication
    Scenario: nmcli - connection - veth - profile duplication
    * Connect device "eth5"
    * Connect device "eth5"
    * Connect device "eth5"
    * Delete connection "testeth5"
    * Connect device "eth5"
    * Connect device "eth5"
    * Connect device "eth5"
    Then "Exactly" "1" lines with pattern "^eth5" are visible with command "nmcli connection"


    @rhbz1498943
    @ver+=1.10
    @double_connection_warning
    Scenario: nmcli - connection - warn about the same name
    * Add "ethernet" connection named "con_con2" for device "eth5"
    Then "Warning: There is another connection with the name 'con_con2'. Reference the connection by its uuid" is visible with command "nmcli con add type ethernet ifname eth con-name con_con2"


    @rhbz997998
    @connection_restricted_to_single_device
    Scenario: nmcli - connection - restriction to single device
     * Add "ethernet" connection named "con_con" for device "\*"
     * Bring "up" connection "con_con" for "eth5" device
     * Bring "up" connection "con_con" for "eth6" device
    Then "eth6" is visible with command "nmcli -f GENERAL.DEVICES connection show con_con"
    Then "eth5" is not visible with command "nmcli -f GENERAL.DEVICES connection show con_con"


    @rhbz1094296
    @connection_secondaries_restricted_to_vpn
    Scenario: nmcli - connection - restriction to single device
     * Add "ethernet" connection named "con_con" for device "\*"
     * Add "ethernet" connection named "con_con2" for device "eth5"
     * Open editor for connection "con_con"
     * Submit "set connection.secondaries con_con2" in editor
    Then Error type "is not a VPN connection profile" shown in editor


    @rhbz1108167
    @connection_removal_of_disapperared_device
    Scenario: nmcli - connection - remove connection of nonexisting device
     * Create "bridge" device named "br0"
     * Execute "ip link set dev br0 up"
     * Execute "ip addr add 192.168.201.3/24 dev br0"
     When "br0" is visible with command "nmcli -f NAME connection show --active" in "5" seconds
     * Execute "ip link del br0"
     Then "br0" is not visible with command "nmcli -f NAME connection show --active" in "5" seconds


    @connection_down
    Scenario: nmcli - connection - down
     * Add "ethernet" connection named "con_con" for device "eth5"
     * Bring "down" connection "con_con"
     Then "con_con" is not visible with command "nmcli -f NAME connection show --active"


    @connection_set_id
    Scenario: nmcli - connection - set id
     * Cleanup connection "con_con2"
     * Add "ethernet" connection named "con_con" for device "blah"
     * Open editor for connection "con_con"
     * Submit "set connection.id con_con2" in editor
     * Save in editor
     * Quit editor
     Then "con_con2" is visible with command "nmcli -f NAME con show"



    @ver+=1.18.0
    @connection_set_uuid_error
    Scenario: nmcli - connection - set uuid
    # Con_con2 is left over after reproducer_1707261
    * Cleanup connection "con_con2"
    * Add "ethernet" connection named "con_con" for device "blah"
    * Open editor for connection "con_con"
    * Submit "set connection.uuid 00000000-0000-0000-0000-000000000000" in editor
    Then Error type "uuid" shown in editor
    Then Execute reproducer "repro_1707261.py"


    @connection_set_interface-name
    Scenario: nmcli - connection - set interface-name
     * Add "ethernet" connection named "con_con" for device "blah"
     * Modify connection "con_con" changing options "connection.interface-name eth6"
     * Bring "up" connection "con_con"
     Then "con_con" is visible with command "nmcli -t -f NAME  connection show -a" in "3" seconds


    @rhbz1715887
    @ver+=1.18.4
    @restart_if_needed
    @connection_autoconnect_yes
    Scenario: nmcli - connection - set autoconnect on
     * Add "ethernet" connection named "con_con" for device "eth6" with options
           """
           connection.autoconnect no
           connection.autoconnect-retries 3
           """
     * Modify connection "con_con" changing options "connection.autoconnect '' connection.autoconnect-retries ''"
     * Reboot
     Then "con_con" is visible with command "nmcli -t -f NAME  connection show -a" in "3" seconds
     Then "-1 \(default\)" is visible with command "nmcli -f connection.autoconnect-retries con show con_con" in "3" seconds


    @rhbz1401515
    @ver+=1.10
    @connection_autoconnect_yes_without_immediate_effects
    Scenario: nmcli - connection - set autoconnect on without autoconnecting
     * Add "ethernet" connection named "con_con2" for device "eth5" with options "autoconnect no"
     When "con_con2" is visible with command "nmcli con"
     * Execute "/usr/bin/python3l contrib/reproducers/repro_1401515.py" without waiting for process to finish
     Then "yes" is visible with command "nmcli connection show con_con2 |grep autoconnect:" in "5" seconds
     Then "con_con" is not visible with command "nmcli -t -f NAME  connection show -a" in "3" seconds


    #@connection_autoconnect_warning
    #Scenario: nmcli - connection - autoconnect warning while saving new
    # * Cleanup connection "con_con"
    # * Open editor for new connection "con_con" type "ethernet"
    # * Save in editor
    # Then autoconnect warning is shown
    # * Enter in editor
    # * Quit editor


    @restart_if_needed
    @connection_autoconnect_no
    Scenario: nmcli - connection - set autoconnect off
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Modify connection "con_con" changing options "connection.autoconnect no"
     * Reboot
     Then "con_con" is not visible with command "nmcli -t -f NAME  connection show -a" in "3" seconds


    @ver+=1.7.1
    @restart_if_needed
    @keyfile_parse_options_with_comment
    Scenario: keyfile - connection - parse options with comments
     * Create keyfile "/etc/NetworkManager/system-connections/con_con.nmconnection"
      """
      [connection]
      interface-name=eth5
      type=ethernet
      autoconnect=false # foo
      device=eth5
      id=con_con

      [ipv4]
      method=dhcp
      """
     * Reload connections
     * Restart NM
     Then "con_con" is not visible with command "nmcli -t -f NAME  connection show -a" in "3" seconds


    @ver+=1.8.0
    @ver-1.51.4
    @ver/rhel/8+=1.8.0
    @ver/rhel/9+=1.8.0
    @ver/rhel/9-1.51.6
    @restart_if_needed
    @keyfile_compliant_with_kickstart
    Scenario: keyfile - connection - pykickstart compliance
    * Cleanup connection "con_con"
    * Create keyfile "/etc/NetworkManager/system-connections/con_con2.nmconnection"
      """
      [connection]
      uuid=8b4753fb-c562-4784-bfa7-f44dc6581e73
      interface-name=eth5
      autoconnect=true
      type=ethernet
      device=eth5
      id=con_con2

      [ipv4]
      address1=192.0.2.2/24,192.0.2.1
      dns=192.0.2.1
      method=manual
      """
    * Reload connections
    * Execute "nmcli con modify uuid 8b4753fb-c562-4784-bfa7-f44dc6581e73 connection.id con_con"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_con" in "45" seconds
    Then "192.0.2.2" is visible with command "ip a s eth5"
    And Check keyfile "/etc/NetworkManager/system-connections/con_con2.nmconnection" has options
      """
      connection.uuid=8b4753fb-c562-4784-bfa7-f44dc6581e73
      connection.interface-name=eth5
      connection.type=ethernet
      connection.id=con_con
      ipv4.address1=192.0.2.2/24,192.0.2.1
      ipv4.dns=192.0.2.1;
      ipv4.method=manual
      """


    @ver+=1.51.4
    @ver/rhel/10+=1.51.4.2
    @ver/rhel/8-
    @ver/rhel/9+=1.51.6
    @restart_if_needed
    @keyfile_compliant_with_kickstart
    Scenario: keyfile - connection - pykickstart compliance
    * Cleanup connection "con_con"
    * Create keyfile "/etc/NetworkManager/system-connections/con_con2.nmconnection"
      """
      [connection]
      uuid=8b4753fb-c562-4784-bfa7-f44dc6581e73
      interface-name=eth5
      autoconnect=true
      type=ethernet
      device=eth5
      id=con_con2

      [ipv4]
      address1=192.0.2.2/24,192.0.2.1
      dns=192.0.2.1
      method=manual
      """
    * Reload connections
    * Execute "nmcli con modify uuid 8b4753fb-c562-4784-bfa7-f44dc6581e73 connection.id con_con"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_con" in "45" seconds
    Then "192.0.2.2" is visible with command "ip a s eth5"
    And Check keyfile "/etc/NetworkManager/system-connections/con_con2.nmconnection" has options
      """
      connection.uuid=8b4753fb-c562-4784-bfa7-f44dc6581e73
      connection.interface-name=eth5
      connection.type=ethernet
      connection.id=con_con
      ipv4.address1=192.0.2.2/24
      ipv4.gateway=192.0.2.1
      ipv4.dns=192.0.2.1;
      ipv4.method=manual
      """


     @rhbz1367737
     @ver+=1.4.0
     @manual_connection_with_both_ips
     Scenario: nmcli - connection - add ipv4 ipv6 manual connection
     * Add "ethernet" connection named "con_con" for device "eth5" with options
           """
           ipv4.method manual
           ipv4.addresses 1.1.1.1/24
           ipv6.method manual
           ipv6.addresses 1::2/128
           """
     Then "con_con" is visible with command "nmcli con"


    @connection_timestamp
    Scenario: nmcli - connection - timestamp
     * Add "ethernet" connection named "con_con" for device "eth6" with options "autoconnect no"
     * Open editor for connection "con_con"
     When Check if object item "connection.timestamp" has value "0" via print
     * Quit editor
     * Bring "up" connection "con_con"
     * Bring "down" connection "con_con"
     * Open editor for connection "con_con"
     Then Check if object item "connection.timestamp" has value "current_time" via print
     * Quit editor


    @connection_timestamp_conn_down
    Scenario: nmcli - connection - timestamp saved on connection down
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Note the output of "nmcli -g connection.timestamp con show con_con" as value "timestamp_pre"
     * Wait for "1" seconds
     * Bring "up" connection "con_con"
     * Note the output of "nmcli -g connection.timestamp con show con_con" as value "timestamp_up"
     Then Check noted values "timestamp_pre" and "timestamp_up" are not the same
     * Wait for "5" seconds
     * Bring "down" connection "con_con"
     * Note the output of "nmcli -g connection.timestamp con show con_con" as value "timestamp_down"
     Then Check noted value "timestamp_down" difference from "timestamp_up" is "more than" "3"


    @RHEL-35539
    # Not present in the first RHEL10 NM-1.48.0-1
    @ver+=1.48.0.2
    @connection_timestamp_nm_stop
    Scenario: nmcli - connection - timestamp saved on NM stop
     * Prepare simulated test "testX" device
     * Add "ethernet" connection named "con_con" for device "testX" with options
        """
        ipv6.method disabled
        """
     When "testX\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
     * Note the output of "nmcli -g connection.timestamp con show con_con" as value "timestamp_up"
     * Wait for "4" seconds
     * Stop NM
     * Wait for "5" seconds
     # Delete interface so connection is not brought up on restart
     * Execute "ip link del dev testX"
     * Wait for "5" seconds
     * Start NM
     * Note the output of "nmcli -g connection.timestamp con show con_con" as value "timestamp_post"
     Then Check noted value "timestamp_post" difference from "timestamp_up" is "more than" "3"
     Then Check noted value "timestamp_post" difference from "timestamp_up" is "less than" "10"


    @RHEL-35539
    @ver+=1.48
    @connection_timestamp_on_restart_activation
    Scenario: nmcli - connection - activation order by timestamp after restart
     * Add "ethernet" connection named "con_con1" for device "eth6"
     * Add "ethernet" connection named "con_con2" for device "eth6"
     * Bring "up" connection "con_con1"
     When "con_con1" is visible with command "nmcli con show --active" in "5" seconds
     * Wait for "2" seconds
     * Bring "up" connection "con_con2"
     When "con_con2" is visible with command "nmcli con show --active" in "5" seconds
     * Restart NM
     When "con_con2" is visible with command "nmcli con show --active" in "5" seconds


    @connection_readonly_timestamp
    Scenario: nmcli - connection - readonly timestamp
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     * Submit "set connection.timestamp 1372338021" in editor
     Then Error type "timestamp" shown in editor
     When Quit editor


    @connection_readonly_yes
    Scenario: nmcli - connection - readonly read-only
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     * Submit "set connection.read-only yes" in editor
     Then Error type "read-only" shown in editor


    @connection_readonly_type
    Scenario: nmcli - connection - readonly type
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     * Submit "set connection.type 802-3-ethernet" in editor
     Then Error type "type" shown in editor


    @eth6_disconnect
    @connection_permission_to_user
    Scenario: nmcli - connection - permissions to user
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     * Submit "set connection.permissions test" in editor
     * Save in editor
     * Check if object item "connection.permissions" has value "user:test" via print
     * Quit editor
     #* Prompt is not running
     * Bring "up" connection "con_con"
     * Open editor for connection "con_con"
    Then Check if object item "connection.permissions" has value "user:test" via print
     * Quit editor
    Then "test" is visible with command "cat test /etc/NetworkManager/system-connections/con_con.nmconnection"


    @firewall
    @connection_zone_drop_to_public
    Scenario: nmcli - connection - zone to drop and public
     * Add "ethernet" connection named "con_con" for device "eth6" with options
           """
           ipv4.method manual
           ipv4.addresses 192.168.122.253
           connection.zone drop
           """
     * Bring "up" connection "con_con"
     When "eth6" is visible with command "firewall-cmd --zone=drop --list-all"
     * Modify connection "con_con" changing options "connection.zone ''"
     * Bring "up" connection "con_con"
     Then "eth6" is visible with command "firewall-cmd --zone=public --list-all"


     @rhbz1366288
     @ver+=1.4.0
     @firewall @restart_if_needed
     @firewall_zones_restart_persistence
     Scenario: nmcli - connection - zone to drop and public
      * Add "ethernet" connection named "con_con" for device "eth5"
      When "public(\s+[(]default[)])?\s+interfaces: eth0 eth5" is visible with command "firewall-cmd --get-active-zones" in "10" seconds
      * Execute "nmcli c modify con_con connection.zone internal"
      When "internal\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "systemctl restart firewalld"
      When "internal\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Restart NM
      When "internal\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "nmcli c modify con_con connection.zone trusted"
      When "trusted\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "systemctl restart firewalld"
      When "trusted\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "nmcli c modify con_con connection.zone work"
      Then "work\s+interfaces: eth5" is visible with command "firewall-cmd --get-active-zones"
       And "public(\s+[(]default[)])?\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"


    @rhbz663730
    @restart_if_needed
    @profile_priorities
    Scenario: nmcli - connection - profile priorities
     * Add "ethernet" connection named "con_con2" for device "eth6" with options "connection.autoconnect-priority 2"
     * Add "ethernet" connection named "con_con" for device "eth6" with options "connection.autoconnect-priority 1"
     * Disconnect device "eth6"
     * Restart NM
     Then "con_con2" is visible with command "nmcli con show -a" in "5" seconds


    # NM_METERED_UNKNOWN    = 0,
    # NM_METERED_YES        = 1,
    # NM_METERED_NO         = 2,
    # NM_METERED_GUESS_YES  = 3,
    # NM_METERED_GUESS_NO   = 4,


    @rhbz1200452
    @eth0
    @connection_metered_manual_yes
    Scenario: nmcli - connection - metered manual yes
     * Add "ethernet" connection named "con_con" for device "eth5" with options "connection.metered true"
     Then "eth5:connected:con_con" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then Metered status is "1"


    @rhbz1200452
    @eth0
    @connection_metered_manual_no
    Scenario: nmcli - connection - metered manual no
     * Add "ethernet" connection named "con_con" for device "eth5" with options "connection.metered false"
     Then "eth5:connected:con_con" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then Metered status is "2"


    @rhbz1200452
    @eth0
    @connection_metered_guess_no
    Scenario: NM - connection - metered guess no
     * Add "ethernet" connection named "con_con" for device "eth5" with options "connection.metered unknown"
     Then "eth5:connected:con_con" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then Metered status is "4"


    @rhbz1200452
    @eth0
    @connection_metered_guess_yes
    Scenario: NM - connection - metered guess yes
     * Prepare simulated test "testXc" device with "192.168.99" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix and dhcp option "43,ANDROID_METERED"
     * Add "ethernet" connection named "con_con" for device "testXc" with options "autoconnect off"
     * Modify connection "con_con" changing options "connection.metered unknown"
     * Bring "up" connection "con_con"
     Then Metered status is "3" in "5" seconds


    @rhbz1200452
    @eth0
    @connection_metered_guess_yes_ipv6_disabled
    Scenario: NM - connection - metered guess yes
     * Prepare simulated test "testXc" device with "192.168.99" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix and dhcp option "43,ANDROID_METERED"
     * Add "ethernet" connection named "con_con" for device "testXc" with options
           """
           autoconnect off
           ipv6.method disabled
           """
     * Modify connection "con_con" changing options "connection.metered unknown"
     * Bring "up" connection "con_con"
     Then Metered status is "3"


     @long
     @display_allowed_values
     Scenario: nmcli - connection - showing allowed values
     * Add "ethernet" connection named "con_con" for device "testXc"
     * Open editor for connection "con_con"
     * Check "fast|leap|md5|peap|pwd|sim|tls|ttls" are shown for object "802-1x.eap"
     * Check "0|1" are shown for object "802-1x.phase1-peapver"
     * Check "0|1" are shown for object "802-1x.phase1-peaplabel"
     * Check "0|1|2|3" are shown for object "802-1x.phase1-fast-provisioning"
     * Check "chap|gtc|md5|mschap|mschapv2|otp|pap|tls" are shown for object "802-1x.phase2-auth"
     * Check "gtc|md5|mschapv2|otp|tls" are shown for object "802-1x.phase2-autheap"
     * Check "fabric|vn2vn" are shown for object "dcb.app-fcoe-mode"
     * Check "auto|disabled|link-local|manual|shared" are shown for object "ipv4.method"
     * Check "auto|dhcp|ignore|link-local|manual|shared" are shown for object "ipv6.method"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.ca-cert"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.ca-path"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.private-key"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.phase2-ca-cert"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.phase2-ca-path"
     * Check "contrib|nmci|README|prepare|run" are shown for object "802-1x.phase2-private-key"
     * Check "broadcast_mode|ctcprot|ipato_add4|ipato_invert6|layer2|protocol|rxip_add6|vipa_add6|buffer_count|fake_broadcast|ipato_add6|isolation|portname|route4|sniffer|canonical_macaddr|inter|ipato_enable|lancmd_timeout|portno|route6|total|checksumming|inter_jumbo|ipato_invert4|large_send|priority_queueing|rxip_add4|vipa_add4" are shown for object "ethernet.s390-options"
     * Check "ctc|lcs|qeth" are shown for object "ethernet.s390-nettype"
     * Check "bond|bridge|team" are shown for object "connection.slave-type"
     * Quit editor
     * Add "bond" connection named "con-bond" for device "con-bond0"
     * Open editor for connection "con-bond"
     * Check "ad_select|arp_ip_target|downdelay|lacp_rate|mode|primary_reselect|updelay|xmit_hash_policy|arp_interval|arp_validate|fail_over_mac|miimon|primary|resend_igmp|use_carrier|" are shown for object "bond.options"
     * Quit editor
     * Add "team" connection named "con-team" for device "con-team0"
     * Open editor for connection "con-team"
     * Check "contrib|nmci|README|prepare|run" are shown for object "team.config"
     * Check "contrib|nmci|README|prepare|run" are shown for object "team-port.config"
     * Quit editor
     * Add "wifi" connection named "con-wifi" for device "wifi" with options "autoconnect off ssid con-wifi"
     * Open editor for connection "con-wifi"
     * Check "adhoc|ap|infrastructure" are shown for object "wifi.mode"
     * Check "a|bg" are shown for object "wifi.band"
     * Check "ieee8021x|none|wpa-eap|wpa-psk\s+" are shown for object "wifi-sec.key-mgmt"
     * Check "leap|open|shared" are shown for object "wifi-sec.auth-alg"
     * Check "rsn|wpa" are shown for object "wifi-sec.proto"
     * Check "ccmp|tkip" are shown for object "wifi-sec.pairwise"
     * Check "ccmp|tkip|wep104|wep40" are shown for object "wifi-sec.group"
     * Quit editor
     * Add "infiniband" connection named "con_con2" for device "mlx4_ib1"
     * Open editor for connection "con_con2"
     * Check "connected|datagram" are shown for object "infiniband.transport-mode"
     * Quit editor


    @rhbz1142898
    @ver+=1.4.0
    @tcpreplay
    @lldp
    Scenario: nmcli - connection - lldp
     * Prepare simulated test "testXc" device
     * Add "ethernet" connection named "con_con" for device "testXc" with options
           """
           ipv4.method manual
           ipv4.addresses 1.2.3.4/24
           connection.lldp enable
           """
     When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
     * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/lldp.detailed.pcap"
     Then "NEIGHBOR\[0\].DEVICE:\s+testXc" is visible with command "nmcli device lldp" in "5" seconds
      And "NEIGHBOR\[0\].CHASSIS-ID:\s+00:01:30:F9:AD:A0" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-ID:\s+1\/1" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-DESCRIPTION:\s+Summit300-48-Port 1001" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-NAME:\s+Summit300-48" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-DESCRIPTION:\s+Summit300-48 - Version 7.4e.1 \(Build 5\) by Release_Master 05\/27\/05 04:53:11" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-CAPABILITIES:\s+20 \(mac-bridge,router\)" is visible with command "nmcli device lldp"


    @rhbz1652210
    @ver+=1.16.0
    @tcpreplay
    @lldp_vlan_name_overflow
    Scenario: nmcli - connection - lldp vlan name overflow
    * Prepare simulated test "testXc" device
    * Add "ethernet" connection named "con_con" for device "testXc" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.lldp enable
          """
    When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
    * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/lldp.vlan.pcap"
    Then "NEIGHBOR\[0\].IEEE-802-1-VLAN-NAME:\s+default\s" is visible with command "nmcli --fields all device lldp" in "5" seconds


    @rhbz2295734 @RHEL-46200
    @ver+=1.49.4
    @ver+=1.48.9
    @ver+=1.46.3
    @ver+=1.44.5
    @ver+=1.42.9
    @ver+=1.40.19
    @ver/rhel/9/4+=1.46.0.18
    @tcpreplay
    @lldp_malformed_chasis_crash
    Scenario: nmcli - connection - lldp vlan name overflow
    * Prepare simulated test "testXc" device
    * Add "ethernet" connection named "con_con" for device "testXc" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.lldp enable
          """
    When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
    * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/malformed_chasis_lldp.pcpng"
    Then "testXc\s+ethernet\s+connected" is visible with command "nmcli device" for full "5" seconds


    @rhbz1652211
    @ver+=1.18.0
    @tcpreplay
    @lldp_vlan_tlv
    Scenario: NM - connection - lldp check vlan tvl values via DBus
    * Prepare simulated test "testXc" device
    * Add "ethernet" connection named "con_con" for device "testXc" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.lldp enable
          """
    When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
    * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/lldp.vlan.pcap"
    # check the deffinition of the step for more details about syntax
    Then Check ":ieee-802-1-vid=0,:ieee-802-3-max-frame-size=1514,:ieee-802-1-vlan-name='default',:ieee-802-1-pvid=0" in LldpNeighbors via DBus for device "testXc"
     And Check ":ieee-802-1-vlans::name='default',:ieee-802-1-vlans::vid=0,:ieee-802-1-vlans::name='jbenc',:ieee-802-1-vlans::vid=99" in LldpNeighbors via DBus for device "testXc"
     And Check ":ieee-802-3-mac-phy-conf:pmd-autoneg-cap=32768,:ieee-802-3-mac-phy-conf:autoneg=0,:ieee-802-3-mac-phy-conf:operational-mau-type=0" in LldpNeighbors via DBus for device "testXc"


    @RHEL-1418 @RHEL-31766 @RHEL-31764
    @ver/rhel/9/4+=1.46.0.5
    @ver/rhel/9/2+=1.42.2.16
    @ver+=1.47.2
    @tcpreplay @openvswitch
    @lldp_with_ovs
    Scenario: nmcli - connection - lldp with ovs
     * Prepare simulated test "testXc" device
     * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
     * Add "ovs-port" connection named "ovs-port1" for device "port1" with options "conn.master ovsbridge0"
     * Add "ethernet" connection named "con_con" for device "testXc" with options
           """
           connection.master port1
           connection.slave-type ovs-port
           connection.lldp enable
           """
     When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
     * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/lldp.detailed.pcap"
     Then "NEIGHBOR\[0\].DEVICE:\s+testXc" is visible with command "nmcli device lldp" in "5" seconds
      And "NEIGHBOR\[0\].CHASSIS-ID:\s+00:01:30:F9:AD:A0" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-ID:\s+1\/1" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-DESCRIPTION:\s+Summit300-48-Port 1001" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-NAME:\s+Summit300-48" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-DESCRIPTION:\s+Summit300-48 - Version 7.4e.1 \(Build 5\) by Release_Master 05\/27\/05 04:53:11" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-CAPABILITIES:\s+20 \(mac-bridge,router\)" is visible with command "nmcli device lldp"


    @rhbz1832273
    @ver+=1.32
    @tcpreplay
    @lldp_status_flag_libnm
    Scenario: nmcli - connection - lldp check status flag via libnm
    * Prepare simulated test "testXc" device
    * Add "ethernet" connection named "con_con" for device "testXc" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.lldp enable
          """
    When "testXc\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
    * Execute "ip netns exec testXc_ns tcpreplay --intf1=testXcp contrib/pcap/lldp.detailed.pcap"
    Then Check "testXc" device LLDP status flag via libnm


    @rhbz1417292
    @eth5_disconnect
    @introspection_active_connection
    Scenario: introspection - check active connections
     * Execute "/usr/bin/python3l contrib/gi/network_check.py testeth5 > /tmp/test"
     When "testeth5" is visible with command "nmcli con s -a"
     Then "Active connections before: 1" is visible with command "cat /tmp/test"
      And "Active connections after: 2.*Active connections after: 2" is visible with command "cat /tmp/test"


    @rhbz1421429
    @ver+=1.8.0
    @connection_user_settings_data
    Scenario: NM - connection - user settings data
    * Add "ethernet" connection named "con_con" for device "testXc" with options "autoconnect no"
    * Execute "/usr/bin/python3l contrib/gi/setting-user-data.py set id con_con my.own.data good_morning_starshine"
    * Execute "/usr/bin/python3l contrib/gi/setting-user-data.py set id con_con my.own.data.two the_moon_says_hello"
    When "good_morning_starshine" is visible with command "/usr/bin/python3l contrib/gi/setting-user-data.py get id con_con my.own.data"
     And "the_moon_says_hello" is visible with command "/usr/bin/python3l contrib/gi/setting-user-data.py get id con_con my.own.data.two"
    * Execute "/usr/bin/python3l contrib/gi/setting-user-data.py set id con_con -d my.own.data"
    * Execute "/usr/bin/python3l contrib/gi/setting-user-data.py set id con_con -d my.own.data.two"
    Then "[none]|[0]" is visible with command "/usr/bin/python3l contrib/gi/setting-user-data.py id con_con"
     And "\"my.own.data\" = \"good_morning_starshine\"|\"my.own.data.two\" = \"the_moon_says_hello\"" is not visible with command "/usr/bin/python3l contrib/gi/setting-user-data.py id con_con" in "5" seconds


    @rhbz1448165
    @eth5_disconnect
    @connection_track_external_changes
    Scenario: NM - connection - track external changes
     * Execute "ip add add 192.168.1.2/24 dev eth5"
    Then "192.168.1.2/24" is visible with command "nmcli con sh eth5 |grep IP4" in "2" seconds


    @ver-1.49.3
    @ver-1.48.8
    @connection_describe
    Scenario: nmcli - connection - describe
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     Then Check "\[id\]|\[uuid\]|\[interface-name\]|\[type\]" are present in describe output for object "connection"
     * Submit "goto connection" in editor

     Then Check "=== \[id\] ===\s+\[NM property description\]\s+A human readable unique identifier for the connection, like \"Work Wi-Fi\" or \"T-Mobile 3G\"." are present in describe output for object "id"

     Then Check regex "=== \[uuid\] ===\s+\[NM property description\]\s+((A universally unique identifier for the connection, for example generated with libuuid.  It should be assigned when the connection is created, and never changed as long as the connection still applies to the same network.  For example, it should not be changed when the \"id\" property or NMSettingIP4Config changes, but might need to be re-created when the Wi-Fi SSID, mobile broadband network provider, or \"type\" property changes. The UUID must be in the format \"2815492f-7e56-435e-b2e9-246bd7cdc664\" \(ie, contains only hexadecimal characters and \"-\"\).)|(The connection.uuid is the real identifier of a profile..*))" in describe output for object "uuid"

     Then Check "=== \[interface-name\] ===\s+\[NM property description\]\s+The name of the network interface this connection is bound to. If not set, then the connection can be attached to any interface of the appropriate type \(subject to restrictions imposed by other settings\). For software devices this specifies the name of the created device. For connection types where interface names cannot easily be made persistent \(e.g. mobile broadband or USB Ethernet\), this property should not be used. Setting this property restricts the interfaces a connection can be used with, and if interface names change or are reordered the connection may be applied to the wrong interface." are present in describe output for object "interface-name"

     Then Check "=== \[type\] ===\s+\[NM property description\]\s+Base type of the connection. For hardware-dependent connections, should contain the setting name of the hardware-type specific setting \(ie, \"802\-3\-ethernet\" or \"802\-11\-wireless\" or \"bluetooth\", etc\), and for non-hardware dependent connections like VPN or otherwise, should contain the setting name of that setting type \(ie, \"vpn\" or \"bridge\", etc\)." are present in describe output for object "type"

     Then Check "=== \[autoconnect\] ===\s+\[NM property description\]\s+Whether or not the connection should be automatically connected by NetworkManager when the resources for the connection are available. TRUE to automatically activate the connection, FALSE to require manual intervention to activate the connection." are present in describe output for object "autoconnect"

     Then Check "=== \[timestamp\] ===\s+\[NM property description\]\s+The time, in seconds since the Unix Epoch, that the connection was last _successfully_ fully activated. NetworkManager updates the connection timestamp periodically when the connection is active to ensure that an active connection has the latest timestamp. The property is only meant for reading \(changes to this property will not be preserved\)." are present in describe output for object "timestamp"

     Then Check "=== \[zone\] ===\s+\[NM property description\]\s+The trust level of a the connection.  Free form case-insensitive string \(for example \"Home\", \"Work\", \"Public\"\).  NULL or unspecified zone means the connection will be placed in the default zone as defined by the firewall." are present in describe output for object "zone"

     Then Check "=== \[master\] ===\s+\[NM property description\]\s+Interface name of the master device or UUID of the master connection" are present in describe output for object "master"

     Then Check "=== \[slave-type\] ===\s+\[NM property description\]\s+Setting name of the device type of this slave's master connection \(eg, \"bond\"\), or NULL if this connection is not a slave." are present in describe output for object "slave-type"

     Then Check "=== \[secondaries\] ===\s+\[NM property description\]\s+List of connection UUIDs that should be activated when the base connection itself is activated. Currently.* only VPN connections are supported." are present in describe output for object "secondaries"

     Then Check "=== \[gateway-ping-timeout\] ===\s+\[NM property description]\s+If greater than zero, delay success of IP addressing until either the timeout is reached, or an IP gateway replies to a ping." are present in describe output for object "gateway-ping-timeout"


    @RHEL-33368
    @ver+=1.49.3
    @ver+=1.48.8
    @connection_describe
    Scenario: nmcli - connection - describe
     * Add "ethernet" connection named "con_con" for device "eth6"
     * Open editor for connection "con_con"
     Then Check "\[id\]|\[uuid\]|\[interface-name\]|\[type\]" are present in describe output for object "connection"
     * Submit "goto connection" in editor

     Then Check "=== \[id\] ===\s+\[NM property description\]\s+A human readable unique identifier for the connection, like \"Work Wi-Fi\" or \"T-Mobile 3G\"." are present in describe output for object "id"

     Then Check regex "=== \[uuid\] ===\s+\[NM property description\]\s+((A universally unique identifier for the connection, for example generated with libuuid.  It should be assigned when the connection is created, and never changed as long as the connection still applies to the same network.  For example, it should not be changed when the \"id\" property or NMSettingIP4Config changes, but might need to be re-created when the Wi-Fi SSID, mobile broadband network provider, or \"type\" property changes. The UUID must be in the format \"2815492f-7e56-435e-b2e9-246bd7cdc664\" \(ie, contains only hexadecimal characters and \"-\"\).)|(The connection.uuid is the real identifier of a profile..*))" in describe output for object "uuid"

     Then Check "=== \[interface-name\] ===\s+\[NM property description\]\s+The name of the network interface this connection is bound to. If not set, then the connection can be attached to any interface of the appropriate type \(subject to restrictions imposed by other settings\). For software devices this specifies the name of the created device. For connection types where interface names cannot easily be made persistent \(e.g. mobile broadband or USB Ethernet\), this property should not be used. Setting this property restricts the interfaces a connection can be used with, and if interface names change or are reordered the connection may be applied to the wrong interface." are present in describe output for object "interface-name"

     Then Check "=== \[type\] ===\s+\[NM property description\]\s+Base type of the connection. For hardware-dependent connections, should contain the setting name of the hardware-type specific setting \(ie, \"802\-3\-ethernet\" or \"802\-11\-wireless\" or \"bluetooth\", etc\), and for non-hardware dependent connections like VPN or otherwise, should contain the setting name of that setting type \(ie, \"vpn\" or \"bridge\", etc\)." are present in describe output for object "type"

     Then Check "=== \[autoconnect\] ===\s+\[NM property description\]\s+Whether or not the connection should be automatically connected by NetworkManager when the resources for the connection are available. TRUE to automatically activate the connection, FALSE to require manual intervention to activate the connection." are present in describe output for object "autoconnect"

     Then Check "=== \[timestamp\] ===\s+\[NM property description\]\s+The time, in seconds since the Unix Epoch, that the connection was last _successfully_ fully activated. NetworkManager updates the connection timestamp periodically when the connection is active to ensure that an active connection has the latest timestamp. The property is only meant for reading \(changes to this property will not be preserved\)." are present in describe output for object "timestamp"

     Then Check "=== \[zone\] ===\s+\[NM property description\]\s+The trust level of a the connection.  Free form case-insensitive string \(for example \"Home\", \"Work\", \"Public\"\).  NULL or unspecified zone means the connection will be placed in the default zone as defined by the firewall." are present in describe output for object "zone"

     Then Check "=== \[master\] ===\s+\[NM property description\]\s+Interface name of the controller device or UUID of the controller connection. Deprecated 1.46. Use \"controller\" instead, this is just an alias." are present in describe output for object "master"

     Then Check "=== \[slave-type\] ===\s+\[NM property description\]\s+Setting name of the device type of this port's controller connection \(eg, \"bond\"\), or NULL if this connection is not a port. Deprecated 1.46. Use \"port-type\" instead, this is just an alias." are present in describe output for object "slave-type"

     Then Check "=== \[secondaries\] ===\s+\[NM property description\]\s+List of connection UUIDs that should be activated when the base connection itself is activated. Currently.* only VPN connections are supported." are present in describe output for object "secondaries"

     Then Check "=== \[gateway-ping-timeout\] ===\s+\[NM property description]\s+If greater than zero, delay success of IP addressing until either the timeout is reached, or an IP gateway replies to a ping." are present in describe output for object "gateway-ping-timeout"


    @ver+=1.14
    @connection_multiconnect_default_single
    Scenario: nmcli - connection - multi-connect default or single
    * Add "ethernet" connection named "con_con" for device "''" with options
          """
          autoconnect no
          connection.multi-connect default
          """
    * Bring "up" connection "con_con" for "eth5" device
    When "eth5" is visible with command "nmcli device | grep con_con"
    * Bring "up" connection "con_con" for "eth6" device
    When "eth6" is visible with command "nmcli device | grep con_con"
     And "eth5" is not visible with command "nmcli device | grep con_con"
    * Bring "down" connection "con_con"
    * Modify connection "con_con" changing options "connection.multi-connect single"
    * Bring "up" connection "con_con" for "eth5" device
    When "eth5" is visible with command "nmcli device | grep con_con"
    * Bring "up" connection "con_con" for "eth6" device
    Then "eth6" is visible with command "nmcli device | grep con_con"
     And "eth5" is not visible with command "nmcli device | grep con_con"


    @ver+=1.14
    @connection_multiconnect_manual
    Scenario: nmcli - connection - multi-connect manual up down
    * Add "ethernet" connection named "con_con" for device "''" with options
          """
          autoconnect no
          connection.multi-connect manual-multiple
          """
    * Bring "up" connection "con_con" for "eth5" device
    When "eth5" is visible with command "nmcli device | grep con_con"
     And "eth6" is not visible with command "nmcli device | grep con_con"
    * Bring "up" connection "con_con" for "eth6" device
    When "eth6" is visible with command "nmcli device | grep con_con"
     And "eth5" is visible with command "nmcli device | grep con_con"
    * Bring "down" connection "con_con"
    When "eth6" is not visible with command "nmcli device | grep con_con"
     And "eth5" is not visible with command "nmcli device | grep con_con"
    * Modify connection "con_con" changing options "connection.multi-connect multiple"
    * Bring "up" connection "con_con" for "eth5" device
    When "eth5" is visible with command "nmcli device | grep con_con"
     And "eth6" is not visible with command "nmcli device | grep con_con"
    * Bring "up" connection "con_con" for "eth6" device
    When "eth6" is visible with command "nmcli device | grep con_con"
     And "eth5" is visible with command "nmcli device | grep con_con"
    * Bring "down" connection "con_con"
    Then "eth6" is not visible with command "nmcli device | grep con_con"
     And "eth5" is not visible with command "nmcli device | grep con_con"


    @ver+=1.14
    @restart_if_needed
    @connection_multiconnect_autoconnect
    Scenario: nmcli - connection - multi-connect with autoconnect
    * Add "ethernet" connection named "con_con" for device "''" with options
          """
          connection.autoconnect yes
          connection.autoconnect-priority 0
          connection.multi-connect manual-multiple
          """
    When "eth5" is not visible with command "nmcli device | grep con_con"
     And "eth6" is not visible with command "nmcli device | grep con_con"
    * Add "ethernet" connection named "con_con2" for device "''" with options
          """
          connection.autoconnect yes
          connection.autoconnect-priority 0
          connection.multi-connect multiple
          """
    When "eth5" is visible with command "nmcli device | grep con_con2"
     And "eth6" is visible with command "nmcli device | grep con_con2"
    * Bring "down" connection "con_con2"
    Then "eth6" is not visible with command "nmcli device | grep con_con2"
     And "eth5" is not visible with command "nmcli device | grep con_con2"


    @ver+=1.14
    @restart_if_needed
    @connection_multiconnect_reboot
    Scenario: nmcli - connection - multi-connect reboot
    * Add "ethernet" connection named "con_con" for device "''" with options
          """
          connection.autoconnect yes
          connection.autoconnect-priority 0
          connection.multi-connect multiple
          match.interface-name '!eth0'
          """
    * Reboot
    Then "eth0" is not visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth1" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth2" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth3" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth4" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth5" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth6" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth7" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth8" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth9" is visible with command "nmcli device | grep ethernet | grep con_con"
     And "eth10" is visible with command "nmcli device | grep ethernet | grep con_con"

    @rhbz2039734
    @rhbz2150000
    @ver+=1.43.2
    @connection_multiconnect_autoconnect_retries
    Scenario: nmcli - connection - multiconnect autoconnect retry count per device
    * Doc: "Configuring the DHCP timeout behavior of a NetworkManager connection"
    * Prepare simulated test "testX1" device without DHCP
    * Prepare simulated test "testX2" device without DHCP
    * Prepare simulated test "testX3" device without DHCP
    * Run child "nmcli monitor"
    * Add "ethernet" connection named "con_con" for device "''" with options
          """
          connection.autoconnect yes
          connection.autoconnect-retries 2
          connection.multi-connect multiple
          ipv4.method auto
          ipv4.dhcp-timeout 10
          ipv6.method disable
          match.interface-name 'testX*'
          """
    Then Expect "testX1: connection failed" in children in "15" seconds
   
    # This covers https://bugzilla.redhat.com/show_bug.cgi?id=2039734
    Then Expect "testX1: connection failed" in children in "15" seconds
   
    # This covers https://bugzilla.redhat.com/show_bug.cgi?id=2150000
    # Do not remove even when other bug is fixed!
    Then Expect "testX1: disconnected" in children in "15" seconds
    Then "testX1" is not visible with command "nmcli dev show | grep con_con"


    @rhbz1639254
    @ver+=1.14
    @unmanage_eth @skip_str
    @connection_prefers_managed_devices
    Scenario: nmcli - connection - connection activates preferably on managed devices
    * Execute "nmcli device set eth10 managed yes"
    * Add "ethernet" connection named "con_con" for device "\*" with options "autoconnect no"
    * Bring "up" connection "con_con"
    Then "eth10" is visible with command "nmcli device | grep con_con"


    @rhbz1639254
    @ver+=1.14
    @unmanage_eth @skip_str
    @connection_no_managed_device
    Scenario: nmcli - connection - connection activates even on unmanaged device
    * Add "ethernet" connection named "con_con" for device "\*" with options "autoconnect no"
    * Bring "up" connection "con_con"
    Then "con_con" is visible with command "nmcli device"


    @rhbz1434527
    @ver+=1.14
    @connection_short_info
    Scenario: nmcli - connection - connection short info
    * Add "ethernet" connection named "con_con" for device "\*" with options "autoconnect no"
    * Note the output of "nmcli -o con show con_con"
    Then Noted value contains "connection.id"
    Then Noted value does not contain "connection.zone"
    * Note the output of "nmcli con show con_con"
    Then Noted value contains "connection.id"
    Then Noted value contains "connection.zone"


    @ver+=1.19.5
    @restart_if_needed
    @in_memory_connection_delete_on_reboot
    Scenario: nmcli - connection - in-memory connection delete on reboot
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes save no"
    Then "con_con" is visible with command "nmcli -g name connection show --active"
    * Reboot
    Then "con_con" is not visible with command "nmcli -g name connection show" in "5" seconds


    @ver+=1.19.5
    @restart_if_needed
    @in_memory_connection_restart_persistency
    Scenario: nmcli - connection - in-memory connection restart persistency
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes save no"
    Then "con_con" is visible with command "nmcli -g name connection show --active"
    * Restart NM
    Then "con_con" is visible with command "nmcli -g name connection show --active"


    @ver+=1.19.5
    @restart_if_needed
    @in_memory_connection_reload_persistency
    Scenario: nmcli - connection - in-memory connection reload persistency
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes save no"
    Then "con_con" is visible with command "nmcli -g name connection show --active"
    * Reload connections
    Then "con_con" is visible with command "nmcli -g name connection show --active"


    @ver+=1.19.5
    @all_to_in_memory_move
    Scenario: nmcli - connection - in-memory move
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "TO_DISK"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Delete connection "con_con"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist


    @ver+=1.19.5
    @all_to_in_memory_only_move
    Scenario: nmcli - connection - in-memory move only to in memory
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "TO_DISK"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Delete connection "con_con"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist


    @ver+=1.19.5
    @remove_tombed_connections
    @all_to_in_memory_detached_move
    Scenario: nmcli - connection - in-memory move detached then move to disk
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes"
    * Note the output of "nmcli -g connection.uuid con show id con_con" as value "uuid"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_ONLY"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "TO_DISK"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
     * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "TO_DISK"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds


    @ver+=1.19.5
    @remove_tombed_connections
    @in_memory_detached_delete_nmmeta
    Scenario: nmcli - connection - in-memory move detached
    * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes"
    * Note the output of "nmcli -g connection.uuid con show id con_con" as value "uuid"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
    Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Delete connection "con_con"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And Noted value "uuid" is visible with command "ls /var/run/NetworkManager/system-connections/"
    And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
    * Execute "rm -f /var/run/NetworkManager/system-connections/*.nmmeta"
    * Reload connections
    Then "con_con" is visible with command "nmcli -g name con show"
    * Delete connection "con_con"
    Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And Noted value "uuid" is not visible with command "ls /var/run/NetworkManager/system-connections/"
    And Path "/etc/NetworkManager/system-connections/con_con.nmconnection" does not exist


     @ver+=1.19.5
     @remove_tombed_connections
     @in_memory_detached_resurrect
     Scenario: nmcli - connection - in-memory move detached and then resurrect
     * Add "ethernet" connection named "con_con" for device "eth5" with options "autoconnect yes"
     * Note the output of "nmcli -g connection.uuid con show id con_con" as value "uuid"
     Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
     * Update connection "con_con" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "IN_MEMORY_DETACHED"
     Then "con_con" is visible with command "ls /var/run/NetworkManager/system-connections/"
     And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
     * Delete connection "con_con"
     Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And Noted value "uuid" is visible with command "ls /var/run/NetworkManager/system-connections/"
     And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
     * Add connection with name "con_con" and uuid "noted.uuid" using libnm with flags "TO_DISK,BLOCK_AUTOCONNECT"
     * Execute "nmcli con show id con_con > /tmp/con"
     Then "con_con" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And Noted value "uuid" is not visible with command "ls /var/run/NetworkManager/system-connections/"
     And "/etc/NetworkManager/system-connections/con_con.nmconnection" is file in "5" seconds
     * Update connection "con_con" changing options "SETTING_CONNECTION_INTERFACE_NAME:eth5" using libnm with flags "IN_MEMORY_DETACHED"


     @rhbz1763054
     @ver+=1.33
     @connection_external_dummy_interface
     Scenario: nmcli - connection - create & activate connection from external dummy interface
     * Cleanup connection "dummy1"
     * Create "dummy" device named "dummy1"
     When "unmanaged" is not visible with command "nmcli device show |grep dummy1" in "2" seconds
     * Connect device "dummy1"
     Then "dummy1" is visible with command "nmcli -g connection.interface-name connection show dummy1"
      And Check if "dummy1" is active connection


    @rhbz2059608
    @rhelver-=9 @fedoraver-=38 @ver+=1.38.0
    @copy_ifcfg
    @delete_testeth0
    @connection_nmcli_migrate
    Scenario: nmcli - connection - migrate all ifcfg profiles to keyfile
    * Reload connections
    * Execute "nmcli con migrate"
    Then "ifcfg" is not visible with command "ls /etc/sysconfig/network-scripts |grep -v readme-ifcfg"
    * Reload connections
    Then "ifcfg" is not visible with command "nmcli -f TYPE,FILENAME,NAME conn"
    * Bring "up" connection "migration_bond"
    Then "nm-bond:connected:migration_bond" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_bond-port1"
    Then "eth9:connected:migration_bond-port1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_team"
    Then "nm-team:connected:migration_team" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_team-port1"
    Then "eth4:connected:migration_team-port1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_team-port2"
    Then "eth5.80:connected:migration_team-port2" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_bridge"
    Then "nm-bridge:connected:migration_bridge" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_bridge-port1"
    Then "eth7:connected:migration_bridge-port1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    * Bring "up" connection "migration_dns"
    Then "eth3:connected:migration_dns" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhelver-=9 @fedoraver-=38 @ver+=1.43.11
    @copy_ifcfg
    @delete_testeth0
    @connection_migrate_via_config_option
    Scenario: nmcli - connection - migrate all ifcfg profiles to keyfile via configuration option
    * Reload connections
    Then "migration_bond:/etc/sysconfig/network-scripts/ifcfg-migration_bond" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_wifi:/etc/sysconfig/network-scripts/ifcfg-migration_wifi" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_team:/etc/sysconfig/network-scripts/ifcfg-migration_team" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_dns:/etc/sysconfig/network-scripts/ifcfg-migration_dns" is visible with command "nmcli -g NAME,FILENAME connection"
    * Create NM config file with content and cleanup priority "PRIORITY_CALLBACK_DEFAULT"
      """
      [main]
      migrate-ifcfg-rh=yes
      """
    * Reboot
    Then "ifcfg" is not visible with command "ls /etc/sysconfig/network-scripts |grep -v readme-ifcfg"
    Then "migration_bond:/etc/NetworkManager/system-connections/migration_bond.nmconnection" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_wifi:/etc/NetworkManager/system-connections/migration_wifi.nmconnection" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_team:/etc/NetworkManager/system-connections/migration_team.nmconnection" is visible with command "nmcli -g NAME,FILENAME connection"
    Then "migration_dns:/etc/NetworkManager/system-connections/migration_dns.nmconnection" is visible with command "nmcli -g NAME,FILENAME connection"


    @rhbz2008337
    @ver+=1.39.10
    @connection_wait-activation-delay
    Scenario: nmcli - connection - wait for 10 seconds before activating connection
    * Add "ethernet" connection named "con_con" for device "eth4" with options
      """
      autoconnect no
      connection.wait-activation-delay 10000
      """
    * Execute "nmcli connection up con_con" without waiting for process to finish
    When "activated" is not visible with command "nmcli -f GENERAL.STATE connection show con_con" for full "9" seconds
    Then "activated" is visible with command "nmcli -f GENERAL.STATE connection show con_con" in "10" seconds


    @rhbz2092323
    @ver+=1.39.12
    @eth5_disconnect
    @connection_dont_assume_settings_connection
    Scenario: nmcli - connection - do not assume active connection has a settings connection
    * Cleanup connection "team0" and device "nm-team"
    * Cleanup connection "team-slave-eth5"
    * NM is restarted within next "1" steps
    * Execute reproducer "repro_2092323.sh" with options "run" for "10" times


    @xfail
    @rhbz2177209
    @nmcli_space_in_secondaries
    Scenario: nmcli - vpn - space in secondaries
    * Add "openvpn" VPN connection named "Open VPN" for device "\*"
    * Cleanup connection "Wired 1"
    * Cleanup connection "Wired 2"
    * Execute "nmcli c add con-name 'Wired 2' ifname 'eth2' type ethernet autoconnect no"
    Then Execute "nmcli c add con-name 'Wired 1' ifname eth2 type ethernet autoconnect no connection.secondaries 'Open VPN'"
    Then Execute "nmcli c modify 'Wired 2' connection.secondaries 'Open VPN'"


    @rhbz2121451
    @ver+=1.45.3.1
    @keyfile
    @openvswitch
    @connection_with_higher_priority_active_on_reload
    Scenario: nmcli - connection - connection with higher priority is active after reload
    * Create keyfile "/etc/NetworkManager/system-connections/bond-bond0.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/bond-bond0.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/bond-port-eth1.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/bond-port-eth1.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/bond-port-eth1-port-ovs-clone.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/bond-port-eth1-port-ovs-clone.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/bond-port-eth2.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/bond-port-eth2.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/bond-port-eth2-port-ovs-clone.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/bond-port-eth2-port-ovs-clone.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/br-ex.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/br-ex.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/ovs-if-br-ex.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/ovs-if-br-ex.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/ovs-if-phys0.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/ovs-if-phys0.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/ovs-port-br-ex.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/ovs-port-br-ex.nmconnection
      """
    * Create keyfile "/etc/NetworkManager/system-connections/ovs-port-phys0.nmconnection"
      """
      ./contrib/profiles/rhbz2121451/ovs-port-phys0.nmconnection
      """
    * Reload connections
    Then "bond-port-eth1-port-ovs-clone" is visible with command "nmcli con show --active" in "10" seconds
    Then "bond-port-eth2-port-ovs-clone" is visible with command "nmcli con show --active"
    Then "bond-port-eth1 " is not visible with command "nmcli con show --active"
    Then "bond-port-eth2 " is not visible with command "nmcli con show --active"
    * Restart NM
    Then "bond-port-eth1-port-ovs-clone" is visible with command "nmcli con show --active" in "10" seconds
    Then "bond-port-eth2-port-ovs-clone" is visible with command "nmcli con show --active"
    Then "bond-port-eth1 " is not visible with command "nmcli con show --active"
    Then "bond-port-eth2 " is not visible with command "nmcli con show --active"


    @RHEL-21160
    @ver+=1.51.4
    @connection_ping_ip_addresses
    Scenario: nmcli - connection - ping ip addresses
    * Prepare simulated test "testX4" device
    * Execute "ip -n testX4_ns addr add 192.168.96.1/24 dev testX4p"
    * Run child "ip netns exec testX4_ns tcpdump -i testX4p -n -v icmp"
    * Add "ethernet" connection named "con_con" for device "testX4" with options
          """
          ipv4.addresses 192.168.96.4/24
          connection.ip-ping-addresses '192.168.99.1,192.168.96.1'
          connection.ip-ping-timeout 10
          connection.ip-ping-addresses-require-all yes
          ipv4.may-fail no
          """
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_con" in "10" seconds
    * Expect "192.168.99.1.*192.168.96.1|192.168.96.1.*192.168.99.1" in children in "5" seconds
    * Commentary
    """
    This is reported bug against selinux-policy.
    https://issues.redhat.com/browse/RHEL-83529
    Remove the following check once it starts failing.
    """
    * Expect AVC "ping.*NetworkManager"


    @RHEL-21160
    @ver+=1.51.4
    @connection_ping_ip6_addresses
    Scenario: nmcli - connection - ping ip6 addresses
    * Prepare simulated test "testX6" device
    * Execute "ip -n testX6_ns addr add 2620:dead:beef::1/64 dev testX6p"
    * Run child "ip netns exec testX6_ns tcpdump -i testX6p -n -v icmp6"
    * Add "ethernet" connection named "con_con" for device "testX6" with options
          """
          ipv6.addresses 2620:dead:beaf::6/64
          connection.ip-ping-addresses '2620:dead:beaf::1,2620:dead:beef::1'
          connection.ip-ping-timeout 10
          connection.ip-ping-addresses-require-all yes
          ipv6.may-fail no
          """
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_con" in "10" seconds
    * Expect "2620:dead:beaf::1.*2620:dead:beef::1|2620:dead:beef::1.*2620:dead:beaf::1" in children in "5" seconds
    * Commentary
    """
    This is reported bug against selinux-policy.
    https://issues.redhat.com/browse/RHEL-83529
    Remove the following check once it starts failing.
    """
    * Expect AVC "ping.*NetworkManager"


    @RHEL-21160
    @ver+=1.51.4
    @connection_ping_ip_addresses_unreachable
    Scenario: nmcli - connection - ping ip addresses
    * Prepare simulated test "testX4" device
    * Execute "ip -n testX4_ns addr add 192.168.96.1/24 dev testX4p"
    * Run child "ip netns exec testX4_ns tcpdump -i testX4p -n -v icmp"
    * Add "ethernet" connection named "con_con" for device "testX4" with options
          """
          ipv4.addresses 192.168.96.4/24
          connection.ip-ping-addresses '192.168.99.1,192.168.96.5'
          connection.ip-ping-timeout 10
          connection.ip-ping-addresses-require-all yes
          ipv4.may-fail no
          """
    Then Fail up connection "con_con" in "10" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_con" in "20" seconds
    * Expect "192.168.99.1" in children in "5" seconds
    * Do not expect "192.168.96.5" in children in "1" seconds
    * Commentary
    """
    This is reported bug against selinux-policy.
    https://issues.redhat.com/browse/RHEL-83529
    Remove the following check once it starts failing.
    """
    * Expect AVC "ping.*NetworkManager"


    @RHEL-58397
    @ver+=1.51.3
    @ver/rhel/9/5+=1.48.10.3
    @connection_with_empty_sriov_vfs
    Scenario: NM - connection - activate ethernet connection with empty SR-IOV VFS
    * Add "ethernet" connection named "con_con" for device "eth4" with options
      """
      autoconnect no
      sriov.vfs ""
      """
    Then Bring "up" connection "con_con"


    @RHEL-77157
    @ver+=1.52
    @keyfile
    @connection_change_name_with_incorrect_selinux_label
    Scenario: NM - connection - change connection name of the connection with incorrect selinux label
    * Add "dummy" connection named "dummy1" for device "dummy1"
    * Cleanup execute "rm -f /etc/NetworkManager/system-connections/dummy*.nmconnection; nmcli con reload"
    * Execute "chcon -t etc_t /etc/NetworkManager/system-connections/dummy1.nmconnection"
    * Reload connections
    * Commentary
    """
    The following step should not crash.
    """
    Then "Error" is visible with command "nmcli c mod id dummy1 connection.id dummy2"
    Then "dummy1" is visible with command "nmcli c"
    Then "dummy2" is not visible with command "nmcli c"
    * Commentary
    """
    Expect AVC not to fail after scenario.
    """
    Then Expect AVC "NetworkManager.*dummy1"
