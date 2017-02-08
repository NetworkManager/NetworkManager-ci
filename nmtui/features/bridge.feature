Feature: Bridge TUI tests

  Background:
  * Prepare virtual terminal environment

    @bridge
    @nmtui_bridge_add_default_bridge
    Scenario: nmtui - bridge - add default bridge
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "bridge0"
    Then "TYPE=Bridge" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge0"
    Then "STP=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge0"
    Then "bridge0:" is visible with command "ip a" in "10" seconds
    Then "bridge0" is visible with command "brctl show"
    Then "bridge0\s+bridge" is visible with command "nmcli device"


    @bridge
    @nmtui_bridge_add_custom_bridge
    Scenario: nmtui - bridge - add custom bridge
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "br88"
    * Set "Aging time" field to "500000"
    * Set "Priority" field to "5"
    * Set "Forward delay" field to "3"
    * Set "Hello time" field to "3"
    * Set "Max age" field to "15"
    * Confirm the connection settings
    Then "br88:" is visible with command "ip a" in "10" seconds
    Then "br88" is visible with command "brctl show"
    Then "DELAY=3.*BRIDGING_OPTS=\"priority=5 hello_time=3 max_age=15 ageing_time=500000\".*NAME=bridge.*ONBOOT=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge0"


    @bridge
    @nmtui_bridge_add_connection_wo_autoconnect
    Scenario: nmtui - bridge - add connnection without autoconnect
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "bridge0"
    Then "TYPE=Bridge" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge0"
    Then "bridge0" is visible with command "nmcli connection"
    Then "bridge0" is not visible with command "nmcli device"


    @bridge
    @nmtui_bridge_activate_wo_autoconnect
    Scenario: nmtui - bridge - activate without autoconnect
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "bridge0" is visible with command "nmcli connection"
    * "bridge0" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bridge0" in the list
    * Choose to "<Activate>" a connection
    Then "bridge0" is visible with command "nmcli device" in "10" seconds
    Then "bridge0" is visible with command "brctl show"


    @bridge
    @nmtui_bridge_activate_with_autoconnect
    Scenario: nmtui - bridge - activate with autoconnect
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli con down bridge0"
    * "bridge0" is visible with command "nmcli connection"
    * "bridge0" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bridge0" in the list
    * Choose to "<Activate>" a connection
    Then "bridge0" is visible with command "nmcli device" in "10" seconds
    Then "bridge0" is visible with command "brctl show"


    @bridge
    @nmtui_bridge_deactivate_connection
    Scenario: nmtui - bridge - deactivate connection
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Confirm the connection settings
    * "bridge0" is visible with command "nmcli connection"
    * "bridge0" is visible with command "nmcli device" in "10" seconds
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bridge0" in the list
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    Then "bridge0" is not visible with command "nmcli device"
    Then "bridge0" is not visible with command "brctl show"


    @bridge
    @nmtui_bridge_delete_connection_up
    Scenario: nmtui - bridge - delete connection while up
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Confirm the connection settings
    * "bridge0" is visible with command "nmcli connection"
    * "bridge0" is visible with command "nmcli device" in "10" seconds
    * Select connection "bridge0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"bridge0" file does not exist
    Then "bridge0" is not visible with command "nmcli connection"
    Then "bridge0" is not visible with command "nmcli device"
    Then "bridge0" is not visible with command "brctl show"


    @bridge
    @nmtui_bridge_delete_connection_down
    Scenario: nmtui - bridge - delete connection while down
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Confirm the connection settings
    * Wait for at least "2" seconds
    * Execute "nmcli connection down bridge0"
    * "bridge0" is visible with command "nmcli connection"
    * "bridge0" is not visible with command "nmcli device"
    * Select connection "bridge0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"bridge0" file does not exist
    Then "bridge0" is not visible with command "nmcli connection"
    Then "bridge0" is not visible with command "nmcli device"
    Then "bridge0" is not visible with command "brctl show"


    @veth
    @bridge
    @nmtui_bridge_add_many_slaves
    Scenario: nmtui - bridge - add many slaves
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth2"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth3"
    * Set "Device" field to "eth3"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth4"
    * Set "Device" field to "eth4"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth5"
    * Set "Device" field to "eth5"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth6"
    * Set "Device" field to "eth6"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth7"
    * Set "Device" field to "eth7"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth8"
    * Set "Device" field to "eth8"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth9"
    * Set "Device" field to "eth9"
    * Confirm the slave settings
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth1"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth2"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth3"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth4"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth5"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth6"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth7"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth8"
    Then "BRIDGE=" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth9"


    @bridge
    @nmtui_bridge_over_ethernet_devices
    Scenario: nmtui - bridge - over ethernet devices
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    Then "eth1\s+ethernet\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    Then "eth2\s+ethernet\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    Then "192.168" is visible with command "ip a s bridge0"


    # @bridge
    # @nmtui_bridge_over_ethernet_devices_no_stp
    # Scenario: nmtui - bridge - over ethernet devices no stp
    # * Prepare new connection of type "Bridge" named "bridge0"
    # * Set "Device" field to "bridge0"
    # * Choose to "<Add>" a slave
    # * Choose the connection type "Ethernet"
    # * Set "Profile name" field to "bridge-slave-eth1"
    # * Set "Device" field to "eth1"
    # * Confirm the slave settings
    # * Choose to "<Add>" a slave
    # * Choose the connection type "Ethernet"
    # * Set "Profile name" field to "bridge-slave-eth2"
    # * Set "Device" field to "eth2"
    # * Confirm the slave settings
    # * Ensure "Enable STP" is not checked
    # * Come in "IPv4 CONFIGURATION" category
    # * Ensure "Require IPv4 addressing for this connection" is checked
    # * Confirm the connection settings
    # Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    # Then "eth1\s+ethernet\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    # Then "eth2\s+ethernet\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    # Then "192.168" is visible with command "ip a s bridge0"


    @bridge
    @nmtui_bridge_over_ethernet_devices_no_stp
    Scenario: nmtui - bridge - over ethernet devices no stp
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth10"
    * Confirm the slave settings
    * Ensure "Enable STP" is not checked
    * Confirm the connection settings
    Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    Then "eth1\s+ethernet\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    Then "eth10\s+ethernet\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    Then "inet 1" is visible with command "ip a s bridge0"


    @bridge
    @vlan
    @nmtui_bridge_over_vlans
    Scenario: nmtui - bridge - over vlans
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1.99"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth2.88"
    * Confirm the slave settings
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    Then "eth1.99\s+vlan\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    Then "eth2.88\s+vlan\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    Then "169.254" is visible with command "ip a s bridge0"


    @bridge
    @vlan
    @nmtui_bridge_over_vlans_no_stp
    Scenario: nmtui - bridge - over vlans no stp
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1.99"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth2.88"
    * Confirm the slave settings
    * Ensure "Enable STP" is not checked
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    Then "eth1.99\s+vlan\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    Then "eth2.88\s+vlan\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    Then "169.254" is visible with command "ip a s bridge0"


    @bridge
    @nmtui_bridge_custom_bridge_port
    Scenario: nmtui - bridge - custom bridge port
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1"
    * Set "Priority" field to "48"
    * Set "Path cost" field to "128"
    * Ensure "Hairpin mode" is checked
    * Confirm the slave settings
    Then "BRIDGING_OPTS=.priority=48 path_cost=128 hairpin_mode=1" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bridge-slave-eth1"


    @bridge
    @vlan
    @nmtui_bridge_over_ethernet_and_vlan
    Scenario: nmtui - bridge - over ethernet and vlan
    * Prepare new connection of type "Bridge" named "bridge0"
    * Set "Device" field to "bridge0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bridge-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Choose the connection type "VLAN"
    * Set "Profile name" field to "bridge-slave-eth2"
    * Set "Device" field to "eth2.88"
    * Confirm the slave settings
    * Set "IPv4 CONFIGURATION" category to "Link-Local"
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "bridge0\s+bridge\s+connected" is visible with command "nmcli device" in "60" seconds
    Then "eth1\s+ethernet\s+connected\s+bridge-slave-eth1" is visible with command "nmcli device"
    Then "eth2.88\s+vlan\s+connected\s+bridge-slave-eth2" is visible with command "nmcli device"
    Then "169.254" is visible with command "ip a s bridge0"
