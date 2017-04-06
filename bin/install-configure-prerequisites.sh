#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Openstack Prerequisites Installation"
./pssh-exe A "yum install -y centos-release-openstack-mitaka"
./pssh-exe A "yum install -y python-openstackclient openstack-selinux openstack-utils"
./pssh-exe A "rm -rf /etc/yum.repos.d/CentOS-*"
