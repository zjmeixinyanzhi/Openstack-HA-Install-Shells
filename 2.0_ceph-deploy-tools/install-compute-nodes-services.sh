#!/bin/sh
nodes_name=(${!hypervisor_map[@]});

sh_name=compute_nodes_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
	 ssh root@$ip mkdir -p $target_sh
         scp $source_sh root@$ip:$target_sh
         ssh root@$ip chmod -R +x $target_sh
         ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $data_nic $password
  done;
