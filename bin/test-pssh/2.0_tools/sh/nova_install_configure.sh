#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
password=$3
 
echo $vip $local_nic
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler
### [所有控制节点]配置配置nova组件，/etc/nova/nova.conf文件 
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$password@$vip/nova_api
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$password@$vip/nova

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

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9292

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

