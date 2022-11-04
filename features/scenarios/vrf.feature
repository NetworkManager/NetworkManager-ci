Feature: nmcli: vrf

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz1773908
    @ver+=1.25 @rhelver+=8
    @vrf_one_address_two_devices
    Scenario: nmcli - vrf - reusing ip address on multiple devices
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          table 1001
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Add "vrf" connection named "vrf1" for device "vrf1" with options
          """
          table 1002
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options
          """
          master vrf1
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    When "eth1|eth4" is not visible with command "ip r"

    When "192.0.2.1" is visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    # VVV Reproducer for 1773908
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    When "192.0.2.1" is visible with command "ip a s eth4"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"


    @rhbz1907661
    @ver+=1.31
    @ver+=1.30.3
    @rhelver+=8
    @vrf_check_local_routes
    Scenario: nmcli - vrf - reusing ip address on multiple devices
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          autoconnect no
          table 1001
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options
          """
          autoconnect no
          master vrf0
          ipv4.method manual
          ipv4.address '192.0.2.1/24,192.0.2.2/24'
          ipv6.method manual
          ipv6.addresses '1:2:3:4:5::1/64,1:2:3:4:5::2/64'
          """
    * Bring "up" connection "vrf.eth1"

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "eth1" is not visible with command "ip r"
    When "192.0.2.1" is visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "local 192.0.2.2 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    When "local 1:2:3:4:5::1 dev eth1 table 1001 proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth1 table 1001 proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"

    * Execute "nmcli device modify eth1 ipv4.address 192.0.2.2/24"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth1 table 1001 proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "local 1:2:3:4:5::1 dev eth1 table 1001 proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth1 table 1001 proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"

    * Execute "nmcli device modify eth1 ipv6.address 1:2:3:4:5::2/64"
    When "192.0.2.1" is not visible with command "ip route show table all"
    When "local 192.0.2.2 dev eth1 table 1001 proto kernel scope host src 192.0.2.2" is visible with command "ip route show table all"
    When "1:2:3:4:5::1" is not visible with command "ip -6 route show table all"
    When "local 1:2:3:4:5::2 dev eth1 table 1001 proto kernel metric 0 pref medium" is visible with command "ip -6 route show table all"


    @rhbz1773908
    @ver+=1.25 @rhelver+=8
    @vrf_bring_down_connections
    Scenario: nmcli - vrf - bring down vrf setup
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          table 1001
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Add "vrf" connection named "vrf1" for device "vrf1" with options
          """
          table 1002
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options
          """
          master vrf1
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"
    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    * Bring "down" connection "vrf.eth1"
    * Bring "down" connection "vrf.eth4"

    When "192.0.2.1" is not visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"

    When "192.0.2.1" is not visible with command "ip a s eth4"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25 @rhelver+=8
    @vrf_delete_connections
    Scenario: nmcli - vrf - delete ethernet profiles
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          table 1001
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Add "vrf" connection named "vrf1" for device "vrf1" with options
          """
          table 1002
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options
          """
          master vrf1
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"
    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    * Delete connection "vrf.eth1"
    * Delete connection "vrf.eth4"

    When "192.0.2.1" is not visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"

    When "192.0.2.1" is not visible with command "ip a s eth4"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25 @rhelver+=8
    @vrf_restart_persistence
    Scenario: nmcli - vrf - restart persistence
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          table 1001
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Add "vrf" connection named "vrf1" for device "vrf1" with options
          """
          table 1002
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options
          """
          master vrf1
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"

    * Reboot

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "25" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    When "eth1|eth4" is not visible with command "ip r"

    When "192.0.2.1" is visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    When "192.0.2.1" is visible with command "ip a s eth4"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"



    @rhbz2094878
    @ver+=1.41.3 @rhelver+=8
    @vrf_various_ports
    Scenario: nmcli - vrf - restart persistence
    * Add "vrf" connection named "vrf0" for device "vrf0" with options
          """
          table 1001
          ipv4.method manual
          ipv4.addresses 5.5.5.1/24
          ipv6.method manual
          ipv6.addresses 5::1/64
          """
    * Add "bond" connection named "vrf0.bond0" for device "nm-bond" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 1.1.1.1/24
          ipv6.method manual
          ipv6.address 1::1/64
          """
    * Add "bridge" connection named "vrf0.br0" for device "nm-bridge" with options
          """
          master vrf0
          ipv4.method manual
          ipv4.address 3.3.3.1/24
          ipv6.method manual
          ipv6.address 3::1/64
          """
    * Add "vlan" connection named "vrf0.vlan0" with options
          """
          master vrf0
          dev nm-bond
          id 4000
          ipv4.method manual
          ipv4.address 4.4.4.1/24
          ipv6.method manual
          ipv6.address 4::1/64
          """
    * Add "ethernet" connection named "vrf0.bond0.eth4" for device "eth4" with options
          """
          master nm-bond
          """
    * Add "ethernet" connection named "vrf0.br0.eth5" for device "eth5" with options
          """
          master nm-bridge
          """
    * Bring "up" connection "vrf0"
    * Bring "up" connection "vrf0.bond0"
    * Bring "up" connection "vrf0.br0"
    * Bring "up" connection "vrf0.vlan0"
    * Bring "up" connection "vrf0.br0.eth5"
    * Bring "up" connection "vrf0.bond0.eth4"
    # These commented lines are not the same under CentOS so commented out, these are set by the kernel anyway.
    # When "broadcast 1.1.1.0 dev nm-bond proto kernel scope link src 1.1.1.1" is visible with command "ip r show table 1001"
    When "1.1.1.0/24 dev nm-bond proto kernel scope link src 1.1.1.1 metric 300" is visible with command "ip r show table 1001"
    When "local 1.1.1.1 dev nm-bond proto kernel scope host src 1.1.1.1" is visible with command "ip r show table 1001"
    When "broadcast 1.1.1.255 dev nm-bond proto kernel scope link src 1.1.1.1" is visible with command "ip r show table 1001"
    # When "broadcast 3.3.3.0 dev nm-bridge proto kernel scope link src 3.3.3.1" is visible with command "ip r show table 1001"
    When "3.3.3.0/24 dev nm-bridge proto kernel scope link src 3.3.3.1 metric 425" is visible with command "ip r show table 1001"
    When "local 3.3.3.1 dev nm-bridge proto kernel scope host src 3.3.3.1" is visible with command "ip r show table 1001"
    When "broadcast 3.3.3.255 dev nm-bridge proto kernel scope link src 3.3.3.1" is visible with command "ip r show table 1001"
    # When "broadcast 4.4.4.0 dev nm-bond.4000 proto kernel scope link src 4.4.4.1" is visible with command "ip r show table 1001"
    When "4.4.4.0/24 dev nm-bond.4000 proto kernel scope link src 4.4.4.1 metric 400" is visible with command "ip r show table 1001"
    When "local 4.4.4.1 dev nm-bond.4000 proto kernel scope host src 4.4.4.1" is visible with command "ip r show table 1001"
    When "broadcast 4.4.4.255 dev nm-bond.4000 proto kernel scope link src 4.4.4.1" is visible with command "ip r show table 1001"
    # When "broadcast 5.5.5.0 dev vrf0 proto kernel scope link src 5.5.5.1" is visible with command "ip r show table 1001"
    When "5.5.5.0/24 dev vrf0 proto kernel scope link src 5.5.5.1 metric 470" is visible with command "ip r show table 1001"
    When "local 5.5.5.1 dev vrf0 proto kernel scope host src 5.5.5.1" is visible with command "ip r show table 1001"
    When "broadcast 5.5.5.255 dev vrf0 proto kernel scope link src 5.5.5.1" is visible with command "ip r show table 1001"
    * Reboot
    # Then "broadcast 1.1.1.0 dev nm-bond proto kernel scope link src 1.1.1.1" is visible with command "ip r show table 1001"
    Then "1.1.1.0/24 dev nm-bond proto kernel scope link src 1.1.1.1 metric 300" is visible with command "ip r show table 1001" in "5" seconds
    Then "local 1.1.1.1 dev nm-bond proto kernel scope host src 1.1.1.1" is visible with command "ip r show table 1001" in "5" seconds
    Then "broadcast 1.1.1.255 dev nm-bond proto kernel scope link src 1.1.1.1" is visible with command "ip r show table 1001" in "5" seconds
    # Then "broadcast 3.3.3.0 dev nm-bridge proto kernel scope link src 3.3.3.1" is visible with command "ip r show table 1001"
    Then "3.3.3.0/24 dev nm-bridge proto kernel scope link src 3.3.3.1 metric 425" is visible with command "ip r show table 1001" in "5" seconds
    Then "local 3.3.3.1 dev nm-bridge proto kernel scope host src 3.3.3.1" is visible with command "ip r show table 1001" in "5" seconds
    Then "broadcast 3.3.3.255 dev nm-bridge proto kernel scope link src 3.3.3.1" is visible with command "ip r show table 1001" in "5" seconds
    # Then "broadcast 4.4.4.0 dev nm-bond.4000 proto kernel scope link src 4.4.4.1" is visible with command "ip r show table 1001"
    Then "4.4.4.0/24 dev nm-bond.4000 proto kernel scope link src 4.4.4.1 metric 400" is visible with command "ip r show table 1001" in "5" seconds
    Then "local 4.4.4.1 dev nm-bond.4000 proto kernel scope host src 4.4.4.1" is visible with command "ip r show table 1001" in "5" seconds
    Then "broadcast 4.4.4.255 dev nm-bond.4000 proto kernel scope link src 4.4.4.1" is visible with command "ip r show table 1001" in "5" seconds
    # Then "broadcast 5.5.5.0 dev vrf0 proto kernel scope link src 5.5.5.1" is visible with command "ip r show table 1001"
    Then "5.5.5.0/24 dev vrf0 proto kernel scope link src 5.5.5.1 metric 470" is visible with command "ip r show table 1001" in "5" seconds
    Then "local 5.5.5.1 dev vrf0 proto kernel scope host src 5.5.5.1" is visible with command "ip r show table 1001" in "5" seconds
    Then "broadcast 5.5.5.255 dev vrf0 proto kernel scope link src 5.5.5.1" is visible with command "ip r show table 1001" in "5" seconds
