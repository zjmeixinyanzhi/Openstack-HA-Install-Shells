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
        ssh root@$ip rabbitmqctl add_user openstack $passsword_rabbitmq;
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
	if [ $name = "controller01"  ];then
	  echo "controller01"
	else
          ssh root@$ip rabbitmqctl stop_app;
          ssh root@$ip rabbitmqctl join_cluster --ram rabbit@$controller_0;
          ssh root@$ip rabbitmqctl start_app;
	fi
  done;

### [controlloer01] 设置ha-mode
rabbitmqctl cluster_status;
rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}';
