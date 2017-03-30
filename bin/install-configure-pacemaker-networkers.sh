#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Networkers Pacemaker Installation"

### [所有网络节点] 安装软件
./pssh-exe N "yum install -y pcs pacemaker corosync fence-agents-all resource-agents"
### [所有网络节点] 配置服务
./pssh-exe N "systemctl enable pcsd && systemctl start pcsd"
### [所有网络节点]设置hacluster用户的密码
./pssh-exe N "echo $password_ha_user | passwd --stdin hacluster"
### [network01]设置到集群节点的认证
ssh root@$network_host pcs cluster auth ${networker_name[@]} -u hacluster -p $password_ha_user --force
### [network01]创建并启动集群
ssh root@$network_host pcs cluster setup --force --name openstack-cluster ${networker_name[@]}
ssh root@$network_host pcs cluster start --all
ssh root@$network_host sleep 5
### [network01]设置集群属性
ssh root@$network_host pcs property set pe-warn-series-max=1000 pe-input-series-max=1000 pe-error-series-max=1000 cluster-recheck-interval=5min
### [network01] 暂时禁用STONISH，否则资源无法启动
ssh root@$network_host pcs property set stonith-enabled=false
### [network01] 检验集群状态 
ssh root@$network_host pcs cluster status
