Feature: Bond TUI tests

  Background:
  * Prepare virtual terminal environment

    @bond
    @nmtui_bond_add_default_bond
    Scenario: nmtui - bond - add default bond
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "bond0"
    Then "TYPE=Bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0"
    Then "bond0:" is visible with command "ip a" in "10" seconds
    Then Check bond "bond0" in proc
    Then "bond0\s+bond" is visible with command "nmcli device"


    @bond
    @nmtui_bond_add_custom_bond_mii
    Scenario: nmtui - bond - add custom bond with MII monitoring
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Set "Monitoring frequency" field to "80"
    * Set "Link up delay" field to "400"
    * Set "Link down delay" field to "160"
    * Confirm the connection settings
    Then "bond0:" is visible with command "ip a" in "10" seconds
    Then Check bond "bond0" state is "up"
    Then "MII Polling Interval \(ms\): 80" is visible with command "cat /proc/net/bonding/bond0"
    Then "Up Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/bond0"
    Then "Down Delay \(ms\): 160" is visible with command "cat /proc/net/bonding/bond0"


    @bond
    @nmtui_bond_add_custom_bond_arp
    Scenario: nmtui - bond - add custom bond with ARP monitoring
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Set "Link monitoring" dropdown to "ARP"
    * Set "Monitoring frequency" field to "100"
    * In "ARP targets" property add "192.168.100.1"
    * Confirm the connection settings
     Then "bond0:" is visible with command "ip a" in "10" seconds
     Then Check bond "bond0" state is "up"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/bond0"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/bond0"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/bond0"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/bond0"
     Then "ARP IP target/s \(n.n.n.n form\):.*192.168.100.1" is visible with command "cat /proc/net/bonding/bond0"



    @bond
    @nmtui_bond_add_connection_wo_autoconnect
    Scenario: nmtui - bond - add connnection without autoconnect
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then Check ifcfg-name file created for connection "bond0"
    Then "TYPE=Bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0"
    Then "bond0" is visible with command "nmcli connection"
    Then "bond0" is not visible with command "nmcli device"


    @bond
    @nmtui_bond_activate_wo_autoconnect
    Scenario: nmtui - bond - activate without autoconnect
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "bond0" is visible with command "nmcli connection"
    * "bond0" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bond0" in the list
    * Choose to "<Activate>" a connection
    Then "bond0" is visible with command "nmcli device" in "10" seconds
    Then Check bond "bond0" state is "up"


    @bond
    @nmtui_bond_activate_with_autoconnect
    Scenario: nmtui - bond - activate with autoconnect
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli con down bond0"
    * "bond0" is visible with command "nmcli connection"
    * "bond0" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bond0" in the list
    * Choose to "<Activate>" a connection
    Then "bond0" is visible with command "nmcli device" in "10" seconds
    Then Check bond "bond0" state is "up"


    @bond
    @nmtui_bond_deactivate_connection
    Scenario: nmtui - bond - deactivate connection
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Confirm the connection settings
    * "bond0" is visible with command "nmcli connection"
    * "bond0" is visible with command "nmcli device" in "10" seconds
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "bond0" in the list
    * Choose to "<Deactivate>" a connection
    * Wait for at least "3" seconds
    Then "bond0" is not visible with command "nmcli device"
    Then Check bond "bond0" link state is "down"


    @bond
    @nmtui_bond_delete_connection_up
    Scenario: nmtui - bond - deactivate connection while up
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Confirm the connection settings
    * "bond0" is visible with command "nmcli connection"
    * "bond0" is visible with command "nmcli device" in "10" seconds
    * Select connection "bond0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"bond0" file does not exist
    Then "bond0" is not visible with command "nmcli connection"
    Then "bond0" is not visible with command "nmcli device"
    Then Check bond "bond0" link state is "down"


    @bond
    @nmtui_bond_delete_connection_down
    Scenario: nmtui - bond - deactivate connection while down
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Confirm the connection settings
    * Wait for at least "2" seconds
    * Execute "nmcli connection down bond0"
    * "bond0" is visible with command "nmcli connection"
    * "bond0" is not visible with command "nmcli device"
    * Select connection "bond0" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then ifcfg-"bond0" file does not exist
    Then "bond0" is not visible with command "nmcli connection"
    Then "bond0" is not visible with command "nmcli device"
    Then Check bond "bond0" link state is "down"


    @rhbz1369008
    @ver+=1.4.0
    @ver-=1.7.9
    @bond
    @nmtui_bond_add_one_slave
    Scenario: nmtui - bond - add one slave
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Confirm the connection settings
    * Select connection "bond0" in the list
    * Choose to "<Edit...>" a connection
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Confirm the connection settings
    Then Check bond "bond0" link state is "up"
     And "Slave Interface: eth1" is visible with command "cat /proc/net/bonding/bond0"
     And "MASTER=bond0" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-eth1"


    @rhbz1425409
    @ver+=1.8.0
    @bond
    @nmtui_bond_add_one_slave
    Scenario: nmtui - bond - add one slave
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Confirm the connection settings
    Then Check bond "bond0" link state is "up"
     And "Slave Interface: eth1" is visible with command "cat /proc/net/bonding/bond0"
     And "MASTER=bond0" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-eth1"


    @bond
    @nmtui_bond_add_many_slaves
    Scenario: nmtui - bond - add many slaves
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth3"
    * Set "Device" field to "eth3"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth4"
    * Set "Device" field to "eth4"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth5"
    * Set "Device" field to "eth5"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth6"
    * Set "Device" field to "eth6"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth7"
    * Set "Device" field to "eth7"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth8"
    * Set "Device" field to "eth8"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth9"
    * Set "Device" field to "eth9"
    * Confirm the slave settings
    * Confirm the connection settings
    Then "bond0\s+bond\s+connected" is visible with command "nmcli device" in "45" seconds
    Then Check bond "bond0" link state is "up"
    Then "Slave Interface: eth1" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth2" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth3" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth4" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth5" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth6" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth7" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth8" is visible with command "cat /proc/net/bonding/bond0"
    Then "Slave Interface: eth9" is visible with command "cat /proc/net/bonding/bond0"



    @bond
    @nmtui_bond_over_ethernet_devices
    Scenario: nmtui - bond - over ethernet devices
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Come in "IPv4 CONFIGURATION" category
    * Ensure "Require IPv4 addressing for this connection" is checked
    * Confirm the connection settings
    Then "bond0\s+bond\s+connected" is visible with command "nmcli device" in "45" seconds
    Then Check bond "bond0" link state is "up"
    Then "eth1\s+ethernet\s+connected\s+bond-slave-eth1" is visible with command "nmcli device"
    Then "eth2\s+ethernet\s+connected\s+bond-slave-eth2" is visible with command "nmcli device"
    Then "192.168" is visible with command "ip a s bond0"


    @bond
    @nmtui_bond_infiniband_slaves
    Scenario: nmtui - bond - infiniband slaves
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "InfiniBand"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "infi1"
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "infi2"
    * Confirm the slave settings
    * Confirm the connection settings
    Then "bond0\s+bond" is visible with command "nmcli device" in "60" seconds
    Then "TYPE=InfiniBand" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-eth1"
    Then "TYPE=InfiniBand" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond-slave-eth2"


    @veth
    @bond
    @nmtui_bond_start_on_boot_with_one_slave_auto
    Scenario: nmtui - bond - start on boot with only one slave auto
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    * Execute "nmcli connection up bond0"
    * Execute "nmcli connection up bond-slave-eth1"
    * Execute "nmcli connection up bond-slave-eth2"
    * Reboot
    Then Check bond "bond0" state is "up"
    Then Check slave "eth1" not in bond "bond0" in proc
    Then Check slave "eth2" in bond "bond0" in proc


    #bz1142864
    @bond
    @nmtui_bond_add_mode_active_backup
    Scenario: nmtui - bond - mode - active backup
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Active Backup"
    * Set "Primary" field to "eth2"
    * Confirm the connection settings
    Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/bond0" in "45" seconds
    Then "Primary Slave: eth2" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "45" seconds
    Then Check bond "bond0" link state is "up"


    # #bz1142864
    # @bond
    # @nmtui_bond_add_mode_active_backup_no_primary
    # Scenario: nmtui - bond - mode - active backup without primary
    # * Prepare new connection of type "Bond" named "bond0"
    # * Set "Device" field to "bond0"
    # * Set "Mode" dropdown to "Active Backup"
    # Then Cannot confirm the connection settings


    #bz1142864
    @bond
    @nmtui_bond_change_mode_ac_to_rr
    Scenario: nmtui - bond - mode - change from active backup to round robin
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Active Backup"
    * Set "Primary" field to "eth2"
    * Confirm the connection settings
    * "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/bond0" in "45" seconds
    * "Primary Slave: eth2" is visible with command "cat /proc/net/bonding/bond0"
    * "192.168" is visible with command "ip a s bond0" in "45" seconds
    * Check bond "bond0" link state is "up"
    * Select connection "bond0" in the list
    * Choose to "<Edit...>" a connection
    * Set "Mode" dropdown to "Round-robin"
    * Confirm the connection settings
    * Execute "nmcli connection up bond0"
    Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "45" seconds
    Then Check bond "bond0" link state is "up"



    @bond
    @nmtui_bond_add_mode_round_robin
    Scenario: nmtui - bond - mode - round robin
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Round-robin"
    * Confirm the connection settings
    Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"


    @bond
    @nmtui_bond_add_mode_xor
    Scenario: nmtui - bond - mode - xor
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "XOR"
    * Confirm the connection settings
    Then "Bonding Mode: load balancing \(xor\)" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"


    @bond
    @nmtui_bond_add_mode_broadcast
    Scenario: nmtui - bond - mode - broadcast
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Broadcast"
    * Confirm the connection settings
    Then "Bonding Mode: fault-tolerance \(broadcast\)" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"


    @bond
    @nmtui_bond_add_mode_8023ad
    Scenario: nmtui - bond - mode - 802.3ad
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "802.3ad"
    * Confirm the connection settings
    Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"


    @bond
    @nmtui_bond_add_mode_balance_tlb
    Scenario: nmtui - bond - mode - balance-tlb
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Adaptive Transmit Load Balancing \(tlb\)"
    * Confirm the connection settings
    Then "Bonding Mode: transmit load balancing" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"


    @bond
    @nmtui_bond_add_mode_balance_alb
    Scenario: nmtui - bond - mode - balance-alb
    * Prepare new connection of type "Bond" named "bond0"
    * Set "Device" field to "bond0"
    * Choose to "<Add>" a slave
    * Choose the connection type "Ethernet"
    * Set "Profile name" field to "bond-slave-eth1"
    * Set "Device" field to "eth1"
    * Ensure "Automatically connect" is not checked
    * Confirm the slave settings
    * Choose to "<Add>" a slave
    * Set "Profile name" field to "bond-slave-eth2"
    * Set "Device" field to "eth2"
    * Ensure "Automatically connect" is checked
    * Confirm the slave settings
    * Set "Mode" dropdown to "Adaptive Load Balancing \(alb\)"
    * Confirm the connection settings
    Then "Bonding Mode: adaptive load balancing" is visible with command "cat /proc/net/bonding/bond0"
    Then "192.168" is visible with command "ip a s bond0" in "60" seconds
    Then Check bond "bond0" link state is "up"
