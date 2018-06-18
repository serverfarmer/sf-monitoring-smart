#!/bin/sh

handle=$1
node=$2

path="/var/cache/cacti"

file="$path/`echo $handle |tr ',' '-'`.tmp"
/usr/sbin/smartctl -d $handle -i $node >$file

if ! grep -q " SAS" $file; then
	model=`grep 'Device Model:' $file |awk '{ print $3 $4 $5 $6 $7 $8 $9 }'`
	serial=`grep 'Serial Number:' $file |awk '{ print $3 }'`

	deviceid="${model}_${serial}"
	file2="$path/ata-$deviceid.txt"

	/usr/sbin/smartctl -d $handle -a $node >$file2.new

	mv -f $file2.new $file2 2>/dev/null
	/opt/farm/ext/monitoring-smart/targets/sata.sh $deviceid $file2
fi
