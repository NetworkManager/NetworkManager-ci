 Feature: nmcli: libreswan

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+/-=1.4.1)
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @libreswan
    @libreswan_add_profile
    Scenario: nmcli - libreswan - add and connect a connection
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @rhbz1250723
    @libreswan
    @libreswan_connection_renewal
    Scenario: NM - libreswan - main connection lifetime renewal
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" for full "130" seconds
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @rhbz1292912
    @ver+=1.4.0
    @libreswan_main
    Scenario: nmcli - libreswan - connect in Main mode
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "Main" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @rhbz1141947
    @libreswan
    @libreswan_activate_asking_for_password
    Scenario: nmcli - vpn - activate asking for password
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd"
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @rhbz1349740
    @libreswan
    @libreswan_activate_asking_for_password_with_delay
    Scenario: nmcli - vpn - activate asking for password with delay
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd" with timeout "40"
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @rhbz1141947
    @libreswan
    @libreswan_activate_asking_for_password_and_secret
    Scenario: nmcli - vpn - activate asking for password and secret
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "ask" and group "yolo" with secret "ask" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Connect to vpn "libreswan" with password "passwd" and secret "ipsecret"
    * Execute "nmcli --show-secrets con show libreswan > /tmp/libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan" in "120" seconds
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"

    @libreswan
    @libreswan_terminate
    Scenario: nmcli - libreswan - terminate connection
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    * Bring "down" connection "libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds


    @libreswan
    @libreswan_delete_active_profile
    Scenario: nmcli - libreswan - delete active profile
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    * Delete connection "libreswan"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds
    Then "172.31.80.0/24 .*dev racoon1" is not visible with command "ip route" in "10" seconds


    @rhbz1348901
    @ver+=1.4.0
    @libreswan
    @libreswan_dns
    Scenario: nmcli - libreswan - dns
    Given "nameserver 172.31.70.1\s+nameserver 10" is visible with command "cat /etc/resolv.conf"
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Bring "up" connection "libreswan"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
     And "nameserver 8.8.8.8\s+nameserver 172.31.70.1\s+nameserver 10" is visible with command "cat /etc/resolv.conf"
    * Delete connection "libreswan"
    When "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show libreswan" in "10" seconds
    Then "nameserver 8.8.8.8\s+nameserver 172.31.70.1\s+nameserver 10" is not visible with command "cat /etc/resolv.conf"
     And "nameserver 172.31.70.1\s+nameserver 10" is visible with command "cat /etc/resolv.conf"


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
    # * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    # * Execute "nmcli con modify eno1 connection.autoconnect no"
    # * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    # * Reboot
    # * "libreswan" is visible with command "nmcli con show -a" in "10" seconds
    # Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    # Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    # Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    # Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    # Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    # Then "IP4.ADDRESS.*172.31.70.2/24" is visible with command "nmcli d show racoon1"
    # Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"
    # Then Ping "10.16.40.254"


    #this is somehow broken in 7.2 in libreswan not in NM
    @ver+=1.0.8
    @libreswan
    @libreswan_start_as_secondary
    Scenario: nmcli - libreswan - start as secondary
    * Add a connection named "libreswan" for device "\*" to "libreswan" VPN
    * Use user "budulinek" with password "passwd" and group "yolo" with secret "ipsecret" for gateway "172.31.70.1" on Libreswan connection "libreswan"
    * Execute "sleep 2; nmcli con modify rac1 connection.secondaries libreswan; sleep 1"
    #* Bring "down" connection "rac1"
    #* Execute "ip link set dev racoon1 up"
    * Bring "up" connection "rac1"
    Then "libreswan" is visible with command "nmcli con show -a" in "60" seconds
    Then "rac1" is visible with command "nmcli con show -a" in "60" seconds
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"


    @vpn_describe
    Scenario: nmcli - vpn - describe
    * Open editor for a type "vpn"
    When Check "<<< vpn >>>|=== \[service-type\] ===\s+\[NM property description\]\s+D-Bus service name of the VPN plugin that this setting uses to connect to its network.  i.e. org.freedesktop.NetworkManager.vpnc for the vpnc plugin.\s+=== \[user-name\] ===\s+\[NM property description\]\s+If the VPN connection requires a user name for authentication, that name should be provided here.  If the connection is available to more than one user, and the VPN requires each user to supply a different name, then leave this property empty.  If this property is empty, NetworkManager will automatically supply the username of the user which requested the VPN connection.\s+=== \[persistent\] ===\s+\[NM property description\]\s+If the VPN service supports persistence, and this property is TRUE, the VPN will attempt to stay connected across link changes and outages, until explicitly disconnected.\s+=== \[data\] ===\s+\[NM property description\]\s+Dictionary of key/value pairs of VPN plugin specific data.  Both keys and values must be strings.\s+=== \[secrets\] ===\s+\[NM property description\]\s+Dictionary of key\/value pairs of VPN plugin specific secrets like passwords or private keys.\s+Both keys and values must be strings." are present in describe output for object "vpn"


    @rhbz1060460
    @vpn
    @vpn_keep_username_from_data
    Scenario: nmcli - vpn - keep username from vpn.data
    * Add a new connection of type "vpn" and options "ifname \* con-name vpn autoconnect no vpn-type libreswan"
    * Open editor for connection "vpn"
    * Submit "set vpn.service-type org.freedesktop.NetworkManager.libreswan" in editor
    * Submit "set vpn.data right = vpn-test.com, xauthpasswordinputmodes = save, xauthpassword-flags = 1, esp = aes-sha1;modp1024, leftxauthusername = desktopqe, pskinputmodes = save, ike = aes-sha1;modp1024, pskvalue-flags = 1, leftid = desktopqe" in editor
    * Save in editor
    * Submit "set vpn.user-name incorrectuser"
    * Save in editor
    * Quit editor
    Then "leftxauthusername=desktopqe" is visible with command "cat /etc/NetworkManager/system-connections/vpn"
    Then "user-name=incorrectuser" is visible with command "cat /etc/NetworkManager/system-connections/vpn"


    @rhbz1034105
    @ver+=1.3.0
    @vpn
    @libreswan_import
    Scenario: nmcli - libreswan - import
    * Execute "nmcli connection import file tmp/vpn.swan type libreswan"
    Then "leftid = VPN-standard" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "right = vpn-test.com" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "ike = aes-sha1;modp1024" is visible with command "nmcli connection show vpn |grep vpn.data"
     And "leftxauthusername = test_user" is visible with command "nmcli connection show vpn |grep vpn.data"


    @rhbz1034105
    @ver+=1.3.0
    @vpn
    @libreswan_export
    Scenario: nmcli - libreswan - export
    * Execute "nmcli connection import file tmp/vpn.swan type libreswan"
    * Execute "nmcli connection export vpn > /tmp/vpn.swan"
    Then "Files /tmp/vpn.swan and tmp/vpn.swan are identical" is visible with command "diff -s /tmp/vpn.swan tmp/vpn.swan"


    @rhbz1337300
    @ver+=1.3.0
    @vpn
    @libreswan_autocompletion
    Scenario: nmcli - libreswan - autocompletion
     * "file.*type" is visible with tab after "nmcli con import "
     Then "vpn.swan" is visible with tab after "nmcli con import file tmp/"
      And "vpn.swan" is visible with tab after "nmcli con import type libreswan file tmp/"
      And "type" is visible with tab after "nmcli con import file tmp/vpn.swan "
      And "libreswan|openswan|openconnect|strongswan" is visible with tab after "nmcli con import file tmp/vpn.swan type "
