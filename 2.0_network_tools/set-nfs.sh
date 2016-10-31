#!/bin/sh
#### controller01
ssh root@$nfs_host echo "$nfs_location $local_network(rw,sync,no_root_squash,no_subtree_check)">>/etc/exports
ssh root@$nfs_host systemctl enable rpcbind nfs-server
ssh root@$nfs_host systemctl start rpcbind nfs-server

nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $nfs_location 
      ssh root@$ip mount $nfs_host:$nfs_location $nfs_location  
      ssh root@$ip echo "$nfs_host:$nfs_location $nfs_location  nfs     defaults        0 0" >>/etc/fstab
      ssh root@$ip mount
  done;
