#!/bin/sh

#base_location="ftp://192.168.100.81/pub/"
base_location=$1
target_dir=$2
ceph_release=$3

###### centos.repo
echo "[centos-base]
name=centos-base
baseurl=${base_location}CentOS-7.2-X86_64/base
gpgcheck=0
enabled=1
# centos-extras reporisoty
[centos-extras]
name=centos-extras
baseurl=${base_location}CentOS-7.2-X86_64/extras
gpgcheck=0
enabled=1
# centos-updates reporisoty
[centos-updates]
name=centos-updates
baseurl=${base_location}CentOS-7.2-X86_64/updates
gpgcheck=0
enabled=1">${target_dir}/centos.repo

###### openstack-mitaka.repo
echo "[openstack-mitaka]
name=openstack-mitaka
baseurl=${base_location}Openstack-Mitaka/openstack-mitaka/
gpgcheck=0
enabled= 1
">${target_dir}/openstack-mitaka.repo

##### Galera.repo
echo "# MariaDB 10.1 CentOS repository list
[mariadb]
name = MariaDB
baseurl = ${base_location}yum.mariadb.org/10.1/centos7-amd64
gpgcheck=0
">${target_dir}/Galera.repo

##### ceph.repo
echo "[ceph-noarch]
name = Ceph noarch packages
baseurl = ${base_location}download.ceph.com/rpm-${ceph_release}/el7/noarch
gpgcheck=0
">${target_dir}/ceph.repo

##### dl.fedoraproject.org_pub_epel_7_x86_64_.repo
echo "[dl.fedoraproject.org_pub_epel_7_x86_64_]
name=added from: dl.fedoraproject.org/pub/epel/7/x86_64//
baseurl=${base_location}dl.fedoraproject.org/pub/epel/7/x86_64//
enabled=1
gpgcheck=0
">${target_dir}/dl.fedoraproject.org_pub_epel_7_x86_64_.repo

