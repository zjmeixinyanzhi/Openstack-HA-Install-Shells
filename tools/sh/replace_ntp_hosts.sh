 #!/bin/sh
ref_host=$1
sed -i -e 's#server 0.centos.pool.ntp.org#server '"$ref_host"'#g'  /etc/chrony.conf
sed -i -e '/server [0 1 2 3].centos.pool.ntp.org/d'  /etc/chrony.conf
