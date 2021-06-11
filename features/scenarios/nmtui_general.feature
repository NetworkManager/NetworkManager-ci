@nmtui
Feature: General TUI tests

  Background:
  * Prepare virtual terminal environment


    @nmtui_general_exit_nmtui
    Scenario: nmtui - general - exit nmtui
    * Start nmtui
    * Nmtui process is running
    * Choose to "Quit" from main screen
    Then Screen is empty


    @nmtui_general_open_edit_menu
    Scenario: nmtui - general - open edit menu
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    Then ".*<Add>.*<Delete>.*" is visible on screen


    @nmtui_general_open_activation_menu
    Scenario: nmtui - general - open activation menu
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    Then ".*ctivate>.*<(Quit|Back)>.*" is visible on screen


    @nmtui_general_open_hostname_dialog
    Scenario: nmtui - general - open hostname dialog
    * Start nmtui
    * Choose to "Set system hostname" from main screen
    Then ".*Set Hostname.*" is visible on screen


    @nmtui_general_display_proper_hostname
    Scenario: nmtui - general - display proper hostname
    * Note the output of "hostname"
    * Execute "nmcli general hostname testhostname"
    * Start nmtui
    * Choose to "Set system hostname" from main screen
    Then ".*Set Hostname.*" is visible on screen
    Then ".*Hostname testhostname.*" is visible on screen


    @ver-=1.2.9
    @restore_hostname
    @nmtui_general_set_new_hostname
    Scenario: nmtui - general - set hostname
    * Note the output of "hostname"
    * Start nmtui
    * Choose to "Set system hostname" from main screen
    * ".*Set Hostname.*" is visible on screen
    * Set current field to "testsethostname"
    * ".*Hostname testsethostname.*" is visible on screen
    * Press "ENTER" key
    * ".*Set hostname to 'testsethostname'.*" is visible on screen
    * Press "ENTER" key
    Then Nmtui process is not running
    Then "testsethostname" is visible with command "hostname"


    @ver+=1.3.0
    @restore_hostname
    @nmtui_general_set_new_hostname
    Scenario: nmtui - general - set hostname
    * Note the output of "hostname"
    * Start nmtui
    * Choose to "Set system hostname" from main screen
    * ".*Set Hostname.*" is visible on screen
    * Set current field to "testsethostname"
    * ".*Hostname testsethostname.*" is visible on screen
    * Press "ENTER" key
    * ".*Set hostname to 'testsethostname'.*" is visible on screen in "10" seconds
    * Press "ENTER" key
    * Choose to "Quit" from main screen
    Then Nmtui process is not running
    Then "testsethostname" is visible with command "hostname"


    @veth
    @bridge
    @ethernet
    @nmtui_general_active_connections_display
    Scenario: nmtui - general - active connections display
    * Execute "nmcli con add type ethernet con-name ethernet1 ifname eth1 autoconnect no"
    * Bring up connection "ethernet1"
    * Execute "nmcli con add type ethernet con-name ethernet2 ifname eth2 autoconnect no"
    * Execute "nmcli c a type bridge con-name bridge0 ifname bridge0"
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    Then Select connection " \* ethernet1" in the list
    Then Select connection "   ethernet2" in the list
    Then Select connection " \* bridge" in the list


    @ethernet
    @nmtui_general_realtime_refresh_edit_screen
    Scenario: nmtui - general - realtime connection refresh edit screen
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Execute "nmcli con add type ethernet con-name ethernet1 ifname eth1 autoconnect no"
    # bring con up in the list by bringing it up :)
    * Bring up connection "ethernet1"
    Then ".* ethernet1.*" is visible on screen in "5" seconds
    * Execute "nmcli con del ethernet1"
    Then ".* ethernet1.*" is not visible on screen in "5" seconds


    @ethernet
    @nmtui_general_realtime_refresh_activate_screen_wo_autoconnect
    Scenario: nmtui - general - realtime connection refresh activation screen without autoconnect
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Execute "nmcli con add type ethernet con-name ethernet1 ifname eth1 autoconnect no"
    Then ".*   ethernet1.*" is visible on screen in "5" seconds
    * Execute "nmcli con del ethernet1"
    Then ".*   ethernet1.*" is not visible on screen in "5" seconds


    @ethernet
    @nmtui_general_realtime_refresh_activate_screen
    Scenario: nmtui - general - realtime connection refresh activation screen
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Execute "nmcli con add type ethernet con-name ethernet1 ifname eth1 autoconnect no"
    * Bring up connection "ethernet1"
    Then ".* \* ethernet1.*" is visible on screen in "5" seconds
    * Execute "nmcli con del ethernet1"
    Then ".* \* ethernet1.*" is not visible on screen in "5" seconds


    @dsl
    @nmtui_dsl_create_default_connection
    Scenario: nmtui - dsl - create default connection
    * Prepare new connection of type "DSL" named "dsl0"
    * Set "Ethernet device" field to "eth5"
    * Set "Username" field to "JohnSmith"
    * Set "Password" field to "testingpassword"
    * Set "Service" field to "NINJA"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "id=dsl0" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "interface-name=eth5" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "type=pppoe" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "service=NINJA" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "username=JohnSmith" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "password=testingpassword" is visible with command "cat /etc/NetworkManager/system-connections/dsl0*"
    Then "dsl0\s+.*pppoe" is visible with command "nmcli connection"


    @rhbz1131574
    @team
    @nmtui_general_show_orphaned_slaves
    Scenario: nmtui - general - show orphaned slaves
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
    * ".*team-slave-eth1.*" is not visible on screen
    * ".*team-slave-eth2.*" is not visible on screen
    # Removing master via CLI does not affect the slaves (opposed to TUI)
    * Execute "nmcli connection delete team0"
    * Wait for at least "3" seconds
    Then ".*team-slave-eth1.*" is visible on screen
    Then ".*team-slave-eth2.*" is visible on screen


    @rhbz1197203
    @no_connections
    @nmtui_general_activate_screen_no_connections
    Scenario: nmtui - general - active screen without connections
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Nmtui process is running
    Then ".*<(Quit|Back)>.*" is visible on screen
    Then ".*testeth.*" is not visible on screen
