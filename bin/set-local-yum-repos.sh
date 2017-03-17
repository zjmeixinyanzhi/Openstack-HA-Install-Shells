#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Set Yum Repositories"
yum_repos_dir=$(echo `pwd`)/../conf/yum.repos.d/
mkdir -p $yum_repos_dir
#### generate yum repos in current node
./generate_repo.sh $ftp_info $yum_repos_dir $ceph_release
### clear old yum 
./pssh-exe A "rm -rf /etc/yum.repos.d/*"
### scp to all nodes
./scp-exe A "$yum_repos_dir/" "/etc/"
###
./pssh-exe A "rpmdb --rebuilddb && yum repolist all && yum upgrade -y "
