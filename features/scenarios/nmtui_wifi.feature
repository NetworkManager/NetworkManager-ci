@nmtui
Feature: WIFI TUI tests

  Background:
  * Prepare virtual terminal environment


    @wifi
    @nmtui_wifi_see_all_networks
    Scenario: nmtui - wifi - see all networks
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    Then ".*qe-open.*" is visible on screen
    Then ".*qe-wep .*" is visible on screen
    Then ".*qe-wpa1-psk.*" is visible on screen
    Then ".*qe-wpa2-psk.*" is visible on screen
    Then ".*qe-wep-enterprise.*" is visible on screen
    Then ".*qe-wep-enterprise-cisco.*" is visible on screen
    Then ".*qe-wpa1-enterprise.*" is visible on screen
    Then ".*qe-wpa2-enterprise.*" is visible on screen


    @wifi
    @nmtui_wifi_connect_to_open_network
    Scenario: nmtui - wifi - connect to open network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-open" in the list
    * Choose to "<Activate>" a connection
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_connect_to_wpa1psk_network
    Scenario: nmtui - wifi - connect to WPA1-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wpa1-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "over the river and through the woods"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_connect_to_wpa2psk_network
    Scenario: nmtui - wifi - connect to WPA2-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "over the river and through the woods"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_connect_to_wep_hexkey_network
    Scenario: nmtui - wifi - connect to WEP hex-key network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wep " in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "74657374696E67313233343536"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_connect_to_wep_asciikey_network
    Scenario: nmtui - wifi - connect to WEP ascii-key network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wep " in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "testing123456"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_connect_to_wep_phrase_network
    Scenario: nmtui - wifi - connect to WEP phrase network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wep " in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "testing123456"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_add_default_connection_open_network
    Scenario: nmtui - wifi - add default connection open network
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_fixed_device_present
    Scenario: nmtui - wifi - fixed device present
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_fixed_device_invalid
    Scenario: nmtui - wifi - fixed device invalid
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "nonexistent"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"

    @wifi
    @nmtui_wifi_autoconnect_off
    Scenario: nmtui - wifi - autoconnect off
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"


    @wifi
    @nmtui_wifi_activate_wo_autoconnect
    Scenario: nmtui - wifi - activate connection without autoconnect
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "wifi1" in the list
    * Choose to "<Activate>" a connection
    Then "wifi1" is visible with command "nmcli device" in "10" seconds
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_activate_with_autoconnect
    Scenario: nmtui - wifi - activate connection with autoconnect
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    When "wlan0\s+wifi\s+connected" is visible with command "nmcli device" in "20" seconds
    * Execute "nmcli con down wifi1"
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is not visible with command "nmcli device"
    * Wait for "5" seconds
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "wifi1" in the list
    * Choose to "<Activate>" a connection
    Then "wifi1" is visible with command "nmcli device" in "10" seconds
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi
    @nmtui_wifi_delete_connection_up
    Scenario: nmtui - wifi - delete connection while up
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    * Wait for "2" seconds
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is visible with command "nmcli device"
    * Select connection "wifi1" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for "3" seconds
    Then "wifi1" is not visible with command "nmcli connection"
    Then "wifi1" is not visible with command "nmcli device"
    Then "inet 10." is not visible with command "ip a s wlan0"


    @wifi
    @nmtui_wifi_delete_connection_down
    Scenario: nmtui - wifi - delete connection while down
    * Execute "while ! nmcli  device wifi list --rescan yes |grep 'qe-open'; do :;done"
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    * Wait for "2" seconds
    * Execute "nmcli connection down wifi1"
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is not visible with command "nmcli device"
    * Select connection "wifi1" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for "3" seconds
    Then "wifi1" is not visible with command "nmcli connection"
    Then "wifi1" is not visible with command "nmcli device"
    Then "inet 10." is not visible with command "ip a s wlan0"


    @xfail
    @wifi
    @nmtui_wifi_adhoc_network
    Scenario: nmtui - wifi - adhoc network
    Given Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-adhoc"
    * Set "Mode" dropdown to "Ad-Hoc Network"
    * Set "IPv4 CONFIGURATION" category to "Shared"
    * Confirm the connection settings
    Then "ssid qe-adhoc" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type IBSS" is visible with command "iw dev wlan0 info"


    @wifi_rescan @wifi
    @nmtui_wifi_ap
    Scenario: nmtui - wifi - ap
    Given Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-ap"
    * Set "Mode" dropdown to "Access Point"
    * Set "IPv4 CONFIGURATION" category to "Shared"
    * Confirm the connection settings
    Then "ssid qe-ap" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type AP" is visible with command "iw dev wlan0 info"


    @wifi
    @nmtui_wifi_wrong_ssid
    Scenario: nmtui - wifi - wrong ssid (over 32 bytes)
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qehsdkfjhsdkjfhskjdhfkdsjhfkjshkjagdgdsfsjkdhf"
    * Confirm the connection settings
    Then ".*Unable to add new connection.*SSID length.*" is visible on screen


    @wifi
    @nmtui_wifi_no_ssid
    Scenario: nmtui - wifi - no ssid (over 32 bytes)
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Empty the field "SSID"
    Then Cannot confirm the connection settings


    @ifcfg-rh @wifi
    @nmtui_wifi_set_existing_bssid
    Scenario: nmtui - wifi - set existing bssid
    * Execute "while ! nmcli  device wifi list --rescan yes |grep '68:7D:B4:08:7F:81'; do :;done"
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "BSSID" field to "68:7D:B4:08:7F:81"
    * Confirm the connection settings
    Then "BSSID=68:7D:B4:08:7F:81" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"
    Then "Connected to 68:7d:b4:08:7f:81" is visible with command "iw dev wlan0 link" in "30" seconds


    @ifcfg-rh @wifi
    @nmtui_wifi_set_nonexisting_bssid
    Scenario: nmtui - wifi - set nonexisting bssid
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "BSSID" field to "AA:AA:BB:BB:CC:CC"
    * Confirm the connection settings
    * Wait for "5" seconds
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"
    Then "BSSID=AA:AA:BB:BB:CC:CC" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"
    Then "qe-open" is not visible with command "iw dev wlan0 info"


    @wifi
    @nmtui_wifi_bogus_bssid
    Scenario: nmtui - wifi - bogus bssid
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "BSSID" field to "AA:AA:BB:XX:CC:CC"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "BSSID" field to "AA:AA:BB"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "BSSID" field to "GG:AA:BB:XX:CC:CC"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "BSSID" field to "1100pp2233"
    Then Cannot confirm the connection settings


    @wifi
    @nmtui_wifi_mac_spoofing
    Scenario: nmtui - wifi - mac spoofing
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "Cloned MAC address" field to "f0:de:aa:fb:bb:cc"
    * Confirm the connection settings
    * Wait for "5" seconds
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip a s wlan0"


    @wifi
    @nmtui_wifi_bogus_spoofing_address
    Scenario: nmtui - wifi - bogus spoofing address
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "Cloned MAC address" field to "AA:AA:BB:XX:CC:CC"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "Cloned MAC address" field to "AA:AA:BB"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "Cloned MAC address" field to "GG:AA:BB:XX:CC:CC"
    * Cannot confirm the connection settings
    * Come back to the top of editor
    * Set "Cloned MAC address" field to "1100pp2233"
    Then Cannot confirm the connection settings


    @ifcfg-rh @wifi
    @nmtui_wifi_mtu
    Scenario: nmtui - wifi - mtu
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-open"
    * Set "MTU" field to "512"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "MTU=512" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"

    @wifi
    @nmtui_wifi_wpa1_connection
    Scenario: nmtui - wifi - WPA1 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wpa1-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa1-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi
    @nmtui_wifi_wpa2_connection
    Scenario: nmtui - wifi - WPA2 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wpa2-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa2-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_wep_hexkey_connection
    Scenario: nmtui - wifi - WEP hex key connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wep"
    * Set "Security" dropdown to "WEP 40/128-bit Key \(Hex or ASCII\)"
    * Set "Key" field to "74657374696E67313233343536"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wep" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_wep_ascii_connection
    Scenario: nmtui - wifi - WEP ascii connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wep"
    * Set "Security" dropdown to "WEP 40/128-bit Key \(Hex or ASCII\)"
    * Set "Key" field to "testing123456"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wep" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi @rhelver-=8
    @nmtui_wifi_wep_passphrase_connection
    Scenario: nmtui - wifi - WEP passphrase connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wep-psk"
    * Set "Security" dropdown to "WEP 128-bit Passphrase"
    * Set "Password" field to "testing123456"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wep" is visible with command "iw dev wlan0 link" in "30" seconds


