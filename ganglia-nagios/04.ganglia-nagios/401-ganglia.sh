#!/bin/sh

###
### deploy openstack ha cluster 
### 
### run from the first controller node, it'll be the ganglia reciever
###

. ../000-common.sh

file_full_name=`basename "$0"`
file_extension="${file_full_name##*.}"
file_name="${file_full_name%.*}"
log_file="/tmp/"$file_name".log"

echo > $log_file

function install_ganglia() {
    ### [controller01] 安装软件
    echo "=== TRACE MESSAGE ===>>> " "安装软件" | tee -a $log_file
    yum install -y ganglia-gmond >> $log_file

    controller_0_mgmt_ip=${controller_mgmt_nic_map[$controller_0]}
    ### [controller01] 修改/etc/ganglia/gmond.conf
    echo "=== TRACE MESSAGE ===>>> " "修改/etc/ganglia/gmond.conf" | tee -a $log_file
    sed \
        -e "s/GANGLIA_HOST_IP/$controller_0_mgmt_ip/g" \
        -e "s/GANGLIA_BIND_IP/$controller_0_mgmt_ip/g" \
        ganglia/gmond-master.conf > /tmp/gmond.conf
    mv -f /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.backup
    cp /tmp/gmond.conf /etc/ganglia/

    ### [controller01] 配置服务
    echo "=== TRACE MESSAGE ===>>> " "配置服务" | tee -a $log_file
    systemctl enable gmond >> $log_file
    systemctl start gmond >> $log_file

    for ((i=1;i<${#controllers[@]};i+=1))
    do
        ### [其他控制节点] 安装软件
        echo "=== TRACE MESSAGE ===>>> " ${controllers[$i]} ": 安装软件" | tee -a $log_file
        ssh ${controllers[$i]} yum install -y ganglia-gmond >> $log_file

        ### [其他控制节点] 修改/etc/ganglia/gmond.conf
        echo "=== TRACE MESSAGE ===>>> " ${controllers[$i]} ": 修改/etc/ganglia/gmond.conf" | tee -a $log_file
        scp ganglia/gmond-slave.conf ${controllers[$i]}:/tmp/gmond.conf
        ssh ${controllers[$i]} /bin/bash << EOF
            sed -i -e "s/GANGLIA_HOST_IP/$controller_0_mgmt_ip/g" /tmp/gmond.conf
            mv -f /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.backup
            cp /tmp/gmond.conf /etc/ganglia/
EOF

        ### [其他控制节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " ${controllers[$i]} ": 配置服务" | tee -a $log_file
        ssh ${controllers[$i]} /bin/bash << EOF
            systemctl enable gmond >> $log_file
            systemctl start gmond >> $log_file
EOF
    done;

  for h in ${networkers[@]};
    do
        ### [所有网络节点] 安装软件
        echo "=== TRACE MESSAGE ===>>> " $h ": 安装软件" | tee -a $log_file
        ssh $h yum install -y ganglia-gmond >> $log_file

        ### [所有网络节点] 修改/etc/ganglia/gmond.conf
        echo "=== TRACE MESSAGE ===>>> " $h ": 修改/etc/ganglia/gmond.conf" | tee -a $log_file
        scp ganglia/gmond-slave.conf $h:/tmp/gmond.conf
        ssh $h /bin/bash << EOF
            sed -i -e "s/GANGLIA_HOST_IP/$controller_0_mgmt_ip/g" /tmp/gmond.conf
            mv -f /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.backup
            cp /tmp/gmond.conf /etc/ganglia/
EOF

        ### [所有网络节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " $h ": 配置服务" | tee -a $log_file
        ssh $h /bin/bash << EOF
            systemctl enable gmond >> $log_file
            systemctl start gmond >> $log_file
EOF
    done

    for h in ${hypervisors[@]};
    do
        ### [所有计算节点] 安装软件
        echo "=== TRACE MESSAGE ===>>> " $h ": 安装软件" | tee -a $log_file
        ssh $h yum install -y ganglia-gmond >> $log_file

        ### [所有计算节点] 修改/etc/ganglia/gmond.conf
        echo "=== TRACE MESSAGE ===>>> " $h ": 修改/etc/ganglia/gmond.conf" | tee -a $log_file
        scp ganglia/gmond-slave.conf $h:/tmp/gmond.conf
        ssh $h /bin/bash << EOF
            sed -i -e "s/GANGLIA_HOST_IP/$controller_0_mgmt_ip/g" /tmp/gmond.conf
            mv -f /etc/ganglia/gmond.conf /etc/ganglia/gmond.conf.backup
            cp /tmp/gmond.conf /etc/ganglia/
EOF

        ### [所有计算节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " $h ": 配置服务" | tee -a $log_file
        ssh $h /bin/bash << EOF
            systemctl enable gmond >> $log_file
            systemctl start gmond >> $log_file
EOF
    done
}

echo -n "confirm to install ganglia [y|n]"
read answer
if [ $answer == "y" ]; then
    install_ganglia
fi
