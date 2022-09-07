 Feature: nmcli: tc

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz909236
    @ver+=1.10
    @set_fq_codel_queue
    Scenario: nmcli - tc - set fq_codel
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdiscs 'root fq_codel'
          """
    Then "fq_codel" is visible with command "ip a s dummy0" in "5" seconds


    @rhbz909236
    @ver+=1.25
    @set_pfifo_fast_queue
    Scenario: nmcli - tc - set pfifo_fast
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdiscs 'root fq_codel'
          """
    * Execute "nmcli con modify con_tc tc.qdiscs 'root pfifo_fast'"
    * Bring "up" connection "con_tc"
    Then "pfifo_fast" is visible with command "ip a s dummy0" in "5" seconds


    @rhbz1928078
    @ver+=1.25
    @remove_root_value
    Scenario: nmcli - tc - remove root value
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdiscs 'root pfifo_fast'
          """
    * Send "remove tc.qdiscs" via editor to "con_tc"
    Then Bring "up" connection "con_tc"
    Then "warn" is not visible with command "journalctl -u NetworkManager --since '20s ago'|grep qdisc |grep warn"


    @rhbz1928078
    @ver+=1.30
    @do_not_touch_external_tc
    Scenario: nmcli - tc - do not touch external ones
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Execute "tc qdisc add dev dummy0 root sfq"
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          """
    Then Bring "up" connection "con_tc"
    # We should leave what was set before
    Then "qdisc sfq" is visible with command "ip a s dummy0" in "5" seconds


    @rhbz1928078
    @ver+=1.30
    @override_externally_set_one
    Scenario: nmcli - tc - override external ones
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Execute "tc qdisc add dev dummy0 root sfq"
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdisc "root prio"
          """
    Then Bring "up" connection "con_tc"
    # We should have what NM wanted
    Then "qdisc sfq" is not visible with command "ip a s dummy0" in "5" seconds


    @rhbz1546805 @rhbz1815875
    @ver+=1.30
    @honor_empty_tc
    Scenario: nmcli - tc - reset to default
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Execute "tc qdisc add dev dummy0 root sfq"
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdisc ' '
          """
    Then Bring "up" connection "con_tc"
    # We should be back to kernel default
    Then "sfq" is not visible with command "ip a s dummy0" in "5" seconds


    @rhbz1546802
    @ver+=1.25
    @set_tbf_qdiscs
    Scenario: nmcli - tc - set qdisc tbf
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdiscs 'handle 1235 root tbf rate 1000000 burst 5000 limit 10000 latency 10'
          """
    * Bring "up" connection "con_tc"
    Then "qdisc tbf" is visible with command "ip a s dummy0" in "5" seconds


    @rhbz1546802
    @ver+=1.25
    @set_sqf_qdiscs
    Scenario: nmcli - tc - set qdisc tbf
    * Add "dummy" connection named "con_tc" for device "dummy0" with options
          """
          ipv4.method manual ipv4.addresses 10.0.0.2/24
          tc.qdiscs 'root sfq perturb 10'
          """
    Then "qdisc sfq" is visible with command "ip a s dummy0" in "5" seconds


    @rhbz1436535
    @ver+=1.27
    @tshark
    @tc_morrir_traffic
    Scenario: nmcli - tc - mirror traffic
    * Doc: "Mirroring a network interface using nmcli"
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Add "ethernet" connection named "con_tc" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname example.com
          """
    * Execute "nmcli connection modify con_tc +tc.qdisc "root prio handle 10:""
    * Execute "nmcli connection modify con_tc +tc.qdisc "ingress handle ffff:""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent ffff: matchall action mirred egress mirror dev dummy0""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent 10:   matchall action mirred egress mirror dev dummy0""
    * Bring "down" connection "con_tc"
    * Bring "up" connection "con_tc"
    * Run child "sudo tshark -l -O bootp -i dummy0 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_tc"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 11\s+Host Name: example.com" is visible with command "cat /tmp/tshark.log"


    @rhbz1436535
    @ver+=1.27
    @tshark
    @tc_morrir_traffic_clsact
    Scenario: nmcli - tc - mirror traffic clsact
    * Create "dummy" device named "dummy0"
    * Execute "ip link set dev dummy0 up"
    * Add "ethernet" connection named "con_tc" for device "eth2" with options
          """
          ipv4.may-fail no
          ipv4.dhcp-hostname example.com
          """
    * Execute "nmcli connection modify con_tc +tc.qdisc "clsact""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent ffff:fff3 matchall action mirred egress mirror dev dummy0""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent ffff:fff2  matchall action mirred egress mirror dev dummy0""
    * Bring "down" connection "con_tc"
    * Bring "up" connection "con_tc"
    * Run child "sudo tshark -l -O bootp -i dummy0 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_tc"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 11\s+Host Name: example.com" is visible with command "cat /tmp/tshark.log"


   @rhbz1753677
   @ver+=1.33
   @filter_batch
   @tc_device_filter_management
   Scenario: nmcli - tc - non-controlled device filter management
   * Create "veth" device named "dummy0" with options "peer name dummy1"
   * Execute "ip link set dummy0 up"
   * Execute "ip link set dummy1 up"
   * Execute "tc qdisc add dev dummy0 ingress"
   Then Note the output of """awk -v clk="$(getconf CLK_TCK)" '{ print $14 * 1000 / clk }' /proc/$(pidof NetworkManager)/stat""" as value "user_before"
   Then Note the output of """awk -v clk="$(getconf CLK_TCK)" '{ print $15 * 1000 / clk}' /proc/$(pidof NetworkManager)/stat""" as value "kernel_before"
   * Execute "tc -b /tmp/filter_batch.txt"
   Then Note the output of """awk -v clk="$(getconf CLK_TCK)" '{ print $14 * 1000 / clk }' /proc/$(pidof NetworkManager)/stat""" as value "user_after"
   Then Note the output of """awk -v clk="$(getconf CLK_TCK)" '{ print $15 * 1000 / clk }' /proc/$(pidof NetworkManager)/stat""" as value "kernel_after"
   Then Check noted value "user_after" difference from "user_before" is "less than" "100"
   And Check noted value "kernel_after" difference from "kernel_before" is "less than" "100"
