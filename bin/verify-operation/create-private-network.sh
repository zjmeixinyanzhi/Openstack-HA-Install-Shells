#!/bin/sh
. ~/keystonerc_admin
neutron net-create private
neutron subnet-create --name private-subnet --dns-nameserver 8.8.8.8 --gateway 155.100.3.1 private 155.100.3.0/24
openstack network list
neutron router-create router
neutron router-gateway-set router public
neutron router-interface-add router private-subnet
neutron router-port-list router
