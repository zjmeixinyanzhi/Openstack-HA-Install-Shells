#!/bin/sh
nodes_name=(${!additionalNodes_map[@]});
allnodes_name=(${!nodes_map[@]});

sh_name=network-config-exec.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path
sh_name_1=disable_selinux_firewall.sh
source_sh_1=./sh/$sh_name_1
sh_name_ntp=replace_ntp_hosts.sh
source_sh=./sh/$sh_name_ntp

base_location=$ftp_info
deploy_node=compute01
ref_host=controller01
echo $deploy_node

tmp_file=/etc/hosts.bak2
target=/etc/hosts
cp $target $tmp_file

for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${additionalNodes_map[$name]};
      echo "-------------$name------------"
      ### set ssh
      ssh-copy-id root@$ip      
      ssh root@$ip mkdir -p $target_sh
      scp $source_sh root@$ip:$target_sh
      ssh root@$ip chmod -R  +x $target_sh
      ### gather hostname
      echo "$ip $name">>$tmp_file
      ### network configure
      ssh root@$ip $target_sh/$sh_name $local_nic $data_nic $storage_nic $ip $data_network $store_network 
      ## test network
      echo ">>>>>>>"
      ping -c 2 $ip
      echo ">>>>>>>"
      ping -c 2 $(echo $data_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      echo ">>>>>>>"
      ping -c 2 $(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
      ### firewall selinux   
      echo "Set firewall and SELinux"  
      scp $source_sh_1 root@$ip:$target_sh
      ssh root@$ip $target_sh/$sh_name_1
      ssh root@$ip systemctl status firewalld.service|grep  Active:
      ssh root@$ip sestatus -v
      ### NTP
      echo "Set NTP"
      ssh root@$ip systemctl enable chronyd.service
      ssh root@$ip systemctl restart chronyd.service
      ssh root@$ip cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
      ssh root@$ip $target_sh/$sh_name_ntp $ref_host
      ssh root@$ip chronyc sources
  done; 
### update /etc/hosts to old nodes
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${allnodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ###set hostname
      scp $tmp_file root@$ip:/etc/hosts
  done;
### update hosts & local yum repos to new nodes
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${additionalNodes_map[$name]};
      echo "-------------$name------------"
      ### hostname
      ssh root@$ip hostnamectl --static set-hostname $name
      scp $tmp_file root@$ip:/etc/hosts
      ### yum repos
      ssh root@$ip rm -rf /etc/yum.repos.d/*
      ssh root@$ip yum clean all
      ssh root@$ip rm -rf /etc/yum.repos.d/CentOS-* ###必须要有，否则ssh root@$ip rm -rf /etc/yum.repos.d/*无法删除系统自带源
      ssh root@$ip rpmdb --rebuilddb
      ssh root@$ip ls -l /etc/yum.repos.d/
      scp -r /etc/yum.repos.d/* root@$ip:/etc/yum.repos.d/
      ssh root@$ip yum repolist all
      ssh root@$ip yum upgrade -y
      ssh root@$ip  yum install -y centos-release-openstack-mitaka
      ssh root@$ip  yum install -y python-openstackclient openstack-selinux openstack-utils

  done; 
