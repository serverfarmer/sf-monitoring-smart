#!/bin/bash
. /opt/farm/scripts/init


if [ "$HWTYPE" = "container" ] || [ "$HWTYPE" = "lxc" ]; then
	echo "skipping smart monitoring configuration (containers do not have access to physical drives)"
	exit 1
fi

if [ "$OSTYPE" = "netbsd" ]; then
	echo "skipping smart monitoring configuration (unsupported system)"
	exit 1
fi

/opt/farm/scripts/setup/extension.sh sf-monitoring-newrelic

if [ ! -s /etc/local/.config/newrelic.license ]; then
	echo "skipping smart monitoring configuration (no license key configured)"
	exit 0
fi

/opt/farm/scripts/setup/extension.sh sf-standby-monitor

mkdir -p /var/cache/cacti

if ! grep -q /var/cache/cacti /etc/fstab && [ "$HWTYPE" = "physical" ]; then
	echo "tmpfs /var/cache/cacti tmpfs noatime,size=16m 0 0" >>/etc/fstab
fi

if ! grep -q /opt/farm/ext/monitoring-smart/cron/update.sh /etc/crontab; then
	echo "setting up crontab entry"
	echo "*/2 * * * * root /opt/farm/ext/monitoring-smart/cron/update.sh" >>/etc/crontab
fi
