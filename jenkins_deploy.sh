#!/bin/bash
#-----------------------
#  Deploy war to tomcat and restart
#-----------------------
#  By jindm
#  dingmingk@gmail.com
#  2015-12-02

#defined
TOMCAT_HOME="/THE/PATH/YOUR/TOMCAT"
TOMCAT_PORT=80
PROJECT="$1"

#param validate
if [ $# -lt 1 ]; then
  echo "you must use like this : ./publish.sh <projectname> [tomcat port] [tomcat home dir]"
  exit
fi
if [ "$2" != "" ]; then
  TOMCAT_PORT=$2
fi
if [ "$3" != "" ]; then
  TOMCAT_HOME=$TOMCAT_HOME"$3"
fi

#check tomcat process
tomcat_pid=`lsof -n -P -t -i :$TOMCAT_PORT`
echo "current :" $tomcat_pid

#shutdown tomcat
"$TOMCAT_HOME"/bin/shutdown.sh
echo "shutting down tomcat..."
sleep 10
kill -9 $tomcat_pid
echo "tomcat shut down!"

#publish project
echo "scan no tomcat pid, $PROJECT publishing"
rm -rf "$TOMCAT_HOME"/webapps/$PROJECT*
cp /THE/PATH/YOUR/JENKINS/PAC/$PROJECT.war "$TOMCAT_HOME"/webapps/$PROJECT.war

#bak project
BAK_DIR=/xxx/backup/tomcat/`date +%Y%m%d`
mkdir -p "$BAK_DIR"
mv /xxx/backup/tomcat/web/$PROJECT.war "$BAK_DIR"/"$PROJECT"_`date +%H%M%S`.war

#start tomcat
"$TOMCAT_HOME"/bin/startup.sh
echo "tomcat is starting..."
sleep 5
new_tomcat_pid=`lsof -n -P -t -i :$TOMCAT_PORT`
if [ -n "new_tomcat_pid" ]
then
  echo "tomcat started success!"
else
  echo "tomcat started failed!"
fi

