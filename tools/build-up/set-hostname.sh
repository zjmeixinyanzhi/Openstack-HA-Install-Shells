#!/bin/sh
declare -A controller_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13");
declare -A hypervisor_map=(["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16");
declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["compute01"]="192.168.2.14" ["compute02"]="192.168.2.15" ["compute03"]="192.168.2.16" );

controllers=(${!controller_map[@]});
computes=(${!hypervisor_map[@]});
nodes_name=(${!nodes_map[@]});

tmp_file=/etc/hosts.bak
target=/etc/hosts

#for c in ${controllers[@]};
#  do
#  echo $c
#
#  done

####clear tmp_file
rm -rf  $tmp_file

#for ((i=0; i<${#controllers[@]}; i+=1));
#  do
#      name=${controllers[$i]};
#      ip=${controller_map[$name]};
#      echo "$ip $name" >>$tmp_file
#      #echo "$ip $name"
#  done;
#for ((i=0; i<${#computes[@]}; i+=1));
#  do
#      name=${computes[$i]};
#      ip=${hypervisor_map[$name]};
#      echo "$ip $name">>$tmp_file
#      #echo "$ip $name"
#  done;


for ((i=0; i<${#nodes_map[@]}; i+=1));
  do
      name=${nodes_name[$i]};
      ip=${nodes_map[$name]};
      echo "$ip $name">>$tmp_file
  done;

