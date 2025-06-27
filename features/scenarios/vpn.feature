 Feature: nmcli: vpn

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    #@libreswan
    #@vpn_add_profile
    #Scenario: nmcli - vpn - add default connection
    #* Add "vpn" connection named "vpn" for device "\*" with options "vpn-type libreswan"
    #* Open editor for connection "vpn"
    #* Submit "set vpn.service-type org.freedesktop.NetworkManager.libreswan" in editor
    #* Submit "set vpn.data right = vpn-test.com, xauthpasswordinputmodes = save, xauthpassword-flags = 1, esp = aes-sha1;modp1024, leftxauthusername = desktopqe, pskinputmodes = save, ike = aes-sha1;modp1024, pskvalue-flags = 1, leftid = desktopqe" in editor
    #* Save in editor
    #* Quit editor
    #Then "vpn.service-type:\s+org.freedesktop.NetworkManager.libreswan" is visible with command "nmcli connection show vpn"


    @rhbz1912423
    @rhelver+=8 @ver+=1.32.4
    @openvpn @openvpn6 @libreswan @ikev2
    @multiple_vpn_connections
    Scenario: nmcli - vpn - multiple connections
    * Add "openvpn" VPN connection named "openvpn" for device "\*"
    * Use certificate "sample-keys/client.crt" with key "sample-keys/client.key" and authority "sample-keys/ca.crt" for gateway "127.0.0.1" on OpenVPN connection "openvpn"
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use certificate "LibreswanClient" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    * Bring "up" connection "openvpn"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" for full "130" seconds
    Then "11.12.13.0/24 .*dev libreswan1" is visible with command "ip route"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS.*11.12.13.*/24" is visible with command "nmcli d show libreswan1"
    Then "IP4.GATEWAY:.*11.12.13.14" is visible with command "nmcli d show libreswan1"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show openvpn"
    Then "IP6.ADDRESS.*2001:db8:666:dead::2/64" is visible with command "nmcli c show openvpn"


#    @vpn_add_profile_novice_mode
#    Scenario: nmcli - vpn - novice mode - add default connection


#    @vpn_activate_with_stored_credentials
#    Scenario: nmcli - vpn - activate with stored credentials


#    @vpn_activate_asking_for_credentials
#    Scenario: nmcli - vpn - activate asking for password


#    @vpn_deactivate
#    Scenario: nmcli - vpn - deactivate


#    @vpn_delete_active_profile
#    Scenario: nmcli - vpn - delete active profile


#    @vpn_start_on_boot
#    Scenario: nmcli - vpn - start on boot


