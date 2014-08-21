#!/bin/sh


#tomcat server, we can't monitor remote tomcat instances...
TOMCAT_SERVER=`hostname`

#Script to control tomcat (start/stop/restart)
TOMCAT_SCRIPT=/etc/init.d/tomcat

#Port where Tomcat is running (management port)
TOMCAT_PORT=8080

TOMCAT_SHUTDOWN_PORT=8005

#Credentials for a user with permissions to stop/start webapps
TOMCAT_USER=user
TOMCAT_PASS=pass
#The Line below is used to extract the Webapp name from the script
#the webapps name is assumed to the last sequence of alphanumeric
#chars in the scriptname (for instance: tomcat_MyWebApp -> WA name=MyWebApp)

#TOMCAT_WA_NAME=`echo $0|egrep -o "[a-zA-Z0-9]*$"`

#Or you can manually set the WS name here 
TOMCAT_WA_NAME=MyWebApp

#Tomcat dir aka CATALINA_DIR
TOMCAT_DIR=/usr/local/jakarta-tomcat


start()
{

    #Check if  tomcat is running
    SHUTDOWN_PORT=`netstat -vatn|grep LISTEN|grep $TOMCAT_SHUTDOWN_PORT|wc -l`
    if [ $SHUTDOWN_PORT -eq 0 ]
    then
        #if not then start it!
        $TOMCAT_SCRIPT stop
        sleep 3
        $TOMCAT_SCRIPT start
        sleep 10
    fi

    #Manually deploy webapp (used for testing)
    #cp -ruv $TOMCAT_DIR/war/$TOMCAT_WA_NAME.war $TOMCAT_DIR/webapps
    #cp $TOMCAT_DIR/war/$TOMCAT_WA_NAME.xml $TOMCAT_DIR/conf/Catalina/localhost/


    curl  -m 10 --user $TOMCAT_USER:$TOMCAT_PASS http://$TOMCAT_SERVER:$TOMCAT_PORT/manager/start?path=/$TOMCAT_WA_NAME > /tmp/tomcatresponse
    sleep 15
    logger -s -t $0 "$TOMCAT_WA_NAME Started!"
    RETVAL=0
}

stop()
{

	if [ ! -d  $TOMCAT_DIR/war ]
	then
		mkdir  $TOMCAT_DIR/war
	fi 

    #Backup WebApp for manual deploy,used in start  (used for testing)
	#cp -ruv $TOMCAT_DIR/webapps/$TOMCAT_WA_NAME.war $TOMCAT_DIR/war/
	#cp -ruv $TOMCAT_DIR/conf/Catalina/localhost/$TOMCAT_WA_NAME.xml $TOMCAT_DIR/war/

    curl  -m 10 --user $TOMCAT_USER:$TOMCAT_PASS http://$TOMCAT_SERVER:$TOMCAT_PORT/manager/stop?path=/$TOMCAT_WA_NAME > /tmp/tomcatresponse
    
    #only undeploy if you manually deploy! (used for testing)
    #curl  -m 10 --user $TOMCAT_USER:$TOMCAT_PASS http://$TOMCAT_SERVER:$TOMCAT_PORT/manager/undeploy?path=/$TOMCAT_WA_NAME > /tmp/tomcatresponse

    #Manually undeploy webapp to ensure clean undeploy (used for testing)
	#rm -fr $TOMCAT_DIR/webapps/$TOMCAT_WA_NAME.war
	#rm -fr $TOMCAT_DIR/conf/Catalina/localhost/$TOMCAT_WA_NAME.xml
    sleep 10
    logger -s -t $0 "$TOMCAT_WA_NAME Stopped!"	
    RETVAL=0
}

status()
{
    #START MEM CHECK
    #Check If tomcat is not out of memory

    #check last line of catalina.out to see if there is an error
    ERR=`tail -n1 $TOMCAT_DIR/logs/catalina.out|grep "java.lang.OutOfMemoryError: PermGen space"|wc -l`
    if [ $ERR -gt 0 ]
    then
        logger -s -t $0 "*****Detected TOMCAT OUT OF MEM!!!****"
        logger -s -t $0 "*****         RESTARTING          ****"
                   
        $TOMCAT_SCRIPT stop &       #in the background to prevent locking
        sleep 10                    #give it some time to stop
        #no need to start tomcat here
        #since the webservice will do it when it starts up
        exit 1
    fi


    #END MEM CHECK
    curl  -m 10 --user $TOMCAT_USER:$TOMCAT_PASS http://$TOMCAT_SERVER:$TOMCAT_PORT/$TOMCAT_WA_NAME/ > /tmp/tomcatresponse

    #if response file is zero sized then the service isn't running
    # -s is true if file size is greater than 0
    if [ -s /tmp/tomcatresponse ]
    then
        echo "WebService $TOMCAT_WA_NAME is running!"
        exit 0
    else
        echo "WebService $TOMCAT_WA_NAME is stopped (or not responding)!"
        exit 1
    fi
    RETVAL=0
}




case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        sleep 2
        start

        ;;
  status)
        status
        RETVAL=$?
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart}"
        RETVAL=1
esac
exit $RETVAL

