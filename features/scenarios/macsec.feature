 Feature: nmcli: macsec

     # Please do use tags as follows:
     # @bugzilla_link (rhbz123456)
     # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
     # @other_tags (see environment.py)
     # @test_name (compiled from scenario name)
     # Scenario:

    @rhbz1337997
    @ver+=1.6.0
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_psk
    Scenario: NM - macsec - MACsec PSK
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring "up" connection "test-macsec-base"
    * Bring "up" connection "test-macsec"
    Then Ping "172.16.10.1" "10" times


    @rhbz2122564
    @ver+=1.41.0
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_reboot
    Scenario: NM - macsec - MACsec PSK
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          autoconnect yes
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect yes
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring "up" connection "test-macsec-base"
    * Bring "up" connection "test-macsec"
    Then Ping "172.16.10.1" "10" times
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-base" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec" in "45" seconds
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-base" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec" in "45" seconds


    @rhbz2122564
    @ver+=1.41.0
    @macsec @not_on_aarch64_but_pegas
    @macsec_vlan_reboot
    Scenario: NM - macsec - MACsec PSK on VLAN
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100" on VLAN "42"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          autoconnect yes
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "vlan" connection named "test-macsec-vlan" for device "macsec_veth.42" with options
          """
          autoconnect yes
          ipv4.method disabled
          ipv6.method ignore
          vlan.parent macsec_veth
          vlan.id 42
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect yes
          macsec.parent macsec_veth.42
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring "up" connection "test-macsec-base"
    * Bring "up" connection "test-macsec-vlan"
    * Bring "up" connection "test-macsec"
    Then Ping "172.16.10.1" "10" times
    * Restart NM
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-base" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-vlan" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec" in "45" seconds
    * Reboot
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-base" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec-vlan" in "45" seconds
    Then "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec" in "45" seconds


    @rhbz1723690
    @ver+=1.18 @rhelver+=8
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_set_mtu_from_parent
    Scenario: NM - macsec - MACsec MTU from parent
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          802-3-ethernet.mtu 1536
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    * Bring "up" connection "test-macsec-base"
    * Bring "up" connection "test-macsec"
    When "1536" is visible with command "ip a s macsec_veth"
    When "1504" is visible with command "ip a s macsec0"
    * Bring "up" connection "test-macsec-base"
    Then "1536" is visible with command "ip a s macsec_veth"
    Then "1504" is visible with command "ip a s macsec0"


    @rhbz1588041
    @ver+=1.12
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_send-sci_by_default
    Scenario: NM - macsec - MACsec send-sci option should be true by default
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Add "ethernet" connection named "test-macsec-base" for device "macsec_veth" with options
          """
          ipv4.method disabled
          ipv6.method ignore
          """
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    Then "yes" is visible with command "nmcli -f macsec.send-sci con show test-macsec"
    * Bring "up" connection "test-macsec-base"
    * Bring "up" connection "test-macsec"
    Then "send_sci on" is visible with command "ip macsec show macsec0"


    @rhbz2110307
    @ver+=1.41.3
    @macsec @not_on_aarch64_but_pegas @long
    @macsec_managed_macsec_from_unmanaged_parent
    Scenario: NM - macsec - MACsec managed from an unmanaged parent
    * Prepare MACsec PSK environment with CAK "00112233445566778899001122334455" and CKN "5544332211009988776655443322110055443322110099887766554433221100"
    * Execute "nmcli device set macsec_veth managed off"
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect yes
          macsec.parent macsec_veth
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          """
    When "activated" is visible with command "nmcli -g GENERAL.STATE con show test-macsec" in "45" seconds
    Then Ping "172.16.10.1" "10" times


    @RHEL-24337
    @ver+=1.46
    @rhelver+=9.4
    @prepare_patched_netdevsim
    @macsec_offload
    Scenario: NM - macsec - check macsec offload flag
    * Skip if next step fails:
    * "on" is visible with command "ethtool -k eth12 | grep -i macsec-hw-offload"
    * Add "macsec" connection named "test-macsec" for device "macsec0" with options
          """
          autoconnect no
          ipv4.method manual
          ipv4.addresses 192.168.6.8/24
          macsec.parent eth12
          macsec.mode psk
          macsec.mka-cak 00112233445566778899001122334455
          macsec.mka-ckn 5544332211009988776655443322110055443322110099887766554433221100
          macsec.validation disable
          macsec.offload mac
          """
    * Bring "up" connection "test-macsec"
    Then "offload mac" is visible with command "ip -d l show dev macsec0"
    * Commentary
    """
    macsec.offload=phy isn't supported by netdevsim
    """
    * Modify connection "test-macsec" changing options "macsec.offload off"
    * Bring "up" connection "test-macsec"
    Then "offload off" is visible with command "ip -d l show dev macsec0"