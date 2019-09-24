 Feature: nmcli: vpn

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @libreswan
    @vpn_add_profile
    Scenario: nmcli - vpn - add default connection
    * Add a new connection of type "vpn" and options "ifname \* con-name vpn vpn-type libreswan"
    * Open editor for connection "vpn"
    * Submit "set vpn.service-type org.freedesktop.NetworkManager.libreswan" in editor
    * Submit "set vpn.data right = vpn-test.com, xauthpasswordinputmodes = save, xauthpassword-flags = 1, esp = aes-sha1;modp1024, leftxauthusername = desktopqe, pskinputmodes = save, ike = aes-sha1;modp1024, pskvalue-flags = 1, leftid = desktopqe" in editor
    * Save in editor
    * Quit editor
    Then "vpn.service-type:\s+org.freedesktop.NetworkManager.libreswan" is visible with command "nmcli connection show vpn"


    @ver+=1.4.0
    @libreswan @openvpn @openvpn6
    @multiple_vpn_connections
    Scenario: nmcli - vpn - multiple connections
    * Add a connection named "openvpn" for device "\*" to "openvpn" VPN
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" for full "130" seconds
    Then "172.31.70.0/24 .*dev libreswan1" is visible with command "ip route"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show libreswan1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show libreswan1"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::2/64" is visible with command "nmcli c show openvpn"


    @vpn_add_profile_novice_mode
    Scenario: nmcli - vpn - novice mode - add default connection


    @vpn_activate_with_stored_credentials
    Scenario: nmcli - vpn - activate with stored credentials


    @vpn_activate_asking_for_credentials
    Scenario: nmcli - vpn - activate asking for password


    @vpn_deactivate
    Scenario: nmcli - vpn - deactivate


    @vpn_delete_active_profile
    Scenario: nmcli - vpn - delete active profile


    @vpn_start_on_boot
    Scenario: nmcli - vpn - start on boot


    @vpn_start_as_secondary
    Scenario: nmcli - vpn - start as secondary


    @vpn_describe
    Scenario: nmcli - vpn - describe
    * Open editor for a type "vpn"
    When Check "<<< vpn >>>" are present in describe output for object "vpn"
    When Check "=== \[service-type\] ===\s+\[NM property description\]\s+D-Bus service name of the VPN plugin that this setting uses to connect to its network.  i.e. org.freedesktop.NetworkManager.vpnc for the vpnc plugin.\s+" are present in describe output for object "vpn"
    When Check "=== \[user-name\] ===\s+\[NM property description\]\s+If the VPN connection requires a user name for authentication, that name should be provided here.  If the connection is available to more than one user, and the VPN requires each user to supply a different name, then leave this property empty.  If this property is empty, NetworkManager will automatically supply the username of the user which requested the VPN connection.\s+" are present in describe output for object "vpn"
    When Check "=== \[persistent\] ===\s+\[NM property description\]\s+If the VPN service supports persistence, and this property is TRUE, the VPN will attempt to stay connected across link changes and outages, until explicitly disconnected.\s+" are present in describe output for object "vpn"
    When Check "=== \[data\] ===\s+\[NM property description\]\s+Dictionary of key/value pairs of VPN plugin specific data.  Both keys and values must be strings.\s+" are present in describe output for object "vpn"
    When Check "=== \[secrets\] ===\s+\[NM property description\]\s+Dictionary of key\/value pairs of VPN plugin specific secrets like passwords or private keys.\s+Both keys and values must be strings." are present in describe output for object "vpn"


    @rhbz1374526
    @ver+=1.4.0
    @pptp
    @vpn_list_args
    Scenario: nmcli - vpn - list args
    Then "libreswan|vpnc|openvpn" is visible with command "nmcli --complete-args connection add type vpn vpn-type ''"


    @ver+=1.14
    @iptunnel
    @iptunnel_create_modify
    Scenario: nmcli - vpn - create IPIP and GRE IP tunnel
    * Add a new connection of type "ip-tunnel" and options "ifname ipip1 con-name ipip1 mode ipip ip-tunnel.parent veth0 remote 172.25.16.2 local 172.25.16.1 ip4 172.25.30.1/24"
    * Bring "up" connection "ipip1"
    Then Ping "172.25.30.2" "2" times
    * Add a new connection of type "ip-tunnel" and options "ifname gre1 con-name gre1 mode gre ip-tunnel.parent veth0 remote 172.25.16.2 local 172.25.16.1 ip4 172.25.31.1/24"
    * Bring "up" connection "gre1"
    Then Ping "172.25.31.2" "2" times
    * Bring "down" connection "ipip1"
    * Modify connection "ipip1" changing options "ifname gre1 mode gre ip4 '' ip6 fe80:dead::b00f/64"
    * Bring "up" connection "ipip1"
    Then Ping6 "fe80:dead::beef%gre1"
    * Bring "down" connection "ipip1"
    * Modify connection "ipip1" changing options "ip-tunnel.input-key 12345678 ip-tunnel.output-key 87654321"
    * Modify connection "ipip1" changing options "mode ipip6 ip-tunnel.input-key '' ip-tunnel.output-key '' local fe80:dead::beef remote fe80:dead::b00f ip-tunnel.flags 8 ip-tunnel.mtu 1000 ip-tunnel.path-mtu-discovery false"
    Then "dead" is visible with command "nmcli con show ipip1"


    @ver+=1.14
    @iptunnel @restart
    @iptunnel_restart
    Scenario: nmcli - vpn - detect IP tunnel by NM
    * Add a new connection of type "ip-tunnel" and options "ifname ipip1 con-name ipip1 mode ipip ip-tunnel.parent veth0 remote 172.25.16.2 local 172.25.16.1 ip4 172.25.30.1/24"
    Then Bring "up" connection "ipip1"
    * Add a new connection of type "ip-tunnel" and options "ifname gre1 con-name gre1 mode gre ip-tunnel.parent veth0 remote 172.25.16.2 local 172.25.16.1 ip4 172.25.31.1/24"
    Then Bring "up" connection "gre1"
    * Restart NM
    Then Bring "down" connection "gre1"
    Then Bring "down" connection "ipip1"


    @rhbz1704308
    @ver+=1.14
    @iptunnel
    @iptunnel_ip6gre_create_device
    Scenario: nmcli - vpn - create IP6GRE tunnel with device
    * Add a new connection of type "ip-tunnel" and options "ifname ip6gre1 con-name gre1 mode ip6gre ip-tunnel.parent veth0 remote fe80:feed::beef local fe80:feed::b00f ip6 fe80:deaf::b00f/64 ipv4.method disabled autoconnect no"
    * Bring "up" connection "gre1"
    * Wait for at least "2" seconds
    Then Ping6 "fe80:deaf::beef%ip6gre1"


    @ver+=1.16
    @wireguard @rhelver+=8
    @wireguard_activate_connection
    Scenario: nmcli - vpn - create and activate wireguard connection
    * Add a new connection of type "wireguard" and options "ifname nm-wireguard con-name wireguard wireguard.private-key qOdhat/redhat/redhat/redhat/redhat/redhatUE= wireguard.listen-port 23456 ipv4.method manual ipv4.addresses 172.25.17.1/24 "
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/redhat/redhat/redhat/redhatUE=" is visible with command "sudo WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "23456" is visible with command "sudo WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.1/24" is visible with command "ip address show dev nm-wireguard"
    * Modify connection "wireguard" changing options "wireguard.private-key qOdhat/redhat/REDHAT/redhat/redhat/redhatUE= wireguard.listen-port 14456 ipv4.addresses 172.25.17.4/24 wireguard.mtu 1300"
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/REDHAT/redhat/redhat/redhatUE=" is visible with command "sudo WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "14456" is visible with command "sudo WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.4/24" is visible with command "ip address show dev nm-wireguard"
     And "mtu 1300" is visible with command "ip address show dev nm-wireguard"
