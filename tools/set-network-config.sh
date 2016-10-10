#!/bin/sh

declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip  sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-eno16777736  
      ssh root@$ip  sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-eno33554960 
      ssh root@$ip  sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-eno50332184 
  done;

