Feature: nmcli: cloud


    @ver+=1.43.8
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


    @ver+=1.43.8
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


    @ver+=1.43.8
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
