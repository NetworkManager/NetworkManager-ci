@testplan
Feature: nmcli - general

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @general
    @logging
    Scenario: NM - general - setting log level and autocompletion
    Then "DEBUG\s+ERR\s+INFO\s+.*TRACE\s+WARN" is visible with tab after "sudo nmcli general logging level "
    * Set logging for "all" to "INFO"
    Then "INFO\s+[^:]*$" is visible with command "nmcli general logging"
    * Set logging for "default,WIFI:ERR" to " "
    Then "INFO\s+[^:]*,WIFI:ERR,[^:]*$" is visible with command "nmcli general logging"


    @rhbz1212196
    @bond @reduce_logging
    Scenario: NM - general - reduce logging
     * Add connection type "bond" named "bond0" for device "nm-bond"
    Then "preparing" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago'   |grep '<info> .*nm-bond' |grep 'preparing device'"
    Then "exported as" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago' |grep '<info> .*nm-bond' |grep 'exported as'"
    Then "Stage" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago'       |grep '<info> .*nm-bond' |grep 'Stage'"


    @rhbz1362542
    @ver+=1.4.0
    @insufficient_logging_perms
    Scenario: NM - general - not enough logging perms
    Then "Error: failed to set logging: access denied" is visible with command "sudo -u test nmcli general logging level TRACE domains all"


    @general
    @general_check_version
    Scenario: nmcli - general - check version
    * Note the output of "rpm -q --queryformat '%{VERSION}' NetworkManager" as value "1"
    * Note the output of "nmcli -t -f VERSION general" as value "2"
    Then Check noted values "1" and "2" are the same


    @general @remove_fedora_connection_checker
    @general_state_connected
    Scenario: nmcli - general - state connected
    * Note the output of "nmcli -t -f STATE general" as value "1"
    * Note the output of "echo connected" as value "2"
    Then Check noted values "1" and "2" are the same


    @general @restore_hostname
    @hostname_change
    Scenario: nmcli - general - set hostname
    * Execute "sudo nmcli general hostname walderon"
    Then "walderon" is visible with command "cat /etc/hostname"


    @ver+=1.4.0
    @general @eth @teardown_testveth @eth0 @restore_hostname
    @pull_hostname_from_dhcp
    Scenario: nmcli - general - pull hostname from DHCP
    * Prepare simulated test "testX" device
    * Execute "sudo nmcli general hostname localhost"
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie autoconnect no"
    When "localhost" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "ethie"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @general @eth @teardown_testveth @restart @delete_testeth0 @restore_hostname
    @hostname_mode_full
    Scenario: NM - general - hostname mode full
    * Execute "echo -e '[main]\nhostname-mode=full' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testX" device
    * Execute "sudo nmcli general hostname localhost"
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie autoconnect no"
    When "localhost" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "ethie"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @general @eth @teardown_testveth @restart @delete_testeth0 @restore_hostname
    @hostname_mode_dhcp
    Scenario: NM - general - hostname mode dhcp
    * Execute "echo -e '[main]\nhostname-mode=dhcp' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testX" device
    * Execute "sudo nmcli general hostname localhost"
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie autoconnect no"
    When "localhost" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "ethie"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @general @eth @teardown_testveth @restart @delete_testeth0 @restore_hostname
    @hostname_mode_full_without_dhcp_hosts
    Scenario: NM - general - hostname mode dhcp without dhcp hosts
    * Execute "echo -e '[main]\nhostname-mode=dhcp' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Execute "echo no-hosts > /etc/dnsmasq.d/dnsmasq_custom.conf"
    * Restart NM
    * Prepare simulated test "testX" device
    * Execute "sudo nmcli general hostname localhost"
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie autoconnect no"
    When "localhost" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "ethie"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost" is visible with command "hostnamectl --transient" in "60" seconds
     And "localhost" is visible with command "hostnamectl --transient" for full "20" seconds


    @rhbz1405275
    @ver+=1.8.0
    @general @eth @teardown_testveth @restart @delete_testeth0 @restore_hostname
    @hostname_mode_none
    Scenario: NM - general - hostname mode none
    * Execute "echo -e '[main]\nhostname-mode=none' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testX" device
    * Execute "sudo nmcli general hostname localhost"
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie autoconnect no"
    When "localhost" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "ethie"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost" is visible with command "hostnamectl --transient" in "60" seconds
     And "localhost" is visible with command "hostnamectl --transient" for full "20" seconds


    @general @restart @veth
    @general_state_disconnected
    Scenario: nmcli - general - state disconnected
    * "disconnect" all " connected" devices
    * Note the output of "nmcli -t -f STATE general" as value "1"
    * Note the output of "echo disconnected" as value "2"
    Then Check noted values "1" and "2" are the same
    * Bring up connection "testeth0"


    @general @veth
    @general_state_asleep
    Scenario: nmcli - general - state asleep
    * Execute "nmcli networking off"
    * Note the output of "nmcli -t -f STATE general" as value "1"
    * Note the output of "echo asleep" as value "2"
    Then Check noted values "1" and "2" are the same
    Then Execute "nmcli networking on"


    @general
    @general_state_running
    Scenario: nmcli - general - running
    * Note the output of "nmcli -t -f RUNNING general" as value "1"
    * Note the output of "echo running" as value "2"
    Then Check noted values "1" and "2" are the same


    @general @veth @restart
    @general_state_not_running
    Scenario: nmcli - general - not running
    * Stop NM
    * Wait for at least "2" seconds
    Then "NetworkManager is not running" is visible with command "nmcli general"


    @rhbz1311988
    @restart @add_testeth1 @shutdown @eth1_disconnect
    @shutdown_service_assumed
    Scenario: NM - general - shutdown service - assumed
    * Delete connection "testeth1"
    * Stop NM
    * Execute "ip addr add 192.168.50.5/24 dev eth1"
    * Execute "route add default gw 192.168.50.1 metric 200 dev eth1"
    * "default via 192.168.50.1 dev eth1\s+metric 200" is visible with command "ip r"
    * "inet 192.168.50.5" is visible with command "ip a s eth1" in "5" seconds
    * Start NM
    * "default via 192.168.50.1 dev eth1\s+metric 200" is visible with command "ip r"
    * "inet 192.168.50.5" is visible with command "ip a s eth1" in "5" seconds
    * Stop NM
    Then "default via 192.168.50.1 dev eth1\s+metric 200" is visible with command "ip r" for full "5" seconds
     And "inet 192.168.50.5" is visible with command "ip a s eth1"


     @rhbz1311988
     @restart @shutdown @eth
     @shutdown_service_connected
     Scenario: NM - general - shutdown service - connected
     * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
     * Bring "up" connection "ethie"
     * "default via 192.168.100.1 dev eth1" is visible with command "ip r"
     * "inet 192.168.100" is visible with command "ip a s eth1" in "5" seconds
     * Stop NM
     Then "default via 192.168.100.1 dev eth1" is visible with command "ip r" for full "5" seconds
      And "inet 192.168.100" is visible with command "ip a s eth1"


      @rhbz1311988
      @restart @shutdown
      @shutdown_service_any
      Scenario: NM - general - shutdown service - all
      * Stop NM
      Then All ifaces but "gre0, gretap0, dummy0, ip6tnl0, tunl0, sit0" are not in state "DOWN"
       And "After=network-pre.target dbus.service" is visible with command "grep After /usr/lib/systemd/system/NetworkManager.service"


    @rhbz1371201
    @ver+=1.4.0
    @CAP_SYS_ADMIN_for_ibft
    Scenario: NM - service - CAP_SYS_ADMIN for ibft plugin
      Then "CAP_SYS_ADMIN" is visible with command "grep CapabilityBoundingSet /usr/lib/systemd/system/NetworkManager.service"


    @general
    @general_networking_on_off
    Scenario: nmcli - general - networking
    * Note the output of "nmcli -t -f NETWORKING general" as value "1"
    * Note the output of "echo enabled" as value "2"
    Then Check noted values "1" and "2" are the same
    * Execute "nmcli networking off"
    * Note the output of "nmcli -t -f NETWORKING general" as value "3"
    * Note the output of "echo disabled" as value "4"
    Then Check noted values "3" and "4" are the same
    Then Execute "nmcli networking on"


    @general
    @general_networking_enabled
    Scenario: nmcli - networking - status - enabled
    * Note the output of "nmcli networking" as value "1"
    * Note the output of "echo enabled" as value "2"
    Then Check noted values "1" and "2" are the same


    @general
    @general_networking_disabled
    Scenario: nmcli - networking - status - disabled
    * Note the output of "nmcli networking" as value "1"
    * Note the output of "echo enabled" as value "2"
    * Check noted values "1" and "2" are the same
    * Execute "nmcli networking off"
    * Note the output of "nmcli networking" as value "3"
    * Note the output of "echo disabled" as value "4"
    Then Check noted values "3" and "4" are the same
    Then Execute "nmcli networking on"


    @general @veth
    @general_networking_off
    Scenario: nmcli - networking - turn off
    * "eth0:" is visible with command "ifconfig"
    * Execute "nmcli networking off"
    Then "eth0:" is not visible with command "ifconfig"
    Then Execute "nmcli networking on"


    @general @veth
    @general_networking_on
    Scenario: nmcli - networking - turn on
    * Execute "nmcli networking off"
    * "eth0:" is not visible with command "ifconfig"
    * Execute "nmcli networking on"
    Then "eth0:" is visible with command "ifconfig"


    @general
    @nmcli_radio_status
    Scenario: nmcli - radio - status
    Then "WIFI-HW\s+WIFI\s+WWAN-HW\s+WWAN\s+enabled|disabled\s+enabled|disabled\s+enabled|disabled\s+enabled|disabled" is visible with command "nmcli radio"


    @general
    @nmcli_device_status
    Scenario: nmcli - device - status
    Then "DEVICE\s+TYPE\s+STATE.+eth0\s+ethernet" is visible with command "nmcli device"


    @general @ethernet
    @nmcli_device_show_ip
    Scenario: nmcli - device - show - check ip
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethernet autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.10/24" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "ethernet"
    Then "IP4.ADDRESS.*192.168.1.10/24" is visible with command "nmcli device show eth1"


    @general
    @nmcli_device_show_general_params
    Scenario: nmcli - device - show - check general params
    * Note the output of "nmcli device show eth0"
    Then Check noted output contains "GENERAL.DEVICE:\s+eth0"
    Then Check noted output contains "GENERAL.TYPE:\s+ethernet"
    Then Check noted output contains "GENERAL.MTU:\s+[0-9]+"
    Then Check noted output contains "GENERAL.HWADDR:\s+\S+:\S+:\S+:\S+:\S+:\S+"
    Then Check noted output contains "GENERAL.CON-PATH:\s+\S+\s"
    Then Check noted output contains "GENERAL.CONNECTION:\s+\S+\s"


    @general
    @nmcli_device_disconnect
    Scenario: nmcli - device - disconnect
    * Bring "up" connection "testeth1"
    * "eth1\s+ethernet\s+connected" is visible with command "nmcli device"
    * Disconnect device "eth1"
    Then "eth1\s+ethernet\s+connected" is not visible with command "nmcli device"


