#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom

license="`cat /etc/local/.config/newrelic.license`"


add_metric() {
	file=$1
	previous=$2
	pattern=$3
	metric=$4
	value=`grep $pattern $file |awk "{ print \\$10 }" |cut -dh -f1`
	if [ "$value" != "" ] && [ "$previous" != "" ]; then
		echo "$previous, \"$metric\": $value"
	elif [ "$value" != "" ]; then
		echo "\"$metric\": $value"
	elif [ "$previous" != "" ]; then
		echo "$previous"
	fi
}


exec 9>/var/run/smart.lock
if ! flock -n 9; then exit 0; fi

path="/var/cache/cacti"
devices=`/opt/farm/ext/standby-monitor/utils/list-physical-drives.sh |grep -vxFf /etc/local/.config/skip-smart.devices`

for device in $devices; do
	base="`basename $device`"
	file="$path/`echo $base |sed s/ata-/nr-/g`.txt"

	/usr/sbin/smartctl -d sat -T permissive -a $device >$file.new

	if grep -q "No such device" $file.new; then
		cat $file.new |mail -s "URGENT: device $base failed SMART data collection" smart-alerts@`external_domain`
	else
		mv -f $file.new $file 2>/dev/null

		deviceid=`echo $base |sed -e s/ata-//g -e s/.txt//g`

		metrics=""
		metrics=`add_metric $file "$metrics" Calibration_Retry_Count "Component/serverFarmer/smart/critical/calibrationRetries[Value]"`
		metrics=`add_metric $file "$metrics" End-to-End_Error        "Component/serverFarmer/smart/critical/endToEndErrors[Value]"`
		metrics=`add_metric $file "$metrics" G-Sense_Error_Rate      "Component/serverFarmer/smart/minor/gSenseErrors[Value]"`
		metrics=`add_metric $file "$metrics" Head_Flying_Hours       "Component/serverFarmer/smart/headFlyingHours[Value]"`
		metrics=`add_metric $file "$metrics" High_Fly_Writes         "Component/serverFarmer/smart/minor/highFlyWrites[Value]"`
		metrics=`add_metric $file "$metrics" Power_On_Hours          "Component/serverFarmer/smart/powerOnHours[Value]"`
		metrics=`add_metric $file "$metrics" Power_Cycle_Count       "Component/serverFarmer/smart/powerCycles[Value]"`
		metrics=`add_metric $file "$metrics" Reallocated_Sector_Ct   "Component/serverFarmer/smart/critical/reallocatedSectors[Value]"`
		metrics=`add_metric $file "$metrics" Reallocated_Event_Count "Component/serverFarmer/smart/critical/reallocatedEvents[Value]"`
		metrics=`add_metric $file "$metrics" Reported_Uncorrect      "Component/serverFarmer/smart/critical/reportedUncorrect[Value]"`
		metrics=`add_metric $file "$metrics" Runtime_Bad_Block       "Component/serverFarmer/smart/minor/runtimeBadBlocks[Value]"`
		metrics=`add_metric $file "$metrics" Spin_Retry_Count        "Component/serverFarmer/smart/critical/spinRetries[Value]"`
		metrics=`add_metric $file "$metrics" Start_Stop_Count        "Component/serverFarmer/smart/startStops[Value]"`
		metrics=`add_metric $file "$metrics" Temperature_Celsius     "Component/serverFarmer/smart/temperatureCelsius[Value]"`
		metrics=`add_metric $file "$metrics" UDMA_CRC_Error_Count    "Component/serverFarmer/smart/critical/udmaCrcErrors[Value]"`

		if [ "$metrics" != "" ]; then
			curl -s -o /dev/null --connect-timeout 2 https://platform-api.newrelic.com/platform/v1/metrics \
				-H "X-License-Key: $license" \
				-H "Content-Type: application/json" \
				-H "Accept: application/json" \
				-X POST -d '{
  "agent": {
    "host" : "'$HOST'",
    "version" : "0.1"
  },
  "components": [
    {
      "name": "'$deviceid'",
      "guid": "org.serverfarmer.newrelic.SmartV7",
      "duration" : 120,
      "metrics" : {
        '"$metrics"'
      }
    }
  ]
}'
		fi
	fi
done
