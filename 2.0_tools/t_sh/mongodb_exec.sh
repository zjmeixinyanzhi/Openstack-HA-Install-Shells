#!/bin/sh
yum install -y mongodb-server mongodb
sed -i \
-e 's#.*bind_ip.*#bind_ip = 0.0.0.0#g' \
-e 's/.*replSet.*/replSet = ceilometer/g' \
-e 's/.*smallfiles.*/smallfiles = true/g' \
/etc/mongod.conf

systemctl start mongod
systemctl stop mongod
