 Feature: nmcli: alias

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @alias @ifcfg-rh
    @alias_ifcfg_add_single_alias
    Scenario: ifcfg - alias - add single alias
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"
    * Reload connections
    * Bring "up" connection "eth7"

    Then "inet 192.168.0.101" is visible with command "ip a s eth7"
    Then "inet 192.168.0.100" is visible with command "ip a s eth7"

    @alias @ifcfg-rh
    @alias_ifcfg_add_multiple_aliases
    Scenario: ifcfg - alias - add mutliple aliases
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"

    * Append "DEVICE='eth7:1'" to ifcfg file "eth7:1"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:1"
    * Append "IPADDR=192.168.0.102" to ifcfg file "eth7:1"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:1"

    * Append "DEVICE='eth7:2'" to ifcfg file "eth7:2"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:2"
    * Append "IPADDR=192.168.0.103" to ifcfg file "eth7:2"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:2"

    * Reload connections
    * Bring "up" connection "eth7"

    Then "inet 192.168.0.100" is visible with command "ip a s eth7"
    Then "inet 192.168.0.101" is visible with command "ip a s eth7"
    Then "inet 192.168.0.102" is visible with command "ip a s eth7"
    Then "inet 192.168.0.103" is visible with command "ip a s eth7"


    @alias @ifcfg-rh
    @alias_ifcfg_connection_restart
    Scenario: ifcfg - alias - connection restart
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"

    * Append "DEVICE='eth7:1'" to ifcfg file "eth7:1"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:1"
    * Append "IPADDR=192.168.0.102" to ifcfg file "eth7:1"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:1"

    * Append "DEVICE='eth7:2'" to ifcfg file "eth7:2"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:2"
    * Append "IPADDR=192.168.0.103" to ifcfg file "eth7:2"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:2"

    * Reload connections
    * Bring "up" connection "eth7"
    * Bring "down" connection "eth7"
    * Bring "up" connection "eth7"

    Then "inet 192.168.0.100" is visible with command "ip a s eth7"
    Then "inet 192.168.0.101" is visible with command "ip a s eth7"
    Then "inet 192.168.0.102" is visible with command "ip a s eth7"
    Then "inet 192.168.0.103" is visible with command "ip a s eth7"


    @alias @ifcfg-rh
    @alias_ifcfg_remove_single_alias
    Scenario: ifcfg - alias - remove single alias
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"

    * Append "DEVICE='eth7:1'" to ifcfg file "eth7:1"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:1"
    * Append "IPADDR=192.168.0.102" to ifcfg file "eth7:1"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:1"

    * Append "DEVICE='eth7:2'" to ifcfg file "eth7:2"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:2"
    * Append "IPADDR=192.168.0.103" to ifcfg file "eth7:2"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:2"

    * Reload connections
    * Bring "up" connection "eth7"
    * Execute "sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:0"
    * Reload connections
    * Bring "up" connection "eth7"

    Then "inet 192.168.0.100" is visible with command "ip a s eth7"
    Then "inet 192.168.0.101" is not visible with command "ip a s eth7"
    Then "inet 192.168.0.102" is visible with command "ip a s eth7"
    Then "inet 192.168.0.103" is visible with command "ip a s eth7"


    @alias @ifcfg-rh
    @alias_ifcfg_remove_all_aliases
    Scenario: ifcfg - alias - remove all aliases
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"

    * Append "DEVICE='eth7:1'" to ifcfg file "eth7:1"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:1"
    * Append "IPADDR=192.168.0.102" to ifcfg file "eth7:1"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:1"

    * Append "DEVICE='eth7:2'" to ifcfg file "eth7:2"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:2"
    * Append "IPADDR=192.168.0.103" to ifcfg file "eth7:2"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:2"

    * Reload connections
    * Bring "up" connection "eth7"

    * "inet 192.168.0.100" is visible with command "ip a s eth7"
    * "inet 192.168.0.101" is visible with command "ip a s eth7"
    * "inet 192.168.0.102" is visible with command "ip a s eth7"
    * "inet 192.168.0.103" is visible with command "ip a s eth7"

    * Execute "sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:0"
    * Execute "sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:1"
    * Execute "sudo rm -f /etc/sysconfig/network-scripts/ifcfg-eth7:2"
    * Reload connections
    * Bring "up" connection "eth7"

    Then "inet 192.168.0.100" is visible with command "ip a s eth7"
    Then "inet 192.168.0.101" is not visible with command "ip a s eth7"
    Then "inet 192.168.0.102" is not visible with command "ip a s eth7"
    Then "inet 192.168.0.103" is not visible with command "ip a s eth7"


    @veth @alias @restart @ifcfg-rh
    @alias_ifcfg_reboot
    Scenario: ifcfg - alias - reboot
    * Add a new connection of type "ethernet" and options "ifname eth7 con-name eth7 autoconnect yes ipv4.may-fail no ipv4.method manual ipv4.addresses 192.168.0.100/24 ipv4.gateway 192.168.0.1"
    * Append "DEVICE='eth7:0'" to ifcfg file "eth7:0"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:0"
    * Append "IPADDR=192.168.0.101" to ifcfg file "eth7:0"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:0"

    * Append "DEVICE='eth7:1'" to ifcfg file "eth7:1"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:1"
    * Append "IPADDR=192.168.0.102" to ifcfg file "eth7:1"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:1"

    * Append "DEVICE='eth7:2'" to ifcfg file "eth7:2"
    * Append "GATEWAY=192.168.0.1" to ifcfg file "eth7:2"
    * Append "IPADDR=192.168.0.103" to ifcfg file "eth7:2"
    * Append "NETMASK=255.255.255.0" to ifcfg file "eth7:2"

    * Reload connections
    * Bring "up" connection "eth7"
    * Reboot

    Then "inet 192.168.0.100" is visible with command "ip a s eth7" in "10" seconds
    Then "inet 192.168.0.101" is visible with command "ip a s eth7"
    Then "inet 192.168.0.102" is visible with command "ip a s eth7"
    Then "inet 192.168.0.103" is visible with command "ip a s eth7"
