#!/bin/sh
nodes_name=(${!nodes_map[@]});

sh_name=network-config-exec.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      scp $source_sh root@$ip:$target_sh
      ssh root@$ip chmod -R  +x $target_sh
      ssh root@$ip $target_sh/$sh_name $local_nic $data_nic $storage_nic $ip $data_network $store_network
  done;

