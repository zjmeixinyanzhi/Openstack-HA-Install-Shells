#!/bin/sh
controller_name=(${!controller_map[@]});

sh_name=dashboard_install_configure.sh
source_sh=$(echo `pwd`)/sh/$sh_name
target_sh=/root/tools/t_sh/

#source_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron
#target_cfg=$(echo `pwd`)/sh/conf/haproxy.cfg.galera.keystone.glance.nova.neutron.dashboard
#
###### generate haproxy.cfg
#cp $source_cfg $target_cfg
#echo "listen dashboard_cluster
#    bind $virtual_ip:80
#    balance  source
#    option  tcpka
#    option  httpchk
#    option  tcplog">>$target_cfg
#for ((i=0; i<${#controller_map[@]}; i+=1));
#  do
#        name=${controller_name[$i]};
#        ip=${controller_map[$name]};
#        echo "-------------$name------------"
#        echo "    server $name $ip:80 check inter 2000 rise 2 fall 5" >>$target_cfg
#  done;

##### scp haproxy.cfg
for ((i=0; i<${#controller_map[@]}; i+=1));
  do
        name=${controller_name[$i]};
        ip=${controller_map[$name]};
        echo "-------------$name------------"
#        scp $target_cfg root@$ip:/etc/haproxy/haproxy.cfg
        ssh root@$ip mkdir -p $target_sh
        scp $source_sh root@$ip:$target_sh
        ssh root@$ip chmod -R +x $target_sh
        ssh root@$ip $target_sh/$sh_name $virtual_ip $local_nic
  done;
