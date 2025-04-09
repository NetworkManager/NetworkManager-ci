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


    @skip_step_skip
    Scenario: Skip if next step fail check - SKIP
    * Skip if next step fails:
    * Execute "false"


    @skip_step_pass
    Scenario: Skip if next step fail check - PASS
    * Skip if next step fails:
    * Execute "true"


    @last_copr_build_check
    Scenario: Check that latest copr build is not failed
    Given NetworkManager is installed from a copr repo
    Then Check last copr build is successful


    @xfail @crash @skip_in_centos
    @crashing_NM_binary
    Scenario: Dummy scenario that is supposed to test crash embeding
    * Execute "sysctl kernel.core_pattern"
    # the test should fail, because @xfail reverts returncode
    Then Check coredump is not found in "60" seconds


    @logging
    @nmcli_logging
    Scenario: NM - general - setting log level and autocompletion
    Then "DEBUG\s+ERR\s+INFO\s+.*TRACE\s+WARN" is visible with tab after "nmcli general logging level "
    * Set logging for "all" to "INFO"
    Then "INFO\s+[^:]*$" is visible with command "nmcli general logging"
    * Set logging for "default,WIFI:ERR" to " "
    Then "INFO\s+[^:]*,WIFI:ERR,[^:]*$" is visible with command "nmcli general logging"


    @rhbz1212196
    @reduce_logging
    Scenario: NM - general - reduce logging
     * Add "bond" connection named "gen-bond0" for device "gen-bond"
    Then "preparing" is not visible with command "journalctl -u NetworkManager --since '2 min ago'   |grep '<info> .*gen-bond' |grep 'preparing device'"
    Then "exported as" is not visible with command "journalctl -u NetworkManager --since '2 min ago' |grep '<info> .*gen-bond' |grep 'exported as'"
    Then "Stage" is not visible with command "journalctl -u NetworkManager --since '2 min ago'       |grep '<info> .*gen-bond' |grep 'Stage'"


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
    * Execute "nmcli general hostname walderon"
    Then "walderon" is visible with command "cat /etc/hostname"


    @ver+=1.4.0
    @restore_hostname @eth0
    @pull_hostname_from_dhcp
    Scenario: nmcli - general - pull hostname from DHCP
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
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
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv6.method ignore
          ipv4.method auto
          """
    * Modify connection "con_general" changing options "ipv4.address 172.25.13.1/30 ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo-bar" is visible with command "hostnamectl --transient" in "60" seconds


    @rhbz2166711
    @ver/rhel/8/6+=1.36.0.13
    @ver/rhel/8/7+=1.40.0.6
    @ver/rhel/8+=1.40.16.1
    @ver+=1.42.2
    @restore_hostname @eth0
    @kill_dnsmasq_ip6
    @pull_hostname_from_dns_static_ipv6
    Scenario: nmcli - general - pull hostname from DNS (static IPv6 address)
    * Prepare simulated test "testG" device without DHCP
    * Execute "ip -n testG_ns addr add dev testGp fd42::1/64"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Run child "ip netns exec testG_ns dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --bind-interfaces --interface testGp --host-record=client42,fd42::42" without shell
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method manual
          ipv6.address fd42::42/64
          ipv6.dns fd42::1
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "30" seconds
    Then "client42" is visible with command "hostnamectl --transient" in "30" seconds


    @rhbz2166711
    @ver/rhel/8/6+=1.36.0.13
    @ver/rhel/8/7+=1.40.0.6
    @ver/rhel/8+=1.40.16.1
    @ver+=1.42.2
    @restore_hostname @eth0
    @kill_dnsmasq_ip6
    @pull_hostname_from_dns_dynamic_ipv6
    Scenario: nmcli - general - pull hostname from DNS (dynamic IPv6 address)
    * Prepare simulated test "testG" device without DHCP
    * Execute "ip -n testG_ns addr add dev testGp fd01::1/64"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Run child "ip netns exec testG_ns dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --bind-interfaces --interface testGp --dhcp-range=fd01::100,fd01::200 --enable-ra --dhcp-host 00:11:22:33:44:55,client001122334455" without shell
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv4.method disabled
          ipv6.method auto
          ethernet.cloned-mac-address 00:11:22:33:44:55
          hostname.from-dhcp no
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "30" seconds
    Then "client001122334455" is visible with command "hostnamectl --transient" in "30" seconds


    @rhbz1970335
    @ver+=1.30.0
    @rhelver+=8
    @internal_DHCP @dhcpd
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
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no ipv4.method auto"
    * Add "ethernet" connection named "con_general2" for device "testX6" with options "ipv6.method auto"
    * Modify connection "con_general" changing options "ipv4.address 172.25.13.1/30 ethernet.cloned-mac-address 00:11:22:33:44:55"
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show testX6" in "25" seconds
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Wait for "10" seconds
    * Execute "ip netns exec testG_ns kill -SIGCONT $(cat /tmp/testG_ns.pid)"
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo-bar" is visible with command "hostnamectl --transient" in "60" seconds


    @RHEL-17972
    @ver+=1.49.2
    @ver/rhel/9+=1.46.0.19
    @ver/rhel/9/2+=1.42.2.26
    @rhelver+=8
    @internal_DHCP @dhcpd
    @restore_hostname @eth0
    @pull_hostname_from_dns_retry
    Scenario: nmcli - general - pull hostname from DNS and retry
    * Commentary
    """
    Check that NM retries to obtain a hostname (in this case, from DNS)
    if the first attempt fails.
    """
    * Write file "/tmp/addn-hosts.txt" with content
    """
    """
    * Prepare simulated test "testG" device with "172.25.15" ipv4 and daemon options "--dhcp-option=12 --dhcp-host=00:11:22:33:44:55,172.25.15.15 --addn-hosts /tmp/addn-hosts.txt --log-queries --no-resolv"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "10" seconds
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options
    """
    autoconnect no
    ipv4.method auto
    ipv6.method disabled
    ethernet.cloned-mac-address 00:11:22:33:44:55
    """
    * Bring "up" connection "con_general"
    When "inet 172.25.15.15" is visible with command "ip addr show dev testG" in "10" seconds
    When "localhost|fedora" is visible with command "hostname"
    * Commentary
    """
    Add the DNS entry for the host and check that NM picks it up
    """
    * Write file "/tmp/addn-hosts.txt" with content
    """
    172.25.15.15 foo-baz
    """
    * Execute "ip netns exec testG_ns kill -SIGHUP $(cat /tmp/testG_ns.pid)"
    Then "foo-baz" is visible with command "hostnamectl --transient" in "40" seconds


    @ver+=1.29.0
    @restore_hostname @delete_testeth0 @restart_if_needed
    @hostname_priority
    Scenario: nmcli - general - Hostname priority
    * Create NM config file "90-nmci-hostname.conf" with content
      """
      [connection-hostname]
      match-device=interface-name:test?
      hostname.only-from-default=0
      """
    * Restart NM
    * Prepare simulated test "testG" device with "192.168.97" ipv4 and daemon options "--dhcp-option=3 --dhcp-host=00:11:22:33:44:55,192.168.97.13,foo"
    * Prepare simulated test "testH" device with "192.168.98" ipv4 and daemon options "--dhcp-option=3 --dhcp-host=00:00:11:00:00:11,192.168.98.11,bar"
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
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

    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foo" is visible with command "hostnamectl --transient" in "60" seconds

    * Bring "up" connection "con_general2"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    # Since connections have the same priority, the one activated earlier wins
    Then "foo" is visible with command "hostnamectl --transient" in "60" seconds

    # Increase the priority of the second connection and retry
    * Modify connection "con_general2" changing options "hostname.priority 50"
    * Bring "up" connection "con_general2"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    # Now con_general2 has higher priority and wins
    Then "bar" is visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_full
    Scenario: NM - general - hostname mode full
    * Create NM config file "90-nmci-hostname.conf" with content
      """
      [main]
      hostname-mode=full
      """
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_dhcp
    Scenario: NM - general - hostname mode dhcp
    * Create NM config file "90-nmci-hostname.conf" with content
      """
      [main]
      hostname-mode=dhcp
      """
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @rhbz1766944
    @ver+=1.29
    @restart_if_needed @restore_hostname @dns_default @delete_testeth0
    @pull_hostname_from_dhcp_no_gw_no_default_hostname
    Scenario: nmcli - general - pull hostname from DHCP - no gw - no need for it
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv4.never-default yes
          hostname.only-from-default false
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is not visible with command "hostnamectl --transient" in "60" seconds


    @RHEL-33435
    @ver+=1.49.4
    @ver+=1.48.9
    @ver+=1.46.3
    @ver+=1.44.5
    @ver+=1.42.9
    @ver+=1.40.19
    @ver/rhel/9/4+=1.46.0.18
    @ver/rhel/9/5+=1.48.4.1
    @ver/rhel/9/2+=1.42.2.25
    @rhelver+=9
    @delete_testeth0 @restart_if_needed @restore_hostname @reset_etc_hosts @dns_default
    @pull_hostname_from_hosts_default
    Scenario: nmcli - general - pull hostname from /etc/hosts - dns=default
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Append "172.23.1.2 foobar" to file "/etc/hosts"
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv6.method disabled
          ipv4.method manual
          ipv4.address 172.23.1.2/28
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "10" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foobar" is visible with command "hostnamectl --transient" in "10" seconds
    * Bring "down" connection "con_general"
    Then "localhost|fedora" is visible with command "hostnamectl --transient" in "10" seconds


    @RHEL-33435
    @ver+=1.49.0
    @ver/rhel/9+=1.48.4.1
    @delete_testeth0 @restart_if_needed @restore_hostname @reset_etc_hosts @dns_systemd_resolved
    @pull_hostname_from_hosts_resolved
    Scenario: nmcli - general - pull hostname from /etc/hosts - dns=system-resolved
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Append "172.23.1.2 foobar" to file "/etc/hosts"
    * Add "ethernet" connection named "con_general" for device "testG" with options
          """
          autoconnect no
          ipv6.method disabled
          ipv4.method manual
          ipv4.address 172.23.1.2/28
          """
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "10" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "foobar" is visible with command "hostnamectl --transient" in "10" seconds
    * Bring "down" connection "con_general"
    Then "localhost|fedora" is visible with command "hostnamectl --transient" in "10" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_full_without_dhcp_hosts
    Scenario: NM - general - hostname mode dhcp without dhcp hosts
    * Create NM config file "90-nmci-hostname.conf" with content
      """
      [main]
      hostname-mode=dhcp
      """
    * Execute "echo no-hosts > /etc/dnsmasq.d/dnsmasq_custom.conf"
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
    When "ransient" is visible with command "hostnamectl" in "60" seconds
    Then "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
     And "localhost|fedora" is visible with command "hostnamectl --transient" for full "20" seconds


    @rhbz1405275
    @ver+=1.8.0
    @delete_testeth0 @restore_hostname @restart_if_needed
    @hostname_mode_none
    Scenario: NM - general - hostname mode none
    * Create NM config file "90-nmci-hostname.conf" with content
      """
      [main]
      hostname-mode=none
      """
    * Restart NM
    * Prepare simulated test "testG" device
    * Execute "hostnamectl set-hostname """
    * Execute "hostnamectl set-hostname --transient localhost.localdomain"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    When "localhost|fedora" is visible with command "hostnamectl --transient" in "60" seconds
    * Bring "up" connection "con_general"
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
    * Bring "up" connection "testeth0"


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
    @ver-=1.39.9
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


    @rhbz1361145 @rhbz2082682
    @ver+=1.39.10
    @restart_if_needed
    @general_nmcli_offline_connection_add_modify
    Scenario: nmcli - general - offline connection add and modify
    * Stop NM
    When Note the output of "nmcli --offline c add con-name offline0 type dummy ifname dummy0 ipv6.addr-gen-mode 0"
    Then Noted value contains "id=offline0"
     And Noted value contains "type=dummy"
     And Noted value contains "interface-name=dummy0"
     And Noted value contains "method=disabled"
     And Noted value contains "addr-gen-mode=eui64"
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
    Then All ifaces but "gre0, gretap0, dummy0, ip6tnl0, tunl0, sit0, erspan0, orig*, wwan*" are not in state "DOWN"
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
    When "disabled" is visible with command "nmcli networking"
    Then Execute "nmcli networking on"
    Then "inet 1" is visible with command "ip a s eth0" in "40" seconds


    @networking_on
    @general_networking_off
    Scenario: nmcli - networking - turn off
    When "inet 1" is visible with command "ip a s eth0" in "40" seconds
    * Execute "nmcli networking off"
    Then "inet 1" is not visible with command "ip a s eth0"
    Then Execute "nmcli networking on"


    @networking_on
    @general_networking_on
    Scenario: nmcli - networking - turn on
    * Execute "nmcli networking off"
    When "inet 1" is not visible with command "ip a s eth0"
    * Execute "nmcli networking on"
    Then "inet 1" is visible with command "ip a s eth0" in "40" seconds


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
    * Bring "up" connection "con_general"
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
    @ver/rhel/9/0-1.36.0.5
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
    @ver/rhel/8/6+=1.36.0.6
    @ver/rhel/9/0+=1.36.0.5
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
    And "192.168.5.0/24 via 192.168.99.111 dev testG\s+proto static\s+metric" is visible with command "ip route" in "5" seconds
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
    @add_testeth9
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
    * Wait for "2" seconds
    * Bring "up" connection "con_general"
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
    * Execute "systemctl restart systemd-journald.service"
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
    * Wait for "5" seconds
    * Note the output of "hostname" as value "localh_cmd"
    # Check that setting the hostname to localhost have been ignored
    * Check noted values "orig_cmd" and "localh_cmd" are the same
    # Now set it to custom non-localhost value
    * Execute "echo myown.hostname > /etc/hostname"
    Then "myown.hostname" is visible with command "nmcli g hostname" in "5" seconds
    # Restoring orig. hostname in after_scenario


    @rhbz1136843
    @nmcli_general_ignore_specified_unamanaged_devices
    Scenario: NM - general - ignore specified unmanaged devices
    * Create "bond" device named "bond0"
    # Still unmanaged
    * "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"
    * Execute "ip link set dev bond0 up"
    * "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"
    # Add a config rule to unmanage the device
    * Create NM config file with content
      """
      [keyfile]
      unmanaged-devices=interface-name:bond0
      """
    * Execute "pkill -HUP NetworkManager"
    * Execute "ip addr add dev bond0 1.2.3.4/24"
    * Wait for "5" seconds
    # Now the device should be listed as unmanaged
    Then "bond0\s+bond\s+unmanaged" is visible with command "nmcli device"


    @rhbz1371433
    @ver+=1.7.9
    @manage_eth8 @eth8_disconnect @restart_if_needed
    @nmcli_general_set_device_unmanaged
    Scenario: NM - general - set device to unmanaged state
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Bring "up" connection "con_general"
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
    @manage_eth8 @eth8_disconnect
    @nmcli_general_set_device_back_to_managed
    Scenario: NM - general - set device back from unmanaged state
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Bring "up" connection "con_general"
    #When "/sbin/dhclient" is visible with command "ps aux|grep dhc |grep eth8 |grep -v orig"
     And "fe80" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip a s eth8" in "15" seconds
     And "192" is visible with command "ip r |grep eth8"
    * Wait for "2" seconds
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


    @nmcli_general_keyfile_tailing_whitespace
    Scenario: nmcli - general - keyfile tailing whitespace ignored
    * Cleanup device "eth8.100"
    * Add "vlan" connection named "eth8.100" with options "autoconnect no dev eth8 id 100"
    When "/etc/NetworkManager/system-connections/eth8.100.nmconnection" is file
    Then Replace "parent=eth8" with "parent=eth9" in file "/etc/NetworkManager/system-connections/eth8.100.nmconnection"
    * Reload connections
    Then "eth9" is visible with command "nmcli con show eth8.100"


    @ver+=1.5
    @nmcli_device_wifi_with_two_devices
    Scenario: nmcli - device - wifi show two devices
    * Execute "cd contrib/dbus; python3l -m unittest dbusmock-unittest.TestNetworkManager.test_two_wifi_with_accesspoints"


    @rhbz1114681
    @add_testeth8
    @nmcli_general_keep_slave_device_unmanaged
    Scenario: nmcli - general - keep slave device unmanaged
    * Cleanup device "eth8.100"
    * Cleanup execute "nmcli device set eth8 managed on"
    # We need to delete keyfile testeth8
    * Execute "nmcli con del testeth8"
    * Add "ethernet" connection named "con_general" for device "eth8"
    Given "/etc/NetworkManager/system-connections/con_general.nmconnection" is file
    * Execute "nmcli device set eth8 managed off"
    * Reload connections
    * Execute "ip link add link eth8 name eth8.100 type vlan id 100"
    Then "eth8\s+ethernet\s+unmanaged" is visible with command "nmcli device" in "5" seconds
    Then "eth8.100\s+vlan\s+unmanaged" is visible with command "nmcli device"
    Then "con_general" is not visible with command "nmcli device"


    @rhbz1393997
    @restart_if_needed @restore_hostname
    @nmcli_general_DHCP_HOSTNAME_profile_pickup
    Scenario: nmcli - general - connect correct profile with DHCP_HOSTNAME
    * Add "ethernet" connection named "con_general" for device "eth8" with options "ipv4.dns 8.8.4.4"
    * Update the keyfile "/etc/NetworkManager/system-connections/con_general.nmconnection"
      """
      [ipv4]
      dhcp-hostname=walderon
      """
    * Bring "up" connection "con_general"
    * Restart NM
    Then "con_general" is visible with command "nmcli  -t -f CONNECTION device"
    And "walderon" is visible with command "nmcli  -t -f ipv4.dhcp-hostname connection show con_general"


    @rhbz1171751
    @ver+=1.8.0
    @restart_if_needed @not_on_s390x
    @match_connections_when_no_var_run_exists
    Scenario: NM - general - connection matching for anaconda
     * Stop NM
     * Execute "rm -rf /var/run/NetworkManager/*"
     * Create keyfile "/etc/NetworkManager/system-connections/con_general.nmconnection"
      """
      [connection]
      interface-name=eth8
      id=con_general
      type=ethernet

      [ipv4]
      method=auto

      [ipv6]
      method=auto
      """
     Then "con_general" is not visible with command "nmcli con sh -a"
     * Start NM
     Then "con_general" is visible with command "nmcli con sh -a" in "5" seconds


    @rhbz1673321 @rhbz1942741
    @ver+=1.30
    @x86_64_only @eth0 @restart_if_needed
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
    * Wait for "1" seconds
    * Execute "nmcli device set eth8 managed yes"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds
    * Delete connection "con_general"
    Then "Wired" is not visible with command "nmcli con"


    @rhbz1460760
    @ver+=1.8.0
    @mtu @add_testeth8
    @keyfile_respect_externally_set_mtu
    Scenario: NM - general - respect externally set mtu
    * Cleanup connection "con_general"
    * Execute "ip link set dev eth8 mtu 1400"
     * Create keyfile "/etc/NetworkManager/system-connections/con_general.nmconnection"
      """
      [connection]
      interface-name=eth8
      id=con_general
      type=ethernet

      [ipv4]
      method=auto

      [ipv6]
      method=auto
      """
    * Reload connections
    * Bring "up" connection "con_general"
    Then "1400" is visible with command "ip a s eth8" in "5" seconds


    @rhbz1103777
    @firewall
    @no_error_when_firewald_restarted
    Scenario: NM - general - no error when firewalld restarted
    * Execute "systemctl restart firewalld"
    Then "nm_connection_get_setting_connection: assertion" is not visible with command "journalctl -u NetworkManager --since '10 seconds ago' --no-pager |grep nm_connection"


    @rhbz1103777
    @ver+=1.8.0 @fedoraver+=31
    @firewall @restart_if_needed
    @show_zones_after_firewalld_install
    Scenario: NM - general - show zones after firewall restart
    * DNF "-y remove firewalld"
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "eth8" with options "connection.zone work"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    * DNF "-y install firewalld"
    * Execute "systemctl start firewalld"
    Then "work" is visible with command "firewall-cmd  --get-zone-of-interface=eth8" in "3" seconds


    @rhbz1286576
    @restart_if_needed
    @wpa_supplicant_not_started
    Scenario: NM - general - do not start wpa_supplicant
    * Execute "systemctl stop wpa_supplicant"
    * Restart NM
    Then "^active" is not visible with command "systemctl is-active wpa_supplicant" in "5" seconds


    @rhbz1041901
    @nmcli_general_multiword_autocompletion
    Scenario: nmcli - general - multiword autocompletion
    * Add "bond" connection named "'Bondy connection 1'" for device "gen-bond"
    * "Bondy connection 1" is visible with command "nmcli connection"
    * Autocomplete "nmcli connection delete Bondy" in bash and execute
    Then "Bondy connection 1" is not visible with command "nmcli connection" in "3" seconds


    @rhbz1170199
    @nmcli_general_dbus_set_gateway
    Scenario: nmcli - general - dbus api gateway setting
    * Cleanup connection "con_general"
    * Execute "/usr/bin/python3l contrib/dbus/dbus-set-gw.py"
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
    @nat_from_shared_network_iptables
    Scenario: NM - general - NAT_dhcp from shared networks - iptables
    Given Create NM config file with content
          """
          [main]
          firewall-backend=iptables
          """
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
    @permissive
    @nat_from_shared_network_nftables
    Scenario: NM - general - NAT_dhcp from shared networks - nftables
    Given Create NM config file with content
          """
          [main]
          firewall-backend=nftables
          """
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
    * Create NM config file "01-nmci-run-once.conf" with content
      """
      [main]
      configure-and-quit=yes
      dhcp=internal
      """
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
    * Create NM config file "01-nmci-run-once.conf" with content
      """
      [main]
      configure-and-quit=yes
      dhcp=internal
      """
    * Wait for "1" seconds
    * Start NM without PID wait
    * "192" is visible with command " ip a s testG |grep 'inet '|grep dynamic" in "60" seconds
    * Wait for "20" seconds
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
    * Create NM config file "01-nmci-run-once.conf" with content
      """
      [main]
      configure-and-quit=yes
      dhcp=internal
      """
    * Wait for "1" seconds
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
    * Wait for "2" seconds
    * Stop NM and clean "eth0"
    When "state DOWN" is visible with command "ip a s eth0" in "5" seconds
    * Execute "hostnamectl set-hostname localhost.localdomain"
    * Create NM config file "01-nmci-run-once.conf" with content
      """
      [main]
      configure-and-quit=yes
      dhcp=internal
      """
    * Execute "ip link set dev eth0 up"
    * Wait for "1" seconds
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
    * Wait for "2" seconds
    * Stop NM and clean "eth0"
    When "state DOWN" is visible with command "ip a s eth0" in "5" seconds
    * Execute "hostnamectl set-hostname localhost.localdomain"
    ## VVV Just to make sure slow devices will catch carrier
    * Create NM config file "01-nmci-run-once.conf" with content
      """
      [main]
      configure-and-quit=yes
      dhcp=internal

      [device]
      match-device=interface-name:eth0
      carrier-wait-timeout=10000
      """
    * Wait for "1" seconds
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
    @ver/rhel/8/6-1.36.0.6
    @ver/rhel/9/0-1.36.0.5
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
    @ver/rhel/9/0+=1.36.0.5
    @delete_testeth0 @restart_if_needed
    @wait-online-for-both-ips
    Scenario: NM - general - wait-online - for both ipv4 and ipv6
    * Prepare simulated test "testG" device
    * Execute "rm -rf /tmp/testG_ns.lease"
    * Execute "ip netns exec testG_ns pkill -SIGSTOP -F /tmp/testG_ns.pid"
    * Wait for "1" seconds
    * Add "ethernet" connection named "con_general" for device "testG" with options "ipv4.may-fail no ipv6.may-fail no"
    # Do a random wait between 0s and 3s to delay DHCP server a bit
    * Execute "sleep $(echo $(shuf -i 0-3 -n 1)) && ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid" without waiting for process to finish
    # It takes slightly over 4s to reach connected state
    # so any delay over 0 or 1 (it really depends on DHCP now)
    # should hit the bug.
    * Wait for "5" seconds
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
    @delete_testeth0 @restart_if_needed
    @nm_online_wait_for_delayed_device
    Scenario: NM - general - wait for delayed device
    * Add "ethernet" connection named "con_general" for device "testG"
    * Stop NM
    * Prepare simulated veth device "testG" without carrier
    * Create NM config file with content
      """
      [device-testG]
      match-device=interface-name:testG
      carrier-wait-timeout=20000
      """
    * Wait for "2" seconds
    * Start NM
    * Run child "echo FAIL > /tmp/nm-online.txt && /usr/bin/nm-online -s -q --timeout=30 && echo PASS > /tmp/nm-online.txt"
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Wait for "10" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
     And Execute "ip netns exec testG_ns ip link set testGp up"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz1759956
    @ver+=1.22.5 @ver-=1.24
    @delete_testeth0 @restart_if_needed
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
    * Wait for "30" seconds
    When "con_general2" is visible with command "nmcli con show -a" in "20" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz1759956 @rhbz1828458
    @ver+=1.25
    @delete_testeth0 @restart_if_needed
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
    * Wait for "30" seconds
    When "con_general2" is visible with command "nmcli con show -a" in "20" seconds
    When "FAIL" is visible with command "cat /tmp/nm-online.txt"
    * Execute "ip netns exec testG_ns pkill -SIGCONT -F /tmp/testG_ns.pid"
    Then "PASS" is visible with command "cat /tmp/nm-online.txt" in "10" seconds


    @rhbz2025617
    @ver+=1.37
    @nm_online_timeout_max
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
    # enable slow dnsmasq - use mv and after Prepare step
    * Execute "mv `which dnsmasq` `which dnsmasq`.orig"
    * Execute "mv `which dnsmasq.slow` `which dnsmasq.slow | sed 's/.slow//'`"
    * Restart NM in background
    # wait until dnsmasq is started by NM
    When "sleep 3" is visible with command "ps aux | grep -A1 dnsmasq" in "10" seconds
    * Execute "/usr/bin/nm-online -s --timeout=30"
    Then "sleep 3" is not visible with command "ps aux | grep -A1 dnsmasq" in "0" seconds


    @rhbz1160013
    @permissive @need_dispatcher_scripts
    @policy_based_routing
    Scenario: NM - general - policy based routing
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Bring "up" connection "con_general"
    * Create PBR files for profile "con_general" and "eth8" device in table "1"
    * Bring "up" connection "con_general"
    Then "17200:\s+from 192.168.10[0-3].* lookup 1.*17201:\s+from all iif eth8 lookup 1" is visible with command "ip rule"
    Then "default via 192.168.100.1 dev eth8" is visible with command "ip r s table 1"
    * Bring "down" connection "con_general"
    Then "17200:\s+from 192.168.10[0-3]..* lookup 1.*17201:\s+from all iif eth8 lookup 1" is not visible with command "ip rule" in "5" seconds
    Then "default via 192.168.100.1 dev eth8" is not visible with command "ip r s table 1"


    @rhbz1384799
    @ver+=1.10
    @permissive @need_dispatcher_scripts @restart_if_needed
    @modify_policy_based_routing_connection
    Scenario: NM - general - modify policy based routing connection
    * Prepare simulated test "testG" device
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Bring "up" connection "con_general"
    * Create PBR files for profile "con_general" and "testG" device in table "1"
    * Modify connection "con_general" changing options "connection.autoconnect yes ipv6.method ignore"
    * Execute "nmcli device reapply testG"
    Then "17200:\s+from 192.168.99.* lookup 1.*17201:\s+from all iif testG lookup 1" is visible with command "ip rule" in "20" seconds
     And "default via 192.168.99.1 dev testG" is visible with command "ip r s table 1" in "20" seconds
     And "2620" is not visible with command "ip a s testG" in "20" seconds


    @RHEL-43583 @RHEL-43720
    @ifcfg-rh
    @rhelver-=9
    @ver-
    @ver/rhel/9+=1.48.2.2
    @ver/rhel/9/4+=1.46.0.12
    @need_dispatcher_scripts
    @policy_based_routing_with_dispatcher_scripts
    Scenario: NM - general - check that ifcfg route and rule files are applied when ipcalc is installed
    When "ipcalc" is visible with command "rpm -qR NetworkManager-dispatcher-routing-rules"
    * Prepare simulated test "testG" device
    * Commentary
    """
      Remove connection testG before PRIORITY_TAG, which removes NM-dispatcher-scripts.
      This is to prevent ip rule leftovers (not cleaned with dispatcher scripts missing).
    """
    * Cleanup connection "testG" with priority "0"
    * Cleanup execute "ip rule flush table 994"
    * Create ifcfg-file "/etc/sysconfig/network-scripts/ifcfg-testG"
    """
      DEVICE=testG
      NAME=testG
      ONBOOT=yes
      BOOTPROTO=static
      IPADDR=192.168.102.5
      NETMASK=255.255.255.0
      GATEWAY=192.168.102.1
    """
    * Create ifcfg-file "/etc/sysconfig/network-scripts/route-testG"
    """
      ADDRESS0=11.12.0.0
      NETMASK0=255.255.0.0
      GATEWAY0=192.168.102.4
    """
    * Create ifcfg-file "/etc/sysconfig/network-scripts/rule-testG"
    """
      from 192.168.102.0/24 table 994
    """
    * Reload connections
    Then "192.168.102.5" is visible with command "ip a s dev testG"
    Then "11.12.0.0/16 via 192.168.102.4" is visible with command "ip route s dev testG"
    Then "from 192.168.102.0/24 lookup 994" is visible with command "ip rule"


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
    * Wait for "3" seconds
    Then Execute "systemctl restart network.service"


    @rhbz1079353

    @nmcli_general_wait_for_carrier_on_new_device_request
    Scenario: nmcli - general - wait for carrier on new device activation request
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Prepare simulated veth device "testG" without carrier
    * Wait for "1" seconds
    * Modify connection "con_general" changing options "ipv4.may-fail no"
    * Execute "nmcli con up con_general" without waiting for process to finish
    * Wait for "1" seconds
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
    When "True" is visible with command "/usr/bin/python3l contrib/gi/nmclient_get_device_property.py eth8 get_carrier"
    * Execute "ip link set dev eth8 down"
    Then "False" is visible with command "/usr/bin/python3l contrib/gi/nmclient_get_device_property.py eth8 get_carrier"


    # Tied to the bz, though these are not direct verifiers
    @rhbz1079353
    @need_config_server
    @nmcli_general_activate_static_connection_carrier_ignored
    Scenario: nmcli - general - activate static connection with no carrier - ignored
    * Add "ethernet" connection named "con_general" for device "testG" with options "autoconnect no"
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.address '192.168.5.11/24' ipv4.gateway '192.168.5.1' ipv6.method ignore"
    * Prepare simulated veth device "testG" without carrier
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
    * Prepare simulated veth device "testG" without carrier
    * Execute "nmcli con up con_general"
    Then "connected:con_general" is visible with command "nmcli -t -f STATE,CONNECTION device" in "60" seconds
    Then "192.168.5.11" is visible with command "ip a s testG" in "60" seconds


    @rhbz1272974
    @s390x_only
    @skip_in_kvm @remove_ctcdevice
    @ctc_device_recognition
    Scenario: NM - general - ctc device as ethernet recognition
    * Execute "znetconf -a $(znetconf -u |grep CTC |awk 'BEGIN { FS = "," } ; { print $1 }')"
    Then "ethernet" is visible with command "nmcli dev |grep $(znetconf -c |grep ctc | awk '{print $5}')"


    @rhbz1034158
    @connect_testeth0 @disp
    @nmcli_monitor
    Scenario: nmcli - monitor
    * Run child "nmcli m 2>&1> /tmp/monitor.txt"
    * Write dispatcher "pre-up.d/98-disp" file with params "sleep 1;"
    * Write dispatcher "pre-down.d/97-disp" file with params "sleep 1;"
    * Bring "down" connection "testeth0"
    * Wait for "1" seconds
    * Bring "up" connection "testeth0"
    * Wait for "1" seconds
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
    @snapshot_timeout_rollback_all_devices
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
    * Wait for "10" seconds
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
    * Wait for "15" seconds
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
    * Wait for "15" seconds
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
    * Wait for "15" seconds
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
    When "Exactly" "3" lines with pattern "vf" are visible with command "ip -c link show eth11" in "5" seconds
    When "Exactly" "0" lines with pattern "vf" are visible with command "ip -c link show eth11" in "15" seconds


    @rhbz2177590
    @ver+=1.45.0
    @checkpoint_remove
    @snapshot_rollback_deleted
    Scenario: NM - general - deleted sw device with --disconnect-new-devices
    * Add "dummy" connection named "con_general" for device "dummy0" with options
          """
          ipv4.method manual
          ipv4.addresses 192.168.244.4/24
          """
    * Bring "up" connection "con_general"
    * Execute "contrib/gi/checkpoint.py create 0 --destroy-all --disconnect-new-devices"
    * Delete device "dummy0"
    * Modify connection "con_general" changing options "ipv4.address 192.168.244.5/24"
    * Execute "contrib/gi/checkpoint.py rollback --last"
    Then "con_general" is visible with command "nmcli -g name con show --active" in "10" seconds
    Then "dummy0:" is visible with command "ip -o link"
    Then "192.168.244.4/24" is visible with command "ip -o addr show dummy0"


    @RHEL-1526
    @ver+=1.44.0.4
    @checkpoint_remove
    @snapshot_rollback_delete_devices_and_profiles
    Scenario: NM - general - deleted sw device with --disconnect-new-devices
    * Execute "contrib/gi/checkpoint.py create 0 --destroy-all --disconnect-new-devices --delete-new-connections"
    * Add "dummy" connection named "dummy0*" for device "dummy0"
    * Add "vlan" connection named "dummy0.100*" with options
        """
        dev dummy0 id 100
        ipv4.method manual
        ipv4.addresses 192.168.1.2/24
        """
    When "dummy0.100\s+vlan\s+connected" is visible with command "nmcli device" in "5" seconds
    * Execute "contrib/gi/checkpoint.py rollback --last"
    Then "dummy0" is not visible with command "nmcli d"
    Then "dummy0*" is not visible with command "nmcli c"
    Then "dummy0.100" is not visible with command "nmcli d"
    Then "dummy0.100*" is not visible with command "nmcli c"


    @RHEL-32493
    @RHEL-31980
    @ver+=1.46.2
    @ver+=1.47.5
    @ver/rhel/9/2+=1.42.2.17
    @ver/rhel/9/4+=1.46.0.8
    @ver/rhel/9+=1.47.90
    @checkpoint_remove
    @snapshot_rollback_in_memory
    Scenario: NM - general - snapshot and rollback in-memory connection
    * Cleanup connection "dummy1"
    * Cleanup device "dummy"
    * Write file "/tmp/dummy1.yaml" with content
      """
      ---
      interfaces:
      - name: dummy1
        type: dummy
      """
    * Execute "nmstatectl set /tmp/dummy1.yaml --memory-only "
    When "/run/NetworkManager/system-connections/dummy1.nmconnection:dummy1" is visible with command "nmcli -t -f 'filename,name,uuid' c show"
    * Execute "nmstatectl set /tmp/dummy1.yaml --no-commit"
    * Execute "nmstatectl rollback"
    Then "/run/NetworkManager/system-connections/dummy1.nmconnection:dummy1" is visible with command "nmcli -t -f 'filename,name,uuid' c show"


    # Skip on unmaintained RHEL8
    @rhelver+=9
    # Latest nmstate dropped support for NM<=1.40
    # https://issues.redhat.com/browse/RHEL-1595
    @ver+=1.41
    @x86_64_only
    @nmstate_setup @permissive
    @nmstate_upstream
    Scenario: NM - general - nmstate
    # Nmstate tests are now run in pod running either c8s or c9s
    # and the version of NM that's under test. No RHEL, no Fedora
    # just CentOS Stream. This should be sufficient to see if NM
    # is not breaking nmstate when we have MR or so.
    * Run tier0 nmstate tests with log in "/tmp/nmstate.txt"
    Then "PASSED" is visible with command "grep -a ' PASS' /tmp/nmstate.txt"
    Then "100%" is visible with command "grep -a '100%' /tmp/nmstate.txt"
    Then "FAILED" is not visible with command "grep -a ' FAILED' /tmp/nmstate.txt"
    Then "ERROR" is not visible with command "grep -a ' ERROR' /tmp/nmstate.txt"


    @rhbz1433303
    @ver+=1.4.0
    @not_on_aarch64
    @logging_info_only
    @stable_mem_consumption
    Scenario: NM - general - stable mem consumption
    * Cleanup device "eth0"
    * Cleanup device "brX"
    * Create NM config file with content
      """
      [keyfile]
      unmanaged-devices=interface-name:orig*;interface-name:eth*
      """
    * Start NM in valgrind
    * Note NM memory consumption as value "0"
    * Execute reproducer "repro_1433303.sh" for "3" times
    * Commentary
      """
      Just log mem usage, do not compare, reported memory seems to vary a lot,
      massif version is more stable.
      """
    * Note NM memory consumption as value "0"


    @rhbz1433303
    @ver+=1.4.0
    @not_on_aarch64
    @logging_info_only
    @stable_mem_consumption_massif
    Scenario: NM - general - stable mem consumption using massif
    * Cleanup device "eth0"
    * Cleanup device "brX"
    * Create NM config file with content
      """
      [keyfile]
      unmanaged-devices=interface-name:orig*;interface-name:eth*
      """
    * Start NM in valgrind using tool "massif"
    * Execute reproducer "repro_1433303.sh" for "2" times
    * Wait for "10" seconds
    * Note NM memory consumption as value "0"
    * Execute reproducer "repro_1433303.sh" for "3" times
    When Check NM memory consumption difference from "0" is "less than" "20" in "60" seconds
    * Commentary
    """
      The following wait is for passing scenario,
      to have some delay after last snapshot.
    """
    * Wait for "10" seconds


    @rhbz1461643 @rhbz1945282
    @ver+=1.10.0
    @ver/rhel/8+=1.36.0.8
    @ver/rhel/9/0+=1.36.0.6
    @ver/rhel/9+=1.38.7
    @not_on_aarch64
    @no_config_server
    @logging_info_only @allow_veth_connections
    @stable_mem_consumption2
    Scenario: NM - general - stable mem consumption - var 2
    * Cleanup device "eth0"
    * Create NM config file with content
      """
      [keyfile]
      unmanaged-devices=interface-name:orig*;interface-name:eth*
      """
    * Start NM in valgrind
    * Note NM memory consumption as value "0"
    * Execute reproducer "repro_1461643.sh" for "7" times
    * Commentary
      """
      Just log mem usage, do not compare, reported memory seems to vary a lot,
      massif version is more stable.
      """
    * Note NM memory consumption as value "1"


    @rhbz1461643 @rhbz1945282
    @ver+=1.10.0
    @ver/rhel/8+=1.36.0.8
    @ver/rhel/9/0+=1.36.0.6
    @ver/rhel/9+=1.38.7
    @not_on_aarch64
    @no_config_server
    @logging_info_only @allow_veth_connections
    @stable_mem_consumption2_massif
    Scenario: NM - general - stable mem consumption - var 2
    * Cleanup device "eth0"
    * Create NM config file with content
      """
      [keyfile]
      unmanaged-devices=interface-name:orig*;interface-name:eth*
      """
    * Start NM in valgrind using tool "massif"
    * Execute reproducer "repro_1461643.sh" for "3" times
    * Wait for "10" seconds
    * Note NM memory consumption as value "0"
    * Execute reproducer "repro_1461643.sh" for "4" times
    When Check NM memory consumption difference from "0" is "less than" "20" in "60" seconds
    * Commentary
    """
      The following wait is for passing scenario,
      to have some delay after last snapshot.
    """
    * Wait for "10" seconds


    @rhbz1398932
    @ver+=1.7.2
    @dummy_connection
    Scenario: NM - general - create dummy connection
    * Add "dummy" connection named "con_general" for device "br0" with options "ip4 1.2.3.4/24 autoconnect no"
    * Bring "up" connection "con_general"
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
    * Bring "up" connection "con_general"
    * Bring "up" connection "con_general"
    * Bring "up" connection "con_general"
    * Execute "tc qdisc add dev br0 root handle 1234 fq_codel"
    * Bring "up" connection "con_general"
    Then "dummy" is visible with command "ip -d l show br0 | grep dummy"


    @rhbz1512316 @rhbz2210271
    @ver+=1.10.1
    @ignore_backoff_message
    @do_not_touch_external_dummy
    Scenario: NM - general - do not touch external dummy device
    * Cleanup device "dummy0"
    Then Execute reproducer "repro_1512316.sh" for "8" times


    @rhbz1443114
    @ver+=1.8.0
    @restart_if_needed @non_utf_device
    @dummy_non_utf_device
    Scenario: NM - general - non UTF-8 device
    * Restart NM
    Then "nonutf" is visible with command "nmcli device"


    @rhbz1458399
    @ver+=1.12.0
    @connectivity
    @connectivity_check
    Scenario: NM - general - connectivity check
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
     And "full" is visible with command "nmcli  -g CONNECTIVITY g" in "70" seconds
    * Append "1.2.3.4 static.redhat.com" to file "/etc/hosts"
    * Append "1::1 static.redhat.com" to file "/etc/hosts"
    When "limited" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
     * Reset /etc/hosts
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" in "10" seconds


    @rhbz1458399
    @ver+=1.12.0
    @connectivity @restart_if_needed
    @disable_connectivity_check
    Scenario: NM - general - disable connectivity check
    * Execute "rm -rf /etc/NetworkManager/conf.d/95-nmci-connectivity.conf"
    * Restart NM
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
     And "full" is visible with command "nmcli  -g CONNECTIVITY g"
    * Append "1.2.3.4 static.redhat.com" to file "/etc/hosts"
    * Append "1::1 static.redhat.com" to file "/etc/hosts"
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" for full "40" seconds


    @rhbz1394345
    @ver+=1.12.0
    @connectivity
    @per_device_connectivity_check
    Scenario: NM - general - per device connectivity check
    # Device with connectivity but low priority
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
    When "full" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
    # Device w/o connectivity but with high priority (testeth0 has metric 99)
    * Add "ethernet" connection named "con_general2" for device "eth8" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.244.4/24
          ipv4.gateway 192.168.244.1
          ipv4.route-metric 95
          ipv6.method ignore
          """
    * Bring "up" connection "con_general2"
    # Connection should stay at the lower priority device
    Then "full" is visible with command "nmcli  -g CONNECTIVITY g" in "40" seconds
     And Ping "boston.com"


    @rhbz1534477
    @ver+=1.12
    @connectivity @restart_if_needed @long
    @manipulate_connectivity_check_via_dbus
    Scenario: dbus - general - connectivity check manipulation
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show testeth0" in "45" seconds
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
    * Wait for "2" seconds
    * Execute "ip link set tap0 down"
    Then "master brX" is visible with command "ip link show tap0" for full "5" seconds


    @ver+=1.10
    @add_testeth8 @eth8_disconnect
    @overtake_external_device
    Scenario: nmcli - general - overtake external device
    * Execute "ip add add 1.2.3.4/24 dev eth8"
    When Path "/etc/NetworkManager/system-connections/eth8.nmconnection" does not exist
     And "eth8\s+ethernet\s+connected" is visible with command "nmcli d" in "15" seconds
     And "dhclient" is not visible with command "ps aux| grep client-eth8"
    * Modify connection "eth8" changing options "ipv4.method auto"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show eth8" in "45" seconds
     And Check keyfile "/etc/NetworkManager/system-connections/eth8.nmconnection" has options
      """
      ipv4.method=auto
      """
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
    * Wait for "0.5" seconds
    * Execute "ip link set testG down"
    * Wait for "8" seconds
    * Execute "ip link set testG up"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "45" seconds


    @rhbz1541031
    @ver+=1.12
    @not_with_systemd_resolved
    @resolv_conf_overwrite_after_stop
    Scenario: NM - general - overwrite resolv conf after stop
    * Create NM config file with content
      """
      [main]
      rc-manager=unmanaged
      """
    * Append "nameserver 1.2.3.4" to file "/etc/resolv.conf"
    * Stop NM
    When "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf" in "3" seconds
    * Start NM
    Then "nameserver 1.2.3.4" is visible with command "cat /etc/resolv.conf" in "3" seconds


    @rhbz1593519
    @ver+=1.12 
    @NM_starts_with_incorrect_logging_config
    Scenario: NM - general - nm starts even when logging is incorrectly configured
    * Stop NM
    * Create NM config file with content
      """
      [logging]
      level=DEFAULT:WARN,TEAM:TRACE
      """
    Then Start NM


    @rhbz1555281
    @ver+=1.10.7
    @libnm_async_tasks_cancelable
    Scenario: NM - general - cancelation of libnm async tasks (add_connection_async)
    * Cleanup connection "con_general"
    Then Execute reproducer "repro_1555281.py" with options "con_general"


    @rhbz1643085 @rhbz1642625
    @ver+=1.14
    @libnm_async_activation_cancelable_no_crash
    Scenario: NM - general - cancelation of libnm async activation - should not crash
    * Cleanup connection "con_general"
    Then Execute reproducer "repro_1643085.py" with options "con_general eth8"

    @rhbz1614691
    @ver+=1.12
    @nmcli_monitor_assertion_con_up_down
    Scenario: NM - general - nmcli monitor asserts error when connection is activated or deactivated
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Execute "nmcli monitor &> /tmp/nmcli_monitor_out & pid=$!; sleep 10; kill $pid" without waiting for process to finish
    * Bring "up" connection "con_general"
    * Wait for "1" seconds
    * Bring "down" connection "con_general"
    * Wait for "10" seconds
    Then "should not be reached" is not visible with command "cat /tmp/nmcli_monitor_out"


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_rollback
    Scenario: NM - general - libnm snapshot and rollback
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 0 eth8 eth9" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * "ERROR" is not visible with command "contrib/gi/checkpoint.py rollback" in "0" seconds
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
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 0" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * "ERROR" is not visible with command "contrib/gi/checkpoint.py rollback" in "0" seconds
    Then "192.168.10[0-3]" is visible with command "ip a s eth8" in "45" seconds
     And "192.168.10[0-3]" is visible with command "ip a s eth9" in "45" seconds
     And "1.2.3.4/24" is not visible with command "ip a s eth8"
     And "1.2.3.5/24" is not visible with command "ip a s eth9"
     And "1.2.3.1" is not visible with command "ip r"
     And "192.168.100.1" is visible with command "ip r"


    @rhbz1496739
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_timeout_rollback_all_devices
    Scenario: NM - general - libnm snapshot and rollback all devices with timeout
    * Add "ethernet" connection named "con_general" for device "eth8"
    * Add "ethernet" connection named "con_general2" for device "eth9"
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 10" in "0" seconds
    * Modify connection "con_general" changing options "ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general"
    * Modify connection "con_general2" changing options "ipv4.method manual ipv4.addresses 1.2.3.5/24 ipv4.gateway 1.2.3.1"
    * Bring "up" connection "con_general2"
    When "1.2.3.4/24" is visible with command "ip a s eth8" in "5" seconds
    When "1.2.3.5/24" is visible with command "ip a s eth9" in "5" seconds
     And "1.2.3.1" is visible with command "ip r"
    * Wait for "10" seconds
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
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 10 eth8" in "0" seconds
    * Execute "nmcli device set eth8 managed on"
    When "unmanaged" is not visible with command "nmcli device show eth8" in "5" seconds
    * Wait for "15" seconds
    Then "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds


    @rhbz1496739
    @ver+=1.12
    @manage_eth8 @checkpoint_remove
    @libnm_snapshot_rollback_managed
    Scenario: NM - general - libnm snapshot and rollback managed
    * Execute "nmcli device set eth8 managed on"
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 10 eth8" in "0" seconds
    * Execute "nmcli device set eth8 managed off"
    When "unmanaged" is visible with command "nmcli device show eth8" in "5" seconds
    * Wait for "15" seconds
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
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 10" in "0" seconds
    * Delete connection "gen-bond0.0"
    * Delete connection "gen-bond0.1"
    * Delete connection "gen-bond0"
    * Wait for "15" seconds
    Then Check slave "eth8" in bond "gen-bond" in proc
    Then Check slave "eth9" in bond "gen-bond" in proc


    @rhbz1574565
    @ver+=1.12
    @checkpoint_remove
    @libnm_snapshot_destroy_after_rollback
    Scenario: NM - general - snapshot and destroy checkpoint
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 5" in "0" seconds
    * Wait for "1" seconds
    Then "Succes" is visible with command "contrib/gi/checkpoint.py destroy --last" in "0" seconds
    Then "Failed" is visible with command "CP=$(contrib/gi/checkpoint.py create 5); sleep 7; contrib/gi/checkpoint.py destroy $CP" in "0" seconds


    @rhbz2035519 @rhbz2125615
    @ver+=1.36
    @checkpoint_remove
    @libnm_snapshot_reattach_unmanaged_ports_to_bridge
    Scenario: NM - general - reatach unmanaged ports to bridge after rollback
    * Cleanup connection "portXa"
    * Cleanup connection "portXb"
    * Cleanup connection "portXc"
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
    * "Failed" is not visible with command "contrib/gi/checkpoint.py create 0" in "0" seconds
    * Bring "up" connection "br12"
    * Execute "ip link set portXb master br0"
    * Execute "ip link set portXc master br0"
    * Wait for "1" seconds
    * "ERROR" is not visible with command "contrib/gi/checkpoint.py rollback" in "0" seconds
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
    * Wait for "2" seconds
    * Execute "contrib/nm_agent/nm_agent_prompt_counter.sh start"
    * Wait for "2" seconds
    * Modify connection "con_general" changing options "connection.autoconnect yes"
    * Wait for "2" seconds
    Then "PASSWORD_PROMPT_COUNT='1'" is visible with command "contrib/nm_agent/nm_agent_prompt_counter.sh stop"


    @rhbz1578436
    @ver+=1.14
    @rhelver+=8 @fedoraver-=41
    @ifupdown
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
    @rhelver-=9 @fedoraver-=41
    @ifupdown @keyfile
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


    @rhbz1649704
    @ver+=1.14
    @not_with_systemd_resolved
    @resolv_conf_search_limit
    Scenario: NM - general - save more than 6 search domains in resolv.conf
    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          autoconnect no
          ipv4.dns-search a.noexist.redhat.com,b.noexist.redhat.com,c.noexist.redhat.com,d.noexist.redhat.com,e.noexist.redhat.com,f.noexist.redhat.com,g.noexist.redhat.com
          """
    * Bring "up" connection "con_general"
    Then "Exactly" "7" lines with pattern "\.noexist\.redhat\.com" are visible with command "nmcli -f ipv4.dns-search con show con_general | sed 's/,/\n/g'"
     And "Exactly" "7" lines with pattern "\.noexist\.redhat\.com" are visible with command "cat /etc/resolv.conf | sed 's/ /\n/g'"


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
    Then Execute reproducer "repro_1689054.py"


    @rhbz2027674
    @ver+=1.37.2
    @ver+=1.36.3
    @libnm_nmclient_init_crash
    Scenario: nmcli - general - libnm crash when cancelling initialization of NMClient
    Then Execute reproducer "repro_2027674.py"


    @rhbz1697858
    @ver+=1.14
    @not_with_rhel_pkg @restart_if_needed
    @keyfile_nmconnection_extension
    Scenario: NM - general - keyfile does have .nmconnection extension
    * Create NM config file with content
      """
      [main]
      plugins=keyfile,ifcfg-rh
      """
    * Restart NM
    * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
    Then "/etc/NetworkManager/system-connections/con_general.nmconnection" is file
     And Path "/etc/NetworkManager/system-connections/con_general" does not exist


     @rhbz1674545
     @ver+=1.19
     @keyfile_cleanup
     @move_keyfile_to_usr_lib_dir
     Scenario: NM - general - move keyfile to usr lib dir and check deletion
    * Create NM config file with content
      """
      [main]
      plugins=keyfile,ifcfg-rh
      """
     * Restart NM
     * Add "ethernet" connection named "con_general" for device "\*" with options "autoconnect no"
     * Note the output of "nmcli -g connection.uuid connection show con_general"
     * Execute "mv /etc/NetworkManager/system-connections/con_general* /tmp/"
     * Delete connection "con_general"
     When "con_general" is not visible with command "nmcli connection"
     * "Unlock" Image Mode
     * Execute "mv /tmp/con_general* /usr/lib/NetworkManager/system-connections/"
     * Execute "restorecon /usr/lib/NetworkManager/system-connections/con_general*"
     * "Lock" Image Mode
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
     * Ignore possible AVC "NetworkManager.*nmmeta"


    @rhbz1674545
    @ver+=1.19
    @restart_if_needed @keyfile_cleanup
    @no_uuid_in_keyfile_in_usr_lib_dir
    Scenario: NM - general - read keyfiles without connection.uuid in usr lib dir
    * Create NM config file with content
      """
      [main]
      plugins=keyfile,ifcfg-rh
      """
    * "Unlock" Image Mode
    * Create keyfile "/usr/lib/NetworkManager/system-connections/con_general.nmconnection"
      """
      [connection]
      id=con_general
      type=ethernet
      autoconnect=false
      permissions=

      [ethernet]
      mac-address-blacklist=

      [ipv4]
      dns-search=
      method=auto

      [ipv6]
      addr-gen-mode=stable-privacy
      dns-search=
      method=auto
      """
    * Reload connections
    * Execute "chmod go-rwx /usr/lib/NetworkManager/system-connections/con_general.nmconnection"
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
    * Ignore possible AVC "NetworkManager.*nmmeta"


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
    @restart_if_needed
    @invalid_config_warning
    Scenario: NM - general - warn about invalid config options
    * Create NM config file with content
      """
      [main]
      something_nonexistent = some_value
      """
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
    @restart_if_needed
    @no_user_control
    Scenario: NM - general - root only control
    * Create NM config file with content
      """
      [main]
      auth-polkit=root-only
      """
    * Restart NM
    # User test has been created in envsetup.py
    Then "org.freedesktop.NetworkManager.network-control\s+no" is visible with command "sudo -u test nmcli gen perm"
    Then " auth" is not visible with command "sudo -u test nmcli gen perm"


    @rhbz1810153
    @ver+=1.22.0
    @ignore_backoff_message
    @clean_device_state_files
    Scenario: NM - general - clean device state files
    * Cleanup device "dummy0"
    * Execute "for i in $(seq 1 120); do ip link delete dummy0 &>/dev/null; ip link add dummy0 type bridge; ip addr add 1.1.1.1/2 dev dummy0;  ip link set dummy0 up; sleep 0.05; done"
    Then "Less than" "105" lines are visible with command "ls -1 /run/NetworkManager/devices/"


    @rhbz1758550
    @ver+=1.18.6
    @manage_eth8 @eth8_disconnect @tshark @dhclient_DHCP
    @NM_merge_dhclient_conditionals
    Scenario: NM - general - merge dhcp conditionals
    * Add "ethernet" connection named "con_general" for device "eth8" with options "autoconnect no"
    * Execute """echo -e 'if not option domain-name = "example.org" {\nprepend domain-name-servers 127.0.0.1;}' > /etc/dhcp/dhclient-eth8.conf"""
    * Bring "up" connection "con_general"
    Then "prepend domain-name-servers 127.0.0.1" is visible with command "cat /var/lib/NetworkManager/dhclient-eth8.conf"


    @rhbz1711215
    @ver+=1.25 @rhelver+=9
    @performance
    @NM_performance_dhcp_on_existing_veths
    Scenario: NM - general - create and activate 100 connections in 6 seconds on existing veths
    # We need up to 1/4 of dhcpd servers to be able to handle the amount of
    # networks in the max time. If we have just one there seems to be some
    # retransmissions needed in DHCP server so we know nothing about NM performance.
    * Create NM config file with content
          """
          [main]
          dhcp=internal
          no-auto-default=*
          dns=none
          [device-99-my]
          match-device=interface-name:t-a*
          managed=1
          [logging]
          level=INFO
          [connection-no-dad]
          match-device=interface-name:t-a*
          ipv4.dad-timeout=0
          """
    # * Restart NM  # no need to restart NM, it is stopped and started in the following step
    Then Activate "100" devices in "6" seconds


    @rhbz1711215
    @ver+=1.25 @rhelver+=9
    @performance
    @NM_performance_dhcp_on_existing_veths_with_dad
    Scenario: NM - general - create and activate 100 connections in 6 seconds on existing veths with DAD
    # We need up to 1/4 of dhcpd servers to be able to handle the amount of
    # networks in the max time. If we have just one there seems to be some
    # retransmissions needed in DHCP server so we know nothing about NM performance.
    * Create NM config file with content
          """
          [main]
          dhcp=internal
          no-auto-default=*
          dns=none
          [device-99-my]
          match-device=interface-name:t-a*
          managed=1
          [logging]
          level=INFO
          [connection-no-dad]
          match-device=interface-name:t-a*
          ipv4.dad-timeout=3000
          """
    Then Activate "100" devices in "10" seconds


    @rhbz1868982
    @eth0 @eth10_disconnect
    @ver+=1.25 @rhelver+=8
    @nmcli_shows_correct_routes
    Scenario: NM - general - nmclic shows correct routes
    * Add "ethernet" connection named "con_gen" for device "eth10" with options
          """
          ipv6.may-fail no
          ipv6.may-fail no
          autoconnect no
          """
    * Bring "up" connection "con_gen"
    When "default" is visible with command "ip r" in "20" seconds
    When "default" is visible with command "ip -6 r" in "20" seconds
    * Note the number of lines of "ip -6 route show dev eth10" as value "ip6_route"
    * Note the number of lines with pattern "route6" of "nmcli | sed '/^eth10:/,/^$/!d'" as value "nmcli6_route"
    * Note the number of lines of "ip -4 route show dev eth10" as value "ip4_route"
    * Note the number of lines with pattern "route4" of "nmcli | sed '/^eth10:/,/^$/!d'" as value "nmcli4_route"
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
    * Bring "up" connection "con_general"
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
    * Bring "up" connection "con_general"
    Then "no permission" is visible with command "sudo -u test nmcli d reapply dummy0"


    @rhbz1820770
    @ver+=1.32.2
    @eth0 @restore_hostname
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
    * Cleanup execute "ip r delete blackhole 172.25.1.0/24 proto bird"
    * Add "dummy" connection named "dummy0" for device "dummy1" with options "ip4 172.26.1.1/24 autoconnect no"
    * Bring "up" connection "dummy0"
    * Execute "ip route add blackhole 172.25.1.0/24 proto bird"
    * Start following journal
    * Execute "nmcli -g uuid connection show --active | xargs nmcli -w 10 connection down"
    Then "succeeded" is visible in journal
    And  "wait for ACK" is not visible in journal in "15" seconds
    And "blackhole" is visible with command "ip route"


    @rhbz2033643
    @ver+=1.39.6
    @eth0 @restore_hostname @dhcpd @dns_default
    @nmcli_dhcp_overlong_hostname
    Scenario: nmcli - general - support DHCP overlong hostnames
    * Execute "systemctl stop dhcpd"
    * Execute "hostnamectl set-hostname ''"
    * Execute "hostname localhost"
    * Prepare simulated test "testX4" device without DHCP
    * Execute "ip -n testX4_ns address add dev testX4p 172.25.1.4/24"
    * Configure dhcp server for subnet "172.25.1" with lease time "30"
    * Append lines to file "/tmp/dhcpd.conf"
      """
      host myhost {
            hardware ethernet 00:11:22:33:44:55;
            fixed-address 172.25.1.150;
            option host-name \"name1.test-dhcp-this-one-here-is-a-very-very-long-domain.example.com\";
      }
      """
    * Execute "ip netns exec testX4_ns dhcpd -4 -cf /tmp/dhcpd.conf -pf /tmp/testX4_ns.pid"
    * Add "ethernet" connection named "veth0+" for device "testX4" with options
      """
      ipv6.method disabled
      connection.autoconnect no
      ethernet.cloned-mac-address 00:11:22:33:44:55
      """
    * Bring "up" connection "veth0+"
    Then "name1" is visible with command "hostname" in "20" seconds
    And "search nodhcp test-dhcp-this-one-here-is-a-very-very-long-domain.example.com" is visible with command "cat /etc/resolv.conf"


    @rhbz2090946
    @ver+=1.39.10
    @eth0 @restore_hostname
    @nmcli_remove_static_hostname
    Scenario: nmcli - general - remove static hostname
    * Execute "nmcli general hostname example.org"
    * Execute "nmcli general hostname ''"
    * Path "/etc/hostname" does not exist
    * "example.org" is not visible with command "hostname" in "10" seconds


    @rhbz2217527
    @rhelver-=9 @fedoraver-=38 @ver+=1.43.10
    @ifcfg-rh
    @modify_link_settings_ifcfg
    Scenario: NM - general - try to modify link settings in ifcfg format
    * Start following journal
    * Create ifcfg-file "/etc/sysconfig/network-scripts/ifcfg-con_general"
      """
      TYPE=Ethernet
      PROXY_METHOD=none
      BROWSER_ONLY=no
      BOOTPROTO=none
      IPADDR=192.168.1.2
      IPV6_DISABLED=yes
      PREFIX=24
      NAME=con_general
      UUID=da8403c5-307c-42c4-aafb-992014973d53
      DEVICE=eth3
      ONBOOT=yes
      """
    * Reload connections
    When "connected" is visible with command "nmcli -g GENERAL.STATE dev show eth3" in "15" seconds
    Then "ifcfg-rh plugin is deprecated" is visible in journal in "10" seconds
    Then "con_general.nmconnection" is visible with command "ls -l /etc/sysconfig/network-scripts/con_general.nmconnection"
    Then "The ifcfg-rh plugin doesn't support setting 'link'" is visible with command "nmcli connection modify con_general link.tx-queue-length 1554"


    @rhbz2158328
    @rhelver-=8 @fedoraver-=0
    @ver+=1.43.2
    @apply_link_settings
    Scenario: NM - general - apply and reapply link settings
    * Note the output of "ip -d link show eth8 | sed -n 's/.* qlen \([0-9]\+\).*/\1/p'" as value "1-before"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_size \([0-9]\+\).*/\1/p'" as value "2-before"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_segs \([0-9]\+\).*/\1/p'" as value "3-before"

    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          link.tx-queue-length 1555
          link.gso-max-size 32000
          link.gso-max-segments 4242
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "30" seconds
    Then "qlen 1555" is visible with command "ip -d link show eth8"
    Then "gso_max_size 32000" is visible with command "ip -d link show eth8"
    Then "gso_max_segs 4242" is visible with command "ip -d link show eth8"

    * Execute "nmcli device modify eth8 link.tx-queue-length 1554 link.gso-max-segments 4243"
    Then "qlen 1554" is visible with command "ip -d link show eth8"
    Then "gso_max_segs 4243" is visible with command "ip -d link show eth8"

    * Bring "down" connection "con_general"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* qlen \([0-9]\+\).*/\1/p'" as value "1-after"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_size \([0-9]\+\).*/\1/p'" as value "2-after"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_segs \([0-9]\+\).*/\1/p'" as value "3-after"
    Then Check noted values "1-before" and "1-after" are the same
    Then Check noted values "2-before" and "2-after" are the same
    Then Check noted values "3-before" and "3-after" are the same


    @rhbz2158328
    @rhelver+=9
    @ver+=1.43.2
    @apply_link_settings
    Scenario: NM - general - apply and reapply link settings
    * Note the output of "ip -d link show eth8 | sed -n 's/.* qlen \([0-9]\+\).*/\1/p'" as value "1-before"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_size \([0-9]\+\).*/\1/p'" as value "2-before"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_segs \([0-9]\+\).*/\1/p'" as value "3-before"

    * Add "ethernet" connection named "con_general" for device "eth8" with options
          """
          link.tx-queue-length 1555
          link.gso-max-size 32000
          link.gso-max-segments 4242
      """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_general" in "30" seconds
    Then "qlen 1555" is visible with command "ip -d link show eth8"
    Then "gso_max_size 32000" is visible with command "ip -d link show eth8"
    Then "gso_max_segs 4242" is visible with command "ip -d link show eth8"

    * Execute "nmcli device modify eth8 link.tx-queue-length 1554 link.gso-max-segments 4243"
    Then "qlen 1554" is visible with command "ip -d link show eth8"
    Then "gso_max_segs 4243" is visible with command "ip -d link show eth8"

    * Bring "down" connection "con_general"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* qlen \([0-9]\+\).*/\1/p'" as value "1-after"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_size \([0-9]\+\).*/\1/p'" as value "2-after"
    * Note the output of "ip -d link show eth8 | sed -n 's/.* gso_max_segs \([0-9]\+\).*/\1/p'" as value "3-after"
    Then Check noted values "1-before" and "1-after" are the same
    Then Check noted values "2-before" and "2-after" are the same
    Then Check noted values "3-before" and "3-after" are the same


    @rhbz2156684
    @rhbz2180363
    @ver+=1.43.9
    @ver/rhel/9+=1.43.10
    @autoconnect_port
    Scenario: NM - general - ignore-carrier with bond
    # First we create a port profile with autoconnect=yes. The port profile
    # starts autoconnecting, finds no controller, fails and gets blocked from
    # autoconnect.
    #
    # Then add the controller profile with autoconnect disabled. The addition
    # of the controller profile needs to unblock the port, which starts autoconnecting
    # and bringing both up.
    * Prepare simulated test "testA" device
    * Add "ethernet" connection ignoring warnings named "c-testA" for device "testA" with options
          """
          autoconnect yes
          master bond1
          slave-type bond
          """
    *  Add "bond" connection named "c-bond1" for device "bond1" with options
          """
          autoconnect no
          """
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "25" seconds
    Then Check bond "bond1" state is "up"

    @rhbz2156684
    @rhbz2180363
    @ver+=1.43.9
    @ver/rhel/9+=1.43.10
    @ignore_carrier_with_bond_noauto
    Scenario: NM - general - ignore-carrier with bond without autoconnect
    # Have controller and port devices without autoconnect enabled. Check that
    # with "ignore-carrier=no" on the controller, the controller goes down
    # after carrier timeout and stays down.
    #
    # This is rather straight forward, because once it goes down, it won't
    # autoconnect again, as that is disabled.
    * Create NM config file "97-ignore-carrier-for-bond.conf" with content and "reload" NM
      """
      [device-97-ignore-carrier-for-bond]
      match-device=interface-name:bond1
      ignore-carrier=no
      carrier-wait-timeout=1500
      """
    * Prepare simulated test "testA" device
    * Add "ethernet" connection ignoring warnings named "c-testA" for device "testA" with options
          """
          autoconnect no
          master bond1
          slave-type bond
          """
    *  Add "bond" connection named "c-bond1" for device "bond1" with options
          """
          autoconnect no
          """
    * Bring "up" connection "c-testA"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "25" seconds
    Then Check bond "bond1" state is "up"
    * Execute "ip netns exec testA_ns ip link set testAp down"
    Then Check bond "bond1" link state is "down"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" in "3" seconds
    Then "bond1" is not visible with command "nmcli device; ip link" for full "5" seconds


    @rhbz2156684
    @rhbz2180363
    @ver+=1.43.9
    @ver/rhel/9+=1.43.10
    @ignore_carrier_with_bond
    Scenario: NM - general - ignore-carrier with bond
    # Have controller and port devices with only the port autoconnect=yes. Check that
    # with "ignore-carrier=no" on the controller, the controller goes down
    # after carrier timeout and stays down.
    #
    # The device goes down after carrier timeout and stays down. After carrier
    # comes back, the port autoconnects and brings the bond up.
    * Create NM config file "97-ignore-carrier-for-bond.conf" with content and "reload" NM
      """
      [device-97-ignore-carrier-for-bond]
      match-device=interface-name:bond1
      ignore-carrier=no
      carrier-wait-timeout=1500
      """
    * Prepare simulated test "testA" device
    * Add "ethernet" connection ignoring warnings named "c-testA" for device "testA" with options
          """
          autoconnect yes
          master bond1
          slave-type bond
          """
    *  Add "bond" connection named "c-bond1" for device "bond1" with options
          """
          autoconnect no
          """
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "25" seconds
    Then Check bond "bond1" state is "up"
    * Execute "ip netns exec testA_ns ip link set testAp down"
    Then Check bond "bond1" link state is "down"
    # The device goes down and stays down...
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" in "3" seconds
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" for full "3" seconds
    * Execute "ip netns exec testA_ns ip link set testAp up"
    # After carrier return, the device autoactivates again.
    Then "GENERAL.STATE:.*(activated|activating)" is visible with command "nmcli connection show c-bond1" in "5" seconds

    @rhbz2156684
    @rhbz2180363
    @ver+=1.43.9
    @ver/rhel/9+=1.43.10
    @ignore_carrier_with_bond_two_ports
    Scenario: NM - general - ignore-carrier with bond and two ports
    # Have controller and port devices with only the port autoconnect=yes. Check that
    # with "ignore-carrier=no" on the controller, the controller goes down
    # after carrier timeout and stays down.
    #
    # The device goes down after carrier timeout and stays down. After carrier
    # on one port comes back, the port autoconnects and brings the bond up.
    # The other port also comes up.
    * Create NM config file "97-ignore-carrier-for-bond.conf" with content and "reload" NM
      """
      [device-97-ignore-carrier-for-bond]
      match-device=interface-name:bond1
      ignore-carrier=no
      carrier-wait-timeout=1500
      """
    * Prepare simulated test "testA" device
    * Prepare simulated test "testB" device
    * Add "ethernet" connection ignoring warnings named "c-testA" for device "testA" with options
          """
          autoconnect yes
          master bond1
          slave-type bond
          """
    * Add "ethernet" connection ignoring warnings named "c-testB" for device "testB" with options
          """
          autoconnect yes
          master bond1
          slave-type bond
          """
    *  Add "bond" connection ignoring warnings named "c-bond1" for device "bond1" with options
          """
          autoconnect no
          """
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "25" seconds
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testB"
    Then Check bond "bond1" state is "up"

    * Commentary
        """
        After one interface looses carrier, nothing happens and all interfaces stay up.
        """
    * Execute "ip netns exec testA_ns ip link set testAp down"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" for full "10" seconds
    Then Check bond "bond1" state is "up"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testB"

    * Commentary
        """
        The bond device goes down and stays down...
        """
    * Execute "ip netns exec testB_ns ip link set testBp down"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" in "3" seconds
    Then Check bond "bond1" link state is "down"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" for full "3" seconds
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-testB"

    * Commentary
        """
        After carrier return, the device autoactivates again (but not testB, which has no carrier)
        """
    * Execute "ip netns exec testA_ns ip link set testAp up"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "10" seconds
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-testB"

    * Commentary
        """
        After carrier return, also testB autoactivates
        """
    * Execute "ip netns exec testB_ns ip link set testBp up"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "10" seconds
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testB"

    * Commentary
        """
        bring the devices down again, after loss of carrier.
        """
    * Execute "ip netns exec testA_ns ip link set testAp down"
    * Execute "ip netns exec testB_ns ip link set testBp down"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-bond1" in "3" seconds
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*(activated|activating)" is not visible with command "nmcli connection show c-testB"

    * Commentary
        """
        We enable autoconnect-slaves on the bond and give carrier on one port. The port autoconnects,
        brings up the bond, and the bond connects testB port too (despite having no carrier).
        """
    * Execute "nmcli connection modify c-bond1 connection.autoconnect-slaves yes"
    * Execute "ip netns exec testA_ns ip link set testAp up"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-bond1" in "10" seconds
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testA"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show c-testB"

    @rhbz2161915
    @rhelver+=9
    @ver+=1.43.6
    @nm_binds_to_dbus_check
    Scenario: NM - general - NetworkManager binds to dbus.service
    Then "BindsTo=dbus.*.service" is visible with command "systemctl show NetworkManager.service"


    @rhbz2186212
    @rhelver-=9
    @ver-1.43.3
    @ver+=1.43.8
    @eth0
    @suspend_wakeup
    Scenario: Suspend and wakeup test
    * Create NM config file "90-eth0-carrier.conf" with content
      """
      [device-eth0-carrier]
      match-device=interface-name:eth0
      ignore-carrier=no
      """
    * Restart NM
    # Restart NM right after the test in case of fail to reset eth0 state
    * Cleanup execute "systemctl restart NetworkManager"
    * Modify connection "testeth0" changing options "autoconnect yes"
    * Bring "up" connection "testeth0"
    * Mock systemd-logind service
    * Send "suspend" signal to mocked logind
    # This is not needed, keeping it here in case someone finds it useful
    #* Suspend and resume via /sys/power
    * Send "wakeup" signal to mocked logind
    Then "testeth0" is visible with command "nmcli c show -a" in "10" seconds


    @rhbz2173196
    @ver+=1.44
    @nmcli_version_warning
    Scenario: nmcli - warn at nmcli/running daemon version mismatches
    Then "nmcli .+ and NetworkManager .+ versions don't match. Restarting NetworkManager is advised." is not visible with command "nmcli 2>&1 >/dev/null"
    * Mock NetworkManager service
    * Set version of the mocked NM to "lower"
    Then "nmcli .+ and NetworkManager .+ versions don't match. Restarting NetworkManager is advised." is visible with command "nmcli 2>&1 >/dev/null"
    * Set version of the mocked NM to "higher"
    Then "nmcli .+ and NetworkManager .+ versions don't match. Restarting NetworkManager is advised." is visible with command "nmcli 2>&1 >/dev/null"


    @RHEL-17619 @RHEL-17620 @RHEL-17621
    @ver+=1.45.90
    @nmcli_controller_naming_convention
    Scenario: NM - general - ignore-carrier with bond
    * Commentary
          """
          Tests the new naming convention for libnm-core and libnm.
            - connection.slave-type is now connection.port-type
            - connection.master is now connection.controller
            - connection.autoconnect-slaves is now connection.autoconnect-ports
          """
    * Add "ethernet" connection ignoring warnings named "con_general" for device "eth8" with options
          """
          controller bond1
          port-type bond
          """
    *  Add "bond" connection named "bond1" for device "bond1" with options
          """
          autoconnect yes
          connection.autoconnect-ports true
          ipv4.method manual
          ipv4.addresses 172.16.1.2/24
          ipv6.method disabled
          """
    * Bring "up" connection "bond1"
    Then "GENERAL.STATE:.*activated" is visible with command "nmcli connection show bond1" in "25" seconds
    And "GENERAL.STATE:.*activated" is visible with command "nmcli connection show con_general" in "25" seconds
    And "bond1" is visible with command "nmcli -g connection.controller connection show con_general" in "10" seconds
    And "bond" is visible with command "nmcli -g connection.port-type connection show con_general" in "10" seconds
    And "1" is visible with command "nmcli -g connection.autoconnect-ports connection show bond1" in "10" seconds
    And Check bond "bond1" state is "up"


    @rhelver+=9
    @dbusmock_unittests
    Scenario: Execute dbusmock unittests
    * Cleanup execute "rm -rf .tmp/python-dbusmock"
    * Execute "cd .tmp; git clone https://github.com/martinpitt/python-dbusmock"
    * Execute "cd .tmp/python-dbusmock; python3l -m pytest tests/test_networkmanager.py"


    @RHEL-14438
    @ver+=1.51.3
    @NM_print_config
    Scenario: NM - general - Check --print-config option and config dir priorities
    * "Unlock" Image Mode
    * Commentary
      """
      Create dirs, if they are not present
      """
    * Execute "mkdir -p {/var/lib,/usr/lib,/etc,/run}/NetworkManager/conf.d"

    * Commentary
      """
      Create /var/lib internal config (impossible to overwrite from /run/, /usr/lib nor /etc)
      """
    * Create NM config file "/var/lib/NetworkManager/NetworkManager-intern.conf" with content
      """
      [.intern.global-dns]
      searches=var.lib.intern.conf
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /us/lib 01-custom config
      """
    * Create NM config file "/usr/lib/NetworkManager/conf.d/01-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_usr_lib_1
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /us/lib 02-custom config, overwrite section from 01-config
      """
    * Create NM config file "/usr/lib/NetworkManager/conf.d/02-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_usr_lib_2
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /run 01-custom config, overwrite sections from /usr/lib configs
      """
    * Create NM config file "/run/NetworkManager/conf.d/01-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_run_1
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /run 02-custom config, overwrite sections from /usr/lib configs and /run 01-custom
      """
    * Create NM config file "/run/NetworkManager/conf.d/02-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_run_2
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /etc 01-custom config, overwrite sections from /usr/lib and /run configs
      """
    * Create NM config file "/etc/NetworkManager/conf.d/01-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_etc_1
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_1" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Create /etc 02-custom config, overwrite sections from /usr/lib, /run configs and /etc 01-custom
      """
    * Create NM config file "/etc/NetworkManager/conf.d/02-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_etc_2
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_2" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Delete /etc 01 and 02 configs, create /etc 03-custom overwriting sections in /usr/lib and /run
      """
    * Execute "rm -f /etc/NetworkManager/conf.d/{01,02}-custom.conf"
    * Create NM config file "/etc/NetworkManager/conf.d/03-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_etc_3
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*03-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_3" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is visible with command "NetworkManager --print-config"

    * Commentary
      """
      Delete /var/lib internal config, modify /etc 03-custom not-overwriting section in /usr/lib and /run, /run 02-custom is active
      """
    * Execute "rm -f /var/lib/NetworkManager/NetworkManager-intern.conf"
    * Create NM config file "/etc/NetworkManager/conf.d/03-custom.conf" with content
      """
      [device-custom-ignore-carrier-3]
      match-device=interface-name:custom_etc_3
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*03-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_etc_3" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is not visible with command "NetworkManager --print-config"

    * Commentary
      """
      Delete /etc 03-custom, /run 01 and 02 configs, create /run 03-custom overwriting section in /usr/lib
      """
    * Execute "rm -f /etc/NetworkManager/conf.d/03-custom.conf"
    * Execute "rm -f /run/NetworkManager/conf.d/{01,02}-custom.conf"
    * Create NM config file "/run/NetworkManager/conf.d/03-custom.conf" with content
      """
      [device-custom-ignore-carrier]
      match-device=interface-name:custom_run_3
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*03-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*03-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/etc/NetworkManager/conf.d/[^/]*03-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_3" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is not visible with command "NetworkManager --print-config"

    * Commentary
      """
      Modify /run 03-custom not-overwriting section in /usr/lib, /usr/lib 02-custom is active
      """
    * Create NM config file "/run/NetworkManager/conf.d/03-custom.conf" with content
      """
      [device-custom-ignore-carrier-3]
      match-device=interface-name:custom_run_3
      ignore-carrier=no
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*03-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_3" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is not visible with command "NetworkManager --print-config"

    * Commentary
      """
      Mask /usr/lib 02-custom by empty file in /run, /run 03-custom and /usr/lib 01-custom are active
      """
    * Create NM config file "/run/NetworkManager/conf.d/02-custom.conf" with content
      """
      """
    Then "/var/lib/NetworkManager/NetworkManager-intern.conf" is not visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*01-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/usr/lib/NetworkManager/conf.d/[^/]*02-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*01-custom.conf" is not visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*02-custom.conf" is visible with command "NetworkManager --print-config"
    Then "/run/NetworkManager/conf.d/[^/]*03-custom.conf" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_1" is visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_usr_lib_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_1" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_2" is not visible with command "NetworkManager --print-config"
    Then "match-device=interface-name:custom_run_3" is visible with command "NetworkManager --print-config"
    Then "searches=var.lib.intern.conf" is not visible with command "NetworkManager --print-config"

    @RHEL-80273
    @ver+=1.53.3
    @nmcli_port_arguments_order
    Scenario: nmcli - general - port related arguments order
    * Commentary
      """
      This test case checks that specifying port-type, type or controller as last arguments in the
      command line is interpreted correctly. Port connections has more restrictions than non-port ones,
      like requiring a controller of the right type or not allowing IP configs.
      We will check that they fail for the right reason.
      """
    * Cleanup connection "nm-test1"
    * Cleanup connection "nm-test2"
    * Cleanup connection "nm-test3"
    * Cleanup connection "nm-test4"
    * Add "bond" connection named "bond0" for device "nm-bond" 
    Then "Warning: controller 'bond0' doesn't refer to any existing profile of type 'bridge'" is visible with command "nmcli connection add type ethernet ifname eth3 con-name nm-test1 controller bond0 port-type bridge" in "0" seconds
     And "Warning: controller 'bond0' doesn't refer to any existing profile of type 'bridge'" is visible with command "nmcli connection add ifname eth4 con-name nm-test2 controller bond0 type bridge-slave" in "0" seconds
     And "Error: invalid or not allowed setting 'ipv4'" is visible with command "nmcli connection add type ethernet ifname eth5 con-name nm-test3 ipv4.method disabled controller bond0 port-type bond" in "0" seconds
    * Add "ovs-interface" connection ignoring warnings named "ovs-if-br-ex" for device "br-ex" with options "controller ovs-port-phys0 autoconnect no"
    * Add "ovs-bridge" connection named "br-ex" for device "br-ex"
    * Commentary
      """
      In OVS there might be duplicated device names. Matching the controller only by interface name
      might choose the wrong controller. However, the type and port-type should restrict the type of the
      controller to be chosen.
      Important: we use `Execute` here to ensure that we are testing the order of the arguments
      """
    * Execute "nmcli connection add con-name nm-test4 ifname port1 controller br-ex autoconnect no type ovs-port port-type ovs-bridge"

    @RHEL-80273
    @ver+=1.53.3
    @nmcli_port_type_guess
    Scenario: nmcli - general - port-type guess
    * Add "bond" connection named "bond0" for device "nm-bond"
    * Add "ethernet" connection named "eth3" for device "eth3" with options "controller bond0"
    Then "bond" is visible with command "nmcli -g connection.port-type connection show eth3" in "0" seconds
    * Add "bridge" connection named "br0" for device "nm-bridge"
    * Add "ethernet" connection named "eth4" for device "eth4" with options "controller br0"
    Then "bridge" is visible with command "nmcli -g connection.port-type connection show eth4" in "0" seconds
    * Commentary
      """
      In OVS there might be duplicated device names. Guessing the port-type by the controller's type only
      is not possible, then. However, the connection's type enforces a specific port-type in this case:
      i.e. ovs-port can only have port-type=ovs-bridge.
      """
    * Add "ovs-interface" connection ignoring warnings named "ovs-if-br-ex" for device "br-ex" with options "controller ovs-port-phys0 autoconnect no"
    * Add "ovs-bridge" connection named "br-ex" for device "br-ex"
    * Add "ovs-port" connection named "ovs-port-phys0" for device "port1" with options "controller br-ex autoconnect no"
    Then "ovs-bridge" is visible with command "nmcli -g connection.port-type connection show ovs-port-phys0" in "0" seconds
