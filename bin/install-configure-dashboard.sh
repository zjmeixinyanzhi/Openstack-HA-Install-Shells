#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Dashboard Installation"

### [所有控制节点] 安装Dashboard
./pssh-exe C "yum install -y openstack-dashboard"
### [所有控制节点] 修改配置文件/etc/openstack-dashboard/local_settings
./scp-exe C "../conf/server-status.conf" "/etc/httpd/conf.d/server-status.conf"
for ((i=0; i<${#controller_map[@]}; i+=1));
do
  name=${controller_name[$i]};
  ip=${controller_map[$name]};
  ssh $ip /bin/bash << EOF  
  sed -i \
      -e 's#OPENSTACK_HOST =.*#OPENSTACK_HOST = "'"${virtual_ip}"'"#g' \
      -e "s#ALLOWED_HOSTS.*#ALLOWED_HOSTS = ['*',]#g" \
      -e "s#^CACHES#SESSION_ENGINE = 'django.contrib.sessions.backends.cache'\nCACHES#g#" \
      -e "s#locmem.LocMemCache'#memcached.MemcachedCache',\n        'LOCATION' : [ 'controller01:11211', 'controller02:11211', 'controller03:11211', ]#g" \
      -e 's#^OPENSTACK_KEYSTONE_URL =.*#OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST#g' \
      -e "s/^#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT.*/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True/g" \
      -e 's/^#OPENSTACK_API_VERSIONS.*/OPENSTACK_API_VERSIONS = {\n    "identity": 3,\n    "image": 2,\n    "volume": 2,\n}\n#OPENSTACK_API_VERSIONS = {/g' \
      -e "s/^#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN.*/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'default'/g" \
      -e 's#^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*#OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"#g' \
      -e "s#^LOCAL_PATH.*#LOCAL_PATH = '/var/lib/openstack-dashboard'#g" \
      -e "s#^SECRET_KEY.*#SECRET_KEY = '4050e76a15dfb7755fe3'#g" \
      -e "s#'enable_ha_router'.*#'enable_ha_router': True,#g" \
      /etc/openstack-dashboard/local_settings

  echo "COMPRESS_OFFLINE = True" >> /etc/openstack-dashboard/local_settings
  python /usr/share/openstack-dashboard/manage.py compress
  sed -i -e 's/^Listen.*/Listen  '"$ip"':80/g' /etc/httpd/conf/httpd.conf
  systemctl restart httpd.service
EOF
##### generate haproxy.cfg
. ./1-gen-haproxy-cfg.sh dashborad
done
