Feature: NM: dracut

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhbz1710935 @rhbz1627820
    @rhelver+=8.3 @fedoraver-=0
    @dracut @long
    @dracut_NM
    Scenario: NM - dracut tests with network-manager module
    * Run dracut test
      | descr  | NFSv3 root=dhcp DHCP path only                 |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 Legacy root=/dev/nfs nfsroot=IP:path     |
      | kernel | root=/dev/nfs nfsroot=192.168.50.1:/nfs/client |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:01,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:01 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
    * Run dracut test
      | descr  | NFSv3 Legacy root=/dev/nfs DHCP path only      |
      | kernel | root=/dev/nfs                                  |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 Legacy root=/dev/nfs DHCP IP:path        |
      | kernel | root=/dev/nfs                                  |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:01,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:01 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.2                        |
    * Run dracut test
      | descr  | NFSv3 DHCP IP:path                             |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:01,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:01 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.2                        |
    * Run dracut test
      | descr  | NFSv3 DHCP proto:IP:path                       |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:02,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:02 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.3                        |
    * Run dracut test
      | descr  | NFSv3 DHCP proto:IP:path:options               |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:03,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:03 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.3                        |
    * Run dracut test
      | descr  | NFSv3 root=nfs:...                             |
      | kernel | root=nfs:192.168.50.1:/nfs/client              |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:04,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:04 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 Bridge root=nfs:...                      |
      | kernel | root=nfs:192.168.50.1:/nfs/client              |
      | kernel | bridge net.ifnames=0                           |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:04,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_ifname br0 192.168.50.101                   |
      | check  | nmcli_con_active br0 br0                       |
      | check  | nmcli_con_active eth0 eth0                     |
      | check  | nmcli_con_num 2                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 Legacy root=IP:path                      |
      | kernel | root=192.168.50.1:/nfs/client                  |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:04,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:04 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 DHCP path,options                        |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:05,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:05 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 Bridge custom DHCP path,options          |
      | kernel | root=dhcp bridge=foobr0:ens2                   |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:05,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_ifname foobr0 192.168.50.101                |
      | check  | nmcli_con_active foobr0 foobr0                 |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 2                                |
      | check  | nfs_server 192.168.50.1                        |
    * Run dracut test
      | descr  | NFSv3 DHCP IP:path,options                     |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:06,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:06 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.2                        |
    * Run dracut test
      | descr  | NFSv3 DHCP proto:IP:path,options               |
      | kernel | root=dhcp                                      |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:07,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:07 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.3                        |
    * Run dracut test
      | descr  | @rhbz1627820 NFSv3 DHCP lease renewal bridge   |
      | kernel | root=dhcp bridge net.ifnames=0                 |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:08,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_ifname br0 192.168.50.101                   |
      | check  | nmcli_con_active br0 br0                       |
      | check  | nmcli_con_active eth0 eth0                     |
      | check  | nmcli_con_num 2                                |
      | check  | nfs_server 192.168.50.3                        |
      | check  | wait_for_ip_renew br0                          |
    * Run dracut test
      | descr  | @rhbz1710935 NFSv3 DHCP rd.neednet=1           |
      | kernel | root=dhcp rd.neednet=1                         |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 192.168.50.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server 192.168.50.1                        |
      | check  | ip_route_unique "default via 192.168.50.1"     |
      | check  | ip_route_unique "192.168.50.0/24 dev ens2"     |
    * Run dracut test
      | descr  | @rhbz1854323 NFSv3 root=nfs:[ipv6]... ip=auto6 |
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ip=auto6   |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::1          |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server [deaf:beef::1]                      |
    * Run dracut test
      | descr  | @rhbz1854323 NFSv3 root=nfs:[ipv6]... ip=dhcp6 |
      | kernel | root=nfs:[deaf:beef::1]:/nfs/client ip=dhcp6   |
      | kernel | ro                                             |
      | qemu   | -net nic,macaddr=52:54:00:12:34:00,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:00 deaf:beef::1          |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_num 1                                |
      | check  | nfs_server [deaf:beef::1]                      |
    * Run dracut test
      | descr  | iSCSI root=dhcp                                |
      | kernel | root=/dev/root netroot=dhcp ip=ens2:dhcp       |
      | kernel | rw rd.auto                                     |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 1                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI netroot=iscsi target0                    |
      | kernel | root=LABEL=singleroot                          |
      | kernel | rw rd.auto                                     |
      | kernel | ip=192.168.51.101::192.168.51.1:255.255.255.0:iscsi-1:ens2:off |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target0       |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_num 1                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI root=ibft                                |
      | kernel | root=LABEL=singleroot rd.iscsi.ibft=1          |
      | kernel | rd.iscsi.firmware=1                            |
      | kernel | rw rd.auto                                     |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | qemu   | -acpitable file=conf/ibft.table                |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active "iBFT Connection 0" ens2      |
      | check  | nmcli_con_num 1                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI netroot=iscsi target1 target2            |
      | kernel | root=LABEL=sysroot ip=dhcp                     |
      | kernel | rw rd.auto                                     |
      | kernel | netroot=iscsi:192.168.52.1::::iqn.2009-06.dracut:target1 |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target2 |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | ip_mac 52:54:00:12:34:a2 192.168.52.101        |
      | check  | nmcli_con_active "Wired Connection" ens2       |
      | check  | nmcli_con_active "Wired Connection" ens3       |
      | check  | nmcli_con_num 1                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI netroot=iscsi target1 target2 manual     |
      | kernel | root=LABEL=sysroot                             |
      | kernel | rw rd.auto                                     |
      | kernel | ip=192.168.51.101:::255.255.255.0::ens2:off    |
      | kernel | ip=192.168.52.101:::255.255.255.0::ens3:off    |
      | kernel | netroot=iscsi:192.168.52.1::::iqn.2009-06.dracut:target1 |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target2 |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | ip_mac 52:54:00:12:34:a2 192.168.52.101        |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI t1 t2 waitnet=0                          |
      | kernel | root=LABEL=sysroot                             |
      | kernel | ip=192.168.51.101:::255.255.255.0::ens2:off    |
      | kernel | ip=192.168.52.101:::255.255.255.0::ens3:off    |
      | kernel | netroot=iscsi:192.168.52.1::::iqn.2009-06.dracut:target1 |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target2 |
      | kernel | rw rd.auto                                     |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)              |
      | kernel | rd.iscsi.firmware rd.iscsi.waitnet=0           |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | ip_mac 52:54:00:12:34:a2 192.168.52.101        |
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI t1 t2 waitnet=0 testroute=0              |
      | kernel | root=LABEL=sysroot                             |
      | kernel | ip=192.168.51.101:::255.255.255.0::ens2:off    |
      | kernel | ip=192.168.52.101:::255.255.255.0::ens3:off    |
      | kernel | rw rd.auto                                     |
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
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |
    * Run dracut test
      | descr  | iSCSI t1 t2 waitnet=0 testroute=0 default GW   |
      | kernel | root=LABEL=sysroot                             |
      | kernel | rw rd.auto                                     |
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
      | check  | nmcli_con_active ens2 ens2                     |
      | check  | nmcli_con_active ens3 ens3                     |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |


    @rhelver+=8.3 @fedoraver-=0
    @dracut @long @network_legacy
    @dracut_legacy
    Scenario: NM - dracut tests with network-legacy module
    * Run dracut test
      | descr  | iSCSI root=ibft                                |
      | kernel | root=LABEL=singleroot rd.iscsi.ibft=1          |
      | kernel | rd.iscsi.firmware=1                            |
      | kernel | rw rd.auto                                     |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a1,model=e1000 |
      | qemu   | -net nic,macaddr=52:54:00:12:34:a2,model=e1000 |
      | qemu   | -net socket,connect=127.0.0.1:12320            |
      | qemu   | -acpitable file=conf/ibft.table                |
      | check  | ip_mac 52:54:00:12:34:a1 192.168.51.101        |
      | check  | link_no_ip4 ens3                               |
      | check  | nmcli_con_active ibft0 ibft0                   |
      | check  | wait_for_ip_renew ibft0                        |
      | check  | nmcli_con_num 2                                |
      | check  | mount_root_type ext3                           |
