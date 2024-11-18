 Feature: nmcli: dcb

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz1774409
    @xfail
    @dcb_enable_connection
    Scenario: nmcli - dcb - enable connection
    * Add "ethernet" connection named "dcb" for device "sriov_device" with options
        """
        ipv4.method manual ipv4.addresses 1.2.3.4/24 ipv6.method ignore
        dcb.app-fcoe-flags 7 dcb.app-fcoe-priority 7 dcb.app-fcoe-mode vn2vn
        dcb.app-iscsi-flags 7 dcb.app-iscsi-priority 6
        dcb.app-fip-flags 7 dcb.app-fip-priority 2
        dcb.priority-flow-control-flags 7
        dcb.priority-flow-control 1,0,0,1,1,0,1,0
        dcb.priority-group-flags 7 dcb.priority-group-id 0,0,0,0,1,1,1,1
        dcb.priority-group-bandwidth 13,13,13,13,12,12,12,12
        dcb.priority-bandwidth 100,100,100,100,100,100,100,100
        dcb.priority-traffic-class 7,6,5,4,3,2,1,0
        """
    * Bring "up" connection "dcb"
    # dcb on
    Then "DCB State:\s+on" is visible with command "dcbtool gc sriov_device dcb"

    # priority groups
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device pg"
    Then "up2tc:\s+0\s+0\s+0\s+0\s+1\s+1\s+1\s+1" is visible with command "dcbtool gc sriov_device pg"
    Then "pgpct:\s+13\%\s+13\%\s+13\%\s+13\%\s+12\%\s+12\%\s+12\%\s+12\%" is visible with command "dcbtool gc sriov_device pg"
    Then "uppct:\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%" is visible with command "dcbtool gc sriov_device pg"

    # priority flow control
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device pfc"
    Then "pfcup:\s+1\s+0\s+0\s+1\s+1\s+0\s+1\s+0" is visible with command "dcbtool gc sriov_device pfc"

     # apps
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:fcoe"
    Then "appcfg:\s+80" is visible with command "dcbtool gc sriov_device app:fcoe"
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:iscsi"
    Then "appcfg:\s+40" is visible with command "dcbtool gc sriov_device app:iscsi"
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:fip"
    Then "appcfg:\s+04" is visible with command "dcbtool gc sriov_device app:fip"


    @rhbz1774409
    @xfail
    @dcb_disable_connection
    Scenario: nmcli - dcb - disable connection
    * Add "ethernet" connection named "dcb" for device "sriov_device" with options
          """
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          """
    #* Open editor for connection "dcb"
    * Prepare connection
    * Set default DCB options
    #* Save in editor
    #* Quit editor
    * Bring "up" connection "dcb"
    * Disconnect device "sriov_device"
    # dcb off
    #Then "DCB State:\s+off" is visible with command "dcbtool gc sriov_device dcb"
    Then "Enable:\s+false" is visible with command "dcbtool gc sriov_device pg" in "5" seconds
    Then "Enable:\s+false" is visible with command "dcbtool gc sriov_device pfc"
    Then "Enable:\s+false" is visible with command "dcbtool gc sriov_device app:fcoe"
    Then "Enable:\s+false" is visible with command "dcbtool gc sriov_device app:iscsi"
    Then "Enable:\s+false" is visible with command "dcbtool gc sriov_device app:fip"


    @rhbz1774409
    @xfail
    @dcb_enable_after_reboot
    Scenario: nmcli - dcb - enable after reboot
    * Add "ethernet" connection named "dcb" for device "sriov_device" with options
          """
          ipv4.addresses 1.2.3.4/24
          ipv4.method manual
          """
    * Prepare connection
    * Set default DCB options
    * Bring "up" connection "dcb"
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show dcb" in "40" seconds
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show dcb" in "40" seconds

    # dcb on
    # Then "DCB State:\s+on" is visible with command "dcbtool gc sriov_device dcb"

    # priority groups
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device pg"
    Then "up2tc:\s+0\s+0\s+0\s+0\s+1\s+1\s+1\s+1" is visible with command "dcbtool gc sriov_device pg"
    Then "pgpct:\s+13\%\s+13\%\s+13\%\s+13\%\s+12\%\s+12\%\s+12\%\s+12\%" is visible with command "dcbtool gc sriov_device pg"
    Then "uppct:\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%\s+100\%" is visible with command "dcbtool gc sriov_device pg"

    # priority flow control
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device pfc"
    Then "pfcup:\s+1\s+0\s+0\s+1\s+1\s+0\s+1\s+0" is visible with command "dcbtool gc sriov_device pfc"

     # apps
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:fcoe"
    Then "appcfg:\s+80" is visible with command "dcbtool gc sriov_device app:fcoe"
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:iscsi"
    Then "appcfg:\s+40" is visible with command "dcbtool gc sriov_device app:iscsi"
    Then "Enable:\s+true\s+Advertise:\s+true\s+Willing:\s+true" is visible with command "dcbtool gc sriov_device app:fip"
    Then "appcfg:\s+04" is visible with command "dcbtool gc sriov_device app:fip"


    @rhbz1080510
    @dcb_error_shown
    Scenario: nmcli - dcb - error shown
    * Add "ethernet" connection named "dcb" for device "sriov_device"
    * Open editor for connection "dcb"
    * Prepare connection
    * Set default DCB options
    * Submit "set dcb.app-fcoe-priority 8" in editor
    Then Error type "failed to set 'app-fcoe-priority' property: '8' is out of range \[-1, 7\]" shown in editor
