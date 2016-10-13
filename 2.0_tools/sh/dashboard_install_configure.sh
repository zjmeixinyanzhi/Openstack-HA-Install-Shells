#!/bin/sh
vip='192.168.2.201'
vip=$1
local_bridge=$2 
echo $vip $local_nic $data_nic
yum install -y openstack-dashboard
### [所有控制节点] 修改配置文件/etc/openstack-dashboard/local_settings
sed -i \
    -e 's#OPENSTACK_HOST =.*#OPENSTACK_HOST = "'"$vip"'"#g' \
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

### [所有控制节点] ？？？
echo "COMPRESS_OFFLINE = True" >> /etc/openstack-dashboard/local_settings 
python /usr/share/openstack-dashboard/manage.py compress

### [所有控制节点] 设置HTTPD在特定的IP上监听
sed -i -e 's/^Listen.*/Listen  '"$(ip addr show dev $local_bridge scope global | grep "inet " | sed -e 's#.*inet ##g' -e 's#/.*##g'|head -n 1)"':80/g' /etc/httpd/conf/httpd.conf 

### [所有控制节点] 添加pacemaker监测httpd的配置文件
echo "<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from localhost
</Location>">/etc/httpd/conf.d/server-status.conf

systemctl restart httpd.service 
