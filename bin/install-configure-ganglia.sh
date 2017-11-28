#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Ganglia Installation"
./pssh-exe A "yum install -y ganglia-gmond"
### 生成配置文件
master_ip=${nodes_map["${ref_host}"]}
echo $master_ip
sed \
  -e "s/GANGLIA_HOST_IP/$master_ip/g" \
  -e "s/GANGLIA_BIND_IP/$master_ip/g" \
../conf/ganglia/gmond-master.conf > /tmp/gmond-master.conf
sed -e "s/GANGLIA_HOST_IP/$master_ip/g" \
../conf/ganglia/gmond-slave.conf > /tmp/gmond-slave.conf 
./pssh-exe A "mv -f /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.backup"
./scp-exe A "/tmp/gmond-slave.conf" "/etc/ganglia/gmond.conf"
### [controller01] 修改/etc/ganglia/gmond.conf
\cp /tmp/gmond-master.conf /etc/ganglia/gmond.conf
./pssh-exe A "systemctl enable gmond && systemctl restart gmond"
### 监控结果测试
telnet $master_ip 8649 | tee ganglia_result.log 
