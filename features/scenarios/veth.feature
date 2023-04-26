Feature: nmcli: veth

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhbz1901523
    @ver+=1.29
    @veth_profile_add
    Scenario: nmcli - veth - add profile
    * Add "veth" connection named "con_veth1" for device "veth11" with options "veth.peer veth12"
    * Add "veth" connection named "con_veth2" for device "veth12" with options "veth.peer veth11 ipv4.method shared"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    Then "inet 10.42.0.1" is visible with command "ip a s veth12"
    Then "inet 10.42.0." is visible with command "ip a s veth11"
    Then "default via 10.42.0.1 dev veth11" is visible with command "ip r"


    @rhbz1901523
    @ver+=1.29
    @veth_profile_remove
    Scenario: nmcli - veth - remove profile
    * Add "veth" connection named "con_veth1" for device "veth11" with options "veth.peer veth12 ip4 10.42.0.2"
    * Add "veth" connection named "con_veth2" for device "veth12" with options "veth.peer veth11 ip4 10.42.0.1"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # Crash when order is con_veth2 before con_veth1 #1915276
    * Delete connection "con_veth2"
    * Delete connection "con_veth1"
    Then "veth11" is not visible with command "ip a s"
    Then "veth11" is not visible with command "nmcli device"
    Then "veth12" is not visible with command "ip a s"
    Then "veth12" is not visible with command "nmcli device"


    @rhbz1915276
    @ver+=1.31
    @veth_profile_remove_in_cycle
    Scenario: nmcli - veth - remove profile in cycle
    Then Execute reproducer "repro_1915276.sh" for "20" times


    @rhbz1915278
    @ver+=1.29
    @veth_device_remove
    Scenario: nmcli - veth - remove device
    * Add "veth" connection named "con_veth1" for device "veth11" with options "veth.peer veth12 ip4 10.42.0.2"
    * Add "veth" connection named "con_veth2" for device "veth12" with options "autoconnect no veth.peer veth11 ip4 10.42.0.1"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # Null error, both connections should go down 1915278
    * Delete device "veth11"
    Then "veth11" is not visible with command "ip a s"
    Then "veth11" is not visible with command "nmcli device"
    Then "veth12" is not visible with command "ip a s"
    Then "veth12" is not visible with command "nmcli device"


    @rhbz1915278
    @ver+=1.43.6
    @temporary_skip
    @veth_device_remove_return
    Scenario: nmcli - veth - remove device but the veth peer gets autoconnected again
    * Add "veth" connection named "con_veth1" for device "veth11" with options "veth.peer veth12 ip4 10.42.0.2"
    * Add "veth" connection named "con_veth2" for device "veth12" with options "veth.peer veth11 ip4 10.42.0.1"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # Null error, both connections should go down 1915278
    * Delete device "veth11"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    Then "veth11:unmanaged" is visible with command "nmcli -g DEVICE,STATE d"
    Then "veth12:connected" is visible with command "nmcli -g DEVICE,STATE d"


    # @veth_change_peer
    # @veth_in_bridge
    # @veth_in_bond


    @rhbz1901523 @rhbz1915284 @rhbz2105956
    @ver+=1.39.9
    @restart_if_needed
    @veth_profile_restart_persistnce
    Scenario: nmcli - veth - restart persistence
    * Add "veth" connection named "con_veth1" for device "veth11" with options "veth.peer veth12 ip4 10.42.0.2"
    * Add "veth" connection named "con_veth2" for device "veth12" with options "veth.peer veth11 ip4 10.42.0.1"
    * Bring "up" connection "con_veth1"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    Then "inet 10.42.0.1" is visible with command "ip a s veth12"
    Then "inet 10.42.0." is visible with command "ip a s veth11"
