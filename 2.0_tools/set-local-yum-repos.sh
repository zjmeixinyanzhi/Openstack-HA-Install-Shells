#!/bin/sh
nodes_name=(${!nodes_map[@]});
base_location=$ftp_info

sh_name=generate_repo.sh
source_sh=$(echo `pwd`)/sh/$sh_name
yum_repos_dir=$(echo `pwd`)/sh/yum.repo/
target_sh=$tmp_path/bak/

echo $yum_repos_dir

#### generate yum repos in current node
$source_sh $base_location $yum_repos_dir $ceph_release

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      ssh root@$ip rm -rf /etc/yum.repos.d/*
      ssh root@$ip yum clean all
      ssh root@$ip rm -rf /etc/yum.repos.d/CentOS-*
      ssh root@$ip rpmdb --rebuilddb
      ssh root@$ip ls -l /etc/yum.repos.d/
      scp -r $yum_repos_dir/* root@$ip:/etc/yum.repos.d/
      ssh root@$ip yum repolist all
      ssh root@$ip yum upgrade -y
  done;
