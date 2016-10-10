#!/bin/sh

declare -A nodes_map=(["compute01"]="11.11.11.14" ["compute02"]="11.11.11.15" ["compute03"]="11.11.11.16");

nodes_name=(${!nodes_map[@]});

base_location=ftp://192.168.100.81/pub/
deploy_node=compute01
echo $deploy_node

storage_nic='eno33554960'
public_ip=$(ip addr show dev $storage_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g')
echo $storage_nic $public_ip

ceph-deploy forgetkeys
ceph-deploy purge  ${nodes_name[@]}  
ceph-deploy purgedata   ${nodes_name[@]} 

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
        ssh root@$ip  rm -rf /osd/*
  done;


mkdir -p /root/my-cluster
cd /root/my-cluster
rm -rf /root/my-cluster/*
ceph-deploy new $deploy_node
sed -i -e 's#192.168.2#11.11.11#g' ceph.conf
echo "public network ="$(ip addr show dev $storage_nic scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|cut -d "." -f1-3
)".0/24">>ceph.conf


ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-jewel/el7/ ${nodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc
ceph-deploy mon create-initial

osds="";
echo $osds

### set 
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
	osds=$osds" "$name":/osd"
	ssh root@$ip  chown -R ceph:ceph /osd/
  done;
echo $osds
###[部署节点]激活OSD
ceph-deploy osd prepare $osds
ceph-deploy osd activate $osds
ceph-deploy admin ${nodes_name[@]}


### set
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
	if [ $name =  $deploy_node ]; then
          echo $name" already is mon!"
	else
	  ceph-deploy mon add $name
        fi        
  done;

###查看集群状态
ceph -s
###[ceph管理节点]创建Pool
ceph osd pool create volumes 128
ceph osd pool create images 128
ceph osd pool create backups 128
ceph osd pool create vms 128

