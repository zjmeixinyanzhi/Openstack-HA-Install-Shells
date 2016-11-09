#!/bin/sh
nodes_name=(${!hypervisor_map[@]});
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
	 ssh root@$ip  systemctl restart openstack-ceilometer-*
  done;
