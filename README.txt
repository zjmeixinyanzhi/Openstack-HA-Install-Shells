Openstack HA平台部署shell 2.0脚本安装说明
目录结构：
install_shell_2.0
   ├── 2.0_ceph-deploy-tools   ### 计算&节点
   │   ├── sh
   │   └── wheel_ceph
   └── 2.0_tools               ### 控制节点部署脚本
       ├── sh
       └── t_sh


1~22、在controller01节点上进行基本配置和Openstack控制节点的部署，23~29在compute01上进行ceph集群的部署

1、根据实际部署环境，设置环境变量，并初始化
vim 0-set-config.sh
. 0-set-config.sh

2、测试部署环境的网络连通性：三个网络是否联通 
. test-network.sh

3、设置各节点之间免密码登录 
. set-ssh-nodes.sh

4、网卡配置（如果已设置可省略） 
. set-network-config.sh

5、设置主机名，控制节点命名 controller+数字（01、02、03）计算节点命名compute+数字（01、02、03……）
. set-hostname.sh

6、关闭防火墙禁用SELinux 需要重启节点，部署节点手动重启
. disable_firewall_selinux.sh

7、设置时间同步：与controller01时间同步 
. set-chrony.sh
可查看result.log检查chronyc resource的结果

8、制作本地软件源：需要将下载好的离线安装包放到指定FTP目录
. set-local-yum-repos.sh

9、安装Pacemaker  
. install-configure-pacemaker.sh
注意：默认设置认证用户密码与配置文件中一致

10、安装Haproxy
. install-configure-haproxy.sh

11、安装Galera 
. install-configure-galera.sh
注意：初始数据库时设置数据库Root密码与配置文件中一致
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保vip服务启动后按Ctrl+C结束查看

12、安装rabbit
 . install-configure-rabbitmq.sh
 注意：默认设置openstack认证用户密码与配置文件中一致
 
 13、安装memcached
 . install-configure-memcached.sh

 14、安装openstack安装包
 . install-configure-prerequisites.sh
 
 15、安装openstack Identity
. install-configure-keystone.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保keystone服务启动后按Ctrl+C结束查看
 
 16、安装openstack Image
 . install-configure-glance.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保glance服务启动后按Ctrl+C结束查看

17、安装openstack Compute
. install-configure-nova.sh 
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保nova服务启动后按Ctrl+C结束查看

18、安装openstack neutron
. install-configure-neutron.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保neutron服务启动后按Ctrl+C结束查看

19、安装openstack dashboard 
. install-configure-dashboard.sh

20、安装openstack cinder
. install-configure-cinder.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保cinder服务启动后按Ctrl+C结束查看

21、安装openstack Ceilometer
. install-configure-ceilometer.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保ceilometer服务启动后按Ctrl+C结束查看

22、安装openstack Aodh
. install-configure-aodh.sh
期间会执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保aodh服务启动后按Ctrl+C结束

切换到计算节点/存储节点部署

23、初始化安装环境的安装变量
0-set-config.sh 

24、存储节点与控制节点之间的ssh
. set-ssh-openstack-storage-nodes.sh

25、安装ceph-deploy
. install-prerequisites-ceph-deploy.sh

26、安装ceph block storage cluster
. install-configure-ceph-storage-cluster.sh
检查ceph存储网络所在网段

27、安装ceph auth client.key
. install-ceph-auth-client.key

28、配置计算节点
. install-compute-nodes-services.sh

29、删除全部安装脚本






