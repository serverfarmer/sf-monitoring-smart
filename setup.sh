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

/opt/farm/scripts/setup/extension.sh sf-cache-utils
/opt/farm/scripts/setup/extension.sh sf-hardware-utils

if [ ! -f /etc/local/.config/allowed.smart ]; then
	echo "# example entries:
# ST4000DM000-1F2168_W300XXXX:UDMA_CRC_Error_Count:3
# WDC_WD121KRYZ-01W0RB0_XXXXXXXX:Temperature_Celsius:50
" >/etc/local/.config/allowed.smart
fi

if ! grep -q /opt/farm/ext/monitoring-smart/cron/update.sh /etc/crontab; then
	echo "setting up crontab entry"
	echo "*/2 * * * * root /opt/farm/ext/monitoring-smart/cron/update.sh" >>/etc/crontab
fi
