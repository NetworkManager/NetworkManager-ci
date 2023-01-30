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
    Then ".*qe-wpa1-psk.*" is visible on screen
    Then ".*qe-wpa2-psk.*" is visible on screen
    Then ".*qe-wpa3-psk.*" is visible on screen
    Then ".*qe-wpa1-enterprise.*" is visible on screen
    Then ".*qe-wpa2-enterprise.*" is visible on screen
    Then ".*qe-wpa3-enterprise-aes.*" is visible on screen


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_connect_to_open_network
    Scenario: nmtui - wifi - connect to open network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-open" in the list
    * Choose to "<Activate>" a connection
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @attach_wpa_supplicant_log
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


    @wifi @attach_wpa_supplicant_log
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


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_connect_to_wpa3psk_network
    Scenario: nmtui - wifi - connect to WPA3-PSK network straight
    * Start nmtui
    * Choose to "Activate a connection" from main screen
    * Select connection "qe-wpa3-psk" in the list
    * Choose to "<Activate>" a connection
    * Wait for "2" seconds
    * ".*Authentication required.*" is visible on screen
    * Set current field to "over the river and through the woods"
    * Press "ENTER" key
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_add_default_connection_open_network
    Scenario: nmtui - wifi - add default connection open network
    * Prepare new connection of type "Wi-Fi" named "wifi"
    * Set "SSID" field to "qe-open"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds


    @wifi @attach_wpa_supplicant_log
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


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa1
    Scenario: nmtui - wifi - WPA1 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa1-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa1-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa2
    Scenario: nmtui - wifi - WPA2 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa2-psk"
    * Set "Security" dropdown to "WPA & WPA2 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa2-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa3
    Scenario: nmtui - wifi - WPA3 psk connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa3-psk"
    * Set "Security" dropdown to "WPA3 Personal"
    * Set "Password" field to "over the river and through the woods"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa3-psk" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa1_enterprise_tls
    Scenario: nmtui - wifi - WPA enterprise tls connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa1-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "TLS"
    * Set "Identity" field to "Bill Smith"
    * Set "CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "User\s+cert" field to "file:///tmp/certs/client.pem"
    * Set "User\s+private\s+key" field to "file:///tmp/certs/client.pem"
    * Set "User\s+privkey\s+password" field to "12345testing"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa1-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa1_enterprise_peap_mschapv2
    Scenario: nmtui - wifi - WPA enterprise peap connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa1-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "PEAP"
    * Set "Anonymous\s+identity" field to "anonymous"
    * Set "CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "Inner\s+authentication" dropdown to "MSCHAPv2"
    * Set "Username" field to "Bill Smith"
    * Set "Password" field to "testing123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa1-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa1_enterprise_ttls_mschapv2
    Scenario: nmtui - wifi - WPA enterprise peap connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa1-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "TTLS"
    * Set "Anonymous\s+identity" field to "anonymous"
    * Set "CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "Inner authentication" dropdown to "MSCHAPv2"
    * Set "Username" field to "Bill Smith"
    * Set "Password" field to "testing123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa1-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa2_enterprise_tls
    Scenario: nmtui - wifi - WPA2 enterprise tls connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa2-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "TLS"
    * Set "Identity" field to "Bill Smith"
    * Set "CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "User\s+cert" field to "file:///tmp/certs/client.pem"
    * Set "User\s+private\s+key" field to "file:///tmp/certs/client.pem"
    * Set "User\s+privkey\s+password" field to "12345testing"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa2-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa2_enterprise_peap_mschapv2
    Scenario: nmtui - wifi - WPA2 enterprise peap connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Come in "WI-FI" category
    * Set "SSID" field to "qe-wpa2-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "PEAP"
    * Set "\s*Anonymous\s+identity" field to "anonymous"
    * Set "\s*CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "Inner\s+authentication" dropdown to "MSCHAPv2"
    * Set "Username" field to "Bill Smith"
    * Set "Password" field to "testing123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa2-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds


    @ver+=1.41
    @wifi @attach_wpa_supplicant_log
    @nmtui_wifi_wpa2_enterprise_ttls_mschapv2
    Scenario: nmtui - wifi - WPA2 enterprise peap connection
    * Prepare new connection of type "Wi-Fi" named "wifi1"
    * Set "Device" field to "wlan0"
    * Set "SSID" field to "qe-wpa2-enterprise"
    * Set "Security" dropdown to "WPA & WPA2 Enterprise"
    * Set "Authentication" dropdown to "TTLS"
    * Set "Anonymous\s+identity" field to "anonymous"
    * Set "CA\s+cert" field to "file:///tmp/certs/eaptest_ca_cert.pem"
    * Set "Inner\s+authentication" dropdown to "MSCHAPv2"
    * Set "Username" field to "Bill Smith"
    * Set "Password" field to "testing123"
    * Confirm the connection settings
    Then "inet 10." is visible with command "ip a s wlan0" in "30" seconds
    Then "SSID: qe-wpa2-enterprise" is visible with command "iw dev wlan0 link" in "30" seconds
