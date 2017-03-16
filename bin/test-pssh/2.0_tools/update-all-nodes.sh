#!/bin/sh
nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      #ssh root@$ip yum upgrade -y
      #ssh root@$ip date
      scp /etc/hosts root@$ip:/etc/
  done;

