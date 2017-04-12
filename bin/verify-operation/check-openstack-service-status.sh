#!/bin/sh
. /root/keystonerc_admin
openstack compute service list
neutron agent-list
cinder service-list
ceilometer meter-list
