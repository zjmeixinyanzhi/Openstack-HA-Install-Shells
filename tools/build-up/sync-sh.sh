#!/bin/sh
for i in 192.168.2.11; do 
scp -r /root/build-up $i:/root/tools/
done
