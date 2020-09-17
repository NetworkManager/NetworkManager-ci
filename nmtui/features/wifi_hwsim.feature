Feature: WIFI TUI tests

  Background:
  * Prepare virtual terminal environment


    @rhelver+=8.2 @fedoraver+=32
    @simwifi
    @nmtui_simwifi_see_all_networks
    Scenario: nmtui - wifi_hwsim - see all networks
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    Then Connections "open, wep ,wep-2,dynwep,wpa1-eap,wpa1-psk,wpa2-eap,wpa2-psk,wpa3" are in the list


    # no wpa3 before 8.2
    @rhelver-=8.1 @fedoraver+=32
    @simwifi
    @nmtui_simwifi_see_all_networks
    Scenario: nmtui - wifi_hwsim - see all networks
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    Then Connections "open, wep ,wep-2,dynwep,wpa1-eap,wpa1-psk,wpa2-eap,wpa2-psk" are in the list


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_connect_to_open_network
    Scenario: nmtui - wifi_hwsim - connect to open network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "open" in the list
    * Choose to "<Activate>" a connection
    Then "ESSID=(\"open\"|open)" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-open"
    Then "TYPE=Wireless" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-open"
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_connect_to_wpa1psk_network
    Scenario: nmtui - wifi_hwsim - connect to WPA1-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "wpa1-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "secret123"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_connect_to_wpa2psk_network
    Scenario: nmtui - wifi_hwsim - connect to WPA2-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "secret123"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @rhelver+=8.2 @fedoraver+=32
    @simwifi
    @nmtui_simwifi_connect_to_wpa3psk_network
    Scenario: nmtui - wifi_hwsim - connect to WPA3-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "wpa3" in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "secret123"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_connect_to_wep_hexkey_network
    Scenario: nmtui - wifi_hwsim - connect to WEP hex-key network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection " wep-2 " in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "74657374696E67313233343536"
    * Press "ENTER" key
    Then "ESSID=(\"wep-2\"|wep-2)" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wep-2"
    Then "TYPE=Wireless" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wep-2"
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_connect_to_wep_asciikey_network
    Scenario: nmtui - wifi_hwsim - connect to WEP ascii-key network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection " wep-2 " in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "testing123456"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_add_default_connection_open_network
    Scenario: nmtui - wifi_hwsim - add default connection open network
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "SSID" field to "open"
    * Confirm the connection settings
    Then "ESSID=(\"open\"|open)" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi"
    Then "DEVICE" is not visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi"
    Then "TYPE=Wireless" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi"
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_fixed_device_present
    Scenario: nmtui - wifi_hwsim - fixed device present
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_fixed_device_invalid
    Scenario: nmtui - wifi_hwsim - fixed device invalid
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "nonexistent"
    * Set "SSID" field to "open"
    * Confirm the connection settings
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_autoconnect_off
    Scenario: nmtui - wifi_hwsim - autoconnect off
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "no" is visible with command "nmcli -g connection.autoconnect con show id wifi1"
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_activate_wo_autoconnect
    Scenario: nmtui - wifi_hwsim - activate connection without autoconnect
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    * "wifi1" is visible with command "nmcli connection"
    Then "no" is visible with command "nmcli -g connection.autoconnect con show id wifi1"
    * "wifi1" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "wifi1" in the list
    * Choose to "<Activate>" a connection
    Then "wifi1" is visible with command "nmcli device" in "10" seconds
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_activate_with_autoconnect
    Scenario: nmtui - wifi_hwsim - activate connection with autoconnect
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Ensure "Automatically connect" is checked
    * Confirm the connection settings
    Then "yes" is visible with command "nmcli -g connection.autoconnect con show id wifi1"
    # don't "up" connection when this gets fixed https://bugzilla.redhat.com/show_bug.cgi?id=1834980
    * Bring "up" connection "wifi1"
    * Bring "down" connection "wifi1"
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is not visible with command "nmcli device"
    * Come back to main screen
    * Choose to "Activate a connection" from main screen
    * Select connection "wifi1" in the list
    * Choose to "<Activate>" a connection
    Then "wifi1" is visible with command "nmcli device" in "10" seconds
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_delete_connection_up
    Scenario: nmtui - wifi_hwsim - delete connection while up
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Confirm the connection settings
    * Wait for at least "2" seconds
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is visible with command "nmcli device"
    * Select connection "wifi1" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then "wifi1" is not visible with command "nmcli connection"
    Then "wifi1" is not visible with command "nmcli device"
    Then "inet 10." is not visible with command "ip a s wlan0"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_delete_connection_down
    Scenario: nmtui - wifi_hwsim - delete connection while down
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Confirm the connection settings
    Then "yes" is visible with command "nmcli -g connection.autoconnect con show id wifi1"
    # don't "up" connection when this gets fixed https://bugzilla.redhat.com/show_bug.cgi?id=1834980
    * Bring "up" connection "wifi1"
    * Bring "down" connection "wifi1"
    * "wifi1" is visible with command "nmcli connection"
    * "wifi1" is not visible with command "nmcli device"
    * Select connection "wifi1" in the list
    * Choose to "<Delete>" a connection
    * Press "Delete" button in the dialog
    * Wait for at least "3" seconds
    Then "wifi1" is not visible with command "nmcli connection"
    Then "wifi1" is not visible with command "nmcli device"
    Then "inet 10." is not visible with command "ip a s wlan0"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_adhoc_network
    Scenario: nmtui - wifi_hwsim - adhoc network
    Given Flag "NM_802_11_DEVICE_CAP_ADHOC" is set in WirelessCapabilites
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-adhoc"
    * Set "Mode" dropdown to "Ad-Hoc Network"
    * Set "IPv4 CONFIGURATION" category to "Shared"
    * Confirm the connection settings
    Then "ssid qe-adhoc" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type IBSS" is visible with command "iw dev wlan0 info"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_ap
    Scenario: nmtui - wifi_hwsim - ap
    Given Flag "NM_802_11_DEVICE_CAP_AP" is set in WirelessCapabilites
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-ap"
    * Set "Mode" dropdown to "Access Point"
    * Set "IPv4 CONFIGURATION" category to "Shared"
    * Confirm the connection settings
    Then "ssid qe-ap" is visible with command "iw dev wlan0 info" in "30" seconds
    Then "type AP" is visible with command "iw dev wlan0 info"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wrong_ssid
    Scenario: nmtui - wifi_hwsim - wrong ssid (over 32 bytes)
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qehsdkfjhsdkjfhskjdhfkdsjhfkjshkjagdgdsfsjkdhf"
    * Confirm the connection settings
    Then ".*Unable to add new connection.*SSID length.*" is visible on screen


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_no_ssid
    Scenario: nmtui - wifi_hwsim - no ssid (over 32 bytes)
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Empty the field "SSID"
    Then Cannot confirm the connection settings


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_set_existing_bssid
    Scenario: nmtui - wifi_hwsim - set existing bssid
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "multiopen"
    * Note the output of "nmcli -g bssid,ssid dev wifi list | grep ':multiopen$' | head -n1 | sed 's/\\//g;s/:multiopen//g'"
    * Set "BSSID" field to "<noted>"
    * Confirm the connection settings
    Then Noted value is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"
    Then Noted value is visible with command "iw dev wlan0 link | tr 'a-z' 'A-Z'" in "30" seconds


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_set_nonexisting_bssid
    Scenario: nmtui - wifi_hwsim - set nonexisting bssid
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Set "BSSID" field to "AA:AA:BB:BB:CC:CC"
    * Confirm the connection settings
    * Wait for at least "5" seconds
    Then "wlan0\s+wifi\s+disconnected" is visible with command "nmcli device"
    Then "BSSID=AA:AA:BB:BB:CC:CC" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"
    Then "open" is not visible with command "iw dev wlan0 info"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_bogus_bssid
    Scenario: nmtui - wifi_hwsim - bogus bssid
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
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


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_mac_spoofing
    Scenario: nmtui - wifi_hwsim - mac spoofing
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Set "Cloned MAC address" field to "f0:de:aa:fb:bb:cc"
    * Confirm the connection settings
    * Wait for at least "5" seconds
    Then "ether f0:de:aa:fb:bb:cc" is visible with command "ip a s wlan0"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_bogus_spoofing_address
    Scenario: nmtui - wifi_hwsim - bogus spoofing address
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
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


    @fedoraver+=32
    @simwifi @ifcfg-rh
    @nmtui_simwifi_mtu
    Scenario: nmtui - wifi_hwsim - mtu
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "open"
    * Set "MTU" field to "512"
    * Ensure "Automatically connect" is not checked
    * Confirm the connection settings
    Then "MTU=512" is visible with command "cat /etc/sysconfig/network-scripts/ifcfg-wifi1"


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wpa1_connection
    Scenario: nmtui - wifi_hwsim - WPA1 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wpa1-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "secret123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: wpa1-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wpa2_connection
    Scenario: nmtui - wifi_hwsim - WPA2 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wpa2-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "secret123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: wpa2-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @rhelver+=8.2 @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wpa3_connection
    Scenario: nmtui - wifi_hwsim - WPA3 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wpa3"
    * Set "Security" dropdown to "WPA3 Personal"
    * Set "Password" field to "secret123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: wpa3" is visible with command "iw dev wlan0 link" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wep_hexkey_connection
    Scenario: nmtui - wifi_hwsim - WEP hex key connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wep-2"
    * Set "Security" dropdown to "WEP 40/128-bit Key \(Hex or ASCII\)"
    * Set "Key" field to "74657374696E67313233343536"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: wep" is visible with command "iw dev wlan0 link" in "30" seconds


    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_wep_ascii_connection
    Scenario: nmtui - wifi_hwsim - WEP ascii connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wep"
    * Set "Security" dropdown to "WEP 40/128-bit Key \(Hex or ASCII\)"
    * Set "Key" field to "abcde"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: wep" is visible with command "iw dev wlan0 link" in "30" seconds


    # mac80211_hwsim does not support WEP 128-bit Passphrase
    #@simwifi
    #@nmtui_simwifi_wep_passphrase_connection
    #Scenario: nmtui - wifi_hwsim - WEP passphrase connection
    #* Prepare new connection of type "Wi-Fi" named "wifi1"
    #* Set "Device" field to "wlan0"
    #* Set "SSID" field to "wep-2"
    #* Set "Security" dropdown to "WEP 128-bit Passphrase"
    #* Set "Password" field to "testing123456"
    #* Confirm the connection settings
    #Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    #Then "SSID: wep" is visible with command "iw dev wlan0 link" in "30" seconds


#### Note TUI doesn't support enterprise and dynamic wep yet, tests will be added when support done. ####
    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_show_password
    Scenario: nmtui - wifi_hwsim - show password
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "wpa1-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "testingpassword"
    * Execute "sleep 0.5"
    * ".*\*\*\*\*\*\*\*\*.*" is visible on screen
    * Ensure "Show password" is checked
    * Execute "sleep 0.5"
    Then ".*testingpassword.*" is visible on screen


    @bz1132612
    @fedoraver+=32
    @simwifi
    @nmtui_simwifi_connect_to_network_after_dismissal
    Scenario: nmtui - wifi_hwsim - connect to a network after dialog dismissal
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for at least "2" seconds
    * Press "<Cancel>" button in the password dialog
    * Execute "sleep 1"
    * ".*Could not activate connection.*Activation failed.*" is visible on screen
    * Press "ENTER" key
    * Get back to the connection list
    * Select connection "wpa2-psk" in the list
    * Choose to "<Activate>" a connection
    * Set current field to "secret123"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @simwifi_teardown
    @nmtui_simwifi_teardown
    Scenario: teardown wifi setup
    * Execute "echo 'this is skipped'"
