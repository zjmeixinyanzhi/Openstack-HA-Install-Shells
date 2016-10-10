#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

nodes_name=(${!nodes_map[@]});

virtual_ip=192.168.2.201
local_nic='eno16777736'
data_nic='eno50332184'

sh_name=compute_nodes_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
	 ssh root@$ip mkdir -p $target_sh
         scp $source_sh root@$ip:$target_sh
         ssh root@$ip chmod -R +x $target_sh
         ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $data_nic
  done;
