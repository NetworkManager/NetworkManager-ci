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


    @rhelver+=8.3 @fedoraver-=0
    @ver+=1.28
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip_manual_gateway_hostname
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:GW:NETMASK:HOSTNAME
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:192.168.50.1:/client ro               |
      | kernel | ip=192.168.50.201::192.168.50.1:255.255.255.0:dracut-nfs-client:52-54-00-12-34-00:none |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.201        |
      | check  | ip_route_unique "default via 192.168.50.1 dev ens2"                                   |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2 proto kernel scope link src 192.168.50.201" |
      | check  | ip4_forever 192.168.50.201 ens2                     |
      | check  | nmcli_con_active '52\:54\:00\:12\:34\:00' ens2 |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      # https://bugzilla.redhat.com/show_bug.cgi?id=1881974
      #| check  | hostname_check dracut-nfs-client               |
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
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ro         |
      | kernel | ip=dhcp6                                       |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::1:10       |
      | check  | wait_for_ip6_renew deaf:beef::1:10 ens2        |
      | check  | ip6_route_unique "deaf:beef::/64 dev ens2 proto ra" |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server [deaf:beef::1]                      |


    @rhelver+=8.3 @fedoraver-=0
    @ver+=1.28
    @dracut @long
    @dracut_NM_NFS_root_nfs_ip6_manual_gateway_hostname
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP6:GW:NETMASK:HOSTNAME
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ro         |
      | kernel | ip=[deaf:beef::ac:1]::[deaf:beef::1]:64:dracut-nfs-client-6:52-54-00-12-34-00:none |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::ac:1       |
      | check  | ip6_route_unique "default via deaf:beef::1 dev ens2"    |
      | check  | ip6_route_unique "deaf:beef::/64 dev ens2 proto kernel" |
      | check  | ip6_forever deaf:beef::ac: ens2                         |
      | check  | nmcli_con_active '52\:54\:00\:12\:34\:00' ens2     |
      | check  | nmcli_con_num 1                                |
      | check  | no_ifcfg                                       |
      # https://bugzilla.redhat.com/show_bug.cgi?id=1881974
      #| check  | hostname_check dracut-nfs-client-6             |
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


    #############
    # bond/team #
    #############


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_bond_over_2_ifaces
    Scenario: NM - dracut - NM module - bond over 2 ifaces
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=dhcp ro                                   |
      | kernel | bond=bond0:ens3,ens4:mode=balance-rr           |
      | qemu   | -netdev socket,id=n1,connect=127.0.0.1:12321   |
      | qemu   | -device e1000,netdev=n1,mac=52:54:00:12:34:10  |
      | qemu   | -netdev socket,id=n2,connect=127.0.0.1:12322   |
      | qemu   | -device e1000,netdev=n2,mac=52:54:00:12:34:11  |
      | check  | ip_ifname bond0 192.168.53.101                 |
      | check  | wait_for_ip4_renew 192.168.53.101 bond0        |
      | check  | ip_route_unique "192.168.53.0/24 dev bond0"    |
      | check  | nmcli_con_active bond0 bond0                   |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_active ens4 ens4                     |
      | check  | nmcli_con_num 3                                |
      | check  | nfs_server 192.168.53.1                        |


    # dracut bug: https://bugzilla.redhat.com/show_bug.cgi?id=1879014
    #@rhelver+=8.3 @fedoraver-=0
    #@dracut @long
    #@dracut_NM_team_over_2_ifaces
    #Scenario: NM - dracut - NM module - team over 2 ifaces
    #* Run dracut test
    #  | Param  | Value                                          |
    #  | kernel | root=dhcp ro                                   |
    #  | kernel | team=team0:ens3,ens4                           |
    #  | qemu   | -netdev socket,id=n1,connect=127.0.0.1:12321   |
    #  | qemu   | -device e1000,netdev=n1,mac=52:54:00:12:34:10  |
    #  | qemu   | -netdev socket,id=n2,connect=127.0.0.1:12322   |
    #  | qemu   | -device e1000,netdev=n2,mac=52:54:00:12:34:11  |
    #  | check  | ip_ifname team0 192.168.53.101                 |
    #  | check  | wait_for_ip4_renew 192.168.53.101 team0        |
    #  | check  | ip_route_unique "192.168.53.0/24 dev team0"    |
    #  | check  | nmcli_con_active team0 team0                   |
    #  | check  | nmcli_con_active ens3 ens3                     |
    #  | check  | nmcli_con_active ens4 ens4                     |
    #  | check  | nmcli_con_num 3                                |
    #  | check  | nfs_server 192.168.53.1                        |


    ########
    # VLAN #
    ########


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_vlan_over_nic
    Scenario: NM - dracut - NM module - VLAN over single NIC
    * Run dracut test
      | Param  | Value                                          |
      | kernel | root=dhcp ro                                   |
      | kernel | vlan=vlan5:ens3                                |
      | qemu   | -netdev socket,id=n7,connect=127.0.0.1:12327   |
      | qemu   | -device e1000,netdev=n7,mac=52:54:00:12:34:11  |
      | check  | ip_ifname vlan5 192.168.55.6                   |
      | check  | wait_for_ip4_renew 192.168.55.6 vlan5          |
      | check  | ip_route_unique "default via 192.168.55.5 dev vlan5" |
      | check  | ip_route_unique "192.168.55.4/30 dev vlan5"    |
      | check  | nmcli_con_active vlan5 vlan5                   |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.55.5                        |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM_vlan_over_everything
    Scenario: NM - dracut - NM module - VLANs over everything (nic, nic, bond, team, bridge)
    # bug bridge part: https://bugzilla.redhat.com/show_bug.cgi?id=1879003
    # bug for bootdev part (nfs_server check): https://bugzilla.redhat.com/show_bug.cgi?id=1879021
    * Run dracut test
      | Param  | Value                                          |
      | timeout | 15m                                           |
      | kernel | root=dhcp ro                                   |
      | kernel | vlan=vlan0005:ens9                             |
      | kernel | vlan=vlan9:ens9                                |
      | kernel | vlan=bond0.13:bond0                            |
      | kernel | bond=bond0:ens3,ens4:mode=balance-rr           |
      | kernel | team=team0:ens5,ens6                           |
      #| kernel | bridge=br0:ens7,ens8                           |
      | kernel | vlan=team0.0017:team0                          |
      #| kernel | vlan=br0.33:br0                                |
      | kernel | ip=vlan9:dhcp                                  |
      | kernel | bootdev=vlan9                                  |
      | qemu   | -netdev socket,id=n1,connect=127.0.0.1:12321   |
      | qemu   | -device e1000,netdev=n1,mac=52:54:00:12:34:11  |
      | qemu   | -netdev socket,id=n2,connect=127.0.0.1:12322   |
      | qemu   | -device e1000,netdev=n2,mac=52:54:00:12:34:12  |
      | qemu   | -netdev socket,id=n3,connect=127.0.0.1:12323   |
      | qemu   | -device e1000,netdev=n3,mac=52:54:00:12:34:13  |
      | qemu   | -netdev socket,id=n4,connect=127.0.0.1:12324   |
      | qemu   | -device e1000,netdev=n4,mac=52:54:00:12:34:14  |
      | qemu   | -netdev socket,id=n5,connect=127.0.0.1:12325   |
      | qemu   | -device e1000,netdev=n5,mac=52:54:00:12:34:15  |
      | qemu   | -netdev socket,id=n6,connect=127.0.0.1:12326   |
      | qemu   | -device e1000,netdev=n6,mac=52:54:00:12:34:16  |
      | qemu   | -netdev socket,id=n7,connect=127.0.0.1:12327   |
      | qemu   | -device e1000,netdev=n7,mac=52:54:00:12:34:17  |
      | check  | ip_ifname bond0 192.168.53.101                 |
      | check  | ip_ifname team0 192.168.54.101                 |
      #| check  | link_no_ip4 br0                                |
      | check  | link_no_ip4 ens3                               |
      | check  | link_no_ip4 ens4                               |
      | check  | link_no_ip4 ens5                               |
      | check  | link_no_ip4 ens6                               |
      | check  | link_no_ip4 ens7                               |
      | check  | link_no_ip4 ens8                               |
      | check  | link_no_ip4 ens9                               |
      | check  | ip_ifname vlan0005 192.168.55.6                |
      | check  | ip_ifname vlan9 192.168.55.10                  |
      | check  | ip_ifname bond0.13 192.168.55.14               |
      | check  | ip_ifname team0.0017 192.168.55.18             |
      #| check  | ip_ifname br0.33 192.168.55.35                 |
      # run IP renew checks simultaneously, `wait` at the end until all checks are finished
      | check  | { wait_for_ip4_renew 192.168.53.101 bond0 & }     |
      | check  | { wait_for_ip4_renew 192.168.54.101 team0 & }     |
      | check  | { wait_for_ip4_renew 192.168.55.6 vlan0005 & }    |
      | check  | { wait_for_ip4_renew 192.168.55.10 vlan9 & }      |
      | check  | { wait_for_ip4_renew 192.168.55.14 bond0.13 & }   |
      | check  | { wait_for_ip4_renew 192.168.55.18 team0.0017 & } |
      #| check  | { wait_for_ip4_renew 192.168.55.35 br0.33 & }     |
      | check  | wait                                              |
      | check  | ip_route_unique "192.168.53.0/24 dev bond0"       |
      | check  | ip_route_unique "192.168.54.0/24 dev team0"       |
      | check  | ip_route_unique "192.168.55.4/30 dev vlan0005"    |
      | check  | ip_route_unique "192.168.55.8/30 dev vlan9"       |
      | check  | ip_route_unique "192.168.55.12/30 dev bond0.13"   |
      | check  | ip_route_unique "192.168.55.16/30 dev team0.0017" |
      #| check  | ip_route_unique "192.168.55.32/29 dev br0.33"     |
      | check  | ip_route_unique "default via 192.168.53.1 dev bond0"       |
      | check  | ip_route_unique "default via 192.168.54.1 dev team0"       |
      | check  | ip_route_unique "default via 192.168.55.5 dev vlan0005"    |
      | check  | ip_route_unique "default via 192.168.55.9 dev vlan9"       |
      | check  | ip_route_unique "default via 192.168.55.13 dev bond0.13"   |
      | check  | ip_route_unique "default via 192.168.55.17 dev team0.0017" |
      #| check  | ip_route_unique "default via 192.168.55.33 dev br0.33"     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_active ens4 ens4                     |
      | check  | nmcli_con_active bond0 bond0                   |
      | check  | nmcli_con_active bond0.13 bond0.13             |
      | check  | nmcli_con_active ens5 ens5                     |
      | check  | nmcli_con_active ens6 ens6                     |
      | check  | nmcli_con_active team0 team0                   |
      | check  | nmcli_con_active team0.0017 team0.0017         |
      #| check  | nmcli_con_active ens7 ens7                     |
      #| check  | nmcli_con_active ens8 ens8                     |
      #| check  | nmcli_con_active br0 br0                       |
      #| check  | nmcli_con_active br0.33 br0.33                 |
      | check  | nmcli_con_active vlan0005 vlan0005             |
      | check  | nmcli_con_active vlan9 vlan9                   |
      #| check  | nmcli_con_num 14                               |
      | check  | nmcli_con_num 10                               |
      #| check  | nfs_server 192.168.55.10                       |


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
      # unique routes do no works with legacy
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
