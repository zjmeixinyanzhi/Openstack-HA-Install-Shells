#!/bin/sh

declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" );

nodes_name=(${!nodes_map[@]});

service='mongod'

finish_flag=0 
while_flag=0

while [ $while_flag -lt 10 ]
do
  echo "#########Check all $service are running! ##########"
  finish_flag=0 
  for((i=0; i<${#nodes_map[@]}; i+=1));
    do
        name=${nodes_name[$i]};
        ip=${nodes_map[$name]};
        echo "-------------$name------------"
          status=$(ssh root@$ip systemctl status $service|grep Active:|awk '{print $3}'|grep "running")
          echo $status
        if [ $status != "" ];then
          echo "running"
        else
          echo "dead"
          let finish_flag++
        fi
    done;
  
  if [ $finish_flag -eq 0 ];then
    echo "All $service are running!"
    while_flag=10
  else
    echo "Please check the $service in pacemaker resource!"
    sleep 5
  fi
  let while_flag++
done

