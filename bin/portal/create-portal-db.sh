#!/bin/sh
### create database
path=$(pwd)
mysql -uroot -p$password_galera_root -h $virtual_ip -e "CREATE DATABASE cloud DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON cloud.* TO 'root'@'%' IDENTIFIED BY '"$password_galera_root"';FLUSH PRIVILEGES;"
mysql -uroot -p$password_galera_root -h $virtual_ip -e "use cloud;source "$path/"cloud_structure.sql;"
