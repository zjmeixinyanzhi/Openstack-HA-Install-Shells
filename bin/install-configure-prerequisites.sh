#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Openstack Prerequisites Installation"
./pssh-exe C "yum install -y centos-release-openstack-mitaka"
./pssh-exe C "yum install -y python-openstackclient openstack-selinux openstack-utils"
./pssh-exe C "rm -rf /etc/yum.repos.d/CentOS-*"
