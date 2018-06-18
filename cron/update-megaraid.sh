#!/bin/sh

# On some (older) servers, MegaRAID drives are not detected
# by list-megaraid-drives.sh script, or in any other method.
# The only way to monitor them is to add them manually to
# crontab, eg.:
#
# /opt/farm/ext/monitoring-smart/handlers/megaraid.sh megaraid,0 /dev/sda
#
# (note the /dev/sda or other existing device instead of /dev/bus/0)

exec 9>/var/run/smart-megaraid.lock
if ! flock -n 9; then exit 0; fi

handles=`/opt/farm/ext/storage-utils/list-megaraid-drives.sh`

for handle in $handles; do
	/opt/farm/ext/monitoring-smart/handlers/megaraid.sh $handle /dev/bus/0
done
