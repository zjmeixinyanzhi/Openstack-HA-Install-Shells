#!/bin/sh
nodes_name=(${!additionalNodes_map[@]});

base_location=$ftp_info
deploy_node=compute01
echo $deploy_node
blk_name=(${!blks_map[@]});


sh_name=compute_nodes_exec.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

### ssh
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${additionalNodes_map[$name]};
      echo "-------------$name------------"
      ssh-copy-id root@$ip
  done;

cd /root/my-cluster

osds="";
echo $osds

### set
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${additionalNodes_map[$name]};
      echo "-------------$name------------"
        for ((j=0; j<${#blks_map[@]}; j+=1));
          do
              name2=${blk_name[$j]};
              blk=${blks_map[$name2]};
              echo "-------------$name2:$blk------------";
              osds=$osds" "$name":"$blk;
	      ssh root@$ip ceph-disk zap /dev/$blk
          done
		  scp /etc/ceph/ceph.client.cinder.keyring  root@$name:/etc/ceph/
       # ssh root@$name  chown -R ceph:ceph $osd_path
  done;
echo $osds
### install ceph
ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-$ceph_release/el7/ ${nodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc

###[部署节点]激活OSD
ceph-deploy --overwrite-conf osd create $osds
ceph-deploy admin ${nodes_name[@]}

###查看集群状态
ceph -s

### install openstack services
for ((i=0; i<${#additionalNodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${additionalNodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      scp $source_sh root@$ip:$target_sh
      ssh root@$ip chmod -R +x $target_sh
      ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic $data_nic $password
  done;
