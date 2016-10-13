#!/bin/sh
local_nic=$1
data_nic=$2
storage_nic=$3

sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$local_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic
