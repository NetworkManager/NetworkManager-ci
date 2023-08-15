Feature: nmcli: cloud


    @ver+=1.43.8.2
    @cloud_aliyun_basic
    Scenario: cloud - aliyun - Basic Aliyun nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock Aliyun metadata for device with MAC address "CC:00:00:00:00:01"
    * Mock Aliyun CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:01"
    * Mock Aliyun IP addresses "172.31.176.249" and "172.31.17.249" with mask "255.255.240.0" for device with MAC address "CC:00:00:00:00:01"
    * Mock Aliyun Gateway "172.31.176.1" for device with MAC address "CC:00:00:00:00:01"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    * Execute nm-cloud-setup for "aliyun" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "2" seconds
    * Mock Aliyun IP addresses "172.31.186.249" and "172.31.18.249" with mask "255.255.240.0" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "aliyun" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "2" seconds


    @ver+=1.43.8.2
    @cloud_azure_basic
    Scenario: cloud - azure - Basic Azure nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock Azure metadata for device "0" with MAC address "CC:00:00:00:00:01"
    * Mock Azure IP addresses "172.31.176.249" and "172.31.17.249" with for device "0"
    * Mock Azure subnet "172.31.16.0" with prefix "20" for device "0"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    * Execute nm-cloud-setup for "azure" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "2" seconds
    * Mock Azure IP addresses "172.31.186.249" and "172.31.18.249" with for device "0"
    * Execute nm-cloud-setup for "azure" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "2" seconds


    @ver+=1.43.8.2
    @cloud_ec2_basic
    Scenario: cloud - ec2 - Basic EC2 nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock EC2 metadata for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 IP addresses "172.31.176.249" and "172.31.17.249" for device with MAC address "CC:00:00:00:00:01"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "2" seconds
    * Mock EC2 IP addresses "172.31.186.249" and "172.31.18.249" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "2" seconds


    @ver+=1.43.8.2
    @cloud_gcp_basic
    Scenario: cloud - gcp - Basic GCP nm-cloud-setup checks
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Mock GCP metadata for device "0" with MAC address "CC:00:00:00:00:01"
    * Mock GCP IP addresses "172.31.176.249" and "172.31.17.249" with for device "0"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    * Execute nm-cloud-setup for "gcp" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then "local 172.31.176.249 dev testX1 table local proto static scope host metric 100" is visible with command "ip route show table all"
    Then "local 172.31.17.249 dev testX1 table local proto static scope host metric 100" is visible with command "ip route show table all"


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
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Execute "ip addr add 192.168.100.200/24 dev testX1"
    * Mock EC2 metadata for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 IP addresses "172.31.176.249" and "172.31.17.249" for device with MAC address "CC:00:00:00:00:01"
    * Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24" on device "testX1"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24 172.31.176.249/20 172.31.17.249/20" on device "testX1" in "2" seconds
    * Mock EC2 IP addresses "172.31.186.249" and "172.31.18.249" for device with MAC address "CC:00:00:00:00:01"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01"
    Then Check "ipv4" address list "192.168.101.11/24 192.168.100.200/24 172.31.186.249/20 172.31.18.249/20" on device "testX1" in "2" seconds


    @rhbz2207812
    @ver+=1.43.10
    @cloud_ec2_race_with_3_interfaces
    Scenario: cloud - ec2 - EC2 nm-cloud-setup check race with 3 interfaces
    * Start test-cloud-meta-mock.py
    * Prepare simulated test "testX1" device with "192.168.101.11" ipv4 and "2620:52:0:dead" ipv6 dhcp address prefix
    * Prepare simulated test "testX2" device with "192.168.102.11" ipv4 and "2620:53:0:dead" ipv6 dhcp address prefix
    * Prepare simulated test "testX3" device with "192.168.103.11" ipv4 and "2620:54:0:dead" ipv6 dhcp address prefix
    * Add "ethernet" connection named "conX1" for device "testX1" with options "autoconnect no"
    * Add "ethernet" connection named "conX2" for device "testX2" with options "autoconnect no"
    * Add "ethernet" connection named "conX3" for device "testX3" with options "autoconnect no"
    * Bring "up" connection "conX1"
    * Bring "up" connection "conX2"
    * Bring "up" connection "conX3"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    * Check "ipv4" address list "192.168.102.11/24" on device "testX2"
    * Check "ipv4" address list "192.168.103.11/24" on device "testX3"
    * Mock EC2 metadata for devices with MAC addresses "CC:00:00:00:00:03,CC:00:00:00:00:02"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:02"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "CC:00:00:00:00:03"
    * Mock EC2 IP address "172.31.176.249" for device with MAC address "CC:00:00:00:00:01"
    * Mock EC2 IP addresses "172.31.176.250" and "172.31.17.250" for device with MAC address "CC:00:00:00:00:02"
    * Mock EC2 IP addresses "172.31.176.251" and "172.31.17.251" for device with MAC address "CC:00:00:00:00:03"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX2=CC:00:00:00:00:02;testX3=CC:00:00:00:00:03"
    * Check "ipv4" address list "192.168.101.11/24" on device "testX1"
    Then Check "ipv4" address list "192.168.102.11/24 172.31.176.250/20 172.31.17.250/20" on device "testX2" in "2" seconds
    Then Check "ipv4" address list "192.168.103.11/24 172.31.176.251/20 172.31.17.251/20" on device "testX3" in "2" seconds
    * Commentary
      """
      The order of rules should match the order in the step * Mock EC2 metadata ...
      In this case, *.251 and then *.251 (CC:...:03 and then CC:...:02)
      If this is not true in future versions, the check for order can be skipped.
      """
    Then "172.31.176.251 .*172.31.176.250 .*172.31.176.251 .*172.31.176.250" is visible with command "ip rule"
    * Mock EC2 metadata for devices with MAC addresses "CC:00:00:00:00:01,CC:00:00:00:00:02,CC:00:00:00:00:03"
    * Execute nm-cloud-setup for "ec2" with mapped interfaces "testX1=CC:00:00:00:00:01;testX2=CC:00:00:00:00:02;testX3=CC:00:00:00:00:03" in background
    * Expect "<debug> config device CC:00:00:00:00:01: reapply" in children in "10" seconds and kill
    Then Check "ipv4" address list "192.168.101.11/24 172.31.176.249/20" on device "testX1" in "2" seconds
    Then Check "ipv4" address list "192.168.102.11/24 172.31.176.250/20 172.31.17.250/20" on device "testX2" in "2" seconds
    Then Check "ipv4" address list "192.168.103.11/24 172.31.176.251/20 172.31.17.251/20" on device "testX3" in "2" seconds
    * Commentary
      """
      The order of rules should match the order in the step * Mock EC2 metadata ...
      In this case, *.249, *.250 and then *.251 (CC:...:01, CC:...:02 and then CC:...:03)
      If this is not true in future versions, the check for order can be skipped.
      If SIGTERM not ignored (regression), table ID for *.249 address will be the same as *.251
      """
    Then "172.31.176.249 .*172.31.176.250 .*172.31.176.251 .*172.31.176.249 .*172.31.176.250 .*172.31.176.251" is visible with command "ip rule"
    * Note the output of "ip rule | grep -F 172.31.176.249 | grep -o ^[0-9]*" as value "testX1"
    * Note the output of "ip rule | grep -F 172.31.176.250 | grep -o ^[0-9]*" as value "testX2"
    * Note the output of "ip rule | grep -F 172.31.176.251 | grep -o ^[0-9]*" as value "testX3"
    Then Check noted values "testX1" and "testX2" are not the same
    And Check noted values "testX1" and "testX3" are not the same