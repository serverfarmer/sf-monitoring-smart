#!/bin/sh

deviceid=$1
file=$2


if [ -s /etc/local/.config/newrelic.license ]; then
	/opt/farm/ext/monitoring-smart/targets/sata-newrelic.sh $deviceid $file
fi

if [ -d /opt/farm/ext/monitoring-heartbeat ]; then
	/opt/farm/ext/monitoring-smart/targets/sata-heartbeat.sh $deviceid $file
fi

if [ -d /opt/farm/ext/monitoring-cacti ]; then
	/opt/farm/ext/monitoring-cacti/cron/send.sh $file
fi
