#!/bin/sh
. ~/keystonerc_admin
neutron net-create --shared --provider:physical_network external  --provider:network_type flat public
neutron subnet-create --name public-subnet --allocation-pool start=192.168.2.100,end=192.168.2.200 --dns-nameserver 8.8.8.8 --gateway 192.168.2.2 public 192.168.2.0/24
neutron net-update public --router:external
openstack network list
