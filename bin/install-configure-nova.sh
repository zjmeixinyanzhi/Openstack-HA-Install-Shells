#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Nova Installation"

### [所有控制节点] 修改/etc/haproxy/haproxy.cfg文件
. ./1-gen-haproxy-cfg.sh nova
##[所有控制节点]安装配置
./pssh-exe C "yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
    openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$password@$virtual_ip/nova_api
    openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$password@$virtual_ip/nova
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
    openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$virtual_ip:35357
    openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
    openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
    openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
    openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
    openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
    openstack-config --set /etc/nova/nova.conf keystone_authtoken password $password
    openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $ip
    openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
    openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
    openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $ip
    openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $ip
    openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $ip
    openstack-config --set /etc/nova/nova.conf glance api_servers http://$virtual_ip:9292
    openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
    openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $ip
    openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $ip
EOF
done;

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'controller01' IDENTIFIED BY '"$password"';
CREATE DATABASE nova_api;
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'controller01' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"
### [任一节点]创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://$virtual_ip:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://$virtual_ip:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://$virtual_ip:8774/v2.1/%\(tenant_id\)s
### [任一节点]生成数据库
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova
### [任一节点]添加pacemaker资源
pcs resource create openstack-nova-consoleauth systemd:openstack-nova-consoleauth --clone interleave=true
pcs resource create openstack-nova-novncproxy systemd:openstack-nova-novncproxy --clone interleave=true
pcs resource create openstack-nova-api systemd:openstack-nova-api --clone interleave=true
pcs resource create openstack-nova-scheduler systemd:openstack-nova-scheduler --clone interleave=true
pcs resource create openstack-nova-conductor systemd:openstack-nova-conductor --clone interleave=true
pcs constraint order start openstack-keystone-clone then openstack-nova-consoleauth-clone
pcs constraint order start openstack-nova-consoleauth-clone then openstack-nova-novncproxy-clone
pcs constraint colocation add openstack-nova-novncproxy-clone with openstack-nova-consoleauth-clone
pcs constraint order start openstack-nova-novncproxy-clone then openstack-nova-api-clone
pcs constraint colocation add openstack-nova-api-clone with openstack-nova-novncproxy-clone
pcs constraint order start openstack-nova-api-clone then openstack-nova-scheduler-clone
pcs constraint colocation add openstack-nova-scheduler-clone with openstack-nova-api-clone
pcs constraint order start openstack-nova-scheduler-clone then openstack-nova-conductor-clone
pcs constraint colocation add openstack-nova-conductor-clone with openstack-nova-scheduler-clone
pcs resource op add openstack-nova-consoleauth start timeout=300
pcs resource op add openstack-nova-consoleauth stop timeout=300
pcs resource op add openstack-nova-novncproxy start timeout=300
pcs resource op add openstack-nova-novncproxy stop timeout=300
pcs resource op add openstack-nova-api start timeout=300
pcs resource op add openstack-nova-api stop timeout=300
pcs resource op add openstack-nova-scheduler start timeout=300
pcs resource op add openstack-nova-scheduler stop timeout=300
pcs resource op add openstack-nova-conductor start timeout=300
pcs resource op add openstack-nova-conductor stop timeout=300
### 重启Pcs集群
. restart-pcs-cluster.sh
### [任一节点]测试
sleep 5
. /root/keystonerc_admin
openstack compute service list
