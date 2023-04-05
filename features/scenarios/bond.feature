 Feature: nmcli: bond
 
    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhelver+=9 @fedoraver+=32
    @plugin_default
    @bond_config_file
    Scenario: nmcli - bond - check keyfile config
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no mode active-backup
          """
    * Check keyfile "/etc/NetworkManager/system-connections/bond0.nmconnection" has options
            """
            connection.id=bond0
            connection.type=bond
            connection.autoconnect=false
            connection.interface-name=nm-bond
            bond.mode=active-backup
            """


    @rhelver-=8 @fedoraver-=31
    @plugin_default
    @bond_config_file
    Scenario: nmcli - bond - check ifcfg config
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no mode active-backup
          """
    * Check ifcfg-file "/etc/sysconfig/network-scripts/ifcfg-bond0" has options
            """
            BONDING_OPTS=mode=active-backup
            TYPE=Bond
            BONDING_MASTER=yes
            DEFROUTE=yes
            NAME=bond0
            DEVICE=nm-bond
            ONBOOT=no
            """


    @bond_add_default_bond
    Scenario: nmcli - bond - add default bond
     * Cleanup connection "bond0" and device "nm-bond"
     * Open editor for a type "bond"
     * Save in editor
     * Enter in editor
     Then Value saved message showed in editor
     * Quit editor
     #When Prompt is not running
      And "nm-bond" is visible with command "ip a s nm-bond" in "10" seconds
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     Then Check bond "nm-bond" in proc


    @rhbz1440957
    @ver+=1.8.0
    @nmcli_editor_for_new_connection_set_con_id
    Scenario: nmcli - bond - add bond-slave via new connection editor
     * Cleanup connection "bond0" and device "nm-bond"
     * Cleanup connection "bond0.0"
     * Open editor for a new connection
     * Expect "connection type"
     * Submit "bond-slave"
     * Expect "nmcli"
     * Submit "set con.id bond0.0"
     * Save in editor
     * Expect "Saving the connection with"
     * Submit "yes" in editor
     When Value saved message showed in editor
     * Quit editor
     #When Prompt is not running
     Then "bond0.0" is visible with command "nmcli con"


    @ver+=1.33 @ver-=1.39.6
    @nmcli_novice_mode_create_bond_with_default_options
    Scenario: nmcli - bond - novice - create bond with default options
     * Cleanup connection "bond" and device "nm-bond"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
    Then "nm-bond" is visible with command "ip a s nm-bond" in "3" seconds
    Then Check bond "nm-bond" state is "up"


    @ver+=1.39.7
    @nmcli_novice_mode_create_bond_with_default_options
    Scenario: nmcli - bond - novice - create bond with default options
     * Cleanup connection "bond-nm-bond" and device "nm-bond"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Interface name"
     * Submit "nm-bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
    Then "nm-bond" is visible with command "ip a s nm-bond" in "3" seconds
    Then Check bond "nm-bond" state is "up"


    @rhbz1368761
    @ver+=1.4.0
    @ifcfg-rh
    @nmcli_bond_manual_ipv4
    Scenario: nmcli - bond - remove BOOTPROTO dhcp for enslaved ethernet
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options
          """
          autoconnect no
          """
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no mode active-backup
          ip4 172.16.1.1/24
          """
    * Modify connection "bond0.0" changing options "connection.slave-type bond connection.master nm-bond connection.autoconnect yes"
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.0"
    Then "BOOTPROTO=dhcp" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"
     And "BOOTPROTO=dhcp" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0"


    @ver+=1.33 @ver-=1.39.6
    @nmcli_novice_mode_create_bond_with_mii_monitor_values
    Scenario: nmcli - bond - novice - create bond with miimon monitor
     * Cleanup connection "bond" and device "nm-bond"
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
     * Submit "400" in editor
     * Expect "Bonding updelay \[0\]"
     * Submit "400" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
    # Remove double up to prevent 1753214
    # * Bring "up" connection "bond"
    When "activated" is visible with command "nmcli c show bond" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Up Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Down Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/nm-bond"


    @ver+=1.39.7
    @nmcli_novice_mode_create_bond_with_mii_monitor_values
    Scenario: nmcli - bond - novice - create bond with miimon monitor
     * Cleanup connection "bond-nm-bond" and device "nm-bond"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Interface name"
     * Submit "nm-bond" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "Bonding mode"
     * Submit "0" in editor
     * Expect "Bonding monitoring mode \(miimon\/arp\) \[miimon\]"
     * Enter in editor
     * Expect "Bonding miimon \[100\]"
     * Submit "100" in editor
     * Expect "Bonding downdelay \[0\]"
     * Submit "400" in editor
     * Expect "Bonding updelay \[0\]"
     * Submit "400" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond-nm-bond"
    When "activated" is visible with command "nmcli c show bond-nm-bond" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Up Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Down Delay \(ms\): 400" is visible with command "cat /proc/net/bonding/nm-bond"


    @ver+=1.33 @ver-=1.39.6
    @nmcli_novice_mode_create_bond_with_arp_monitor_values
    Scenario: nmcli - bond - novice - create bond with arp monitor
     * Cleanup connection "bond-1" and device "nm-bond1"
     * Cleanup connection "bond" and device "nm-bond"
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
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond"
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\):.*192.168.100.1" is visible with command "cat /proc/net/bonding/nm-bond"


    @ver+=1.39.7
    @nmcli_novice_mode_create_bond_with_arp_monitor_values
    Scenario: nmcli - bond - novice - create bond with arp monitor
     * Cleanup connection "bond-nm-bond" and device "nm-bond"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond" in editor
     * Expect "Interface name"
     * Submit "nm-bond" in editor
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
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond-nm-bond"
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\):.*192.168.100.1" is visible with command "cat /proc/net/bonding/nm-bond"


    @ver-1.20
    @nmcli_novice_mode_create_bond-slave_with_default_options
    Scenario: nmcli - bond - novice - create bond-slave with default options
     * Cleanup connection "bond-slave" and device "eth1"
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
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


    @ver+=1.21.1 @ver-=1.32
    @nmcli_novice_mode_create_bond-slave_with_default_options
    Scenario: nmcli - bond - novice - create bond-slave with default options
     * Cleanup connection "bond-slave" and device "eth1"
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond-slave" in editor
     * Expect "aster"
     * Submit "nm-bond" in editor
     * Expect "Do you want to provide it\? \(yes\/no\) \[yes\]"
     * Submit "yes" in editor
     * Expect "Interface name"
     * Submit "eth1" in editor
    Then "activated" is visible with command "nmcli c show bond-slave" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @ver+=1.33 @ver-=1.39.6
    @nmcli_novice_mode_create_bond-slave_with_default_options
    Scenario: nmcli - bond - novice - create bond-slave with default options
     * Cleanup connection "bond-slave" and device "eth1"
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond-slave" in editor
     * Expect "aster"
     * Submit "nm-bond" in editor
     * Expect "Do you want to provide it\? \(yes\/no\) \[yes\]"
     * Submit "yes" in editor
     * Expect "Interface name"
     * Submit "eth1" in editor
     * Expect "Do you want to provide it\? \(yes\/no\) \[yes\]"
     * Submit "no"
    Then "activated" is visible with command "nmcli c show bond-slave" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @ver+=1.39.7
    @nmcli_novice_mode_create_bond-slave_with_default_options
    Scenario: nmcli - bond - novice - create bond-slave with default options
     * Cleanup connection "bond-slave" and device "eth1"
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "bond-slave" in editor
     * Expect "aster"
     * Submit "nm-bond" in editor
     * Expect "Interface name"
     * Submit "eth1" in editor
     * Expect "Queue ID"
     * Enter in editor
    Then "activated" is visible with command "nmcli c show bond-slave" in "45" seconds
    Then Check bond "nm-bond" link state is "up"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @bond_add_slaves
    Scenario: nmcli - bond - add slaves
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @rhbz1949127
    @ver+=1.33
    @ver-1.40.2
    @bond_add_slaves_with_queue-id
    Scenario: nmcli - bond - add slaves
    * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ipv4.addresses 1.2.3.4/24 ipv4.method manual
           """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options
           """
           master nm-bond queue-id 2
           """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options
           """
           master nm-bond queue-id 4
           """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
    Then Check slave "eth1" in bond "nm-bond" in proc
     And "2" is visible with command "nmcli -f bond-port.queue-id con show bond0.0"
     And "Slave queue ID: 2" is visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth1/,/^$/p'"
    Then Check slave "eth4" in bond "nm-bond" in proc
     And "Slave queue ID: 4" is visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth4/,/^$/p'"
     And "4" is visible with command "nmcli -f bond-port.queue-id con show bond0.1"


    @rhbz1949127 @rhbz2126262
    @ver+=1.40.2
    @bond_add_slaves_with_queue-id
    Scenario: nmcli - bond - add slaves
    * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ipv4.addresses 1.2.3.4/24 ipv4.method manual
           """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options
           """
           master nm-bond queue-id 2
           """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options
           """
           master nm-bond queue-id 4
           """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
    When Check slave "eth1" in bond "nm-bond" in proc
     And "2" is visible with command "nmcli -f bond-port.queue-id con show bond0.0"
     And "Slave queue ID: 2" is visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth1/,/^$/p'"
    When Check slave "eth4" in bond "nm-bond" in proc
     And "Slave queue ID: 4" is visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth4/,/^$/p'"
     And "4" is visible with command "nmcli -f bond-port.queue-id con show bond0.1"
    * Modify connection "bond0.0" changing options "connection.master '' connection.slave-type ''"
    * Bring "up" connection "bond0.0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
    Then Check slave "eth1" not in bond "nm-bond" in proc
     And "2" is not visible with command "nmcli -f bond-port.queue-id con show bond0.0"
     And "Slave queue ID: 2" is not visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth1/,/^$/p'"
    Then Check slave "eth4" in bond "nm-bond" in proc
     And "Slave queue ID: 4" is visible with command "cat /proc/net/bonding/nm-bond | sed -n '/eth4/,/^$/p'"
     And "4" is visible with command "nmcli -f bond-port.queue-id con show bond0.1"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0.0" in "40" seconds


    @rhbz1057494
    @add_bond_master_via_uuid
    Scenario: nmcli - bond - master via uuid
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add slave connection for master "bond0" on device "eth1" named "bond0.0"
     * Bring "up" connection "bond0.0"
    Then Check slave "eth1" in bond "nm-bond" in proc


    @rhbz1369008
    @ver+=1.4.0
    @ifcfg-rh
    @bond_ifcfg_master_as_device
    Scenario: ifcfg - bond - slave has master as device
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
    Then Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc
     And "MASTER=nm-bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"


    @rhbz1434555
    @ver+=1.8.0
    @restart_if_needed
    @bond_ifcfg_master_called_ethernet
    Scenario: ifcfg - bond - master with Ethernet type
    * Append "DEVICE=nm-bond" to ifcfg file "bond0"
    * Append "NAME=bond0" to ifcfg file "bond0"
    * Append "TYPE=Ethernet" to ifcfg file "bond0"
    * Append "BONDING_OPTS='miimon=100 mode=4 lacp_rate=1'" to ifcfg file "bond0"
    * Append "BONDING_MASTER=yes" to ifcfg file "bond0"
    * Append "NM_CONTROLLED=yes" to ifcfg file "bond0"
    * Append "BOOTPROTO=none" to ifcfg file "bond0"
    * Append "USERCTL=no" to ifcfg file "bond0"
    * Execute "nmcli con reload"
    * Cleanup device "nm-bond"
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
    * Restart NM
    Then Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc
     And "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "50" seconds
     And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1369008
    @ver+=1.4.0
    @ifcfg-rh
    @bond_ifcfg_master_as_device_via_con_name
    Scenario: ifcfg - bond - slave has master as device via conname
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "bond0" on device "eth1" named "bond0.0"
    Then Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc
     And "MASTER=nm-bond" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-bond0.0"


     @ver+=1.8.0
     @bond_keyfile_master
     Scenario: ifcfg - bond - master with Ethernet type
     * Create keyfile "/etc/NetworkManager/system-connections/bond0.nmconnection"
       """
       [connection]
       id=bond0
       uuid=4a2b8b74-12cd-4f94-b086-3c62542d027c
       type=bond
       interface-name=nm-bond
       autoconnect=true
       permissions=

       [bond]
       lacp_rate=1
       miimon=100
       mode=802.3ad

       [ipv4]
       dns-search=
       method=auto

       [ipv6]
       addr-gen-mode=stable-privacy
       dns-search=
       method=auto

       [proxy]
       """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     Then Check bond "nm-bond" link state is "up"
      And Check slave "eth1" in bond "nm-bond" in proc
      And "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "50" seconds
      And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @bond_remove_all_slaves
    Scenario: nmcli - bond - remove all slaves
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     * Delete connection "bond0.0"
     Then Check bond "nm-bond" link state is "down"


    @bond_remove_slave
    Scenario: nmcli - bond - remove slave
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Delete connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc


    @bond_slave_type
    Scenario: nmcli - bond - slave-type and master settings
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1"
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


    @bond_remove_active_bond_profile
    Scenario: nmcli - bond - remove active bond profile
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     Then Check bond "nm-bond" state is "up"
     * Delete connection "bond0"
     * Wait for "3" seconds
     Then Check bond "nm-bond" link state is "down"


    @bond_disconnect
    Scenario: nmcli - bond - disconnect active bond
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Disconnect device "nm-bond"
     Then Check bond "nm-bond" link state is "down"


    @bond_start_by_hand
    Scenario: nmcli - bond - start bond by hand
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     * Disconnect device "nm-bond"
     Then Check bond "nm-bond" link state is "down"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @bond_start_by_hand_no_slaves
    Scenario: nmcli - bond - start bond by hand with no slaves
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     * Disconnect device "nm-bond"
     Then Check bond "nm-bond" link state is "down"
     * Bring "up" connection "bond0" ignoring error
     Then Check bond "nm-bond" state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth4" not in bond "nm-bond" in proc


    @bond_activate
    Scenario: nmcli - bond - activate
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"
     * Disconnect device "nm-bond"
     Then Check bond "nm-bond" link state is "down"
     * Open editor for connection "bond0.0"
     * Submit "activate" in editor
     * Enter in editor
     * Quit editor
     * Wait for "3" seconds
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth4" not in bond "nm-bond" in proc


    @rhbz1386872
    @ver+=1.8.0
    @bond_mac_spoof
    Scenario: nmcli - bond - mac spoof
    * Add "bond" connection named "bond0" with options
          """
          ip4 172.16.1.1/24
          ethernet.cloned-mac-address 02:02:02:02:02:02
          """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
    * Bring "up" connection "bond0.0"
    Then "02:02:02:02:02:02" is visible with command "ip a s eth1"
     And "02:02:02:02:02:02" is visible with command "ip a s nm-bond"
     And Check bond "nm-bond" link state is "up"
     And Check slave "eth1" in bond "nm-bond" in proc


    @rhbz1472965 @rhbz1649394
    @ver+=1.16.2
    @bond_mac_reconnect_preserve
    Scenario: nmcli - bond - mac reconnect preserve
    * Note the output of "nmcli -g GENERAL.HWADDR device show eth1" as value "old_eth1"
    * Add "bond-slave" connection named "bond0.0" for device "eth1" with options "master nm-bond"
    * Add "bond" connection named "bond0" with options
          """
          ip4 172.16.1.1/24
          """
    * Execute "nmcli con up bond0.0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    #* Bring "up" connection "bond0.0"
    * Note the output of "nmcli -g GENERAL.HWADDR device show eth1" as value "new_eth1"
    * Note the output of "nmcli -g GENERAL.HWADDR device show nm-bond" as value "old_nm-bond"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Note the output of "nmcli -g GENERAL.HWADDR device show eth1" as value "newest_eth1"
    * Note the output of "nmcli -g GENERAL.HWADDR device show nm-bond" as value "new_nm-bond"
    Then Check noted values "old_eth1" and "new_eth1" are the same
     And Check noted values "newest_eth1" and "new_eth1" are the same
     And Check noted values "old_nm-bond" and "old_nm-bond" are the same


    @bond_start_by_hand_with_one_auto_only
    Scenario: nmcli - bond - start bond by hand with on auto only
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0.0" changing options "autoconnect no"
     * Bring "up" connection "bond0"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @restart_if_needed
    @bond_start_on_boot
    Scenario: nmcli - bond - start bond on boot
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0.0" changing options "autoconnect yes"
     * Modify connection "bond0.1" changing options "autoconnect yes"
     * Bring "up" connection "bond0"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @rhbz1959961
    @ver+=1.30.0
    @restart_if_needed
    @bond_connect_slave_over_ethernet_upon_reboot
    Scenario: NM - bond - autoconnect slaves - if ethernet exist
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options
          """
          autoconnect yes
          """
    * Bring "up" connection "bond0.0"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          con.autoconnect-sl 1
          con.autoconnect-priority 1
          ipv4.method manual
          ipv4.addresses 192.168.100.12/24
          ipv4.dhcp-client-id mac
          ipv6.method disabled
          autoconnect yes
          """
    * Add "ethernet" connection named "bond0.1" for device "eth1" with options
          """
          con.autoconnect-priority 1
          connection.master nm-bond
          connection.slave-type bond
          autoconnect yes
          """
    * Reboot
    Then "bond0.0" is not visible with command "nmcli -g name connection show -a"
    Then "bond0.1" is visible with command "nmcli -g name connection show -a"
    Then "activated" is visible with command "nmcli c show bond0" in "45" seconds


    @rhbz1420708
    @ver+=1.7.9
    @rhelver-=7 @fedoraver-=0 @rhel_pkg
    @restart_if_needed
    @bond_default_rhel7_slaves_ordering
    Scenario: NM - bond - default rhel7 slaves ordering (ifindex)
    * Prepare simulated test "eth11" device
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "orig_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "orig_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "orig_eth5"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "nm-bond" on device "eth11" named "bond0.0"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Add slave connection for master "nm-bond" on device "eth5" named "bond0.2"
    * Bring "down" connection "bond0" ignoring error
    * Bring "down" connection "bond0.0" ignoring error
    * Bring "down" connection "bond0.1" ignoring error
    * Bring "down" connection "bond0.2" ignoring error
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Execute "ip a s"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    When Check noted values "orig_eth4" and "new_eth11" are the same
     And Check noted values "new_eth4" and "new_eth4" are the same
     And Check noted values "new_eth4" and "new_eth5" are the same
     And Check noted values "new_eth4" and "bond" are the same
    * Delete connection "bond0.1"
    * Bring "down" connection "bond0.0"
    * Bring "down" connection "bond0.2"
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    Then Check noted values "orig_eth5" and "new_eth5" are the same
     And Check noted values "new_eth5" and "new_eth11" are the same
     And Check noted values "new_eth5" and "bond" are the same


    @rhbz1420708
    @ver+=1.7.9
    @restart_if_needed
    @bond_slaves_ordering_by_ifindex
    Scenario: NM - bond - ifindex slaves ordering
    * Prepare simulated test "eth11" device
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "orig_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "orig_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "orig_eth5"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "nm-bond" on device "eth11" named "bond0.0"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Add slave connection for master "nm-bond" on device "eth5" named "bond0.2"
    * Bring "down" connection "bond0" ignoring error
    * Bring "down" connection "bond0.0" ignoring error
    * Bring "down" connection "bond0.1" ignoring error
    * Bring "down" connection "bond0.2" ignoring error
    * Create NM config file "99-bond.conf" with content
      """
      [main]
      slaves-order=index
      """
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Execute "ip a s"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    When Check noted values "orig_eth4" and "new_eth11" are the same
     And Check noted values "new_eth4" and "new_eth4" are the same
     And Check noted values "new_eth4" and "new_eth5" are the same
     And Check noted values "new_eth4" and "bond" are the same
    * Delete connection "bond0.1"
    * Bring "down" connection "bond0.0"
    * Bring "down" connection "bond0.2"
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    Then Check noted values "orig_eth5" and "new_eth5" are the same
     And Check noted values "new_eth5" and "new_eth11" are the same
     And Check noted values "new_eth5" and "bond" are the same


    @rhbz1420708
    @ver+=1.7.9
    @restart_if_needed
    @bond_slaves_ordering_by_ifindex_with_autoconnect_slaves
    Scenario: NM - bond - autoconnect slaves - ifindex slaves ordering
    * Prepare simulated test "eth11" device
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "orig_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "orig_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "orig_eth5"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "nm-bond" on device "eth11" named "bond0.0"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Add slave connection for master "nm-bond" on device "eth5" named "bond0.2"
    * Execute "nmcli con modify bond0 con.autoconnect-sl 1"
    * Create NM config file "99-bond.conf" with content
      """
      [main]
      slaves-order=index
      """
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Execute "ip a s"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    When Check noted values "orig_eth4" and "new_eth11" are the same
     And Check noted values "new_eth4" and "new_eth4" are the same
     And Check noted values "new_eth4" and "new_eth5" are the same
     And Check noted values "new_eth4" and "bond" are the same
    * Delete connection "bond0.1"
    * Bring "down" connection "bond0.0"
    * Bring "down" connection "bond0.2"
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    Then Check noted values "orig_eth5" and "new_eth5" are the same
     And Check noted values "new_eth5" and "new_eth11" are the same
     And Check noted values "new_eth5" and "bond" are the same


    @rhbz1420708
    @ver+=1.7.9
    @restart_if_needed
    @bond_slaves_ordering_by_name
    Scenario: NM - bond - alphabet slaves ordering
    * Prepare simulated test "eth11" device
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "orig_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "orig_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "orig_eth5"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "nm-bond" on device "eth11" named "bond0.0"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Add slave connection for master "nm-bond" on device "eth5" named "bond0.2"
    * Bring "down" connection "bond0" ignoring error
    * Bring "down" connection "bond0.0" ignoring error
    * Bring "down" connection "bond0.1" ignoring error
    * Bring "down" connection "bond0.2" ignoring error
    * Create NM config file "99-bond.conf" with content
      """
      [main]
      slaves-order=name
      """
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Execute "ip a s"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    When Check noted values "orig_eth11" and "new_eth11" are the same
     And Check noted values "new_eth11" and "new_eth4" are the same
     And Check noted values "new_eth11" and "new_eth5" are the same
     And Check noted values "new_eth11" and "bond" are the same
    * Delete connection "bond0.0"
    * Bring "down" connection "bond0.1"
    * Bring "down" connection "bond0.2"
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    Then Check noted values "orig_eth4" and "new_eth4" are the same
     And Check noted values "new_eth4" and "new_eth5" are the same
     And Check noted values "new_eth4" and "bond" are the same


    @rhbz1420708
    @ver+=1.7.9
    @restart_if_needed
    @bond_slaves_ordering_by_name_with_autoconnect_slaves
    Scenario: NM - bond - autoconnect slaves - alphabet slaves ordering
    * Prepare simulated test "eth11" device
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "orig_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "orig_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "orig_eth5"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
    * Add slave connection for master "nm-bond" on device "eth11" named "bond0.0"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Add slave connection for master "nm-bond" on device "eth5" named "bond0.2"
    * Execute "nmcli con modify bond0 con.autoconnect-sl 1"
    * Create NM config file "99-bond.conf" with content
      """
      [main]
      slaves-order=name
      """
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth11" in bond "nm-bond" in proc
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Execute "ip a s"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth11" as value "new_eth11"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    When Check noted values "orig_eth11" and "new_eth11" are the same
     And Check noted values "new_eth11" and "new_eth4" are the same
     And Check noted values "new_eth11" and "new_eth5" are the same
     And Check noted values "new_eth11" and "bond" are the same
    * Delete connection "bond0.0"
    * Bring "down" connection "bond0.1"
    * Bring "down" connection "bond0.2"
    * Wait for "1" seconds
    * Reboot
    When Check bond "nm-bond" link state is "up"
     And Check slave "eth4" in bond "nm-bond" in proc
     And Check slave "eth5" in bond "nm-bond" in proc
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth4" as value "new_eth4"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth5" as value "new_eth5"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show nm-bond" as value "bond"
    Then Check noted values "orig_eth4" and "new_eth4" are the same
     And Check noted values "new_eth4" and "new_eth5" are the same
     And Check noted values "new_eth4" and "bond" are the same


    @rhbz1158529
    @bond_slaves_start_via_master
    Scenario: nmcli - bond - start slaves via master
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "connection.autoconnect-slaves 1"
     * Disconnect device "nm-bond"
     * Bring "up" connection "bond0"
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @restart_if_needed
    @bond_start_on_boot_with_nothing_auto
    Scenario: nmcli - bond - start bond on boot - nothing auto
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0.0" changing options "connection.autoconnect no"
     * Modify connection "bond0.1" changing options "connection.autoconnect no"
     * Modify connection "bond0" changing options "connection.autoconnect no"
     * Disconnect device "nm-bond"
     * Reboot
     Then Check bond "nm-bond" link state is "down"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth4" not in bond "nm-bond" in proc


    @restart_if_needed
    @bond_start_on_boot_with_one_auto_only
    Scenario: nmcli - bond - start bond on boot - one slave auto only
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect yes"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @restart_if_needed
    @bond_start_on_boot_with_bond_and_one_slave_auto
    Scenario: nmcli - bond - start bond on boot - bond and one slave auto
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0.0" changing options "connection.autoconnect no"
     * Modify connection "bond0.1" changing options "connection.autoconnect yes"
     * Modify connection "bond0" changing options "connection.autoconnect yes"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     * Reboot
     Then Check bond "nm-bond" link state is "up"
     Then Check slave "eth1" not in bond "nm-bond" in proc
     Then Check slave "eth4" in bond "nm-bond" in proc


    @ver-=1.24
    @bond_set_miimon_values
    Scenario: nmcli - bond - options - set new miimon values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=0,miimon=100,downdelay=100,updelay=100"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"


    @rhbz1806549
    @ver+=1.25
    @bond_set_miimon_values
    Scenario: nmcli - bond - options - set new miimon values
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          bond.options mode=0,miimon=100,downdelay=100,updelay=100
          """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    # vvv rhbz1806549 reproducer
    Then "miimon=100" is visible with command "nmcli -g bond.options connection show bond0"
    Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
    Then Check bond "nm-bond" link state is "up"
    Then "MII Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Up Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
    Then "Down Delay \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"


    @rhbz1805184
    @ver+=1.25
    @bond_set_zero_miimon_values
    Scenario: nmcli - bond - options - set new miimon values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=0,miimon=0,downdelay=0,updelay=0"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"


    @rhbz2117202
    @rhelver-=8
    @bond_options_new_arp_values
    Scenario: nmcli - bond - options - set new arp values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options
         """
         bond.options
         mode=0,\
         arp_interval=1000,\
         arp_ip_target="10.16.135.254 10.16.135.253"
         """
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\):.*10.16.135.254, 10.16.135.253" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth4" in proc


    @rhbz2117202
    @ver-1.43.2
    @rhelver+=9
    @bond_options_new_arp_values
    Scenario: nmcli - bond - options - set new arp values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options
         """
         bond.options
         mode=0,\
         arp_interval=1000,\
         arp_ip_target="10.16.135.254 10.16.135.253"
         """
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\):.*10.16.135.254, 10.16.135.253" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth4" in proc


    @rhbz2117202
    @rhbz2069004
    @rhbz2148684
    @ver+=1.43.2 @rhelver+=9
    @bond_options_new_arp_values
    Scenario: nmcli - bond - options - set new arp values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options
     """
     bond.options
     mode=0,\
     arp_interval=1000,\
     arp_missed_max=200,\
     arp_ip_target="10.16.135.254 10.16.135.253",\
     ns_ip6_target="2001:dead:beef:: 2000:acdc:1234:6600::"
     """
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Up Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Down Delay \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 100" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Missed Max: 200" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP IP target/s \(n.n.n.n form\):.*10.16.135.254, 10.16.135.253" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "NS IPv6 target/s \(xx::xx form\):.*2001:dead:beef::, 2000:acdc:1234:6600::" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth4" in proc


    @bond_options_arp_vs_miimon_conflict
    Scenario: nmcli - bond - options - set conflicting values between miimon and arp
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options
         """
         bond.options
         mode=0,\
         miimon=100,\
         arp_interval=1000,\
         arp_ip_target=10.16.135.254
         """
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "MII Polling Interval \(ms\): 0" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "ARP Polling Interval \(ms\): 1000" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check "nm-bond" has "eth1" in proc
     Then Check "nm-bond" has "eth4" in proc


    @bond_option_mode_missing
    Scenario: nmcli - bond - options - mode missing
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Open editor for connection "bond0"
     * Set a property named "bond.options" to " " in editor
     * Enter in editor
     * Save in editor
     Then Mode missing message shown in editor
     * Set a property named "bond.options" to "mode=0, miimon=100" in editor
     * Save in editor
     * Quit editor


    @bond_add_option
    Scenario: nmcli - bond - options - add values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
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


    @bond_mode_incorrect_value
    Scenario: nmcli - bond - options - add incorrect value
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Open editor for connection "bond0"
     * Submit "goto bond" in editor
     * Submit "goto options" in editor
     * Submit "add modem=2" in editor
     Then Wrong bond options message shown in editor
     * Enter in editor
     * Submit "back" in editor
     * Submit "back" in editor
     * Quit editor


    @bond_change_options
    Scenario: nmcli - bond - options - change values
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
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


    @bond_remove_option
    Scenario: nmcli - bond - options - remove a value
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=0,miimon=100,downdelay=100,updelay=100"
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


    @bond_overwrite_options
    Scenario: nmcli - bond - options - overwrite some value
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=0,miimon=999"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     Then "MII Polling Interval \(ms\): 999" is visible with command "cat /proc/net/bonding/nm-bond"


    @bond_mode_balance_rr
    Scenario: nmcli - bond - options - mode set to balance-rr
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=2"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(xor\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     * Modify connection "bond0" changing options "bond.options mode=0"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(round-robin\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @bond_mode_active_backup
    Scenario: nmcli - bond - options - mode set to active backup
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=1"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @ver-=1.26
    @bond_active-backup_primary_set
    Scenario: nmcli - bond - options - mode set to active backup with primary device
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=active-backup,primary=eth1,miimon=100,fail_over_mac=2"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"



    @rhbz1856640 @rhbz1876577
    @ver+=1.27 @ver-=1.29
    @bond_active-backup_primary_set
    Scenario: nmcli - bond - options - mode set to active backup with primary device
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=active-backup,primary=eth1,miimon=100,fail_over_mac=2,primary=eth1
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     When Check bond "nm-bond" link state is "up"
     * "Error" is not visible with command "nmcli device modify nm-bond +bond.options 'primary = eth4'"
     When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth4 \(primary_reselect always\)\s+Currently Active Slave: eth4" is visible with command "cat /proc/net/bonding/nm-bond"
     * "Error" is not visible with command "nmcli connection modify bond0 +bond.options 'active_slave = eth1' && nmcli device reapply nm-bond"
     Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"



    @rhbz1856640 @rhbz1876577 @rhbz1933292
    @ver+=1.30
    @bond_active-backup_primary_set
    Scenario: nmcli - bond - options - mode set to active backup with primary device
     * Note MAC address output for device "eth1" via ip command
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=active-backup,primary=eth1,miimon=100,fail_over_mac=2,primary=eth1
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     When Check bond "nm-bond" link state is "up"
     # VVV nm-bond has eth1's mac
     When Noted value is visible with command "ip a s nm-bond" in "2" seconds

     * "Error" is not visible with command "nmcli device modify nm-bond +bond.options 'primary = eth4'"
     When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth4 \(primary_reselect always\)\s+Currently Active Slave: eth4" is visible with command "cat /proc/net/bonding/nm-bond"
     # VVV nm-bond has eth1's mac as changing primary should not change mac
     When Noted value is visible with command "ip a s nm-bond" in "2" seconds

     * "Error" is not visible with command "nmcli connection modify bond0 +bond.options 'active_slave = eth1' && nmcli device reapply nm-bond"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     # VVV nm-bond has eth1's mac
     When Noted value is visible with command "ip a s nm-bond" in "2" seconds

     * Bring "down" connection "bond0.0"
     * Bring "down" connection "bond0.1"

     * Bring "up" connection "bond0"
     Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"
     # VVV nm-bond has eth1's mac
     Then Noted value is visible with command "ip a s nm-bond" in "2" seconds


    @bond_mode_balance_xor
    Scenario: nmcli - bond - options - mode set to balance xor
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=2"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: load balancing \(xor\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @bond_mode_broadcast
    Scenario: nmcli - bond - options - mode set to broadcast
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=3"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: fault-tolerance \(broadcast\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @bond_mode_8023ad
    Scenario: nmcli - bond - options - mode set to 802.3ad
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=4"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @bond_8023ad_with_lacp_rate_fast
    Scenario: nmcli - bond - options - mode set to 802.3ad with lacp_rate fast
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=802.3ad,miimon=100,xmit_hash_policy=layer2+3,lacp_rate=fast"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Transmit Hash Policy:\s+layer2\+3" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "802.3ad info.*LACP rate: fast" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz2069001
    @ver+=1.43.2
    @bond_8023ad_with_lacp_active_on
    Scenario: nmcli - bond - options - mode set to 802.3ad with lacp_rate fast
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=802.3ad,miimon=100,xmit_hash_policy=layer2+3,lacp_active=on"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Transmit Hash Policy:\s+layer2\+3" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "802.3ad info.*LACP rate: slow" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "LACP active:.*on" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz2069001
    @ver+=1.43.2
    @bond_8023ad_with_lacp_active_off
    Scenario: nmcli - bond - options - mode set to 802.3ad with lacp_rate fast
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options mode=802.3ad,miimon=100,xmit_hash_policy=layer2+3,lacp_active=off"
     * Bring "up" connection "bond0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Transmit Hash Policy:\s+layer2\+3" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "802.3ad info.*LACP rate: slow" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "LACP active:.*off" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @bond_mode_balance_tlb
    Scenario: nmcli - bond - options - mode set to balance-tlb
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options miimon=100,mode=5,lp_interval=10"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: transmit load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "10" is visible with command "cat /sys/class/net/nm-bond/bonding/lp_interval"
     Then Check bond "nm-bond" link state is "up"


    @bond_mode_balance_alb
    Scenario: nmcli - bond - options - mode set to balance-alb
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "bond.options miimon=100,mode=6"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     Then "Bonding Mode: adaptive load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1177860
    @bond_set_mtu
    Scenario: nmcli - bond - set mtu
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0.0" changing options "802-3-ethernet.mtu 9000"
     * Modify connection "bond0.1" changing options "802-3-ethernet.mtu 9000"
     * Modify connection "bond0" changing options "802-3-ethernet.mtu 9000 ipv4.method manual ipv4.addresses 1.1.1.2/24"
     * Disconnect device "nm-bond"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
    Then Check bond "nm-bond" link state is "up"
    Then Check "nm-bond" has "eth1" in proc
    Then Check "nm-bond" has "eth4" in proc
    Then "mtu 9000" is visible with command "ip a s eth1 |grep mtu" in "15" seconds
    Then "mtu 9000" is visible with command "ip a s eth4 |grep mtu"
    Then "mtu 9000" is visible with command "ip a s nm-bond |grep mtu"


    @rhbz2071985
    @ver+=1.39.3
    @bond_set_different_mtu_on_slaves
    # This scenario may start failing in case of kernel changes here:
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/net/bonding/bond_main.c?h=v5.17#n3603
    # https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/drivers/net/bonding/bond_main.c?h=v5.17#n4372
    Scenario: nmcli - bond - set different MTU on slaves in active-backup
    * Add "bond" connection named "bond0" for device "bond0" with options "autoconnect no 802-3-ethernet.mtu 1450 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "bond0.1" for device "eth1" with options "autoconnect no 802-3-ethernet.mtu 1400 connection.master bond0 connection.slave-type bond"
    * Add "ethernet" connection named "bond0.4" for device "eth4" with options "autoconnect no 802-3-ethernet.mtu 1400 connection.master bond0 connection.slave-type bond"
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.1"
    * Bring "up" connection "bond0.4"
    Then "mtu 1450" is visible with command "ip l show bond0"
    Then "mtu 1400" is visible with command "ip l show eth1"
    Then "mtu 1400" is visible with command "ip l show eth4"


    @rhbz1304641
    @ver+=1.8
    @restart_if_needed
    @bond_addreses_restart_persistence
    Scenario: nmcli - bond - addresses restart persistence
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Modify connection "bond0" changing options "ipv4.method manual ipv4.addresses 1.1.1.2/24 ipv6.method manual ipv6.addresses 1::2/128"
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     * Restart NM
     When "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "45" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
     * Restart NM
     When "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "45" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
     * Restart NM
     Then "activated" is visible with command "nmcli  connection show bond0 |grep STATE" in "45" seconds
      And "nm-bond" is not visible with command "nmcli -f NAME connection"
      And Check bond "nm-bond" link state is "up"
      And Check "nm-bond" has "eth1" in proc
      And Check "nm-bond" has "eth4" in proc
      And "1.1.1.2/24" is visible with command "nmcli connection show bond0 |grep ipv4.addresses"
      And "manual" is visible with command "nmcli connection show bond0 |grep ipv4.method"
      And "1.1.1.2/24" is visible with command "nmcli connection show bond0 |grep IP4.ADDRESS"
      And "1::2/128" is visible with command "nmcli connection show bond0 |grep ipv6.addresses"
      And "manual" is visible with command "nmcli connection show bond0 |grep ipv6.method"
      And "1::2/128" is visible with command "nmcli connection show bond0 |grep IP6.ADDRESS"
      And "fe80" is visible with command "nmcli connection show bond0 |grep IP6.ADDRESS"


    @rhbz1816202
    @ver+=1.25 @rhelver+=8
    @bond_reflect_changes_from_outside_of_NM
    Scenario: nmcli - bond - reflect changes from outside of NM
    * Create "bond" device named "bond0"
    When "bond0\s+bond\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev bond0 up"
    When "bond0\s+bond\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Create "dummy" device named "dummy0"
    When "dummy0\s+dummy\s+unmanaged" is visible with command "nmcli d" in "5" seconds
    * Execute "ip link set dev dummy0 up"
    * Execute "ip addr add 1.1.1.1/24 dev bond0"
    When "bond0\s+bond\s+connected \(externally\)\s+bond0" is visible with command "nmcli d" in "5" seconds
    * Execute "ifenslave bond0 dummy0"
    When "dummy0\s+dummy\s+connected \(externally\)\s+dummy0" is visible with command "nmcli d" in "5" seconds
    Then "BOND.SLAVES:\s+dummy0" is visible with command "nmcli -f bond.slaves dev show bond0"

#FIXME: more tests with arp and conflicts with load balancing can be written

    @rhbz1133544 @rhbz1804350
    @bond_dbus_creation
    Scenario: NM - bond - dbus api bond setting
    * Cleanup connection "bond0"
    * Cleanup device "nm-bond"
    * Execute "/usr/bin/python contrib/dbus/dbus-set-bond.py"
    Then "bond0.*bond\s+nm-bond" is visible with command "nmcli connection"


    @rhbz1171009
    @ifcfg-rh
    @bond_mode_by_number_in_ifcfg
    Scenario: NM - bond - ifcfg - mode set by number
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           """
     * Add "ethernet" connection named "bond0.0" for device "eth4" with options "master nm-bond"
     * Add slave connection for master "nm-bond" on device "eth5" named "bond0.1"
     * Replace "BONDING_OPTS=mode=balance-rr" with "BONDING_OPTS=mode=5" in file "/etc/sysconfig/network-scripts/ifcfg-bond0"
     * Reload connections
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then "Bonding Mode: transmit load balancing" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1299103 @rhbz1348198
    @ver-=1.24
    @bond_set_active_backup_options
    Scenario: nmcli - bond - set active backup options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=active-backup,active_slave=eth4,num_grat_arp=3,num_unsol_na=3
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     # sort the BONDING_OPTS to prevent failures in the future
     * Note the output of "grep BONDING_OPTS= /etc/sysconfig/network-scripts/ifcfg-bond0 | grep -o '".*"' | sed 's/"//g;s/ /\n/g' | sort | tr '\n' ' '" as value "ifcfg_opts"
     * Note the output of "echo 'active_slave=eth4 mode=active-backup num_grat_arp=3 num_unsol_na=3 '" as value "desired_opts"
     Then Check noted values "ifcfg_opts" and "desired_opts" are the same
      #And "Currently Active Slave: eth4" is visible with command "cat /proc/net/bonding/nm-bond"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"


    @rhbz1299103 @rhbz1348198 @rhbz1858326
    @ver+=1.26
    @bond_set_active_backup_options
    Scenario: nmcli - bond - set active backup options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           bond.options
           mode=active-backup,active_slave=eth4,num_grat_arp=3,num_unsol_na=3
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     And "error" is not visible with command "journalctl -u NetworkManager --since '10 seconds ago' --no-pager |grep active_backup | grep error"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     # sort the BONDING_OPTS to prevent failures in the future
     #* Note the output of "grep BONDING_OPTS= /etc/sysconfig/network-scripts/ifcfg-bond0 | grep -o '".*"' | sed 's/"//g;s/ /\n/g' | sort | tr '\n' ' '" as value "ifcfg_opts"
     #* Note the output of "echo 'active_slave=eth4 mode=active-backup num_grat_arp=3 num_unsol_na=3 '" as value "desired_opts"
     #Then Check noted values "ifcfg_opts" and "desired_opts" are the same
      #And "Currently Active Slave: eth4" is visible with command "cat /proc/net/bonding/nm-bond"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
      And "3" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"


    @rhbz1299103
    @bond_set_ad_options
    Scenario: nmcli - bond - set 802.3ad options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options
           mode=802.3ad,ad_actor_sys_prio=666,ad_select=bandwidth,ad_actor_system=00:00:00:00:11:00,min_links=2,ad_user_port_key=2,all_slaves_active=1
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     #When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "system priority: 666" is visible with command "cat /proc/net/bonding/nm-bond"
      And "Aggregator selection policy \(ad_select\): bandwidth" is visible with command "cat /proc/net/bonding/nm-bond"
      And "2" is visible with command "cat /sys/class/net/nm-bond/bonding/ad_user_port_key"
      And "00:00:00:00:11:00" is visible with command "cat /sys/class/net/nm-bond/bonding/ad_actor_system"
      And "1" is visible with command "cat /sys/class/net/nm-bond/bonding/all_slaves_active"
      And "2" is visible with command "cat /sys/class/net/nm-bond/bonding/min_links"


    @rhbz1299103
    @bond_set_arp_all_targets
    Scenario: nmcli - bond - set arp_all_targets
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options
           mode=active-backup,arp_interval=1000,arp_ip_target=172.16.1.254,arp_all_targets=1
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "1" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_all_targets"


    @rhbz1299103
    @bond_set_packets_per_slave_option
    Scenario: nmcli - bond - set packets_per_slave option
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=balance-rr,packets_per_slave=1024
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "1024" is visible with command "cat /sys/class/net/nm-bond/bonding/packets_per_slave"


    @rhbz1963854
    @ver+=1.33.0
    @rhelver+=8
    @bond_set_peer_notif_delay_option
    Scenario: nmcli - bond - set peer_notif_delay option
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=balance-rr,miimon=300,peer_notif_delay=600
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "600" is visible with command "cat /sys/class/net/nm-bond/bonding/peer_notif_delay"


    @rhbz1963854
    @ver+=1.33.0
    @bond_set_invalid_peer_notif_delay_option
    Scenario: nmcli - bond - set invalid peer_notif_delay option
     Then "Error.*needs to be a value multiple of 'miimon' value" is visible with command "nmcli con add type bond con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=balance-rr,miimon=295,peer_notif_delay=600" in "1" seconds
     Then "Error.*requires 'miimon' option to be enabled" is visible with command "nmcli con add type bond con-name bond0 ifname nm-bond autoconnect no -- connection.autoconnect-slaves 1 bond.options mode=balance-rr,miimon=0,peer_notif_delay=600" in "1" seconds


    @rhbz1299103 @rhbz1348573
    @ver-=1.26
    @bond_set_balance_tlb_options
    Scenario: nmcli - bond - set balance-tlb options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=balance-tlb,tlb_dynamic_lb=0,lp_interval=666
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     #When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "0" is visible with command "cat /sys/class/net/nm-bond/bonding/tlb_dynamic_lb"
      And "666" is visible with command "cat /sys/class/net/nm-bond/bonding/lp_interval"


    @rhbz1299103 @rhbz1348573 @rhbz1856640
    @ver+=1.27
    @bond_set_balance_tlb_options
    Scenario: nmcli - bond - set balance-tlb options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=balance-tlb,tlb_dynamic_lb=0,lp_interval=666,primary=eth1,miimon=500,updelay=100
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
      And "error" is not visible with command "journalctl -u NetworkManager --since '10 seconds ago' --no-pager |grep balance |grep error"
      And "Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"
     * "Error" is not visible with command "nmcli device modify nm-bond +bond.options 'primary = eth4'"
     When "0" is visible with command "cat /sys/class/net/nm-bond/bonding/tlb_dynamic_lb"
      And "666" is visible with command "cat /sys/class/net/nm-bond/bonding/lp_interval"
      And "Primary Slave: eth4 \(primary_reselect always\)\s+Currently Active Slave: eth4" is visible with command "cat /proc/net/bonding/nm-bond"
     * "Error" is not visible with command "nmcli connection modify bond0 +bond.options 'active_slave = eth1' && nmcli device reapply nm-bond"
     Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
      And "error" is not visible with command "journalctl -u NetworkManager --since '10 seconds ago' --no-pager |grep balance |grep error"
      And "Primary Slave: eth1 \(primary_reselect always\)\s+Currently Active Slave: eth1" is visible with command "cat /proc/net/bonding/nm-bond"


    @rhbz1959934
    @ver+=1.30
    @rhelver+=8.4
    @bond_set_balance_tlb_options_var2
    Scenario: nmcli - bond - set balance-tlb options
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           -- connection.autoconnect-slaves 1
           bond.options mode=balance-alb,miimon=100,xmit_hash_policy=5,tlb_dynamic_lb=0
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     Then "0" is visible with command "cat /sys/class/net/nm-bond/bonding/tlb_dynamic_lb"


    @ver+=1.8.1
    @rhbz979425 @rhbz1450219
    @bond_device_rename
    Scenario: NM - bond - device rename
     * Cleanup device "nm-bond"
     * Add "bond" connection named "bond0" for device "bondy" with options
           """
           ip4 172.16.1.1/24
           """
     * Modify connection "bond0" changing options "connection.interface-name nm-bond"
     * Bring "down" connection "bond0"
     * Bring "up" connection "bond0"
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0.1"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1243371
    @restart_if_needed
    @delete_addrgenmode_bond
    Scenario: NM - bond - addrgenmode bond delete
    * Stop NM
    * Create "bond" device named "bond0"
    * Execute "ip l set eth4 down; ip l set eth4 master bond0; ip l set eth4 addrgenmode none; ip l set eth4 up"
    * Execute "ip l set eth1 down; ip l set eth1 master bond0; ip l set eth1 addrgenmode none; ip l set eth1 up"
    * Cleanup device "eth4"
    * Cleanup device "eth1"
    * Restart NM
    * Wait for "5" seconds
    * Note the output of "pidof NetworkManager" as value "orig_pid"
    * Execute "ip l del bond0"
    * Note the output of "pidof NetworkManager" as value "new_pid"
    Then Check noted values "orig_pid" and "new_pid" are the same


    @rhbz1183420
    @bond_enslave_to_bridge
    Scenario: nmcli - bond - enslave bond device to bridge
     * Add "bridge" connection named "bond_bridge0" for device "bond-bridge" with options
           """
           bridge.stp off
           ipv4.method manual ipv4.addresses 172.16.1.2/24
           """
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           master bond-bridge
           """
     * Add "ethernet" connection named "bond-slave-eth1" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond-slave-eth1"
    Then "bond-bridge:bridge:connected:bond_bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "45" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


    @rhbz1360386
    @ver+=1.7.1 @ver-=1.24
    @bridge_bond_autoconnect_nested_slaves
    Scenario: nmcli - bond - autoconnect slaves of slaves
     * Add "bridge" connection named "bond_bridge0" for device "bond-bridge" with options
           """
           autoconnect no
           ipv4.method manual ipv4.addresses 172.16.1.2/24
           connection.autoconnect-slaves 1 bridge.stp off
           """
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           master bond-bridge autoconnect no
           connection.autoconnect-slaves 1
           """
     * Add "ethernet" connection named "bond-slave-eth1" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond_bridge0"
    Then "bond-bridge:bridge:connected:bond_bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "60" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


    @rhbz1360386 @rhbz1845018
    @ver+=1.25
    @restart_if_needed
    @bridge_bond_autoconnect_nested_slaves
    Scenario: nmcli - bond - autoconnect slaves of slaves
     * Add "bridge" connection named "bond_bridge0" for device "bond-bridge" with options
           """
           autoconnect no
           ipv4.method manual ipv4.addresses 172.16.1.2/24
           connection.autoconnect-slaves 1 bridge.stp off
           """
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           master bond-bridge autoconnect no
           connection.autoconnect-slaves 1
           """
     * Add "ethernet" connection named "bond-slave-eth1" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond_bridge0"
    When "bond-bridge:bridge:connected:bond_bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "60" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
    * Modify connection "bond-slave-eth1" changing options "connection.autoconnect yes"
    * Modify connection "bond0" changing options "connection.autoconnect-slaves 0"
    * Reboot
    Then "bond-bridge:bridge:connected:bond_bridge0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "60" seconds
     And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "eth1:ethernet:connected:bond-slave-eth1" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds


     @rhbz1352131
     @ver+=1.4.0
     @bond_8023ad_no_error
     Scenario: nmcli - bond - no error in 8023ad setup
      * Run child "journalctl -f > /tmp/journal.txt"
      * Add "bond" connection named "bond0" for device "bond0" with options
            """
            mode 4 miimon 100
            """
      * Execute "pkill journalctl"
      Then "mode dependency failed, not supported in mode 802.3ad" is not visible with command "grep arp_validate /tmp/journal.txt"


     @rhbz1349266
     @ver+=1.4.0
     @restart_if_needed
     @bond_balance-alb_no_error
     Scenario: nmcli - bond - no error in balance-alb setup
      * Run child "journalctl -f > /tmp/journal.txt"
      * Add "bond" connection named "bond0" for device "nm-bond" with options "mode 6"
      * Reboot
      * Execute "pkill journalctl"
      Then "mode dependency failed, not supported in mode balance-alb" is not visible with command "grep arp_validate /tmp/journal.txt"


     @rhbz1364275
     @ver+=1.4
     @bond_in_bridge_mtu
     Scenario: nmcli - bond - enslave bond device to bridge and set mtu
      * Add "bridge" connection named "bond_bridge0" for device "bond-bridge" with options
            """
            autoconnect no
            ipv4.method manual ipv4.addresses 172.16.1.1/24
            802-3-ethernet.mtu 9000
            """
      * Add "bond" connection named "bond0" for device "nm-bond" with options
            """
            autoconnect no master bond-bridge
            802-3-ethernet.mtu 9000
            """
      * Add "ethernet" connection named "bond0.0" for device "eth1" with options
            """
            autoconnect no
            master nm-bond
            -- 802-3-ethernet.mtu 9000
            """
      * Bring "up" connection "bond_bridge0"
      * Bring "up" connection "bond0"
      * Bring "up" connection "bond0.0"
      Then "mtu 9000" is visible with command "ip a s eth1"
      Then "mtu 9000" is visible with command "ip a s nm-bond"
      Then "mtu 9000" is visible with command "ip a s bond-bridge"


    @bond_describe
    Scenario: nmcli - bond - describe bond
     * Cleanup connection "bond"
     * Open editor for a type "bond"
     Then Check "<<< bond >>>|=== \[options\] ===|\[NM property description\]" are present in describe output for object "bond"
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object "bond.options"
      * Submit "g b" in editor
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object "options"
      * Submit "g o" in editor
     Then Check "NM property description|nmcli specific description|mode, miimon, downdelay, updelay, arp_interval, arp_ip_target|balance-rr    = 0\s+active-backup = 1\s+balance-xor   = 2\s+broadcast     = 3\s+802.3ad       = 4\s+balance-tlb   = 5\s+balance-alb   = 6" are present in describe output for object " "


     @rhbz1376784
     @ver+=1.4.0
     @reapply_unchanged_slave
     Scenario: nmcli - bond - reapply unchanged slave
      * Add "bond" connection named "bond0" for device "nm-bond" with options
            """
            ip4 172.16.1.1/24
            """
      * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
      * Bring "up" connection "bond0"
      * Bring "up" connection "bond0.0"
      Then "Connection successfully reapplied to device" is visible with command "nmcli dev reapply eth1"


    @rhbz1333983
    @ver+=1.8.0
    @restart_if_needed
    @vlan_over_no_L3_bond_restart_persistence
    Scenario: nmcli - bond - restart persistence of no L3 bond in vlan
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ipv4.method disable ipv6.method ignore
          """
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "autoconnect no master nm-bond"
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "autoconnect no master nm-bond"
    * Add "vlan" connection named "vlan" with options
          """
          dev nm-bond
          id 153
          autoconnect no
          ip4 10.66.66.1/24
          ipv6.method ignore
          """
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0.1"
    * Bring "up" connection "vlan"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "eth4:connected:bond0.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "nm-bond.153:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
    * Stop NM
    When "state UP" is visible with command "ip a s eth1"
     And "state UP" is visible with command "ip a s eth4"
     And "state UP" is visible with command "ip a s nm-bond"
     And "state UP" is visible with command "ip a s nm-bond.153"
     And "10.66.66.1/24" is visible with command "ip a s nm-bond.153"
    * Restart NM
    Then "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     And "eth1:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "eth4:connected:bond0.1" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "nm-bond.153:connected:vlan" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     And "10.66.66.1/24" is visible with command "ip a s nm-bond.153"


     @rhbz1371126
     @ver-1.13
     @restart_if_needed
     @bond_leave_L2_only_up_when_going_down
     Scenario: nmcli - bond - leave UP with L2 only config
      * Prepare simulated test "testXB" device
      * Add "bond" connection named "bond0" for device "nm-bond" with options
            """
            autoconnect no
            ipv4.method disabled ipv6.method ignore
            """
      * Add "ethernet" connection named "bond0.0" for device "testXB" with options
            """
            autoconnect no
            connection.master nm-bond
            connection.slave-type bond
            """
      * Bring "up" connection "bond0.0"
      When "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
       And "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond"
      * Kill NM
      * Restart NM
      When "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond" for full "10" seconds
      * Bring "up" connection "bond0.0"
      Then "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
       And "state UP" is visible with command "ip -6 a s nm-bond"
       And "inet6 fe80" is visible with command "ip -6 a s nm-bond"


    @rhbz1593282
    @ver+=1.14.0
    @restart_if_needed
    @bond_leave_L2_only_up_when_going_down
    Scenario: nmcli - bond - leave UP with L2 only config
    * Prepare simulated test "testXB" device
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ipv4.method disabled ipv6.method ignore
          """
    * Add "ethernet" connection named "bond0.0" for device "testXB" with options
          """
          autoconnect no
          connection.master nm-bond
          connection.slave-type bond
          """
    * Bring "up" connection "bond0.0"
    When "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
     And "state UP" is visible with command "ip -6 a s nm-bond"
     And "inet6 fe80" is visible with command "ip -6 a s nm-bond"
    * Kill NM with signal "9"
    * Restart NM
    When "state UP" is visible with command "ip -6 a s nm-bond"
     And "inet6 fe80" is visible with command "ip -6 a s nm-bond" for full "10" seconds
    * Bring "up" connection "bond0.0"
    Then "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "40" seconds
     And "state UP" is visible with command "ip -6 a s nm-bond"
     And "inet6 fe80" is visible with command "ip -6 a s nm-bond"


    @rhbz1463077
    @ver+=1.8.1
    @restart_if_needed
    @bond_assume_options_1
    Scenario: nmcli - bond - assume options 1
     * Stop NM
     * Create "bond" device named "bond0"
     * Execute "echo 1   > /sys/class/net/bond0/bonding/mode"
     * Execute "echo 100 > /sys/class/net/bond0/bonding/miimon"
     * Execute "echo 100 > /sys/class/net/bond0/bonding/updelay"
     * Execute "ip l set bond0 up"
     * Execute "ip a a 172.16.1.1/24 dev bond0"
     * Restart NM
     Then "bond0\s+bond\s+connected" is visible with command "nmcli d" in "10" seconds
     Then "inet 172.16.1.1/24" is visible with command "ip a show dev bond0"


    @rhbz1463077
    @ver+=1.10.0
    @restart_if_needed
    @bond_assume_options_2
    Scenario: nmcli - bond - assume options 2
     * Add "bond" connection named "bond" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           bond.options mode=1,miimon=100,updelay=200
           """
     * Bring "up" connection "bond"
     * Restart NM
     Then "nm-bond\s+bond\s+connected\s+bond" is visible with command "nmcli d" in "10" seconds


    @rhbz1463077
    @ver+=1.10.0
    @restart_if_needed
    @bond_assume_options_3
    Scenario: nmcli - bond - assume options 3
     * Add "bond" connection named "bond" for device "nm-bond" with options
           """
           ip4 172.16.1.1/24
           bond.options mode=1,arp_interval=100,arp_ip_target=172.16.1.100
           """
     * Bring "up" connection "bond"
     * Restart NM
     Then "nm-bond\s+bond\s+connected\s+bond" is visible with command "nmcli d" in "10" seconds


    @rhbz1454883
    @ver+=1.10
    @nmclient_bond_get_state_flags
    Scenario: nmclient - bond - get state flags
    * Add "bond" connection named "bond0" for device "nm-bond"
    When "LAYER2" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "5" seconds
    When "IS_MASTER" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "5" seconds
     And "MASTER_HAS_SLAVES" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0"
     And "IP6" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0"
     And "IP4" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0"
    * Add slave connection for master "nm-bond" on device "testXB" named "bond0.0"
    When "LAYER2" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0.0" in "5" seconds
    When "IP4" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0.0"
    When "IP6" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0.0"
    * Prepare simulated veth device "testXB" without carrier
    * Execute "nmcli con modify bond0 ipv4.may-fail no"
    * Execute "nmcli con up bond0.0" without waiting for process to finish
    When "IP4" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0"
     And "IP6" is not visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0"
     And "MASTER_HAS_SLAVES" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "5" seconds
     And "IS_SLAVE" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0.0" in "5" seconds
    * Execute "ip netns exec testXB_ns kill -SIGSTOP $(cat /tmp/testXB_ns.pid)"
    * Execute "ip netns exec testXB_ns ip link set testXBp up"
    * Execute "ip netns exec testXB_ns kill -SIGCONT $(cat /tmp/testXB_ns.pid)" without waiting for process to finish
    Then "MASTER_HAS_SLAVES" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "40" seconds
    Then "IP4" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "40" seconds
    Then "IP6" is visible with command "/usr/bin/python contrib/gi/nmclient_get_state_flags.py bond0" in "40" seconds


    @rhbz1591734
    @ver+=1.11.4
    @bond_set_num_grat_arp_unsol_na
    Scenario: nmcli - bond - set num_grat_arp and num_unsol_na options
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ip4 172.16.1.1/24
          connection.autoconnect-slaves 1
          bond.options mode=active-backup,num_grat_arp=7
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
    * Bring "up" connection "bond0"
    Then "7" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
     And "7" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"
    * Modify connection "bond0" changing options "-bond.options num_grat_arp"
    * Modify connection "bond0" changing options "+bond.options num_unsol_na=8"
    * Bring "up" connection "bond0"
    Then "8" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
     And "8" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"
    # this call fails as num_grat_arp is already unset
    #* Modify connection "bond0" changing options "-bond.options num_grat_arp"
    * Modify connection "bond0" changing options "-bond.options num_unsol_na"
    * Bring "up" connection "bond0"
    Then "1" is visible with command "cat /sys/class/net/nm-bond/bonding/num_grat_arp"
     And "1" is visible with command "cat /sys/class/net/nm-bond/bonding/num_unsol_na"


     @rhbz1678796
     @ver+=1.16
     @tshark @not_on_aarch64
     @bond_send_correct_arp
     Scenario: nmcli - bond - send correct arp
     * Prepare simulated test "testXB" device
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ipv4.method manual
           ipv4.addresses 2.3.4.5/24,192.168.100.123/24,1.1.1.1/24,1.2.3.4/24,1.2.3.5/24,1.3.5.9/24
           """
     * Add "ethernet" connection named "bond0.0" for device "testXB" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     * Note MAC address output for device "nm-bond" via ip command
     * Run child "sudo tshark -l -O arp -i nm-bond -x -c 10 > /tmp/tshark.log"
     * Bring "up" connection "bond0.0"
     When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
     * Bring "up" connection "bond0"
     * Bring "up" connection "bond0.0"
     * Execute "echo $COLUMNS"
     When "activated" is visible with command "nmcli c show bond0.0" in "10" seconds
     When "tshark -l -O arp" is not visible with command "ps aux" in "15" seconds
     Then Noted value is not visible with command "cat /tmp/tshark.log" in "2" seconds


    @rhbz1667874
    @ver+=1.19
    @bond_autoconnect_activation_fails_with_libnm
    Scenario: NM - bond - bond activation fails with autoconnect true using libnm
    * Cleanup device "nm-bond"
    * Cleanup connection "bond0"
    Then "Connection added\s+Connection activated" is visible with command "/usr/bin/python contrib/gi/bond_add_activate.py" in "1" seconds


    @rhbz1730793
    @ver+=1.18.4
    @bond_arp_validate
    Scenario: NM - bond - bond set arp_validate
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ip4 10.16.135.1/24
          -- connection.autoconnect-slaves 1
          bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=6
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "filter_backup 6" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=5"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "filter_active 5" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=4"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "filter 4" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=3"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "all 3" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=2"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "backup 2" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=1"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "active 1" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"
    * Modify connection "bond0" changing options "bond.options mode=active-backup,arp_interval=1000,arp_ip_target=10.16.135.254,arp_all_targets=1,arp_validate=0"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    Then "none 0" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"


    @rhbz1789437
    @ver+=1.22.8
    @bond_rr_arp_validate
    Scenario: NM - bond - bond set arp_validate in rr mode
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          autoconnect no
          ipv4.method disabled ipv6.method disabled
          bond.options mode=balance-rr
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
    * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond autoconnect no"
    * Bring "up" connection "bond0"
    When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Modify connection "bond0" changing options "bond.options mode=balance-rr,arp_validate=active"
    * Bring "down" connection "bond0"
    * Bring "up" connection "bond0"
    Then "active 1" is visible with command "cat /sys/class/net/nm-bond/bonding/arp_validate"


    @rhbz1703960
    @ver+=1.18.4
    @bond_reapply_connection_without_wired_settings
    Scenario: NM - bond - reapply connection without wired settings
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          connection.autoconnect-slaves 1
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show nm-bond" in "40" seconds
    Then "Error.*" is not visible with reproducer "repro_reapply_no_wired_settings.py" with options "bond0 nm-bond" in "1" seconds


    @rhbz1686634
    @ver+=1.22
    @modprobe_cfg_remove
    @bond_reconnect_previously_unavailable_device
    Scenario: NM - bond - reconnect device
    * Execute "echo 'blacklist bonding' > /etc/modprobe.d/99-test.conf && modprobe -r bonding"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          connection.autoconnect-slaves 1
          ipv4.method manual ipv4.addresses 172.16.1.1/24
          """
    * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond"
    * Bring "up" connection "bond0" ignoring error
    * Execute "rm -rf /etc/modprobe.d/99-test.conf"
    * Bring "up" connection "bond0"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show nm-bond" in "40" seconds


    @rhbz1754511
    @ver+=1.18
    @restart_if_needed
    @bond_add_default_route_if_bond0_exists
    Scenario: NM - bond - reconnect device
    * Add "bond" connection named "bond0" for device "bond0" with options
          """
          ip4 172.16.1.1/24 gw4 172.16.1.254
          """
    * Stop NM
    * Execute "rm -rf /var/run/NetworkManager"
    * Execute "ip link del bond0 2> /dev/null ; ip link add bond0 type bond"
    * Start NM
    * Bring "up" connection "bond0"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show bond0" in "40" seconds
    Then "default" is visible with command "ip r |grep bond0"


    @rhbz1718173
    @ver+=1.20 @ver-=1.29
    @bond_normalize_connection
    Scenario: NM - bond - bond normalize connection
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          bond.options mode=4,arp_interval=2,arp_ip_target=1.1.1.1
          """
    Then "mode=802.3ad" is visible with command "nmcli c show bond0"


    @rhbz1718173 @rhbz1923999
    @ver+=1.29
    @bond_normalize_connection
    Scenario: NM - bond - bond normalize connection
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          bond.options mode=4,arp_interval=2,arp_ip_target=1.1.1.1
          """
    Then "mode=802.3ad" is visible with command "nmcli c show bond0"
    Then "error" is not visible with command "journalctl -u NetworkManager --since -10s -p 3 -o cat |grep ad_actor_system"


    @rhbz1847814
    @ver+=1.25
    @ver-=1.37.2
    @bond_reapply
    Scenario: NM - device - reapply just routes
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          bond.options mode=0,miimon=100,updelay=100
          """
    * Bring "up" connection "bond0"
    * Modify connection "bond0" changing options "bond.options mode=0,miimon=100,downdelay=1000,updelay=100"
    * Execute "sudo nmcli d reapply nm-bond"
    Then "1000" is visible with command "cat /sys/class/net/nm-bond/bonding/downdelay"


    @rhbz1847814 @rhbz2065049
    @ver+=1.37.3
    @bond_reapply
    Scenario: NM - device - reapply just routes
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          bond.options mode=0,miimon=100,updelay=100
          """
    * Bring "up" connection "bond0"
    Then "-1" is visible with command "nmcli -g connection.autoconnect-slaves con show bond0"
    * Modify connection "bond0" changing options "bond.options mode=0,miimon=100,downdelay=1000,updelay=100 connection.autoconnect-slaves yes"
    * Execute "sudo nmcli d reapply nm-bond"
    Then "1000" is visible with command "cat /sys/class/net/nm-bond/bonding/downdelay"
    And "1" is visible with command "nmcli -g connection.autoconnect-slaves con show bond0"


    @rhbz1870691
    @ver+=1.29
    @bond_change_mode_of_externally_created_bond
    Scenario: nmcli - bond - options - change mode of externally created bond
    * Create "veth" device named "veth11" with options "peer name veth12"
    * Execute "ip link set veth12 up"
    * Create "bond" device named "nm-bond"
    * Execute "ip link set veth11 down"
    * Execute "ip link set veth11 master nm-bond"
    * Execute "ip link set veth11 up"
    * Execute "ip link set nm-bond up"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          connection.autoconnect no
          connection.autoconnect-slaves no
          bond.option mode=active-backup
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "bond0.1" for device "veth11" with options
          """
          connection.master nm-bond
          connection.slave-type bond
          connection.autoconnect no
          connection.autoconnect-slaves no
          """
    * Bring "down" connection "bond0"
    * Bring "up" connection "bond0"
    * Bring "up" connection "bond0.1"
     When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0" in "40" seconds
     Then "Bonding Mode: fault-tolerance \(active-backup\)" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1915457
    @ver+=1.30 @rhelver+=8.4 @skip_in_centos
    @bond_8023ad_with_vlan_srcmac
    Scenario: nmcli - bond - options - mode set to 802.3ad with vlan+srcmax
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          ip4 172.16.1.1/24
          bond.options 'mode=802.3ad,
          miimon=100,xmit_hash_policy=vlan+srcmac'
          """
     * Add "ethernet" connection named "bond0.0" for device "eth1" with options "master nm-bond"
     * Bring "up" connection "bond0.0"
     Then "Bonding Mode: IEEE 802.3ad Dynamic link aggregation" is visible with command "cat /proc/net/bonding/nm-bond"
     Then "Transmit Hash Policy:\s+vlan\+srcmac" is visible with command "cat /proc/net/bonding/nm-bond"
     Then Check bond "nm-bond" link state is "up"


    @rhbz1890234
    @ver+=1.31.0
    @rhelver+=8
    @bond_set_MTU_before_DHCP
    Scenario: nmcli - bond - set MTU before DHCP starts
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           ethernet.mtu 1400
           ipv6.method disabled
           """
     * Add "dummy" connection named "bond0.0" for device "dummy0" with options "master bond0"
     * Add "dummy" connection named "bond0.1" for device "dummy1" with options "master bond0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0.0" in "10" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show bond0.1" in "10" seconds
    Then "mtu 1400" is visible with command "ip link show nm-bond"
    Then "activating" is visible with command "nmcli -g GENERAL.STATE con show bond0"


     @rhbz1942331
     @ver+=1.31
     @bond_accept_all_mac_addresses
     Scenario: nmcli - bond - accept-all-mac-addresses (promisc mode)
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           """
     * Bring "up" connection "bond0"
     Then "PROMISC" is not visible with command "ip link show dev nm-bond"
     * Modify connection "bond0" changing options "802-3-ethernet.accept-all-mac-addresses true"
     * Bring "up" connection "bond0"
     Then "PROMISC" is visible with command "ip link show dev nm-bond"
     * Modify connection "bond0" changing options "802-3-ethernet.accept-all-mac-addresses false"
     * Bring "up" connection "bond0"
     Then "PROMISC" is not visible with command "ip link show dev nm-bond"


     @rhbz1942331
     @ver+=1.31
     @bond_accept_all_mac_addresses_external_device
     Scenario: nmcli - bond - accept-all-mac-addresses (promisc mode)
     # promisc off -> default
     * Execute "ip link add nm-bond type bond && ip link set dev nm-bond promisc off"
     When "PROMISC" is not visible with command "ip link show dev nm-bond"
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           ip4 172.16.1.1/24
           802-3-ethernet.accept-all-mac-addresses default
           """
     * Bring "up" connection "bond0"
     Then "PROMISC" is not visible with command "ip link show dev nm-bond"
     * Bring "down" connection "bond0"
     # promisc on -> default
     * Execute "ip link set dev nm-bond promisc on"
     When "PROMISC" is visible with command "ip link show dev nm-bond"
     * Bring "up" connection "bond0"
     Then "PROMISC" is visible with command "ip link show dev nm-bond"
     * Bring "down" connection "bond0"
     # promisc off -> true
     * Execute "ip link set dev nm-bond promisc off"
     When "PROMISC" is not visible with command "ip link show dev nm-bond"
     * Modify connection "bond0" changing options "802-3-ethernet.accept-all-mac-addresses true"
     * Bring "up" connection "bond0"
     Then "PROMISC" is visible with command "ip link show dev nm-bond"
     * Bring "down" connection "bond0"
     # promisc on -> false
     * Execute "ip link set dev nm-bond promisc on"
     When "PROMISC" is visible with command "ip link show dev nm-bond"
     * Modify connection "bond0" changing options "802-3-ethernet.accept-all-mac-addresses false"
     * Bring "up" connection "bond0"
     Then "PROMISC" is not visible with command "ip link show dev nm-bond"


    @rhbz1956793
    @ver+=1.32.4
    @tshark
    @bond_enslave_to_bridge_correct_ARP
    Scenario: nmcli - bond - send correct ARP for bond in bridge
     * Add "bridge" connection named "bond_bridge0" for device "bond-bridge" with options
           """
           autoconnect no
           ipv4.method manual ipv4.addresses 172.16.1.2/24
           bridge.stp no
           """
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           master bond-bridge
           """
     * Add "ethernet" connection named "bond-slave-eth1" for device "eth1" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond_bridge0"
     * Note MAC address output for device "bond-bridge" via ip command as "mac_bridge"
     * Bring "up" connection "bond0"
     * Note MAC address output for device "nm-bond" via ip command as "mac_bond"
     * Bring "up" connection "bond-slave-eth1"
     * Execute "tshark -i bond-bridge -a duration:5 -Y arp -T fields -e eth.src -e arp.src.hw_mac -e _ws.col.Info > /tmp/tshark.log"
     Then Noted value "mac_bridge" is not visible with command "cat /tmp/tshark.log"
     Then Noted value "mac_bond" is not visible with command "cat /tmp/tshark.log"


    @rhbz1949023
    @ver+=1.36
    @bond_controller_port_terminology
    Scenario: bond - use controller/port terminology
    * Add "bond" connection named "bond0" for device "bond0" with options "autoconnect no"
    # update to controller/port when nmcli also gets update.
    * Add "dummy" connection named "dummy0" for device "dummy0" with options "master bond0"
    * Bring "up" connection "dummy0"
    # list ports using libnm
    Then "dummy0" is visible with command "contrib/naming/ports-libnm.py bond0"
    # list ports using dbus
    Then Note the output of "contrib/naming/ports-dbus.sh bond0 dummy0"
     And Noted value contains "dbus ports:ao \d+"


    @rhbz2028751
    @ver+=1.35.5
    @tcpdump
    @bond_ipv4_dad_timeout_not_used
    Scenario: bond - ipv4.dad-timeout parameter should not be used
    * Add namespace "ns1"
    * Execute "ip link add veth0 type veth peer name veth1 netns ns1"
    * Execute "ip -n ns1 l set veth1 up"
    * Execute "ip -n ns1 a add dev veth1 172.25.13.1/24"
    * Execute "ip l set veth0 up"
    * Add "bond" connection named "bond0" for device "nm-bond" with options
          """
          bond.option mode=1
          ip4 172.25.13.1/24 ipv4.method manual ipv4.dad-timeout 3000
          connection.autoconnect no connection.autoconnect-slaves yes
          """
    * Execute "nmcli -f ipv4.dad-timeout c s id bond0"
    * Add "ethernet" connection named "con_veth1" for device "veth0" with options
          """
          master bond0
          connection.autoconnect no
          """
    When Execute "nmcli c up id bond0 || /bin/true"
    * Wait for "50" seconds
    Then "172.25.13.1" is not visible with command "ip -4 a show dev bond0"
     And "Request who-has 172.25.13.1" is visible with command "cat /tmp/network-traffic.log"
     And "Reply 172.25.13.1 is-at" is visible with command "cat /tmp/network-traffic.log"


    @rhbz2003214
    @ver+=1.37.3
    @bond_modify_bond-opts_with_slaves
    Scenario: bond - block modifying fail_over_mac bond.options when bond already has slaves
    * Add "bond" connection named "bond0" for device "bond0" with options
          """
          bond.options mode=1,miimon=100
          """
    * Add "ethernet" connection named "bond-slave0" for device "eth4" with options
          """
          master bond0
          """
    * Add "ethernet" connection named "bond-slave1" for device "eth7" with options
          """
          master bond0
          """
    When "bond0:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Modify connection "bond0" changing options "bond.options mode=1,fail_over_mac=0"
    Then "failed" is visible with command "nmcli device reapply bond0"


    @ver+=1.41.1
    @bond_conflicting_device_names
    Scenario: nmcli - bond - ensure a bond doesn't get brought down by autoactivation requiring master of the same name
    * Add "bond" connection named "bond0a" for device "bond0" with options "ipv4.method disabled ipv6.method disabled"
    * Add "dummy" connection named "dummy0a" for device "dummy0" with options "master bond0a"
    When "dummy0:connected:dummy0a" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Add "bond" connection named "bond0b" for device "bond0" with options "ipv4.method disabled ipv6.method disabled"
    * Add "dummy" connection named "dummy0b" for device "dummy0" with options "master bond0b"
    Then "dummy0:connected:dummy0a" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
    * Bring "up" connection "bond0b"
    When "bond0:connected:bond0b" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "1" seconds
    Then "bond0:connected:bond0b" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" for full "5" seconds


    @rhbz2128216
    @fedoraver+=36 @rhelver+=9.2
    @ver+=1.41.3
    @skip_in_centos
    @bond_set_balance_slb_options
    Scenario: bond - create bond with "balance-slb" bonding mode (multi chassis link aggregation (MLAG)
     * Add "bond" connection named "bond0" for device "nm-bond" with options
           """
           autoconnect no
           bond.options mode=balance-xor,balance-slb=1,xmit_hash_policy=5
           ipv4.method manual ipv4.addresses 172.16.1.2/24
           """
     * Add "ethernet" connection named "bond0.1" for device "eth4" with options "master nm-bond autoconnect no"
     * Add "ethernet" connection named "bond0.0" for device "eth7" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0.1"
     * Bring "up" connection "bond0.0"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
     And "vlan\+srcmac\s+5" is visible with command "cat /sys/class/net/nm-bond/bonding/xmit_hash_policy"
     And "balance-xor" is visible with command "cat /sys/class/net/nm-bond/bonding/mode"


     @rhbz2107647
     @ver+=1.39.11
     @bond_vlan_filtering_unmanaged_bridge
     Scenario: bond - do not modify unmanaged bridge associated with managed bond
     * Create "veth" device named "test-bond0-1-0" with options "peer name test-bond0-1-1"
     * Create "veth" device named "test-bond0-2-0" with options "peer name test-bond0-2-1"
     * Create "veth" device named "test-br0-v0" with options "peer name test-br0-v1"
     * Create "bridge" device named "test-br0" with options "vlan_filtering 1"
     * Execute "ip link set test-br0 up"
     Then "vlan_filtering 1" is visible with command "ip -d link show test-br0" in "15" seconds
     * Execute "ip link set test-br0-v0 master test-br0"
     * Execute "ip link set test-br0-v0 up"
     * Execute "ip link set test-br0-v1 up"
     * Add "bond" connection named "test-bond0" for device "test-bond0" with options
       """
       master test-br0
       bond.options "mode=2,xmit_hash_policy=vlan+srcmac"
       slave-type bridge
       """
      * Add "ethernet" connection named "test-bond0-1-0" for device "test-bond0-1-0" with options "master test-bond0"
      * Add "ethernet" connection named "test-bond0-2-0" for device "test-bond0-2-0" with options "master test-bond0"
      * Bring "up" connection "test-bond0-1-0"
      * Bring "up" connection "test-bond0-2-0"
      * Bring "up" connection "test-bond0"
      Then "vlan_filtering 1" is visible with command "ip -d link show test-br0" in "15" seconds


      @rhbz2130287
      @ver+=1.41.3
      @bond_unattach_ports_on_controller_failure
      Scenario: bond - ports should be unattached when controller dependency fails
      * Create "bond" device named "nm-bond"
      * Add "bond" connection named "bond0" for device "nm-bond" with options
            """
            ipv4.method auto
            ipv6.method disabled
            autoconnect no
            connection.autoconnect-slaves yes
            """
     * Add "ethernet" connection named "bond0.0" for device "eth4" with options "master nm-bond autoconnect no"
     * Bring "up" connection "bond0"
     * Execute "ip link del nm-bond"
     Then "deactivating -> disconnected" is visible with command "journalctl  -t NetworkManager  --since -30s| grep '(eth4): state change:'" in "5" seconds
     And "enslaved to unknown device" is not visible with command "journalctl  -t NetworkManager  --since -30s" in "5" seconds
     * Create "bond" device named "nm-bond"
     * Modify connection "bond0" changing options "ipv4.method manual ipv4.addresses 172.16.1.2/24"
     * Bring "up" connection "bond0"
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "30" seconds
     When "nm-bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" for full "30" seconds
     When "eth4:connected:bond0.0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device"
     * Execute "ip link del nm-bond"
     And "enslaved to unknown device" is not visible with command "journalctl -t NetworkManager  --since -30s" in "5" seconds
     Then "deactivating -> disconnected" is visible with command "journalctl  -t NetworkManager  --since -30s | grep '(eth4): state change:'" in "5" seconds


    @rhbz2118817
    @ver+=1.40.2
    @ver/rhel/8/7+=1.40.0.5
    @ver/rhel/8/6+=1.36.0.12
    @ver/rhel/8/4+=1.30.0.17
    @restore_hostname @eth0
    @bond_set_hostname_even_when_links_do_not_come_up_immediately
    Scenario: bond - system should get hostname from DHCP over bond even when links come up with a delay
    * Execute "hostnamectl set-hostname ''"
    * Execute "systemctl stop systemd-hostnamed"
    * Execute "hostname localhost"
    * Execute "systemctl restart systemd-hostnamed"
    * Restart NM
    * Wait for "4" seconds
    * Add namespace "ns1"
    * Create "veth" device named "veth0" with options "peer name veth0p netns ns1"
    * Create "veth" device named "veth1" with options "peer name veth1p netns ns1"
    * Create "bond" device named "bond1" in namespace "ns1" with options "mode balance-rr"
    * Execute "ip -n ns1 link set bond1 up"
    * Execute "for if in veth{0,1}p; do ip -n ns1 link set ${if} master bond1; ip -n ns1 link set ${if} down; done"
    * Execute "ip -n ns1 address add dev bond1 172.25.1.1/24"
    * Wait for "0.2" seconds
    * Execute "for if in veth{0,1}; do ip link set ${if} up; done"
    * Run child "ip netns exec ns1 dnsmasq -d -h --interface bond1 --except-interface lo --host-record=client1234,172.25.1.101 --log-queries --no-resolv --server=8.8.8.8"
    * Add "ethernet" connection named "veth0" for device "veth0" with options "master bond0 slave-type bond"
    * Add "ethernet" connection named "veth1" for device "veth1" with options "master bond0 slave-type bond"
    * Add "bond" connection named "bond0" for device "bond0" with options
        """
        ipv6.method disabled
        ipv4.method manual ipv4.address 172.25.1.101/24
        ipv4.gateway 172.25.1.1 ipv4.dns 172.25.1.1
        mode balance-rr connection.autoconnect-slaves yes
        """
    * Dump status
    * Bring "up" connection "bond0"
    * Wait for "4" seconds
    * "client1234" is not visible with command "hostname"
    When Execute "for if in veth{0,1}p; do ip -n ns1 link set ${if} up; done"
    Then "client1234" is visible with command "hostname" in "10" seconds


    @rhbz2171827
    @rhbz2171832
    @ver+=1.42
    @ver/rhel/8/8+=1.40.12
    @bond_expose_dhcp_client_identifier
    Scenario: bond - expose DHCP client-id
    * Add "bond" connection named "bond0" for device "nm-bond" with options "ipv4.method auto ipv6.method disabled"
    * Add "ethernet" connection named "bond0.0" for device "eth10" with options "master bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0"
    When "inet" is visible with command "ip -4 a show nm-bond" in "15" seconds
    Then "dhcp_client_identifier" is visible with command "nmcli -t -f DHCP4.OPTION d show nm-bond" in "5" seconds
    * Commentary
        """
        DHCP client identifier is to be exposed at three interfaces and these should match:
          * nmcli device show
          * auto-generated device file in /run/NetworkManager/devices/IFINDEX
          * in D-Bus, more detailed description of this interface follows:

        In D-Bus, the information is provided in a DHCP4Config object that is separate from the
        per-device Device object. In order to get these, we need to run several calls to nmcli and busctl:
          * one to nmcli to find out D-Bus address of Device object
          * then busctl to query the Device object for the address of DHCP4Config object
          * then busctl to get the Options of the DHCP4Config object
          * last, we need seds along the way to extract only the values we want
        """
    Then "dhcp_client_identifier" is visible with command "nmcli -t -f DHCP4.OPTION d show nm-bond"
    Then "dhcp_client_identifier" is visible with command "cat /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')"
    Then "dhcp_client_identifier" is visible with command "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp4Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP4Config Options"
    * Note the output of "nmcli -t -f DHCP4.OPTION d show nm-bond | sed -n 's/.*dhcp_client_identifier = //p'" as value "client_id_nmcli"
    * Note the output of "sed -n 's/.*dhcp_client_identifier=//p' /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')" as value "client_id_run"
    * Note the output of "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp4Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP4Config Options | sed -e 's/.*dhcp_client_identifier" s "\([^"]*\).*$/\1/'" as value "client_id_dbus"
    Then Check noted values "client_id_nmcli" and "client_id_run" are the same
    Then Check noted values "client_id_nmcli" and "client_id_dbus" are the same


    @rhbz2171827
    @rhbz2171832
    @ver+=1.42
    @ver/rhel/8/8+=1.40.12
    @bond_expose_dhcp6_client_id
    Scenario: bond - expose DHCP DUID
    * Add "bond" connection named "bond0" for device "nm-bond" with options "ipv4.method disabled ipv6.method auto"
    * Prepare simulated test "eth11" device
    * Add "ethernet" connection named "bond0.0" for device "eth11" with options "master bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0"
    When "2620:dead:beaf" is visible with command "ip -6 a show nm-bond" in "15" seconds
    Then "dhcp6_client_id" is visible with command "nmcli -t -f DHCP6.OPTION d show nm-bond" in "5" seconds
    * Commentary
        """
        DHCP client identifier is to be exposed at three interfaces and these should match:
          * nmcli device show
          * auto-generated device file in /run/NetworkManager/devices/IFINDEX
          * in D-Bus, more detailed description of this interface follows:

        In D-Bus, the information is provided in a DHCP6Config object that is separate from the
        per-device Device object. In order to get these, we need to run several calls to nmcli and busctl:
          * one to nmcli to find out D-Bus address of Device object
          * then busctl to query the Device object for the address of DHCP6Config object
          * then busctl to get the Options of the DHCP6Config object
          * last, we need seds along the way to extract only the values we want
        """
    Then "dhcp6_client_id" is visible with command "nmcli -t -f DHCP6.OPTION d show nm-bond"
    Then "dhcp6_client_id" is visible with command "cat /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')"
    Then "dhcp6_client_id" is visible with command "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp6Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP6Config Options"
    * Note the output of "nmcli -t -f DHCP6.OPTION d show nm-bond | sed -n 's/.*dhcp6_client_id = //p'" as value "duid_nmcli"
    * Note the output of "sed -n 's/.*dhcp6_client_id=//p' /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')" as value "duid_run"
    * Note the output of "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp6Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP6Config Options | sed -e 's/.*dhcp6_client_id" s "\([^"]*\).*$/\1/'" as value "duid_dbus"
    Then Check noted values "duid_nmcli" and "duid_run" are the same
    Then Check noted values "duid_nmcli" and "duid_dbus" are the same


    @rhbz2169869
    @rhbz2152601
    @ver+=1.43.2
    @ver+=1.42.1
    @ver+=1.40.15
    @bond_expose_iaid
    Scenario: bond - expose DHCP IAID
    * Add "bond" connection named "bond0" for device "nm-bond" with options "ipv4.method disabled ipv6.method auto"
    * Prepare simulated test "eth11" device
    * Add "ethernet" connection named "bond0.0" for device "eth11" with options "master bond0"
    * Bring "up" connection "bond0.0"
    * Bring "up" connection "bond0"
    When "2620:dead:beaf" is visible with command "ip -6 a show nm-bond" in "15" seconds
    Then "iaid" is visible with command "nmcli -t -f DHCP6.OPTION d show nm-bond" in "5" seconds
    * Commentary
        """
        IAID is to be exposed at three interfaces and these should match:
          * nmcli device show
          * auto-generated device file in /run/NetworkManager/devices/IFINDEX
          * in D-Bus, more detailed description of this interface follows:

        In D-Bus, the information is provided in a DHCP6Config object that is separate from the
        per-device Device object. In order to get these, we need to run several calls to nmcli and busctl:
          * one to nmcli to find out D-Bus address of Device object
          * then busctl to query the Device object for the address of DHCP6Config object
          * then busctl to get the Options of the DHCP6Config object
          * last, we need seds along the way to extract only the values we want
        """
    Then "iaid" is visible with command "nmcli -t -f DHCP6.OPTION d show nm-bond"
    Then "iaid" is visible with command "cat /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')"
    Then "iaid" is visible with command "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp6Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP6Config Options"
    * Note the output of "nmcli -t -f DHCP6.OPTION d show nm-bond | sed -n 's/.*iaid = //p'" as value "iaid_nmcli"
    * Note the output of "sed -n 's/.*iaid=//p' /run/NetworkManager/devices/$(ip -o l show nm-bond | sed -e 's/:.*$//')" as value "iaid_run"
    * Note the output of "busctl get-property org.freedesktop.NetworkManager $(busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:nm-bond//p') org.freedesktop.NetworkManager.Device Dhcp6Config | sed -e 's/.*"\([^"]*\)".*/\1/') org.freedesktop.NetworkManager.DHCP6Config Options | sed -e 's/.*iaid" s "\([^"]*\).*$/\1/'" as value "iaid_dbus"
    Then Check noted values "iaid_nmcli" and "iaid_run" are the same
    Then Check noted values "iaid_nmcli" and "iaid_dbus" are the same
