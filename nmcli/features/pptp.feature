 Feature: nmcli: pptp

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+/-=1.4.1)
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @pptp
    @pptp_add_profile
    Scenario: nmcli - pptp - add and connect a connection
    * Add a connection named "pptp" for device "\*" to "pptp" VPN
    * Use user "budulinek" with password "passwd" and MPPE set to "yes" for gateway "127.0.0.1" on PPTP connection "pptp"
    * Bring "up" connection "pptp"
    Then "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show pptp"
    Then "IP4.ADDRESS.*172.31.66.*/32" is visible with command "nmcli c show pptp"

    @pptp
    @pptp_terminate
    Scenario: nmcli - pptp - terminate connection
    * Add a connection named "pptp" for device "\*" to "pptp" VPN
    * Use user "budulinek" with password "passwd" and MPPE set to "yes" for gateway "127.0.0.1" on PPTP connection "pptp"
    * Execute "nmcli c modify pptp vpn.persistent true"
    * Bring "up" connection "pptp"
    When "VPN.VPN-STATE:.*VPN connected" is visible with command "nmcli c show pptp"
    * Execute "pkill -f nm-pptp-pppd-plugin"
    Then "VPN.VPN-STATE:.*VPN connected" is not visible with command "nmcli c show pptp" in "5" seconds
