#!/bin/sh
# this generates ibft.table file

perl ibft.pl \
		--initiator iqn=iqn.1994-05.com.redhat:633114aacf2 \
		--nic ip=192.168.51.101,prefix=24,gw=192.168.51.1,dns1=192.168.51.1,dhcp=192.168.51.1,mac=52:54:00:12:34:a1,pci=00:03.0 \
		--target nic=0,ip=192.168.51.1,port=3260,lun=1,name=iqn.2009-06.dracut:target0 > ibft.table
