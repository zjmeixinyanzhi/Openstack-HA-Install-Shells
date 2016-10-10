#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );
declare -A controllers_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13");

nodes_name=(${!nodes_map[@]});
controllers_name=(${!controllers_map[@]})

echo ${controllers_name[@]}


###复制ceph配置文件 glance-api, cinder-volume, nova-compute and cinder-backup的主机名,由于存储和计算在同一个节点，不需要复制到自身
for ((i=0; i<${#controllers_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controllers_map[$name]};
      echo "-------------$name------------"
	ssh $name  mkdir -p /etc/ceph/
	ssh $name  tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf
	###[所有控制节点]在glance-api节点上
	ssh $name yum install -y python-rbd
	###[所有控制节点]在nova-compute, cinder-backup 和cinder-volume节点上
	ssh $name yum install -y ceph-common
  done;
###安装Ceph客户端认证
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'

###为client.cinder, client.glance, and client.cinder-backup添加keyring
for ((i=0; i<${#controllers_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controllers_map[$name]};
      echo "-------------$name------------"
	ceph auth get-or-create client.glance | ssh $name  tee /etc/ceph/ceph.client.glance.keyring
	ssh $name  chown glance:glance /etc/ceph/ceph.client.glance.keyring
	ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
	ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
	ceph auth get-or-create client.cinder-backup | ssh $name  tee /etc/ceph/ceph.client.cinder-backup.keyring
	ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring
  done;
###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
	ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
	ceph auth get-key client.cinder | ssh $name tee client.cinder.key
  done;

echo "

Please switch to contrller01 for installing cinder service!"

#for ((i=0; i<${#nodes_map[@]}; i+=1));
#  do
#      name=${nodes_name[$i]};
#      ip=${nodes_map[$name]};
#      echo "-------------$name------------"
#  done;
#
#for ((i=0; i<${#controllers_map[@]}; i+=1));
#  do
#      name=${controllers_name[$i]};
#      ip=${controllers_map[$name]};
#      echo "-------------$name------------"
#  done;

