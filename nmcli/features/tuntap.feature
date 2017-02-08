Feature: nmcli: tuntap

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+/-=1.4.1)
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @tuntap
    @add_default_tap_device
    Scenario: nmcli - tuntap - create default tap device
    * Add a new connection of type "tun" and options "ifname tap0 con-name tap0 tun.mode 2 ipv4.addresses 1.2.3.4/24 ipv4.method manual"
    Then "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is visible with command "ip a s tap0"
     And "fe80::" is visible with command "ip a s tap0"
     And "tap0: tap" is visible with command "ip tuntap"


    @tuntap
    @add_default_tun_device
    Scenario: nmcli - tuntap - create default tun device
    * Add a new connection of type "tun" and options "ifname tap0 con-name tap0 tun.mode 1 ipv4.addresses 1.2.3.4/24 ipv4.method manual"
    Then "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is visible with command "ip a s tap0"
     And "fe80::" is visible with command "ip a s tap0"
     And "tap0: tun" is visible with command "ip tuntap"


    @tuntap
    @remove_default_tuntap
    Scenario: nmcli - tuntap - remove default tuntap device
    * Add a new connection of type "tun" and options "ifname tap0 con-name tap0 tun.mode 1 ipv4.addresses 1.2.3.4/24 ipv4.method manual"
    When "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Delete connection "tap0"
    Then "tap0:connected:tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is not visible with command "ip a s tap0"
     And "fe80::" is not visible with command "ip a s tap0"
     And "tap0: tun" is not visible with command "ip tuntap"
    * Add a new connection of type "tun" and options "ifname tap0 con-name tap0 tun.mode 2 ipv4.addresses 1.2.3.4/24 ipv4.method manual"
    When "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Delete connection "tap0"
    Then "tap0:connected:tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is not visible with command "ip a s tap0"
     And "fe80::" is not visible with command "ip a s tap0"
     And "tap0: tap" is not visible with command "ip tuntap"


    @rhbz1357738
    @ver+=1.4.0
    @tuntap
    @preserve_master_and_ip_settings
    Scenario: NM - tuntap - preserve master and IP settings
     * Execute "ip link add br0 type bridge"
     * Execute "ip addr add 192.0.2.1/24 dev br0"
     * Execute "ip tuntap add tap0 mode tap"
     * Execute "ip addr add 192.0.2.2/24 dev tap0"
     * Execute "ip link set tap0 master br0"
     * Execute "ip link set tap0 up"
     * Execute "ip link set br0 up"
     When "master" is visible with command "ip link show tap0" in "2" seconds
      And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
      And "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     * Execute "ip link set dev tap0 down"
     * Execute "ip link set dev tap0 up"
     * Execute "ip link set dev tap0 down"
     When "master" is visible with command "ip link show tap0" in "2" seconds
      And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
      And "tap0:connected:tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
