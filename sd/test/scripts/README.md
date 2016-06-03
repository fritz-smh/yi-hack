copy_to_ftp.sh
==============

This script can help you to copy some files to a ftp server (on a NAS for example).

Configure the script : 

* ftp_dir value, just put there the path where you want to copy videos.
* ftp_host value, indicate the IP of the NAS
* ftp_port value, indicate the port of the FTP server (like 21)
* ftp_login value, indicate the user or login to connect to the ftp folder in the nas server.
* ftp_pass value, indicate the password of the user before for permision to save in the folder.

Add the script to the crontab of your yi camera

Source of the script : 

* https://github.com/fritz-smh/yi-hack/pull/24
* http://4pda.ru/forum/index.php?showtopic=638230&st=2780#entry44208114

delete_old_videos.sh
====================

This script searchs and deletes videos older than 15 days. (You can change this value if you configure the script)
You have to run it manually or add it to crontab for running it autmatically.
The camera might throw an error if you try to run "crontab -e":
```sh
          crontab -e
          crontab: chdir(/var/spool/cron/crontabs): No such file or directory
```
If that's the case just create that dir manually and you can edit the crontab with "crontab -e"
Example configuration of crontab (runs the script the 15th of each month):
```sh
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
0 0 15 * * /home/hd1/test/scripts/delete_old_videos.sh
```
