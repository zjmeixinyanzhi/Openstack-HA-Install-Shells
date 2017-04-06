#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Haproxy Installation"
### [所有控制节点] 安装软件
./pssh-exe C "yum install -y haproxy"
### [所有控制节点] 修改/etc/rsyslog.d/haproxy.conf文件
./scp-exe C ../conf/rsyslog_haproxy.conf /etc/rsyslog.d/haproxy.conf
### [所有控制节点] 修改/etc/sysconfig/rsyslog文件
./pssh-exe C "sed -i -e 's#SYSLOGD_OPTIONS=\"\"#SYSLOGD_OPTIONS=\"-c 2 -r -m 0\"#g' /etc/sysconfig/rsyslog"
### [所有控制节点] 重启rsyslog服务
./pssh-exe C "systemctl restart rsyslog"
### [controller01]在pacemaker集群增加haproxy资源
pcs resource create haproxy systemd:haproxy --clone
pcs constraint order start vip then haproxy-clone kind=Optional
pcs constraint colocation add haproxy-clone with vip
. ./restart-pcs-cluster.sh
ping -c 3 $virtual_ip
