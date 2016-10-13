### 修改部署环境的配置文件  0-set-config.sh
#!/bin/sh
### 设置部署节点主机名和IP，nodes_map为全部节点、controller_map为三个控制节点、hypervisor_map为计算节点（与存储节点融合）
declare -A nodes_map=(["controller01"]="192.168.2.101" ["controller02"]="192.168.2.102" ["controller03"]="192.168.2.103" ["compute01"]="192.168.2.104" ["compute02"]="192.168.2.105" ["compute03"]="192.168.2.106" );
declare -A controller_map=(["controller01"]="192.168.2.101" ["controller02"]="192.168.2.102" ["controller03"]="192.168.2.103");
declare -A hypervisor_map=(["compute01"]="192.168.2.104" ["compute02"]="192.168.2.105" ["compute03"]="192.168.2.106");
### 设置虚拟IP，virtual_ip为openstack服务的虚拟IP，virtual_ip_redis为Redis为虚拟IP
virtual_ip=192.168.2.211
virtual_ip_redis=192.168.2.212
### 设置网卡信息 local_nic为管理网网卡名称 data_nic为虚拟网网卡名称 storage_nic为存储网网卡信息 local_bridge为外网网桥名称
local_nic=eno16777736
data_nic=eno50332184
storage_nic=eno33554960
local_bridge=br-ex
### 设置网络网段信息，分别对应管理网、虚拟网、存储网
local_network=192.168.2.0/24
data_network=10.10.10.0/24
store_network=11.11.11.0/24
### Openstack各组件的密码，所有服务统一成一个
password=Gugong123
### 离线安装源的FTP目录信息
ftp_info="ftp://192.168.100.81/pub/"


##############################################
#########       测试网络连通性   #############
##############################################
### test-network.sh

