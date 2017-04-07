Feature: nmcli: inf

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @inf
    @inf_create_connection
    Scenario: nmcli - inf - create master connection
    * Add connection type "infiniband" named "inf" for device "inf_ib0"
    * Bring "up" connection "inf"
    Then "inet 172" is visible with command "ip a s inf_ib0"


    @inf
    @inf_create_connection_novice_mode
    Scenario: nmcli - inf - novice - create infiniband with default options
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "infiniband" in editor
     * Expect "Interface name"
     * Submit "inf_ib0" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Bring "up" connection "infiniband-inf_ib0"
    Then "inet 172" is visible with command "ip a s inf_ib0"


    @inf
    @inf_disable_connection
    Scenario: nmcli - inf - disable master connection
    * Add connection type "infiniband" named "inf" for device "inf_ib0"
    * Bring "up" connection "inf"
    * Bring "down" connection "inf"
    Then "inet 172" is not visible with command "ip a s inf_ib0"


    @inf
    @inf_create_port_connection
    Scenario: nmcli - inf - create port connection
    * Add connection type "infiniband" named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002"


    @inf
    @inf_create_port_novice_mode
    Scenario: nmcli - inf - novice - create infiniband port with default options
     * Add connection type "infiniband" named "inf" for device "inf_ib0"
     * Bring "up" connection "inf"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "infiniband" in editor
     * Expect "Interface name"
     * Submit "inf_ib0.8002" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "yes" in editor
     * Expect "MTU"
     * Enter in editor
     * Expect "MAC"
     * Enter in editor
     * Expect "Transport mode"
     * Enter in editor
     * Expect "Parent interface"
     * Submit "inf_ib0" in editor
     * Expect "P_KEY"
     * Submit "0x8002" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Bring "up" connection "inf"
     * Bring "up" connection "infiniband-inf_ib0.8002"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002"


    @inf
    @inf_disable_port
    Scenario: nmcli - inf - disable port connection
    * Add connection type "infiniband" named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    * Bring "down" connection "inf.8002"
    Then "inet 172" is visible with command "ip a s inf_ib0"
    Then "inet 172" is not visible with command "ip a s inf_ib0.8002"


    @inf
    @inf_enable_after_reboot
    Scenario: nmcli - inf - enable after reboot
    * Add connection type "infiniband" named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    * Reboot
    Then "inet 172" is visible with command "ip a s inf_ib0"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002"


    @rhbz1339008
    @ver+=1.4.0
    @inf @bond
    @inf_master_in_bond
    Scenario: nmcli - inf - inf master in bond
     * Add connection type "infiniband" named "inf" for device "inf_ib0"
     * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 bond.options mode=active-backup"
     * Execute "nmcli connection modify id inf connection.slave-type bond connection.master nm-bond"
     * Bring "up" connection "inf"
     * Bring "up" connection "bond0"
     Then "inet 172" is visible with command "ip a s nm-bond"
      And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And "inf_ib0:infiniband:connected:inf" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And Check bond "nm-bond" link state is "up"
      And Check slave "inf_ib0" in bond "nm-bond" in proc


    @rhbz1375558
    @ver+=1.4.0
    @inf_master_in_bond_restart_persistence
    @inf @bond @restart
    Scenario: nmcli - inf - inf master in bond res
     * Add connection type "infiniband" named "inf" for device "inf_ib0"
     * Add a new connection of type "bond" and options "ifname nm-bond con-name bond0 bond.options mode=active-backup"
     * Execute "nmcli connection modify id inf connection.slave-type bond connection.master nm-bond"
     * Bring "up" connection "inf"
     * Bring "up" connection "bond0"
     When "inet 172" is visible with command "ip a s nm-bond"
      And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And "inf_ib0:infiniband:connected:inf" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And Check bond "nm-bond" link state is "up"
      And Check slave "inf_ib0" in bond "nm-bond" in proc
     * Restart NM
    Then "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And "inf_ib0:infiniband:connected:inf" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
     And Check bond "nm-bond" link state is "up"
     And Check slave "inf_ib0" in bond "nm-bond" in proc


    @rhbz1281301
    @ver+=1.4.0
    @inf
    @inf_down_before_mode_change
    Scenario: nmcli - inf - take down device before changing
    * Add a new connection of type "infiniband" and options "con-name inf ifname inf_ib0 infiniband.transport-mode datagram"
    * Add a new connection of type "infiniband" and options "con-name inf2 ifname inf_ib0 infiniband.transport-mode connected"
    * Bring "up" connection "inf"
    * Execute "nmcli general logging level debug domains all"
    * Run child "journalctl -f > /tmp/journal.txt"
    * Bring "up" connection "inf2"
    * Execute "pkill journalctl; sleep 2"
    When "taking down device.*inf_ib0/mode' to 'connected'" is visible with command "egrep 'taking|datagram' /tmp/journal.txt"
    * Run child "journalctl -f > /tmp/journal.txt"
    * Bring "up" connection "inf"
    * Execute "sleep 2;pkill journalctl"
    Then "taking down device.*inf_ib0/mode' to 'datagram'" is visible with command "egrep 'taking|datagram' /tmp/journal.txt"
