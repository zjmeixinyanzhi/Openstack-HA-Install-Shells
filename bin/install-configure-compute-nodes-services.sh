#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Openstack Services Installation on Compute Nodes"
./scp-exe H compute_nodes_exec.sh /tmp
./pssh-exe H "chmod +x /tmp/compute_nodes_exec.sh"
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
do
  name=${nodes_name[$i]};
  ip=${hypervisor_map[$name]};
  . style/print-info.sh "$name configuration"  
  ssh root@$ip /tmp/compute_nodes_exec.sh $virtual_ip $local_nic $data_nic $password
done;
