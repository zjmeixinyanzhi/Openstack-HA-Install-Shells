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
           echo "    server $name $ip:3306 check inter 2000 rise 2 fall 5" >>$target_cfg
       else
           echo "    server $name $ip:3306 backup check inter 2000 rise 2 fall 5" >>$target_cfg
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
          echo "Please set the database password is "$password_galera_root
          mysql_secure_installation
       else
         ssh root@$ip systemctl start mariadb
         #ssh root@$ip mysql_secure_installation
       fi
  done;
#### check
. restart-pcs-cluster.sh
mysql -uroot -p$password_galera_root -e "use mysql;INSERT INTO user(Host, User) VALUES('"$virtual_ip"', 'haproxy_check');FLUSH PRIVILEGES;"
mysql -uroot -p$password_galera_root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'controller01' IDENTIFIED BY '"$password_galera_root"'";
mysql -uroot -p$password_galera_root -h $virtual_ip -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
