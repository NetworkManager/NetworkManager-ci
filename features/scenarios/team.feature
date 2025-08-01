 Feature: nmcli: team

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @rhelver-=9
    @rhbz1257195
    @add_default_team
    Scenario: nmcli - team - add default team
     * Cleanup connection "team0" and device "nm-team"
     * Open editor for a type "team"
     * Submit "set connection.interface-name nm-team" in editor
     * Submit "set connection.connection-name nm-team" in editor
     * Save in editor
     * Enter in editor
     * Quit editor
    #Then Prompt is not running
     Then "ifname": "nm-team" is visible with command "teamdctl nm-team state dump"


    @rhbz1393853
    @rhelver-=9
    @ver+=1.8
    @ver-=1.40.15
    @restart_if_needed
    @add_default_team_after_journal_restart
    Scenario: nmcli - team - add default team after journal restart
     * Execute "systemctl restart systemd-journald"
     * Add "team" connection named "team0" for device "nm-team"
     Then "ifname": "nm-team" is visible with command "teamdctl nm-team state dump"


    @rhbz1393853 @rhbz2182029 @RHEL-14016
    @rhelver-=9
    # set actual build for RHEL 8.y according to RHEL-14016
    #@ver+=1.40.16.5
    @ver+=1.42.9
    @restart_if_needed
    @add_default_team_after_journal_restart
    Scenario: nmcli - team - add default team after journal restart
     * Execute "systemctl restart systemd-journald"
     * Add "team" connection named "team0" for device "nm-team"
     Then "(Failed|Error)" is not visible with command "journalctl -u NetworkManager --since '30 seconds ago' --no-pager | grep libteamdctl"
     And "ifname": "nm-team" is visible with command "teamdctl nm-team state dump"


    @rhelver-=9
    @ifcfg-rh
    @ifcfg_team_slave_device_type
    Scenario: nmcli - team - slave ifcfg devicetype
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    Then "DEVICETYPE=TeamPort" is visible with command "grep TYPE /etc/sysconfig/network-scripts/ifcfg-team0.0"


    @rhelver-=9
    @ver+=1.39.7
    @nmcli_novice_mode_create_team
    Scenario: nmcli - team - novice - create team
     * Cleanup connection "team-nm-team" and device "nm-team"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "team" in editor
     * Expect "Interface name"
     * Enter in editor
     * Expect "Team JSON configuration"
     * Enter in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     Then "ifname": "nm-team" is visible with command "teamdctl nm-team state dump" in "5" seconds


    @rhelver-=9
    @ver+=1.39.7
    @nmcli_novice_mode_create_team_slave_with_default_options
    Scenario: nmcli - team - novice - create team-slave with default options
     * Cleanup connection "team-slave" and device "eth5"
     * Add "team" connection named "team0" for device "nm-team"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "team-slave" in editor
     * Expect "Master|Controller"
     * Submit "nm-team" in editor
     * Expect "Interface name"
     * Submit "eth5" in editor
     * Expect "Team JSON configuration"
     * Enter in editor
     * Bring "up" connection "team-slave"
    Then Check slave "eth5" in team "nm-team" is "up"


    @rhbz1257237
    @rhelver-=9
    @add_two_slaves_to_team
    Scenario: nmcli - team - add slaves
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhbz1310435
    @rhelver-=9
    @ver+=1.4.0
    @team_default_config_watch
    Scenario: nmcli - team - default config watcher
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     And "eth5" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     And "eth6" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     * Bring "down" connection "team0.1"
    Then "eth5" is visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds
     And "eth6" is not visible with command "nmcli -f all d show nm-team |grep CONFIG" in "20" seconds


    @rhelver-=9
    @team_remove_all_slaves
    Scenario: nmcli - team - remove last slave
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Delete connection "team0.0"
    Then Check slave "eth5" in team "nm-team" is "down"


    @rhelver-=9
    @team_remove_one_slave
    Scenario: nmcli - team - remove a slave
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Delete connection "team0.1"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "down"


    @rhelver-=9
    @remove_active_team_profile
    Scenario: nmcli - team - remove active team profile
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
    Then Check slave "eth5" in team "nm-team" is "up"
     * Delete connection "team0"
    Then Team "nm-team" is down


    @rhelver-=9
    @disconnect_active_team
    Scenario: nmcli - team - disconnect active team
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Disconnect device "nm-team"
    Then Team "nm-team" is down


    @rhelver-=9
    @team_start_by_hand_no_slaves
    Scenario: nmcli - team - start team by hand with no slaves
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
     * Disconnect device "nm-team"
    Then Team "nm-team" is down
     * Bring "up" connection "team0" ignoring error
     Then "ifname": "nm-team" is visible with command "teamdctl nm-team state dump"


    @rhbz1158529
    @rhelver-=9
    @team_slaves_start_via_master
    Scenario: nmcli - team - start slaves via master
     * Add "team" connection named "team0" for device "nm-team" with options "connection.autoconnect-slaves 1 autoconnect no"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team autoconnect no"
     * Bring "up" connection "team0"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @start_team_by_hand_all_auto
    Scenario: nmcli - team - start team by hand with all auto
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
     * Disconnect device "nm-team"
    Then Team "nm-team" is down
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @team_activate
    Scenario: nmcli - team - activate
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "down" connection "team0.0"
     * Bring "down" connection "team0.1"
     * Disconnect device "nm-team"
    When Team "nm-team" is down
     * Open editor for connection "team0.0"
     * Submit "activate" in editor
     * Enter in editor
     * Save in editor
     * Quit editor
     * Wait for "3" seconds
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "down"


    @rhbz1386872
    @rhelver-=9
    @ver+=1.8.0
    @team_mac_spoof
    Scenario: nmcli - team - mac spoof
     * Add "team" connection named "team0" with options "ethernet.cloned-mac-address 02:02:02:02:02:02"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
     * Bring "up" connection "team0.0"
     Then "02:02:02:02:02:02" is visible with command "ip a s eth5"
      And "02:02:02:02:02:02" is visible with command "ip a s nm-team"
      And Check slave "eth5" in team "nm-team" is "up"


    @rhbz1424641
    @rhelver-=9
    @ver+=1.8.0
    @team_mac_spoof_var1
    Scenario: nmcli - team - config - mac spoof with mac in json
     * Add "team" connection named "team0" with options
        """
        team.config '{"device":"nm-team","hwaddr":  "02:03:03:03:03:03","runner":{"name":"loadbalance"},"ports":{"eth5":{},"eth6": {}}}'
        ethernet.cloned-mac-address 02:02:02:02:02:02
        """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
     * Bring "up" connection "team0.0"
    Then Check slave "eth5" in team "nm-team" is "up"
     And "02:03:03:03:03:03" is visible with command "ip a s eth5"
     And "02:03:03:03:03:03" is visible with command "ip a s nm-team"


    @rhelver-=9
    @start_team_by_hand_one_auto
    Scenario: nmcli - team - start team by hand with one auto
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team connection.autoconnect no"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0"
    Then Check slave "eth5" in team "nm-team" is "down"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @restart_if_needed
    @start_team_on_boot
    Scenario: nmcli - team - start team on boot
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Reboot
    Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
     And Check slave "eth5" in team "nm-team" is "up"
     And Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @restart_if_needed
    @team_start_on_boot_with_nothing_auto
    Scenario: nmcli - team - start team on boot - nothing auto
     * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team autoconnect no"
     * Bring "up" connection "team0.0"
     * Bring "up" connection "team0.1"
     * Reboot
    Then Team "nm-team" is down


    @rhelver-=9
    @restart_if_needed
    @team_start_on_boot_with_one_auto_only
    Scenario: nmcli - team - start team on boot - one slave auto only
     * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
    Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
     And Check slave "eth6" in team "nm-team" is "up"
     And Check slave "eth5" in team "nm-team" is "down"


    @rhelver-=9
    @restart_if_needed
    @team_start_on_boot_with_team_and_one_slave_auto
    Scenario: nmcli - team - start team on boot - team and one slave auto
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team connection.autoconnect no"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Reboot
    Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
     And Check slave "eth6" in team "nm-team" is "up"
     And Check slave "eth5" in team "nm-team" is "down"


    @rhelver-=9
    @team_config_loadbalance
    Scenario: nmcli - team - config - set loadbalance mode
     * Add "team" connection named "team0" for device "nm-team" with options
        """
        team.config '{"device":"nm-team","runner":{"name":"loadbalance"},"ports":{"eth5":{},"eth6": {}}}'
        """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @team_config_broadcast
    Scenario: nmcli - team - config - set broadcast mode
     * Add "team" connection named "team0" for device "nm-team" with options
        """
        team.config '{"device":"nm-team","runner":{"name":"broadcast"},"ports":{"eth5":{},"eth6":{}}}'
        """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
    Then "\"kernel_team_mode_name\": \"broadcast\"" is visible with command "teamdctl nm-team state dump"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhelver-=9
    @rhbz149733
    @ver+=1.10
    @not_on_veth @restart_if_needed
    @team_config_lacp
    Scenario: nmcli - team - config - set lacp mode
     * Add "team" connection named "team0" for device "nm-team" with options
           """
           config '{"runner":{"name": "lacp"}}'
           ipv4.method manual
           ipv4.address 10.0.0.1/24
           """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Restart NM
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
     And "\"runner_name\": \"lacp\"" is visible with command "teamdctl nm-team state dump"
     And Check slave "eth5" in team "nm-team" is "up"
     And Check slave "eth6" in team "nm-team" is "up"
     And "Exactly" "1" lines with pattern "team0\s+" are visible with command "nmcli device"


    @rhbz1366300
    @rhelver-=9
    @ver+=1.4.0
    @team_config_null
    Scenario: nmcli - team - config - empty string
     * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no team.config "" "
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
     Then "\"kernel_team_mode_name\": \"roundrobin\"" is visible with command "teamdctl nm-team state dump"
      And Check slave "eth5" in team "nm-team" is "up"
      And Check slave "eth6" in team "nm-team" is "up"


    @rhbz1255927
    @rhelver-=9
    @team_set_mtu
    Scenario: nmcli - team - set mtu
     * Add "team" connection named "team0" for device "nm-team" with options
        """
        802-3-ethernet.mtu 9000
        ipv4.method manual ipv4.addresses 1.1.1.2/24
        """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team 802-3-ethernet.mtu 9000"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team 802-3-ethernet.mtu 9000"
    Then "mtu 9000" is visible with command "ip a s eth5 |grep mtu" in "25" seconds
    Then "mtu 9000" is visible with command "ip a s eth6 |grep mtu"
    Then "mtu 9000" is visible with command "ip a s nm-team |grep mtu"


    @rhelver-=9
    @team_remove_config
    Scenario: nmcli - team - config - remove
     * Add "team" connection named "team0" for device "nm-team" with options
        """
        team.config '{"device":"nm-team","runner":{"name":"loadbalance"},"ports":{"eth5":{},"eth6": {}}}'
        """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"
     * Modify connection "team0" changing options "team.config "" "
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     * Bring "up" connection "team0.0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is not visible with command "teamdctl nm-team state dump"
    Then Check slave "eth5" in team "nm-team" is "up"
    Then Check slave "eth6" in team "nm-team" is "up"


    @rhbz1816202
    @rhelver-=9
    @ver+=1.25
    @teamd
    @team_reflect_changes_from_outside_of_NM
    Scenario: nmcli - team - reflect changes from outside of NM
    * Execute "systemd-run --unit teamd teamd --team-dev=team0"
    * Wait for "2" seconds
    When "team0\s+team\s+unmanaged" is visible with command "nmcli d"
    * Execute "ip link set dev team0 up"
    When "team0\s+team\s+unmanaged" is visible with command "nmcli d"
    * Create "dummy" device named "dummy0"
    * Execute "ip addr add 1.1.1.1/24 dev team0"
    When "team0\s+team\s+connected \(externally\)\s+team0" is visible with command "nmcli d" in "5" seconds
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d"
    * Execute "teamdctl team0 port add dummy0"
    When "dummy0\s+dummy\s+connected \(externally\)\s+dummy" is visible with command "nmcli d"
    Then "TEAM.SLAVES:\s+dummy0" is visible with command "nmcli -f team.slaves dev show team0"


    @rhbz1145988
    @rhelver-=9
    @kill_teamd
    Scenario: NM - team - kill teamd
     * Add "team" connection named "team0" for device "nm-team"
     * Wait for "6" seconds
     * Terminate "teamd" with signal "KILL"
    Then "teamd -o -n -U -D -N* -t nm-team" is visible with command "ps aux|grep -v grep| grep teamd" in "10" seconds


    @rhelver-=9
    @ver+=1.41.1
    @kill_teamd_with_ports
    Scenario: NM - team - kill teamd, ensure ports stay attached
     * Add "team" connection named "team0" for device "nm-team" with options "ipv4.method disabled ipv6.method disabled"
     * Add "dummy" connection named "dummy0" for device "dummy0" with options "master nm-team team-port.prio 10"
     When "connected" is visible with command "nmcli -g GENERAL.STATE dev show dummy0" in "10" seconds
     Then "\"prio\": 10" is visible with command "teamdctl nm-team port config dump dummy0"
     * Terminate "teamd"
     When "teamd -o -n -U -D -N* -t nm-team" is visible with command "ps aux|grep -v grep| grep teamd" in "10" seconds
     Then "\"prio\": 10" is visible with command "teamdctl nm-team port config dump dummy0"


    @rhelver-=9
    @team_describe
    Scenario: nmcli - team - describe team
     * Open editor for a type "team"
     Then Check "<<< team >>>|=== \[config\] ===|\[NM property description\]" are present in describe output for object "team"
     Then Check "The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object "team.config"
      * Submit "g team" in editor
     Then Check "NM property description|The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object "config"
      * Submit "g c" in editor
     Then Check "The JSON configuration for the team network interface.  The property should contain raw JSON configuration data suitable for teamd, because the value is passed directly to teamd. If not specified, the default configuration is used.  See man teamd.conf for the format details." are present in describe output for object " "


    @rhbz1183444
    @rhelver-=9
    @team_enslave_to_bridge
    Scenario: nmcli - team - enslave team device to bridge
     * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no"
     * Add "bridge" connection named "team_br" for device "brA" with options
           """
           autoconnect no
           ip4 192.168.177.100/24
           gw4 192.168.177.1
           """
     * Modify connection "team0" changing options "connection.master brA connection.slave-type bridge"
     * Bring "up" connection "team0"
    Then "brA:bridge:connected:team_br" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
    Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


    @rhbz1303968
    @rhelver-=9
    @team_in_bridge_mtu
    Scenario: nmcli - team - enslave team device to bridge and set mtu
     * Add "bridge" connection named "team_br" for device "brA" with options
           """
           autoconnect no
           -- 802-3-ethernet.mtu 9000
           ipv4.method manual
           ipv4.addresses 192.168.177.100/24
           ipv4.gateway 192.168.177.1
           """
     * Add "team" connection named "team0" for device "nm-team" with options
           """
           autoconnect no
           master brA
           -- 802-3-ethernet.mtu 9000
           """
     * Add "ethernet" connection named "team0.0" for device "eth5" with options
           """
           autoconnect no
           master nm-team
           -- 802-3-ethernet.mtu 9000
           """
     * Bring "up" connection "team_br"
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.0"
     Then "mtu 9000" is visible with command "ip a s eth5"
     Then "mtu 9000" is visible with command "ip a s nm-team"
     Then "mtu 9000" is visible with command "ip a s brA"


    @rhbz1367180
    @rhelver-=9
    @ver+=1.4.0
    @ifcfg-rh
    @team_ifcfg_with_missing_devicetype
    Scenario: ifcfg - team - missing device type
     * Append "DEVICE=eth5" to ifcfg file "team0.0"
     * Append "NAME=team0.0" to ifcfg file "team0.0"
     * Append "ONBOOT=no" to ifcfg file "team0.0"
     * Append "TEAM_MASTER=nm-team" to ifcfg file "team0.0"
     * Append "DEVICE=eth6" to ifcfg file "team0.1"
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
     Then "\"kernel_team_mode_name\": \"activebackup\"" is visible with command "teamdctl nm-team state dump"
      And Check slave "eth5" in team "nm-team" is "up"
      And Check slave "eth6" in team "nm-team" is "up"


    @rhbz1286105 @rhbz1312359
    @rhelver-=9
    @ver+=1.4.0
    @team_in_vlan
    Scenario: nmcli - team - team in vlan
     * Add "team" connection named "team0" for device "nm-team" with options
           """
           autoconnect no
           ipv4.method manual
           ipv4.addresses 192.168.168.17/24
           ipv4.gateway 192.168.103.1
           ipv6.method manual
           ipv6.addresses 2168::17/64
           """
     * Add "vlan" connection named "team0.1" with options
           """
           dev nm-team
           id 1
           mtu 1500
           autoconnect no
           ipv4.method manual
           ipv4.addresses 192.168.168.16/24
           ipv4.gateway 192.168.103.1
           ipv6.method manual
           ipv6.addresses 2168::16/64
           """
     * Bring "up" connection "team0"
     * Bring "up" connection "team0.1"
     When "2168::16" is visible with command "ip a s nm-team.1" in "5" seconds
      And "2168::17" is visible with command "ip a s nm-team"
      And "192.168.168.16" is visible with command "ip a s nm-team.1"
      And "192.168.168.17" is visible with command "ip a s nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Wait for "5" seconds
    Then "2168::16" is visible with command "ip a s nm-team.1"
     And "2168::17" is visible with command "ip a s nm-team"
     And "192.168.168.16" is visible with command "ip a s nm-team.1"
     And "192.168.168.17" is visible with command "ip a s nm-team"


    @rhbz1286105 @rhbz1312359
    @rhelver-=9
    @ver+=1.18
    @team_in_vlan_start_correct_device
    Scenario: nmcli - team - team in vlan start correct device
    * Add "team" connection named "team0" for device "nm-team0" with options "config '{"runner": {"name": "lacp"}}'"
    * Add "team" connection named "team1" for device "nm-team1" with options "config '{"runner": {"name": "lacp"}}'"
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team0"
    * Add "ethernet" connection named "team1.0" for device "eth6" with options "master nm-team1"
    * Add "vlan" connection named "team0.vlan10" with options "dev nm-team0 id 10 ip4 192.168.122.155/24 gw4 192.168.122.1"
    * Add "vlan" connection named "team1.vlan10" with options
          """
          dev nm-team1
          id 10
          ip4 192.168.122.155/24
          gw4 192.168.122.1
          """
    * Bring "down" connection "team0"
    * Bring "down" connection "team1"
    * Bring "up" connection "team0.0"
    Then "nm-team0 " is visible with command "nmcli con show -a" in "5" seconds
    Then "nm-team1" is not visible with command "nmcli con show -a"


    @rhbz1286105 @rhbz1312359 @rhbz1490157
    @rhelver-=9
    @ver+=1.8.1
    @restart_if_needed
    @team_in_vlan_restart_persistence
    Scenario: nmcli - team - team in vlan restart persistence
     * Prepare simulated test "testXT2" device
     * Add "team" connection named "team0" for device "nm-team" with options "ipv4.method disabled ipv6.method ignore"
     * Add "vlan" connection named "team0.1" with options
           """
           dev nm-team
           id 1
           mtu 1500
           ipv4.method manual
           ipv4.addresses 192.168.168.16/24
           ipv4.gateway 192.168.103.1
           ipv6.method manual
           ipv6.addresses 2168::16/64
           """
     * Add "ethernet" connection named "team0.0" for device "testXT2" with options "master nm-team"
     * Delete device "nm-team.1"
     * Reboot
    Then "2168::16" is visible with command "ip a s nm-team.1" in "10" seconds
     And "192.168.168.16" is visible with command "ip a s nm-team.1" in "10" seconds
     And "nm-team.1" is not visible with command "journalctl -u NetworkManager --since '10 seconds ago' --no-pager |grep warn"


    @rhbz1427482
    @rhelver-=9
    @ver+=1.8.0
    @restart_if_needed
    @vlan_in_team
    Scenario: nmcli - team - vlans in team
     * Add "team" connection named "team0" for device "nm-team" with options "ip4 192.168.168.17/24 ipv6.method ignore"
     * Add "vlan" connection named "team0.0" for device "eth5.80" with options
           """
           slave-type team
           dev eth5
           id 80
           master team0
           """
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show team0" in "45" seconds
      And "activated" is visible with command "nmcli -g GENERAL.STATE con show team0.0"
     * Stop NM
     * Execute "rm -rf /var/run/NetworkManager"
     * Execute "ip link del eth5.80"
     * Execute "ip link del nm-team"
     * Start NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show team0" in "45" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show team0.0"


    @rhbz1371126
    @rhelver-=9
    @ver+=1.4.0
    @restart_if_needed
    @team_leave_L2_only_up_when_going_down
    Scenario: nmcli - team - leave UP with L2 only config
     * Prepare simulated test "testXT1" device
     * Add "team" connection named "team0" for device "nm-team" with options
           """
           autoconnect no
           ipv4.method disabled
           ipv6.method ignore
           """
     * Add "ethernet" connection named "team0.0" for device "testXT1" with options
           """
           autoconnect no
           connection.master nm-team
           connection.slave-type team
           """
     * Bring "up" connection "team0.0"
     When "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
      And "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team"
      And "inet6 2620" is visible with command "ip -6 a s nm-team" in "25" seconds
      And "tentative" is not visible with command "ip -6 a s nm-team" in "5" seconds
     * Kill NM
     * Restart NM
     When "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team" for full "10" seconds
      And "inet6 2620" is visible with command "ip -6 a s nm-team"
     * Bring "up" connection "team0.0"
     Then "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
      And "state UP" is visible with command "ip -6 a s nm-team"
      And "inet6 fe80" is visible with command "ip -6 a s nm-team"
      And "inet6 2620" is visible with command "ip -6 a s nm-team" in "5" seconds
      And "tentative" is not visible with command "ip -6 a s nm-team" in "5" seconds


    @rhbz1445242
    @rhelver-=9
    @ver+=1.8.0
    @firewall @restart_if_needed
    @team_add_into_firewall_zone
    Scenario: nmcli - team - modify zones
    * Add "team" connection named "team0" for device "nm-team"
    When "public(\s+[(]default[)])?\s+interfaces: eth0 nm-team" is visible with command "firewall-cmd --get-active-zones" in "10" seconds
    * Modify connection "team0" changing options "connection.zone work"
    * Bring "up" connection "team0"
    When "work\s+interfaces: nm-team" is visible with command "firewall-cmd --get-active-zones" in "5" seconds


    @rhbz1310676
    @rhelver-=9
    @ver+=1.10
    @ethernet
    @team_reconnect_back_to_ethernet_after_master_delete
    Scenario: nmcli - team - reconnect ethernet when master deleted
     * Add "ethernet" connection named "ethernet" for device "eth5"
     * Add "team" connection named "team0" for device "nm-team"
     * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
     * Bring "up" connection "team0.0"
    When Check slave "eth5" in team "nm-team" is "up"
    * Delete connection "team0"
    Then "eth5:connected:ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1398925
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_runners
    Scenario: nmcli - team_abs - set runners
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    Then "\"kernel_team_mode_name\": \"roundrobin\"" is visible with command "teamdctl nm-team state dump"
    And Check slave "eth5" in team "nm-team" is "up"
    # VVV Set random runner
    * Modify connection "team0" changing options "team.runner random"
    * Bring "up" connection "team0"
    Then "{\s*\"runner\": {\s*\"name\": \"random\"\s*}\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"kernel_team_mode_name\": \"random\"" is visible with command "teamdctl nm-team state dump"
    And Check slave "eth5" in team "nm-team" is "up"
    # VVV Set broadcast runner
    * Modify connection "team0" changing options "team.runner broadcast"
    * Bring "up" connection "team0"
    Then "{\s*\"runner\": {\s*\"name\": \"broadcast\"\s*}\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"kernel_team_mode_name\": \"broadcast\"" is visible with command "teamdctl nm-team state dump"
    And Check slave "eth5" in team "nm-team" is "up"
    # VVV Set activebackup runner
    * Modify connection "team0" changing options "team.runner activebackup"
    * Bring "up" connection "team0"
    Then "\"kernel_team_mode_name\": \"activebackup\"" is visible with command "teamdctl nm-team state dump"
    And "{\s*\"runner\": {\s*\"name\": \"activebackup\"\s*}\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And Check slave "eth5" in team "nm-team" is "up"
    # VVV Set loadbalance runner
    * Modify connection "team0" changing options "team.runner loadbalance"
    * Bring "up" connection "team0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
    And "{\s*\"runner\": {\s*\"name\": \"loadbalance\" }\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And Check slave "eth5" in team "nm-team" is "up"
    # VVV Set lacp runner
    * Modify connection "team0" changing options "team.runner lacp"
    * Bring "up" connection "team0"
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
    And "{\s*\"runner\": {\s*\"name\": \"lacp\" }\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @not_on_s390x @not_on_ppc64
    @team_abs_set_runner_hwaddr_policy
    Scenario: nmcli - team_abs - set runners hwadd policy
    * Note the output of "ip a s eth5|grep ether |awk '{print $2}'" as value "eth5"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "eth6"
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team autoconnect no"
    * Add "ethernet" connection named "team0.1" for device "eth6" with options "master nm-team autoconnect no"
    * Modify connection "team0" changing options "team.runner activebackup team.runner-hwaddr-policy by_active"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    * Bring "up" connection "team0.1"
    * Note the output of "ip a s nm-team|grep ether |awk '{print $2}'" as value "team"
    * Note the output of "ip a s eth5|grep ether |awk '{print $2}'" as value "team1"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "team2"
    Then Check noted values "team" and "team1" are the same
     And Check noted values "team" and "eth5" are the same
     And Check noted values "team" and "team2" are not the same
     And "by_active" is visible with command "nmcli connection show team0 |grep 'team.runner-hwaddr-policy'"
    * Bring "down" connection "team0"
    * Modify connection "team0" changing options "team.runner activebackup team.runner-hwaddr-policy only_active"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    * Bring "up" connection "team0.1"
    * Note the output of "ip a s nm-team|grep ether |awk '{print $2}'" as value "team"
    * Note the output of "ip a s eth5|grep ether |awk '{print $2}'" as value "team1"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "team2"
    When Check noted values "team" and "team2" are not the same
    * Bring "down" connection "team0.0"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "team2"
    Then Check noted values "team" and "team2" are the same
     And "only_active" is visible with command "nmcli connection show team0 |grep 'team.runner-hwaddr-policy'"
    * Bring "down" connection "team0"
    # Resetting back to default
    * Modify connection "team0" changing options "team.runner lacp team.runner-hwaddr-policy """
    * Modify connection "team0" changing options "team.runner activebackup"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    * Bring "up" connection "team0.1"
    * Note the output of "ip a s nm-team|grep ether |awk '{print $2}'" as value "team"
    * Note the output of "ip a s eth5|grep ether |awk '{print $2}'" as value "team1"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "team2"
    Then Check noted values "team" and "team1" are the same
     And Check noted values "team1" and "team2" are the same
     And Check noted values "eth5" and "team" are the same
    * Bring "down" connection "team0.0"
    * Note the output of "ip a s eth6|grep ether |awk '{print $2}'" as value "team2"
    Then Check noted values "team" and "team2" are the same


    @rhbz1398925
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_runner_tx_hash
    Scenario: nmcli - team_abs - set runner tx-hash
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"tx_hash\": \[\s+\"eth\",\s+\"ipv4\",\s+\"ipv6\"\s+\]" is visible with command "teamdctl nm-team conf dump"
    And "{\s*\"runner\": {\s*\"name\": \"lacp\" } }" is visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-tx-hash l3"
    * Bring "up" connection "team0"
    Then "\"tx_hash\": \[\s+\"l3\"\s+\]" is visible with command "teamdctl nm-team conf dump"
    And "{\s*\"runner\": {\s*\"name\": \"lacp\", \"tx_hash\": \[\s*\"l3\"\s*]\s*}\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @team_abs_set_runner_tx_balancer
    Scenario: nmcli - team_abs - set runner tx-balancer
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"name\": \"basic\"" is not visible with command "teamdctl nm-team conf dump"
    * Modify connection "team0" changing options "team.runner-tx-balancer basic"
    * Bring "up" connection "team0"
    Then "\"name\": \"basic\"" is visible with command "teamdctl nm-team conf dump"
     And "\"tx_balancer\": {\s*\"name\": \"basic\"\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @team_abs_set_runner_tx_balancer_interval
    Scenario: nmcli - team_abs - set runner tx-balancer-interval
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"balancing-interval\"" is not visible with command "teamdctl nm-team conf dump"
    * Modify connection "team0" changing options "team.runner-tx-balancer-interval 100"
    * Bring "up" connection "team0"
    Then "\"balancing_interval\": 100" is visible with command "teamdctl nm-team conf dump"
     And "\"tx_balancer\": {\s*\"balancing_interval\": 100\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @team_abs_set_runner_active
    Scenario: nmcli - team_abs - set runner active
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"active\": true" is visible with command "teamdctl nm-team state dump"
    * Modify connection "team0" changing options "team.runner-active no"
    * Bring "up" connection "team0"
    Then "\"active\": false" is visible with command "teamdctl nm-team state dump"
     And "\"active\": false" is visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @team_abs_set_runner_fast_rate
    Scenario: nmcli - team_abs - set runner fast-rate
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          team.runner-fast-rate yes
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"fast_rate\": true" is visible with command "teamdctl nm-team state dump"
     And "\"fast_rate\": true" is visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-fast-rate no"
    * Bring "up" connection "team0"
    Then "\"fast_rate\": false" is visible with command "teamdctl nm-team state dump"
     And "\"fast_rate\": true" is not visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925 @rhbz1533810
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_runner_sys_prio
    Scenario: nmcli - team_abs - set runner sys_prio
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"sys_prio\": 65535" is visible with command "teamdctl nm-team state dump"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.runner-sys-prio'"
    * Modify connection "team0" changing options "team.runner-sys-prio 255"
    * Bring "up" connection "team0"
    When "\"sys_prio\": 255" is visible with command "teamdctl nm-team state dump"
    And "255" is visible with command "nmcli connection show team0 |grep 'team.runner-sys-prio'"
    # This need to be fixed in 1533810
    * Modify connection "team0" changing options "team.runner-sys-prio default"
    * Bring "up" connection "team0"
    Then "\"sys_prio\": 65535" is visible with command "teamdctl nm-team state dump"
    And "65535 \(default\)" is visible with command "nmcli connection show team0 |grep 'team.runner-sys-prio'"


    @rhbz1398925 @rhbz1533830
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_runner_min_ports
    Scenario: nmcli - team_abs - set runner min_ports
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          team.runner lacp
          team.runner-min-ports 2
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    When "\"min_ports\": 2" is visible with command "teamdctl nm-team conf dump"
    And "2" is visible with command "nmcli connection show team0 |grep min-port"
    * Modify connection "team0" changing options "team.runner-min-ports """
    * Bring "up" connection "team0"
    When "min_ports" is not visible with command "teamdctl nm-team conf dump"
    And "-1" is visible with command "nmcli connection show team0 |grep min-port"
    * Modify connection "team0" changing options "team.runner-min-ports 2"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    When "\"min_ports\": 2" is visible with command "teamdctl nm-team conf dump"
    And "2" is visible with command "nmcli connection show team0 |grep min-port"
    # * Execute "nmcli connection modify team0 team.runner-min-ports default"
    # * Bring "up" connection "team0"
    # Then "min_ports" is not visible with command "teamdctl nm-team conf dump"
    # And "0 \(default\)" is visible with command "nmcli connection show team0 |grep min-port"


    @rhbz1398925 @rhbz1533830
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_runner_agg_select_policy
    Scenario: nmcli - team_abs - set runner agg-select-policy
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          team.runner lacp
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "\"select_policy\": \"lacp_prio\"" is visible with command "teamdctl nm-team state dump"
    And "agg_select_policy" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-agg-select-policy lacp_prio_stable"
    * Bring "up" connection "team0"
    When "\"select_policy\": \"lacp_prio_stable\"" is visible with command "teamdctl nm-team state dump"
    And "\"agg_select_policy\": \"lacp_prio_stable\"" is visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-agg-select-policy bandwidth"
    * Bring "up" connection "team0"
    When "\"select_policy\": \"bandwidth\"" is visible with command "teamdctl nm-team state dump"
    And "\"agg_select_policy\": \"bandwidth\"" is visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-agg-select-policy count"
    * Bring "up" connection "team0"
    When "\"select_policy\": \"count\"" is visible with command "teamdctl nm-team state dump"
    And "\"agg_select_policy\": \"count\"" is visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.runner-agg-select-policy port_config"
    * Bring "up" connection "team0"
    When "\"select_policy\": \"port_config\"" is visible with command "teamdctl nm-team state dump"
    And "\"agg_select_policy\": \"port_config\"" is visible with command "nmcli connection show team0 |grep 'team.config'"
    # VVV Verify bug 1533830
    * Modify connection "team0" changing options "team.runner-agg-select-policy """
    * Bring "up" connection "team0"
    Then "\"select_policy\": \"lacp_prio\"" is visible with command "teamdctl nm-team state dump"
    And "agg_select_policy" is not visible with command "nmcli connection show team0 |grep 'team.config'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_notify_peers
    Scenario: nmcli - team_abs - set notify_peers
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          team.runner lacp
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    When "notify_peers" is not visible with command "teamdctl nm-team conf dump"
    And "notify_peers" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-count'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-interval'"
    * Modify connection "team0" changing options "team.runner activebackup"
    * Bring "up" connection "team0"
    When "\"notify_peers\": {\s+\"count\": 1" is visible with command "teamdctl nm-team conf dump"
    And "notify_peers" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-count'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-interval'"
    * Modify connection "team0" changing options "team.notify-peers-count 2 team.notify-peers-interval 20"
    * Bring "up" connection "team0"
    Then "\"notify_peers\": {\s+\"count\": 2,\s+\"interval\": 20" is visible with command "teamdctl nm-team conf dump"
    And "notify_peers" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "2" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-count'"
    And "20" is visible with command "nmcli connection show team0 |grep 'team.notify-peers-interval'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.19.2
    @team_abs_set_mcast_rejoin
    Scenario: nmcli - team_abs - set mcast_rejoin
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          team.runner lacp
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    * Bring "up" connection "team0.0"
    When "mcast_rejoin" is not visible with command "teamdctl nm-team conf dump"
    And "mcast_rejoin" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-count'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-interval'"
    * Modify connection "team0" changing options "team.runner activebackup"
    * Bring "up" connection "team0"
    When "\"mcast_rejoin\": {\s+\"count\": 1" is visible with command "teamdctl nm-team conf dump"
    And "mcast_rejoin" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-count'"
    And "-1" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-interval'"
    * Modify connection "team0" changing options "team.mcast-rejoin-count 2 team.mcast-rejoin-interval 20"
    * Bring "up" connection "team0"
    Then "\"mcast_rejoin\": {\s+\"count\": 2,\s+\"interval\": 20" is visible with command "teamdctl nm-team conf dump"
    And "mcast_rejoin" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "2" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-count'"
    And "20" is visible with command "nmcli connection show team0 |grep 'team.mcast-rejoin-interval'"


    @rhbz1398925
    @rhelver-=9
    @ver+=1.10
    @team_abs_set_link_watchers_ethtool
    Scenario: nmcli - team_abs - set link_watchers ethtool
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "link_watch | ethtool" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.link-watchers 'name=ethtool delay-up=100 delay-down=200'"
    * Bring "up" connection "team0"
    Then "{\s*\"link_watch\": {\s*\"name\": \"ethtool\", \"delay_up\": 100, \"delay_down\": 200\s*}\s*}" is visible with command "nmcli connection show team0 |grep 'team.config'"
     And "\"link_watch\": {\s+\"delay_down\": 200,\s+\"delay_up\": 100,\s+\"name\": \"ethtool\"" is visible with command "teamdctl nm-team conf dump"


   @rhbz1398925
   @rhelver-=9
   @ver+=1.19.2
   @team_abs_set_link_watchers_nsna_ping
   Scenario: nmcli - team_abs - set link_watchers nsna_ping
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "link_watch | nsna_ping" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.link-watchers 'name=nsna_ping init-wait=1000 interval=100 missed-max=999 target-host=1.2.3.1'"
    * Bring "up" connection "team0"
    Then "{ \"link_watch\": { \"name\": \"nsna_ping\", \"interval\": 100, \"init_wait\": 1000, \"missed_max\": 999, \"target_host\": \"1.2.3.1\"\ } }" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"link_watch\": {\s+\"init_wait\": 1000,\s+\"interval\": 100,\s+\"missed_max\": 999,\s+\"name\": \"nsna_ping\",\s+\"target_host\": \"1.2.3.1\"" is visible with command "teamdctl nm-team conf dump"


   @rhbz1398925
   @rhelver-=9
   @ver+=1.19.2
   @team_abs_set_link_watchers_arp_ping
   Scenario: nmcli - team_abs - set link_watchers arp_ping
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    When "link_watch | arp_ping" is not visible with command "nmcli connection show team0 |grep 'team.config'"
    * Modify connection "team0" changing options "team.link-watchers 'name=arp_ping init-wait=1000 interval=100 missed-max=999 target-host=1.2.3.1 source-host=1.2.3.4'"
    * Bring "up" connection "team0"
    Then "{ \"link_watch\": { \"name\": \"arp_ping\", \"interval\": 100, \"init_wait\": 1000, \"missed_max\": 999, \"source_host\": \"1.2.3.4\", \"target_host\": \"1.2.3.1\" }\ }" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"link_watch\": {\s+"init_wait": 1000,\s+\"interval\": 100,\s+\"missed_max\": 999,\s+\"name\": \"arp_ping\",\s+\"source_host\": \"1.2.3.4\",\s+\"target_host\": \"1.2.3.1\"" is visible with command "teamdctl nm-team conf dump"


   @rhbz1652931
   @rhelver-=9
   @ver+=1.19.2
   @team_abs_set_link_watchers_arp_ping_vlanid
   Scenario: nmcli - team_abs - set link_watchers arp_ping vlanid property
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          connection.autoconnect-slaves yes
          team.link-watchers 'name=arp_ping init-wait=1000 interval=100 missed-max=999 target-host=1.2.3.1 source-host=1.2.3.4 vlanid=123'
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    Then "{ \"link_watch\": { \"name\": \"arp_ping\", \"interval\": 100, \"init_wait\": 1000, \"missed_max\": 999, \"source_host\": \"1.2.3.4\", \"target_host\": \"1.2.3.1\", \"vlanid\": 123 }\ }" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"link_watch\": {\s+"init_wait": 1000,\s+\"interval\": 100,\s+\"missed_max\": 999,\s+\"name\": \"arp_ping\",\s+\"source_host\": \"1.2.3.4\",\s+\"target_host\": \"1.2.3.1\",\s+\"vlanid\": 123" is visible with command "teamdctl nm-team conf dump"


   @rhbz1533926
   @rhelver-=9
   @ver+=1.19.2
   @team_abs_overwrite_watchers
   Scenario: nmcli - team_abs - overwrite watchers
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          ip4 1.2.3.4/24
          connection.autoconnect-slaves yes
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    * Bring "up" connection "team0"
    * Open editor for connection "team0"
    * Submit "set team.link-watchers name=ethtool delay-up=100 delay-down=200" in editor
    * Submit "set team.link-watchers name=arp_ping init-wait=1000 interval=100 missed-max=999 target-host=1.2.3.1 source-host=1.2.3.4" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "team0"
    Then "{ \"link_watch\": \[ { \"name\": \"ethtool\", \"delay_up\": 100, \"delay_down\": 200 }, { \"name\": \"arp_ping\", \"interval\": 100, \"init_wait\": 1000, \"missed_max\": 999, \"source_host\": \"1.2.3.4\", \"target_host\": \"1.2.3.1\" \} \] \}" is visible with command "nmcli connection show team0 |grep 'team.config'"
    And "\"link_watch\": \[\s+{\s+\"delay_down\": 200,\s+\"delay_up\": 100,\s+\"name\": \"ethtool\"\s+},\s+{\s+\"init_wait\": 1000,\s+\"interval\": 100,\s+\"missed_max\": 999,\s+\"name\": \"arp_ping\",\s+\"source_host\": \"1.2.3.4\",\s+\"target_host\": \"1.2.3.1\"" is visible with command "teamdctl nm-team conf dump"


    @rhbz1551958
    @rhelver-=9
    @ver+=1.10
    @restart_if_needed
    @team_restart_L2_only_lacp
    Scenario: nmcli - team - reboot L2 lacp
    Given Prepare simulated test "testXT1" device
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          config '{"runner": {"name": "lacp"}, "link_watch": {"name": "ethtool"}}'
          ipv4.method disable
          ipv6.method ignore
          """
    * Add "ethernet" connection named "team0.0" for device "testXT1" with options "master nm-team"
    When Bring "up" connection "team0.0"
    And Check slave "testXT1" in team "nm-team" is "up"
    * Restart NM
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "teamdctl nm-team state dump"
     And "\"runner_name\": \"lacp\"" is visible with command "teamdctl nm-team state dump"
     And Check slave "testXT1" in team "nm-team" is "up"
     And "Exactly" "1" lines with pattern "team0\s+" are visible with command "nmcli device"


    @rhbz1647414
    @rhelver-=9
    @ver+=1.18 @rhelver-=7
    @long
    @teamd_logging
    Scenario: nmcli - teamd - logging to syslog
    * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no ip4 1.2.3.4/24"
    * Add "ethernet" connection named "team0.0" for device "eth5" with options "master nm-team"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show team0" in "45" seconds
    Then "teamd_nm-team" is visible with command "journalctl --since '40 seconds ago' -u NetworkManager |grep teamd_"


    @rhbz1711952
    @rhelver-=9
    @ver+=1.18
    @regenerate_veth @permissive @skip_str
    @teamd_killed_by_NM
    Scenario: NM - teamd - NM should not kill teamd
    * Cleanup connection "eth5" and device "eth5"
    * Cleanup device "nm-team"
    * Execute "ip link set dev eth5 down"
    * Execute "teamd -d -c "{\"device\":\"nm-team\",\"runner\":{\"name\":\"lacp\"},\"link_watch\":{\"name\":\"ethtool\"},\"ports\":{\"eth5\":{}}}""
    When "teamd -d -c " is visible with command "ps aux | grep -v grep | grep teamd"
    * Execute "ip link set nm-team up"
    * Execute "ip link set nm-team down"
    * Wait for "2" seconds
    * Execute "ip link set nm-team up"
    * Execute "ip link set nm-team down"
    * Wait for "2" seconds
    Then "teamd -d -c " is visible with command "ps aux | grep -v grep | grep teamd"


    @rhbz1720153
    @rhelver-=9
    @ver+=1.18
    @teamd_boolean_values_problem
    Scenario: nmcli - teamd - boolean values of validate_active and validate_inactive are ignored
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          config '{"device": "nm-team","link_watch": {"interval": 1000,"missed_max": 1,"name": "arp_ping","send_always": false,"source_host": "192.168.1.1","target_host": "192.168.1.2","validate_active": true,"validate_inactive": true},"ports": {"eth5": {"prio": 100,"sticky": true},"eth6": {"prio": 50}},"runner": {"name": "activebackup"}}'
          ip4 192.168.1.1/24
          """
    * Bring "up" connection "team0"
    Then "\"validate_active\": true" is visible with command "ps aux | grep -v grep | grep teamd"
     And "\"validate_inactive\": true" is visible with command "ps aux | grep -v grep | grep teamd"


    @rhbz1755406
    @rhelver-=9
    @ver+=1.22.2
    @team_port_multiple_slaves
    Scenario: nmcli - teamd - add multiple slaves with team-port option
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          team.runner activebackup
          ip4 172.20.1.3/24
          """
    * Add "ethernet" connection named "team0.0" for device "eth5" with options
          """
          master nm-team
          team-port.prio -10
          team-port.sticky true
          """
    * Bring "up" connection "team0.0"
    Then JSON "{"prio":-10, "sticky":true}" is visible with command "nmcli -g team-port.config connection show id team0.0 | sed 's/\\//g'"
    * Bring "up" connection "team0.0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show team0" in "45" seconds
     And JSON "{"device":"nm-team","ports":{"eth5":{"prio":-10,"sticky":true}}}" is visible with command "teamdctl nm-team config dump"
     And JSON "{"ports":{"eth6":{}}}" is not visible with command "teamdctl nm-team config dump"
    * Add "ethernet" connection named "team0.1" for device "eth6" with options
          """
          master nm-team
          team-port.prio 10
          team-port.sticky false
          """
    Then JSON "{"prio":10}" is visible with command "nmcli -g team-port.config connection show id team0.1 | sed 's/\\//g'"
    * Bring "up" connection "team0.1"
    Then JSON "{"device":"nm-team","ports":{"eth5":{"prio":-10,"sticky":true}}}" is visible with command "teamdctl nm-team config dump"
     And JSON "{"device":"nm-team","ports":{"eth6":{"prio": 10}}}" is visible with command "teamdctl nm-team config dump"
    * Bring "down" connection "team0.0"
    Then JSON "{"ports":{"eth5":{}}}" is visible with command "teamdctl nm-team config dump"
    And  JSON "{"device":"nm-team","ports":{"eth6":{"prio": 10}}}" is visible with command "teamdctl nm-team config dump"


    @rhbz1942331
    @rhelver-=9
    @ver+=1.31
    @team_accept_all_mac_addresses
    Scenario: nmcli - team - accept-all-mac-addresses (promisc mode)
    * Add "team" connection named "team0" for device "nm-team" with options "autoconnect no"
    * Bring "up" connection "team0"
    Then "PROMISC" is not visible with command "ip link show dev nm-team"
    * Modify connection "team0" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "team0"
    Then "PROMISC" is visible with command "ip link show dev nm-team"
    * Modify connection "team0" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "team0"
    Then "PROMISC" is not visible with command "ip link show dev nm-team"


    @rhbz1942331
    @rhelver-=9
    @ver+=1.31
    @team_accept_all_mac_addresses_external_device
    Scenario: nmcli - team - accept-all-mac-addresses (promisc mode)
    # promisc off -> default
    * Execute "ip link add nm-team type team && ip link set dev nm-team promisc off"
    When "PROMISC" is not visible with command "ip link show dev nm-team"
    * Add "team" connection named "team0" for device "nm-team" with options
          """
          autoconnect no
          802-3-ethernet.accept-all-mac-addresses default
          """
    * Bring "up" connection "team0"
    Then "PROMISC" is not visible with command "ip link show dev nm-team"
    * Bring "down" connection "team0"
    # promisc on -> default
    * Execute "ip link set dev nm-team promisc on"
    When "PROMISC" is visible with command "ip link show dev nm-team"
    * Bring "up" connection "team0"
    Then "PROMISC" is visible with command "ip link show dev nm-team"
    * Bring "down" connection "team0"
    # promisc off -> true
    * Execute "ip link set dev nm-team promisc off"
    When "PROMISC" is not visible with command "ip link show dev nm-team"
    * Modify connection "team0" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "team0"
    Then "PROMISC" is visible with command "ip link show dev nm-team"
    * Bring "down" connection "team0"
    # promisc on -> false
    * Execute "ip link set dev nm-team promisc on"
    When "PROMISC" is visible with command "ip link show dev nm-team"
    * Modify connection "team0" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "team0"
    Then "PROMISC" is not visible with command "ip link show dev nm-team"


    @rhbz1949023
    @rhelver-=9
    @ver+=1.36
    @team_controller_port_terminology
    Scenario: team - use controller/port terminology
    * Add "team" connection named "team0" for device "team0" with options "autoconnect no"
    # update to controller/port when nmcli also gets update.
    * Add "dummy" connection named "dummy0" for device "dummy0" with options "master team0"
    * Bring "up" connection "dummy0"
    # list ports using libnm
    Then "dummy0" is visible with command "contrib/naming/ports-libnm.py team0"
    # list ports using dbus
    Then Note the output of "contrib/naming/ports-dbus.sh team0 dummy0"
     And Noted value contains "dbus ports:ao \d+"
