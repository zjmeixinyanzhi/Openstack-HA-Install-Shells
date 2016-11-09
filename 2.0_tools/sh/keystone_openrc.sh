#!/bin/sh
vip='192.168.2.201'
vip=$1
echo $vip
password=$2
### [所有控制节点]编辑/etc/keystone/keystone-paste.ini
sed -i -e 's#admin_token_auth ##g' /etc/keystone/keystone-paste.ini 
unset OS_TOKEN OS_URL
### 生成keystonerc_admin脚本
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${password}
export OS_AUTH_URL=http://${vip}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone_admin)]\$ '
">/root/keystonerc_admin
chmod +x /root/keystonerc_admin
