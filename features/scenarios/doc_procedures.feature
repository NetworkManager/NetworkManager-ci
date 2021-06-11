Feature: nmcli - procedures in documentation

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @ver+=1.18
    @con_PBR_remove @firewall @eth0 @teardown_testveth @tcpdump
    @policy_based_routing_doc_procedure
    Scenario: nmcli - docs -  Configuring policy-based routing to define alternative routes
    * Prepare PBR documentation procedure
    * Add a new connection of type "ethernet" and options "con-name Provider-A ifname provA ipv4.method manual ipv4.addresses 198.51.100.1/30 ipv4.gateway 198.51.100.2 ipv4.dns 198.51.100.2 connection.zone external"
    * Bring "up" connection "Provider-A"
    * Add a new connection of type "ethernet" and options "con-name Provider-B ifname provB ipv4.method manual ipv4.addresses 192.0.2.1/30 ipv4.routes '0.0.0.0/1 192.0.2.2 table=5000, 128.0.0.0/1 192.0.2.2 table=5000' connection.zone external"
    * Bring "up" connection "Provider-B"
    * Add a new connection of type "ethernet" and options "con-name Internal-Workstations ifname int_work ipv4.method manual ipv4.addresses 10.0.0.1/24 ipv4.routes '10.0.0.0/24 src=192.0.2.1 table=5000' ipv4.routing-rules 'priority 5 from 10.0.0.0/24 table 5000' connection.zone internal"
    * Bring "up" connection "Internal-Workstations"
    * Add a new connection of type "ethernet" and options "con-name Servers ifname servers ipv4.method manual ipv4.addresses 203.0.113.1/24 connection.zone internal"
    * Bring "up" connection "Servers"
    * Execute "ip -n provB_ns route add default via 192.0.2.1"
    * Execute "ip -n int_work_ns route add default via 10.0.0.1"
    * Execute "ip -n servers_ns route add default via 203.0.113.1"
    * Execute "ip -n provA_ns route add default via 198.51.100.1"
    # do not bring down eth0 sooner, adding other default routes above may fail
    * Bring "down" connection "testeth0"
    Then "external\s+interfaces: provA provB" is visible with command "firewall-cmd --get-active-zones"
    Then "internal\s+interfaces: int_work servers" is visible with command "firewall-cmd --get-active-zones"
    Then "from 10.0.0.0/24 lookup 5000" is visible with command "ip rule list"
    Then "0.0.0.0/1 via 192.0.2.2 dev provB" is visible with command "ip route list table 5000"
    Then "10.0.0.0/24 dev int_work" is visible with command "ip route list table 5000"
    Then "128.0.0.0/1 via 192.0.2.2 dev provB" is visible with command "ip route list table 5000"
    * Run child "ip netns exec provA_ns tcpdump -nn -i provAp icmp > /tmp/tcpdump_provA.log"
    * Run child "ip netns exec provB_ns tcpdump -nn -i provBp icmp > /tmp/tcpdump_provB.log"
    * Execute "ip netns exec servers_ns ping -c 3 172.20.20.20"
    * Execute "pkill tcpdump"
    Then "198.51.100.1 > 172.20.20.20" is visible with command "cat /tmp/tcpdump_provA.log" in "30" seconds
     And "> 172.20.20.20" is not visible with command "cat /tmp/tcpdump_provB.log"
    * Run child "ip netns exec provA_ns tcpdump -nn -i provAp icmp > /tmp/tcpdump_provA.log"
    * Run child "ip netns exec provB_ns tcpdump -nn -i provBp icmp > /tmp/tcpdump_provB.log"
    * Execute "ip netns exec int_work_ns ping -c 3 172.20.20.20"
    * Execute "pkill tcpdump"
    Then "192.0.2.1 > 172.20.20.20" is visible with command "cat /tmp/tcpdump_provB.log" in "30" seconds
     And "> 8.8.8.8" is not visible with command "cat /tmp/tcpdump_provA.log"


    @ver+=1.6.0
    @con_ethernet_remove @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_peap_mschapv2_doc_procedure
    Scenario: nmcli - docs - Configuring 802.1x network authentication on an existing Ethernet connection using nmcli
    * Add a new connection of type "ethernet" and options "ifname test8X con-name con_ethernet autoconnect no"
    * Modify connection "con_ethernet" changing options "802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "con_ethernet" changing options "802-1x.password password"
    * Modify connection "con_ethernet" changing options "802-1x.ca-cert /tmp/certs/test_user.ca.pem"
    Then Bring "up" connection "con_ethernet"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_mschapv2_doc_procedure
    Scenario: nmcli - docs - Configuring 802.1x network authentication on an existing Wi-Fi connection using nmcli
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Modify connection "wifi" changing options "802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "wifi" changing options "802-1x.password password"
    * Modify connection "wifi" changing options "802-1x.ca-cert /tmp/certs/test_user.ca.pem"
    Then Bring "up" connection "wifi"


    @simwifi_teardown
    @nmcli_simwifi_teardown_doc
    Scenario: teardown wifi setup
    * Execute "echo 'this is skipped'"

    @ver+=1.14
    @iptunnel_doc @teardown_testveth
    @iptunnel_ipip_doc_procedure
    Scenario: nmcli - docs - Configuring an IPIP tunnel using nmcli to encapsulate IPv4 traffic in IPv4 packets
    * Prepare "ipip" iptunnel networks A and B
    * Add a new connection of type "ip-tunnel" and options "ip-tunnel.mode ipip con-name tun0 ifname tun0 remote 198.51.100.5 local 203.0.113.10"
    * Modify connection "tun0" changing options "ipv4.addresses '10.0.1.1/30'"
    * Modify connection "tun0" changing options "ipv4.method manual"
    * Modify connection "tun0" changing options "+ipv4.routes '172.16.0.0/24 10.0.1.2'"
    Then Bring "up" connection "tun0"
    Then Execute "ping -c 1 172.16.0.1"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"


    @ver+=1.14
    @iptunnel_doc @teardown_testveth
    @iptunnel_gre_doc_procedure
    Scenario: nmcli - docs - Configuring a GRE tunnel using nmcli to encapsulate layer-3 traffic in IPv4 packets
    * Prepare "gre" iptunnel networks A and B
    * Add a new connection of type "ip-tunnel" and options "ip-tunnel.mode gre con-name gre1 ifname gre1 remote 198.51.100.5 local 203.0.113.10"
    * Modify connection "gre1" changing options "ipv4.addresses '10.0.1.1/30'"
    * Modify connection "gre1" changing options "ipv4.method manual"
    * Modify connection "gre1" changing options "+ipv4.routes '172.16.0.0/24 10.0.1.2'"
    Then Bring "up" connection "gre1"
    Then Execute "ping -c 1 172.16.0.1"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"


    @ver+=1.20
    @iptunnel_doc @teardown_testveth
    @iptunnel_gretap_doc_procedure
    Scenario: nmcli - docs - Configuring a GRETAP tunnel to transfer Ethernet frames over IPv4
    * Prepare "gretap" iptunnel networks A and B
    * Add a new connection of type "bridge" and options "con-name bridge0 ifname bridge0"
    * Modify connection "bridge0" changing options "ipv4.addresses '192.0.2.1/24'"
    * Modify connection "bridge0" changing options "ipv4.method manual"
    * Modify connection "bridge0" changing options "bridge.stp off"
    * Add a new connection of type "ethernet" and options "slave-type bridge con-name bridge0-port1 ifname netA master bridge0"
    * Add a new connection of type "ip-tunnel" and options "ip-tunnel.mode gretap slave-type bridge con-name bridge0-port2 ifname gretap1 remote 198.51.100.5 local 203.0.113.10 master bridge0"
    * Modify connection "bridge0" changing options "connection.autoconnect-slaves 1"
    Then Bring "up" connection "bridge0"
    Then "bridge0:bridge:connected:bridge0" is visible with command "nmcli -t device"
    Then "netA:ethernet:connected:bridge0-port1" is visible with command "nmcli -t device"
    Then "gretap1:iptunnel:connected:bridge0-port2" is visible with command "nmcli -t device"
    Then Execute "ping -c 1 192.0.2.2"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"
    Then Execute "ip netns exec netA_ns ping -c 1 192.0.2.4"
    Then Execute "ip netns exec netB_ns ping -c 1 192.0.2.3"


    @rhelver+=8
    @con_tc_remove @eth0
    @qdisc_doc_procedure
    Scenario: nmcli - docs - Permanently setting the current qdisk of a network interface
    Given "qdisc fq_codel 0: root refcnt 2" is visible with command "tc qdisc show dev eth0"
    * Add a new connection of type "ethernet" and options "con-name con_tc ifname eth0"
    * Modify connection "con_tc" changing options "tc.qdisc 'root pfifo_fast'"
    * Modify connection "con_tc" changing options "+tc.qdisc 'ingress handle ffff:'"
    When "qdisc fq_codel 0: root refcnt 2" is visible with command "tc qdisc show dev eth0"
    * Bring "up" connection "con_tc"
    Then "qdisc pfifo_fast .*: root refcnt 2 bands 3 priomap\s+1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1" is visible with command "tc qdisc show dev eth0"
    And  "qdisc ingress ffff: parent ffff:fff1\s+----------------" is visible with command "tc qdisc show dev eth0"


    @rhelver+=8
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_doc_procedure
    Scenario: nmcli - docs - Using MACsec to encrypt layer-2 traffic in the same physical network
    * Prepare MACsec PSK environment with CAK "50b71a8ef0bd5751ea76de6d6c98c03a" and CKN "f2b4297d39da7330910a74abc0449feb45b5c0b9fc23df1430e1898fcf1c4550"
    * Add a new connection of type "macsec" and options "con-name test-macsec ifname macsec0 autoconnect no macsec.parent macsec_veth macsec.mode psk macsec.mka-cak 50b71a8ef0bd5751ea76de6d6c98c03a macsec.mka-ckn f2b4297d39da7330910a74abc0449feb45b5c0b9fc23df1430e1898fcf1c4550"
    * Modify connection "test-macsec" changing options "ipv4.method manual ipv4.addresses '172.16.10.5/24' ipv4.gateway '172.16.10.1' ipv4.dns '172.16.10.1'"
    * Modify connection "test-macsec" changing options "ipv6.method manual ipv6.addresses '2001:db8:1::1/32' ipv6.gateway '2001:db8:1::fffe' ipv6.dns '2001:db8:1::fffe'"
    * Bring up connection "test-macsec"
    Then Ping "172.16.10.1" "10" times
    Then Ping6 "2001:db8:1::fffe"
