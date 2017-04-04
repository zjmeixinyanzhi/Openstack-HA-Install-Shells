#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Test Compute Nodes SSH"

scp pssh-exe root@$compute_host:/tmp/
scp -r ./hosts root@$compute_host:/tmp/ 

ssh root@$compute_host /bin/bash << EOF
  yum install -y pssh
  chmod +x /tmp/pssh-exe
  sed -i -e '/0-gen-hosts.sh/d' /tmp/pssh-exe
  cd /tmp
  /tmp/pssh-exe A date
  cp /etc/hosts /etc/hosts.bak2
  sed -i -e 's#'"$(echo $local_network|cut -d "." -f1-3)"'#'"$(echo $store_network|cut -d "." -f1-3)"'#g' /etc/hosts  
EOF
