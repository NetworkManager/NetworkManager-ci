@testplan
Feature: nmcli - wifi

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+/-=1.4.1)
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @cleanwifi
    Scenario: Clean wifi
    * Execute "echo nada"


    @wifi
    @nmcli_wifi_connect_to_wpa2_psk_network_without_profile
    Scenario: nmcli - wifi - connect to WPA2 PSK network without profile
    Given "qe-wpa2-psk" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-wpa2-psk" network with options "password 'over the river and through the woods'"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connect_to_wpa1_psk_network_without_profile
    Scenario: nmcli - wifi - connect to WPA1 PSK network without profile
    Given "qe-wpa1-psk" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-wpa1-psk" network with options "password 'over the river and through the woods'"
    Then "\*\s+qe-wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-wpa1-psk" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connect_to_open_network_without_profile
    Scenario: nmcli - wifi - connect to open network without profile
    Given "qe-open" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-open" network
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-open" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connect_to_wep_hexkey_network_without_profile
    Scenario: nmcli - wifi - connect to WEP hex-key network without profile
    Given "qe-wep" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-wep" network with options "password 74657374696E67313233343536 wep-key-type key"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-wep" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connect_to_wep_asciikey_network_without_profile
    Scenario: nmcli - wifi - connect to WEP ascii-key network without profile
    Given "qe-wep" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-wep" network with options "password testing123456 wep-key-type key"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-wep" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connect_to_wep_phrase_network_without_profile
    Scenario: nmcli - wifi - connect to WEP phrase network without profile
    Given "qe-wep-psk" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Connect wifi device to "qe-wep-psk" network with options "password testing123456 wep-key-type phrase"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-wep" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_create_a_new_connection_for_an_open_network
    Scenario: nmcli - wifi - create a new connection for an open network
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect on ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "qe-open" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi
    @nmcli_wifi_connection_up_for_an_open_network
    Scenario: nmcli - wifi - connection up for an open network
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Bring up connection "qe-open"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-open" is visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_connection_down_for_an_open_network
    Scenario: nmcli - wifi - connection down for an open network
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Bring up connection "qe-open"
    * "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    * "qe-open" is visible with command "iw dev wlan0 link"
    * Bring down connection "qe-open"
    Then "\*\s+qe-open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "qe-open" is not visible with command "iw dev wlan0 link"


    @wifi
    @nmcli_wifi_infrastructure_mode_setting
    Scenario: nmcli - wifi - infrastructure mode setting
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.mode" to "infrastructure" in editor
    * Save in editor
    * Check value saved message showed in editor
    * No error appeared in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_adhoc_open_network
    Scenario: nmcli - wifi - adhoc open network
    Given Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-adhoc autoconnect off ssid qe-adhoc"
    * Check ifcfg-name file created for connection "qe-adhoc"
    * Open editor for connection "qe-adhoc"
    * Set a property named "802-11-wireless.mode" to "adhoc" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Set a property named "ipv6.method" to "auto" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Execute "nmcli connection up qe-adhoc"
    Then "qe-adhoc" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type IBSS" is visible with command "iw dev wlan0 info" in "30" seconds


    @wifi
    @nmcli_wifi_ap
    Scenario: nmcli - wifi - ap open network
    Given Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-ap autoconnect off ssid qe-ap"
    * Check ifcfg-name file created for connection "qe-ap"
    * Open editor for connection "qe-ap"
    * Set a property named "802-11-wireless.mode" to "ap" in editor
    * Set a property named "ipv4.method" to "shared" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Execute "nmcli connection up qe-ap"
    Then "qe-ap" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type AP" is visible with command "iw dev wlan0 info" in "30" seconds


    @wifi
    @nmcli_wifi_right_band
    Scenario: nmcli - wifi - right band
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "bg" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_right_band_80211a
    Scenario: nmcli - wifi - right band - 802.11a
    Given Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is set in WirelessCapabilites
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "a" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @rhbz1254461
    @wifi
    @nmcli_wifi_different_than_networks_band
    Scenario: nmcli - wifi - different than network's band
    Given Flag "NM_802_11_DEVICE_CAP_FREQ_5GHZ" is not set in WirelessCapabilites
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "a" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * "Error: Connection activation failed" is visible with command "nmcli con up qe-open"
    Then "qe-open" is not visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_setting_bogus_band
    Scenario: nmcli - wifi - setting bogus band
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "x" in editor
    Then See Error while saving in editor
    * Quit editor


    @wifi
    @nmcli_wifi_setting_wrong_ssid_over_32_bytes
    Scenario: nmcli - wifi - setting wrong SSID (over 32 bytes)
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.ssid" to "hsdkfjhsdkjfhskjdhfkdsjhfkjshkjagdgdsfsjkdhf" in editor
    Then See Error while saving in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_channel
    Scenario: nmcli - wifi - set channel
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "bg" in editor
    * Set a property named "802-11-wireless.channel" to "6" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_set_channel_under_7
    Scenario: nmcli - wifi - set channel < 7 (bz 999999)
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "bg" in editor
    * Set a property named "802-11-wireless.channel" to "1" in editor
    * Set a property named "802-11-wireless.channel" to "2" in editor
    * Set a property named "802-11-wireless.channel" to "3" in editor
    * Set a property named "802-11-wireless.channel" to "4" in editor
    * Set a property named "802-11-wireless.channel" to "5" in editor
    * Set a property named "802-11-wireless.channel" to "6" in editor
    Then No error appeared in editor
    * Save in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_channel_13_and_14_bz_999999
    Scenario: nmcli - wifi - set channel 13 and 14 (bz 999999)
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "bg" in editor
    * Set a property named "802-11-wireless.channel" to "13" in editor
    * Set a property named "802-11-wireless.channel" to "14" in editor
    Then No error appeared in editor
    * Save in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_wrong_channel
    Scenario: nmcli - wifi - set wrong channel
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.band" to "bg" in editor
    * Set a property named "802-11-wireless.channel" to "3" in editor
    Then Error type "might be ignored in infrastructure mode" shown in editor
    # * Save in editor
    # * Check value saved message showed in editor
    # * Quit editor
    # Then "Error" is visible with command "nmcli connection up qe-open"
    # Then "\*\s+qe-open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_set_bogus_channel
    Scenario: nmcli - wifi - set bogus channel
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.channel" to "15" in editor
    Then See Error while saving in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_nonexistent_bssid
    Scenario: nmcli - wifi - set non-existent bssid
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.bssid" to "00:11:22:33:44:55" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "Error" is visible with command "nmcli connection up qe-open"
    Then "\*\s+qe-open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_set_bogus_bssid
    Scenario: nmcli - wifi - set bogus bssid
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.bssid" to "dough" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.bssid" to "00:13:DG:7F:54:CF" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.bssid" to "00:13:DA:7F:54" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.bssid" to "00:13:DA:7F:54:CF:AA" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_existing_bssid
    Scenario: nmcli - wifi - set existing bssid
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Bring up connection "qe-open"
    * Bring down connection "qe-open"
    * Open editor for connection "qe-open"
    * Note the "802-11-wireless.seen-bssids" property from editor print output
    * Set a property named "802-11-wireless.bssid" to "noted-value" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"

    @wifi
    @nmcli_wifi_check_rate_configuration
    Scenario: nmcli - wifi - check rate configuration
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.rate" to "5500" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_check_txpower_configuration
    Scenario: nmcli - wifi - check txpower configuration
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.tx-power" to "5" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_bogus_txpower
    Scenario: nmcli - wifi - set bogus txpower
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.rate" to "-1" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.rate" to "valderon" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.rate" to "9999999999" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_bogus_rate
    Scenario: nmcli - wifi - set bogus rate
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.rate" to "-5" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.rate" to "krobot" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.rate" to "9999999999" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_matching_mac_adress
    Scenario: nmcli - wifi - set matching mac adress
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Note MAC address output for device "wlan0" via ethtool
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.mac-address" to "noted-value" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_set_nonexistent_mac_adress
    Scenario: nmcli - wifi - set non-existent mac adress
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.mac-address" to "00:11:22:33:44:55" in editor
    * Save in editor
    * Check value saved message showed in editor
    * No error appeared in editor
    * Quit editor
    Then "No suitable device found for this connection" is visible with command "nmcli connection up qe-open"


    @wifi
    @nmcli_wifi_set_bogus_mac_adress
    Scenario: nmcli - wifi - set bogus mac adress
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.mac-address" to "-1" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.mac-address" to "4294967297" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.mac-address" to "ooops" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.mac-address" to "00:13:DG:7F:54:CF" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.mac-address" to "00:13:DA:7F:54" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.mac-address" to "00:13:DA:7F:54:CF:AA" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_mac_adress_in_dashed_format_bz_1002553
    Scenario: nmcli - wifi - set mac adress in dashed format (bz 1002553)
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.mac-address" to "00-11-22-33-44-55" in editor
    Then No error appeared in editor

    @wifi
    @nmcli_wifi_mac_spoofing_if_hw_supported
    Scenario: nmcli - wifi - mac spoofing (if hw supported)
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.cloned-mac-address" to "f0:de:aa:fb:bb:cc" in editor
    * Save in editor
    * Check value saved message showed in editor
    * No error appeared in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ifconfig wlan0"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_mac_adress_blacklist
    Scenario: nmcli - wifi - mac adress blacklist
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Note MAC address output for device "wlan0" via ethtool
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.mac-address-blacklist" to "noted-value" in editor
    * No error appeared in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "Error" is visible with command "nmcli connection up qe-open"
    Then "\*\s+qe-open" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @mtu_wlan0 @wifi
    @nmcli_wifi_set_mtu
    Scenario: nmcli - wifi - set mtu
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Open editor for connection "qe-open"
    * Set a property named "802-11-wireless.mtu" to "64" in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-open"
    Then "MTU=64" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-qe-open"
    Then "qe-open" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @rhbz1094298
    @wifi
    @nmcli_wifi_seen_bssids
    Scenario: nmcli - wifi - seen bssids
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Bring up connection "qe-open"
    * Open editor for connection "qe-open"
    * Note the "802-11-wireless.seen-bssids" property from editor print output
    Then Noted value contains "([0-9A-F]{2}[:-]){5}([0-9A-F]{2})"
    * Quit editor


    @wifi
    @nmcli_wifi_set_and_connect_to_a_hidden_network
    Scenario: nmcli - wifi - set and connect to a hidden network
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-hidden-wpa2-psk autoconnect off ssid qe-hidden-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-hidden-wpa2-psk"
    * Open editor for connection "qe-hidden-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless.hidden" to "yes" in editor
    * Set a property named "802-11-wireless-security.psk" to "6ubDLTiFr6jDSAxW08GdKU0s5Prh1c5G8CWeYpXHgXeYmhhMyDX8vMMWwLhx8Sl" in editor
    * No error appeared in editor
    * Save in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-hidden-wpa2-psk"
    Then "qe-hidden-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-hidden-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_set_proper_hidden_property_values
    Scenario: nmcli - wifi - set proper hidden property values
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.hidden" to "true" in editor
    * Set a property named "802-11-wireless.hidden" to "yes" in editor
    * Set a property named "802-11-wireless.hidden" to "on" in editor
    * Set a property named "802-11-wireless.hidden" to "false" in editor
    * Set a property named "802-11-wireless.hidden" to "no" in editor
    * Set a property named "802-11-wireless.hidden" to "off" in editor
    Then No error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_set_bogus_hidden_property_values
    Scenario: nmcli - wifi - set bogus hidden property values
    * Open editor for a type "wifi"
    * Set a property named "802-11-wireless.hidden" to "0" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.hidden" to "-1" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.hidden" to "valderon" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless.hidden" to "999999999999" in editor
    Then Error appeared in editor
    * Quit editor


    @wifi
    @nmcli_wifi_80211wireless_describe_all
    Scenario: nmcli - wifi - 802-11-wireless describe all
    * Open editor for a type "wifi"
    Then Check "ssid|mode|band|channel|bssid|rate|tx-power|mac-address|cloned-mac-address|mac-address-blacklist|mtu|seen-bssids|hidden" are present in describe output for object "802-11-wireless"


    @wifi
    @nmcli_wifi_describe_separately
    Scenario: nmcli - wifi - describe separately
    * Open editor for a type "wifi"
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


    @wifi
    @nmcli_wifisec_80211wirelesssecurity_describe_all
    Scenario: nmcli - wifi-sec - 802-11-wireless-security describe all
    * Open editor for a type "wifi"
    Then Check "key-mgmt|wep-tx-keyidx|auth-alg|proto|pairwise|group|leap-username|wep-key0|wep-key1|wep-key2|wep-key3|wep-key-flags|wep-key-type|psk|psk-flags|leap-password|leap-password-flags" are present in describe output for object "802-11-wireless-security"


    @wifi
    @nmcli_wifisec_describe_separately
    Scenario: nmcli - wifi-sec - describe separately
    * Open editor for a type "wifi"
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


    @wifi
    @nmcli_wifisec_configure_and_connect_wpa2psk_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PSK profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wpa1psk_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA1-PSK profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-psk autoconnect off ssid qe-wpa1-psk"
    * Check ifcfg-name file created for connection "qe-wpa1-psk"
    * Open editor for connection "qe-wpa1-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa1-psk"
    Then "qe-wpa1-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wep_hex_key_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP hex key profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "74657374696E67313233343536" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep"
    Then "qe-wep" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wep_ascii_key_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP ascii key profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "testing123456" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep"
    Then "qe-wep" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wep_phrase_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP phrase profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep-psk autoconnect off ssid qe-wep-psk"
    * Check ifcfg-name file created for connection "qe-wep-psk"
    * Open editor for connection "qe-wep-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "testing123456" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "passphrase" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep-psk"
    Then "qe-wep-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wpa1peap_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA1-PEAP profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-enterprise autoconnect off ssid qe-wpa1-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa1-enterprise"
    * Open editor for connection "qe-wpa1-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "peap" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Set a property named "802-1x.phase2-auth" to "gtc" in editor
    * Set a property named "802-1x.password" to "testing123" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa1-enterprise"
    Then "qe-wpa1-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wpa1tls_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA1-TLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-enterprise autoconnect off ssid qe-wpa1-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa1-enterprise"
    * Open editor for connection "qe-wpa1-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "tls" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Set a property named "802-1x.client-cert" to "file:///tmp/certs/client.pem" in editor
    * Set a property named "802-1x.private-key-password" to "12345testing" in editor
    * Set a property named "802-1x.private-key" to "file:///tmp/certs/client.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa1-enterprise"
    Then "qe-wpa1-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wpa1ttls_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA1-TTLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-enterprise autoconnect off ssid qe-wpa1-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa1-enterprise"
    * Open editor for connection "qe-wpa1-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "ttls" in editor
    * Set a property named "802-1x.phase2-auth" to "mschapv2" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.password" to "testing123" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa1-enterprise"
    Then "qe-wpa1-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wpa2peap_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA2-PEAP profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-enterprise autoconnect off ssid qe-wpa2-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa2-enterprise"
    * Open editor for connection "qe-wpa2-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "peap" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Set a property named "802-1x.phase2-auth" to "gtc" in editor
    * Set a property named "802-1x.password" to "testing123" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "inet 10." is visible with command "ip a s wlan0"


    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wpa2tls_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA2-TLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-enterprise autoconnect off ssid qe-wpa2-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa2-enterprise"
    * Open editor for connection "qe-wpa2-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "tls" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Set a property named "802-1x.client-cert" to "file:///tmp/certs/client.pem" in editor
    * Set a property named "802-1x.private-key-password" to "12345testing" in editor
    * Set a property named "802-1x.private-key" to "file:///tmp/certs/client.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_wpa2ttls_profile
    Scenario: nmcli - wifi-sec - configure and connect WPA2-TTLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-enterprise autoconnect off ssid qe-wpa2-enterprise"
    * Check ifcfg-name file created for connection "qe-wpa2-enterprise"
    * Open editor for connection "qe-wpa2-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-eap" in editor
    * Set a property named "802-1x.eap" to "ttls" in editor
    * Set a property named "802-1x.phase2-auth" to "mschapv2" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.password" to "testing123" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-enterprise"
    Then "qe-wpa2-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"

    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wep_leap_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP LEAP profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep-enterprise-cisco autoconnect off ssid qe-wep-enterprise-cisco"
    * Check ifcfg-name file created for connection "qe-wep-enterprise-cisco"
    * Open editor for connection "qe-wep-enterprise-cisco"
    * Set a property named "802-11-wireless-security.key-mgmt" to "ieee8021x" in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "leap" in editor
    * Set a property named "802-11-wireless-security.leap-username" to "Bill Smith" in editor
    * Set a property named "802-11-wireless-security.leap-password" to "testing123" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep-enterprise-cisco"
    Then "qe-wep-enterprise-cisco" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep-enterprise-cisco" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_configure_and_connect_weptls_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP-TLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep-enterprise autoconnect off ssid qe-wep-enterprise"
    * Check ifcfg-name file created for connection "qe-wep-enterprise"
    * Open editor for connection "qe-wep-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "ieee8021x" in editor
    * Set a property named "802-1x.eap" to "tls" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Set a property named "802-1x.client-cert" to "file:///tmp/certs/client.pem" in editor
    * Set a property named "802-1x.private-key-password" to "12345testing" in editor
    * Set a property named "802-1x.private-key" to "file:///tmp/certs/client.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep-enterprise"
    Then "qe-wep-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi @wireless_certs
    @nmcli_wifisec_configure_and_connect_wepttls_profile
    Scenario: nmcli - wifi-sec - configure and connect WEP-TTLS profile
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep-enterprise autoconnect off ssid qe-wep-enterprise"
    * Check ifcfg-name file created for connection "qe-wep-enterprise"
    * Open editor for connection "qe-wep-enterprise"
    * Set a property named "802-11-wireless-security.key-mgmt" to "ieee8021x" in editor
    * Set a property named "802-1x.eap" to "ttls" in editor
    * Set a property named "802-1x.phase2-auth" to "mschapv2" in editor
    * Set a property named "802-1x.identity" to "Bill Smith" in editor
    * Set a property named "802-1x.password" to "testing123" in editor
    * Set a property named "802-1x.ca-cert" to "file:///tmp/certs/eaptest_ca_cert.pem" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep-enterprise"
    Then "qe-wep-enterprise" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep-enterprise" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifi_remove_connection_while_up
    Scenario: nmcli - wifi - remove connection while up
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Bring up connection "qe-open"
    * "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    * "qe-open" is visible with command "iw dev wlan0 link"
    * Delete connection "qe-open"
    Then ifcfg-"qe-open" file does not exist
    Then "qe-open" is not visible with command "iw dev wlan0 link"

    @wifi
    @nmcli_wifi_remove_connection_while_down
    Scenario: nmcli - wifi - remove connection while down
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Check ifcfg-name file created for connection "qe-open"
    * Delete connection "qe-open"
    Then ifcfg-"qe-open" file does not exist


    @wifi
    @nmcli_wifisec_keymgmt_wrong_values
    Scenario: nmcli - wifi-sec - key-mgmt - wrong values
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "ieee8021x123" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.key-mgmt" to "ieee8021x sth" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.key-mgmt" to "-1" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.key-mgmt" to "0" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.key-mgmt" to "999999999999999999999" in editor
    Then Error appeared in editor


    @wifi
    @nmcli_wifisec_weptxkeyidx_nondefault_wep_key
    Scenario: nmcli - wifi-sec - wep-tx-keyidx - non-default wep key
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "0" in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "1" in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "2" in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "3" in editor
    * Set a property named "802-11-wireless-security.wep-key3" to "testing123456" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Execute "nmcli connection up qe-wep" without waiting for process to finish
    Then "KEY4=s:testing123456" is visible with command "sudo cat /etc/sysconfig/network-scripts/keys-qe-wep"
    Then Look for "'wep_tx_keyidx' value '3'" in journal


    @wifi
    @nmcli_wifisec_weptxkeyidx_bogus_key_id
    Scenario: nmcli - wifi-sec - wep-tx-keyidx - bogus key id
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "-1" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "4" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "999999999999999999999999" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "walderon" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.wep-tx-keyidx" to "2 0" in editor
    Then Error appeared in editor


    @wifi
    @nmcli_wifisec_authalg_wep_open_key
    Scenario: nmcli - wifi-sec - auth-alg - wep open key
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "open" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "74657374696E67313233343536" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wep"
    Then "qe-wep" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_authalg_wep_shared_key
    Scenario: nmcli - wifi-sec - auth-alg - wep shared key
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "shared" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "testing123456" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Execute "nmcli connection up qe-wep" without waiting for process to finish
    Then Look for "added 'auth_alg' value 'SHARED'" in journal


    @wifi
    @nmcli_wifisec_authalg_bogus_values_and_leap_with_wrong_keymgmt
    Scenario: nmcli - wifi-sec - auth-alg - bogus values and leap with wrong key-mgmt
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "0" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "null" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "999999999999999999" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "open shared" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.auth-alg" to "leap" in editor
    * No error appeared in editor
    * Save in editor
    Then Error appeared in editor


    @wifi
    @nmcli_wifisec_proto_rsn
    Scenario: nmcli - wifi-sec - proto - rsn
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.proto" to "rsn" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_proto_wpa
    Scenario: nmcli - wifi-sec - proto - wpa
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-psk autoconnect off ssid qe-wpa1-psk"
    * Check ifcfg-name file created for connection "qe-wpa1-psk"
    * Open editor for connection "qe-wpa1-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.proto" to "wpa" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa1-psk"
    Then "qe-wpa1-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_unmatching_proto
    Scenario: nmcli - wifi-sec - unmatching proto
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.proto" to "wpa" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    Then "Error" is visible with command "nmcli connection up qe-wpa2-psk"
    Then Look for "added 'proto' value 'WPA'" in journal
    Then "\*\s+qe-wpa2-psk" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_pairwise_ccmp
    Scenario: nmcli - wifi-sec - pairwise - ccmp
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.pairwise" to "ccmp" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Bring up connection "qe-wpa2-psk"
    Then Look for "added 'pairwise' value 'CCMP'" in journal
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_pairwise_tkip
    Scenario: nmcli - wifi-sec - pairwise - tkip
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-psk autoconnect off ssid qe-wpa1-psk"
    * Check ifcfg-name file created for connection "qe-wpa1-psk"
    * Open editor for connection "qe-wpa1-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.pairwise" to "tkip" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Bring up connection "qe-wpa1-psk"
    Then Look for "added 'pairwise' value 'TKIP'" in journal
    Then "qe-wpa1-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_unmatching_pairwise
    Scenario: nmcli - wifi-sec - unmatching pairwise
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.pairwise" to "tkip" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    Then "Error" is visible with command "nmcli connection up qe-wpa2-psk ifname wlan0"
    Then Look for "added 'pairwise' value 'TKIP'" in journal
    Then "\*\s+qe-wpa2-psk" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_group_ccmp
    Scenario: nmcli - wifi-sec - group - ccmp
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.group" to "ccmp" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Bring up connection "qe-wpa2-psk"
    Then Look for "added 'group' value 'CCMP'" in journal
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_group_tkip
    Scenario: nmcli - wifi-sec - group - tkip
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa1-psk autoconnect off ssid qe-wpa1-psk"
    * Check ifcfg-name file created for connection "qe-wpa1-psk"
    * Open editor for connection "qe-wpa1-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.group" to "tkip" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    * Bring up connection "qe-wpa1-psk"
    Then Look for "added 'group' value 'TKIP'" in journal
    Then "qe-wpa1-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa1-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_unmatching_group
    Scenario: nmcli - wifi-sec - unmatching group
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Set a property named "802-11-wireless-security.group" to "tkip" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Start following journal
    Then "Error" is visible with command "nmcli connection up qe-wpa2-psk ifname wlan0"
    Then Look for "added 'group' value 'TKIP'" in journal
    Then "\*\s+qe-wpa2-psk" is not visible with command "nmcli -f IN-USE,SSID device wifi list"


    @wifi
    @nmcli_wifisec_set_all_wep_keys
    Scenario: nmcli - wifi-sec - set all wep keys
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "testing123456" in editor
    * Set a property named "802-11-wireless-security.wep-key1" to "testi" in editor
    * Set a property named "802-11-wireless-security.wep-key2" to "123456testing" in editor
    * Set a property named "802-11-wireless-security.wep-key3" to "54321" in editor
    * Set a property named "802-11-wireless-security.wep-key-type" to "key" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    Then "KEY1=s:testing123456.+KEY2=s:testi.+KEY3=s:123456testing.+KEY4=s:54321" is visible with command "sudo cat /etc/sysconfig/network-scripts/keys-qe-wep"


    @wifi
    @nmcli_wifisec_wepkeytype_autodetection_passphrase
    Scenario: nmcli - wifi-sec - wep-key-type auto-detection - passphrase
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wep autoconnect off ssid qe-wep"
    * Check ifcfg-name file created for connection "qe-wep"
    * Open editor for connection "qe-wep"
    * Set a property named "802-11-wireless-security.key-mgmt" to "none" in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "123" in editor
    * "passphrase" appeared in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "aaaaabbsbb" in editor
    * "passphrase" appeared in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "1234A678B01F" in editor
    * "passphrase" appeared in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "1234567890123456" in editor
    * "passphrase" appeared in editor
    * Set a property named "802-11-wireless-security.wep-key0" to "G234567F9012345678911F3451" in editor
    Then "passphrase" appeared in editor


    @wifi
    @nmcli_wifisec_psk_validity
    Scenario: nmcli - wifi-sec - psk validity
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "valid size and input for ascii psk @#$%^&*()[]{}" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.psk" to "short12" in editor
    * Error appeared in editor
    * Set a property named "802-11-wireless-security.psk" to "valid123" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.psk" to "maximumasciiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.psk" to "1234A678B01F1234A678B01F1234A678B01F1234A678B01F1234A678B01F123B" in editor
    * No error appeared in editor
    * Set a property named "802-11-wireless-security.psk" to "G234A678B01F1234A678B01F1234A678B01F1234A678B01F1234A678B01F123B" in editor
    * Error appeared in editor


    @wifi
    @nmcli_wifi_add_default_connection_in_novice_nmcli_a_mode
    Scenario: nmcli - wifi - add default connection in novice (nmcli -a) mode
    * Open interactive connection addition mode for a type "wifi"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "SSID"
    * Submit "qe-open"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "no"
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "qe-open" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi
    @nmcli_wifi_add_connection_in_novice_nmcli_a_mode_specifying_options
    Scenario: nmcli - wifi - add connection in novice (nmcli -a) mode specifying options
    * Open interactive connection addition mode for a type "wifi"
    * Note MAC address output for device "wlan0" via ethtool
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "SSID"
    * Submit "qe-open"
    * Expect "There are . optional .*Wi-Fi"
    * Submit "yes"
    * Expect "Wi-Fi mode"
    * Submit "infrastructure"
    * Expect "MTU"
    * Submit "64"
    * Expect "MAC"
    * Submit "noted-value"
    * Expect "Cloned MAC"
    * Submit "noted-value"
    * Dismiss IP configuration in editor
    * Dismiss Proxy configuration in editor
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "qe-open" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi
    @ver+=1.6.0
    @nmcli_wifi_add_connection_in_novice_nmcli_a_mode_specifying_ip_setup
    Scenario: nmcli - wifi - add connection in novice (nmcli -a) mode specifying IP setup
    * Open interactive connection addition mode
    * Expect "Connection type"
    * Submit "wifi"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "SSID"
    * Submit "qe-open"
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
    #* Submit "fe80::215:ff:fe93:ffff"
    #* No error appeared in editor
    * Submit "fe80::215:ff:fe93:ffff/128"
    * No error appeared in editor
    * Submit "<enter>"
    * Expect "IPv6 gateway"
    * Submit "::1"
    * Dismiss Proxy configuration in editor
    * Expect "Connection.*successfully added"
    Then "\*\s+qe-open" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "30" seconds
    Then "qe-open" is visible with command "iw dev wlan0 link" in "30" seconds
    Then "10.1.1.6.*fe80::215:ff:fe93:ffff" is visible with command "ip a" in "30" seconds
    Then "10.1.1.5" is visible with command "ip a" in "30" seconds


    @wifi
    @nmcli_wifi_add_connection_in_novice_nmcli_a_mode_with_bogus_ip
    Scenario: nmcli - wifi - add connection in novice (nmcli -a) mode with bogus IP
    * Open interactive connection addition mode
    * Expect "Connection type"
    * Submit "wifi"
    * Expect "Interface name"
    * Submit "wlan0"
    * Expect "SSID"
    * Submit "qe-open"
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


    @wifi
    @nmcli_wifi_disable_radio
    Scenario: nmcli - wifi - disable radio
    Given  "enabled" is visible with command "nmcli radio wifi"
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect off ssid qe-open"
    * Bring up connection "qe-open"
    * "qe-open" is visible with command "iw dev wlan0 link"
    * Execute "nmcli radio wifi off"
    Then "disabled" is visible with command "nmcli radio wifi"
    Then "qe-open" is not visible with command "iw dev wlan0 link"
    Then "wlan0\s+wifi\s+unavailable" is visible with command "nmcli device"
    * Execute "nmcli radio wifi on"


    @wifi
    @nmcli_wifi_enable_radio
    Scenario: nmcli - wifi - enable radio
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-open autoconnect on ssid qe-open"
    * Execute "nmcli radio wifi off"
    * "disabled" is visible with command "nmcli radio wifi"
    * "qe-open" is not visible with command "iw dev wlan0 link"
    * "wlan0\s+wifi\s+unavailable" is visible with command "nmcli device"
    * Execute "nmcli radio wifi on"
    Then "enabled" is visible with command "nmcli radio wifi"
    Then "qe-open" is visible with command "iw dev wlan0 link" in "15" seconds
    Then "wlan0\s+wifi\s+connected" is visible with command "nmcli device" in "15" seconds


    @bz1080628
    @wifi
    @nmcli_wifi_keep_secrets_after_modification
    Scenario: nmcli - wifi-sec - keep secrets after connection modification
    * Add a new connection of type "wifi" and options "ifname wlan0 con-name qe-wpa2-psk autoconnect off ssid qe-wpa2-psk"
    * Check ifcfg-name file created for connection "qe-wpa2-psk"
    * Open editor for connection "qe-wpa2-psk"
    * Set a property named "802-11-wireless-security.key-mgmt" to "wpa-psk" in editor
    * Set a property named "802-11-wireless-security.psk" to "over the river and through the woods" in editor
    * Save in editor
    * No error appeared in editor
    * Check value saved message showed in editor
    * Quit editor
    * Bring up connection "qe-wpa2-psk"
    * Bring down connection "qe-wpa2-psk"
    * Execute "nmcli con modify qe-wpa2-psk connection.zone trusted"
    * Bring up connection "qe-wpa2-psk"
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list"
    Then "inet 10" is visible with command "ip a s wlan0"


    @rhbz990111
    @wifi
    @nmcli_wifi_wpa_ask_passwd
    Scenario: nmcli - wifi - connect WPA network asking for password
    Given "qe-wpa2-psk" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Spawn "nmcli -a device wifi connect qe-wpa2-psk" command
    * Expect "Password:"
    * Submit "over the river and through the woods"
    Then "\*\s+qe-wpa2-psk" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "45" seconds
    Then "qe-wpa2-psk" is visible with command "iw dev wlan0 link"


    @rhbz990111
    @wifi
    @nmcli_wifi_wep_ask_passwd
    Scenario: nmcli - wifi - connect WEP network asking for password
    Given "qe-wep" is visible with command "nmcli -f SSID device wifi list" in "15" seconds
    * Spawn "nmcli -a device wifi connect qe-wep" command
    * Expect "Password:"
    * Submit "testing123456"
    Then "\*\s+qe-wep" is visible with command "nmcli -f IN-USE,SSID device wifi list" in "45" seconds
    Then "qe-wep" is visible with command "iw dev wlan0 link"


    @rhbz1115564 @rhbz1184530
    @wifi
    @nmcli_wifi_add_certificate_as_blob
    Scenario: nmcli - wifi - show or hide certificate blob
    * Execute "python tmp/dbus-set-wifi-tls-blob.py"
    Then "802-1x.client-cert:\s+3330383230" is visible with command "nmcli --show-secrets connection show wifi-wlan0"
    And "3330383230" is not visible with command "nmcli connection show wifi-wlan0"


    @rhbz1182567
    @wifi
    @nmcli_wifi_dbus_invalid_cert_input
    Scenario: nmcli - wifi - dbus invalid certificate input
    Then "Connection.InvalidProperty" is visible with command "python tmp/dbus-set-wifi-bad-cert.py"


    @rhbz1200451
    @wifi
    @nmcli_wifi_indicate_wifi_band_caps
    Scenario: nmcli - wifi - indicate wireless band capabilities
    Given Flag "NM_802_11_DEVICE_CAP_FREQ_VALID" is set in WirelessCapabilites
    Then Check "NM_802_11_DEVICE_CAP_FREQ_2GHZ" band cap flag set if device supported
    Then Check "NM_802_11_DEVICE_CAP_FREQ_5GHZ" band cap flag set if device supported
