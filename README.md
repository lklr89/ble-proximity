# ble-proximity
Measuring distance from a Bluetooth Low Energy beacon to an observer device


In this project, I used a RaspberryPi 3B to collect, filter and analyze data of an 
advertising beacon to trigger an action when a given RSSI value is reached. The service
is handled and managed by systemd and I implemented a udev rule to automount usb sticks and 
fetch data from them.
