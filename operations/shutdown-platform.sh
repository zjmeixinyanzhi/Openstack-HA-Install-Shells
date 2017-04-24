#!/bin/sh
. 0-set-config.sh
nodes_name=(${!nodes_map[@]});

stop_all_services(){
  ### stop portal
  . /opt/apache-tomcat-7.0.68/bin/shutdown.sh
  ### Stop controller cluster
  pcs cluster stop --all
  for i in 01 02 03; do ssh controller$i pcs cluster kill; done
  pcs cluster stop --all
  ### Stop network cluster
  ssh root@$network_host pcs cluster stop --all
  for i in 01 02 03; do ssh network$i pcs cluster kill; done
  ssh root@$network_host pcs cluster stop --all
}
shutdown_all_nodes(){
  for host in ${nodes_name[@]}
  do
    if [ $name =  "controller01" ]; then
      echo $name" will poweroff at the end!"
    else
      ssh $host poweroff
    fi
  done
  poweroff
}

echo -e "\033[33m警告:是否要关闭云平台服务？yes/no \033[0m"
read confirm
if [ $confirm = "yes" ];then
  stop_all_services 
  echo -e "\033[34m云平台服务已关闭！ \033[0m"
else
  echo -e "\033[34m未执行关闭云平台服务操作！\033[0m"
fi
### Poweroff
echo -e "\033[33m警告:是否要关闭所有节点？yes/no \033[0m"
read confirm
if [ $confirm = "yes" ];then
  shutdown_all_nodes
else
  echo -e "\033[34m未执行关机操作！\033[0m"
fi
