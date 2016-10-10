#!/bin/sh

declare -A controller_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" );

controller_name=(${!controller_map[@]});

for ((i=0; i<${#controller_map[@]}; i+=1));
  do
	name=${controller_name[$i]};
	ip=${controller_map[$name]};
	echo "-------------$name------------"
        ssh root@$ip  yum install -y memcached
        ssh root@$ip  systemctl enable memcached.service
        ssh root@$ip  systemctl start memcached.service
  done;
