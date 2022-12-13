#!/bin/bash
# Try to flood hostapd by EAPOL frames from random MAC addresses.
# Traffic is mirrored to test1 device.
# We can prepare the env by running ./test_run.sh 8021x_hostapd_freeradius_doc_procedure
# with '* Wait for "3600" seconds' before first 'When Bring up connection "test1-ttls"' step.

ip link del dev fuzz0 >/dev/null 2>&1
ip link add dev fuzz0 type dummy
ip link set dev fuzz0 up
tc qdisc add dev fuzz0 clsact
tc filter add dev fuzz0 egress protocol 0x888e matchall action mirred egress redirect dev test1


case ${1:-pae_group} in
broadcast)
	mac_dest="ff:ff:ff:ff:ff:ff"
	;;
unicast_ok)
	mac_dest="52:54:00:3b:17:10"
	;;
unicast_ko)
	mac_dest="00:0c:1a:0b:e1:1a"
	;;
pae_group | *)
	mac_dest="01:80:c2:00:00:03"
	;;
esac


for i in `seq 1 32`; do
	oct1=$(($RANDOM % 256))
	oct2=$(($RANDOM % 256))
	oct3=$(($RANDOM % 256))

	mac_src=`printf 00:13:c8:%02x:%02x:%02x $oct1 $oct2 $oct3`
	scapy <<-EOF
		e = Ether(dst='$mac_dest',src='$mac_src',type=0x888e)/EAPOL(version=1,type=1,len=0)
		sendp(e,iface='fuzz0',count=1)
	EOF
done