#    @vpn_start_as_secondary
#    Scenario: nmcli - vpn - start as secondary


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
    * Add "ip-tunnel" connection named "ipip1" for device "ipip1" with options
          """
          mode ipip
          ip-tunnel.parent veth0
          remote 172.25.16.2
          local 172.25.16.1
          ip4 172.25.30.1/24
          """
    * Bring "up" connection "ipip1"
    Then Ping "172.25.30.2" "2" times
    * Add "ip-tunnel" connection named "gre1" for device "gre1" with options
          """
          mode gre
          ip-tunnel.parent veth0
          remote 172.25.16.2
          local 172.25.16.1
          ip4 172.25.31.1/24
          """
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
    @iptunnel @restart_if_needed
    @iptunnel_restart
    Scenario: nmcli - vpn - detect IP tunnel by NM
    * Add "ip-tunnel" connection named "ipip1" for device "ipip1" with options
          """
          mode ipip
          ip-tunnel.parent veth0
          remote 172.25.16.2
          local 172.25.16.1
          ip4 172.25.30.1/24
          """
    Then Bring "up" connection "ipip1"
    * Add "ip-tunnel" connection named "gre1" for device "gre1" with options
          """
          mode gre
          ip-tunnel.parent veth0
          remote 172.25.16.2
          local 172.25.16.1
          ip4 172.25.31.1/24
          """
    Then Bring "up" connection "gre1"
    * Restart NM
    Then Bring "down" connection "gre1"
    Then Bring "down" connection "ipip1"


    @rhbz1704308
    @ver+=1.14
    @iptunnel
    @iptunnel_ip6gre_create_device
    Scenario: nmcli - vpn - create IP6GRE tunnel with device
    * Add "ip-tunnel" connection named "gre1" for device "ip6gre1" with options
          """
          mode ip6gre
          ip-tunnel.parent veth0
          remote fe80:feed::beef
          local fe80:feed::b00f
          ip6 fe80:deaf::b00f/64
          ipv4.method disabled
          autoconnect no
          """
    * Bring "up" connection "gre1"
    * Wait for "2" seconds
    Then Ping6 "fe80:deaf::beef%ip6gre1"


    @ver+=1.51.3
    @iptunnel
    @iptunnel_ip6gre_create_device_with_eui64
    Scenario: nmcli - vpn - create IP6GRE tunnel with device with EUI64
    * Add "ip-tunnel" connection named "gre1" for device "ip6gre1" with options
          """
          mode ip6gre
          ip-tunnel.parent veth0
          remote fe80:feed::beef
          local fe80:feed::b00f
          ip6 fe80:deaf::b00f/64
          ipv4.method disabled
          autoconnect no
          ipv6.addr-gen-mode eui64
          """
    * Bring "up" connection "gre1"
    * Wait for "2" seconds
    Then Ping6 "fe80:deaf::beef%ip6gre1"


    @ver+=1.16
    @rhelver+=9
    @wireguard
    @wireguard_activate_connection
    Scenario: nmcli - vpn - create and activate wireguard connection
    * Add "wireguard" connection named "wireguard" for device "nm-wireguard" with options
          """
          wireguard.private-key qOdhat/redhat/redhat/redhat/redhat/redhatUE=
          wireguard.listen-port 23456
          ipv4.method manual
          ipv4.addresses 172.25.17.1/24
          """
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/redhat/redhat/redhat/redhatUE=" is visible with command "WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "23456" is visible with command "WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.1/24" is visible with command "ip address show dev nm-wireguard"
    * Modify connection "wireguard" changing options "wireguard.private-key qOdhat/redhat/REDHAT/redhat/redhat/redhatUE= wireguard.listen-port 14456 ipv4.addresses 172.25.17.4/24 wireguard.mtu 1300"
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/REDHAT/redhat/redhat/redhatUE=" is visible with command "WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "14456" is visible with command "WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.4/24" is visible with command "ip address show dev nm-wireguard"
     And "mtu 1300" is visible with command "ip address show dev nm-wireguard"


    @ver+=1.16
    @rhelver+=8 @rhelver-=8 @fedoraver-=0
    @may_fail
    @wireguard
    @wireguard_activate_connection
    Scenario: nmcli - vpn - create and activate wireguard connection
    * Add "wireguard" connection named "wireguard" for device "nm-wireguard" with options
          """
          wireguard.private-key qOdhat/redhat/redhat/redhat/redhat/redhatUE=
          wireguard.listen-port 23456
          ipv4.method manual
          ipv4.addresses 172.25.17.1/24
          """
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/redhat/redhat/redhat/redhatUE=" is visible with command "WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "23456" is visible with command "WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.1/24" is visible with command "ip address show dev nm-wireguard"
    * Modify connection "wireguard" changing options "wireguard.private-key qOdhat/redhat/REDHAT/redhat/redhat/redhatUE= wireguard.listen-port 14456 ipv4.addresses 172.25.17.4/24 wireguard.mtu 1300"
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/REDHAT/redhat/redhat/redhatUE=" is visible with command "WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
     And "14456" is visible with command "WG_HIDE_KEYS=never wg | grep 'port:'" in "10" seconds
     And "172.25.17.4/24" is visible with command "ip address show dev nm-wireguard"
     And "mtu 1300" is visible with command "ip address show dev nm-wireguard"


    @RHEL-79975
    @rhelver+=9
    @ver+=1.53.2.2
    @wireguard @firewall
    @wireguard_allowedIP
    Scenario: nmcli - docs - Configuring wireguard server & client with nmcli
    * Doc: "Configuring a WireGuard server using nmcli"
    * Add "wireguard" connection named "server-wg0" for device "wg0" with options "autoconnect no"
    * Modify connection "server-wg0" changing options "ipv4.method manual ipv4.addresses 192.0.2.1/24"
    * Modify connection "server-wg0" changing options "ipv6.method manual ipv6.addresses 2001:db8:1::1/32"
    * Modify connection "server-wg0" changing options "wireguard.private-key 'YFAnE0psgIdiAF7XR4abxiwVRnlMfeltxu10s/c4JXg='"
    * Modify connection "server-wg0" changing options "wireguard.listen-port 51820"
    * Execute "echo -e '[wireguard-peer.bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM=]\nallowed-ips=192.0.2.2;::/0;' >> /etc/NetworkManager/system-connections/server-wg0.nmconnection"
    * Execute "nmcli connection load /etc/NetworkManager/system-connections/server-wg0.nmconnection"
    * Bring "up" connection "server-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show server-wg0" in "40" seconds
     Then "bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM=" is visible with command "wg show wg0"
      And "inet 192.0.2.1/24 brd 192.0.2.255 scope global noprefixroute wg0" is visible with command "ip address show wg0"
      And "inet6 2001:db8:1::1/32 scope global noprefixroute" is visible with command "ip address show wg0"
     * Doc: "Configuring firewalld on a WireGuard server using the command line"
     * Execute "firewall-cmd --permanent --add-port=51820/udp --zone=public"
     * Execute "firewall-cmd --permanent --zone=public --add-masquerade"
     * Execute "firewall-cmd --reload"
     Then "51820/udp" is visible with command "firewall-cmd --list-all"
    * Doc: "Configuring a WireGuard client using nmcli"
    * Add "wireguard" connection named "client-wg0" for device "wg1" with options
    * Modify connection "client-wg0" changing options "ipv4.method manual ipv4.addresses 192.0.2.2/24"
    * Modify connection "client-wg0" changing options "ipv6.method manual ipv6.addresses 2001:db8:1::2/32"
    * Modify connection "client-wg0" changing options "ipv4.gateway 192.0.2.1 ipv6.gateway 2001:db8:1::1"
    * Modify connection "client-wg0" changing options "wireguard.private-key 'aPUcp5vHz8yMLrzk8SsDyYnV33IhE/k20e52iKJFV0A='"
    * Execute "echo -e '[wireguard-peer.UtjqCJ57DeAscYKRfp7cFGiQqdONRn69u249Fa4O6BE=]\nendpoint=192.0.2.1:51820\nallowed-ips=192.0.2.1;2001:db8:1::1;\npersistent-keepalive=20' >> /etc/NetworkManager/system-connections/client-wg0.nmconnection"
    * Execute "nmcli connection load /etc/NetworkManager/system-connections/client-wg0.nmconnection"
    * Bring "up" connection "client-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show client-wg0" in "40" seconds
    Then "peer: UtjqCJ57DeAscYKRfp7cFGiQqdONRn69u249Fa4O6BE=" is visible with command "wg show wg1"
     And "inet 192.0.2.2/24 brd 192.0.2.255 scope global noprefixroute wg1" is visible with command "ip address show wg1"
     And "inet6 2001:db8:1::2/32 scope global noprefixroute" is visible with command "ip address show wg1"
    * Commentary
    """
    The following covers RHEL-79975
    Replace endpoint and allowd-ips in nmconnection keyfile.
    """
    * Modify connection "client-wg0" changing options "ipv4.method disabled ipv4.address '' ipv4.gateway ''"
    * Execute "sed -i 's@endpoint=.*@endpoint=2001:db8:1::1:51820@; s@allowed-ips=.*@allowed-ips=::/0\;@' /etc/NetworkManager/system-connections/client-wg0.nmconnection"
    * Execute "cat /etc/NetworkManager/system-connections/client-wg0.nmconnection"
    * Reload connections
    * Bring "up" connection "client-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show client-wg0" in "40" seconds
    * Execute "ip -6 r"
    * Execute "nft list ruleset"
    And "inet6 2001:db8:1::2/32 scope global noprefixroute" is visible with command "ip address show wg1"
    Then "meta l4proto udp meta mark set ct mark" is visible with command "nft list table ip6 nm-wg-wg0"
    Then "meta l4proto udp meta mark set ct mark" is visible with command "nft list table ip6 nm-wg-wg1"
    * Bring "down" connection "client-wg0"

    Then "meta l4proto udp meta mark set ct mark" is not visible with command "nft list table ip6 nm-wg-wg1"
    * Bring "down" connection "server-wg0"
    Then "meta l4proto udp meta mark set ct mark" is not visible with command "nft list table ip6 nm-wg-wg0"


    @RHEL-70160 @RHEL-69901
    @ver+=1.16
    @rhelver+=9
    @ver/rhel/9/5+=1.48.10.5
    @wireguard
    @wireguard_add_routing_rules
    Scenario: nmcli - vpn - create and activate wireguard connection
    * Add "wireguard" connection named "wireguard" for device "nm-wireguard" with options
          """
          wireguard.private-key qOdhat/redhat/redhat/redhat/redhat/redhatUE=
          wireguard.listen-port 23456
          ipv4.method manual
          ipv4.addresses 172.25.17.1/24
          """
    * Modify connection "wireguard" changing options "ipv4.route-table 127"
    * Modify connection "wireguard" changing options "ipv6.route-table 200"
    * Modify connection "wireguard" changing options "ipv4.routing-rules 'priority 16383 from all table 127'"
    * Modify connection "wireguard" changing options "ipv6.routing-rules 'priority 16600 from all table 200'"
    * Bring "up" connection "wireguard"
    Then "qOdhat/redhat/redhat/redhat/redhat/redhatUE=" is visible with command "WG_HIDE_KEYS=never wg | grep 'private key:'" in "10" seconds
    Then "16383:\s+from all lookup 127 proto static" is visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is visible with command "ip -6 rule"
    * Bring "down" connection "wireguard"
    Then "16383:\s+from all lookup 127 proto static" is not visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is not visible with command "ip -6 rule"
