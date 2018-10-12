#!/bin/sh

deviceid=$1
file=$2

if [ -d /opt/farm/ext/monitoring-cacti ]; then
	/opt/farm/ext/monitoring-cacti/cron/send.sh $file
fi
