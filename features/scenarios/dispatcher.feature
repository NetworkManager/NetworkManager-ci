Feature: NM: dispatcher


    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz982633
    @permissive @disp
    @dispatcher_preup_and_up
    Scenario: NM - dispatcher - preup and up
    * Write dispatcher "pre-up.d/98-disp" file
    * Write dispatcher "99-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Bring "up" connection "testeth1"
    Then "pre-up" is visible with command "cat /tmp/dispatcher.txt"
    Then "pre-up.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "pre-up.*\s+up" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds

    @rhbz982633
    @permissive @disp
    @dispatcher_predown_and_down
    Scenario: NM - dispatcher - pre-down and down
    * Bring "up" connection "testeth1"
    * Write dispatcher "pre-down.d/97-disp" file
    * Write dispatcher "99-disp" file with params "if [ "$2" == "down" ]; then sleep 15; fi"
    * Bring "down" connection "testeth1"
    Then "pre-down" is visible with command "cat /tmp/dispatcher.txt"
    Then "pre-down.*\s+down" is not visible with command "cat /tmp/dispatcher.txt"
    Then "pre-down.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds

#    @dispatcher_vpn_up
#    Scenario: NM - dispatcher - vpn-up
#
#    @dispatcher_vpn_down
#    Scenario: NM - dispatcher - vpn-down

    @permissive @disp @restore_hostname
    @dispatcher_hostname
    Scenario: NM - dispatcher - hostname
    * Write dispatcher "99-disp" file
    * Execute "nmcli general hostname walderoon"
    Then "hostname" is visible with command "cat /tmp/dispatcher.txt"

