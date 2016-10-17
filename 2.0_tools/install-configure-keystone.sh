#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=keystone_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
sh_name_1=httpd_keystone_conf_configure.sh
source_sh_1=$(echo `pwd`)/sh/$sh_name_1
sh_name_2=keystone_openrc.sh
source_sh_2=$(echo `pwd`)/sh/$sh_name_2
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone
source_cfg_1=$(echo `pwd`)/sh/conf/wsgi-keystone.conf

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'controller01' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen keystone_admin_cluster
    bind $virtual_ip:35357
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:35357 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;
  
echo "listen keystone_public_internal_cluster
    bind $virtual_ip:5000
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:5000 check inter 2000 rise 2 fall 5" >>$target_cfg
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

### [任一节点/controller01]初始化Fernet key，并共享给其他节点
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
for ((i=1; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
	ssh root@$ip mkdir -p /etc/keystone/fernet-keys/
        scp /etc/keystone/fernet-keys/* root@$ip:/etc/keystone/fernet-keys/
	ssh root@$ip chown keystone:keystone /etc/keystone/fernet-keys/*
  done;

##### scp httpd.conf wsgi-keystone.conf

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        scp $source_cfg_1 root@$ip:/etc/httpd/conf.d/wsgi-keystone.conf
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh_1 root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name_1 $local_nic
	ssh root@$ip chown -R keystone:keystone /var/log/keystone/*
  done;
### [任一节点]生成数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone
### [任一节点]添加pacemaker资源，openstack资源和haproxy资源无关，可以开启A/A模式
pcs resource create  openstack-keystone systemd:httpd --clone interleave=true

echo "Pcs cluster is restarting! If is stuck, please type Ctrl+C to terminate and it'll continue!"
. restart-pcs-cluster.sh

### [任一节点]设置临时环境变量
export OS_TOKEN=3e9cffc84608cc62cca5
export OS_URL=http://$virtual_ip:35357/v3
export OS_IDENTITY_API_VERSION=3

### [任一节点]service entity and API endpoints
openstack service create --name keystone --description "OpenStack Identity" identity

openstack endpoint create --region RegionOne identity public http://$virtual_ip:5000/v3
openstack endpoint create --region RegionOne identity internal http://$virtual_ip:5000/v3
openstack endpoint create --region RegionOne identity admin http://$virtual_ip:35357/v3

### [任一节点]创建项目和用户
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password $password_openstack_admin admin
openstack role create admin
openstack role add --project admin --user admin admin

### [任一节点]创建service项目
openstack project create --domain default --description "Service Project" service

### check
openstack service list
openstack endpoint list
openstack project list

### openrc.sh
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh_2 root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name_2 $virtual_ip $password
  done;
/root/keystonerc_admin
openstack endpoint list
openstack service list
