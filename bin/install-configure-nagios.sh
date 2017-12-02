#!/bin/sh
. ../0-set-config.sh
./style/print-split.sh "Nagios Installation"
### [controller01] 安装软件
yum install -y nagios nagios-devel nagios-plugins* gd gd-devel php gcc glibc glibc-common openssl
###修改/etc/nagios/objects/commands.cfg文件
cat ../conf/nagios/check_nrpe | tee -a /etc/nagios/objects/commands.cfg > /dev/null
### [controller01] 修改/etc/nagios/objects/hosts.cfg文件
echo > /tmp/hosts.cfg.new
for ((i=0; i<${#nodes_map[@]}; i+=1));
do
  name=${nodes_name[$i]};
  ip=${nodes_map[$name]};
  sed \
      -e "s/FQDN/$name/g" \
      -e "s/HOSTNAME/$name/g" \
      -e "s/IP/$ip/g" \
      ../conf/nagios/host >> /tmp/hosts.cfg.new
done;
\cp /tmp/hosts.cfg.new /etc/nagios/objects/hosts.cfg
echo "cfg_file=/etc/nagios/objects/hosts.cfg" >> /etc/nagios/nagios.cfg
### [controller01] 修改/etc/nagios/objects/services.cfg文件
echo > /tmp/services.cfg.new
for h in ${!controller_map[@]}
do
  sed -e "s/FQDN/$h/g" ../conf/nagios/controller_services >> /tmp/services.cfg.new
  if [[ "$networker_split" = "no" ]];then
    sed -e "s/FQDN/$h/g" ../conf/nagios/networker_services >> /tmp/services.cfg.new
  fi
done
if [[ "$networker_split" = "yes" ]];then
  for h in ${!networker_map[@]}
  do
    sed -e "s/FQDN/$h/g" ../conf/nagios/networker_services >> /tmp/services.cfg.new
  done
fi
for h in ${!hypervisor_map[@]}
do
  sed -e "s/FQDN/$h/g" ../conf/nagios/compute_services >> /tmp/services.cfg.new
done
\cp /tmp/services.cfg.new /etc/nagios/objects/services.cfg
echo "cfg_file=/etc/nagios/objects/services.cfg" >> /etc/nagios/nagios.cfg
### [controller01] 检查配置项是否正确
echo "=== TRACE MESSAGE ===>>> " "按任意键检查配置项是否正确[-]"
read answer
nagios -v /etc/nagios/nagios.cfg
echo "=== TRACE MESSAGE ===>>> " "按任意键继续[-]" 
read answer
### [controller01] 配置服务
echo "=== TRACE MESSAGE ===>>> " "配置服务"
systemctl enable nagios && systemctl start nagios
### [controller01] 设置nagiosadmin登录密码
echo "=== TRACE MESSAGE ===>>> " "设置nagiosadmin登录密码" 
htpasswd -b -c /etc/nagios/passwd nagiosadmin $password_nagiosadmin
### 安装nrpe
./pssh-exe A "yum install -y nrpe nagios-plugins* openssl"
### [所有节点] 编辑/etc/nagios/nrpe.cfg配置文件，添加服务端地址
./pssh-exe A "\cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg.bak"
./pssh-exe A  "sed -i -e 's#^allowed_hosts.*#allowed_hosts=127.0.0.1,${local_network}#' /etc/nagios/nrpe.cfg"
### 定义check_nrpe监控脚本
cat ../conf/nagios/controller_nrpe_commands > /tmp/controller_nrpe_commands
if [[ "$networker_split" = "yes" ]];then
  cat ../conf/nagios/networker_nrpe_commands > /tmp/networker_nrpe_commands
  ./scp-exe N /tmp/networker_nrpe_commands /etc/nagios/nrpe.cfg
else
  cat ../conf/nagios/networker_nrpe_commands >> /tmp/controller_nrpe_commands
fi
./scp-exe C /tmp/controller_nrpe_commands /etc/nagios/nrpe.cfg
cat ../conf/nagios/compute_nrpe_commands > /tmp/compute_nrpe_commands
./scp-exe H /tmp/compute_nrpe_commands /etc/nagios/nrpe.cfg
### [所有节点] 配置服务
./pssh-exe A "systemctl enable nrpe && systemctl start nrpe"
echo -n "访问nagios web服务确认安装成功：http://"${controller_map[$ref_host]}"/nagios"
read answer
