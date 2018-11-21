 Feature: nmcli: sriov

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    ################# Test set with VF driver and device ######################################
    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF
    Scenario: nmcli - sriov - drv - add 1 VF
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.total-vfs 1"
    * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    * Bring "up" connection "sriov_2"
    Then "1" is visible with command "cat /sys/class/net/em2/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep em2_0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_mac
    Scenario: nmcli - sriov - drv - add 1 VF with mac
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:99' sriov.total-vfs 1"
    * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    * Bring "up" connection "sriov_2"
    Then "1" is visible with command "cat /sys/class/net/em2/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep em2_0"
    And "00:11:22:33:44:99" is visible with command "ip a s em2_0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_mtu
    Scenario: nmcli - sriov - drv - add 1 VF with mtu
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:99' sriov.total-vfs 1 802-3-ethernet.mtu 9000"
    # Workaround for 1651974
    # * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24 802-3-ethernet.mtu 9000"
    # WQorkaround for 1651974
    # * Bring "up" connection "sriov_2"
    And " connected" is visible with command "nmcli  device |grep em2_0"
    And "00:11:22:33:44:99" is visible with command "ip a s em2_0"
    And "9000" is visible with command "ip a s em2_0" in "10" seconds


    @rhbz1555013
    @ver+=1.14.0
    @sriov @tcpdump
    @sriov_con_drv_add_VF_vlan
    Scenario: nmcli - sriov - drv - add 1 VF with vlan Q
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 vlans=100.2.q' sriov.total-vfs 1"
    * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    * Run child "tcpdump -n -i em2 -xxvv -e > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    * Bring "up" connection "sriov_2"
    Then "802.1Q.*vlan 100, p 2" is visible with command "cat /tmp/tcpdump.log" in "20" seconds
    * Execute "pkill tcpdump"


    # Not working under RHEL8 as protocol seems to be unsupported
    # @rhbz1555013
    # @ver+=1.14.0
    # @sriov @tcpdump
    # @sriov_con_drv_add_VF_vlan_ad
    # Scenario: nmcli - sriov - drv - add 1 VF with vlan AD
    # * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 vlans=100.2.ad' sriov.total-vfs 1"
    # * Bring "up" connection "sriov"
    # * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    # * Run child "tcpdump -n -i em2 -xxvv -e > /tmp/tcpdump.log"
    # When "empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    # * Bring "up" connection "sriov_2"
    # Then "802.1AD.*vlan 100, p 2" is visible with command "cat /tmp/tcpdump.log" in "20" seconds
    # * Execute "pkill tcpdump"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_trust
    Scenario: nmcli - sriov - drv - add 1 VF with trust
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 trust=true' sriov.total-vfs 1"
    # * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    When " connected" is visible with command "nmcli  device |grep em2_0"
    And "trust on" is visible with command " ip l show dev em2"
    And "BMRU" is visible with command "netstat -i |grep em2_0"
    * Execute "ip link set em2_0 promisc on"
    Then "BMPRU" is visible with command "netstat -i |grep em2_0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_trust_off
    Scenario: nmcli - sriov - drv - add 1 VF with trust off
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 trust=false' sriov.total-vfs 1"
    # * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    When " connected" is visible with command "nmcli  device |grep em2_0"
    And "trust off" is visible with command " ip l show dev em2"
    And "BMRU" is visible with command "netstat -i |grep em2_0"
    * Execute "ip link set em2_0 promisc on"
    Then "BMPRU" is not visible with command "netstat -i |grep em2_0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_spoof_off
    Scenario: nmcli - sriov - drv - add 1 VF without spoof check
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=false' sriov.total-vfs 1"
    # * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    When " connected" is visible with command "nmcli  device |grep em2_0"
    And "spoof checking off" is visible with command " ip l show dev em2"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_drv_add_VF_spoof
    Scenario: nmcli - sriov - drv - add 1 VF without spoof check
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=true' sriov.total-vfs 1"
    # * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24"
    When " connected" is visible with command "nmcli  device |grep em2_0"
    And "spoof checking on" is visible with command " ip l show dev em2"


    @rhbz1555013
    @ver+=1.14.0
    @sriov @firewall
    @sriov_con_drv_add_VF_firewalld
    Scenario: nmcli - sriov - drv - add 1 VF with firewall zone
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 vlan=100.2.q' sriov.total-vfs 1"
    * Bring "up" connection "sriov"
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.4/24 connection.zone work"
    * Bring "up" connection "sriov_2"
    Then "1" is visible with command "cat /sys/class/net/em2/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep em2_0"
    Then "work\s+interfaces: em2_0" is visible with command "firewall-cmd --get-active-zones"



    ################# Test set WITHOUT VF driver (just inder PF device) ######################################

    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF
    Scenario: nmcli - sriov - add 1 VF
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "1" is visible with command "cat /sys/class/net/em2/device/sriov_numvfs"
    And "vf 0" is visible with command "ip link show dev em2 |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_mac
    Scenario: nmcli - sriov - add 1 VF with mac
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:99' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "1" is visible with command "cat /sys/class/net/em2/device/sriov_numvfs"
    And "00:11:22:33:44:99" is visible with command "ip link show dev em2 |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_mtu
    Scenario: nmcli - sriov - add 1 VF with mtu
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:99' sriov.total-vfs 1 802-3-ethernet.mtu 9000 sriov.autoprobe-drivers false sriov.autoprobe-drivers false"
    And "00:11:22:33:44:99" is visible with command "ip link show dev em2 |grep 'vf 0'"
    And "9000" is visible with command "ip link show dev em2 |grep 'vf 0'" in "10" seconds


    @rhbz1555013
    @ver+=1.14.0
    @sriov @tcpdump
    @sriov_con_add_VF_vlan
    Scenario: nmcli - sriov - add 1 VF with vlan Q
    * Run child "tcpdump -n -i em2 -xxvv -e > /tmp/tcpdump.log"
    When "empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 vlans=100.2.q' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "802.1Q.*vlan 100, p 2" is visible with command "cat /tmp/tcpdump.log" in "45" seconds
    * Execute "pkill tcpdump"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_trust
    Scenario: nmcli - sriov - add 1 VF with trust
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 trust=true' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "trust on" is visible with command "ip link show dev em2 |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_trust_off
    Scenario: nmcli - sriov - add 1 VF with trust off
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 trust=false' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "trust off" is visible with command "ip link show dev em2 |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_spoof_off
    Scenario: nmcli - sriov - add 1 VF without spoof check
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=false' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "spoof checking off" is visible with command "ip link show dev em2 |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0
    @sriov
    @sriov_con_add_VF_spoof
    Scenario: nmcli - sriov - add 1 VF without spoof check
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=true' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    Then "spoof checking on" is visible with command "ip link show dev em2 |grep 'vf 0'"



    # @rhbz1555013
    # @ver+=1.14.0
    # @sriov @firewall
    # @sriov_con_add_VF_firewalld
    # Scenario: nmcli - sriov - add 1 VF with firewall zone
    # * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov sriov.vfs '0 vlan=100.2.q' sriov.total-vfs 1 sriov.autoprobe-drivers false"
    # Then "work\s+interfaces: em2" is visible with command "firewall-cmd --get-active-zones"



    ################# Test set with VF enabled via config file ######################################

    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_enable
    Scenario: NM - sriov - enable sriov in config
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em1" device with "63" VFs
    When "64" is visible with command "nmcli dev |grep em1  |wc -l" in "20" seconds
    * Prepare "98-sriov.conf" config for "em2" device with "63" VFs
    When "64" is visible with command "nmcli dev |grep em2  |wc -l" in "20" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_disable
    Scenario: NM - sriov - disable sriov in config
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    * Prepare "99-sriov.conf" config for "em1" device with "2" VFs
    When "3" is visible with command "nmcli dev |grep em1  |wc -l"
    * Prepare "99-sriov.conf" config for "em1" device with "0" VFs
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"


    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_connect
    Scenario: NM - sriov - connect virtual sriov device
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov autoconnect no ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov_2 autoconnect no ipv4.method manual ipv4.address 1.2.3.5/24"
    * Bring "up" connection "sriov"
    * Bring "up" connection "sriov_2"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_2" in "5" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_autoconnect
    Scenario: NM - sriov - autoconnect virtual sriov device
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.5/24"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_2" in "5" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_connect_externally
    Scenario: NM - sriov - see externally connected sriov device
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Execute "echo 2 > /sys/class/net/em1/device/sriov_numvfs"
    * Execute "ip add add 192.168.1.2/24 dev em1_0"
    Then "192.168.1.2/24" is visible with command "nmcli con sh em1_0 |grep IP4" in "2" seconds


    # @rhbz1398934
    # @ver+=1.8.0
    # @sriov
    # @sriov_set_mtu
    # Scenario: NM - sriov - change mtu
    # When "10" is visible with command "nmcli dev |wc -l"
    # * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    # * Add a new connection of type "ethernet" and options "ifname enp5s16f1 con-name sriov ipv4.method manual ipv4.address 1.2.3.4/24 802-3-ethernet.mtu 9000"
    # Then "9000" is visible with command "ip a s enp5s16f1" in "2" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov
    @sriov_reboot_persistence
    Scenario: NM - sriov - reboot persistence
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name sriov ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name sriov_2 ipv4.method manual ipv4.address 1.2.3.5/24"
    * Bring "down" connection "sriov"
    * Bring "down" connection "sriov_2"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_2" in "5" seconds
