#!/bin/sh
name=`uuidgen`
. ~/keystonerc_admin 
openstack server create --flavor m1.tiny --image $(openstack image list |grep cirros|head -n 1|awk '{print $2}') --nic net-id=$(openstack network list |grep private|head -n 1|awk '{print $2}') --security-group default demo-vm-$name
