#!/bin/sh
### 设置部署节点主机名和IP，nodes_map为全部节点、controller_map为三个控制节点、hypervisor_map为计算节点（与存储节点融合）
declare -A nodes_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13" ["network01"]="192.168.2.14" ["network02"]="192.168.2.15" ["network03"]="192.168.2.16" ["compute01"]="192.168.2.17" ["compute02"]="192.168.2.18" ["compute03"]="192.168.2.19" ["compute04"]="192.168.2.20")
declare -A controller_map=(["controller01"]="192.168.2.11" ["controller02"]="192.168.2.12" ["controller03"]="192.168.2.13");
declare -A networker_map=(["network01"]="192.168.2.14" ["network02"]="192.168.2.15" ["network03"]="192.168.2.16");
declare -A hypervisor_map=(["compute01"]="192.168.2.17" ["compute02"]="192.168.2.18" ["compute03"]="192.168.2.19");
declare -A monitor_map=(["controller01"]="192.168.2.11" ["network01"]="192.168.2.14" ["compute01"]="192.168.2.17");

declare nodes_name=(${!nodes_map[@]});
declare controller_name=(${!controller_map[@]});
declare networker_name=(${!networker_map[@]});
declare hypervisor_name=(${!hypervisor_map[@]});
### 后期需要增加的计算节点
declare -A additionalNodes_map=(["compute04"]="192.168.2.20");
### NTP主机
ref_host=controller01
### 网络HA集群默认部署节点（必须存在该主机名的节点）
network_host=network01
### 计算节点默认部署节点（必须存在该主机名的节点）
compute_host=compute01
### 设置虚拟IP，virtual_ip为openstack服务的虚拟IP，virtual_ip_redis为Redis为虚拟IP
virtual_ip=192.168.2.241
virtual_ip_redis=192.168.2.242
### 设置网卡信息 local_nic为管理网网卡名称 data_nic为虚拟网网卡名称 storage_nic为存储网网卡信息 local_bridge为外网网桥名称
local_nic=eno16777736
data_nic=eno33554960
storage_nic=eno50332184
local_bridge=br-ex
### 设置网络网段信息，分别对应管理网、虚拟网、存储网
local_network=192.168.2.0/24
data_network=10.10.10.0/24
store_network=11.11.11.0/24
### 离线安装源的FTP目录信息
ftp_info="ftp://192.168.100.81/pub/"
### 临时目录，用于scp存放配置脚本
tmp_path=/root/tools/t_sh/
### 存储节点上OSD盘挂载目录 所有节点统一成一个
declare -A blks_map=(["osd01"]="sdb" ["osd02"]="sdc" ["osd03"]="sdd");
#osd_path=/osd
### ceph安装版本
ceph_release=jewel

### Openstack各组件的数据库密码，所有服务统一成一个
password=9b15318364bb66e1
### Pacemaker密码
password_ha_user=9b15318364bb66e1
### Mariadb数据库Root密码
password_galera_root=a263f6a89fa2
### Mongodb数据库Root密码
password_mongo_root=a263f6a89fa2
### Rabbitm密码
passsword_rabbitmq=9b15318364bb66e1
### Openstack admin用户密码
password_openstack_admin=9b15318364bb66e1
