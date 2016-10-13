#!/bin/sh
nodes_name=(${!nodes_map[@]});
base_location=$ftp_info

sh_name=generate_repo.sh
source_sh=$(echo `pwd`)/sh/$sh_name
yum_repos_dir=$(echo `pwd`)/sh/yum.repo/
target_sh=$tmp_path/bak/

echo $yum_repos_dir

#### generate yum repos in current node
$source_sh $base_location $yum_repos_dir

for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
      ssh root@$ip mkdir -p $target_sh
      ssh root@$ip mv /etc/yum.repos.d/*.repo $target_sh
      scp -r $yum_repos_dir/* root@$ip:/etc/yum.repos.d/
      ssh root@$ip yum upgrade -y
  done;
