#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=cinder_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard.cinder

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
  IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'controller01' \
  IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
  IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen cinder_api_cluster
    bind $virtual_ip:8776
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:8776 check inter 2000 rise 2 fall 5" >>$target_cfg
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
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_bridge $password
  done;
### [任一节点]创建用户等
. /root/keystonerc_admin
### [任一节点]创建用户等
openstack user create --domain default --password $password cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder  --description "OpenStack Block Storage" volume
openstack service create --name cinderv2  --description "OpenStack Block Storage" volumev2
###创建cinder服务的API endpoints
openstack endpoint create --region RegionOne   volume public http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne   volume internal http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne   volume admin http://$virtual_ip:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne   volumev2 public http://$virtual_ip:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne   volumev2 internal http://$virtual_ip:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne   volumev2 admin http://$virtual_ip:8776/v2/%\(tenant_id\)s


### [任一节点]生成数据库
su -s /bin/sh -c "cinder-manage db sync" cinder
### [任一节点]添加pacemaker资源
pcs resource create openstack-cinder-api systemd:openstack-cinder-api --clone interleave=true
pcs resource create openstack-cinder-scheduler systemd:openstack-cinder-scheduler --clone interleave=true
pcs resource create openstack-cinder-volume systemd:openstack-cinder-volume

pcs constraint order start openstack-keystone-clone then openstack-cinder-api-clone
pcs constraint order start openstack-cinder-api-clone then openstack-cinder-scheduler-clone
pcs constraint colocation add openstack-cinder-scheduler-clone with openstack-cinder-api-clone
pcs constraint order start openstack-cinder-scheduler-clone then openstack-cinder-volume
pcs constraint colocation add openstack-cinder-volume with openstack-cinder-scheduler-clone

echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh
