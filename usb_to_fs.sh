#!/bin/bash

############################# USB_TO_FS SYNC #############################################
# USB Mount is managed by UDEV rule /etc/udev/rules.d/11-media-by-label-auto-mount.rules
# Once a USB device is plugged in, it mounts it with its name at /media
# so you can plug in every USB device, which contains an AGI folder for script success
# better not try to plug in 2 or more devices
# just reboot system after update
##########################################################################################

log=/etc/ble-agi/usb.log
src=/media/$(ls /media)/AGI/
date > $log 2>&1
sleep_count=20

echo "Looking for USB device..." >> $log 2>&1 

# Wait until Device is found
until [ $sleep_count -lt 1 ]
do
       	if [ -d "$src" ]; then
		echo "Found USB device..." >> $log 2>&1
		rsync -t /media/*/AGI/config.txt /etc/ble-agi/config.txt >> $log 2>&1
		rm /etc/ble-agi/audio/*.m4a >> $log 2>&1
		cp /media/*/AGI/*.m4a /etc/ble-agi/audio/ >> $log 2>&1
		echo "Data sync done..." >> $log 2>&1
		exit 0 
	else
		sleep 5
	fi
	let sleep_count=sleep_count-1
done
echo "Failure! Couldn't read usb.." >> $log 2>&1
exit 1
