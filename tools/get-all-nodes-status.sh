#!/bin/sh

declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

nodes_name=(${!nodes_map[@]});
rm -rf result.log
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------">> result.log 
      #ssh root@$ip  cat /etc/sysconfig/network-scripts/ifcfg-eno*|grep ONBOOT
      ssh root@$ip ls /etc/yum.repos.d/>> result.log
  done;

