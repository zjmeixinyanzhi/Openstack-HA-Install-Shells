#!/bin/sh
. /root/keystonerc_admin
project_id=$(openstack project show -f value -c id admin)
echo $project_id
openstack quota show $project_id
openstack quota set --volumes 10 $project_id
openstack quota set --gigabytes 1000 $project_id
openstack quota set --ram 512 $project_id
openstack quota show $project_id
openstack role add --domain default --user admin admin
