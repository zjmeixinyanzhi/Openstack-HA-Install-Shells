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
#$tmp_path/mongodb_configure.sh
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
	if [ $name = $(hostname) ];then
	  $tmp_path/mongodb_configure.sh
	else   
          scp $tmp_path/mongodb_configure.sh root@$ip:$tmp_path/mongodb_configure.sh
          ssh root@$ip mkdir -p $target_sh
          scp $source_sh_1 root@$ip:$target_sh
          ssh root@$ip chmod -R +x $target_sh
          ssh root@$ip $tmp_path/mongodb_configure.sh
        fi
  done;

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
        ssh root@$ip $target_sh/$sh_name_1 $virtual_ip $virtual_ip_redis $local_nic $password $password_mongo_root
  done;

### [controller01] 创建用户等
. /root/keystonerc_admin
openstack user create --domain default --password $password ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer --description "Telemetry" metering
openstack endpoint create --region RegionOne metering public http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering internal http://$virtual_ip:8777
openstack endpoint create --region RegionOne metering admin http://$virtual_ip:8777