## Basically various bug related reproducer tests follow here

    @general
    @ethernet
    @device_connect
    Scenario: nmcli - device - connect
    * Bring "up" connection "testeth2"
    * Disconnect device "eth2"
    When "eth2\s+ethernet\s+ connected\s+eth2" is not visible with command "nmcli device"
    * Connect device "eth2"
    Then "eth2\s+ethernet\s+connected" is visible with command "nmcli device"


    @rhbz1032717
    @ver+=1.2.0 @ver-=1.7.1
    @eth @teardown_testveth @two_bridged_veths @dhcpd
    @device_reapply_routes
    Scenario: NM - device - reapply just routes
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.99.111 1" in editor
    * Submit "set ipv4.route-metric 21" in editor
    * Submit "set ipv6.method static" in editor
    * Submit "set ipv6.addresses 2000::2/126" in editor
    * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
    * Save in editor
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "nmcli device reapply testX"
    Then "1010::1 via 2000::1 dev testX\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
     And "2000::/126 dev testX\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
     And "192.168.5.0/24 via 192.168.99.111 dev testX\s+proto static\s+metric" is visible with command "ip route"
     And "routers = 192.168.99.1" is visible with command "nmcli con show ethie"
     And "default via 192.168.99.1 dev testX" is visible with command "ip r"


    @ver+=1.7.1
    @eth @teardown_testveth @two_bridged_veths @dhcpd
    @device_reapply_routes
    Scenario: NM - device - reapply just routes
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.99.111 1" in editor
    * Submit "set ipv4.route-metric 21" in editor
    * Submit "set ipv6.method static" in editor
    * Submit "set ipv6.addresses 2000::2/126" in editor
    * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
    * Save in editor
    * Execute "nmcli device reapply testX"
    Then "1010::1 via 2000::1 dev testX\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
     And "2000::/126 dev testX\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
     And "192.168.5.0/24 via 192.168.99.111 dev testX\s+proto static\s+metric" is visible with command "ip route"
     And "routers = 192.168.99.1" is visible with command "nmcli con show ethie"
     And "default via 192.168.99.1 dev testX" is visible with command "ip r"


    @rhbz1032717
    @ver+=1.2.0
    @eth @teardown_testveth @two_bridged_veths @dhcpd
    @device_reapply_all
    Scenario: NM - device - reapply even address and gate
    * Prepare simulated test "testX" device
    * Add connection type "ethernet" named "ethie" for device "testX"
    * Bring "up" connection "ethie"
    * Open editor for connection "ethie"
    * Submit "set ipv4.method static" in editor
    * Submit "set ipv4.addresses 192.168.3.10/24" in editor
    * Submit "set ipv4.gateway 192.168.4.1" in editor
    * Submit "set ipv4.routes 192.168.5.0/24 192.168.3.11 1" in editor
    * Submit "set ipv4.route-metric 21" in editor
    * Submit "set ipv6.method static" in editor
    * Submit "set ipv6.addresses 2000::2/126" in editor
    * Submit "set ipv6.routes 1010::1/128 2000::1 1" in editor
    * Save in editor
    * Execute "ip netns exec testX_ns kill -SIGSTOP $(cat /tmp/testX_ns.pid)"
    * Execute "nmcli device reapply testX"
    Then "1010::1 via 2000::1 dev testX\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
     And "2000::/126 dev testX\s+proto kernel\s+metric 256" is visible with command "ip -6 route"
     And "192.168.3.0/24 dev testX\s+proto kernel\s+scope link\s+src 192.168.3.10" is visible with command "ip route"
     And "192.168.4.1 dev testX\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
     And "192.168.5.0/24 via 192.168.3.11 dev testX\s+proto static\s+metric" is visible with command "ip route"
     And "routers = 192.168.99.1" is not visible with command "nmcli con show ethie"
     And "default via 192.168.99.1 dev testX" is not visible with command "ip r"


    @rhbz1113941
    @veth
    @general
    @device_connect_no_profile
    Scenario: nmcli - device - connect - no profile
    * Finish "nmcli connection delete id testeth2"
    * Connect device "eth2"
    * Bring "down" connection "eth2"
    Then "eth2" is not visible with command "nmcli connection show -a"
    Then "connection.interface-name: \s+eth2" is visible with command "nmcli connection show eth2"


    @rhbz1034150
    @general
    @bridge
    @nmcli_device_delete
    Scenario: nmcli - device - delete
    * Add a new connection of type "bridge" and options "ifname bridge0 con-name bridge0"
    * "bridge0\s+bridge" is visible with command "nmcli device"
    * Execute "nmcli device delete bridge0"
    Then "bridge0\s+bridge" is not visible with command "nmcli device"
    Then "bridge0" is visible with command "nmcli connection"


    @rhbz1034150
    @general
    @veth
    @newveth
    @nmcli_device_attempt_hw_delete
    Scenario: nmcli - device - attempt to delete hw interface
    * "eth9\s+ethernet" is visible with command "nmcli device"
    Then "Error" is visible with command "nmcli device delete eth9"
    Then "eth9\s+ethernet" is visible with command "nmcli device"


    @rhbz1067712
    @nmcli_general_correct_profile_activated_after_restart
    Scenario: nmcli - general - correct profile activated after restart
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name aaa -- ipv4.method auto ipv6.method auto ipv4.may-fail no ipv6.may-fail no"
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name bbb -- ipv4.method auto ipv6.method auto ipv4.may-fail no ipv6.may-fail no"
    * Wait for at least "2" seconds
    * Bring up connection "aaa"
    When "100" is visible with command "nmcli  -t -f GENERAL.STATE device show eth10"
    * Restart NM
    Then "aaa" is visible with command "nmcli device" in "10" seconds
     And "bbb" is not visible with command "nmcli device"


    @rhbz1007365
    @general
    @bridge
    @nmcli_novice_mode_readline
    Scenario: nmcli - general - using readline library in novice mode
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Send "bond" in editor
    * Clear the text typed in editor
    * Submit "bridge" in editor
    Then Expect "There are \d+ optional .*[Bb]ridge"
    * Submit "no" in editor
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "nm-bridge" is visible with command "nmcli connection show bridge"


    @general
    @dns_none
    Scenario: NM - dns none setting
    * Execute "printf '[main]\ndns=none\n' | sudo tee /etc/NetworkManager/conf.d/90-test-dns-none.conf"
    * Restart NM
    * Execute "echo 'nameserver 1.2.3.4' | sudo bash -c 'cat > /etc/resolv.conf'"
    * Execute "systemctl mask sendmail"
    * Bring "up" connection "testeth0"
    * Execute "systemctl unmask sendmail"
    Then "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    Then "nameserver 1[0-9]" is not visible with command "cat /etc/resolv.conf"


    @general
    @remove_dns_none
    Scenario: NM - dns  none removal
    When "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf"
    * Execute "sudo rm -rf /etc/NetworkManager/conf.d/90-test-dns-none.conf"
    * Restart NM
    * Bring "up" connection "testeth0"
    Then "nameserver 1.2.3.4" is not visible with command "cat /etc/resolv.conf"
    Then "nameserver 1[0-9]" is visible with command "cat /etc/resolv.conf"


    @rhbz1136836
    @rhbz1173632
    @general
    @restart
    @connection_up_after_journald_restart
    Scenario: NM - general - bring up connection after journald restart
    #* Add connection type "ethernet" named "ethie" for device "eth1"
    #* Bring "up" connection "testeth0"
    * Finish "sudo systemctl restart systemd-journald.service"
    Then Bring "up" connection "testeth0"


    @rhbz1110436
    @general
    @restore_hostname
    @nmcli_general_dhcp_hostname_over_localhost
    Scenario: NM - general - dont take localhost as configured hostname
    * Execute "hostnamectl set-hostname walderon"
    * Note the output of "cat /etc/hostname" as value "orig_file"
    * Execute "systemctl mask dbus-org.freedesktop.hostname1.service"
    * Execute "systemctl mask systemd-hostnamed.service"
    * Execute "systemctl stop systemd-hostnamed.service"
    * Restart NM
    * Note the output of "hostname" as value "orig_cmd"
    * Check noted values "orig_file" and "orig_cmd" are the same
    * Execute "echo localhost.localdomain > /etc/hostname"
    * Wait for at least "5" seconds
    * Note the output of "hostname" as value "localh_cmd"
    # Check that setting the hostname to localhost have been ignored
    * Check noted values "orig_cmd" and "localh_cmd" are the same
    # Now set it to custom non-localhost value
    * Execute "echo myown.hostname > /etc/hostname"
    * Note the output of "echo myown.hostname" as value "nonlocalh_file"
    * Wait for at least "5" seconds
    * Note the output of "nmcli g hostname" as value "nonlocalh_cmd"
    # Now see that the non-locahost value has been set
    Then Check noted values "nonlocalh_file" and "nonlocalh_cmd" are the same
    # Restoring orig. hostname in after_scenario


    @ver-=1.1
    @rhbz1136843
    @general
    @nmcli_general_ignore_specified_unamanaged_devices
    Scenario: NM - general - ignore specified unmanaged devices
    * Execute "ip link add name dnt type bond"
    # Still unmanaged
    * "dnt\s+bond\s+unmanaged" is visible with command "nmcli device"
    * Execute "ip link set dev dnt up"
    * "dnt\s+bond\s+disconnected" is visible with command "nmcli device"
    # Add a config rule to unmanage the device
    * Execute "echo -e \\n[keyfile]\\nunmanaged-devices=interface-name:dnt > /etc/NetworkManager/NetworkManager.conf"
    * Execute "pkill -HUP NetworkManager"
    * Wait for at least "5" seconds
    # Now the device should be listed as unmanaged
    Then "dnt\s+bond\s+unmanaged" is visible with command "nmcli device"


    @ver+=1.1.1
    @rhbz1136843
    @general
    @nmcli_general_ignore_specified_unamanaged_devices
    Scenario: NM - general - ignore specified unmanaged devices
    * Execute "ip link add name dnt type bond"
    # Still unmanaged
    * "dnt\s+bond\s+unmanaged" is visible with command "nmcli device"
    * Execute "ip link set dev dnt up"
    * "dnt\s+bond\s+unmanaged" is visible with command "nmcli device"
    # Add a config rule to unmanage the device
    * Execute "echo -e \\n[keyfile]\\nunmanaged-devices=interface-name:dnt > /etc/NetworkManager/NetworkManager.conf"
    * Execute "pkill -HUP NetworkManager"
    * Execute "ip addr add dev dnt 1.2.3.4/24"
    * Wait for at least "5" seconds
    # Now the device should be listed as unmanaged
    Then "dnt\s+bond\s+unmanaged" is visible with command "nmcli device"


    @rhbz1371433
    @ver+=1.7.9
    @eth @manage_eth1 @restart
    @nmcli_general_set_device_unmanaged
    Scenario: NM - general - set device to unmanaged state
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
    * Bring up connection "ethie"
    When "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth1"
    * Execute "nmcli device set eth1 managed off"
    When "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth1"
     And "state UP" is visible with command "ip a s eth1"
     And "unmanaged" is visible with command "nmcli device show eth1"
     And "fe80" is visible with command "ip a s eth1"
     And "192" is visible with command "ip a s eth1" in "10" seconds
     And "192" is visible with command "ip r |grep eth1"
    * Restart NM
    Then "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth1"
     And "state UP" is visible with command "ip a s eth1"
     And "unmanaged" is visible with command "nmcli device show eth1"
     And "fe80" is visible with command "ip a s eth1"
     And "192" is visible with command "ip a s eth1"
     And "192" is visible with command "ip r |grep eth1"


    @rhbz1371433
    @ver+=1.7.9
    @eth @manage_eth1 @restart
    @nmcli_general_set_device_back_to_managed
    Scenario: NM - general - set device back from unmanaged state
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie autoconnect no"
    * Bring "up" connection "ethie"
    When "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth1"
    * Execute "nmcli device set eth1 managed off"
    When "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth1"
     And "state UP" is visible with command "ip a s eth1"
     And "unmanaged" is visible with command "nmcli device show eth1"
     And "fe80" is visible with command "ip a s eth1"
     And "192" is visible with command "ip a s eth1" in "10" seconds
     And "192" is visible with command "ip r |grep eth1"
    * Bring "up" connection "ethie"
    Then "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth1"
     And "state UP" is visible with command "ip a s eth1"
     And "unmanaged" is not visible with command "nmcli device show eth1"
     And "fe80" is visible with command "ip a s eth1"
     And "192" is visible with command "ip a s eth1"
     And "192" is visible with command "ip r |grep eth1"


    @vlan
    @general
    @nmcli_general_ifcfg_tailing_whitespace
    Scenario: nmcli - general - ifcfg tailing whitespace ignored
    * Add a new connection of type "vlan" and options "con-name eth1.99 autoconnect no dev eth1 id 99"
    * Check ifcfg-name file created for connection "eth1.99"
    * Execute "sed -i 's/PHYSDEV=eth1/PHYSDEV=eth2    /' /etc/sysconfig/network-scripts/ifcfg-eth1.99"
    * Execute "nmcli connection reload"
    Then "eth2" is visible with command "nmcli con show eth1.99"


    @ver-=1.5
    @mock
    @nmcli_device_wifi_with_two_devices
    Scenario: nmcli - device - wifi show two devices
    Then "test_two_wifi_with_accesspoints \(__main__.TestNetworkManager\) ... ok" is visible with command "sudo -u test python ./tmp/dbusmock-unittest.py TestNetworkManager.test_two_wifi_with_accesspoints"


    @rhbz1114681
    @general
    @nmcli_general_keep_slave_device_unmanaged
    Scenario: nmcli - general - keep slave device unmanaged
    Given Check ifcfg-name file created for connection "testeth1"
    * Execute "echo -e NM_CONTROLLED=no >> /etc/sysconfig/network-scripts/ifcfg-testeth1"
    * Execute "nmcli connection reload"
    * Execute "ip link add link eth1 name eth1.100 type vlan id 100"
    Then "eth1\s+ethernet\s+unmanaged" is visible with command "nmcli device" in "5" seconds
    Then "eth1.100\s+vlan\s+unmanaged" is visible with command "nmcli device"
    Then "testeth1" is not visible with command "nmcli device"


    @rhbz1393997
    @general @eth @restart @restore_hostname
    @nmcli_general_DHCP_HOSTNAME_profile_pickup
    Scenario: nmcli - general - connect correct profile with DHCP_HOSTNAME
    * Add connection type "ethernet" named "ethie" for device "eth1"
    * Execute "nmcli connection modify ethie ipv4.dns 8.8.4.4"
    * Execute "echo -e 'DHCP_HOSTNAME=walderon' >> /etc/sysconfig/network-scripts/ifcfg-ethie"
    * Bring "up" connection "ethie"
    * Restart NM
    Then "ethie" is visible with command "nmcli  -t -f CONNECTION device"


    @rhbz1103777
    @firewall
    @no_error_when_firewald_restarted
    Scenario: NM - general - no error when firewalld restarted
    * Execute "sudo systemctl restart firewalld"
    Then "nm_connection_get_setting_connection: assertion" is not visible with command "journalctl --since '10 seconds ago' --no-pager |grep nm_connection"


    @rhbz1286576
    @restart
    @wpa_supplicant_not_started
    Scenario: NM - general - do not start wpa_supplicant
    * Execute "sudo systemctl stop wpa_supplicant"
    * restart NM
    Then "^active" is not visible with command "systemctl is-active wpa_supplicant" in "5" seconds


    @rhbz1041901
    @general
    @nmcli_general_multiword_autocompletion
    Scenario: nmcli - general - multiword autocompletion
    * Add a new connection of type "bond" and options "con-name 'Bondy connection 1'"
    * "Bondy connection 1" is visible with command "nmcli connection"
    * Autocomplete "nmcli connection delete Bondy" in bash and execute
    Then "Bondy connection 1" is not visible with command "nmcli connection" in "3" seconds


    @rhbz1170199
    @general
    @ethernet
    @IPy
    @nmcli_general_dbus_set_gateway
    Scenario: nmcli - general - dbus api gateway setting
    * Execute "python tmp/dbus-set-gw.py"
    Then "ipv4.gateway:\s+192.168.1.100" is visible with command "nmcli connection show ethos"


    @rhbz1141264
    @general
    @BBB
    @preserve_failed_assumed_connections
    Scenario: NM - general - presume failed assumed connections
    * Execute "ip tuntap add BBB mode tap"
    * Execute "ip link set dev BBB up"
    * Execute "ip addr add 10.2.5.6/24 valid_lft 1024 preferred_lft 1024 dev BBB"
    When "connecting" is visible with command "nmcli device show BBB" in "45" seconds
    * Bring "down" connection "BBB"
    * Execute "ip link set dev BBB up"
    * Execute "ip addr add 10.2.5.6/24 dev BBB"
    Then "connected" is visible with command "nmcli device show BBB" in "45" seconds


    @rhbz1066705
    @general
    @BBB
    @vxlan_interface_recognition
    Scenario: NM - general - vxlan interface support
    * Execute "/sbin/ip link add BBB type vxlan id 42 group 239.1.1.1 dev eth1"
    When "unmanaged" is visible with command "nmcli device show BBB" in "5" seconds
    * Execute "ip link set dev BBB up"
    * Execute "ip addr add fd00::666/8 dev BBB"
    Then "connected" is visible with command "nmcli device show BBB" in "10" seconds
    Then vxlan device "BBB" check


    @rhbz1109426
    @two_bridged_veths
    @veth_goes_to_unmanaged_state
    Scenario: NM - general - veth in unmanaged state
    * Execute "ip link add test1 type veth peer name test1p"
    Then "test1\s+ethernet\s+unmanaged.*test1p\s+ethernet\s+unmanaged" is visible with command "nmcli device"


    @rhbz1067299
    @two_bridged_veths @peers_ns
    @nat_from_shared_network
    Scenario: NM - general - NAT_dhcp from shared networks
    * Execute "ip link add test1 type veth peer name test1p"
    * Add a new connection of type "bridge" and options "ifname vethbr con-name vethbr autoconnect no"
    * Execute "nmcli connection modify vethbr ipv4.method shared"
    * Execute "nmcli connection modify vethbr ipv4.address 172.16.0.1/24"
    * Bring "up" connection "vethbr"
    * Execute "brctl addif vethbr test1p"
    * Execute "ip link set dev test1p up"
    * Execute "ip netns add peers"
    * Execute "ip link set test1 netns peers"
    * Execute "ip netns exec peers ip link set dev test1 up"
    * Execute "ip netns exec peers ip addr add 172.16.0.111/24 dev test1"
    * Execute "ip netns exec peers ip route add default via 172.16.0.1"
    Then Execute "ip netns exec peers ping -c 2 -I test1 8.8.8.8"
    Then Unable to ping "172.16.0.111" from "eth0" device


    @rhbz1083683 @rhbz1256772 @rhbz1260243
    @runonce @teardown_testveth
    @run_once_new_connection
    Scenario: NM - general - run once and quit start new ipv4 and ipv6 connection
    * Prepare simulated test "testY" device
    * Add a new connection of type "ethernet" and options "ifname testY con-name ethie"
    * Execute "nmcli connection modify ethie ipv4.addresses 1.2.3.4/24 ipv4.may-fail no ipv6.addresses 1::128/128 ipv6.may-fail no connection.autoconnect yes"
    * Bring "up" connection "ethie"
    * Disconnect device "testY"
    * Stop NM and clean "testY"
    When "state DOWN" is visible with command "ip a s testY" in "15" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Start NM
    Then "192." is visible with command " ip a s testY |grep 'inet '|grep dynamic" in "60" seconds
    Then "1.2.3.4\/24" is visible with command "ip a s testY |grep 'inet '|grep -v dynamic" in "60" seconds
    Then "2620:" is visible with command "ip a s testY |grep 'inet6'|grep  dynamic" in "60" seconds
    Then "1::128\/128" is visible with command "ip a s testY |grep 'inet6'" in "60" seconds
    Then "default via 192" is visible with command "ip r |grep testY" in "60" seconds
    Then "1.2.3.0\/24" is visible with command "ip r |grep testY" in "60" seconds
    Then "1::128" is visible with command "ip -6 r |grep testY" in "60" seconds
    Then "nm-iface-helper --ifname testY" is visible with command "ps aux|grep helper" in "60" seconds
    Then "inactive" is visible with command "systemctl is-active NetworkManager"


    @rhbz1083683 @rhbz1256772
    @runonce @long
    @run_once_ip4_renewal
    Scenario: NM - general - run once and quit ipv4 renewal
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie"
    * Bring "up" connection "ethie"
    * Disconnect device "eth1"
    * Stop NM and clean "eth1"
    When "state DOWN" is visible with command "ip a s eth1" in "5" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM
    * "192" is visible with command " ip a s eth1 |grep 'inet '|grep dynamic" in "60" seconds
    * Execute "sleep 120"
    # VVV this means that lifetime was refreshed
    When "IPv4" lifetimes are slightly smaller than "245" and "245" for device "eth1"
    Then "192.168.100" is visible with command " ip a s eth1 |grep 'inet '|grep dynamic"
    Then "192.168.100.0/24" is visible with command "ip r |grep eth1"


    @rhbz1083683
    @rhbz1256772
    @teardown_testveth
    @runonce
    @run_once_ip6_renewal
    Scenario: NM - general - run once and quit ipv6 renewal
    * Prepare simulated test "testX" device
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethie"
    #* Execute "nmcli con modify ethie ipv4.may-fail no ipv6.may-fail no"
    * Bring "up" connection "ethie"
    Then "2620" is visible with command "ip a s testX" in "60" seconds
    Then "192" is visible with command "ip a s testX" in "60" seconds
    * Disconnect device "testX"
    * Stop NM and clean "testX"
    When "state DOWN" is visible with command "ip a s testX" in "5" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM
    * Force renew IPv6 for "testX"
    When "2620:" is not visible with command "ip a s testX"
    Then "2620:" is visible with command "ip a s testX" in "120" seconds


    @rhbz1201497
    @runonce @restore_hostname @eth0
    @run_once_helper_for_localhost_localdomain
    Scenario: NM - general - helper running for localhost on localdo
    * Bring "up" connection "testeth0"
    * Disconnect device "eth0"
    * Execute "sleep 2"
    * Stop NM and clean "eth0"
    When "state DOWN" is visible with command "ip a s eth0" in "5" seconds
    * Execute "hostnamectl set-hostname localhost.localdomain"
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM
    Then "eth0" is visible with command "ps aux|grep helper" in "40" seconds
    Then "eth0" is visible with command "ps aux|grep helper" for full "20" seconds



    @rhbz1086906
    @veth @delete_testeth0 @newveth @eth @restart
    @wait-online-for-both-ips
    Scenario: NM - general - wait-online - for both ipv4 and ipv6
    * Add a new connection of type "ethernet" and options "ifname eth10 con-name ethie"
    * Execute "nmcli con modify ethie ipv4.may-fail no ipv6.may-fail no"
    * Bring "up" connection "ethie"
    * Disconnect device "eth10"
    * Restart NM
    #When "2620:" is not visible with command "ip a s eth10"
    * Execute "/usr/bin/nm-online -s -q --timeout=30"
    When "inet .* global" is visible with command "ip a s eth10"
    Then "inet6 .* global" is visible with command "ip a s eth10"


    @rhbz1160013
    @eth
    @policy_based_routing
    Scenario: NM - general - policy based routing
    * Add a new connection of type "ethernet" and options "ifname eth1 con-name ethie"
    * Bring "up" connection "ethie"
    * Bring "up" connection "ethie"
    * Create PBR files for profile "ethie" and "eth1" device in table "1"
    * Bring "down" connection "ethie"
    * Bring "up" connection "ethie"
    Then "32764:\s+from 192.168.100.* lookup 1.*32765:\s+from all iif eth1 lookup 1" is visible with command "ip rule"
    Then "default via 192.168.100.1 dev eth1" is visible with command "ip r s table 1"
    * Bring "down" connection "ethie"
    Then "32764:\s+from 192.168.100..* lookup 1.*32765:\s+from all iif eth1 lookup 1" is not visible with command "ip rule"
    Then "default via 192.168.100.1 dev eth1" is not visible with command "ip r s table 1"


    @rhbz1262972
    @ethernet
    @nmcli_general_dhcp_profiles_general_gateway
    Scenario: NM - general - auto connections ignore the generic-set gateway
    # Up two generic dhcp connections
    * Bring "up" connection "testeth1"
    * Bring "up" connection "testeth2"
    # Create a static connection without gateway
    * Add a new connection of type "ethernet" and options "ifname eth4 con-name ethernet0 autoconnect no"
    * Execute "nmcli connection modify ethernet0 ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.may-fail no"
    # Set a "general" gateway (normally discouraged)
    * Execute "echo 'GATEWAY=1.2.3.1' >> /etc/sysconfig/network"
    * Execute "nmcli connection reload"
    # See that we can still 'see' an upped dhcp connection
    Then "testeth1" is visible with command "nmcli connection"
    # And it still has the DHCP originated gateway, ignoring the static general setting
    Then "default via 192.168.100.1 dev eth1" is visible with command "ip route"
    # Check the other one also for the address
    Then "192.168." is visible with command "ip a s eth2"
    # See we have didn't inactive auto connection
    Then "testeth3" is visible with command "nmcli connection"
    * Bring "up" connection "ethernet0"
    # Static connection up and running with given address
    Then "1.2.3.4" is visible with command "ip a s eth4"
    # And it does use the general set gateway
    Then "default via 1.2.3.1 dev eth4" is visible with command "ip route"


    @rhbz1254089
    @teardown_testveth
    @allow_wired_connections
    Scenario: NM - general - create Wired connection for veth devices
    * Prepare simulated test "testX" device
    * Restart NM
    Then "Wired connection 1" is visible with command "nmcli con"


    @rhbz1182085
    @ver+=1.4
    @long
    @nmcli_general_profile_pickup_doesnt_break_network
    Scenario: nmcli - general - profile pickup does not break network service
    * Add a new connection of type "ethernet" and options "ifname * con-name ethernet0"
    * Add a new connection of type "ethernet" and options "ifname * con-name ethernet1"
    * "connected:ethernet0" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    * "connected:ethernet1" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    # Finish asserts the command exited with 0, thus the network service completed properly
    Then Finish "systemctl restart NetworkManager.service && systemctl restart network.service"


    @rhbz1079353
    @ethernet @teardown_testveth
    @nmcli_general_wait_for_carrier_on_new_device_request
    Scenario: nmcli - general - wait for carrier on new device activation request
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethernet0 autoconnect no"
    * Prepare simulated veth device "testX" wihout carrier
    * Execute "nmcli con modify ethernet0 ipv4.may-fail no"
    * Execute "nmcli con up ethernet0" without waiting for process to finish
    * Wait for at least "1" seconds
    * Execute "ip netns exec testX_ns ip link set testXp up"
    * "connected:ethernet0" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192" is visible with command "ip a s testX" in "60" seconds
    Then "2620" is visible with command "ip a s testX" in "60" seconds


    # Tied to the bz, though these are not direct verifiers
    @rhbz1079353
    @ethernet
    @need_config_server
    @teardown_testveth
    @nmcli_general_activate_static_connection_carrier_ignored
    Scenario: nmcli - general - activate static connection with no carrier - ignored
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethernet0 autoconnect no"
    * Modify connection "ethernet0" changing options "ipv4.method manual ipv4.address '192.168.5.11/24' ipv4.gateway '192.168.5.1' ipv6.method ignore"
    * Prepare simulated veth device "testX" wihout carrier
    * Execute "nmcli con up ethernet0"
    Then "connected:ethernet0" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192.168.5.11" is visible with command "ip a s testX" in "60" seconds


    @rhbz1079353
    @ethernet
    @no_config_server
    @teardown_testveth
    @nmcli_general_activate_static_connection_carrier_not_ignored
    Scenario: nmcli - general - activate static connection with no carrier - not ignored
    * Add a new connection of type "ethernet" and options "ifname testX con-name ethernet0 autoconnect no"
    * Modify connection "ethernet0" changing options "ipv4.method manual ipv4.address '192.168.5.11/24' ipv4.gateway '192.168.5.1' ipv6.method ignore"
    * Prepare simulated veth device "testX" wihout carrier
    * Execute "nmcli con up ethernet0"
    Then "connected:ethernet0" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192.168.5.11" is visible with command "ip a s testX" in "60" seconds


    @rhbz1272974
    @need_s390x
    @remove_ctcdevice
    @ctc_device_recognition
    Scenario: NM - general - ctc device as ethernet recognition
    * Execute "znetconf -a $(znetconf -u |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }')"
    Then "ethernet" is visible with command "nmcli dev |grep $(znetconf -c |grep ctc | awk '{print $5}')"


    @rhbz1128581
    @eth0
    @eth
    @teardown_testveth
    @connect_to_slow_router
    Scenario: NM - general - connection up to 60 seconds
    * Prepare simulated test "testM" device
    * Add a new connection of type "ethernet" and options "ifname testM con-name ethie autoconnect no"
    * Modify connection "ethie" changing options "ipv4.method manual ipv4.address '192.168.99.99/24' ipv4.gateway '192.168.99.1' ipv6.method ignore"
    * Append "GATEWAY_PING_TIMEOUT=60" to ifcfg file "ethie"
    * Execute "sudo nmcli connection reload"
    # VVV Remove gateway's ip address so it is unpingable
    * Execute "ip netns exec testM_ns ip a del 192.168.99.1/24 dev testM_bridge"
    * Run child "nmcli con up ethie"
    When "gateway ping failed with error code 1" is visible with command "journalctl -o cat --since '50 seconds ago' |grep testM" in "20" seconds
    # VVV Add gateway's ip address so it is pingable again
    * Run child "sleep 40 && ip netns exec testM_ns ip a add 192.168.99.1/24 dev testM_bridge"
    Then "connected:ethie" is visible with command "nmcli -t -f STATE,CONNECTION device" in "55" seconds
    And "connected:full" is visible with command "nmcli -t -f STATE,CONNECTIVITY general status"


    @rhbz1034158
    @connect_testeth0
    @nmcli_monitor
    @disp
    Scenario: nmcli - monitor
    * Run child "nmcli m 2>&1> /tmp/monitor.txt"
    * Write dispatcher "pre-up.d/98-disp" file with params "sleep 1;"
    * Write dispatcher "pre-down.d/97-disp" file with params "sleep 1;"
    * Bring "down" connection "testeth0"
    * Execute "sleep 1"
    * Bring "up" connection "testeth0"
    * Execute "sleep 1"
    * Execute "pkill -9 nmcli"
    Then "eth0: deactivating" is visible with command "cat /tmp/monitor.txt"
     And "Connectivity is now 'none'" is visible with command "cat /tmp/monitor.txt"
     And "eth0: disconnected" is visible with command "cat /tmp/monitor.txt"
     And "There's no primary connection" is visible with command "cat /tmp/monitor.txt"
     And "Networkmanager is now in the 'disconnected' state" is visible with command "cat /tmp/monitor.txt"
     And "Networkmanager is now in the 'connecting' state" is visible with command "cat /tmp/monitor.txt"
     And "eth0: using connection 'testeth0'" is visible with command "cat /tmp/monitor.txt"
     And "Connectivity is now 'full'" is visible with command "cat /tmp/monitor.txt"
     And "'testeth0' is now the primary connection" is visible with command "cat /tmp/monitor.txt"
     And "Networkmanager is now in the 'connected' state" is visible with command "cat /tmp/monitor.txt"
     And "eth0: connected" is visible with command "cat /tmp/monitor.txt"


     @rhbz998000
     @ver+=1.4.0
     @ipv4 @disp
     @device_reapply
     Scenario: nmcli - device -reapply
     * Add connection type "ethernet" named "ethie" for device "eth1"
     * Bring "up" connection "ethie"
     * Write dispatcher "99-disp" file
     * Execute "ip addr a 1.2.3.4/24 dev eth1"
     * Execute "nmcli c modify ethie +ipv4.address 1.2.3.4/24"
     * Execute "nmcli device reapply eth1"
     When "up" is not visible with command "cat /tmp/dispatcher.txt"
     * Execute "ip addr a 1.2.3.4/24 dev eth1"
     * Execute "nmcli c modify ethie -ipv4.address 1.2.3.4/24"
     * Execute "nmcli device reapply eth1"
     Then "up" is not visible with command "cat /tmp/dispatcher.txt"


     @rhbz1371920
     @ver+=1.4.0
     @eth @teardown_testveth @kill_dbus-monitor
     @device_dbus_signal
     Scenario: NM - general - device dbus signal
     * Prepare simulated test "testX" device
     * Add connection type "ethernet" named "ethie" for device "testX"
     * Run child "dbus-monitor --system --monitor 'sender=org.freedesktop.NetworkManager' > /tmp/dbus.txt"
     * Bring "up" connection "ethie"
     Then "NetworkManager.Device.Wired; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"
      And "NetworkManager.Device.Veth; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"
      And "DBus.Properties; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"


     @rhbz1404594
     @ver+=1.7.1
     @ipv4 @kill_dbus-monitor
     @dns_over_dbus
     Scenario: NM - general - publish dns over dbus
     * Add connection type "ethernet" named "ethie" for device "eth1"
     * Run child "dbus-monitor --system --monitor 'sender=org.freedesktop.NetworkManager' > /tmp/dbus.txt"
     * Bring "up" connection "ethie"
     Then "string \"nameservers\"\s+variant\s+array\s+\[\s+string" is visible with command "grep -A 10 Dns /tmp/dbus.txt"


      @rhbz1358335
      @ver+=1.4.0
      @NM_syslog_in_anaconda
      Scenario: NM - general - syslog in Anaconda
      Then "NetworkManager" is visible with command "grep NetworkManager /var/log/anaconda/syslog"


      @rhbz1217288
      @ver+=1.4.0
      @eth
      @snapshot_rollback
      Scenario: NM - general - snapshot and rollback
      * Add connection type "ethernet" named "ethie" for device "eth1"
      * Bring "up" connection "ethie"
      * Snapshot "create" for "eth1"
      * Open editor for connection "ethie"
      * Submit "set ipv4.method manual" in editor
      * Submit "set ipv4.addresses 1.2.3.4/24" in editor
      * Submit "set ipv4.gateway 1.2.3.1" in editor
      * Save in editor
      * Quit editor
      * Bring "up" connection "ethie"
      When "1.2.3.4/24" is visible with command "ip a s eth1" in "5" seconds
       And "1.2.3.1" is visible with command "ip r"
      * Snapshot "revert" for "eth1"
      Then "192.168.100" is visible with command "ip a s eth1" in "5" seconds
       And "1.2.3.4/24" is not visible with command "ip a s eth1"
       And "1.2.3.1" is not visible with command "ip r"
       And "192.168.100.1" is visible with command "ip r"


      @rhbz1433303
      @ver+=1.4.0
      @long
      @stable_mem_consumption
      Scenario: NM - general - stable mem consumption
      * Execute "sh tmp/repro_1433303.sh"
      * Execute "sh tmp/repro_1433303.sh"
      * Note the output of "pmap -x $(pidof NetworkManager) |grep total | awk '{print $4}'" as value "1"
      * Note the output of "pmap -x $(pidof NetworkManager) |grep total | awk '{print $3}'" as value "3"
      * Execute "sh tmp/repro_1433303.sh"
      * Note the output of "pmap -x $(pidof NetworkManager) |grep total | awk '{print $4}'" as value "2"
      * Note the output of "pmap -x $(pidof NetworkManager) |grep total | awk '{print $3}'" as value "4"
      Then Check noted value "2" difference from "1" is lower than "500"
      Then Check noted value "4" difference from "3" is lower than "500"

      @rhbz1398932
      @ver+=1.7.2
      @BBB
      @dummy_connection
      Scenario: NM - general - create dummy connection
      * Add a new connection of type "dummy" and options "ifname BBB con-name BBB ip4 1.2.3.4/24 autoconnect no"
      * Bring up connection "BBB"
      Then "dummy" is visible with command "ip -d l show BBB | grep dummy"
      Then "1.2.3.4/24" is visible with command "ip a s BBB | grep inet"
