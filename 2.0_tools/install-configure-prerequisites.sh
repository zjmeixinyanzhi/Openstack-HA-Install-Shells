#!/bin/sh
nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip  yum install -y centos-release-openstack-mitaka
      ssh root@$ip  yum install -y python-openstackclient openstack-selinux openstack-utils
      ssh root@$ip  rm -rf /etc/yum.repos.d/CentOS-*
  done;

