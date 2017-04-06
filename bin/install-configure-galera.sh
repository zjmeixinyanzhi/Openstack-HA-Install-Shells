#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Galera Installation"
### install mariadb
./pssh-exe C "yum install -y MariaDB-server xinetd"
### [所有控制节点] 修改/etc/haproxy/haproxy.cfg文件
. ./1-gen-haproxy-cfg.sh base
. ./1-gen-haproxy-cfg.sh galera
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
  if [ $name = "controller01" ]; then
    ./style/print-warnning.sh "Please set the database password is $password_galera_root"
    mysql_secure_installation
  else
    ssh root@$ip systemctl start mariadb
  fi
done;
. ./restart-pcs-cluster.sh
mysql -uroot -p$password_galera_root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '"$password_galera_root"';FLUSH PRIVILEGES;"
mysql -uroot -p$password_galera_root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

#### Galera cluster check
rm -rf ../conf/clustercheck
cp ../conf/clustercheck.template ../conf/clustercheck
sed -i -e 's#MYSQL_PASSWORD=#MYSQL_PASSWORD='"$password_galera_root"'#g' ../conf/clustercheck
sed -i -e 's#MYSQL_HOST=#MYSQL_HOST='"$virtual_ip"'#g' ../conf/clustercheck
./scp-exe C "../conf/clustercheck" "/etc/sysconfig/clustercheck"
mysql -uroot -p$password_galera_root -e "GRANT ALL PRIVILEGES ON *.* TO 'clustercheck_user'@'localhost' IDENTIFIED BY '"$password_galera_root"';GRANT ALL PRIVILEGES ON *.* TO 'clustercheck_user'@'"$virtual_ip"' IDENTIFIED BY '"$password_galera_root"';FLUSH PRIVILEGES;"
rm -rf ../conf/clustercheck.sh
cp ../conf/clustercheck.sh.template ../conf/clustercheck.sh
sed -i -e 's#MYSQL_PASSWORD=#MYSQL_PASSWORD='"\"\${2-$password_galera_root}\""'#g' ../conf/clustercheck.sh
./scp-exe C ../conf/clustercheck.sh /usr/bin/clustercheck
./pssh-exe C "chmod a+x /usr/bin/clustercheck && chmod 755 /usr/bin/clustercheck && chown nobody /usr/bin/clustercheck"
###setup check service
./pssh-exe C "sed -i -e '/9200\/[udp,tcp]/d' /etc/services"
./pssh-exe C "echo 'mysqlchk	9200/tcp # mysqlchk' >> /etc/services"
./scp-exe C "../conf/mysqlchk" "/etc/xinetd.d/mysqlchk"
./pssh-exe C "systemctl stop xinetd && systemctl enable xinetd && systemctl start xinetd"
### test checking service
./pssh-exe C /usr/bin/clustercheck
telnet $virtual_ip 9200 
