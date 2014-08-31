#!/bin/sh
#-----------------------
#  Get KVM MAC 
#-----------------------
#  By jindm 
#  dingmingk@gmail.com
#  2013-12-2

getMAC(){
	MAC_ADDR=$(echo $1 | awk -F'.''{printf("%02X:%02X:%02X:%02X\n",$1,$2,$3,$4)}')
	}

getMAC $1

echo "02:00:"$MAC_ADDR
