Feature: NM: dispatcher


    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz982633
    @disp
    @dispatcher_preup_and_up
    Scenario: NM - dispatcher - preup and up
    * Write dispatcher "pre-up.d/98-disp" file
    * Write dispatcher "99-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Bring "up" connection "testeth1"
    Then "pre-up" is visible with command "cat /tmp/dispatcher.txt"
    Then "pre-up.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "pre-up.*\s+up" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds

    @rhbz982633
    @disp
    @dispatcher_predown_and_down
    Scenario: NM - dispatcher - pre-down and down
    * Bring "up" connection "testeth1"
    * Write dispatcher "pre-down.d/97-disp" file
    * Write dispatcher "99-disp" file with params "if [ "$2" == "down" ]; then sleep 15; fi"
    * Bring "down" connection "testeth1"
    Then "pre-down" is visible with command "cat /tmp/dispatcher.txt"
    Then "pre-down.*\s+down" is not visible with command "cat /tmp/dispatcher.txt"
    Then "pre-down.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds

    @dispatcher_vpn_up
    Scenario: NM - dispatcher - vpn-up

    @dispatcher_vpn_down
    Scenario: NM - dispatcher - vpn-down

    @disp @restore_hostname
    @dispatcher_hostname
    Scenario: NM - dispatcher - hostname
    * Write dispatcher "99-disp" file
    * Execute "nmcli general hostname walderoon"
    Then "hostname" is visible with command "cat /tmp/dispatcher.txt"

    @dispatcher_dhcp4_change
    Scenario: NM - dispatcher - dhcp4-change

    @dispatcher_dhcp6_change
    Scenario: NM - dispatcher - dhcp6-change


    @rhbz1048345
    @disp
    @dispatcher_synchronicity
    Scenario: NM - dispatcher - synchronicity
    * Write dispatcher "99-disp" file
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Bring "up" connection "testeth1"
    Then "connected" is visible with command "nmcli device show eth1" in "45" seconds
    * Bring "down" connection "testeth1"
    Then "up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "up.*\s+up.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds


    @rhbz1048345
    @disp
    @dispatcher_synchronicity_with_predown
    Scenario: NM - dispatcher - synchronicity with predown
    * Write dispatcher "99-disp" file
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Write dispatcher "pre-down.d/97-disp" file
    * Bring "up" connection "testeth1"
    * Bring down connection "testeth1" ignoring error
    Then "up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "up.*\s+up.*\s+pre-down.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds


    @rhbz1061212
    @disp
    @dispatcher_serialization
    Scenario: NM - dispatcher - serialization
    * Bring "down" connection "testeth1"
    * Bring "down" connection "testeth2"
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 10; echo $1 >> /tmp/dispatcher.txt; fi"
    * Write dispatcher "99-disp" file with params "if [ "$2" == "up" ]; then echo "quick$1" >> /tmp/dispatcher.txt; fi"
    * Bring "up" connection "testeth1"
    * Bring "up" connection "testeth2"
    #Then "eth1.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    #Then "eth2.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "eth1.*\s+up.*\s+quicketh1.*\s+up.*\s+eth2.*\s+up.*\s+quicketh2.*\s+up" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds

    @rhbz1663253
    @ver+=1.20
    @disp @con_ipv4_remove @teardown_testveth @dhclient_DHCP
    @dispatcher_private_dhcp_option_dhclient
    Scenario: NM - dispatcher - private option 245 dhclient plugin
    * Prepare simulated test "testX" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Write dispatcher "99-disp" file with params "[ "$2" != "up" ] && exit 0 || echo DHCP4_UNKNOWN_245=$DHCP4_UNKNOWN_245,DHCP4_PRIVATE_245=$DHCP4_PRIVATE_245 >> /tmp/dispatcher.txt"
    * Add a new connection of type "ethernet" and options "ifname testX con-name con_ipv4"
    * Bring "up" connection "con_ipv4"
    Then "DHCP4_UNKNOWN_245=aa:bb:cc:dd,DHCP4_PRIVATE_245=aa:bb:cc:dd" is visible with command "cat /tmp/dispatcher.txt" in "5" seconds

    @rhbz1663253
    @ver+=1.20
    @disp @con_ipv4_remove @teardown_testveth @internal_DHCP
    @dispatcher_private_dhcp_option_internal
    Scenario: NM - dispatcher - private dhcp option 245 internal plugin
    * Prepare simulated test "testX" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Write dispatcher "99-disp" file with params "[ "$2" != "up" ] && exit 0 || echo DHCP4_UNKNOWN_245=$DHCP4_UNKNOWN_245,DHCP4_PRIVATE_245=$DHCP4_PRIVATE_245 >> /tmp/dispatcher.txt"
    * Add a new connection of type "ethernet" and options "ifname testX con-name con_ipv4"
    * Bring "up" connection "con_ipv4"
    Then "DHCP4_UNKNOWN_245=aa:bb:cc:dd,DHCP4_PRIVATE_245=aa:bb:cc:dd" is visible with command "cat /tmp/dispatcher.txt" in "5" seconds


    @rhbz1674550
    @ver+=1.19
    @disp
    @dispatcher_usr_lib_dir
    Scenario: NM - dispatcher - usr lib dir dispatcher scripts
    * Write dispatcher "/usr/lib/NetworkManager/dispatcher.d/99-disp" file
    * Bring "up" connection "testeth1"
    Then "up" is visible with command "cat /tmp/dispatcher.txt" in "10" seconds
