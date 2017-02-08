Feature: VLAN TUI tests

  Background:
  * Prepare virtual terminal environment

    @vlan
    @nmtui_vlan_add_default_connection
    Scenario: nmtui - vlan - add default connection
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "99"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "vlan"
    Then "TYPE=Vlan" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-vlan"
    Then "VLAN_ID=99" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-vlan"
    Then "eth1.99@eth1:" is visible with command "ip a" in "10" seconds
    Then "eth1.99\s+vlan" is visible with command "nmcli device"


    @vlan
    @nmtui_vlan_set_device
    Scenario: nmtui - vlan - set device
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "vlan_device"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "99"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "vlan"
    Then "TYPE=Vlan" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-vlan"
    Then "DEVICE=vlan_device" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-vlan"
    Then "VLAN_ID=99" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-vlan"
    Then "vlan_device@eth1:" is visible with command "ip a" in "10" seconds
    Then "vlan_device\s+vlan" is visible with command "nmcli device"


    @vlan
    @nmtui_vlan_missing_parent
    Scenario: nmtui - vlan - missing parent
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "vlan_device"
    * Set "VLAN id" field to "99"
    * Confirm the connection settings
    Then ".*vlan.parent: property is not.*specified and neither is.*'802-3-ethernet:mac-address'.*" is visible on screen


    #common mistake misplacing device with parent
    @vlan
    @nmtui_vlan_set_parent_as_device
    Scenario: nmtui - vlan - set parent also as device
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "eth1"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "99"
    * Confirm the connection settings
    Then "vlan +--" is visible with command "nmcli connection"


    @vlan
    @nmtui_vlan_set_non_existant_parent
    Scenario: nmtui - vlan - set non-existant parent
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "eth52.99"
    * Set "Parent" field to "eth52"
    * Set "VLAN id" field to "99"
    * Confirm the connection settings
    Then "vlan +--" is visible with command "nmcli connection"


    @vlan
    @nmtui_vlan_autocompletion
    Scenario: nmtui - vlan - autocompletion
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "eth52.99"
    * Ensure "Automatically connect" is checked
    Then ".*Parent eth52.*" is visible on screen
    Then ".*VLAN id 99.*" is visible on screen



    @vlan
    @nmtui_vlan_invalid_ids
    Scenario: nmtui - vlan - invalid ids
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "vlan"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "4096"
    Then Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "vlan"
    * Set "Device" field to "vlan"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "65536"
    Then Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "vlan"
    * Set "Device" field to "vlan"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "string"
    Then Cannot confirm the connection settings
    * Press "ENTER" key
    * Choose to "<Add>" a connection
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "vlan"
    * Set "Device" field to "vlan"
    * Set "Parent" field to "eth1"
    * Set "VLAN id" field to "99"
    Then Confirm the connection settings


    @vlan
    @nmtui_vlan_delete_connection_down
    Scenario: nmtui - vlan - delete nonactive connection
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99" is not visible with command "nmcli device"
    * Select connection "eth1.99" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then ifcfg-"eth1.99" file does not exist
    Then "eth1.99" is not visible with command "nmcli connection"


    @vlan
    @nmtui_vlan_delete_connection_activating
    Scenario: nmtui - vlan - delete activating connection
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99\s+vlan\s+connecting" is visible with command "nmcli device" in "10" seconds
    * Select connection "eth1.99" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then ifcfg-"eth1.99" file does not exist
    Then "eth1.99" is not visible with command "nmcli connection"
    Then "eth1.99" is not visible with command "nmcli device"


    @vlan
    @nmtui_vlan_delete_connection_up
    Scenario: nmtui - vlan - delete active connection
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99\s+vlan\s+connected" is visible with command "nmcli device" in "10" seconds
    * "169.254" is visible with command "ip a s eth1.99" in "10" seconds
    * Select connection "eth1.99" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then ifcfg-"eth1.99" file does not exist
    Then "eth1.99" is not visible with command "nmcli connection"
    Then "eth1.99" is not visible with command "nmcli device"


    @vlan
    @nmtui_vlan_create_no_autoconnect
    Scenario: nmtui - vlan - create connetion without autoconnect
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "eth1.99"
    Then "eth1.99" is visible with command "nmcli connection"
    Then "eth1.99" is not visible with command "nmcli device"


    @vlan
    @nmtui_vlan_activate_connection
    Scenario: nmtui - vlan - activate connection
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99" is visible with command "nmcli connection"
    * "eth1.99" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "eth1.99" in the list
    * Choose to "<Activate>" a connection
    Then "inet 169.254" is visible with command "ip a s eth1.99" in "10" seconds
    Then "eth1.99\s+vlan\s+connected" is visible with command "nmcli device"


    @vlan
    @nmtui_vlan_deactivate_connection_wo_autoconnect
    Scenario: nmtui - vlan - deactivate connection without autoconnect
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99" is visible with command "nmcli connection"
    * "eth1.99" is not visible with command "nmcli device"
    * Execute "nmcli connection up eth1.99"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "eth1.99" in the list
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    Then "inet 169.254" is not visible with command "ip a s eth1.99"
    Then "eth1.99" is not visible with command "nmcli device"
    Then "eth1.99" is visible with command "nmcli connection"


    @vlan
    @nmtui_vlan_deactivate_connection_with_autoconnect
    Scenario: nmtui - vlan - deactivate connection with autoconnect
    * Prepare new connection of type "VLAN" named "eth1.99"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "eth1.99"
    * "eth1.99" is visible with command "nmcli connection"
    * "eth1.99" is visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "eth1.99" in the list
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    Then "inet 169.254" is not visible with command "ip a s eth1.99"
    Then "eth1.99" is not visible with command "nmcli device"
    Then "eth1.99" is visible with command "nmcli connection"


    @vlan
    @nmtui_vlan_change_id
    Scenario: nmtui - vlan - change id
    * Prepare new connection of type "VLAN" named "vlan"
    * Set "Device" field to "eth1.99"
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Confirm the connection settings
    * Select connection "vlan" in the list
    * Choose to "<Edit...>" a connection
    * Set "Device" field to "eth1.88"
    * Set "VLAN id" field to "88"
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "vlan" in the list
    * "eth1.99" is visible with command "nmcli device"
    * "VID: 99" is visible with command "cat /proc/net/vlan/eth1.99"
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    * Press "UPARROW" key
    * Select connection "vlan" in the list
    * Choose to "<Activate>" a connection
    Then "eth1.88" is visible with command "nmcli device" in "10" seconds
    Then "eth1.99" is not visible with command "nmcli device"
    Then "VID: 88" is visible with command "cat /proc/net/vlan/eth1.88"
