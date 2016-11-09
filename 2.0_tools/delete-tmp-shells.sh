#!/bin/sh
nodes_name=(${!nodes_map[@]});

target_sh=/root/tools/
echo "rm "$target_sh

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      if [ $target_sh = "" ];then
         echo "target dir is null!"
      else
        ssh root@$ip rm -rf /root/tools/
      fi
  done;
echo "Please delete the install dir manually on controller01 and compute01!"
