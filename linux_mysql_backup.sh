#!/bin/sh
#-----------------------
#  Linux Mysql backup
#-----------------------
#  By jindm
#  dingmingk@gmail.com
#  2013-12-9


rundir=`pwd`
LOGDIR=/var/log/mysql
filename=`basename $0`
set -e
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

#Add crond to run every day
/bin/cp /etc/crontab /etc/crontab.`date +'%Y%m%d[%T]'`
if [ `grep backup /etc/crontab|grep mysql|wc -l` -ge 1 ] || [ `grep backup /etc/crontab|grep db|wc -l` -ge 1 ];then
echo "please drop the mysqlbackup crontab,then run the script again"; exit;
else 
echo "there is no crontab about mysqlbackup,hava a look for /etc/crontab after this script over";
fi

if [ ! -d /root/mysqlbackup/ ];then
mkdir -p /root/mysqlbackup/;
fi

if [ ! -d /var/log/mysql ];then
mkdir -p /var/log/mysql;
fi
if [ ! -f /usr/bin/paste ];then
yum -y install coreutils;
fi
echo "$(($RANDOM%60)) $(($RANDOM%3+2)) * * * root  (sh -x /root/mysqlbackup/mysql_backup.sh 2>>${LOGDIR}/run_detail_"\`date +\\\%Y\\\%m\\\%d\`" &)" >>/etc/crontab
echo "#$(($RANDOM%60)) $(($RANDOM%3+7)) * * * root  (/root/mysqlbackup/repair_linux_mysqlbackup.sh 2>&1 > /dev/null &)" >>/etc/crontab


cd /root/mysqlbackup/;
rm -f mysql_backup.tar.gz
wget -S "http://nagios.101.com/ndtool/mysqlbackup/mysql_backup.tar.gz" 
tar -zxf mysql_backup.tar.gz
chmod 755 /root/mysqlbackup/mysql_backup.sh

#Add nagios_monitor
cd /root/mysqlbackup/;/bin/cp -a ./check_monitormysqlbackup /usr/local/nagios/libexec/
chmod 755 /usr/local/nagios/libexec/check_monitormysqlbackup;
chown nagios.nagios /usr/local/nagios/libexec/check_monitormysqlbackup;
/bin/cp /usr/local/nagios/etc/nrpe.cfg /usr/local/nagios/etc/nrpe.cfg.`date +'%Y%m%d[%T]'`
echo "command[check_monitormysqlbackup]=/usr/local/nagios/libexec/check_monitormysqlbackup" >>/usr/local/nagios/etc/nrpe.cfg
pkill nrpe;sleep 4;/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
chmod 755 /root/mysqlbackup/repair_linux_mysqlbackup.sh

#remove 10.1.242.152 netdisk
/bin/cp /etc/rc.local /etc/rc.local.`date +'%Y%m%d[%T]'`
sed -i '/\/remotebackup/s/^/#/g' /etc/rc.local
mount_num=`ps aux|grep ndfs_fuse|grep remotebackup|wc -l`
if [ ${mount_num} -eq 1 ];then
umount -l /remotebackup
kill -9 `ps aux|grep ndfs_fuse|grep remotebackup|awk '{print $2}'`
elif [ `ps aux|grep ndfs_fuse|grep remotebackup|wc -l` -gt 1 ];then
exit 1;echo "they are more mount on /remotebackup."
else
echo "that is no mount on /remotebackup."
fi
echo "please add the mysqlbackup in mysql master instance,COMMAND: mysql -S /tmp/mysql.sock -u root -p  -e grant SELECT,RELOAD,LOCK TABLES,super,process,show view on *.* to mysqlbackup@'localhost' identified by 'r3bYH3vdr753hd78rjwe'; "

sleep 3
rm -fv $rundir/$filename
