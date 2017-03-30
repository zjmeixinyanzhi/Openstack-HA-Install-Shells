#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Controllers Pacemaker Cluster Installation"
 ### [所有控制节点] 安装软件
./pssh-exe C "yum install -y pcs pacemaker corosync fence-agents-all resource-agents"
### [所有控制节点] 配置服务
./pssh-exe C "systemctl enable pcsd && systemctl start pcsd"
 ### [所有控制节点]设置hacluster用户的密码
./pssh-exe C "echo $password_ha_user | passwd --stdin hacluster"
## [controller01]设置到集群节点的认证
pcs cluster auth ${controller_name[@]} -u hacluster -p $password_ha_user --force
### [controller01]创建并启动集群
pcs cluster setup --force --name openstack-cluster ${controller_name[@]}
pcs cluster start --all
pcs cluster enable --all
sleep 5
### [controller01]设置集群属性
pcs property set pe-warn-series-max=1000 pe-input-series-max=1000 pe-error-series-max=1000 cluster-recheck-interval=5min
### [controller01] 暂时禁用STONISH，否则资源无法启动
pcs property set stonith-enabled=false
### [controller01]配置VIP资源，VIP可以在集群节点间浮动
pcs resource create vip ocf:heartbeat:IPaddr2 params ip=$virtual_ip cidr_netmask="24" op monitor interval="30s"
