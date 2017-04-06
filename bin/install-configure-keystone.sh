#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Keystone Installation"

### [所有控制节点] 修改/etc/haproxy/haproxy.cfg文件
. ./1-gen-haproxy-cfg.sh keystone
### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -e "CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'controller01' IDENTIFIED BY '"$password"';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '"$password"';
FLUSH PRIVILEGES;"

##### [所有控制节点]安装软件
./pssh-exe C "yum install -y openstack-keystone httpd mod_wsgi"
### [所有控制节点] 配置/etc/keystone/keystone.conf文件
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token 3e9cffc84608cc62cca5"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:$password@$virtual_ip/keystone"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf token provider fernet"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues true"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_interval 1"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_backoff 2"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_max_retries 0"
./pssh-exe C "openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_durable_queues true"
### [任一节点/controller01]初始化Fernet key，并共享给其他节点
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
./pssh-exe C "mkdir -p /etc/keystone/fernet-keys/"
./scp-exe C /etc/keystone/fernet-keys/ /etc/keystone/
./pssh-exe C "chown keystone:keystone /etc/keystone/fernet-keys/*"
##### scp httpd.conf wsgi-keystone.conf
./scp-exe C ../conf/wsgi-keystone.conf /etc/httpd/conf.d/wsgi-keystone.conf
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  ssh $ip /bin/bash << EOF
  sed -i -e 's#\#ServerName www.example.com:80#ServerName '"$name"'#g' /etc/httpd/conf/httpd.conf
  sed -i -e 's#0.0.0.0#'"$ip"'#g' /etc/httpd/conf.d/wsgi-keystone.conf
  chown -R keystone:keystone /var/log/keystone/*
EOF
done;
### [任一节点]生成数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone
### [任一节点]添加pacemaker资源，openstack资源和haproxy资源无关，可以开启A/A模式
pcs resource create  openstack-keystone systemd:httpd --clone interleave=true
pcs resource op add openstack-keystone start timeout=300
pcs resource op add openstack-keystone stop timeout=300
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
openstack role create user
openstack role add --project admin --user admin admin
### [任一节点]创建service项目
openstack project create --domain default --description "Service Project" service
### check
openstack service list
openstack endpoint list
openstack project list
### [所有控制节点]编辑/etc/keystone/keystone-paste.ini
./pssh-exe C "sed -i -e 's#admin_token_auth ##g' /etc/keystone/keystone-paste.ini"
unset OS_TOKEN OS_URL
###[所有控制节点] create openrc.sh
\cp ../conf/keystonerc_admin.template ../conf/keystonerc_admin
sed -i -e 's#OS_PASSWORD=#OS_PASSWORD='"$password_openstack_admin"'#g' ../conf/keystonerc_admin
sed -i -e 's#OS_AUTH_URL=#OS_AUTH_URL=http://'"$virtual_ip"':35357/v3#g' ../conf/keystonerc_admin
./scp-exe C "../conf/keystonerc_admin" "/root/keystonerc_admin"
./pssh-exe C "chmod +x /root/keystonerc_admin" 
./style/print-info.sh "Please re-login!"
curr_dir=$(echo `pwd`)
ssh `hostname` cd $curr_dir
. /root/keystonerc_admin
openstack token issue
