#!/bin/sh
. 0-set-config.sh 
### create portal db
path=$(echo `pwd`)
echo $path
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;show tables;"
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;source "$path/"monitor.sql;source "$path/"physical_machine_type.sql;source "$path/"role.sql;"
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;show tables;"
