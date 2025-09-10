Feature: nmcli - ethernet

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.25
    @rhelver+=8 @fedoraver+=32
    @skip_in_centos
    @ethernet_default_initramfs_connection
    Scenario: nmcli - ethernet - initramfs connection
    Then "ipv6.method:\s+auto" is visible with command "nmcli  con show testeth0  |grep method"
    Then "ipv4.method:\s+auto" is visible with command "nmcli  con show testeth0  |grep method"


    @ethernet_create_with_editor
    Scenario: nmcli - ethernet - create with editor
    * Cleanup connection "ethernet0"
    * Open editor for a type "ethernet"
    * Set a property named "ipv4.method" to "auto" in editor
    * Set a property named "connection.interface-name" to "eth1" in editor
    * Set a property named "connection.autoconnect" to "no" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Note the "connection.id" property from editor print output
    * Quit editor
    Then Noted value is visible with command "nmcli con show"


    @ethernet_create_default_connection
    Scenario: nmcli - ethernet - create default connection
    * Add "ethernet" connection named "ethernet" for device "eth1"
    Then "/etc/NetworkManager/system-connections/ethernet.nmconnection" is file in "5" seconds


    @ethernet_create_ifname_generic_connection
    Scenario: nmcli - ethernet - create ifname generic connection
    * Add "ethernet" connection named "ethos" for device "'*'" with options "autoconnect no"
    * Bring "up" connection "ethos"
    Then "ethernet\s+connected\s+ethos" is visible with command "nmcli device"


    @ethernet_connection_up
    Scenario: nmcli - ethernet - up
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no ipv4.may-fail no"
    * "inet 192." is not visible with command "ip addr show eth1"
    * Bring "up" connection "ethernet"
    Then "inet 192." is visible with command "ip addr show eth1"


    @ethernet_disconnect_device
    Scenario: nmcli - ethernet - disconnect device
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect yes ipv4.may-fail no"
    * Bring "up" connection "ethernet"
    * "inet 192." is visible with command "ip addr show eth1"
    * Disconnect device "eth1"
    Then "inet 192." is not visible with command "ip addr show eth1"


    @ethernet
    @ethernet_describe_all
    Scenario: nmcli - ethernet - describe all
    * Open editor for a type "ethernet"
    Then Check "port|speed|duplex|auto-negotiate|mac-address|cloned-mac-address|mac-address-blacklist|mtu|s390-subchannels|s390-nettype|s390-options" are present in describe output for object "802-3-ethernet"


    @ethernet
    @ethernet_describe_separately
    Scenario: nmcli - ethernet - describe separately
    * Open editor for a type "ethernet"
    Then Check "\[port\]" are present in describe output for object "802-3-ethernet.port"
    Then Check "\[speed\]" are present in describe output for object "802-3-ethernet.speed"
    Then Check "\[duplex\]" are present in describe output for object "802-3-ethernet.duplex"
    Then Check "\[auto-negotiate\]" are present in describe output for object "802-3-ethernet.auto-negotiate"
    Then Check "\[mac-address\]" are present in describe output for object "802-3-ethernet.mac-address"
    Then Check "\[cloned-mac-address\]" are present in describe output for object "802-3-ethernet.cloned-mac-address"
    Then Check "\[mac-address-blacklist\]" are present in describe output for object "802-3-ethernet.mac-address-blacklist"
    Then Check "\[mtu\]" are present in describe output for object "802-3-ethernet.mtu"
    Then Check "\[s390-subchannels\]" are present in describe output for object "802-3-ethernet.s390-subchannels"
    Then Check "\[s390-nettype\]" are present in describe output for object "802-3-ethernet.s390-nettype"
    Then Check "\[s390-options\]" are present in describe output for object "802-3-ethernet.s390-options"


    @rhbz1264024
    @ethernet_set_matching_mac
    Scenario: nmcli - ethernet - set matching mac adress
    * Add "ethernet" connection named "ethernet" for device "'*'" with options "autoconnect no"
    * Note the output of "nmcli -f GENERAL.HWADDR device show eth1 | awk '{print $2}'"
    * Open editor for connection "ethernet"
    * Set a property named "802-3-ethernet.mac-address" to "noted-value" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "eth1:connected:ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds
    Then "inet 192." is visible with command "ip a s eth1"


    @restart_if_needed
    @no_assumed_connection_for_veth
    Scenario: NM - ethernet - no assumed connection for veth
    * Prepare simulated test "testE" device
    * Add "ethernet" connection named "ethernet" for device "testE" with options "autoconnect no"
    * Bring "up" connection "ethernet"
    * Restart NM
    Then "testE" is not visible with command "nmcli -f NAME c" in "50" seconds


    @ethernet
    @ethernet_set_invalid_mac
    Scenario: nmcli - ethernet - set non-existent mac adress
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "802-3-ethernet.mac-address" to "00:11:22:33:44:55" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "No suitable device found for this connection" is visible with command "nmcli connection up ethernet"


    @rhbz1264024
    @ethernet_set_blacklisted_mac
    Scenario: nmcli - ethernet - set blacklisted mac adress
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Note the output of "nmcli -f GENERAL.HWADDR device show eth1 | awk '{print $2}'"
    * Open editor for connection "ethernet"
    * Set a property named "802-3-ethernet.mac-address-blacklist" to "noted-value" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "Error" is visible with command "nmcli connection up ethernet"


    @ethernet_mac_spoofing
    Scenario: nmcli - ethernet - mac spoofing
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "802-3-ethernet.cloned-mac-address" to "f0:de:aa:fb:bb:cc" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip link show eth1"


    @rhbz1413312
    @ver+=1.6.0
    @restart_if_needed
    @ethernet_mac_address_preserve
    Scenario: NM - ethernet - mac address preserve
    * Create NM config file "95-nmci-mac.conf" with content
      """
      [connection]
      ethernet.cloned-mac-address=preserve
      """
    * Reboot
    * Execute "ip link set dev eth1 address f0:11:22:33:44:55"
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Bring "up" connection "ethernet"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth1" as value "new_eth1"
    Then "ether f0:11:22:33:44:55" is visible with command "ip a s eth1"


    @rhbz1413312
    @ver+=1.6.0
    @restart_if_needed
    @ethernet_mac_address_permanent
    Scenario: NM - ethernet - mac address permanent
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth1" as value "orig_eth1"
    * Create NM config file "95-nmci-mac.conf" with content
      """
      [connection]
      ethernet.cloned-mac-address=permanent
      """
    * Reboot
    * Execute "ip link set dev eth1 address f0:11:22:33:44:55"
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Bring "up" connection "ethernet"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth1" as value "new_eth1"
    Then Check noted values "orig_eth1" and "new_eth1" are the same


    @rhbz1413312
    @ver+=1.6.0
    @rhelver-=7 @rhel_pkg
    @ethernet_mac_address_rhel7_default
    Scenario: NM - ethernet - mac address rhel7 dafault
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth1" as value "orig_eth1"
    * Execute "ip link set dev eth1 address f0:11:22:33:44:55"
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Bring "up" connection "ethernet"
    * Note the output of "nmcli -t --mode tabular --fields GENERAL.HWADDR device show eth1" as value "new_eth1"
    Then Check noted values "orig_eth1" and "new_eth1" are the same


    @rhbz1487477
    @ver+=1.11.4
    @ethernet_duplex_speed_auto_negotiation
    Scenario: nmcli - ethernet - duplex speed and auto-negotiation
    * Add "ethernet" connection named "ethernet" for device "eth1"
    * Modify connection "ethernet" changing options "802-3-ethernet.duplex full 802-3-ethernet.speed 10"
    When Check keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection" has options
      """
      ethernet.duplex=full
      ethernet.speed=10
      """
    * Modify connection "ethernet" changing options "802-3-ethernet.auto-negotiate yes"
    When Check keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection" has options
      """
      ethernet.auto-negotiate=true
      ethernet.duplex=full
      ethernet.speed=10
      """
    * Modify connection "ethernet" changing options "802-3-ethernet.auto-negotiate no 802-3-ethernet.speed 0"
    Then "auto-negotiate=true" is not visible with command "cat /etc/NetworkManager/system-connections/ethernet.nmconnection"
    Then "speed=10" is not visible with command "cat /etc/NetworkManager/system-connections/ethernet.nmconnection"


    @rhbz1775136
    @ver+=1.20.0
    @mtu
    @ethernet_set_mtu
    Scenario: nmcli - ethernet - set mtu
    * Add "ethernet" connection named "ethernet" for device "eth1" with options
          """
          ipv6.method disable
          802-3-ethernet.mtu 666
          """
    * Bring "up" connection "ethernet"
    When Check keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection" has options
      """
      ethernet.mtu=666
      """
    When "666" is visible with command "ip a s eth1"
    * Modify connection "ethernet" changing options "802-3-ethernet.mtu 9000"
    * Bring "up" connection "ethernet"
    When Check keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection" has options
      """
      ethernet.mtu=9000
      """
    When "9000" is visible with command "ip a s eth1"


    @mtu
    @nmcli_set_mtu_lower_limit
    Scenario: nmcli - ethernet - set lower limit mtu
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "802-3-ethernet.mtu" to "666" in editor
    * Save in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "1280" is visible with command "ip a s eth1"


    @ethernet_set_static_configuration
    Scenario: nmcli - ethernet - static IPv4 configuration
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.10/24" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "inet 192.168.1.10/24" is visible with command "ip addr show eth1"


    @ethernet_set_static_ipv6_configuration
    Scenario: nmcli - ethernet - static IPv6 configuration
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "ipv6.method" to "manual" in editor
    * Set a property named "ipv6.addresses" to "2607:f0d0:1002:51::4/64" in editor
    * Set a property named "ipv4.method" to "disabled" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip addr show eth1"


    @ethernet_set_both_ipv4_6_configuration
    Scenario: nmcli - ethernet - static IPv4 and IPv6 combined configuration
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "ipv6.method" to "manual" in editor
    * Set a property named "ipv6.addresses" to "2607:f0d0:1002:51::4/64" in editor
    * Set a property named "ipv4.method" to "manual" in editor
    * Set a property named "ipv4.addresses" to "192.168.1.10/24" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "inet 192.168.1.10/24" is visible with command "ip addr show eth1"
    Then "inet6 2607:f0d0:1002:51::4/64" is visible with command "ip addr show eth1"


    @nmcli_ethernet_no_ip
    Scenario: nmcli - ethernet - no ip
    * Add "ethernet" connection named "ethernet" for device "eth1" with options "autoconnect no"
    * Open editor for connection "ethernet"
    * Set a property named "ipv6.method" to "ignore" in editor
    * Set a property named "ipv4.method" to "disabled" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring "up" connection "ethernet"
    Then "eth1\s+ethernet\s+connected" is visible with command "nmcli device"


    @rhbz1141417
    @restart_if_needed
    @nmcli_ethernet_wol_default
    Scenario: nmcli - ethernet - wake-on-lan default
    * Stop NM
    * Note the output of "ethtool sriov_device |grep Wake-on |grep Supports | awk '{print $3}'" as value "wol_supports"
    * Note the output of "ethtool sriov_device |grep Wake-on |grep -v Supports | awk '{print $2}'" as value "wol_orig"
    * Restart NM
    * Add "ethernet" connection named "ethernet" for device "sriov_device"
    # Wake-on-lan 94 equals to (phy, unicast, multicast, broadcast, magic) alias pumbg
    * Modify connection "ethernet" changing options "802-3-ethernet.wake-on-lan 92"
    * Bring "up" connection "ethernet"
    * Note the output of "ethtool sriov_device |grep Wake-on |grep -v Supports | awk '{print $2}'" as value "wol_now"
    When Check noted values "wol_now" and "wol_supports" are the same
    * Modify connection "ethernet" changing options "802-3-ethernet.wake-on-lan default"
    * Restart NM
    * Bring "up" connection "ethernet"
    * Note the output of "ethtool sriov_device |grep Wake-on |grep -v Supports | awk '{print $2}'" as value "wol_now"
    Then Check noted values "wol_now" and "wol_orig" are the same


    @rhbz1141417
    @nmcli_ethernet_wol_enable_magic
    Scenario: nmcli - ethernet - wake-on-lan magic
    * Add "ethernet" connection named "ethernet" for device "sriov_device"
    * Modify connection "ethernet" changing options "802-3-ethernet.wake-on-lan magic"
    * Bring "up" connection "ethernet"
    Then "Wake-on: g" is visible with command "ethtool sriov_device"


    @rhbz1141417
    @nmcli_ethernet_wol_disable
    Scenario: nmcli - ethernet - wake-on-lan disable
    * Add "ethernet" connection named "ethernet" for device "sriov_device"
    * Modify connection "ethernet" changing options "802-3-ethernet.wake-on-lan none"
    * Bring "up" connection "ethernet"
    Then "Wake-on: d" is visible with command "ethtool sriov_device"


    @rhbz1141417
    @nmcli_ethernet_wol_from_file
    Scenario: nmcli - ethernet - wake-on-lan from file
    * Add "ethernet" connection named "ethernet" for device "sriov_device"
    * Update the keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection"
      """
      [ethernet]
      wake-on-lan=64
      """
    * Reload connections
    * Bring "up" connection "ethernet"
    Then "Wake-on: g" is visible with command "ethtool sriov_device"
    Then "default|g|magic" is visible with command "nmcli con show ethernet |grep wake-on-lan"


    @rhbz1141417 @rhbz2016348
    @ver+=1.36.0
    @nmcli_ethernet_wol_from_file_to_default
    Scenario: nmcli - ethernet - wake-on-lan from file and back
    * Add "ethernet" connection named "ethernet" for device "sriov_device"
    * Note the output of "ethtool sriov_device |grep Wake-on |grep -v Supports | awk '{print $2}'" as value "wol_orig"
    * Update the keyfile "/etc/NetworkManager/system-connections/ethernet.nmconnection"
      """
      [ethernet]
      wake-on-lan=64
      """
    * Reload connections
    * Bring "up" connection "ethernet"
    Then "Wake-on: g" is visible with command "ethtool sriov_device"
    Then "magic|g|default" is visible with command "nmcli con show ethernet |grep wake-on-lan"
    * Open editor for connection "ethernet"
    * Submit "remove 802-3-ethernet.wake-on-lan magic"
    * Note the "802-3-ethernet.wake-on-lan" property from editor print output
    Then Noted value does not contain "magic"
    * Submit "set 802-3-ethernet.wake-on-lan phy" in editor
    * Submit "remove 802-3-ethernet.wake-on-lan default" in editor
    * Submit "set 802-3-ethernet.wake-on-lan unicast" in editor
    * Save in editor
    Then Check if object item "802-3-ethernet.wake-on-lan" has value "phy, unicast" via print
    * Submit "remove 802-3-ethernet.wake-on-lan"
    * Save in editor
    * Quit editor
    * Bring "down" connection "ethernet"
    * Bring "up" connection "ethernet"
    #Then "ETHTOOL_OPTS" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-ethernet"
    * Note the output of "ethtool sriov_device |grep Wake-on |grep -v Supports | awk '{print $2}'" as value "wol_new"
    Then Check noted values "wol_new" and "wol_orig" are the same


    @ver+=1.33 @rhelver+=8 @rhelver-10
    @not_on_s390x @8021x @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_pkcs11_saved_pw
    Scenario: nmcli - ethernet - connect to 8021x - tls - PKCS#11/SoftHSM - PIN is saved
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert 'pkcs11:token=nmci;object=nmclient'
          802-1x.client-cert-password-flags 4
          802-1x.private-key 'pkcs11:token=nmci;object=nmclient'
          802-1x.private-key-password 1234
          """
    * Execute "nmcli -a con up con_ethernet"
    Then Bring "up" connection "con_ethernet"


    @ver+=1.33 @rhelver+=8 @rhelver-10
    @not_on_s390x @8021x @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_pkcs11_pwfile
    Scenario: nmcli - ethernet - connect to 8021x - tls - PKCS#11/SoftHSM - PIN in password file
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert 'pkcs11:token=nmci;object=nmclient'
          802-1x.client-cert-password-flags 4
          802-1x.private-key 'pkcs11:token=nmci;object=nmclient'
          """
    * Execute "nmcli -s c show id con_ethernet"
    * Execute "nmcli con up con_ethernet passwd-file /tmp/pkcs11_passwd-file"
    Then "test8X:connected:con_ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8 @rhelver-10
    @not_on_s390x @8021x @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_pkcs11_nmcli_ask
    Scenario: nmcli - ethernet - connect to 8021x - tls - PKCS#11/SoftHSM - just private key/ask for pin on CLI
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert 'pkcs11:token=nmci;object=nmclient'
          802-1x.client-cert-password-flags 4
          802-1x.private-key 'pkcs11:token=nmci;object=nmclient'
          802-1x.private-key-password-flags 2
          """
    * Spawn "nmcli -a con up con_ethernet" command
    * Expect "802-1x.identity"
    * Enter in editor
    * Expect "802-1x.private-key-password"
    * Send "1234" in editor
    * Enter in editor
    Then "test8X:connected:con_ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8 @rhelver-10
    @not_on_s390x @8021x @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_pkcs11_pw_in_uri_flag_nr
    # these settings are hacky and may stop working when this is resolved: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/792
    Scenario: nmcli - ethernet - connect to 8021x - tls - PKCS#11/SoftHSM - just private key/pin given in URI with password flag not-required
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert 'pkcs11:token=nmci;object=nmclient'
          802-1x.client-cert-password-flags 4
          802-1x.private-key 'pkcs11:token=nmci;object=nmclient?pin-value=1234'
          802-1x.private-key-password-flags 4
          """
    * Execute "nmcli -a con up con_ethernet"
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_with_credentials
    Scenario: nmcli - ethernet - connect to 8021x - md5
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap md5
          802-1x.identity user
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls
    Scenario: nmcli - ethernet - connect to 8021x - tls
    # RHEL10 version
    * Doc: "Configuring 802.1X network authentication on an existing Ethernet connection using nmcli"
    * Add "ethernet" connection named "con_ethernet" with options "ifname test8X autoconnect no"
    * Modify connection "con_ethernet" changing options "802-1x.eap tls 802-1x.client-cert /etc/pki/nm-ci-certs/test_user.cert.pem 802-1x.private-key /etc/pki/nm-ci-certs/test_user.key.enc.pem"
    * Modify connection "con_ethernet" changing options "802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem"
    * Modify connection "con_ethernet" changing options "802-1x.identity test"
    * Modify connection "con_ethernet" changing options "802-1x.private-key-password redhat"
    Then Bring "up" connection "con_ethernet"


    @rhbz1623798
    @ver+=1.12
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_aes256_private_key
    Scenario: nmcli - ethernet - connect to 8021x - tls - private key encrypted by aes256
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert /etc/pki/nm-ci-certs/test_user.cert.pem
          802-1x.private-key /etc/pki/nm-ci-certs/test_user.key.enc.aes256.pem
          802-1x.private-key-password redhat
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_bad_private_key_password
    Scenario: nmcli - ethernet - connect to 8021x - tls - bad private key password
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert /etc/pki/nm-ci-certs/test_user.cert.pem
          802-1x.private-key /etc/pki/nm-ci-certs/test_user.key.enc.pem
          802-1x.private-key-password redhat12345
          """
    Then Bring "up" connection "con_ethernet" ignoring error
     And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id con_ethernet"


    @rhbz1433536
    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_no_private_key_password
    Scenario: nmcli - ethernet - connect to 8021x - tls - no private key pasword
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap tls
          802-1x.identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.client-cert /etc/pki/nm-ci-certs/test_user.cert.pem
          802-1x.private-key /etc/pki/nm-ci-certs/test_user.key.pem
          802-1x.private-key-password-flags 4
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.12
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_tls_bad_password_flag
    Scenario: nmcli - ethernet - connect to 8021x - tls - bad password flag
     * Add "ethernet" connection named "con_ethernet" with options
           """
           ifname test8X
           autoconnect no
           802-1x.eap tls
           802-1x.identity test
           802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
           802-1x.client-cert /etc/pki/nm-ci-certs/test_user.cert.pem
           802-1x.private-key /etc/pki/nm-ci-certs/test_user.key.enc.pem
           802-1x.private-key-password-flags 4
           """
    Then "Secrets were required, but not provided" is visible with command "nmcli con up con_ethernet" in "30" seconds
     And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id con_ethernet"


     @rhbz1714610
     @ver+=1.18.0
     @8021x @attach_hostapd_log @attach_wpa_supplicant_log @restart_if_needed
     @8021x_tls_pkcs12_key_restart
     Scenario: nmcli - ethernet - 8021x - tls - connection with pkcs12 key persists restart
     * Add "ethernet" connection named "con_ethernet" with options
           """
           ifname test8X
           autoconnect no
           802-1x.eap tls
           802-1x.identity test
           802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
           802-1x.private-key /etc/pki/nm-ci-certs/test_user.p12
           802-1x.private-key-password redhat
           """
     Then Bring "up" connection "con_ethernet"
     * Restart NM
     Then "con_ethernet" is visible with command "nmcli con"
      And Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_peap_md5
    Scenario: nmcli - ethernet - connect to 8021x - peap - md5
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap peap
          802-1x.identity test_md5
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth md5
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_peap_mschapv2
    Scenario: nmcli - ethernet - connect to 8021x - peap - mschapv2
    # RHEL8/9 version
    * Doc: "Configuring 802.1X network authentication on an existing Ethernet connection using nmcli"
    * Add "ethernet" connection named "con_ethernet" with options "ifname test8X autoconnect no"
    * Modify connection "con_ethernet" changing options "802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.phase2-auth mschapv2"
    * Modify connection "con_ethernet" changing options "802-1x.password password"
    * Modify connection "con_ethernet" changing options "802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem"
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_peap_gtc
    Scenario: nmcli - ethernet - connect to 8021x - peap - gtc
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap peap
          802-1x.identity test_gtc
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth gtc
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_pap
    Scenario: nmcli - ethernet - connect to 8021x -ttls - pap
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth pap
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_chap
    Scenario: nmcli - ethernet - connect to 8021x -ttls - chap
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth chap
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_mschap
    Scenario: nmcli - ethernet - connect to 8021x -ttls - mschap
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth mschap
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_mschapv2
    Scenario: nmcli - ethernet - connect to 8021x -ttls - mschapv2
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth mschapv2
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_mschapv2_eap
    Scenario: nmcli - ethernet - connect to 8021x -ttls - mschap - eap
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity TESTERS\\test_mschapv2
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-autheap mschapv2
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_md5
    Scenario: nmcli - ethernet - connect to 8021x -ttls - md5
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_md5
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-autheap md5
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @ver+=1.6.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_ttls_gtc
    Scenario: nmcli - ethernet - connect to 8021x -ttls - gtc
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_gtc
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-autheap gtc
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"


    @rhbz1698532
    @ver+=1.22.0
    @skip_in_centos
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_auto_auth_retry_with_backup_network
    Scenario: nmcli - ethernet - connect to 8021x auto auth retry
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth chap
          802-1x.password password
          connection.auth-retries 1
          802-1x.optional yes
          802-1x.auth-timeout 10
          """
    # Shut down authenticated port
    * Execute "ip link set dev test8Yp down"
    # Bring up backup network port
    * Execute "ip link set dev test8Zp up"
    * Bring "up" connection "con_ethernet"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ethernet" in "20" seconds
    When "10.0.254" is visible with command "ip a s test8X"
    And Ping "10.0.254.1" "3" times
    # Bring up backup authenticated network port
    * Execute "ip link set dev test8Yp up"
    * Execute "ip link set dev test8Zp down"
    Then "10.0.253" is visible with command "ip a s test8X" in "130" seconds
    And Ping "10.0.253.1" "3" times


    #@rhbz1698532
    #@ver+=1.22.0
    #@8021x @attach_hostapd_log @attach_wpa_supplicant_log
    #@8021x_auto_auth_retry
    #Scenario: nmcli - ethernet - connect to 8021x auto auth retry
    #* Add "ethernet" connection named "con_ethernet" with options
    #   """
    #   ifname test8X
    #   autoconnect no
    #   802-1x.eap ttls
    #   802-1x.identity test_ttls
    #   802-1x.anonymous-identity test
    #   802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
    #   802-1x.phase2-auth chap
    #   802-1x.password password
    #   connection.auth-retries 5
    #   802-1x.auth-timeout 180
    #   """
    ## Stop Hostapd
    #* Execute "pkill -SIGSTOP -F /tmp/hostapd.pid"
    #* Run child "nmcli con up con_ethernet"
    ## Start it again
    #* Execute "sleep 30 && kill -SIGCONT -F /tmp/hostapd.pid"
    #Then "activated" is visible with command "nmcli -g GENERAL.STATE con show con_ethernet" in "180" seconds
    @rhbz1456362
    @ver+=1.8.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_with_raw_credentials
    Scenario: nmcli - ethernet - connect to 8021x - md5 - raw
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap md5
          802-1x.identity user
          802-1x.password-raw '70 61 73 73 77 6f 72 64'
          """
    Then Bring "up" connection "con_ethernet"


    @rhbz1113941 @rhbz1438476
    @ver+=1.10.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_without_password
    Scenario: nmcli - ethernet - connect to 8021x - md5 - ask for password
    * Add "ethernet" connection named "con_ethernet" with options "ifname test8X 802-1x.eap md5 802-1x.identity user"
    * Spawn "nmcli -a con up con_ethernet" command
    * Expect "identity.*user"
    * Enter in editor
    * Send "password" in editor
    * Enter in editor
    Then "test8X:connected:con_ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.8.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_without_password_with_ask_at_the_end
    Scenario: nmcli - ethernet - connect to 8021x - md5 - ask for password at the end
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          802-1x.eap md5
          802-1x.identity user
          autoconnect no
          """
    * Spawn "nmcli con up con_ethernet -a" command
    * Expect "identity.*user"
    * Enter in editor
    * Send "password" in editor
    * Enter in editor
    Then "test8X:connected:con_ethernet" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @rhbz1391477
    @ver+=1.7.1
    @preserve_8021x_certs
    @preserve_8021x_certs_ethernet
    Scenario: nmcli - ethernet - preserve 8021x certs
    * Add "ethernet" connection named "con_ethernet" for device "\*" with options
          """
          802-1x.eap 'tls'
          802-1x.client-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.private-key-password x
          802-1x.private-key /etc/pki/nm-ci-certs/test_user.cert_and_enc_key.pem
          802-1x.password pass1
          """
    * Reload connections
    Then "con_ethernet" is visible with command "nmcli con"


    @rhbz1374660
    @ver+=1.10
    @preserve_8021x_leap_con
    Scenario: nmcli - ethernet - preserve 8021x leap connection
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          802-1x.identity jdoe
          802-1x.eap leap
          """
    * Reload connections
    Then "con_ethernet" is visible with command "nmcli con"


    @rhbz1843360 @rhbz1841398 @rhbz1841397
    @ver+=1.25.2
    @rhelver-=9 @fedoraver-=38 @ifcfg-rh
    @8021x_ca_path_with_ifcfg_plugin
    Scenario: nmcli - ethernet - check that CA path is saved with ifcfg-rh plugin
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          autoconnect no
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-path /etc/pki/nm-ci-certs/
          802-1x.phase2-auth mschapv2
          802-1x.password password
          """
    Then "/etc/pki/nm-ci-certs/" is visible with command "nmcli -t -f 802-1x.ca-path con show id con_ethernet"


    @ver+=1.32.0
    @8021x @attach_hostapd_log @attach_wpa_supplicant_log
    @8021x_stop_wpa_supplicant_with_8021x_optional
    Scenario: nmcli - ethernet - stop wpa_supplicant with 802-1x optional
    * Add "ethernet" connection named "con_ethernet" with options
          """
          ifname test8X
          802-1x.eap peap
          802-1x.optional yes
          802-1x.identity test_md5
          802-1x.anonymous-identity test
          802-1x.ca-cert /etc/pki/nm-ci-certs/test_user.ca.pem
          802-1x.phase2-auth md5
          802-1x.password password
          """
    Then Bring "up" connection "con_ethernet"
    Then "activated" is visible with command "nmcli -g general.state con show id con_ethernet" in "10" seconds
    * Execute "systemctl stop wpa_supplicant.service"
    Then "activated" is not visible with command "nmcli -g general.state con show id con_ethernet" in "10" seconds
    And "^active" is visible with command "systemctl is-active wpa_supplicant.service"
    Then "activated" is visible with command "nmcli -g general.state con show id con_ethernet" in "10" seconds


    # all tests with @8021x tag should go before this one
    @8021x_teardown
    @8021x_teardown_eth
    Scenario: just remove 802.1-x set up
    * Execute "echo 'this is skipped'"


    @rhbz1335409
    @ver+=1.14
    @ethtool_features_connection
    Scenario: nmcli - ethernet - change ethtool feature in connection
    * Doc: "Configuring network adapter offload settings"
    Given "fixed" is not visible with command "ethtool -k eth1 | grep tx-checksum-ip-generic:"
    * Note the output of "ethtool -k eth1 | grep tx-checksum-ipv4:" as value "out1"
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          autoconnect no
          ethtool.feature-tx-checksum-ip-generic on
          """
    * Bring "up" connection "con_ethernet"
    When "on" is visible with command "ethtool -k eth1 | grep tx-checksum-ip-generic:"
    * Modify connection "con_ethernet" changing options "ethtool.feature-tx-checksum-ip-generic off"
    * Bring "up" connection "con_ethernet"
    Then "off" is visible with command "ethtool -k eth1 | grep tx-checksum-ip-generic:"
    * Modify connection "con_ethernet" changing options "ethtool.feature-tx-checksum-ip-generic ignore"
    * Bring "up" connection "con_ethernet"
    * Note the output of "ethtool -k eth1 | grep tx-checksum-ipv4:" as value "out2"
    Then Check noted values "out1" and "out2" are the same


    @rhbz1335409
    @ver+=1.14
    @ethtool_features_fixed_connection
    Scenario: nmcli - ethernet - change ethtool fixed feature in connection
    Given "fixed" is visible with command "ethtool -k eth1 | grep tx-checksum-ipv4:"
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          autoconnect no
          ethtool.feature-tx-checksum-ipv4 on
          """
    * Bring "up" connection "con_ethernet"
    * Note the output of "ethtool -k eth1 | grep tx-checksum-ipv4:" as value "out1"
    * Modify connection "con_ethernet" changing options "ethtool.feature-tx-checksum-ipv4 off"
    * Bring "up" connection "con_ethernet"
    * Note the output of "ethtool -k eth1 | grep tx-checksum-ipv4:" as value "out2"
    Then Check noted values "out1" and "out2" are the same


    @rhbz1614700 @rhbz1807171 @rhbz2034086
    @ver+=1.35 @rhelver+=8 @fedoraver+=34
    @prepare_patched_netdevsim
    @ethtool_features_ring
    Scenario: nmcli - ethernet - ethtool set ring options
    * Note the output of "ethtool -g eth11" as value "ring"
    * Run child "journalctl -f -u NetworkManager -o cat"
    When Expect "<" in children in "10" seconds
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/24
          ethtool.ring-tx 1000
          ethtool.ring-rx-jumbo 1000
          ethtool.ring-rx-mini 100
          ethtool.ring-rx 1
          autoconnect no
          """
    Then Expect "ethtool.ring-rx-mini\s+= 100" in children in "10" seconds
    * Kill children
    * Bring "up" connection "con_ethernet"
    When "RX:\s+1\s*RX Mini:\s+100\s*RX Jumbo:\s+1000\s*TX:\s+1000" is visible with command "ethtool -g eth11"
    * Disconnect device "eth11"
    When Noted value "ring" is visible with command "ethtool -g eth11"
    * Modify connection "con_ethernet" changing options "ethtool.ring-tx 0 ethtool.ring-rx-jumbo 0 ethtool.ring-rx-mini 0 ethtool.ring-rx 0"
    * Bring "up" connection "con_ethernet"
    When "RX:\s+0\s*RX Mini:\s+0\s*RX Jumbo:\s+0\s*TX:\s+0" is visible with command "ethtool -g eth11"


    @ver+=1.45.4 @rhelver+=8
    @prepare_patched_netdevsim
    @ethtool_features_channels
    Scenario: nmcli - ethernet - ethtool set channels options
    * Note the output of "ethtool -l eth11" as value "channels_before"
    * Note the output of "ethtool -l eth11 | grep -i combined" as value "channels_combined_before"
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/24
          ethtool.channels-rx 4
          ethtool.channels-tx 3
          ethtool.channels-other 2
          ethtool.channels-combined 2
          """
    * Bring "up" connection "con_ethernet"
    * Commentary
      """
      Match only last 4 lines, should be "Current hardware settings".
      However, ethtool v6.15+ doesn't print "Current hardware settings" anymore.
      """
    When "RX:\s+4\s*TX:\s+3\s*Other:\s+2\s*Combined:\s+2" is visible with command "ethtool -l eth11 | tail -n4"
    * Modify connection "con_ethernet" changing options "ethtool.channels-other 9"
    * Bring "up" connection "con_ethernet"
    When "RX:\s+4\s*TX:\s+3\s*Other:\s+9\s*Combined:\s+2" is visible with command "ethtool -l eth11 | tail -n4"
    * Modify connection "con_ethernet" changing options "ethtool.channels-combined ''"
    * Bring "up" connection "con_ethernet"
    When "RX:\s+4\s*TX:\s+3\s*Other:\s+9" is visible with command "ethtool -l eth11 | tail -n4"
    * Note the output of "ethtool -l eth11 | grep -i combined" as value "channels_combined_after"
    Then Check noted values "channels_combined_before" and "channels_combined_after" are the same
    * Disconnect device "eth11"
    Then Noted value "channels_before" is visible with command "ethtool -l eth11"


    @rhbz1899372
    @ver+=1.31 @rhelver+=8.5 @fedoraver+=34
    @prepare_patched_netdevsim
    @ethtool_features_pause
    Scenario: nmcli - ethernet - ethtool set pause options
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/24
          ethtool.pause-tx on
          ethtool.pause-rx on
          ethtool.pause-autoneg off
          """
    * Bring "up" connection "con_ethernet"
    When "Autonegotiate:" is visible with command "ethtool -a eth11"
    Then "Autonegotiate:\s+off" is visible with command "ethtool -a eth11"
    Then "RX:\s+on" is visible with command "ethtool -a eth11"
    Then "TX:\s+on" is visible with command "ethtool -a eth11"
    * Disconnect device "eth11"
    When "Autonegotiate" is visible with command "ethtool -a eth11"
    * Modify connection "con_ethernet" changing options "ethtool.pause-rx off ethtool.pause-tx off"
    * Bring "up" connection "con_ethernet"
    When "Autonegotiate:" is visible with command "ethtool -a eth11"
    Then "Autonegotiate:\s+off" is visible with command "ethtool -a eth11"
    Then "RX:\s+off" is visible with command "ethtool -a eth11"
    Then "TX:\s+off" is visible with command "ethtool -a eth11"


    @rhbz1614700 @rhbz1807171
    @ver+=1.25 @rhelver+=8 @fedoraver+=34
    @prepare_patched_netdevsim
    @ethtool_features_coal
    Scenario: nmcli - ethernet - ethtool set coalescing options
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.addresses 192.0.2.1/24
          ethtool.coalesce-adaptive-rx 1
          ethtool.coalesce-adaptive-tx 1
          ethtool.coalesce-pkt-rate-high 3
          ethtool.coalesce-pkt-rate-low 2
          ethtool.coalesce-rx-frames 1
          ethtool.coalesce-rx-frames-high 3
          ethtool.coalesce-rx-frames-irq 2
          ethtool.coalesce-rx-frames-low 1
          ethtool.coalesce-rx-usecs 1
          ethtool.coalesce-rx-usecs-high 3
          ethtool.coalesce-rx-usecs-irq 2
          ethtool.coalesce-rx-usecs-low 1
          ethtool.coalesce-sample-interval 2
          ethtool.coalesce-stats-block-usecs 2
          ethtool.coalesce-tx-frames 1
          ethtool.coalesce-tx-frames-high 3
          ethtool.coalesce-tx-frames-irq 2
          ethtool.coalesce-tx-frames-low 1
          ethtool.coalesce-tx-usecs 1
          ethtool.coalesce-tx-usecs-high 3
          ethtool.coalesce-tx-usecs-irq 2
          ethtool.coalesce-tx-usecs-low 1
          """
    * Bring "up" connection "con_ethernet"
    When "Adaptive RX: on  TX: on\s*stats-block-usecs:\s*2\s*sample-interval:\s*2\s*pkt-rate-low:\s*2\s*pkt-rate-high:\s*3" is visible with command "ethtool -c eth11"
    When "rx-usecs:\s*1\s*rx-frames:\s*1\s*rx-usecs-irq:\s*2\s*rx-frames-irq:\s*2" is visible with command "ethtool -c eth11"
    When "rx-frames-irq:\s*2\s*tx-usecs:\s*1\s*tx-frames:\s*1\s*tx-usecs-irq:\s*2\s*tx-frames-irq:\s*2" is visible with command "ethtool -c eth11"
    When "rx-usecs-low:\s*1\s*rx-frames?-low:\s*1\s*tx-usecs-low:\s*1\s*tx-frames?-low:\s*1" is visible with command "ethtool -c eth11"
    When "rx-usecs-high:\s*3\s*rx-frames?-high:\s*3\s*tx-usecs-high:\s*3\s*tx-frames?-high:\s*3\s*" is visible with command "ethtool -c eth11"
    * Disconnect device "eth11"
    When "Adaptive RX:\s*off  TX:\s*off\s*stats-block-usecs:\s*0\s*sample-interval:\s*0\s*pkt-rate-low:\s*0\s*pkt-rate-high:\s*0\s*rx-usecs:\s*0\s*rx-frames:\s*0\s*rx-usecs-irq:\s*0\s*rx-frames-irq:\s*0\s*tx-usecs:\s*0\s*tx-frames:\s*0\s*tx-usecs-irq:\s*0\s*tx-frames-irq:\s*0\s*rx-usecs-low:\s*0\s*rx-frames?-low:\s*0\s*tx-usecs-low:\s*0\s*tx-frames?-low:\s*0\s*rx-usecs-high:\s*0\s*rx-frames?-high:\s*0\s*tx-usecs-high:\s*0\s*tx-frames?-high:\s*0\s*" is visible with command "ethtool -c eth11"
    * Modify connection "con_ethernet" changing options
          """
          ethtool.coalesce-adaptive-rx 0
          ethtool.coalesce-adaptive-tx 0
          ethtool.coalesce-pkt-rate-high 0
          ethtool.coalesce-pkt-rate-low 0
          ethtool.coalesce-rx-frames 0
          ethtool.coalesce-rx-frames-high 0
          ethtool.coalesce-rx-frames-irq 0
          ethtool.coalesce-rx-frames-low 0
          ethtool.coalesce-rx-usecs 0
          ethtool.coalesce-rx-usecs-high 0
          ethtool.coalesce-rx-usecs-irq 0
          ethtool.coalesce-rx-usecs-low 0
          ethtool.coalesce-sample-interval 0
          ethtool.coalesce-stats-block-usecs 0
          ethtool.coalesce-tx-frames 0
          ethtool.coalesce-tx-frames-high 0
          ethtool.coalesce-tx-frames-irq 0
          ethtool.coalesce-tx-frames-low 0
          ethtool.coalesce-tx-usecs 0
          ethtool.coalesce-tx-usecs-high 0
          ethtool.coalesce-tx-usecs-irq 0
          ethtool.coalesce-tx-usecs-low 0
          """
    * Bring "up" connection "con_ethernet"
    Then "Adaptive RX:\s*off  TX:\s*off\s*stats-block-usecs:\s*0\s*sample-interval:\s*0\s*pkt-rate-low:\s*0\s*pkt-rate-high:\s*0\s*rx-usecs:\s*0\s*rx-frames:\s*0\s*rx-usecs-irq:\s*0\s*rx-frames-irq:\s*0\s*tx-usecs:\s*0\s*tx-frames:\s*0\s*tx-usecs-irq:\s*0\s*tx-frames-irq:\s*0\s*rx-usecs-low:\s*0\s*rx-frames?-low:\s*0\s*tx-usecs-low:\s*0\s*tx-frames?-low:\s*0\s*rx-usecs-high:\s*0\s*rx-frames?-high:\s*0\s*tx-usecs-high:\s*0\s*tx-frames?-high:\s*0\s*" is visible with command "ethtool -c eth11"


    @RHEL-24055
    @ver+=1.51.4 @rhelver+=8
    @ver+=1.50.3
    @ver+=1.48.17
    @ver+=1.46.7
    @ver/rhel/9/4+=1.46.0.29
    @ver/rhel/9/5+=1.48.10.9
    @prepare_patched_netdevsim
    @ethtool_features_fec
    Scenario: nmcli - ethernet - ethtool set fec options
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
        """
        ipv4.method manual
        ipv4.addresses 192.0.2.1/24
        ethtool.fec auto
        """
    When Bring "up" connection "con_ethernet"
     And "Supported/Configured FEC encodings: Auto" is visible with command "ethtool --show-fec eth11"
    * Modify connection "con_ethernet" changing options "ethtool.fec off"
    Then Bring "up" connection "con_ethernet"
     And "Active FEC encoding: Off" is visible with command "ethtool --show-fec eth11"
    * Modify connection "con_ethernet" changing options "ethtool.fec rs"
    Then Bring "up" connection "con_ethernet"
     And "Active FEC encoding: RS" is visible with command "ethtool --show-fec eth11"
    * Modify connection "con_ethernet" changing options "ethtool.fec baser"
    Then Bring "up" connection "con_ethernet"
     And "Active FEC encoding: BaseR" is visible with command "ethtool --show-fec eth11"
    * Modify connection "con_ethernet" changing options "ethtool.fec llrs"
    Then Bring "up" connection "con_ethernet"
     And "Active FEC encoding: LLRS" is visible with command "ethtool --show-fec eth11"


    @rhbz1942331
    @ver+=1.31
    @ethernet_accept_all_mac_addresses_external_device
    Scenario: nmcli - ethernet - accept-all-mac-addresses (promisc mode)
    # promisc off -> default
    * Execute "ip link set dev eth1 promisc off"
    When "PROMISC" is not visible with command "ip link show dev eth1"
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          autoconnect no
          802-3-ethernet.accept-all-mac-addresses default
          """
    * Bring "up" connection "con_ethernet"
    Then "PROMISC" is not visible with command "ip link show dev eth1"
    * Bring "down" connection "con_ethernet"
    # promisc on -> default
    * Execute "ip link set dev eth1 promisc on"
    When "PROMISC" is visible with command "ip link show dev eth1"
    * Bring "up" connection "con_ethernet"
    Then "PROMISC" is visible with command "ip link show dev eth1"
    * Bring "down" connection "con_ethernet"
    # promisc off -> true
    * Execute "ip link set dev eth1 promisc off"
    When "PROMISC" is not visible with command "ip link show dev eth1"
    * Modify connection "con_ethernet" changing options "802-3-ethernet.accept-all-mac-addresses true"
    * Bring "up" connection "con_ethernet"
    Then "PROMISC" is visible with command "ip link show dev eth1"
    * Bring "down" connection "con_ethernet"
    # promisc on -> false
    * Execute "ip link set dev eth1 promisc on"
    When "PROMISC" is visible with command "ip link show dev eth1"
    * Modify connection "con_ethernet" changing options "802-3-ethernet.accept-all-mac-addresses false"
    * Bring "up" connection "con_ethernet"
    Then "PROMISC" is not visible with command "ip link show dev eth1"


    @rhbz1935842
    @keyfile
    @ethernet_s390_options_with_subchannels
    Scenario: nmcli - ethernet - set ethernet.s390-options with subchannels
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          autoconnect no
          802-3-ethernet.s390-options portno=20
          802-3-ethernet.s390-subchannels "0.0.8000,0.0.8001,0.0.8002"
          """
    Then "portno=20" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "0.0.8000,0.0.8001,0.0.8002" is visible with command "nmcli -g 802-3-ethernet.s390-subchannels con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "802-3-ethernet.s390-options layer2=secondary,portno=6"
    Then "layer2=secondary" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno=6" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "+802-3-ethernet.s390-options layer2=none"
    Then "layer2=none" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno=6" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "-802-3-ethernet.s390-options portno"
    Then "layer2=none" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno" is not visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"


    @rhbz1935842
    @ver+=1.32.2
    @ethernet_s390_options_without_subchannels
    Scenario: nmcli - ethernet - set ethernet.s390-options without setting s390-subchannels
    * Add "ethernet" connection named "con_ethernet" for device "eth1" with options
          """
          autoconnect no
          802-3-ethernet.s390-options bridge_role=primary
          """
    Then "bridge_role=primary" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "802-3-ethernet.s390-options bridge_role=secondary,portno=6"
    Then "bridge_role=secondary" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno=6" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "+802-3-ethernet.s390-options bridge_role=none"
    Then "bridge_role=none" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno=6" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    * Modify connection "con_ethernet" changing options "-802-3-ethernet.s390-options portno"
    Then "bridge_role=none" is visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"
    And "portno" is not visible with command "nmcli -g 802-3-ethernet.s390-options con show id con_ethernet"


    @rhbz2022623
    @ver+=1.36.0
    @ethernet_keyfiles_dont_write_empty_mac_address_blacklist
    Scenario: Don't write mac-address-blacklist= in keyfiles
    * Create keyfile "/etc/NetworkManager/system-connections/con_ethernet.nmconnection"
      """
      [connection]
      id=con_ethernet
      uuid=0b91a219-b24c-4588-816f-a873530ac58e
      type=ethernet
      autoconnect=true

      [ethernet]
      mac-address-blacklist=

      [ipv4]
      method=auto

      [ipv6]
      addr-gen-mode=stable-privacy
      method=auto

      [proxy]
      """
    * Reload connections
    * Modify connection "con_ethernet" changing options "connection.autoconnect false"
    When Execute "ls /etc/NetworkManager/system-connections/con_ethernet.nmconnection"
    Then "mac-address" is not visible with command "cat /etc/NetworkManager/system-connections/con_ethernet.nmconnection"


    @rhbz2134569
    @ver+=1.40.4 @rhelver+=8
    @prepare_patched_netdevsim
    @ethtool_multiple_options_in_profile_file
    Scenario: nmcli - ethernet - check if correct ethtool options are configured in ifcfg file
    * Add "ethernet" connection named "con_ethernet" for device "eth11" with options
          """
          ipv4.method manual
          ipv4.address 192.0.2.1/24
          """
    * Bring "up" connection "con_ethernet"
    When "GENERAL.STATE:activated" is visible with command "nmcli -f GENERAL.STATE -t connection show id con_ethernet"
    * Modify connection "con_ethernet" changing options "ethtool.pause-autoneg off"
    * Bring "up" connection "con_ethernet" 
    When "GENERAL.STATE:activated" is visible with command "nmcli -f GENERAL.STATE -t connection show id con_ethernet"
    * Modify connection "con_ethernet" changing options "ethtool.ring-rx 512"
    * Bring "up" connection "con_ethernet"
    When "GENERAL.STATE:activated" is visible with command "nmcli -f GENERAL.STATE -t connection show id con_ethernet"
    Then Check keyfile "/etc/NetworkManager/system-connections/con_ethernet.nmconnection" has options
          """
          ethtool.pause-autoneg=false
          ethtool.ring-rx=512
          """


    @rhbz2154350
    @ver+=1.40.12
    @ignore_backoff_message
    @ethernet_keep_mtu_on_reboot
    Scenario: nmcli - connection - keep the same MTU for many devices on reboot
    * Create "302" "veth" devices named "veth_dev"
    * Add "302" "ethernet" connections named "con_con" for devices "veth_dev" with options
          """
          autoconnect yes
          ipv4.method disabled
          ipv6.method disabled
          802-3-ethernet.mtu 9000
          """
     Then "Exactly" "302" lines with pattern "mtu 9000" are visible with command "ip link show" in "120" seconds
     * Stop NM
     * Execute "for i in $(seq 0 301); do ip link set veth_dev_$i down; ip addr flush veth_dev_$i; done;"
     * Reboot within "20" seconds
     Then "Exactly" "302" lines with pattern "mtu 9000" are visible with command "ip link show" in "120" seconds
