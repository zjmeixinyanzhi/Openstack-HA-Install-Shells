#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16");

nodes_name=(${!nodes_map[@]});

deploy_node=compute01
echo $deploy_node


cd /root/my-cluster

### set 
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
     if [ $name =  $deploy_node ]; then
	echo $name" already is mon!"
     else
        ceph-deploy mon add $name
      fi
  done;

