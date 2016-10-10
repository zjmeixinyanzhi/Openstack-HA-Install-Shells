#!/bin/sh
local_nic="eno16777736"
local_nic=$1
echo $local_nic

## 备份原来配置文件
cp /etc/sysconfig/network-scripts/ifcfg-$local_nic /etc/sysconfig/network-scripts/bak-ifcfg-$local_nic
echo "DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep IPADDR|awk -F '=' '{print $2}')
NETMASK=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep NETMASK|awk -F '=' '{print $2}')
GATEWAY=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep GATEWAY|awk -F '=' '{print $2}')
DNS1=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep DNS1|awk -F '=' '{print $2}')
DNS2=8.8.8.8
ONBOOT=yes">/etc/sysconfig/network-scripts/ifcfg-br-ex

echo "TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
NAME=$local_nic
DEVICE=$local_nic
ONBOOT=yes">/etc/sysconfig/network-scripts/ifcfg-$local_nic

ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $local_nic

systemctl restart network.service
