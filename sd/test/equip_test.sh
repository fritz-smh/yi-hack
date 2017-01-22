#!/bin/sh
######################################################
# Xiaomi Yi hack
######################################################
#
# Features
# ========
#
# * no more cloud !
# * network configuration done in this file. No more need to use a Xiaomi app on a smartphone!
# * http server   : port 80
# * telnet server : port 23
# * ftp server    : port 21
# * rtsp server   : port 554
#      rtsp://192.168.1.121:554/ch0_0.h264     : replace with your ip
#      rtsp://192.168.1.121:554/ch0_1.h264     : replace with your ip
#
# How it works
# ============
#
# See http://github.com/fritz-smh/yi-hack/
#
# TODO
# ====
#
# * strem audio from network to camera  ==> svoxpico ?
# * create a watchdog script

led() {
    # example usage :
    #    led -boff -yon
    # options :
    #    -bfast
    #    -bon
    #    -boff
    #    -yfast
    #    -yon
    #    -yoff

    # first, kill current led_ctl process
    kill $(ps | grep led_ctl | grep -v grep | awk '{print $1}')
    # then process
    /home/led_ctl $@ &

}

LOG_DIR=/home/hd1/test/
LOG_FILE=${LOG_DIR}/log.txt

log_init() {
    # clean the previous log file and add a starting line
    echo "[$(date +'%Y%m%d-%H%M%S')] Starting to log..." > /home/hd1/test/log.txt
}

log() {
    # do_logging
    echo "$@" >> /home/hd1/test/log.txt
    sync
}

get_config() {
    key=$1
    grep $1 /home/hd1/test/yi-hack.cfg  | cut -d"=" -f2
}



### first we assume that this script is started from /home/init.sh and will replace it from the below lines (which are not commented in init.sh :

#if [ -f "/home/hd1/test/equip_test.sh" ]; then
#   /home/hd1/test/equip_test.sh
#   exit
#fi

######################################################
# start of our custom script !!!!!!
######################################################

### Launch Telnet server
log "Start telnet server..."
telnetd &


### configure timezone

echo "$(get_config TIMEZONE)" > /etc/TZ

### get time is done after wifi configuration!



### first, let's do as the orignal script does....

export LD_LIBRARY_PATH=/home/libusr:$LD_LIBRARY_PATH
mv /home/default.script /usr/share/udhcpc -f

rm /etc/resolv.conf
ln -s /tmp/resolv.conf /etc/resolv.conf

### TODO : comment this?
/home/log_server &


# some things from the original script...
cd /home
mount |grep "/tmp"
/home/productioninfoget.sh
insmod cpld_periph.ko

cd /home/3518
./load3518_audio -i

# added :
himm 0x20050074 0x06802424

### Let ppl hear that we start
/home/rmm "/home/hd1/test/voice/welcome.g726" 1
/home/rmm "/home/hd1/test/voice/wait.g726" 1

### start blinking blue led for configuration in progress
#/home/led_ctl -boff -yon &
led -yoff -bfast


insmod /home/mtprealloc7601Usta.ko
insmod /home/mt7601Usta.ko

ifconfig ra0 up

### INFORMATION : the 'clic' 'clic' is done after this line


sysctl -w fs.mqueue.msg_max=256
mkdir /dev/mqueue
mount -t mqueue none /dev/mqueue

#insmod /home/cpld_wdg.ko
#insmod /home/cpld_periph.ko
#insmod /home/iap_auth.ko
/home/gethwplatform

#now begin app
sysctl -w net.ipv4.tcp_mem='3072    4096    2000000'
sysctl -w net.core.wmem_max='2000000'
sysctl -w net.ipv4.tcp_keepalive_time=300 net.ipv4.tcp_keepalive_intvl=6 net.ipv4.tcp_keepalive_probes=3

insmod /home/as-iosched.ko
echo "anticipatory" > /sys/block/mmcblk0/queue/scheduler
echo "1024" > /sys/block/mmcblk0/queue/read_ahead_kb

### The followinf unmount+mount of hd1 allows a rw mount (on startup, it is ro mounted)

