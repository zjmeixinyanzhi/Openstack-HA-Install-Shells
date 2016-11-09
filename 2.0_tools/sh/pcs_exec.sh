#!/bin/sh
 ### [所有控制节点] 安装软件
password=$1
yum install -y pcs pacemaker corosync fence-agents-all resource-agents
### [所有控制节点] 配置服务
systemctl enable pcsd
systemctl start pcsd
 ### [所有控制节点]设置hacluster用户的密码
echo ${password} | passwd --stdin hacluster
