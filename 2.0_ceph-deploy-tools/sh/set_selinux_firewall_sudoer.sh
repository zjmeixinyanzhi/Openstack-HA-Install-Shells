#!/bin/sh
### disable firewall
systemctl disable firewalld.service
systemctl stop firewalld.service
### disable selinux
sed -i -e "s#SELINUX=enforcing#SELINUX=disabled#g" /etc/selinux/config
sed -i -e "s#SELINUXTYPE=targeted#\#SELINUXTYPE=targeted#g" /etc/selinux/config
###set ceph ssh
sed -i -e 's#Defaults   *requiretty#Defaults:ceph !requiretty#g' /etc/sudoers
