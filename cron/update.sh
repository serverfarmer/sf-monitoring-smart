#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom


exec 9>/var/run/smart.lock
if ! flock -n 9; then exit 0; fi

path="/var/cache/cacti"
devices=`/opt/farm/ext/storage-utils/list-physical-drives.sh |grep -vxFf /etc/local/.config/skip-smart.devices`

for device in $devices; do
	base="`basename $device`"
	file="$path/`echo $base |tr ':' '-'`.txt"
	deviceid=${base:4}

	/usr/sbin/smartctl -d sat -T permissive -a $device >$file.new

	if grep -q "No such device" $file.new || grep -q "Read Device Identity failed" $file.new; then
		cat $file.new |mail -s "URGENT: device $deviceid failed SMART data collection" smart-alerts@`external_domain`
	else
		mv -f $file.new $file 2>/dev/null
		/opt/farm/ext/monitoring-smart/targets/sata.sh $deviceid $file
	fi
done


raid=`cat /etc/local/.config/raid.drives |grep -vFf /etc/local/.config/skip-smart.raid`

for entry in $raid; do
	type=$(echo $entry |cut -d: -f1)
	node=$(echo $entry |cut -d: -f2)
	handle=$(echo $entry |cut -d: -f3)
	device=$(echo $entry |cut -d: -f4)

	file="$path/$device.txt"
	/usr/sbin/smartctl -d $handle -a $node >$file.new
	mv -f $file.new $file 2>/dev/null

	/opt/farm/ext/monitoring-smart/targets/$type.sh ${device:4} $file
done
