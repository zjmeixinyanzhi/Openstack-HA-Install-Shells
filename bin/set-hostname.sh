#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Set HOSTNAME & HOSTS"
curr_dir=$(echo `pwd`)

tmp_file=../conf/hosts.bak
target=/etc/hosts
rm -rf $tmp_file
touch $tmp_file
### generate host file
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
    name=${nodes_name[$i]};
    ip=${nodes_map[$name]};
    echo "$ip $name">>$tmp_file
    ssh root@$ip hostnamectl --static set-hostname $name
  done;
cat $tmp_file
### scp to other nodes
./scp-exe A $tmp_file $target
## check
. ./0-gen-hosts.sh
pssh -i -h hosts/nodes.txt hostname
### update hostname
./style/print-info.sh "Re-login to update the local hostname!"
ssh `hostname` cd $curr_dir