umount /home/hd1
umount /home/hd2
mount -t vfat /dev/hd1 /home/hd1
mkdir /home/hd1/record
mkdir /home/hd1/record_sub
mount -t vfat /dev/hd2 /home/hd2
mkdir /home/hd2/record_sub
rm /home/web/sd/* -rf


cd /home/3518
./load3518_left -i

### Detect the hardware version
# result will be written in /tmp/hwplatform
/home/detect_ver


himm 0x20050074 0x06802424

### what is this ?
cd /home
./peripheral &
./dispatch &
./exnet &
#./mysystem &

count=5

while [ $count -gt 0 ]
do
if [ -f "/tmp/init_finish" ]; then
    break
else
    count=`expr $count - 1`
    echo "wait init" $count
    sleep 1
fi
done


### INFORMATION : the 'clic' 'clic' is done before this line

### we copy our wpa_supplicant file in /home
cp /home/hd1/test/wpa_supplicant.conf /home/wpa_supplicant.conf


### Init logs
log_init
# Put version informations in logs and a file which will be included in the http server default page
TMP_VERSION_FILE=/tmp/version_information
rm -f ${TMP_VERSION_FILE}
echo "Hardware version informations : " >> ${TMP_VERSION_FILE}
cat /tmp/hwplatform | sed "s/^/    /" >> ${TMP_VERSION_FILE}

echo "Software version informations : " >> ${TMP_VERSION_FILE}
cat /home/version | sed "s/^/    /" >> ${TMP_VERSION_FILE}

FIRMWARE_LETTER=$(cat /home/version | grep "version=" | head -1 | cut -d"=" -f2 | sed "s/^[0-9]\.[0-9]\.[0-9]\.[0-9]\([A-Z]\).*/\1/")
echo "Firmware letter is : '${FIRMWARE_LETTER}'" >> ${TMP_VERSION_FILE}

cat ${TMP_VERSION_FILE} >> ${LOG_FILE}

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
log "The RTSP server binary version which will be used is the '${RTSP_VERSION}'"
log "The HTTP server binary version which will be used is the '${HTTP_VERSION}'"



log "Check for some files size..."
ls -l /home/hd1/test/rtspsvr* /home/hd1/test/http/server* | sed "s/^/    /" >> ${LOG_FILE}

log "The blue led is currently blinking"
log "Debug mode = $(get_config DEBUG)"

# first, configure wifi

### Let ppl hear that we start connect wifi
/home/rmm "/home/hd1/test/voice/connectting.g726" 1

log "Check for wifi configuration file...*"
log $(find /home -name "wpa_supplicant.conf")

log "Start wifi configuration..."
res=$(/home/wpa_supplicant -B -i ra0 -c /home/wpa_supplicant.conf )
log "Status for wifi configuration=$?  (0 is ok)"
log "Wifi configuration answer: $res"

log "Do network configuration 1/2 (ip and gateway)"
#ifconfig ra0 192.168.1.121 netmask 255.255.255.0
#route add default gw 192.168.1.254
ifconfig ra0 $(get_config IP) netmask $(get_config NETMASK)
route add default gw $(get_config GATEWAY)
log "Done"

log "Configuration is :"
ifconfig | sed "s/^/    /" >> ${LOG_FILE}

### configure DNS (google one)
log "Do network configuration 2/2 (DNS)"
echo "nameserver $(get_config NAMESERVER)" > /etc/resolv.conf
log "Done"

### configure time on a NTP server
log "Get time from a NTP server..."
NTP_SERVER=$(get_config NTP_SERVER)
log "But first, test the NTP server '${NTP_SERVER}':"
ping -c1 ${NTP_SERVER} >> ${LOG_FILE}
log "Previous datetime is $(date)"
ntpd -q -p ${NTP_SERVER}
log "Done"
log "New datetime is $(date)"


### Check if reach gateway and notify
ping -c1 -W2 $(get_config GATEWAY) > /dev/null
if [ 0 -eq $? ]; then
    /home/rmm "/home/hd1/test/voice/wifi_connected.g726" 1
fi

