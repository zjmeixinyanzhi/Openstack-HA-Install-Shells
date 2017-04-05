#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Memcached Installation"
./pssh-exe C "yum install -y memcached"
./pssh-exe C "systemctl enable memcached.service && systemctl start memcached.service"