#    @dispatcher_dhcp4_change
#    Scenario: NM - dispatcher - dhcp4-change
#
#    @dispatcher_dhcp6_change
#    Scenario: NM - dispatcher - dhcp6-change


    @rhbz1048345
    @permissive @disp
    @dispatcher_synchronicity
    Scenario: NM - dispatcher - synchronicity
    * Write dispatcher "99-disp" file
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Bring "up" connection "testeth1"
    Then "connected" is visible with command "nmcli device show eth1" in "45" seconds
    * Bring "down" connection "testeth1"
    Then "up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "up.*\s+up.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds


    @rhbz1048345
    @permissive @disp
    @dispatcher_synchronicity_with_predown
    Scenario: NM - dispatcher - synchronicity with predown
    * Write dispatcher "99-disp" file
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 15; fi"
    * Write dispatcher "pre-down.d/97-disp" file
    * Bring "up" connection "testeth1"
    * Bring "down" connection "testeth1" ignoring error
    Then "up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "up.*\s+up.*\s+pre-down.*\s+down" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds


    @rhbz1061212
    @permissive @disp
    @dispatcher_serialization
    Scenario: NM - dispatcher - serialization
    * Bring "down" connection "testeth1"
    * Bring "down" connection "testeth2"
    * Write dispatcher "98-disp" file with params "if [ "$2" == "up" ]; then sleep 10; echo $1 >> /tmp/dispatcher.txt; fi"
    * Write dispatcher "99-disp" file with params "if [ "$2" == "up" ]; then echo "quick$1" >> /tmp/dispatcher.txt; fi"
    * Bring "up" connection "testeth1"
    * Bring "up" connection "testeth2"
    #Then "eth1.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    #Then "eth2.*\s+up" is not visible with command "cat /tmp/dispatcher.txt"
    Then "eth1.*\s+up.*\s+quicketh1.*\s+up.*\s+eth2.*\s+up.*\s+quicketh2.*\s+up" is visible with command "cat /tmp/dispatcher.txt" in "50" seconds


    @rhbz2179537
    @ver+=1.43.5 @ver+=1.42.5 @ver+=1.40.19
    @ver/rhel/9/2+=1.42.2.19
    @permissive
    @dispatcher_dhcp4_change_on_renewal
    Scenario: NM - dispatcher - check that dhcp4-change is emitted on lease renewal
    * Write dispatcher "99-disp" file with params "[ "$2" != "dhcp4-change" ] && exit 0;"
    * Prepare simulated test "testX" device with "60" leasetime
    * Add "ethernet" connection named "con_ipv4" for device "testX" with options
          """
          autoconnect no
          ipv6.method disabled
          """
    * Bring "up" connection "con_ipv4"
    Then "dhcp4-change" is visible with command "cat /tmp/dispatcher.txt"
    * Execute "rm -f /tmp/dispatcher.txt"
    Then "dhcp4-change" is visible with command "cat /tmp/dispatcher.txt" in "90" seconds


    @rhbz1663253
    @ver+=1.20
    @permissive @disp @dhclient_DHCP
    @dispatcher_private_dhcp_option_dhclient
    Scenario: NM - dispatcher - private option 245 dhclient plugin
    * Prepare simulated test "testXd" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Write dispatcher "99-disp" file with params "[ "$2" != "up" ] && exit 0 || echo DHCP4_UNKNOWN_245=$DHCP4_UNKNOWN_245,DHCP4_PRIVATE_245=$DHCP4_PRIVATE_245 >> /tmp/dispatcher.txt"
    * Add "ethernet" connection named "con_ipv4" for device "testXd" with options "ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "DHCP4_UNKNOWN_245=aa:bb:cc:dd,DHCP4_PRIVATE_245=aa:bb:cc:dd" is visible with command "cat /tmp/dispatcher.txt" in "5" seconds

    @rhbz1663253
    @ver+=1.20
    @permissive @disp @internal_DHCP
    @dispatcher_private_dhcp_option_internal
    Scenario: NM - dispatcher - private dhcp option 245 internal plugin
    * Prepare simulated test "testXd" device with "192.168.99" ipv4 and "2620:dead:beaf" ipv6 dhcp address prefix and dhcp option "245,aa:bb:cc:dd"
    * Write dispatcher "99-disp" file with params "[ "$2" != "up" ] && exit 0 || echo DHCP4_UNKNOWN_245=$DHCP4_UNKNOWN_245,DHCP4_PRIVATE_245=$DHCP4_PRIVATE_245 >> /tmp/dispatcher.txt"
    * Add "ethernet" connection named "con_ipv4" for device "testXd" with options "ipv4.may-fail no"
    * Bring "up" connection "con_ipv4"
    Then "DHCP4_UNKNOWN_245=aa:bb:cc:dd,DHCP4_PRIVATE_245=aa:bb:cc:dd" is visible with command "cat /tmp/dispatcher.txt" in "5" seconds


    @rhbz1674550
    @ver+=1.19
    @permissive @disp
    @dispatcher_usr_lib_dir
    Scenario: NM - dispatcher - usr lib dir dispatcher scripts
    * Write dispatcher "/usr/lib/NetworkManager/dispatcher.d/99-disp" file
    * Bring "up" connection "testeth1"
    Then "up" is visible with command "cat /tmp/dispatcher.txt" in "10" seconds


    @rhbz1732791
    @ver+=1.25
    @openvswitch @restart_if_needed
    @dispatcher_restart
    Scenario: NM - dispatcher - do not block NM service restart
    * Restart NM
    * Execute "systemctl restart NetworkManager-dispatcher"
    * Add "ovs-bridge" connection named "ovs-bridge0" for device "ovsbridge0"
    * Add "ovs-port" connection named "ovs-port0" for device "port0" with options
          """
          conn.master ovsbridge0
          ovs-port.tag 120
          """
    * Add "ovs-interface" connection named "ovs-iface0" for device "iface0" with options
          """
          conn.master port0
          ip4 192.0.2.2/24
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show ovs-iface0" in "40" seconds
    When "inactive|unknown" is visible with command "systemctl is-active NetworkManager-dispatcher.service" in "30" seconds
    * Restart NM in background
    # If NM hangs this will be never shown
    When "deactivating" is not visible with command "systemctl status NetworkManager" in "10" seconds


    @rhbz2100456
    @ver+=1.41.3
    @ver/rhel/8+=1.36.0.9
    @kill_dnsmasq_ip4 @kill_dnsmasq_ip6
    @tshark
    @disp
    @dispatcher_interface_stuck_in_check_ip_state
    Scenario: nmcli - interface doesn't end up stuck in check-ip-state
    * Execute "rm -f /tmp/nmci-no-stub-resolv.conf"
    * Write dispatcher "00-dhcp-dns.sh" file with params
          """
          if [ "$1" != testX6 ] || [ "$2" != dhcp4-change ]; then
              # failure with exit code 77 will indicate no-op in NM log
              exit 77
          fi

          cp /run/NetworkManager/no-stub-resolv.conf /tmp/nmci-no-stub-resolv.conf || exit $?
          """
    * Prepare simulated test "testX6" device with a bridged peer with bridge options "mcast_snooping 0" and veths to namespaces "v4, v6"
    * Execute "ip -n v4 a add 192.168.99.1/24 dev veth0"
    * Execute "ip -n v6 a add 2620:dead:beaf::1/64 dev veth0"
    * Run child "ip netns exec v4 dnsmasq --log-facility=/tmp/dnsmasq_ip4.log --pid-file=/tmp/dnsmasq_ip4.pid --conf-file=/dev/null --no-hosts --dhcp-range=192.168.99.50,192.168.99.250,2m --dhcp-option=6,192.168.99.1" without shell
    #* Run child "ip netns exec v6 dnsmasq --log-facility=/tmp/dnsmasq_ip6.log --pid-file=/tmp/dnsmasq_ip6.pid --conf-file=/dev/null --no-hosts --enable-ra --dhcp-range=::,constructor:veth0,slaac,64,2m --dhcp-option=option6:dns-server,[2620:dead:beaf::1]"" without shell
    * Run child "ip netns exec testX6_ns tshark -n -l -i br0 'icmp6 or port 67 or port 68 or port 546 or port 547' > /tmp/tshark.log"
    * Execute "tc -n testX6_ns qdisc add dev v4 root netem delay 1900ms"
    * Execute "tc -n v4 qdisc add dev veth0 root netem delay 1900ms"
    * Add "ethernet" connection named "con_ipv6" for device "testX6"
    * Bring "up" connection "con_ipv6" ignoring error
    * "192.168.99" is visible with command "ip a show testX6" in "10" seconds
    * "/tmp/nmci-no-stub-resolv.conf" is file in "10" seconds
    Then "nameserver 192.168.99.1" is visible with command "cat /tmp/nmci-no-stub-resolv.conf"


    @RHEL-1435 @RHEL-1567
    @ver+=1.47.1
    @ver+=1.46
    @disp
    @dispatcher_device_handler_dummy
    Scenario: generic connection with device-handler to create a dummy interface
    * Write dispatcher "device/test-dummy" file copied from "dummy"
    * Add "generic" connection named "generic1" for device "dummy123" with options
          """
          generic.device-handler test-dummy
          ipv4.method manual
          ipv4.address 172.25.88.1/24
          """
    Then "generic1" is visible with command "nmcli -f name connection show --active" in "5" seconds
    And "100" is visible with command "nmcli -t -f general.state device show dummy123"
    And "dummy123" is visible with command "ip link show"
    And "172.25.88.1/24" is visible with command "ip addr show dev dummy123"

    * Bring "down" connection "generic1"
    Then "generic1" is not visible with command "nmcli -f name connection show --active"
    And "dummy123" is not visible with command "ip link show"

    * Bring "up" connection "generic1"
    Then "generic1" is visible with command "nmcli -f name connection show --active"
    * Bring "up" connection "generic1"
    Then "generic1" is visible with command "nmcli -f name connection show --active"

    * Restart NM
    Then "generic1" is visible with command "nmcli -f name connection show --active"
    And "dummy123" is visible with command "ip link show"


    @RHEL-1435 @RHEL-1567
    @ver+=1.47.1
    @ver+=1.46
    @disp
    @dispatcher_device_handler_dummy_in_bond
    Scenario: generic connection with device-handler to create a dummy interface in a bond
    * Write dispatcher "device/test-dummy" file copied from "dummy"
    * Add "bond" connection named "bond1" for device "bond1" with options
          """
          ipv4.method manual
          ipv4.address 172.25.88.1/24
	  """
    * Add "generic" connection named "generic1" for device "dummy123" with options
          """
          generic.device-handler test-dummy
          connection.master bond1
          connection.slave-type bond
          """
    Then "generic1" is visible with command "nmcli -f name connection show --active" in "5" seconds
    And "bond1" is visible with command "nmcli -f name connection show --active"
    And "100" is visible with command "nmcli -t -f general.state device show dummy123"
    And "100" is visible with command "nmcli -t -f general.state device show bond1"
    And "dummy123: .* master" is visible with command "ip link show"

    * Bring "down" connection "generic1"
    Then "generic1" is not visible with command "nmcli -f name connection show --active"
    And "dummy123" is not visible with command "ip link show"


    @RHEL-1435 @RHEL-1567
    @ver+=1.47.1
    @ver+=1.46
    @disp @keyfile
    @dispatcher_device_handler_geneve
    Scenario: generic connection with device-handler to create a geneve interface
    * Write dispatcher "device/test-geneve" file copied from "geneve"
    * Add "generic" connection named "generic-geneve1" for device "geneve1" with options
          """
          connection.autoconnect no
          generic.device-handler test-geneve
          ipv4.method manual
          ipv4.address 172.25.88.1/24
          """

    # nmcli doesn't support the user setting yet; modify the connection file directly
    * Execute "echo '[user]' >> /etc/NetworkManager/system-connections/generic-geneve1.nmconnection"
    * Execute "echo 'geneve.vni=1234' >> /etc/NetworkManager/system-connections/generic-geneve1.nmconnection"
    * Execute "echo 'geneve.remote=192.0.2.1' >> /etc/NetworkManager/system-connections/generic-geneve1.nmconnection"
    * Execute "nmcli connection reload"

    * Bring "up" connection "generic-geneve1"
    Then "generic-geneve1" is visible with command "nmcli -f name connection show --active" in "5" seconds
    And "100" is visible with command "nmcli -t -f general.state device show geneve1"
    And "geneve\s+id\s+1234\s+remote\s+192.0.2.1" is visible with command "ip -d link show dev geneve1"
    And "172.25.88.1/24" is visible with command "ip addr show dev geneve1"
    * Bring "up" connection "generic-geneve1"
    Then "generic-geneve1" is visible with command "nmcli -f name connection show --active" in "5" seconds

    * Restart NM
    Then "generic-geneve1" is visible with command "nmcli -f name connection show --active"
    And "100" is visible with command "nmcli -t -f general.state device show geneve1"
    And "geneve\s+id\s+1234\s+remote\s+192.0.2.1" is visible with command "ip -d link show dev geneve1"
    And "172.25.88.1/24" is visible with command "ip addr show dev geneve1"

    * Bring "down" connection "generic-geneve1"
    Then "generic-geneve1" is not visible with command "nmcli -f name connection show --active"
    And "geneve1" is not visible with command "ip link show"


    @RHEL-1671 @RHEL-10195
    @ver/rhel/8/6+=1.36.0.17
    @ver/rhel/8/8+=1.40.16.6
    @ver/rhel/8/9+=1.40.16.11
    @ver/rhel/9/2+=1.42.2.11
    @ver/rhel/9/3+=1.44.0.4
    @ver/rhel/8+=1.40.16.12
    @ver+=1.45.4
    @ver/rhel/9/4-=1.46.0.1
    @ver/rhel/9/2-=1.42.2.13
    @ver/rhel/9/3-=1.44.0.5
    @ver-=1.47.2
    @not_on_s390x @not_on_ppc64 @not_on_aarch64
    @restore_resolvconf @restart_if_needed
    @dispatcher_track_dns_changes
    Scenario: NM - dispatcher - track dns changes
    * Cleanup execute with timeout "15" seconds
      """
      echo 'dns-resolver:
        config: {}' | nmstatectl apply -
      """
    * Cleanup NM config file "/var/lib/NetworkManager/NetworkManager-intern.conf"
    * Write file "/tmp/change_global_dns.yaml" with content
      """
      dns-resolver:
        config:
          search:
            - example.com
            - example.org
          server:
            - 2001:4860:4860::8888
            - 8.8.8.8
            - 2606:4700:4700::1111
            - 8.8.4.4
      """
     * Start following journal
     * Commentary
      """
      We modified the global dns configuration and we expect that the dispatcher event 'dns-change' will be triggered.
      """
     * Execute "nmstatectl apply /tmp/change_global_dns.yaml"
     Then "NM_DISPATCHER_ACTION=dns-change" is visible in journal in "10" seconds
     * Start following journal
     * Commentary
      """
      The dispatcher event 'dns-change' should not be triggered again, since there was no change in the dns configuration.
      """
     * Execute "echo '{}' | nmstatectl apply -"
     Then "NM_DISPATCHER_ACTION=dns-change" is not visible in journal in "10" seconds


    @RHEL-1671 @RHEL-10195 @RHEL-23446 @RHEL-29725 @RHEL-29723 @RHEL-29724
    @ver/rhel/9/4+=1.46.0.2
    @ver/rhel/9/3+=1.44.0.6
    @ver/rhel/9/2+=1.42.2.14
    @ver+=1.47.3
    @not_on_s390x @not_on_ppc64 @not_on_aarch64
    @restore_resolvconf @restart_if_needed
    @dispatcher_track_dns_changes
    Scenario: NM - dispatcher - track dns changes
    * Ensure that version of "nmstate" package is at least "2.2.27"
    * Cleanup execute with timeout "15" seconds
      """
      echo 'dns-resolver:
        config: {}' | nmstatectl apply -
      """
    * Cleanup NM config file "/var/lib/NetworkManager/NetworkManager-intern.conf"
    * Write file "/tmp/change_global_dns.yaml" with content
      """
      dns-resolver:
        config:
          search:
            - example.com
            - example.org
          server:
            - 2001:4860:4860::8888
            - 8.8.8.8
            - 2606:4700:4700::1111
            - 8.8.4.4
      """
     * Start following journal
     * Commentary
      """
      We modified the global dns configuration and we expect that the dispatcher event 'dns-change' will be triggered.
      """
     * Execute "nmstatectl apply /tmp/change_global_dns.yaml --no-commit"
     Then "NM_DISPATCHER_ACTION=dns-change" is visible in journal in "10" seconds
     * Execute "nmstatectl rollback"
     * Commentary
      """
      /etc/reslov.conf should be restored to the original state.
      """
     Then "2001:4860:4860::8888" is not visible with command "cat /etc/resolv.conf" in "15" seconds
     * Commentary
      """
      Since the the changes were rolled back, we need to apply the config again.
      """
     * Execute "nmstatectl apply /tmp/change_global_dns.yaml"
     * Wait for "10" seconds
     * Start following journal
     * Commentary
      """
      The dispatcher event 'dns-change' should not be triggered again, since there was no change in the dns configuration.
      """
     * Execute "echo '{}' | nmstatectl apply -"
     Then "NM_DISPATCHER_ACTION=dns-change" is not visible in journal in "10" seconds
