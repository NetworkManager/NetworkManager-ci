Feature: Bridge TUI tests

  Background:
  * Prepare virtual terminal environment

    @inf
    @nmtui_inf_create_master_connection
    Scenario: nmtui - inf - create master connection
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0"
    Then "TYPE=InfiniBand" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "NAME=infiniband0" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "DEVICE=inf0" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "ONBOOT=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "infiniband0\s+.*infiniband" is visible with command "nmcli connection"


    @inf
    @nmtui_inf_create_port_connection
    Scenario: nmtui - inf - create port connection
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "infiniband0"
    * Choose to "<Add>" a connection
    * Choose the connection type "InfiniBand"
    * Set "Profile name" field to "infiniband0-port"
    * Set "Device" field to "inf0.8003"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0-port"
    Then "TYPE=InfiniBand" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0-port"
    Then "NAME=infiniband0-port" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0-port"
    Then "DEVICE=inf0.8003" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0-port"
    Then "ONBOOT=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0-port"
    Then "infiniband0-port\s+.*infiniband" is visible with command "nmcli connection"


    @inf
    @nmtui_inf_add_connection_wo_autoconnect
    Scenario: nmtui - inf - add connnection without autoconnect
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0"
    Then "ONBOOT=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"


    @inf
    @nmtui_inf_delete_connection
    Scenario: nmtui - inf - delete connection
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Confirm the connection settings
    * Check ifcfg-name file created for connection "infiniband0"
    * Select connection "infiniband0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"infiniband0" file does not exist
    Then "infiniband0" is not visible with command "nmcli connection"


    @inf
    @nmtui_inf_set_mtu
    Scenario: nmtui - inf - set MTU
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Set "MTU" field to "1280"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0"
    Then "MTU=1280" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"


    @inf
    @nmtui_inf_datagram_mode
    Scenario: nmtui - inf - set datagram mode
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Set "Transport mode" dropdown to "Datagram"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0"
    Then "CONNECTED_MODE=no" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "CONNECTED_MODE=yes" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"


    @inf
    @nmtui_inf_connected_mode
    Scenario: nmtui - inf - set connected mode
    * Prepare new connection of type "InfiniBand" named "infiniband0"
    * Set "Device" field to "inf0"
    * Set "Transport mode" dropdown to "Connected"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "infiniband0"
    Then "CONNECTED_MODE=yes" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
    Then "CONNECTED_MODE=no" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-infiniband0"
