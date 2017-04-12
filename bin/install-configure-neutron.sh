#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Neutron Installation"

### [所有控制节点] 修改/etc/haproxy/haproxy.cfg文件
. ./1-gen-haproxy-cfg.sh neutron

###[所有控制节点] 安装配置 
./pssh-exe C "yum install -y openstack-neutron openstack-neutron-ml2 python-neutronclient"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $ip
    openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$password@$virtual_ip/neutron
    openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
    openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
    openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
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
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$virtual_ip:35357
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
    openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password
    openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
    openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
    openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$virtual_ip:35357
    openstack-config --set /etc/neutron/neutron.conf nova auth_type password
    openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
    openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
    openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
    openstack-config --set /etc/neutron/neutron.conf nova project_name service
    openstack-config --set /etc/neutron/neutron.conf nova username nova
    openstack-config --set /etc/neutron/neutron.conf nova password $password
    openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan,gre
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
    openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver iptables_hybrid
    openstack-config --set /etc/nova/nova.conf neutron url http://$virtual_ip:9696
    openstack-config --set /etc/nova/nova.conf neutron auth_url http://$virtual_ip:35357
    openstack-config --set /etc/nova/nova.conf neutron auth_type password
    openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
    openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
    openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
    openstack-config --set /etc/nova/nova.conf neutron project_name service
    openstack-config --set /etc/nova/nova.conf neutron username neutron
    openstack-config --set /etc/nova/nova.conf neutron password $password
    openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
    openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $password
    ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
    systemctl restart openstack-nova-api.service openstack-nova-scheduler.service openstack-nova-conductor.service
EOF
done;
### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'controller01' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"
### [任一节点]创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://$virtual_ip:9696
openstack endpoint create --region RegionOne network internal http://$virtual_ip:9696
openstack endpoint create --region RegionOne network admin http://$virtual_ip:9696
### [任一节点]生成数据库
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
### [任一节点]添加pacemaker资源
pcs resource create neutron-server systemd:neutron-server op start timeout=300 --clone interleave=true
pcs constraint order start openstack-keystone-clone then neutron-server-clone
pcs resource op add neutron-server start timeout=300
pcs resource op add neutron-server stop timeout=300
### [任一节点]测试
. restart-pcs-cluster.sh
. /root/keystonerc_admin
neutron ext-list
### [网络节点] 安装网络高可用集群
. install-configure-pacemaker-networkers.sh
. install-configure-neutron-networkers.sh
### [任一节点]测试
. /root/keystonerc_admin
neutron agent-list
