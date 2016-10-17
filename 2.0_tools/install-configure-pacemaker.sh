#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=pcs_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=$tmp_path

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $password_ha_user

  done;
### [controller01]设置到集群节点的认证
pcs cluster auth $controller_list_space -u hacluster -p $password_ha_user --force

### [controller01]创建并启动集群
pcs cluster setup --force --name openstack-cluster $controller_list_space
pcs cluster start --all

sleep 5
### [controller01]设置集群属性
pcs property set pe-warn-series-max=1000 pe-input-series-max=1000 pe-error-series-max=1000 cluster-recheck-interval=5min

### [controller01] 暂时禁用STONISH，否则资源无法启动
pcs property set stonith-enabled=false

### [controller01]配置VIP资源，VIP可以在集群节点间浮动
pcs resource create vip ocf:heartbeat:IPaddr2 params ip=$virtual_ip cidr_netmask="24" op monitor interval="30s"
