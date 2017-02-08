Feature: Team TUI tests

  Background:
  * Prepare virtual terminal environment

    @team
    @nmtui_team_add_default_team
    Scenario: nmtui - team - add default team
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "team0"
    Then "TYPE=Team" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-team0"
    Then "team0:" is visible with command "ip a" in "10" seconds
    Then Team "team0" is up
    Then "team0\s+team" is visible with command "nmcli device"


    @team
    @nmtui_team_add_connection_wo_autoconnect
    Scenario: nmtui - team - add connnection without autoconnect
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "team0"
    Then "team0" is visible with command "nmcli connection"
    Then "team0" is not visible with command "nmcli device"
    Then Team "team0" is down


    @team
    @nmtui_team_activate_wo_autoconnect
    Scenario: nmtui - team - activate without autoconnect
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "team0" is visible with command "nmcli connection"
    * "team0" is not visible with command "nmcli device"
    * Team "team0" is down
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "team0" in the list
    * Choose to "<Activate>" a connection
    Then "team0" is visible with command "nmcli device" in "45" seconds
    Then Team "team0" is up


    @team
    @nmtui_team_activate_with_autoconnect
    Scenario: nmtui - team - activate with autoconnect
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli con down team0"
    * "team0" is visible with command "nmcli connection"
    * "team0" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "team0" in the list
    * Choose to "<Activate>" a connection
    Then "team0" is visible with command "nmcli device" in "10" seconds
    Then Team "team0" is up


    @team
    @nmtui_team_deactivate_connection
    Scenario: nmtui - team - deactivate connection
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Confirm the connection settings
    * "team0" is visible with command "nmcli connection"
    * "team0" is visible with command "nmcli device" in "10" seconds
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "team0" in the list
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    Then Team "team0" is down
    Then "team0" is not visible with command "nmcli device"


    @team
    @nmtui_team_delete_connection_up
    Scenario: nmtui - team - deactivate connection while up
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Confirm the connection settings
    * "team0" is visible with command "nmcli connection"
    * "team0" is visible with command "nmcli device" in "10" seconds
    * Select connection "team0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"team0" file does not exist
    Then "team0" is not visible with command "nmcli connection"
    Then "team0" is not visible with command "nmcli device"
    Then Team "team0" is down


    @team
    @nmtui_team_delete_connection_down
    Scenario: nmtui - team - deactivate connection while down
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Confirm the connection settings
    * Wait for at least "2" seconds
    * Execute "nmcli connection down team0"
    * "team0" is visible with command "nmcli connection"
    * "team0" is not visible with command "nmcli device"
    * Select connection "team0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"team0" file does not exist
    Then "team0" is not visible with command "nmcli connection"
    Then "team0" is not visible with command "nmcli device"
    Then Team "team0" is down


    @team
    @nmtui_team_add_many_slaves
    Scenario: nmtui - team - add many slaves
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth3"
    * Set "Device" field to "eth3"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth4"
    * Set "Device" field to "eth4"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth5"
    * Set "Device" field to "eth5"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth6"
    * Set "Device" field to "eth6"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth7"
    * Set "Device" field to "eth7"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth8"
    * Set "Device" field to "eth8"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth9"
    * Set "Device" field to "eth9"
    * Confirm the slave settings
    * Confirm the connection settings
    Then Team "team0" is up
    Then Check slave "eth1" in team "team0" is "up"
    Then Check slave "eth2" in team "team0" is "up"
    Then Check slave "eth3" in team "team0" is "up"
    Then Check slave "eth4" in team "team0" is "up"
    Then Check slave "eth5" in team "team0" is "up"
    Then Check slave "eth6" in team "team0" is "up"
    Then Check slave "eth7" in team "team0" is "up"
    Then Check slave "eth8" in team "team0" is "up"
    Then Check slave "eth9" in team "team0" is "up"


    @team
    @nmtui_team_over_ethernet_devices
    Scenario: nmtui - team - over ethernet devices
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "team0\s+team\s+connected" is visible with command "nmcli device" in "60" seconds
    Then Team "team0" is up
    Then Check slave "eth1" in team "team0" is "up"
    Then Check slave "eth2" in team "team0" is "up"
    Then "eth1\s+ethernet\s+connected\s+team-slave-eth1" is visible with command "nmcli device"
    Then "eth2\s+ethernet\s+connected\s+team-slave-eth2" is visible with command "nmcli device"
    Then "192.168" is visible with command "ip a s team0"


    @bz1131574
    @team
    @nmtui_team_delete_slaves_after_deleting_profile
    Scenario: nmtui - team - delete slaves after deleting master
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Confirm the slave settings
    * Confirm the connection settings
    * "team0\s+team\s+connected" is visible with command "nmcli device" in "60" seconds
    * Select connection "team0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ".*team-slave-eth1.*" is not visible on screen
    Then ".*team-slave-eth2.*" is not visible on screen
    Then "team-slave-eth1" is not visible with command "nmcli connection"
    Then "team-slave-eth2" is not visible with command "nmcli connection"


    @team
    @nmtui_team_infiniband_slaves
    Scenario: nmtui - team - infiniband slaves
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "InfiniBand"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "infi1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "infi2"
    * Confirm the slave settings
    * Confirm the connection settings
    Then "team0\s+team" is visible with command "nmcli device" in "60" seconds
    Then "DEVICETYPE=TeamPort" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-team-slave-eth1"
    Then "DEVICETYPE=TeamPort" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-team-slave-eth2"
    Then Team "team0" is up


    @team
    @nmtui_team_slaves_non_auto
    Scenario: nmtui - team - slaves non auto
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli connection up team0"
    * Team "team0" is up
    * Reboot
    Then Check slave "eth1" in team "team0" is "down"
    Then Check slave "eth2" in team "team0" is "down"


    @team
    @nmtui_team_boot_with_team_and_one_slave_auto
    Scenario: nmtui - team - start with only one slave auto
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli connection up team0"
    * Team "team0" is up
    * Reboot
    Then Check slave "eth1" in team "team0" is "down"
    Then Check slave "eth2" in team "team0" is "down"


    @team
    @nmtui_team_json_set_loadbalance_mode
    Scenario: nmtui - team - json - set loadbalance mode
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set team json config to "{"device":"team0","runner":{"name":"loadbalance"},"ports":{"eth1":{},"eth2": {}}}"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    Then "\"kernel_team_mode_name\": \"loadbalance\"" is visible with command "sudo teamdctl team0 state dump"
    Then Check slave "eth1" in team "team0" is "up"
    Then Check slave "eth2" in team "team0" is "up"


    @team
    @nmtui_team_json_set_broadcast_mode
    Scenario: nmtui - team - json - set broadcast mode
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set team json config to "{    "device":       "team0",  "runner":       {"name": "broadcast"},  "ports":        {"eth1": {}, "eth2": {}}}"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    Then "\"kernel_team_mode_name\": \"broadcast\"" is visible with command "sudo teamdctl team0 state dump"
    Then Check slave "eth1" in team "team0" is "up"
    Then Check slave "eth2" in team "team0" is "up"


    @team
    @nmtui_team_json_set_invalid_mode
    Scenario: nmtui - team - json - set invalid mode
    * Prepare new connection of type "Team" named "team0"
    * Set "Device" field to "team0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "team-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set team json config to "{walderony {tutti frutti}}"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    Then Team "team0" is down