#    @wifi
#    @nmtui_wifi_leap_connection
#    Scenario: nmtui - wifi - LEAP connection
#    * Prepare new connection of type "Wi-Fi" named "wifi1"
#    * Set "Device" field to "wlan0"
#    * Set "SSID" field to "qe-wep-enterprise-cisco"
#    * Set "Security" dropdown to "LEAP"
#    * Set "Username" field to "Bill Smith"
#    * Set "Password" field to "testing123"
#    * Confirm the connection settings
#    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
#    Then "SSID: qe-wep-enterprise-cisco" is visible with command "iw dev wlan0 link" in "30" seconds

#### Note TUI doesn't support enterprise and dynamic wep yet, tests will be added when support done. ####

    @wifi
    @nmtui_wifi_show_password
    Scenario: nmtui - wifi - show password
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wpa1-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "testingpassword"
    * Wait for "0.5" seconds
    * ".*\*\*\*\*\*\*\*\*.*" is visible on screen
    * Ensure "Show password" is checked
    * Wait for "0.5" seconds
    Then ".*testingpassword.*" is visible on screen


    @rhbz1132612
    @wifi
    @nmtui_wifi_connect_to_network_after_dismissal
    Scenario: nmtui - wifi - connect to a network after dialog dismissal
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * Press "<Cancel>" button in the password dialog
    * Wait for "1" seconds
    * ".*Could not activate connection.*Activation failed.*" is visible on screen
    * Press "ENTER" key
    * Get back to the connection list
    * Select connection "qe-wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Set current field to "over the river and through the woods"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
