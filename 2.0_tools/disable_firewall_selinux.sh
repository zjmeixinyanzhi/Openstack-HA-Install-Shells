#!/bin/sh
nodes_name=(${!nodes_map[@]});
sh_name=disable_selinux_firewall.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      scp $source_sh root@$ip:$target_sh
      ssh root@$ip chmod +x $target_sh
      ssh root@$ip $target_sh/$sh_name
      ssh root@$ip systemctl status firewalld.service|grep  Active:
      ssh root@$ip sestatus -v
  done;
