 Feature: nmcli: vpn

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
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
    Then "172.31.80.0/24 .*dev racoon1" is visible with command "ip route"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show libreswan"
    Then "VPN.BANNER:.*BUG_REPORT_URL" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli c show libreswan"
    Then "IP4.ADDRESS.*172.31.60.2/32" is visible with command "nmcli d show racoon1"
    Then "IP4.ADDRESS.*172.31.70.*/24" is visible with command "nmcli d show racoon1"
    Then "IP4.GATEWAY:.*172.31.70.1" is visible with command "nmcli d show racoon1"
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
    When Check "<<< vpn >>>|=== \[service-type\] ===\s+\[NM property description\]\s+D-Bus service name of the VPN plugin that this setting uses to connect to its network.  i.e. org.freedesktop.NetworkManager.vpnc for the vpnc plugin.\s+=== \[user-name\] ===\s+\[NM property description\]\s+If the VPN connection requires a user name for authentication, that name should be provided here.  If the connection is available to more than one user, and the VPN requires each user to supply a different name, then leave this property empty.  If this property is empty, NetworkManager will automatically supply the username of the user which requested the VPN connection.\s+=== \[persistent\] ===\s+\[NM property description\]\s+If the VPN service supports persistence, and this property is TRUE, the VPN will attempt to stay connected across link changes and outages, until explicitly disconnected.\s+=== \[data\] ===\s+\[NM property description\]\s+Dictionary of key/value pairs of VPN plugin specific data.  Both keys and values must be strings.\s+=== \[secrets\] ===\s+\[NM property description\]\s+Dictionary of key\/value pairs of VPN plugin specific secrets like passwords or private keys.\s+Both keys and values must be strings." are present in describe output for object "vpn"


    @rhbz1060460
    @libreswan
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


    @rhbz1374526
    @ver+=1.4.0
    @pptp
    @vpn_list_args
    Scenario: nmcli - vpn - list args
    Then "libreswan|vpnc|openvpn|org.freedesktop.NetworkManager.libreswan" is visible with command "nmcli --complete-args connection add type vpn vpn-type ''"
