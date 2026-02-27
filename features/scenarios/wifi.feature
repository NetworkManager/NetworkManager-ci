Feature: nmcli - wifi

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @attach_wpa_supplicant_log
    @nmcli_wifi_infrastructure_mode_setting
    Scenario: nmcli - wifi - infrastructure mode setting
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless.mode infrastructure
      """
    * Bring "up" connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    # Not working
    # @xfail
    # @attach_wpa_supplicant_log
    # @nmcli_wifi_adhoc_wpa2_network
    # Scenario: nmcli - wifi - adhoc wpa2 network
    # Given Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites
    # * Add "wifi" connection named "qe-adhoc" for device "wlan0" with options
    #   """
    #   autoconnect off
    #   ssid qe-adhoc
    #   802-11-wireless.mode adhoc
    #   802-11-wireless-security.key-mgmt wpa-psk
    #   802-11-wireless-security.psk "over the river and through the woods"
    #   ipv4.method shared
    #   ipv6.method auto
    #   """
    # * Execute "nmcli connection up qe-adhoc"
    # Then "qe-adhoc" is visible with command "iw dev  wlan0 info" in "30" seconds
    # Then "type IBSS" is visible with command "iw dev wlan0 info" in "30" seconds


    @attach_wpa_supplicant_log
    @nmcli_wifi_ap
    Scenario: nmcli - wifi - ap network
    Given Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites
    * Add "wifi" connection named "qe-ap" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-ap
      802-11-wireless.mode ap
      802-11-wireless.band bg
      802-11-wireless.channel 1
      ipv4.method shared
      """
    * Execute "nmcli connection up qe-ap"
    Then "qe-ap" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type AP" is visible with command "iw dev wlan0 info" in "30" seconds


    @ver+=1.37.3
    @attach_wpa_supplicant_log
    @nmcli_wifi_disable_radio
    Scenario: nmcli - wifi - disable radio
    Given  "enabled" is visible with command "nmcli radio wifi"
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      """"
    * Bring "up" connection "qe-wpa2-psk"
    When "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    * Execute "nmcli radio wifi off"
    Then "disabled" is visible with command "nmcli radio wifi"
    Then "qe-wpa2-psk" is not visible with command "iw dev wlan0 link"
    Then "wlan0\s+wifi\s+unavailable" is visible with command "nmcli device"
    * Execute "nmcli radio wifi on"


    @ver+=1.37.3
    @attach_wpa_supplicant_log
    @nmcli_wifi_enable_radio
    Scenario: nmcli - wifi - enable radio
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      """
    * Execute "nmcli radio wifi off"
    When "disabled" is visible with command "nmcli radio wifi"
    And "qe-wpa2-psk" is not visible with command "iw dev wlan0 link"
    * "wlan0\s+wifi\s+unavailable" is visible with command "nmcli device"
    * Execute "nmcli radio wifi on"
    Then "enabled" is visible with command "nmcli radio wifi"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link" in "60" seconds
    Then "wlan0\s+wifi\s+connected" is visible with command "nmcli device" in "15" seconds


    @attach_wpa_supplicant_log
    @nmcli_wifi_mac_spoofing
    Scenario: nmcli - wifi - mac spoofing (if hw supported)
    # There might be some delay between tests
    Given "qe-wpa2-psk" is visible with command "nmcli device wifi list --rescan yes" in "20" seconds
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless.cloned-mac-address f0:de:aa:fb:bb:cc
      """
    * Bring "up" connection "qe-wpa2-psk"
    Then "addr f0:de:aa:fb:bb:cc" is visible with command "iw dev wlan0 info"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_set_mtu
    Scenario: nmcli - wifi - set mtu
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless.mtu 64
      """
    * Bring "up" connection "qe-wpa2-psk"
    Then "64" is visible with command "nmcli -g 802-11-wireless.mtu connection show qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @rhbz1094298
    @attach_wpa_supplicant_log
    @nmcli_wifi_seen_bssids
    Scenario: nmcli - wifi - seen bssids
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      """
    * Bring "up" connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Note the "802-11-wireless.seen-bssids" property from editor print output
    Then Noted value contains "([0-9A-F]{2}[:-]){5}([0-9A-F]{2})"
    * Quit editor


    @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2hidden_psk
    Scenario: nmcli - wifi - set and connect to a hidden network
    * Add "wifi" connection named "qe-hidden-wpa2-psk" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-hidden-wpa2-psk
          802-11-wireless-security.key-mgmt wpa-psk
          802-11-wireless.hidden yes
          802-11-wireless-security.proto rsn
          802-11-wireless.cloned-mac-address random
          connection.auth-retries 20
          802-11-wireless-security.psk 6ubDLTiFr6jDSAxW08GdKU0s5Prh1c5G8CWeYpXHgXeYmhhMyDX8vMMWwLhx8Sl
          """
    * Bring "up" connection "qe-hidden-wpa2-psk"
    Then "qe-hidden-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-hidden-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @may_fail
    @nmcli_wifi_wpa2_psk_2_4g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.proto rsn
      802-11-wireless.band bg
      """
    * Bring "up" connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2_psk_5g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.proto rsn
      802-11-wireless.band a
      """
    * Bring "up" connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @may_fail
    @nmcli_wifi_wpa3_psk_2_4g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    * Add "wifi" connection named "qe-wpa3-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa3-psk
      802-11-wireless-security.key-mgmt sae
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless.band bg

      """
    * Bring "up" connection "qe-wpa3-psk"
    Then "qe-wpa3-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"



    @attach_wpa_supplicant_log
    @nmcli_wifi_wpa3_psk_5g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    * Add "wifi" connection named "qe-wpa3-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa3-psk
      802-11-wireless-security.key-mgmt sae
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless.band a
      """
    * Bring "up" connection "qe-wpa3-psk"
    Then "qe-wpa3-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2_peap_mschapv2
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PEAP profile
    * Add "wifi" connection named "qe-wpa2-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa2-enterprise
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap peap
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.phase2-autheap mschapv2
          802-1x.password testing123
          """
    * Bring "up" connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "inet 1" is visible with command "ip a s wlan0" in "20" seconds


    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2_tls_2_4g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-TLS profile
    # Wireless device does not support wpa3 enterprise
    * Skip if next step fails:
    * "qe-wpa2-enterprise" is visible with command "nmcli device wifi list |grep -e qe-wpa[2-3]-enterprise |grep -v 48'"
    * Add "wifi" connection named "qe-wpa2-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa2-enterprise
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap tls
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.client-cert file:///tmp/certs/client.pem
          802-1x.private-key-password 12345testing
          802-1x.private-key file:///tmp/certs/client.pem
          802-11-wireless.band bg
          """
    * Bring "up" connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2_tls_5g
    Scenario: nmcli - wifi-sec - configure and connect WPA2-TLS profile
    * Add "wifi" connection named "qe-wpa2-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa2-enterprise
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap tls
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.client-cert file:///tmp/certs/client.pem
          802-1x.private-key-password 12345testing
          802-1x.private-key file:///tmp/certs/client.pem
          802-11-wireless.band a
          """
    * Bring "up" connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_wpa2_ttls_mschapv2
    Scenario: nmcli - wifi-sec - configure and connect WPA2-TTLS profile
    * Add "wifi" connection named "qe-wpa2-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa2-enterprise
          802-11-wireless-security.key-mgmt wpa-eap
          802-1x.eap ttls
          802-1x.phase2-auth mschapv2
          802-1x.identity "Bill Smith"
          802-1x.password "testing123"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          """
    * Bring "up" connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa3_peap_mschapv2
    Scenario: nmcli - wifi-sec - configure and connect WPA3-PEAP profile
    # Wireless device does not support wpa3 enterprise
    * Skip if next step fails:
    * "GCMP-256" is visible with command "iw list |grep -A 20 'Supported Ciphers'"
    * Add "wifi" connection named "qe-wpa3-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa3-enterprise
          802-11-wireless-security.key-mgmt wpa-eap-suite-b-192
          802-1x.eap peap
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.phase2-autheap mschapv2
          802-1x.password testing123
          802-11-wireless.band a
          """
    * Bring "up" connection "qe-wpa3-enterprise"
    Then "qe-wpa3-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "inet 1" is visible with command "ip a s wlan0" in "20" seconds


    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa3_tls_2_4g
    Scenario: nmcli - wifi-sec - configure and connect WPA3-TLS profile
    # Wireless device does not support wpa3 enterprise
    * Skip if next step fails:
    * "GCMP-256" is visible with command "iw list |grep -A 20 'Supported Ciphers'"
    * Add "wifi" connection named "qe-wpa3-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa3-enterprise
          802-11-wireless-security.key-mgmt wpa-eap-suite-b-192
          802-1x.eap tls
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.client-cert file:///tmp/certs/client.pem
          802-1x.private-key-password 12345testing
          802-1x.private-key file:///tmp/certs/client.pem
          802-11-wireless.band bg
          """
    * Bring "up" connection "qe-wpa3-enterprise"
    Then "qe-wpa3-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"



    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_wpa3_tls_5g
    Scenario: nmcli - wifi-sec - configure and connect WPA3-TLS profile
    # Wireless device does not support wpa3 enterprise
    * Skip if next step fails:
    * "GCMP-256" is visible with command "iw list |grep -A 20 'Supported Ciphers'"
    * Add "wifi" connection named "qe-wpa3-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa3-enterprise
          802-11-wireless-security.key-mgmt wpa-eap-suite-b-192
          802-1x.eap tls
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.client-cert file:///tmp/certs/client.pem
          802-1x.private-key-password 12345testing
          802-1x.private-key file:///tmp/certs/client.pem
          802-11-wireless.band a
          """
    * Bring "up" connection "qe-wpa3-enterprise"
    Then "qe-wpa3-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_wpa3_ttls_mschapv2
    Scenario: nmcli - wifi-sec - configure and connect WPA3-TTLS profile
    # Wireless device does not support wpa3 enterprise
    * Skip if next step fails:
    * "GCMP-256" is visible with command "iw list |grep -A 20 'Supported Ciphers'"
    * Add "wifi" connection named "qe-wpa3-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa3-enterprise
          802-11-wireless-security.key-mgmt wpa-eap-suite-b-192
          802-1x.eap ttls
          802-1x.phase2-auth mschapv2
          802-1x.identity "Bill Smith"
          802-1x.password "testing123"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-11-wireless.channel 48
          802-11-wireless.band a
          """
    * Bring "up" connection "qe-wpa3-enterprise"
    Then "qe-wpa3-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_pairwise_ccmp
    Scenario: nmcli - wifi-sec - pairwise - ccmp
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.pairwise ccmp
      """
    * Start following journal
    * Bring "up" connection "qe-wpa2-psk"
    Then "added 'pairwise' value 'CCMP'" is visible in journal
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_unmatching_pairwise
    Scenario: nmcli - wifi-sec - unmatching pairwise
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.pairwise tkip
      """
    * Start following journal
    Then "Error" is visible with command "nmcli connection up qe-wpa2-psk ifname wlan0"
    Then "added 'pairwise' value 'TKIP'" is visible in journal
    Then "\*\s+qe-wpa2-psk" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_group_ccmp
    Scenario: nmcli - wifi-sec - group - ccmp
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.group ccmp
      """
    * Start following journal
    * Bring "up" connection "qe-wpa2-psk"
    Then "added 'group' value 'CCMP'" is visible in journal
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @attach_wpa_supplicant_log
    @nmcli_wifi_unmatching_group
    Scenario: nmcli - wifi-sec - unmatching group
    * Add "wifi" connection named "qe-wpa2-psk" for device "wlan0" with options
      """
      autoconnect off
      ssid qe-wpa2-psk
      802-11-wireless-security.key-mgmt wpa-psk
      802-11-wireless-security.psk "over the river and through the woods"
      802-11-wireless-security.group tkip
      """
    * Start following journal
    Then "Error" is visible with command "nmcli connection up qe-wpa2-psk ifname wlan0"
    Then "added 'group' value 'TKIP'" is visible in journal
    Then "\*\s+qe-wpa2-psk" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @rhbz1115564 @rhbz1184530
    @ver+=1.14
    @rhelver-=9
    @ifcfg-rh @attach_wpa_supplicant_log
    @nmcli_wifi_add_certificate_as_blob_saved
    Scenario: nmcli - wifi - save certificate blob
    * Cleanup connection "wifi-wlan0"
    * Execute "/usr/bin/python3l contrib/dbus/dbus-set-wifi-tls-blob.py Saved"
    Then "802-1x.client-cert:\s+/etc/sysconfig/network-scripts/wifi-wlan0-client-cert.der" is visible with command "nmcli connection show wifi-wlan0"
    And "3082045e30820346" is visible with command "cat /etc/sysconfig/network-scripts/wifi-wlan0-client-cert.der"
    And "802-1x.private-key:\s+/etc/sysconfig/network-scripts/wifi-wlan0-private-key.pem" is visible with command "nmcli connection show wifi-wlan0"
    And "3082045e30820346" is visible with command "cat /etc/sysconfig/network-scripts/wifi-wlan0-private-key.pem"


    @rhbz1200451
    @attach_wpa_supplicant_log
    @nmcli_wifi_indicate_wifi_band_caps
    Scenario: nmcli - wifi - indicate wireless band capabilities
    Given Flag "NM_802_11_DEVICE_CAP_FREQ_VALID" is set in WirelessCapabilites
    * Wait for "10" seconds
    Then Check "NM_802_11_DEVICE_CAP_FREQ_2GHZ" band cap flag set if device supported
    Then Check "NM_802_11_DEVICE_CAP_FREQ_5GHZ" band cap flag set if device supported


    # This needs wifi6E card
    @wireless_certs @attach_wpa_supplicant_log
    @nmcli_wifi_6e_wpa3_tls
    Scenario: nmcli - wifi-sec - configure and connect WPA3-TLS profile over 6E
    * Skip if next step fails:
    * "qe-wpa3-6e-enterprise" is visible with command "nmcli  device wifi list --rescan yes"
    * Add "wifi" connection named "qe-wpa3-6e-enterprise" for device "wlan0" with options
          """
          autoconnect off
          ssid qe-wpa3-6e-enterprise
          802-11-wireless-security.key-mgmt wpa-eap-suite-b-192
          802-1x.eap tls
          802-1x.identity "Bill Smith"
          802-1x.ca-cert file:///tmp/certs/eaptest_ca_cert.pem
          802-1x.client-cert file:///tmp/certs/client.pem
          802-1x.private-key-password 12345testing
          802-1x.private-key file:///tmp/certs/client.pem
          """
    * Bring "up" connection "qe-wpa3-6e-enterprise"
    Then "qe-wpa3-6e-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa3-6e-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"
