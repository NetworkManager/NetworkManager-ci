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


    # https://gitlab.gnome.org/GNOME/NetworkManager-libreswan/-/issues/11
    # https://issues.redhat.com/browse/RHEL-14288
    @libreswan
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
    @rhelver+=8 @ver+=1.4.0
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


    @rhbz1034105
    @ver+=1.3.0 @rhelver-=8 @fedoraver-=31
    @vpn
    @libreswan_import
    Scenario: nmcli - libreswan - import
    * Execute "nmcli connection import file contrib/vpn/vpn.swan3 type libreswan"
    Then "leftid = VPN-standard" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "right = vpn-test.com" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "ike = aes-sha1;modp2048" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "leftxauthusername = test_user" is visible with command "nmcli connection show vpn |grep vpn.data"


    @rhbz1034105
    @ver+=1.3.0 @rhelver+=9 @fedoraver+=32
    @vpn
    @libreswan_import
    Scenario: nmcli - libreswan - import
    * Execute "nmcli connection import file contrib/vpn/vpn.swan4 type libreswan"
    Then "leftid = VPN-standard" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "right = vpn-test.com" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "ike = aes-sha1;modp2048" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "leftusername = test_user" is visible with command "nmcli connection show vpn |grep vpn.data"


    @rhbz1034105 @rhbz1626485
    @ver+=1.3.0 @rhelver-=8 @fedoraver-=31
    @vpn
    @libreswan_export
    Scenario: nmcli - libreswan - export
    * Execute "nmcli connection import file contrib/vpn/vpn.swan3 type libreswan"
    * Execute "nmcli connection export vpn > /tmp/vpn.swan3"
    * Replace "phase2alg=" with "esp=" in file "/tmp/vpn.swan3"
    Then Check file "contrib/vpn/vpn.swan3" is contained in file "/tmp/vpn.swan3"
    * Execute "nmcli -g vpn.data conn show vpn > /tmp/vpn1.data"
    * Delete connection "vpn"
    * Execute "nmcli connection import file /tmp/vpn.swan3 type libreswan"
    * Execute "nmcli -g vpn.data conn show vpn > /tmp/vpn2.data"
    Then Check file "/tmp/vpn1.data" is identical to file "/tmp/vpn2.data"


    @rhbz1034105 @rhbz1626485
    @ver+=1.3.0 @rhelver+=9 @fedoraver+=32
    @vpn
    @libreswan_export
    Scenario: nmcli - libreswan - export
    * Execute "nmcli connection import file contrib/vpn/vpn.swan4 type libreswan"
    * Execute "nmcli connection export vpn > /tmp/vpn.swan4"
    * Replace "phase2alg=" with "esp=" in file "/tmp/vpn.swan4"
    Then Check file "contrib/vpn/vpn.swan4" is contained in file "/tmp/vpn.swan4"
    * Execute "nmcli -g vpn.data conn show vpn > /tmp/vpn1.data"
    * Delete connection "vpn"
    * Execute "nmcli connection import file /tmp/vpn.swan4 type libreswan"
    * Execute "nmcli -g vpn.data conn show vpn > /tmp/vpn2.data"
    Then Check file "/tmp/vpn1.data" is identical to file "/tmp/vpn2.data"


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
    * Note the output of "grep rightrsasigkey /tmp/hostb_ipsec_conf/ipsec.d/hostb_conn.conf |awk -F 'asigkey=' '{print $2}' | tr -d '\n'" as value "hosta_rsa"
    * Note the output of "grep leftrsasigkey /tmp/hostb_ipsec_conf/ipsec.d/hostb_conn.conf |awk -F 'asigkey=' '{print $2}'| tr -d '\n'" as value "hostb_rsa"
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

