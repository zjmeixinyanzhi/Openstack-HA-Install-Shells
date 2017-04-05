#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "MongoDB Installation"

mongo_replica_cfg=../conf/mongo_replica_setup.js
### 所有控制节点安装mongodb
./pssh-exe C "yum install -y mongodb-server mongodb"
./pssh-exe C "sed -i -e 's#.*bind_ip.*#bind_ip = 0.0.0.0#g' -e 's/.*replSet.*/replSet = ceilometer/g' -e 's/.*smallfiles.*/smallfiles = true/g' /etc/mongod.conf"
./pssh-exe C "systemctl start mongod && systemctl stop mongod"
### [controller01] 添加资源
pcs resource create mongod systemd:mongod op start timeout=300s --clone
### [controller01] 设置副本集，等待pcs启动所有节点上的mongod服务
. restart-pcs-cluster.sh
mongo $mongo_replica_cfg
### [controller01] 确认副本集状态
#mongo rs.status()
#mongo rs.conf()
