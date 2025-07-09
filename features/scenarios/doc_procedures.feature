Feature: nmcli - procedures in documentation

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @ver+=1.18
    @firewall @eth0
    @policy_based_routing_doc_procedure
    Scenario: nmcli - docs -  Configuring policy-based routing to define alternative routes
    * Doc: "Routing traffic from a specific subnet to a different default gateway using NetworkManager"
    * Prepare PBR documentation procedure
    * Add "ethernet" connection named "Provider-A" for device "provA" with options
          """
          ipv4.method manual
          ipv4.addresses 198.51.100.1/30
          ipv4.gateway 198.51.100.2
          ipv4.dns 198.51.100.200
          connection.zone external
          """
    * Add "ethernet" connection named "Provider-B" for device "provB" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/30
          ipv4.routes "0.0.0.0/0 192.0.2.2 table=5000"
          connection.zone external
          """
    * Add "ethernet" connection named "Internal-Workstations" for device "int_work" with options
          """
          ipv4.method manual
          ipv4.addresses 10.0.0.1/24
          ipv4.routes "10.0.0.0/24 table=5000"
          ipv4.routing-rules 'priority 5 from 10.0.0.0/24 table 5000'
          connection.zone trusted
          """
    * Add "ethernet" connection named "Servers" for device "servers" with options
          """
          ipv4.method manual
          ipv4.addresses 203.0.113.1/24
          connection.zone trusted
          """
    # Disable reverse DNS lookups of traceroute - it does't work (timeouts), even when dnsmasq provides PTR records.
    # * "_gateway \(10.0.0.1\) .* 192.0.2.2 \(192.0.2.2\)" is visible with command "ip netns exec int_work_ns traceroute 172.20.20.20"
    # * "_gateway \(203.0.113.1\) .* 198.51.100.2 \(198.51.100.2\)" is visible with command "ip netns exec servers_ns traceroute 172.20.20.20"
    * "203.0.113.1 .* 198.51.100.2 .* 172.20.20.20" is visible with command "ip netns exec servers_ns traceroute -n 172.20.20.20" in "5" seconds
    * "10.0.0.1 .* 192.0.2.2 .* 172.20.20.20" is visible with command "ip netns exec int_work_ns traceroute -n 172.20.20.20" in "5" seconds
    Then "external\s+interfaces: provA provB" is visible with command "firewall-cmd --get-active-zones"
    Then "trusted\s+interfaces: int_work servers" is visible with command "firewall-cmd --get-active-zones"
    Then "masquerade: yes" is visible with command "firewall-cmd --info-zone=external"
    Then "from 10.0.0.0/24 lookup 5000" is visible with command "ip rule list"
    Then "default via 192.0.2.2 dev provB" is visible with command "ip route list table 5000"
    Then "10.0.0.0/24 dev int_work" is visible with command "ip route list table 5000"
    * Run child "ip netns exec provA_ns stdbuf -oL -eL tcpdump -nn -i provAp icmp > /tmp/tcpdump_provA.log"
    * Run child "ip netns exec provB_ns stdbuf -oL -eL tcpdump -nn -i provBp icmp > /tmp/tcpdump_provB.log"
    * Execute "ip netns exec servers_ns ping -c 3 172.20.20.20"
    * Kill children
    Then "198.51.100.1 > 172.20.20.20" is visible with command "cat /tmp/tcpdump_provA.log" in "30" seconds
     And "> 172.20.20.20" is not visible with command "cat /tmp/tcpdump_provB.log"
    * Run child "ip netns exec provA_ns stdbuf -oL -eL tcpdump -nn -i provAp icmp > /tmp/tcpdump_provA.log"
    * Run child "ip netns exec provB_ns stdbuf -oL -eL tcpdump -nn -i provBp icmp > /tmp/tcpdump_provB.log"
    * Execute "ip netns exec int_work_ns ping -c 3 172.20.20.20"
    * Kill children
    Then "192.0.2.1 > 172.20.20.20" is visible with command "cat /tmp/tcpdump_provB.log" in "30" seconds
     And "> 172.20.20.20" is not visible with command "cat /tmp/tcpdump_provA.log"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_mschapv2_doc_procedure
    Scenario: nmcli - docs - Configuring 802.1x network authentication on an existing Wi-Fi connection using nmcli
    * Doc: "Configuring 802.1X network authentication on an existing Wi-Fi connection using nmcli"
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Modify connection "wifi" changing options "802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "wifi" changing options "802-1x.password password"
    * Modify connection "wifi" changing options "802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem"
    Then Bring "up" connection "wifi"


    @rhelver+=8 @rhelver-=8 @fedoraver-=0
    @ver+=1.37
    @simwifi @attach_wpa_supplicant_log
    @simwifi_hotspot_doc_procedure
    Scenario: nmcli - docs - Configuring RHEL as a WPA2 or WPA3 Personal access point
    Given Create NM config file with content
          """
          [main]
          firewall-backend=nftables
          """
    Given Restart NM
    # We need small delay here after restarting NM service
    * Wait for "1" seconds
    * Doc: "Identifying whether a wireless device supports the access point mode"
    * Doc: "Configuring RHEL as a WPA2 or WPA3 Personal access point"
    * Cleanup connection "Example-Hotspot"
    Given "wifi" is visible with command "nmcli device status"
    Given "yes" is visible with command "nmcli -f WIFI-PROPERTIES.AP device show wlan0"
    * Execute "nmcli device wifi hotspot ifname wlan0 con-name Example-Hotspot ssid Example-Hotspot password 'password'"
    * Bring "up" connection "Example-Hotspot"
    Then "udp\s* UNCONN\s* 0\s* 0\s* 10.42.0.1:53" is visible with command "ss -tulpn | grep dnsmasq" in "20" seconds
    Then "udp\s* UNCONN\s* 0\s* 0\s* 0.0.0.0:67" is visible with command "ss -tulpn  | grep dnsmasq"
    Then "tcp\s* LISTEN\s* 0\s* 32\s* 10.42.0.1:53" is visible with command "ss -tulpn | grep dnsmasq"
    Then "table ip nm-shared-wlan0.*ip saddr 10.42.0.0/24 ip daddr != 10.42.0.0/24 masquerade.*" is visible with command "nft list ruleset"
    Then "chain filter_forward.*ip daddr 10.42.0.0/24 oifname .wlan0.*ip saddr 10.42.0.0/24 iifname .wlan0. accept" is visible with command "nft list ruleset"


    @rhelver+=9 @ver+=1.37
    @simwifi @attach_wpa_supplicant_log
    @simwifi_hotspot_doc_procedure
    Scenario: nmcli - docs - Configuring RHEL as a WPA2 or WPA3 Personal access point
    * Doc: "Identifying whether a wireless device supports the access point mode"
    * Doc: "Configuring RHEL as a WPA2 or WPA3 Personal access point"
    * Cleanup connection "Example-Hotspot"
    Given "wifi" is visible with command "nmcli device status"
    Given "yes" is visible with command "nmcli -f WIFI-PROPERTIES.AP device show wlan0"
    * Execute "nmcli device wifi hotspot ifname wlan0 con-name Example-Hotspot ssid Example-Hotspot password 'password'"
    * Bring "up" connection "Example-Hotspot"
    Then "udp\s* UNCONN\s* 0\s* 0\s* 10.42.0.1:53" is visible with command "ss -tulpn | grep dnsmasq" in "20" seconds
    Then "udp\s* UNCONN\s* 0\s* 0\s* 0.0.0.0:67" is visible with command "ss -tulpn  | grep dnsmasq"
    Then "tcp\s* LISTEN\s* 0\s* 32\s* 10.42.0.1:53" is visible with command "ss -tulpn | grep dnsmasq"
    Then "table ip nm-shared-wlan0.*ip saddr 10.42.0.0/24 ip daddr != 10.42.0.0/24 masquerade.*" is visible with command "nft list ruleset"
    Then "chain filter_forward.*ip daddr 10.42.0.0/24 oifname .wlan0.*ip saddr 10.42.0.0/24 iifname .wlan0. accept" is visible with command "nft list ruleset"


    @rhelver+=8 @rhelver-=8 @fedoraver-=0
    @ver+=1.37
    @simwifi @attach_wpa_supplicant_log
    @simwifi_hotspot_sae_doc_procedure
    Scenario: nmcli - docs - Configuring RHEL as a WPA2 or WPA3 Personal access point (SAE + custom IP range)
    Given Create NM config file with content
          """
          [main]
          firewall-backend=nftables
          """
    Given Restart NM
    # We need small delay here after restarting NM service
    * Wait for "1" seconds
    * Doc: "Configuring RHEL as a WPA2 or WPA3 Personal access point"
    * Cleanup connection "Example-Hotspot"
    * Execute "nmcli device wifi hotspot ifname wlan0 con-name Example-Hotspot ssid Example-Hotspot password 'password'"
    * Modify connection "Example-Hotspot" changing options "802-11-wireless-security.key-mgmt sae"
    * Modify connection "Example-Hotspot" changing options "ipv4.addresses 192.0.2.254/24"
    * Bring "up" connection "Example-Hotspot"
    Then "udp\s* UNCONN\s* 0\s* 0\s* 192.0.2.254:53" is visible with command "ss -tulpn | grep dnsmasq" in "20" seconds
    Then "udp\s* UNCONN\s* 0\s* 0\s* 0.0.0.0:67" is visible with command "ss -tulpn  | grep dnsmasq"
    Then "tcp\s* LISTEN\s* 0\s* 32\s* 192.0.2.254:53" is visible with command "ss -tulpn | grep dnsmasq"
    Then "table ip nm-shared-wlan0.*ip saddr 192.0.2.0/24 ip daddr != 192.0.2.0/24 masquerade.*" is visible with command "nft list ruleset"
    Then "chain filter_forward.*ip daddr 192.0.2.0/24 oifname .wlan0.*ip saddr 192.0.2.0/24 iifname .wlan0. accept" is visible with command "nft list ruleset"


    @rhelver+=9 @ver+=1.37
    @simwifi @attach_wpa_supplicant_log
    @simwifi_hotspot_sae_doc_procedure
    Scenario: nmcli - docs - Configuring RHEL as a WPA2 or WPA3 Personal access point (SAE + custom IP range)
    * Doc: "Configuring RHEL as a WPA2 or WPA3 Personal access point"
    * Cleanup connection "Example-Hotspot"
    * Execute "nmcli device wifi hotspot ifname wlan0 con-name Example-Hotspot ssid Example-Hotspot password 'password'"
    * Modify connection "Example-Hotspot" changing options "802-11-wireless-security.key-mgmt sae"
    * Modify connection "Example-Hotspot" changing options "ipv4.addresses 192.0.2.254/24"
    * Bring "up" connection "Example-Hotspot"
    Then "udp\s* UNCONN\s* 0\s* 0\s* 192.0.2.254:53" is visible with command "ss -tulpn | grep dnsmasq" in "20" seconds
    Then "udp\s* UNCONN\s* 0\s* 0\s* 0.0.0.0:67" is visible with command "ss -tulpn  | grep dnsmasq"
    Then "tcp\s* LISTEN\s* 0\s* 32\s* 192.0.2.254:53" is visible with command "ss -tulpn | grep dnsmasq"
    Then "table ip nm-shared-wlan0.*ip saddr 192.0.2.0/24 ip daddr != 192.0.2.0/24 masquerade.*" is visible with command "nft list ruleset"
    Then "chain filter_forward.*ip daddr 192.0.2.0/24 oifname .wlan0.*ip saddr 192.0.2.0/24 iifname .wlan0. accept" is visible with command "nft list ruleset"


    @simwifi_teardown
    @nmcli_simwifi_teardown_doc
    Scenario: teardown wifi setup
    * Execute "echo 'this is skipped'"

    @ver+=1.14
    @iptunnel_ipip_doc_procedure
    Scenario: nmcli - docs - Configuring an IPIP tunnel using nmcli to encapsulate IPv4 traffic in IPv4 packets
    * Doc: "Configuring an IPIP tunnel using nmcli to encapsulate IPv4 traffic in IPv4 packets"
    * Prepare "ipip" iptunnel networks A and B
    * Add "ip-tunnel" connection named "tun0" for device "tun0" with options
          """
          ip-tunnel.mode ipip
          remote 198.51.100.5
          local 203.0.113.10
          """
    * Modify connection "tun0" changing options "ipv4.addresses '10.0.1.1/30'"
    * Modify connection "tun0" changing options "ipv4.method manual"
    * Modify connection "tun0" changing options "+ipv4.routes '172.16.0.0/24 10.0.1.2'"
    Then Bring "up" connection "tun0"
    Then Execute "ping -c 1 172.16.0.1"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"


    @ver+=1.14
    @iptunnel_gre_doc_procedure
    Scenario: nmcli - docs - Configuring a GRE tunnel using nmcli to encapsulate layer-3 traffic in IPv4 packets
    * Doc: "Configuring a GRE tunnel using nmcli to encapsulate layer-3 traffic in IPv4 packets"
    * Prepare "gre" iptunnel networks A and B
    * Add "ip-tunnel" connection named "gre1" for device "gre1" with options
          """
          ip-tunnel.mode gre
          remote 198.51.100.5
          local 203.0.113.10
          """
    * Modify connection "gre1" changing options "ipv4.addresses '10.0.1.1/30'"
    * Modify connection "gre1" changing options "ipv4.method manual"
    * Modify connection "gre1" changing options "+ipv4.routes '172.16.0.0/24 10.0.1.2'"
    Then Bring "up" connection "gre1"
    Then Execute "ping -c 1 172.16.0.1"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"


    @ver+=1.20
    @iptunnel_gretap_doc_procedure
    Scenario: nmcli - docs - Configuring a GRETAP tunnel to transfer Ethernet frames over IPv4
    * Doc: "Configuring a GRETAP tunnel to transfer Ethernet frames over IPv4"
    * Prepare "gretap" iptunnel networks A and B
    * Add "bridge" connection named "bridge0" for device "bridge0"
    * Modify connection "bridge0" changing options "ipv4.addresses '192.0.2.1/24'"
    * Modify connection "bridge0" changing options "ipv4.method manual"
    * Modify connection "bridge0" changing options "bridge.stp off"
    * Add "ethernet" connection named "bridge0-port1" for device "netA" with options "slave-type bridge master bridge0"
    * Add "ip-tunnel" connection named "bridge0-port2" for device "gretap1" with options
          """
          ip-tunnel.mode gretap
          slave-type bridge
          remote 198.51.100.5
          local 203.0.113.10
          master bridge0
          """
    * Modify connection "bridge0" changing options "connection.autoconnect-slaves 1"
    Then Bring "up" connection "bridge0"
    Then "bridge0:bridge:connected:bridge0" is visible with command "nmcli -t device" in "5" seconds
    Then "netA:ethernet:connected:bridge0-port1" is visible with command "nmcli -t device"
    Then "gretap1:iptunnel:connected:bridge0-port2" is visible with command "nmcli -t device"
    Then Execute "ping -c 1 192.0.2.2"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"
    Then Execute "ip netns exec netA_ns ping -c 1 192.0.2.4"
    Then Execute "ip netns exec netB_ns ping -c 1 192.0.2.3"


    @rhelver+=8
    @qdisc_doc_procedure
    Scenario: nmcli - docs - Permanently setting the current qdisk of a network interface
    * Execute "tc qdisc replace dev eth1 root fq_codel"
    Given "qdisc fq_codel .*: root refcnt .*" is visible with command "tc qdisc show dev eth1"
    * Add "ethernet" connection named "con_tc" for device "eth1"
    * Modify connection "con_tc" changing options "tc.qdisc 'root pfifo_fast'"
    * Modify connection "con_tc" changing options "+tc.qdisc 'ingress handle ffff:'"
    When "qdisc fq_codel .*: root refcnt .*" is visible with command "tc qdisc show dev eth1"
    * Bring "up" connection "con_tc"
    Then "qdisc pfifo_fast .*: root refcnt .* bands 3 priomap\s+1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1" is visible with command "tc qdisc show dev eth1"
    And  "qdisc ingress ffff: parent ffff:fff1\s+----------------" is visible with command "tc qdisc show dev eth1"


    @rhelver+=8
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_doc_procedure
    Scenario: nmcli - docs - Using MACsec to encrypt layer-2 traffic in the same physical network
    * Doc: "Configuring a MACsec connection using nmcli"
    * Prepare MACsec PSK environment with CAK "50b71a8ef0bd5751ea76de6d6c98c03a" and CKN "f2b4297d39da7330910a74abc0449feb45b5c0b9fc23df1430e1898fcf1c4550"
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 50b71a8ef0bd5751ea76de6d6c98c03a
          macsec.mka-ckn f2b4297d39da7330910a74abc0449feb45b5c0b9fc23df1430e1898fcf1c4550
          """
    * Modify connection "test-macsec" changing options "ipv4.method manual ipv4.addresses '172.16.10.5/24' ipv4.gateway '172.16.10.1' ipv4.dns '172.16.10.1'"
    * Modify connection "test-macsec" changing options "ipv6.method manual ipv6.addresses '2001:db8:1::1/32' ipv6.gateway '2001:db8:1::fffe' ipv6.dns '2001:db8:1::fffe'"
    * Bring "up" connection "test-macsec"
    Then Ping "172.16.10.1" "10" times
    Then Ping6 "2001:db8:1::fffe"


    @rhelver+=9
    @wireguard @firewall
    @wireguard_nmcli_doc_procedure
    Scenario: nmcli - docs - Configuring wireguard server & client with nmcli
    * Add "wireguard" connection named "server-wg0" for device "wg0" with options "autoconnect no"
    * Modify connection "server-wg0" changing options "ipv4.method manual ipv4.addresses 192.0.2.1/24"
    * Modify connection "server-wg0" changing options "ipv6.method manual ipv6.addresses 2001:db8:1::1/32"
    * Modify connection "server-wg0" changing options "wireguard.private-key 'YFAnE0psgIdiAF7XR4abxiwVRnlMfeltxu10s/c4JXg='"
    * Modify connection "server-wg0" changing options "wireguard.listen-port 51820"
    * Execute "echo -e '[wireguard-peer.bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM=]\nallowed-ips=192.0.2.2;2001:db8:1::2;' >> /etc/NetworkManager/system-connections/server-wg0.nmconnection"
    * Reload connections
    * Bring "up" connection "server-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show server-wg0" in "40" seconds
     Then "bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM=" is visible with command "wg show wg0"
      And "inet 192.0.2.1/24 brd 192.0.2.255 scope global noprefixroute wg0" is visible with command "ip address show wg0"
      And "inet6 2001:db8:1::1/32 scope global noprefixroute" is visible with command "ip address show wg0"
     * Execute "firewall-cmd --permanent --add-port=51820/udp --zone=public"
     * Execute "firewall-cmd --permanent --zone=public --add-masquerade"
     * Execute "firewall-cmd --reload"
     Then "51820/udp" is visible with command "firewall-cmd --list-all"
    * Add "wireguard" connection named "client-wg0" for device "wg1" with options "autoconnect no"
    * Modify connection "client-wg0" changing options "ipv4.method manual ipv4.addresses 192.0.2.2/24"
    * Modify connection "client-wg0" changing options "ipv6.method manual ipv6.addresses 2001:db8:1::2/32"
    * Modify connection "client-wg0" changing options "ipv4.method manual ipv4.gateway 192.0.2.1 ipv6.gateway 2001:db8:1::1"
    * Modify connection "client-wg0" changing options "ipv4.method manual wireguard.private-key 'aPUcp5vHz8yMLrzk8SsDyYnV33IhE/k20e52iKJFV0A='"
    * Execute "echo -e '[wireguard-peer.UtjqCJ57DeAscYKRfp7cFGiQqdONRn69u249Fa4O6BE=]\nendpoint=192.0.2.1:51820\nallowed-ips=192.0.2.1;2001:db8:1::1;\npersistent-keepalive=20' >> /etc/NetworkManager/system-connections/client-wg0.nmconnection"
    * Reload connections
    * Bring "up" connection "client-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show client-wg0" in "40" seconds
     Then "192.0.2.1:51820" is visible with command "wg show wg1"
      And "inet 192.0.2.2/24 brd 192.0.2.255 scope global noprefixroute wg1" is visible with command "ip address show wg1"
      And "inet6 2001:db8:1::2/32 scope global noprefixroute" is visible with command "ip address show wg1"

    @rhelver+=9
    @wireguard @nmtui
    @wireguard_nmtui_doc_procedure
    Scenario: nmcli - docs - Configuring wireguard server & client with nmtui
    * Prepare virtual terminal environment
    * Prepare new connection of type "WireGuard" named "server-wg0"
    * Set "Device" field to "wg0"
    * Set "Private key" field to "YFAnE0psgIdiAF7XR4abxiwVRnlMfeltxu10s/c4JXg="
    * Set "Listen port" field to "51820"
    * Choose to "<Add>" a peer
    * Set "Public key" field to "bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM="
    * Set "Allowed IPs" field to "192.0.2.2,2001:db8:1::2"
    * Confirm the peer settings
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.0.2.1/24"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001:db8:1::1/32"
    * Confirm the connection settings
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show server-wg0" in "40" seconds
    Then "bnwfQcC8/g2i4vvEqcRUM2e6Hi3Nskk6G9t4r26nFVM=" is visible with command "wg show wg0"
     And "inet 192.0.2.1/24 brd 192.0.2.255 scope global noprefixroute wg0" is visible with command "ip address show wg0"
     And "inet6 2001:db8:1::1/32 scope global noprefixroute" is visible with command "ip address show wg0"
    * Choose to "<Add>" a connection
    * Choose the connection type "WireGuard"
    * Set "Profile name" field to "client-wg0"
    * Set "Device" field to "wg1"
    * Set "Private key" field to "aPUcp5vHz8yMLrzk8SsDyYnV33IhE/k20e52iKJFV0A="
    * Choose to "<Add>" a peer
    * Set "Public key" field to "UtjqCJ57DeAscYKRfp7cFGiQqdONRn69u249Fa4O6BE="
    * Set "Allowed IPs" field to "192.0.2.1,2001:db8:1::1"
    * Set "Endpoint" field to "192.0.2.1:51820"
    * Set "Persistent keepalive" field to "20"
    * Confirm the peer settings
    * Set "IPv4 CONFIGURATION" category to "Manual"
    * Come in "IPv4 CONFIGURATION" category
    * In "Addresses" property add "192.0.2.2/24"
    * Set "Gateway" field to "192.0.2.1"
    * Set "IPv6 CONFIGURATION" category to "Manual"
    * Come in "IPv6 CONFIGURATION" category
    * In "Addresses" property add "2001:db8:1::2/32"
    * Set "Gateway" field to "2001:db8:1::1"
    * Confirm the connection settings
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show client-wg0" in "40" seconds
    Then "192.0.2.1:51820" is visible with command "wg show wg1"
     And "inet 192.0.2.2/24 brd 192.0.2.255 scope global noprefixroute wg1" is visible with command "ip address show wg1"
     And "inet6 2001:db8:1::2/32 scope global noprefixroute" is visible with command "ip address show wg1"


    @firewall
    @vxlan_doc_procedure
    Scenario: nmcli - docs - Creating a network bride with VXLAN attached
    * Add "bridge" connection named "br88" for device "br4" with options
          """
          ipv4.method disabled
          ipv6.method disabled
          """
    * Add "vxlan" connection named "br4-vxlan10" for device "vxlan10" with options
          """
          slave-type bridge
          id 10
          local 198.51.100.2
          remote 203.0.113.1
          master br88
          """
    * Bring "up" connection "br88"
    * Execute "firewall-cmd --permanent --add-port=8472/udp"
    * Execute "firewall-cmd --reload"
    Then "master br4 permanent" is visible with command "bridge fdb show dev vxlan10"


    @rhelver+=8.6
    @rhelver-10
    @fedoraver-
    @not_in_image_mode
    @permissive @firewall
    @radius @8021x_doc_procedure @attach_wpa_supplicant_log
    # permissive is required until selinux-policy is updated in:
    #   - el9: https://bugzilla.redhat.com/show_bug.cgi?id=2064688
    #   - el8: https://bugzilla.redhat.com/show_bug.cgi?id=2064284
    @8021x_hostapd_freeradius_doc_procedure
    Scenario: nmcli - docs - set up 802.1x using FreeRadius and hostapd
    * Doc: "Setting up an 802.1x network authentication service for LAN clients by using hostapd with FreeRADIUS backend"
    ### 1. Setting up the bridge on the authenticator
    * Add "bridge" connection named "br0" for device "br0" with options
            """
            con-name br0
            bridge.group-forward-mask 8
            connection.autoconnect-slaves 1
            ipv4.method disabled
            ipv6.method disabled
            stp off
            forward-delay 2
            """
    # Sometimes we need to avoid too many EAPOLs to hit hostapd, drop zone to bridge seems to be doing it correctly
    * Add "ethernet" connection named "br0-uplink" for device "eth4" with options "master br0 connection.zone drop"
    # bridge port to have access limited by 802.1x auth
    * Execute "ip l add test1 type veth peer name test1b"
    * Execute "ip l set dev test1b up"
    * Execute "ip l set dev test1 up"
    * Add "ethernet" connection named "br0-client-port" for device "test1b" with options "master br0"
    * Bring "up" connection "br0"
    ### .2: unused, .3 and .4: handled by @radius tag
    ### .5 Configuring hostapd as an authenticator in a wired network
    * Execute "cp contrib/8021x/doc_procedures/hostapd.conf /etc/hostapd/hostapd.conf"
    Then Execute "systemctl start hostapd"
    * Execute "systemctl status hostapd"
    ### .6 Testing EAP-TTLS authentication against a FreeRADIUS server or authenticator
    * Execute "cp -f contrib/8021x/doc_procedures/wpa_supplicant-TTLS.conf /etc/wpa_supplicant/wpa_supplicant-TTLS.conf"
    Then Note the output of "eapol_test -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -s client_password"
     And Noted value contains "EAP: Status notification: remote certificate verification \(param=success\)"
     And Noted value contains "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully"
     And Noted value contains "SUCCESS"
    * Run child "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -D wired -i test1 -d -t" without shell
    Then Expect "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" in children in "5" seconds
    * Kill children with signal "15"
    Then Expect "CTRL-EVENT-TERMINATING" in children in "5" seconds
    * Add "ethernet" connection named "test1-ttls" for device "test1" with options
            """
            autoconnect no
            802-1x.eap ttls
            802-1x.phase2-auth pap
            802-1x.identity example_user
            802-1x.password user_password
            802-1x.ca-cert /etc/pki/tls/certs/8021x-ca.pem
            802-1x.auth-timeout 75
            connection.auth-retries 5
            """
    # Just in case a bit of time to settle
    * Wait for "1" seconds
    When Bring "up" connection "test1-ttls"
    Then Check if "test1-ttls" is active connection
    * Disconnect device "test1"
    ### .7 Testing EAP-TLS authentication against a FreeRADIUS server or authenticator
    * Execute "cp -f contrib/8021x/doc_procedures/wpa_supplicant-TLS.conf /etc/wpa_supplicant/wpa_supplicant-TLS.conf"
    Then Note the output of "eapol_test -c /etc/wpa_supplicant/wpa_supplicant-TLS.conf -a 127.0.0.1 -s client_password"
     And Noted value contains "EAP: Status notification: remote certificate verification \(param=success\)"
     And Noted value contains "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully"
     And Noted value contains "SUCCESS"
    * Run child "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TLS.conf -D wired -i test1 -d -t" without shell
    Then Expect "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" in children in "5" seconds
    * Kill children with signal "15"
    Then Expect "CTRL-EVENT-TERMINATING" in children in "5" seconds
    * Add "ethernet" connection named "test1-tls" for device "test1" with options
            """
            autoconnect no
            802-1x.eap tls
            802-1x.identity spam
            802-1x.ca-cert /etc/pki/tls/certs/8021x-ca.pem
            802-1x.client-cert /etc/pki/tls/certs/8021x.pem
            802-1x.private-key /etc/pki/tls/private/8021x.key
            802-1x.private-key-password whatever
            802-1x.auth-timeout 75
            connection.auth-retries 5
            """
    * Wait for "1" seconds
    When Bring "up" connection "test1-tls"
    Then Check if "test1-tls" is active connection
    * Disconnect device "test1"
    ### .8. Blocking and allowing traffic based on hostapd authentication events and check connection using NM
    * Execute "mkdir -p /var/local/bin"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt /usr/local/bin/802-1x-tr-mgmt"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt.service /etc/systemd/system/802-1x-tr-mgmt.service"
    * Execute "systemctl daemon-reload"
    * Add "ethernet" connection named "test1-plain" for device "test1" with options "autoconnect no"
    * Bring "up" connection "test1-plain"
    * Execute "systemctl start 802-1x-tr-mgmt.service"
    * Note MAC address output for device "test1" via ip command
    Then Unable to ping "192.168.100.1" from "test1" device
    Then Noted value is not visible with command "nft list set bridge tr-mgmt-br0 allowed_macs"
    * Bring "down" connection "test1-plain"
    * Bring "up" connection "test1-ttls"
    * Wait for "1" seconds
    Then Noted value is visible with command "nft list set bridge tr-mgmt-br0 allowed_macs"
    * Commentary
        """
        Sometimes, the gateway is unreachable. Let's skip, if the MAC is
        visible in the previous step, we're good anyway
        """
    * Skip if next step fails:
    Then Ping "192.168.100.1" from "test1" device


    @rhelver+=10
    @permissive
    # permissive is needed for 802-1x-tr-mgmt service to start
    # selinux-policy bug seems to be not fixed on rhel10
    @not_in_image_mode
    @firewall @radius @8021x_doc_procedure @attach_wpa_supplicant_log
    @8021x_hostapd_freeradius_doc_procedure
    Scenario: nmcli - docs - set up 802.1x using FreeRadius and hostapd
    * Doc: "Setting up an 802.1x network authentication service for LAN clients by using hostapd with FreeRADIUS backend"
    ### .1 Prerequisites - handled by @radius tag
    ### .2 Setting up the bridge on the authenticator
    * Add "bridge" connection named "br0" for device "br0"
    * Create "veth" device named "test1" with options "peer name test1b"
    * Execute "ip link set test1 up"
    * Add "ethernet" connection named "br0-port1" for device "test1b" with options "port-type bridge controller br0"
    * Modify connection "br0" changing options "group-forward-mask 8 stp off"
    * Modify connection "br0" changing options "connection.autoconnect-ports 1"
    * Bring "up" connection "br0"
    Then "0x8" is visible with command "cat /sys/class/net/br0/bridge/group_fwd_mask"
    Then "test1b@" is visible with command "ip link show master br0"
    ### .3 - configs are handled by @radius tag
    * Execute "firewall-cmd --permanent --add-service=radius"
    * Execute "firewall-cmd --reload"
    ### .4 Configuring hostapd as an authenticator in a wired network
    * Execute "cp contrib/8021x/doc_procedures/hostapd.conf /etc/hostapd/hostapd.conf"
    Then Execute "systemctl start hostapd"
    * Execute "systemctl status hostapd"
    ### .5 Testing EAP-TTLS authentication against a FreeRADIUS server or authenticator
    * Execute "cp -f contrib/8021x/doc_procedures/wpa_supplicant-*.conf /etc/wpa_supplicant/"
    Then Note the output of "eapol_test -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -s client_password"
     And Noted value contains "EAP: Status notification: remote certificate verification \(param=success\)"
     And Noted value contains "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully"
     And Noted value contains "\nSUCCESS$"
    * Run child "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -D wired -i test1" without shell
    Then Expect "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" in children in "5" seconds
    * Kill children with signal "15"
    Then Expect "CTRL-EVENT-TERMINATING" in children in "5" seconds
    ### .6 Blocking and allowing traffic based on hostapd authentication events and check connection using NM
    * Note MAC address output for device "test1" via ip command as "test1_mac"
    * Execute "mkdir -p /var/local/bin"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt-rhel10 /usr/local/bin/802-1x-tr-mgmt"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt@.service /etc/systemd/system/802-1x-tr-mgmt@.service"
    * Execute "systemctl daemon-reload"
    * Execute "systemctl start 802-1x-tr-mgmt@br0.service"
    Then Noted value "test1_mac" is not visible with command "nft list set bridge tr-mgmt-br0 allowed_macs"
    Then Note the output of "eapol_test -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -s client_password"
     And Noted value contains "EAP: Status notification: remote certificate verification \(param=success\)"
     And Noted value contains "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully"
     And Noted value contains "\nSUCCESS"
    * Run child "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -D wired -i test1" without shell
    Then Expect "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" in children in "5" seconds
    * Kill children with signal "15"
    Then Noted value "test1_mac" is visible with command "nft list set bridge tr-mgmt-br0 allowed_macs"


    @doc_set_gateway_on_existing_profile
    Scenario: nmcli - doc - routes - set gateway to exisitng profile
    * Doc: "Setting the default gateway on an existing connection using nmcli"
    * Add "ethernet" connection named "con_doc" for device "eth10" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.2.5/24"
            ipv6.method manual
            ipv6.addresses "2001:db8:1::6"
            """
    * Modify connection "con_doc" changing options "ipv4.gateway "192.0.2.1""
    * Modify connection "con_doc" changing options "ipv6.gateway "2001:db8:1::1""
    * Bring "up" connection "con_doc"
    Then "default via 192.0.2.1 dev eth10 proto static metric 10" is visible with command "ip -4 route" in "20" seconds
    Then "default via 2001:db8:1::1 dev eth10 proto static metric 10.* pref medium" is visible with command "ip -6 route" in "20" seconds


    @doc_set_gateway_nmstate
    Scenario: nmstate - doc - set gateway to existing profile
    * Doc: "Setting the default gateway on an existing connection using nmstatectl"
    * Add "ethernet" connection named "con_doc" for device "eth1" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.2.5/24"
            ipv6.method manual
            ipv6.addresses "2001:db8:1::6"
            """
    * Execute "nmstatectl apply contrib/doc/set_default_gw.yml"
    Then "default via 192.0.2.1" is visible with command "ip -4 r"
    Then "2001:db8:1::1" is visible with command "ip -6 r"
    Then "192.0.2.1" is visible with command "nmcli c show con_doc"
    Then "2001:db8:1::1" is visible with command "nmcli c show con_doc"


    @eth0
    @doc_set_gateway_multiple
    Scenario: nmcli - doc - set gateway to multiple devices
    * Doc: "How NetworkManager manages multiple default gateways"
    * Add "ethernet" connection named "con_doc_1" for device "eth1" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.2.5/24"
            ipv4.gateway 192.0.2.1
            ipv6.method manual
            ipv6.addresses "2001:db8:1::6/64"
            ipv6.gateway "2001:db8:1::1"
            """
    * Add "ethernet" connection named "con_doc_2" for device "eth2" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.3.5/24"
            ipv4.gateway 192.0.3.1
            ipv6.method manual
            ipv6.addresses "2001:db8:2::6/64"
            ipv6.gateway "2001:db8:2::1"
            """
    Then "default via 192.0.2.1 dev eth1 proto static metric 100" is visible with command "ip -4 r"
    And "default via 192.0.3.1 dev eth2 proto static metric 101" is visible with command "ip -4 r"
    And "default via 2001:db8:1::1 dev eth1 proto static metric 100 pref medium" is visible with command "ip -6 r"
    And "default via 2001:db8:2::1 dev eth2 proto static metric 101 pref medium" is visible with command "ip -6 r"


    @eth0
    @doc_set_gateway_multiple_with_metric
    Scenario: nmcli - doc - set gateway and metric to multiple devices
    * Doc: "Configuring NetworkManager to avoid using a specific profile to provide a default gateway"
    * Add "ethernet" connection named "con_doc_1" for device "eth1" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.2.5/24"
            ipv4.gateway 192.0.2.1
            ipv6.method manual
            ipv6.addresses "2001:db8:1::6/64"
            ipv6.gateway "2001:db8:1::1"
            ipv6.route-metric 200
            """
    * Add "ethernet" connection named "con_doc_2" for device "eth2" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.3.5/24"
            ipv4.gateway 192.0.3.1
            ipv4.route-metric 40
            ipv6.method manual
            ipv6.addresses "2001:db8:2::6/64"
            ipv6.gateway "2001:db8:2::1"
            """
    Then "default via 192.0.2.1 dev eth1 proto static metric 100" is visible with command "ip -4 r"
    And "default via 192.0.3.1 dev eth2 proto static metric 40" is visible with command "ip -4 r"
    And "default via 2001:db8:1::1 dev eth1 proto static metric 200 pref medium" is visible with command "ip -6 r"
    And "default via 2001:db8:2::1 dev eth2 proto static metric 101 pref medium" is visible with command "ip -6 r"


    @doc_set_gateway_ignore
    Scenario: nmcli - doc - set connection to ignore gateway
    * Doc: "Fixing unexpected routing behavior due to multiple default gateways"
    * Add "ethernet" connection named "con_doc_1" for device "eth1" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.2.5/24"
            ipv4.gateway 192.0.2.1
            ipv4.never-default yes
            ipv6.method manual
            ipv6.addresses "2001:db8:1::6/64"
            ipv6.gateway "2001:db8:1::1"
            ipv6.never-default yes
            """
    * Add "ethernet" connection named "con_doc_2" for device "eth2" with options
            """
            ipv4.method manual
            ipv4.addresses "192.0.3.5/24"
            ipv4.gateway 192.0.3.1
            ipv6.method manual
            ipv6.addresses "2001:db8:2::6/64"
            ipv6.gateway "2001:db8:2::1"
            """
    Then "default via [^\n]* dev eth1" is not visible with command "ip -4 r"
    And "default via 192.0.3.1 dev eth2 proto static metric 101" is visible with command "ip -4 r"
    Then "default via [^\n]* dev eth1" is not visible with command "ip -6 r"
    And "default via 2001:db8:2::1 dev eth2 proto static metric 101 pref medium" is visible with command "ip -6 r"


    @prepare_patched_netdevsim
    @doc_unmanage_interface_permanent
    Scenario: NM - unmanage in terface in config
    * Doc: "Permanently configuring a device as unmanaged in NetworkManager"
    * Create NM config file "99-unmanage-doc.conf" with content and "reload" NM
      """
      [keyfile]
      unmanaged-devices=interface-name:eth11
      """
    Then "unmanaged:eth11" is visible with command "nmcli -g state,device device status"
    Then "disconnected:eth12" is visible with command "nmcli -g state,device device status"
    Then "disconnected:eth13" is visible with command "nmcli -g state,device device status"
    * Note MAC address output for device "eth12" via ip command as "mac_eth12"
    * Create NM config file "99-unmanage-doc.conf" with content and "reload" NM
      """
      [keyfile]
      unmanaged-devices=mac:<noted:mac_eth12>
      """
    Then "disconnected:eth11" is visible with command "nmcli -g state,device device status"
    Then "unmanaged:eth12" is visible with command "nmcli -g state,device device status"
    Then "disconnected:eth13" is visible with command "nmcli -g state,device device status"
    * Create NM config file "99-unmanage-doc.conf" with content and "reload" NM
      """
      [keyfile]
      unmanaged-devices=type:ethernet
      """
    Then "unmanaged:eth11" is visible with command "nmcli -g state,device device status"
    Then "unmanaged:eth12" is visible with command "nmcli -g state,device device status"
    Then "unmanaged:eth13" is visible with command "nmcli -g state,device device status"
    * Create NM config file "99-unmanage-doc.conf" with content and "reload" NM
      """
      [keyfile]
      unmanaged-devices=interface-name:eth11;interface-name:eth12
      """
    Then "unmanaged:eth11" is visible with command "nmcli -g state,device device status"
    Then "unmanaged:eth12" is visible with command "nmcli -g state,device device status"
    Then "disconnected:eth13" is visible with command "nmcli -g state,device device status"


    @doc_unmanage_interface_temporary
    Scenario: nmcli - unmanage device temporarily
    * Doc: "Temporarily configuring a device as unmanaged in NetworkManager"
    * Cleanup execute "nmcli d set eth1 managed yes"
    When "disconnected:eth1:" is visible with command "nmcli -g state,device,type device status"
    * Execute "nmcli device set eth1 managed no"
    Then "unmanaged:eth1:" is visible with command "nmcli -g state,device,type device status"
    * Reload NM
    Then "unmanaged:eth1:" is visible with command "nmcli -g state,device,type device status"
    * Restart NM
    Then "unmanaged:eth1:" is visible with command "nmcli -g state,device,type device status"
    * Reboot
    Then "disconnected:eth1:" is visible with command "nmcli -g state,device,type device status"


    @ver+=1.52
    @doc_nmcli_route_all_options
    Scenario: nmcli - set all route options in connection
    * Doc: "Configuring a static route using an nmcli command"
    * Add "ethernet" connection named "con_doc" for device "eth1" with options
      """
      ipv4.method manual
      ipv4.addresses 192.168.100.6/24
      ipv4.routes "192.168.4.1/24 192.168.100.254 30
            cwnd=30
            lock-cwnd=true
            lock-mtu=true
            lock-window=true
            mtu=1450
            onlink=true
            scope=20
            src=192.168.4.99
            table=32766
            tos=47
            type=unicast
            window=10"
      """
    * Commentary
      """
      The route is discarded by kernel, because all params are set.
      """
    * Modify connection "con_doc" changing options "+ipv4.routes '192.168.0.0/24 192.168.100.1'"
    Then "192.168.0.0/24" is visible with command "nmcli -g ipv4.routes c show con_doc"
    And "192.168.4.1/24" is visible with command "nmcli -g ipv4.routes c show con_doc"
    * Modify connection "con_doc" changing options "-ipv4.routes '192.168.0.0/24 192.168.100.1'"
    Then "192.168.0.0/24" is not visible with command "nmcli -g ipv4.routes c show con_doc"
    And "192.168.4.1/24" is visible with command "nmcli -g ipv4.routes c show con_doc"


    # the same feature as general_nmcli_offline_connection_add_modify tests
    @rhelver+=8.7 @rhelver+=9.1
    @ver+=1.39.2
    @restart_if_needed
    @doc_nmcli_offline_connection_add
    Scenario: nmcli - doc - general - Using nmcli to create key file connection profiles in offline mode
    * Doc: "Using nmcli to create key file connection profiles in offline mode"
    * Cleanup connection "Example-Connection"
    * Stop NM
    * Execute "nmcli --offline connection add type ethernet con-name Example-Connection ipv4.addresses 192.0.2.1/24 ipv4.dns 192.0.2.200 ipv4.method manual > /etc/NetworkManager/system-connections/example.nmconnection"
    * Start NM
    * Execute "chmod 600 /etc/NetworkManager/system-connections/example.nmconnection ; chown root:root /etc/NetworkManager/system-connections/example.nmconnection"
    Then "ethernet\s+/etc/NetworkManager/system-connections/example.nmconnection\s+Example-Connection" is not visible with command "nmcli -f TYPE,FILENAME,NAME connection"
    * Reload connections
    * Bring "up" connection "Example-Connection"
    Then "ethernet\s+/etc/NetworkManager/system-connections/example.nmconnection\s+Example-Connection" is visible with command "nmcli -f TYPE,FILENAME,NAME connection" in "10" seconds
    Then Execute "nmcli connection show Example-Connection"


    @restart_if_needed
    @doc_keyfile_connection_add
    Scenario: nmcli - doc - general - Using nmcli to create key file connection profiles in offline mode
    * Doc: "Using nmcli to create key file connection profiles in offline mode"
    * Cleanup connection "Example-Connection"
    * Create keyfile "/etc/NetworkManager/system-connections/example.nmconnection"
      """
      [connection]
      id=Example-Connection
      type=ethernet
      autoconnect=true
      interface-name=eth2

      [ipv4]
      method=auto

      [ipv6]
      method=auto
      """
    * Execute "chmod 600 /etc/NetworkManager/system-connections/example.nmconnection ; chown root:root /etc/NetworkManager/system-connections/example.nmconnection"
    Then "ethernet\s+/etc/NetworkManager/system-connections/example.nmconnection\s+Example-Connection" is not visible with command "nmcli -f TYPE,FILENAME,NAME connection"
    * Reload connections
    * Bring "up" connection "Example-Connection"
    Then "ethernet\s+/etc/NetworkManager/system-connections/example.nmconnection\s+Example-Connection" is visible with command "nmcli -f TYPE,FILENAME,NAME connection" in "10" seconds
    Then Execute "nmcli connection show Example-Connection"


    @eth0  # to prevent packet fragmentation stats to change
    @doc_set_mtu_9000
    Scenario: nmci - ethernet - set MTU 9000 and verify
    * Doc: "Configuring the MTU in an existing NetworkManager connection profile"
    * Prepare simulated test "testG" device
    * Execute "ip -n testG_ns link set dev testGp mtu 9000"
    * Add "ethernet" connection named "Example" for device "testG" with options "autoconnect no"
    * Bring "up" connection "Example"
    * Note the output of "nstat -az IpReasm*" as value "nstat1"
    * Modify connection "Example" changing options "mtu 9000"
    * Bring "up" connection "Example"
    Then "mtu\s+9000" is visible with command "ip link show dev testG"
    Then Execute "ping -c1 -Mdo -s 8972 192.168.99.1"
    * Note the output of "nstat -az IpReasm*" as value "nstat2"
    Then Check noted values "nstat1" and "nstat2" are the same


    @rhelver+=9.3 @rhelver+=8.9
    @dns_dnsmasq
    @doc_split_dns_dnsmasq
    Scenario: Using different DNS servers for different domains - dnsmasq
    * Doc: "Using different DNS servers for different domains"
    * Prepare simulated test "ethX" device with "192.168.99" ipv4 and "none" ipv6 dhcp address prefix and "2m" leasetime and daemon options "--local=/example.com/ --domain=example.com --address=/www.example.com/192.168.99.3"
    * Start following journal
    * Add "ethernet" connection named "con_ethX" for device "ethX" with options "ipv4.method auto ipv4.dns-search example.com autoconnect yes"
    Then Execute "grep '^nameserver 127.0.0.1$' /etc/resolv.conf"
    Then "exactly" "1" lines are visible with command "grep '^nameserver' /etc/resolv.conf"
    Then "using nameserver 192.168.99.1.* for domain example.com" is visible in journal in "10" seconds
    * Note the output of "ip -4 a show dev eth0 | grep -o 'inet [^/]*/' | grep -o '[0-9.]*' | tr -d '\n'" as value "eth0_ip4"
    * Note the output of "ip -4 a show dev ethX | grep -o 'inet [^/]*/' | grep -o '[0-9.]*' | tr -d '\n'" as value "ethX_ip4"
    * Run child "stdbuf -oL -eL tcpdump -nn -i any port 53"
    # We need some time to allow tcpdump to start (especially on ppc64le)
    * Wait for "3" seconds
    Then "www.redhat.com.* has address" is visible with command "host -t A www.redhat.com" in "20" seconds
    Then Expect "<noted:eth0_ip4>.*www.redhat.com" in children in "5" seconds
    Then "www.example.com has address 192.168.99.3" is visible with command "host -t A www.example.com" in "20" seconds
    And Expect "<noted:ethX_ip4>.*www.example.com" in children in "5" seconds


    @rhelver+=9.3 @rhelver+=8.9
    @dns_systemd_resolved
    @doc_split_dns_resolved
    Scenario: Using different DNS servers for different domains - dnsmasq
    * Doc: "Using different DNS servers for different domains"
    * Prepare simulated test "ethX" device with "192.168.99" ipv4 and "none" ipv6 dhcp address prefix and "2m" leasetime and daemon options "--local=/example.com/ --domain=example.com --address=/www.example.com/192.168.99.3"
    * Add "ethernet" connection named "con_ethX" for device "ethX" with options "ipv4.method auto ipv4.dns-search example.com autoconnect yes"
    Then Execute "grep '^nameserver 127.0.0.53$' /etc/resolv.conf"
    Then "exactly" "1" lines are visible with command "grep '^nameserver' /etc/resolv.conf"
    Then "\(ethX\): example.com" is visible with command "resolvectl domain" in "10" seconds
    * Note the output of "ip -4 a show dev eth0 | grep -o 'inet [^/]*/' | grep -o '[0-9.]*' | tr -d '\n'" as value "eth0_ip4"
    * Note the output of "ip -4 a show dev ethX | grep -o 'inet [^/]*/' | grep -o '[0-9.]*' | tr -d '\n'" as value "ethX_ip4"
    * Run child "stdbuf -oL -eL tcpdump -nn -i any port 53"
    # We need some time to allow tcpdump to start (especially on ppc64le)
    * Wait for "3" seconds
    Then "www.redhat.com.* has address" is visible with command "host -t A www.redhat.com" in "20" seconds
    Then Expect "<noted:eth0_ip4>.*www.redhat.com" in children in "5" seconds
    Then "www.example.com has address 192.168.99.3" is visible with command "host -t A www.example.com" in "20" seconds
    And Expect "<noted:ethX_ip4>.*www.example.com" in children in "5" seconds


    @rhelver+=8.9 @rhelver-9.0 @fedoraver-=0
    @ver-1.44
    @disp
    @doc_transmit_queue_length
    Scenario: docs - Increasing the transmit queue length of a NIC to reduce the number of transmit errors
    * Doc "Monitoring and managing system status and performance": "Increasing the transmit queue length of a NIC to reduce the number of transmit errors"
    * Add "dummy" connection named "con_ethernet" for device "dummy0" with options "autoconnect no"
    * Write dispatcher "99-disp" file with params "if [ "$1" == "dummy0" ] && [ "$2" == "up" ] ; then ip link set dev dummy0 txqueuelen 2000; fi"
    * Wait for "0.5" seconds
    When Bring "up" connection "con_ethernet"
    Then "default qlen 2000" is visible with command "ip -s link show dummy0" in "5" seconds


    @rhelver+=9.3
    @ver+=1.44
    @doc_transmit_queue_length
    Scenario: docs - Increasing the transmit queue length of a NIC to reduce the number of transmit errors
    * Doc "Monitoring and managing system status and performance": "Increasing the transmit queue length of a NIC to reduce the number of transmit errors"
    * Add "dummy" connection named "con_ethernet" for device "dummy0" with options
        """
        autoconnect no link.tx-queue-length 2000
        """
    When Bring "up" connection "con_ethernet"
    Then "default qlen 2000" is visible with command "ip -s link show dummy0" in "5" seconds


    @RHELDOCS-16954
    @rhelver+=9.3
    @keyfile @firewall
    @doc_firewalld_zones_via_keyfile
    Scenario: connection - zone of interface defined in keyfile
    * Doc "Configuring firewalls and packet filters": "Manually assigning a zone to a network connection in a connection profile file"
    * Add "ethernet" connection named "con_con" for device "eth5"
    * Note the output of "nmcli -t -f NAME,FILENAME connection | sed -n 's/^con_con:// p'"
    #* In noted keyfile, section "connection", set "zone" key to "internal"
    * Update the noted keyfile
        """
        [connection]
        zone=internal
        """
    * Reload connections
    When Execute "nmcli connection up con_con"
    Then "internal" is visible with command "firewall-cmd --get-zone-of-interface eth5"


    @RHELDOCS-16954
    @rhelver+=9.3
    @rhelver-10
    @ifcfg-rh @firewall
    @doc_firewalld_zones_via_ifcfg
    Scenario: connection - zone of interface defined in ifcfg
    * Doc "Configuring firewalls and packet filters": "Manually assigning a zone to a network connection in a connection profile file"
    * Add "ethernet" connection named "con_con" for device "eth5"
    * Append "ZONE=internal" to ifcfg file "con_con"
    * Reload connections
    When Execute "nmcli connection up con_con"
    Then "internal" is visible with command "firewall-cmd --get-zone-of-interface eth5"


    @RHELDOCS-19823
    @rhelver+=9.6
    @rhelver+=10.0
    @doc_unmanaged_reason
    Scenario: test unmanaged reson for certain devices
    * Doc: "Identifying the reason why NetworkManager does not manage a certain network device"
    * Create udev rule "90-nmci-unmanage-testX1.rules" with content
      """
      ENV{ID_NET_DRIVER}=="veth", ENV{INTERFACE}=="testX1*", ENV{NM_UNMANAGED}="1"
      """
    * Create NM config file "99-unmanage-testX2.conf" with content
      """
      [keyfile]
      unmanaged-devices=interface-name:testX2
      """
    * Create NM config file "99-unmanage-testX3.conf" with content
      """
      [device-unmanage-testX3]
      match-device=interface-name:testX3*
      managed=0
      """
    * Commentary
    """
    Use reboot step to delete all possible device state config in /run/NetworkManager.
    Without reboot, testX3 RESON is unmanaged by udev on some systems.
    """
    * Reboot
    * Create "veth" device named "testX1" with options "peer testX2"
    * Create "veth" device named "testX3" with options "peer testX4"
    * Create "dummy" device named "testX5"
    * Execute "NetworkManager --print-config"
    * Execute "nmcli d set testX4 managed no"
    Then String "77 (The device is unmanaged via udev rule)" is visible with command "nmcli -g GENERAL.REASON d show testX1"
    Then String "76 (The device is unmanaged by user decision via settings plugin" is visible with command "nmcli -g GENERAL.REASON d show testX2"
    Then String "74 (The device is unmanaged by user decision in NetworkManager.conf ('unmanaged' in a [device*] section)" is visible with command "nmcli -g GENERAL.REASON d show testX3"
    Then String "75 (The device is unmanaged by explicit user decision (e.g. 'nmcli device set $DEV managed no'))" is visible with command "nmcli -g GENERAL.REASON d show testX4"
    Then String "70 (The device is unmanaged because it is an external device and is unconfigured (down or without addresses))" is visible with command "nmcli -g GENERAL.REASON d show testX5"