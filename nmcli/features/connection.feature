Feature: nmcli: connection

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
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


    @con
    @connection_names_autocompletion
    Scenario: nmcli - connection - names autocompletion
    Then "testeth0" is visible with tab after "nmcli connection edit id "
    Then "testeth6" is visible with tab after "nmcli connection edit id "
    Then "connie" is not visible with tab after "nmcli connection edit id "
    * Add connection type "ethernet" named "connie" for device "eth1"
    Then "connie" is visible with tab after "nmcli connection edit "
    Then "connie" is visible with tab after "nmcli connection edit id "


    @rhbz1375933
    @con
    @device_autocompletion
    Scenario: nmcli - connection - device autocompletion
    Then "eth0|eth1|eth10" is visible with tab after "nmcli connection add type ethernet ifname "


    @rhbz1367736
    @con
    @connection_objects_autocompletion
    Scenario: nmcli - connection - objects autocompletion
    Then "ipv4.dad-timeout" is visible with tab after "nmcli  connection add type bond -- ipv4.method manual ipv4.addresses 1.1.1.1/24 ip"


    @rhbz1301226
    @ver+=1.4.0
    @con
    @802_1x_objects_autocompletion
    Scenario: nmcli - connection - 802_1x objects autocompletion
    * "802.1x" is visible with tab after "nmcli  connection add type ethernet ifname eth1 con-name ethie 802-"
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name connie 802-1x.identity jdoe 802-1x.eap leap"
    Then "802-1x.eap:\s+leap\s+802-1x.identity:\s+jdoe" is visible with command "nmcli con show connie"


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


    @con
    @connection_delete_while_editing
    Scenario: nmcli - connection - delete opened connection
     * Add connection type "ethernet" named "connie" for device "eth1"
     * Open editor for "connie" with timeout
     * Delete connection "connie" and hit Enter


    @rhbz1168657
    @con
    @connection_double_delete
    Scenario: nmcli - connection - double delete
     * Add connection type "ethernet" named "connie" for device "*"
     * Delete connection "connie connie"


    @rhbz1171751
    @teardown_testveth @con
    @connection_profile_duplication
    Scenario: nmcli - connection - profile duplication
     * Prepare simulated test "testX" device
     * Add a new connection of type "ethernet" and options "ifname testX con-name connie autoconnect no"
     * Execute "echo 'NM_CONTROLLED=no' >> /etc/sysconfig/network-scripts/ifcfg-connie"
     * Execute "nmcli con reload"
     * Execute "rm -f /etc/sysconfig/network-scripts/ifcfg-connie"
     * Add a new connection of type "ethernet" and options "ifname eth1 con-name connie autoconnect no"
     * Execute "nmcli con reload"
     Then "1" is visible with command "nmcli c |grep connie |wc -l"
     * Bring "up" connection "connie"


    @rhbz1174164
    @add_testeth1
    @connection_veth_profile_duplication
    Scenario: nmcli - connection - veth - profile duplication
    * Connect device "eth1"
    * Connect device "eth1"
    * Connect device "eth1"
    * Delete connection "testeth1"
    * Connect device "eth1"
    * Connect device "eth1"
    * Connect device "eth1"
    Then "1" is visible with command "nmcli connection |grep ^eth1 |wc -l"


    @rhbz997998
    @con
    @connection_restricted_to_single_device
    Scenario: nmcli - connection - restriction to single device
     * Add connection type "ethernet" named "connie" for device "*"
     * Start generic connection "connie" for "eth1"
     * Start generic connection "connie" for "eth2"
    Then "eth2" is visible with command "nmcli -f GENERAL.DEVICES connection show connie"
    Then "eth1" is not visible with command "nmcli -f GENERAL.DEVICES connection show connie"


    @rhbz1094296
    @con @time
    @connection_secondaries_restricted_to_vpn
    Scenario: nmcli - connection - restriction to single device
     * Add connection type "ethernet" named "connie" for device "*"
     * Add connection type "ethernet" named "time" for device "time"
     * Open editor for connection "connie"
     * Submit "set connection.secondaries time" in editor
    Then Error type "is not a VPN connection profile" shown in editor


    @rhbz1108167
    @BBB
    @connection_removal_of_disapperared_device
    Scenario: nmcli - connection - remove connection of nonexisting device
     * Finish "sudo ip link add name BBB type bridge"
     * Finish "ip link set dev BBB up"
     * Finish "ip addr add 192.168.201.3/24 dev BBB"
     When "BBB" is visible with command "nmcli -f NAME connection show --active" in "5" seconds
     * Finish "sudo ip link del BBB"
     Then "BBB" is not visible with command "nmcli -f NAME connection show --active" in "5" seconds


    @con
    @connection_down
    Scenario: nmcli - connection - down
     * Add connection type "ethernet" named "connie" for device "eth1"
     * Bring "up" connection "connie"
     * Bring "down" connection "connie"
     Then "connie" is not visible with command "nmcli -f NAME connection show --active"


    @con
    @connection_set_id
    Scenario: nmcli - connection - set id
     * Add connection type "ethernet" named "connie" for device "blah"
     * Open editor for connection "connie"
     * Submit "set connection.id after_rename" in editor
     * Save in editor
     * Quit editor
     * Prompt is not running
     Then Open editor for connection "after_rename"
     * Quit editor
     * Delete connection "after_rename"


    @con
    @connection_set_uuid_error
    Scenario: nmcli - connection - set uuid
     * Add connection type "ethernet" named "connie" for device "blah"
     * Open editor for connection "connie"
     * Submit "set connection.uuid 00000000-0000-0000-0000-000000000000" in editor
     Then Error type "uuid" shown in editor


    @con
    @connection_set_interface-name
    Scenario: nmcli - connection - set interface-name
     * Add connection type "ethernet" named "connie" for device "blah"
     * Open editor for connection "connie"
     * Submit "set connection.interface-name eth2" in editor
     * Save in editor
     * Quit editor
     When Prompt is not running
     * Bring "up" connection "connie"
     Then Check if "connie" is active connection


    @veth @con
    @connection_autoconnect_yes
    Scenario: nmcli - connection - set autoconnect on
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     * Disconnect device "eth2"
     * Reboot
     Then Check if "connie" is active connection


    @con
    @connection_autoconnect_warning
    Scenario: nmcli - connection - autoconnect warning while saving new
     * Open editor for new connection "connie" type "ethernet"
     * Save in editor
     Then autoconnect warning is shown
     * Enter in editor
     * Quit editor


    @con
    @connection_autoconnect_no
    Scenario: nmcli - connection - set autoconnect off
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     * Reboot
     Then Check if "connie" is not active connection


    @ver+=1.7.1
    @con
    @ifcfg_parse_options_with_comment
    Scenario: ifcfg - connection - parse options with comments
     * Execute "echo 'DEVICE=eth1' >> /etc/sysconfig/network-scripts/ifcfg-connie"
     * Execute "echo 'NAME=connie' >> /etc/sysconfig/network-scripts/ifcfg-connie"
     * Execute "echo 'BOOTPROTO=dhcp' >> /etc/sysconfig/network-scripts/ifcfg-connie"
     * Execute "echo 'ONBOOT=no  # foo' >> /etc/sysconfig/network-scripts/ifcfg-connie"
     * Execute "nmcli con reload"
     * Restart NM
     Then Check if "connie" is not active connection


     @rhbz1367737
     @ver+=1.4.0
     @con
     @manual_connection_with_both_ips
     Scenario: nmcli - connection - add ipv4 ipv6 manual connection
     * Execute "nmcli connection add type ethernet con-name connie ifname eth1 ipv4.method manual ipv4.addresses 1.1.1.1/24 ipv6.method manual ipv6.addresses 1::2/128"
     Then "connie" is visible with command "nmcli con"


    @time
    @connection_timestamp
    Scenario: nmcli - connection - timestamp
     * Add connection type "ethernet" named "time" for device "blah"
     * Open editor for connection "time"
     * Submit "set connection.autoconnect no" in editor
     * Submit "set connection.interface-name eth2" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "time"
     When Check if object item "connection.timestamp:" has value "0" via print
     * Quit editor
     * Bring "up" connection "time"
     * Bring "down" connection "time"
     * Open editor for connection "time"
     Then Check if object item "connection.timestamp:" has value "current_time" via print
     * Quit editor
     * Delete connection "time"


    @con
    @connection_readonly_timestamp
    Scenario: nmcli - connection - readonly timestamp
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.timestamp 1372338021" in editor
     Then Error type "timestamp" shown in editor
     When Quit editor


    @con
    @connection_readonly_yes
    Scenario: nmcli - connection - readonly read-only
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.read-only yes" in editor
     Then Error type "read-only" shown in editor


    @con
    @connection_readonly_type
    Scenario: nmcli - connection - readonly type
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.type 802-3-ethernet" in editor
     Then Error type "type" shown in editor


    @con
    @connection_permission_to_user
    Scenario: nmcli - connection - permissions to user
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     * Submit "set connection.permissions test" in editor
     * Save in editor
     * Check if object item "connection.permissions:" has value "user:test" via print
     * Quit editor
     * Prompt is not running
     * Bring "up" connection "connie"
     * Open editor for connection "connie"
    Then Check if object item "connection.permissions:" has value "user:test" via print
     * Quit editor
    Then "test" is visible with command "grep test /etc/sysconfig/network-scripts/ifcfg-connie"


    @con @firewall
    @connection_zone_drop_to_public
    Scenario: nmcli - connection - zone to drop and public
     * Add connection type "ethernet" named "connie" for device "eth6"
     * Open editor for connection "connie"
     * Submit "set ipv4.method manual" in editor
     * Submit "set ipv4.addresses 192.168.122.253" in editor
     * Submit "set connection.zone drop" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     When "eth6" is visible with command "firewall-cmd --zone=drop --list-all"
     * Open editor for connection "connie"
     * Submit "set connection.zone" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     Then "eth6" is visible with command "firewall-cmd --zone=public --list-all"


     @rhbz1366288
     @ver+=1.4.0
     @con @firewall @restart
     @firewall_zones_restart_persistence
     Scenario: nmcli - connection - zone to drop and public
      * Add connection type "ethernet" named "connie" for device "eth1"
      When "public\s+interfaces: eth0 eth1" is visible with command "firewall-cmd --get-active-zones"
      * Execute "nmcli c modify connie connection.zone internal"
      When "internal\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "systemctl restart firewalld"
      When "internal\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * restart NM
      When "internal\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "nmcli c modify connie connection.zone home"
      When "home\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "systemctl restart firewalld"
      When "home\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"
      * Execute "nmcli c modify connie connection.zone work"
      Then "work\s+interfaces: eth1" is visible with command "firewall-cmd --get-active-zones"
       And "public\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"


    @rhbz663730
    @con @eth @connect_testeth0
    @route_priorities
    Scenario: nmcli - connection - route priorities
     * Add a new connection of type "ethernet" and options "ifname eth0 con-name ethie autoconnect no"
     * Add a new connection of type "ethernet" and options "ifname eth10 con-name connie autoconnect no"
     * Execute "nmcli con modify ethie ipv4.may-fail no"
     * Execute "nmcli con modify connie ipv4.may-fail no"
     * Bring "up" connection "ethie"
     * Bring "up" connection "connie"
     When "metric 100" is visible with command "ip r |grep default |grep eth0"
     When "metric 101" is visible with command "ip r |grep default |grep eth10"
     * Execute "nmcli con modify connie ipv4.route-metric 10"
     * Bring "up" connection "connie"
     When "metric 100" is visible with command "ip r |grep default |grep eth0"
     When "metric 10" is visible with command "ip r |grep default |grep eth10"
     * Execute "nmcli con modify connie ipv4.route-metric -1"
     * Bring "up" connection "connie"
     When "metric 100" is visible with command "ip r |grep default |grep eth0"
     When "metric 101" is visible with command "ip r |grep default |grep eth10"


    @rhbz663730
    @veth @con @eth
    @profile_priorities
    Scenario: nmcli - connection - profile priorities
     * Add connection type "ethernet" named "ethie" for device "eth10"
     * Add connection type "ethernet" named "connie" for device "eth10"
     * Execute "nmcli con modify ethie connection.autoconnect-priority 2"
     * Execute "nmcli con modify connie connection.autoconnect-priority 1"
     * Bring "up" connection "ethie"
     * Bring "up" connection "connie"
     * Disconnect device "eth10"
     * Restart NM
     Then "ethie" is visible with command "nmcli con show -a"


    # NM_METERED_UNKNOWN    = 0,
    # NM_METERED_YES        = 1,
    # NM_METERED_NO         = 2,
    # NM_METERED_GUESS_YES  = 3,
    # NM_METERED_GUESS_NO   = 4,


    @rhbz1200452
    @con @eth0
    @connection_metered_manual_yes
    Scenario: nmcli - connection - metered manual yes
     * Add connection type "ethernet" named "connie" for device "eth1"
     * Open editor for connection "connie"
     * Submit "set connection.metered true" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     Then Metered status is "1"


    @rhbz1200452
    @con @eth0
    @connection_metered_manual_no
    Scenario: nmcli - connection - metered manual no
     * Add connection type "ethernet" named "connie" for device "eth1"
     * Open editor for connection "connie"
     * Submit "set connection.metered false" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     Then Metered status is "2"


    @rhbz1200452
    @con @eth0
    @connection_metered_guess_no
    Scenario: NM - connection - metered guess no
     * Add connection type "ethernet" named "connie" for device "eth1"
     * Open editor for connection "connie"
     * Submit "set connection.metered unknown" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     Then Metered status is "4"


    @rhbz1200452
    @con @eth0
    @teardown_testveth
    @connection_metered_guess_yes
    Scenario: NM - connection - metered guess yes
     * Prepare simulated test "testX" device with "192.168.99" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix and dhcp option "43,ANDROID_METERED"
     * Add a new connection of type "ethernet" and options "ifname testX con-name connie autoconnect off"
     * Open editor for connection "connie"
     * Submit "set ipv6.method ignore" in editor
     * Submit "set connection.metered unknown" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "connie"
     Then Metered status is "3"


     @con @bond @team @wifi @eth @long
     @display_allowed_values
     Scenario: nmcli - connection - showing allowed values
     * Add connection type "ethernet" named "connie" for device "testX"
     * Open editor for connection "connie"
     * Check "fast|leap|md5|peap|pwd|sim|tls|ttls" are shown for object "802-1x.eap"
     * Check "0|1" are shown for object "802-1x.phase1-peapver"
     * Check "0|1" are shown for object "802-1x.phase1-peaplabel"
     * Check "0|1|2|3" are shown for object "802-1x.phase1-fast-provisioning"
     * Check "chap|gtc|md5|mschap|mschapv2|otp|pap|tls" are shown for object "802-1x.phase2-auth"
     * Check "gtc|md5|mschapv2|otp|tls" are shown for object "802-1x.phase2-autheap"
     * Check "fabric|vn2vn" are shown for object "dcb.app-fcoe-mode"
     * Check "auto|disabled|link-local|manual|shared" are shown for object "ipv4.method"
     * Check "auto|dhcp|ignore|link-local|manual|shared" are shown for object "ipv6.method"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.ca-cert"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.ca-path"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.private-key"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.phase2-ca-cert"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.phase2-ca-path"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "802-1x.phase2-private-key"
     * Check "broadcast_mode|ctcprot|ipato_add4|ipato_invert6|layer2|protocol|rxip_add6|vipa_add6|buffer_count|fake_broadcast|ipato_add6|isolation|portname|route4|sniffer|canonical_macaddr|inter|ipato_enable|lancmd_timeout|portno|route6|total|checksumming|inter_jumbo|ipato_invert4|large_send|priority_queueing|rxip_add4|vipa_add4" are shown for object "ethernet.s390-options"
     * Check "ctc|lcs|qeth" are shown for object "ethernet.s390-nettype"
     * Check "bond|bridge|team" are shown for object "connection.slave-type"
     * Quit editor
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Open editor for connection "bond0"
     * Check "ad_select|arp_ip_target|downdelay|lacp_rate|mode|primary_reselect|updelay|xmit_hash_policy|arp_interval|arp_validate|fail_over_mac|miimon|primary|resend_igmp|use_carrier|" are shown for object "bond.options"
     * Quit editor
     * Add connection type "team" named "team0" for device "nm-team"
     * Open editor for connection "team0"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "team.config"
     * Check "testmapper.txt|nmcli|nmtui|README|vethsetup.sh" are shown for object "team-port.config"
     * Quit editor
     * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
     * Open editor for connection "qe-open"
     * Check "adhoc|ap|infrastructure" are shown for object "wifi.mode"
     * Check "a|bg" are shown for object "wifi.band"
     * Check "ieee8021x|none|wpa-eap|wpa-none|wpa-psk\s+" are shown for object "wifi-sec.key-mgmt"
     * Check "leap|open|shared" are shown for object "wifi-sec.auth-alg"
     * Check "rsn|wpa" are shown for object "wifi-sec.proto"
     * Check "ccmp|tkip" are shown for object "wifi-sec.pairwise"
     * Check "ccmp|tkip|wep104|wep40" are shown for object "wifi-sec.group"
     * Quit editor
     * Add connection type "infiniband" named "ethie" for device "mlx4_ib1"
     * Open editor for connection "ethie"
     * Check "connected|datagram" are shown for object "infiniband.transport-mode"
     * Quit editor


    @rhbz1142898
    @ver+=1.4.0
    @con @teardown_testveth
    @lldp
    Scenario: nmcli - connection - lldp
     * Prepare simulated test "testX" device
     * Add a new connection of type "ethernet" and options "ifname testX con-name connie ipv4.method manual ipv4.addresses 1.2.3.4/24 connection.lldp enable"
     * Bring "up" connection "connie"
     When "testX\s+ethernet\s+connected" is visible with command "nmcli device" in "5" seconds
     * Execute "ip netns exec testX_ns tcpreplay --intf1=testXp tmp/lldp.detailed.pcap"
     Then "NEIGHBOR\[0\].DEVICE:\s+testX" is visible with command "nmcli device lldp" in "5" seconds
      And "NEIGHBOR\[0\].CHASSIS-ID:\s+00:01:30:F9:AD:A0" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-ID:\s+1\/1" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].PORT-DESCRIPTION:\s+Summit300-48-Port 1001" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-NAME:\s+Summit300-48" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-DESCRIPTION:\s+Summit300-48 - Version 7.4e.1 \(Build 5\) by Release_Master 05\/27\/05 04:53:11" is visible with command "nmcli device lldp"
      And "NEIGHBOR\[0\].SYSTEM-CAPABILITIES:\s+20 \(mac-bridge,router\)" is visible with command "nmcli device lldp"


    @rhbz1417292
    @eth1_disconnect
    @introspection_active_connection
    Scenario: introspection - check active connections
     * Execute "python tmp/network_test.py testeth1 > /tmp/network_test.py"
     When "testeth1" is visible with command "nmcli con s -a"
     Then "Active connections before: 1" is visible with command "cat /tmp/test"
      And "Active connections after: 2.*Active connections after: 2" is visible with command "cat /tmp/test"


    @con
    @connection_describe
    Scenario: nmcli - connection - describe
     * Add connection type "ethernet" named "connie" for device "eth2"
     * Open editor for connection "connie"
     Then Check "\[id\]|\[uuid\]|\[interface-name\]|\[type\]|\[permissions\]|\[autoconnect\]|\[timestamp\]|\[read-only\]|\[zone\]|\[master\]|\[slave-type\]|\[secondaries\]|\[gateway-ping-timeout\]" are present in describe output for object "connection"
     * Submit "goto connection" in editor

     Then Check "=== \[id\] ===\s+\[NM property description\]\s+A human readable unique identifier for the connection, like \"Work Wi-Fi\" or \"T-Mobile 3G\"." are present in describe output for object "id"

     Then Check "=== \[uuid\] ===\s+\[NM property description\]\s+A universally unique identifier for the connection, for example generated with libuuid.  It should be assigned when the connection is created, and never changed as long as the connection still applies to the same network.  For example, it should not be changed when the \"id\" property or NMSettingIP4Config changes, but might need to be re-created when the Wi-Fi SSID, mobile broadband network provider, or \"type\" property changes. The UUID must be in the format \"2815492f-7e56-435e-b2e9-246bd7cdc664\" \(ie, contains only hexadecimal characters and \"-\"\)." are present in describe output for object "uuid"

    Then Check "=== \[interface-name\] ===\s+\[NM property description\]\s+The name of the network interface this connection is bound to. If not set, then the connection can be attached to any interface of the appropriate type \(subject to restrictions imposed by other settings\). For software devices this specifies the name of the created device. For connection types where interface names cannot easily be made persistent \(e.g. mobile broadband or USB Ethernet\), this property should not be used. Setting this property restricts the interfaces a connection can be used with, and if interface names change or are reordered the connection may be applied to the wrong interface." are present in describe output for object "interface-name"

     Then Check "=== \[type\] ===\s+\[NM property description\]\s+Base type of the connection. For hardware-dependent connections, should contain the setting name of the hardware-type specific setting \(ie, \"802\-3\-ethernet\" or \"802\-11\-wireless\" or \"bluetooth\", etc\), and for non-hardware dependent connections like VPN or otherwise, should contain the setting name of that setting type \(ie, \"vpn\" or \"bridge\", etc\)." are present in describe output for object "type"

     Then Check "=== \[autoconnect\] ===\s+\[NM property description\]\s+Whether or not the connection should be automatically connected by NetworkManager when the resources for the connection are available. TRUE to automatically activate the connection, FALSE to require manual intervention to activate the connection." are present in describe output for object "autoconnect"

     Then Check "=== \[timestamp\] ===\s+\[NM property description\]\s+The time, in seconds since the Unix Epoch, that the connection was last _successfully_ fully activated. NetworkManager updates the connection timestamp periodically when the connection is active to ensure that an active connection has the latest timestamp. The property is only meant for reading \(changes to this property will not be preserved\)." are present in describe output for object "timestamp"

     Then Check "=== \[read-only\] ===\s+\[NM property description\]\s+FALSE if the connection can be modified using the provided settings service's D-Bus interface with the right privileges, or TRUE if the connection is read-only and cannot be modified." are present in describe output for object "read-only"

     Then Check "=== \[zone\] ===\s+\[NM property description\]\s+The trust level of a the connection.  Free form case-insensitive string \(for example \"Home\", \"Work\", \"Public\"\).  NULL or unspecified zone means the connection will be placed in the default zone as defined by the firewall." are present in describe output for object "zone"

     Then Check "=== \[master\] ===\s+\[NM property description\]\s+Interface name of the master device or UUID of the master connection" are present in describe output for object "master"

     Then Check "=== \[slave-type\] ===\s+\[NM property description\]\s+Setting name of the device type of this slave's master connection \(eg, \"bond\"\), or NULL if this connection is not a slave." are present in describe output for object "slave-type"

     Then Check "=== \[secondaries\] ===\s+\[NM property description\]\s+List of connection UUIDs that should be activated when the base connection itself is activated. Currently only VPN connections are supported." are present in describe output for object "secondaries"

     Then Check "=== \[gateway-ping-timeout\] ===\s+\[NM property description]\s+If greater than zero, delay success of IP addressing until either the timeout is reached, or an IP gateway replies to a ping." are present in describe output for object "gateway-ping-timeout"
