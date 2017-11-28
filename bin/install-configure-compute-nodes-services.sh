#!/bin/sh
. ../0-set-config.sh
### 设置计算节点间Nova用户的SSH
./style/print-split.sh "Set nova user ssh between compute nodes"
./pssh-exe A "usermod -s /bin/bash nova"
su - nova -c "ssh-keygen -t rsa"
cat << EOF > /var/lib/nova/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF
cat /var/lib/nova/.ssh/id_rsa.pub > /var/lib/nova/.ssh/authorized_keys
chmod 600 /var/lib/nova/.ssh/authorized_keys
./scp-exe H /var/lib/nova/.ssh/ /var/lib/nova/
./pssh-exe H "chown nova:nova -R /var/lib/nova/.ssh/"
./pssh-exe H "su - nova -c 'ssh nova@compute02 cd ~ && pwd'"
### 安装Openstack服务
./style/print-split.sh "Openstack Services Installation on Compute Nodes"
./scp-exe H compute_nodes_exec.sh /tmp
./pssh-exe H "chmod +x /tmp/compute_nodes_exec.sh"
./pssh-exe H "/tmp/compute_nodes_exec.sh $virtual_ip $local_nic $data_nic $password"
