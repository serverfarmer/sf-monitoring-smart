#!/bin/sh

file=`mktemp -u /var/cache/cacti/raid.XXXXXXXXX.tmp`
handles=`/opt/farm/ext/storage-utils/list-megaraid-drives.sh`
node=/dev/bus/0

for handle in $handles; do
	/usr/sbin/smartctl -d $handle -i $node >$file

	if grep -q " SAS" $file; then
		model=`grep 'Product:' $file |awk '{ print $2 $3 $4 $5 $6 $7 $8 $9 }'`
		serial=`grep 'Serial number:' $file |awk '{ print $3 }'`
		echo sas:$node:$handle:sas-${model}_${serial}
	else
		model=`grep 'Device Model:' $file |awk '{ print $3 $4 $5 $6 $7 $8 $9 }'`
		serial=`grep 'Serial Number:' $file |awk '{ print $3 }'`
		echo sata:$node:$handle:ata-${model}_${serial}
	fi
done

rm -f $file
