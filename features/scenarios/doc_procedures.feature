Feature: nmcli - procedures in documentation

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @ver+=1.18
    @firewall @eth0 @tcpdump
    @policy_based_routing_doc_procedure
    Scenario: nmcli - docs -  Configuring policy-based routing to define alternative routes
    * Prepare PBR documentation procedure
    * Add "ethernet" connection named "Provider-A" for device "provA" with options
          """
          ipv4.method manual
          ipv4.addresses 198.51.100.1/30
          ipv4.gateway 198.51.100.2
          ipv4.dns 198.51.100.2
          connection.zone external
          """
    * Bring "up" connection "Provider-A"
    * Add "ethernet" connection named "Provider-B" for device "provB" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/30
          ipv4.routes '0.0.0.0/1 192.0.2.2 table=5000, 128.0.0.0/1 192.0.2.2 table=5000'
          connection.zone external
          """
    * Add "ethernet" connection named "Internal-Workstations" for device "int_work" with options
          """
          ipv4.method manual
          ipv4.addresses 10.0.0.1/24
          ipv4.routes '10.0.0.0/24 table=5000'
          ipv4.routing-rules 'priority 5 from 10.0.0.0/24 table 5000'
          connection.zone trusted
          """
    * Bring "up" connection "Internal-Workstations"
    * Bring "up" connection "Provider-B"
    * Add "ethernet" connection named "Servers" for device "servers" with options
          """
          ipv4.method manual
          ipv4.addresses 203.0.113.1/24
          connection.zone trusted
          """
    * Bring "up" connection "Servers"
    * Execute "ip -n provB_ns route add default via 192.0.2.1"
    * Execute "ip -n int_work_ns route add default via 10.0.0.1"
    * Execute "ip -n servers_ns route add default via 203.0.113.1"
    * Execute "ip -n provA_ns route add default via 198.51.100.1"
    # do not bring down eth0 sooner, adding other default routes above may fail
    * Bring "down" connection "testeth0"
    Then "external\s+interfaces: provA provB" is visible with command "firewall-cmd --get-active-zones"
    Then "trusted\s+interfaces: int_work servers" is visible with command "firewall-cmd --get-active-zones"
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
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @need_legacy_crypto
    @8021x_peap_mschapv2_doc_procedure
    Scenario: nmcli - docs - Configuring 802.1x network authentication on an existing Ethernet connection using nmcli
    * Add "ethernet" connection named "con_ethernet" for device "test8X" with options "autoconnect no"
    * Modify connection "con_ethernet" changing options "802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "con_ethernet" changing options "802-1x.password password"
    * Modify connection "con_ethernet" changing options "802-1x.ca-cert /tmp/certs/test_user.ca.pem"
    Then Bring "up" connection "con_ethernet"


    @8021x_teardown
    @8021x_teardown_doc
    Scenario: just remove 802.1-x set up
    * Execute "echo 'this is skipped'"


    @ver+=1.10 @fedoraver+=31
    @need_legacy_crypto
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_mschapv2_doc_procedure
    Scenario: nmcli - docs - Configuring 802.1x network authentication on an existing Wi-Fi connection using nmcli
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Modify connection "wifi" changing options "802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "wifi" changing options "802-1x.password password"
    * Modify connection "wifi" changing options "802-1x.ca-cert /tmp/certs/test_user.ca.pem"
    Then Bring "up" connection "wifi"


    @simwifi_teardown
    @nmcli_simwifi_teardown_doc
    Scenario: teardown wifi setup
    * Execute "echo 'this is skipped'"

    @ver+=1.14
    @iptunnel_ipip_doc_procedure
    Scenario: nmcli - docs - Configuring an IPIP tunnel using nmcli to encapsulate IPv4 traffic in IPv4 packets
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
    Then "bridge0:bridge:connected:bridge0" is visible with command "nmcli -t device"
    Then "netA:ethernet:connected:bridge0-port1" is visible with command "nmcli -t device"
    Then "gretap1:iptunnel:connected:bridge0-port2" is visible with command "nmcli -t device"
    Then Execute "ping -c 1 192.0.2.2"
    Then Execute "ip netns exec iptunnelB ping -c 1 192.0.2.1"
    Then Execute "ip netns exec netA_ns ping -c 1 192.0.2.4"
    Then Execute "ip netns exec netB_ns ping -c 1 192.0.2.3"


    @rhelver+=8
    @eth0
    @qdisc_doc_procedure
    Scenario: nmcli - docs - Permanently setting the current qdisk of a network interface
    * Execute "tc qdisc replace dev eth0 root fq_codel"
    Given "qdisc fq_codel .*: root refcnt .*" is visible with command "tc qdisc show dev eth0"
    * Add "ethernet" connection named "con_tc" for device "eth0"
    * Modify connection "con_tc" changing options "tc.qdisc 'root pfifo_fast'"
    * Modify connection "con_tc" changing options "+tc.qdisc 'ingress handle ffff:'"
    When "qdisc fq_codel .*: root refcnt .*" is visible with command "tc qdisc show dev eth0"
    * Bring "up" connection "con_tc"
    Then "qdisc pfifo_fast .*: root refcnt .* bands 3 priomap\s+1 2 2 2 1 2 0 0 1 1 1 1 1 1 1 1" is visible with command "tc qdisc show dev eth0"
    And  "qdisc ingress ffff: parent ffff:fff1\s+----------------" is visible with command "tc qdisc show dev eth0"


    @rhelver+=8
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_doc_procedure
    Scenario: nmcli - docs - Using MACsec to encrypt layer-2 traffic in the same physical network
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
    * Bring up connection "test-macsec"
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
    * Bring up connection "server-wg0"
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
    * Bring up connection "client-wg0"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show client-wg0" in "40" seconds
     Then "192.0.2.1:51820" is visible with command "wg show wg1"
      And "inet 192.0.2.2/24 brd 192.0.2.255 scope global noprefixroute wg1" is visible with command "ip address show wg1"
      And "inet6 2001:db8:1::2/32 scope global noprefixroute" is visible with command "ip address show wg1"

    @rhelver+=9
    @wireguard
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
    * Prepare new connection of type "WireGuard" named "client-wg0"
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
    * Bring up connection "br88"
    * Execute "firewall-cmd --permanent --add-port=8472/udp"
    * Execute "firewall-cmd --reload"
    Then "master br4 permanent" is visible with command "bridge fdb show dev vxlan10"


    @radius @8021x_doc_procedure @attach_wpa_supplicant_log
    # permissive is required until selinux-policy is updated in:
    #   - el9: https://bugzilla.redhat.com/show_bug.cgi?id=2064688
    #   - el8: https://bugzilla.redhat.com/show_bug.cgi?id=2064284
    @permissive
    @8021x_hostapd_freeradius_doc_procedure
    Scenario: nmcli - docs - set up 802.1x using FreeRadius and hostapd
    ### 1. Setting up the bridge on the authenticator
    * Add "bridge" connection named "br0" for device "br0" with options
            """
            con-name br0
            group-forward-mask 8 connection.autoconnect-slaves 1
            ipv4.method disabled ipv6.method disabled
            """
    * Add "ethernet" connection named "br0-uplink" for device "eth4" with options "master br0"
    # bridge port to have access limited by 802.1x auth
    * Execute "ip l add test1 type veth peer name test1b"
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
    Then "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" is visible with command "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TTLS.conf -D wired -i test1 -d -t"
    * Add "ethernet" connection named "test1-ttls" for device "test1" with options
            """
            autoconnect no 802-1x.eap ttls 802-1x.phase2-auth pap
            802-1x.identity example_user 802-1x.password user_password
            802-1x.ca-cert /etc/pki/tls/certs/8021x-ca.pem
            """
    When Bring up connection "test1-ttls"
    Then Check if "test1-ttls" is active connection
    * Disconnect device "test1"
    ### .7 Testing EAP-TLS authentication against a FreeRADIUS server or authenticator
    * Execute "cp -f contrib/8021x/doc_procedures/wpa_supplicant-TLS.conf /etc/wpa_supplicant/wpa_supplicant-TLS.conf"
    Then Note the output of "eapol_test -c /etc/wpa_supplicant/wpa_supplicant-TLS.conf -a 127.0.0.1 -s client_password"
     And Noted value contains "EAP: Status notification: remote certificate verification \(param=success\)"
     And Noted value contains "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully"
     And Noted value contains "SUCCESS"
    Then "CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully" is visible with command "wpa_supplicant -c /etc/wpa_supplicant/wpa_supplicant-TLS.conf -D wired -i test1 -d -t"
    * Add "ethernet" connection named "test1-tls" for device "test1" with options
            """
            autoconnect no 802-1x.eap tls 802-1x.identity spam
            802-1x.ca-cert /etc/pki/tls/certs/8021x-ca.pem 802-1x.client-cert /etc/pki/tls/certs/8021x.pem
            802-1x.private-key /etc/pki/tls/private/8021x.key 802-1x.private-key-password whatever
            """
    When Bring up connection "test1-tls"
    Then Check if "test1-tls" is active connection
    * Disconnect device "test1"
    ### .8. Blocking and allowing traffic based on hostapd authentication events and check connection using NM
    * Execute "mkdir -p /usr/local/bin"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt /usr/local/bin/802-1x-tr-mgmt"
    * Execute "cp -f contrib/8021x/doc_procedures/802-1x-tr-mgmt.service /etc/systemd/system/802-1x-tr-mgmt.service"
    * Execute "systemctl daemon-reload"
    * Add "ethernet" connection named "test1-plain" for device "test1" with options "autoconnect no"
    * Bring up connection "test1-plain"
    * Execute "systemctl start 802-1x-tr-mgmt.service"
    Then Unable to ping "192.168.100.1" from "test1" device
    * Bring down connection "test1-plain"
    * Bring up connection "test1-ttls"
    * Execute "sleep 1"
    Then Ping "192.168.100.1" from "test1" device
    ### Uncomment next steps if https://bugzilla.redhat.com/show_bug.cgi?id=2067124 gets approved, remove if rejected
    #* Bring down connection "test1-ttls"
    #* Execute "ip l set test1 up; ip a add 192.168.123/24 dev test1"
    #Then Unable to ping "192.168.100.1" from "test1" device
