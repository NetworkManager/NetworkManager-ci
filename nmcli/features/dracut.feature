Feature: NM: dracut

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    #########
    # NFSv3 #
    #########


    @rhbz1710935
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_dhcp
    Scenario: NM - dracut - NM module - NFSv3 root=dhcp
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=dhcp ro                                   |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | ip_route_unique "default via 192.168.50.1"     |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2"     |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | wait_for_ip4_renew 192.168.50.101 ens2         |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_dhcp_ip_dhcp_neednet
    Scenario: NM - dracut - NM module - NFSv3 root=dhcp ip=dhcp neednet
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=dhcp ro ip=dhcp rd.neednet=1              |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | ip_route_unique "default via 192.168.50.1"     |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2"     |
      | check  | wait_for_ip4_renew 192.168.50.101 ens2         |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_nfsroot_ip_dhcp
    Scenario: NM - dracut - NM module - NFSv3 nfsroot= ip=dhcp
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=/dev/nfs nfsroot=192.168.50.1:/client ro  |
      | kernel | ip=dhcp                                        |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | ip_route_unique "default via 192.168.50.1"     |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2"     |
      | check  | wait_for_ip4_renew 192.168.50.101 ens2         |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip_manual
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=manual
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/client ro               |
      | kernel | ip=192.168.50.201::255.255.255.0:::ens2:off    |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.201        |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2"     |
      | check  | ip4_forever 192.168.50.201 ens2                |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip_manual_dhcp
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=manual:dhcp
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/client ro               |
      | kernel | ip=192.168.50.201::255.255.255.0:::ens2:dhcp   |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.201        |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2 proto kernel scope link src 192.168.50.101" |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2 proto kernel scope link src 192.168.50.201" |
      | check  | wait_for_ip4_renew 192.168.50.101 ens2         |
      | check  | ip4_forever 192.168.50.201 ens2                |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |


    @rhbz1872299
    @ver+=1.26
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_dhcp_vendor_class
    Scenario: NM - dracut - NM module - NFSv3 root=nfs rd.net.dhcp.vendor-class
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=dhcp ro                                   |
      | kernel | rd.net.dhcp.vendor-class=RedHat                |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.102        |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2 proto kernel scope link src 192.168.50.102" |
      | check  | wait_for_ip4_renew 192.168.50.102 ens2         |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_prop "Wired Connection" ipv4.dhcp-vendor-class-identifier RedHat |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.2                        |


    @rhbz1854323
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip_auto6
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=auto6
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ip=auto6   |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::1:10       |
      | check  | wait_for_ip6_renew deaf:beef::1:10 ens2        |
      | check  | ip6_route_unique "deaf:beef::/64 dev ens2 proto ra" |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server [deaf:beef::1]                      |


    @rhbz1854323
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip_dhcp6
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp6
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ip=dhcp6   |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::1:10       |
      | check  | wait_for_ip6_renew deaf:beef::1:10 ens2        |
      | check  | ip6_route_unique "deaf:beef::/64 dev ens2 proto ra" |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server [deaf:beef::1]                      |


    @rhbz1840989
    @ver+=1.26
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_NFS_root_nfs_ipv6_disable
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ipv6.disable
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/client ro               |
      | kernel | ipv6.disable=1                                 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2 proto kernel scope link src 192.168.50.101" |
      | check  | wait_for_ip4_renew 192.168.50.101 ens2         |
      | check  | link_no_ip6 ens2                               |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | nfs_server 192.168.50.1                        |
      | check  | reproduce_1840989                              |


    #########
    # iSCSI #
    #########


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_iSCSI_netroot_dhcp
    Scenario: NM - dracut - NM module - iSCSI netroot=dhcp
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=/dev/root netroot=dhcp                    |
      | kernel | rw rd.auto rd.iscsi.initiator=$(iscsi-iname)   |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | wait_for_ip4_renew 192.168.51.101 ens2         |
      | check  | ip_route_unique "default via 192.168.51.1"     |
      | check  | ip_route_unique "192.168.51.0/24 dev ens2"     |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | mount_root_type ext3                           |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_iSCSI_netroot_dhcp_ip_dhcp
    Scenario: NM - dracut - NM module - iSCSI netroot=dhcp ip=ens2:dhcp
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=/dev/root netroot=dhcp ip=ens2:dhcp       |
      | kernel | rw rd.auto rd.iscsi.initiator=$(iscsi-iname)   |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | wait_for_ip4_renew 192.168.51.101 ens2         |
      | check  | ip_route_unique "default via 192.168.51.1"     |
      | check  | ip_route_unique "192.168.51.0/24 dev ens2"     |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      | check  | mount_root_type ext3                           |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_iSCSI_ibft_table
    Scenario: NM - dracut - NM module - iSCSI ibft.table
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=LABEL=singleroot                          |
      | kernel | rd.iscsi.ibft=1 rd.iscsi.firmware=1            |
      | kernel | rw rd.auto                                     |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | qemu   | -acpitable file=conf/ibft.table                |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | wait_for_ip4_renew 192.168.51.101 ens2         |
      | check  | ip_route_unique "default via 192.168.51.1"     |
      | check  | ip_route_unique "192.168.51.0/24 dev ens2"     |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active "iBFT Connection 0" ens2      |
      | check  | nmcli_con_num 1                                |
      | check  | mount_root_type ext3                           |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_iSCSI_multiple_targets
    Scenario: NM - dracut - NM module - iSCSI 2 targets in RAID0
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=LABEL=sysroot rw rd.auto                  |
      | kernel | ip=192.168.51.101::192.168.51.1:255.255.255.0::ens2:off  |
      | kernel | ip=192.168.52.101::192.168.52.1:255.255.255.0::ens3:off  |
      | kernel | netroot=iscsi:192.168.52.1::::iqn.2009-06.dracut:target1 |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target2 |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | kernel | rd.iscsi.firmware rd.iscsi.waitnet=0           |
      | kernel | rd.iscsi.testroute=0                           |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | ip_mac 52:54:00:12:34:a2 192.168.52.101        |
      | check  | ip4_forever 192.168.51.101 ens2                |
      | check  | ip4_forever 192.168.52.101 ens3                |
      | check  | ip_route_unique "default via 192.168.51.1"     |
      | check  | ip_route_unique "192.168.51.0/24 dev ens2"     |
      | check  | ip_route_unique "default via 192.168.52.1"     |
      | check  | ip_route_unique "192.168.52.0/24 dev ens3"     |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |


    ##########
    # bridge #
    ##########


    @rhbz1627820
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_bridge_eth0
    Scenario: NM - dracut - NM module - bridge over eth0
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/nfs/client ro           |
      | kernel | bridge net.ifnames=0                           |
      | qemu   | -net nic,macaddr=52:54:00:12:34:01,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_ifname br0 192.168.50.101                   |
      | check  | wait_for_ip4_renew 192.168.50.101 br0          |
      | check  | ip_route_unique "default via 192.168.50.1"     |
      | check  | ip_route_unique "192.168.50.0/24 dev br0"      |
      | check  | nmcli_con_active br0 br0                       |
      | check  | nmcli_con_active eth0 eth0                     |
      | check  | nmcli_con_num 2                                |
      | check  | nfs_server 192.168.50.1                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_bridge_custom_name_2_ifaces
    Scenario: NM - dracut - NM module - custom bridge name over 2 ifaces
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/nfs/client ro           |
      | kernel | bridge=foobr0:ens3,ens4                        |
      | kernel | ip=192.168.50.101:::255.255.255.0::foobr0:off  |
      | qemu   | -netdev socket,id=n0,connect=127.0.0.1:12320   |
      | qemu   | -device e1000,netdev=n0,mac=52:54:00:12:34:00  |
      | qemu   | -netdev socket,id=n1,connect=127.0.0.1:12321   |
      | qemu   | -device e1000,netdev=n1,mac=52:54:00:12:34:01  |
      | check  | ip_ifname foobr0 192.168.50.101                |
      | check  | ip4_forever 192.168.50.101 foobr0              |
      | check  | ip_route_unique "192.168.50.0/24 dev foobr0"   |
      | check  | nmcli_con_active foobr0 foobr0                 |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_active ens4 ens4                     |
      | check  | nmcli_con_num 3                                |
      | check  | nfs_server 192.168.50.1                        |


    ##########
    # legacy #
    ##########


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_legacy_iSCSI_ibft_table
    Scenario: NM - dracut - legacy module - iSCSI ibft table
    * Run dracut test
      | Param  | Value                                          |
      | initrd | initramfs.client.legacy                        |
      | kernel | root=LABEL=singleroot rd.iscsi.ibft=1          |
      | kernel | rd.iscsi.firmware=1                            |
      | kernel | rw rd.auto                                     |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | qemu   | -acpitable file=conf/ibft.table                |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | wait_for_ip4_renew 192.168.51.101 ibft0        |
      # unique route no works with legacy
      #| check  | ip_route_unique "default via 192.168.51.1"     |
      #| check  | ip_route_unique "192.168.51.0/24 dev ibft0"    |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active ibft0 ibft0                   |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |


    ############
    # teardown #
    ############


    @rhelver+=8.3 @fedoraver-=0
    @dracut_clean
    Scenario: NM - dracut tests cleanup and log collection
    * Execute "true"
