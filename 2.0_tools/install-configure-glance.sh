#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=glance_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/
test_img=$(echo `pwd`)/sh/img/cirros-0.3.4-x86_64-disk.img

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'controller01' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen glance_api_cluster
    bind $virtual_ip:9292
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:9292 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;
  
echo "listen glance_registry_cluster
    bind $virtual_ip:9191
    balance  source
    option  tcpka
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:9191 check inter 2000 rise 2 fall 5" >>$target_cfg
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

echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh

### [任一节点]添加测试镜像
. /root/keystonerc_admin
openstack image create "cirros" --file $test_img --disk-format qcow2 --container-format bare --public
openstack image list
