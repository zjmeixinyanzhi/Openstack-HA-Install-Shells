#!/bin/sh
name=`uuidgen`
. ~/keystonerc_admin 
openstack image list
openstack image create "image-cirros-"$name   --file ../../conf/cirros.raw --disk-format raw --container-format bare   --public
openstack image list
