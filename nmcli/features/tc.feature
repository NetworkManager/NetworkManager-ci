 Feature: nmcli: tc

    # Please do use tags as follows:
    # @bugzilla_link (rhbz123456)
    # @version_control (ver+=1.10,rhelver-=8,fedoraver+30,[not_with_]rhel_pkg,[not_with_]fedora_pkg) - see version_control.py
    # @other_tags (see environment.py)
    # @test_name (compiled from scenario name)
    # Scenario:

    @rhbz909236
    @ver+=1.10
    @con_tc_remove @eth0
    @set_fq_codel_queue
    Scenario: nmcli - tc - set fq_codel
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'root fq_codel'"
    * Bring "up" connection "con_tc"
    Then "fq_codel" is visible with command "ip a s eth0" in "5" seconds


    @rhbz909236
    @ver+=1.10
    @con_tc_remove @eth0
    @set_pfifo_fast_queue
    Scenario: nmcli - tc - set pfifo_fast
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'root fq_codel'"
    * Execute "nmcli con modify con_tc tc.qdiscs 'root pfifo_fast'"
    * Bring "up" connection "con_tc"
    Then "pfifo_fast" is visible with command "ip a s eth0" in "5" seconds


    @rhbz1546805
    @ver+=1.16 @ver-=1.24
    @con_tc_remove @eth0
    @remove_root_value
    Scenario: nmcli - tc - remove root value
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'root pfifo_fast'"
    * Bring "up" connection "con_tc"
    * Send "remove tc.qdiscs" via editor to "con_tc"
    Then Bring "up" connection "con_tc"


    @rhbz1546805 @rhbz1815875
    @ver+=1.25
    @con_tc_remove @eth0
    @remove_root_value
    Scenario: nmcli - tc - remove root value
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'root pfifo_fast'"
    * Bring "up" connection "con_tc"
    * Send "remove tc.qdiscs" via editor to "con_tc"
    Then Bring "up" connection "con_tc"
    Then "warn" is not visible with command "journalctl -u NetworkManager --since '20s ago'|grep qdisc |grep warn"


    @rhbz1546802
    @ver+=1.25
    @con_tc_remove @eth0
    @set_tbf_qdiscs
    Scenario: nmcli - tc - set qdisc tbf
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'handle 1235 root tbf rate 1000000 burst 5000 limit 10000 latency 10'"
    * Bring "up" connection "con_tc"
    Then "qdisc tbf" is visible with command "ip a s eth0" in "5" seconds


    @rhbz1546802
    @ver+=1.25
    @con_tc_remove @eth0
    @set_sqf_qdiscs
    Scenario: nmcli - tc - set qdisc tbf
    * Add a new connection of type "ethernet" and options "ifname eth0 con-name con_tc autoconnect no tc.qdiscs 'root sfq perturb 10'"
    * Bring "up" connection "con_tc"
    Then "qdisc sfq" is visible with command "ip a s eth0" in "5" seconds


    @rhbz1436535
    @ver+=1.27
    @con_tc_remove @dummy @tshark
    @tc_morrir_traffic
    Scenario: nmcli - tc - mirror traffic
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_tc ipv4.may-fail no ipv4.dhcp-hostname example.com"
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
    * Finish "sudo pkill tshark"



    @rhbz1436535
    @ver+=1.27
    @con_tc_remove @dummy @tshark
    @tc_morrir_traffic_clsact
    Scenario: nmcli - tc - mirror traffic clsact
    * Execute "ip link add dummy0 type dummy"
    * Execute "ip link set dev dummy0 up"
    * Add a new connection of type "ethernet" and options "ifname eth2 con-name con_tc ipv4.may-fail no ipv4.dhcp-hostname example.com"
    * Execute "nmcli connection modify con_tc +tc.qdisc "clsact""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent ffff:fff3 matchall action mirred egress mirror dev dummy0""
    * Execute "nmcli connection modify con_tc +tc.tfilter "parent ffff:fff2  matchall action mirred egress mirror dev"
    * Bring "down" connection "con_tc"
    * Bring "up" connection "con_tc"
    * Run child "sudo tshark -l -O bootp -i dummy0 > /tmp/tshark.log"
    When "empty" is not visible with command "file /tmp/tshark.log" in "150" seconds
    * Bring "up" connection "con_tc"
    Then "example.com" is visible with command "cat /tmp/tshark.log" in "10" seconds
     And "Option: \(12\) Host Name\s+Length: 11\s+Host Name: example.com" is visible with command "cat /tmp/tshark.log"
    * Finish "sudo pkill tshark"
