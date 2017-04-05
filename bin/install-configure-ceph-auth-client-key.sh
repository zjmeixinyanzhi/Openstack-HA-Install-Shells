#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Ceph Authentication Installation"

###复制ceph配置文件 glance-api, cinder-volume, nova-compute and cinder-backup的主机名,由于存储和计算在同一个节点，不需要复制到自身
./pssh-exe C "mkdir -p /etc/ceph/"
scp $compute_host:/etc/ceph/ceph.conf /etc/ceph/ceph.conf
./scp-exe C /etc/ceph/ceph.conf /etc/ceph/ceph.conf 
###[所有控制节点]在glance-api节点上
./pssh-exe C "yum install -y python-rbd"
###[所有控制节点]在nova-compute, cinder-backup 和cinder-volume节点上
./pssh-exe C "yum install -y ceph-common"
###安装Ceph客户端认证[这里放在控制节点执行执行，]
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rwx pool=images'
####为client.cinder, client.glance, and client.cinder-backup添加keyring
. style/print-info.sh "Copy cinder.keyring & glance.keyring & cinder-backup.keyring to compute nodes"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  ceph auth get-or-create client.glance | ssh $name  tee /etc/ceph/ceph.client.glance.keyring
  ssh $name  chown glance:glance /etc/ceph/ceph.client.glance.keyring
  ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
  ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
  ceph auth get-or-create client.cinder-backup | ssh $name  tee /etc/ceph/ceph.client.cinder-backup.keyring
  ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring
done;
###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
. style/print-info.sh "Copy cinder.keyring to compute nodes"
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
do
  name=${hypervisor_name[$i]};
  ip=${hypervisor_map[$name]};
  ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
  ceph auth get-key client.cinder | ssh $name tee client.cinder.key
done;
