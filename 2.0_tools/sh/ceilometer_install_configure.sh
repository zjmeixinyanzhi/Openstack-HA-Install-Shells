#!/bin/sh
vip='192.168.2.201'
vip=$1
vip2='192.168.2.202'
vip2=$2
local_bridge='br-ex'
local_bridge=$3
password=$4

### [所有控制节点] 安装软件
yum install -y openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central python-ceilometerclient redis python-redis
### [所有控制节点] 配置redis
sed -i "s/\s*bind \(.*\)$/#bind \1/" /etc/redis.conf
### [所有控制节点] 修改配置文件
openstack-config --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$password@controller01:27017,controller02:27017,controller03:27017/ceilometer?replicaSet=ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf database max_retries -1
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
# keep last 5 days data only (value is in secs). Don't set to retain all data indefinetely.
openstack-config --set /etc/ceilometer/ceilometer.conf database metering_time_to_live 432000
openstack-config --set /etc/ceilometer/ceilometer.conf coordination backend_url 'redis://'"$vip2"':6379'
openstack-config --set /etc/ceilometer/ceilometer.conf api host $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1) 
openstack-config --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret $password
