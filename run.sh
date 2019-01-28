#!/bin/bash
# run.sh ver1.2
# lklr89
# for reference see iBeacon Scanner by Elliot Larsen https://gist.github.com/elliotlarson/1e637da6613dbe3e777c and Radius Networks

############## PARSE CONFIG FILE ##############

UUID=XX:XX:XX:XX:XX
DISTANCE=0
TIMEOUTLEN=0

configfile='/etc/ble-agi/config.txt'

filtered_config=$(sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$configfile") 
#echo $filtered_config

UUID=$(echo $filtered_config | cut -d " " -f1)
DISTANCE=$(echo $filtered_config | cut -d " " -f2)
TIMEOUTLEN=$(echo $filtered_config | cut -d " " -f3)

echo "UUID=$UUID"
echo "DISTANCE=$DISTANCE"
echo "TIMEOUT=$TIMEOUTLEN"


############# AUDIO FILE ######################

AUDIO=/etc/ble-agi/audio/*.m4a


############# RESET HCI  ######################

halt_hcitool_lescan() {
	sudo pkill --signal SIGINT hcitool
}

trap halt_hcitool_lescan INT
hciconfig hci0 reset


############# SCAN AND ANALYZE ##############################

process_complete_packet() {
  # an example packet with output:
  # >04 3E 2A 02 01 03 00 CA 66 69 70 F3 5C 1E 02 01 1A 1A FF 4C 00 02 15 2F 23 44 54 CF 6D 4A 0F AD F2 F4 91 1B A9 FF A6 00 01 00 01 C5 B2
  # => 2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6    1       1       -59     -78

  local packet=${1//[\ |>]/}

  # only work with iBeacon packets
  if [[ ! $packet =~ ^043E2A0201.{18}0201.{10}0215 ]]; then
    return
  fi

  beacon_uuid="${packet:46:8}-${packet:54:4}-${packet:58:4}-${packet:62:4}-${packet:66:12}"
  beacon_major=$((0x${packet:78:4}))
  beacon_minor=$((0x${packet:82:4}))
  beacon_power=$[$((0x${packet:86:2})) - 256]
  beacon_rssi=$[$((0x${packet:88:2})) - 256]
 
  echo -e "$beacon_uuid\t$beacon_major\t$beacon_minor\t$beacon_power\t$beacon_rssi"

  if [ "$beacon_uuid" == "$UUID" ]; then
	if [ $beacon_rssi -gt $DISTANCE ]; then 
    	echo "$beacon_rssi is greater than $DISTANCE" 
        # TODO: case Major/Minor and select audio file..
		su pi -c "cvlc --play-and-exit $AUDIO" 2> /etc/ble-agi/vlc_err.log 
		sleep $TIMEOUTLEN
	fi
  fi
}

read_blescan_packet_dump() {
  # packets span multiple lines and need to be built up
  packet=""
  while read line; do
    # packets start with ">"
    if [[ $line =~ ^\> ]]; then
      # process the completed packet (unless this is the first time through)
      if [ "$packet" ]; then
        process_complete_packet "$packet"
      fi
      # start the new packet
      packet=$line
    else
      # continue building the packet
      packet="$packet $line"
    fi
  done
}


nohup hcitool lescan --duplicates 2>/dev/null & 
sleep 1
# make sure the scan started
if [ "$(pidof hcitool)" ]; then
	# start the scan packet dump and process the stream
	while [ 1 ]
	do
		timeout 0.1 hcidump --raw | read_blescan_packet_dump # terminate for packet update
    done
   else
	echo "ERROR: it looks like hcitool lescan isn't starting up correctly" >&2
        exit 1
fi

exit 0

