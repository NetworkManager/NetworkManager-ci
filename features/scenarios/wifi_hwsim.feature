Feature: nmcli - wifi

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.9.1 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_open_connect
    Scenario: nmcli - simwifi - connect to open network
    Given "open" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add "wifi" connection named "open" for device "wlan0" with options "autoconnect no ssid open"
    * Bring "up" connection "open"
    And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id wifi"
    Then "open" is visible with command "iw dev wlan0 link" in "15" seconds
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @ver+=1.9.1 @fedoraver-=34 @rhelver-=8
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_ask_passwd
    Scenario: simwifi - connect WEP network asking for password
    Given "wep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Cleanup connection "wep"
    * Spawn "nmcli -a device wifi connect wep" command
    * Expect "Password:"
    * Submit "abcde"
    Then "\*\s+wep" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "45" seconds
    Then "wep" is visible with command "iw dev wlan0 link"


    @ver+=1.10 @fedoraver-=34 @rhelver-=8
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_tls
    Scenario: nmcli - simwifi - connect to WEP TLS
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add insecure "wifi" connection named "wifi" for device "wlan0" with options
            """
            autoconnect no
            ssid dynwep
            802-11-wireless-security.key-mgmt ieee8021x
            802-1x.eap tls
            802-1x.identity test
            802-1x.ca-cert /tmp/certs/test_user.ca.pem
            802-1x.client-cert /tmp/certs/test_user.cert.pem
            802-1x.private-key /tmp/certs/test_user.key.enc.pem
            802-1x.private-key-password redhat
            """"
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver-=34 @rhelver-=8
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_ttls_mschapv2_eap
    Scenario: nmcli - simwifi - connect to WEP TTLS MSCHAPv2 + EAP
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add insecure "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid dynwep
          802-11-wireless-security.key-mgmt ieee8021x
          802-1x.eap ttls
          802-1x.identity TESTERS\\test_mschapv2
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-autheap mschapv2
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver-=34 @rhelver-=8
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_peap_gtc
    Scenario: nmcli - simwifi - connect to WEP PEAP GTC
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add insecure "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid dynwep
          802-11-wireless-security.key-mgmt ieee8021x
          802-1x.eap peap
          802-1x.identity test_gtc
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth gtc
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa1psk_no_profile
    Scenario: nmcli - simwifi - connect to WPA1 PSK network without profile
    Given "wpa1-psk" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Cleanup connection "wpa1-psk"
    * Connect wifi device to "wpa1-psk" network with options "password secret123"
    Then "\*\s+wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "wpa1-psk" is visible with command "iw dev wlan0 link"


    @ver+=1.9.1 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa2psk_no_profile
    Scenario: nmcli - simwifi - connect to WPA2 PSK network without profile
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Cleanup connection "wpa2-eap"
    * Execute "nmcli device wifi connect wpa2-eap password secret123"
    * Wait for "1" seconds
    * Bring "up" connection "wpa2-eap"
    Then "wpa2-eap" is visible with command "iw dev wlan0 link" in "15" seconds
    Then "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @rhbz1080628
    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa2psk_profile
    Scenario: simwifi - wifi-sec - configure and connect WPA2-PSK profile
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add "wifi" connection named "wpa2-eap" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk secret123
          """
    * Wait for "1" seconds
    * Bring up connection "wpa2-eap"
    Then "wpa2-eap" is visible with command "iw dev wlan0 link" in "3" seconds
    Then "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    # Lets make sure that profile keeps secrets after modifications
    * Modify connection "wpa2-eap" changing options "connection.zone trusted"
    * Bring up connection "wpa2-eap"
    Then "wpa2-eap" is visible with command "iw dev wlan0 link" in "3" seconds
    And "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    And "inet 10" is visible with command "ip a s wlan0"


    @rhbz990111
    @simwifi
    @simwifi_wpa2_ask_passwd
    Scenario: nmcli - wifi - connect WPA network asking for password
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Cleanup connection "wpa2-eap"
    * Spawn "nmcli -a device wifi connect wpa2-eap" command
    * Expect "Password:"
    * Submit "secret123"
    Then "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "45" seconds
    Then "wpa2-eap" is visible with command "iw dev wlan0 link"


    @rhbz2059608
    @ver+=1.38.0
    @simwifi
    @simwifi_migrate_to_keyfile
    Scenario: nmcli - connection - migrate connection from ifcfg-file to keyfile
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Cleanup connection "migration_wifi" and device "wlan0"
    * Execute "cp contrib/profiles/ifcfg-migration_wifi /etc/sysconfig/network-scripts/ifcfg-migration_wifi"
    * Reload connections
    * Modify connection "migration_wifi" changing options "802-1x.password password"
    * Bring "up" connection "migration_wifi"
    Then "wlan0:connected:migration_wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Note the output of "nmcli con show migration_wifi" as value "ifcfg_output"
    * Execute "nmcli con migrate ddb42e19-642d-4139-a2bc-eda0c6504fdd"
    * Reload connections
    Then "wlan0:connected:migration_wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "40" seconds
    * Note the output of "nmcli con show migration_wifi" as value "keyfile_output"
    Then Check noted values "ifcfg_output" and "keyfile_output" are the same
    And ifcfg-"migration_wifi" file does not exist


    @ver+=1.33 @rhelver+=8
    @simwifi @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_saved_pw
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11 - saved PIN
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient' 802-1x.private-key-password 1234"
    * Wait for "3" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.33 @rhelver+=8
    @simwifi @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_pwfile
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient'"
    * Wait for "3" seconds
    * Execute "nmcli con up wifi passwd-file /tmp/pkcs11_passwd-file"
    Then "wlan0:connected:wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8
    @simwifi @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_nmcli_ask
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient' 802-1x.private-key-password-flags 2"
    * Wait for "3" seconds
    * Spawn "nmcli -a con up wifi" command
    * Expect "802-1x.identity"
    * Enter in editor
    * Expect "802-1x.private-key-password"
    * Send "1234" in editor
    * Enter in editor
    Then "wlan0:connected:wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8
    @simwifi @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_pw_in_uri_flag_nr
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    # these settings are hacky and may stop working when this is resolved: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/792
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient?pin-value=1234' 802-1x.private-key-password-flags 4"
    * Wait for "3" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls
    Scenario: nmcli - simwifi - connect to TLS
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat"
    * Wait for "3" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_bad_private_key_password
    Scenario: nmcli - simwifi - connect to TLS - bad private key password
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat123456"
    * Wait for "3" seconds
    Then Bring up connection "wifi" ignoring error
     And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id wifi"


    @rhbz1433536
    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_no_private_key_password
    Scenario: nmcli - simwifi - connect to TLS - no private key password
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.pem 802-1x.private-key-password-flags 4"
    * Wait for "3" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_gtc
    Scenario: nmcli - simwifi - connect to PEAP GTC
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap peap
          802-1x.identity test_gtc
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth gtc
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_md5
    Scenario: nmcli - simwifi - connect to PEAP MD5
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap peap
          802-1x.identity test_md5
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth md5
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_mschapv2
    Scenario: nmcli - simwifi - connect to PEAP MSCHAPv2
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap peap
          802-1x.identity TESTERS\\test_mschapv2
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth mschapv2
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_pap
    Scenario: nmcli - simwifi - connect to TTLS PAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth pap
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_chap
    Scenario: nmcli - simwifi - connect to TTLS CHAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth chap
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschap
    Scenario: nmcli - simwifi - connect to TTLS MSCHAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth mschap
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschapv2
    Scenario: nmcli - simwifi - connect to TTLS MSCHAPv2
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_ttls
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-auth mschapv2
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschapv2_eap
    Scenario: nmcli - simwifi - connect to TTLS MSCHAPv2 + EAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity TESTERS\\test_mschapv2
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-autheap mschapv2
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_md5
    Scenario: nmcli - simwifi - connect to TTLS MD5
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_md5
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-autheap md5
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_gtc
    Scenario: nmcli - simwifi - connect to TTLS GTC
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.identity test_gtc
          802-1x.anonymous-identity test
          802-1x.ca-cert /tmp/certs/test_user.ca.pem
          802-1x.phase2-autheap gtc
          802-1x.password password
          """
    * Wait for "1" seconds
    Then Bring "up" connection "wifi"


    @rhbz1520398
    @ver+=1.10 @fedoraver+=31
    @simwifi
    @nmclient_get_wireless_hw_property
    Scenario: nmclient - property - get wireless hardware property
    Then "True|False" is visible with command "/usr/bin/python contrib/gi/nmclient_get_property.py wireless-hardware-enabled"


    @rhbz1626391
    @ver+=1.12 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi
    @simwifi_dbus_bitrate_property_name
    Scenario: dbus - property name for Device.Wireless.Bitrate
    Then "Bitrate" is visible with command "for dev_id in $(busctl tree org.freedesktop.NetworkManager | grep Devices/ | grep -o '[0-9]*$'); do busctl introspect org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Devices/$dev_id | grep Bitrate; done"


    @rhbz1730177
    @ver+=1.22 @rhelver+=8.2 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi
    @simwifi_wpa3_personal
    Scenario: nmcli - simwifi - connect to WPA3 personal wifi
    Given "wpa3-psk" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then "wpa3-psk:WPA3" is visible with command "nmcli -t -f ssid,security device wifi list"
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa3-psk
          802-11-wireless-security.key-mgmt sae
          802-11-wireless-security.psk secret123
          """
    Then Bring "up" connection "wifi"


    @rhbz2019396
    @ver+=1.35.5 @rhelver+=8.6 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa3_h2e
    Scenario: nmcli - simwifi - connect to WPA3 H2E
    Given "wpa3-h2e" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then "wpa3-h2e:WPA3" is visible with command "nmcli -t -f ssid,security device wifi list"
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa3-h2e
          802-11-wireless-security.key-mgmt sae
          802-11-wireless-security.psk secret123
          """
    Then Bring "up" connection "wifi"


    @rhbz1730177
    @ver+=1.22 @rhelver+=8.2 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa3_personal_device_connect_ask
    Scenario: nmcli - simwifi - connect to WPA3 personal wifi with device command
    Given "wpa3-psk" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Cleanup connection "wpa3-psk"
    Then Execute "echo secret123 | nmcli dev wifi connect wpa3-psk --ask"



    @ver+=1.29 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_wpa3
    Scenario: nmcli - simwifi - connect to TLS
    Given "wpa3-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa3-eap"
    * Modify connection "wifi" changing options "802-11-wireless-security.key-mgmt wpa-eap-suite-b-192 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat"
    * Wait for "3" seconds
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network
    Given "wpa3-owe" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa3-owe
          wifi-sec.key-mgmt owe
          """
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_device_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network
    Given "wpa3-owe" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Cleanup connection "wpa3-owe"
    Then Execute "nmcli dev wifi connect wpa3-owe"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in transition mode
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          autoconnect no
          ssid wpa3-owe-transition
          wifi-sec.key-mgmt owe
          """
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_connect_as_open
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in open mode
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options "autoconnect no ssid wpa3-owe-transition"
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_device_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in transition mode
    * Cleanup connection "wpa3-owe-transition"
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    Then Execute "nmcli dev wifi connect wpa3-owe-transition"
    And "owe" is visible with command "nmcli -g wifi-sec.key-mgmt con show id wpa3-owe-transition"


    @rhbz1781253
    @ver+=1.25
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_do_not_block_autoconnect
    Scenario: nmcli - simwifi - do not block autoconnect
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add "wifi" connection named "wifi" for device "wlan0" with options
          """
          ssid wpa2-eap
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk Secret123
          """
    * Wait for "1" seconds
    Then Bring up connection "wifi" ignoring error
    And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id wifi"
    * Modify connection "wifi" changing options "802-11-wireless-security.psk secret123"
    * Reboot
    And "GENERAL.STATE:activated" is visible with command "nmcli -f GENERAL.STATE -t connection show id wifi" in "45" seconds


    @simwifi_teardown
    @nmcli_simwifi_teardown
    Scenario: teardown wifi setup
    * Execute "echo 'this is skipped'"


    @ver+=1.16 @rhelver+=8 @fedoraver-=0
    @simwifi_p2p @attach_wpa_supplicant_log @attach_hostapd_log
    @simwifi_p2p_connect
    Scenario: nmcli - simwifi - p2p - connect
    # This is not needed now as unmanaged directly see environment.py simwifi_p2p tag
    # * Execute "nmcli device set wlan1 managed off && sleep 1"
    # Start wpa_supplicant instance for NM unamanged wlan1 interface
    * Run child "wpa_supplicant -i wlan1 -C /tmp/wpa_supplicant_peer_ctrl"
    # Tell wlan1's wpa_supplicant instance to listen and wait a bit
    * Execute "sleep 2 && wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_listen && sleep 5"
    # Create a connection with dynamic mac address
    * Note the output of "wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl status | sed -n 's/p2p_device_address=//p'" as value "wifi_peer"
    * Add "wifi-p2p" connection named "wifi-p2p" for device "p2p-dev-wlan0" with options
        """
        wifi-p2p.peer <noted:wifi_peer>
        """
    # Wait a bit and pass a authentication command to wlan1's wpa_supplicant instance
    * Run child "sleep 5; echo Peer address: $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ); wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_connect $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ) pbc auth go_intent=0"
    Then "activated" is visible with command "nmcli con show wifi-p2p" in "120" seconds


    @ver+=1.16
    @rhelver+=8 @fedoraver-=0
    @simwifi_p2p @attach_wpa_supplicant_log
    @simwifi_p2p_client_connect
    Scenario: nmcli - simwifi - p2p - connect - NM as client
    # This is not needed now as unmanaged directly see environment.py simwifi_p2p tag
    # * Execute "nmcli device set wlan1 managed off && sleep 1"
    # Start wpa_supplicant instance for NM unamanged wlan1 interface
    * Run child "wpa_supplicant -i wlan1 -C /tmp/wpa_supplicant_peer_ctrl"
    # Tell wlan1's wpa_supplicant instance to listen and wait a bit
    * Execute "sleep 2 && wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_listen && sleep 5"
    # Create a connection with dynamic mac address
    * Note the output of "wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl status | sed -n 's/p2p_device_address=//p'" as value "wifi_peer"
    * Add "wifi-p2p" connection named "wifi-p2p" for device "p2p-dev-wlan0" with options
        """
        wifi-p2p.peer <noted:wifi_peer>
        ipv4.never-default yes
        """
    # Wait a bit and pass a authentication command to wlan1's wpa_supplicant instance
    * Run child "sleep 5; echo Peer address: $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ); wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_connect $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ) pbc auth go_intent=14"
    When "p2p-wlan1-0" is visible with command "ls /sys/class/net/" in "10" seconds
    * Execute "ip addr add 192.168.10.1/24 dev p2p-wlan1-0"
    * Run child "dnsmasq -k -i p2p-wlan1-0 --dhcp-range=192.168.10.100,192.168.10.200"
    Then "activated" is visible with command "nmcli con show wifi-p2p" in "120" seconds


    @rhbz2032539
    @rhelver+=8 @fedoraver+=31
    @simwifi_ap @attach_wpa_supplicant_log @attach_hostapd_log
    @simwifi_ap_wpa_psk_method_shared
    Scenario: nmcli - simwifi - AP - connect to NM AP with WPA2 psk security and method shared
    * Add "wifi" connection named "wifi-ap" for device "wlan1" with options
          """
          ssid AP_test
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk Secret123
          mode ap
          ipv4.method shared
          802-11-wireless.channel 1
          802-11-wireless.band bg
          """
    # stability reasons: sometimes bring up fails that eth0 is not matchin interface.
    * Wait for "1" seconds
    * Bring "up" connection "wifi-ap"
    When "AP_test" is visible with command "nmcli dev wifi list"
    * Add "wifi" connection named "wifi-client" for device "wlan0" with options
          """
          ssid AP_test
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk Secret123
          mode infrastructure
          """
    Then Bring "up" connection "wifi-client"


    @rhbz1888051 @rhbz2032539
    @ver+=1.29 @rhelver+=8 @fedoraver+=33
    @simwifi_ap @attach_wpa_supplicant_log @attach_hostapd_log
    @simwifi_ap_in_bridge_wpa_psk_method_manual
    Scenario: nmcli - simwifi - AP - connect to NM AP with WPA2 psk security and method shared
    * Prepare simulated test "testW" device without dhcp
    * Add "bridge" connection named "br0" for device "br0" with options
          """
          connection.autoconnect true
          ipv4.method manual
          ipv4.addresses 192.168.14.1/24
          """
    * Add "ethernet" connection named "br0-slave1" for device "testW"
    * Add "wifi" connection named "br0-slave2" for device "wlan1" with options
          """
          master br0
          ssid AP_test
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk Secret123
          mode ap
          802-11-wireless.channel 1
          802-11-wireless.band bg
          """
    * Bring "up" connection "br0"
    When "AP_test" is visible with command "nmcli dev wifi list --rescan yes" in "30" seconds
    * Add "wifi" connection named "wifi-client" for device "wlan0" with options
          """
          ssid AP_test
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless-security.psk Secret123
          mode infrastructure
          ipv4.method manual
          ipv4.addresses 192.168.14.2/24
          """
    Then Bring "up" connection "wifi-client"


    @rhbz1996918
    @ver+=1.37.3
    @simwifi_ap
    @simwifi_nmcli_radio
    Scenario: nmcli - simwifi - AP - check nmcli radio all status
    * Execute "nmcli radio wifi on"
    Then "enabled" is visible with command "nmcli radio wifi"
    * Execute "nmcli radio wifi off"
    * Execute "modprobe -r mac80211_hwsim"
    * Note the output of "nmcli radio all | tail -n 1 | cut -d ' ' -f 1" as value "wifi-hw_reported"
    # wifi-hw_real gets set in simwifi_ap tag
    Then "disabled" is visible with command "nmcli radio wifi"
    And Check noted values "wifi-hw_reported" and "wifi-hw_real" are the same


    @simwifi_setting_bogus_values
    Scenario: nmcli - simwifi - setting bogus values
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      """
    # Setting invalid band value
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.band x"
    # Setting SSID over 32 bytes
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.ssid hsdkfjhsdkjfhskjdhfkdsjhfkjshkjagdgdsfsjkdhf"


    @rhbz1002553
    @simwifi_set_mac_address
    Scenario: simwifi - set mac adress
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      """
    # Set matching address
    * Note MAC address output for device "wlan0" via ethtool
    * Modify connection "wifi0" property "802-11-wireless.mac-address" to noted value
    * Bring up connection "wifi0"
    Then "open" is visible with command "iw dev wlan0 link"
    And "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    # Valid inputs
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '00-11-22-33-44-55'"
    # Invalid inputs
    * Modify connection "wifi0" changing options "802-11-wireless.mac-address '00:11:22:33:44:55'"
    Then "No suitable device found for this connection" is visible with command "nmcli connection up wifi0"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '-1'"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '4294967297'"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address 'ooops'"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '00:13:DG:7F:54:CF'"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '00:13:DA:7F:54'"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.mac-address '00:13:DA:7F:54:CF:AA'"


    @simwifi_mac_address_blacklist
    Scenario: simwifi - mac adress blacklist
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      """
    Then Note MAC address output for device "wlan0" via ethtool
    * Open editor for connection "wifi0"
    * Set a property named "802-11-wireless.mac-address-blacklist" to "noted-value" in editor
    * No error appeared in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "Error" is visible with command "nmcli connection up wifi0"
    Then "\*\s+open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @simwifi
    @simwifi_wpa2_psk_unmatching_proto
    Scenario: nmcli - wifi-sec - unmatching proto
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid wpa2-eap
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.proto wpa
      """
    * Start following journal
    Then "Error" is visible with command "nmcli connection up wifi0"
    Then Look for "added 'proto' value 'WPA'" in journal
    Then "\*\s+wpa2-eap" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @simwifi_set_channel
    Scenario: simwifi - set channel < 7 (bz 999999)
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      802-11-wireless.band bg
      802-11-wireless.channel 1
      """
    # Valid inputs
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 2"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 3"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 4"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 5"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 6"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 13"
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.channel 14"
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.channel 15"


    @simwifi_set_nonexistent_bssid
    Scenario: nmcli - simwifi - set non-existent bssid
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      802-11-wireless.bssid 00:11:22:33:44:55
      """
    Then "Error" is visible with command "nmcli connection up wifi0"
    Then "\*\s+open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"
    # Setting invalid bssid vlaues
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.bssid dough"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.bssid 00:13:DG:7F:54:CF"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.bssid 00:13:DA:7F:54"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.bssid 00:13:DA:7F:54:CF:AA"


    @simwifi_set_txpower
    Scenario: nmcli - wifi - set bogus txpower
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      """
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.tx-power -1"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.tx-power valderon"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.tx-power 9999999999"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.tx-power 5"

    
    @simwifi_set_rate
    Scenario: nmcli - wifi - set bogus rate
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      """
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.rate -5"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.rate krobot"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.rate 9999999999"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.rate 5500"



    @rhbz1702203
    @ver+=1.18
    @simwifi_wifisec_validity
    Scenario: nmcli - simwifi - set wireless security values
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      autoconnect off
      ssid open
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk 'valid size and input for ascii psk @#$%^&*()[]{}'
      """
    # Valid inputs
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless-security.psk valid123"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless-security.psk maximumasciiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless-security.psk 1234A678B01F1234A678B01F1234A678B01F1234A678B01F1234A678B01F123B"
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.psk short12" 
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.psk G234A678B01F1234A678B01F1234A678B01F1234A678B01F1234A678B01F123B"


    @simwifi_set_hidden_property_values
    Scenario: nmcli - simwifi - set hidden property values
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      ssid open
      autoconnect off
      802-11-wireless.hidden true
      """
    # Valid inputs
    Then "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.hidden yes"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.hidden on"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.hidden false"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.hidden no"
    And "Error" is not visible with command "nmcli connection modify wifi0 802-11-wireless.hidden off"
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.hidden -1"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.hidden valderon"
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless.hidden 999999999999"


    @simwifi_wifisec_keymgmt_wrong_values
    Scenario: nmcli - simwifi - set wrong keymgmt values
    * Add "wifi" connection named "wifi0" for device "wlan0" with options
      """
      ssid open
      autoconnect off
      """
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.key-mgmt ieee8021x123"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.key-mgmt 'ieee8021x sth'"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.key-mgmt -1"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.key-mgmt 0"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.key-mgmt 999999999999999999999"    


    @simwifi_wifisec_authalg_wrong_values
    Scenario: nmcli - simwifi - set wrong authalg & leap with from keymgmt
    * Add insecure "wifi" connection named "wifi0" for device "wlan0" with options
      """
      ssid open
      autoconnect off
      802-11-wireless-security.key-mgmt none
      """
    # Invalid inputs
    Then "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.auth-alg 0"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.auth-alg null"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.auth-alg 999999999999999999"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.auth-alg 'open shared'"    
    And "Error" is visible with command "nmcli connection modify wifi0 802-11-wireless-security.auth-alg leap"    


    @simwifi_describe
    Scenario: simwifi - describe
    * Open editor for a type "wifi"
    Then Check "ssid|mode|band|channel|bssid|rate|tx-power|mac-address|cloned-mac-address|mac-address-blacklist|mtu|seen-bssids|hidden" are present in describe output for object "802-11-wireless"
    Then Check "\[ssid\]" are present in describe output for object "802-11-wireless.ssid"
    Then Check "\[mode\]" are present in describe output for object "802-11-wireless.mode"
    Then Check "\[band\]" are present in describe output for object "802-11-wireless.band"
    Then Check "\[channel\]" are present in describe output for object "802-11-wireless.channel"
    Then Check "\[bssid\]" are present in describe output for object "802-11-wireless.bssid"
    Then Check "\[rate\]" are present in describe output for object "802-11-wireless.rate"
    Then Check "\[tx-power\]" are present in describe output for object "802-11-wireless.tx-power"
    Then Check "\[mac-address\]" are present in describe output for object "802-11-wireless.mac-address"
    Then Check "\[cloned-mac-address\]" are present in describe output for object "802-11-wireless.cloned-mac-address"
    Then Check "\[mac-address-blacklist\]" are present in describe output for object "802-11-wireless.mac-address-blacklist"
    Then Check "\[mtu\]" are present in describe output for object "802-11-wireless.mtu"
    Then Check "\[seen-bssids\]" are present in describe output for object "802-11-wireless.seen-bssids"
    Then Check "\[hidden\]" are present in describe output for object "802-11-wireless.hidden"


    @rhelver-=8
    @simwifi_wifisec_describe
    Scenario: simwifi-sec - describe
    * Open editor for a type "wifi"
    Then Check "key-mgmt|wep-tx-keyidx|auth-alg|proto|pairwise|group|leap-username|wep-key0|wep-key1|wep-key2|wep-key3|wep-key-flags|wep-key-type|psk|psk-flags|leap-password|leap-password-flags" are present in describe output for object "802-11-wireless-security"
    Then Check "\[key-mgmt\]" are present in describe output for object "802-11-wireless-security.key-mgmt"
    Then Check "\[wep-tx-keyidx\]" are present in describe output for object "802-11-wireless-security.wep-tx-keyidx"
    Then Check "\[auth-alg\]" are present in describe output for object "802-11-wireless-security.auth-alg"
    Then Check "\[proto\]" are present in describe output for object "802-11-wireless-security.proto"
    Then Check "\[pairwise\]" are present in describe output for object "802-11-wireless-security.pairwise"
    Then Check "\[group\]" are present in describe output for object "802-11-wireless-security.group"
    Then Check "\[leap-username\]" are present in describe output for object "802-11-wireless-security.leap-username"
    Then Check "\[wep-key0\]" are present in describe output for object "802-11-wireless-security.wep-key0"
    Then Check "\[wep-key1\]" are present in describe output for object "802-11-wireless-security.wep-key1"
    Then Check "\[wep-key2\]" are present in describe output for object "802-11-wireless-security.wep-key2"
    Then Check "\[wep-key3\]" are present in describe output for object "802-11-wireless-security.wep-key3"
    Then Check "\[wep-key-flags\]" are present in describe output for object "802-11-wireless-security.wep-key-flags"
    Then Check "\[wep-key-type\]" are present in describe output for object "802-11-wireless-security.wep-key-type"
    Then Check "\[psk\]" are present in describe output for object "802-11-wireless-security.psk"
    Then Check "\[psk-flags\]" are present in describe output for object "802-11-wireless-security.psk-flags"
    Then Check "\[leap-password\]" are present in describe output for object "802-11-wireless-security.leap-password"
    Then Check "\[leap-password-flags\]" are present in describe output for object "802-11-wireless-security.leap-password-flags"


    @rhelver+=9
    @simwifi_wifisec_describe
    Scenario: simwifi- wifisec - describe
    * Open editor for a type "wifi"
    Then Check "key-mgmt|auth-alg|proto|pairwise|group|leap-username|psk|psk-flags|leap-password|leap-password-flags" are present in describe output for object "802-11-wireless-security"
    Then Check "\[key-mgmt\]" are present in describe output for object "802-11-wireless-security.key-mgmt"
    Then Check "\[auth-alg\]" are present in describe output for object "802-11-wireless-security.auth-alg"
    Then Check "\[proto\]" are present in describe output for object "802-11-wireless-security.proto"
    Then Check "\[pairwise\]" are present in describe output for object "802-11-wireless-security.pairwise"
    Then Check "\[group\]" are present in describe output for object "802-11-wireless-security.group"
    Then Check "\[leap-username\]" are present in describe output for object "802-11-wireless-security.leap-username"
    Then Check "\[psk\]" are present in describe output for object "802-11-wireless-security.psk"
    Then Check "\[psk-flags\]" are present in describe output for object "802-11-wireless-security.psk-flags"
    Then Check "\[leap-password\]" are present in describe output for object "802-11-wireless-security.leap-password"
    Then Check "\[leap-password-flags\]" are present in describe output for object "802-11-wireless-security.leap-password-flags"


    @rhbz1182567
    @simwifi_dbus_invalid_cert_input
    Scenario: nmcli - wifi - dbus invalid certificate input
    Then "Connection.InvalidProperty" is visible with command "/usr/bin/python contrib/dbus/dbus-set-wifi-bad-cert.py"


    @simwifi
    @simwifi_remove_connection_while_up
    Scenario: nmcli - wifi - remove connection while up
    * Add "wifi" connection named "wifi0" for device "wlan0" with options "autoconnect off ssid open"
    * Bring up connection "wifi0"
    When "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    And "open" is visible with command "iw dev wlan0 link"
    * Delete connection "wifi0"
    Then "open" is not visible with command "iw dev wlan0 link"


    @simwifi
    @simwifi_set_existing_bssid
    Scenario: nmcli - wifi - set existing bssid
    * Add "wifi" connection named "open" for device "wlan0" with options "autoconnect off ssid open"
    * Bring up connection "open"
    * Bring down connection "open"
    * Open editor for connection "open"
    * Note the "802-11-wireless.seen-bssids" property from editor print output
    * Set a property named "802-11-wireless.bssid" to "noted-value" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "open"
    Then "open" is visible with command "iw dev wlan0 link"
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @ver+=1.40
    @simwifi
    @simwifi_novice_mode_add_connection_ip_setup
    Scenario: simwifi - add connection in novice (nmcli -a) mode specifying IP setup
    * Cleanup connection "wifi"
    * Open interactive connection addition mode
    * Expect "Connection type"
    * Submit "wifi"
    * Expect "SSID"
    * Submit "open"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "no"
    * Agree to add IPv4 configuration in editor
    * Submit "10.1.1.5"
    * No error appeared in editor
    * Submit "10.1.1.6/24"
    * No error appeared in editor
    * Submit "<enter>"
    * Expect "IPv4 gateway"
    * Submit "10.1.1.1"
    * Agree to add IPv6 configuration in editor
    * Submit "fe80::215:ff:fe93:ffff/128"
    * No error appeared in editor
    * Submit "<enter>"
    * Expect "IPv6 gateway"
    * Submit "::1"
    * Dismiss Proxy configuration in editor
    * Expect "Connection.*successfully added"
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "open" is visible with command "iw dev wlan0 link" in "30" seconds
    Then "10.1.1.6.*fe80::215:ff:fe93:ffff" is visible with command "ip a" in "30" seconds
    Then "10.1.1.5" is visible with command "ip a" in "30" seconds


    @ver+=1.40
    @simwifi
    @simwifi_novice_mode_add_connection_bogus_ip
    Scenario: simwifi - add connection in novice (nmcli -a) mode with bogus IP
    * Open interactive connection addition mode
    * Expect "Connection type"
    * Submit "wifi"
    * Expect "SSID"
    * Submit "open"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "no"
    * Agree to add IPv4 configuration in editor
    * Submit "280.1.1.5"
    * Error appeared in editor
    * Submit "val.der.oni.uma"
    * Error appeared in editor
    * Submit "-1.1.-1.5"
    * Error appeared in editor
    * Submit "<enter>"
    * Submit "<enter>"
    * Agree to add IPv6 configuration in editor
    * Submit "feG0::215:ff:fe93:ffff"
    * Error appeared in editor
    * Submit "vald::ron:bogu:sva:vald"
    Then Error appeared in editor


    @ver+=1.40
    @simwifi
    @simwifi_novice_mode_add_default_connection
    Scenario: simwifi - add default connection in novice (nmcli -a) mode
    * Cleanup connection "wifi"
    * Open interactive connection addition mode for a type "wifi"
    * Expect "SSID"
    * Submit "open"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "no"
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "open" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.40
    @simwifi
    @simwifi_novice_mode_add_connection_with_options
    Scenario: simwifi - add connection in novice (nmcli -a) mode specifying options
    * Cleanup connection "wifi"
    * Open interactive connection addition mode for a type "wifi"
    * Note MAC address output for device "wlan0" via ethtool
    * Expect "SSID"
    * Submit "open"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "yes"
    * Expect "Wi-Fi mode"
    * Submit "infrastructure"
    * Expect "MAC"
    * Submit "noted-value"
    * Expect "Cloned MAC"
    * Submit "noted-value"
    * Expect "MTU"
    * Submit "1280"
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "open" is visible with command "iw dev wlan0 link" in "30" seconds
