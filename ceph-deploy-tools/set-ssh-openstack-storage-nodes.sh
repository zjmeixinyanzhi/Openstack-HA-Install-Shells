#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );
declare -A controllers_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13");

nodes_name=(${!nodes_map[@]});
controllers_name=(${!controllers_map[@]})

echo ${controllers_name[@]}

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@10.10.10.$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@11.11.11.$(echo $ip|awk -F "." '{print $4}')
  done;

for ((i=0; i<${#controllers_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controllers_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@10.10.10.$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@11.11.11.$(echo $ip|awk -F "." '{print $4}')
  done;

