#!/bin/sh
. 0-set-config.sh  
### create portal db
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE cloud DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON cloud.* TO 'root'@'%' IDENTIFIED BY '"$password_galera_root"';FLUSH PRIVILEGES;"
 
