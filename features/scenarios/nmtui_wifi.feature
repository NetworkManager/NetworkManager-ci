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
    Then ".*qe-wpa3-enterprise-aes.*" is visible on screen


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


    @wifi
    @nmtui_wifi_connect_to_wpa3psk_network
    Scenario: nmtui - wifi - connect to WPA2-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wpa3-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "over the river and through the woods"
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


    @wifi
    @nmtui_wifi_wpa3_connection
    Scenario: nmtui - wifi - WPA2 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wpa3-psk"
    * Set "Security" dropdown to "WPA3 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa3-psk" is visible with command "iw dev wlan0 link" in "30" seconds
