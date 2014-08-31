#!/bin/sh
#-----------------------
#  Linux web backup
#-----------------------
#  By jindm
#  dingmingk@gmail.com
#  2013-12-9

set -e
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
LOGDIR=/var/log
LOGFILE=${LOGDIR}/backup-manager.log
BAKTYPE=webbackup
LOCKFILE=/${LOGDIR}/${BAKTYPE}.lock
DATE=`date +%Y%m%d`
LOCALBAKDIR=/backup/web
IP=`ifconfig |grep "inet addr"|grep -v "inet addr:127\.0\.0\.1"|grep -v "inet addr:10\."|awk '{print $2}' |sed "s/addr://g"|head -1`
run_dir=`pwd`
MOMENT_SEGMENT=`date +'%Y%m%d-%H%M%S'`
FTP_USER="xxxxxxxxxx"
FTP_PASS="xxxxxxxxxxxxxx"

function choose_ftpserver() {
segment1=`echo $IP|cut -d'.' -f 1-3`
segment2=`echo $IP|cut -d'.' -f 1-2`
if [ ${segment1} = "xxx.xxx.xxx" ];then
ftpserver="ftpserver1.webbackup.xx.com"
elif [ ${segment1} = "xxx.xxx.xxx" ];then
ftpserver="ftpserver2.webbackup.xx.com"
elif [ ${segment1} = "xxx.xxx.xxx" ];then
ftpserver="ftpserver3.webbackup.xx.com"
else
ftpserver="ftpserver.webbackup.xx.com"
fi
}

MK_UPLOAD_DESTINATION() {
(
ftp -ni ${ftpserver} <<EOF
quote USER ${FTP_USER}
quote PASS ${FTP_PASS}
binary
cd linux
mkdir ${IP}
cd ${IP}
mkdir ${BAKTYPE}
cd ${BAKTYPE}
pwd
bye
EOF
) >>/dev/null 2>&1
}
function edit_BackupManager_conf() {
choose_ftpserver;
MK_UPLOAD_DESTINATION;
FTP_PATH="linux/${IP}/${BAKTYPE}"
FTP_PATH1="linux\/${IP}\/${BAKTYPE}"
cd ${run_dir};
sed -i "/^export BM_TARBALLINC_MASTERDATEVALUE/s/\"\"/\"$(($RANDOM%7))\"/g" backup-manager.conf
sed -i "/^export BM_UPLOAD_HOSTS/s/\"\"/\"${ftpserver}\"/g" backup-manager.conf
sed -i "/^export BM_UPLOAD_DESTINATION/s/\"\"/\"${FTP_PATH1}\"/g" backup-manager.conf
sed -i "/^export BM_UPLOAD_FTP_HOSTS/s/\"\"/\"${ftpserver}\"/g" backup-manager.conf
sed -i "/^export BM_UPLOAD_FTP_DESTINATION/s/\"\"/\"${FTP_PATH1}\"/g" backup-manager.conf
}

function install_BackupManager() {
run_dir=`pwd`
BackupManager_version=0.7.10
cd ${run_dir};tar -zxf Backup-Manager-${BackupManager_version}.tar.gz;
cd Backup-Manager-${BackupManager_version};make install;
edit_BackupManager_conf;
/bin/cp  ${run_dir}/backup-manager.conf /etc/backup-manager.conf;
}

if [ ! -d /root/ndserver/webbackup/ ];then
mkdir -p /root/ndserver/webbackup/;
fi  
#install backup-manager;
if [ ! -f /usr/bin/gettext ];then
yum -y install gettext;
fi
if [ ! -f /usr/bin/ftp ];then
yum -y install ftp;
fi
if [ ! -f /usr/bin/which ];then
yum -y install which;
fi

if [ ! -f /bin/dbus-daemon ];then
yum -y install dbus
fi
if [ ! -f /var/run/messagebus.pid ];then
dbus-daemon --system
sed -i '/dbus-daemon/d' /etc/rc.local
echo "dbus-daemon --system" >>/etc/rc.local
fi
cd /root/ndserver/webbackup/;
wget -S "http://nagios.xx.com/ndtool/webbackup/linux_web_backup.tar.gz" 
tar -zxf linux_web_backup.tar.gz;
install_BackupManager;
#Add nagios_monitor
cd ${run_dir};/bin/cp ./check_monitorwebbackup /usr/local/nagios/libexec/
chmod 755 /usr/local/nagios/libexec/check_monitorwebbackup;
chown nagios.nagios /usr/local/nagios/libexec/check_monitorwebbackup;
/bin/cp /usr/local/nagios/etc/nrpe.cfg /usr/local/nagios/etc/nrpe.cfg.${MOMENT_SEGMENT}
sed -i '/check_monitorbackup/d' /usr/local/nagios/etc/nrpe.cfg
echo "command[check_monitorwebbackup]=/usr/local/nagios/libexec/check_monitorwebbackup" >>/usr/local/nagios/etc/nrpe.cfg 
pkill nrpe;sleep 4;/usr/local/nagios/bin/nrpe -c /usr/local/nagios/etc/nrpe.cfg -d
#Add crond to run every day
chmod 755 /root/ndserver/webbackup/webbackup-manager.sh
/bin/cp /etc/crontab /etc/crontab.${MOMENT_SEGMENT}
sed -i '/webbackup-manager.sh/d' /etc/crontab 
echo "$(($RANDOM%60)) $(($RANDOM%4+2)) * * * root  (/root/webbackup/webbackup-manager.sh 2>&1 > /dev/null &)" >>/etc/crontab
echo "$(($RANDOM%60)) $(($RANDOM%2+8)) * * * root  (sh /root//webbackup/repair_linux_webbackup.sh 2>&1 > /dev/null &)" >>/etc/crontab
chkconfig --level 345 crond on

#remove  netdisk
/bin/cp /etc/rc.local /etc/rc.local.${MOMENT_SEGMENT}
sed -i '/\/remotebackup/s/^/#/g' /etc/rc.local
mount_num=`ps aux|grep ndfs_fuse|grep remotebackup|wc -l`
if [ ${mount_num} -eq 1 ];then
umount -l /remotebackup
kill -9 `ps aux|grep ndfs_fuse|grep remotebackup|awk '{print $2}'`
elif [ `ps aux|grep ndfs_fuse|grep remotebackup|wc -l` -gt 1 ];then
exit 1;echo "they are more mount on /remotebackup."
else
exit 0;echo "that is no mount on /remotebackup."
fi

service crond start
