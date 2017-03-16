#!/bin/sh
vip='192.168.2.201'
vip=$1
local_bridge=$2
password=$3
 
echo $vip $local_bridge $password
yum install -y openstack-cinder
### [所有控制节点]配置配置cinder组件，/etc/nova/nova.conf文件
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$password@$vip/cinder
openstack-config --set /etc/cinder/cinder.conf database max_retries -1
	
openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://$vip:35357
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
openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen  $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip  $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://$vip:9292


######**********集成Ceph的Openstack配置****************#########
### [所有控制节点] 修改/etc/glance/glance-api.conf文件，增加
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd
openstack-config --set /etc/glance/glance-api.conf glance_store default_store rbd
openstack-config --del /etc/glance/glance-api.conf glance_store filesystem_store_datadir
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone

####[所有控制节点] 修改/etc/cinder/cinder.conf
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

openstack-config --set /etc/cinder/cinder.conf DEFAULT host cinder-cluster-$(echo `hostname`|awk -F "controller" '{print $2}')
####[所有控制节点] 修改NOVA 设置/etc/nova/nova.conf
#openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
#openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool vms
#openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
#openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
#openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid 032198f4-b815-4254-9de2-185f935bd7de
#
#openstack-config --set /etc/nova/nova.conf libvirt disk_cachemodes \"network=writeback\"
#openstack-config --set /etc/nova/nova.conf libvirt inject_password false
#openstack-config --set /etc/nova/nova.conf libvirt inject_key false
#openstack-config --set /etc/nova/nova.conf libvirt inject_partition  -2
#openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"

service openstack-glance-api restart
service openstack-cinder-volume restart
service openstack-cinder-backup restart
