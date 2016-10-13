#!/bin/sh
nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      echo ">>>>>>>"
      ping -c 2 $ip
      echo ">>>>>>>"
      ping -c 2 $(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      echo ">>>>>>>"
      ping -c 2 $(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;

