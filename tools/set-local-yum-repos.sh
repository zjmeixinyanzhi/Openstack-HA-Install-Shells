#!/bin/sh

declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

nodes_name=(${!nodes_map[@]});

base_location="ftp://192.168.100.81/pub/"

sh_name=generate_repo.sh
source_sh=$(echo `pwd`)/sh/$sh_name
yum_repos_dir=$(echo `pwd`)/sh/yum.repo/
target_sh=/root/tools/t_sh/bak/

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

