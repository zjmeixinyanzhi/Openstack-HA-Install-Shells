#!/bin/sh

nodes_name=(${!nodes_map[@]});

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      #ssh root@$ip  yum install -y memcached
      #ssh root@$ip  systemctl enable memcached.service
      #ssh root@$ip  systemctl start memcached.service
      #ssh root@$ip  yum install -y centos-release-openstack-mitaka
      #ssh root@$ip  yum install -y python-openstackclient openstack-selinux openstack-utils
      #ssh root@$ip  yum install -y mongodb-server mongodb
      #ssh root@$ip  yum remove -y   MariaDB-server xinetd
      if [ $name= "controller01"];then
	echo "$ip"
      else 
        ssh root@$ip  service network restart
      fi
  done;

