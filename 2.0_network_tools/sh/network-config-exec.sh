#!/bin/sh
local_nic=$1
data_nic=$2
storage_nic=$3
local_ip=$4
data_network=$5
storage_network=$6
echo $storage_network

sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$local_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic

### set network suffix
old_data_ip=$(cat /etc/sysconfig/network-scripts/ifcfg-$data_nic |grep IPADDR=|egrep -v "#IPADDR"|awk -F "=" '{print $2}')
new_data_ip=$(echo $data_network|cut -d "." -f1-3).$(echo $local_ip|awk -F "." '{print $4}') 
if [ $old_data_ip = $new_data_ip  ];then
  echo "The suffix of data network is same as the local network!"
else
  echo "The suffix of data network is not same as the local network, Renew it as following! "
  sed -i -e 's#IPADDR=#\#IPADDR=#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
  echo "IPADDR="$new_data_ip>> /etc/sysconfig/network-scripts/ifcfg-$data_nic
  ifdown $data_nic
  ifup   $data_nic 
fi
old_storage_ip=$(cat /etc/sysconfig/network-scripts/ifcfg-$storage_nic |grep IPADDR=|egrep -v "#IPADDR"|awk -F "=" '{print $2}')
new_storage_ip=$(echo $storage_network|cut -d "." -f1-3).$(echo $local_ip|awk -F "." '{print $4}') 
if [ $old_storage_ip = $new_storage_ip  ];then
  echo "The suffix of storage network is same as the local network!"
else
  echo "The suffix of storage network is not same as the local network, Renew it as following! "
  sed -i -e 's#IPADDR=#\#IPADDR=#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic
  echo "IPADDR="$new_storage_ip>> /etc/sysconfig/network-scripts/ifcfg-$storage_nic
  ifdown $storage_nic
  ifup   $storage_nic 
fi

