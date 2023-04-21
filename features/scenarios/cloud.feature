Feature: nmcli: cloud

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @cloud
    @ethernet
    @cloud_aliyun_basic
    Scenario: cloud - aliyun - Basic Aliyun nm-cloud-setup checks
    * Bring "up" connection "testeth1"
    * Note MAC address output for device "eth0" via ip command as "mac0"
    * Mock Aliyun metadata for device with MAC address "mac0"
    * Mock Aliyun CIDR block "172.31.16.0/20" for device with MAC address "mac0"
    * Mock Aliyun IP addresses "172.31.176.249" and "172.31.17.249" with mask "255.255.240.0" for device with MAC address "mac0"
    * Mock Aliyun Gateway "172.31.176.1" for device with MAC address "mac0"
    * Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$" on device "eth0"
    #* Execute "bash"
    * Execute "NM_CLOUD_SETUP_ALIYUN=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.176.249/20 172.31.17.249/20" on device "eth0"
    * Mock Aliyun IP addresses "172.31.186.249" and "172.31.18.249" with mask "255.255.240.0" for device with MAC address "mac0"
    * Execute "NM_CLOUD_SETUP_ALIYUN=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.186.249/20 172.31.18.249/20" on device "eth0"


    @cloud
    @ethernet
    @cloud_azure_basic
    Scenario: cloud - azure - Basic Azure nm-cloud-setup checks
    * Bring "up" connection "testeth1"
    * Note MAC address output for device "eth0" via ip command as "mac0"
    * Mock Azure metadata for device "0" with MAC address "mac0"
    * Mock Azure IP addresses "172.31.176.249" and "172.31.17.249" with for device "0"
    * Mock Azure subnet "172.31.16.0" with prefix "20" for device "0"
    * Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$" on device "eth0"
    * Execute "NM_CLOUD_SETUP_AZURE=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.176.249/20 172.31.17.249/20" on device "eth0"
    * Mock Azure IP addresses "172.31.186.249" and "172.31.18.249" with for device "0"
    * Execute "NM_CLOUD_SETUP_AZURE=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.186.249/20 172.31.18.249/20" on device "eth0"


    @cloud
    @ethernet
    @cloud_ec2_basic
    Scenario: cloud - ec2 - Basic EC2 nm-cloud-setup checks
    * Bring "up" connection "testeth1"
    * Note MAC address output for device "eth0" via ip command as "mac0"
    * Mock EC2 metadata for device with MAC address "mac0"
    * Mock EC2 CIDR block "172.31.16.0/20" for device with MAC address "mac0"
    * Mock EC2 IP addresses "172.31.176.249" and "172.31.17.249" for device with MAC address "mac0"
    * Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$" on device "eth0"
    * Execute "NM_CLOUD_SETUP_EC2=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.176.249/20 172.31.17.249/20" on device "eth0"
    * Mock EC2 IP addresses "172.31.186.249" and "172.31.18.249" for device with MAC address "mac0"
    * Execute "NM_CLOUD_SETUP_EC2=yes NM_CLOUD_SETUP_LOG=trace /usr/libexec/nm-cloud-setup"
    Then Check "ipv4" address list "/192.168.[0-9]+.[0-9]+/24$ 172.31.186.249/20 172.31.18.249/20" on device "eth0"
