Feature: nmcli: sriov_netdevsim

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhbz1555013 @rhbz1651578
    @ver+=1.14.0
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_add_maxVFs
    Scenario: nmcli - sriov_hwsim - drv - add 4 VFs
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 4
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    * Bring "up" connection "sriov_controller"
    When "4" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "disconnected" is visible with command "nmcli  device |grep eth14" in "120" seconds
    And "disconnected" is visible with command "nmcli  device |grep eth12"
    And "disconnected" is visible with command "nmcli  device |grep eth11"
    * Add "ethernet" connection named "sriov_port2" for device "''" with options
          """
          match.interface-name eth*
          connection.multi-connect multiple
          """
    Then " connected" is visible with command "nmcli  device |grep eth14" in "45" seconds
    And " connected" is visible with command "nmcli  device |grep eth12" in "45" seconds
    And " connected" is visible with command "nmcli  device |grep eth11" in "45" seconds


    @rhbz1651576 @rhbz1659514
    @ver+=1.14.0
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_set_VF_to_0
    Scenario: nmcli - sriov_hwsim - set VF number to 0
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.total-vfs 4
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    * Modify connection "sriov_controller" changing options "sriov.total-vfs 0"
    * Bring "up" connection "sriov_controller"
    Then "4" is not visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And "vf 0" is not visible with command "ip link show dev sriov_device |grep 'vf 0'"
    And "eth11" is not visible with command "nmcli  device" in "10" seconds


    @rhbz1555013
    @ver+=1.14.0
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_bond
    Scenario: nmcli - sriov_hwsim - drv - add 2VFs bond on 2PFs
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 trust=true'
          sriov.total-vfs 1
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    When "sriov_device\:ethernet\:connected\:sriov" is visible with command "nmcli -t device" in "15" seconds
    When "eth11" is visible with command "nmcli dev" in "60" seconds
    * Add "bond" connection named "sriov_bond0" for device "bond0" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          bond.options 'mode=active-backup,primary=eth11,miimon=100,fail_over_mac=2'
          """
    * Add "ethernet" connection named "sriov_bond0.0" for device "eth11" with options
            """
            master bond0
            """
    * Add "dummy" connection named "sriov_bond0.1" for device "dummy0" with options
            """
            master bond0
            """
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth11 \(primary_reselect always\)\s+Currently Active Slave: eth11" is visible with command "cat /proc/net/bonding/bond0"
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth11 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth11 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"
    Then "00:11:22:33:44:55" is visible with command "ip a s bond0"
    * Reboot
    When "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth11 \(primary_reselect always\)\s+Currently Active Slave: eth11" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    When Check bond "bond0" link state is "up"
    * Execute "ip link set dev eth11 down"
    Then "Bonding Mode: fault-tolerance \(active-backup\) \(fail_over_mac follow\)\s+Primary Slave: eth11 \(primary_reselect always\)\s+Currently Active Slave: dummy0" is visible with command "cat /proc/net/bonding/bond0" in "20" seconds
    Then Check bond "bond0" link state is "up"


    @rhbz1555013
    @ver+=1.14.0
    @firewall
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_add_VF_firewalld
    Scenario: nmcli - sriov_hwsim - drv - add 1 VF with firewall zone
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 vlans=100.2.q'
          sriov.total-vfs 1
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    * Bring "up" connection "sriov_controller"
    When "eth11" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          connection.zone work
          autoconnect no
          """
    * Bring "up" connection "sriov_port2"
    Then "1" is visible with command "cat /sys/class/net/sriov_device/device/sriov_numvfs"
    And " connected" is visible with command "nmcli  device |grep eth11"
    Then "work\s+interfaces: eth0" is visible with command "firewall-cmd --get-active-zones"


    @rhbz1555013
    @ver+=1.14.0
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_add_VF_spoof
    Scenario: nmcli - sriov_hwsim - drv - add 1 VF with spoof check
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:55 spoof-check=true'
          sriov.total-vfs 1
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    When "eth11" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          """
    When " connected" is visible with command "nmcli  device |grep eth11"
    Then "spoof checking on" is visible with command " ip l show dev sriov_device"


    @rhbz1555013
    @ver+=1.14.0
    @tcpdump
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_add_VF_vlan
    Scenario: nmcli - sriov_hwsim - drv - add 1 VF with vlan Q
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 vlans=100.2.q'
          sriov.total-vfs 1
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    * Bring "up" connection "sriov_controller"
    When "eth11" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov_port2" for device "eth11" with options
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


    @rhbz1555013
    @rhbz1852442
    @ver+=1.14.0
    @sriov_netdevsim_setup
    @sriov_hwsim_con_drv_add_VF_mtu
    Scenario: nmcli - sriov_hwsim - drv - add 1 VF with mtu
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
          """
          sriov.vfs '0 mac=00:11:22:33:44:99 trust=true'
          sriov.total-vfs 1
          802-3-ethernet.mtu 9000
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.99.1/24
          """
    * Bring "up" connection "sriov_controller"
    When "eth11" is visible with command "nmcli dev" in "60" seconds
    * Add "ethernet" connection named "sriov" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.address 1.2.3.4/24
          802-3-ethernet.mtu 9000
          autoconnect no
          """
     * Bring "up" connection "sriov"
    Then " connected" is visible with command "nmcli  device |grep eth11"
    And "00:11:22:33:44:99" is visible with command "ip a s eth11"
    And "9000" is visible with command "ip a s eth11" in "10" seconds


    @RHEL-69125
    @ver+=1.53.91
    @sriov_netdevsim_setup
    @sriov_hwsim_preserve_on_down
    Scenario: nmcli - sriov_hwsim - preserve-on-down
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


    @rhbz2210164
    @ver+=1.43.11
    @sriov_netdevsim_setup
    @sriov_hwsim_dont_disable_on_acitvation_fail
    Scenario: NM - sriov_hwsim - do not deactivate connection on failed SRI-OV parameter apply
    * Cleanup connection "sriov_device"
    * Cleanup connection "bond0" and device "bond0"
    * Cleanup connection "eth11.101"
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
      - name: eth11.101
        type: vlan
        state: up
        vlan:
          base-iface: eth11
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
          - eth11.101
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
           total-vfs: 4
           vfs:
           - id: 2
             max-tx-rate: 200
      """
    Then "Destroyed" is visible with command "nmstatectl apply /tmp/sriov_dont_disable_on_acitvation_fail.yaml" in "0" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show eth11.101" in "5" seconds
    Then Check slave "eth11.101" in bond "bond0" in proc


    @RHEL-95884
    @ver+=1.55.3
    @sriov_netdevsim_setup
    @sriov_hwsim_reapply_vf
    Scenario: nmcli - sriov_hwsim - reapply VF setting
    * Add "ethernet" connection named "sriov_controller" for device "sriov_device" with options
        """
        sriov.total-vfs 4
        sriov.vfs "0 spoof-check=false trust=true vlans=72, 1 spoof-check=false trust=true vlans=73, 3 spoof-check=false trust=true"
        ipv4.method manual
        ipv4.addresses 192.168.99.1/24
        """
    * Commentary
        """
        Modify just VF 3 of sriov-controller by changing spoof-check and trust values
        Reapply.
        """
    When " connected" is visible with command "nmcli  device |grep sriov_device"
    When "spoof checking off, link-state auto, trust on" is visible with command "ip -d link show sriov_device |grep 'vf 3'"
    * Modify connection "sriov_controller" changing options "sriov.vfs" "0 spoof-check=false trust=true vlans=72, 1 spoof-check=false trust=true vlans=73, 3 spoof-check=true trust=false"
    Then "Error.*" is not visible with command "nmcli device reapply sriov_device" in "1" seconds
    Then "spoof checking on, link-state auto, trust off" is visible with command "ip -d link show sriov_device |grep 'vf 3'"