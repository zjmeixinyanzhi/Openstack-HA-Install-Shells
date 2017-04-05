#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Configure SSH"
ssh-keygen
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
  done;
