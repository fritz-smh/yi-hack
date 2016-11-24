===============
Yi-hack project
===============

Personnal note - 4 october 2016
===============================

Hi, I am Fritz, the one who created this project. Since summer 2016, I have a lot of other topics to work on (especially the Domogik home automation project) and I have nearly to time for this project.

I would like to say THANK YOU to the people who are currently helping the others in the issues opened and who have submitted some pull requests! Your help is really welcome and I am very happy that this project  is interesting to many people !!!

Thanks again to all of you, users and contributors !

If one of the regular contributor wish to got some administrator permissions to this repository, please, just create an issue and I will be happy to give you the access.

-- Fritz

Purpose
=======

This project is a collection of scripts and binaries file to hack your Xiaomi Yi Ants camera.

![Alt text](yi.jpg?raw=true "Yi camera")

This camera has the default following features :
* wifi
* night vision
* motion detection : a video file is generated if a motion have been detected in the last 60 seconds.
* send video data over the network on Chinese servers in the cloud to allow people to view camera data from their smartphone wherever they are.
* setup thanks to a smartphone application.
* local video storage on a SD card
* no RTSP server in the last firmwares

This hack includes :
* ntpclient (set date and time over internet)
* Base firmware is : M release.
* no more cloud feature (nothing goes out of your local network)
* no more need to use a smartphone application
* RTSP server activated
* Telnet server activated
* HTTP server activated
* FTP server activated
* No more (chinese) voices on startup

Warning about some models that are usable only in China
=======================================================

If you have some issues to use your camera, even without this firmware, please read this webpage : https://diy.2pmc.net/solved-xiaomi-xiao-yi-ant-home-camera-can-used-china/ (more information about users issues here : https://github.com/fritz-smh/yi-hack/issues/8 )

Installation on the Yi camera
=============================

The memory card must stay in the camera ! If you remove it, the camera will start without using the hack.

Prepare the memory card
-----------------------

Clone this repository on a computer :

    git clone http://github.com/fritz-smh/yi-hack.git
    
Then, format a micro SD card in fat32 (vfat) format and copy the content of the **yi-hack/sd/** folder at the root of your memory card.

The memory card will so contain :

* home : the official firmware file compliant with this hack
* test : the folder which contains the hack scripts and binaries
* record : this folder will only be created when some video records will be added on the memory card by the camera
* record_sub : this folder will only be created when some video records will be added on the memory card by the camera

Configure the Yi camera on the memory card
------------------------------------------

You will need to set a static IP adresse to the camera. To check for the available IPs on your network, you can use the **Fing** application to scan the network on your Android smartphone.

To configure the wifi network to use, edit the file **test/wpa_supplicant.conf**.

To configure your IP address, open the file **test/yi-hack.cfg** and set the values.

Start the camera
----------------

* If plugged, unplug the Yi camera
* Insert the memory card in the Yi camera
* Plug the Yi camera

The camera will start. The led will indicate the current status :
* yellow : camera startup
* blue blinking : network configuration in progress (connec to wifi, set up the IP address)
* blue : network configuration is OK. Camera is ready to use.

You can test is your camera is up and running this hack with your browser on url **http://ip/**. You should see this page :

![Alt text](http_server.png?raw=true "Yi camera HTTP server")

Warning : changes done on the original camera filesystem
--------------------------------------------------------

One change is needed on the camera filesystem which will not be reverted by removing the memory card : the file **/home/timeout.g726** is renamed to **/home/timeout.g726.OFF**.

This is done because a process (rmm) tries to connect to the cloud process without success (as it is not started) and raise the play of a chinese voice timeout file. If this file would not be renamed, you would be bothered with this message.


How can I know which is the version of a firmware 'home' file ?
===============================================================

Just do : **strings home  | grep version**. Example :

    $ strings home  | grep version
    version=1.8.5.1M_201512011815


Use the camera
==============

Domogik
-------

You can easily use the Yi camera with the Domogik (http://www.domogik.org) home automation solution. You just need to install the **domogik-plugin-yi** package.

Access the video stream over RTSP
---------------------------------

RTSP server is on port 554.

You can access the video over RTSP on 3 urls : 
* High definition video and audio (h264) : http://ip:554/ch0_0.h264
* Low definition video and audio (h264) : http://ip:554/ch0_1.h264
* Audio (h264) : http://ip:554/ch0_3.h264

There is no login and password and currently no way to set it.

Access the history of motion detection
--------------------------------------

Each time a motion is detected, the camera will generate a video file (60s max). This file is stored on the memory card and can be accessed over :
* http server
* ftp server

The simplest way is to browse the file from the http server.

To know if a motion have been detected in the last minute, you can check the url http://ip/motion (GET). It can give : 
* when no motion is detected : an empty content
* when motion is detected : a file path to the video file from the root of the http server

Telnet server
-------------

The telnet server is on port 23.

Default login/password : 
* login = root
* password = 1234qwer (unless you specified another password in yi-hack.cfg file)

Ftp server
----------

The ftp server is on port 21.

There is no login/password required.


I want more !
=============

Some scripts are provided in the **sd/test/scripts** folder. Please read the **README.md** file in this folder for more informations.

Uninstall the hack
==================

First, remove the SD card. But keep in mind that the timeout sound has been altered.

If you want the timeout sound back:
Edit equip_test.sh to look like this:

    #!/bin/sh
    ######################################################
    # Xiaomi Yi hack restore
    ######################################################
     
    ### Rename back the timeout sound file ...
    [ -f /home/timeout.g726.OFF ] && mv /home/timeout.g726.OFF /home/timeout.g726
     
    sync

Then reboot the camera so the script runs. After remove the stuff from sd card and you are all original.


How it works ?
==============

Hack content
------------

```
home                           Official firmware 
test/                          Yi hack folder
  yi-hack.cfg                  Yi hack configuration file
  equip_test.sh                This script is called on camera startup and will launch all the needed processes
  check_motion.sh              This script will check each minute if a motion video has been recorded and fill the **motion** file of the http server
  rtspsrvK|L|M                 The various RTSP server binary releases (the final letter is corresponding to the firmware)
  http/                        HTTP server folder
    index.html                 HTTP server home page
    record/                    Mount point to access video records
    server                     HTTP server binary
  wpa_supplicant.conf          Configuration file for wifi  
  log.txt                      Log file of the hack (filled by equip_test.sh)
````


equip_test.sh
-------------

**TODO**

check_motion.sh
---------------

Script that runs from equip_test.sh and tell us if a new video was created in the last minute (a video file is created in case of motion detection).

If a file is found, it adds the name of the file to the section GET /motion on the http server.


