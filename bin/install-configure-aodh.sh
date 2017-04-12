#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Aodh Installation"

### [所有控制节点] 安装软件
./pssh-exe C "yum install -y openstack-aodh-api openstack-aodh-evaluator openstack-aodh-notifier openstack-aodh-listener openstack aodh-expirer python-ceilometerclient"
### [所有控制节点] 修改配置文件
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  . style/print-info.sh "Openstack configure in $name"
  ssh root@$ip /bin/bash << EOF
    openstack-config --set /etc/aodh/aodh.conf database connection mysql+pymysql://aodh:$password@$virtual_ip/aodh
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
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_uri http://$virtual_ip:5000
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_url http://$virtual_ip:35357
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_name service
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken username aodh
    openstack-config --set /etc/aodh/aodh.conf keystone_authtoken password $password
    openstack-config --set /etc/aodh/aodh.conf service_credentials auth_type password
    openstack-config --set /etc/aodh/aodh.conf service_credentials auth_url http://$virtual_ip:5000/v3
    openstack-config --set /etc/aodh/aodh.conf service_credentials project_domain_name default
    openstack-config --set /etc/aodh/aodh.conf service_credentials user_domain_name default
    openstack-config --set /etc/aodh/aodh.conf service_credentials project_name service
    openstack-config --set /etc/aodh/aodh.conf service_credentials username aodh
    openstack-config --set /etc/aodh/aodh.conf service_credentials password $password
    openstack-config --set /etc/aodh/aodh.conf service_credentials interface internalURL
    openstack-config --set /etc/aodh/aodh.conf service_credentials region_name RegionOne
    openstack-config --set /etc/aodh/aodh.conf api host $ip
EOF
done;
### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE aodh;
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'controller01' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY '$password';
FLUSH PRIVILEGES;"
##### generate haproxy.cfg
. ./1-gen-haproxy-cfg.sh aodh
### [controller01] 初始化数据库
su -s /bin/sh -c "aodh-dbsync" aodh
### [controller01] 创建用户、服务实体、端点
. /root/keystonerc_admin
openstack user create --domain default --password $password aodh
openstack role add --project service --user aodh admin
openstack service create --name aodh --description "Telemetry" alarming
openstack endpoint create --region RegionOne alarming public http://$virtual_ip:8042
openstack endpoint create --region RegionOne alarming internal http://$virtual_ip:8042
openstack endpoint create --region RegionOne alarming admin http://$virtual_ip:8042
### [controller01] 添加资源
pcs resource create redis redis wait_last_known_master=true --master meta notify=true ordered=true interleave=true
pcs resource create vip-redis IPaddr2 ip=$virtual_ip_redis
pcs resource create openstack-ceilometer-central systemd:openstack-ceilometer-central --clone interleave=true
pcs resource create openstack-ceilometer-collector systemd:openstack-ceilometer-collector --clone interleave=true
pcs resource create openstack-ceilometer-api systemd:openstack-ceilometer-api --clone interleave=true
pcs resource create delay Delay startdelay=10 --clone interleave=true
pcs resource create openstack-aodh-evaluator systemd:openstack-aodh-evaluator --clone interleave=true
pcs resource create openstack-aodh-notifier systemd:openstack-aodh-notifier --clone interleave=true
pcs resource create openstack-aodh-api systemd:openstack-aodh-api --clone interleave=true
pcs resource create openstack-aodh-listener systemd:openstack-aodh-listener --clone interleave=true
pcs resource create openstack-ceilometer-notification systemd:openstack-ceilometer-notification --clone interleave=true
pcs constraint order promote redis-master then start vip-redis
pcs constraint colocation add vip-redis with master redis-master
pcs constraint order start vip-redis then openstack-ceilometer-central-clone kind=Optional
pcs constraint order start mongod-clone then openstack-ceilometer-central-clone
pcs constraint order start openstack-keystone-clone then openstack-ceilometer-central-clone
pcs constraint order start openstack-ceilometer-central-clone then openstack-ceilometer-collector-clone
pcs constraint order start openstack-ceilometer-collector-clone then openstack-ceilometer-api-clone
pcs constraint colocation add openstack-ceilometer-api-clone with openstack-ceilometer-collector-clone
pcs constraint order start openstack-ceilometer-api-clone then delay-clone
pcs constraint colocation add delay-clone with openstack-ceilometer-api-clone
pcs constraint order start delay-clone then openstack-aodh-evaluator-clone
pcs constraint order start openstack-aodh-evaluator-clone then openstack-aodh-notifier-clone
pcs constraint order start openstack-aodh-notifier-clone then openstack-aodh-api-clone
pcs constraint order start openstack-aodh-api-clone then openstack-aodh-listener-clone
pcs constraint order start openstack-aodh-api-clone then openstack-ceilometer-notification-clone
pcs resource op add openstack-ceilometer-central start timeout=300
pcs resource op add openstack-ceilometer-central stop timeout=300
pcs resource op add openstack-ceilometer-collector start timeout=300
pcs resource op add openstack-ceilometer-collector stop timeout=300
pcs resource op add openstack-ceilometer-api start timeout=300
pcs resource op add openstack-ceilometer-api stop timeout=300
pcs resource op add delay start timeout=300
pcs resource op add delay stop timeout=300
pcs resource op add openstack-aodh-evaluator start timeout=300
pcs resource op add openstack-aodh-evaluator stop timeout=300
pcs resource op add openstack-aodh-notifier start timeout=300
pcs resource op add openstack-aodh-notifier stop timeout=300
pcs resource op add openstack-aodh-api start timeout=300
pcs resource op add openstack-aodh-api stop timeout=300
pcs resource op add openstack-aodh-listener start timeout=300
pcs resource op add openstack-aodh-listener stop timeout=300
pcs resource op add openstack-ceilometer-notification start timeout=300
pcs resource op add openstack-ceilometer-notification stop timeout=300
pcs resource op add mongod start timeout=300
pcs resource op add mongod stop timeout=300
. restart-pcs-cluster.sh
### [任意节点] 测试数据收集 
ceilometer meter-list
