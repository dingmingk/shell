#!/bin/sh
#-----------------------
#  Kill the redundant Rsync process
#-----------------------
#  By jindm 
#  dingmingk@gmail.com
#  2014-8-15

for i in `ps -ef | grep rsync | grep -v grep | awk {'print $2'}`
do
	kill -9 $i
	echo "Kill $i successed."
done
