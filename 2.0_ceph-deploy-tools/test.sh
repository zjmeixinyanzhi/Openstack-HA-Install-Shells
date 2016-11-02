#!/bin/sh
osd_numbers=$(echo $osd_path| awk -F ";" '{print NF}') 
echo $osd_numbers
for i in `seq 1 $osd_numbers`
do
  echo $i
  echo $(echo $osd_path|cut -d ';' -f $i)
done
