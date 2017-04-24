#!/bin/sh

###
### deploy openstack ha cluster 
### 
### run from the first controller node, it'll be the nagios master
###

. ../000-common.sh

file_full_name=`basename "$0"`
file_extension="${file_full_name##*.}"
file_name="${file_full_name%.*}"
log_file="/tmp/"$file_name".log"

echo > $log_file

function install_nagios() {
    ### [controller01] 安装软件
    echo "=== TRACE MESSAGE ===>>> " "安装软件" | tee -a $log_file
    yum install -y nagios nagios-devel nagios-plugins* gd gd-devel php gcc glibc glibc-common openssl >> $log_file

    ### [controller01] 修改/etc/nagios/objects/commands.cfg文件，定义check_nrpe监控脚本，它用在service的定义中
    echo "=== TRACE MESSAGE ===>>> " "修改/etc/nagios/objects/commands.cfg文件" | tee -a $log_file
    cat nagios/check_nrpe | tee -a /etc/nagios/objects/commands.cfg > /dev/null

    ### [controller01] 修改/etc/nagios/objects/hosts.cfg文件
    echo "=== TRACE MESSAGE ===>>> " "修改/etc/nagios/objects/hosts.cfg文件" | tee -a $log_file
    echo > /tmp/hosts.cfg.new
    for c in ${controllers[@]};
    do
        sed \
            -e "s/FQDN/$c$domain_suffix/g" \
            -e "s/HOSTNAME/$c/g" \
            -e "s/IP/${controller_mgmt_nic_map[$c]}/g" \
            nagios/host >> /tmp/hosts.cfg.new
    done
    
    for h in ${networkers[@]};
    do
        sed \
            -e "s/FQDN/$h$domain_suffix/g" \
            -e "s/HOSTNAME/$h/g" \
            -e "s/IP/${networkers_mgmt_nic_map[$h]}/g" \
            nagios/host >> /tmp/hosts.cfg.new
    done


    for h in ${hypervisors[@]};
    do
        sed \
            -e "s/FQDN/$h$domain_suffix/g" \
            -e "s/HOSTNAME/$h/g" \
            -e "s/IP/${hypervisor_mgmt_nic_map[$h]}/g" \
            nagios/host >> /tmp/hosts.cfg.new
    done

    cp /tmp/hosts.cfg.new /etc/nagios/objects/hosts.cfg
    echo "cfg_file=/etc/nagios/objects/hosts.cfg" >> /etc/nagios/nagios.cfg

    ### [controller01] 修改/etc/nagios/objects/services.cfg文件
    echo "=== TRACE MESSAGE ===>>> " "修改/etc/nagios/objects/services.cfg文件" | tee -a $log_file
    echo > /tmp/services.cfg.new
    for c in ${controllers[@]};
    do
        sed -e "s/FQDN/$c$domain_suffix/g" nagios/controller_services >> /tmp/services.cfg.new
    done
    
    for h in ${networkers[@]};
    do
        sed -e "s/FQDN/$h$domain_suffix/g" nagios/networker_services >> /tmp/services.cfg.new
    done

    for h in ${hypervisors[@]};
    do
        sed -e "s/FQDN/$h$domain_suffix/g" nagios/compute_services >> /tmp/services.cfg.new
    done

    cp /tmp/services.cfg.new /etc/nagios/objects/services.cfg
    echo "cfg_file=/etc/nagios/objects/services.cfg" >> /etc/nagios/nagios.cfg

    ### [controller01] 检查配置项是否正确
    echo "=== TRACE MESSAGE ===>>> " "按任意键检查配置项是否正确[-]" | tee -a $log_file
    read answer
    nagios -v /etc/nagios/nagios.cfg 
    echo "=== TRACE MESSAGE ===>>> " "按任意键继续[-]" | tee -a $log_file
    read answer

    ### [controller01] 配置服务
    echo "=== TRACE MESSAGE ===>>> " "配置服务" | tee -a $log_file
    systemctl enable nagios >> $log_file
    systemctl start nagios

    ### [controller01] 设置nagiosadmin登录密码
    echo "=== TRACE MESSAGE ===>>> " "设置nagiosadmin登录密码" | tee -a $log_file
    htpasswd -b -c /etc/nagios/passwd nagiosadmin 123456

    controller_0_mgmt_ip=${controller_mgmt_nic_map[$controller_0]}
    for c in ${controllers[@]};
    do
        ### [所有控制节点] 安装软件
        echo "=== TRACE MESSAGE ===>>> " $c ": 安装软件" | tee -a $log_file
        ssh $c yum install -y nrpe nagios-plugins* openssl >> $log_file

        ### [所有控制节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加服务端地址
        echo "=== TRACE MESSAGE ===>>> " $c ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        ssh $c /bin/bash << EOF
            sed -i -e "s/^allowed_hosts.*/allowed_hosts=127.0.0.1, $controller_0_mgmt_ip/" /etc/nagios/nrpe.cfg
EOF

        ### [所有控制节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加监控命令
        echo "=== TRACE MESSAGE ===>>> " $c ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        scp nagios/controller_nrpe_commands $c:/tmp
        ssh $c /bin/bash << EOF
            cat /tmp/controller_nrpe_commands | tee -a /etc/nagios/nrpe.cfg > /dev/null
EOF

        ### [所有控制节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " $c ": 配置服务" | tee -a $log_file
        ssh $c /bin/bash << EOF
            systemctl enable nrpe >> $log_file
            systemctl start nrpe
EOF
    done;

  for h in ${networkers[@]};
    do
        ### [所有网络节点] 安装软件
:        echo "=== TRACE MESSAGE ===>>> " $h ": 安装软件" | tee -a $log_file
        ssh $h yum install -y nrpe nagios-plugins* openssl >> $log_file

        ### [所有网络节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加服务端地址
        echo "=== TRACE MESSAGE ===>>> " $h ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        ssh $h /bin/bash << EOF
            sed -i -e "s/^allowed_hosts.*/allowed_hosts=127.0.0.1, $controller_0_mgmt_ip/" /etc/nagios/nrpe.cfg
EOF

        ### [所有网络节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加监控命令
        echo "=== TRACE MESSAGE ===>>> " $h ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        scp nagios/networker_nrpe_commands $h:/tmp
        ssh $h /bin/bash << EOF
            cat /tmp/networker_nrpe_commands | tee -a /etc/nagios/nrpe.cfg > /dev/null
EOF

        ### [所有网络节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " $h ": 配置服务" | tee -a $log_file
        ssh $h /bin/bash << EOF
            systemctl enable nrpe >> $log_file
            systemctl start nrpe
EOF
    done;


    for h in ${hypervisors[@]};
    do
        ### [所有计算节点] 安装软件
        echo "=== TRACE MESSAGE ===>>> " $h ": 安装软件" | tee -a $log_file
        ssh $h yum install -y nrpe nagios-plugins* openssl >> $log_file

        ### [所有计算节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加服务端地址
        echo "=== TRACE MESSAGE ===>>> " $h ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        ssh $h /bin/bash << EOF
            sed -i -e "s/^allowed_hosts.*/allowed_hosts=127.0.0.1, $controller_0_mgmt_ip/" /etc/nagios/nrpe.cfg
EOF

        ### [所有计算节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加监控命令
        echo "=== TRACE MESSAGE ===>>> " $h ": 编辑/etc/nagios/nrpe.cfg配置文件" | tee -a $log_file
        scp nagios/compute_nrpe_commands $h:/tmp
        ssh $h /bin/bash << EOF
            cat /tmp/compute_nrpe_commands | tee -a /etc/nagios/nrpe.cfg > /dev/null
EOF

        ### [所有计算节点] 配置服务
        echo "=== TRACE MESSAGE ===>>> " $h ": 配置服务" | tee -a $log_file
        ssh $h /bin/bash << EOF
            systemctl enable nrpe >> $log_file
            systemctl start nrpe
EOF
    done;

    echo -n "访问nagios web服务确认安装成功：http://"${controller_mgmt_nic_map[$controller_0]}"/nagios"
    read answer        
}

echo -n "confirm to install nagios [y|n]"
read answer
if [ $answer == "y" ]; then
    install_nagios
fi
