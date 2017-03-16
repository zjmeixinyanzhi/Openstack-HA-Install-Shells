#!/bin/sh

nodes_name=(${!nodes_map[@]});
tmp_file=hosts.bak
target=/etc/hosts
rm -rf  $tmp_file
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
pscp -h nodes.txt $tmp_file /etc/hosts
## check
pssh -i -h nodes.txt hostname
### update hostname
echo "Please log in again and renew the local hostname!"
exit
