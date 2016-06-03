#!/bin/sh
#Delete files and folders more than 15 days
#To run this script you can make an entry the cameras crontab
#You might need to create manually the folder structure /var/spool/cron/crontabs 
#or when you try to add a crontab with "crontab -e" it might give you an error
#search on internet about the use of crontab

dir="/home/hd1/record/"
days=+15
dt=`date +%y%m%d`

du -sh ${dir} > ${dir}Delete_$dt.log
find ${dir} -mtime $days -exec rm -Rf {} \;
du -sh ${dir} >> ${dir}Delete_$dt.log
