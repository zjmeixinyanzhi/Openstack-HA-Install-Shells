#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Cinder Installation"
### [所有控制节点] 安装配置
./pssh-exe C "yum install -y openstack-cinder"
### [所有控制节点]配置配置cinder组件，/etc/nova/nova.conf文件
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$password@$virtual_ip/cinder
    openstack-config --set /etc/cinder/cinder.conf database max_retries -1
    openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://$virtual_ip:35357
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
    openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password $password
    openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues true
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_interval 1
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_backoff 2
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_max_retries 0
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_durable_queues true
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
    openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password $password
    openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
    openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen  $ip
    openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip  $ip
    openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
    openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://$virtual_ip:9292
    openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
    openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd
    openstack-config --set /etc/glance/glance-api.conf glance_store default_store rbd
    openstack-config --del /etc/glance/glance-api.conf glance_store filesystem_store_datadir
    openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
    openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
    openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
    openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
    openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
    openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends ceph
    openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version 2
    openstack-config --set /etc/cinder/cinder.conf ceph volume_driver cinder.volume.drivers.rbd.RBDDriver
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_pool volumes
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_ceph_conf /etc/ceph/ceph.conf
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_flatten_volume_from_snapshot false
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_max_clone_depth 5
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_store_chunk_size 4
    openstack-config --set /etc/cinder/cinder.conf ceph rados_connect_timeout -1
    openstack-config --set /etc/cinder/cinder.conf ceph glance_api_version 2
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_user cinder
    openstack-config --set /etc/cinder/cinder.conf ceph rbd_secret_uuid 032198f4-b815-4254-9de2-185f935bd7de
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_driver  cinder.backup.drivers.ceph
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_conf /etc/ceph/ceph.conf
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_user cinder-backup
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_chunk_size 134217728
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_pool backups
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_unit 0
    openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_count 0
    openstack-config --set /etc/cinder/cinder.conf DEFAULT restore_discard_excess_bytes true
    openstack-config --set /etc/cinder/cinder.conf DEFAULT host cinder-cluster 
    service openstack-glance-api restart
    service openstack-cinder-volume restart
    service openstack-cinder-backup restart
EOF
done;
### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
  IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'controller01' \
  IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
  IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"
##### generate haproxy.cfg
. ./1-gen-haproxy-cfg.sh cinder
### [任一节点]创建用户等
. /root/keystonerc_admin
### [任一节点]创建用户等
openstack user create --domain default --password $password cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder  --description "OpenStack Block Storage" volume
openstack service create --name cinderv2  --description "OpenStack Block Storage" volumev2
###创建cinder服务的API endpoints
openstack endpoint create --region RegionOne volume public http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume internal http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume admin http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 public http://$virtual_ip:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$virtual_ip:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$virtual_ip:8776/v2/%\(tenant_id\)s
### [任一节点]生成数据库
su -s /bin/sh -c "cinder-manage db sync" cinder
### [任一节点]添加pacemaker资源
pcs resource create openstack-cinder-api systemd:openstack-cinder-api --clone interleave=true
pcs resource create openstack-cinder-scheduler systemd:openstack-cinder-scheduler --clone interleave=true
pcs resource create openstack-cinder-volume systemd:openstack-cinder-volume
pcs constraint order start openstack-keystone-clone then openstack-cinder-api-clone
pcs constraint order start openstack-cinder-api-clone then openstack-cinder-scheduler-clone
pcs constraint colocation add openstack-cinder-scheduler-clone with openstack-cinder-api-clone
pcs constraint order start openstack-cinder-scheduler-clone then openstack-cinder-volume
pcs constraint colocation add openstack-cinder-volume with openstack-cinder-scheduler-clone
pcs resource op add openstack-cinder-api start timeout=300
pcs resource op add openstack-cinder-api stop timeout=300
pcs resource op add openstack-cinder-scheduler start timeout=300
pcs resource op add openstack-cinder-scheduler stop timeout=300
pcs resource op add openstack-cinder-volume start timeout=300
pcs resource op add openstack-cinder-volume stop timeout=300
. restart-pcs-cluster.sh
cinder service-list
