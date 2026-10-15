 Feature: nmcli: dcb

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz1774409
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

    # ETS (priority groups) - verify prio-to-TC mapping
    Then "prio-tc 0:0 1:0 2:0 3:0 4:1 5:1 6:1 7:1" is visible with command "dcb ets show dev sriov_device"

    # PFC - verify per-priority flow control
    Then "prio-pfc 0:on 1:off 2:off 3:on 4:on 5:off 6:on 7:off" is visible with command "dcb pfc show dev sriov_device"

    # APP - verify FCoE (ethtype 0x8906), iSCSI (port 3260), FIP (ethtype 0x8914)
    Then "8906:7" is visible with command "dcb app show dev sriov_device"
    Then "3260:6" is visible with command "dcb app show dev sriov_device"
    Then "8914:2" is visible with command "dcb app show dev sriov_device"


    @rhbz1774409
    @dcb_disable_connection
    Scenario: nmcli - dcb - disable connection
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
    * Disconnect device "sriov_device"
    # PFC should be reset after disconnect
    Then "prio-pfc 0:off 1:off 2:off 3:off 4:off 5:off 6:off 7:off" is visible with command "dcb pfc show dev sriov_device" in "5" seconds
    # APP entries should be removed
    Then "8906" is not visible with command "dcb app show dev sriov_device"
    Then "3260" is not visible with command "dcb app show dev sriov_device"
    Then "8914" is not visible with command "dcb app show dev sriov_device"


    @rhbz1774409
    @dcb_enable_after_reboot
    Scenario: nmcli - dcb - enable after reboot
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
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show dcb" in "40" seconds
    * Reboot
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show dcb" in "40" seconds

    # ETS (priority groups) - verify prio-to-TC mapping persists after reboot
    Then "prio-tc 0:0 1:0 2:0 3:0 4:1 5:1 6:1 7:1" is visible with command "dcb ets show dev sriov_device"

    # PFC
    Then "prio-pfc 0:on 1:off 2:off 3:on 4:on 5:off 6:on 7:off" is visible with command "dcb pfc show dev sriov_device"

    # APP
    Then "8906:7" is visible with command "dcb app show dev sriov_device"
    Then "3260:6" is visible with command "dcb app show dev sriov_device"
    Then "8914:2" is visible with command "dcb app show dev sriov_device"


    @rhbz1080510
    @dcb_error_shown
    Scenario: nmcli - dcb - error shown
    * Add "ethernet" connection named "dcb" for device "sriov_device"
    * Open editor for connection "dcb"
    * Prepare connection
    * Set default DCB options
    * Submit "set dcb.app-fcoe-priority 8" in editor
    Then Error type "failed to set 'app-fcoe-priority' property: '8' is out of range \[-1, 7\]" shown in editor
