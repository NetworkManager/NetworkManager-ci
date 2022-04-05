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
    * Add "vrf" connection named "vrf0" for device "vrf0" with options "table 1001 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options "master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add "vrf" connection named "vrf1" for device "vrf1" with options "table 1002 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options "master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
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
    * Add "vrf" connection named "vrf0" for device "vrf0" with options "autoconnect no table 1001 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options "autoconnect no master vrf0 ipv4.method manual ipv4.address '192.0.2.1/24,192.0.2.2/24' ipv6.method manual ipv6.addresses '1:2:3:4:5::1/64,1:2:3:4:5::2/64'"
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
    * Add "vrf" connection named "vrf0" for device "vrf0" with options "table 1001 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options "master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add "vrf" connection named "vrf1" for device "vrf1" with options "table 1002 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options "master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
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
    * Add "vrf" connection named "vrf0" for device "vrf0" with options "table 1001 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options "master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add "vrf" connection named "vrf1" for device "vrf1" with options "table 1002 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options "master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
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
    * Add "vrf" connection named "vrf0" for device "vrf0" with options "table 1001 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth1" for device "eth1" with options "master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add "vrf" connection named "vrf1" for device "vrf1" with options "table 1002 ipv4.method disabled ipv6.method disabled"
    * Add "ethernet" connection named "vrf.eth4" for device "eth4" with options "master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
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


    #@rhbz1773908
    #@ver+=1.25 @rhelver+=8
    #@con_vrf_remove
    #@vrf_external
    #Scenario: nmcli - vrf - external setup
    #* Execute "ip link add dev vrf0 type vrf table 1001"
    #* Execute "ip link set dev vrf0 up"
    #* Execute "ip link set dev eth1 master vrf0"
    #* Execute "ip link set dev eth1 up"
    #* Execute "ip addr add dev eth1 192.0.2.1/24"

    #* Execute "ip link add dev vrf1 type vrf table 1002"
    #* Execute "ip link set dev vrf1 up"
    #* Execute "ip link set dev eth4 master vrf1"
    #* Execute "ip link set dev eth4 up"
    #* Execute "ip addr add dev eth4 192.0.2.1/24"

    #When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "25" seconds
    #When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    #When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    #When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    #When "eth1|eth4" is not visible with command "ip r"

    #When "192.0.2.1" is visible with command "ip a s eth1"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # #When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    #When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    #When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    #When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    #When "192.0.2.1" is visible with command "ip a s eth4"
    # Obsolete by https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=94c821c74bf5fe0c25e09df5334a16f98608db90
    # #When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    #When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    #When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    #When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
