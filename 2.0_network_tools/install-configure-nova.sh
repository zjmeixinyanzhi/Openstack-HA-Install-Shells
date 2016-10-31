#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=nova_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/
test_img=$(echo `pwd`)/sh/img/cirros-0.3.4-x86_64-disk.img

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova

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


##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen nova_compute_api_cluster
    bind $virtual_ip:8774
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog
">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:8774 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;
  
echo "listen nova_metadata_api_cluster
    bind $virtual_ip:8775
    balance  source
    option  tcpka
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:8775 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;
echo "listen nova_vncproxy_cluster
    bind $virtual_ip:6080
    balance  source
    option  tcpka
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:6080 check inter 2000 rise 2 fall 5" >>$target_cfg
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

echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh

### [任一节点]测试
sleep 10
. /root/keystonerc_admin
openstack compute service list
