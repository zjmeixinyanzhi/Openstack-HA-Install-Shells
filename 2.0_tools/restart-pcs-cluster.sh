#!/bin/sh
pcs cluster stop --all
sleep 10
#ps aux|grep "pcs cluster stop --all"|grep -v grep|awk '{print $2 }'|xargs kill
for i in 01 02 03; do ssh controller$i pcs cluster kill; done
pcs cluster stop --all
pcs cluster start --all
sleep 5
watch -n 0.5 pcs resource
echo "pcs resource"
pcs resource
pcs resource|grep Stop
pcs resource|grep FAILED
