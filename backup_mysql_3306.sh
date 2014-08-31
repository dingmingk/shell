#!/bin/bash
# yum install cmake gcc gcc-c++ libaio libaio-devel automake autoconf bzr bison libtool ncurses5-devel
# 免安装包
# 64位
# http://www.percona.com/redir/downloads/XtraBackup/LATEST/binary/Linux/x86_64/percona-xtrabackup-2.0.2-461.tar.gz
# 32位
# http://www.percona.com/redir/downloads/XtraBackup/LATEST/binary/Linux/i686/percona-xtrabackup-2.0.2-461.tar.gz
# 需要更改innobackupex-1.5.1文件以下内容，否则可能会出现innobackupex: Error: mysql child process has died： MySQL server has gone away
#if (compare_versions($mysql_server_version, '4.0.22') == 0
#        || compare_versions($mysql_server_version, '4.1.7') == 0) {
#        # MySQL server version is 4.0.22 or 4.1.7
#        mysql_send "COMMIT;";
#        mysql_send "set session interactive_timeout=28800;";
#        mysql_send "set session wait_timeout=28800";
#        mysql_send "FLUSH TABLES WITH READ LOCK;";
#    } else {
#        # MySQL server version is other than 4.0.22 or 4.1.7
#        mysql_send "set session interactive_timeout=28800;";
#        mysql_send "set session wait_timeout=28800;";
#        mysql_send "FLUSH TABLES WITH READ LOCK;";
#        mysql_send "COMMIT;";
#    }

## Settings ##
PATH="/bin:/usr/bin"
USER="root"
PASSWD="xxxxxxxxxxxxxxxxx"
SOCKET="/tmp/mysql_3306.sock"
MYCNF="/usr/local/mysql/my.cnf"
BACKUPDIR="/backup/3306"
# 如果不需远程备份将REMOTE_BACKUPDIR设置为空
REMOTE_BACKUPDIR=""
MINFREE_M="5000"
INNOBACKUPEX_OPTIONS="--user=${USER} --password=${PASSWD}  --socket=${SOCKET} --slave-info --defaults-file=${MYCNF}"
RETENTION_DAYS_LOCAL="5"
RETENTION_DAYS_REMOTE="30"

## Logic ##
timestamp=`date +%Y%m%d_%H%M%S_%Z`
export PATH;

if [ ! -x "/usr/bin/innobackupex-1.5.1" ]; then
  echo "ERROR: /usr/bin/innobackupex-1.5.1 is not executable."
  exit 1
fi 

if [ ! -d ${BACKUPDIR} ]; then
  echo "ERROR: ${BACKUPDIR} is not a directory."
  exit 2
fi

#if [ ! -d ${REMOTE_BACKUPDIR} ]; then
#  echo "ERROR: ${REMOTE_BACKUPDIR} is not a directory or not exist."
#  exit 3
#fi

freespace_m=`df -k ${BACKUPDIR} | awk '{ if ($4 ~ /^[0-9]*$/) { print int($4/1024) } }'`
if [ ${freespace_m} -le ${MINFREE_M} ]; then
  echo "ERROR: There is less than ${MINFREE_M} MB of free space on ${BACKUPDIR}"
  exit 4
fi

# Remove backups older than $RETENTION_DAYS
#find ${BACKUPDIR} -name "*_*_*_xtrabackup\.tar\.bz2" -type f -mtime +${RETENTION_DAYS_LOCAL}
find ${BACKUPDIR} -name "*_*_*_xtrabackup\.*" -type f -mtime +${RETENTION_DAYS_LOCAL} | xargs rm 
#if [ -d ${REMOTE_BACKUPDIR} ]; then
#	find ${REMOTE_BACKUPDIR} -name "*_*_*_xtrabackup\.tar\.bz2" -type f -mtime +${RETENTION_DAYS_REMOTE}
#fi

# Create the backup
#/usr/bin/innobackupex-1.5.1 ${INNOBACKUPEX_OPTIONS} --stream=tar /tmp 2> ${BACKUPDIR}/${timestamp}_xtrabackup.log | bzip2 > ${BACKUPDIR}/${timestamp}_xtrabackup.tar.bz2
/usr/bin/innobackupex-1.5.1 ${INNOBACKUPEX_OPTIONS} --no-timestamp ${BACKUPDIR}/${timestamp}  2> ${BACKUPDIR}/${timestamp}_xtrabackup.log
cd ${BACKUPDIR}
tar czpf  ${timestamp}_xtrabackup.tar.gz  ./${timestamp}
if [ $? = 0 ]; then
  rm -rf ${timestamp}
fi

# Copy to remotedir
if [ -d ${REMOTE_BACKUPDIR} ]; then
	cp -RP ${BACKUPDIR}/${timestamp}_xtrabackup.tar.gz  ${REMOTE_BACKUPDIR}
	cp -RP ${BACKUPDIR}/${timestamp}_xtrabackup.log  ${REMOTE_BACKUPDIR}
fi	
