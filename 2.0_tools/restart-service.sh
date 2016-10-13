#!/bin/sh
for i in 01 02 03; do
 for j in $@; do
    echo "  "$j "in controller"$i 
    ssh controller$i systemctl restart $j;
    ssh controller$i systemctl status $j |grep Active:;
 done
done
