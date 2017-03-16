#!/bin/sh
#### controller01
subnet=$local_network

ref_host=controller01

sh_name=replace_ntp_hosts.sh
source_sh=./sh/$sh_name
target_sh=$tmp_path

nodes_name=(${!nodes_map[@]});

rm -rf result.log

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      if [ $name = $ref_host  ]; then
          echo ""$ip
	    sed -i -e '/server [0 1 2 3].centos.pool.ntp.org/d'  /etc/chrony.conf
	    sed -i -e "s#\#local stratum#local stratum#g" /etc/chrony.conf
          echo "allow "$subnet >>/etc/chrony.conf
      else
          ssh root@$ip mkdir -p $target_sh
          scp $source_sh root@$ip:$target_sh
          ssh root@$ip chmod +x $target_sh
          ssh root@$ip $target_sh/$sh_name $ref_host
      fi
      ssh root@$ip systemctl enable chronyd.service
      ssh root@$ip systemctl restart chronyd.service
      ssh root@$ip cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
      ssh root@$ip date +%z >>result.log
      ssh root@$ip chronyc sources>>result.log
  done;
