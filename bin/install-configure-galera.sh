#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Galera Installation"
### install mariadb
./pssh-exe C "yum install -y MariaDB-server xinetd"
### 备份配置文件
./pssh-exe C "cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/bak.server.cnf"
###  
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  rm -rf ../conf/server.cnf
  cp ../conf/server.cnf.template ../conf/server.cnf
  sed -i -e 's#bind-address=*#bind-address='"${ip}"'#g' ../conf/server.cnf
  sed -i -e 's#wsrep_node_name=#wsrep_node_name='"${name}"'#g' ../conf/server.cnf
  sed -i -e 's#wsrep_node_address=#wsrep_node_address='"${ip}"'#g' ../conf/server.cnf
  scp ../conf/server.cnf root@$ip:/etc/my.cnf.d/server.cnf 
done
##### controller01
galera_new_cluster
#### config galera
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  echo "-------------$name------------"
  if [ $name = "controller01" ]; then
    ./style/print-warnning.sh "Please set the database password is $password_galera_root"
    mysql_secure_installation
  else
    ssh root@$ip systemctl start mariadb
  fi
done;
#### check
. restart-pcs-cluster.sh
mysql -uroot -p$password_galera_root -e "use mysql;INSERT INTO user(Host, User) VALUES('"$virtual_ip"', 'haproxy_check');FLUSH PRIVILEGES;"
mysql -uroot -p$password_galera_root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'controller01' IDENTIFIED BY '"$password_galera_root"'";
mysql -uroot -p$password_galera_root -h $virtual_ip -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
