 Feature: nmcli: sriov

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

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
    @sriov @eth @con
    @sriov_connect
    Scenario: NM - sriov - connect virtual sriov device
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name ethie autoconnect no ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name connie autoconnect no ipv4.method manual ipv4.address 1.2.3.5/24"
    * Bring "up" connection "ethie"
    * Bring "up" connection "connie"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ethie" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show connie" in "5" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov @eth @con
    @sriov_autoconnect
    Scenario: NM - sriov - autoconnect virtual sriov device
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name ethie ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name connie ipv4.method manual ipv4.address 1.2.3.5/24"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ethie" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show connie" in "5" seconds


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
    # * Add a new connection of type "ethernet" and options "ifname enp5s16f1 con-name ethie ipv4.method manual ipv4.address 1.2.3.4/24 802-3-ethernet.mtu 9000"
    # Then "9000" is visible with command "ip a s enp5s16f1" in "2" seconds


    @rhbz1398934
    @ver+=1.8.0
    @sriov @eth @con
    @sriov_reboot_persistence
    Scenario: NM - sriov - reboot persistence
    When "1" is visible with command "nmcli dev |grep em1  |wc -l"
    When "1" is visible with command "nmcli dev |grep em2  |wc -l"
    * Prepare "99-sriov.conf" config for "em2" device with "2" VFs
    * Add a new connection of type "ethernet" and options "ifname em2_0 con-name ethie ipv4.method manual ipv4.address 1.2.3.4/24"
    * Add a new connection of type "ethernet" and options "ifname em2 con-name connie ipv4.method manual ipv4.address 1.2.3.5/24"
    * Bring "down" connection "ethie"
    * Bring "down" connection "connie"
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show ethie" in "5" seconds
     And "activated" is visible with command "nmcli -g GENERAL.STATE con show connie" in "5" seconds
