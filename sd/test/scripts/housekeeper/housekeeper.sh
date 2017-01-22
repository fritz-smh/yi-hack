#!/bin/sh

source "/tmp/hd1/test/scripts/ftp_upload/common_lib.sh"

NAME=`basename "$0"`
HK_LOG="/tmp/hd1/test/scripts/housekeeper/log.txt"
PID_FILE="/tmp/hd1/test/scripts/housekeeper/housekeeper.pid"
UNREACH_FILE="/tmp/hd1/test/scripts/housekeeper/unreach_count.mem"
LAST_CLEANDAY_FILE="/tmp/hd1/test/scripts/housekeeper/last_record_cleanup.mem"

check_gw_to_alert()
{
    retry_time=$(get_config RETRY_TO_ALERT)
    ur_count=$(unreach_get $UNREACH_FILE)
    if [ $ur_count -eq $retry_time ]; then
        log "[$NAME] Reach retry $retry_time time reboot $retry_time. Reset and reboot." $HK_LOG
        unreach_reset $UNREACH_FILE
        led -boff -yfast
        return 1
    fi

    is_server_live $(get_config GATEWAY)
    if [ $? -ne 0 ]; then
        log "[$NAME] Unreach gateway, increase unreach count" $HK_LOG
        unreach_increase $UNREACH_FILE
        return 1
    fi

    # Pass unreach gateway check, so reset it
    log "[$NAME] Check unreach pass. Reset unreach count" $HK_LOG
    unreach_reset $UNREACH_FILE
    led $(get_config LED_WHEN_READY)
    return 0
}

cleanup_record()
{
    last_day=$(cat $LAST_CLEANDAY_FILE)
    if [ ! -z "$last_day" ]; then
        today=$(date +'%Y%m%d')
        if [ $today -eq $last_day ]; then
            log "[$NAME] Today cleanup check done" $HK_LOG
            return 0
        fi
    fi
    echo $today > $LAST_CLEANDAY_FILE
	
    number_keep_day=$(get_config RECORD_KEEP_DAYS)
    keep_date=$(date -D %s -d $(( $(date +%s) - ((86400 * $number_keep_day)) )) \
               +'%Y%m%d')
    log "[$NAME] Keep record until $keep_date" $HK_LOG
    for item in $(ls -l /tmp/hd1/record | awk '{print $9}'); do
        log "[$NAME] Work on $item" $HK_LOG
        if [ $(echo $item | egrep '.*Y.*M.*D.*H.*' | wc -l) -gt 0 ]; then
            y=$(echo $item | cut -d'Y' -f1)
            m=$(echo $item | cut -d'M' -f1 | cut -d'Y' -f2)
            d=$(echo $item | cut -d'D' -f1 | cut -d'M' -f2)
            if [ "${y}${m}${d}" -lt "${keep_date}" ]; then
                log "[$NAME] Delete folder $item" $HK_LOG
                rm -Rf $item
            else
                log "[$NAME] Stop at $item" $HK_LOG
                break
            fi
        fi
    done
}

main()
{
    check_offline_duration
    if [ $? -eq 0 ]; then        
        log "[$NAME] Check gw and alert." $HK_LOG
        check_gw_to_alert
    fi
    log "[$NAME] Cleanup records" $HK_LOG
    cleanup_record
    pid_clear $PID_FILE
}

#
# Start the main script
#

last_pid=$(pid_get $PID_FILE)

if [ -n "$last_pid" ]; then
    is_pid_exist "$last_pid.*ftp_upload"
    if [ $? -eq 0 ]; then
        exit 0
    else
        log "[$NAME] $last_pid is not existed. Start new" ${FTP_LOG}
        pid_clear $PID_FILE
    fi
fi

main &

pid_store $! $PID_FILE

