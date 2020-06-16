 Feature: nmcli: vrf

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz1773908
    @ver+=1.25
    @con_vrf_remove
    @vrf_one_address_two_devices
    Scenario: nmcli - vrf - reusing ip address on multiple devices
    * Add a new connection of type "vrf" and options "ifname vrf0 con-name vrf0 table 1001 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth1 ifname eth1 master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add a new connection of type "vrf" and options "ifname vrf1 con-name vrf1 table 1002 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth4 ifname eth4 master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    When "eth1|eth4" is not visible with command "ip r"

    When "192.0.2.1" is visible with command "ip a s eth1"
    When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    # VVV Reproducer for 1773908
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    When "192.0.2.1" is visible with command "ip a s eth4"
    When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25
    @con_vrf_remove
    @vrf_bring_down_connections
    Scenario: nmcli - vrf - bring down vrf setup
    * Add a new connection of type "vrf" and options "ifname vrf0 con-name vrf0 table 1001 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth1 ifname eth1 master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add a new connection of type "vrf" and options "ifname vrf1 con-name vrf1 table 1002 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth4 ifname eth4 master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"
    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    * Bring "down" connection "vrf.eth1"
    * Bring "down" connection "vrf.eth4"

    When "192.0.2.1" is not visible with command "ip a s eth1"
    When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"

    When "192.0.2.1" is not visible with command "ip a s eth4"
    When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25
    @con_vrf_remove
    @vrf_delete_connections
    Scenario: nmcli - vrf - delete ethernet profiles
    * Add a new connection of type "vrf" and options "ifname vrf0 con-name vrf0 table 1001 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth1 ifname eth1 master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add a new connection of type "vrf" and options "ifname vrf1 con-name vrf1 table 1002 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth4 ifname eth4 master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"
    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "5" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    * Delete connection "vrf.eth1"
    * Delete connection "vrf.eth4"

    When "192.0.2.1" is not visible with command "ip a s eth1"
    When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1001"

    When "192.0.2.1" is not visible with command "ip a s eth4"
    When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is not visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is not visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is not visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25
    @con_vrf_remove
    @vrf_restart_persistence
    Scenario: nmcli - vrf - restart persistence
    * Add a new connection of type "vrf" and options "ifname vrf0 con-name vrf0 table 1001 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth1 ifname eth1 master vrf0 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Add a new connection of type "vrf" and options "ifname vrf1 con-name vrf1 table 1002 ipv4.method disabled ipv6.method disabled"
    * Add a new connection of type "ethernet" and options "con-name vrf.eth4 ifname eth4 master vrf1 ipv4.method manual ipv4.address 192.0.2.1/24"
    * Bring "up" connection "vrf.eth1"
    * Bring "up" connection "vrf.eth4"

    * Reboot

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "25" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    When "eth1|eth4" is not visible with command "ip r"

    When "192.0.2.1" is visible with command "ip a s eth1"
    When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    When "192.0.2.1" is visible with command "ip a s eth4"
    When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"


    @rhbz1773908
    @ver+=1.25
    @con_vrf_remove
    @vrf_external
    Scenario: nmcli - vrf - external setup
    * Execute "ip link add dev vrf0 type vrf table 1001"
    * Execute "ip link set dev vrf0 up"
    * Execute "ip link set dev eth1 master vrf0"
    * Execute "ip link set dev eth1 up"
    * Execute "ip addr add dev eth1 192.0.2.1/24"

    * Execute "ip link add dev vrf1 type vrf table 1002"
    * Execute "ip link set dev vrf1 up"
    * Execute "ip link set dev eth4 master vrf1"
    * Execute "ip link set dev eth4 up"
    * Execute "ip addr add dev eth4 192.0.2.1/24"

    When "eth1\:ethernet\:connected\:vrf.eth1" is visible with command "nmcli -t device" in "25" seconds
    When "eth4\:ethernet\:connected\:vrf.eth4" is visible with command "nmcli -t device"
    When "vrf0\:vrf\:connected\:vrf0" is visible with command "nmcli -t device"
    When "vrf1\:vrf\:connected\:vrf1" is visible with command "nmcli -t device"

    When "eth1|eth4" is not visible with command "ip r"

    When "192.0.2.1" is visible with command "ip a s eth1"
    When "broadcast 192.0.2.0 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"
    When "192.0.2.0\/24 dev eth1 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1001"
    When "local 192.0.2.1 dev eth1 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1001"
    When "broadcast 192.0.2.255 dev eth1 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1001"

    When "192.0.2.1" is visible with command "ip a s eth4"
    When "broadcast 192.0.2.0 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
    When "192.0.2.0\/24 dev eth4 proto kernel scope link src 192.0.2.1 metric 1" is visible with command "ip r show table 1002"
    When "local 192.0.2.1 dev eth4 proto kernel scope host src 192.0.2.1" is visible with command "ip r show table 1002"
    When "broadcast 192.0.2.255 dev eth4 proto kernel scope link src 192.0.2.1" is visible with command "ip r show table 1002"
