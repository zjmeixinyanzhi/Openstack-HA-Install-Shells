#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Ceilometer Installation"
### 所有控制节点安装mongodb
./pssh-exe C "yum install -y openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstack-ceilometer-central python-ceilometerclient redis python-redis"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    sed -i "s/\s*bind \(.*\)$/#bind \1/" /etc/redis.conf
    ### [所有控制节点] 修改配置文件
    openstack-config --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$password_mongo_root@controller01:27017,controller02:27017,controller03:27017/ceilometer?replicaSet=ceilometer
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
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://$virtual_ip:35357
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
    openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $password
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_type password
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$virtual_ip:5000/v3
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials password $password
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
    openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials region_name RegionOne
    # keep last 5 days data only (value is in secs). Don't set to retain all data indefinetely.
    openstack-config --set /etc/ceilometer/ceilometer.conf database metering_time_to_live 432000
    openstack-config --set /etc/ceilometer/ceilometer.conf coordination backend_url 'redis://'"$virtual_ip_redis"':6379'
    openstack-config --set /etc/ceilometer/ceilometer.conf api host $ip
    openstack-config --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret $password
EOF
done;
### [controller01] 新建数据库、用户名和权限
\cp ../conf/mongo_create_ceilometer_user-template.sh /tmp/mongodb_configure_ceilometer.sh
sed -i -e 's#123456#'"$password_mongo_root"'#g' /tmp/mongodb_configure_ceilometer.sh
./scp-exe C /tmp/mongodb_configure_ceilometer.sh /tmp/mongodb_configure_ceilometer.sh
./pssh-exe C ". /tmp/mongodb_configure_ceilometer.sh" 
##### generate haproxy.cfg
. ./1-gen-haproxy-cfg.sh ceilometer
### [controller01] 创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer --description "Telemetry" metering
openstack endpoint create --region RegionOne metering public http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering internal http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering admin http://$virtual_ip:8777
