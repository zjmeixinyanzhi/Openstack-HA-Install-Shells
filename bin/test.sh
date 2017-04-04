#!/bin/sh
. ../0-set-config.sh
deploy_node=$compute_host
### 获取Monitor信息，用于生成ceph配置文件
monitor_name=(${!monitor_map[@]});
mon_hostname=""
mon_ip=""
### set mon nodes
for ((i=0; i<${#monitor_map[@]}; i+=1));
do
  name=${monitor_name[$i]};
  ip=${monitor_map[$name]};
  echo "-------------$name------------"
  if [ $name =  $deploy_node ]; then
    echo $name" already is mon!"
  else
   mon_hostname=$mon_hostname","$name
   mon_ip=$mon_ip","$(echo $store_network|cut -d "." -f1-3).$(echo $ip|awk -F "." '{print $4}')
  fi
done;
echo $mon_hostname" >>${#monitor_map[@]}  "$mon_ip

ssh root@$compute_host /bin/bash << EOF
cd /root/my-cluster
cat /root/my-cluster/ceph.conf |grep mon_initial_members
sed -i -e 's#'"$(ssh root@$compute_host cat /root/my-cluster/ceph.conf |grep mon_initial_members)"'#'"$(ssh root@$compute_host cat /root/my-cluster/ceph.conf |grep mon_initial_members)$mon_hostname"'#g' /root/my-cluster/ceph.conf
sed -i -e 's#'"$(ssh root@$compute_host cat /root/my-cluster/ceph.conf |grep mon_host )"'#'"$(ssh root@$compute_host  cat /root/my-cluster/ceph.conf |grep mon_host )$mon_ip"'#g' /root/my-cluster/ceph.conf
pwd
EOF
