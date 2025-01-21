 Feature: nmcli: libreswan

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @libreswan
    @rhelver-=8
    @libreswan_ikev1_aggressive
    Scenario: nmcli - libreswan - connect in ike1 aggressive
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhbz1292912
    @ver+=1.4.0
    @rhelver-=8
    @libreswan @main
    @libreswan_ikev1_main
    Scenario: nmcli - libreswan - connect in ike1 main
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "passwd" and group "Main" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhelver+=8
    @libreswan @ikev2
    @libreswan_ikev2
    Scenario: nmcli - libreswan - connect in ike2
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    #Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @RHEL-58040
    @fedoraver+=43
    @rhelver+=9
    @libreswan @ikev2
    @libreswan_ikev2_require_id_on_cert_subject
    Scenario: nmcli - libreswan - test require ID on certs in subject
    * Ensure that version of "NetworkManager-libreswan" package is at least
      | version       | distro  |
      | 1.2.22-5.el9  | rhel9   |
      | 1.2.22-2.el9  | rhel9.6 |
      | 1.2.22-2.el9  | c9s     |
      | 1.2.22-3.el10 | rhel10  |
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options
      """
      vpn.data "ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14, rightid=CN=libreswan_server, require-id-on-certificate=yes"
      """
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    #Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"
    * Bring "down" connection "libreswan"
    * Commentary
    """
    Setting rightid to CN=something will force libreswan to match subject directly
    and require-id-on-certificate has no effect
    """
    * Modify connection "libreswan" changing options "+vpn.data 'rightid=CN=invalid_cert'"
    Then Fail up connection "libreswan" in "10" seconds
    # Con might be down or up, if down already, down fails
    * Execute "nmcli con down id libreswan 2>&1 || true"
    * Modify connection "libreswan" changing options "+vpn.data 'require-id-on-certificate=no'"
    Then Fail up connection "libreswan" in "10" seconds
    # Con might be down or up, if down already, down fails
    * Execute "nmcli con down id libreswan 2>&1 || true"
    * Commentary
    """
    Setting rightid to string without 'CN=' will force libreswan to match subject directly
    and require-id-on-certificate should work properly now.
    """
    * Modify connection "libreswan" changing options "+vpn.data 'rightid=invalid_id, require-id-on-certificate=yes'"
    Then Fail up connection "libreswan" in "10" seconds
    # Con might be down or up, if down already, down fails
    * Execute "nmcli con down id libreswan 2>&1 || true"
    * Modify connection "libreswan" changing options "+vpn.data 'require-id-on-certificate=no'"
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"


    # https://gitlab.gnome.org/GNOME/NetworkManager-libreswan/-/issues/11
    # https://issues.redhat.com/browse/RHEL-14288
    @libreswan @main
    @libreswan_add_profile_wrong_password
    Scenario: nmcli - libreswan - add and connect a connection with worong password
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "simply_wrong" and group "yolo" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan" ignoring error
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is not visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is not visible with command "nmcli c show libreswan"


    @rhbz1250723
    @rhelver+=8
    @libreswan @ikev2
    @libreswan_connection_renewal
    Scenario: NM - libreswan - main connection lifetime renewal
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan" for full "130" seconds
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhbz1141947
    @rhelver-=8
    @libreswan
    @libreswan_activate_asking_for_password
    Scenario: nmcli - vpn - activate asking for password
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd"
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhbz1349740
    @rhelver-=8
    @libreswan @long
    @libreswan_activate_asking_for_password_with_delay
    Scenario: nmcli - vpn - activate asking for password with delay
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd" after "40" seconds
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhbz1141947
    @rhelver-=8
    @libreswan
    @libreswan_activate_asking_for_password_and_secret
    Scenario: nmcli - vpn - activate asking for password and secret
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ask" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd" and secret "ipsecret"
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhelver+=8
    @libreswan @ikev2
    @libreswan_terminate
    Scenario: nmcli - libreswan - terminate connection
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    * Bring "down" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds


    @rhelver+=8
    @libreswan @ikev2
    @libreswan_delete_active_profile
    Scenario: nmcli - libreswan - delete active profile
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    * Delete connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds
    Then "172.29.100.0/24 [^\n]*dev libreswan1" is not visible with command "ip route" in "10" seconds



    @rhbz1348901
    @rhelver-=8.4
    @fedoraver-=0
    @ver+=1.4.0
    @libreswan @ikev2
    @dns_systemd_resolved
    @libreswan_dns
    Scenario: nmcli - libreswan - dns
    Given Nameserver "11.12.13.14" is set in "20" seconds
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
     And Nameserver "8.8.8.8" is set
     #And Nameserver "11.12.13.14" is not set
    * Delete connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds
    Then Nameserver "8.8.8.8" is not set
     And Nameserver "11.12.13.14" is set


    @rhbz1348901
    @rhelver+8.4
    @ver+=1.4.0
    @libreswan @ikev2
    @dns_systemd_resolved
    @libreswan_dns
    Scenario: nmcli - libreswan - dns
    Given Nameserver "11.12.13.14" is set in "20" seconds
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
     And Nameserver "8.8.8.8" is set
     And Nameserver "11.12.13.14" is not set
    * Delete connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds
    Then Nameserver "8.8.8.8" is not set
     And Nameserver "11.12.13.14" is set


    @rhbz1264552
    @libreswan_provides_and_obsoletes
    Scenario: nmcli - libreswan - provides and obsoletes
    Then "NetworkManager-libreswan" is visible with command "rpm -q --qf '[%{provides}\n]' NetworkManager-libreswan"
     And "NetworkManager-openswan" is visible with command "rpm -q --qf '[%{provides}\n]' NetworkManager-libreswan"
     And "NetworkManager-openswan" is visible with command "rpm -q --qf '[%{obsoletes}\n]' NetworkManager-libreswan"


    #@libreswan
    #@ethernet
    #@libreswan_start_on_boot
    #Scenario: nmcli - libreswan - start on boot
    # * Add "libreswan" VPN connection named "libreswan" for device "\*"
    # * Execute "nmcli con modify eno1 connection.autoconnect no"
    # * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    # * Reboot
    # * "libreswan" is visible with command "nmcli con show -a" in "10" seconds
    # Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    # Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    # Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    # Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    # Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    # Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    # Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"
    # Then Ping "10.16.40.254"


    #this is somehow broken in 7.2 in libreswan not in NM
    @ver+=1.0.8 @rhelver+=8
    @libreswan @ikev2
    @libreswan_start_as_secondary
    Scenario: nmcli - libreswan - start as secondary
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Execute "sleep 2; nmcli con modify lib1 connection.secondaries libreswan; sleep 3"
    * Bring "down" connection "lib1"
    * Execute "ip link set dev libreswan1 up"
    * Bring "up" connection "lib1"
    Then "libreswan" is visible with command "nmcli con show -a" in "60" seconds
    Then "lib1" is visible with command "nmcli con show -a" in "60" seconds
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @rhbz1060460
    @ver+=1.14.0 @rhelver+=8
    @vpn
    @vpn_keep_username_from_data
    Scenario: nmcli - vpn - keep username from vpn.data
    * Add "vpn" connection named "vpn" for device "\*" with options "autoconnect no vpn-type libreswan"
    * Open editor for connection "vpn"
    * Submit "set vpn.service-type org.freedesktop.NetworkManager.libreswan" in editor
    * Submit "set vpn.data right = vpn-test.com, xauthpasswordinputmodes = save, xauthpassword-flags = 1, esp = aes-sha1;modp2048, leftxauthusername = desktopqe, pskinputmodes = save, ike = aes-sha1;modp2048, pskvalue-flags = 1, leftid = desktopqe" in editor
    * Save in editor
    * Submit "set vpn.user-name incorrectuser"
    * Save in editor
    * Quit editor
    Then "leftxauthusername=desktopqe" is visible with command "cat /etc/NetworkManager/system-connections/vpn.nmconnection" in "5" seconds
    Then "user-name=incorrectuser" is visible with command "cat /etc/NetworkManager/system-connections/vpn.nmconnection"


    @rhbz1060460
    @ver+=1.14.1
    @rhelver-=7 @rhel_pkg
    @vpn
    @vpn_keep_username_from_data
    Scenario: nmcli - vpn - keep username from vpn.data
    * Add "vpn" connection named "vpn" for device "\*" with options "autoconnect no vpn-type libreswan"
    * Open editor for connection "vpn"
    * Submit "set vpn.service-type org.freedesktop.NetworkManager.libreswan" in editor
    * Submit "set vpn.data right = vpn-test.com, xauthpasswordinputmodes = save, xauthpassword-flags = 1, esp = aes-sha1;modp2048, leftxauthusername = desktopqe, pskinputmodes = save, ike = aes-sha1;modp2048, pskvalue-flags = 1, leftid = desktopqe" in editor
    * Save in editor
    * Submit "set vpn.user-name incorrectuser"
    * Save in editor
    * Quit editor
    Then "leftxauthusername=desktopqe" is visible with command "cat /etc/NetworkManager/system-connections/vpn" in "5" seconds
    Then "user-name=incorrectuser" is visible with command "cat /etc/NetworkManager/system-connections/vpn"


    @rhbz1337300
    @ver+=1.3.0
    @vpn
    @libreswan_autocompletion
    Scenario: nmcli - libreswan - autocompletion
    * "file[^\n]*type" is visible with tab after "nmcli con import "
    Then "vpn.swan" is visible with tab after "nmcli con import file contrib/vpn/"
     And "vpn.swan" is visible with tab after "nmcli con import type libreswan file contrib/vpn/"
     And "type" is visible with tab after "nmcli con import file contrib/vpn/vpn.swan3 "
     And "libreswan|openswan|openconnect|strongswan" is visible with tab after "nmcli con import file contrib/vpn/vpn.swan type "


    @rhbz1633174
    @ver+=1.14.0 @rhelver+=8 @rhelver-=8 @fedoraver-=31
    @libreswan
    @libreswan_reimport
    Scenario: nmcli - libreswan - reimport exported connection
    * Add "vpn" connection named "libreswan" for device "\*" with options "autoconnect no vpn-type libreswan"
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ask" for gateway "11.12.13.14" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd" and secret "ipsecret"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    # options in vpn.data may be in arbitrary order, sort them so it is comparable
    * Note the output of "nmcli -t -f vpn.data connection show libreswan | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn1"
    * Execute "nmcli connection export libreswan > /tmp/vpn.swan"
    * Execute "sed -i 's/\"//g' /tmp/vpn.swan"
    * Bring "down" connection "libreswan"
    * Delete connection "libreswan"
    * Execute "nmcli con import file /tmp/vpn.swan type libreswan"
    # add required options, which are not exported
    * Modify connection "libreswan" changing options "+vpn.data pskinputmodes=ask,xauthpasswordinputmodes=ask,pskvalue-flags=2,xauthpassword-flags=2,leftxauthusername=budulinek"
    * Note the output of "nmcli -t -f vpn.data connection show libreswan | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn2"
    When Check noted values "vpn1" and "vpn2" are the same
    * Connect to vpn "libreswan" with password "passwd" and secret "ipsecret"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"


    @rhbz1633174
    @ver+=1.14.0 @rhelver+=8
    @libreswan @ikev2
    @libreswan_reimport_ikev2
    Scenario: nmcli - libreswan - reimport exported IKEv2 connection
    * Add "vpn" connection named "libreswan" for device "\*" with options "autoconnect no vpn-type libreswan"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    # options in vpn.data may be in arbitrary order, sort them so it is comparable
    * Note the output of "nmcli -t -f vpn.data connection show libreswan | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn1"
    * Execute "nmcli connection export libreswan > /tmp/vpn.swan"
    * Execute "sed -i 's/\"//g' /tmp/vpn.swan"
    * Bring "down" connection "libreswan"
    * Delete connection "libreswan"
    * Execute "nmcli con import file /tmp/vpn.swan type libreswan"
    # add required options, which are not exported
    * Note the output of "nmcli -t -f vpn.data connection show libreswan | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn2"
    When Check noted values "vpn1" and "vpn2" are the same
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"


    @rhbz1557035
    @ver+=1.14.0 @rhelver+=8
    @vpn
    @libreswan_configurable_options_reimport
    Scenario: nmcli - libreswan - check libreswan options in vpn.data
    * Add "vpn" connection named "vpn" for device "\*" with options
          """
          autoconnect no
          vpn-type libreswan
          vpn.data 'right=1.2.3.4, rightid=server, rightrsasigkey=server-key, left=1.2.3.5, leftid=client, leftrsasigkey=client-key, leftcert=client-cert, ike=aes256-sha1;modp1536, esp=aes256-sha1, ikelifetime=10m, salifetime=1h, vendor=Cisco, rightsubnet=1.2.3.0/24, ikev2=yes, narrowing=yes, rekey=no, fragmentation=no'
          """
    * Note the output of "nmcli -t -f vpn.data connection show vpn | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn1"
    * Execute "nmcli connection export vpn > /tmp/vpn.swan"
    * Execute "sed -i 's/\"//g' /tmp/vpn.swan"
    * Delete connection "vpn"
    * Execute "nmcli con import file /tmp/vpn.swan type libreswan"
    * Note the output of "nmcli -t -f vpn.data connection show vpn | sed -e 's/vpn.data:\s*//' | sed -e 's/\s*,\s*/\n/g' | sort" as value "vpn2"
    Then Check noted values "vpn1" and "vpn2" are the same


    @RHEL-33372
    @RHEL-33370
    @RHEL-28898
    @rhelver+=9.2
    @libreswan_update_rightcert
    @libreswan @ikev2
    @libreswan_ikev2_right_cert
    Scenario: nmcli - libreswan - connect in ike2
    # Import the server cert into local db
    * Execute "pk12util -W "" -i contrib/libreswan/server/libreswan_server.p12 -d sql:/var/lib/ipsec/nss/"
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, rightcert=LibreswanServer, right=11.12.13.14'"
    * Bring "up" connection "libreswan"
    Then "11.12.13.0/24 [^\n]*dev libreswan1" is visible with command "ip route"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    #Then "VPN.BANNER:[^\n]*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS[^\n]*11.12.13.15/24" is visible with command "nmcli d show libreswan1"
    Then "VPN.GATEWAY:[^\n]*11.12.13.14" is visible with command "nmcli c show libreswan"


    @libreswan_ikev2_ipv4_leftcert
    Scenario: libreswan - ikev2 - ipv4 - certs
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikelifetime = 24h, ikev2 = insist, left = 192.0.2.251, leftcert = hosta.example.org, leftid = %fromcert, right = 192.0.2.152, rightid = hostb.example.org, salifetime = 24h'
      """
    * Bring "up" connection "libreswan"
    Then "203.0.113.2/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli d show hosta_nic"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.152" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.251 dst 192.0.2.152" is visible with command "ip xfrm state"


    @fedoraver+=40
    @libreswan_ikev2_ipv4_psk
    Scenario: libreswan - ikev2 - ipv4 - psk
    * Prepare nmstate libreswan environment
    When "rundir" is visible with command "ps aux|grep pluto |grep hostb" in "15" seconds
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'authby = secret, ikev2 = insist, left = 192.0.2.250, leftid = hosta-psk.example.org, right = 192.0.2.153, rightid = hostb-psk.example.org'
      vpn.secrets 'pskvalue = JjyNzrnHTnMqzloKaMuq2uCfJvSSUqTYdAXqD2U2OCFyVIJUUEHmXihBbPrUcmik'
      """
    * Bring "up" connection "libreswan"
    Then "203.0.113.[^\n]*/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli d show hosta_nic"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.153" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.250 dst 192.0.2.153" is visible with command "ip xfrm state"


    @libreswan_ikev2_ipv4_rsa
    Scenario: libreswan - ikev2 - ipv4 - rsa
    * Prepare nmstate libreswan environment
    * Note the output of "echo $HOSTA_RSA_KEY" as value "hosta_rsa"
    * Note the output of "echo $HOSTB_RSA_KEY" as value "hostb_rsa"
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikev2 = insist, left = 192.0.2.249, leftid = hosta-rsa.example.org, leftrsasigkey = <noted:hosta_rsa>, right = 192.0.2.154, rightid = hostb-rsa.example.org, rightrsasigkey = <noted:hostb_rsa>'
      """
    * Bring "up" connection "libreswan"
    Then "203.0.113.[^\n]*/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli d show hosta_nic"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.154" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.249 dst 192.0.2.154" is visible with command "ip xfrm state"


    @libreswan_ikev2_ipv4_leftcert_var2
    Scenario: libreswan - ikev2 - ipv4 - certs
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikev2 = insist, left = 192.0.2.251, leftcert = hosta.example.org, leftid = %fromcert, right = 192.0.2.152, rightid = %fromcert'
      """
    * Bring "up" connection "libreswan"
    Then "203.0.113.2/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli d show hosta_nic"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.152" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.251 dst 192.0.2.152" is visible with command "ip xfrm state"


    @fedoraver+=40
    @libreswan_ikev2_interface
    Scenario: libreswan - ikev2 - ipv4 - interface
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'authby = secret, ikev2 = insist, ipsec-interface = 9, left = 192.0.2.250, leftid = hosta-psk.example.org, right = 192.0.2.153, rightid = hostb-psk.example.org'
      vpn.secrets 'pskvalue = JjyNzrnHTnMqzloKaMuq2uCfJvSSUqTYdAXqD2U2OCFyVIJUUEHmXihBbPrUcmik'
      """
    * Execute "nmcli con show libreswan --show-secrets"
    * Bring "up" connection "libreswan"
    Then "203.0.113.[^\n]*/32" is visible with command "ip a s ipsec9"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli d show ipsec9"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.153" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.250 dst 192.0.2.153" is visible with command "ip xfrm state"


    @fedoraver+=40
    @libreswan_ikev2_dpd_interface
    Scenario: libreswan - ikev2 - dpd
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'authby = secret, dpdaction = restart, dpddelay = 1, dpdtimeout = 60, ikev2 = insist, ipsec-interface = 10, left = 192.0.2.250, leftid = hosta-psk.example.org, right = 192.0.2.153, rightid = hostb-psk.example.org'
      vpn.secrets 'pskvalue = JjyNzrnHTnMqzloKaMuq2uCfJvSSUqTYdAXqD2U2OCFyVIJUUEHmXihBbPrUcmik'
      """
    * Wait for "1" seconds
    * Bring "up" connection "libreswan"
    Then "203.0.113.[^\n]*/32" is visible with command "ip a s ipsec10"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.[^\n]*/32" is visible with command "nmcli d show ipsec10"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.153" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.250 dst 192.0.2.153" is visible with command "ip xfrm state"


    @fedoraver+=41
    @ver+=1.46
    @ver/rhel/9/2+=1.42.2.24
    @libreswan_ikev2_ipv4_p2p_cert
    Scenario: libreswan - ikev2 - p2p
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikev2 = insist, left = 192.0.2.248, leftcert = hosta.example.org, leftid = hosta.example.org, leftmodecfgclient = no, right = 192.0.2.155, rightid = hostb.example.org, rightsubnet = 192.0.2.155/32'
      """
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.155" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.248 dst 192.0.2.155" is visible with command "ip xfrm state"


    @fedoraver+=41
    @rhelver-10
    @ver+=1.46
    @ver/rhel/9/2+=1.42.2.24
    @libreswan_ikev2_ipv4_leftsubnet
    Scenario: libreswan - ikev2 - leftsubnet
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikev2 = insist, left = 192.0.2.246, leftcert = hosta.example.org, leftid = hosta.example.org, leftmodecfgclient = no, leftsubnet = 192.0.4.0/24, right = 192.0.2.157, rightid = hostb.example.org, rightsubnet = 192.0.3.0/24'
      """
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.157" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.246 dst 192.0.2.157" is visible with command "ip xfrm state"


    @xfail
    @RHEL-70164
    @fedoraver+=41
    @rhelver+=10
    # Delete this once 70164 is fixed together with rhelver-10 in test above
    @libreswan_ikev2_ipv4_leftsubnet
    Scenario: libreswan - ikev2 - leftsubnet
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikev2 = insist, left = 192.0.2.246, leftcert = hosta.example.org, leftid = hosta.example.org, leftmodecfgclient = no, leftsubnet = 192.0.4.0/24, right = 192.0.2.157, rightid = hostb.example.org, rightsubnet = 192.0.3.0/24'
      """
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.157" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.246 dst 192.0.2.157" is visible with command "ip xfrm state"


    @fedoraver+=41
    @ver+=1.46
    @ver/rhel/9/4+=1.46.0.10
    @libreswan_ikev2_ipv6_p2p_cert
    Scenario: libreswan - ikev2 - ipv6 - p2p
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'clientaddrfamily = ipv6, hostaddrfamily = ipv6, ikev2 = insist, left = 2001:db8:f::a, leftcert = hosta.example.org, leftid = hosta.example.org, leftmodecfgclient = no, right = 2001:db8:f::b, rightid = hostb.example.org, rightsubnet = 2001:db8:f::b/128'
      """
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP6.ADDRESS[^\n]*2001:db8:f::a/64" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*2001:db8:f::b" is visible with command "nmcli c show libreswan"
    Then "src 2001:db8:f::a dst 2001:db8:f::b" is visible with command "ip xfrm state"


    @fedoraver+=41
    @ver+=1.46
    @ver/rhel/9/4+=1.46.0.10
    @libreswan_ikev2_ipv6_p2p_client_server
    Scenario: libreswan - ikev2 - ipv6 - client - server
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'clientaddrfamily = ipv6, hostaddrfamily = ipv6, ikev2 = insist, left = 2001:db8:f::a, leftcert = hosta.example.org, leftid = hosta.example.org, leftmodecfgclient = no, right = 2001:db8:f::b, rightid = hostb.example.org, rightsubnet = 2001:db8:f::b/128'
      """
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP6.ADDRESS[^\n]*2001:db8:f::a/64" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*2001:db8:f::b" is visible with command "nmcli c show libreswan"
    Then "src 2001:db8:f::a dst 2001:db8:f::b" is visible with command "ip xfrm state"


    @RHEL-58040
    @fedoraver+=43
    @rhelver+=9
    @libreswan_ikev2_require_id_on_cert
    Scenario: libreswan - ikev2 - ipv4 - test require ID on certs
    * Ensure that version of "NetworkManager-libreswan" package is at least
      | version       | distro  |
      | 1.2.22-5.el9  | rhel9   |
      | 1.2.22-2.el9  | rhel9.6 |
      | 1.2.22-2.el9  | c9s     |
      | 1.2.22-3.el10 | rhel10  |
    * Prepare nmstate libreswan environment
    * Add "vpn" connection named "libreswan" for device "\*" with options
      """
      autoconnect no
      vpn-type libreswan
      vpn.data 'ikelifetime = 24h, ikev2 = insist, left = 192.0.2.251, leftcert = hosta.example.org, leftid = %fromcert, right = 192.0.2.152, rightid = hostb.example.org, salifetime = 24h, require-id-on-certificate = yes'
      """
    * Bring "up" connection "libreswan"
    Then "203.0.113.2/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS[^\n]*203.0.113.2/32" is visible with command "nmcli d show hosta_nic"
    Then "IP4.ADDRESS[^\n]*192.0.2.251/24" is visible with command "nmcli d show hosta_nic"
    Then "VPN.GATEWAY:[^\n]*192.0.2.152" is visible with command "nmcli c show libreswan"
    Then "src 192.0.2.251 dst 192.0.2.152" is visible with command "ip xfrm state"
    # Re-up doesn't work with VPN
    * Bring "down" connection "libreswan"
    * Modify connection "libreswan" changing options "+vpn.data 'rightid = hostc.example.com'"
    Then Fail up connection "libreswan" in "10" seconds
    # Con might be down or up, if down already, down fails
    * Execute "nmcli con down id libreswan 2>&1 || true"
    * Modify connection "libreswan" changing options "+vpn.data 'require-id-on-certificate = no'"
    * Bring "up" connection "libreswan"
    Then "203.0.113.2/32" is visible with command "ip a s hosta_nic"
    Then "VPN.VPN-STATE:[^\n]*VPN connected" is visible with command "nmcli c show libreswan"


    @libreswan @ikev2
    @libreswan_wrong_data
    Scenario: libreswan - malformed data in keyfile
    Given Ensure that version of "NetworkManager-libreswan" package is at least
      | version         | distro   |
      | 1.2.4-4.el7_7   | rhel7.7  |
      | 1.2.4-4.el7_9   | rhel7.9  |
      | 1.2.10-6.el8_2  | rhel8.2  |
      | 1.2.10-6.el8_4  | rhel8.4  |
      | 1.2.10-6.el8_6  | rhel8.6  |
      | 1.2.10-6.el8_8  | rhel8.8  |
      | 1.2.10-7.el8_10 | rhel8.10 |
      | 1.2.14-3.el9_0  | rhel9.0  |
      | 1.2.14-6.el9_2  | rhel9.2  |
      | 1.2.18-6.el9_4  | rhel9.4  |
      | 1.2.22-4.el9_5  | rhel9.5  |
      | 1.2.22-4.el9    | rhel9.6  |
    * Cleanup connection "libreswan"
    * Create keyfile "/etc/NetworkManager/system-connections/libreswan.nmconnection"
"""
[connection]
id=libreswan
type=vpn
autoconnect=false
[vpn]
ikev2=insist
leftcert=LibreswanClient
# Malformed leftid entry
leftid=%fromcert\n ikev2=insist\n leftcert=LibreswanClient\n leftrsasigkey=%cert\n rightrsasigkey=%cert\n left=%defaultroute\n leftmodecfgclient=yes\n right=11.12.13.14\n leftupdown=/bin/true\nconn ign
right=11.12.13.14
service-type=org.freedesktop.NetworkManager.libreswan
[ipv4]
method=auto
[ipv6]
addr-gen-mode=default
method=auto
[proxy]
"""
    * Reload connections
    * Start following journal
    * Bring "up" connection "libreswan" ignoring error
    * Commentary
        """
        Here we should fail immediatelly and no connecting should happen
        In some cases we saw those values propagated further and timeout 60s.
        """
    When "libreswan " is not visible with command "nmcli  connection show -a" in "2" seconds
    Then "Invalid character|name owner .* disappeared" is visible in journal in "5" seconds


    @libreswan @ikev2
    @libreswan_wrong_data_var2
    Scenario: libreswan - unsupported key in data
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'foo=bar, ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Start following journal
    * Bring "up" connection "libreswan" ignoring error
    * Commentary
        """
        Here we should fail immediatelly and no connecting should happen
        In some cases we saw those values propagated further and timeout 60s.
        We can see several errors:
        RHEL8.6+/9 has Invaldi character/name owner disappeared
        RHEL8.4- throws property foo invalid.
        """
    Then "libreswan " is not visible with command "nmcli  connection show -a" in "2" seconds
    Then "Invalid character|name owner .* disappeared|'property 'foo' invalid or not supported" is visible in journal in "5" seconds


    @RHEL-70160 @RHEL-69901
    @ver+=1.51.6
    @ver/rhel/9/5+=1.48.10.5
    @libreswan @ikev2
    @libreswan_add_routing_rules
    Scenario: nmcli - libreswan - add routing rules
    * Add "libreswan" VPN connection named "libreswan" for device "\*"
    * Modify connection "libreswan" changing options "vpn.data 'ikev2=insist, leftcert=LibreswanClient, leftid=%fromcert, right=11.12.13.14'"
    * Execute "nmcli con modify libreswan ipv4.route-table 127"
    * Execute "nmcli con modify libreswan ipv6.route-table 200"
    * Execute "nmcli con modify libreswan ipv4.routing-rules 'priority 16383 from all table 127'"
    * Execute "nmcli con modify libreswan ipv6.routing-rules 'priority 16600 from all table 200'"
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" for full "130" seconds
    And "default" is visible with command "ip r show table 127 |grep ^default | grep -v eth0"
    Then "16383:\s+from all lookup 127 proto static" is visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is visible with command "ip -6 rule"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.29.100.2/32" is visible with command "nmcli d show libreswan1"
    Then "IP4.ADDRESS.*11.12.13.*/24" is visible with command "nmcli d show libreswan1"
    Then "IP4.GATEWAY:.*11.12.13.14" is visible with command "nmcli d show libreswan1"
    * Bring "down" connection "libreswan"
    Then "16383:\s+from all lookup 127 proto static" is not visible with command "ip rule"
    Then "16600:\s+from all lookup 200 proto static" is not visible with command "ip -6 rule"
    And "default" is not visible with command "ip r show table 127 |grep ^default | grep -v eth0"
