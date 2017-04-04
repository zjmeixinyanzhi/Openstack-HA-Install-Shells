#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Ceph Storage Cluster Installation"

base_location=$ftp_info
deploy_node=$compute_host
pool_size=256
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
### 获取OSD信息，用于生成并激活OSD
blk_name=(${!blks_map[@]});
osds="";
echo $osds
for ((i=0; i<${#nodes_map[@]}; i+=1));
do
  name=${nodes_name[$i]};
  ip=${nodes_map[$name]};
  echo "-------------$name------------";
  for ((j=0; j<${#blks_map[@]}; j+=1));
  do
    name2=${blk_name[$j]};
    blk=${blks_map[$name2]};
    echo "-------------$name2:$blk------------";
    osds=$osds" "$name":"$blk;
  done
done
echo $osds

echo $deploy_node
##重置为裸盘
for ((i=0; i<${#nodes_map[@]}; i+=1));
do
  name=${nodes_name[$i]};
  ip=${nodes_map[$name]};
  echo "-------------$name------------";
  for ((j=0; j<${#blks_map[@]}; j+=1));
  do
    name2=${blk_name[$j]};
    blk=${blks_map[$name2]};
    echo "-------------$name2:$blk------------";
    ssh root@$ip ceph-disk zap /dev/$blk
  done
done
ssh root@$compute_host /bin/bash << EOF
  ceph-deploy forgetkeys
  ceph-deploy purge ${nodes_name[@]}
  ceph-deploy purgedata ${nodes_name[@]}
  mkdir -p /root/my-cluster
  cd /root/my-cluster
  rm -rf /root/my-cluster/*
  ceph-deploy new $deploy_node
  sed -i -e 's#'"$(cat ceph.conf |grep mon_initial_members)"'#'"$(cat ceph.conf |grep mon_initial_members)$mon_hostname"'#g' ceph.conf
  sed -i -e 's#'"$(cat ceph.conf |grep mon_host )"'#'"$(cat ceph.conf |grep mon_host )$mon_ip"'#g' ceph.conf
  echo "public network ="$store_network>>ceph.conf
  ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-$ceph_release/el7/ ${nodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc
  #ceph-deploy mon create-initial
  #ceph-deploy osd create $osds
  #ceph-deploy admin ${nodes_name[@]}
EOF
### set  mon nodes
#for ((i=0; i<${#monitor_map[@]}; i+=1));
#do
#  name=${monitor_name[$i]};
#  ip=${monitor_map[$name]};
#  echo "-------------$name------------"
#  if [ $name =  $deploy_node ]; then
#    echo $name" already is mon!"
#  else
#    ssh root@$deploy_node cd /root/my-cluster && ceph-deploy mon add $name
#  fi
#done;
####查看集群状态 ceph管理节点创建Pool
#ssh root@$deploy_node /bin/bash << EOF
#  ceph -s
#  ceph osd pool create volumes $pool_size
#  ceph osd pool create images $pool_size
#  ceph osd pool create backups $pool_size
#  ceph osd pool create vms $pool_size
#EOF
