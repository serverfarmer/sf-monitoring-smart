#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom


exec 9>/var/run/smart.lock
if ! flock -n 9; then exit 0; fi

path="/var/cache/cacti"
devices=`/opt/farm/ext/standby-monitor/utils/list-physical-drives.sh |grep -vxFf /etc/local/.config/skip-smart.devices`

for device in $devices; do
	base="`basename $device`"
	file="$path/`echo $base |tr ':' '-'`.txt"
	deviceid=${base:4}

	/usr/sbin/smartctl -d sat -T permissive -a $device >$file.new

	if grep -q "No such device" $file.new; then
		cat $file.new |mail -s "URGENT: device $deviceid failed SMART data collection" smart-alerts@`external_domain`
	else
		mv -f $file.new $file 2>/dev/null

		if [ -s /etc/local/.config/newrelic.license ]; then
			/opt/farm/ext/monitoring-smart/targets/newrelic.sh $deviceid $file
		fi

		if [ -d /opt/farm/ext/monitoring-heartbeat ]; then
			/opt/farm/ext/monitoring-smart/targets/heartbeat.sh $deviceid $file
		fi

		if [ -d /opt/farm/ext/monitoring-cacti ]; then
			/opt/farm/ext/monitoring-cacti/cron/send.sh $file
		fi
	fi
done
