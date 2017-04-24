#!/bin/sh
. ../0-set-config.sh
. ./style/print-warnning.sh "Pcs cluster is restarting! \nIf have started, please press Ctrl+C to terminate and it'll continue!"
ssh root@$network_host pcs cluster stop --all
sleep 5
#ps aux|grep "pcs cluster stop --all"|grep -v grep|awk '{print $2 }'|xargs kill
./pssh-exe N "pcs cluster kill"
ssh root@$network_host /bin/bash << EOF
  pcs cluster stop --all
  pcs cluster kill --all
  pcs cluster start --all
  sleep 10
  pcs resource
  pcs resource|grep Stop
  pcs resource|grep FAILED
EOF
