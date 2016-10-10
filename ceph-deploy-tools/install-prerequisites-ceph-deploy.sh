#!/bin/sh

declare -A nodes_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16");

nodes_name=(${!nodes_map[@]});

base_location=./wheel_ceph/

sh_name=set_selinux_firewall_sudoer.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/


yum install --nogpgcheck -y epel-release
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
rm -rf /etc/yum.repos.d/epel*
yum install -y python-pip
yum install -y python-wheel
pip install --use-wheel --no-index --trusted-host 192.168.100.81 --find-links=$base_location ceph-deploy
ceph-deploy --version

### set 
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
  done;