#!/bin/sh
nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      echo ">>>>>>>"
      ping -c 2 $ip
      echo ">>>>>>>"
      ping -c 2 $(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      echo ">>>>>>>"
      ping -c 2 $(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;
  
  
sed -i -e 's#'"$(echo $data_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' /etc/hosts


 #############################################
 ########       设置SSH          #############
 #############################################
###set-ssh-nodes.sh

#!/bin/sh
nodes_name=(${!nodes_map[@]});

ssh-keygen
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;
 
 #############################################
 ########     修改网卡配置文件       #############
 #############################################
 
 ####3 修改所有节点上配置文件内容
 ####修改网卡配置文件，设置开启启动, 网卡需要统一命名

### 修改操作 sh/network-config-exec.sh
#!/bin/sh
local_nic=$1
data_nic=$2
storage_nic=$3

sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$local_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic 

### scp到其他节点 执行操作 set-network-config.sh

#!/bin/sh
local_nic=$1
data_nic=$2
storage_nic=$3

sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$local_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$data_nic
sed -i -e 's#ONBOOT=no#ONBOOT=yes#g'  /etc/sysconfig/network-scripts/ifcfg-$storage_nic

  
 #############################################
 ########      设置主机名        #############
 #############################################

 ### set-hostname.sh
#!/bin/sh

nodes_name=(${!nodes_map[@]});

tmp_file=/etc/hosts.bak
target=/etc/hosts
rm -rf  $tmp_file
### generate host file
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "$ip $name">>$tmp_file
  done;
### scp to other nodes
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ###set hostname
      ssh root@$ip hostnamectl --static set-hostname $name
      scp /etc/hosts.bak root@$ip:/etc/hosts
  done;
### check
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ###ping hostname
      ping -c 2 $name
      ssh root@$ip hostname
  done

 ############################################
 ########5 关闭防火墙禁用SELinux#############
 ############################################

 
#####可执行脚本  disable_selinux_firewall.sh
 #!/bin/sh
systemctl disable firewalld.service
systemctl stop firewalld.service
sed -i -e "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sed -i -e "s#SELINUXTYPE=targeted#\#SELINUXTYPE=targeted#g" /etc/selinux/config

sestatus=$(sestatus -v |grep "SELinux status:"|awk '{print $3}')
echo $sestatus
if [ $sestatus = "enabled" ];then
  echo "Reboot now? (yes/no)"
  read flag
  if [ $flag = "yes" ];then
    echo "Reboot now!"
    reboot
  else
    echo "You should reboot manually!"
  fi
else
  echo "SELinux is disabled!"
fi
 
### scp到其他节点 执行脚本 cat disable_firewall_selinux.sh
 #!/bin/sh
nodes_name=(${!nodes_map[@]});
sh_name=disable_selinux_firewall.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      scp $source_sh root@$ip:$target_sh
      ssh root@$ip chmod -R +x $target_sh
      ssh root@$ip $target_sh/$sh_name
      ssh root@$ip systemctl status firewalld.service|grep  Active:
      ssh root@$ip sestatus -v
  done;


 ############################################
 ########     设置时间同步      #############
 ############################################
  
### 基本操作 sh/replace_ntp_hosts.sh
 #!/bin/sh
ref_host=$1
sed -i -e 's#server 0.centos.pool.ntp.org#server '"$ref_host"'#g'  /etc/chrony.conf
sed -i -e '/server [0 1 2 3].centos.pool.ntp.org/d'  /etc/chrony.conf

####set-chrony.sh 
#!/bin/sh
#### controller01
subnet=$local_network

ref_host=controller01

sh_name=replace_ntp_hosts.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path

nodes_name=(${!nodes_map[@]});

rm -rf result.log

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      if [ $name = $ref_host  ]; then
          echo ""$ip
          echo "allow "$subnet >>/etc/chrony.conf
      else
          ssh root@$ip mkdir -p $target_sh
          scp $source_sh root@$ip:$target_sh
          ssh root@$ip chmod +x $target_sh
          ssh root@$ip $target_sh/$sh_name $ref_host
      fi
      ssh root@$ip systemctl enable chronyd.service
      ssh root@$ip systemctl restart chronyd.service
      ssh root@$ip cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
      ssh root@$ip date +%z >>result.log
      ssh root@$ip chronyc sources>>result.log
  done;

  
 ############################################
 ########    制作本地软件源     #############
 ############################################
 
 
### 生成文件 ./sh/generate_repo.sh
#!/bin/sh

#base_location="ftp://192.168.100.81/pub/"
base_location=$1
target_dir=$2

echo $base_location $target_dir
###### centos.repo
echo "[centos-base]
name=centos-base
baseurl="$base_location"CentOS-7.2-X86_64/base
gpgcheck=0
enabled=1
# centos-extras reporisoty
[centos-extras]
name=centos-extras
baseurl="$base_location"CentOS-7.2-X86_64/extras
gpgcheck=0
enabled=1
# centos-updates reporisoty
[centos-updates]
name=centos-updates
baseurl="$base_location"CentOS-7.2-X86_64/updates
gpgcheck=0
enabled=1">$target_dir/centos.repo

###### openstack-mitaka.repo
echo "[openstack-mitaka]
name=openstack-mitaka
baseurl="$base_location"Openstack-Mitaka/openstack-mitaka/
gpgcheck=0
enabled=1
">$target_dir/openstack-mitaka.repo

##### Galera.repo
echo "# MariaDB 10.1 CentOS repository list
[mariadb]
name = MariaDB
baseurl = "$base_location"yum.mariadb.org/10.1/centos7-amd64
gpgcheck=0
">$target_dir/Galera.repo

##### ceph.repo
echo "[ceph-noarch]
name = Ceph noarch packages
baseurl = "$base_location"download.ceph.com/rpm-jewel/el7/noarch
gpgcheck=0
">$target_dir/ceph.repo

##### dl.fedoraproject.org_pub_epel_7_x86_64_.repo
echo "[dl.fedoraproject.org_pub_epel_7_x86_64_]
name=added from: dl.fedoraproject.org/pub/epel/7/x86_64//
baseurl="$base_location"dl.fedoraproject.org/pub/epel/7/x86_64//
enabled=1
gpgcheck=0
">$target_dir/dl.fedoraproject.org_pub_epel_7_x86_64_.repo



###scp到其他节点 set-local-yum-repos.sh 
#!/bin/sh
nodes_name=(${!nodes_map[@]});
base_location=$ftp_info

sh_name=generate_repo.sh
source_sh=$(echo `pwd`)/sh/$sh_name
yum_repos_dir=$(echo `pwd`)/sh/yum.repo/
target_sh=$tmp_path/bak/

echo $yum_repos_dir

#### generate yum repos in current node
$source_sh $base_location $yum_repos_dir

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      ssh root@$ip mv /etc/yum.repos.d/*.repo $target_sh
      scp -r $yum_repos_dir/* root@$ip:/etc/yum.repos.d/
      ssh root@$ip yum upgrade -y
  done;

 ############################################
 ########     安装Pacemaker     #############
 ############################################
 
#### 各节点需要执行的操作  ./sh/pcs_exec.sh

#!/bin/sh
 ### [所有控制节点] 安装软件
password=$1
yum install -y pcs pacemaker corosync fence-agents-all resource-agents
### [所有控制节点] 配置服务
systemctl enable pcsd
systemctl start pcsd
 ### [所有控制节点]设置hacluster用户的密码
echo $password | passwd --stdin hacluster


  
#### scp到其他节点 执行命令，部署pcs集群 install-configure-pacemaker.sh   

#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=pcs_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=$tmp_path

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $password

  done;
### [controller01]设置到集群节点的认证
pcs cluster auth $controller_list_space -u hacluster -p 123456 --force

### [controller01]创建并启动集群
pcs cluster setup --force --name openstack-cluster $controller_list_space
pcs cluster start --all

### [controller01]设置集群属性
pcs property set pe-warn-series-max=1000 pe-input-series-max=1000 pe-error-series-max=1000 cluster-recheck-interval=5min

### [controller01] 暂时禁用STONISH，否则资源无法启动
pcs property set stonith-enabled=false

### [controller01]配置VIP资源，VIP可以在集群节点间浮动
pcs resource create vip ocf:heartbeat:IPaddr2 params ip=$virtual_ip cidr_netmask="24" op monitor interval="30s"

 ############################################
 ########      安装Haproxy      #############
 ############################################
 
###所有控制节点上操作基本操作 ./sh/haproxy_exec.sh

#!/bin/sh
 ### [所有控制节点] 安装软件
yum install -y haproxy
### [所有控制节点] 修改/etc/rsyslog.d/haproxy.conf文件
echo "\$ModLoad imudp" >> /etc/rsyslog.d/haproxy.conf;
echo "\$UDPServerRun 514" >> /etc/rsyslog.d/haproxy.conf;
echo "local3.* /var/log/haproxy.log" >> /etc/rsyslog.d/haproxy.conf;
echo "&~" >> /etc/rsyslog.d/haproxy.conf;
### [所有控制节点] 修改/etc/sysconfig/rsyslog文件
sed -i -e 's#SYSLOGD_OPTIONS=\"\"#SYSLOGD_OPTIONS=\"-c 2 -r -m 0\"#g' /etc/sysconfig/rsyslog
### [所有控制节点] 重启rsyslog服务
systemctl restart rsyslog

#### scp到其他控制节点 进行执行  install-configure-haproxy.sh

#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=haproxy_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=$tmp_path
source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.base

####scp其他脚本执行操作
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
        scp $source_cfg root@$ip:/etc/haproxy/haproxy.cfg
  done;

### [controller01]在pacemaker集群增加haproxy资源
pcs resource create haproxy systemd:haproxy --clone
pcs constraint order start vip then haproxy-clone kind=Optional
pcs constraint colocation add haproxy-clone with vip
ping -c 3 $virtual_ip


 ############################################
 ########      安装Galera       #############
 ############################################

 ####所有控制节点上操作基本操作 ：安装、设置配置文件 （注意网卡设置，用来获取IP）galera_exec.sh
 
#!/bin/sh
local_nic='eno16777736'
local_nic=$1


echo $local_nic

yum install -y MariaDB-server xinetd

cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/bak.server.cnf

echo "[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
binlog_format=ROW
max_connections = 4096
bind-address= $(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)

default_storage_engine=innodb
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=122M

wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_provider_options=\"pc.recovery=TRUE;gcache.size=300M\"
wsrep_cluster_name=\"galera_cluster\"
wsrep_cluster_address=\"gcomm://controller01,controller02,controller03\"
wsrep_node_name= $(hostname)
wsrep_node_address= $(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)
wsrep_sst_method=rsync
"> /etc/my.cnf.d/server.cnf

#####生成haproxy.cfg scp到其他控制节点 执行以上操作，galera集群配置、vip登录验证  install-configure-galera.sh

#!/bin/sh
controller_name=(${!controller_map[@]});
controller_list_space=${!controller_map[@]};

sh_name=galera_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=$tmp_path

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.base
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen galera_cluster" >>$target_cfg
echo "    bind $virtual_ip:3306" >>$target_cfg
echo "    balance source" >>$target_cfg
echo "    option mysql-check user haproxy_check" >>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        if [ $i -eq 0 ]; then
                   echo $i
           echo "    server $name $ip:3306 inter 2000 rise 2 fall 5" >>$target_cfg
       else
           echo "    server $name $ip:3306 backup inter 2000 rise 2 fall 5" >>$target_cfg
       fi
  done;
##### scp
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        scp $target_cfg root@$ip:/etc/haproxy/haproxy.cfg
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $local_nic
  done;

#### controller01
galera_new_cluster

#### config galera

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        if [ $i -eq 0 ]; then
          echo "Please set the database password is "$password
          mysql_secure_installation
       else
         ssh root@$ip systemctl start mariadb
         #ssh root@$ip mysql_secure_installation
       fi
  done;
#### check
mysql -uroot -p$password -e "use mysql;INSERT INTO user(Host, User) VALUES('"$virtual_ip"', 'haproxy_check');FLUSH PRIVILEGES;"
mysql -uroot -p -h $virtual_ip -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

 ############################################
 ########      安装rabbit       #############
 ############################################

###### install-configure-rabbitmq.sh

#!/bin/sh
controller_name=(${!controller_map[@]});
controller_0=${controller_name[0]};
controller_list_space=${!controller_map[@]};
echo $controller_0

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip yum install -y rabbitmq-server;
                ssh root@$ip systemctl start rabbitmq-server.service
        ssh root@$ip rabbitmqctl add_user openstack $password;
                ssh root@$ip rabbitmqctl set_permissions openstack \".*\" \".*\" \".*\";
                ssh root@$ip systemctl stop rabbitmq-server.service
  done;
### [controlloer01] 拷贝cookie文件到其他节点
systemctl start rabbitmq-server;
systemctl stop rabbitmq-server;

for ((i=1; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        scp /var/lib/rabbitmq/.erlang.cookie root@$ip:/var/lib/rabbitmq/.erlang.cookie;
  done;

### [所有控制节点] 修改cookie文件的权限
### [所有控制节点] 配置rabbitmq-server服务
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        ssh root@$ip chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie;
        ssh root@$ip chmod 400 /var/lib/rabbitmq/.erlang.cookie;

        ssh root@$ip systemctl enable rabbitmq-server.service
        ssh root@$ip systemctl start rabbitmq-server.service
                ssh root@$ip rabbitmqctl cluster_status
  done;


   ### [controller01以外的节点] 加入集群
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        ssh root@$ip rabbitmqctl stop_app;
        ssh root@$ip rabbitmqctl join_cluster --ram rabbit@$controller_0;
        ssh root@$ip rabbitmqctl start_app;
  done;

### [controlloer01] 设置ha-mode
rabbitmqctl cluster_status;
rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}';


 ############################################
 ########     安装memcached     #############
 ############################################
 
 #### install-configure-memcached.sh

#!/bin/sh
controller_name=(${!controller_map[@]});

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip  yum install -y memcached
        ssh root@$ip  systemctl enable memcached.service
        ssh root@$ip  systemctl start memcached.service
  done;

 
 #############################################
 ########   安装openstack安装包  #############
 #############################################
  
#### 所有节点，注意删除产生的在线源  install-configure-prerequisites.sh
#!/bin/sh
nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip  yum install -y centos-release-openstack-mitaka
      ssh root@$ip  yum install -y python-openstackclient openstack-selinux openstack-utils
      ssh root@$ip  rm -rf /etc/yum.repos.d/CentOS-*
  done;

 #################################################
 ########   安装openstack Identity   #############
 #################################################
 
  
 ###安装配置keystone http  所有节点执行  ./sh/keystone_install_configure.sh 

#!/bin/sh
vip='192.168.2.201'
vip=$1

echo $vip
yum install -y openstack-keystone httpd mod_wsgi

openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token 3e9cffc84608cc62cca5
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:123456@$vip/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet

openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/keystone/keystone.conf oslo_messaging_rabbit rabbit_durable_queues true

###安装配置keystone http  所有节点执行 ./sh/httpd_keystone_conf_configure.sh 

#!/bin/sh
local_nic=$1
echo $local_nic
local_ip=$(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)
echo $local_ip
sed -i -e 's#\#ServerName www.example.com:80#ServerName '"$(hostname)"'#g'  /etc/httpd/conf/httpd.conf
sed -i -e 's#0.0.0.0#'"$local_ip"'#g' /etc/httpd/conf.d/wsgi-keystone.conf
 
 ### 生成openrc.sh认证脚本  ./sh/keystone_openrc.sh
#!/bin/sh
vip='192.168.2.201'
vip=$1
echo $vip
password=$2
### [所有控制节点]编辑/etc/keystone/keystone-paste.ini
#sed -i -e 's#admin_token_auth ##g' /etc/keystone/keystone-paste.ini
unset OS_TOKEN OS_URL
### 生成keystonerc_admin脚本
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_AUTH_URL=http://$vip:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone_admin)]\$ '
">/root/keystonerc_admin
chmod +x /root/keystonerc_admin
 
#### scp其他脚本执行操作 汇总上面三个脚本  install-configure-keystone.sh
 
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
mysql -uroot -p$password_galera_root -h $virtual_ip -e "DROP DATABASE keystone;CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '"$password"';
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

 #################################################
 ########   安装openstack Image      #############
 #################################################

 
 #### glance 配置脚本 ./sh/glance_install_configure.sh


#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
password=$3
echo $vip $local_nic
yum install -y openstack-glance

### [所有控制节点]配置/etc/glance/glance-api.conf文件
openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:$password@$vip/glance

openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://$vip:35357
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

openstack-config --set /etc/glance/glance-api.conf DEFAULT registry_host $vip
openstack-config --set /etc/glance/glance-api.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
### [所有控制节点]配置/etc/glance/glance-registry.conf文件
openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:$password@$vip/glance

openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://$vip:35357
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

openstack-config --set /etc/glance/glance-registry.conf DEFAULT registry_host $vip
openstack-config --set /etc/glance/glance-registry.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

 #### scp到其他控制节点  不会立即可以获得openstack服务，可能需要重启pcs集群 install-configure-glance.sh


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
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '"$passowrd"';
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
### [任一节点]添加测试镜像
. /root/keystonerc_admin
openstack image create "cirros" --file $test_img --disk-format qcow2 --container-format bare --public
openstack image list


 ##################################################
 ########   安装openstack Compute     #############
 ##################################################
 
 ### 单独的nova 安装配置脚本   nova_install_configure.sh
 
#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
password=$3

echo $vip $local_nic
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler
### [所有控制节点]配置配置nova组件，/etc/nova/nova.conf文件
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller01:11211,controller02:11211,controller03:11211

openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:$password@$vip/nova_api
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:$password@$vip/nova

openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $password

openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf vnc novncproxy_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9292
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
openstack-config --set /etc/nova/nova.conf DEFAULT osapi_compute_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/nova/nova.conf DEFAULT metadata_listen $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

 ### scp到其他控制节点 综合脚本 (注意需要重启pcs集群才能获取计算服务) install-configure-nova.sh 
 

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
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '"$passowrd"';
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

### [任一节点]测试
sleep 10
. /root/keystonerc_admin
openstack compute service list


 ##################################################
 ########   安装openstack neutron     #############
 ##################################################
 
 ##******************************************************************##
 ### neutron 安装配置脚本   neutron_install_configure.sh
 
#!/bin/sh
vip='192.168.2.201'
vip=$1
local_nic="eno16777736"
local_nic=$2
data_nic='eno50332184'
data_nic=$3
password=$4

echo $vip $local_nic $data_nic

yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
### [所有控制节点]配置neutron server，/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT bind_host $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')

openstack-config --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:$password@$vip/neutron

openstack-config --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
openstack-config --set /etc/neutron/neutron.conf DEFAULT service_plugins router
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
openstack-config --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
openstack-config --set /etc/neutron/neutron.conf nova auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf nova auth_type password
openstack-config --set /etc/neutron/neutron.conf nova project_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova user_domain_name default
openstack-config --set /etc/neutron/neutron.conf nova region_name RegionOne
openstack-config --set /etc/neutron/neutron.conf nova project_name service
openstack-config --set /etc/neutron/neutron.conf nova username nova
openstack-config --set /etc/neutron/neutron.conf nova password $password

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

### [所有控制节点]配置ML2 plugin，/etc/neutron/plugins/ml2/ml2_conf.ini
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,vxlan,gre
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks external

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 1:1000

openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver iptables_hybrid

### [所有控制节点]配置Open vSwitch agent，/etc/neutron/plugins/ml2/openvswitch_agent.ini，注意，此处填写第二块网卡

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $(ip addr show dev $data_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings external:br-ex

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population True

### [所有控制节点]配置L3 agent，/etc/neutron/l3_agent.ini
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge

### [所有控制节点]配置DHCP agent，/etc/neutron/dhcp_agent.ini
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
openstack-config --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True

### [所有控制节点]配置metadata agent，/etc/neutron/metadata_agent.ini
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip $vip
openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret $password

### [所有控制节点]配置nova和neutron集成，/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://$vip:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $password

openstack-config --set /etc/nova/nova.conf neutron service_metadata_proxy True
openstack-config --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret $password

### [所有控制节点]配置L3 agent HA、/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT l3_ha True
openstack-config --set /etc/neutron/neutron.conf DEFAULT allow_automatic_l3agent_failover True
openstack-config --set /etc/neutron/neutron.conf DEFAULT max_l3_agents_per_router 3
openstack-config --set /etc/neutron/neutron.conf DEFAULT min_l3_agents_per_router 2

### [所有控制节点]配置DHCP agent HA、/etc/neutron/neutron.conf
openstack-config --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 3

### [所有控制节点] 配置Open vSwitch (OVS) 服务，创建网桥和端口
systemctl enable openvswitch.service
systemctl start openvswitch.service

### [所有控制节点] 创建ML2配置文件软连接
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini


##******************************************************************##
#### ovs网桥配置脚本 

#!/bin/sh
local_nic="eno16777736"
local_nic=$1
echo $local_nic

## 备份原来配置文件
cp /etc/sysconfig/network-scripts/ifcfg-$local_nic /etc/sysconfig/network-scripts/bak-ifcfg-$local_nic
echo "DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep IPADDR|awk -F '=' '{print $2}')
NETMASK=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep NETMASK|awk -F '=' '{print $2}')
GATEWAY=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep GATEWAY|awk -F '=' '{print $2}')
DNS1=$(cat /etc/sysconfig/network-scripts/ifcfg-$local_nic |grep DNS1|awk -F '=' '{print $2}')
DNS2=8.8.8.8
ONBOOT=yes">/etc/sysconfig/network-scripts/ifcfg-br-ex

echo "TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
NAME=$local_nic
DEVICE=$local_nic
ONBOOT=yes">/etc/sysconfig/network-scripts/ifcfg-$local_nic

ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $local_nic

systemctl restart network.service


##******************************************************************##
#### scp到其他控制节点 集成以上两个脚本  install-configure-neutron.sh


#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=neutron_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
sh_name_1=neutron_ovs_configure.sh
source_sh_1=$(echo `pwd`)/sh/$sh_name_1
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron

### [任一节点]创建数据库
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '"$password"';
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
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $data_nic $password
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
pcs resource create neutron-server systemd:neutron-server op start timeout=90 --clone interleave=true
pcs constraint order start openstack-keystone-clone then neutron-server-clone

pcs resource create neutron-scale ocf:neutron:NeutronScale --clone globally-unique=true clone-max=3 interleave=true
pcs constraint order start neutron-server-clone then neutron-scale-clone

pcs resource create neutron-ovs-cleanup ocf:neutron:OVSCleanup --clone interleave=true
pcs resource create neutron-netns-cleanup ocf:neutron:NetnsCleanup --clone interleave=true
pcs resource create neutron-openvswitch-agent systemd:neutron-openvswitch-agent --clone interleave=true
pcs resource create neutron-dhcp-agent systemd:neutron-dhcp-agent --clone interleave=true
pcs resource create neutron-l3-agent systemd:neutron-l3-agent --clone interleave=true
pcs resource create neutron-metadata-agent systemd:neutron-metadata-agent  --clone interleave=true

pcs constraint order start neutron-scale-clone then neutron-ovs-cleanup-clone
pcs constraint colocation add neutron-ovs-cleanup-clone with neutron-scale-clone
pcs constraint order start neutron-ovs-cleanup-clone then neutron-netns-cleanup-clone
pcs constraint colocation add neutron-netns-cleanup-clone with neutron-ovs-cleanup-clone
pcs constraint order start neutron-netns-cleanup-clone then neutron-openvswitch-agent-clone
pcs constraint colocation add neutron-openvswitch-agent-clone with neutron-netns-cleanup-clone
pcs constraint order start neutron-openvswitch-agent-clone then neutron-dhcp-agent-clone
pcs constraint colocation add neutron-dhcp-agent-clone with neutron-openvswitch-agent-clone
pcs constraint order start neutron-dhcp-agent-clone then neutron-l3-agent-clone
pcs constraint colocation add neutron-l3-agent-clone with neutron-dhcp-agent-clone
pcs constraint order start neutron-l3-agent-clone then neutron-metadata-agent-clone
pcs constraint colocation add neutron-metadata-agent-clone with neutron-l3-agent-clone

### [任一节点]
. /root/keystonerc_admin
neutron ext-list
neutron agent-list
### ovs 操作
echo "ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex "$local_nic
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh_1 root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name_1 $local_nic
  done;

  
 ##################################################
 ########   安装openstack dashboard      #############
 ##################################################
 
 ##******************************************************************##
 ### dashboard 安装配置脚本   dashboard_install_configure.sh 注意IP需要用网桥br-ex获取
 
#!/bin/sh
vip='192.168.2.201'
vip=$1
local_bridge=$2
echo $vip $local_nic $data_nic
yum install -y openstack-dashboard
### [所有控制节点] 修改配置文件/etc/openstack-dashboard/local_settings
sed -i \
    -e 's#OPENSTACK_HOST =.*#OPENSTACK_HOST = "'"$vip"'"#g' \
    -e "s#ALLOWED_HOSTS.*#ALLOWED_HOSTS = ['*',]#g" \
    -e "s#^CACHES#SESSION_ENGINE = 'django.contrib.sessions.backends.cache'\nCACHES#g#" \
    -e "s#locmem.LocMemCache'#memcached.MemcachedCache',\n        'LOCATION' : [ 'controller01:11211', 'controller02:11211', 'controller03:11211', ]#g" \
    -e 's#^OPENSTACK_KEYSTONE_URL =.*#OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST#g' \
    -e "s/^#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" \
    -e 's/^#OPENSTACK_API_VERSIONS.*/OPENSTACK_API_VERSIONS = {\n    "identity": 3,\n    "image": 2,\n    "volume": 2,\n}\n#OPENSTACK_API_VERSIONS = {/g' \
    -e "s/^#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN.*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/g" \
    -e 's#^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*#OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"#g' \
    -e "s#^LOCAL_PATH.*#LOCAL_PATH = '/var/lib/openstack-dashboard'#g" \
    -e "s#^SECRET_KEY.*#SECRET_KEY = '4050e76a15dfb7755fe3'#g" \
    -e "s#'enable_ha_router'.*#'enable_ha_router': True,#g" \
    /etc/openstack-dashboard/local_settings

### [所有控制节点] ？？？
echo "COMPRESS_OFFLINE = True" >> /etc/openstack-dashboard/local_settings
python /usr/share/openstack-dashboard/manage.py compress

### [所有控制节点] 设置HTTPD在特定的IP上监听
sed -i -e 's/^Listen.*/Listen  '"$(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)"':80/g' /etc/httpd/conf/httpd.conf

### [所有控制节点] 添加pacemaker监测httpd的配置文件
echo "<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from localhost
</Location>">/etc/httpd/conf.d/server-status.conf

systemctl restart httpd.service

 ##******************************************************************##
 #### install-configure-dashboard.sh
 
#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=dashboard_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen dashboard_cluster
    bind $virtual_ip:80
    balance  source
    option  tcpka
    option  httpchk
    option  tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:80 check inter 2000 rise 2 fall 5" >>$target_cfg
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
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_bridge
  done;

  
 #####################################################
 ########      安装openstack cinder       ############
 #####################################################
 
 ##******************************************************************##
 ### cinder配置 cat sh/cinder_install_configure.sh
 

#!/bin/sh
vip='192.168.2.201'
vip=$1
local_bridge=$2
password=$3

echo $vip $local_bridge $password
yum install -y openstack-cinder
### [所有控制节点]配置配置cinder组件，/etc/nova/nova.conf文件
openstack-config --set /etc/cinder/cinder.conf database connection mysql+pymysql://cinder:$password@$vip/cinder
openstack-config --set /etc/cinder/cinder.conf database max_retries -1

openstack-config --set /etc/cinder/cinder.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_type password
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name service
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password $password

openstack-config --set /etc/cinder/cinder.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/cinder/cinder.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/cinder/cinder.conf DEFAULT control_exchange cinder
openstack-config --set /etc/cinder/cinder.conf DEFAULT osapi_volume_listen  $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/cinder/cinder.conf DEFAULT my_ip  $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/cinder/cinder.conf oslo_concurrency lock_path /var/lib/cinder/tmp
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_servers http://$vip:9292


######**********集成Ceph的Openstack配置****************#########
### [所有控制节点] 修改/etc/glance/glance-api.conf文件，增加
openstack-config --set /etc/glance/glance-api.conf DEFAULT show_image_direct_url True
openstack-config --set /etc/glance/glance-api.conf glance_store stores rbd
openstack-config --set /etc/glance/glance-api.conf glance_store default_store rbd
openstack-config --del /etc/glance/glance-api.conf glance_store filesystem_store_datadir
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_pool images
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_user glance
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/glance/glance-api.conf glance_store rbd_store_chunk_size 8
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone

####[所有控制节点] 修改/etc/cinder/cinder.conf
openstack-config --set /etc/cinder/cinder.conf DEFAULT enabled_backends ceph
openstack-config --set /etc/cinder/cinder.conf DEFAULT glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf ceph volume_driver cinder.volume.drivers.rbd.RBDDriver
openstack-config --set /etc/cinder/cinder.conf ceph rbd_pool volumes
openstack-config --set /etc/cinder/cinder.conf ceph rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/cinder/cinder.conf ceph rbd_flatten_volume_from_snapshot false
openstack-config --set /etc/cinder/cinder.conf ceph rbd_max_clone_depth 5
openstack-config --set /etc/cinder/cinder.conf ceph rbd_store_chunk_size 4
openstack-config --set /etc/cinder/cinder.conf ceph rados_connect_timeout -1
openstack-config --set /etc/cinder/cinder.conf ceph glance_api_version 2
openstack-config --set /etc/cinder/cinder.conf ceph rbd_user cinder
openstack-config --set /etc/cinder/cinder.conf ceph rbd_secret_uuid 032198f4-b815-4254-9de2-185f935bd7de

openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_driver  cinder.backup.drivers.ceph
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_user cinder-backup
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_chunk_size 134217728
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_pool backups
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_unit 0
openstack-config --set /etc/cinder/cinder.conf DEFAULT backup_ceph_stripe_count 0
openstack-config --set /etc/cinder/cinder.conf DEFAULT restore_discard_excess_bytes true

openstack-config --set /etc/cinder/cinder.conf DEFAULT host cinder-cluster-$(echo `hostname`|awk -F "controller" '{print $2}')

####[所有控制节点] 修改NOVA 设置/etc/nova/nova.conf
#openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
#openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool vms
#openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
#openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
#openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid 032198f4-b815-4254-9de2-185f935bd7de
#
#openstack-config --set /etc/nova/nova.conf libvirt disk_cachemodes \"network=writeback\"
#openstack-config --set /etc/nova/nova.conf libvirt inject_password false
#openstack-config --set /etc/nova/nova.conf libvirt inject_key false
#openstack-config --set /etc/nova/nova.conf libvirt inject_partition  -2
#openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"

service openstack-glance-api restart
service openstack-cinder-volume restart
service openstack-cinder-backup restart


 ##******************************************************************##
 ### 控制节点上执行 集成以上脚本 install-configure-cinder.sh 
 
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


  
 #####################################################
 ########     安装openstack Ceilometer    ############
 #####################################################
 
 sed -i -e 's#123456#'"$password_mongo_root"'#g'  $tmp_path/mongodb_configure.sh

 
##******************************************************************##
#### 各控制节点需要执行的操作 sh/ceilometer_install_configure.sh

#!/bin/sh
vip='192.168.2.201'
vip=$1
vip2='192.168.2.202'
vip2=$2
local_bridge='br-ex'
local_bridge=$3
password=$4

### [所有控制节点] 安装软件
yum install -y openstack-ceilometer-api openstack-ceilometer-collector openstack-ceilometer-notification openstackceilometer-central python-ceilometerclient redis python-redis
### [所有控制节点] 配置redis
sed -i "s/\s*bind \(.*\)$/#bind \1/" /etc/redis.conf
### [所有控制节点] 修改配置文件
openstack-config --set /etc/ceilometer/ceilometer.conf database connection mongodb://ceilometer:$password@controller01:27017,controller02:27017,controller03:27017/ceilometer?replicaSet=ceilometer
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
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf keystone_authtoken password $password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_type password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials auth_url http://$vip:5000/v3
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials user_domain_name default
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials project_name service
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials username ceilometer
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials password $password
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials interface internalURL
openstack-config --set /etc/ceilometer/ceilometer.conf service_credentials region_name RegionOne
# keep last 5 days data only (value is in secs). Don't set to retain all data indefinetely.
openstack-config --set /etc/ceilometer/ceilometer.conf database metering_time_to_live 432000
openstack-config --set /etc/ceilometer/ceilometer.conf coordination backend_url 'redis://'"$vip2"':6379'
openstack-config --set /etc/ceilometer/ceilometer.conf api host $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)
openstack-config --set /etc/ceilometer/ceilometer.conf publisher telemetry_secret $password

### mongodb 配置脚本 sh/mongodb_configure.sh，用于替换密码

#!/bin/sh
mongo --host controller01 --eval 'db = db.getSiblingDB("ceilometer");db.createUser({user: "ceilometer",pwd: "123456",roles: [ "readWrite", "dbAdmin" ]})'

### mongodb 安装脚本  sh/mongodb_exec.sh
#!/bin/sh
yum install -y mongodb-server mongodb
sed -i \
-e 's#.*bind_ip.*#bind_ip = 0.0.0.0#g' \
-e 's/.*replSet.*/replSet = ceilometer/g' \
-e 's/.*smallfiles.*/smallfiles = true/g' \
/etc/mongod.conf

systemctl start mongod
systemctl stop mongod



##### scp到其他控制节点  install-configure-ceilometer.sh

#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=mongodb_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
sh_name_1=ceilometer_install_configure.sh
source_sh_1=$(echo `pwd`)/sh/$sh_name_1
target_sh=/root/tools/t_sh/

mongo_replica_cfg=$(echo `pwd`)/sh/conf/mongo_replica_setup.js
source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard.cinder
target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard.cinder.ceilometer

### 所有控制节点安装mongodb
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo " Install mongodb!"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
  done;
### [controller01] 添加资源
pcs resource create mongod systemd:mongod op start timeout=300s --clone
### [controller01] 设置副本集，等待pcs启动所有节点上的mongod服务

finish_flag=0
while_flag=0
service="mongod"

while [ $while_flag -lt 20 ]
do
  echo "#########Check all $service are running! ##########"
  finish_flag=0
  for ((i=0; i<${#controller_map[@]}; i+=1));
    do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        status=$(ssh root@$ip systemctl status $service|grep Active:|awk '{print $3}'|grep "running")
        echo $status
        if [ $status != "" ];then
          echo "running"
        else
          echo "dead"
          let finish_flag++
        fi
    done;
  if [ $finish_flag -eq 0 ];then
    echo "All $service are running!"
    while_flag=20
  else
    echo "Please check the $service in pacemaker resource!"
    sleep 5
  fi
  let while_flag++
echo $while_flag
done

if [  $finish_flag -ne 0 ]; then
    echo "Not all $service are running!"
    exit 2
fi


mongo $mongo_replica_cfg

### [controller01] 确认副本集状态
#mongo rs.status()
#mongo rs.conf()

### [controller01] 新建数据库、用户名和权限
cp sh/mongodb_configure.sh $tmp_path/mongodb_configure.sh
sed -i -e 's#123456#'"$password_mongo_root"'#g'  $tmp_path/mongodb_configure.sh
chmod +x $tmp_path/mongodb_configure.sh
. $tmp_path/mongodb_configure.sh

##### generate haproxy.cfg
cp $source_cfg $target_cfg
echo "listen ceilometer_api_cluster
    bind $virtual_ip:8777
    balance source
    option tcpka
    option tcplog">>$target_cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        echo "    server $name $ip:8777 check inter 2000 rise 2 fall 5" >>$target_cfg
  done;

##### scp haproxy.cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
        scp $target_cfg root@$ip:/etc/haproxy/haproxy.cfg
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh_1 root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name_1 $virtual_ip $virtual_ip_redis $local_bridge $password
  done;

### [controller01] 创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer --description "Telemetry" metering
openstack endpoint create --region RegionOne metering public http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering internal http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering admin http://$virtual_ip:8777

 #####################################################
 ########     安装openstack Aodh    ############
 #####################################################
 
##******************************************************************##
### aodh 各控制节点需要执行的操作 sh/aodh_install_configure.sh
#!/bin/sh
vip='192.168.2.201'
vip=$1
local_bridge='br-ex'
local_bridge=$2
password=$3
### [所有控制节点] 安装软件
yum install -y openstack-aodh-api openstack-aodh-evaluator openstack-aodh-notifier openstack-aodh-listener openstack aodh-expirer python-ceilometerclient
### [所有控制节点] 修改配置文件
openstack-config --set /etc/aodh/aodh.conf database connection mysql+pymysql://aodh:$password@$vip/aodh
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
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken auth_type password
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken project_name service
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken username aodh
openstack-config --set /etc/aodh/aodh.conf keystone_authtoken password $password
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_type password
openstack-config --set /etc/aodh/aodh.conf service_credentials auth_url http://$vip:5000/v3
openstack-config --set /etc/aodh/aodh.conf service_credentials project_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials user_domain_name default
openstack-config --set /etc/aodh/aodh.conf service_credentials project_name service
openstack-config --set /etc/aodh/aodh.conf service_credentials username aodh
openstack-config --set /etc/aodh/aodh.conf service_credentials password $password
openstack-config --set /etc/aodh/aodh.conf service_credentials interface internalURL
openstack-config --set /etc/aodh/aodh.conf service_credentials region_name RegionOne
openstack-config --set /etc/aodh/aodh.conf api host $(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)

##******************************************************************##
### scp到其他控制节点 install-configure-aodh.sh

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
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_bridge $password
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
pcs constraint colocation add delay-clone with openstack-ceilometer-api-clonepcs constraint order start delay-clone then openstack-aodh-evaluator-clone
pcs constraint order start openstack-aodh-evaluator-clone then openstack-aodh-notifier-clone
pcs constraint order start openstack-aodh-notifier-clone then openstack-aodh-api-clone
pcs constraint order start openstack-aodh-api-clone then openstack-aodh-listener-clone
pcs constraint order start openstack-aodh-api-clone then openstack-ceilometer-notification-clone
  
 #####################################################
 ########    安装计算&存储节点的ssh       ############
 #####################################################
###  set-ssh-openstack-storage-nodes.sh
#!/bin/sh
nodes_name=(${!hypervisor_map[@]});
controllers_name=(${!controller_map[@]})
echo ${controllers_name[@]}
ssh-keygen

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controller_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;
  
  
 #####################################################
 ########         安装ceph-deploy         ############
 #####################################################
 
  
 ##******************************************************************##
 ####存储节点上执行 基本配置

#!/bin/sh
### disable firewall
systemctl disable firewalld.service
systemctl stop firewalld.service
### disable selinux
sed -i -e "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sed -i -e "s#SELINUXTYPE=targeted#\#SELINUXTYPE=targeted#g" /etc/selinux/config
###set ceph ssh
sed -i -e 's#Defaults   *requiretty#Defaults:ceph !requiretty#g' /etc/sudoers

 #### scp到其他存储节点 

#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16");
nodes_name=(${!nodes_map[@]});
base_location=./wheel_ceph/

sh_name=set_selinux_firewall_sudoer.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

yum install --nogpgcheck -y epel-release
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
rm -rf /etc/yum.repos.d/epel*
yum install -y python-pip
yum install -y python-wheel
pip install --use-wheel --no-index --trusted-host 192.168.100.81 --find-links=$base_location ceph-deploy
ceph-deploy --version

### set
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
  done;
  
 
 #####################################################
 ######## 安装ceph block storage cluster  ############
 #####################################################
 
 ##******************************************************************##
 ### 存储节点上部署ceph集群 注意网卡设置，统一成同一个网段11.11.11.0   install-configure-ceph-storage-cluster.sh


#!/bin/sh
#declare -A hypervisor_map=(["compute01"]="11.11.11.14" ["compute02"]="11.11.11.15" ["compute03"]="11.11.11.16");

nodes_name=(${!hypervisor_map[@]});

base_location=$ftp_info
deploy_node=compute01
echo $deploy_node

cp /etc/hosts /etc/hosts.bak.tmp
sed -i -e 's#'"$(echo $local_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' /etc/hosts

ceph-deploy forgetkeys
ceph-deploy purge  ${nodes_name[@]}
ceph-deploy purgedata   ${nodes_name[@]}

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        ssh root@$name  rm -rf /osd/*
  done;

mkdir -p /root/my-cluster
cd /root/my-cluster
rm -rf /root/my-cluster/*
ceph-deploy new $deploy_node
sed -i -e 's#'"$(echo $local_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' ceph.conf
echo "public network ="$store_network>>ceph.conf

ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-jewel/el7/ ${nodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc
ceph-deploy mon create-initial

osds="";
echo $osds

### set
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        osds=$osds" "$name":/osd"
        ssh root@$name  chown -R ceph:ceph /osd/
  done;
echo $osds
###[部署节点]激活OSD
ceph-deploy osd prepare $osds
ceph-deploy osd activate $osds
ceph-deploy admin ${nodes_name[@]}


### set
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        if [ $name =  $deploy_node ]; then
          echo $name" already is mon!"
        else
          ceph-deploy mon add $name
        fi
  done;

###查看集群状态
ceph -s
###[ceph管理节点]创建Pool
ceph osd pool create volumes 128
ceph osd pool create images 128
ceph osd pool create backups 128
ceph osd pool create vms 128

mv /etc/hosts.bak.tmp /etc/hosts

 #####################################################
 ########   存储节点与控制节点之间的ssh     ############
 #####################################################

#!/bin/sh
nodes_name=(${!hypervisor_map[@]});
controllers_name=(${!controller_map[@]})
echo ${controllers_name[@]}
ssh-keygen

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controller_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
      ssh-copy-id root@$(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ssh-copy-id root@$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  done;




 #####################################################
 ########   安装ceph auth client.key     ############
 #####################################################
 
 ##******************************************************************##
 ### 存储节点上执行 集群   install-ceph-auth-client.key
 
#!/bin/sh
nodes_name=(${!hypervisor_map[@]});
controllers_name=(${!controller_map[@]})

echo ${controllers_name[@]}

###复制ceph配置文件 glance-api, cinder-volume, nova-compute and cinder-backup的主机名,由于存储和计算在同一个节点，不需要复制到自身
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controller_map[$name]};
      echo "-------------$name------------"
        ssh $name  mkdir -p /etc/ceph/
        ssh $name  tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf
        ###[所有控制节点]在glance-api节点上
        ssh $name yum install -y python-rbd
        ###[所有控制节点]在nova-compute, cinder-backup 和cinder-volume节点上
        ssh $name yum install -y ceph-common
  done;
###安装Ceph客户端认证
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'

###为client.cinder, client.glance, and client.cinder-backup添加keyring
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
      name=${controllers_name[$i]};
      ip=${controller_map[$name]};
      echo "-------------$name------------"
        ceph auth get-or-create client.glance | ssh $name  tee /etc/ceph/ceph.client.glance.keyring
        ssh $name  chown glance:glance /etc/ceph/ceph.client.glance.keyring
        ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
        ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
        ceph auth get-or-create client.cinder-backup | ssh $name  tee /etc/ceph/ceph.client.cinder-backup.keyring
        ssh $name  chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring
  done;
###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        ceph auth get-or-create client.cinder | ssh $name  tee /etc/ceph/ceph.client.cinder.keyring
        ceph auth get-key client.cinder | ssh $name tee client.cinder.key
  done;

 #####################################################
 ########      计算节点上配置             ############
 #####################################################

  ##******************************************************************##
 #### 网络服务、计算服务、存储服务集成
 #### 各存储节点（与计算节点融合）执行的脚本 sh/compute_nodes_exec.sh

#!/bin/sh
vip=$1
local_nic=$2
data_nic=$3
password=$4

yum install -y centos-release-openstack-mitaka
yum install -y python-openstackclient openstack-selinux openstack-utils
### 1. OpenStack Compute service
yum install -y openstack-nova-compute

### 修改配置文件/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf DEFAULT memcached_servers controller01:11211,controller02:11211,controller03:11211

openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password $password

openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

openstack-config --set /etc/nova/nova.conf vnc enabled True
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $(ip addr show dev $local_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://$vip:6080/vnc_auto.html

openstack-config --set /etc/nova/nova.conf glance api_servers http://$vip:9292
 openstack-config --set /etc/nova/nova.conf libvirt virt_type  $(count=$(egrep -c '(vmx|svm)' /proc/cpuinfo); if [ $count -eq 0 ];then   echo "qemu"; else   echo "kvm"; fi)



### 打开虚拟机迁移的监听端口
sed -i -e "s#\#listen_tls *= *0#listen_tls = 0#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#listen_tcp *= *1#listen_tcp = 1#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#auth_tcp *= *\"sasl\"#auth_tcp = \"none\"#g" /etc/libvirt/libvirtd.conf
sed -i -e "s#\#LIBVIRTD_ARGS *= *\"--listen\"#LIBVIRTD_ARGS=\"--listen\"#g" /etc/sysconfig/libvirtd


###启动服务
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service


#### 2. OpenStack Network service
### 安装组件
yum install -y openstack-neutron-openvswitch
yum install -y openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
### 修改/etc/neutron/neutron.conf

openstack-config --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_hosts controller01:5672,controller02:5672,controller03:5672
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_ha_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_interval 1
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_retry_backoff 2
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_max_retries 0
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_durable_queues true
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $password

openstack-config --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$vip:5000
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$vip:35357
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken memcached_servers controller01:11211,controller02:11211,controller03:11211
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken auth_type password
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken project_name service
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken username neutron
openstack-config --set /etc/neutron/neutron.conf keystone_authtoken password $password

openstack-config --set /etc/neutron/neutron.conf oslo_concurrency lock_path /var/lib/neutron/tmp

### 配置Open vSwitch agent，/etc/neutron/plugins/ml2/openvswitch_agent.ini，注意，此处填写第二块网卡
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_ipset True
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver iptables_hybrid

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs local_ip $(ip addr show dev $data_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')

openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent tunnel_types vxlan
openstack-config --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent l2_population False

### 配置nova和neutron集成，/etc/nova/nova.conf
openstack-config --set /etc/nova/nova.conf neutron url http://$vip:9696
openstack-config --set /etc/nova/nova.conf neutron auth_url http://$vip:35357
openstack-config --set /etc/nova/nova.conf neutron auth_type password
openstack-config --set /etc/nova/nova.conf neutron project_domain_name default
openstack-config --set /etc/nova/nova.conf neutron user_domain_name default
openstack-config --set /etc/nova/nova.conf neutron region_name RegionOne
openstack-config --set /etc/nova/nova.conf neutron project_name service
openstack-config --set /etc/nova/nova.conf neutron username neutron
openstack-config --set /etc/nova/nova.conf neutron password $password

ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

systemctl restart openstack-nova-compute.service
systemctl start openvswitch.service
systemctl restart neutron-openvswitch-agent.service



### 3. OpenStack Block Storage service
###计算节点安装客户端命令行工具
yum install -y ceph-common


echo "<secret ephemeral='no' private='no'>
  <uuid>032198f4-b815-4254-9de2-185f935bd7de</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>">secret.xml
virsh secret-define --file secret.xml
virsh secret-set-value --secret 032198f4-b815-4254-9de2-185f935bd7de --base64 $(cat /etc/ceph/ceph.client.cinder.keyring |grep 'key ='|awk '{print $3}') && rm client.cinder.key secret.xml

echo "[client]
rbd cache = true
rbd cache writethrough until flush = true
admin socket = /var/run/ceph/guests/\$cluster-\$type.\$id.\$pid.\$cctid.asok
log file = /var/log/qemu/qemu-guest-\$pid.log
rbd concurrent management ops = 20">> /etc/ceph/ceph.conf

###设置路径权限
mkdir -p /var/run/ceph/guests/ /var/log/qemu/
chown ceph:ceph /var/run/ceph/guests /var/log/qemu/
###设置/etc/nova/nova.conf

openstack-config --set /etc/nova/nova.conf libvirt images_type rbd
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_pool vms
openstack-config --set /etc/nova/nova.conf libvirt images_rbd_ceph_conf /etc/ceph/ceph.conf
openstack-config --set /etc/nova/nova.conf libvirt rbd_user cinder
openstack-config --set /etc/nova/nova.conf libvirt rbd_secret_uuid $(virsh secret-list| grep ceph| awk '{print $1}')
openstack-config --set /etc/nova/nova.conf libvirt disk_cachemodes \"network=writeback\"
openstack-config --set /etc/nova/nova.conf libvirt inject_password false
openstack-config --set /etc/nova/nova.conf libvirt inject_key false
openstack-config --set /etc/nova/nova.conf libvirt inject_partition  -2
openstack-config --set /etc/nova/nova.conf libvirt live_migration_flag "VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"

service openstack-nova-compute restart


 ##******************************************************************##
#### scp到其他存储节点执行 install-compute-nodes-services.sh

#!/bin/sh
nodes_name=(${!hypervisor_map[@]});

sh_name=compute_nodes_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

###复制Keyring文件到nova-compute节点,为nova-compute节点上创建临时密钥
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
         ssh root@$ip mkdir -p $target_sh
         scp $source_sh root@$ip:$target_sh
         ssh root@$ip chmod -R +x $target_sh
         ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $data_nic $password
  done;
 

 #####################################################
 ########        删除部署脚本             ############
 #####################################################

###******************************** delete-tmp-shells.sh
#!/bin/sh
nodes_name=(${!nodes_map[@]});

target_sh=$tmp_path
echo "rm "$target_sh

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip rm -rf $target_sh
  done;
echo "Please delete the install dir manually on controller01 and compute01!"


  
  




 
 
 

 
  

  


 
 

 
 
 
 
 
 
  
  
  


  
  


   
   







	
	




  
  



 


  
  
  
  
  
  
  
  
  
  
  
  


  
  


  

  

  
 


