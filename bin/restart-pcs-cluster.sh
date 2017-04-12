#!/bin/sh
. ./style/print-warnning.sh "Pcs cluster is restarting! \nIf have started, please press Ctrl+C once to terminate and it'll continue!"
pcs cluster stop --all
sleep 10
#ps aux|grep "pcs cluster stop --all"|grep -v grep|awk '{print $2 }'|xargs kill
./pssh-exe C "pcs cluster kill"
pcs cluster stop --all
pcs cluster start --all
sleep 5
watch -n 0.5 pcs resource
echo "pcs resource"
pcs resource
pcs resource|grep Stop
pcs resource|grep FAILED
