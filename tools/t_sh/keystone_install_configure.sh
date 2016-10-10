#!/bin/sh
vip='192.168.2.201'
vip=$1
 
echo $vip
yum install -y openstack-keystone httpd mod_wsgi

openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token 3e9cffc84608cc62cca5
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:123456@$vip/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet

openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_durable_queues true

