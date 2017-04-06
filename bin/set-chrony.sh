#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Set NTP"
rm -rf result.log

for ((i=0; i<${#nodes_map[@]}; i+=1));
do
  name=${nodes_name[$i]};
  ip=${nodes_map[$name]};
  ./style/print-info.sh $name 
  if [ $name = $ref_host  ]; then
    echo ""$ip
      sed -i -e '/server [0 1 2 3].centos.pool.ntp.org/d'  /etc/chrony.conf
      sed -i -e "s#\#local stratum#local stratum#g" /etc/chrony.conf
    echo "allow "$local_network >>/etc/chrony.conf
  else
    ssh root@$ip /bin/bash <<EOF
    sed -i -e 's#server 0.centos.pool.ntp.org#server '"$ref_host"'#g'  /etc/chrony.conf
    sed -i -e '/server [0 1 2 3].centos.pool.ntp.org/d'  /etc/chrony.conf
EOF
  fi
  ssh root@$ip systemctl enable chronyd.service && systemctl restart chronyd.service
  ssh root@$ip cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  ssh root@$ip date +%z >>result.log
  ssh root@$ip chronyc sources>>result.log
done;
