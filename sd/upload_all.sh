#!/bin/bash

#set -x 

get_config() {
    key=$1
    grep "^$1=" ./test/yi-hack.cfg  | cut -d'=' -f2
}

pass=$(get_config ROOT_PASSWORD)


for srv in $(echo "192.168.2.20 192.168.2.21 192.168.2.22 192.168.2.23 192.168.2.24")
do
   echo "=================================="
   echo "Uploading test to ... $srv" 
   echo "=================================="

   for file in $(find test -type f | grep -v "\.DS_Store")
   do
       #echo -ne "Deleting  file $file  " && curl ftp://$srv -X 'DELE /home/hd1/${file}' && echo -ne "\t\t\tOK\n"
        echo -ne "Uploading file $file  " && ( curl -s -S --ftp-create-dirs -T $file ftp://${srv}/home/hd1/${file}  && echo -ne "\t\t\tOK\n" ) || echo -ne "\t\t\tERROR!!!\n"
   done
   #curl ftp://$srv -X 'DELE /home/hd1/test/web' -v
   #find test -type f -exec curl -s -S --ftp-create-dirs -T {} ftp://${srv}/home/hd1/{} \; 
 
   # Restart
   echo "" 
   echo "Restarting ... $srv"
   ./reboot.expect $srv 23 root $pass  >/dev/null
done
