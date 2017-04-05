#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Ceph-deploy Installation"

base_location=../conf/wheel_ceph/
scp -r ../conf/wheel_ceph/ root@$compute_host:/tmp
ssh root@$compute_host /bin/bash << EOF
  yum install --nogpgcheck -y epel-release
  sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
  rm -rf /etc/yum.repos.d/epel*
  yum install -y python-pip
  yum install -y python-wheel
  pip install --use-wheel --no-index --trusted-host $(echo $ftp_info|awk -F "/" '{print $3}') --find-links=/tmp/wheel_ceph/ ceph-deploy
  ceph-deploy --version
EOF
