Openstack HA平台部署shell 2.0脚本安装说明
=================================== 
###目录结构：
</br>install_shell_2.0
</br>   ├── 2.0_ceph-deploy-tools   ### 计算节点部署脚本
</br>   │   ├── sh                  ### 需要scp到各个计算节点执行的脚本
</br>   │   └── wheel_ceph
</br>   └── 2.0_tools               ### 控制节点部署脚本
</br>       ├── sh                  ### 需要scp到各个控制节点执行的脚本
</br>       └── t_sh                ### 各节点存放脚本的临时目录


注意：1~22、在controller01节点上进行基本配置和Openstack控制节点的部署，23~29在compute01上进行ceph集群的部署

1、根据实际部署环境，设置环境变量，并初始化
</br> vim 0-set-config.sh
</br> . 0-set-config.sh

2、测试部署环境的网络连通性：三个网络是否联通 
</br> . test-network.sh

3、设置各节点之间免密码登录 
</br> . set-ssh-nodes.sh

4、网卡配置（如果已设置可省略） 
</br> . set-network-config.sh

5、设置主机名，控制节点命名 controller+数字（01、02、03）计算节点命名compute+数字（01、02、03……）
</br> . set-hostname.sh

6、关闭防火墙禁用SELinux 需要重启节点，部署节点手动重启
</br> . disable_firewall_selinux.sh

7、设置时间同步：与controller01时间同步 
</br> . set-chrony.sh

8、制作本地软件源：需要将下载好的离线安装包放到指定FTP目录
</br> . set-local-yum-repos.sh

9、安装Pacemaker  
</br> . install-configure-pacemaker.sh
</br> 注意：默认设置认证用户密码与配置文件中一致

10、安装Haproxy
</br> . install-configure-haproxy.sh

11、安装Galera 
</br> . install-configure-galera.sh
注意：初始数据库时设置数据库Root密码与配置文件中一致
如果无法通过vip访问数据库，执行restart-pcs-cluster.sh重启pcs集群后再检查
</br> . restart-pcs-cluster.sh

12、安装rabbit
 </br> . install-configure-rabbitmq.sh
 </br> 注意：默认设置openstack认证用户密码与配置文件中一致
 
 13、安装memcached
 </br> . install-configure-memcached.sh

 14、安装openstack安装包
</br>  . install-configure-prerequisites.sh
 
 15、安装openstack Identity
</br> . install-configure-keystone.sh
</br> 执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource,确保keystone服务启动
</br> . restart-pcs-cluster.sh
 
 16、安装openstack Image
</br> . install-configure-glance.sh
</br>  执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保glance服务启动
</br> . restart-pcs-cluster.sh

17、安装openstack Compute
</br> . install-configure-nova.sh 
</br>  执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保nova服务启动
</br> . restart-pcs-cluster.sh

18、安装openstack neutron
</br> . install-configure-neutron.sh
</br>  执行restart-pcs-cluster.sh重启pcs集群后检查pcs resource，确保neutron服务启动
</br> . restart-pcs-cluster.sh

19、安装openstack dashboard 
</br> . install-configure-dashboard.sh

20、安装openstack cinder
</br> . install-configure-cinder.sh

21、安装openstack Ceilometer
</br> . install-configure-ceilometer.sh

22、安装openstack Aodh
</br> . install-configure-aodh.sh

23、安装计算&存储节点的ssh 
</br> . set-ssh-openstack-storage-nodes.sh

24、安装ceph-deploy
</br> . install-prerequisites-ceph-deploy.sh
 
25、安装ceph block storage cluster
</br> . install-configure-ceph-storage-cluster.sh
</br> 检查ceph存储网络所在网段

27、存储节点与控制节点之间的ssh
</br> . set-ssh-openstack-storage-nodes.sh

28、安装ceph auth client.key
</br> . install-ceph-auth-client.key

29、配置计算节点
</br> . install-compute-nodes-services.sh

30、删除安装脚本
</br>. delete-tmp-shells.sh





