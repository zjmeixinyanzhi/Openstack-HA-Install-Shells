#!/bin/sh
networker_name=(${!networker_map[@]});
controller_name=(${!controller_map[@]});

for ((i=0; i<${#networker_map[@]}; i+=1));
  do
      name=${networker_name[$i]};
      ip=${networker_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$name
      #ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
      name=${controller_name[$i]};
      ip=${controller_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$name
      #ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;
