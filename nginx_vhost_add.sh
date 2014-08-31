#!/bin/sh
#------------------------
# Add nginx vhost
#------------------------
# By jindm
# dingmingk@gmail.com
# 2013-9-5

#global setting
NGINXCONF=/usr/local/nginx/conf/nginx.conf
NGINXHOST=/usr/local/nginx/conf
DATE=$(date +%y%m%d)

if [ ! -d ${NGINXHOST}/vhosts ]; then
       mkdir -p ${NGINXHOST}/hosts
fi

#create conf
/bin/cp -f config/vhostnginx.conf ${NGINXHOST}/vhosts/$1.conf
/bin/cp -i "s/www.test.com/$1/g" ${NGINXHOST}/vhosts/$1.conf
/bin/sed -i '$d' ${NGINXCONF}
/bin/echo "      #$1 Add by jindm script ${DATE}" >> ${NGINXCONF}
/bin/echo "      include vhosts/$1.conf;" >> ${NGINXCONF}
/bin/echo "}" >> ${NGINXCONF}

#create log rate
/bin/sed -i '$d' /root/logcron.sh
/bin/echo "/bin/mv \${log_dir}/$1-access.log \${log_dir}/\${date_dir}/$1-access.log" >> /root/logcron.sh
/bin/echo "/bin/mv \${log_dir}/$1-error.log \${log_dir}/\${date_dir}/$1-error.log" >> /root/logcron.sh
/bin/echo "kill -USR1 \`cat /var/run/nginx.pid\`" >> /root/logcron.sh

#mkdir 
if [ ! -d /data/httplogs ]; then
	/bin/mkdir -p /data/httplogs
fi

if [ ! -d /data/wwwroot/$1/webroot ]; then
	/bin/mkdir -p /data/wwwroot/$1/webroot
	chown -R nobody:nobody /data/wwwroot/$1/webroot
fi

if [ ! -d /data/upload/$1/upload ]; then
	/bin/mkdir -p /data/upload/$1/upload/upload
	/bin/mkdir -p /data/upload/$1/upload/cache
	chown -R nobody:nobody /data/upload/$1/upload
	chmod -R 777 /data/upload/$1/upload*
fi

if [ ! -d /data/weblogs/$1/weblogs ]; then 
	/bin/mkdir -p /data/weblogs/$1/weblogs
	chown -R nobody:nobody /data/weblogs/$1/weblogs
	chmod -R 777 /data/weblogs/$1/weblogs
fi

#logs
/bin/echo "##########################################" >> logs/vhost.log
/bin/echo "Date:${DATE}}" >> logs/vhost.log
/bin/echo "Domain: $1" >> logs/vhost.log

#reload configure
/etc/init.d/nginx reload
/bin/echo "Vhost $1 create success!"








