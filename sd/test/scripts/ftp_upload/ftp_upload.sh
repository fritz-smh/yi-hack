#!/bin/sh

source "/tmp/hd1/test/scripts/ftp_upload/common_lib.sh"

NAME=`basename "$0"`
FTP_MEM_FILE="/tmp/hd1/test/scripts/ftp_upload/ftp_upload.mem"
FTP_LOG="/tmp/hd1/test/scripts/ftp_upload/log.txt"
PID_FILE="/tmp/hd1/test/scripts/ftp_upload/ftp.pid"


mem_store()
{
    if [ ! -r "$3" ]; then
        log "[$(basename "$0")] Mem file $3 not existed" ${FTP_LOG}
    fi
    last_folder=$1
    last_file=$2
    echo "${last_folder}/${last_file}" > $3
}

mem_get()
{
    if [ ! -r "$1" ]; then
        log "[$(basename "$0")] Mem file $1 not existed" ${FTP_LOG}
    fi
    mfile=$1
    last_folder=$(cat ${mfile} | cut -d'/' -f1)
    last_file=$(cat ${mfile} | cut -d'/' -f2)
    if [ -z "${last_folder}" ] || [ -z "${last_file}" ]; then
        log "[$(basename "$0")] Cannot find last folder and file in $mfile" ${FTP_LOG}
        log "[$(basename "$0")] The file should content as: 2016Y08M01D13H/23M00S.mp4" ${FTP_LOG}
        exit 1
    fi
}

ftp_mkd()
{
    (sleep 1;
     echo "USER $(get_config FTP_USER)";
     sleep 1;
     echo "PASS $(get_config FTP_PASS)";
     sleep 1;
     echo "MKD $(get_config FTP_DIR)/$1";
     sleep 1;
     echo "QUIT";
     sleep 1 ) | telnet $(get_config FTP_HOST) $(get_config FTP_PORT) >> $FTP_LOG 2>&1
}

ftp_upload()
{
    from_f=$1
    to_f=$2
    ftpput -u $(get_config FTP_USER) -p $(get_config FTP_PASS) -P $(get_config FTP_PORT) \
              $(get_config FTP_HOST) $(get_config FTP_DIR)/${to_f} ${from_f} >> $FTP_LOG 2>&1
    return $?
}


main()
{
    last_folder=""
    last_file=""

    # Here we goooooo!
    is_server_live $(get_config FTP_HOST)
    if [ $? -ne 0 ]; then
        log "[$NAME] $(get_config FTP_HOST) is unreachable!!!" ${FTP_LOG}
        pid_clear $PID_FILE
        exit 1
    fi
    log "[$NAME] $(get_config FTP_HOST) is reachable" ${FTP_LOG}

    mem_get $FTP_MEM_FILE
    log "[$NAME] last folder: $last_folder last file: $last_file" ${FTP_LOG}

    last_y=$(echo $last_folder | cut -d'Y' -f1)
    last_m=$(echo $last_folder | cut -d'M' -f1 | cut -d'Y' -f2)
    last_d=$(echo $last_folder | cut -d'D' -f1 | cut -d'M' -f2)
    last_h=$(echo $last_folder | cut -d'H' -f1 | cut -d'D' -f2)
    last_i=$(echo $last_file | cut -d'M' -f1)
    last_s=$(echo $last_file | cut -d'S' -f1 | cut -d'M' -f2)

    now_h=$(date +"%H")
    now_m=$(date +"%m")
    now_d=$(date +"%d")
    now_y=$(date +"%Y")

    cont_last=1
    is_leap_year last_y
    if [ $? -eq 0 ]; then
        max_d02=29
    fi

    while [ 1 -eq 1 ]; do
        if [ -d "${DEFAULT_RECORD_DIR}${last_folder}" ]; then
            cd "${DEFAULT_RECORD_DIR}${last_folder}"
            list_file=$(ls)
            if [ -n "$list_file" ]; then
                log "[$NAME] Create ${last_folder}" ${FTP_LOG}
                # Make dir of FTP again to ensure it exists
                ftp_mkd ${last_folder}
                if [ $cont_last -eq 1 ]; then
                    # Use current last_i and last_s
                    cont_last=0
                else
                    last_i="00"
                    last_s="00"
                fi

            fi
            for file in $list_file; do
                #log $file
                check_offline_duration
                if [ $(echo $file | grep tmp | wc -l) -gt 0 ]; then
                    log "[$NAME] Skip tmp file" ${FTP_LOG}
                    continue
                fi
                this_i=$(echo $file | cut -d'M' -f1)
                this_s=$(echo $file | cut -d'S' -f1 | cut -d'M' -f2)
                if [ "${this_i}${this_s}" -gt "${last_i}${last_s}" ]; then
                    log "[$NAME] Uploading ${last_folder}/${file}" ${FTP_LOG}
                    ftp_upload ${DEFAULT_RECORD_DIR}/${last_folder}/${file} ${last_folder}/${file}
                    upload_res=$?
                    mem_store ${last_folder} ${file} ${FTP_MEM_FILE}
                    if [ $upload_res -ne 0 ]; then
                        log "[$NAME] FAILED" ${FTP_LOG}
                        exit 1
                    fi
                    last_file=$file
                fi
            done
        fi
        # If last_h between 01 to 09 then remove leading 0 for calculation
        if [ $(expr match "$last_h" '0*') -gt 0 ]; then
            last_h=${last_h:1}
        fi
        last_h=$(printf %02d $((last_h + 1)))
        if [ $last_h -gt 23 ]; then
            last_h=00
            if [ $(expr match "$last_d" '0*') -gt 0 ]; then
                last_d=${last_d:1}
            fi
            last_d=$(printf %02d $((last_d + 1)))
        fi
        eval max_d='$max_d'$last_m
        if [ $last_d -gt $max_d ]; then
            last_d=01
            if [ $(expr match "$last_m" '0*') -gt 0 ]; then
                last_m=${last_m:1}
            fi
            last_m=$(printf %02d $((last_m + 1)))
        fi
        if [ $last_m -gt 12 ]; then
            last_m=01
            last_y=$((last_y + 1))
            is_leap_year $last_y
            if [ $? -eq 0 ]; then
                max_d02=29
            else
                max_d02=28
            fi
        fi
        if [ "${last_y}${last_m}${last_d}${last_h}" -gt "${now_y}${now_m}${now_d}${now_h}" ]; then
            # Nothing more to do, break the loop
            break
        fi
        last_folder="${last_y}Y${last_m}M${last_d}D${last_h}H"
        log "[$NAME] Next folder: $last_folder" ${FTP_LOG}
    done
    pid_clear $PID_FILE
}

#
# Start the main script
#

# Check offline duration at beginning
check_offline_duration

is_server_live $(get_config FTP_HOST)
if [ $? -ne 0 ]; then
    log "[$NAME] Unreach FTP server $(get_config FTP_HOST)" ${FTP_LOG}
    exit 0
fi

# If pass all above check, start the FTP upload
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

