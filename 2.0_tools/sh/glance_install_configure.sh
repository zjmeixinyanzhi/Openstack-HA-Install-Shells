#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
password=$3 
echo $vip $local_nic
yum install -y openstack-glance

### [所有控制节点]配置/etc/glance/glance-api.conf文件
openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$password@$vip/glance

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password $password

openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone

openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host $vip
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
### [所有控制节点]配置/etc/glance/glance-registry.conf文件 
openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$password@$vip/glance

openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password $password

openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone

openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/glance/glance-registry.conf oslo_messaging_rabbit rabbit_durable_queues true

openstack-config --set /etc/glance/glance-registry.conf DEFAULT registry_host $vip
openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)


