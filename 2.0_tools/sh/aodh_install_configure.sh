vip='192.168.2.201'
vip=$1
local_bridge='br-ex'
local_bridge=$2
password=$3
### [所有控制节点] 安装软件
yum install -y openstack-aodh-api openstack-aodh-evaluator openstack-aodh-notifier openstack-aodh-listener openstack aodh-expirer python-ceilometerclient
### [所有控制节点] 修改配置文件
openstack-config --set /etc/aodh/aodh.conf database connection mysql+pymysql://aodh:$password@$vip/aodh
openstack-config --set /etc/aodh/aodh.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/aodh/aodh.conf oslo_messaging_rabbit rabbit_password $password
openstack-config --set /etc/aodh/aodh.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_name service
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken username aodh
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken password $password
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_type password
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_url http://$vip:5000/v3
openstack-config --set /etc/aodh/aodh.conf service_credentials project_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials user_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials project_name service
openstack-config --set /etc/aodh/aodh.conf service_credentials username aodh
openstack-config --set /etc/aodh/aodh.conf service_credentials password $password
openstack-config --set /etc/aodh/aodh.conf service_credentials interface internalURL
openstack-config --set /etc/aodh/aodh.conf service_credentials region_name RegionOne
openstack-config --set /etc/aodh/aodh.conf api host $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

