#!/bin/sh

###
### deploy openstack ha cluster 
### 
### run from the first controller node
###
### M controller nodes + N compute nodes
### ceph deploy runs from the first controller node, and ceph mon + osd run on the compute nodes
###

# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
# setting for ceph
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

# ceph admin node, run ceph-deploy from this node
ceph_admin=controller01

# ceph-deploy user
ceph_deploy_user=deploy

# array of ceph monitors, in our deploy shell, monitors must be subset of osds
declare -a ceph_mons=(compute01 compute02 compute03)

# array of ceph osds
declare -a ceph_osds=(compute01 compute02 compute03)

# array of ceph osd directory
declare -a ceph_osd_disks=(/disk1 /disk2 /disk3)

#
ceph_osd_list=""
for osd in ${ceph_osds[@]};
do
	for disk in ${ceph_osd_disks[@]};
	do
		ceph_osd_list=$ceph_osd_list$osd":"$disk" "
	done
done

# ceph public network, for client access (r/w), 
# the mon listens on this network, the ceph.conf set mon_host on the mgmt network, so here we must use mgmt network???
ceph_public_network="192.168.2.0"
ceph_public_network_prefix="23"

# ceph cluster network, for heartbeat, object replication and recovery
ceph_cluster_network="172.16.2.0"
ceph_cluster_network_prefix="24"


# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
# setting for openstack
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

# array of controllers
declare -a controllers=(controller01 controller02 controller03)

# associate array of controllers and management network interface ip address
declare -A controller_mgmt_nic_map=(["controller01"]="192.168.2.101" ["controller02"]="192.168.2.102" ["controller03"]="192.168.2.103");

# associate array of controllers and tuennel network interface ip address
declare -A controller_tunnel_nic_map=(["controller01"]="10.10.10.101" ["controller02"]="10.10.10.102" ["controller03"]="10.10.10.103");

# array of networkers
declare -a networkers=(network01 network02 network03)

# associate array of networkers and management network interface ip address
declare -A networkers_mgmt_nic_map=(["network01"]="192.168.2.111" ["network02"]="192.168.2.112" ["network03"]="192.168.2.113");

# associate array of hypervisors and tuennel network interface ip address
declare -A networkders_tunnel_nic_map=(["network01"]="10.10.10.111" ["network02"]="10.10.10.112" ["network03"]="10.10.10.113");

# array of hypervisors
declare -a hypervisors=(compute01 compute02 compute03)

# associate array of hypervisors and management network interface ip address
declare -A hypervisor_mgmt_nic_map=(["compute01"]="192.168.2.104" ["compute02"]="192.168.2.105" ["compute03"]="192.168.2.106");

# associate array of hypervisors and tuennel network interface ip address
declare -A hypervisor_tunnel_nic_map=(["compute01"]="10.10.10.104" ["compute02"]="10.10.10.105" ["compute03"]="10.10.10.106");

domain_suffix=".stack.local"

# haproxy virtual ip address
virtual_ip="192.168.2.121"

# redis server ip address, for ceilometer
redis_vip="192.168.2.122"

# first controller, deprecated
controller_0=${controllers[0]};

# list of controllers seperated by space
controller_list_space=${!controller_mgmt_nic_map[@]};

# list of controllers seperated by comma
controller_list_comma=`echo $controller_list_space | tr " " ","`;
echo $controller_list_comma 
#
rabbit_hosts_list=""
memcached_servers_list=""
dashboard_memcached_servers_list=""
mongodb_servers_list=""
for ((i=0;i<${#controllers[@]};i+=1))
do
	if [ $i -lt `expr ${#controllers[@]} - 1` ]
	then
		rabbit_hosts_list=$rabbit_hosts_list${controllers[$i]}":5672,"
		memcached_servers_list=$memcached_servers_list${controllers[$i]}":11211,"
		dashboard_memcached_servers_list=$dashboard_memcached_servers_list"'"${controllers[$i]}":11211',"
		mongodb_servers_list=$mongodb_servers_list${controllers[$i]}":27017,"
	else
		rabbit_hosts_list=$rabbit_hosts_list${controllers[$i]}":5672"
		memcached_servers_list=$memcached_servers_list${controllers[$i]}":11211"
		dashboard_memcached_servers_list=$dashboard_memcached_servers_list"'"${controllers[$i]}":11211'"
		mongodb_servers_list=$mongodb_servers_list${controllers[$i]}":27017"
	fi
done

# 
keystone_db_password="123456"

#
keystone_admin_password="123456"

# 
glance_db_password="123456"

#
glance_ks_password="123456"

#
nova_db_password="123456"

#
nova_ks_password="123456"

#
neutron_db_password="123456"

#
neutron_ks_password="123456"

# neurtorn metadata service agent secret key
metadata_secret_key="123456"

#
cinder_db_password="123456"

#
cinder_ks_password="123456"

# mongodb password
ceilometer_db_password="123456"

#
ceilometer_ks_password="123456"

#
aodh_db_password="123456"

#
aodh_ks_password="123456"

# echo $rabbit_hosts_list
# echo $memcached_servers_list
# echo $dashboard_memcached_servers_list

