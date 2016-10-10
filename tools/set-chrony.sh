#!/bin/sh
#### controller01

declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

subnet=192.168.2.0/24

ref_host=controller01

sh_name=replace_ntp_hosts.sh
source_sh=./sh/$sh_name
target_sh=/root/tools/t_sh/

nodes_name=(${!nodes_map[@]});

rm -rf result.log

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      if [ $name = $ref_host  ]; then
          echo ""$ip
          echo "allow 192.168.2.0/24" >>/etc/chrony.conf
      else
          ssh root@$ip mkdir -p $target_sh
          scp $source_sh root@$ip:$target_sh
          ssh root@$ip chmod +x $target_sh
          ssh root@$ip $target_sh/$sh_name $ref_host	  
      fi
      ssh root@$ip systemctl enable chronyd.service
      ssh root@$ip systemctl restart chronyd.service
      ssh root@$ip cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
      ssh root@$ip  date +%z >>result.log
      ssh root@$ip chronyc sources>>result.log
  done;



