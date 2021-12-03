Feature: NM: dracut

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:


    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_setup
    Scenario: NM - dracut - setup test environment
    * Execute "[ -f /tmp/dracut_setup_done ]"


    #########
    # NFSv3 #
    #########


    @rhbz1710935
    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_dhcp
    Scenario: NM - dracut - NM module - NFSv3 root=dhcp
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=dhcp ro                                                           |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | dracut_crash_test                                                      |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl01.nfs.redhat.com       |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search *'nfs.redhat.com'*                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                         |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_dhcp_ip_dhcp_neednet
    Scenario: NM - dracut - NM module - NFSv3 root=dhcp ip=dhcp neednet
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=dhcp ro ip=dhcp rd.neednet=1                                      |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl01.nfs.redhat.com       |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search *'nfs.redhat.com'*                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                         |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_dhcp_ip_dhcp_peerdns0
    Scenario: NM - dracut - NM module - NFSv3 root=dhcp ip=dhcp rd.peerdns=0
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=dhcp ro ip=dhcp rd.peerdns=0                                      |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" ipv4.ignore-auto-dns yes             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS ''                           |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" ipv6.ignore-auto-dns yes             |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS ''                           |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search ''                                                          |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |


    @rhbz1872299
    @ver+=1.25
    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_dhcp_vendor_class
    Scenario: NM - dracut - NM module - NFSv3 root=nfs rd.net.dhcp.vendor-class
    * Run dracut test
      | Param  | Value                                                                      |
      | kernel | root=dhcp ro rd.net.dhcp.vendor-class=RedHat                               |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                        |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                               |
      | check  | nmcli_con_active "Wired Connection" eth0                                   |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                         |
      | check  | nmcli_con_prop "Wired Connection" ipv4.dhcp-vendor-class-identifier RedHat |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.102/24 10         |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*              |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl02.nfs.redhat.com           |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                         |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*               |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10                  |
      | check  | wait_for_ip4_renew 192.168.50.102/24 eth0                                  |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                                |
      | check  | dns_search *'nfs.redhat.com'*                                              |
      | check  | dns_search *'nfs6.redhat.com'*                                             |
      | check  | nmcli_con_num 1                                                            |
      | check  | no_ifcfg                                                                   |
      | check  | ip4_route_unique "default via 192.168.50.1"                                |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                                |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"                   |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                        |
      | check  | nfs_server 192.168.50.2                                                    |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_mtu
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IFNAME:AUTOCONF:MTU
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro ip=eth0:dhcp:1490       |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00      |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 802-3-ethernet.mtu 1490              |
      | check  | nmcli_con_prop eth0 ipv4.method auto                     |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN cl01.nfs.redhat.com       |
      | check  | nmcli_con_prop eth0 ipv6.method auto                     |
      | check  | nmcli_con_prop eth0 IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop eth0 IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop eth0 IP6.DNS deaf:beef::1 10              |
      | check  | ifname_mtu eth0 1490                                     |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0              |
      | check  | dns_search *'nfs.redhat.com'*                            |
      | check  | dns_search *'nfs6.redhat.com'*                           |
      | check  | nmcli_con_num 1                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "default via 192.168.50.1"              |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"              |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel" |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"      |
      | check  | nfs_server 192.168.50.1                                  |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_mtu_cloned_mac
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IFNAME:AUTOCONF:MTU:CMAC
    * Run dracut test
      | Param  | Value                                                                   |
      | kernel | root=nfs:192.168.50.1:/client ro ip=eth0:dhcp:1510:52:54:00:12:34:10    |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                     |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                            |
      | check  | nmcli_con_active eth0 eth0                                              |
      | check  | nmcli_con_prop eth0 802-3-ethernet.mtu 1510                             |
      | check  | nmcli_con_prop eth0 802-3-ethernet.cloned-mac-address 52:54:00:12:34:10 |
      | check  | nmcli_con_prop eth0 ipv4.method auto                                    |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS 192.168.50.101/24 10                    |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.50.1                            |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                         |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.50.1                                |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN cl01.nfs.redhat.com                      |
      | check  | nmcli_con_prop eth0 ipv6.method auto                                    |
      | check  | nmcli_con_prop eth0 IP6.ADDRESS *deaf:beef::1:10/128* 10                |
      | check  | nmcli_con_prop eth0 IP6.ROUTE *deaf:beef::/64*                          |
      | check  | nmcli_con_prop eth0 IP6.DNS deaf:beef::1 10                             |
      | check  | ifname_mtu eth0 1510                                                    |
      | check  | ifname_mac eth0 52:54:00:12:34:10                                       |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                               |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                             |
      | check  | dns_search *'nfs.redhat.com'*                                           |
      | check  | dns_search *'nfs6.redhat.com'*                                          |
      | check  | nmcli_con_num 1                                                         |
      | check  | no_ifcfg                                                                |
      | check  | ip4_route_unique "default via 192.168.50.1"                             |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                             |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"                |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                     |
      | check  | nfs_server 192.168.50.1                                                 |


      @rhbz1900260
      @rhelver+=8.4 @fedoraver+=32
      @ver+=1.26.0
      @dracut @long @not_on_ppc64le
      @dracut_NM_NFS_root_nfs_ip_dhcp_hostname
      Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=::::HOSTNAME::dhcp
      * Run dracut test
        | Param  | Value                                                                  |
        | kernel | root=nfs:192.168.50.1:/client ro ip=::::nfs-cl::dhcp                   |
        | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
        | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
        | check  | nmcli_con_active 'Wired Connection' eth0                               |
        | check  | nmcli_con_prop 'Wired Connection' ipv4.method auto                     |
        | check  | nmcli_con_prop 'Wired Connection' IP4.ADDRESS 192.168.50.101/24 10     |
        | check  | nmcli_con_prop 'Wired Connection' IP4.GATEWAY 192.168.50.1             |
        | check  | nmcli_con_prop 'Wired Connection' IP4.ROUTE *192.168.50.0/24*          |
        | check  | nmcli_con_prop 'Wired Connection' IP4.DNS 192.168.50.1                 |
        | check  | nmcli_con_prop 'Wired Connection' IP4.DOMAIN cl01.nfs.redhat.com       |
        | check  | nmcli_con_prop 'Wired Connection' ipv6.method auto                     |
        | check  | nmcli_con_prop 'Wired Connection' IP6.ADDRESS *deaf:beef::1:10/128* 10 |
        | check  | nmcli_con_prop 'Wired Connection' IP6.ROUTE *deaf:beef::/64*           |
        | check  | nmcli_con_prop 'Wired Connection' IP6.DNS deaf:beef::1 10              |
        | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                              |
        | check  | dns_search *'nfs.redhat.com'*                                          |
        | check  | dns_search *'nfs6.redhat.com'*                                         |
        | check  | nmcli_con_num 1                                                        |
        | check  | ip4_route_unique "default via 192.168.50.1"                            |
        | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
        | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
        | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
        # https://bugzilla.redhat.com/show_bug.cgi?id=1881974
        | check  | hostname_check nfs-cl                                                  |
        | check  | nfs_server 192.168.50.1                                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_rd_routes
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IFNAME:dhcp rd.route
    * Run dracut test
      | Param  | Value                                                            |
      | kernel | root=nfs:192.168.50.1:/client ro                                 |
      | kernel | ip=eth0:dhcp:1490:52:54:00:12:34:10                              |
      | kernel | rd.route=192.168.48.0/24:192.168.50.3:eth0                       |
      | kernel | rd.route=192.168.49.0/24:192.168.50.4:eth0                       |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00              |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                     |
      | check  | nmcli_con_active eth0 eth0                                       |
      | check  | nmcli_con_prop eth0 ipv4.method auto                             |
      | check  | nmcli_con_prop eth0 ipv4.routes '*192.168.48.0/24 192.168.50.3*' |
      | check  | nmcli_con_prop eth0 ipv4.routes '*192.168.49.0/24 192.168.50.4*' |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS 192.168.50.101/24 10             |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.50.1                     |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                  |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.50.1                         |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN cl01.nfs.redhat.com               |
      | check  | nmcli_con_prop eth0 ipv6.method auto                             |
      | check  | nmcli_con_prop eth0 IP6.ADDRESS *deaf:beef::1:10/128* 10         |
      | check  | nmcli_con_prop eth0 IP6.ROUTE *deaf:beef::/64*                   |
      | check  | nmcli_con_prop eth0 IP6.DNS deaf:beef::1 10                      |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                        |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                      |
      | check  | dns_search *'nfs.redhat.com'*                                    |
      | check  | dns_search *'nfs6.redhat.com'*                                   |
      | check  | nmcli_con_num 1                                                  |
      | check  | no_ifcfg                                                         |
      | check  | ip4_route_unique "default via 192.168.50.1"                      |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                      |
      | check  | ip4_route_unique "192.168.49.0/24 via 192.168.50.4 dev eth0"     |
      | check  | ip4_route_unique "192.168.48.0/24 via 192.168.50.3 dev eth0"     |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"         |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"              |
      | check  | nfs_server 192.168.50.1                                          |


    @rhbz1961666
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_dhcp6_slow_ip4
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp,dhcp6 with slow IPv4 DHCP
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:192.168.50.1:/client ro ip=dhcp,dhcp6                         |
      | kernel | rd.retry=0 rd.net.dhcp.retry=0 rd.net.timeout.dhcp=30                  |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:20                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active "Wired Connection" eth0 25                            |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.103/24 10     |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl03.nfs.redhat.com       |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip4_renew 192.168.50.103/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search *'nfs.redhat.com'*                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                         |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |


    @rhbz1961666
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_dhcp6_slow_ip6
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp,dhcp6 with slow IPv6 DHCP
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:[feed:beef::1]:/var/dracut_test/nfs/client ro ip=dhcp,dhcp6   |
      | kernel | rd.retry=0 rd.net.dhcp.retry=0 rd.net.timeout.dhcp=30                  |
      | qemu   | -device virtio-net,netdev=slow6,mac=52:54:00:12:34:20                  |
      | qemu   | -netdev tap,id=slow6,script=$PWD/qemu-ifup/slow6                       |
      | check  | nmcli_con_active "Wired Connection" eth0 25                            |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.49.2/30 10       |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.49.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.49.0/30*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.49.1                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl.slow6.redhat.com       |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *feed:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *feed:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS feed:beef::1 10              |
      | check  | wait_for_ip4_renew 192.168.49.2/30 eth0                                |
      | check  | wait_for_ip6_renew feed:beef::1:10/128 eth0                            |
      | check  | dns_search *'slow6.redhat.com'*                                        |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.49.1"                            |
      | check  | ip4_route_unique "192.168.49.0/30 dev eth0"                            |
      | check  | ip6_route_unique "feed:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "feed:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server [feed:beef::1]                                              |


    @rhbz1961666
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_dhcp6_with_ip46_and_ip6_nic
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp,dhcp6 with IPv4+IPv6 NIC and IPv6 only NIC
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:192.168.50.1:/client ro ip=dhcp,dhcp6                         |
      | kernel | rd.retry=0 rd.net.dhcp.retry=0 rd.net.timeout.dhcp=30                  |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | qemu   | -device virtio-net,netdev=nfs_ip6,mac=52:54:00:12:34:01                |
      | qemu   | -netdev tap,id=nfs_ip6,script=$PWD/qemu-ifup/nfs_ip6                   |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_active "Wired Connection" eth1 25                            |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS *192.168.50.101/24* 10   |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY *192.168.50.1*           |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS *192.168.50.1*               |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN *cl01.nfs.redhat.com*     |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beaf::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beaf::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *deaf:beef::1* 10            |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *deaf:beaf::1*               |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | wait_for_ip6_renew deaf:beaf::1:10/128 eth1                            |
      | check  | dns_search *'nfs.redhat.com'*                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                         |
      | check  | dns_search *'nfs6_2.redhat.com'*                                       |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | ip6_route_unique "deaf:beaf::1:10 dev eth1 proto kernel"               |
      | check  | ip6_route_unique "deaf:beaf::/64 dev eth1 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |


    @rhbz1961666
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_dhcp6_with_slow_ip46_and_ip6_nic
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp,dhcp6 with slow IPv4+IPv6 NIC and IPv6 only NIC
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:192.168.50.1:/client ro ip=dhcp,dhcp6                         |
      | kernel | rd.retry=0 rd.net.dhcp.retry=0 rd.net.timeout.dhcp=30                  |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:20                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | qemu   | -device virtio-net,netdev=nfs_ip6,mac=52:54:00:12:34:01                |
      | qemu   | -netdev tap,id=nfs_ip6,script=$PWD/qemu-ifup/nfs_ip6                   |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_active "Wired Connection" eth1 25                            |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS *192.168.50.103/24* 10   |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY *192.168.50.1*           |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS *192.168.50.1*               |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN *cl03.nfs.redhat.com*     |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beaf::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beaf::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *deaf:beef::1* 10            |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *deaf:beaf::1*               |
      | check  | wait_for_ip4_renew 192.168.50.103/24 eth0                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | wait_for_ip6_renew deaf:beaf::1:10/128 eth1                            |
      | check  | dns_search *'nfs.redhat.com'*                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                         |
      | check  | dns_search *'nfs6_2.redhat.com'*                                       |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | ip6_route_unique "deaf:beaf::1:10 dev eth1 proto kernel"               |
      | check  | ip6_route_unique "deaf:beaf::/64 dev eth1 proto ra"                    |
      | check  | nfs_server 192.168.50.1                                                |



    @rhbz1961666
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp_dhcp6_with_slow_ip64_and_ip6_nic
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp,dhcp6 with IPv4 + slow IPv6 NIC and IPv6 only NIC
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:[feed:beef::1]:/var/dracut_test/nfs/client ro ip=dhcp,dhcp6   |
      | kernel | rd.retry=0 rd.net.dhcp.retry=0 rd.net.timeout.dhcp=30                  |
      | qemu   | -device virtio-net,netdev=slow6,mac=52:54:00:12:34:00                  |
      | qemu   | -netdev tap,id=slow6,script=$PWD/qemu-ifup/slow6                       |
      | qemu   | -device virtio-net,netdev=nfs_ip6,mac=52:54:00:12:34:01                |
      | qemu   | -netdev tap,id=nfs_ip6,script=$PWD/qemu-ifup/nfs_ip6                   |
      | check  | nmcli_con_active "Wired Connection" eth0 25                            |
      | check  | nmcli_con_active "Wired Connection" eth1 25                            |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS *192.168.49.2/30* 10     |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY *192.168.49.1*           |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.49.0/30*          |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS *192.168.49.1*               |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN *cl.slow6.redhat.com*     |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *feed:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *feed:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beaf::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beaf::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *feed:beef::1* 10            |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS *deaf:beaf::1*               |
      | check  | wait_for_ip4_renew 192.168.49.2/30 eth0                                |
      | check  | wait_for_ip6_renew feed:beef::1:10/128 eth0                            |
      | check  | wait_for_ip6_renew deaf:beaf::1:10/128 eth1                            |
      | check  | dns_search *'slow6.redhat.com'*                                        |
      | check  | dns_search *'nfs6_2.redhat.com'*                                       |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "default via 192.168.49.1"                            |
      | check  | ip4_route_unique "192.168.49.0/30 dev eth0"                            |
      | check  | ip6_route_unique "feed:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "feed:beef::/64 dev eth0 proto ra"                    |
      | check  | ip6_route_unique "deaf:beaf::1:10 dev eth1 proto kernel"               |
      | check  | ip6_route_unique "deaf:beaf::/64 dev eth1 proto ra"                    |
      | check  | nfs_server [feed:beef::1]                                              |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_dhcp
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::MAC:dhcp
    * Run dracut test
      | Param  | Value                                                                                  |
      | kernel | root=nfs:192.168.50.1:/client ro                                                       |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:dhcp                                           |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                                           |
      | check  | nmcli_con_active eth0 eth0                                                             |
      | check  | nmcli_con_prop eth0 ipv4.method auto                                                   |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24                                   |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.101/24* 10                                 |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*                                    |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.50.1                                           |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                                        |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.50.1                                               |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN cl01.nfs.redhat.com                                     |
      | check  | nmcli_con_prop eth0 ipv6.method auto                                                   |
      | check  | nmcli_con_prop eth0 IP6.ADDRESS *deaf:beef::1:10/128* 10                               |
      | check  | nmcli_con_prop eth0 IP6.ROUTE *deaf:beef::/64*                                         |
      | check  | nmcli_con_prop eth0 IP6.DNS deaf:beef::1 10                                            |
      | check  | ip4_forever 192.168.50.201/24 eth0                                                     |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                                              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                                            |
      | check  | dns_search *'nfs.redhat.com'*                                                          |
      | check  | dns_search *'nfs6.redhat.com'*                                                         |
      | check  | nmcli_con_num 1                                                                        |
      | check  | no_ifcfg                                                                               |
      | check  | ip4_route_unique "default via 192.168.50.1"                                            |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0 proto kernel scope link src 192.168.50.101" |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0 proto kernel scope link src 192.168.50.201" |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"                               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                                    |
      | check  | nfs_server 192.168.50.1                                                                |


    @rhbz1883958
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=manual
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro                         |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:off              |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00      |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 ipv4.method manual                   |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24     |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*      |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                       |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth0 IP4.DNS ''                           |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                 |
      | check  | ip4_forever 192.168.50.201/24 eth0                       |
      | check  | dns_search ''                                            |
      | check  | nmcli_con_num 1                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"              |
      | check  | nfs_server 192.168.50.1                                  |


    @rhbz1879795
    @rhelver+=8.4 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_gateway_hostname_mac
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP::GW:NETMASK:HOSTNAME:MAC:none
    * Run dracut test
      | Param  | Value                                                                       |
      | kernel | root=nfs:192.168.50.1:/client ro                                            |
      | kernel | ip=192.168.50.201::192.168.50.1:255.255.255.0:nfs-cl:52-54-00-12-34-00:none |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                         |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                                |
      | check  | nmcli_con_active 52:54:00:12:34:00 eth0                                     |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv4.method manual                         |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv4.addresses 192.168.50.201/24           |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv4.gateway 192.168.50.1                  |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP4.ADDRESS *192.168.50.201/24*            |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP4.GATEWAY 192.168.50.1                   |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP4.ROUTE *192.168.50.0/24*                |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP4.DNS ''                                 |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP4.DOMAIN ''                              |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv6.method disabled                       |
      | check  | ip4_forever 192.168.50.201/24 eth0                                          |
      | check  | dns_search ''                                                               |
      | check  | nmcli_con_num 1                                                             |
      | check  | no_ifcfg                                                                    |
      | check  | ip4_route_unique "default via 192.168.50.1 dev eth0"                        |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                                 |
      # https://bugzilla.redhat.com/show_bug.cgi?id=1881974
      | check  | hostname_check nfs-cl                                                       |
      | check  | nfs_server 192.168.50.1                                                     |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_mtu
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::IFNAME:none:MTU
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro                         |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none:1491        |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00      |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 802-3-ethernet.mtu 1491              |
      | check  | nmcli_con_prop eth0 ipv4.method manual                   |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24     |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*      |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                       |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth0 IP4.DNS ''                           |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                 |
      | check  | ifname_mtu eth0 1491                                     |
      | check  | ip4_forever 192.168.50.201/24 eth0                       |
      | check  | dns_search ''                                            |
      | check  | nmcli_con_num 1                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"              |
      | check  | nfs_server 192.168.50.1                                  |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_mtu_cloned_mac
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::IFNAME:none:MTU:CMAC
    * Run dracut test
      | Param  | Value                                                                   |
      | kernel | root=nfs:192.168.50.1:/client ro                                        |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none:1511:52:54:00:12:34:11     |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                     |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                            |
      | check  | nmcli_con_active eth0 eth0                                              |
      | check  | nmcli_con_prop eth0 802-3-ethernet.mtu 1511                             |
      | check  | nmcli_con_prop eth0 802-3-ethernet.cloned-mac-address 52:54:00:12:34:11 |
      | check  | nmcli_con_prop eth0 ipv4.method manual                                  |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24                    |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*                     |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                                      |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                         |
      | check  | nmcli_con_prop eth0 IP4.DNS ''                                          |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                                       |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                                |
      | check  | ifname_mtu eth0 1511                                                    |
      | check  | ifname_mac eth0 52:54:00:12:34:11                                       |
      | check  | ip4_forever 192.168.50.201/24 eth0                                      |
      | check  | dns_search ''                                                           |
      | check  | nmcli_con_num 1                                                         |
      | check  | no_ifcfg                                                                |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                             |
      | check  | nfs_server 192.168.50.1                                                 |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_dns1
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::IFNAME:none:DNS1
    * Run dracut test
      | Param  | Value                                                                                 |
      | kernel | root=nfs:192.168.50.1:/client ro                          |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none:192.168.50.4 |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00       |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs              |
      | check  | nmcli_con_active eth0 eth0                                |
      | check  | nmcli_con_prop eth0 ipv4.method manual                    |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24      |
      | check  | nmcli_con_prop eth0 ipv4.dns 192.168.50.4                 |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*       |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                        |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*           |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.50.4                  |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                         |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                  |
      | check  | ip4_forever 192.168.50.201/24 eth0                        |
      | check  | dns_search ''                                             |
      | check  | nmcli_con_num 1                                           |
      | check  | no_ifcfg                                                  |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"               |
      | check  | nfs_server 192.168.50.1                                   |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_dns2
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::IFNAME:none:DNS1:DNS2
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:192.168.50.1:/client ro                                       |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none:192.168.50.4:192.168.50.5 |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active eth0 eth0                                             |
      | check  | nmcli_con_prop eth0 ipv4.method manual                                 |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24                   |
      | check  | nmcli_con_prop eth0 ipv4.dns 192.168.50.4,192.168.50.5                 |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*                    |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                                     |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                        |
      | check  | nmcli_con_prop eth0 IP4.DNS '192.168.50.4 \| 192.168.50.5'             |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                                      |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                               |
      | check  | ip4_forever 192.168.50.201/24 eth0                                     |
      | check  | dns_search ''                                                          |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                            |
      | check  | nfs_server 192.168.50.1                                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_dns3
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP:::NETMASK::IFNAME:none:DNS1:DNS2 nameserver
    * Run dracut test
      | Param  | Value                                                                                      |
      | kernel | root=nfs:192.168.50.1:/client ro nameserver=192.168.50.7 nameserver=192.168.50.6           |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none:192.168.50.4:192.168.50.5                     |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                                        |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                                               |
      | check  | nmcli_con_active eth0 eth0                                                                 |
      | check  | nmcli_con_prop eth0 ipv4.method manual                                                     |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24                                       |
      | check  | nmcli_con_prop eth0 ipv4.dns '192.168.50.4,192.168.50.5,192.168.50.7,192.168.50.6'         |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*                                        |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                                                         |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*                                            |
      | check  | nmcli_con_prop eth0 IP4.DNS '192.168.50.4 \| 192.168.50.5 \| 192.168.50.7 \| 192.168.50.6' |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                                                          |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                                                   |
      | check  | ip4_forever 192.168.50.201/24 eth0                                                         |
      | check  | dns_search ''                                                                              |
      | check  | nmcli_con_num 1                                                                            |
      | check  | no_ifcfg                                                                                   |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                                                |
      | check  | nfs_server 192.168.50.1                                                                    |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual_custom_ifname
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=manual ifname=nfs
    * Run dracut test
      | Param  | Value                                                   |
      | kernel | root=nfs:192.168.50.1:/client ro                        |
      | kernel | ip=192.168.50.201:::255.255.255.0::nfs:none             |
      | kernel | ifname=nfs:52:54:00:12:34:00                            |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00     |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs            |
      | check  | nmcli_con_active nfs nfs                                |
      | check  | nmcli_con_prop nfs ipv4.method manual                   |
      | check  | nmcli_con_prop nfs ipv4.addresses 192.168.50.201/24     |
      | check  | nmcli_con_prop nfs ipv4.dns ''                          |
      | check  | nmcli_con_prop nfs IP4.ADDRESS *192.168.50.201/24*      |
      | check  | nmcli_con_prop nfs IP4.GATEWAY ''                       |
      | check  | nmcli_con_prop nfs IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop nfs IP4.DNS ''                           |
      | check  | nmcli_con_prop nfs IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop nfs ipv6.method disabled                 |
      | check  | ip4_forever 192.168.50.201/24 nfs                       |
      | check  | dns_search ''                                           |
      | check  | nmcli_con_num 1                                         |
      | check  | no_ifcfg                                                |
      | check  | ip4_route_unique "192.168.50.0/24 dev nfs"              |
      | check  | nfs_server 192.168.50.1                                 |


    @rhbz1883958
    @ver+=1.29
    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_off
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=off
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro ip=eth1:off             |
      | kernel | ip=192.168.50.201:::255.255.255.0::eth0:none             |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00      |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | qemu   | -device virtio-net,netdev=vlan33_0,mac=52:54:00:12:34:01 |
      | qemu   | -netdev tap,id=vlan33_0,script=$PWD/qemu-ifup/vlan33_0   |
      | check  | nmcli_con_active eth1 eth1                               |
      | check  | nmcli_con_prop eth1 ipv4.method disabled                 |
      | check  | nmcli_con_prop eth1 ipv6.method disabled                 |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 ipv4.method manual                   |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.50.201/24     |
      | check  | nmcli_con_prop eth0 ipv4.dns ''                          |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS *192.168.50.201/24*      |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY ''                       |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth0 IP4.DNS ''                           |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                 |
      | check  | ip4_forever 192.168.50.201/24 eth0                       |
      | check  | dns_search ''                                            |
      | check  | nmcli_con_num 2                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"              |
      | check  | nfs_server 192.168.50.1                                  |


    @rhbz1934122
    @ver+=1.32
    @rhelver+=8.3 @fedoraver+=32
    @dracut @dracut_remote_NFS_clean @long @not_on_ppc64le
    @dracut_NM_NFS_remote_rootfs_connection
    Scenario: NM - dracut - NM module - NM uses connection defined in remote root with ip=eth*:dhcp
    * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_NM.conf $TESTDIR/nfs/client/etc/NetworkManager/conf.d/50-persist-conn.conf"
    * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth0.nmconnection $TESTDIR/nfs/client/etc/NetworkManager/system-connections/eth0.nmconnection"
    * Execute ". contrib/dracut/setup.sh; chmod 600 $TESTDIR/nfs/client/etc/NetworkManager/system-connections/eth0.nmconnection"
    * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth1.ifcfg $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-eth1_p"
    * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth2.ifcfg $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-eth2_p"
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro                         |
      | kernel | ip=eth0:dhcp ip=eth1:dhcp ip=eth2:dhcp                   |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1   |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0       |
      | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2   |
      | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1       |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00      |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | check  | nmcli_con_inactive eth0                                  |
      | check  | nmcli_con_prop eth0 ipv4.method auto                     |
      | check  | nmcli_con_prop eth0 ipv6.method auto                     |
      | check  | nmcli_con_active eth0_p eth0                             |
      | check  | nmcli_con_prop eth0_p ipv4.method manual                 |
      | check  | nmcli_con_prop eth0_p IP4.ADDRESS 192.168.90.204/24 10   |
      | check  | nmcli_con_prop eth0_p IP4.GATEWAY ''                     |
      | check  | nmcli_con_prop eth0_p IP4.ROUTE *192.168.90.0/24*        |
      | check  | nmcli_con_prop eth0_p IP4.DNS ''                         |
      | check  | nmcli_con_prop eth0_p IP4.DOMAIN ''                      |
      | check  | nmcli_con_prop eth0_p ipv6.method disabled               |
      | check  | nmcli_con_inactive eth1                                  |
      | check  | nmcli_con_prop eth1 ipv4.method auto                     |
      | check  | nmcli_con_prop eth1 ipv6.method auto                     |
      | check  | nmcli_con_active eth1_p eth1                             |
      | check  | nmcli_con_prop eth1_p ipv4.method manual                 |
      | check  | nmcli_con_prop eth1_p IP4.ADDRESS 192.168.91.204/24 10   |
      | check  | nmcli_con_prop eth1_p IP4.GATEWAY ''                     |
      | check  | nmcli_con_prop eth1_p IP4.ROUTE *192.168.91.0/24*        |
      | check  | nmcli_con_prop eth1_p IP4.DNS ''                         |
      | check  | nmcli_con_prop eth1_p IP4.DOMAIN ''                      |
      | check  | nmcli_con_prop eth1_p ipv6.method disabled               |
      | check  | nmcli_con_inactive eth2_p                                |
      | check  | nmcli_con_active eth2 eth2                               |
      | check  | nmcli_con_prop eth2 ipv4.method auto                     |
      | check  | nmcli_con_prop eth2 IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop eth2 IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop eth2 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth2 IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop eth2 IP4.DOMAIN cl01.nfs.redhat.com       |
      | check  | nmcli_con_prop eth2 ipv6.method auto                     |
      | check  | nmcli_con_prop eth2 IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop eth2 IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop eth2 IP6.DNS deaf:beef::1 10              |
      | check  | dns_search *'nfs.redhat.com'*                            |
      | check  | dns_search *'nfs6.redhat.com'*                           |
      | check  | ip4_forever 192.168.90.204/24 eth0                       |
      | check  | ip4_forever 192.168.91.204/24 eth1                       |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth2                |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth2              |
      | check  | nmcli_con_num 6                                          |
      | check  | ip4_route_unique "default via 192.168.50.1"              |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth2"              |
      | check  | ip4_route_unique "192.168.91.0/24 dev eth1"              |
      | check  | ip4_route_unique "192.168.90.0/24 dev eth0"              |
      | check  | nfs_server 192.168.50.1                                  |


      @rhbz1934122
      @ver+=1.32
      @rhelver+=8.3 @fedoraver+=32
      @dracut @dracut_remote_NFS_clean @long @not_on_ppc64le
      @dracut_NM_NFS_remote_rootfs_connection_var2
      Scenario: NM - dracut - NM module - NM uses connection defined in remote root with ip=dhcp
      * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_NM.conf $TESTDIR/nfs/client/etc/NetworkManager/conf.d/50-persist-conn.conf"
      * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth0.nmconnection $TESTDIR/nfs/client/etc/NetworkManager/system-connections/eth0.nmconnection"
      * Execute ". contrib/dracut/setup.sh; chmod 600 $TESTDIR/nfs/client/etc/NetworkManager/system-connections/eth0.nmconnection"
      * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth1.ifcfg $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-eth1_p"
      * Execute ". contrib/dracut/setup.sh; cp contrib/dracut/conf/rhbz1934122_eth2.ifcfg $TESTDIR/nfs/client/etc/sysconfig/network-scripts/ifcfg-eth2_p"
      * Run dracut test
        | Param  | Value                                                                  |
        | kernel | root=nfs:192.168.50.1:/client ro ip=dhcp                               |
        | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1                 |
        | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0                     |
        | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2                 |
        | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1                     |
        | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
        | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
        | check  | nmcli_con_active eth0_p eth0                                           |
        | check  | nmcli_con_prop eth0_p ipv4.method manual                               |
        | check  | nmcli_con_prop eth0_p IP4.ADDRESS 192.168.90.204/24 10                 |
        | check  | nmcli_con_prop eth0_p IP4.GATEWAY ''                                   |
        | check  | nmcli_con_prop eth0_p IP4.ROUTE *192.168.90.0/24*                      |
        | check  | nmcli_con_prop eth0_p IP4.DNS ''                                       |
        | check  | nmcli_con_prop eth0_p IP4.DOMAIN ''                                    |
        | check  | nmcli_con_prop eth0_p ipv6.method disabled                             |
        | check  | nmcli_con_active eth1_p eth1                                           |
        | check  | nmcli_con_prop eth1_p ipv4.method manual                               |
        | check  | nmcli_con_prop eth1_p IP4.ADDRESS 192.168.91.204/24 10                 |
        | check  | nmcli_con_prop eth1_p IP4.GATEWAY ''                                   |
        | check  | nmcli_con_prop eth1_p IP4.ROUTE *192.168.91.0/24*                      |
        | check  | nmcli_con_prop eth1_p IP4.DNS ''                                       |
        | check  | nmcli_con_prop eth1_p IP4.DOMAIN ''                                    |
        | check  | nmcli_con_prop eth1_p ipv6.method disabled                             |
        | check  | nmcli_con_inactive eth2_p                                              |
        | check  | nmcli_con_active "Wired Connection" eth2                               |
        | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                     |
        | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.101/24 10     |
        | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1             |
        | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*          |
        | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1                 |
        | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl01.nfs.redhat.com       |
        | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
        | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
        | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
        | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
        | check  | dns_search *'nfs.redhat.com'*                                          |
        | check  | dns_search *'nfs6.redhat.com'*                                         |
        | check  | ip4_forever 192.168.90.204/24 eth0                                     |
        | check  | wait_for_ip4_renew 192.168.50.101/24 eth2                              |
        | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth2                            |
        | check  | nmcli_con_num 4                                                        |
        | check  | ip4_route_unique "default via 192.168.50.1"                            |
        | check  | ip4_route_unique "192.168.50.0/24 dev eth2"                            |
        | check  | ip4_route_unique "192.168.91.0/24 dev eth1"                            |
        | check  | ip4_route_unique "192.168.90.0/24 dev eth0"                            |
        | check  | nfs_server 192.168.50.1                                                |


    @rhbz1854323
    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_auto6
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=auto6
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:[deaf:beef::1]:/var/dracut_test/nfs/client                    |
      | kernel | ip=auto6 ro                                                            |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method disabled                 |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search nfs6.redhat.com                                             |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server [deaf:beef::1]                                              |


    @rhbz1854323
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_dhcp6
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=dhcp6
    * Run dracut test
      | Param  | Value                                                                  |
      | kernel | root=nfs:[deaf:beef::1]:/var/dracut_test/nfs/client                    |
      | kernel | ip=dhcp6 ro                                                            |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                    |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                           |
      | check  | nmcli_con_active "Wired Connection" eth0                               |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method disabled                 |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth0                            |
      | check  | dns_search nfs6.redhat.com                                             |
      | check  | nmcli_con_num 1                                                        |
      | check  | no_ifcfg                                                               |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth0 proto kernel"               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto ra"                    |
      | check  | nfs_server [deaf:beef::1]                                              |


    @rhbz1879795
    @rhelver+=8.4 @fedoraver+=32
    @ver+=1.25.0
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ip_manual6_gateway_hostname_mac
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ip=IP6:GW::NETMASK:HOSTNAME:MAC
    * Run dracut test
      | Param  | Value                                                                              |
      | kernel | root=nfs:[deaf:beef::1]:/var/dracut_test/nfs/client ro                             |
      | kernel | ip=[deaf:beef::ac:1]::[deaf:beef::1]:64:dracut-nfs-client-6:52-54-00-12-34-00:none |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                                |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                                       |
      | check  | nmcli_con_active 52:54:00:12:34:00 eth0                                            |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv6.method manual                                |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv6.addresses deaf:beef::ac:1/64                 |
      | check  | nmcli_con_prop 52:54:00:12:34:00 ipv6.gateway deaf:beef::1                         |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP6.ADDRESS *deaf:beef::ac:1/64* 10               |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP6.GATEWAY deaf:beef::1                          |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP6.ROUTE *deaf:beef::/64*                        |
      | check  | nmcli_con_prop 52:54:00:12:34:00 IP6.DNS ''                                        |
      | check  | ip6_forever deaf:beef::ac:1/64 eth0                                                |
      | check  | dns_search ''                                                                      |
      | check  | nmcli_con_num 1                                                                    |
      | check  | no_ifcfg                                                                           |
      | check  | ip6_route_unique "default via deaf:beef::1 dev eth0"                               |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth0 proto kernel"                            |
      # https://bugzilla.redhat.com/show_bug.cgi?id=1881974
      | check  | hostname_check dracut-nfs-client-6                                                 |
      | check  | nfs_server [deaf:beef::1]                                                          |


    @rhbz1840989
    @ver+=1.25
    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_NFS_root_nfs_ipv6_disable
    Scenario: NM - dracut - NM module - NFSv3 root=nfs ipv6.disable
    * Run dracut test
      | Param  | Value                                                              |
      | kernel | root=nfs:192.168.50.1:/client ro                                   |
      | kernel | ipv6.disable=1                                                     |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                       |
      | check  | nmcli_con_active "Wired Connection" eth0                           |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.50.101/24 10 |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.50.1         |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.50.0/24*      |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.50.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl01.nfs.redhat.com   |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                 |
      | check  | nmcli_con_prop "Wired Connection" IP6.ADDRESS ''                   |
      | check  | nmcli_con_prop "Wired Connection" IP6.ROUTE ''                     |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS ''                       |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth0                          |
      | check  | dns_search nfs.redhat.com                                          |
      | check  | nmcli_con_num 1                                                    |
      | check  | no_ifcfg                                                           |
      | check  | ip4_route_unique "default via 192.168.50.1"                        |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth0"                        |
      | check  | nfs_server 192.168.50.1                                            |
      | check  | reproduce_1840989                                                  |


    #########
    # iSCSI #
    #########


    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_iSCSI_netroot_dhcp
    Scenario: NM - dracut - NM module - iSCSI netroot=dhcp
    * Run dracut test
      | Param  | Value                                                              |
      | type   | iscsi_single                                                       |
      | kernel | root=/dev/root netroot=dhcp                                        |
      | kernel | rw rd.auto rd.iscsi.initiator=$(iscsi-iname)                       |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1             |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0                 |
      | check  | nmcli_con_active "Wired Connection" eth0                           |
      | check  | nmcli_con_prop "Wired Connection" ipv4.method auto                 |
      | check  | nmcli_con_prop "Wired Connection" IP4.ADDRESS 192.168.51.101/24 10 |
      | check  | nmcli_con_prop "Wired Connection" IP4.GATEWAY 192.168.51.1         |
      | check  | nmcli_con_prop "Wired Connection" IP4.ROUTE *192.168.51.0/24*      |
      | check  | nmcli_con_prop "Wired Connection" IP4.DNS 192.168.51.1             |
      | check  | nmcli_con_prop "Wired Connection" IP4.DOMAIN cl.iscsi0.redhat.com  |
      | check  | nmcli_con_prop "Wired Connection" ipv6.method auto                 |
      | check  | nmcli_con_prop "Wired Connection" IP6.DNS ''                       |
      | check  | wait_for_ip4_renew 192.168.51.101/24 eth0                          |
      | check  | dns_search iscsi0.redhat.com                                       |
      | check  | nmcli_con_num 1                                                    |
      | check  | no_ifcfg                                                           |
      | check  | ip4_route_unique "default via 192.168.51.1"                        |
      | check  | ip4_route_unique "192.168.51.0/24 dev eth0"                        |
      | check  | mount_root_type ext3                                               |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_iSCSI_netroot_dhcp_ip_dhcp
    Scenario: NM - dracut - NM module - iSCSI netroot=dhcp ip=eth0:dhcp
    * Run dracut test
      | Param  | Value                                                  |
      | type   | iscsi_single                                           |
      | kernel | root=/dev/root netroot=dhcp ip=eth0:dhcp               |
      | kernel | rw rd.auto rd.iscsi.initiator=$(iscsi-iname)           |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1 |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0     |
      | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2 |
      | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1     |
      | check  | nmcli_con_active eth0 eth0                             |
      | check  | nmcli_con_prop eth0 ipv4.method auto                   |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS 192.168.51.101/24 10   |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.51.1           |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.51.0/24*        |
      | check  | nmcli_con_prop eth0 IP4.DNS 192.168.51.1               |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN cl.iscsi0.redhat.com    |
      | check  | nmcli_con_prop eth0 ipv6.method auto                   |
      | check  | nmcli_con_prop eth0 IP6.DNS ''                         |
      | check  | wait_for_ip4_renew 192.168.51.101/24 eth0              |
      | check  | link_no_ip4 eth1                                       |
      | check  | dns_search iscsi0.redhat.com                           |
      | check  | nmcli_con_num 1                                        |
      | check  | no_ifcfg                                               |
      | check  | ip4_route_unique "default via 192.168.51.1"            |
      | check  | ip4_route_unique "192.168.51.0/24 dev eth0"            |
      | check  | mount_root_type ext3                                   |


    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @x86_64_only
    @dracut_NM_iSCSI_ibft_table
    @ver+=1.36.0
    Scenario: NM - dracut - NM module - iSCSI ibft.table
    * Run dracut test
      | Param  | Value                                                               |
      | type   | iscsi_single                                                        |
      | kernel | root=LABEL=singleroot                                               |
      | kernel | rd.iscsi.ibft=1 rd.iscsi.firmware=1                                 |
      | kernel | rw rd.auto                                                          |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1              |
      | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2              |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0                  |
      | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1                  |
      | qemu   | -acpitable file=conf/ibft.table                                     |
      | check  | nmcli_con_active "iBFT Connection 0" eth0                           |
      | check  | nmcli_con_prop "iBFT Connection 0" ipv4.method auto                 |
      | check  | nmcli_con_prop "iBFT Connection 0" IP4.ADDRESS 192.168.51.101/24 10 |
      | check  | nmcli_con_prop "iBFT Connection 0" IP4.GATEWAY 192.168.51.1         |
      | check  | nmcli_con_prop "iBFT Connection 0" IP4.ROUTE *192.168.51.0/24*      |
      | check  | nmcli_con_prop "iBFT Connection 0" IP4.DNS 192.168.51.1             |
      | check  | nmcli_con_prop "iBFT Connection 0" IP4.DOMAIN cl.iscsi0.redhat.com  |
      | check  | nmcli_con_prop "iBFT Connection 0" ipv6.method disabled             |
      | check  | ip4_forever 192.168.51.101/24 eth0                                  |
      | check  | link_no_ip4 eth1                                                    |
      | check  | dns_search iscsi0.redhat.com                                        |
      | check  | nmcli_con_num 1                                                     |
      | check  | no_ifcfg                                                            |
      | check  | ip4_route_unique "default via 192.168.51.1"                         |
      | check  | ip4_route_unique "192.168.51.0/24 dev eth0"                         |
      | check  | mount_root_type ext3                                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29
    @dracut @long @not_on_ppc64le
    @dracut_NM_iSCSI_multiple_targets
    Scenario: NM - dracut - NM module - iSCSI 2 targets in RAID0
    * Run dracut test
      | Param  | Value                                                    |
      | type   | iscsi_raid                                               |
      | kernel | root=LABEL=sysroot rw rd.auto                            |
      | kernel | ip=192.168.51.101::192.168.51.1:255.255.255.0::eth0:off  |
      | kernel | ip=192.168.52.101::192.168.52.1:255.255.255.0::eth1:off  |
      | kernel | netroot=iscsi:192.168.52.1::::iqn.2009-06.dracut:target1 |
      | kernel | netroot=iscsi:192.168.51.1::::iqn.2009-06.dracut:target2 |
      | kernel | rd.iscsi.initiator=$(iscsi-iname)                        |
      | kernel | rd.iscsi.firmware rd.iscsi.waitnet=0                     |
      | kernel | rd.iscsi.testroute=0                                     |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1   |
      | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2   |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0       |
      | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1       |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 ipv4.method manual                   |
      | check  | nmcli_con_prop eth0 ipv4.addresses 192.168.51.101/24     |
      | check  | nmcli_con_prop eth0 ipv4.gateway 192.168.51.1            |
      | check  | nmcli_con_prop eth0 IP4.ADDRESS 192.168.51.101/24 10     |
      | check  | nmcli_con_prop eth0 IP4.GATEWAY 192.168.51.1             |
      | check  | nmcli_con_prop eth0 IP4.ROUTE *192.168.51.0/24*          |
      | check  | nmcli_con_prop eth0 IP4.DNS ''                           |
      | check  | nmcli_con_prop eth0 IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                 |
      | check  | nmcli_con_active eth1 eth1                               |
      | check  | nmcli_con_prop eth1 ipv4.method manual                   |
      | check  | nmcli_con_prop eth1 ipv4.addresses 192.168.52.101/24     |
      | check  | nmcli_con_prop eth1 ipv4.gateway 192.168.52.1            |
      | check  | nmcli_con_prop eth1 IP4.ADDRESS 192.168.52.101/24 10     |
      | check  | nmcli_con_prop eth1 IP4.GATEWAY 192.168.52.1             |
      | check  | nmcli_con_prop eth1 IP4.ROUTE *192.168.52.0/24*          |
      | check  | nmcli_con_prop eth1 IP4.DNS ''                           |
      | check  | nmcli_con_prop eth1 IP4.DOMAIN ''                        |
      | check  | nmcli_con_prop eth1 ipv6.method disabled                 |
      | check  | ip4_forever 192.168.51.101/24 eth0                       |
      | check  | ip4_forever 192.168.52.101/24 eth1                       |
      | check  | dns_search ''                                            |
      | check  | nmcli_con_num 2                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "default via 192.168.51.1"              |
      | check  | ip4_route_unique "default via 192.168.52.1"              |
      | check  | ip4_route_unique "192.168.51.0/24 dev eth0"              |
      | check  | ip4_route_unique "192.168.52.0/24 dev eth1"              |
      | check  | mount_root_type ext3                                     |


    ##########
    # bridge #
    ##########


    @rhbz1627820
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_bridge_eth0
    Scenario: NM - dracut - NM module - bridge over eth0
    * Run dracut test
      | Param  | Value                                                                     |
      | kernel | root=nfs:192.168.50.1:/client ro bridge ip=br0:dhcp                       |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                       |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                              |
      | check  | nmcli_con_active br0 br0 45                                               |
      | check  | nmcli_con_prop br0 ipv4.method auto                                       |
      | check  | nmcli_con_prop br0 IP4.ADDRESS 192.168.50.101/24 45                       |
      | check  | nmcli_con_prop br0 IP4.GATEWAY 192.168.50.1                               |
      | check  | nmcli_con_prop br0 IP4.ROUTE *192.168.50.0/24*                            |
      | check  | nmcli_con_prop br0 IP4.DNS 192.168.50.1                                   |
      | check  | nmcli_con_prop br0 IP4.DOMAIN cl01.nfs.redhat.com                         |
      | check  | nmcli_con_prop br0 ipv6.method auto                                       |
      | check  | nmcli_con_prop br0 IP6.ADDRESS *deaf:beef::1:10/128* 10                   |
      | check  | nmcli_con_prop br0 IP6.ROUTE *deaf:beef::/64*                             |
      | check  | nmcli_con_prop br0 IP6.DNS deaf:beef::1 10                                |
      | check  | nmcli_con_active eth0 eth0                                                |
      | check  | nmcli_con_prop eth0 connection.slave-type bridge                          |
      | check  | nmcli_con_prop eth0 connection.master $(nmcli -g connection.uuid c s br0) |
      | check  | nmcli_con_prop eth0 ipv4.method ''                                        |
      | check  | nmcli_con_prop eth0 ipv6.method ''                                        |
      | check  | wait_for_ip4_renew 192.168.50.101/24 br0                                  |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 br0                                |
      | check  | dns_search *'nfs.redhat.com'*                                             |
      | check  | dns_search *'nfs6.redhat.com'*                                            |
      | check  | nmcli_con_num 2                                                           |
      | check  | no_ifcfg                                                                  |
      | check  | ip4_route_unique "default via 192.168.50.1"                               |
      | check  | ip4_route_unique "192.168.50.0/24 dev br0"                                |
      | check  | ip6_route_unique "deaf:beef::1:10 dev br0 proto kernel"                   |
      | check  | ip6_route_unique "deaf:beef::/64 dev br0 proto ra"                        |
      | check  | nfs_server 192.168.50.1                                                   |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.29
    @dracut @long @not_on_ppc64le
    @dracut_NM_bridge_custom_name_2_ifaces
    Scenario: NM - dracut - NM module - custom bridge name over 2 ifaces
    * Run dracut test
      | Param  | Value                                                                        |
      | kernel | root=nfs:192.168.50.1:/client ro                                             |
      | kernel | bridge=foobr0:eth0,eth1                                                      |
      | kernel | ip=192.168.50.201:::255.255.255.0::foobr0:off                                |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs                                 |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:00                          |
      | qemu   | -netdev tap,id=empty,script=$PWD/qemu-ifup/empty                             |
      | qemu   | -device virtio-net,netdev=empty,mac=52:54:00:12:34:01                        |
      | check  | nmcli_con_active foobr0 foobr0 45                                            |
      | check  | nmcli_con_prop foobr0 ipv4.method manual                                     |
      | check  | nmcli_con_prop foobr0 ipv4.addresses 192.168.50.201/24                       |
      | check  | nmcli_con_prop foobr0 IP4.ADDRESS 192.168.50.201/24 45                       |
      | check  | nmcli_con_prop foobr0 IP4.GATEWAY ''                                         |
      | check  | nmcli_con_prop foobr0 IP4.ROUTE *192.168.50.0/24*                            |
      | check  | nmcli_con_prop foobr0 IP4.DNS ''                                             |
      | check  | nmcli_con_prop foobr0 IP4.DOMAIN ''                                          |
      | check  | nmcli_con_prop foobr0 ipv6.method disabled                                   |
      | check  | nmcli_con_active eth0 eth0                                                   |
      | check  | nmcli_con_prop eth0 connection.slave-type bridge                             |
      | check  | nmcli_con_prop eth0 connection.master $(nmcli -g connection.uuid c s foobr0) |
      | check  | nmcli_con_prop eth0 ipv4.method ''                                           |
      | check  | nmcli_con_prop eth0 ipv6.method ''                                           |
      | check  | nmcli_con_active eth1 eth1                                                   |
      | check  | nmcli_con_prop eth1 connection.slave-type bridge                             |
      | check  | nmcli_con_prop eth1 connection.master $(nmcli -g connection.uuid c s foobr0) |
      | check  | nmcli_con_prop eth1 ipv4.method ''                                           |
      | check  | nmcli_con_prop eth1 ipv6.method ''                                           |
      | check  | ip4_forever 192.168.50.201/24 foobr0                                         |
      | check  | dns_search ''                                                                |
      | check  | nmcli_con_num 3                                                              |
      | check  | no_ifcfg                                                                     |
      | check  | ip4_route_unique "192.168.50.0/24 dev foobr0"                                |
      | check  | nfs_server 192.168.50.1                                                      |


    #############
    # bond/team #
    #############


    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @not_on_ppc64le
    @dracut_NM_bond_over_2_ifaces_rr
    Scenario: NM - dracut - NM module - bond over 2 ifaces balance-rr
    * Run dracut test
      | Param  | Value                                                                       |
      | kernel | root=dhcp ro                                                                |
      | kernel | bond=bond0:eth0,eth1:mode=balance-rr                                        |
      | qemu   | -netdev tap,id=bond0_0,script=$PWD/qemu-ifup/bond0_0                        |
      | qemu   | -device virtio-net,netdev=bond0_0,mac=52:54:00:12:34:10                     |
      | qemu   | -netdev tap,id=bond0_1,script=$PWD/qemu-ifup/bond0_1                        |
      | qemu   | -device virtio-net,netdev=bond0_1,mac=52:54:00:12:34:11                     |
      | check  | nmcli_con_active bond0 bond0 45                                             |
      | check  | nmcli_con_prop bond0 bond.options mode=balance-rr                           |
      | check  | nmcli_con_prop bond0 ipv4.method auto                                       |
      | check  | nmcli_con_prop bond0 IP4.ADDRESS 192.168.53.101/24 45                       |
      | check  | nmcli_con_prop bond0 IP4.GATEWAY 192.168.53.1                               |
      | check  | nmcli_con_prop bond0 IP4.ROUTE *192.168.53.0/24*                            |
      | check  | nmcli_con_prop bond0 IP4.DNS 192.168.53.1                                   |
      | check  | nmcli_con_prop bond0 IP4.DOMAIN cl.bond0.redhat.com                         |
      | check  | nmcli_con_prop bond0 ipv6.method auto                                       |
      | check  | nmcli_con_prop bond0 IP6.DNS ''                                             |
      | check  | nmcli_con_active eth0 eth0                                                  |
      | check  | nmcli_con_prop eth0 connection.slave-type bond                              |
      | check  | nmcli_con_prop eth0 connection.master $(nmcli -g connection.uuid c s bond0) |
      | check  | nmcli_con_prop eth0 ipv4.method ''                                          |
      | check  | nmcli_con_prop eth0 ipv6.method ''                                          |
      | check  | nmcli_con_active eth1 eth1                                                  |
      | check  | nmcli_con_prop eth1 connection.slave-type bond                              |
      | check  | nmcli_con_prop eth1 connection.master $(nmcli -g connection.uuid c s bond0) |
      | check  | nmcli_con_prop eth1 ipv4.method ''                                          |
      | check  | nmcli_con_prop eth1 ipv6.method ''                                          |
      | check  | wait_for_ip4_renew 192.168.53.101/24 bond0                                  |
      | check  | dns_search bond0.redhat.com                                                 |
      | check  | nmcli_con_num 3                                                             |
      | check  | no_ifcfg                                                                    |
      | check  | ip4_route_unique "192.168.53.0/24 dev bond0"                                |
      | check  | nfs_server 192.168.53.1                                                     |


    # dracut bug: https://bugzilla.redhat.com/show_bug.cgi?id=1879014
    #@rhbz1879014
    #@rhelver+=8.3 @fedoraver+=32
    #@dracut @long @not_on_ppc64le
    #@dracut_NM_team_over_2_ifaces
    #Scenario: NM - dracut - NM module - team over 2 ifaces
    #* Run dracut test
    #  | Param  | Value                                                                       |
    #  | kernel | root=dhcp ro                                                                |
    #  | kernel | team=team0:eth0,eth1                                                        |
    #  | qemu   | -netdev tap,id=bond0_0,script=$PWD/qemu-ifup/bond0_0                        |
    #  | qemu   | -device virtio-net,netdev=bond0_0,mac=52:54:00:12:34:10                     |
    #  | qemu   | -netdev tap,id=bond0_1,script=$PWD/qemu-ifup/bond0_1                        |
    #  | qemu   | -device virtio-net,netdev=bond0_1,mac=52:54:00:12:34:11                     |
    #  | check  | nmcli_con_active team0 team0 45                                             |
    #  | check  | nmcli_con_prop team0 ipv4.method auto                                       |
    #  | check  | nmcli_con_prop team0 IP4.ADDRESS 192.168.53.101/24 45                       |
    #  | check  | nmcli_con_prop team0 IP4.GATEWAY 192.168.53.1                               |
    #  | check  | nmcli_con_prop team0 IP4.ROUTE *192.168.53.0/24*                            |
    #  | check  | nmcli_con_prop team0 IP4.DNS 192.168.53.1                                   |
    #  | check  | nmcli_con_prop team0 IP4.DOMAIN cl.bond0.redhat.com                         |
    #  | check  | nmcli_con_prop team0 ipv6.method auto                                       |
    #  | check  | nmcli_con_prop team0 IP6.DNS ''                                             |
    #  | check  | nmcli_con_active eth0 eth0                                                  |
    #  | check  | nmcli_con_prop eth0 connection.slave-type bond                              |
    #  | check  | nmcli_con_prop eth0 connection.master $(nmcli -g connection.uuid c s team0) |
    #  | check  | nmcli_con_prop eth0 ipv4.method ''                                          |
    #  | check  | nmcli_con_prop eth0 ipv6.method ''                                          |
    #  | check  | nmcli_con_active eth1 eth1                                                  |
    #  | check  | nmcli_con_prop eth1 connection.slave-type bond                              |
    #  | check  | nmcli_con_prop eth1 connection.master $(nmcli -g connection.uuid c s team0) |
    #  | check  | nmcli_con_prop eth1 ipv4.method ''                                          |
    #  | check  | nmcli_con_prop eth1 ipv6.method ''                                          |
    #  | check  | wait_for_ip4_renew 192.168.53.101/24 team0                                  |
    #  | check  | dns_search team0.redhat.com                                                 |
    #  | check  | nmcli_con_num 3                                                             |
    #  | check  | no_ifcfg                                                                    |
    #  | check  | ip4_route_unique "192.168.53.0/24 dev team0"                                |
    #  | check  | nfs_server 192.168.53.1                                                     |


    ########
    # VLAN #
    ########


    @rhelver+=8.3 @fedoraver+=32
    @ver-=1.24
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_nic
    Scenario: NM - dracut - NM module - VLAN over single NIC
    * Run dracut test
      | Param  | Value                                                |
      | kernel | root=dhcp ro                                         |
      | kernel | vlan=vlan5:eth0                                      |
      | qemu   | -netdev tap,id=vlan,script=$PWD/qemu-ifup/vlan       |
      | qemu   | -device virtio-net,netdev=vlan,mac=52:54:00:12:34:11 |
      | check  | nmcli_con_active vlan5 vlan5 45                      |
      | check  | nmcli_con_prop vlan5 vlan.id 5                       |
      | check  | nmcli_con_prop vlan5 vlan.parent eth0                |
      | check  | nmcli_con_prop vlan5 ipv4.method auto                |
      | check  | nmcli_con_prop vlan5 IP4.ADDRESS 192.168.55.6/30 45  |
      | check  | nmcli_con_prop vlan5 IP4.GATEWAY 192.168.55.5        |
      | check  | nmcli_con_prop vlan5 IP4.ROUTE *192.168.55.4/30*     |
      | check  | nmcli_con_prop vlan5 IP4.DNS 192.168.55.5            |
      | check  | nmcli_con_prop vlan5 IP4.DOMAIN cl.vl5.redhat.com    |
      | check  | nmcli_con_prop vlan5 ipv6.method auto                |
      | check  | nmcli_con_prop vlan5 IP6.DNS ''                      |
      | check  | wait_for_ip4_renew 192.168.55.6/30 vlan5             |
      | check  | dns_search vl5.redhat.com                            |
      | check  | nmcli_con_num 1                                      |
      | check  | no_ifcfg                                             |
      | check  | ip4_route_unique "default via 192.168.55.5"          |
      | check  | ip4_route_unique "192.168.55.4/30 dev vlan5"         |
      | check  | nfs_server 192.168.55.5                              |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_nic
    Scenario: NM - dracut - NM module - VLAN over single NIC
    * Run dracut test
      | Param  | Value                                                |
      | kernel | root=dhcp ro                                         |
      | kernel | vlan=vlan5:eth0                                      |
      | qemu   | -netdev tap,id=vlan,script=$PWD/qemu-ifup/vlan       |
      | qemu   | -device virtio-net,netdev=vlan,mac=52:54:00:12:34:11 |
      | check  | nmcli_con_active vlan5 vlan5 45                      |
      | check  | nmcli_con_prop vlan5 vlan.id 5                       |
      | check  | nmcli_con_prop vlan5 vlan.parent eth0                |
      | check  | nmcli_con_prop vlan5 ipv4.method auto                |
      | check  | nmcli_con_prop vlan5 IP4.ADDRESS 192.168.55.6/30 45  |
      | check  | nmcli_con_prop vlan5 IP4.GATEWAY 192.168.55.5        |
      | check  | nmcli_con_prop vlan5 IP4.ROUTE *192.168.55.4/30*     |
      | check  | nmcli_con_prop vlan5 IP4.DNS 192.168.55.5            |
      | check  | nmcli_con_prop vlan5 IP4.DOMAIN cl.vl5.redhat.com    |
      | check  | nmcli_con_prop vlan5 ipv6.method auto                |
      | check  | nmcli_con_prop vlan5 IP6.DNS ''                      |
      | check  | nmcli_con_active eth0 eth0                           |
      | check  | nmcli_con_prop eth0 ipv4.method disabled             |
      | check  | nmcli_con_prop eth0 ipv6.method disabled             |
      | check  | wait_for_ip4_renew 192.168.55.6/30 vlan5             |
      | check  | dns_search vl5.redhat.com                            |
      | check  | nmcli_con_num 2                                      |
      | check  | no_ifcfg                                             |
      | check  | ip4_route_unique "default via 192.168.55.5"          |
      | check  | ip4_route_unique "192.168.55.4/30 dev vlan5"         |
      | check  | nfs_server 192.168.55.5                              |


    @rhelver+=8.3 @fedoraver+=32
    @ver-=1.24
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_mutliple_over_nic
    Scenario: NM - dracut - NM module - multiple VLANs over single NIC
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.55.9:/client ro                         |
      | kernel | vlan=vlan.5:eth0 vlan=vlan.0009:eth0                     |
      | qemu   | -netdev tap,id=vlan,script=$PWD/qemu-ifup/vlan           |
      | qemu   | -device virtio-net,netdev=vlan,mac=52:54:00:12:34:11     |
      | check  | nmcli_con_active vlan.5 vlan.5 45                        |
      | check  | nmcli_con_prop vlan.5 vlan.id 5                          |
      | check  | nmcli_con_prop vlan.5 vlan.parent eth0                   |
      | check  | nmcli_con_prop vlan.5 ipv4.method auto                   |
      | check  | nmcli_con_prop vlan.5 IP4.ADDRESS 192.168.55.6/30 45     |
      | check  | nmcli_con_prop vlan.5 IP4.GATEWAY 192.168.55.5           |
      | check  | nmcli_con_prop vlan.5 IP4.ROUTE *192.168.55.4/30*        |
      | check  | nmcli_con_prop vlan.5 IP4.DNS 192.168.55.5               |
      | check  | nmcli_con_prop vlan.5 IP4.DOMAIN cl.vl5.redhat.com       |
      | check  | nmcli_con_prop vlan.5 ipv6.method auto                   |
      | check  | nmcli_con_prop vlan.5 IP6.DNS ''                         |
      | check  | nmcli_con_active vlan.0009 vlan.0009 45                  |
      | check  | nmcli_con_prop vlan.0009 vlan.id 9                       |
      | check  | nmcli_con_prop vlan.0009 vlan.parent eth0                |
      | check  | nmcli_con_prop vlan.0009 ipv4.method auto                |
      | check  | nmcli_con_prop vlan.0009 IP4.ADDRESS 192.168.55.10/30 45 |
      | check  | nmcli_con_prop vlan.0009 IP4.GATEWAY 192.168.55.9        |
      | check  | nmcli_con_prop vlan.0009 IP4.ROUTE *192.168.55.8/30*     |
      | check  | nmcli_con_prop vlan.0009 IP4.DNS 192.168.55.9            |
      | check  | nmcli_con_prop vlan.0009 IP4.DOMAIN cl.vl9.redhat.com    |
      | check  | nmcli_con_prop vlan.0009 ipv6.method auto                |
      | check  | nmcli_con_prop vlan.0009 IP6.DNS ''                      |
      | check  | wait_for_ip4_renew 192.168.55.6/30 vlan.5                |
      | check  | wait_for_ip4_renew 192.168.55.10/30 vlan.0009            |
      | check  | dns_search *vl5.redhat.com*                              |
      | check  | dns_search *vl9.redhat.com*                              |
      | check  | nmcli_con_num 2                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "default via 192.168.55.5"              |
      | check  | ip4_route_unique "192.168.55.4/30 dev vlan.5"            |
      | check  | ip4_route_unique "default via 192.168.55.9"              |
      | check  | ip4_route_unique "192.168.55.8/30 dev vlan.0009"         |
      | check  | nfs_server 192.168.55.9                                  |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_mutliple_over_nic
    Scenario: NM - dracut - NM module - multiple VLANs over single NIC
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.55.9:/client ro ip=vlan.5:dhcp          |
      | kernel | vlan=vlan.5:eth0 vlan=vlan.0009:eth0                     |
      | qemu   | -netdev tap,id=vlan,script=$PWD/qemu-ifup/vlan           |
      | qemu   | -device virtio-net,netdev=vlan,mac=52:54:00:12:34:11     |
      | check  | nmcli_con_active vlan.5 vlan.5 45                        |
      | check  | nmcli_con_prop vlan.5 vlan.id 5                          |
      | check  | nmcli_con_prop vlan.5 vlan.parent eth0                   |
      | check  | nmcli_con_prop vlan.5 ipv4.method auto                   |
      | check  | nmcli_con_prop vlan.5 IP4.ADDRESS 192.168.55.6/30 45     |
      | check  | nmcli_con_prop vlan.5 IP4.GATEWAY 192.168.55.5           |
      | check  | nmcli_con_prop vlan.5 IP4.ROUTE *192.168.55.4/30*        |
      | check  | nmcli_con_prop vlan.5 IP4.DNS 192.168.55.5               |
      | check  | nmcli_con_prop vlan.5 IP4.DOMAIN cl.vl5.redhat.com       |
      | check  | nmcli_con_prop vlan.5 ipv6.method auto                   |
      | check  | nmcli_con_prop vlan.5 IP6.DNS ''                         |
      | check  | nmcli_con_active vlan.0009 vlan.0009 45                  |
      | check  | nmcli_con_prop vlan.0009 vlan.id 9                       |
      | check  | nmcli_con_prop vlan.0009 vlan.parent eth0                |
      | check  | nmcli_con_prop vlan.0009 ipv4.method auto                |
      | check  | nmcli_con_prop vlan.0009 IP4.ADDRESS 192.168.55.10/30 45 |
      | check  | nmcli_con_prop vlan.0009 IP4.GATEWAY 192.168.55.9        |
      | check  | nmcli_con_prop vlan.0009 IP4.ROUTE *192.168.55.8/30*     |
      | check  | nmcli_con_prop vlan.0009 IP4.DNS 192.168.55.9            |
      | check  | nmcli_con_prop vlan.0009 IP4.DOMAIN cl.vl9.redhat.com    |
      | check  | nmcli_con_prop vlan.0009 ipv6.method auto                |
      | check  | nmcli_con_prop vlan.0009 IP6.DNS ''                      |
      | check  | nmcli_con_active eth0 eth0                               |
      | check  | nmcli_con_prop eth0 ipv4.method disabled                 |
      | check  | nmcli_con_prop eth0 ipv6.method disabled                 |
      | check  | wait_for_ip4_renew 192.168.55.6/30 vlan.5                |
      | check  | wait_for_ip4_renew 192.168.55.10/30 vlan.0009            |
      | check  | dns_search *vl5.redhat.com*                              |
      | check  | dns_search *vl9.redhat.com*                              |
      | check  | nmcli_con_num 3                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "default via 192.168.55.5"              |
      | check  | ip4_route_unique "192.168.55.4/30 dev vlan.5"            |
      | check  | ip4_route_unique "default via 192.168.55.9"              |
      | check  | ip4_route_unique "192.168.55.8/30 dev vlan.0009"         |
      | check  | nfs_server 192.168.55.9                                  |


    @rhbz1879003
    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.27
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_bridge
    Scenario: NM - dracut - NM module - VLAN over bridge
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.55.33:/client ro                        |
      | kernel | bridge=br0:eth0,eth1 vlan=br0.0033:br0                   |
      | qemu   | -netdev tap,id=vlan33_0,script=$PWD/qemu-ifup/vlan33_0   |
      | qemu   | -device virtio-net,netdev=vlan33_0,mac=52:54:00:12:34:15 |
      | qemu   | -netdev tap,id=vlan33_1,script=$PWD/qemu-ifup/vlan33_1   |
      | qemu   | -device virtio-net,netdev=vlan33_1,mac=52:54:00:12:34:16 |
      | check  | nmcli_con_active br0 br0 45                              |
      | check  | nmcli_con_prop br0 ipv4.method disabled                  |
      | check  | nmcli_con_prop br0 ipv6.method disabled                  |
      | check  | nmcli_con_active br0.0033 br0.0033 45                    |
      | check  | nmcli_con_prop br0.0033 vlan.id 33                       |
      | check  | nmcli_con_prop br0.0033 vlan.parent br0                  |
      | check  | nmcli_con_prop br0.0033 ipv4.method auto                 |
      | check  | nmcli_con_prop br0.0033 IP4.ADDRESS 192.168.55.35/29 45  |
      | check  | nmcli_con_prop br0.0033 IP4.GATEWAY 192.168.55.33        |
      | check  | nmcli_con_prop br0.0033 IP4.ROUTE *192.168.55.32/29*     |
      | check  | nmcli_con_prop br0.0033 IP4.DNS 192.168.55.33            |
      | check  | nmcli_con_prop br0.0033 IP4.DOMAIN cl.vl33.redhat.com    |
      | check  | nmcli_con_prop br0.0033 ipv6.method auto                 |
      | check  | nmcli_con_prop br0.0033 IP6.DNS ''                       |
      | check  | wait_for_ip4_renew 192.168.55.35 br0.0033                |
      | check  | dns_search *vl33.redhat.com*                             |
      | check  | nmcli_con_num 4                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip_route_unique "192.168.55.32/29 dev br0.0033"          |
      | check  | ip_route_unique "default via 192.168.55.33 dev br0.0033" |
      | check  | nfs_server 192.168.55.33                                 |


    @rhelver+=8.3 @fedoraver+=32
    @ver-=1.24
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_bond
    Scenario: NM - dracut - NM module - VLAN over bond
    * Run dracut test
      | Param  | Value                                                   |
      | kernel | root=nfs:192.168.55.13:/client ro                       |
      | kernel | bond=bond0:eth0,eth1:mode=balance-rr                    |
      | kernel | vlan=bond0.13:bond0                                     |
      | qemu   | -netdev tap,id=bond0_0,script=$PWD/qemu-ifup/bond0_0    |
      | qemu   | -device virtio-net,netdev=bond0_0,mac=52:54:00:12:34:11 |
      | qemu   | -netdev tap,id=bond0_1,script=$PWD/qemu-ifup/bond0_1    |
      | qemu   | -device virtio-net,netdev=bond0_1,mac=52:54:00:12:34:12 |
      | check  | nmcli_con_active bond0 bond0 45                         |
      | check  | nmcli_con_prop bond0 bond.options mode=balance-rr       |
      | check  | nmcli_con_prop bond0 ipv4.method auto                   |
      | check  | nmcli_con_prop bond0 IP4.ADDRESS 192.168.53.101/24 45   |
      | check  | nmcli_con_prop bond0 IP4.GATEWAY 192.168.53.1           |
      | check  | nmcli_con_prop bond0 IP4.ROUTE *192.168.53.0/24*        |
      | check  | nmcli_con_prop bond0 IP4.DNS 192.168.53.1               |
      | check  | nmcli_con_prop bond0 IP4.DOMAIN cl.bond0.redhat.com     |
      | check  | nmcli_con_prop bond0 ipv6.method auto                   |
      | check  | nmcli_con_prop bond0 IP6.DNS ''                         |
      | check  | nmcli_con_active bond0.13 bond0.13 45                   |
      | check  | nmcli_con_prop bond0.13 vlan.id 13                      |
      | check  | nmcli_con_prop bond0.13 vlan.parent bond0               |
      | check  | nmcli_con_prop bond0.13 ipv4.method auto                |
      | check  | nmcli_con_prop bond0.13 IP4.ADDRESS 192.168.55.14/30 45 |
      | check  | nmcli_con_prop bond0.13 IP4.GATEWAY 192.168.55.13       |
      | check  | nmcli_con_prop bond0.13 IP4.ROUTE *192.168.55.12/30*    |
      | check  | nmcli_con_prop bond0.13 IP4.DNS 192.168.55.13           |
      | check  | nmcli_con_prop bond0.13 IP4.DOMAIN cl.vl13.redhat.com   |
      | check  | nmcli_con_prop bond0.13 ipv6.method auto                |
      | check  | nmcli_con_prop bond0.13 IP6.DNS ''                      |
      | check  | wait_for_ip4_renew 192.168.53.101/24 bond0              |
      | check  | wait_for_ip4_renew 192.168.55.14/30 bond0.13            |
      | check  | dns_search *bond0.redhat.com*                           |
      | check  | dns_search *vl13.redhat.com*                            |
      | check  | nmcli_con_num 4                                         |
      | check  | no_ifcfg                                                |
      | check  | ip4_route_unique "default via 192.168.53.1"             |
      | check  | ip4_route_unique "192.168.53.0/24 dev bond0"            |
      | check  | ip4_route_unique "default via 192.168.55.13"            |
      | check  | ip4_route_unique "192.168.55.12/30 dev bond0.13"        |
      | check  | nfs_server 192.168.55.13                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.25
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_bond
    Scenario: NM - dracut - NM module - VLAN over bond
    * Run dracut test
      | Param  | Value                                                   |
      | kernel | root=nfs:192.168.55.13:/client ro                       |
      | kernel | bond=bond0:eth0,eth1:mode=balance-rr                    |
      | kernel | vlan=bond0.13:bond0                                     |
      | qemu   | -netdev tap,id=bond0_0,script=$PWD/qemu-ifup/bond0_0    |
      | qemu   | -device virtio-net,netdev=bond0_0,mac=52:54:00:12:34:11 |
      | qemu   | -netdev tap,id=bond0_1,script=$PWD/qemu-ifup/bond0_1    |
      | qemu   | -device virtio-net,netdev=bond0_1,mac=52:54:00:12:34:12 |
      | check  | nmcli_con_active bond0 bond0 45                         |
      | check  | nmcli_con_prop bond0 bond.options mode=balance-rr       |
      | check  | nmcli_con_prop bond0 ipv4.method disabled               |
      | check  | nmcli_con_prop bond0 ipv6.method disabled               |
      | check  | nmcli_con_active bond0.13 bond0.13 45                   |
      | check  | nmcli_con_prop bond0.13 vlan.id 13                      |
      | check  | nmcli_con_prop bond0.13 vlan.parent bond0               |
      | check  | nmcli_con_prop bond0.13 ipv4.method auto                |
      | check  | nmcli_con_prop bond0.13 IP4.ADDRESS 192.168.55.14/30 45 |
      | check  | nmcli_con_prop bond0.13 IP4.GATEWAY 192.168.55.13       |
      | check  | nmcli_con_prop bond0.13 IP4.ROUTE *192.168.55.12/30*    |
      | check  | nmcli_con_prop bond0.13 IP4.DNS 192.168.55.13           |
      | check  | nmcli_con_prop bond0.13 IP4.DOMAIN cl.vl13.redhat.com   |
      | check  | nmcli_con_prop bond0.13 ipv6.method auto                |
      | check  | nmcli_con_prop bond0.13 IP6.DNS ''                      |
      | check  | wait_for_ip4_renew 192.168.55.14/30 bond0.13            |
      | check  | dns_search *vl13.redhat.com*                            |
      | check  | nmcli_con_num 4                                         |
      | check  | no_ifcfg                                                |
      | check  | ip4_route_unique "default via 192.168.55.13"            |
      | check  | ip4_route_unique "192.168.55.12/30 dev bond0.13"        |
      | check  | nfs_server 192.168.55.13                                |


    @rhelver+=8.3 @fedoraver+=32
    @ver+=1.27
    @dracut @long @not_on_ppc64le
    @dracut_NM_vlan_over_team_no_boot
    Scenario: NM - dracut - NM module - VLAN over team boot over other iface (team not stable)
    * Run dracut test
      | Param  | Value                                                    |
      | kernel | root=nfs:192.168.50.1:/client ro                         |
      | kernel | team=team0:eth0,eth1 vlan=vlan0017:team0 ip=eth2:dhcp    |
      | qemu   | -netdev tap,id=bond1_0,script=$PWD/qemu-ifup/bond1_0     |
      | qemu   | -device virtio-net,netdev=bond1_0,mac=52:54:00:12:34:11  |
      | qemu   | -netdev tap,id=bond1_1,script=$PWD/qemu-ifup/bond1_1     |
      | qemu   | -device virtio-net,netdev=bond1_1,mac=52:54:00:12:34:12  |
      | qemu   | -netdev tap,id=nfs,script=$PWD/qemu-ifup/nfs             |
      | qemu   | -device virtio-net,netdev=nfs,mac=52:54:00:12:34:10      |
      | check  | nmcli_con_active team0 team0 45                          |
      | check  | nmcli_con_prop team0 ipv4.method disabled                |
      | check  | nmcli_con_prop team0 ipv6.method disabled                |
      | check  | nmcli_con_active vlan0017 vlan0017 45                    |
      | check  | nmcli_con_prop vlan0017 vlan.id 17                       |
      | check  | nmcli_con_prop vlan0017 vlan.parent team0                |
      | check  | nmcli_con_prop vlan0017 ipv4.method auto                 |
      | check  | nmcli_con_prop vlan0017 IP4.ADDRESS 192.168.55.18/30 45  |
      | check  | nmcli_con_prop vlan0017 IP4.GATEWAY 192.168.55.17        |
      | check  | nmcli_con_prop vlan0017 IP4.ROUTE *192.168.55.16/30*     |
      | check  | nmcli_con_prop vlan0017 IP4.DNS 192.168.55.17 45         |
      | check  | nmcli_con_prop vlan0017 IP4.DOMAIN cl.vl17.redhat.com    |
      | check  | nmcli_con_prop vlan0017 ipv6.method auto                 |
      | check  | nmcli_con_prop vlan0017 IP6.DNS ''                       |
      | check  | nmcli_con_active eth2 eth2                               |
      | check  | nmcli_con_prop eth2 ipv4.method auto                     |
      | check  | nmcli_con_prop eth2 IP4.ADDRESS 192.168.50.101/24 10     |
      | check  | nmcli_con_prop eth2 IP4.GATEWAY 192.168.50.1             |
      | check  | nmcli_con_prop eth2 IP4.ROUTE *192.168.50.0/24*          |
      | check  | nmcli_con_prop eth2 IP4.DNS 192.168.50.1                 |
      | check  | nmcli_con_prop eth2 IP4.DOMAIN cl01.nfs.redhat.com       |
      | check  | nmcli_con_prop eth2 ipv6.method auto                     |
      | check  | nmcli_con_prop eth2 IP6.ADDRESS *deaf:beef::1:10/128* 10 |
      | check  | nmcli_con_prop eth2 IP6.ROUTE *deaf:beef::/64*           |
      | check  | nmcli_con_prop eth2 IP6.DNS deaf:beef::1 10              |
      | check  | wait_for_ip4_renew 192.168.55.18/30 vlan0017             |
      | check  | wait_for_ip4_renew 192.168.50.101/24 eth2                |
      | check  | wait_for_ip6_renew deaf:beef::1:10/128 eth2              |
      | check  | dns_search *vl17.redhat.com*                             |
      | check  | dns_search *nfs.redhat.com*                              |
      | check  | dns_search *nfs6.redhat.com*                             |
      | check  | dns_search *nfs6.redhat.com*                             |
      | check  | nmcli_con_num 5                                          |
      | check  | no_ifcfg                                                 |
      | check  | ip4_route_unique "default via 192.168.55.17"             |
      | check  | ip4_route_unique "192.168.55.16/30 dev vlan0017"         |
      | check  | ip4_route_unique "default via 192.168.50.1"              |
      | check  | ip4_route_unique "192.168.50.0/24 dev eth2"              |
      | check  | ip6_route_unique "deaf:beef::1:10 dev eth2 proto kernel" |
      | check  | ip6_route_unique "deaf:beef::/64 dev eth2 proto ra"      |
      | check  | nfs_server 192.168.50.1                                  |


    ##########
    # legacy #
    ##########


    @rhelver+=8.3 @fedoraver+=32
    @dracut @long @x86_64_only
    @dracut_legacy_iSCSI_ibft_table
    Scenario: NM - dracut - legacy module - iSCSI ibft table
    * Run dracut test
      | Param  | Value                                                   |
      | initrd | initramfs.client.legacy                                 |
      | type   | iscsi_single                                            |
      | kernel | root=LABEL=singleroot                                   |
      | kernel | rd.iscsi.ibft=1 rd.iscsi.firmware=1                     |
      | kernel | rw rd.auto                                              |
      | qemu   | -device virtio-net,netdev=iscsi0,mac=52:54:00:12:34:a1  |
      | qemu   | -device virtio-net,netdev=iscsi1,mac=52:54:00:12:34:a2  |
      | qemu   | -netdev tap,id=iscsi0,script=$PWD/qemu-ifup/iscsi0      |
      | qemu   | -netdev tap,id=iscsi1,script=$PWD/qemu-ifup/iscsi1      |
      | qemu   | -acpitable file=conf/ibft.table                         |
      | check  | nmcli_con_active ibft0 ibft0                            |
      | check  | nmcli_con_prop ibft0 ipv4.method auto                   |
      | check  | nmcli_con_prop ibft0 IP4.ADDRESS 192.168.51.101/24 10   |
      | check  | nmcli_con_prop ibft0 IP4.GATEWAY 192.168.51.1           |
      | check  | nmcli_con_prop ibft0 IP4.ROUTE *192.168.51.0/24*        |
      | check  | nmcli_con_prop ibft0 IP4.DNS 192.168.51.1               |
      | check  | nmcli_con_prop ibft0 IP4.DOMAIN cl.iscsi0.redhat.com    |
      | check  | nmcli_con_prop ibft0 ipv6.method link-local             |
      | check  | wait_for_ip4_renew 192.168.51.101/24 ibft0              |
      | check  | link_no_ip4 eth1                                        |
      | check  | dns_search iscsi0.redhat.com                            |
      | check  | nmcli_con_num 1                                         |
      # duplicit routes with legacy module
      #| check  | ip_route_unique "default via 192.168.51.1"              |
      #| check  | ip_route_unique "192.168.51.0/24 dev ibft0"             |
      | check  | mount_root_type ext3                                    |


    ############
    # teardown #
    ############


    @rhelver+=8.3 @fedoraver+=32
    @dracut_teardown
    Scenario: NM - dracut tests cleanup
    * Execute "cd contrib/dracut; . ./setup.sh; { time test_clean; }"
