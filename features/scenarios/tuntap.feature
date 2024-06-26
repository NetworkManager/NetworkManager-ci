Feature: nmcli: tuntap

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @ver+=1.4.0
    @add_default_tap_device
    Scenario: nmcli - tuntap - create default tap device
    * Add "tun" connection named "tap0" for device "tap0" with options
          """
          tun.mode 2
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          """
    Then "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is visible with command "ip a s tap0"
     And "fe80::" is visible with command "ip a s tap0"
     And "tap0: tap" is visible with command "ip tuntap"


    @ver+=1.4.0
    @add_default_tun_device
    Scenario: nmcli - tuntap - create default tun device
    * Add "tun" connection named "tap0" for device "tap0" with options
          """
          tun.mode 1
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          ipv6.addr-gen-mode stable-privacy
          """
    Then "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is visible with command "ip a s tap0"
     And "fe80::" is visible with command "ip a s tap0"
     And "tap0: tun" is visible with command "ip tuntap"


    @ver+=1.4.0
    @remove_default_tuntap
    Scenario: nmcli - tuntap - remove default tuntap device
    * Add "tun" connection named "tap0" for device "tap0" with options
          """
          tun.mode 1
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          ipv6.addr-gen-mode stable-privacy
          """
    When "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Delete connection "tap0"
    Then "tap0:connected:tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is not visible with command "ip a s tap0"
     And "fe80::" is not visible with command "ip a s tap0"
     And "tap0: tun" is not visible with command "ip tuntap"
    * Add "tun" connection named "tap0" for device "tap0" with options
          """
          tun.mode 2
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          """
    When "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Delete connection "tap0"
    Then "tap0:connected:tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
     And "1.2.3.4\/24" is not visible with command "ip a s tap0"
     And "fe80::" is not visible with command "ip a s tap0"
     And "tap0: tap" is not visible with command "ip tuntap"


    @rhbz1357738 @rhbz1816202
    @ver+=1.25
    @ver-1.43.6
    @preserve_master_and_ip_settings
    Scenario: NM - tuntap - preserve master and IP settings
    * Cleanup device "tap0"
    * Create "bridge" device named "brY"
    * Execute "ip addr add 192.0.2.1/24 dev brY"
    * Execute "ip tuntap add tap0 mode tap"
    * Execute "ip addr add 192.0.2.2/24 dev tap0"
    * Execute "ip link set tap0 master brY"
    * Execute "ip link set tap0 up"
    * Execute "ip link set brY up"
    When "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    And "tap0:connected \(externally\):tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "ip link set dev tap0 down"
    * Execute "ip link set dev tap0 up"
    * Execute "ip link set dev tap0 down"
    When "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    # This is racy and should be uncommented to show rhbz2178269
    # And "tap0:connected \(externally\):tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "ip link set dev tap0 up"
    Then "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    And "tap0:connected \(externally\):tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1357738 @rhbz1816202 @rhbz2178269
    @ver+=1.43.6
    @preserve_master_and_ip_settings
    Scenario: NM - tuntap - preserve master and IP settings
    * Cleanup device "tap0"
    * Create "bridge" device named "brY"
    * Execute "ip addr add 192.0.2.1/24 dev brY"
    * Execute "ip tuntap add tap0 mode tap"
    * Execute "ip addr add 192.0.2.2/24 dev tap0"
    * Execute "ip link set tap0 master brY"
    * Execute "ip link set tap0 up"
    * Execute "ip link set brY up"
    When "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    And "tap0:connected \(externally\):tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "ip link set dev tap0 down"
    * Execute "ip link set dev tap0 up"
    * Execute "ip link set dev tap0 down"
    When "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    And "tap0:connected \(externally\):tap0" is not visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    * Execute "ip link set dev tap0 up"
    Then "master" is visible with command "ip link show tap0" in "2" seconds
    And "192.0.2.2\/24" is visible with command "ip a s tap0" in "2" seconds
    And "tap0:connected \(externally\):tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds


    @rhbz1547213
    @ver+=1.12.0
    @tuntap_device_kernel_properties
    Scenario: nmcli - tuntap - test tuntap properties from kernel, dbus, nmcli
    * Add "tun" connection named "tap0" for device "tap0" with options
          """
          tun.mode 1
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          """
    When "tap0:connected:tap0" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "10" seconds
    Then Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 owner"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 group"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 mode tun"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 multi-queue"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 vnet-hdr"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 nopi"
    * Modify connection "tap0" changing options "tun.mode 2 tun.pi yes tun.vnet-hdr yes tun.multi-queue no tun.owner 1000 tun.group 1002"
    * Bring "down" connection "tap0"
    * Bring "up" connection "tap0"
    Then Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 owner 1000"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 group 1002"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 mode tap"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 multi-queue false"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 vnet-hdr true"
     And Execute "bash contrib/tuntap/tuntap_device_kernel_properties.sh tap0 nopi false"
