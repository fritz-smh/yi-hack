#! /bin/sh

FIRMWARE_LETTER=$(cat /home/version | grep "version=" | head -1 | cut -d"=" -f2 | sed "s/^[0-9]\.[0-9]\.[0-9]\.[0-9]\([A-Z]\).*/\1/")

case ${FIRMWARE_LETTER} in
    # 1.8.6.1
    A)  # NOT TESTTED YET
        RTSP_VERSION='M'
        HTTP_VERSION='M'
        ;;

    # 1.8.5.1
    M)  # Tested :)
        RTSP_VERSION='M'
        HTTP_VERSION='M'
        ;;

    L)  # Tested :)
        RTSP_VERSION='M'
        HTTP_VERSION='M'
        ;;

    K)  # NOT TESTED YET
        RTSP_VERSION='K'
        HTTP_VERSION='M'
        ;;

    B|E|F|H|I|J)  # NOT TESTED YET
        RTSP_VERSION='I'
        HTTP_VERSION='J'
        ;;

    *)
        RTSP_VERSION='M'
        HTTP_VERSION='M'
        log "WARNING : I don't know which RTSP binary version is compliant with your firmware! I will try to use the M..."
        ;;
esac


get_config() {
    key=$1
    grep $1 /home/hd1/test/yi-hack.cfg  | cut -d"=" -f2
}

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
       return 0    # $substring is in $string
    else
       return 1    # $substring is not in $string
    fi
}
                                        
ftp() {
    RESULT="$(pgrep tcpsvd)"
    if [ "${TOGGLE}" = "YES" ]; then
      if [ "${RESULT:-null}" = null ]; then
        echo "Starting FTP server"
        tcpsvd -vE 0.0.0.0 21 ftpd -w / &
        STATUS="Starting"
        BUTTON="Disable"
      else
        echo "Closing FTP server"
        pkill "tcpsvd"
        STATUS="Stopping"
        BUTTON="Enable"
      fi
    else
      if [ "${RESULT:-null}" = null ]; then 
        STATUS="Stopped"
        BUTTON="Enable"
      else
        STATUS="Running"
        BUTTON="Disable"
      fi
    fi
}

rtsp() {
    RESULT="$(pgrep rtspsvr)"
    if [ "${TOGGLE}" = "YES" ]; then 
      if [ "${RESULT:-null}" = null ]; then
        echo "Starting RTSP server"
        ../.././rtspsvr${RTSP_VERSION} &
        STATUS="Starting"
        BUTTON="Disable"
      else
         echo "Closing RTSP server"
         pkill "rtspsvr"
         STATUS="Stopping" 
         BUTTON="Enable"
      fi
    else                                               
      if [ "${RESULT:-null}" = null ]; then            
        STATUS="Stopped"                               
        BUTTON="Enable"                                
      else                                             
        STATUS="Running"                               
        BUTTON="Disable"                         
      fi                                         
    fi       
                                          

}

record() {
    RESULT="$(pgrep mp4record)"
    if [ "${TOGGLE}" = "YES" ]; then    
      if [ "${RESULT:-null}" = null ]; then                                                                                 
         echo "Starting Motion Recording"                                                                                         
         /home/./record_event & 
         /home/./mp4record 60 &                                                                                    
         STATUS="Starting"
         BUTTON="Disable"
      else                                                                                                                  
         echo "Stopping Motion Recording"                                                                                         
         pkill "record_event"
         pkill "mp4record"   
         STATUS="Stopping"                                                                                                 
         BUTTON="Enable"
      fi     
    else
      if [ "${RESULT:-null}" = null ]; then
        STATUS="Stopped"
        BUTTON="Enable" 
      else                                                                                                                
        STATUS="Running"
        BUTTON="Disable"
      fi
    fi
}

STATUS=null
BUTTON=null

# we need to create a redirect page that takes our iframe back to the status page

IP=$(get_config IP)
echo -e "HTTP/1.1 200 OK\r\n" > redirect
echo "<html><head><meta http-equiv='refresh' content='1;url=http://${IP}/interactive/status.html'></meta></head><body>Refreshing...</body></html>" >> redirect


while :
do
# we use netcat to dynamically interact with the camera, we need to regenerate the status page on change
    OUTPUT="$(nc -l -p 8080 < redirect)"

    echo "<html><head><meta http-equiv='refresh' content='10;url=http://${IP}:8080'></meta></head><body>" > status.html                                                                                                                                           
    echo "<table><tr><td>Service</td><td>Status</td><td>Action</td></tr>" >> status.html     
    
    TOGGLE=NO
    contains "$OUTPUT" "FTP" && TOGGLE=YES

    ftp

    echo "<tr><td>FTP</td><td>${STATUS}</td><td><a href='http://${IP}:8080/?FTP'><button type="button">${BUTTON}</button></a></td></tr>" >> status.html  

    TOGGLE=NO                                                                                                                                                                 
    contains "$OUTPUT" "RTSP" && TOGGLE=YES                                                                                                                                    

    rtsp

    echo "<tr><td>RTSP</td><td>${STATUS}</td><td><a href='http://${IP}:8080/?RTSP'><button type="button">${BUTTON}</button></a></td></tr>" >> status.html    
 
    TOGGLE=NO                                                                                                                                                                 
    contains "$OUTPUT" "RECORD" && TOGGLE=YES  

    record

    echo "<tr><td>Recording</td><td>${STATUS}</td><td><a href='http://${IP}:8080/?RECORD'><button type="button">${BUTTON}</button></a><td></td></tr></td></tr>" >> status.html   


    echo "</body></html>" >> status.html 
done
