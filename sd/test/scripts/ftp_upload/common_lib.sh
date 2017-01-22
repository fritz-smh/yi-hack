#!/bin/sh

DEFAULT_SCRIPT_DIR="/tmp/hd1/test/scripts"
DEFAULT_RECORD_DIR="/tmp/hd1/record/"
DEFAULT_CONFIG_FILE="/home/hd1/test/yi-hack.cfg"

max_d01=31
max_d02=28
max_d03=31
max_d04=30
max_d05=31
max_d06=30
max_d07=31
max_d08=31
max_d09=30
max_d10=31
max_d11=30
max_d12=31

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

get_config() 
{
    param=$1
    conf_file=${2-"$DEFAULT_CONFIG_FILE"}
    count=$(grep -e ^\s*${param}\s* ${conf_file} | wc -l)
    if [ $count -gt 1 ]; then
        log "ERROR: Found $count line for ${param}"
    fi
    
    grep -e ^\s*${param}\s* $conf_file  | cut -d"=" -f2
}

is_server_live()
{
    ping -c1 -W2 $1 > /dev/null
    return $?
}

is_pid_exist()
{
    count=$(ps | grep $1 | wc -l)
    if [ $count -gt 1 ]; then
       return 0
    fi
    return 1
}

pid_store()
{
    if [ ! -r "$2" ]; then
        log "[$(basename "$0")] PID file $2 not existed"
    fi
    echo $1 > $2
}

pid_get()
{
    if [ ! -r "$1" ]; then
        log "[$(basename "$0")] PID file $1 not existed"
    fi
    cat $1
}

pid_clear()
{
    if [ ! -r "$1" ]; then
        log "[$(basename "$0")] PID file $1 not existed"
    fi
    cat /dev/null > $1
}

log()
{
    echo $3 "$(date +'%Y-%m-%dT%H:%M:%S%z') $1" >> $2
}

unreach_get()
{
    if [ ! -r "$1" ]; then
        log "[$(basename "$0")] Unreach file $1 not existed"
    fi
    urcount=$(cat $1)
    if [ -z "$urcount" ]; then
        urcount=0
    fi
    echo $urcount
}

unreach_increase()
{
    urfile=$1
    if [ ! -r "$urfile" ]; then
        log "[$(basename "$0")] Unreach file $urfile not existed"
    fi
    urcount=$(unreach_get $urfile)
    urcount=$((urcount + 1))
    echo $urcount > $urfile
}

unreach_reset()
{
    if [ ! -r "$1" ]; then
        log "[$(basename "$0")] Unreach file $1 not existed"
    fi
    echo 0 > $1
}


is_leap_year()
{
    year=$1
    if [ $((year % 400)) -eq 0 ]; then
        return 0
    elif [ $((year % 4)) -eq 0 ] && [ $((year % 100)) -ne 0 ]; then
        return 0
    else
        return 1
    fi
}


check_offline_duration()
{
    # Check if execution time within Gateway Off duration
    gw_off_start=$(get_config GW_OFF_START)
    gw_off_end=$(get_config GW_OFF_END)
    if [ ! -z "$gw_off_start" ] && [ ! -z "$gw_off_end" ]; then
        log "[$NAME] Check gateway offline duration" ${FTP_LOG}
        gw_off_start=$(echo $gw_off_start | sed 's/://g')
        gw_off_end=$(echo $gw_off_end | sed 's/://g')
        current_time=$(date +%H%M%S)
        if [ $gw_off_start -gt $gw_off_end ]; then
            if [ $gw_off_start -lt 1200 ]; then
                gw_off_start=$((gw_off_start + 2400))
            fi
            if [ $gw_off_end -lt 1200 ]; then
                gw_off_end=$((gw_off_end + 2400))
            fi
            if [ $current_time -lt 1200 ]; then
                current_time=$((current_time + 2400))
            fi
        fi
        if [ $current_time -gt $gw_off_start ] && [ $current_time -lt $gw_off_end ]; then
            log "[$NAME] Excution at $gw_off_start < $current_time < $gw_off_end. Do nothing" ${FTP_LOG}
            return 1
        fi
    fi
    return 0
}

