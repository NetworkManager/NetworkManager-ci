 Feature: nmcli: team

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+/-=1.4.1)
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @rhbz1257195
    @team
    @add_default_team
    Scenario: nmcli - team - add default team
     * Open editor for a type "team"
     * Submit "set team.interface-name nm-team" in editor
     * Submit "set team.connection-name nm-team" in editor
     * Save in editor
     * Enter in editor
     * Quit editor
    #Then Prompt is not running
    Then "nm-team" is visible with command "sudo teamdctl nm-team state dump"


    @team
    @ifcfg_team_slave_device_type
    Scenario: nmcli - team - slave ifcfg devicetype
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
    Then "DEVICETYPE=TeamPort" is visible with command "grep TYPE /etc/sysconfig/network-scripts/ifcfg-team0.0"


    @team
    @nmcli_novice_mode_create_team
    Scenario: nmcli - team - novice - create team
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "team" in editor
     * Expect "There .* optional"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
    Then "nm-team" is visible with command "sudo teamdctl nm-team state dump"


    @team_slaves @team
    @nmcli_novice_mode_create_team-slave_with_default_options
    Scenario: nmcli - team - novice - create team-slave with default options
     * Add connection type "team" named "team0" for device "nm-team"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "team-slave" in editor
     * Expect "Interface name"
     * Submit "eth1" in editor
     * Expect "aster"
     * Submit "nm-team" in editor
     * Expect "There .* optional"
     * Submit "no" in editor
     * Bring "up" connection "team-slave-eth1"
    Then Check slave "eth1" in team "nm-team" is "up"


    @rhbz1257237
    @team_slaves @team
    @add_two_slaves_to_team
    Scenario: nmcli - team - add slaves
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @rhbz1310435
    @ver+=1.4.0
    @team_slaves @team
    @default_config_watch
    Scenario: nmcli - team - default config watcher
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     And "eth1" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     And "eth2" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     * Bring "down" connection "team0.1"
    Then "eth1" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     And "eth2" is not visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds


    @rhbz1057494
    @team_slaves @team
    @add_team_master_via_uuid
    Scenario: nmcli - team - master via uuid
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "team0" on device "eth1" named "team0.0"
     * Bring "up" connection "team0.0"
    Then Check slave "eth1" in team "nm-team" is "up"


    @team_slaves @team
    @remove_all_slaves
    Scenario: nmcli - team - remove last slave
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Bring "up" connection "team0.0"
     * Delete connection "team0.0"
    Then Check slave "eth1" in team "nm-team" is "down"


    @rhbz1294728
    @ver+=1.1
    @team @restart @team_slaves
    @team_restart_persistence
    Scenario: nmcli - team - restart persistence
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     When "nm-team:connected:team0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     * Restart NM
     * Restart NM
     * Restart NM
     Then Check slave "eth2" in team "nm-team" is "up"
      And Check slave "eth1" in team "nm-team" is "up"
      And "team0" is visible with command "nmcli con show -a"
      And "team0.0" is visible with command "nmcli con show -a"
      And "team0.1" is visible with command "nmcli con show -a"


    @team_slaves @team
    @remove_one_slave
    Scenario: nmcli - team - remove a slave
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
     * Delete connection "team0.1"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "down"



    @team_slaves @team
    @change_slave_type_and_master
    Scenario: nmcli - connection - slave-type and master settings
     * Add connection type "team" named "team0" for device "nm-team"
     * Add connection type "ethernet" named "team0.0" for device "eth1"
     * Open editor for connection "team0.0"
     * Set a property named "connection.slave-type" to "team" in editor
     * Set a property named "connection.master" to "nm-team" in editor
     * Submit "yes" in editor
     * Submit "verify fix" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0.0"
    Then Check slave "eth1" in team "nm-team" is "up"



    @team_slaves @team
    @remove_active_team_profile
    Scenario: nmcli - team - remove active team profile
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Bring "up" connection "team0.0"
    Then Check slave "eth1" in team "nm-team" is "up"
     * Delete connection "team0"
    Then Team "nm-team" is down


    @team_slaves @team
    @disconnect_active_team
    Scenario: nmcli - team - disconnect active team
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Bring "up" connection "team0"
     * Disconnect device "nm-team"
    Then Team "nm-team" is down


    @team_slaves @team
    @team_start_by_hand_no_slaves
    Scenario: nmcli - team - start team by hand with no slaves
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Disconnect device "nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
    Then Team "nm-team" is down
     * Bring up connection "team0" ignoring error
    Then "nm-team" is visible with command "sudo teamdctl nm-team state dump"


    @rhbz1158529
    @team_slaves @team
    @team_slaves_start_via_master
    Scenario: nmcli - team - start slaves via master
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Disconnect device "nm-team"
     * Open editor for connection "team0"
     * Submit "set connection.autoconnect-slaves 1" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @team_slaves @team
    @start_team_by_hand_all_auto
    Scenario: nmcli - team - start team by hand with all auto
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Disconnect device "nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
    Then Team "nm-team" is down
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @team_slaves @team
    @team_activate
    Scenario: nmcli - team - activate
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Disconnect device "nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
    Then Team "nm-team" is down
     * Open editor for connection "team0.0"
     * Submit "activate" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Execute "sleep 3"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "down"


    @veth @team_slaves @team
    @start_team_by_hand_one_auto
    Scenario: nmcli - team - start team by hand with one auto
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0"
    Then Check slave "eth1" in team "nm-team" is "down"
    Then Check slave "eth2" in team "nm-team" is "up"


    @veth @team_slaves @team
    @start_team_on_boot
    Scenario: nmcli - team - start team on boot
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.0"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Reboot
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @veth @team_slaves @team
    @team_start_on_boot_with_nothing_auto
    Scenario: nmcli - team - start team on boot - nothing auto
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.1"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     #* Bring up connection "team0" ignoring error
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
     * Reboot
    Then Team "nm-team" is down


    #VVV    THIS IS DIFFERENT IN BOND AREA

    @veth @team_slaves @team
    @team_start_on_boot_with_one_auto_only
    Scenario: nmcli - team - start team on boot - one slave auto only
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Bring "down" connection "team0"
     * Reboot
    Then Check slave "eth2" in team "nm-team" is "up"
    Then Check slave "eth1" in team "nm-team" is "down"


    @veth @team_slaves @team
    @team_start_on_boot_with_team_and_one_slave_auto
    Scenario: nmcli - team - start team on boot - team and one slave auto
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Reboot
    Then Check slave "eth2" in team "nm-team" is "up"
    Then Check slave "eth1" in team "nm-team" is "down"


    @team_slaves @team
    @config_loadbalance
    Scenario: nmcli - team - config - set loadbalance mode
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0"
     * Submit "set team.config {\\"device\\":\"nm-team\",\"runner\":{\"name\":\"loadbalance\"},\"ports\":{\"eth1\":{},\"eth2\": {}}}" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "sudo teamdctl nm-team state dump"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @team_slaves @team
    @config_broadcast
    Scenario: nmcli - team - config - set broadcast mode
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0"
     * Submit "set team.config {    \"device\":       \"nm-team\",  \"runner\":       {\"name": \"broadcast\"},  \"ports\":        {\"eth1\": {}, \"eth2\": {}}}" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then "\"kernel_team_mode_name\": \"broadcast\"" is visible with command "sudo teamdctl nm-team state dump"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @team_slaves @team @clean @long
    @config_invalid
    Scenario: nmcli - team - config - set invalid mode
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0"
     * Submit "set team.config {\"blah\":1,\"blah\":2,\"blah\":3}" in editor
     * Save in editor
     * Quit editor
     * Bring up connection "team0" ignoring error
    Then Team "nm-team" is down


    @rhbz1270814
    @ver+=1.3.0
    @team_slaves @team @clean @long
    @config_invalid2
    Scenario: nmcli - team - config - set invalid mode
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0"
     * Submit "set team.config {\"blah\":1,\"blah\":2,\"blah\":3}" in editor
     * Save in editor
     * Quit editor
     * Bring up connection "team0" ignoring error
    Then Team "nm-team" is down
     And "connecting" is not visible with command "nmcli device"


     @rhbz1312726
     @ver+=1.4.0
     @team_slaves @team @clean @long
     @config_invalid3
     Scenario: nmcli - team - config - set invalid mode
      * Add connection type "team" named "team0" for device "nm-team"
      * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
      * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
      * Execute "nmcli connection modify team0 team.config '{ "device": "nm-team", "runner": {"name": "activebalance"}}' "
      Then "Error: Connection activation failed" is visible with command "nmcli connection up id team0"
       And Team "nm-team" is down
       And "Error: Connection activation failed" is visible with command "nmcli connection up id team0"
       And Team "nm-team" is down


     @rhbz1366300
     @ver+=1.4.0
     @team_slaves @team @clean
     @team_config_null
     Scenario: nmcli - team - config - empty string
     * Add a new connection of type "team" and options "con-name team0 ifname nm-team autoconnect no team.config "" "
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
     Then "\"kernel_team_mode_name\": \"roundrobin\"" is visible with command "sudo teamdctl nm-team state dump"
      And Check slave "eth1" in team "nm-team" is "up"
      And Check slave "eth2" in team "nm-team" is "up"


    @rhbz1255927
    @team_slaves @team
    @team_set_mtu
    Scenario: nmcli - team - set mtu
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Open editor for connection "team0.0"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0.1"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "team0"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Set a property named "ipv4.method" to "manual" in editor
     * Set a property named "ipv4.addresses" to "1.1.1.2/24" in editor
     * Save in editor
     * Quit editor
     * Disconnect device "nm-team"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"
    Then "mtu 9000" is visible with command "ip a s eth1 |grep mtu" in "25" seconds
    Then "mtu 9000" is visible with command "ip a s eth2 |grep mtu"
    Then "mtu 9000" is visible with command "ip a s nm-team |grep mtu"


    @team_slaves @team
    @remove_config
    Scenario: nmcli - team - config - remove
     * Add connection type "team" named "team0" for device "nm-team"
     * Add slave connection for master "nm-team" on device "eth1" named "team0.0"
     * Add slave connection for master "nm-team" on device "eth2" named "team0.1"
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
     * Open editor for connection "team0"
     * Submit "set team.config {\"device\":\"nm-team\",\"runner\":{\"name\":\"loadbalance\"},\"ports\":{\"eth1\":{},\"eth2\": {}}}" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "sudo teamdctl nm-team state dump"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"
     * Open editor for connection "team0"
     * Submit "set team.config" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is not visible with command "sudo teamdctl nm-team state dump"
    Then Check slave "eth1" in team "nm-team" is "up"
    Then Check slave "eth2" in team "nm-team" is "up"


    @ver-=1.1
    @dummy @teamd
    @team_reflect_changes_from_outside_of_NM
    Scenario: nmcli - team - reflect changes from outside of NM
    * Finish "systemd-run --unit teamd teamd --team-dev=team0"
    * Finish "sleep 2"
    When "team0\s+team\s+unmanaged" is visible with command "nmcli d"
    * Finish "ip link set dev team0 up"
    When "team0\s+team\s+disconnected" is visible with command "nmcli d"
    * Finish "ip link add dummy0 type dummy"
    * Finish "ip addr add 1.1.1.1/24 dev team0"
    When "team0\s+team\s+connected\s+team0" is visible with command "nmcli d" in "5" seconds
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d"
    * Finish "teamdctl team0 port add dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d"
    Then "TEAM.SLAVES:\s+dummy0" is visible with command "nmcli -f team.slaves dev show team0"


    @ver+=1.1.1
    @dummy @teamd
    @team_reflect_changes_from_outside_of_NM
    Scenario: nmcli - team - reflect changes from outside of NM
    * Finish "systemd-run --unit teamd teamd --team-dev=team0"
    * Finish "sleep 2"
    When "team0\s+team\s+unmanaged" is visible with command "nmcli d"
    * Finish "ip link set dev team0 up"
    When "team0\s+team\s+unmanaged" is visible with command "nmcli d"
    * Finish "ip link add dummy0 type dummy"
    * Finish "ip addr add 1.1.1.1/24 dev team0"
    When "team0\s+team\s+connected\s+team0" is visible with command "nmcli d" in "5" seconds
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d"
    * Finish "teamdctl team0 port add dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d"
    Then "TEAM.SLAVES:\s+dummy0" is visible with command "nmcli -f team.slaves dev show team0"


    @rhbz1145988
    @team_slaves @team
    @kill_teamd
    Scenario: NM - team - kill teamd
     * Add connection type "team" named "team0" for device "nm-team"
     * Execute "sleep 6"
     * Execute "killall -9 teamd; sleep 2"
    Then "teamd -o -n -U -D -N -t nm-team" is visible with command "ps aux|grep -v grep| grep teamd"


    @team
    @describe
    Scenario: nmcli - team - describe team
     * Open editor for a type "team"
     Then Check "<<< team >>>|=== \[config\] ===|\[NM property description\]" are present in describe output for object "team"
     Then Check "The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object "team.config"
      * Submit "g t" in editor
     Then Check "NM property description|The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object "config"
      * Submit "g c" in editor
     Then Check "The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object " "


    @rhbz1183444
    @veth @team @bridge
    @team_enslave_to_bridge
    Scenario: nmcli - team - enslave team device to bridge
     * Add a new connection of type "team" and options "con-name team0 autoconnect no ifname nm-team"
     * Add a new connection of type "bridge" and options "con-name br10 autoconnect no ifname bridge0 ip4 192.168.177.100/24 gw4 192.168.177.1"
     * Execute "nmcli connection modify id team0 connection.master bridge0 connection.slave-type bridge"
     * Bring "up" connection "team0"
    Then "bridge0:bridge:connected:br10" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
    Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


    @rhbz1303968
    @team @bridge @team_slaves
    @team_in_bridge_mtu
    Scenario: nmcli - team - enslave team device to bridge and set mtu
     * Add a new connection of type "bridge" and options "con-name bridge0 autoconnect no ifname bridge0 -- 802-3-ethernet.mtu 9000 ipv4.method manual ipv4.addresses 192.168.177.100/24 ipv4.gateway 192.168.177.1"
     * Add a new connection of type "team" and options "con-name team0 autoconnect no ifname nm-team master bridge0 -- 802-3-ethernet.mtu 9000"
     * Add a new connection of type "ethernet" and options "con-name team0.0 autoconnect no ifname eth1 master nm-team -- 802-3-ethernet.mtu 9000"
     * Add a new connection of type "ethernet" and options "con-name team0.0 autoconnect no ifname eth1 master nm-team -- 802-3-ethernet.mtu 9000"
     * Bring "up" connection "bridge0"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.0"
     Then "mtu 9000" is visible with command "ip a s eth1"
     Then "mtu 9000" is visible with command "ip a s nm-team"
     Then "mtu 9000" is visible with command "ip a s bridge0"


     @rhbz1367180
     @ver+=1.4.0
     @team @team_slaves
     @ifcfg_with_missing_devicetype
     Scenario: ifcfg - team - missing device type
     * Append "DEVICE=eth1" to ifcfg file "team0.0"
     * Append "NAME=team0.0" to ifcfg file "team0.0"
     * Append "ONBOOT=no" to ifcfg file "team0.0"
     * Append "TEAM_MASTER=nm-team" to ifcfg file "team0.0"
     * Append "DEVICE=eth2" to ifcfg file "team0.1"
     * Append "NAME=team0.1" to ifcfg file "team0.1"
     * Append "ONBOOT=no" to ifcfg file "team0.1"
     * Append "TEAM_MASTER=nm-team" to ifcfg file "team0.1"
     * Append "DEVICE=nm-team" to ifcfg file "team0"
     * Append "NAME=team0" to ifcfg file "team0"
     * Append "ONBOOT=no" to ifcfg file "team0"
     * Append "BOOTPROTO=none" to ifcfg file "team0"
     * Append "IPADDR=192.168.23.11" to ifcfg file "team0"
     * Append "NETMASK=255.255.255.0" to ifcfg file "team0"
     * Append "TEAM_CONFIG='{\"runner\": {\"name\": \"activebackup\"}, \"link_wach\": {\"name\": \"ethtool\"}}'" to ifcfg file "team0"
     * Execute "nmcli con reload"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
     Then "\"kernel_team_mode_name\": \"activebackup\"" is visible with command "sudo teamdctl nm-team state dump"
      And Check slave "eth1" in team "nm-team" is "up"
      And Check slave "eth2" in team "nm-team" is "up"


    @rhbz1286105 @rhbz1312359
    @ver+=1.4.0
    @team @team_slaves
    @team_in_vlan
    Scenario: nmcli - team - team in vlan
     * Add a new connection of type "team" and options "con-name team0 ifname nm-team autoconnect no ipv4.method manual ipv4.addresses 192.168.168.17/24 ipv4.gateway 192.168.103.1 ipv6.method manual ipv6.addresses 2168::17/64"
     * Execute "ip link set nm-team mtu 1500"
     * Add a new connection of type "vlan" and options "con-name team0.1 dev nm-team id 1 mtu 1500 autoconnect no ipv4.method manual ipv4.addresses 192.168.168.16/24 ipv4.gateway 192.168.103.1 ipv6.method manual ipv6.addresses 2168::16/64"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     When "2168::16" is visible with command "ip a s nm-team.1" in "5" seconds
      And "2168::17" is visible with command "ip a s nm-team"
      And "192.168.168.16" is visible with command "ip a s nm-team.1"
      And "192.168.168.17" is visible with command "ip a s nm-team"
     * Add a new connection of type "team-slave" and options "con-name team0.0 ifname eth10 master nm-team"
     * Bring "up" connection "team0.0"
     * Wait for at least "10" seconds
    Then "2168::16" is visible with command "ip a s nm-team.1"
     And "2168::17" is visible with command "ip a s nm-team"
     And "192.168.168.16" is visible with command "ip a s nm-team.1"
     And "192.168.168.17" is visible with command "ip a s nm-team"


    @rhbz1371126
    @ver+=1.4.0
    @team_slaves @team @teardown_testveth @restart
    @team_leave_L2_only_up_when_going_down
    Scenario: nmcli - team - leave UP with L2 only config
     * Prepare simulated test "testX" device
     * Add a new connection of type "team" and options "con-name team0 ifname nm-team autoconnect no ipv4.method disabled ipv6.method ignore"
     * Add a new connection of type "ethernet" and options "con-name team0.0 ifname testX autoconnect no connection.master nm-team connection.slave-type team"
     * Bring "up" connection "team0.0"
     When "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
      And "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team"
      And "inet6 2620" is visible with command "ip -6 a s nm-team" in "5" seconds
      And "tentative" is not visible with command "ip -6 a s nm-team" in "5" seconds
     * Execute "killall NetworkManager && sleep 5"
     * Execute "systemctl restart NetworkManager"
     When "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team" for full "10" seconds
      And "inet6 2620" is visible with command "ip -6 a s nm-team"
     * Bring "up" connection "team0.0"
     Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
      And "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team"
      And "inet6 2620" is visible with command "ip -6 a s nm-team" in "5" seconds
      And "tentative" is not visible with command "ip -6 a s nm-team" in "5" seconds