### set the root password
root_pwd=$(get_config ROOT_PASSWORD)
[ $? -eq 0 ] &&  echo "root:$root_pwd" | chpasswd

### start blue led for configuration finished
log "Start blue led on"
led -yoff -bon


### Rename the timeout sound file to avoid being spammed with chinese audio stuff...
[ -f /home/timeout.g726 ] && mv /home/timeout.g726 /home/timeout.g726.OFF

sync

### Launch FTP server
log "Start ftp server..."
if [[ $(get_config DEBUG) == "yes" ]] ; then
    tcpsvd -vE 0.0.0.0 21 ftpd -w / > /${LOG_DIR}/log_ftp.txt 2>&1 &
else
    tcpsvd -vE 0.0.0.0 21 ftpd -w / &
fi
sleep 1
log "Check for ftp process : "
ps | grep tcpsvd | grep -v grep >> ${LOG_FILE}


### Launch web server

# first, prepare the index.html page
cd /home/hd1/test/http/
cat index.html.tpl_header ${TMP_VERSION_FILE} index.html.tpl_footer > index.html

# then, bind the record folder
mkdir /home/hd1/test/http/record/
mount -o bind /home/hd1/record/ /home/hd1/test/http/record/

# prepare the GET /motion url
touch /home/hd1/test/http/motion

# start the server
log "Start http server : server${HTTP_VERSION}..."
if [[ $(get_config DEBUG) == "yes" ]] ; then
    ./server${HTTP_VERSION} 80  > /${LOG_DIR}/log_http.txt 2>&1 &
else
    ./server${HTTP_VERSION} 80 &
fi
sleep 1
log "Check for http server process : "
ps | grep server | grep -v grep | grep -v log_server >> ${LOG_FILE}

sync



### Launch record event
cd /home
./record_event &
./mp4record 60 &


### Some configuration

himm 0x20050068 0x327c2c
#himm 0x20050068 0x0032562c
himm 0x20050074 0x06802424
himm 0x20050078 0x18ffc001
#himm 0x20050078 0x1effc001
himm 0x20110168 0x10601
himm 0x20110188 0x10601
himm 0x20110184 0x03ff2
himm 0x20030034 0x43
himm 0x200300d0 0x1
himm 0x2003007c 0x1
himm 0x20030040 0x102
himm 0x20030040 0x202
himm 0x20030040 0x302
himm 0x20030048 0x102
himm 0x20030048 0x202
himm 0x20030048 0x302


rm /home/hd1/FSCK*

# Check and create crontabs folder
crontab_folder="/var/spool/cron/crontabs"
if [ ! -r "$crontab_folder" ]; then
    mkdir -p "$crontab_folder"
fi
if [ ! -r "/var/spool/cron/crontabs/root" ]; then
    cp /home/hd1/test/crontabs_root /var/spool/cron/crontabs/root
fi
# Start crond daemon
/usr/sbin/crond -b

### Final led color

### Check if reach gateway and notify
ping -c1 -W2 $(get_config GATEWAY) > /dev/null
if [ 0 -eq $? ]; then
    led $(get_config LED_WHEN_READY)
    /home/rmm "/home/hd1/test/voice/success.g726" 1
else
    led -boff -yfast
fi

### Rmm stuff
# without this, most things does not work (http server, rtsp)
# It starts to use the cloud (which is no more launched) so you will find timeout in the logs
# This must be launched after all "/home/rmm" command calls
cd /home
./rmm &


### Rtsp server
cd /home/hd1/test/
log "Start rtsp server : rtspsvr${RTSP_VERSION}..."
if [[ $(get_config DEBUG) == "yes" ]] ; then
    ./rtspsvr${RTSP_VERSION} > /${LOG_DIR}/log_rtsp.txt 2>&1 &
else
    ./rtspsvr${RTSP_VERSION} &
fi
sleep 1
log "Check for rtsp process : "
ps | grep rtspsvr | grep -v grep >> ${LOG_FILE}

sleep 5


### List the processes after startup
log "Processes after startup :"
ps >> ${LOG_FILE}

### List storage status
log "Storage status :"
df -h >> ${LOG_FILE}

### to make sure log are written...

sync




