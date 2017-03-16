#!/bin/sh
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
for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
     name=${nodes_name[$i]};
     scp $tmp_file $name:$target
  done;
## check
./pssh/0-gen-hosts.sh
pssh -i -h pssh/nodes.txt hostname
### update hostname
echo "Please log in again and renew the local hostname!"
ssh `hostname`
