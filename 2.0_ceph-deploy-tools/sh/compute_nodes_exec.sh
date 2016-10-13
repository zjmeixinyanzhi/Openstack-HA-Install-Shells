#!/bin/sh
vip=$1
local_nic=$2
data_nic=$3
password=$4

yum install -y centos-release-openstack-mitaka
yum install -y python-openstackclient openstack-selinux openstack-utils
### 1. OpenStack Compute service
yum install -y openstack-nova-compute

### 修改配置文件/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller01:11211,controller02:11211,controller03:11211

openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $password

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$vip:6080/vnc_auto.html

openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9292
openstack-config --set /etc/nova/nova.conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)


### 打开虚拟机迁移的监听端口
sed -i -e "s#\#listen_tls *= *0#listen_tls = 0#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#listen_tcp *= *1#listen_tcp = 1#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#auth_tcp *= *\"sasl\"#auth_tcp = \"none\"#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#LIBVIRTD_ARGS *= *\"--listen\"#LIBVIRTD_ARGS=\"--listen\"#g" /etc/sysconfig/libvirtd

###启动服务
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

#### 2. OpenStack Network service
### 安装组件
yum install -y openstack-neutron-openvswitch
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
### 修改/etc/neutron/neutron.conf

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

### 配置Open vSwitch agent，/etc/neutron/plugins/ml2/openvswitch_agent.ini，注意，此处填写第二块网卡
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $(ip addr show dev $data_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population False

### 配置nova和neutron集成，/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://$vip:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $password

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

systemctl restart openstack-nova-compute.service
systemctl start openvswitch.service
systemctl restart neutron-openvswitch-agent.service


### 3. OpenStack Block Storage service
###计算节点安装客户端命令行工具
yum install -y ceph-common


echo "<secret ephemeral='no' private='no'>
  <uuid>032198f4-b815-4254-9de2-185f935bd7de</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>">secret.xml
virsh secret-define --file secret.xml
virsh secret-set-value --secret 032198f4-b815-4254-9de2-185f935bd7de --base64 $(cat /etc/ceph/ceph.client.cinder.keyring |grep 'key ='|awk '{print $3}') && rm client.cinder.key secret.xml

echo "[client]
rbd cache = true
rbd cache writethrough until flush = true
admin socket = /var/run/ceph/guests/\$cluster-\$type.\$id.\$pid.\$cctid.asok
log file = /var/log/qemu/qemu-guest-\$pid.log
rbd concurrent management ops = 20">> /etc/ceph/ceph.conf

###设置路径权限
mkdir -p /var/run/ceph/guests/ /var/log/qemu/
chown ceph:ceph /var/run/ceph/guests /var/log/qemu/
###设置/etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool vms
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid $(virsh secret-list| grep ceph| awk '{print $1}') 
openstack-config --set /etc/nova/nova.conf libvirt disk_cachemodes \"network=writeback\"
openstack-config --set /etc/nova/nova.conf libvirt inject_password false
openstack-config --set /etc/nova/nova.conf libvirt inject_key false
openstack-config --set /etc/nova/nova.conf libvirt inject_partition  -2
openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"

service openstack-nova-compute restart

### 4. OpenStack Ceilomerter service
###[在计算节点上配置]
yum install -y openstack-ceilometer-compute python-ceilometerclient python-pecan

###[在计算节点上配置]
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/ceilometer/ceilometer.conf oslo_messaging_rabbit rabbit_password $password
openstack-config --set /etc/ceilometer/ceilometer.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$vip:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials password $password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials region_name RegionOne
### 配置nova使用ceilometer服务
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit True
openstack-config --set /etc/nova/nova.conf DEFAULT instance_usage_audit_period hour
openstack-config --set /etc/nova/nova.conf DEFAULT notify_on_state_change vm_and_task_state
openstack-config --set /etc/nova/nova.conf DEFAULT notification_driver messagingv2

###启动服务
systemctl enable openstack-ceilometer-compute.service
systemctl start openstack-ceilometer-compute.service
systemctl restart openstack-nova-compute.service

