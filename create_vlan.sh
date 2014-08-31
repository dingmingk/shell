#!/bin/sh
#-----------------------
#  Create KVM Vlan
#-----------------------
#  By jindm 
#  dingmingk@gmail.com
#  2013-6-18

if [ $# -lt 2 ]; then
	echo "usage: $0 vlanID PHY_net_card"
	echo "example: $0 108 eth1"
	exit
fi

vlanid=$1
PHY_net=$2

createVlan(){
	brctl addbr br-vlan-$vlanid
	ifconfig br-vlan-$vlanid up
	vconfig add $PHY_net $vlanid
	brctl addif br-vlan-$vlanid ${PHY_net}.${vlanid}
	ifconfig ${PHY_net}.${vlanid} up
}

createVlan
