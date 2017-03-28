#!/bin/bash

#set -x

get_config() {
    key=$1
    grep "^$1=" ./test/yi-hack.cfg  | cut -d'=' -f2
}

pass=$(get_config ROOT_PASSWORD)
IPs="192.168.2.20 192.168.2.21 192.168.2.22 192.168.2.23 192.168.2.24"


for srv in $(echo $IPs)
do
   echo "Restarting ... $srv"
   ./reboot.expect $srv 23 root $pass

done
