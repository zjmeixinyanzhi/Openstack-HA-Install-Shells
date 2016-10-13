#!/bin/sh
 ### [所有控制节点] 安装软件
yum install -y haproxy
### [所有控制节点] 修改/etc/rsyslog.d/haproxy.conf文件
echo "\$ModLoad imudp" >> /etc/rsyslog.d/haproxy.conf;
echo "\$UDPServerRun 514" >> /etc/rsyslog.d/haproxy.conf;
echo "local3.* /var/log/haproxy.log" >> /etc/rsyslog.d/haproxy.conf;
echo "&~" >> /etc/rsyslog.d/haproxy.conf;
### [所有控制节点] 修改/etc/sysconfig/rsyslog文件
sed -i -e 's#SYSLOGD_OPTIONS=\"\"#SYSLOGD_OPTIONS=\"-c 2 -r -m 0\"#g' /etc/sysconfig/rsyslog
### [所有控制节点] 重启rsyslog服务
systemctl restart rsyslog
