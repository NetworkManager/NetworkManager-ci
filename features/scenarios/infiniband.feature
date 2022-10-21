Feature: nmcli: inf

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @inf
    @inf_create_connection
    Scenario: nmcli - inf - create master connection
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Bring "up" connection "inf"
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds


    @inf
    @ver-1.40
    @inf_create_connection_novice_mode
    Scenario: nmcli - inf - novice - create infiniband with default options
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "infiniband" in editor
     * Expect "Do you want to provide it\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "Interface name"
     * Submit "inf_ib0" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "no" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Wait for "1" seconds
     * Bring "up" connection "infiniband"
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds


    @inf
    @ver+=1.40
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
     * Wait for "1" seconds
     * Bring "up" connection "infiniband"
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds


    @inf
    @inf_disable_connection
    Scenario: nmcli - inf - disable master connection
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Bring "up" connection "inf"
    * Bring "down" connection "inf"
    Then "inet 172" is not visible with command "ip a s inf_ib0" in "10" seconds


    @inf
    @inf_create_port_connection
    Scenario: nmcli - inf - create port connection
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002" in "10" seconds


    @ver+=1.10.0
    @ver-1.40
    @inf
    @inf_create_port_novice_mode
    Scenario: nmcli - inf - novice - create infiniband port with default options
     * Add "infiniband" connection named "inf" for device "inf_ib0"
     * Bring "up" connection "inf"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "infiniband" in editor
     * Expect "Do you want to provide it\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "Interface name"
     * Submit "inf_ib0.8002" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Submit "yes" in editor
     * Expect "MAC"
     * Enter in editor
     * Expect "MTU"
     * Enter in editor
     * Expect "Transport mode"
     * Submit "datagram" in editor
     # TO avoid https://bugzilla.redhat.com/show_bug.cgi?id=2053603
     #* Enter in editor
     * Expect "P_KEY"
     * Submit "0x8002" in editor
     * Expect "Parent interface"
     * Submit "inf_ib0" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Wait for "1" seconds
     * Bring "up" connection "inf"
     * Bring "up" connection "infiniband"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002" in "10" seconds


    @ver+=1.40.0
    @inf
    @inf_create_port_novice_mode
    Scenario: nmcli - inf - novice - create infiniband port with default options
     * Add "infiniband" connection named "inf" for device "inf_ib0"
     * Bring "up" connection "inf"
     * Open wizard for adding new connection
     * Expect "Connection type"
     * Submit "infiniband" in editor
     * Expect "Interface name"
     * Submit "inf_ib0.8002" in editor
     * Expect "Do you want to provide them\? \(yes\/no\) \[yes\]"
     * Enter in editor
     * Expect "MAC"
     * Enter in editor
     * Expect "MTU"
     * Enter in editor
     * Expect "Transport mode"
     * Submit "datagram" in editor
     # TO avoid https://bugzilla.redhat.com/show_bug.cgi?id=2053603
     #* Enter in editor
     * Expect "P_KEY"
     * Submit "0x8002" in editor
     * Expect "Parent interface"
     * Submit "inf_ib0" in editor
     * Dismiss IP configuration in editor
     * Dismiss Proxy configuration in editor
     * Wait for "1" seconds
     * Bring "up" connection "inf"
     * Bring "up" connection "infiniband"
    Then "inet 172" is visible with command "ip a s inf_ib0.8002" in "10" seconds



    @inf
    @inf_disable_port
    Scenario: nmcli - inf - disable port connection
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    * Bring "down" connection "inf.8002"
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds
    Then "inet 172" is not visible with command "ip a s inf_ib0.8002"


    @inf
    @inf_enable_after_reboot
    Scenario: nmcli - inf - enable after reboot
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    * Reboot
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds
    Then "inet 172" is visible with command "ip a s inf_ib0.8002"


    @rhbz1477678
    @ver+=1.10.0
    @inf @internal_DHCP
    @inf_internal_dhcp
    Scenario: nmcli - inf - enable after reboot
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Add infiniband port named "inf.8002" for device "inf_ib0.8002" with parent "inf_ib0" and p-key "0x8002"
    * Bring "up" connection "inf"
    * Bring "up" connection "inf.8002"
    When "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds
     And "inet 172" is visible with command "ip a s inf_ib0.8002"
    * Reboot
    Then "inet 172" is visible with command "ip a s inf_ib0" in "10" seconds
     And "inet 172" is visible with command "ip a s inf_ib0.8002"


    @rhbz1339008
    @ver+=1.4.0
    @inf
    @inf_master_in_bond
    Scenario: nmcli - inf - inf master in bond
     * Add "infiniband" connection named "inf" for device "inf_ib0"
     * Add "bond" connection named "bond0" for device "nm-bond" with options "bond.options mode=active-backup"
     * Execute "nmcli connection modify id inf connection.slave-type bond connection.master nm-bond"
     * Bring "up" connection "inf"
     * Bring "up" connection "bond0"
     Then "inet 172" is visible with command "ip a s nm-bond" in "10" seconds
      And "nm-bond:bond:connected:bond0" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And "inf_ib0:infiniband:connected:inf" is visible with command "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device" in "5" seconds
      And Check bond "nm-bond" link state is "up"
      And Check slave "inf_ib0" in bond "nm-bond" in proc


    @rhbz1375558
    @ver+=1.4.0
    @inf @restart_if_needed
    @inf_master_in_bond_restart_persistence
    Scenario: nmcli - inf - inf master in bond res
     * Add "infiniband" connection named "inf" for device "inf_ib0"
     * Add "bond" connection named "bond0" for device "nm-bond" with options "bond.options mode=active-backup"
     * Execute "nmcli connection modify id inf connection.slave-type bond connection.master nm-bond"
     * Bring "up" connection "inf"
     * Bring "up" connection "bond0"
     Then "inet 172" is visible with command "ip a s nm-bond" in "10" seconds
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
    * Add "infiniband" connection named "inf" for device "inf_ib0" with options "infiniband.transport-mode datagram"
    * Add "infiniband" connection named "inf2" for device "inf_ib0" with options "infiniband.transport-mode connected"
    * Bring "up" connection "inf"
    * Execute "nmcli general logging level debug domains all"
    * Run child "journalctl -f > /tmp/journal.txt"
    * Bring "up" connection "inf2"
    * Execute "pkill journalctl; sleep 2"
    When "taking down device.*inf_ib0/mode' to 'connected'" is visible with command "egrep "taking|datagram" /tmp/journal.txt"
    * Run child "journalctl -f > /tmp/journal.txt"
    * Bring "up" connection "inf"
    * Execute "sleep 2;pkill journalctl"
    Then "taking down device.*inf_ib0/mode' to 'datagram'" is visible with command "egrep "taking|datagram" /tmp/journal.txt"


    @rhbz1658057
    @rhelver+=8
    @internal_DHCP @tcpdump @inf
    @inf_send_correct_client_id
    Scenario: NM - inf - internal - send client id
    * Add "infiniband" connection named "inf" for device "inf_ib0"
    * Add "infiniband" connection named "inf.8002" for device "inf_ib0.8002" with options
          """
          parent inf_ib0
          p-key 0x8002
          ipv4.addresses 1.2.3.4/24,1.2.4.5/24,1.2.5.6/24,1.2.6.8/24,1.3.5.7/24,1.2.1.2/24,1.1.2.1/24,1.1.2.2/24,1.1.2.3/24,1.1.2.4/24,1.1.2.5/24,1.1.2.6/24,1.1.2.7/24,1.1.2.8/24,1.1.2.9/24,1.1.2.10/24
          """
    * Run child "sudo tcpdump -l -i any -v -n > /tmp/tcpdump.log"
    * Run child "nmcli con up inf.8002"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "150" seconds
    * Note MAC address output for device "inf_ib0.8002" via ip command
    Then Noted value is visible with command "grep 'Client-ID.*61' /tmp/tcpdump.log" in "10" seconds


    @rhbz1653494
    @ver+=1.18.0
    @inf
    @inf_mtu
    Scenario: nmcli - inf - mtu
    * Add "infiniband" connection named "inf" for device "inf_ib0.8010" with options
          """
          parent inf_ib0
          p-key 0x8010
          infiniband.mtu 2042
          """
    * Bring "up" connection "inf"
    When "2042" is visible with command "ip a s inf_ib0.8010"
    * Add "infiniband" connection named "inf2" for device "inf_ib0.8010" with options
          """
          parent inf_ib0
          p-key 0x8010
          infiniband.mtu 4092
          """
    * Bring "up" connection "inf2"
    Then "4092" is visible with command "ip a s inf_ib0.8010"


    # Keep this test at the end as it may leave residues
    @rhbz2122703
    @ver+=1.40.2
    @inf
    @inf_reload
    Scenario: nmcli - inf - reload
    * Add "infiniband" connection named "possibly_hidden_inf" for device "ib0.000e" with options
          """
          parent ib0 p-key 14
          """
    * Reload connections
    * "possibly_hidden_inf" is visible with command "nmcli con"
