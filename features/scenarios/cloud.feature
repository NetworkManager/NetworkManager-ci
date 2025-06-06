Feature: nmcli: cloud


    @ver+=1.43.8.2
    @cloud_aliyun_basic
    Scenario: cloud - aliyun - Basic Aliyun nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock Aliyun device with MAC "CC:00:00:00:00:01", IPs "172.31.176.249" and "172.31.17.249", netmask "255.255.240.0", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "aliyun" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "5" seconds
    * Mock Aliyun IP addresses "172.31.186.249" and "172.31.18.249" with mask "255.255.240.0" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "aliyun" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "5" seconds


    @ver+=1.43.8.2
    @cloud_azure_basic
    Scenario: cloud - azure - Basic Azure nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock Azure device "0" with MAC "CC:00:00:00:00:01", IPs "172.31.176.249" and "172.31.17.249" and subnet "172.31.16.0/20"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "azure" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "5" seconds
    * Mock Azure IP addresses "172.31.186.249" and "172.31.18.249" for device "0"
    * Execute nm-cloud-setup for "azure" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "5" seconds


    @RHEL-56387
    @ver+=1.50
    @ver+=1.48.10.2
    @ver+=1.46.3
    @ver/rhel/9/4+=1.46.0.19
    @ver/rhel/8+=1.40.16.19
    @prepare_patched_netdevsim
    @cloud_azure_primary_address_race
    Scenario: cloud - azure - Basic Azure with primary address delayed
    * Start test-cloud-meta-mock.py
    * Add "dummy" connection named "azure_dummy" for device "dummy1" with options "ipv4.method static ipv4.addresses 169.254.169.254"
    * Cleanup execute "iptables -t nat -D PREROUTING -i dummy1 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:19080"
    * Cleanup execute "iptables -t nat -D OUTPUT -s 169.254.169.254 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:19080"
    * Execute "iptables -t nat -A PREROUTING -i dummy1 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:19080"
    * Execute "iptables -t nat -A OUTPUT -s 169.254.169.254 -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:19080"
    * Add "ethernet" connection named "conX1" for device "eth11" with options "autoconnect no ipv4.method static ipv4.addresses 192.168.101.11/24"
    * Bring "up" connection "conX1"
    * Note MAC address output for device "eth11" via ip command as "eth11"
    * Mock Azure device "0" with MAC "eth11", IPs "172.31.176.249" and "172.31.17.249" and subnet "172.31.16.0/20"
    * Mock Azure forced delay on primary address for device "0"
    * Check "ipv4" address list "192.168.101.11/24" on device "eth11" in "5" seconds
    * Execute nm-cloud-setup for "azure" with mapped interfaces "eth11=<noted:eth11>"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "eth11" in "5" seconds
    * Mock Azure IP addresses "172.31.186.249" and "172.31.18.249" for device "0"
    * Mock Azure forced delay on primary address for device "0"
    * Execute nm-cloud-setup for "azure" with mapped interfaces "eth11=<noted:eth11>"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "eth11" in "5" seconds


    @ver+=1.43.8.2
    @cloud_ec2_basic
    Scenario: cloud - ec2 - Basic EC2 nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock EC2 device with MAC "CC:00:00:00:00:01", IPs "172.31.176.249" and "172.31.17.249" and subnet "172.31.16.0/20"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "5" seconds
    * Mock EC2 IP addresses "172.31.186.249" and "172.31.18.249" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "5" seconds


    @ver+=1.43.8.2
    @cloud_gcp_basic
    Scenario: cloud - gcp - Basic GCP nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock GCP device "0" with MAC "CC:00:00:00:00:01" and IPs "172.31.176.249" and "172.31.17.249"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "gcp" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then "local 172.31.176.249 dev testX1 table local proto static scope host metric 100" is visible with command "ip route show table all" in "5" seconds
    Then "local 172.31.17.249 dev testX1 table local proto static scope host metric 100" is visible with command "ip route show table all" in "5" seconds


    @ver+=1.51.3
    @cloud_oci_basic_vm
    Scenario: cloud - OCI (Virtual Machine instance) - Basic Oracle Cloud nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock OCI (VM) device "0" with MAC "CC:00:00:00:00:01", IP "172.31.176.249", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Commentary
      """
      This additional mocked device is needed because nm-cloud-setup skips configuring if there is
      only 1 interface with 1 address. In OCI we cannot add 2 addresses to an interface, so we
      return 2 interfaces from the mock server. The 2nd won't be found by nm-c-s, so skipped.
      """
    * Mock OCI (VM) device "1" with MAC "CC:00:00:00:00:02", IP "172.31.186.249", subnet "172.31.16.0/20" and gateway "172.31.186.1"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20" on device "testX1" in "5" seconds
    * Mock OCI IP address "172.31.186.249" for device "0"
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20" on device "testX1" in "5" seconds


    @ver+=1.51.91
    @cloud_oci_basic_baremetal
    Scenario: cloud - OCI (baremetal instance) - Basic Oracle Cloud nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Prepare simulated test "testX2" device with "192.168.101.12" ipv4 and "2620:52:0:beef" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Add "ethernet" connection named "conX2" for device "testX2" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Bring "up" connection "conX2"
    When Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
     And Check "ipv4" address list "192.168.101.12/24" on device "testX2" in "5" seconds
    * Mock OCI (baremetal) physical device "0" with NIC index "0", MAC "CC:00:00:00:00:01", IP "172.31.176.249", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Mock OCI (baremetal) physical device "1" with NIC index "1", MAC "CC:00:00:00:00:02", IP "172.31.176.250", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01;testX2=CC:00:00:00:00:02"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20" on device "testX1" in "5" seconds
     And Check "ipv4" address list "192.168.101.12/24 172.31.176.250/20" on device "testX2" in "5" seconds
    * Mock OCI IP address "172.31.186.249" for device "0"
    * Mock OCI IP address "172.31.186.250" for device "1"
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01;testX2=CC:00:00:00:00:02"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20" on device "testX1" in "5" seconds
     And Check "ipv4" address list "192.168.101.12/24 172.31.186.250/20" on device "testX2" in "5" seconds


    @ver+=1.51.91
    @cloud_oci_baremetal_with_vlan
    Scenario: cloud - OCI (baremetal instance) - Oracle Cloud with VLANs nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    When Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Mock OCI (baremetal) physical device "0" with NIC index "0", MAC "CC:00:00:00:00:01", IP "172.31.176.249", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Mock OCI (baremetal) VLAN device "1" with parent "0" MAC "CC:00:00:00:00:02", IP "172.31.176.250", subnet "172.31.16.0/20", gateway "172.31.176.1" and VLAN tag "123"
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01"
    * Commentary
      """
      Macvlan's name is 'macvlanX', being X the interface index in the JSON array from the metadata.
      VLAN's name is 'parent.vlan_id'.
      """
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20" on device "testX1" in "5" seconds
     And macvlan device "macvlan1" check for parent "testX1" and MAC address "CC:00:00:00:00:02"
     And Check there are no "ipv4" addresses on device "macvlan1" in "5" seconds
     And vlan device "macvlan1.123" check for parent "macvlan1", MAC address "CC:00:00:00:00:02" and VLAN ID "123"
     And Check "ipv4" address list "172.31.176.250/20" on device "macvlan1.123" in "5" seconds
    * Mock OCI IP address "172.31.186.249" for device "0"
    * Mock OCI IP address "172.31.186.250" for device "1"
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20" on device "testX1" in "5" seconds
     And macvlan device "macvlan1" check for parent "testX1" and MAC address "CC:00:00:00:00:02"
     And Check there are no "ipv4" addresses on device "macvlan1" in "5" seconds
     And vlan device "macvlan1.123" check for parent "macvlan1", MAC address "CC:00:00:00:00:02" and VLAN ID "123"
     And Check "ipv4" address list "172.31.186.250/20" on device "macvlan1.123" in "5" seconds
    * Commentary
      """
      Here nm-cloud-setup is supposed to modify existing MACVLAN and VLAN devices, not to
      create new ones. Ensure that we still have only one of each.
      """
    Then "Exactly" "1" lines are visible with command "ip -br link show type macvlan"
     And "Exactly" "1" lines are visible with command "ip -br link show type vlan"


    @ver+=1.53.2.2
    @cloud_oci_vm_vnic
    Scenario: cloud - OCI - Apply config also on non DHCP device in VMs
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with MAC address "CC:00:00:00:00:01" and "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Prepare simulated test "testX2" device with MAC address "CC:00:00:00:00:02" and without DHCP
    * Add "ethernet" connection named "conX1" for device "testX1"
    * Commentary
        """
        This step is removed as even disconnected device should connect.
        * Add "ethernet" connection named "conX2" for device "testX2"

        """
    * Mock OCI (VM) device "0" with MAC "CC:00:00:00:00:01", IP "172.31.176.249", subnet "172.31.16.0/20" and gateway "172.31.176.1"
    * Mock OCI (VM) device "1" with MAC "CC:00:00:00:00:02", IP "172.31.186.249", subnet "172.31.16.0/20" and gateway "172.31.186.1"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "oci" with mapped interfaces "testX1=CC:00:00:00:00:01;testX2=CC:00:00:00:00:02"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20" on device "testX1" in "5" seconds
    Then Check "ipv4" address list "172.31.186.249/20" on device "testX2" in "5" seconds


    @rhbz2214880
    @ver+=1.43.10
    @skip_in_centos
    @cloud_no_provider_warning
    Scenario: cloud - warn user about no available providers
    * Execute "mkdir -p /etc/systemd/system/nm-cloud-setup.service.d"
    * Write file "/etc/systemd/system/nm-cloud-setup.service.d/overrides.conf" with content
      """
      [Service]
      Environment=NM_CLOUD_SETUP_EC2=yes NM_CLOUD_SETUP_LOG=warn
      """
    * Start following journal
    * Execute "systemctl daemon-reload"
    * Execute "systemctl restart nm-cloud-setup.service"
    Then "no provider detected" is visible in journal in "60" seconds


    @rhbz2151040
    @ver+=1.43.10
    @cloud_setup_keep_secondary_ips
    Scenario: cloud - ec2 - keep secondary addresses or a device
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no ipv4.may-fail no"
    * Bring "up" connection "conX1"
    * Execute "ip addr add 192.168.100.200/24 dev testX1"
    * Mock EC2 device with MAC "CC:00:00:00:00:01", IPs "172.31.176.249" and "172.31.17.249" and subnet "172.31.16.0/20"
    * Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24" on device "testX1" in "5" seconds
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "5" seconds
    * Mock EC2 IP addresses "172.31.186.249" and "172.31.18.249" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "5" seconds


    @rhbz2207812
    @ver+=1.40.16.2000
    # VVV Fix was not backported to RHEL8.8
    @ver/rhel/8/8-
    @ver/rhel/8+=1.40.16.9
    @ver/rhel/9+=1.43.10
    @prepare_patched_netdevsim
    @cloud_ec2_race_with_3_interfaces
    Scenario: cloud - ec2 - EC2 nm-cloud-setup check race with 3 interfaces
    * Start test-cloud-meta-mock.py
    * Add "ethernet" connection named "conX1" for device "eth11" with options "autoconnect no ipv4.address 192.168.100.5/24 ipv4.method manual"
    * Add "ethernet" connection named "conX2" for device "eth12" with options "autoconnect no ipv4.address 192.168.101.5/24 ipv4.method manual"
    * Add "ethernet" connection named "conX3" for device "eth13" with options "autoconnect no ipv4.address 192.168.102.5/24 ipv4.method manual"
    * Note MAC address output for device "eth11" via ip command as "eth11"
    * Note MAC address output for device "eth12" via ip command as "eth12"
    * Note MAC address output for device "eth13" via ip command as "eth13"
    * Bring "up" connection "conX1"
    * Bring "up" connection "conX2"
    * Bring "up" connection "conX3"
    * Check "ipv4" address list "/192.168.100.[0-9/]+" on device "eth11"
    * Check "ipv4" address list "/192.168.101.[0-9/]+" on device "eth12"
    * Check "ipv4" address list "/192.168.102.[0-9/]+" on device "eth13"
    * Mock EC2 device with MAC "eth13", IPs "172.31.176.251" and "172.31.17.251" and subnet "172.31.16.0/20"
    * Mock EC2 device with MAC "eth12", IPs "172.31.176.250" and "172.31.17.250" and subnet "172.31.16.0/20"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "eth12=<noted:eth12>;eth13=<noted:eth13>"
    * Check "ipv4" address list "/192.168.100.[0-9/]+" on device "eth11"
    Then Check "ipv4" address list "/192.168.101.[0-9/]+ 172.31.176.250/20 172.31.17.250/20" on device "eth12" in "5" seconds
    Then Check "ipv4" address list "/192.168.102.[0-9/]+ 172.31.176.251/20 172.31.17.251/20" on device "eth13" in "5" seconds
    * Commentary
      """
      The order of rules should match the order in the step * Mock EC2 device ...
      In this case, *.251 and then *.250 (eth13 and then eth12)
      If this is not true in future versions, the check for order can be skipped.
      """
    Then "172.31.176.251 .*172.31.176.250 .*172.31.176.251 .*172.31.176.250" is visible with command "ip rule"
    * Clear EC2 mocks
    * Mock EC2 device with MAC "eth11", IP "172.31.176.249" and subnet "172.31.16.0/20"
    * Mock EC2 device with MAC "eth13", IPs "172.31.176.251" and "172.31.17.251" and subnet "172.31.16.0/20"
    * Mock EC2 device with MAC "eth12", IPs "172.31.176.250" and "172.31.17.250" and subnet "172.31.16.0/20"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "eth11=<noted:eth11>;eth12=<noted:eth12>;eth13=<noted:eth13>" in background
    * Expect "<debug> config device [0-9A-Fa-f:]*: reapply" in children in "20" seconds and kill
    Then Check "ipv4" address list "/192.168.100.[0-9/]+ 172.31.176.249/20" on device "eth11" in "5" seconds
    Then Check "ipv4" address list "/192.168.101.[0-9/]+ 172.31.176.250/20 172.31.17.250/20" on device "eth12" in "5" seconds
    Then Check "ipv4" address list "/192.168.102.[0-9/]+ 172.31.176.251/20 172.31.17.251/20" on device "eth13" in "5" seconds
    * Commentary
      """
      The order of rules should match the order in the step * Mock EC2 device ...
      In this case, *.249, *.251 and then *.250 (eth11, eth13 and then eth12)
      If this is not true in future versions, the check for order can be skipped.
      If SIGTERM not ignored (regression), table ID for *.249 address will be the same as *.251
      """
    Then "172.31.176.249 .*172.31.176.251 .*172.31.176.250 .*172.31.176.249 .*172.31.176.251 .*172.31.176.250" is visible with command "ip rule"
    * Note the output of "ip rule | grep -F 172.31.176.249 | grep -o ^[0-9]*" as value "eth11_table"
    * Note the output of "ip rule | grep -F 172.31.176.250 | grep -o ^[0-9]*" as value "eth12_table"
    * Note the output of "ip rule | grep -F 172.31.176.251 | grep -o ^[0-9]*" as value "eth13_table"
    Then Check noted values "eth11_table" and "eth12_table" are not the same
    And Check noted values "eth11_table" and "eth13_table" are not the same


    @RHEL-56740
    @ver+=1.50
    @ver+=1.48.10.2
    @ver+=1.46.3
    @ver/rhel/9/4+=1.46.0.19
    @nm_cloud_setup_burst_limit
    Scenario: cloud - setup - allow 100 restarts in 1 second
    * Commentary
      """
      Every pre-up and dhcp4-change triggers a nm-c-s restart
      so in case of many devices (100/s is OK up to 50) we need
      to have larger systemd restart limit to avoid entering
      failed state. Check that we don't lose this along the way.
      """
    Then "100$" is visible with command "grep StartLimitBurst /usr/lib/systemd/system/nm-cloud-setup.service"
    Then "1$" is visible with command "grep StartLimitIntervalSec /usr/lib/systemd/system/nm-cloud-setup.service"
