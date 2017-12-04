#!/bin/sh
. /root/keystonerc_admin
openstack compute service list
neutron agent-list
cinder service-list
ceilometer meter-list
rabbitmqctl cluster_status
mysql -uroot -p$password_galera_root -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
pcs resource
