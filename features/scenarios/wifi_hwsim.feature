Feature: nmcli - wifi

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.9.1 @fedoraver+=31
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_open
    @simwifi_open_connect
    Scenario: nmcli - simwifi - connect to open network
    Given "open" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name open autoconnect no ssid open"
    * Bring "up" connection "open"
    And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id wifi"
    Then "open" is visible with command "iw dev wlan0 link" in "15" seconds
    Then "\*\s+open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @ver+=1.9.1 @fedoraver+=31 @rhelver-=8
    @simwifi @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_pskwep
    @simwifi_wep_ask_passwd
    Scenario: nmcli - wifi - connect WEP network asking for password
    Given "wep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Spawn "nmcli -a device wifi connect wep" command
    * Expect "Password:"
    * Submit "abcde"
    Then "\*\s+wep" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "45" seconds
    Then "wep" is visible with command "iw dev wlan0 link"


    @ver+=1.10 @fedoraver+=31 @rhelver-=8
    @simwifi @simwifi_dynwep @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_tls
    Scenario: nmcli - simwifi - connect to WEP TLS
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid dynwep"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt ieee8021x 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31 @rhelver-=8
    @need_legacy_crypto
    @simwifi @simwifi_dynwep @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_ttls_mschapv2_eap
    Scenario: nmcli - simwifi - connect to WEP TTLS MSCHAPv2 + EAP
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid dynwep 802-11-wireless-security.key-mgmt ieee8021x 802-1x.eap ttls 802-1x.identity TESTERS\\test_mschapv2 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-autheap mschapv2 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31 @rhelver-=8
    @simwifi @simwifi_dynwep @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wep_peap_gtc
    Scenario: nmcli - simwifi - connect to WEP PEAP GTC
    Given "dynwep" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid dynwep 802-11-wireless-security.key-mgmt ieee8021x 802-1x.eap peap 802-1x.identity test_gtc 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth gtc 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.9.1 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_wpa2
    @simwifi_wpa2psk_no_profile
    Scenario: nmcli - simwifi - connect to WPA2 PSK network without profile
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Execute "nmcli device wifi connect wpa2-eap password secret123"
    * Execute "sleep 1"
    * Bring "up" connection "wpa2-eap"
    Then "wpa2-eap" is visible with command "iw dev wlan0 link" in "15" seconds
    Then "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_wpa2psk_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wpa2-eap autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk secret123"
    * Execute "sleep 1"
    * Bring up connection "wpa2-eap"
    Then "wpa2-eap" is visible with command "iw dev wlan0 link" in "3" seconds
    Then "\*\s+wpa2-eap" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @ver+=1.33 @rhelver+=8
    @simwifi @simwifi_wpa2 @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_saved_pw
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11 - saved PIN
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient' 802-1x.private-key-password 1234"
    * Execute "sleep 3"
    Then Bring "up" connection "wifi"


    @ver+=1.33 @rhelver+=8
    @simwifi @simwifi_wpa2 @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_pwfile
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient'"
    * Execute "sleep 3"
    * Execute "nmcli con up wifi passwd-file /tmp/pkcs11_passwd-file"
    Then "wlan0:connected:wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8
    @simwifi @simwifi_wpa2 @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_nmcli_ask
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient' 802-1x.private-key-password-flags 2"
    * Execute "sleep 3"
    * Spawn "nmcli -a con up wifi" command
    * Expect "802-1x.identity"
    * Enter in editor
    * Expect "802-1x.private-key-password"
    * Send "1234" in editor
    * Enter in editor
    Then "wlan0:connected:wifi" is visible with command "nmcli -t -f DEVICE,STATE,CONNECTION device" in "20" seconds


    @ver+=1.33 @rhelver+=8
    @simwifi @simwifi_wpa2 @pkcs11 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_pkcs11_pw_in_uri_flag_nr
    Scenario: nmcli - simwifi - connect to TLS - PKCS#11
    # these settings are hacky and may stop working when this is resolved: https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/792
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert 'pkcs11:token=nmci;object=nmclient' 802-1x.client-cert-password-flags 4 802-1x.private-key 'pkcs11:token=nmci;object=nmclient?pin-value=1234' 802-1x.private-key-password-flags 4"
    * Execute "sleep 3"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls
    Scenario: nmcli - simwifi - connect to TLS
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat"
    * Execute "sleep 3"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_bad_private_key_password
    Scenario: nmcli - simwifi - connect to TLS - bad private key password
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat123456"
    * Execute "sleep 3"
    Then Bring up connection "wifi" ignoring error
     And "GENERAL.STATE:activated" is not visible with command "nmcli -f GENERAL.STATE -t connection show id wifi"


    @rhbz1433536
    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_no_private_key_password
    Scenario: nmcli - simwifi - connect to TLS - no private key password
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap"
    * Execute "nmcli con modify wifi 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.pem 802-1x.private-key-password-flags 4"
    * Execute "sleep 3"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_gtc
    Scenario: nmcli - simwifi - connect to PEAP GTC
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity test_gtc 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth gtc 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_md5
    Scenario: nmcli - simwifi - connect to PEAP MD5
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity test_md5 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth md5 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @need_legacy_crypto
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_peap_mschapv2
    Scenario: nmcli - simwifi - connect to PEAP MSCHAPv2
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap peap 802-1x.identity TESTERS\\test_mschapv2 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth mschapv2 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_pap
    Scenario: nmcli - simwifi - connect to TTLS PAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_ttls 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth pap 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_chap
    Scenario: nmcli - simwifi - connect to TTLS CHAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_ttls 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth chap 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @need_legacy_crypto
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschap
    Scenario: nmcli - simwifi - connect to TTLS MSCHAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_ttls 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth mschap 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @need_legacy_crypto
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschapv2
    Scenario: nmcli - simwifi - connect to TTLS MSCHAPv2
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_ttls 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-auth mschapv2 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @need_legacy_crypto
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_mschapv2_eap
    Scenario: nmcli - simwifi - connect to TTLS MSCHAPv2 + EAP
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity TESTERS\\test_mschapv2 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-autheap mschapv2 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_md5
    Scenario: nmcli - simwifi - connect to TTLS MD5
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_md5 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-autheap md5 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_ttls_gtc
    Scenario: nmcli - simwifi - connect to TTLS GTC
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.identity test_gtc 802-1x.anonymous-identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.phase2-autheap gtc 802-1x.password password"
    * Execute "sleep 1"
    Then Bring "up" connection "wifi"


    @rhbz1520398
    @ver+=1.10 @fedoraver+=31
    @simwifi @simwifi_wpa2
    @nmclient_get_wireless_hw_property
    Scenario: nmclient - property - get wireless hardware property
    Then "True|False" is visible with command "/usr/bin/python contrib/gi/nmclient_get_property.py wireless-hardware-enabled"


    @rhbz1626391
    @ver+=1.12 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_wpa2
    @wifi_dbus_bitrate_property_name
    Scenario: dbus - property name for Device.Wireless.Bitrate
    Then "Bitrate" is visible with command "for dev_id in $(busctl tree org.freedesktop.NetworkManager | grep Devices/ | grep -o '[0-9]*$'); do busctl introspect org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Devices/$dev_id | grep Bitrate; done"


    @rhbz1730177
    @ver+=1.22 @rhelver+=8.2 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_wpa3
    @simwifi_wpa3_personal
    Scenario: nmcli - simwifi - connect to WPA3 personal wifi
    Given "wpa3-psk" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then "wpa3-psk:WPA3" is visible with command "nmcli -t -f ssid,security device wifi list"
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-psk 802-11-wireless-security.key-mgmt sae 802-11-wireless-security.psk secret123"
    Then Bring "up" connection "wifi"


    @rhbz2019396
    @ver+=1.35.5 @rhelver+=8.6 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_wpa3
    @simwifi_wpa3_h2e
    Scenario: nmcli - simwifi - connect to WPA3 H2E
    Given "wpa3-h2e" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then "wpa3-h2e:WPA3" is visible with command "nmcli -t -f ssid,security device wifi list"
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-h2e 802-11-wireless-security.key-mgmt sae 802-11-wireless-security.psk secret123"
    Then Bring "up" connection "wifi"


    @rhbz1730177
    @ver+=1.22 @rhelver+=8.2 @fedoraver+=31
    @attach_hostapd_log @attach_wpa_supplicant_log @simwifi_wpa3
    @simwifi_wpa3_personal_device_connect_ask
    Scenario: nmcli - simwifi - connect to WPA3 personal wifi with device command
    Given "wpa3-psk" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then Execute "echo secret123 | nmcli dev wifi connect wpa3-psk --ask"


    @ver+=1.29 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @simwifi_wpa3_eap @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_tls_wpa3
    Scenario: nmcli - simwifi - connect to TLS
    Given "wpa3-eap" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-eap"
    * Modify connection "wifi" changing options "802-11-wireless-security.key-mgmt wpa-eap-suite-b-192 802-1x.eap tls 802-1x.identity test 802-1x.ca-cert /tmp/certs/test_user.ca.pem 802-1x.client-cert /tmp/certs/test_user.cert.pem 802-1x.private-key /tmp/certs/test_user.key.enc.pem 802-1x.private-key-password redhat"
    * Execute "sleep 3"
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network
    Given "wpa3-owe" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-owe wifi-sec.key-mgmt owe"
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_device_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network
    Given "wpa3-owe" is visible with command "nmcli -f SSID device wifi list" in "60" seconds
    Then Execute "nmcli dev wifi connect wpa3-owe"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in transition mode
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-owe-transition wifi-sec.key-mgmt owe"
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_connect_as_open
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in open mode
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi autoconnect no ssid wpa3-owe-transition"
    Then Bring "up" connection "wifi"


    @ver+=1.26 @rhelver+=8 @fedoraver-=0
    @simwifi @simwifi_wpa3 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_owe_transition_device_connect
    Scenario: nmcli - simwifi - connect to Enhanced Open (OWE) network in transition mode
    Given "wpa3-owe-transition:OWE" is visible with command "nmcli -t -f SSID,SECURITY device wifi list" in "60" seconds
    Then Execute "nmcli dev wifi connect wpa3-owe-transition"
    And "owe" is visible with command "nmcli -g wifi-sec.key-mgmt con show id wpa3-owe-transition"


    @rhbz1781253
    @ver+=1.25
    @simwifi @simwifi_wpa2 @attach_hostapd_log @attach_wpa_supplicant_log
    @simwifi_do_not_block_autoconnect
    Scenario: nmcli - simwifi - do not block autoconnect
    Given "wpa2-eap" is visible with command "nmcli -f SSID device wifi list" in "90" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi ssid wpa2-eap 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk Secret123"
    * Execute "sleep 1"
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
    * Execute "nmcli con add type wifi-p2p ifname p2p-dev-wlan0 wifi-p2p.peer $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl status | sed -n 's/p2p_device_address=//p' ) con-name wifi-p2p"
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
    * Execute "nmcli con add type wifi-p2p ifname p2p-dev-wlan0 wifi-p2p.peer $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl status | sed -n 's/p2p_device_address=//p' ) ipv4.never-default yes con-name wifi-p2p"
    # Wait a bit and pass a authentication command to wlan1's wpa_supplicant instance
    * Run child "sleep 5; echo Peer address: $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ); wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_connect $( wpa_cli -i wlan1 -p /tmp/wpa_supplicant_peer_ctrl p2p_peers ) pbc auth go_intent=14"
    When "p2p-wlan1-0" is visible with command "ls /sys/class/net/" in "10" seconds
    * Execute "ip addr add 192.168.10.1/24 dev p2p-wlan1-0"
    * Run child "dnsmasq -k -i p2p-wlan1-0 --dhcp-range=192.168.10.100,192.168.10.200"
    Then "activated" is visible with command "nmcli con show wifi-p2p" in "120" seconds


    @rhbz2032539
    @rhelver-=8 @fedoraver+=31
    @simwifi_ap @attach_wpa_supplicant_log @attach_hostapd_log
    @simwifi_ap_wpa_psk_method_shared
    Scenario: nmcli - simwifi - AP - connect to NM AP with WPA2 psk security and method shared
    * Add a new connection of type "wifi" and options "ifname wlan1 con-name wifi-ap ssid AP_test 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk Secret123 mode ap ipv4.method shared"
    * Bring "up" connection "wifi-ap"
    When "AP_test" is visible with command "nmcli dev wifi list"
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi-client ssid AP_test 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk Secret123 mode infrastructure"
    Then Bring "up" connection "wifi-client"


    @rhbz1888051 @rhbz2032539
    @ver+=1.29 @rhelver-=8 @fedoraver+=33
    @simwifi_ap @teardown_testveth @attach_wpa_supplicant_log @attach_hostapd_log
    @simwifi_ap_in_bridge_wpa_psk_method_manual
    Scenario: nmcli - simwifi - AP - connect to NM AP with WPA2 psk security and method shared
    * Prepare simulated test "testW" device without dhcp
    * Add a new connection of type "bridge" and options "con-name br0 ifname br0 connection.autoconnect true ipv4.method manual ipv4.addresses 192.168.14.1/24"
    * Add a new connection of type "ethernet" and options "con-name br0-slave1 ifname testW"
    * Add a new connection of type "wifi" and options "con-name br0-slave2 master br0 ifname wlan1 ssid AP_test 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk Secret123 mode ap"
    * Bring "up" connection "br0"
    When "AP_test" is visible with command "nmcli dev wifi list --rescan yes" in "30" seconds
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name wifi-client ssid AP_test 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk Secret123 mode infrastructure ipv4.method manual ipv4.addresses 192.168.14.2/24"
    Then Bring "up" connection "wifi-client"
