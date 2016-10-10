 #!/bin/sh
declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

nodes_name=(${!nodes_map[@]});
sh_name=disable_selinux_firewall.sh
source_sh=./sh/$sh_name
target_sh=/root/tools/t_sh/

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

