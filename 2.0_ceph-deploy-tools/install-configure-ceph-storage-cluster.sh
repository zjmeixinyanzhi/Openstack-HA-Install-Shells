
#!/bin/sh
#declare -A hypervisor_map=(["compute01"]="11.11.11.14" ["compute02"]="11.11.11.15" ["compute03"]="11.11.11.16");

nodes_name=(${!hypervisor_map[@]});

base_location=$ftp_info
deploy_node=compute01
echo $deploy_node

cp /etc/hosts /etc/hosts.bak.tmp
sed -i -e 's#'"$(echo $local_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' /etc/hosts

ceph-deploy forgetkeys
ceph-deploy purge  ${nodes_name[@]}
ceph-deploy purgedata   ${nodes_name[@]}

for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        ssh root@$name  rm -rf /osd/*
  done;

mkdir -p /root/my-cluster
cd /root/my-cluster
rm -rf /root/my-cluster/*
ceph-deploy new $deploy_node
sed -i -e 's#'"$(echo $local_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' ceph.conf
echo "public network ="$store_network>>ceph.conf

ceph-deploy install --nogpgcheck --repo-url $base_location/download.ceph.com/rpm-jewel/el7/ ${nodes_name[@]} --gpg-url $base_location/download.ceph.com/release.asc
ceph-deploy mon create-initial

osds="";
echo $osds

### set
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        osds=$osds" "$name":/osd"
        ssh root@$name  chown -R ceph:ceph /osd/
  done;
echo $osds
###[部署节点]激活OSD
ceph-deploy osd prepare $osds
ceph-deploy osd activate $osds
ceph-deploy admin ${nodes_name[@]}


### set
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
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

mv /etc/hosts.bak.tmp /etc/hosts

