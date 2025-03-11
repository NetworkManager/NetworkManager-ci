@nmtui
Feature: Veth TUI tests

  Background:
  * Prepare virtual terminal environment


    @ver+=1.48.10.7
    @nmtui_veth_create_default_connection
    Scenario: nmtui - veth - create default connection
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Veth"
    * Set "Profile name" field to "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Confirm the connection settings
    Then "con_veth" is visible with command "nmcli -f NAME con sh"
    And "veth1:disconnected" is visible with command "nmcli -g DEVICE,STATE d" in "5" seconds
    And "veth2:unmanaged" is visible with command "nmcli -g DEVICE,STATE d" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_activate_connection_wo_autoconnect
    Scenario: nmtui - veth - activate connection
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Veth"
    * Set "Profile name" field to "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Disabled"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "veth\s+--\s+no" is visible with command "nmcli -f NAME,DEVICE,ACTIVE connection"
    And "veth1" is not visible with command "nmcli d" in "5" seconds
    And "veth2" is not visible with command "nmcli d" in "5" seconds
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "con_veth" in the list
    * Choose to "<Activate>" a connection
    Then "con_veth" is visible with command "nmcli -f NAME con sh -a"
    And "veth1:connected" is visible with command "nmcli -g DEVICE,STATE d" in "5" seconds
    And "veth2:unmanaged" is visible with command "nmcli -g DEVICE,STATE d" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_deactivate_connection
    Scenario: nmtui - veth - deactivate connection
    * Add "veth" connection named "con_veth" for device "veth1" with options "autoconnect no peer veth2 ipv4.method disabled ipv6.method disabled"
    * Bring "up" connection "con_veth"
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "con_veth" in the list
    * Choose to "<Deactivate>" a connection
    Then "con_veth\s+--\s+no" is visible with command "nmcli -f NAME,DEVICE,ACTIVE connection"
    And "veth1" is not visible with command "nmcli d" in "5" seconds
    And "veth2" is not visible with command "nmcli d" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_delete_connection_down
    Scenario: nmtui - veth - delete nonactive connection
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Veth"
    * Set "Profile name" field to "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "con_veth\s+--\s+no" is visible with command "nmcli -f NAME,DEVICE,ACTIVE connection"
    And "veth1" is not visible with command "nmcli d" in "5" seconds
    And "veth2" is not visible with command "nmcli d" in "5" seconds
    * Select connection "con_veth" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then "con_veth" is not visible with command "nmcli connection"
    And "veth1" is not visible with command "nmcli d" in "5" seconds
    And "veth2" is not visible with command "nmcli d" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_delete_connection_up
    Scenario: nmtui - veth - delete active connection
    * Add "veth" connection named "con_veth" for device "veth1" with options "autoconnect no peer veth2 ipv4.method disabled ipv6.method disabled"
    * Bring "up" connection "con_veth"
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Select connection "con_veth" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then "con_veth" is not visible with command "nmcli connection"
    And "veth1" is not visible with command "nmcli d" in "5" seconds
    And "veth2" is not visible with command "nmcli d" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_set_mtu
    Scenario: nmtui - veth - set mtu
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Veth"
    * Set "Profile name" field to "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Come in "ETHERNET" category
    * Set "MTU" field to "128"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Disabled"
    * Confirm the connection settings
    Then "128" is visible with command "nmcli -g 802-3-ethernet.mtu con show con_veth"
    And "mtu 128" is visible with command "ip a s veth1" in "5" seconds


    @ver+=1.48.10.7
    @nmtui_veth_cloned_mac
    Scenario: nmtui - veth - cloned mac
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Veth"
    * Set "Profile name" field to "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Come in "ETHERNET" category
    * Set "Cloned MAC address" field to "f0:de:aa:fb:bb:cc"
    * Set "IPv4 CONFIGURATION" category to "Disabled"
    * Set "IPv6 CONFIGURATION" category to "Disabled"
    * Confirm the connection settings
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip a" in "60" seconds


    @ver+=1.48.10.7
    @nmtui_veth_static_ipv4
    Scenario: nmtui - veth - static IPv4 configuration
    * Prepare new connection of type "Veth" named "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.168.1.10/24"
    * Confirm the connection settings
    Then "inet 192.168.1.10/24" is visible with command "ip a s veth1" in "10" seconds
    Then "veth1\s+ethernet\s+connected\s+con_veth" is visible with command "nmcli device"


    @ver+=1.48.10.7
    @nmtui_veth_static_ipv6
    Scenario: nmtui - veth - static IPv6 configuration
    * Prepare new connection of type "Veth" named "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/64"
    * Confirm the connection settings
    * Commentary
    """
    Connection is connecting, because waiting for ipv4.
    """
    Then "veth1\s+ethernet\s+connect.*\s+con_veth" is visible with command "nmcli device" in "20" seconds
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip a s veth1" in "10" seconds


    @ver+=1.48.10.7
    @nmtui_veth_static_combined
    Scenario: nmtui - veth - static IPv4 and IPv6 combined
    * Prepare new connection of type "Veth" named "con_veth"
    * Set "Device" field to "veth1"
    * Set "Peer" field to "veth2"
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.168.1.10/24"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/64"
    * Confirm the connection settings
    Then "inet 192.168.1.10/24" is visible with command "ip a" in "10" seconds
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip a" in "10" seconds
    Then "veth1\s+ethernet\s+connected\s+con_veth" is visible with command "nmcli device"
