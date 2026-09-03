Feature: nmcli: bluetooth

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @ver+=1.58
    @restart_if_needed
    @bt_dun
    @bluetooth_dun_sdp_error_no_crash
    Scenario: nmcli - bluetooth - DUN SDP error does not crash NM
    * Add "bluetooth" connection named "bt-dun" with options "bluetooth.bdaddr 00:AA:01:01:00:01 bluetooth.type dun gsm.apn test autoconnect no"
    Then "00:AA:01:01:00:01" is visible with command "nmcli device status" in "5" seconds
    * Execute "nmcli con up bt-dun || true"
    Then "SDP search failed\|failed to connect to the SDP server" is visible with command "journalctl -u NetworkManager --no-pager -n 50"
