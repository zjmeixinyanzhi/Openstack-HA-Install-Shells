#!/bin/sh
nodes_name=(${!hypervisor_map[@]});

base_location=./wheel_ceph/

sh_name=set_selinux_firewall_sudoer.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

yum install --nogpgcheck -y epel-release
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
rm -rf /etc/yum.repos.d/epel*
yum install -y python-pip
yum install -y python-wheel
pip install --use-wheel --no-index --trusted-host $(echo $ftp_info|awk -F "/" '{print $3}') --find-links=$base_location ceph-deploy
ceph-deploy --version

### set 
for ((i=0; i<${#hypervisor_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${hypervisor_map[$name]};
      echo "-------------$name------------"
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name
  done;

