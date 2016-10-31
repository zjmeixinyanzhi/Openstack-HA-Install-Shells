#!/bin/sh
nodes_name=(${!nodes_map[@]});

target_sh=$tmp_path
echo "rm "$target_sh

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip rm -rf $target_sh
  done;
echo "Please delete the install dir manually on controller01 and compute01!"
