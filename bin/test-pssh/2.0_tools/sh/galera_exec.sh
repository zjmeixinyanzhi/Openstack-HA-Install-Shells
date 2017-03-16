#!/bin/sh
local_nic='eno16777736'
local_nic=$1
 
echo $local_nic

yum install -y MariaDB-server xinetd

cp /etc/my.cnf.d/server.cnf /etc/my.cnf.d/bak.server.cnf

echo "[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
binlog_format=ROW
max_connections = 4096
bind-address= $(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)

default_storage_engine=innodb
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=122M

wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_provider_options=\"pc.recovery=TRUE;gcache.size=300M\"
wsrep_cluster_name=\"galera_cluster\"
wsrep_cluster_address=\"gcomm://controller01,controller02,controller03\"
wsrep_node_name= $(hostname)
wsrep_node_address= $(ip addr show dev $local_nic scope global | grep "inet " | sed -e "s#.*inet ##g" -e "s#/.*##g"|head -n 1)
wsrep_sst_method=rsync
"> /etc/my.cnf.d/server.cnf  
