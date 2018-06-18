#!/bin/bash
. /opt/farm/scripts/init
. /opt/farm/scripts/functions.custom


deviceid=$1
file=$2

reasons=""


lookup_smart_attribute() {
	name=$1
	reference=$2
	value="`grep $name $file |awk \"{ print \\\$10 }\" |cut -dh -f1`"

	if [ "$value" != "" ] && [ $value -gt $reference ]; then
		increase=`grep ^$deviceid: /etc/local/.config/allowed.smart |grep :$name: |cut -d: -f3 |sed 's/[^0-9]*//g'`
		if [ "$increase" = "" ]; then
			reasons="$reasons, $name=$value"
		elif [ $value -gt $increase ]; then
			reasons="$reasons, $name=$value (previously increased to $increase)"
		fi
	fi
}


if [ "`echo $deviceid |grep SSD`" = "" ]; then
	maxtemp=48
else
	maxtemp=55
fi

lookup_smart_attribute Temperature_Celsius $maxtemp
lookup_smart_attribute Reallocated_Sector_Ct 0
lookup_smart_attribute End-to-End_Error 0
lookup_smart_attribute UDMA_CRC_Error_Count 0
lookup_smart_attribute Spin_Retry_Count 0
lookup_smart_attribute Runtime_Bad_Block 10
lookup_smart_attribute Current_Pending_Sector 2
lookup_smart_attribute Reported_Uncorrect 0
lookup_smart_attribute Offline_Uncorrectable 0
lookup_smart_attribute Calibration_Retry_Count 0
lookup_smart_attribute Power_On_Hours 70000   # 8 years is enough for any drive...

if [ "$reasons" != "" ]; then
	logger -p cron.notice -t smart "aborting heartbeat for drive $deviceid: ${reasons:2}"
	exit 0
fi

if [ -s /etc/local/.config/heartbeat.url ]; then
	url=`cat /etc/local/.config/heartbeat.url`
else
	url=`heartbeat_url`
fi

serial=`echo $deviceid |tr '_' '-' |tr ':' '-' |tr '[:upper:]' '[:lower:]'`
curl --connect-timeout 1 --retry 2 --retry-max-time 3 -s "$url?host=$HOST&services=smart-$serial" >/dev/null 2>/dev/null
