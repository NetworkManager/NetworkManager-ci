@nmtui
Feature: Loopback TUI tests

  Background:
  * Prepare virtual terminal environment


    @ver+=1.53.3
    @nmtui_loopback_modify_generated
    Scenario: nmtui - loopback - modify generated connection
    * Cleanup connection "lo"
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Select connection "lo" in the list
    * Choose to "<Edit...>" a connection
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * Remove all "Addresses" property items
    * In "Addresses" property add "192.168.1.10/24"
    * Confirm the connection settings
    Then "inet 192.168.1.10/24" is visible with command "ip a s lo" in "10" seconds
    Then "lo\s+loopback\s+connected\s+lo" is visible with command "nmcli device"


    @ver+=1.53.3
    @nmtui_loopback_static_ipv4
    Scenario: nmtui - loopback - create static IPv4 connection
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Loopback"
    * Set "Profile name" field to "loopback1"
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.168.1.10/24"
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "loopback1" in the list
    * Choose to "<Activate>" a connection
    Then "inet 192.168.1.10/24" is visible with command "ip a s lo" in "10" seconds
    Then "lo\s+loopback\s+connected\s+loopback1" is visible with command "nmcli device"


    @ver+=1.53.3
    @nmtui_loopback_static_ipv6
    Scenario: nmtui - loopback - static IPv6 configuration
    * Prepare new connection of type "Loopback" named "lo2c"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/64"
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "lo2c" in the list
    * Choose to "<Activate>" a connection
    Then "lo\s+loopback\s+connected\s+lo2c" is visible with command "nmcli device" in "20" seconds
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip a s lo" in "10" seconds


    @ver+=1.53.3
    @nmtui_loopback_static_combined
    Scenario: nmtui - loopback - static IPv4 and IPv6 combined
    * Prepare new connection of type "Loopback" named "lo3c"
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.168.1.10/24"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2607:f0d0:1002:51::4/64"
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "lo3c" in the list
    * Choose to "<Activate>" a connection
    Then "inet 192.168.1.10/24" is visible with command "ip a s lo" in "10" seconds
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip a s lo" in "10" seconds
    Then "lo\s+loopback\s+connected\s+lo3c" is visible with command "nmcli device"


    @ver+=1.53.3
    @nmtui_loopback_delete_connection_down
    Scenario: nmtui - loopback - delete nonactive connection
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Loopback"
    * Set "Profile name" field to "deleteme"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "deleteme\s+--\s+no" is visible with command "nmcli -f NAME,DEVICE,ACTIVE connection"
    * Select connection "deleteme" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    Then "deleteme" is not visible with command "nmcli connection"


    @ver+=1.53.3
    @nmtui_loopback_set_mtu
    Scenario: nmtui - loopback - set mtu
    * Start nmtui
    * Choose to "Edit a connection" from main screen
    * Choose to "<Add>" a connection
    * Choose the connection type "Loopback"
    * Set "Profile name" field to "lomtu"
    * Come in "LOOPBACK" category
    * Set "MTU" field to "1420"
    * Confirm the connection settings
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "lomtu" in the list
    * Choose to "<Activate>" a connection
    Then "mtu 1420" is visible with command "ip a s lo" in "60" seconds
