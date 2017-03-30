#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Glance Installation"
test_img=../conf/cirros.raw

### [所有控制节点] 修改/etc/haproxy/haproxy.cfg文件
. ./1-gen-haproxy-cfg.sh glance
### 安装配置
./pssh-exe C "yum install -y openstack-glance"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$password@$virtual_ip/glance
    openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$virtual_ip:35357
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
    openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host $virtual_ip
    openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host $ip
    openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$password@$virtual_ip/glance
    openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$virtual_ip:35357
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
    openstack-config --set /etc/glance/glance-registry.conf DEFAULT registry_host $virtual_ip
    openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host $ip
EOF
done;

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'controller01' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"
### [任一节点]创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://$virtual_ip:9292
openstack endpoint create --region RegionOne image internal http://$virtual_ip:9292
openstack endpoint create --region RegionOne image admin http://$virtual_ip:9292
### [任一节点]生成数据库
su -s /bin/sh -c "glance-manage db_sync" glance
### [任一节点]添加pacemaker资源
pcs resource create openstack-glance-registry systemd:openstack-glance-registry --clone interleave=true
pcs resource create openstack-glance-api systemd:openstack-glance-api --clone interleave=true
pcs constraint order start openstack-keystone-clone then openstack-glance-registry-clone
pcs constraint order start openstack-glance-registry-clone then openstack-glance-api-clone
pcs constraint colocation add openstack-glance-api-clone with openstack-glance-registry-clone
pcs resource op add openstack-glance-registry start timeout=300
pcs resource op add openstack-glance-registry stop timeout=300
pcs resource op add openstack-glance-api start timeout=300
pcs resource op add openstack-glance-api stop timeout=300
### 重启Pcs集群
. restart-pcs-cluster.sh
### [任一节点]添加测试镜像
. /root/keystonerc_admin
openstack image create "cirros" --file $test_img --disk-format raw --container-format bare --public
openstack image list
openstack image delete cirros
