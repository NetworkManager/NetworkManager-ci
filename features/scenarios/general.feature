Feature: nmcli - general

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @pass
    Scenario: Dummy scenario that is supposed to pass
    * Execute "nmcli --version"


    @xfail @crash
    @crashing_NM_binary
    Scenario: Dummy scenario that is supposed to test crash embeding
    * Execute "sysctl kernel.core_pattern"
    * Execute "pkill -SIGSEGV NetworkManager"
    # the test should fail, because @xfail reverts returncode
    Then Check coredump is not found in "60" seconds


    @logging
    @nmcli_logging
    Scenario: NM - general - setting log level and autocompletion
    Then "DEBUG\s+ERR\s+INFO\s+.*TRACE\s+WARN" is visible with tab after "sudo nmcli general logging level "
    * Set logging for "all" to "INFO"
    Then "INFO\s+[^:]*$" is visible with command "nmcli general logging"
    * Set logging for "default,WIFI:ERR" to " "
    Then "INFO\s+[^:]*,WIFI:ERR,[^:]*$" is visible with command "nmcli general logging"


    @rhbz1212196
    @reduce_logging
    Scenario: NM - general - reduce logging
     * Add "bond" connection named "gen-bond0" for device "gen-bond"
    Then "preparing" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago'   |grep '<info> .*gen-bond' |grep 'preparing device'"
    Then "exported as" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago' |grep '<info> .*gen-bond' |grep 'exported as'"
    Then "Stage" is not visible with command "journalctl _COMM=NetworkManager --since '2 min ago'       |grep '<info> .*gen-bond' |grep 'Stage'"


    @rhbz1614726
    @ver+=1.25 @rhelver+=8
    @man_pages
    Scenario: NM - general - man pages
    Then "nm-settings " is visible with tab after "man nm-settings"
    Then "nm-settings-dbus" is visible with tab after "man nm-settings"
    Then "nm-settings-keyfile" is visible with tab after "man nm-settings"
    Then "nm-settings-nmcli" is visible with tab after "man nm-settings"


    @rhbz1362542
    @ver+=1.4.0
    @insufficient_logging_perms
    Scenario: NM - general - not enough logging perms
    Then "Error: failed to set logging: access denied" is visible with command "sudo -u test nmcli general logging level TRACE domains all"


    @rhbz1422786
    @ver+=1.8.0
    @eth8_disconnect
    @insufficient_perms_connection_down
    Scenario: nmcli - general - not enough perms for connection down
    * Bring "up" connection "testeth8"
    Then "Not authorized to deactivate connections" is visible with command "sudo -u test nmcli connection down testeth8"


    @rhbz1422786
    @ver+=1.8.0
    @eth8_disconnect
    @insufficient_perms_connection_up
    Scenario: nmcli - general - not enough perms for connection up
    Then "Not authorized to control networking" is visible with command "sudo -u test nmcli connection up testeth8"


    @general_check_version
    Scenario: nmcli - general - check version
    * Note the output of "rpm -q --queryformat '%{VERSION}' NetworkManager" as value "1"
    * Note the output of "nmcli -t -f VERSION general" as value "2"
    Then Check noted values "1" and "2" are the same


    @remove_fedora_connection_checker
    @general_state_connected
    Scenario: nmcli - general - state connected
    Then "connected" is visible with command "nmcli -t -f STATE general"


    @restore_hostname
    @hostname_change
    Scenario: nmcli - general - set hostname
    * Execute "sudo nmcli general hostname walderon"
    Then "walderon" is visible with command "cat /etc/hostname"


    @ver+=1.4.0
    @restore_hostname @eth0
    @pull_hostname_from_dhcp
    Scenario: nmcli - general - pull hostname from DHCP
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @ver+=1.4.0
    @ver-=1.29
    @restore_hostname @eth0
    @pull_hostname_from_dns
    Scenario: nmcli - general - pull hostname from DNS
    # Note: we want to test the name resolution via DNS lookup. If we used the
    # default DHCP range, even if the DNS lookup fails the glibc resolver would
    # look into /etc/hosts and return one of the names there. Instead, use a
    # different range without mapping in /etc/hosts.
    # Note/2: we also add a static address so that NM will first try to resolve
    # that (and fail because at that point there is no name server). Later,
    # after the DHCPv4 lease is obtained, NM will try again and succeed.
    # Note/3: --dhcp-option=12 is to prevent NM from sending a hostname option
    * Prepare simulated test "testG" device with "172.25.15" ipv4 and daemon options "--dhcp-option=12 --dhcp-host=00:11:22:33:44:55,172.25.15.1,foo-bar"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv6.method ignore
          ipv4.method auto
          """
    * Modify connection "con_general" changing options "ipv4.address 172.25.13.1/30 ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo-bar" is visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1970335
    @ver+=1.30.0
    @rhelver+=8
    @kill_children @internal_DHCP @dhcpd
    @restore_hostname @eth0
    @pull_hostname_from_dns
    Scenario: nmcli - general - pull hostname from DNS
    # Note: we want to test the name resolution via DNS lookup. If we used the
    # default DHCP range, even if the DNS lookup fails the glibc resolver would
    # look into /etc/hosts and return one of the names there. Instead, use a
    # different range without mapping in /etc/hosts.
    # Note/2: we also add a static address so that NM will first try to resolve
    # that (and fail because at that point there is no name server). Later,
    # after the DHCPv4 lease is obtained, NM will try again and succeed.
    # Note/3: --dhcp-option=12 is to prevent NM from sending a hostname option
    # Note/4: We have ipv6 only default device testX6 not setting hostname.
    * Prepare simulated test "testX6" device without DHCP
    * Execute "ip -n testX6_ns addr add dev testX6p fc01::1/64"
    * Configure dhcpv6 prefix delegation server with address configuration mode "dhcp-stateful"
    * Prepare simulated test "testG" device with "172.25.15" ipv4 and daemon options "--dhcp-option=12 --dhcp-host=00:11:22:33:44:55,172.25.15.1,foo-bar"
    * Execute "ip netns exec testG_ns kill -SIGSTOP $(cat /tmp/testG_ns.pid)"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no ipv4.method auto"
    * Add "ethernet" connection named "con_general2" for device "testX6" with options "ipv6.method auto"
    * Modify connection "con_general" changing options "ipv4.address 172.25.13.1/30 ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testX6" in "25" seconds
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Execute "sleep 10"
    * Execute "ip netns exec testG_ns kill -SIGCONT $(cat /tmp/testG_ns.pid)"
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo-bar" is visible with command "hostnamectl --transient" in "60" seconds


    @ver+=1.29.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_priority
    Scenario: nmcli - general - Hostname priority
    * Execute "echo -e '[connection-hostname]\nmatch-device=interface-name:test?\nhostname.only-from-default=0' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testG" device with "192.168.97" ipv4 and daemon options "--dhcp-option=3 --dhcp-host=00:11:22:33:44:55,192.168.97.13,foo"
    * Prepare simulated test "testH" device with "192.168.98" ipv4 and daemon options "--dhcp-option=3 --dhcp-host=00:00:11:00:00:11,192.168.98.11,bar"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ethernet.cloned-mac-address 00:11:22:33:44:55
          ipv6.method disabled
          """
    * Add "ethernet" connection named "con_general2" for device "testH" with options
          """
          autoconnect no
          ethernet.cloned-mac-address 00:00:11:00:00:11
          ipv6.method disabled
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds

    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo" is visible with command "hostnamectl --transient" in "60" seconds

    * Bring up connection "con_general2"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    # Since connections have the same priority, the one activated earlier wins
    Then "foo" is visible with command "hostnamectl --transient" in "60" seconds

    # Increase the priority of the second connection and retry
    * Modify connection "con_general2" changing options "hostname.priority 50"
    * Bring up connection "con_general2"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    # Now con_general2 has higher priority and wins
    Then "bar" is visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_full
    Scenario: NM - general - hostname mode full
    * Execute "echo -e '[main]\nhostname-mode=full' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_dhcp
    Scenario: NM - general - hostname mode dhcp
    * Execute "echo -e '[main]\nhostname-mode=dhcp' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1766944
    @ver+=1.29
    @restart_if_needed @restore_hostname @delete_testeth0
    @pull_hostname_from_dhcp_no_gw_no_default_hostname
    Scenario: nmcli - general - pull hostname from DHCP - no gw - no need for it
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv4.never-default yes
          hostname.only-from-default false
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_full_without_dhcp_hosts
    Scenario: NM - general - hostname mode dhcp without dhcp hosts
    * Execute "echo -e '[main]\nhostname-mode=dhcp' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Execute "echo no-hosts > /etc/dnsmasq.d/dnsmasq_custom.conf"
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
     And "localhost|fedora" is visible with command "hostnamectl --transient" for full "20" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_none
    Scenario: NM - general - hostname mode none
    * Execute "echo -e '[main]\nhostname-mode=none' > /etc/NetworkManager/conf.d/90-hostname.conf"
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring up connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
     And "localhost|fedora" is visible with command "hostnamectl --transient" for full "20" seconds


    @rhbz1744427
    @ver+=1.22.0
    @restore_hostname
    @gen_activate_with_incorrect_hostname
    Scenario: nmcli - ipv4 - dhcp-hostname - set dhcp-hostname
    * Execute "hostnamectl set-hostname bpelled_invalid_hostname"
    * Add "ethernet" connection named "con_general" for device "eth8"
    Then Bring "up" connection "con_general"


    @restart_if_needed
    @general_state_disconnected
    Scenario: nmcli - general - state disconnected
    * "disconnect" all " connected" devices
    Then "disconnected" is visible with command "nmcli -t -f STATE general"
    * Bring up connection "testeth0"


    @networking_on
    @general_state_asleep
    Scenario: nmcli - general - state asleep
    * Execute "nmcli networking off"
    Then "asleep" is visible with command "nmcli -t -f STATE general"
    * Execute "nmcli networking on"


    @general_state_running
    Scenario: nmcli - general - running
    Then "running" is visible with command "nmcli -t -f RUNNING general"


    @restart_if_needed
    @general_state_not_running
    Scenario: nmcli - general - not running
    * Stop NM
    Then "NetworkManager is not running" is visible with command "nmcli general" in "5" seconds


    @rhbz1361145
    @ver+=1.39.2
    @restart_if_needed
    @general_nmcli_offline_connection_add_modify
    Scenario: nmcli - general - offline connection add and modify
    * Stop NM
    When Note the output of "nmcli --offline c add con-name offline0 type dummy ifname dummy0"
    Then Noted value contains "id=offline0"
     And Noted value contains "type=dummy"
     And Noted value contains "interface-name=dummy0"
     And Noted value contains "method=disabled"
    When Note the output of "nmcli --offline c add con-name offline0 type dummy ifname dummy0 | nmcli --offline c modify ipv4.method auto ipv6.method auto"
    Then Noted value contains "id=offline0"
     And Noted value contains "type=dummy"
     And Noted value contains "interface-name=dummy0"
     And Noted value contains "method=auto"


    @rhbz1311988
    @shutdown @eth8_disconnect @add_testeth8  @restart_if_needed
    @shutdown_service_assumed
    Scenario: NM - general - shutdown service - assumed
    * Delete connection "testeth8"
    * Stop NM
    * Execute "ip addr add 192.168.50.5/24 dev eth8"
    * Execute "route add default gw 192.168.50.1 metric 200 dev eth8"
    * "default via 192.168.50.1 dev eth8\s+metric 200" is visible with command "ip r"
    * "inet 192.168.50.5" is visible with command "ip a s eth8" in "5" seconds
    * Start NM
    * "default via 192.168.50.1 dev eth8\s+metric 200" is visible with command "ip r"
    * "inet 192.168.50.5" is visible with command "ip a s eth8" in "5" seconds
    * Stop NM
    Then "default via 192.168.50.1 dev eth8\s+metric 200" is visible with command "ip r" for full "5" seconds
     And "inet 192.168.50.5" is visible with command "ip a s eth8"


    @rhbz1311988
    @shutdown @restart_if_needed
    @shutdown_service_connected
    Scenario: NM - general - shutdown service - connected
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no ipv4.may-fail no "
    * Bring "up" connection "con_general"
    * "default via 192.168.100.1 dev eth8" is visible with command "ip r"
    * "inet 192.168.10[0-3]" is visible with command "ip a s eth8" in "5" seconds
    * Stop NM
    Then "default via 192.168.100.1 dev eth8" is visible with command "ip r" for full "5" seconds
     And "inet 192.168.10[0-3]" is visible with command "ip a s eth8"


    @rhbz1311988
    @shutdown @unload_kernel_modules @restart_if_needed
    @shutdown_service_any
    Scenario: NM - general - shutdown service - all
    * Stop NM
    Then All ifaces but "gre0, gretap0, dummy0, ip6tnl0, tunl0, sit0, erspan0, orig*" are not in state "DOWN"
     And "After=network-pre.target dbus.service" is visible with command "grep After /usr/lib/systemd/system/NetworkManager.service"


    @rhbz1371201
    @ver+=1.4.0
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @CAP_SYS_ADMIN_for_ibft
    Scenario: NM - service - CAP_SYS_ADMIN for ibft plugin
    Then "CAP_SYS_ADMIN" is visible with command "grep ^CapabilityBoundingSet /usr/lib/systemd/system/NetworkManager.service"


    @networking_on
    @general_networking_on_off
    Scenario: nmcli - general - networking
    When "enabled" is visible with command "nmcli -t -f NETWORKING general"
    * Execute "nmcli networking off"
    When "disabled" is visible with command "nmcli -t -f NETWORKING general"
    Then Execute "nmcli networking on"


    @networking_on
    @general_networking_enabled
    Scenario: nmcli - networking - status - enabled
    Then "enabled" is visible with command "nmcli networking"


    @networking_on
    @general_networking_disabled
    Scenario: nmcli - networking - status - disabled
    When "enabled" is visible with command "nmcli networking"
    * Execute "nmcli networking off"
    Then "disabled" is visible with command "nmcli networking"
    Then Execute "nmcli networking on"


    @networking_on
    @general_networking_off
    Scenario: nmcli - networking - turn off
    * "eth0:" is visible with command "ifconfig"
    * Execute "nmcli networking off"
    Then "eth0:" is not visible with command "ifconfig" in "5" seconds
    Then Execute "nmcli networking on"


    @networking_on
    @general_networking_on
    Scenario: nmcli - networking - turn on
    * Execute "nmcli networking off"
    * "eth0:" is not visible with command "ifconfig" in "5" seconds
    * Execute "nmcli networking on"
    Then "eth0:" is visible with command "ifconfig" in "5" seconds


    @ver-1.37.3
    @nmcli_radio_status
    Scenario: nmcli - radio - status
    Then "WIFI-HW\s+WIFI\s+WWAN-HW\s+WWAN\s+enabled|disabled\s+enabled|disabled\s+enabled|disabled\s+enabled|disabled" is visible with command "nmcli radio"


    @ver+=1.37.3
    @nmcli_radio_status
    Scenario: nmcli - radio - status
    Then "WIFI-HW\s+WIFI\s+WWAN-HW\s+WWAN\s+enabled|disabled|missing\s+enabled|disabled\s+enabled|disabled|missing\s+enabled|disabled" is visible with command "nmcli radio"


    @nmcli_device_status
    Scenario: nmcli - device - status
    Then "DEVICE\s+TYPE\s+STATE.+eth0\s+ethernet" is visible with command "nmcli device"


    @nmcli_device_show_ip
    Scenario: nmcli - device - show - check ip
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.1.10/24
          """
    * Bring up connection "con_general"
    Then "IP4.ADDRESS.*192.168.1.10/24" is visible with command "nmcli device show eth8"


    @nmcli_device_show_general_params
    Scenario: nmcli - device - show - check general params
    * Note the output of "nmcli device show eth0"
    Then Noted value contains "GENERAL.DEVICE:\s+eth0"
    Then Noted value contains "GENERAL.TYPE:\s+ethernet"
    Then Noted value contains "GENERAL.MTU:\s+[0-9]+"
    Then Noted value contains "GENERAL.HWADDR:\s+\S+:\S+:\S+:\S+:\S+:\S+"
    Then Noted value contains "GENERAL.CON-PATH:\s+\S+\s"
    Then Noted value contains "GENERAL.CONNECTION:\s+\S+\s"


    @nmcli_device_disconnect
    Scenario: nmcli - device - disconnect
    * Bring "up" connection "testeth8"
    * "eth8\s+ethernet\s+connected" is visible with command "nmcli device"
    * Disconnect device "eth8"
    Then "eth8\s+ethernet\s+connected" is not visible with command "nmcli device"


