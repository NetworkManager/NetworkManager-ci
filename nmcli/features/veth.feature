Feature: nmcli: veth

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhbz1901523
    @ver+=1.29
    @veth_remove
    @veth_profile_add
    Scenario: nmcli - veth - add profile
    * Add a new connection of type "veth" and options "con-name con_veth1 ifname test11 veth.peer test12"
    * Add a new connection of type "veth" and options "con-name con_veth2 ifname test12 veth.peer test11 ipv4.method shared"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    Then "inet 10.42.0.1" is visible with command "ip a s test12"
    Then "inet 10.42.0." is visible with command "ip a s test11"
    Then "default via 10.42.0.1 dev test11" is visible with command "ip r"


    @rhbz1901523
    @ver+=1.29
    @veth_remove
    @veth_profile_remove
    Scenario: nmcli - veth - remove profile
    * Add a new connection of type "veth" and options "con-name con_veth1 ifname test11 veth.peer test12 ip4 10.42.0.2"
    * Add a new connection of type "veth" and options "con-name con_veth2 ifname test12 veth.peer test11 ip4 10.42.0.1"
    * Bring "up" connection "con_veth2"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # Crash when order is con_veth2 before con_veth1 #1915276
    * Delete connection "con_veth2"
    * Delete connection "con_veth1"
    Then "test11" is not visible with command "ip a s"
    Then "test11" is not visible with command "nmcli device"
    Then "test12" is not visible with command "ip a s"
    Then "test12" is not visible with command "nmcli device"

    #
    # @rhbz1901523
    # @ver+=1.29
    # @veth_remove
    # @veth_device_remove
    # Scenario: nmcli - veth - remove device
    # * Add a new connection of type "veth" and options "con-name con_veth1 ifname test11 veth.peer test12 ip4 10.42.0.2"
    # * Add a new connection of type "veth" and options "con-name con_veth2 ifname test12 veth.peer test11 ip4 10.42.0.1"
    # * Bring "up" connection "con_veth2"
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # # Null error, both connections should go down 1915278
    # * Delete device "test11"
    # Then "test11" is not visible with command "ip a s"
    # Then "test11" is not visible with command "nmcli device"
    # Then "test12" is not visible with command "ip a s"
    # Then "test12" is not visible with command "nmcli device"
    #
    #
    # # @veth_change_peer
    # # @veth_in_bridge
    # # @veth_in_bond
    #
    #
    # @rhbz1901523
    # @ver+=1.29
    # @veth_remove @restart
    # @veth_profile_restart_persistnce
    # Scenario: nmcli - veth - restart persistence
    # * Add a new connection of type "veth" and options "con-name con_veth1 ifname test11 veth.peer test12 ip4 10.42.0.2"
    # * Add a new connection of type "veth" and options "con-name con_veth2 ifname test12 veth.peer test11 ip4 10.42.0.1"
    # * Bring "up" connection "con_veth1"
    # * Bring "up" connection "con_veth2"
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # * Reboot
    # # This, for some reason, is not working, only con_veth2 is upped
    # # You need to restart NM service to have test12 assumed, then you can up con_veth1 and then con_veth2
    # # The rest is OK, when you do these two
    # # 1915284
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth2" in "45" seconds
    # When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_veth1" in "45" seconds
    # Then "inet 10.42.0.1" is visible with command "ip a s test12"
    # Then "inet 10.42.0." is visible with command "ip a s test11"
