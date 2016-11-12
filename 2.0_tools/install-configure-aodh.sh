#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=aodh_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard.cinder.ceilometer
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard.cinder.ceilometer.aodh

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE aodh;
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'localhost' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'controller01' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON aodh.* TO 'aodh'@'%' IDENTIFIED BY '$password';
FLUSH PRIVILEGES;"

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen aodh_api_cluster
    bind $virtual_ip:8042
    balance source
    option tcpka
    option tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:8042 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;
  
##### scp haproxy.cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        scp $target_cfg root@$ip:/etc/haproxy/haproxy.cfg
	ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $password
  done;


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

echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh

