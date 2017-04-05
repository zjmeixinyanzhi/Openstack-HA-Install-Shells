#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "RabbitMQ Installation"

./pssh-exe C "yum install -y rabbitmq-server && systemctl start rabbitmq-server.service"
./pssh-exe C "rabbitmqctl add_user openstack $passsword_rabbitmq"
./pssh-exe C "rabbitmqctl set_permissions openstack \".*\" \".*\" \".*\""
./pssh-exe C "systemctl stop rabbitmq-server.service"

### [controlloer01] 拷贝cookie文件到其他节点
systemctl start rabbitmq-server;
systemctl stop rabbitmq-server;
./scp-exe C "/var/lib/rabbitmq/.erlang.cookie" "/var/lib/rabbitmq/.erlang.cookie"
### [所有控制节点] 修改cookie文件的权限
./pssh-exe C "chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie"
./pssh-exe C "chmod 400 /var/lib/rabbitmq/.erlang.cookie"
### [所有控制节点] 配置rabbitmq-server服务
./pssh-exe C "systemctl enable rabbitmq-server.service && systemctl start rabbitmq-server.service"
./pssh-exe C "rabbitmqctl cluster_status"
### [controller01以外的节点] 加入集群
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
	if [ $name = "controller01"  ];then
	  echo "controller01"
	else
          ssh root@$ip rabbitmqctl stop_app;
          ssh root@$ip rabbitmqctl join_cluster --ram rabbit@controller01;
          ssh root@$ip rabbitmqctl start_app;
	fi
  done;
### [controlloer01] 设置ha-mode
rabbitmqctl cluster_status;
rabbitmqctl set_policy ha-all '^(?!amq\.).*' '{"ha-mode": "all"}';
