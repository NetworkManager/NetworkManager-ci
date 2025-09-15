 Feature: nmcli: sriov

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    ################# Test set with VF enabled via config file ######################################

    @rhbz1398934
    @ver+=1.8.0
    @sriov_enable
    Scenario: NM - sriov - enable sriov in config
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "98-sriov.conf" config for "sriov_device" device with "32" VFs
    When "Exactly" "32" lines with pattern "^eth" are visible with command "nmcli dev" in "40" seconds


    @rhbz1398934
    @ver+=1.33.3
    @sriov_enable_with_deployed_profile
    Scenario: NM - sriov - enable sriov in config
    * Cleanup connection "sriov_device"
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Execute "nmcli device connect sriov_device"
    When " connected" is visible with command "nmcli  device |grep sriov_device"
    * Prepare "98-sriov.conf" config for "sriov_device" device with "4" VFs
    When "Exactly" "4" lines with pattern "^eth" are visible with command "nmcli dev" in "40" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_disable
    Scenario: NM - sriov - disable sriov in config
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "0" VFs
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev" in "20" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_connect
    Scenario: NM - sriov - connect virtual sriov device
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Add "ethernet" connection named "sriov_port" for device "eth0" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    * Add "ethernet" connection named "sriov_port2" for device "eth1" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.address 1.2.3.5/24
          """
    When "eth0" is visible with command "nmcli device" in "5" seconds
    * Bring "up" connection "sriov_port"
    * Bring "up" connection "sriov_port2"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port2" in "5" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_autoconnect
    Scenario: NM - sriov - autoconnect virtual sriov device
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Add "ethernet" connection named "sriov_port" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    * Add "ethernet" connection named "sriov_port2" for device "eth1" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.5/24
          """
    When "eth0" is visible with command "nmcli device" in "5" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port2" in "5" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_connect_externally
    Scenario: NM - sriov - see externally connected sriov device
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Execute "echo 2 > /sys/class/net/sriov_device/device/sriov_numvfs"
    When "eth0" is visible with command "nmcli device" in "5" seconds
    * Execute "ip add add 192.168.1.2/24 dev eth0"
    Then "192.168.1.2/24" is visible with command "nmcli con sh eth0 |grep IP4" in "2" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_set_mtu
    Scenario: NM - sriov - change mtu
    * Cleanup execute "echo 0 > /sys/class/net/sriov_device/device/sriov_numvfs" with priority "50"
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
        * Add "ethernet" connection named "sriov" for device "eth0" with options
       """
       ipv4.method manual
       ipv4.address 1.2.3.4/24
       802-3-ethernet.mtu 9000
       """
    Then "9000" is visible with command "ip a s eth0" in "2" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov_reboot_persistence
    Scenario: NM - sriov - reboot persistence
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "2" VFs
    When "Exactly" "2" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Add "ethernet" connection named "sriov_port" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    * Add "ethernet" connection named "sriov_port2" for device "eth1" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.5/24
          """
    When "eth1" is visible with command "nmcli device" in "5" seconds
    * Bring "down" connection "sriov_port"
    * Bring "down" connection "sriov_port2"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port" in "25" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show sriov_port2" in "25" seconds


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_bond_with_config
    Scenario: nmcli - sriov - drv - bond with VF and ethernet reboot persistence
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Prepare "95-nmci-sriov.conf" config for "sriov_device" device with "1" VFs
    When "Exactly" "1" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Add "bond" connection named "sriov_bond0" for device "bond0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          bond.options 'mode=active-backup,primary=eth0,miimon=100,fail_over_mac=2'
          """
    When "eth0" is visible with command "nmcli device" in "5" seconds
    * Add slave connection for master "bond0" on device "eth0" named "sriov_bond0.0"
    * Add "dummy" connection named "sriov_bond0.1" for device "dummy0" with options
            """
            master bond0
            """
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: eth0" is visible with command "cat /proc/net/bonding/bond0"
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth0 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"
    * Reboot
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: eth0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth0 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"


    ################# Test set with VF driver and device ######################################

    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF
    Scenario: nmcli - sriov - drv - add 1 VF
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 1
          autoconnect no
          """
    * Bring "up" connection "sriov_controller"
    * Add "ethernet" connection named "sriov" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          autoconnect no
          """
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Bring "up" connection "sriov"
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep eth0"


    @rhbz1555013 @rhbz1651578
    @ver+=1.14.0
    @sriov_con_drv_add_maxVFs
    Scenario: nmcli - sriov - drv - add 32 VFs
    * Cleanup execute "sleep 15" with timeout "20" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options "sriov.total-vfs 32 autoconnect no"
    * Bring "up" connection "sriov_controller"
    When "32" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "disconnected" is visible with command "nmcli  device |grep eth31" in "120" seconds
    And "disconnected" is visible with command "nmcli  device |grep eth10"
    And "disconnected" is visible with command "nmcli  device |grep eth0"
    * Add "ethernet" connection named "sriov_port2" for device "''" with options
          """
          match.interface-name eth*
          connection.multi-connect multiple
          """
    Then " connected" is visible with command "nmcli  device |grep eth31" in "45" seconds
    And " connected" is visible with command "nmcli  device |grep eth10" in "45" seconds
    And " connected" is visible with command "nmcli  device |grep eth0" in "45" seconds


    @rhbz1651576 @rhbz1659514
    @ver+=1.14.0
    @sriov_con_drv_set_VF_to_0
    Scenario: nmcli - sriov - set VF number to 0
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options "sriov.total-vfs 1 autoconnect no"
    * Modify connection "sriov_controller" changing options "sriov.total-vfs 0"
    * Bring "up" connection "sriov_controller"
    Then "1" is not visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "vf 0" is not visible with command "ip link show dev sriov_device |grep 'vf 0'"
    And "eth0" is not visible with command "nmcli  device" in "10" seconds


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF_mac_and_trust
    Scenario: nmcli - sriov - drv - add 1 VF with mac and trust
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99 trust=true'
          sriov.total-vfs 1
          autoconnect no
          """
    * Bring "up" connection "sriov_controller"
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          autoconnect no
          """
    * Bring "up" connection "sriov"
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep eth0"
    And "00:11:22:33:44:99" is visible with command "ip a s eth0"
    And "trust on" is visible with command " ip l show dev sriov_device"


    @rhbz1555013
    @rhbz1852442
    @ver+=1.14.0
    @sriov_con_drv_add_VF_mtu
    Scenario: nmcli - sriov - drv - add 1 VF with mtu
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99 trust=true'
          sriov.total-vfs 1
          802-3-ethernet.mtu 9000
          autoconnect no
          """
    * Bring "up" connection "sriov_controller"
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          802-3-ethernet.mtu 9000
          autoconnect no
          """
     * Bring "up" connection "sriov"
    Then " connected" is visible with command "nmcli  device |grep eth0"
    And "00:11:22:33:44:99" is visible with command "ip a s eth0"
    And "9000" is visible with command "ip a s eth0" in "10" seconds


    @rhbz1555013
    @ver+=1.14.0
    @tcpdump
    @sriov_con_drv_add_VF_vlan
    Scenario: nmcli - sriov - drv - add 1 VF with vlan Q
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 vlans=100.2.q'
          sriov.total-vfs 1
          autoconnect no
          """
    * Bring "up" connection "sriov_controller"
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          autoconnect no
          """
    * Run child "stdbuf -oL -eL tcpdump -n -i sriov_device -xxvv -e > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    * Bring "up" connection "sriov_port2"
    Then "802.1Q.*vlan 100, p 2" is visible with command "grep 100 /tmp/tcpdump.log" in "20" seconds
    * Execute "pkill tcpdump"


    # Not working under RHEL8 as protocol seems to be unsupported
    # @rhbz1555013
    # @ver+=1.14.0
    # @sriov @tcpdump
    # @sriov_con_drv_add_VF_vlan_ad
    # Scenario: nmcli - sriov - drv - add 1 VF with vlan AD
    # * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
    #    """
    #    sriov.vfs '0 vlans=100.2.ad'
    #    sriov.total-vfs 1
    #    """
    # * Bring "up" connection "sriov_controller"
    # * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
    #    """
    #    ipv4.method manual
    #    ipv4.address 1.2.3.4/24
    #    """
    # * Run child "stdbuf -oL -eL tcpdump -n -i sriov_device -xxvv -e > /tmp/tcpdump.log"
    # When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    # * Bring "up" connection "sriov_port2"
    # Then "802.1AD.*vlan 100, p 2" is visible with command "cat /tmp/tcpdump.log" in "20" seconds
    # * Execute "pkill tcpdump"


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF_trust_on
    Scenario: nmcli - sriov - drv - add 1 VF with trust on
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99 trust=true'
          sriov.total-vfs 1
          """
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    When " connected" is visible with command "nmcli  device |grep eth0"
    * Execute "ip link set dev eth0 address 00:11:22:33:44:55"
    Then "trust on" is visible with command " ip link show sriov_device"
    And "00:11:22:33:44:55" is visible with command "ip a s eth0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF_trust_off
    Scenario: nmcli - sriov - drv - add 1 VF with trust off
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99 trust=false'
          sriov.total-vfs 1
          """
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    When " connected" is visible with command "nmcli  device |grep eth0"
    # It may or may not fail (dependent on ip version and kernel)
    * Execute "ip link set dev eth0 address 00:11:22:33:44:55 || true"
    Then "trust off" is visible with command " ip link show sriov_device"
    And "00:11:22:33:44:55" is not visible with command "ip a s eth0"


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF_spoof_off
    Scenario: nmcli - sriov - drv - add 1 VF without spoof check
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=false'
          sriov.total-vfs 1
          """
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    When " connected" is visible with command "nmcli  device |grep eth0"
    Then "spoof checking off" is visible with command " ip l show dev sriov_device"


    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_add_VF_spoof
    Scenario: nmcli - sriov - drv - add 1 VF with spoof check
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=true'
          sriov.total-vfs 1
          """
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    When " connected" is visible with command "nmcli  device |grep eth0"
    Then "spoof checking on" is visible with command " ip l show dev sriov_device"


    @rhbz1555013
    @ver+=1.14.0
    @firewall
    @sriov_con_drv_add_VF_firewalld
    Scenario: nmcli - sriov - drv - add 1 VF with firewall zone
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 vlans=100.2.q'
          sriov.total-vfs 1
          autoconnect no
          """
    * Bring "up" connection "sriov_controller"
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          connection.zone work
          autoconnect no
          """
    * Bring "up" connection "sriov_port2"
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep eth0"
    Then "work\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"



    @rhbz1555013
    @ver+=1.14.0
    @sriov_con_drv_bond
    Scenario: nmcli - sriov - drv - add 2VFs bond on 2PFs
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 trust=true'
          sriov.total-vfs 1
          """
    When "sriov_device\:ethernet\:connected\:sriov" is visible with command "nmcli -t device" in "15" seconds
    When "eth0" is visible with command "nmcli dev" in "60" seconds
    * Add "bond" connection named "sriov_bond0" for device "bond0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          bond.options 'mode=active-backup,primary=eth0,miimon=100,fail_over_mac=2'
          """
    * Add "ethernet" connection named "sriov_bond0.0" for device "eth0" with options
            """
            master bond0
            """
    * Add "dummy" connection named "sriov_bond0.1" for device "dummy0" with options
            """
            master bond0
            """
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: eth0" is visible with command "cat /proc/net/bonding/bond0"
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth0 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"
    Then "00:11:22:33:44:55" is visible with command "ip a s bond0"
    * Reboot
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: eth0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth0 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth0 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"


    ################# Test set WITHOUT VF driver (just inder PF device) ######################################

    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_add_VF
    Scenario: nmcli - sriov - add 1 VF
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "vf 0" is visible with command "ip link show dev sriov_device |grep 'vf 0'"


    @rhbz1651576
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_set_VF_to_0
    Scenario: nmcli - sriov - set VF number to 0
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    * Modify connection "sriov_controller" changing options "sriov.total-vfs 0"
    * Bring "up" connection "sriov_controller"
    Then "1" is not visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "vf 0" is not visible with command "ip link show dev sriov_device |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_add_VF_mac_and_trust
    Scenario: nmcli - sriov - add 1 VF with mac
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99'
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "00:11:22:33:44:99" is visible with command "ip link show dev sriov_device |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @tcpdump
    @sriov_con_add_VF_vlan
    Scenario: nmcli - sriov - add 1 VF with vlan Q
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Run child "stdbuf -oL -eL tcpdump -n -i sriov_device -xxvv -e > /tmp/tcpdump.log"
    When "cannot|empty" is not visible with command "file /tmp/tcpdump.log" in "20" seconds
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 vlans=100.2.q'
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "vlan 100, qos 2" is visible with command "ip link show sriov_device |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_add_VF_trust_off
    Scenario: nmcli - sriov - add 1 VF with trust off
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 trust=false'
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "trust off" is visible with command "ip link show dev sriov_device |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_add_VF_spoof_off
    Scenario: nmcli - sriov - add 1 VF without spoof check
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=false'
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "spoof checking off" is visible with command "ip link show dev sriov_device |grep 'vf 0'"


    @rhbz1555013
    @ver+=1.14.0 @rhelver+=8
    @sriov_con_add_VF_spoof
    Scenario: nmcli - sriov - add 1 VF with spoof check
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=true'
          sriov.total-vfs 1
          sriov.autoprobe-drivers false
          """
    Then "spoof checking on" is visible with command "ip link show dev sriov_device |grep 'vf 0'"



    ################# Other ######################################


    @rhbz2150831 @rhbz2038050
    @ver+=1.40.2
    @ver+=1.41.6
    @nmstate
    @sriov_nmstate_many_vfs
    Scenario: NM - sriov - enable sriov in config
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    When "Exactly" "0" lines with pattern "^eth" are visible with command "nmcli dev"
    * Cleanup connection "sriov_device"
    * Write file "/tmp/many-vfs.yaml" with content
      """
      interfaces:
      - name: sriov_device
        type: ethernet
        state: up
        ethernet:
          sr-iov:
            total-vfs: 16
      """
    * Execute "nmstatectl apply /tmp/many-vfs.yaml"
    When "Exactly" "16" lines with pattern "^eth" are visible with command "nmcli dev" in "10" seconds
    * Write file "/tmp/many-vfs.yaml" with content
      """
      interfaces:
      - name: sriov_device
        type: ethernet
        state: up
        ethernet:
          sr-iov:
            total-vfs: 32
      """
    * Execute "nmstatectl apply /tmp/many-vfs.yaml"
    Then "Exactly" "32" lines with pattern "^eth" are visible with command "nmcli dev" in "120" seconds


    @rhbz2210164
    @ver+=1.43.11
    @sriov_dont_disable_on_acitvation_fail
    Scenario: NM - sriov - do not deactivate connection on failed SRI-OV parameter apply
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"
    * Cleanup connection "sriov_device"
    * Cleanup connection "bond0" and device "bond0"
    * Cleanup connection "eth0.101"
    * Cleanup execute "nmstatectl rollback || true" with timeout "10" seconds
    * Write file "/tmp/sriov_dont_disable_on_acitvation_fail.yaml" with content
      """
      interfaces:
      - name: sriov_device
        type: ethernet
        state: up
        ethernet:
          sr-iov:
            total-vfs: 2
      """
    * Execute "nmstatectl apply /tmp/sriov_dont_disable_on_acitvation_fail.yaml"
    * Write file "/tmp/sriov_dont_disable_on_acitvation_fail.yaml" with content
      """
      interfaces:
      - name: eth0.101
        type: vlan
        state: up
        vlan:
          base-iface: eth0
          id: 101
      """
    * Execute "nmstatectl apply /tmp/sriov_dont_disable_on_acitvation_fail.yaml"
    * Write file "/tmp/sriov_dont_disable_on_acitvation_fail.yaml" with content
      """
      interfaces:
      - name: bond0
        type: bond
        state: up
        link-aggregation:
          mode: balance-rr
          port:
          - eth0.101
      """
    * Execute "nmstatectl apply /tmp/sriov_dont_disable_on_acitvation_fail.yaml"
    * Write file "/tmp/sriov_dont_disable_on_acitvation_fail.yaml" with content
      """
      interfaces:
      - name: sriov_device
        type: ethernet
        state: up
        ethernet:
         sr-iov:
           total-vfs: 5
           vfs:
           - id: 2
             max-tx-rate: 200
      """
    Then "Destroyed" is visible with command "nmstatectl apply /tmp/sriov_dont_disable_on_acitvation_fail.yaml" in "0" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show eth0.101" in "5" seconds
    Then Check slave "eth0.101" in bond "bond0" in proc


    @RHEL-69125
    @ver+=1.53.91
    @sriov_preserve_on_down
    Scenario: nmcli - sriov - preserve-on-down
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"

    * Commentary
        """
        Test sriov.preserve-on-down=default (no)
        """
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 2
          ipv4.method disabled
          ipv6.method disabled
          """
    * Bring "up" connection "sriov_controller"
    Then "2" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    * Bring "down" connection "sriov_controller"
    Then "0" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"

    * Commentary
        """
        Test sriov.preserve-on-down=yes
        """
    * Modify connection "sriov_controller" changing options "sriov.preserve-on-down yes sriov.total-vfs 3"
    * Bring "up" connection "sriov_controller"
    Then "3" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    * Bring "down" connection "sriov_controller"
    Then "3" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"

    * Commentary
        """
        Test sriov.preserve-on-down=default (global default yes)
        """
    * Create NM config file "90-sriov-preserve-on-down.conf" with content
      """
      [connection-sriov-preserve-on-down]
      match-device=interface-name:sriov_device
      sriov.preserve-on-down=1
      """
    * Execute "nmcli general reload conf"
    * Modify connection "sriov_controller" changing options "sriov.preserve-on-down default sriov.total-vfs 4"
    * Bring "up" connection "sriov_controller"
    Then "4" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    * Bring "down" connection "sriov_controller"
    Then "4" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"

    * Commentary
        """
        Test reapply of sriov.preserve-on-down
        """
    * Modify connection "sriov_controller" changing options "sriov.preserve-on-down no sriov.total-vfs 2"
    * Bring "up" connection "sriov_controller"
    Then "2" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    * Execute "nmcli device modify sriov_device sriov.preserve-on-down yes"
    * Bring "down" connection "sriov_controller"
    Then "2" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"

    * Commentary
        """
        Test sriov.preserve-on-down=no
        """
    * Modify connection "sriov_controller" changing options "sriov.preserve-on-down no sriov.total-vfs 3"
    * Bring "up" connection "sriov_controller"
    Then "3" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    * Bring "down" connection "sriov_controller"
    Then "0" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"


    @RHEL-95884
    @RHEL-113954
    @ver+=1.55.3
    @ver/rhel/9/4+=1.46.0.35
    @sriov_reapply_vf
    Scenario: nmcli - sriov - reapply VF setting
    * Cleanup execute "sleep 8" with timeout "10" seconds and priority "100"

    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
        """
        sriov.total-vfs 5
        sriov.vfs "0 spoof-check=false trust=true vlans=72, 1 spoof-check=false trust=true vlans=73, 2, 3 spoof-check=false trust=true, 4"
        """
    * Commentary
        """
        Modify just VF 4 of sriov-controller by changing spoof-check and trust values
        Reapply.
        """
    When " connected" is visible with command "nmcli  device |grep sriov_device" in "15" seconds
    When "spoof checking off, link-state auto, trust on" is visible with command "ip -d link show sriov_device |grep 'vf 3'"
    * Modify connection "sriov_controller" changing options "sriov.vfs "0 spoof-check=false trust=true vlans=72, 1 spoof-check=false trust=true vlans=73, 2, 3 spoof-check=true trust=false, 4"
    Then "Error.*" is not visible with command "nmcli device reapply sriov_device" in "1" seconds
    When " connected" is visible with command "nmcli  device |grep sriov_device" in "15" seconds
    Then "spoof checking on, link-state auto, trust off" is visible with command "ip -d link show sriov_device |grep 'vf 3'"

