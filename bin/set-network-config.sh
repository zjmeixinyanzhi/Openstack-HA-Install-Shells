#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Configure Network"

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
    name=${nodes_name[$i]};
    ip=${nodes_map[$name]};
    ./style/print-info.sh $name
    old_data_ip=$(ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$data_nic |grep IPADDR=|egrep -v "#IPADDR"|awk -F "=" '{print $2}')
    new_data_ip=$(echo ${data_network}|cut -d "." -f1-3).$(echo ${ip}|awk -F "." '{print $4}')
    old_storage_ip=$(ssh $ip cat /etc/sysconfig/network-scripts/ifcfg-$storage_nic |grep IPADDR=|egrep -v "#IPADDR"|awk -F "=" '{print $2}')
    new_storage_ip=$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
    #echo $old_data_ip $new_data_ip
    ssh $ip /bin/bash << EOF
    #echo "$local_nic $data_nic $storage_nic"
    sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$local_nic
    sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
    sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic
    sed -i -e 's#BOOTPROTO=dhcp#BOOTPROTO=none#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
    sed -i -e 's#BOOTPROTO=dhcp#BOOTPROTO=none#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic
    ### set network suffix
    cat /etc/sysconfig/network-scripts/ifcfg-$data_nic  |grep IPADDR= 
    if [ $old_data_ip = $new_data_ip ];then
      echo "The suffix of data network is same as the local network!"
    else
      echo "The suffix of data network is not same as the local network, Renew it as following! "
      sed -i -e 's/^IPADDR=.*/IPADDR=$new_data_ip/' /etc/sysconfig/network-scripts/ifcfg-$data_nic
      ifdown $data_nic
      ifup   $data_nic
    fi
    
    if [ $old_storage_ip = $new_storage_ip  ];then
      echo "The suffix of storage network is same as the local network!"
    else
      echo "The suffix of storage network is not same as the local network, Renew it as following! "
      sed -i -e 's/^IPADDR=.*/IPADDR=$new_storage_ip/' /etc/sysconfig/network-scripts/ifcfg-$storage_nic
      ifdown $storage_nic
      ifup   $storage_nic
    fi
EOF
  done;

