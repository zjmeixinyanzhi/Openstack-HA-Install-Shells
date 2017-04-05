#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Additional Compute Nodes' Installation and Configuration"

additionalnodes_name=(${!additionalNodes_map[@]});
base_location=$ftp_info
deploy_node=$compute_host
echo $deploy_node
blk_name=(${!blks_map[@]});
osds="";
### 获取OSD信息，用于生成并激活OSD
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
do
  name=${additionalnodes_name[$i]};
  ip=${additionalNodes_map[$name]};
  for ((j=0; j<${#blks_map[@]}; j+=1));
  do
    name2=${blk_name[$j]};
    blk=${blks_map[$name2]};
    echo "-------------$name:$name2------------";
    osds=$osds" "$name":"$blk;
    ssh root@$ip ceph-disk zap /dev/$blk
  done
  scp /etc/ceph/ceph.client.cinder.keyring  root@$name:/etc/ceph/
  # ssh root@$name  chown -R ceph:ceph $osd_path
done;
echo $osds
### install ceph
ssh root@$compute_host /bin/bash << EOF
  cd /root/my-cluster
  ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-$ceph_release/el7/ ${additionalnodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc
  ###[部署节点]激活OSD
  ceph-deploy --overwrite-conf osd create $osds
  ceph-deploy admin ${additionalnodes_name[@]}
EOF
###查看集群状态
ceph -s
### install openstack services
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
do
  name=${additionalnodes_name[$i]};
  ip=${additionalNodes_map[$name]};
  . style/print-info.sh "$name configuration" 
  scp compute_nodes_exec.sh root@$ip:/tmp
  ssh root@$ip chmod +x /tmp/compute_nodes_exec.sh 
  ssh root@$ip /tmp/compute_nodes_exec.sh $virtual_ip $local_nic $data_nic $password
done;
