#!/bin/sh

if grep -q /opt/farm/ext/monitoring-smart/cron /etc/crontab; then
	sed -i -e "/\/opt\/farm\/ext\/monitoring-smart\/cron/d" /etc/crontab
fi
