#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=neutron_install_configure_controller.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'controller01' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen neutron_api_cluster
    bind $virtual_ip:9696
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:9696 check inter 2000 rise 2 fall 5" >>$target_cfg
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
        ssh root@$ip $target_sh/$sh_name $virtual_ip $password
  done;
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
echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh
. /root/keystonerc_admin
neutron ext-list
