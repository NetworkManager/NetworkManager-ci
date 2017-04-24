 Feature: nmcli: bond

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @slaves @bond
    @bond_add_default_bond
    Scenario: nmcli - bond - add default bond
     * Open editor for a type "bond"
     * Save in editor
     * Enter in editor
     Then Value saved message showed in editor
     * Quit editor
     When Prompt is not running
      And "nm-bond" is visible with command "ip a s nm-bond" in "10" seconds
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond0.0"
     Then Check bond "nm-bond" in proc


    @slaves @bond
    @nmcli_novice_mode_create_bond_with_default_options
    Scenario: nmcli - bond - novice - create bond with default options
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Finish "sleep 3"
    Then Check bond "nm-bond" state is "up"


    @rhbz1368761
    @ver+=1.4.0
    @slaves @bond
    @nmcli_bond_manual_ipv4
    Scenario: nmcli - bond - remove BOOTPROTO dhcp for enslaved ethernet
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name bond0.0 autoconnect no"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name bond0.1 autoconnect no"
    * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 autoconnect no mode active-backup"
    * Execute "nmcli con mod id bond0 ipv4.addresses 10.35.1.2/24 ipv4.gateway 10.35.1.254 ipv4.method manual"
    * Execute "nmcli connection modify id bond0.0 connection.slave-type bond connection.master nm-bond connection.autoconnect yes"
    * Execute "nmcli connection modify id bond0.1 connection.slave-type bond connection.master nm-bond connection.autoconnect yes"
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0.1"
    Then "BOOTPROTO=dhcp" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"
     And "BOOTPROTO=dhcp" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.1"
     And "BOOTPROTO=dhcp" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0"


    @slaves @bond
    @nmcli_novice_mode_create_bond_with_mii_monitor_values
    Scenario: nmcli - bond - novice - create bond with miimon monitor
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "Bonding mode"
     * Submit "0" in editor
     * Expect "Bonding monitoring mode \(miimon\/arp\) \[miimon\]"
     * Enter in editor
     * Expect "Bonding miimon \[100\]"
     * Submit "100" in editor
     * Expect "Bonding downdelay \[0\]"
     * Submit "200" in editor
     * Expect "Bonding updelay \[0\]"
     * Submit "400" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond"
    Then Check bond "nm-bond" link state is "up"
    Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Up Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Down Delay \(ms\): 200" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @nmcli_novice_mode_create_bond_with_arp_monitor_values
    Scenario: nmcli - bond - novice - create bond with arp monitor
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "Bonding mode"
     * Submit "1" in editor
     * Expect "Bonding primary interface \[none\]"
     * Enter in editor
     * Expect "Bonding monitoring mode \(miimon\/arp\) \[miimon\]"
     * Submit "arp" in editor
     * Expect "Bonding arp-interval \[0\]"
     * Submit "100" in editor
     * Expect "Bonding arp-ip-target \[none\]"
     * Submit "192.168.100.1" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Bring "up" connection "bond"
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\): 192.168.100.1" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @nmcli_novice_mode_create_bond-slave_with_default_options
    Scenario: nmcli - bond - novice - create bond-slave with default options
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond-slave" in editor
     * Expect "Interface name"
     * Submit "eth1" in editor
     * Expect "aster"
     * Submit "nm-bond" in editor
    Then "activated" is visible with command "nmcli c show bond-slave-eth1" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @slaves @bond
    @bond_add_slaves
    Scenario: nmcli - bond - add slaves
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @rhbz1057494
    @slaves @bond
    @add_bond_master_via_uuid
    Scenario: nmcli - bond - master via uuid
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "bond0" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond0.0"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @rhbz1369008
    @ver+=1.4.0
    @slaves @bond
    @bond_ifcfg_master_as_device
    Scenario: ifcfg - bond - slave has master as device
    * Add connection type "bond" named "bond0" for device "nm-bond"
    * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
    Then Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc
     And "MASTER=nm-bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"


    @rhbz1369008
    @ver+=1.4.0
    @slaves @bond
    @bond_ifcfg_master_as_device_via_con_name
    Scenario: ifcfg - bond - slave has master as device via conname
    * Add connection type "bond" named "bond0" for device "nm-bond"
    * Add slave connection for master "bond0" on device "eth1" named "bond0.0"
    Then Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc
     And "MASTER=nm-bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"


    @slaves @bond
    @bond_remove_all_slaves
    Scenario: nmcli - bond - remove all slaves
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond0.0"
     * Delete connection "bond0.0"
     Then Check bond "nm-bond" link state is "down"


    @slaves @bond
    @bond_remove_slave
    Scenario: nmcli - bond - remove slave
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Delete connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc


    @slaves
    @bond
    @testcase_301107
    Scenario: nmcli - connection - slave-type and master settings
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add connection type "ethernet" named "bond0.0" for device "eth1"
     * Open editor for connection "bond0.0"
     * Set a property named "connection.slave-type" to "bond" in editor
     * Set a property named "connection.master" to "nm-bond" in editor
     * Submit "yes" in editor
     * Submit "verify fix" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0.0"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc


    @slaves @bond
    @bond_remove_active_bond_profile
    Scenario: nmcli - bond - remove active bond profile
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond0.0"
     Then Check bond "nm-bond" state is "up"
     * Delete connection "bond0"
     * Execute "sleep 3"
     Then Check bond "nm-bond" link state is "down"


    @slaves @bond
    @bond_disconnect
    Scenario: nmcli - bond - disconnect active bond
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Disconnect device "nm-bond"
     Then Check bond "nm-bond" link state is "down"


    @slaves @bond
    @bond_start_by_hand
    Scenario: nmcli - bond - start bond by hand
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Disconnect device "nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     Then Check bond "nm-bond" link state is "down"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @slaves @bond
    @bond_start_by_hand_no_slaves
    Scenario: nmcli - bond - start bond by hand with no slaves
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Disconnect device "nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     Then Check bond "nm-bond" link state is "down"
     * Bring up connection "bond0" ignoring error
     Then Check bond "nm-bond" state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth2" not in bond "nm-bond" in proc


    @slaves @bond
    @bond_activate
    Scenario: nmcli - bond - activate
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Disconnect device "nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     Then Check bond "nm-bond" link state is "down"
     * Open editor for connection "bond0.0"
     * Submit "activate" in editor
     * Enter in editor
     * Quit editor
     * Execute "sleep 3"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth2" not in bond "nm-bond" in proc


    @veth @slaves @bond
    @bond_start_by_hand_with_one_auto_only
    Scenario: nmcli - bond - start bond by hand with on auto only
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @veth @slaves @bond
    @bond_start_on_boot
    Scenario: nmcli - bond - start bond on boot
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @rhbz1158529
    @slaves @bond
    @bond_slaves_start_via_master
    Scenario: nmcli - bond - start slaves via master
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Submit "set connection.autoconnect-slaves 1" in editor
     * Save in editor
     * Quit editor
     * Disconnect device "nm-bond"
     * Bring "up" connection "bond0"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @veth @slaves @bond
    @bond_start_on_boot_with_nothing_auto
    Scenario: nmcli - bond - start bond on boot - nothing auto
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0.1"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Disconnect device "nm-bond"
     * Reboot
     Then Check bond "nm-bond" link state is "down"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth2" not in bond "nm-bond" in proc


    @veth @slaves @bond
    @bond_start_on_boot_with_one_auto_only
    Scenario: nmcli - bond - start bond on boot - one slave auto only
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @veth @slaves @bond
    @bond_start_on_boot_with_bond_and_one_slave_auto
    Scenario: nmcli - bond - start bond on boot - bond and one slave auto
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Submit "set connection.autoconnect no" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0.1"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0"
     * Submit "set connection.autoconnect yes" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth2" in bond "nm-bond" in proc


    @slaves @bond
    @bond_set_miimon_values
    Scenario: nmcli - bond - options - set new miimon values
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0, miimon=100, downdelay=100, updelay=100" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @bond_options_new_arp_values
    Scenario: nmcli - bond - options - set new arp values
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0, arp_interval=10000, arp_ip_target=10.16.135.254" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\): 10.16.135.254" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth2" in proc


    @slaves @bond
    @bond_options_arp_vs_miimon_conflict
    Scenario: nmcli - bond - options - set conflicting values between miimon and arp
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0,miimon=100,arp_interval=10000,arp_ip_target=10.16.135.254" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 10000" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth2" in proc


    @bond
    @bond_option_mode_missing
    Scenario: nmcli - bond - options - mode missing
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to " " in editor
     * Enter in editor
     * Save in editor
     Then Mode missing message shown in editor
     * Set a property named "bond.options" to "mode=0, miimon=100" in editor
     * Save in editor
     * Quit editor


    @slaves @bond
    @bond_add_option
    Scenario: nmcli - bond - options - add values
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Submit "goto bond" in editor
     * Submit "goto options" in editor
     * Submit "add miimon=100" in editor
     * Submit "add updelay=200" in editor
     * Submit "back" in editor
     * Submit "back" in editor
     * Save in editor
     When Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "Up Delay \(ms\): 200" is visible with command "cat /proc/net/bonding/nm-bond"


    @bond
    @bond_mode_incorrect_value
    Scenario: nmcli - bond - options - add incorrect value
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Open editor for connection "bond0"
     * Submit "goto bond" in editor
     * Submit "goto options" in editor
     * Submit "add modem=2" in editor
     Then Wrong bond options message shown in editor
     * Enter in editor
     * Submit "back" in editor
     * Submit "back" in editor
     * Quit editor


    @slaves @bond
    @bond_change_options
    Scenario: nmcli - bond - options - change values
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Submit "goto bond" in editor
     * Submit "goto options" in editor
     * Submit "change" in editor
     * Submit ", miimon=100, updelay=100" in editor
     * Submit "back" in editor
     * Submit "back" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @bond_remove_option
    Scenario: nmcli - bond - options - remove a value
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0, miimon=100, downdelay=100, updelay=100" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     * Open editor for connection "bond0"
     * Submit "goto bond" in editor
     * Submit "goto options" in editor
     * Submit "remove downdelay" in editor
     * Submit "back" in editor
     * Submit "back" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @bond_overwrite_options
    Scenario: nmcli - bond - options - overwrite some value
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0, miimon=999" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 999" is visible with command "cat /proc/net/bonding/nm-bond"


    @slaves @bond
    @bond_mode_balance_rr
    Scenario: nmcli - bond - options - mode set to balance-rr
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=2" in editor
     * Save in editor
     When Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(xor\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=0" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_active_backup
    Scenario: nmcli - bond - options - mode set to active backup
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=1" in editor
     * Save in editor
     When Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_active-backup_primary_set
    Scenario: nmcli - bond - options - mode set to active backup with primary device
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=active-backup,primary=eth1,miimon=100,fail_over_mac=2" in editor
     * Save in editor
     When Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_balance_xor
    Scenario: nmcli - bond - options - mode set to balance xor
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=2" in editor
     * Save in editor
     When Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(xor\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_broadcast
    Scenario: nmcli - bond - options - mode set to broadcast
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=3" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: fault-tolerance \(broadcast\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_8023ad
    Scenario: nmcli - bond - options - mode set to 802.3ad
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=4" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_8023ad_with_lacp_rate_fast
    Scenario: nmcli - bond - options - mode set to 802.3ad with lacp_rate fast
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "mode=802.3ad,miimon=100,xmit_hash_policy=layer2+3,lacp_rate=fast" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Transmit Hash Policy:\s+layer2\+3" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "802.3ad info\s+LACP rate: fast" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_balance_tlb
    Scenario: nmcli - bond - options - mode set to balance-tlb
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "miimon=100,mode=5" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: transmit load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @slaves @bond
    @bond_mode_balance_alb
    Scenario: nmcli - bond - options - mode set to balance-alb
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to "miimon=100,mode=6" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     Then "Bonding Mode: adaptive load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1177860
    @slaves @bond
    @bond_set_mtu
    Scenario: nmcli - bond - set mtu
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0.0"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0.1"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Save in editor
     * Quit editor
     * Open editor for connection "bond0"
     * Set a property named "802-3-ethernet.mtu" to "9000" in editor
     * Set a property named "ipv4.method" to "manual" in editor
     * Set a property named "ipv4.addresses" to "1.1.1.2/24" in editor
     * Save in editor
     * Quit editor
     * Disconnect device "nm-bond"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
    Then Check bond "nm-bond" link state is "up"
    Then Check "nm-bond" has "eth1" in proc
    Then Check "nm-bond" has "eth2" in proc
    Then "mtu 9000" is visible with command "ip a s eth1 |grep mtu" in "15" seconds
    Then "mtu 9000" is visible with command "ip a s eth2 |grep mtu"
    Then "mtu 9000" is visible with command "ip a s nm-bond |grep mtu"


    @rhbz1304641
    @ver+=1.3
    @slaves @bond @restart
    @bond_addreses_restart_persistence
    Scenario: nmcli - bond - addresses restart persistence
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Open editor for connection "bond0"
     * Set a property named "ipv4.method" to "manual" in editor
     * Set a property named "ipv4.addresses" to "1.1.1.2/24" in editor
     * Set a property named "ipv6.method" to "manual" in editor
     * Set a property named "ipv6.addresses" to "1::2/128" in editor
     * Save in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     * restart NM
     When "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "10" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
     * restart NM
     When "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "10" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
     * restart NM
     Then "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "10" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
      And Check bond "nm-bond" link state is "up"
      And Check "nm-bond" has "eth1" in proc
      And Check "nm-bond" has "eth2" in proc
      And "1.1.1.2/24" is visible with command "nmcli connection show bond0 |grep ipv4.addresses"
      And "manual" is visible with command "nmcli connection show bond0 |grep ipv4.method"
      And "1.1.1.2/24" is visible with command "nmcli connection show bond0 |grep IP4.ADDRESS"
      And "1::2/128" is visible with command "nmcli connection show bond0 |grep ipv6.addresses"
      And "manual" is visible with command "nmcli connection show bond0 |grep ipv6.method"
      And "1::2/128" is visible with command "nmcli connection show bond0 |grep IP6.ADDRESS"
      And "fe80" is visible with command "nmcli connection show bond0 |grep IP6.ADDRESS"


    @ver-=1.1
    @dummy
    @bond_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bond - reflect changes from outside of NM
    * Finish "ip link add bond0 type bond"
    When "bond0\s+bond\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link set dev bond0 up"
    When "bond0\s+bond\s+disconnected" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link add dummy0 type dummy"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link set dev dummy0 up"
    * Finish "ip addr add 1.1.1.1/24 dev bond0"
    When "bond0\s+bond\s+connected\s+bond0" is visible with command "nmcli d" in "5" seconds
    * Finish "ifenslave bond0 dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d" in "5" seconds
    Then "BOND.SLAVES:\s+dummy0" is visible with command "nmcli -f bond.slaves dev show bond0"


    @ver+=1.1.1
    @dummy
    @bond_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bond - reflect changes from outside of NM
    * Finish "ip link add bond0 type bond"
    When "bond0\s+bond\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link set dev bond0 up"
    When "bond0\s+bond\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link add dummy0 type dummy"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Finish "ip link set dev dummy0 up"
    * Finish "ip addr add 1.1.1.1/24 dev bond0"
    When "bond0\s+bond\s+connected\s+bond0" is visible with command "nmcli d" in "5" seconds
    * Finish "ifenslave bond0 dummy0"
    When "dummy0\s+dummy\s+connected\s+dummy" is visible with command "nmcli d" in "5" seconds
    Then "BOND.SLAVES:\s+dummy0" is visible with command "nmcli -f bond.slaves dev show bond0"

#FIXME: more tests with arp and conflicts with load balancing can be written

    @rhbz1133544
    @bond
    @bond_dbus_creation
    Scenario: NM - bond - dbus api bond setting
    * Execute "python tmp/dbus-set-bond.py"
    Then "bond0.*bond\s+nm-bond" is visible with command "nmcli connection"


    @rhbz1171009
    @slaves @bond
    @bond_mode_by_number_in_ifcfg
    Scenario: NM - bond - ifcfg - mode set by number
     * Add connection type "bond" named "bond0" for device "nm-bond"
     * Add slave connection for master "nm-bond" on device "eth3" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth4" named "bond0.1"
     * Execute "sed -i 's/BONDING_OPTS=mode=balance-rr/BONDING_OPTS=mode=5/' /etc/sysconfig/network-scripts/ifcfg-bond0"
     * Execute "sudo nmcli connection reload"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: transmit load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1299103 @rhbz1348198
    @slaves @bond
    @bond_set_active_backup_options
    Scenario: nmcli - bond - set active backup options
     * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=active-backup,active_slave=eth2,num_grat_arp=3,num_unsol_na=3"
     * Add a new connection of type "ethernet" and options "con-name bond0.1 ifname eth2 master nm-bond autoconnect no"
     * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then "BONDING_OPTS=\"mode=active-backup num_grat_arp=3 num_unsol_na=3 active_slave=eth2\"" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0"
      #And "Currently Active Slave: eth2" is visible with command "cat /proc/net/bonding/nm-bond"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"


    @rhbz1299103
    @slaves @bond
    @bond_set_ad_options
    Scenario: nmcli - bond - set 802.3ad options
     * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=802.3ad,ad_actor_sys_prio=666,ad_actor_system=00:00:00:00:11:00,min_links=2,ad_user_port_key=2,all_slaves_active=1"
     * Add a new connection of type "ethernet" and options "con-name bond0.1 ifname eth2 master nm-bond autoconnect no"
     * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     #When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then "system priority: 666" is visible with command "cat /proc/net/bonding/nm-bond"
      And "2" is visible with command "cat /sys/class/net/nm-bond/bonding/ad_user_port_key"
      And "00:00:00:00:11:00" is visible with command "cat /sys/class/net/nm-bond/bonding/ad_actor_system"
      And "1" is visible with command "cat /sys/class/net/nm-bond/bonding/all_slaves_active"
      And "2" is visible with command "cat /sys/class/net/nm-bond/bonding/min_links"


    @rhbz1299103
    @slaves @bond
    @bond_set_arp_all_targets
    Scenario: nmcli - bond - set arp_all_targets
     * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=active-backup,arp_interval=10000,arp_ip_target=10.16.135.254,arp_all_targets=1"
     * Add a new connection of type "ethernet" and options "con-name bond0.1 ifname eth2 master nm-bond autoconnect no"
     * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then "1" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_all_targets"


    @rhbz1299103
    @slaves @bond
    @bond_set_packets_per_slave_option
    Scenario: nmcli - bond - set packets_per_slave option
     * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=balance-rr,packets_per_slave=1024"
     * Add a new connection of type "ethernet" and options "con-name bond0.1 ifname eth2 master nm-bond autoconnect no"
     * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then "1024" is visible with command "cat /sys/class/net/nm-bond/bonding/packets_per_slave"


    @rhbz1299103 @rhbz1348573
    @slaves @bond
    @bond_set_balance_tlb_options
    Scenario: nmcli - bond - set balance-tlb options
     * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=balance-tlb,tlb_dynamic_lb=0,lp_interval=666"
     * Add a new connection of type "ethernet" and options "con-name bond0.1 ifname eth2 master nm-bond autoconnect no"
     * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     #When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     Then "0" is visible with command "cat /sys/class/net/nm-bond/bonding/tlb_dynamic_lb"
      And "666" is visible with command "cat /sys/class/net/nm-bond/bonding/lp_interval"


    @rhbz979425
    @slaves @bond
    @bond_device_rename
    Scenario: NM - bond - device rename
     * Add connection type "bond" named "bond0" for device "bondy"
     * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
     * Add slave connection for master "nm-bond" on device "eth2" named "bond0.1"
     * Bring "down" connection "bond0"
     * Open editor for connection "bond0"
     * Set a property named "connection.interface-name" to "nm-bond" in editor
     * Save in editor
     Then Value saved message showed in editor
     * Quit editor
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1243371
    @bond @restart
    @delete_addrgenmode_bond
    Scenario: NM - bond - addrgenmode bond delete
    * Execute "systemctl stop NetworkManager"
    * Execute "ip l add bond0 type bond"
    * Execute "ip l set eth2 down; ip l set eth2 master bond0; ip l set eth2 addrgenmode none; ip l set eth2 up"
    * Execute "ip l set eth1 down; ip l set eth1 master bond0; ip l set eth1 addrgenmode none; ip l set eth1 up"
    * Restart NM
    * Execute "sleep 5"
    * Note the output of "pidof NetworkManager" as value "orig_pid"
    * Execute "ip l del bond0"
    * Note the output of "pidof NetworkManager" as value "new_pid"
    Then Check noted values "orig_pid" and "new_pid" are the same


    @rhbz1183420
    @bond @bridge @slaves
    @bond_enslave_to_bridge
    Scenario: nmcli - bond - enslave bond device to bridge
     * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
     * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 master bridge0"
     * Add a new connection of type "ethernet" and options "ifname eth1 con-name bond-slave-eth1 master nm-bond"
     * Bring "up" connection "bond-slave-eth1"
    Then "bridge0:bridge:connected:bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "45" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


    @rhbz1360386
    @ver+=1.7.1
    @bond @bridge @slaves @team
    @bridge_team_bond_autoconnect_nested_slaves
    Scenario: nmcli - bond - autoconnect slaves of slaves
     * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0 autoconnect no connection.autoconnect-slaves 1"
     * Add a new connection of type "team" and options "ifname nm-team con-name team0 master bridge0 autoconnect no connection.autoconnect-slaves 1"
     * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 master nm-team autoconnect no connection.autoconnect-slaves 1"
     * Add a new connection of type "ethernet" and options "ifname eth1 con-name bond-slave-eth1 master nm-bond autoconnect no"
     * Bring "up" connection "bridge0"
    Then "bridge0:bridge:connected:bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "45" seconds
     And "nm-team:team:connected:team0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


     @rhbz1352131
     @ver+=1.4.0
     @bond
     @bond_8023ad_no_error
     Scenario: nmcli - bond - no error in 8023ad setup
      * Run child "journalctl -f > /tmp/journal.txt"
      * Execute "nmcli connection add type bond ifname bond0 con-name bond0 mode 4 miimon 100"
      * Execute "pkill journalctl"
      Then "mode dependency failed, not supported in mode 802.3ad" is not visible with command "grep arp_validate /tmp/journal.txt"


     @rhbz1364275
     @ver+=1.4
     @bond @bridge @slaves
     @bond_in_bridge_mtu
     Scenario: nmcli - bond - enslave bond device to bridge and set mtu
      * Add a new connection of type "bridge" and options "con-name bridge0 autoconnect no ifname bridge0 -- 802-3-ethernet.mtu 9000 ipv4.method manual ipv4.addresses 192.168.177.100/24 ipv4.gateway 192.168.177.1"
      * Add a new connection of type "bond" and options "con-name bond0 autoconnect no ifname nm-bond master bridge0 -- 802-3-ethernet.mtu 9000"
      * Add a new connection of type "ethernet" and options "con-name bond0.0 autoconnect no ifname eth1 master nm-bond -- 802-3-ethernet.mtu 9000"
      * Bring "up" connection "bridge0"
      * Bring "up" connection "bond0"
      * Bring "up" connection "bond0.0"
      Then "mtu 9000" is visible with command "ip a s eth1"
      Then "mtu 9000" is visible with command "ip a s nm-bond"
      Then "mtu 9000" is visible with command "ip a s bridge0"


    @bond
    @bond_describe
    Scenario: nmcli - bond - describe bond
     * Open editor for a type "bond"
     Then Check "<<< bond >>>|=== \[options\] ===|\[NM property description\]" are present in describe output for object "bond"
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object "bond.options"
      * Submit "g b" in editor
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object "options"
      * Submit "g o" in editor
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object " "


     @rhbz1376784
     @ver+=1.4.0
     @slaves @bond
     @reapply_unchanged_slave
     Scenario: nmcli - bond - reapply unchanged slave
      * Add connection type "bond" named "bond0" for device "nm-bond"
      * Add slave connection for master "nm-bond" on device "eth1" named "bond0.0"
      * Bring "up" connection "bond0"
      * Bring "up" connection "bond0.0"
      Then "Connection successfully reapplied to device" is visible with command "nmcli dev reapply eth1"


    @rhbz1333983
    @ver+=1.4.0
    @slaves @bond @vlan @restart
    @vlan_over_no_L3_bond_restart_persistence
    Scenario: nmcli - bond - restart persistence of no L3 bond in vlan
    * Add a new connection of type "bond" and options "con-name bond0 autoconnect no ifname nm-bond ipv4.method disable ipv6.method ignore"
    * Add a new connection of type "ethernet" and options "con-name bond0.0 autoconnect no ifname eth1 master nm-bond"
    * Add a new connection of type "ethernet" and options "con-name bond0.1 autoconnect no ifname eth2 master nm-bond"
    * Add a new connection of type "vlan" and options "con-name vlan dev nm-bond id 153 autoconnect no ip4 10.66.66.1/24 ipv6.method ignore"
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0.1"
    * Bring "up" connection "vlan"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "eth2:connected:bond0.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "nm-bond.153:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
    * Execute "systemctl stop NetworkManager"
    When "state UP" is visible with command "ip a s eth1"
     And "state UP" is visible with command "ip a s eth2"
     And "state UP" is visible with command "ip a s nm-bond"
     And "state UP" is visible with command "ip a s nm-bond.153"
     And "10.66.66.1/24" is visible with command "ip a s nm-bond.153"
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
     And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "eth2:connected:bond0.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "nm-bond.153:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "10.66.66.1/24" is visible with command "ip a s nm-bond.153"


     @rhbz1371126
     @ver+=1.4.0
     @slaves @bond @teardown_testveth @restart
     @bond_leave_L2_only_up_when_going_down
     Scenario: nmcli - bond - leave UP with L2 only config
      * Prepare simulated test "testX" device
      * Add a new connection of type "bond" and options "con-name bond0 ifname nm-bond autoconnect no ipv4.method disabled ipv6.method ignore"
      * Add a new connection of type "ethernet" and options "con-name bond0.0 ifname testX autoconnect no connection.master nm-bond connection.slave-type bond"
      * Bring "up" connection "bond0.0"
      When "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
       And "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond"
       And "inet6 2620" is visible with command "ip -6 a s nm-bond" in "5" seconds
       And "tentative" is not visible with command "ip -6 a s nm-bond" in "5" seconds
      * Execute "killall NetworkManager && sleep 5"
      * Execute "systemctl restart NetworkManager"
      When "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond" for full "10" seconds
       And "inet6 2620" is visible with command "ip -6 a s nm-bond"
      * Bring "up" connection "bond0.0"
      Then "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "20" seconds
       And "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond"
       And "inet6 2620" is visible with command "ip -6 a s nm-bond" in "5" seconds
       And "tentative" is not visible with command "ip -6 a s nm-bond" in "5" seconds