## Basically various bug related reproducer tests follow here

    @device_connect
    @nmcli_device_connect
    Scenario: nmcli - device - connect
    * Bring "up" connection "testeth9"
    * Disconnect device "eth9"
    When "eth9\s+ethernet\s+ connected\s+eth9" is not visible with command "nmcli device"
    * Connect device "eth9"
    Then "eth9\s+ethernet\s+connected" is visible with command "nmcli device"


    @ver+=1.12.2
    @ver-1.21
    @dhcpd
    @nmcli_device_reapply_routes
    Scenario: NM - device - reapply just routes
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testG" in "25" seconds
    * Modify connection "con_general" changing options "ipv4.routes '192.168.5.0/24 192.168.99.111 1' ipv4.route-metric 21 ipv6.method static ipv6.addresses 2000::2/126 ipv6.routes '1010::1/128 2000::1 1'"
    * "Error.*" is not visible with command "nmcli device reapply testG" in "1" seconds
    Then "1010::1 via 2000::1 dev testG\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
     And "2000::/126 dev testG\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
     And "192.168.5.0/24 via 192.168.99.111 dev testG\s+proto static\s+metric" is visible with command "ip route"
     And "routers = 192.168.99.1" is visible with command "nmcli con show con_general"
     And "default via 192.168.99.1 dev testG\s+proto dhcp\s+metric 21" is visible with command "ip r"
     And "default via 192.168.99.1 dev testG\s+proto dhcp\s+metric" is visible with command "ip r"


    @rhbz1763062
    @ver+=1.21
    @ver-1.37.90
    @ver-1.36.7
    @ver/rhel/8/6-1.36.0.6
    @dhcpd
    @nmcli_device_reapply_routes
    Scenario: NM - device - reapply just routes
    * Prepare simulated test "testG" device
    * Execute "ip netns exec testG_ns kill -SIGSTOP $(cat /tmp/testG_ns.pid)"
    * Add "ethernet" connection named "con_general" for device "testG"
    * Modify connection "con_general" changing options "ipv4.routes '192.168.5.0/24 192.168.99.111 1' ipv4.route-metric 21 ipv6.method static ipv6.addresses 2000::2/126 ipv6.routes '1010::1/128 2000::1 1'"
    * "Error.*" is not visible with command "nmcli device reapply testG" in "1" seconds
    * Execute "ip netns exec testG_ns kill -SIGCONT $(cat /tmp/testG_ns.pid)"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testG" in "25" seconds
    Then "1010::1 via 2000::1 dev testG\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
    And "2000::/126 dev testG\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    And "192.168.5.0/24 via 192.168.99.111 dev testG\s+proto static\s+metric" is visible with command "ip route"
    And "routers = 192.168.99.1" is visible with command "nmcli con show con_general" in "70" seconds
    And "default via 192.168.99.1 dev testG\s+proto dhcp\s+metric 21" is visible with command "ip r"


    @rhbz1763062
    @ver+=1.37.90
    @ver+=1.36.7
    @ver/rhel/8/6-=1.36.0.6
    @dhcpd
    @nmcli_device_reapply_routes
    Scenario: NM - device - reapply just routes
    * Prepare simulated test "testG" device
    * Execute "ip netns exec testG_ns kill -SIGSTOP $(cat /tmp/testG_ns.pid)"
    * Add "ethernet" connection named "con_general" for device "testG"
    * Modify connection "con_general" changing options "ipv4.routes '192.168.5.0/24 192.168.99.111 1' ipv4.route-metric 21 ipv6.method static ipv6.addresses 2000::2/126 ipv6.routes '1010::1/128 2000::1 1'"
    * "Error.*" is not visible with command "nmcli device reapply testG" in "1" seconds
    * Execute "ip netns exec testG_ns kill -SIGCONT $(cat /tmp/testG_ns.pid)"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testG" in "25" seconds
    Then "1010::1 via 2000::1 dev testG\s+proto static\s+metric 1" is visible with command "ip -6 route" in "5" seconds
    And "2000::/126 dev testG\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
    And "192.168.5.0/24 via 192.168.99.111 dev testG\s+proto static\s+metric" is visible with command "ip route"
    And "routers = 192.168.99.1" is visible with command "nmcli con show con_general" in "70" seconds
    And "default via 192.168.99.1 dev testG\s+proto dhcp\s+src 192.168.99.[0-9]+\s+metric 21" is visible with command "ip r"


    @rhbz1032717 @rhbz1505893 @rhbz1702657
    @ver+=1.18
    @dhcpd @mtu
    @nmcli_device_reapply_all
    Scenario: NM - device - reapply even address and gate
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options "802-3-ethernet.mtu 1460"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testG" in "45" seconds
    * Modify connection "con_general" changing options "ipv4.method static 802-3-ethernet.mtu 9000 ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11 1' ipv4.route-metric 21 ipv6.method static ipv6.addresses 2000::2/126 ipv6.routes '1010::1/128 2000::1 1'"
    * Execute "ip netns exec testG_ns kill -SIGSTOP $(cat /tmp/testG_ns.pid)"
    * "Error.*" is not visible with command "nmcli device reapply testG" in "1" seconds
    Then "1010::1 via 2000::1 dev testG\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
     And "2000::/126 dev testG\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
     And "192.168.3.0/24 dev testG\s+proto kernel\s+scope link\s+src 192.168.3.10 metric 21" is visible with command "ip route" in "45" seconds
     And "192.168.4.1 dev testG\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
     And "192.168.5.0/24 via 192.168.3.11 dev testG\s+proto static\s+metric 1" is visible with command "ip route"
     And "routers = 192.168.99.1" is not visible with command "nmcli con show con_general"
     And "default via 192.168.99.1 dev testG" is not visible with command "ip r"
     And "9000" is visible with command "ip a s testG" in "5" seconds


    @rhbz1032717 @rhbz1505893
    @ver+=1.10.2 @ver-1.18
    @dhcpd
    @nmcli_device_reapply_all
    Scenario: NM - device - reapply even address and gate
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testG" in "45" seconds
    * Modify connection "con_general" changing options "ipv4.method static ipv4.addresses 192.168.3.10/24 ipv4.gateway 192.168.4.1 ipv4.routes '192.168.5.0/24 192.168.3.11 1' ipv4.route-metric 21 ipv6.method static ipv6.addresses 2000::2/126 ipv6.routes '1010::1/128 2000::1 1'"
    * Execute "ip netns exec testG_ns kill -SIGSTOP $(cat /tmp/testG_ns.pid)"
    * "Error.*" is not visible with command "nmcli device reapply testG" in "1" seconds
    Then "1010::1 via 2000::1 dev testG\s+proto static\s+metric 1" is visible with command "ip -6 route" in "45" seconds
     And "2000::/126 dev testG\s+proto kernel\s+metric 1" is visible with command "ip -6 route"
     And "192.168.3.0/24 dev testG\s+proto kernel\s+scope link\s+src 192.168.3.10 metric 21" is visible with command "ip route" in "45" seconds
     And "192.168.4.1 dev testG\s+proto static\s+scope link\s+metric 21" is visible with command "ip route"
     And "192.168.5.0/24 via 192.168.3.11 dev testG\s+proto static\s+metric 1" is visible with command "ip route"
     And "routers = 192.168.99.1" is not visible with command "nmcli con show con_general"
     And "default via 192.168.99.1 dev testG" is not visible with command "ip r"


    @rhbz1113941
    @nmcli_device_connect_no_profile
    Scenario: nmcli - device - connect - no profile
    * Cleanup connection "eth9" and device "eth9"
    * Execute "nmcli connection delete id testeth9"
    * Connect device "eth9"
    * Bring "down" connection "eth9"
    Then "eth9" is not visible with command "nmcli connection show -a"
    Then "connection.interface-name: \s+eth9" is visible with command "nmcli connection show eth9"


    @rhbz1034150
    @nmcli_device_delete
    Scenario: nmcli - device - delete
    * Add "bridge" connection named "gen_br" for device "brX"
    * "brX\s+bridge" is visible with command "nmcli device"
    * Execute "nmcli device delete brX"
    Then "brX\s+bridge" is not visible with command "nmcli device"
    Then "gen_br" is visible with command "nmcli connection"


    @rhbz1034150
    @not_on_veth
    @nmcli_device_attempt_hw_delete
    Scenario: nmcli - device - attempt to delete hw interface
    * "eth9\s+ethernet" is visible with command "nmcli device"
    Then "Error" is visible with command "nmcli device delete eth9"
    Then "eth9\s+ethernet" is visible with command "nmcli device"


    @rhbz1067712
    @restart_if_needed
    @nmcli_general_correct_profile_activated_after_restart
    Scenario: nmcli - general - correct profile activated after restart
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          -- ipv4.method auto
          ipv6.method auto
          ipv4.may-fail no
          ipv6.may-fail no
          """
    * Add "ethernet" connection named "con_general2" for device "testG" with options
          """
          -- ipv4.method auto
          ipv6.method auto
          ipv4.may-fail no
          ipv6.may-fail no
          """
    * Wait for at least "2" seconds
    * Bring up connection "con_general"
    When "100" is visible with command "nmcli  -t -f GENERAL.STATE device show testG"
    When "connected:con_general:testG" is visible with command "nmcli -t -f STATE,CONNECTION,DEVICE device" in "10" seconds
    * Restart NM
    Then "connected:con_general:testG" is visible with command "nmcli -t -f STATE,CONNECTION,DEVICE device" in "10" seconds
     And "con_general2" is not visible with command "nmcli device"


    @rhbz1007365
    @ver-=1.39.2
    @nmcli_novice_mode_readline
    Scenario: nmcli - general - using readline library in novice mode
    * Cleanup connection "bridge" and device "nm-bridge"
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


    @rhbz1136836 @rhbz1173632
    @restart_if_needed
    @connection_up_after_journald_restart
    Scenario: NM - general - bring up connection after journald restart
    #* Add "ethernet" connection named "con_general" for device "eth8"
    #* Bring "up" connection "testeth0"
    * Execute "sudo systemctl restart systemd-journald.service"
    Then Bring "up" connection "testeth0"


    @rhbz1110436
    @restore_hostname @restart_if_needed
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
    Then "myown.hostname" is visible with command "nmcli g hostname" in "5" seconds
    # Restoring orig. hostname in after_scenario


    @rhbz1136843
    @remove_custom_cfg
    @nmcli_general_ignore_specified_unamanaged_devices
    Scenario: NM - general - ignore specified unmanaged devices
    * Create "bond" device named "bond0"
    # Still unmanaged
    * "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"
    * Execute "ip link set dev bond0 up"
    * "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"
    # Add a config rule to unmanage the device
    * Execute "echo -e [keyfile]\\nunmanaged-devices=interface-name:bond0 > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "pkill -HUP NetworkManager"
    * Execute "ip addr add dev bond0 1.2.3.4/24"
    * Wait for at least "5" seconds
    # Now the device should be listed as unmanaged
    Then "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"


    @rhbz1371433
    @ver+=1.7.9
    @manage_eth8 @eth8_disconnect @restart_if_needed
    @nmcli_general_set_device_unmanaged
    Scenario: NM - general - set device to unmanaged state
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Bring up connection "con_general"
    #When "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
    * Execute "nmcli device set eth8 managed off"
    #When "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "state UP" is visible with command "ip a s eth8"
     And "unmanaged" is visible with command "nmcli device show eth8"
     And "fe80" is visible with command "ip a s eth8"
     And "192" is visible with command "ip a s eth8" in "10" seconds
     And "192" is visible with command "ip r |grep eth8"
    * Restart NM
    #Then "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "state UP" is visible with command "ip a s eth8"
     And "unmanaged" is visible with command "nmcli device show eth8"
     And "fe80" is visible with command "ip a s eth8"
     And "192" is visible with command "ip a s eth8"
     And "192" is visible with command "ip r |grep eth8"


    @rhbz1371433
    @ver+=1.7.9
    @ifcfg-rh @manage_eth8 @eth8_disconnect
    @nmcli_general_set_device_back_to_managed
    Scenario: NM - general - set device back from unmanaged state
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Bring "up" connection "con_general"
    #When "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "fe80" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip r |grep eth8"
    * Wait for at least "2" seconds
    * Execute "nmcli device set eth8 managed off"
    #When "/sbin/dhclient" is not visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "state UP" is visible with command "ip a s eth8"
     And "unmanaged" is visible with command "nmcli device show eth8"
     And "192" is visible with command "ip a s eth8" in "15" seconds
     And "fe80" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip r |grep eth8"
    * Bring "up" connection "con_general"
    #Then "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "state UP" is visible with command "ip a s eth8"
     And "unmanaged" is not visible with command "nmcli device show eth8"
     And "192" is visible with command "ip a s eth8" in "15" seconds
     And "fe80" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip r |grep eth8"


    @ifcfg-rh
    @nmcli_general_ifcfg_tailing_whitespace
    Scenario: nmcli - general - ifcfg tailing whitespace ignored
    * Cleanup interface "eth8.100"
    * Add "vlan" connection named "eth8.100" with options "autoconnect no dev eth8 id 100"
    * Check ifcfg-name file created for connection "eth8.100"
    * Execute "sed -i 's/PHYSDEV=eth8/PHYSDEV=eth9    /' /etc/sysconfig/network-scripts/ifcfg-eth8.100"
    * Reload connections
    Then "eth9" is visible with command "nmcli con show eth8.100"


    @ver+=1.5
    @mock
    @nmcli_device_wifi_with_two_devices
    Scenario: nmcli - device - wifi show two devices
    * Execute "mv ./contrib/dbus/dbusmock-unittest.py /tmp"
    Then "test_two_wifi_with_accesspoints \(__main__.TestNetworkManager\) ... ok" is visible with command "sudo -u test python3 /tmp/dbusmock-unittest.py"


    @rhbz1114681
    @ifcfg-rh @add_testeth8 @restore_eth8
    @nmcli_general_keep_slave_device_unmanaged
    Scenario: nmcli - general - keep slave device unmanaged
    # We need to delete keyfile testeth8
    * Execute "nmcli con del testeth8"
    # And add ifcfg one
    * Add "ethernet" connection named "testeth8" for device "eth8"
    Given Check ifcfg-name file created for connection "testeth8"
    * Execute "echo -e NM_CONTROLLED=no >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
    * Reload connections
    * Execute "ip link add link eth8 name eth8.100 type vlan id 100"
    Then "eth8\s+ethernet\s+unmanaged" is visible with command "nmcli device" in "5" seconds
    Then "eth8.100\s+vlan\s+unmanaged" is visible with command "nmcli device"
    Then "testeth8" is not visible with command "nmcli device"


    @rhbz1393997
    @restart_if_needed @restore_hostname
    @nmcli_general_DHCP_HOSTNAME_profile_pickup
    Scenario: nmcli - general - connect correct profile with DHCP_HOSTNAME
    * Add "ethernet" connection named "con_general" for device "eth8" with options "ipv4.dns 8.8.4.4"
    * Execute "echo -e 'DHCP_HOSTNAME=walderon' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Bring "up" connection "con_general"
    * Restart NM
    Then "con_general" is visible with command "nmcli  -t -f CONNECTION device"


    @rhbz1171751
    @ver+=1.8.0
    @add_testeth8 @restart_if_needed @not_on_s390x
    @match_connections_when_no_var_run_exists
    Scenario: NM - general - connection matching for anaconda
     * Stop NM
     * Execute "rm -rf /etc/sysconfig/network-scripts/ifcfg-testeth8"
     * Execute "rm -rf /var/run/NetworkManager/*"
     * Execute "echo 'DEVICE=eth8' >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
     * Execute "echo 'NAME=testeth8' >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
     * Execute "echo 'BOOTPROTO=dhcp' >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
     * Execute "echo 'IPV6INIT=yes' >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
     * Execute "echo 'TYPE=Ethernet' >> /etc/sysconfig/network-scripts/ifcfg-testeth8"
     Then "testeth8" is not visible with command "nmcli con sh -a"
     * Start NM
     Then "testeth8" is visible with command "nmcli con sh -a" in "5" seconds


    @rhbz1673321
    @ver+=1.25.90 @ver-=1.29
    @not_on_veth @restart_if_needed
    @match_connections_with_pci_address
    Scenario: NM - general - connection matching for dhcp with infinite leasetime
    * Add "ethernet" connection named "con_general"
    * Execute "nmcli con mod con_general +match.path $(udevadm info /sys/class/net/eth1 | grep ID_PATH= | awk -F '=' '{print $2}')"
    * Bring "up" connection "con_general"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds


    @rhbz1673321 @rhbz1942741
    # Fixed in 1.30.0-7
    @ver+=1.30
    @eth0 @restart_if_needed
    @match_connections_with_pci_address
    Scenario: NM - general - connection matching for dhcp with infinite leasetime
    * Add "ethernet" connection named "con_general"
    * Execute "nmcli con mod con_general +match.path $(udevadm info /sys/class/net/eth0 | grep ID_PATH= | awk -F '=' '{print $2}')"
    * Bring "up" connection "con_general"
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds


    @rhbz1837999
    @ver+=1.25.90
    @restart_if_needed
    @match_connections_via_kernel_option
    Scenario: NM - general - connection matching via kernel option
    * Add "ethernet" connection named "con_general" for device "eth8" with options "match.kernel-command-line root"
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
    * Modify connection "con_general" changing options "match.kernel-command-line r00t"
    * Reboot
    # Kernel command line doesn't match so connection should be blocked
    Then "eth8" is not visible with command "nmcli con show -a" in "10" seconds


    @rhbz1729854
    @ver+=1.14
    @restart_if_needed @not_on_s390x @no_config_server @rhelver+=8 @rhel_pkg
    @no_assumed_wired_connections
    Scenario: NM - general - connection matching for anaconda
    * Stop NM
    * Execute "rm -rf /var/lib/NetworkManager/no-auto-default.state"
    * Execute "rm -rf /var/run/NetworkManager/*"
    * Start NM
    Then "Wired" is not visible with command "nmcli con" in "5" seconds


    @rhbz1687937
    @ver+=1.25
    @no_config_server @eth8_disconnect @manage_eth8 @add_testeth8 @restart_if_needed
    @no_assumed_wired_connections_var2
    Scenario: NM - general - no auto connection created
    * Execute "nmcli device set eth8 managed no"
    * Delete connection "testeth8"
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Stop NM
    * Execute "rm -rf /var/lib/NetworkManager/no-auto-default.state"
    * Start NM
    * Execute "sleep 1"
    * Execute "nmcli device set eth8 managed yes"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
    * Delete connection "con_general"
    Then "Wired" is not visible with command "nmcli con"


    @rhbz1460760
    @ver+=1.8.0
    @mtu
    @ifcfg_respect_externally_set_mtu
    Scenario: NM - general - respect externally set mtu
    * Cleanup connection "con_general"
    * Execute "ip link set dev eth8 mtu 1400"
    * Execute "echo 'DEVICE=eth8' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Execute "echo 'NAME=con_general' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Execute "echo 'BOOTPROTO=dhcp' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Execute "echo 'IPV6INIT=yes' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Execute "echo 'TYPE=Ethernet' >> /etc/sysconfig/network-scripts/ifcfg-con_general"
    * Reload connections
    * Bring "up" connection "con_general"
    Then "1400" is visible with command "ip a s eth8" in "5" seconds


    @rhbz1103777
    @firewall
    @no_error_when_firewald_restarted
    Scenario: NM - general - no error when firewalld restarted
    * Execute "sudo systemctl restart firewalld"
    Then "nm_connection_get_setting_connection: assertion" is not visible with command "journalctl --since '10 seconds ago' --no-pager |grep nm_connection"


    @rhbz1103777
    @ver+=1.8.0 @fedoraver+=31
    @firewall @restart_if_needed
    @show_zones_after_firewalld_install
    Scenario: NM - general - show zones after firewall restart
    * Execute "yum -y remove firewalld"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "eth8" with options "connection.zone work"
    * Execute "yum -y install firewalld"
    * Execute "systemctl start firewalld"
    Then "work" is visible with command "firewall-cmd  --get-zone-of-interface=eth8" in "3" seconds


    @rhbz1286576
    @restart_if_needed
    @wpa_supplicant_not_started
    Scenario: NM - general - do not start wpa_supplicant
    * Execute "sudo systemctl stop wpa_supplicant"
    * restart NM
    Then "^active" is not visible with command "systemctl is-active wpa_supplicant" in "5" seconds


    @rhbz1041901
    @nmcli_general_multiword_autocompletion
    Scenario: nmcli - general - multiword autocompletion
    * Add "bond" connection named "'Bondy connection 1'" for device "gen-bond"
    * "Bondy connection 1" is visible with command "nmcli connection"
    * Autocomplete "nmcli connection delete Bondy" in bash and execute
    Then "Bondy connection 1" is not visible with command "nmcli connection" in "3" seconds


    @rhbz1170199
    @IPy
    @nmcli_general_dbus_set_gateway
    Scenario: nmcli - general - dbus api gateway setting
    * Cleanup connection "con_general"
    * Execute "/usr/bin/python contrib/dbus/dbus-set-gw.py"
    Then "ipv4.gateway:\s+192.168.1.100" is visible with command "nmcli connection show con_general"


    @rhbz1141264
    @tuntap
    @preserve_failed_assumed_connections
    Scenario: NM - general - presume failed assumed connections
    * Execute "ip tuntap add tap0 mode tap"
    * Execute "ip link set dev tap0 up"
    * Execute "ip addr add 10.2.5.6/24 valid_lft 30 preferred_lft 30 dev tap0"
    Then "10.2.5.6/24" is visible with command "ip addr show tap0" for full "25" seconds
    Then "10.2.5.6/24" is not visible with command "ip addr show tap0" in "10" seconds
    * Execute "ip link set dev tap0 up"
    * Execute "ip addr add 10.2.5.6/24 dev tap0"
    Then "10.2.5.6/24" is visible with command "ip addr show tap0" for full "10" seconds


    @rhbz1109426
    @ver+=1.10
    @veth_goes_to_unmanaged_state
    Scenario: NM - general - veth in unmanaged state
    * Create "veth" device named "test1g" with options "peer name test1gp"
    Then "test1g\s+ethernet\s+unmanaged.*test1gp\s+ethernet\s+unmanaged" is visible with command "nmcli device"


    @rhbz1067299
    @ver-=1.31.4
    @nat_from_shared_network_iptables
    Scenario: NM - general - NAT_dhcp from shared networks
    * Create "veth" device named "test1g" with options "peer name test1gp"
    * Add "bridge" connection named "vethbrg" for device "vethbrg" with options
          """
          stp no
          autoconnect no
          ipv4.method shared
          ipv4.address 172.16.0.1/24
          """
    * Bring "up" connection "vethbrg"
    * Execute "ip link set test1gp master vethbrg"
    * Execute "ip link set dev test1gp up"
    * Add namespace "peers"
    * Execute "ip link set test1g netns peers"
    * Execute "ip netns exec peers ip link set dev test1g up"
    * Execute "ip netns exec peers ip addr add 172.16.0.111/24 dev test1g"
    * Execute "ip netns exec peers ip route add default via 172.16.0.1"
    Then "OK" is visible with command "ip netns exec peers curl --interface test1g http://static.redhat.com/test/rhel-networkmanager.txt" in "20" seconds
    Then Unable to ping "172.16.0.111" from "eth0" device


    @rhbz1067299 @rhbz1548825
    @rhelver+=8 @fedoraver+=32
    @ver+=1.31.5
    @remove_custom_cfg
    @nat_from_shared_network_iptables
    Scenario: NM - general - NAT_dhcp from shared networks - iptables
    Given Execute "printf '[main]\nfirewall-backend=iptables' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    Given Restart NM
    * Create "veth" device named "test1g" with options "peer name test1gp"
    * Add "bridge" connection named "vethbrg" for device "vethbrg" with options
          """
          stp no
          autoconnect no
          ipv4.method shared
          ipv4.address 172.16.0.1/24
          """
    * Bring "up" connection "vethbrg"
    * Execute "ip link set test1gp master vethbrg"
    * Execute "ip link set dev test1gp up"
    * Add namespace "peers"
    * Execute "ip link set test1g netns peers"
    * Execute "ip netns exec peers ip link set dev test1g up"
    * Execute "ip netns exec peers ip addr add 172.16.0.111/24 dev test1g"
    * Execute "ip netns exec peers ip route add default via 172.16.0.1"
    Then "OK" is visible with command "ip netns exec peers curl --interface test1g http://static.redhat.com/test/rhel-networkmanager.txt" in "20" seconds
    Then Unable to ping "172.16.0.111" from "eth0" device


    @rhbz1548825
    @rhelver+=8 @fedoraver+=32
    @ver+=1.31.5
    @remove_custom_cfg @permissive
    @nat_from_shared_network_nftables
    Scenario: NM - general - NAT_dhcp from shared networks - nftables
    Given Execute "printf '[main]\nfirewall-backend=nftables' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    Given Restart NM
    * Create "veth" device named "test1g" with options "peer name test1gp"
    * Add "bridge" connection named "vethbrg" for device "vethbrg" with options
          """
          stp no
          autoconnect no
          ipv4.method shared
          ipv4.address 172.16.0.1/24
          """
    * Bring "up" connection "vethbrg"
    * Execute "ip link set test1gp master vethbrg"
    * Execute "ip link set dev test1gp up"
    * Add namespace "peers"
    * Execute "ip link set test1g netns peers"
    * Execute "ip netns exec peers ip link set dev test1g up"
    * Execute "ip netns exec peers ip addr add 172.16.0.111/24 dev test1g"
    * Execute "ip netns exec peers ip route add default via 172.16.0.1"
    Then "OK" is visible with command "ip netns exec peers curl --interface test1g http://static.redhat.com/test/rhel-networkmanager.txt" in "20" seconds
    Then Unable to ping "172.16.0.111" from "eth0" device


    @rhbz1083683 @rhbz1256772 @rhbz1260243
    @ver-=1.34
    @restart_if_needed @runonce
    @run_once_new_connection
    Scenario: NM - general - run once and quit start new ipv4 and ipv6 connection
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          ipv4.addresses 1.2.3.4/24
          ipv4.may-fail no
          ipv6.addresses 1::128/128
          ipv6.may-fail no
          connection.autoconnect yes
          """
    * Bring "up" connection "con_general"
    * Disconnect device "testG"
    * Stop NM and clean "testG"
    When "state DOWN" is visible with command "ip a s testG" in "15" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Start NM without PID wait
    Then "192." is visible with command " ip a s testG |grep 'inet '|grep dynamic" in "60" seconds
    Then "1.2.3.4\/24" is visible with command "ip a s testG |grep 'inet '|grep -v dynamic" in "60" seconds
    Then "2620:" is visible with command "ip a s testG |grep 'inet6'|grep  dynamic" in "60" seconds
    Then "1::128\/128" is visible with command "ip a s testG |grep 'inet6'" in "60" seconds
    Then "default via 192" is visible with command "ip r |grep testG" in "60" seconds
    Then "1.2.3.0\/24" is visible with command "ip r |grep testG" in "60" seconds
    Then "1::128" is visible with command "ip -6 r |grep testG" in "60" seconds
    Then "nm-iface-helper --ifname testG" is visible with command "ps aux|grep helper" in "60" seconds
    Then "inactive" is visible with command "systemctl is-active NetworkManager"


    @rhbz1083683 @rhbz1256772
    @restart_if_needed @runonce
    @run_once_ip4_renewal
    Scenario: NM - general - run once and quit ipv4 renewal
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG"
    * Bring "up" connection "con_general"
    * Disconnect device "testG"
    * Stop NM and clean "testG"
    When "state DOWN" is visible with command "ip a s testG" in "5" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM without PID wait
    * "192" is visible with command " ip a s testG |grep 'inet '|grep dynamic" in "60" seconds
    * Execute "sleep 20"
    # VVV this means that lifetime was refreshed
    When "preferred_lft (119|118|117)sec" is visible with command " ip a s testG" in "100" seconds
    Then "192.168.99" is visible with command " ip a s testG |grep 'inet '|grep dynamic"
    Then "192.168.99.0/24" is visible with command "ip r |grep testG"


    @rhbz1083683 @rhbz1256772
    @ver+=1.12
    @restart_if_needed @runonce
    @run_once_ip6_renewal
    Scenario: NM - general - run once and quit ipv6 renewal
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG"
    #* Execute "nmcli con modify con_general ipv4.may-fail no ipv6.may-fail no"
    * Bring "up" connection "con_general"
    Then "2620" is visible with command "ip a s testG" in "60" seconds
    Then "192" is visible with command "ip a s testG" in "60" seconds
    * Disconnect device "testG"
    * Stop NM and clean "testG"
    When "state DOWN" is visible with command "ip a s testG" in "5" seconds
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'configure-and-quit=yes' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'dhcp=internal' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM without PID wait
    When "2620:" is visible with command "ip a s testG" in "60" seconds
    * Force renew IPv6 for "testG"
    Then "2620:" is visible with command "ip a s testG" in "120" seconds


    @rhbz1201497
    @ver-1.10
    @restart_if_needed @eth0 @restore_hostname @runonce
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
    * Execute "ip link set dev eth0 up"
    * Execute "sleep 1"
    * Start NM without PID wait
    Then "eth0" is visible with command "ps aux|grep helper" in "40" seconds
    Then "eth0" is visible with command "ps aux|grep helper" for full "20" seconds


    @rhbz1201497
    @ver+=1.10
    @restart_if_needed @eth0 @restore_hostname @runonce
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
    ## VVV Just to make sure slow devices will catch carrier
    * Execute "echo '[device]' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'match-device=interface-name:eth0' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "echo 'carrier-wait-timeout=10000' >> /etc/NetworkManager/conf.d/01-run-once.conf"
    * Execute "sleep 1"
    * Start NM without PID wait
    Then "eth0" is visible with command "ps aux|grep helper" in "40" seconds
    Then "eth0" is visible with command "ps aux|grep helper" for full "20" seconds


    @rhbz1498943
    @ver+=1.10
    @network_online_target_not_depend_on_wait_online
    Scenario: NM - general - network-online target - no wait-online dep
    Then "No such file or directory" is visible with command "cat /usr/lib/systemd/system/network-online.target.wants/NetworkManager-wait-online.service"


    @rhbz1520865
    @ver+=1.10
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @nm_wait_online_requisite_NM
    Scenario: NM - general - NM wait online - requisite NM
    Then "Requisite=NetworkManager.service" is visible with command "cat /usr/lib/systemd/system/NetworkManager-wait-online.service"


    @rhbz1520865
    @ver+=1.10
    @rhelver-=0
    @nm_wait_online_requires_NM
    Scenario: NM - general - NM wait online - requires NM
    Then "Requires=NetworkManager.service" is visible with command "cat /usr/lib/systemd/system/NetworkManager-wait-online.service"


    @rhbz1086906
    @ver-1.39.3
    @ver-1.38.1
    @ver-1.36.5
    @ver/rhel/8/6-=1.36.0.5
    @delete_testeth0 @restart_if_needed
    @wait-online-for-both-ips
    Scenario: NM - general - wait-online - for both ipv4 and ipv6
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options "ipv4.may-fail no ipv6.may-fail no"
    * "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    * Restart NM
    #When "2620:" is not visible with command "ip a s testG"
    * Execute "/usr/bin/nm-online -s -q --timeout=30"
    When "inet .* global" is visible with command "ip a s testG"
    Then "inet6 .* global" is visible with command "ip a s testG"


    @rhbz1086906 @rhbz2050216 @rhbz2077605
    @ver+=1.39.3
    @ver+=1.38.1
    @ver+=1.36.5
    @ver/rhel/8/6+=1.36.0.6
    @delete_testeth0 @restart_if_needed
    @wait-online-for-both-ips
    Scenario: NM - general - wait-online - for both ipv4 and ipv6
    * Prepare simulated test "testG" device
    * Execute "rm -rf /tmp/testG_ns.lease"
    * Execute "ip netns exec testG_ns pkill -SIGSTOP -F /tmp/testG_ns.pid && sleep 1"
    * Add "ethernet" connection named "con_general" for device "testG" with options "ipv4.may-fail no ipv6.may-fail no"
    # Do a random wait between 0s and 3s to delay DHCP server a bit
    * Execute "sleep $(echo $(shuf -i 0-3 -n 1)) && ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid" without waiting for process to finish
    # It takes slightly over 4s to reach connected state
    # so any delay over 0 or 1 (it really depends on DHCP now)
    # should hit the bug.
    * Execute "sleep 5"
    * Restart NM
    * Execute "/usr/bin/nm-online -s -q --timeout=30"
    When "inet .* global" is visible with command "ip a s testG"
    Then "inet6 .* global" is visible with command "ip a s testG"


    @rhbz1498807
    @ver+=1.8.0
    @restart_if_needed
    @wait_online_with_autoconnect_no_connection
    Scenario: NM - general - wait-online - skip non autoconnect soft device connections
    * Add "bridge" connection named "gen_br" for device "brX" with options "autoconnect no"
    * Stop NM
    * Start NM
    Then "PASS" is visible with command "/usr/bin/nm-online -s -q --timeout=30 && echo PASS"


    @rhbz1515027
    @ver+=1.10
    @delete_testeth0 @remove_custom_cfg @restart_if_needed
    @nm_online_wait_for_delayed_device
    Scenario: NM - general - wait for delayed device
    * Add "ethernet" connection named "con_general" for device "testG"
    * Stop NM
    * Prepare simulated veth device "testG" wihout carrier
    * Execute "echo '[device-testG]' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo 'match-device=interface-name:testG' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo 'carrier-wait-timeout=20000' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "sleep 2"
    * Start NM
    * Run child "echo FAIL > /tmp/nm-online.txt && /usr/bin/nm-online -s -q --timeout=30 && echo PASS > /tmp/nm-online.txt"
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "sleep 10"
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
     And Execute "ip netns exec testG_ns ip link set testGp up"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz1759956
    @ver+=1.22.5 @ver-=1.24
    @delete_testeth0 @remove_custom_cfg @restart_if_needed
    @nm_online_wait_for_second_connection
    Scenario: NM - general - wait for second device
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          802-1x.eap md5
          802-1x.identity user
          802-1x.password password
          connection.autoconnect-priority 50
          connection.auth-retries 1
          """
    * Add "ethernet" connection named "con_general2" for device "testG" with options
          """
          connection.autoconnect-priority 20
          """
    * Stop NM
    * Execute "rm -rf /var/run/NetworkManager"
    * Prepare simulated test "testG" device
    * Execute "ip netns exec testG_ns pkill -SIGSTOP -F /tmp/testG_ns.pid"
    * Execute "ip addr flush dev testG"
    * Start NM
    * Run child "echo FAIL > /tmp/nm-online.txt && /usr/bin/nm-online -s -q --timeout=60 && echo PASS > /tmp/nm-online.txt"
    When "con_general" is visible with command "nmcli con show -a" in "10" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "sleep 30"
    When "con_general2" is visible with command "nmcli con show -a" in "20" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz1759956 @rhbz1828458
    @ver+=1.25
    @delete_testeth0 @remove_custom_cfg @restart_if_needed
    @nm_online_wait_for_second_connection
    Scenario: NM - general - wait for second device
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          802-1x.eap md5
          802-1x.identity user
          802-1x.password password
          connection.autoconnect-priority 50
          connection.auth-retries 1
          """
    * Add "ethernet" connection named "con_general2" for device "testG" with options
          """
          connection.autoconnect-priority 20
          """
    * Stop NM
    * Execute "rm -rf /var/run/NetworkManager"
    * Prepare simulated test "testG" device
    * Execute "ip netns exec testG_ns pkill -SIGSTOP -F /tmp/testG_ns.pid"
    * Execute "ip addr flush dev testG"
    * Start NM
    * Run child "echo FAIL > /tmp/nm-online.txt && NM_ONLINE_TIMEOUT=60 /usr/bin/nm-online -s -q && echo PASS > /tmp/nm-online.txt"
    When "con_general" is visible with command "nmcli con show -a" in "10" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "sleep 30"
    When "con_general2" is visible with command "nmcli con show -a" in "20" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz2025617
    @ver+=1.37
    @nm_online_large_timeout
    Scenario: NM - general - nm-online accepts 24 days timeout
    Then "2073600" is visible with command "nm-online --help"
    And "Connecting.*2073600s.*online" is visible with command "nm-online --timeout 2073600"


    @rhbz2049421
    @ver+=1.39
    @ver/rhel/8+=1.39.2
    # do not remove @permissive, dnsmasq.orig then fails to bind to :53
    @delete_testeth0 @dns_dnsmasq @slow_dnsmasq @permissive
    @nm_online_wait_for_dnsmasq
    Scenario: NM - general - nm-online waits until dnsmasq is up
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options "ipv4.may-fail no ipv6.may-fail no"
    * "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    Then "dnsmasq.orig" is not visible with command "ps aux" in "0" seconds
    # enable slow dnsmasq
    * Execute "cp -f `which dnsmasq.slow` `which dnsmasq`"
    * Restart NM in background
    # wait until dnsmasq is started by NM
    When "sleep 3" is visible with command "ps aux | grep -A1 dnsmasq" in "10" seconds
    * Execute "/usr/bin/nm-online -s --timeout=30"
    Then "sleep 3" is not visible with command "ps aux | grep -A1 dnsmasq" in "0" seconds


    @rhbz1160013
    @permissive @need_dispatcher_scripts @ifcfg-rh
    @policy_based_routing
    Scenario: NM - general - policy based routing
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Bring "up" connection "con_general"
    * Bring "up" connection "con_general"
    * Create PBR files for profile "con_general" and "eth8" device in table "1"
    * Bring "down" connection "con_general"
    * Bring "up" connection "con_general"
    Then "17200:\s+from 192.168.10[0-3].* lookup 1.*17201:\s+from all iif eth8 lookup 1" is visible with command "ip rule"
    Then "default via 192.168.100.1 dev eth8" is visible with command "ip r s table 1"
    * Bring "down" connection "con_general"
    Then "17200:\s+from 192.168.10[0-3]..* lookup 1.*17201:\s+from all iif eth8 lookup 1" is not visible with command "ip rule" in "5" seconds
    Then "default via 192.168.100.1 dev eth8" is not visible with command "ip r s table 1"


    @rhbz1384799
    @ver+=1.10
    @permissive @need_dispatcher_scripts @ifcfg-rh @restart_if_needed
    @modify_policy_based_routing_connection
    Scenario: NM - general - modify policy based routing connection
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Bring "up" connection "con_general"
    * Create PBR files for profile "con_general" and "testG" device in table "1"
    * Modify connection "con_general" changing options "connection.autoconnect yes ipv6.method ignore"
    * Reboot
    Then "17200:\s+from 192.168.99.* lookup 1.*17201:\s+from all iif testG lookup 1" is visible with command "ip rule" in "20" seconds
     And "default via 192.168.99.1 dev testG" is visible with command "ip r s table 1" in "20" seconds
     And "2620" is not visible with command "ip a s testG" in "20" seconds


    @rhbz1262972
    @ifcfg-rh @backup_sysconfig_network
    @nmcli_general_dhcp_profiles_general_gateway
    Scenario: NM - general - auto connections ignore the generic-set gateway
    # Up dhcp connection
    * Bring "up" connection "testeth9"
    # Create a static connection without gateway
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          ipv4.may-fail no
          """
    # Set a "general" gateway (normally discouraged)
    * Execute "echo 'GATEWAY=1.2.3.1' >> /etc/sysconfig/network"
    * Reload connections
    # See that we can still 'see' an upped dhcp connection
    Then "testeth9" is visible with command "nmcli connection"
    # And it still has the DHCP originated gateway, ignoring the static general setting
    Then "default via 192.168.100.1 dev eth9" is visible with command "ip route" in "10" seconds
    # Check the other one also for the address
    Then "192.168." is visible with command "ip a s eth9"
    * Bring "up" connection "con_general"
    # See we didn't inactive auto connection
    Then "testeth9" is visible with command "nmcli connection"
    # Static connection up and running with given address
    Then "1.2.3.4" is visible with command "ip a s eth8"
    # And it does use the general set gateway
    Then "default via 1.2.3.1 dev eth8" is visible with command "ip route"


    @rhbz1254089
    @allow_veth_connections @restart_if_needed
    @allow_wired_connections
    Scenario: NM - general - create Wired connection for veth devices
    * Prepare simulated test "testG" device
    * Restart NM
    Then "Wired connection" is visible with command "nmcli con"


    @rhbz1182085
    @ver+=1.9
    @netservice @restart_if_needed @eth10_disconnect @rhelver-=7 @fedoraver-=0 @connect_testeth0 @restore_broken_network
    @nmcli_general_profile_pickup_doesnt_break_network
    Scenario: nmcli - general - profile pickup does not break network service
    * Add "ethernet" connection named "con_general" for device "'*'"
    * Add "ethernet" connection named "con_general2" for device "'*'"
    * "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    * "connected:con_general2" is visible with command "nmcli -t -f STATE,CONNECTION device" in "50" seconds
    # Finish asserts the command exited with 0, thus the network service completed properly
    * Restart NM
    Then Execute "sleep 3 && systemctl restart network.service"


    @rhbz1079353

    @nmcli_general_wait_for_carrier_on_new_device_request
    Scenario: nmcli - general - wait for carrier on new device activation request
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Prepare simulated veth device "testG" wihout carrier
    * Wait for at least "1" seconds
    * Modify connection "con_general" changing options "ipv4.may-fail no"
    * Execute "nmcli con up con_general" without waiting for process to finish
    * Wait for at least "1" seconds
    * Execute "ip netns exec testG_ns ip link set testGp up"
    * "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192" is visible with command "ip a s testG" in "60" seconds
    Then "2620" is visible with command "ip a s testG" in "60" seconds


    @rhbz1722024
    @ver+=1.22
    @eth8_up
    @general_nmclient_query_carrier
    Scenario: nmclient - general - query carrier
    * Execute "ip link set dev eth8 up"
    When "True" is visible with command "/usr/bin/python contrib/gi/nmclient_get_device_property.py eth8 get_carrier"
    * Execute "ip link set dev eth8 down"
    Then "False" is visible with command "/usr/bin/python contrib/gi/nmclient_get_device_property.py eth8 get_carrier"


    # Tied to the bz, though these are not direct verifiers
    @rhbz1079353
    @need_config_server
    @nmcli_general_activate_static_connection_carrier_ignored
    Scenario: nmcli - general - activate static connection with no carrier - ignored
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.address '192.168.5.11/24' ipv4.gateway '192.168.5.1' ipv6.method ignore"
    * Prepare simulated veth device "testG" wihout carrier
    * Execute "nmcli con up con_general"
    Then "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192.168.5.11" is visible with command "ip a s testG" in "60" seconds


    @rhbz1079353 @rhbz2043514
    @may_fail
    @no_config_server
    @nmcli_general_activate_static_connection_carrier_not_ignored
    Scenario: nmcli - general - activate static connection with no carrier - not ignored
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.address '192.168.5.11/24' ipv4.gateway '192.168.5.1' ipv6.method ignore"
    * Prepare simulated veth device "testG" wihout carrier
    * Execute "nmcli con up con_general"
    Then "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192.168.5.11" is visible with command "ip a s testG" in "60" seconds


    @rhbz1272974
    @s390x_only
    @remove_ctcdevice
    @ctc_device_recognition
    Scenario: NM - general - ctc device as ethernet recognition
    * Execute "znetconf -a $(znetconf -u |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }')"
    Then "ethernet" is visible with command "nmcli dev |grep $(znetconf -c |grep ctc | awk '{print $5}')"


    #@rhbz1128581
    #@eth0
    #@connect_to_slow_router
    #Scenario: NM - general - connection up to 60 seconds
    #* Prepare simulated test "testM" device
    #* Add "ethernet" connection named "con_general" for device "testM" with options "autoconnect no"
    #* Modify connection "con_general" changing options "ipv4.method manual ipv4.address '192.168.99.99/24' ipv4.gateway '192.168.99.1' ipv6.method ignore"
    #* Append "GATEWAY_PING_TIMEOUT=60" to ifcfg file "con_general"
    #* Reload connections
    ## VVV Remove gateway's ip address so it is unpingable
    #* Execute "ip netns exec testM_ns ip a del 192.168.99.1/24 dev testM_bridge"
    #* Run child "nmcli con up con_general"
    #When "gateway ping failed with error code 1" is visible with command "journalctl -o cat --since '50 seconds ago' |grep testM" in "20" seconds
    ## VVV Add gateway's ip address so it is pingable again
    #* Run child "sleep 40 && ip netns exec testM_ns ip a add 192.168.99.1/24 dev testM_bridge"
    #Then "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "55" seconds
    #And "connected:full" is visible with command "nmcli -t -f STATE,CONNECTIVITY general status"


    @rhbz1034158
    @connect_testeth0 @disp
    @nmcli_monitor
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


    @rhbz998000 @rhbz1591631
    @ver+=1.10.2
    @disp
    @nmcli_device_reapply
    Scenario: nmcli - device -reapply
    * Add "ethernet" connection named "con_general" for device "eth8"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show eth8" in "45" seconds
    * Write dispatcher "99-disp" file
    * Execute "ip addr a 1.2.3.4/24 dev eth8"
    * Modify connection "con_general" changing options "+ipv4.address 1.2.3.4/24 connection.autoconnect no"
    * "Error.*" is not visible with command "nmcli device reapply eth8" in "1" seconds
    When "up" is not visible with command "cat /tmp/dispatcher.txt"
    And "con_general" is visible with command "nmcli con show -a"
    * Execute "ip addr a 1.2.3.4/24 dev eth8 || true"
    * Modify connection "con_general" changing options "-ipv4.address 1.2.3.4/24"
    * "Error.*" is not visible with command "nmcli device reapply eth8" in "1" seconds
    Then "up" is not visible with command "cat /tmp/dispatcher.txt"


    @rhbz1371920
    @ver+=1.4.0
    @ver-1.31.4
    @kill_dbus-monitor
    @device_dbus_signal
    Scenario: NM - general - device dbus signal
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG"
    * Run child "dbus-monitor --system --monitor 'sender=org.freedesktop.NetworkManager' > /tmp/dbus.txt"
    * Bring "up" connection "con_general"
    Then "NetworkManager.Device.Wired; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"
     And "NetworkManager.Device.Veth; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"
     And "DBus.Properties; member=PropertiesChanged" is visible with command "grep PropertiesChanged /tmp/dbus.txt"


    @rhbz1404594
    @ver+=1.7.1
    @kill_dbus-monitor
    @dns_over_dbus
    Scenario: NM - general - publish dns over dbus
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Run child "dbus-monitor --system --monitor 'sender=org.freedesktop.NetworkManager' > /tmp/dbus.txt"
    * Bring "up" connection "con_general"
    Then "string \"nameservers\"\s+variant\s+array\s+\[\s+string" is visible with command "grep -A 10 Dns /tmp/dbus.txt"


    @rhbz1358335
    @ver+=1.4.0
    @not_on_veth
    @NM_syslog_in_anaconda
    Scenario: NM - general - syslog in Anaconda
    Then "NetworkManager" is visible with command "grep NetworkManager /var/log/anaconda/syslog"


    @rhbz1217288
    @ver+=1.4.0
    @checkpoint_remove
    @snapshot_rollback
    Scenario: NM - general - snapshot and rollback
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * Snapshot "create" for "eth8,eth9"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * Snapshot "revert" for "eth8,eth9"
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "10" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "10" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1369716
    @ver+=1.8.0
    @checkpoint_remove
    @snapshot_rollback_all_devices
    Scenario: NM - general - snapshot and rollback all devices
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * Snapshot "create" for "all"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * Snapshot "revert" for "all"
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "15" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "15" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1369716
    @ver+=1.8.0
    @checkpoint_remove
    @snapshot_rollback_all_devices_with_timeout
    Scenario: NM - general - snapshot and rollback all devices with timeout
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * Snapshot "create" for "all" with timeout "10"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * Wait for at least "10" seconds
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "5" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1369716
    @ver+=1.8.0
    @manage_eth8 @checkpoint_remove
    @snapshot_rollback_unmanaged
    Scenario: NM - general - snapshot and rollback unmanaged
    * Execute "nmcli device set eth8 managed off"
    * Snapshot "create" for "eth8" with timeout "10"
    * Execute "nmcli device set eth8 managed on"
    When "unmanaged" is not visible with command "nmcli device show eth8" in "5" seconds
    * Wait for at least "15" seconds
    Then "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds


    @rhbz1464904
    @ver+=1.10.0
    @manage_eth8 @checkpoint_remove
    @snapshot_rollback_managed
    Scenario: NM - general - snapshot and rollback managed
    * Execute "nmcli device set eth8 managed on"
    * Snapshot "create" for "eth8" with timeout "10"
    * Execute "nmcli device set eth8 managed off"
    When "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds
    * Wait for at least "15" seconds
    Then "unmanaged" is not visible with command "nmcli device show eth8" in "5" seconds


    @rhbz1369716
    @ver+=1.8.0
    @checkpoint_remove
    @snapshot_rollback_soft_device
    Scenario: NM - general - snapshot and rollback deleted soft device
    * Add "bond" connection named "gen-bond0" for device "gen-bond"
    * Add slave connection for master "gen-bond" on device "eth8" named "gen-bond0.0"
    * Add slave connection for master "gen-bond" on device "eth9" named "gen-bond0.1"
    * Bring "up" connection "gen-bond0.0"
    * Bring "up" connection "gen-bond0.1"
    When Check slave "eth8" in bond "gen-bond" in proc
    When Check slave "eth9" in bond "gen-bond" in proc
    * Snapshot "create" for "all" with timeout "10"
    * Delete connection "gen-bond0.0"
    * Delete connection "gen-bond0.1"
    * Delete connection "gen-bond0"
    * Wait for at least "15" seconds
    Then Check slave "eth8" in bond "gen-bond" in proc
    Then Check slave "eth9" in bond "gen-bond" in proc


    @rhbz1578335
    @ver+=1.17.3
    @checkpoint_remove
    @snapshot_deleted_soft_device_dbus_link
    Scenario: NM - general - check that deleted device is also deleted from snapshot
    * Add "bond" connection named "gen-bond0" for device "gen-bond"
    * Add slave connection for master "gen-bond" on device "eth8" named "gen-bond0.0"
    * Add slave connection for master "gen-bond" on device "eth9" named "gen-bond0.1"
    * Bring "up" connection "gen-bond0.0"
    * Bring "up" connection "gen-bond0.1"
    When Check slave "eth8" in bond "gen-bond" in proc
    When Check slave "eth9" in bond "gen-bond" in proc
    * Snapshot "create" for "all"
    # next step also saves dbus path of "gen-bond" into "last"
    * Snapshot for "all" "does contain" device "gen-bond"
    * Delete connection "gen-bond0.0"
    * Delete connection "gen-bond0.1"
    * Delete connection "gen-bond0"
    When "link/ether" is not visible with command "ip a show dev gen-bond" in "10" seconds
    # next step uses previous dbus path of "gen-bond", because "gen-bond" does not exist anymore
    Then Snapshot for "all" "does not contain" device "last"
    * Snapshot "delete" for "all"


    @rhbz1819587
    @ver+=1.25.90 @rhelver+=8 @skip_in_centos
     @checkpoint_remove @load_netdevsim
    @snapshot_rollback_sriov
    Scenario: NM - general - sriov
    * Snapshot "create" for "all" with timeout "10"
    * Add "ethernet" connection named "con_general" for device "eth11" with options
          """
          connection.autoconnect no
          ip4 172.25.14.1/24
          """
    * Execute "nmcli connection modify con_general sriov.total-vfs 3"
    * Bring "up" connection "con_general"
    When "3" is visible with command "ip -c link show eth11 |grep vf |wc -l" in "5" seconds
    When "0" is visible with command "ip -c link show eth11 |grep vf |wc -l" in "15" seconds


    @ver+=1.26.0
    @rhelver+=8 @fedoraver+=31 @skip_in_centos
    @ifcfg-rh @nmstate_upstream_setup @permissive
    @nmstate_upstream
    Scenario: NM - general - nmstate
    * Restart NM
    * Execute "ip link add eth1 type veth peer name eth1peer && ip link set dev eth1peer up"
    * Execute "ip link add eth2 type veth peer name eth2peer && ip link set dev eth2peer up"
    # Run only tier1 tests
    * Execute "cd nmstate && pytest -vv -m 'tier1' --log-level=DEBUG 2>&1 | tee /tmp/nmstate.txt"
    Then "PASSED" is visible with command "grep ' PASS' /tmp/nmstate.txt"
    Then "100%" is visible with command "grep '100%' /tmp/nmstate.txt"
    Then "FAILED" is not visible with command "grep ' FAILED' /tmp/nmstate.txt"
    Then "ERROR" is not visible with command "grep ' ERROR' /tmp/nmstate.txt"


    @rhbz1433303
    @ver+=1.4.0 @skip_in_centos
    @delete_testeth0 @long @logging_info_only
    @stable_mem_consumption
    Scenario: NM - general - stable mem consumption
    * Cleanup interface "gen_br"
    * Execute "sh contrib/reproducers/repro_1433303.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "0"
    * Execute "sh contrib/reproducers/repro_1433303.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "1"
    * Execute "sh contrib/reproducers/repro_1433303.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "2"
    * Execute "sh contrib/reproducers/repro_1433303.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "3"
    * Execute "sh contrib/reproducers/repro_1433303.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "4"
    Then Check RSS writable memory in noted value "4" differs from "3" less than "300"


    @rhbz1461643 @rhbz1945282
    @ver+=1.10.0 @skip_in_centos
    @long @logging_info_only @delete_testeth0 @no_config_server @allow_veth_connections
    @stable_mem_consumption2
    Scenario: NM - general - stable mem consumption - var 2
    * Execute "sh contrib/reproducers/repro_1461643.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "0"
    * Execute "sh contrib/reproducers/repro_1461643.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "1"
    * Execute "sh contrib/reproducers/repro_1461643.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "2"
    * Execute "sh contrib/reproducers/repro_1461643.sh && sleep 10"
    * Note the output of "pmap -x $(pidof NetworkManager) |grep 'total' | awk '{print $4}'" as value "3"
    #Then Check RSS writable memory in noted value "2" differs from "1" less than "300"
    Then Check RSS writable memory in noted value "3" differs from "2" less than "300"
    # Then Check RSS writable memory in noted value "4" differs from "3" less than "50"



    @rhbz1398932
    @ver+=1.7.2
    @dummy_connection
    Scenario: NM - general - create dummy connection
    * Add "dummy" connection named "con_general" for device "br0" with options "ip4 1.2.3.4/24 autoconnect no"
    * Bring up connection "con_general"
    Then "dummy" is visible with command "ip -d l show br0 | grep dummy"
    Then "1.2.3.4/24" is visible with command "ip a s br0 | grep inet"


    @rhbz1527197
    @ver+=1.10.1
    @dummy_with_qdisc
    Scenario: NM - general - create dummy with qdisc
    * Add "dummy" connection named "con_general" for device "br0" with options
          """
          ipv4.method link-local
          ipv6.method link-local
          """
    * Bring up connection "con_general"
    * Bring up connection "con_general"
    * Bring up connection "con_general"
    * Execute "tc qdisc add dev br0 root handle 1234 fq_codel"
    * Bring up connection "con_general"
    Then "dummy" is visible with command "ip -d l show br0 | grep dummy"


    @rhbz1512316
    @ver+=1.10.1
    @do_not_touch_external_dummy
    Scenario: NM - general - do not touch external dummy device
    * Cleanup interface "dummy0"
    Then Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"
     And Execute "sh contrib/reproducers/repro_1512316.sh"


    @rhbz1337997
    @ver+=1.6.0
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_psk
    Scenario: NM - general - MACsec PSK
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring up connection "test-macsec-base"
    * Bring up connection "test-macsec"
    Then Ping "172.16.10.1" "10" times


    @rhbz1723690
    @ver+=1.18 @rhelver+=8
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_set_mtu_from_parent
    Scenario: NM - general - MACsec MTU from parent
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          802-3-ethernet.mtu 1536
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring up connection "test-macsec-base"
    * Bring up connection "test-macsec"
    #Then Ping "172.16.10.1" "10" times
    When "1536" is visible with command "ip a s macsec_veth"
    When "1504" is visible with command "ip a s macsec0"
    * Bring up connection "test-macsec-base"
    Then "1536" is visible with command "ip a s macsec_veth"
    Then "1504" is visible with command "ip a s macsec0"


    @rhbz1443114
    @ver+=1.8.0
    @restart_if_needed @non_utf_device
    @dummy_non_utf_device
    Scenario: NM - general - non UTF-8 device
    * Restart NM
    Then "nonutf" is visible with command "nmcli device"


    @rhbz1458399
    @ver+=1.12.0
    @connectivity @eth0
    @connectivity_check
    Scenario: NM - general - connectivity check
    * Add "ethernet" connection named "con_general" for device "eth0" with options "autoconnect no ipv6.method ignore"
    * Bring up connection "con_general"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
     And "full" is visible with command "nmcli  -g CONNECTIVITY g" in "70" seconds
    * Append "1.2.3.4 static.redhat.com" to file "/etc/hosts"
    * Append "1::1 static.redhat.com" to file "/etc/hosts"
    When "limited" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
     * Reset /etc/hosts
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" in "10" seconds


    @rhbz1458399
    @ver+=1.12.0
    @connectivity @delete_testeth0 @restart_if_needed
    @disable_connectivity_check
    Scenario: NM - general - disable connectivity check
    * Execute "rm -rf /etc/NetworkManager/conf.d/99-connectivity.conf"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "eth0" with options "autoconnect no ipv6.method ignore"
    * Bring up connection "con_general"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
     And "full" is visible with command "nmcli  -g CONNECTIVITY g"
    * Append "1.2.3.4 static.redhat.com" to file "/etc/hosts"
    * Append "1::1 static.redhat.com" to file "/etc/hosts"
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" for full "40" seconds


    @rhbz1394345
    @ver+=1.12.0
    @connectivity @eth0
    @per_device_connectivity_check
    Scenario: NM - general - per device connectivity check
    # Device with connectivity but low priority
    * Add "ethernet" connection named "con_general" for device "eth0" with options
          """
          ipv4.route-metric 1024
          ipv6.method ignore
          """
    * Bring up connection "con_general"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
    When "full" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
    # Device w/o connectivity but with high priority
    * Add "ethernet" connection named "con_general2" for device "eth8" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.244.4/24
          ipv4.gateway 192.168.244.1
          ipv4.route-metric 100
          ipv6.method ignore
          """
    * Bring up connection "con_general2"
    # Connection should stay at the lower priority device
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
     And Ping "boston.com"


    @rhbz1534477
    @ver+=1.12
    @connectivity @delete_testeth0 @restart_if_needed @long
    @manipulate_connectivity_check_via_dbus
    Scenario: dbus - general - connectivity check manipulation
    * Add "ethernet" connection named "con_general" for device "eth0" with options "autoconnect no ipv6.method ignore"
    * Bring up connection "con_general"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
     And "full" is visible with command "nmcli -g CONNECTIVITY g" in "70" seconds
    # VVV Turn off connectivity check
    * Execute "busctl set-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager ConnectivityCheckEnabled 'b' 0"
    #* Execute "sleep 1 && firewall-cmd --panic-on"
    * Append "1.2.3.4 static.redhat.com" to file "/etc/hosts"
    * Append "1::1 static.redhat.com" to file "/etc/hosts"
    When "false" is visible with command "busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager ConnectivityCheckEnabled"
     And "full" is visible with command "nmcli  -g CONNECTIVITY g" for full "70" seconds
    # VVV Turn on connectivity check
    * Execute "busctl set-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager ConnectivityCheckEnabled 'b' 1"
    When "true" is visible with command "busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager ConnectivityCheckEnabled"
     And "limited" is visible with command "nmcli  -g CONNECTIVITY g" in "100" seconds
     * Reset /etc/hosts
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" in "70" seconds


    @rhbz1442361
    @ver+=1.8.3
    @tuntap
    @keep_external_device_enslaved_on_down
    Scenario: NM - general - keep external device enslaved on down
    # Check that an externally configure device is not released from
    # its master when brought down externally
    * Add "bridge" connection named "con_general2" for device "brX" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method ignore
          """
    * Bring "up" connection "con_general2"
    * Execute "ip tuntap add mode tap tap0"
    * Execute "ip link set tap0 master brX"
    * Execute "ip link set tap0 up"
    * Execute "sleep 2"
    * Execute "ip link set tap0 down"
    Then "master brX" is visible with command "ip link show tap0" for full "5" seconds


    @ver+=1.10
    @add_testeth8 @eth8_disconnect @ifcfg-rh
    @overtake_external_device
    Scenario: nmcli - general - overtake external device
    * Execute "ip add add 1.2.3.4/24 dev eth8"
    When "No such file" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-eth8"
     And "eth8\s+ethernet\s+connected" is visible with command "nmcli d" in "15" seconds
     And "dhclient" is not visible with command "ps aux| grep client-eth8"
    * Modify connection "eth8" changing options "ipv4.method auto"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show eth8" in "45" seconds
     And "BOOTPROTO=dhcp" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-eth8"
     And "dhclient" is visible with command "ps aux| grep dhclient-eth8"
     And "192.168" is visible with command "ip a s eth8" in "20" seconds


    @rhbz1487702
    @ver+=1.10
    @no_config_server @restart_if_needed
    @wait_10s_for_flappy_carrier
    Scenario: NM - general - wait for flappy carrier up to 10s
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          802-3-ethernet.mtu 9000
          """
    * Prepare simulated test "testG" device
    * Run child "nmcli con up con_general"
    * Execute "sleep 0.5 && ip link set testG down"
    * Execute "sleep 8"
    * Execute "ip link set testG up"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds


    @rhbz1541031
    @ver+=1.12
    @not_with_systemd_resolved
    @remove_custom_cfg
    @resolv_conf_overwrite_after_stop
    Scenario: NM - general - overwrite resolv conf after stop
    * Append "[main]" to file "/etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Append "rc-manager=unmanaged" to file "/etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Append "nameserver 1.2.3.4" to file "/etc/resolv.conf"
    * Stop NM
    When "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf" in "3" seconds
    * Start NM
    Then "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf" in "3" seconds


    @rhbz1593519
    @ver+=1.12
    @remove_custom_cfg
    @NM_starts_with_incorrect_logging_config
    Scenario: NM - general - nm starts even when logging is incorrectly configured
    * Stop NM
    * Execute "echo -e '[logging]\nlevel=DEFAULT:WARN,TEAM:TRACE' > /etc/NetworkManager/conf.d/99-xxcustom.conf;"
    Then Start NM


    @rhbz1588041
    @ver+=1.12
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_send-sci_by_default
    Scenario: NM - general - MACsec send-sci option should be true by default
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    Then "yes" is visible with command "nmcli -f macsec.send-sci con show test-macsec"
    * Bring up connection "test-macsec-base"
    * Bring up connection "test-macsec"
    Then "send_sci on" is visible with command "ip macsec show macsec0"


    @rhbz1555281
    @ver+=1.10.7
    @libnm_async_tasks_cancelable
    Scenario: NM - general - cancelation of libnm async tasks (add_connection_async)
    * Cleanup connection "con_general"
    Then Execute "/usr/bin/python contrib/reproducers/repro_1555281.py con_general"


    @rhbz1643085 @rhbz1642625
    @ver+=1.14
    @libnm_async_activation_cancelable_no_crash
    Scenario: NM - general - cancelation of libnm async activation - should not crash
    * Cleanup connection "con_general"
    Then Execute "/usr/bin/python contrib/reproducers/repro_1643085.py con_general eth8"

    @rhbz1614691
    @ver+=1.12
    @nmcli_monitor_assertion_con_up_down
    Scenario: NM - general - nmcli monitor asserts error when connection is activated or deactivated
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Execute "nmcli monitor &> /tmp/nmcli_monitor_out & pid=$!; sleep 10; kill $pid" without waiting for process to finish
    * Bring "up" connection "con_general"
    * Wait for at least "1" seconds
    * Bring "down" connection "con_general"
    * Wait for at least "10" seconds
    Then "should not be reached" is not visible with command "cat /tmp/nmcli_monitor_out"


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_rollback
    Scenario: NM - general - libnm snapshot and rollback
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 0 eth8 eth9" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * "ERROR" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py rollback" in "0" seconds
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "45" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "45" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_rollback_all_devices
    Scenario: NM - general - libnm snapshot and rollback all devices
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 0" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * "ERROR" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py rollback" in "0" seconds
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "45" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "45" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_rollback_all_devices_with_timeout
    Scenario: NM - general - libnm snapshot and rollback all devices with timeout
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 10" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * Wait for at least "10" seconds
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "45" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "45" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1496739
    @ver+=1.12
    @manage_eth8  @checkpoint_remove
    @libnm_snapshot_rollback_unmanaged
    Scenario: NM - general - libnm snapshot and rollback unmanaged
    * Execute "nmcli device set eth8 managed off"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 10 eth8" in "0" seconds
    * Execute "nmcli device set eth8 managed on"
    When "unmanaged" is not visible with command "nmcli device show eth8" in "5" seconds
    * Wait for at least "15" seconds
    Then "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds


    @rhbz1496739
    @ver+=1.12
    @manage_eth8 @checkpoint_remove
    @libnm_snapshot_rollback_managed
    Scenario: NM - general - libnm snapshot and rollback managed
    * Execute "nmcli device set eth8 managed on"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 10 eth8" in "0" seconds
    * Execute "nmcli device set eth8 managed off"
    When "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds
    * Wait for at least "15" seconds
    Then "unmanaged" is not visible with command "nmcli device show eth8" in "5" seconds


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_rollback_soft_device
    Scenario: NM - general - snapshot and rollback deleted soft device
    * Add "bond" connection named "gen-bond0" for device "gen-bond"
    * Add slave connection for master "gen-bond" on device "eth8" named "gen-bond0.0"
    * Add slave connection for master "gen-bond" on device "eth9" named "gen-bond0.1"
    * Bring "up" connection "gen-bond0.0"
    * Bring "up" connection "gen-bond0.1"
    When Check slave "eth8" in bond "gen-bond" in proc
    When Check slave "eth9" in bond "gen-bond" in proc
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 10" in "0" seconds
    * Delete connection "gen-bond0.0"
    * Delete connection "gen-bond0.1"
    * Delete connection "gen-bond0"
    * Wait for at least "15" seconds
    Then Check slave "eth8" in bond "gen-bond" in proc
    Then Check slave "eth9" in bond "gen-bond" in proc


    @rhbz1574565
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_destroy_after_rollback
    Scenario: NM - general - snapshot and destroy checkpoint
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 5" in "0" seconds
    Then "Succes" is visible with command "sleep 1; contrib/gi/libnm_snapshot_checkpoint.py destroy --last" in "0" seconds
    Then "Failed" is visible with command "CP=$(contrib/gi/libnm_snapshot_checkpoint.py create 5); sleep 7; contrib/gi/libnm_snapshot_checkpoint.py destroy $CP" in "0" seconds


    @rhbz2035519
    @ver+=1.36
    @checkpoint_remove
    @libnm_snapshot_reattach_unmanaged_ports_to_bridge
    Scenario: NM - general - reatach unmanaged ports to bridge after rollback
    # do not use names prefixed "test", we need devices unmanaged
    * Prepare simulated test "portXa" device without DHCP
    * Prepare simulated test "portXb" device without DHCP
    * Prepare simulated test "portXc" device without DHCP
    * Add "bridge" connection named "br12" for device "br0" with options
          """
          ipv4.method disabled
          ipv6.method disabled
          autoconnect no
          """
    * Add "bridge" connection named "br15" for device "br0" with options
          """
          ipv4.method disabled
          ipv6.method disabled
          autoconnect no
          """
    * Add "ethernet" connection named "br15-slave1" for device "portXa" with options "master br15 autoconnect no"
    # unmanage to be 100% sure
    #* Execute "nmcli dev set portXb managed no"
    #* Execute "nmcli dev set portXc managed no"
    * Bring "up" connection "br15-slave1"
    * Execute "ip link set portXb master br0"
    * Execute "ip link set portXc master br0"
    * "Failed" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py create 0" in "0" seconds
    * Bring "up" connection "br12"
    * Execute "ip link set portXb master br0"
    * Execute "ip link set portXc master br0"
    * Wait for at least "1" seconds
    * "ERROR" is not visible with command "contrib/gi/libnm_snapshot_checkpoint.py rollback" in "0" seconds
    Then "portXa" is visible with command "bridge link"
    Then "portXb" is visible with command "bridge link"
    Then "portXc" is visible with command "bridge link"


    @rhbz1553113
    @ver+=1.12
    @autoconnect_no_secrets_prompt
    Scenario: NM - general - count number of password prompts with autoconnect yes and no secrets provided
    * Add "ethernet" connection named "con_general" for device "eth5" with options
          """
          802-1x.identity test
          802-1x.password-flags 2
          802-1x.eap md5
          connection.autoconnect no
          """
    * Wait for at least "2" seconds
    * Execute "contrib/nm_agent/nm_agent_prompt_counter.sh start"
    * Wait for at least "2" seconds
    * Modify connection "con_general" changing options "connection.autoconnect yes"
    * Wait for at least "2" seconds
    Then "PASSWORD_PROMPT_COUNT='1'" is visible with command "contrib/nm_agent/nm_agent_prompt_counter.sh stop"


    @rhbz1578436
    @ver+=1.14
    @rhelver+=8 @fedoraver+=31 @ifcfg-rh
    @ifup_ifdown_scripts
    Scenario: NM - general - test ifup (ifdown) script uses NM
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.address 1.2.3.4/24
          ipv4.method manual
          """
    * Execute "/usr/sbin/ifup con_general"
    When "connected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    * Execute "/usr/sbin/ifdown con_general"
    Then "disconnected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is not visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is not visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is not visible with command "ip a s eth8" in "5" seconds


    @rhbz1954607
    @ver+=1.32.2
    @rhelver+=9 @ifcfg-rh
    @ifup_ifdown_scripts_new_conn_from_ifcfg
    Scenario: NM - general - test ifup (ifdown) loads new connection from ifcfg file of same name automagically
    Given "con_general" is not visible with command "nmcli c show"
    * Execute """echo -e 'NAME=con_general\nTYPE=Ethernet\nDEVICE=eth8\nBOOTPROTO=static\nIPADDR=1.2.3.4\nPREFIX=24\nIPV6=no\nONBOOT=no' >> /etc/sysconfig/network-scripts/ifcfg-con_general"""
    * Execute "/usr/sbin/ifup con_general"
    When "connected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    * Execute "/usr/sbin/ifdown con_general"
    Then "disconnected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is not visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is not visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is not visible with command "ip a s eth8" in "5" seconds


    @rhbz1954607
    @ver+=1.32.2
    @rhelver+=9 @keyfile
    @ifup_ifdown_keyfile
    Scenario: NM - general - test ifup (ifdown) script uses NM with keyfile-defined connection
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.address 1.2.3.4/24
          ipv4.method manual
          """
    * Execute "/usr/sbin/ifup con_general"
    When "connected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    * Execute "/usr/sbin/ifdown con_general"
    Then "disconnected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is not visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is not visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is not visible with command "ip a s eth8" in "5" seconds


    @rhbz1954607
    @ver+=1.32.2
    @rhelver+=9 @keyfile
    @ifup_ifdown_keyfile_new_conn_from_ifcfg
    Scenario: NM - general - test ifup (ifdown) loads new connection from ifcfg file of same name automagically
    Given "con_general" is not visible with command "nmcli c show"
    * Cleanup connection "con_general"
    * Execute """echo -e 'NAME=con_general\nTYPE=Ethernet\nDEVICE=eth8\nBOOTPROTO=static\nIPADDR=1.2.3.4\nPREFIX=24\nIPV6=no\nONBOOT=no' >> /etc/sysconfig/network-scripts/ifcfg-con_general"""
    * Execute "/usr/sbin/ifup con_general"
    When "connected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    * Execute "/usr/sbin/ifdown con_general"
    Then "disconnected" is visible with command "nmcli -f GENERAL.STATE device show eth8" in "5" seconds
     And "1.2.3.4/24" is not visible with command "nmcli -f IP4.ADDRESS device show eth8" in "5" seconds
     And "activated" is not visible with command "nmcli -f GENERAL.STATE connection show con_general"
     And "1.2.3.4/24" is not visible with command "ip a s eth8" in "5" seconds


    @rhbz1649704
    @ver+=1.14
    @not_with_systemd_resolved
    @resolv_conf_search_limit
    Scenario: NM - general - save more than 6 search domains in resolv.conf
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.dns-search $(echo {a..g}.noexist.redhat.com, | tr -d ' ')
          """
    * Bring "up" connection "con_general"
    Then "7" is visible with command "nmcli -f ipv4.dns-search con show con_general | grep -o '\.noexist\.redhat\.com' | wc -l"
     And "7" is visible with command "cat /etc/resolv.conf | grep -o '\.noexist\.redhat\.com' | wc -l"


    @rhbz1658217
    @ver+=1.14 @rhelver+=8
    @captive_portal @connectivity
    @captive_portal_detection
    Scenario: NM - general - portal is detected by NM
    Given "full" is visible with command "nmcli -f CONNECTIVITY general" in "20" seconds
    * Execute "echo NOK > /tmp/python_http/test/rhel-networkmanager.txt"
    Then "portal" is visible with command "nmcli -f CONNECTIVITY general" in "30" seconds
    * Execute "echo -n OK > /tmp/python_http/test/rhel-networkmanager.txt"
    Then "full" is visible with command "nmcli -f CONNECTIVITY general" in "30" seconds
    * Execute "rm -f /tmp/python_http/test/rhel-networkmanager.txt"
    Then "portal" is visible with command "nmcli -f CONNECTIVITY general" in "40" seconds


    @rhbz1588995
    @ver+=1.14
    @editor_print_info
    Scenario: nmcli - general - connection editor print info
    * Open editor for a new connection
    Then "Valid connection types:.*Enter connection type:" appeared in editor
    * Submit "ethernet" in editor
    Then "Type 'help' or '\?' for available commands\." appeared in editor
    Then "Type 'print' to show all the connection properties\." appeared in editor
    Then "Type 'describe \[<setting>\.<prop>\]' for detailed property description." appeared in editor
    * Submit "print" in editor
    Then "connection.id:" appeared in editor
    * Quit editor


    @rhbz1588952 @rhbz1654062
    @ver+=1.18.4
    @nmcli_novice_print_types
    Scenario: nmcli - general - print availiable connection types in connection assistant
    * Open wizard for adding new connection
    * Expect "Connection type"
    * Submit "<double_tab>"
    Then Expect "adsl.*bluetooth.*bond.*bond-slave.*bridge"
	* Send "t" in editor
    * Submit "<double_tab>"
    Then Expect "team\s+team-slave\s+tun"


    @rhbz1671200
    @ver+=1.14
    @nmcli_modify_altsubject-matches
    Scenario: nmcli - general - modification of 802-1x.altsubject-matches sometimes leads to nmcli SIGSEGV
    * Add "ethernet" connection named "con_general" for device "\*" with options
          """
          autoconnect no
          802-1x.eap peap
          802-1x.identity aaa
          802-1x.phase2-auth mschap
          """
    Then Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "
     And Execute "nmcli con mod con_general 802-1x.altsubject-matches '/something/very/long/should/be/there/at/least/fortyfour/characters' "


    @rhbz1689054
    @ver+=1.16
    @libnm_get_dns_crash
    Scenario: nmcli - general - libnm crash when getting nmclient.props.dns_configuration
    Then Execute "/usr/bin/python contrib/reproducers/repro_1689054.py"


    @rhbz2027674
    @ver+=1.37.2
    @ver+=1.36.3
    @libnm_nmclient_init_crash
    Scenario: nmcli - general - libnm crash when cancelling initialization of NMClient
    Then Execute "/usr/bin/python contrib/reproducers/repro_2027674.py"


    @rhbz1697858
    @rhelver-=7 @rhel_pkg @fedoraver-=0
    @remove_custom_cfg
    @keyfile_nmconnection_extension
    Scenario: NM - general - keyfile does not have .nmconnection extension
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo 'plugins=keyfile,ifcfg-rh' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
    Then "/etc/NetworkManager/system-connections/con_general" is file
     And Path "/etc/NetworkManager/system-connections/con_general.nmconnection" does not exist


    @rhbz1697858
    @ver+=1.19
    @rhelver+=8 @rhel_pkg @remove_custom_cfg
    @keyfile_nmconnection_extension
    Scenario: NM - general - keyfile does have .nmconnection extension
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo 'plugins=keyfile,ifcfg-rh' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
    Then "/etc/NetworkManager/system-connections/con_general.nmconnection" is file
     And Path "/etc/NetworkManager/system-connections/con_general" does not exist


    @rhbz1697858
    @ver+=1.14
    @not_with_rhel_pkg @remove_custom_cfg @restart_if_needed
    @keyfile_nmconnection_extension
    Scenario: NM - general - keyfile does have .nmconnection extension
    * Execute "echo '[main]' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo 'plugins=keyfile,ifcfg-rh' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
    Then "/etc/NetworkManager/system-connections/con_general.nmconnection" is file
     And Path "/etc/NetworkManager/system-connections/con_general" does not exist


     @rhbz1674545
     @ver+=1.19
     @keyfile_cleanup @remove_custom_cfg
     @move_keyfile_to_usr_lib_dir
     Scenario: NM - general - move keyfile to usr lib dir and check deletion
     * Execute "echo '[main]' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
     * Execute "echo 'plugins=keyfile,ifcfg-rh' >> /etc/NetworkManager/conf.d/99-xxcustom.conf"
     * Restart NM
     * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
     * Note the output of "nmcli -g connection.uuid connection show con_general"
     * Execute "mv /etc/NetworkManager/system-connections/con_general* /tmp/"
     * Delete connection "con_general"
     When "con_general" is not visible with command "nmcli connection"
     * Execute "mv /tmp/con_general* /usr/lib/NetworkManager/system-connections/"
     * Execute "nmcli con reload"
     When "con_general" is visible with command "nmcli connection"
      And Noted value is visible with command "nmcli connection"
     * Delete connection "con_general"
     Then "con_general" is not visible with command "nmcli connection"
      And "con_general" is visible with command "ls /usr/lib/NetworkManager/system-connections/"
     # And "/etc/NetworkManager/system-connections/<noted_value>.nmmeta" is symlink with destination "/dev/null"
     #* Execute "nmcli con reload"
     #Then "con_general" is not visible with command "nmcli connection"
     #And "con_general" is visible with command "ls /usr/lib/NetworkManager/system-connections/"
     #And "/etc/NetworkManager/system-connections/<noted_value>.nmmeta" is symlink with destination "/dev/null"


    @rhbz1674545
    @ver+=1.19
    @remove_custom_cfg @restart_if_needed @keyfile_cleanup
    @no_uuid_in_keyfile_in_usr_lib_dir
    Scenario: NM - general - read keyfiles without connection.uuid in usr lib dir
    * Execute "echo -e '[main]\nplugins=keyfile,ifcfg-rh' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Execute "echo -e '[connection]\nid=con_general\ntype=ethernet\nautoconnect=false\npermissions=\n\n[ethernet]\nmac-address-blacklist=\n\n[ipv4]\ndns-search=\nmethod=auto\n\n[ipv6]\naddr- gen-mode=stable-privacy\ndns-search=\nmethod=auto' > /usr/lib/NetworkManager/system-connections/con_general.nmconnection"
    * Execute "sudo chmod go-rwx /usr/lib/NetworkManager/system-connections/con_general.nmconnection"
    * Restart NM
    When "con_general" is visible with command "nmcli connection" in "10" seconds
    * Note the output of "nmcli -g connection.uuid connection show con_general"
    * Delete connection "con_general"
    Then "con_general" is not visible with command "nmcli connection"
    And "con_general" is visible with command "ls /usr/lib/NetworkManager/system-connections/"
    #And "/etc/NetworkManager/system-connections/<noted_value>.nmmeta" is symlink with destination "/dev/null"
    #* Execute "nmcli con reload"
    #Then "con_general" is not visible with command "nmcli connection"
    #And "con_general" is visible with command "ls /usr/lib/NetworkManager/system-connections/"
    #And "/etc/NetworkManager/system-connections/<noted_value>.nmmeta" is symlink with destination "/dev/null"


    @rhbz1708660
    @ver+=1.18
    @busctl_LoadConnections_relative_path
    Scenario: NM - general - busctl LoadConnections does not accept relative paths
    * Cleanup connection "con_general"
    When "bas false 1 \"contrib/profiles/eth8-con.keyfile\"" is visible with command "busctl call org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Settings org.freedesktop.NetworkManager.Settings LoadConnections as 1 contrib/profiles/eth8-con.keyfile"
    * Execute "cp contrib/profiles/eth8-con.keyfile /etc/NetworkManager/system-connections/con_general"
    * Execute "chmod 0600 /etc/NetworkManager/system-connections/con_general"
    Then "bas true 0" is visible with command "busctl call org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Settings org.freedesktop.NetworkManager.Settings LoadConnections as 1 /etc/NetworkManager/system-connections/con_general"
     And "con_general" is visible with command "nmcli connection show"


    @rhbz1709849
    @ver+=1.18
    @secret_key_reset @restart_if_needed
    @secret_key_file_permissions
    Scenario: NM - general - check secret_key file permissions
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "eth8" with options "ipv4.dhcp-client-id stable"
    Then "-rw-------" is visible with command "ls -l /var/lib/NetworkManager/secret_key" in "5" seconds


    @rhbz1541013
    @ver+=1.19
    @remove_custom_cfg @restart_if_needed
    @invalid_config_warning
    Scenario: NM - general - warn about invalid config options
    * Execute "echo -e '[main]\nsomething_nonexistent = some_value' > /etc/NetworkManager/conf.d/99-xxcustom.conf;"
    * Restart NM
    * Note NM log
    Then Noted value contains "<warn>[^<]*config: unknown key 'something_nonexistent' in section \[main\] of file"


    @rhbz1677068
    @ver+=1.20
    @libnm_addconnection2_block_autoconnect
    Scenario: NM - general - libnm addconnection2 BLOCK_AUTOCONNECT flag
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect yes"
    * Bring "down" connection "con_general"
    When "con_general" is not visible with command "nmcli -g name con show --active" in "3" seconds
    * Clone connection "con_general" to "con_general2" using libnm
    Then "con_general2" is visible with command "nmcli -g name con show --active" in "5" seconds
    * Delete connection "con_general2"
    * Clone connection "con_general" to "con_general2" using libnm with flags "BLOCK_AUTOCONNECT,TO_DISK"
    Then "con_general2" is not visible with command "nmcli -g name con show --active" for full "3" seconds
    # check persistency of BLOCK_AUTOCONNECT flag
    * Update connection "con_general2" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm
    Then "con_general2" is not visible with command "nmcli -g name con show --active" for full "3" seconds


    @rhbz1677068
    @ver+=1.20
    @libnm_update2_block_autoconnect
    Scenario: NM - general - libnm update2 BLOCK_AUTOCONNECT flag
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Update connection "con_general" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm with flags "BLOCK_AUTOCONNECT"
    Then "con_general" is not visible with command "nmcli -g name con show --active" for full "3" seconds
    # check persistency of BLOCK_AUTOCONNECT flag
    * Update connection "con_general" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm
    Then "con_general" is not visible with command "nmcli -g name con show --active" for full "3" seconds
    * Add "ethernet" connection named "con_general2" for device "eth8" with options "autoconnect no"
    * Update connection "con_general2" changing options "SETTING_CONNECTION_AUTOCONNECT:bool:True" using libnm
    Then "con_general2" is visible with command "nmcli -g name con show --active" in "5" seconds


    @rhbz1677070
    @ver+=1.20
    @libnm_update2_no_reapply
    Scenario: NM - general - libnm update2 NO_REAPPLY flag
    * Add "ethernet" connection named "con_general" for device "eth8" with options "connection.metered yes"
    * Bring "up" connection "con_general"
    When "u 1" is visible with command " busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:eth8//p') org.freedesktop.NetworkManager.Device Metered"
    * Update connection "con_general" changing options "SETTING_CONNECTION_METERED:int:2" using libnm with flags "TO_DISK"
    Then "u 2" is visible with command " busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:eth8//p') org.freedesktop.NetworkManager.Device Metered"
    * Update connection "con_general" changing options "SETTING_CONNECTION_METERED:int:1" using libnm with flags "TO_DISK,NO_REAPPLY"
    Then "u 2" is visible with command " busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:eth8//p') org.freedesktop.NetworkManager.Device Metered"
    * Execute "nmcli device reapply eth8"
    Then "u 1" is visible with command " busctl get-property org.freedesktop.NetworkManager $(nmcli -g DBUS-PATH,DEVICE device | sed -n 's/:eth8//p') org.freedesktop.NetworkManager.Device Metered"


    @rhbz1782642
    @ver+=1.22
    @dhclient_DHCP @manage_eth8 @eth8_disconnect @kill_dhclient_custom
    @nmcli_general_unmanaged_device_dhclient_fail
    Scenario: NM - general - dhclient should not fail on unmanaged device
    * Execute "nmcli device disconnect eth8 || true"
    * Execute "nmcli device set eth8 managed no"
    * Execute "dhclient -v -pf /tmp/dhclient_custom.pid eth8"


    @rhbz1762011
    @ver+=1.22
    @remove_custom_cfg @restart_if_needed
    @no_user_control
    Scenario: NM - general - root only control
    * Execute "echo -e '[main]\nauth-polkit=root-only' > /etc/NetworkManager/conf.d/99-xxcustom.conf"
    * Restart NM
    # User test has been created in envsetup.py
    Then "org.freedesktop.NetworkManager.network-control\s+no" is visible with command "sudo -u test nmcli gen perm"
    Then " auth" is not visible with command "sudo -u test nmcli gen perm"


    @rhbz1810153
    @ver+=1.22.0
    @clean_device_state_files
    Scenario: NM - general - clean device state files
    * Run child "for i in $(seq 1 120); do ip link delete dummy0 &>/dev/null; ip link add dummy0 type bridge; ip addr add 1.1.1.1/2 dev dummy0;  ip link set dummy0 up; sleep 0.25; done; ip link del dummy0"
    When "4[0-9]" is visible with command "ls /run/NetworkManager/devices/ |wc -l" in "40" seconds
    Then "2[5-9]" is visible with command "ls /run/NetworkManager/devices/ |wc -l" in "60" seconds
    # VVV Check that dummy0 is not present anymore as next tests can be affected
    When "dummy0" is not visible with command "ip a s" in "30" seconds
    When "dummy0" is not visible with command "ip a s" in "30" seconds
    When "dummy0" is not visible with command "ip a s" in "30" seconds
    # And we need another one Sept/2021
    When "dummy0" is not visible with command "ip a s" in "30" seconds


    @rhbz1758550
    @ver+=1.18.6
    @manage_eth8 @eth8_disconnect @tshark @dhclient_DHCP
    @NM_merge_dhclient_conditionals
    Scenario: NM - general - merge dhcp conditionals
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Execute "echo -e 'if not option domain-name = "example.org" {\nprepend domain-name-servers 127.0.0.1;}' > /etc/dhcp/dhclient-eth8.conf"
    * Bring "up" connection "con_general"
    Then "prepend domain-name-servers 127.0.0.1" is visible with command "cat /var/lib/NetworkManager/dhclient-eth8.conf"


    @rhbz1711215
    @ver+=1.25 @rhelver+=8
    @remove_custom_cfg @performance
    @NM_performance_dhcp_on_existing_veths
    Scenario: NM - general - create and activate 100 connections in 6 seconds on existing veths
    # We need up to 1/4 of dhcpd servers to be able to handle the amount of
    # networks in the max time. If we have just one there seems to be some
    # retransmissions needed in DHCP server so we know nothing about NM performance.
    Then Activate "100" devices in "6" seconds


    @rhbz1868982
    @eth0 @eth10_disconnect
    @ver+=1.25 @rhelver+=8
    @nmcli_shows_correct_routes
    Scenario: NM - general - nmclic shows correct routes
    * Bring "up" connection "testeth10"
    When "default" is visible with command "ip r" in "20" seconds
    When "default" is visible with command "ip -6 r" in "20" seconds
    # dev lo is not managed by NM
    * Note the output of "ip -6 r | grep -v 'dev lo' | wc -l" as value "ip6_route"
    # ff00::/8 are not shown in `ip -6 r`
    * Note the output of "nmcli | grep route6 | grep -v 'ff00::/8' |wc -l" as value "nmcli6_route"
    * Note the output of "ip r |wc -l" as value "ip4_route"
    * Note the output of "nmcli |grep route4 |wc -l" as value "nmcli4_route"
    Then Check noted values "ip6_route" and "nmcli6_route" are the same
    Then Check noted values "ip4_route" and "nmcli4_route" are the same


    @rhbz1870059
    @ver+=1.33
    @nmcli_show_gateways
    Scenario: nmcli - general - show default gateways when called without arguments
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          ipv4.method static
          ipv4.addresses 192.168.122.253/24
          ipv4.gateway 192.168.122.96
          ipv6.method static
          ipv6.addresses 2607:f0d0:1002:51::4/64
          ipv6.gateway 2607:f0d0:1002:51::1
          """
    * Bring up connection "con_general"
    * "default via 192.168.122.96" is visible with command "ip -4 r show default"
    * "default via 2607:f0d0:1002:51::1" is visible with command "ip -6 r show default"
    * "via 192.168.122.96" is visible with command "nmcli"
    * "via 2607:f0d0:1002:51::1" is visible with command "nmcli"


    @rhbz1882380
    @ver+=1.27 @rhelver+=8
    @nm_device_get_applied_connection_user_allowed
    Scenario: NM - general - NM Device get applied connection can be used by user
    Then "not authorized" is not visible with command "sudo -u test busctl call org.freedesktop.NetworkManager $(nmcli -g DEVICE,DBUS-PATH device | sed -n 's/^eth0://p') org.freedesktop.NetworkManager.Device GetAppliedConnection u 0"


    @rhbz1890634
    @ver+=1.26
    @user_cannot_reapply_roots_connection
    Scenario: NM - general - user cannot reapply root's connection
    * Execute "ip link del dummy0 || true"
    * Add "dummy" connection named "con_general" for device "dummy0" with options
          """
          ipv4.method manual
          ipv4.addresses 1.2.3.4/24
          connection.permissions 'user:root'
          """
    * Bring up connection "con_general"
    Then "no permission" is visible with command "sudo -u test nmcli d reapply dummy0"


    @rhbz1820770
    @ver+=1.32.2
    @eth0 @restore_hostname @kill_children
    @nmcli_general_assign_valid_hostname_to_device
    Scenario: NM - general - assign - valid - hostname - to - device
    * Bring "down" connection "testeth0"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Prepare simulated test "testX6" device without DHCP
    * Execute "ip -n testX6_ns addr add dev testX6p fd01::1/64"
    * Run child "ip netns exec testX6_ns dnsmasq --bind-interfaces --interface testX6p --pid-file=/tmp/testX6_ns.pid  --host-record=deprecated1,fd01::91 --host-record=validhostname,fd01::92 --host-record=deprecated2,fd01::93" without shell
    * Run child "ip netns exec testX6_ns radvd -n -C contrib/ipv6/radvd3.conf" without shell
    * Add "ethernet" connection named "con_ipv6" for device "testX6" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method auto
          """
    * Bring "up" connection "con_ipv6"
    * Execute "ip addr add dev testX6 fd01::91/128 valid_lft forever preferred_lft 0"
    * Execute "ip addr add dev testX6 fd01::92/128"
    * Execute "ip addr add dev testX6 fd01::93/128 valid_lft forever preferred_lft 0"
    Then "fd01::92" is visible with command "ip address show testX6" in "10" seconds
        And "validhostname" is visible with command "hostname" in "20" seconds


    @rhbz2037411
    @ver+=1.35.7
    @permissive @eth0
    @nmcli_route_dump
    Scenario: nmcli - general - NM does not wait for route dump
    * Add "dummy" connection named "dummy0" for device "dummy1" with options "ip4 172.26.1.1/24 autoconnect no"
    * Bring "up" connection "dummy0"
    * Execute "ip route add blackhole 172.25.1.0/24 proto bird"
    * Execute "nmcli -g uuid connection show --active | xargs nmcli -w 10 connection down"
    When "succeeded" is visible with command "journalctl -u NetworkManager --no-pager -n 10"
    Then "wait for ACK" is not visible with command "journalctl -u NetworkManager --no-pager -n 1000"
     And "blackhole" is visible with command "ip route"
