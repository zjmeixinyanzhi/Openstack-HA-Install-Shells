#!/bin/sh
. ../0-set-config.sh
mysql -uroot -p$password_galera_root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

